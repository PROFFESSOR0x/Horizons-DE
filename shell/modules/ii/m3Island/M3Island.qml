pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets

Scope {
    id: root
    property bool showBarBackground: Config.options.m3Island.showBackground

    Variants {
        model: {
            const screens = Quickshell.screens;
            const list = Config.options.bar.screenList;
            if (!list || list.length === 0)
                return screens;
            return screens.filter(screen => list.includes(screen.name));
        }
        LazyLoader {
            id: barLoader
            active: GlobalStates.barOpen && !GlobalStates.screenLocked
            required property ShellScreen modelData
            component: PanelWindow {
                id: barRoot
                screen: barLoader.modelData

                Timer {
                    id: showBarTimer
                    interval: (Config?.options.bar.autoHide.showWhenPressingSuper.delay ?? 100)
                    repeat: false
                    onTriggered: barRoot.superShow = true
                }
                Connections {
                    target: GlobalStates
                    function onSuperDownChanged() {
                        if (!Config?.options.bar.autoHide.showWhenPressingSuper.enable) return;
                        if (GlobalStates.superDown) showBarTimer.restart();
                        else {
                            showBarTimer.stop();
                            barRoot.superShow = false;
                        }
                    }
                }

                property bool superShow: false
                // For m3Island launcher is separate overlay, but bar still respects hover/super
                property bool mustShow: hoverRegion.containsMouse || superShow
                // Always hug+float -> no exclusive zone push, window is transparent full-width but content is centered pill
                exclusionMode: ExclusionMode.Ignore
                exclusiveZone: 0
                WlrLayershell.namespace: "quickshell:m3Island"
                WlrLayershell.layer: WlrLayer.Top
                // Fixed window to avoid per-frame layer-shell resize - content morphs inside
                implicitHeight: 520
                color: "transparent"
                mask: Region { item: hoverMaskRegion }

                anchors {
                    top: !Config.options.bar.bottom
                    bottom: Config.options.bar.bottom
                    left: true
                    right: true
                }
                // The launcher can deliberately float even when the idle island hugs the edge.
                readonly property bool isHug: Config.options.m3Island.cornerStyle === 0
                    && (!barContent.isLauncher || Config.options.m3Island.launcherHug)
                readonly property color hugColor: Config.options.m3Island.showBackground
                    ? (barContent.isLauncher ? Appearance.colors.colBackgroundSurfaceContainer : Appearance.colors.colLayer0)
                    : "transparent"

                margins {
                    top: barRoot.isHug ? 0 : (Config.options.m3Island.cornerStyle === 1 ? Appearance.sizes.hyprlandGapsOut : 0)
                    bottom: barRoot.isHug ? 0 : (Config.options.m3Island.cornerStyle === 1 ? Appearance.sizes.hyprlandGapsOut : 0)
                }

                Component.onCompleted: GlobalFocusGrab.addPersistent(barRoot)
                Component.onDestruction: GlobalFocusGrab.removePersistent(barRoot)

                MouseArea {
                    id: hoverRegion
                    hoverEnabled: true
                    anchors.fill: parent

                    // Hug inverted corners - makes island look emerging from screen edge
                    RoundCorner {
                        id: leftHugCorner
                        visible: barRoot.isHug && barContent.visible && Config.options.m3Island.showBackground
                        implicitSize: Appearance.rounding.screenRounding
                        color: barRoot.hugColor
                        corner: Config.options.bar.bottom ? RoundCorner.CornerEnum.BottomRight : RoundCorner.CornerEnum.TopRight
                        x: barContent.x - implicitSize
                        y: Config.options.bar.bottom ? barContent.y + barContent.height - implicitSize : barContent.y
                    }
                    RoundCorner {
                        id: rightHugCorner
                        visible: barRoot.isHug && barContent.visible && Config.options.m3Island.showBackground
                        implicitSize: Appearance.rounding.screenRounding
                        color: barRoot.hugColor
                        corner: Config.options.bar.bottom ? RoundCorner.CornerEnum.BottomLeft : RoundCorner.CornerEnum.TopLeft
                        x: barContent.x + barContent.width
                        y: Config.options.bar.bottom ? barContent.y + barContent.height - implicitSize : barContent.y
                    }

                    M3IslandContent {
                        id: barContent
                        screen: barLoader.modelData
                        mustShow: barRoot.mustShow
                        panelWindow: barRoot
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.top: parent.top
                        anchors.bottom: undefined
                        // autoHide slide - faster response
                        property real hiddenOffset: -Appearance.sizes.barHeight - 12
                        anchors.topMargin: (Config?.options.bar.autoHide.enable && !mustShow) ? hiddenOffset : 0
                        Behavior on anchors.topMargin {
                            NumberAnimation {
                                duration: mustShow ? 180 : 140
                                easing.type: Easing.BezierSpline
                                easing.bezierCurve: mustShow ? Appearance.animationCurves.emphasizedDecel : Appearance.animationCurves.emphasizedAccel
                                alwaysRunToEnd: true
                            }
                        }
                        Behavior on opacity {
                            NumberAnimation {
                                duration: mustShow ? 180 : 120
                                easing.type: Easing.OutCubic
                            }
                        }

                        states: State {
                            name: "bottom"
                            when: Config.options.bar.bottom
                            AnchorChanges {
                                target: barContent
                                anchors { top: undefined; bottom: parent.bottom }
                            }
                            PropertyChanges { target: barContent; anchors.topMargin: 0; anchors.bottomMargin: (Config?.options.bar.autoHide.enable && !mustShow) ? barContent.hiddenOffset : 0 }
                        }
                    }

                    Item {
                        id: hoverMaskRegion
                        anchors.fill: barContent
                        anchors.topMargin: -Config.options.bar.autoHide.hoverRegionWidth
                        anchors.bottomMargin: -Config.options.bar.autoHide.hoverRegionWidth
                    }
                }
            }
        }
    }

    IpcHandler {
        target: "m3Island"
        function toggle(): void { GlobalStates.barOpen = !GlobalStates.barOpen }
        function close(): void { GlobalStates.barOpen = false }
        function open(): void { GlobalStates.barOpen = true }
    }
}
