pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

Scope {
    id: root
    property var windowList: HyprlandData.windowList.map(normalizeWindow)
    property var workspaces: HyprlandData.workspaces
    property var workspaceById: HyprlandData.workspaceById
    property var activeWorkspace: HyprlandData.activeWorkspace
    property var monitors: HyprlandData.monitors
    property var focusedMonitor: Hyprland.focusedMonitor

    // Hyprland >= 0.55 parses socket `dispatch` payloads as Lua
    // (hl.dispatch(...)), so every dispatcher below is spelled in the Lua
    // form (hl.dsp.*). The classic flat names ("workspace 3",
    // "focusmonitor eDP-1", ...) are rejected with exit 7 and the action
    // silently never happens.
    function luaStr(s) {
        return '"' + String(s ?? "").replace(/\\/g, "\\\\").replace(/"/g, '\\"') + '"'
    }

    function switchWorkspaceRelative(direction) {
        Hyprland.dispatch(`hl.dsp.focus({ workspace = "r${direction === "next" ? "+1" : "-1"}" })`);
    }
    function normalizeWindow(w) {
        return {
            id: w.address,
            address: w.address,
            title: w.title,
            appId: w.class,
            workspaceId: w.workspace?.id ?? -1,
            monitorName: HyprlandData.monitors.find(m => m.id === w.monitor || m.name === w.monitor)?.name ?? "",
            pid: w.pid ?? 0,
            focused: w.address === HyprlandData.activeWorkspace?.lastwindow
        };
    }

    function focusWindow(id) {
        Hyprland.dispatch(`hl.dsp.focus({ window = "address:${id}" })`);
    }
    function closeWindow(id) {
        Hyprland.dispatch(`hl.dsp.window.close({ window = "address:${id}" })`);
    }
    function forceCloseWindow(id, pid) {
        const numericPid = Number(pid)
        if (!Number.isInteger(numericPid) || numericPid < 2) {
            root.closeWindow(id)
            return
        }
        // End descendants before the app process. This is intentionally
        // explicit rather than a compositor "close" request: it is the
        // End task action exposed in the contextual menus.
        Quickshell.execDetached(["bash", "-c", "killtree(){ for child in $(pgrep -P \"$1\"); do killtree \"$child\"; done; kill -KILL \"$1\" 2>/dev/null || true; }; killtree \"$1\"", "horizons-end-task", String(numericPid)])
    }
    function switchWorkspace(id) {
        Hyprland.dispatch(`hl.dsp.focus({ workspace = ${Number(id)} })`);
    }
    function switchWorkspaceOnMonitor(id, monitorName) {
        if (monitorName)
            Hyprland.dispatch(`hl.dsp.focus({ monitor = ${root.luaStr(monitorName)} })`)
        root.switchWorkspace(id)
    }
    function nextWorkspaceId() {
        const used = new Set()
        for (const workspace of Hyprland.workspaces.values) {
            const id = Number(workspace?.id)
            if (Number.isInteger(id) && id > 0 && id < 2147483000)
                used.add(id)
        }
        let candidate = 1
        while (used.has(candidate)) ++candidate
        return candidate
    }
    function switchWorkspacesOnMonitors(entries, focusMonitor, windowToFocus) {
        const quote = s => "'" + String(s).replace(/'/g, "'\\''") + "'"
        // One hyprctl call per action; the payload is Lua (see note above),
        // shell-quoted as a whole so the compositor receives it verbatim.
        const dispatchLua = lua => `hyprctl dispatch ${quote(lua)} >/dev/null 2>&1 || true`
        const commands = []
        for (const entry of entries) {
            if (!entry?.monitorName || !Number.isInteger(Number(entry.workspaceId))) continue
            const monitor = String(entry.monitorName)
            const workspace = Number(entry.workspaceId)
            commands.push(dispatchLua(`hl.dsp.workspace.move({ workspace = ${workspace}, monitor = ${root.luaStr(monitor)} })`))
            commands.push(dispatchLua(`hl.dsp.focus({ monitor = ${root.luaStr(monitor)} })`))
            commands.push(dispatchLua(`hl.dsp.focus({ workspace = ${workspace} })`))
        }
        if (commands.length === 0) return
        // Restore focus to the screen that initiated the action. The previous
        // implementation ignored focusMonitor, leaving focus on whichever
        // monitor happened to be processed last.
        const focusEntry = entries.find(entry => entry?.monitorName === focusMonitor)
            ?? entries[entries.length - 1]
        if (focusEntry?.monitorName)
            commands.push(dispatchLua(`hl.dsp.focus({ monitor = ${root.luaStr(focusEntry.monitorName)} })`))
        if (focusEntry?.workspaceId)
            commands.push(dispatchLua(`hl.dsp.focus({ workspace = ${Number(focusEntry.workspaceId)} })`))
        // A dock/tray activation may point at a window in a currently hidden
        // member of the set. Focus it only after all monitors have reached
        // their mapped workspaces, otherwise Hyprland performs its normal
        // single-monitor workspace jump first.
        if (typeof windowToFocus === "string" && windowToFocus.length > 0)
            commands.push(dispatchLua(`hl.dsp.focus({ window = "address:${windowToFocus}" })`))
        const script = commands.join("; ")
        console.log("[Workspaces] Hyprland multi-monitor dispatch=" + script)
        Quickshell.execDetached(["bash", "-c", script])
    }
    function moveWindowToWorkspace(id, wsId) {
        Hyprland.dispatch(`hl.dsp.window.move({ workspace = ${Number(wsId)}, window = "address:${id}", follow = false })`);
    }

    function monitorFor(screen) {
        return Hyprland.monitorFor(screen);
    }

    function activeWorkspaceForMonitor(monitorName) {
        // HyprlandData is the same direct `hyprctl monitors -j` snapshot used
        // for the rest of the shell. Quickshell's monitor wrapper can lag one
        // compositor event, which previously made group generation use stale
        // workspace ids immediately after a switch.
        const m = HyprlandData.monitors.find(mm => mm.name === monitorName)
            ?? Hyprland.monitors.values.find(mm => mm.name === monitorName);
        return m?.activeWorkspace ? { id: m.activeWorkspace.id } : null;
    }

    function biggestWindowForWorkspace(wsId) {
        return HyprlandData.biggestWindowForWorkspace(wsId);
    }

    // Per-monitor "is the desktop actually covered right now": true when the
    // monitor's active workspace holds at least one mapped, non-floating (or
    // fullscreen) window. Deliberately a property, not a function, so bindings
    // that read it re-evaluate when the window list changes - and keyed by
    // monitor so one screen going busy never affects what another screen shows.
    readonly property var obscuredMonitors: computeObscuredMonitors()
    function computeObscuredMonitors() {
        const out = ({});
        const windows = HyprlandData.windowList ?? [];
        for (const m of (HyprlandData.monitors ?? [])) {
            if (!m?.name) continue;
            const wsId = m.activeWorkspace?.id;
            if (wsId === undefined || wsId === null) {
                out[m.name] = false;
                continue;
            }
            out[m.name] = windows.some(w => w?.workspace?.id === wsId
                && w.mapped !== false
                && w.hidden !== true
                // A floating window is one the user can see the desktop
                // around/behind, so it doesn't count as covering it. A
                // fullscreened one does even when it is also floating.
                && (w.fullscreen ? true : !w.floating));
        }
        return out;
    }

    function fullscreenOnMonitor(monitorName) {
        const wsList = Hyprland.workspaces.values.filter(ws => ws.monitor && ws.monitor.name === monitorName);
        return wsList.some(ws => ws.active && ws.toplevels.values.some(w => w.wayland?.fullscreen));
    }

    function monitorGeometry(screen) {
        const m = Hyprland.monitorFor(screen);
        if (!m) return { x: 0, y: 0, scale: 1 };
        return { x: m.x, y: m.y, scale: m.scale };
    }

}
