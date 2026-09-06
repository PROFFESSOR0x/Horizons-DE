pragma ComponentBehavior: Bound
import QtQuick
import Quickshell

// Intentionally empty backend for desktops Horizons does not integrate with.
// Keeping this shape identical to the real backends lets generic shell widgets
// load safely instead of accidentally constructing Hyprland objects on X11.
Scope {
    property var windowList: []
    property var workspaces: []
    property var workspaceById: ({})
    property var activeWorkspace: null
    property var monitors: []
    property var focusedMonitor: null

    function switchWorkspaceRelative(direction) {}
    function focusWindow(id) {}
    function closeWindow(id) {}
    function switchWorkspace(id) {}
    function moveWindowToWorkspace(id, wsId) {}
    function monitorFor(screen) { return null }
    function activeWorkspaceForMonitor(monitorName) { return null }
    function biggestWindowForWorkspace(wsId) { return null }
    // See HyprlandBackend.obscuredMonitors - nothing known, nothing covered.
    property var obscuredMonitors: ({})
    function fullscreenOnMonitor(monitorName) { return false }
    function monitorGeometry(screen) { return { x: 0, y: 0, scale: 1 } }
}
