import QtQuick

QtObject {
    required property var lastIpcObject
    readonly property string ssid: lastIpcObject.ssid
    readonly property string bssid: lastIpcObject.bssid
    readonly property int strength: lastIpcObject.strength
    readonly property int frequency: lastIpcObject.frequency
    readonly property bool active: lastIpcObject.active
    readonly property string security: lastIpcObject.security
    readonly property bool isSecure: security.length > 0
    // nmcli's SECURITY column reports enterprise (802.1x) networks as e.g. "WPA2 802.1X" /
    // "WPA3 802.1X", as opposed to personal networks ("WPA1 WPA2", "WPA3", "WEP", ...).
    readonly property bool isEnterprise: security.toUpperCase().includes("802.1X")

    property bool askingPassword: false
}
