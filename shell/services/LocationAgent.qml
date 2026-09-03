pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Io
import QtQuick
import qs.modules.common
import qs.modules.common.functions

/**
 * Location services toggle: starts/stops the GeoClue demo agent the dots
 * ship at ~/.config/hypr/hyprland/scripts/start_geoclue_agent.sh (normally
 * launched once at Hyprland startup). Reflects whether the agent process is
 * actually running, matched the same way the script itself checks
 * ("geoclue-2.0/demos/agent" in the process's cmdline).
 */
Singleton {
    id: root

    readonly property string agentMatchPattern: "geoclue-2.0/demos/agent"
    readonly property string scriptPath: FileUtils.trimFileProtocol(
        `${Directories.config}/hypr/hyprland/scripts/start_geoclue_agent.sh`)

    property bool scriptAvailable: false
    readonly property bool available: root.scriptAvailable
    readonly property string unavailableReason: "GeoClue agent script not found"

    property bool running: false

    function refresh() {
        checkRunning.running = false;
        checkRunning.running = true;
    }

    function toggle() {
        if (!root.available) return;
        if (root.running) root.stop(); else root.start();
    }

    function start() {
        if (!root.available || root.running) return;
        Quickshell.execDetached(["bash", root.scriptPath]);
        refreshTimer.restart();
    }

    function stop() {
        if (!root.running) return;
        Quickshell.execDetached(["pkill", "-f", root.agentMatchPattern]);
        refreshTimer.restart();
    }

    Process {
        id: checkAvailable
        running: true
        command: ["sh", "-c", `test -x "${root.scriptPath}" && echo yes || echo no`]
        stdout: StdioCollector {
            onStreamFinished: {
                root.scriptAvailable = text.trim() === "yes";
                if (root.scriptAvailable) root.refresh();
            }
        }
    }

    Process {
        id: checkRunning
        command: ["pgrep", "-f", root.agentMatchPattern]
        stdout: StdioCollector {
            onStreamFinished: root.running = text.trim().length > 0
        }
    }

    // Only QuickActionsBarContent.qml reads root.running, and it only exists
    // while barMode is "quickActionsBar" (see PanelLoader in
    // IllogicalImpulseFamily.qml). Polling pgrep every 5s for a value
    // nothing displays wastes a subprocess spawn; toggle()/refresh() still
    // update immediately on demand and after start()/stop() either way.
    Timer {
        interval: 5000
        running: root.available && Config.options.bar.barMode === "quickActionsBar"
        repeat: true
        onTriggered: root.refresh()
    }

    Timer {
        id: refreshTimer
        interval: 400
        repeat: false
        onTriggered: root.refresh()
    }
}
