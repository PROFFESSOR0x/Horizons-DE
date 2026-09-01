import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions

Item {
    id: root
    implicitHeight: 24
    width: parent.width

    Rectangle {
        id: barBackground
        anchors.fill: parent
        color: Config.options.bar.showBackground
            ? (Config.options.bar.followFrameColor
                ? Appearance.getColorFromName(Config.options.bar.frameColor)
                : Appearance.colors.colLayer0)
            : "transparent"
        radius: Config.options.bar.cornerStyle === 1 ? Appearance.rounding.windowRounding : 0
        border.width: Config.options.bar.cornerStyle === 1 ? 1 : 0
        border.color: Appearance.colors.colLayer0Border
    }

    // Click anywhere on strip → toggle right sidebar
    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: mouse => {
            if (mouse.button === Qt.RightButton)
                GlobalStates.sidebarLeftOpen = !GlobalStates.sidebarLeftOpen
            else
                GlobalStates.sidebarRightOpen = !GlobalStates.sidebarRightOpen
        }
        // Don't eat the event so child MouseAreas still work
        propagateComposedEvents: true
    }

    RowLayout {
        id: stripRow
        anchors {
            fill: barBackground
            leftMargin: 8
            rightMargin: 8
            topMargin: 2
            bottomMargin: 2
        }
        spacing: 8

        // ── Active window icon + title ────────────────────────────────────
        Loader {
            active: Config.options.infoStrip.showActiveWindow
            visible: active
            Layout.fillWidth: true
            sourceComponent: RowLayout {
                spacing: 4

                IconImage {
                    source: {
                        const id = ToplevelManager.activeToplevel?.appId ?? ""
                        if (!id) return ""
                        return Quickshell.iconPath(AppSearch.guessIcon(id), "image-missing")
                    }
                    implicitSize: 14
                    visible: source !== ""
                }

                StyledText {
                    Layout.fillWidth: true
                    text: ToplevelManager.activeToplevel?.title ?? ""
                    elide: Text.ElideRight
                    font.pixelSize: Appearance.font.pixelSize.small
                    color: Appearance.colors.colOnLayer1
                    opacity: 0.8
                }
            }
        }

        // Spacer when active window is hidden
        Item {
            Layout.fillWidth: true
            visible: !Config.options.infoStrip.showActiveWindow
        }

        // ── CPU usage ────────────────────────────────────────────────────
        Loader {
            active: Config.options.infoStrip.showCpuUsage
            visible: active
            sourceComponent: RowLayout {
                spacing: 2
                MaterialSymbol {
                    text: "memory"
                    iconSize: Appearance.font.pixelSize.small
                    color: Appearance.colors.colOnLayer1
                    opacity: 0.6
                }
                StyledText {
                    text: Math.round(ResourceUsage.cpuUsage) + "%"
                    font.pixelSize: Appearance.font.pixelSize.smallest
                    font.features: { "tnum": 1 }
                    color: Appearance.colors.colOnLayer1
                    opacity: 0.6
                }
            }
        }

        // ── RAM usage ────────────────────────────────────────────────────
        Loader {
            active: Config.options.infoStrip.showMemoryUsage
            visible: active
            sourceComponent: RowLayout {
                spacing: 2
                MaterialSymbol {
                    text: "planner_review"
                    iconSize: Appearance.font.pixelSize.small
                    color: Appearance.colors.colOnLayer1
                    opacity: 0.6
                }
                StyledText {
                    text: Math.round(ResourceUsage.memoryUsedPercentage * 100) + "%"
                    font.pixelSize: Appearance.font.pixelSize.smallest
                    font.features: { "tnum": 1 }
                    color: Appearance.colors.colOnLayer1
                    opacity: 0.6
                }
            }
        }

        // ── Notification dot ─────────────────────────────────────────────
        Loader {
            active: Config.options.infoStrip.showNotificationDot && Notifications.unread > 0
            visible: active
            sourceComponent: RowLayout {
                spacing: 3
                Rectangle {
                    width: 6; height: 6; radius: 3
                    color: Appearance.colors.colPrimary
                    Layout.alignment: Qt.AlignVCenter
                }
                StyledText {
                    visible: Notifications.unread > 0
                    text: Notifications.unread
                    font.pixelSize: Appearance.font.pixelSize.smallest
                    color: Appearance.colors.colPrimary
                }
            }
        }

        // ── Clock ────────────────────────────────────────────────────────
        Loader {
            active: Config.options.infoStrip.showClock
            visible: active
            sourceComponent: StyledText {
                text: DateTime.time
                font.pixelSize: Appearance.font.pixelSize.small
                font.features: { "tnum": 1 }
                color: Appearance.colors.colOnLayer1
            }
        }
    }
}
