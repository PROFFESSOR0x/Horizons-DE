pragma Singleton
import qs
import qs.modules.common
import qs.modules.common.functions
import QtQuick
import Quickshell
import Quickshell.Io

/*
 * System + Horizons-DE repo updates service. System package checking
 * currently only supports Arch; the repo check works anywhere the shell was
 * installed from a git clone (see scripts/horizons/check_update.sh).
 */
Singleton {
    id: root

    property bool available: false
    property alias checking: checkUpdatesProc.running
    // Raw counts, kept separate so the UI can explain what "count" is made
    // of (package upgrades vs. the shell/dotfiles repo being behind) instead
    // of a single opaque number.
    property int packageCount: 0
    property int horizonsBehindCount: 0
    readonly property int count: packageCount + horizonsBehindCount

    readonly property bool updateAdvised: available && count > Config.options.updates.adviseUpdateThreshold
    readonly property bool updateStronglyAdvised: available && count > Config.options.updates.stronglyAdviseUpdateThreshold

    function load() {}
    function refresh() {
        if (available) {
            print("[Updates] Checking for system updates")
            checkUpdatesProc.running = true;
        }
        print("[Updates] Checking for a Horizons-DE repo update")
        checkHorizonsProc.running = true;
    }

    Timer {
        interval: Config.options.updates.checkInterval * 60 * 1000
        repeat: true
        running: Config.ready && Config.options.updates.enableCheck
        onTriggered: {
            print("[Updates] Periodic update check due")
            root.refresh();
        }
    }

    Process {
        id: checkAvailabilityProc
        running: Config.ready && Config.options.updates.enableCheck
        command: ["which", "checkupdates"]
        onExited: (exitCode, exitStatus) => {
            root.available = (exitCode === 0);
            root.refresh();
        }
    }

    Process {
        id: checkUpdatesProc
        command: ["bash", "-c", "pacman=$(checkupdates 2>/dev/null | wc -l); aur=$(yay -Qua 2>/dev/null | wc -l || paru -Qua 2>/dev/null | wc -l || echo 0); echo $((pacman + aur))"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.packageCount = parseInt(text.trim()) || 0
            }
        }
    }

    Process {
        id: checkHorizonsProc
        command: ["bash", `${FileUtils.trimFileProtocol(Directories.scriptPath)}/horizons/check_update.sh`]
        stdout: StdioCollector {
            onStreamFinished: {
                root.horizonsBehindCount = parseInt(text.trim()) || 0
            }
        }
    }
}
