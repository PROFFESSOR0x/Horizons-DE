pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import qs.services

/**
 * Provides access to some Hyprland data not available in Quickshell.Hyprland.
 */
Singleton {
    id: root
    property bool workspacesReady: false
    property var windowList: []
    property var addresses: []
    property var windowByAddress: ({})
    property var workspaces: []
    property var workspaceIds: []
    property var workspaceById: ({})
    property var activeWorkspace: null
    property var monitors: []
    property var layers: ({})
    readonly property string requestSocketPath: {
        const runtime = Quickshell.env("XDG_RUNTIME_DIR") ?? ""
        const signature = Quickshell.env("HYPRLAND_INSTANCE_SIGNATURE") ?? ""
        return runtime && signature ? runtime + "/hypr/" + signature + "/.socket.sock" : ""
    }
    // decoration:blur:variant (hyprwm/Hyprland PR #15661, merged
    // 2026-08-22) isn't in any tagged Hyprland release yet, only in a
    // from-source/-git build past that commit — hyprconfigurator.py's
    // option_is_supported() silently drops it on anything older, so picking
    // a variant does nothing with no visible error. Checked once so any
    // settings page (Hyprland > Blur Style, Quick > performance profiles)
    // can show a real warning instead of a silent no-op. Defaults to
    // "assume supported" so a failed/slow hyprctl call never shows a
    // false-positive warning.
    property bool blurVariantSupported: true
    function checkBlurVariantSupport() {
        if (WM.compositor !== "hyprland") return;
        checkBlurVariantSupportProc.running = true;
    }
    Process {
        id: checkBlurVariantSupportProc
        command: ["hyprctl", "-j", "getoption", "decoration:blur:variant"]
        stdout: StdioCollector { id: blurVariantSupportOutput }
        onExited: (exitCode, exitStatus) => {
            if (exitCode !== 0) return; // hyprctl unreachable — stay optimistic
            try {
                const parsed = JSON.parse(blurVariantSupportOutput.text)
                root.blurVariantSupported = !!(parsed && parsed.option === "decoration:blur:variant")
            } catch (e) {
                // hyprctl exited 0 but didn't return JSON — that's how it
                // reports "no such option" (matches hyprconfigurator.py's
                // option_is_supported()), i.e. genuinely unsupported.
                root.blurVariantSupported = false
            }
        }
    }

    // Convenient stuff

    function toplevelsForWorkspace(workspace) {
        return ToplevelManager.toplevels.values.filter(toplevel => {
            const address = `0x${toplevel.HyprlandToplevel?.address}`;
            var win = HyprlandData.windowByAddress[address];
            return win?.workspace?.id === workspace;
        })
    }

    function hyprlandClientsForWorkspace(workspace) {
        return root.windowList.filter(win => win?.workspace?.id === workspace);
    }

    function clientForToplevel(toplevel) {
        if (!toplevel) return null

        // ToplevelManager exposes Wayland Toplevel handles. On current
        // Quickshell the Hyprland address is an *attached* property, not a
        // JavaScript field on that handle; treating it as
        // `toplevel.HyprlandToplevel.address` therefore produced
        // "0xundefined" and made dock buttons inert. Match the compositor's
        // authoritative client snapshot by its stable app id and title. The
        // address path remains for older QuickShell builds that expose it.
        const rawAddress = toplevel?.HyprlandToplevel?.address ?? ""
        if (rawAddress) {
            const address = String(rawAddress).startsWith("0x")
                ? String(rawAddress) : "0x" + String(rawAddress)
            if (root.windowByAddress[address]) return root.windowByAddress[address]
        }
        const appId = String(toplevel.appId ?? "").toLowerCase()
        const title = String(toplevel.title ?? "")
        const candidates = root.windowList.filter(window => {
            const windowAppId = String(window?.class ?? "").toLowerCase()
            return (appId && windowAppId === appId) || (title && window?.title === title)
        })
        return candidates.find(window => String(window?.class ?? "").toLowerCase() === appId
                && window?.title === title)
            ?? candidates.find(window => String(window?.class ?? "").toLowerCase() === appId)
            ?? candidates[0]
            ?? null
    }

    // Internals

    function updateWindowList() {
        if (WM.compositor === "hyprland") getClients.request()
    }
    function updateLayers() {
        if (WM.compositor === "hyprland") getLayers.request()
    }
    function updateMonitors() {
        if (WM.compositor === "hyprland") getMonitors.request()
    }
    function updateWorkspaces() {
        if (WM.compositor !== "hyprland") return
        getWorkspaces.request()
        getActiveWorkspace.request()
    }
    function updateAll() {
        updateWindowList()
        updateMonitors()
        updateLayers()
        updateWorkspaces()
    }
    function scheduleWindowListUpdate() { updateWindowList() }
    function scheduleWorkspaceUpdate() { updateMonitors(); updateWorkspaces() }
    function scheduleUpdateAll() { updateAll() }

    function biggestWindowForWorkspace(workspaceId) {
        const windowsInThisWorkspace = HyprlandData.windowList.filter(w => w?.workspace?.id == workspaceId);
        return windowsInThisWorkspace.reduce((maxWin, win) => {
            const maxArea = (maxWin?.size?.[0] ?? 0) * (maxWin?.size?.[1] ?? 0);
            const winArea = (win?.size?.[0] ?? 0) * (win?.size?.[1] ?? 0);
            return winArea > maxArea ? win : maxWin;
        }, null);
    }

    Component.onCompleted: {
        updateAll();
        checkBlurVariantSupport();
    }

    Connections {
        target: Hyprland
        enabled: WM.compositor === "hyprland"

        function onRawEvent(event) {
            const name = event.name
            if (["openlayer", "closelayer"].includes(name)) {
                root.updateLayers()
                return
            }
            if (["screencast", "activelayout", "submap", "bell", "configreloaded"].includes(name)) {
                if (name === "configreloaded") root.updateAll()
                return
            }
            if (["openwindow", "closewindow", "movewindow", "movewindowv2"].includes(name)) {
                root.updateWindowList()
                root.updateWorkspaces()
                return
            }
            if (["activewindow", "activewindowv2", "windowtitle", "windowtitlev2",
                 "changefloatingmode", "fullscreen", "pin", "urgent"].includes(name)) {
                root.updateWindowList()
                // lastwindow, window count/title and fullscreen metadata can change.
                root.updateWorkspaces()
                return
            }
            if (["workspace", "workspacev2", "focusedmon", "focusedmonv2",
                 "moveworkspace", "moveworkspacev2", "renameworkspace",
                 "createworkspace", "createworkspacev2", "destroyworkspace",
                 "destroyworkspacev2", "activespecial", "activespecialv2"].includes(name)) {
                root.scheduleWorkspaceUpdate()
                return
            }
            // Keep a conservative fallback for compositor extensions/new events.
            root.scheduleUpdateAll()
        }
    }

    HyprlandSnapshot {
        socketPath: root.requestSocketPath
        id: getClients
        query: "clients"
        onSnapshot: clients => {
            const index = {}
            for (const win of clients) index[win.address] = win
            root.windowByAddress = index
            root.addresses = clients.map(win => win.address)
            root.windowList = clients
        }
    }
    HyprlandSnapshot {
        socketPath: root.requestSocketPath
        id: getMonitors
        query: "monitors"
        onSnapshot: value => { root.monitors = value }
    }
    HyprlandSnapshot {
        socketPath: root.requestSocketPath
        id: getLayers
        query: "layers"
        expectedType: "object"
        onSnapshot: value => { root.layers = value }
    }
    HyprlandSnapshot {
        socketPath: root.requestSocketPath
        id: getWorkspaces
        query: "workspaces"
        onSnapshot: value => {
            const workspaces = value.filter(ws => Number.isInteger(ws.id) && ws.id >= 1)
            const index = {}
            for (const ws of workspaces) index[ws.id] = ws
            root.workspaceById = index
            root.workspaceIds = workspaces.map(ws => ws.id)
            root.workspaces = workspaces
            root.workspacesReady = true
        }
    }
    HyprlandSnapshot {
        socketPath: root.requestSocketPath
        id: getActiveWorkspace
        query: "activeworkspace"
        expectedType: "object"
        onSnapshot: value => { root.activeWorkspace = value }
    }
}
