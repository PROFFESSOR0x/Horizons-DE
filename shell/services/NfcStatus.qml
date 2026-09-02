pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Io
import QtQuick

/**
 * NFC toggle via rfkill. Most laptops/desktops have no NFC rfkill switch at
 * all, so this genuinely checks `rfkill list nfc` and reports unavailable
 * (rather than pretending to work) when nothing shows up.
 */
Singleton {
    id: root

    property bool rfkillAvailable: false
    property bool deviceFound: false
    readonly property bool available: root.rfkillAvailable && root.deviceFound
    readonly property string unavailableReason: !root.rfkillAvailable
        ? "rfkill not found"
        : "No NFC radio found"

    property bool enabled: false

    function refresh() {
        if (!root.rfkillAvailable) return;
        statusProc.running = false;
        statusProc.running = true;
    }

    function toggle() {
        if (!root.available) return;
        setEnabled(!root.enabled);
    }

    function setEnabled(on) {
        if (!root.available) return;
        toggleProc.command = ["rfkill", on ? "unblock" : "block", "nfc"];
        toggleProc.running = true;
    }

    Process {
        id: checkRfkill
        running: true
        command: ["sh", "-c", "command -v rfkill"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.rfkillAvailable = text.trim().length > 0;
                if (root.rfkillAvailable) root.refresh();
            }
        }
    }

    Process {
        id: statusProc
        command: ["sh", "-c", "rfkill list nfc"]
        stdout: StdioCollector {
            onStreamFinished: {
                const output = text.trim();
                root.deviceFound = output.length > 0;
                root.enabled = root.deviceFound && !/Soft blocked:\s*yes/i.test(output);
            }
        }
    }

    Process {
        id: toggleProc
        onExited: root.refresh()
    }

    Timer {
        interval: 5000
        running: root.rfkillAvailable
        repeat: true
        onTriggered: root.refresh()
    }
}
