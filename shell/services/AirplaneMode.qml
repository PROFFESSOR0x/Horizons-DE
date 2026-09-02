pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Io
import Quickshell.Bluetooth
import QtQuick
import qs.services

/**
 * Airplane mode: disables Wi-Fi (via nmcli, same mechanism as Network.qml)
 * and Bluetooth (via the same adapter.enabled property BluetoothStatus.qml
 * uses) together. Deliberately has no state of its own — "enabled" is
 * derived live from Network.wifiEnabled / BluetoothStatus.enabled so this
 * never disagrees with the Wi-Fi/Bluetooth quick toggles.
 */
Singleton {
    id: root

    property bool nmcliAvailable: false
    readonly property bool available: root.nmcliAvailable
    readonly property string unavailableReason: "nmcli not found"

    // On (radios off) only once both Wi-Fi and Bluetooth are confirmed off.
    readonly property bool enabled: !Network.wifiEnabled && !BluetoothStatus.enabled

    function toggle() {
        if (!root.available) return;
        setEnabled(!root.enabled);
    }

    function setEnabled(on) {
        if (!root.available) return;
        radioProc.command = ["nmcli", "radio", "all", on ? "off" : "on"];
        radioProc.running = true;

        const adapter = Bluetooth.defaultAdapter;
        if (adapter) adapter.enabled = !on;
    }

    Process {
        id: checkNmcli
        running: true
        command: ["sh", "-c", "command -v nmcli"]
        stdout: StdioCollector {
            onStreamFinished: root.nmcliAvailable = text.trim().length > 0
        }
    }

    Process {
        id: radioProc
    }
}
