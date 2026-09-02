import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.UPower
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions

Item {
    id: root
    property bool borderless: Config.options.bar.borderless
    property bool showDate: Config.options.bar.verbose
    property bool vertical: Config.options.bar.vertical
    property bool isMaterial: Config.options.bar.cornerStyle === 3

    implicitWidth: root.vertical ? 32 : flow.implicitWidth + 4
    implicitHeight: root.vertical ? flow.implicitHeight + 4 : 32

    MouseArea {
        id: interaction
        anchors.fill: parent
        hoverEnabled: Config.options.bar.systemIconsHover.enable
        onPressed: {
            GlobalStates.sidebarRightOpen = !GlobalStates.sidebarRightOpen;
        }
    }

    StyledPopup {
        hoverTarget: interaction
        popupBackgroundMargin: 4

        ColumnLayout {
            implicitWidth: 280
            implicitHeight: content.implicitHeight
            spacing: 7

            RowLayout {
                Layout.fillWidth: true
                MaterialSymbol {
                    text: Config.options.bar.systemIconsHover.content === "notifications" ? "notifications" : "info"
                    iconSize: Appearance.font.pixelSize.normal
                    color: Appearance.colors.colPrimary
                }
                StyledText {
                    Layout.fillWidth: true
                    font.weight: Font.Medium
                    text: Config.options.bar.systemIconsHover.content === "notifications"
                        ? Translation.tr("Recent notifications") : Translation.tr("System status")
                }
                StyledText {
                    visible: Config.options.bar.systemIconsHover.content === "notifications"
                    color: Appearance.colors.colSubtext
                    text: Notifications.unread > 0 ? Notifications.unread : ""
                }
            }

            ColumnLayout {
                id: content
                Layout.fillWidth: true
                spacing: 4
                Repeater {
                    model: {
                        if (Config.options.bar.systemIconsHover.content !== "notifications") return []
                        return Notifications.list.slice(-Config.options.bar.systemIconsHover.recentLimit).reverse()
                    }
                    delegate: StyledText {
                        required property var modelData
                        Layout.fillWidth: true
                        maximumLineCount: 1
                        elide: Text.ElideRight
                        color: Appearance.colors.colSubtext
                        text: (modelData.appName ? modelData.appName + " · " : "")
                            + (modelData.summary || modelData.body || Translation.tr("Notification"))
                    }
                }
                StyledText {
                    Layout.fillWidth: true
                    visible: Config.options.bar.systemIconsHover.content === "notifications" && Notifications.list.length === 0
                    color: Appearance.colors.colSubtext
                    text: Translation.tr("No recent notifications")
                }
                StyledText {
                    Layout.fillWidth: true
                    visible: Config.options.bar.systemIconsHover.content === "status"
                    color: Appearance.colors.colSubtext
                    text: Network.networkName || Translation.tr("No network connection")
                }
            }
        }
    }

    Flow {
        id: flow
        anchors.centerIn: parent
        flow: root.vertical ? Flow.TopToBottom : Flow.LeftToRight
        spacing: isMaterial ? 2 : root.vertical ? 6 : 10

        Revealer {
            reveal: true
            MaterialSymbol {
                text: Audio.sink?.audio?.muted ? "volume_off" : "volume_up"
                iconSize: Appearance.font.pixelSize.larger
                color: root.isMaterial ? Appearance.colors.colOnPrimary : Appearance.colors.colOnLayer1
            }
        }
        Revealer {
            reveal: Audio.source?.audio?.muted ?? false
            MaterialSymbol {
                text: "mic_off"
                iconSize: Appearance.font.pixelSize.larger
                color: root.isMaterial ? Appearance.colors.colOnPrimary : Appearance.colors.colOnLayer1
            }
        }
        // HyprlandXkbIndicator removed from SystemIcons - now standalone via BarContent.withAutoXkb (before systemIcons)
        MaterialSymbol {
            text: Network.materialSymbol
            iconSize: Appearance.font.pixelSize.larger
            color: root.isMaterial ? Appearance.colors.colOnPrimary : Appearance.colors.colOnLayer1
        }
        MaterialSymbol {
            visible: BluetoothStatus.available
            text: BluetoothStatus.connected ? "bluetooth_connected" : BluetoothStatus.enabled ? "bluetooth" : "bluetooth_disabled"
            iconSize: Appearance.font.pixelSize.larger
            color: root.isMaterial ? Appearance.colors.colOnPrimary : Appearance.colors.colOnLayer1
        }
        Loader {
            id: notifLoader
            active: Notifications.silent || Notifications.unread > 0
            visible: active
            width: active ? item?.implicitWidth ?? 0 : 0
            height: active ? item?.implicitHeight ?? 0 : 0
            source: "NotificationUnreadCount.qml"
        }
    }
}
