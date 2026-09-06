pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

Scope {
    id: root
    property var windowList: []
    property var workspaces: []
    property var workspaceById: ({})
    property var activeWorkspace: null
    property var monitors: []
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
            monitorName: w.monitor ?? "",
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
    function switchWorkspacesOnMonitors(entries, focusMonitor) {
        for (const entry of entries) {
            if (!entry?.monitorName) continue
            Hyprland.dispatch(`hl.dsp.focus({ monitor = "${entry.monitorName}" })`)
            Hyprland.dispatch(`hl.dsp.focus({ workspace = ${entry.workspaceId} })`)
        }
        if (focusMonitor)
            Hyprland.dispatch(`hl.dsp.focus({ monitor = "${focusMonitor}" })`)
    }
    function moveWindowToWorkspace(id, wsId) {
        Hyprland.dispatch(`hl.dsp.window.move({ workspace = ${wsId}, follow = false, window = "address:${id}" })`);
    }

    function monitorFor(screen) {
        return Hyprland.monitorFor(screen);
    }

    function activeWorkspaceForMonitor(monitorName) {
        const m = Hyprland.monitors.values.find(mm => mm.name === monitorName);
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

    Component.onCompleted: refresh()

    function refresh() {
        windowList = HyprlandData.windowList.map(normalizeWindow);
        workspaces = HyprlandData.workspaces;
        workspaceById = HyprlandData.workspaceById;
        activeWorkspace = HyprlandData.activeWorkspace;
        monitors = HyprlandData.monitors;
    }

    Connections {
        target: HyprlandData
        function onWindowListChanged() { root.refresh() }
        function onWorkspacesChanged() { root.refresh() }
        function onMonitorsChanged() { root.refresh() }
    }
}
