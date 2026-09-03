pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Io
import QtQuick
import qs.modules.common
import qs.services

/**
 * Wi-Fi hotspot via nmcli, following the same Process pattern as
 * Network.qml. Creates/tears down a connection profile named "Hotspot" on
 * the first available Wi-Fi device.
 */
Singleton {
    id: root

    readonly property string connectionName: "Hotspot"

    property bool nmcliAvailable: false
    readonly property bool available: root.nmcliAvailable
    readonly property string unavailableReason: "nmcli not found"

    property bool active: false
    property string wifiInterface: ""

    readonly property string ssid: Config.options.quickActionsBar.hotspotSsid.length > 0
        ? Config.options.quickActionsBar.hotspotSsid
        : root._defaultSsid()
    readonly property string password: Config.options.quickActionsBar.hotspotPassword.length > 0
        ? Config.options.quickActionsBar.hotspotPassword
        : root._defaultPassword()

    function _defaultSsid() {
        const host = SystemInfo.hostname && SystemInfo.hostname.length > 0 ? SystemInfo.hostname : "shell";
        return `${host}-hotspot`;
    }

    // Deterministic per-machine default so it doesn't change every call
    // before the user has saved anything, but isn't a hardcoded secret either.
    function _defaultPassword() {
        const seed = `${SystemInfo.hostname}-hotspot-seed`;
        let hash = 0;
        for (let i = 0; i < seed.length; i++) {
            hash = (hash * 31 + seed.charCodeAt(i)) >>> 0;
        }
        return `hs${hash.toString(36)}`.slice(0, 12).padEnd(8, "0");
    }

    function ensureConfigDefaults() {
        if (Config.options.quickActionsBar.hotspotSsid.length === 0)
            Config.options.quickActionsBar.hotspotSsid = root._defaultSsid();
        if (Config.options.quickActionsBar.hotspotPassword.length === 0)
            Config.options.quickActionsBar.hotspotPassword = root._defaultPassword();
    }

    function refresh() {
        if (!root.available) return;
        activeCheckProc.running = false;
        activeCheckProc.running = true;
        if (root.wifiInterface.length === 0) {
            deviceProc.running = false;
            deviceProc.running = true;
        }
    }

    function toggle() {
        if (!root.available) return;
        if (root.active) root.stop(); else root.start();
    }

    function start() {
        if (!root.available || root.active || root.wifiInterface.length === 0) return;
        root.ensureConfigDefaults();
        startProc.command = ["nmcli", "device", "wifi", "hotspot",
            "ifname", root.wifiInterface,
            "ssid", root.ssid,
            "password", root.password];
        startProc.running = true;
    }

    function stop() {
        if (!root.active) return;
        stopProc.running = true;
    }

    Process {
        id: checkNmcli
        running: true
        command: ["sh", "-c", "command -v nmcli"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.nmcliAvailable = text.trim().length > 0;
                if (root.nmcliAvailable) root.refresh();
            }
        }
    }

    Process {
        id: deviceProc
        command: ["sh", "-c", "nmcli -t -f DEVICE,TYPE device status | awk -F: '$2==\"wifi\"{print $1; exit}'"]
        stdout: StdioCollector {
            onStreamFinished: root.wifiInterface = text.trim()
        }
    }

    Process {
        id: activeCheckProc
        command: ["sh", "-c", `nmcli -t -f NAME connection show --active | grep -Fx "${root.connectionName}"`]
        stdout: StdioCollector {
            onStreamFinished: root.active = text.trim().length > 0
        }
    }

    Process {
        id: startProc
        onExited: root.refresh()
    }

    Process {
        id: stopProc
        command: ["nmcli", "connection", "down", root.connectionName]
        onExited: {
            // Also remove the profile so a later start regenerates it cleanly
            // with whatever SSID/password are currently configured.
            deleteProc.running = true;
            root.refresh();
        }
    }

    Process {
        id: deleteProc
        command: ["nmcli", "connection", "delete", root.connectionName]
    }

    // Only QuickActionsBarContent.qml reads root.active, and it only exists
    // while barMode is "quickActionsBar" (see PanelLoader in
    // IllogicalImpulseFamily.qml). Polling nmcli every 5s for a value
    // nothing displays wastes two subprocess spawns; toggle()/refresh() still
    // update immediately on demand and after every user action either way.
    Timer {
        interval: 5000
        running: root.available && Config.options.bar.barMode === "quickActionsBar"
        repeat: true
        onTriggered: root.refresh()
    }
}
