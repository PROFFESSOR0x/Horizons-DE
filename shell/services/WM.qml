pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property string compositor: detectCompositor()
    readonly property string sessionType: (Quickshell.env("XDG_SESSION_TYPE") ?? "").toLowerCase()
    readonly property bool isWayland: sessionType === "wayland"
    readonly property bool isX11: sessionType === "x11"
    // Keep feature checks in one place. Components can stay generic instead of
    // making assumptions from the compositor name.
    readonly property var capabilities: ({
        workspaceIpc: compositor === "hyprland" || compositor === "niri" || compositor === "i3",
        compositorShortcuts: compositor === "hyprland",
        layerShell: isWayland,
        screenCapture: isWayland,
        x11: isX11
    })
    property QtObject backend: null

    function switchWorkspaceRelative(direction) { backend?.switchWorkspaceRelative(direction) }

    function detectCompositor() {
        const desktop = (Quickshell.env("XDG_CURRENT_DESKTOP") ?? "").toLowerCase();
        const session = (Quickshell.env("XDG_SESSION_DESKTOP") ?? "").toLowerCase();
        const combined = desktop + " " + session;

        if (combined.includes("hyprland")) return "hyprland";
        if (combined.includes("niri")) return "niri";
        if (combined.includes("i3")) return "i3";
        if (combined.includes("sway")) return "sway";
        if (combined.includes("mango")) return "mango";
        return "unknown";
    }

    Component { id: hyprlandComp; HyprlandBackend {} }
    Component { id: niriComp; NiriBackend {} }
    Component { id: i3Comp; I3Backend {} }
    Component { id: nullComp; NullBackend {} }
    // Component { id: swayComp; SwayBackend {} }
    // Component { id: mangoComp; MangoBackend {} }

    Component.onCompleted: {
        switch (root.compositor) {
        case "hyprland": backend = hyprlandComp.createObject(root); break;
        case "niri":     backend = niriComp.createObject(root); break;
        case "i3":       backend = i3Comp.createObject(root); break;
        // case "sway":  backend = swayComp.createObject(root); break;
        // case "mango": backend = mangoComp.createObject(root); break;
        default:
            // Never instantiate Hyprland integration outside a Hyprland
            // session: that used to make a plain X11 session fail at startup.
            console.log("[WM] Unsupported compositor: " + root.compositor + "; using the safe backend");
            backend = nullComp.createObject(root);
        }
    }

    // Proxies
    readonly property var windowList: backend?.windowList ?? []
    readonly property var workspaces: backend?.workspaces ?? []
    readonly property var workspaceById: backend?.workspaceById ?? ({})
    readonly property var activeWorkspace: backend?.activeWorkspace ?? null
    readonly property var monitors: backend?.monitors ?? []
    readonly property var focusedMonitor: backend?.focusedMonitor ?? null

    function focusWindow(id) { backend?.focusWindow(id) }
    function closeWindow(id) { backend?.closeWindow(id) }
    function switchWorkspace(id) { backend?.switchWorkspace(id) }
    function moveWindowToWorkspace(id, wsId) { backend?.moveWindowToWorkspace(id, wsId) }
    function monitorFor(screen) { return backend?.monitorFor(screen) ?? null }
    function activeWorkspaceForMonitor(monitorName) { return backend?.activeWorkspaceForMonitor(monitorName) ?? null }
    function biggestWindowForWorkspace(wsId) { return backend?.biggestWindowForWorkspace(wsId) ?? null }
    function fullscreenOnMonitor(monitorName) { return backend?.fullscreenOnMonitor(monitorName) ?? false }
    function monitorGeometry(screen) { return backend?.monitorGeometry(screen) ?? { x: 0, y: 0, scale: 1 } }
}
