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
    property var windowList: []
    property var addresses: []
    property var windowByAddress: ({})
    property var workspaces: []
    property var workspaceIds: []
    property var workspaceById: ({})
    property var activeWorkspace: null
    property var monitors: []
    property var layers: ({})

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
        if (!toplevel || !toplevel.HyprlandToplevel) {
            return null;
        }
        const address = `0x${toplevel?.HyprlandToplevel?.address}`;
        return root.windowByAddress[address];
    }

    // Internals

    function parseHyprctlJson(text, fallback, label) {
        try {
            return JSON.parse(text)
        } catch (error) {
            console.log("[HyprlandData] Failed to parse " + label + ": " + error)
            return fallback
        }
    }

    function updateWindowList() {
        if (WM.compositor !== "hyprland") return;
        getClients.running = true;
    }

    function updateLayers() {
        if (WM.compositor !== "hyprland") return;
        getLayers.running = true;
    }

    function updateMonitors() {
        if (WM.compositor !== "hyprland") return;
        getMonitors.running = true;
    }

    function updateWorkspaces() {
        if (WM.compositor !== "hyprland") return;
        getWorkspaces.running = true;
        getActiveWorkspace.running = true;
    }

    function updateAll() {
        if (WM.compositor !== "hyprland") return;
        updateWindowList();
        updateMonitors();
        updateLayers();
        updateWorkspaces();
    }

    // A single user action can produce a burst of raw events. Coalescing them
    // keeps the shell responsive instead of starting four hyprctl calls per event.
    function scheduleUpdateAll() {
        if (WM.compositor !== "hyprland") return;
        refreshDebounce.restart();
    }

    Timer {
        id: refreshDebounce
        interval: 80
        repeat: false
        onTriggered: root.updateAll()
    }

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
            if (["openlayer", "closelayer", "screencast"].includes(event.name)) return;
            scheduleUpdateAll()
        }
    }

    Process {
        id: getClients
        command: ["hyprctl", "clients", "-j"]
        stdout: StdioCollector {
            id: clientsCollector
            onStreamFinished: {
                const clients = root.parseHyprctlJson(clientsCollector.text, [], "clients")
                root.windowList = Array.isArray(clients) ? clients : []
                let tempWinByAddress = {};
                for (var i = 0; i < root.windowList.length; ++i) {
                    var win = root.windowList[i];
                    tempWinByAddress[win.address] = win;
                }
                root.windowByAddress = tempWinByAddress;
                root.addresses = root.windowList.map(win => win.address);
            }
        }
    }

    Process {
        id: getMonitors
        command: ["hyprctl", "monitors", "-j"]
        stdout: StdioCollector {
            id: monitorsCollector
            onStreamFinished: {
                const monitors = root.parseHyprctlJson(monitorsCollector.text, [], "monitors")
                root.monitors = Array.isArray(monitors) ? monitors : []
            }
        }
    }

    Process {
        id: getLayers
        command: ["hyprctl", "layers", "-j"]
        stdout: StdioCollector {
            id: layersCollector
            onStreamFinished: {
                const layers = root.parseHyprctlJson(layersCollector.text, {}, "layers")
                root.layers = layers && typeof layers === "object" ? layers : {}
            }
        }
    }

    Process {
        id: getWorkspaces
        command: ["hyprctl", "workspaces", "-j"]
        stdout: StdioCollector {
            id: workspacesCollector
            onStreamFinished: {
                const parsedWorkspaces = root.parseHyprctlJson(workspacesCollector.text, [], "workspaces")
                var rawWorkspaces = Array.isArray(parsedWorkspaces) ? parsedWorkspaces : []
                root.workspaces = rawWorkspaces.filter(ws => ws.id >= 1 && ws.id <= 100);
                let tempWorkspaceById = {};
                for (var i = 0; i < root.workspaces.length; ++i) {
                    var ws = root.workspaces[i];
                    tempWorkspaceById[ws.id] = ws;
                }
                root.workspaceById = tempWorkspaceById;
                root.workspaceIds = root.workspaces.map(ws => ws.id);
            }
        }
    }

    Process {
        id: getActiveWorkspace
        command: ["hyprctl", "activeworkspace", "-j"]
        stdout: StdioCollector {
            id: activeWorkspaceCollector
            onStreamFinished: {
                const workspace = root.parseHyprctlJson(activeWorkspaceCollector.text, null, "active workspace")
                root.activeWorkspace = workspace && typeof workspace === "object" ? workspace : null
            }
        }
    }
}
