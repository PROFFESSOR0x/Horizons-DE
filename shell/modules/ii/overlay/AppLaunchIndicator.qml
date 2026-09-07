import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets

Scope {
    id: root

    PanelWindow {
        id: indicatorWindow
        screen: Quickshell.screens.find(screen =>
            screen.name === AppLaunchService.targetScreenName)
            ?? Quickshell.screens[0]
            readonly property var monitor: WM.monitorFor(screen)
            readonly property real monitorScale: monitor?.scale ?? 1
            readonly property var targetRect: AppLaunchService.targetRect
            visible: AppLaunchService.active
            color: "transparent"
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: Config.options.appLaunch.aboveWindows
                ? WlrLayer.Overlay : WlrLayer.Top
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
            anchors { top: true; bottom: true; left: true; right: true }

            Rectangle {
                id: card
                x: indicatorWindow.targetRect
                    ? (indicatorWindow.targetRect.x - (indicatorWindow.monitor?.x ?? 0)) / indicatorWindow.monitorScale
                        + (indicatorWindow.targetRect.width / indicatorWindow.monitorScale - width) / 2
                    : (parent.width - width) / 2
                y: indicatorWindow.targetRect
                    ? (indicatorWindow.targetRect.y - (indicatorWindow.monitor?.y ?? 0)) / indicatorWindow.monitorScale
                        + (indicatorWindow.targetRect.height / indicatorWindow.monitorScale - height) / 2
                    : (parent.height - height) / 2
                width: 220
                height: 206
                radius: Appearance.rounding.windowRounding
                color: Appearance.colors.colLayer0
                border.width: 1
                border.color: Appearance.colors.colLayer0Border
                layer.enabled: true

                StyledRectangularShadow {
                    target: card
                    visible: indicatorWindow.visible
                }

                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 20

                    IconImage {
                        Layout.alignment: Qt.AlignHCenter
                        source: Quickshell.iconPath(AppLaunchService.iconName, "application-x-executable")
                        implicitSize: 68
                    }

                    Rectangle {
                        Layout.alignment: Qt.AlignHCenter
                        width: 140
                        height: 4
                        radius: 2
                        color: Appearance.colors.colOutlineVariant

                        Rectangle {
                            width: parent.width * AppLaunchService.progress
                            height: parent.height
                            radius: parent.radius
                            color: Appearance.colors.colPrimary
                            Behavior on width {
                                NumberAnimation { duration: 100; easing.type: Easing.OutCubic }
                            }
                        }
                    }

                    StyledText {
                        Layout.alignment: Qt.AlignHCenter
                        Layout.maximumWidth: 180
                        text: AppLaunchService.appName
                        color: Appearance.colors.colOnLayer0
                        font.pixelSize: Appearance.font.pixelSize.small
                        elide: Text.ElideRight
                    }
                }
            }
    }
}
