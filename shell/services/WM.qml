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

    // Backends are resolved by *file URL* at runtime rather than declared as
    // inline `Component { NullBackend {} }` blocks.
    //
    // WM.qml is a Singleton that most other services depend on (Updates ->
    // TrayService -> Translation -> Todo, ...), so it is one of the very first
    // documents the engine compiles. An inline component pins its type at
    // document-compile time against the implicit same-directory import, and
    // that lookup has been observed to run before every sibling file has
    // finished registering - throwing "NullBackend is not a type" and taking
    // the entire configuration down with it (see the reload failure in
    // ~/.local/state logs). Qt.callLater did not help, because the failing
    // lookup happens while WM.qml itself is being compiled, long before
    // onCompleted ever runs.
    //
    // Qt.createComponent() resolves the same file lazily, by path, after the
    // engine is fully up - and reports a readable error instead of aborting
    // the whole config if a backend file really is broken.
    Component.onCompleted: root.createBackend()

    function _componentFor(fileName) {
        const comp = Qt.createComponent(Qt.resolvedUrl(fileName), Component.PreferSynchronous);
        if (comp.status === Component.Error) {
            console.warn("[WM] Could not load backend " + fileName + ": " + comp.errorString());
            return null;
        }
        return comp;
    }

    function _instantiate(fileName) {
        const comp = root._componentFor(fileName);
        return comp ? comp.createObject(root) : null;
    }

    function createBackend() {
        let created = null;
        switch (root.compositor) {
        case "hyprland": created = root._instantiate("HyprlandBackend.qml"); break;
        case "niri":     created = root._instantiate("NiriBackend.qml"); break;
        case "i3":       created = root._instantiate("I3Backend.qml"); break;
        // case "sway":  created = root._instantiate("SwayBackend.qml"); break;
        // case "mango": created = root._instantiate("MangoBackend.qml"); break;
        default:
            // Never instantiate Hyprland integration outside a Hyprland
            // session: that used to make a plain X11 session fail at startup.
            console.log("[WM] Unsupported compositor: " + root.compositor + "; using the safe backend");
        }
        // Also covers a compositor-specific backend that failed to load: the
        // shell stays up on the no-op backend instead of leaving every
        // `backend?.` proxy permanently null.
        root.backend = created ?? root._instantiate("NullBackend.qml");
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
