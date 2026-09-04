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
    id: bar

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
                    onTriggered: {
                        barRoot.superShow = true
                    }
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
                property bool mustShow: hoverRegion.containsMouse || superShow
                exclusionMode: ExclusionMode.Ignore
                exclusiveZone: (Config?.options.bar.autoHide.enable && (!mustShow || !Config?.options.bar.autoHide.pushWindows)) ? 0 : Appearance.sizes.barHeight + (Config.options.bar.cornerStyle === 1 ? Appearance.sizes.hyprlandGapsOut : 0)
                // See Bar.qml for why this is gated behind a Wayland-only
                // Loader instead of set directly.
                Loader {
                    active: WM.isWayland
                    sourceComponent: Item {
                        Binding { target: barRoot.WlrLayershell; property: "namespace"; value: "quickshell:quickactionsbar" }
                        Binding { target: barRoot.WlrLayershell; property: "layer"; value: WlrLayer.Top }
                    }
                }
                implicitHeight: Appearance.sizes.barHeight + Appearance.rounding.screenRounding
                color: "transparent"

                anchors {
                    top: !Config.options.bar.bottom
                    bottom: Config.options.bar.bottom
                    left: true
                    right: true
                }

                margins {
                    top: Config.options.bar.cornerStyle === 1 ? Appearance.sizes.hyprlandGapsOut : 0
                    bottom: Config.options.bar.cornerStyle === 1 ? Appearance.sizes.hyprlandGapsOut : 0
                }

                Component.onCompleted: {
                    GlobalFocusGrab.addPersistent(barRoot);
                }
                Component.onDestruction: {
                    GlobalFocusGrab.removePersistent(barRoot);
                }

                MouseArea {
                    id: hoverRegion
                    hoverEnabled: true
                    anchors.fill: parent

                    AutoHideRevealRegion {
                        id: hoverMaskRegion
                        barItem: barContent
                        edgeAtEnd: Config.options.bar.bottom
                    }

                    QuickActionsBarContent {
                        id: barContent

                        implicitHeight: Appearance.sizes.barHeight
                        anchors {
                            horizontalCenter: parent.horizontalCenter
                            top: parent.top
                            bottom: undefined
                            topMargin: (Config?.options.bar.autoHide.enable && !mustShow) ? -barContent.height : 0
                        }
                        Behavior on anchors.topMargin {
                            animation: Appearance.animation.elementMove.numberAnimation.createObject(this)
                        }
                        Behavior on anchors.bottomMargin {
                            animation: Appearance.animation.elementMove.numberAnimation.createObject(this)
                        }

                        states: State {
                            name: "bottom"
                            when: Config.options.bar.bottom
                            AnchorChanges {
                                target: barContent
                                anchors {
                                    top: undefined
                                    bottom: parent.bottom
                                }
                            }
                            PropertyChanges {
                                target: barContent
                                anchors.topMargin: 0
                                anchors.bottomMargin: (Config?.options.bar.autoHide.enable && !mustShow) ? -barContent.height : 0
                            }
                        }
                    }
                }
            }
        }
    }

    IpcHandler {
        target: "quickActionsBar"

        function toggle(): void {
            GlobalStates.barOpen = !GlobalStates.barOpen
        }

        function close(): void {
            GlobalStates.barOpen = false
        }

        function open(): void {
            GlobalStates.barOpen = true
        }
    }
}
