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

    function switchWorkspaceRelative(direction) {
        Hyprland.dispatch(`hl.dsp.focus({workspace = "r${direction === "next" ? "+1" : "-1"}"})`);
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
        Hyprland.dispatch(`hl.dsp.focus({ workspace = ${id} })`);
    }
    function switchWorkspaceOnMonitor(id, monitorName) {
        if (monitorName)
            Hyprland.dispatch(`hl.dsp.focus({ monitor = "${monitorName}" })`)
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
        // Hyprland 0.55+ uses Lua dispatchers. `focus({ monitor })` alone is
        // not enough here: focus-follows-mouse can immediately return focus to
        // the pointer's output before the next workspace command executes.
        // Drive the cursor to the *centre* of each target output inside one Lua
        // evaluation, focus/create the requested workspace there, then restore
        // it in the same compositor transaction. Never use x/y + 1 here:
        // those are screen-corner hover zones and made Ctrl+Super+Arrow open a
        // sidebar as an unintended side effect. If a target already exists on
        // a different screen, move it first so every logical member remains on
        // its assigned output.
        const statements = ["local p = hl.get_cursor_pos()"]
        for (const entry of entries) {
            if (!entry?.monitorName || !Number.isInteger(Number(entry.workspaceId))) continue
            const monitor = JSON.stringify(String(entry.monitorName))
            const workspace = Number(entry.workspaceId)
            statements.push("do local m = hl.get_monitor(" + monitor + "); if m then "
                + "local ws = hl.get_workspace(" + workspace + "); "
                + "if ws then hl.dispatch(hl.dsp.workspace.move({ workspace = ws, monitor = m })) end; "
                + "hl.dispatch(hl.dsp.cursor.move({ x = m.position.x + math.floor(m.width / 2), y = m.position.y + math.floor(m.height / 2) })); "
                + "hl.dispatch(hl.dsp.focus({ workspace = " + workspace + " })) end end")
        }
        if (statements.length === 1) return
        statements.push("hl.dispatch(hl.dsp.cursor.move({ x = p.x, y = p.y }))")
        // Restore focus to the screen that initiated the action. The previous
        // implementation ignored focusMonitor, leaving focus on whichever
        // monitor happened to be processed last.
        const focusEntry = entries.find(entry => entry?.monitorName === focusMonitor)
            ?? entries[entries.length - 1]
        if (focusEntry?.workspaceId)
            statements.push("hl.dispatch(hl.dsp.focus({ workspace = " + Number(focusEntry.workspaceId) + " }))")
        // A dock/tray activation may point at a window in a currently hidden
        // member of the set. Focus it only after all monitors have reached
        // their mapped workspaces, otherwise Hyprland performs its normal
        // single-monitor workspace jump first.
        if (typeof windowToFocus === "string" && windowToFocus.length > 0)
            statements.push("hl.dispatch(hl.dsp.focus({ window = "
                + JSON.stringify("address:" + windowToFocus) + " }))")
        const code = statements.join("; ")
        console.log("[Workspaces] Hyprland multi-monitor eval=" + code)
        Quickshell.execDetached(["hyprctl", "eval", code])
    }
    function moveWindowToWorkspace(id, wsId) {
        Hyprland.dispatch(`hl.dsp.window.move({ workspace = ${wsId}, follow = false, window = "address:${id}" })`);
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
