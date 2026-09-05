pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property string compositor: detectCompositor()
    // XDG_SESSION_TYPE is empty inside Xephyr/nested X sessions and plain `i3` launches.
    // Fall back to WAYLAND_DISPLAY/DISPLAY so a bare `DISPLAY=:1 quickshell -c horizons`
    // is correctly recognised as X11 instead of “unknown”.
    readonly property string sessionType: {
        let t = (Quickshell.env("XDG_SESSION_TYPE") ?? "").toLowerCase();
        if (t === "wayland" || t === "x11") return t;
        if ((Quickshell.env("WAYLAND_DISPLAY") ?? "") !== "") return "wayland";
        if ((Quickshell.env("DISPLAY") ?? "") !== "") return "x11";
        return t;
    }
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
        // i3/X11 sessions often export no XDG_CURRENT_DESKTOP – detect via I3SOCK/WINDOWMANAGER too
        const i3sock = (Quickshell.env("I3SOCK") ?? "")
        const wmHint = (Quickshell.env("WINDOWMANAGER") ?? "").toLowerCase()

        if (combined.includes("hyprland")) return "hyprland";
        if (combined.includes("niri")) return "niri";
        if (combined.includes("i3") || i3sock !== "" || wmHint.includes("i3")) return "i3";
        if (combined.includes("sway")) return "sway";
        if (combined.includes("mango")) return "mango";
        // Last resort: if we are on X11 and no compositor was identified, assume i3
        let sess = (Quickshell.env("XDG_SESSION_TYPE") ?? "").toLowerCase();
        if (sess !== "wayland" && sess !== "x11") {
            if ((Quickshell.env("WAYLAND_DISPLAY") ?? "") === "" && (Quickshell.env("DISPLAY") ?? "") !== "")
                return "i3";
        } else if (sess === "x11") {
            return "i3";
        }
        return "unknown";
    }

    Component { id: hyprlandComp; HyprlandBackend {} }
    Component { id: niriComp; NiriBackend {} }
    Component { id: i3Comp; I3Backend {} }
    Component { id: nullComp; NullBackend {} }
    // Component { id: swayComp; SwayBackend {} }
    // Component { id: mangoComp; MangoBackend {} }

    // Deferred one tick past construction: WM.qml is a Singleton other
    // services eagerly depend on (Updates -> TrayService -> Translation ->
    // Todo, etc.), so it tends to be one of the very first files the QML
    // engine resolves on a cold shell start. Calling createObject() on a
    // same-directory Component synchronously inside Component.onCompleted
    // has been observed to occasionally hit the directory's own type table
    // before every sibling file (NullBackend.qml included) finishes
    // registering, throwing "NullBackend is not a type" and cascading into
    // every service that (transitively) imports WM - a one-shot crash on the
    // first launch after boot that a plain restart doesn't reproduce.
    // Qt.callLater lets that registration pass finish first.
    Component.onCompleted: Qt.callLater(root.createBackend)

    function createBackend() {
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
