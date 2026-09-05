pragma ComponentBehavior: Bound
import qs.modules.common
import qs.modules.common.widgets
import qs.services
import Quickshell
import QtQuick
import QtQuick.Layouts

// Shows only while an nmcli VPN/WireGuard connection is active (Network.qml's
// activeVpnConnections, refreshed on the same `nmcli monitor`-driven cycle
// everything else in that service already uses - no extra polling). Purely
// informational: opens nm-connection-editor on click for anyone who wants to
// actually disconnect, rather than guessing which nmcli command to run.
MouseArea {
    id: root
    property bool vertical: Config.options.bar.vertical
    property bool isMaterial: Config.options.bar.cornerStyle === 3

    readonly property bool active: Network.vpnActive
    readonly property string connectionsLabel: Network.activeVpnConnections.join(", ")

    visible: root.active
    implicitWidth: vertical ? Appearance.sizes.verticalBarWidth : (contentLoader.item?.implicitWidth ?? 0)
    implicitHeight: vertical ? (contentLoader.item?.implicitHeight ?? 0) : Appearance.sizes.barHeight

    cursorShape: Qt.PointingHandCursor
    onClicked: Quickshell.execDetached(["bash", "-c", "nm-connection-editor || nmtui"])

    StyledToolTip {
        text: root.connectionsLabel.length > 0
            ? Translation.tr("VPN connected: %1").arg(root.connectionsLabel)
            : Translation.tr("VPN connected")
    }

    Loader {
        id: contentLoader
        anchors.centerIn: parent
        sourceComponent: root.vertical ? colContent : rowContent
    }

    Component {
        id: rowContent
        RowLayout {
            spacing: 4
            MaterialSymbol {
                Layout.alignment: Qt.AlignVCenter
                text: "vpn_lock"
                fill: 1
                iconSize: Appearance.font.pixelSize.normal
                color: root.isMaterial ? Appearance.colors.colOnPrimaryContainer : Appearance.colors.colOnLayer1
            }
        }
    }

    Component {
        id: colContent
        ColumnLayout {
            spacing: 4
            MaterialSymbol {
                Layout.alignment: Qt.AlignHCenter
                text: "vpn_lock"
                fill: 1
                iconSize: Appearance.font.pixelSize.normal
                color: root.isMaterial ? Appearance.colors.colOnPrimaryContainer : Appearance.colors.colOnLayer1
            }
        }
    }
}
