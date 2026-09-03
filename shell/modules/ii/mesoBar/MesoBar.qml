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

// "Mesobar" ("meso-" = Greek mesos, "middle") — a real, medium-width bar that
// floats as a rounded/pill-cornered panel spanning a configurable percentage
// of the screen width (Config.options.mesoBar.widthPercent), rather than
// either the edge-to-edge classic Bar or a pure content-hugging pill. See
// Config.qml's Config.options.mesoBar block for the naming rationale and the
// backward-compat shim for configs saved under its old name, "topIsland".
Scope {
    id: bar
    property bool showBarBackground: Config.options.bar.showBackground

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
                // Ported from Bar.qml: fullscreen+special-workspace detection, used
                // both to promote the layer above fullscreen windows (so the bar
                // isn't buried under a fullscreen app peeking at a special
                // workspace) and to carve the shared screen-corner click zones out
                // of this window's own hit region (see `mask` below).
                property var thisMonitorData: HyprlandData.monitors.find(m => m.name === barRoot.screen?.name)
                property bool monitorHasFullscreen: HyprlandData.workspaceById[thisMonitorData?.activeWorkspace?.id]?.hasfullscreen ?? false
                property bool monitorHasSpecialOpen: (thisMonitorData?.specialWorkspace?.name ?? "") !== ""
                exclusionMode: ExclusionMode.Ignore
                exclusiveZone: (Config?.options.bar.autoHide.enable && (!mustShow || !Config?.options.bar.autoHide.pushWindows)) ? 0 : Appearance.sizes.barHeight + (Config.options.mesoBar.cornerStyle === 1 ? Appearance.sizes.hyprlandGapsOut : 0)
                WlrLayershell.namespace: "quickshell:mesobar"
                // Overlay layer only while special workspace sits on top of a fullscreen window on this monitor,
                // else Top layer so fullscreen apps cover the bar as normal (mirrors Bar.qml's rule).
                WlrLayershell.layer: (monitorHasFullscreen && monitorHasSpecialOpen) ? WlrLayer.Overlay : WlrLayer.Top
                implicitHeight: Appearance.sizes.barHeight + Appearance.rounding.screenRounding
                // See Bar.qml for why this cutout exists: on the Overlay layer this
                // window shares a layer with ScreenCorners.qml's click zones, and
                // same-layer overlap is resolved by stacking order rather than layer
                // priority - this window's own strip was winning and swallowing the
                // tiny corner-open hit rects. Subtract them from its mask so clicks
                // reach the corners underneath. Only relevant on the edge shared with
                // the corner zones.
                property bool cutOutCornerOpenZones: (monitorHasFullscreen && monitorHasSpecialOpen) && (Config.options.bar.bottom === Config.options.sidebar.cornerOpen.bottom)
                property int cornerOpenCutWidth: cutOutCornerOpenZones ? Config.options.sidebar.cornerOpen.cornerRegionWidth : 0
                property int cornerOpenCutHeight: cutOutCornerOpenZones ? Config.options.sidebar.cornerOpen.cornerRegionHeight : 0
                mask: Region {
                    item: hoverMaskRegion
                    Region {
                        intersection: Intersection.Subtract
                        x: 0
                        y: Config.options.bar.bottom ? (barRoot.height - barRoot.cornerOpenCutHeight) : 0
                        width: barRoot.cornerOpenCutWidth
                        height: barRoot.cornerOpenCutHeight
                    }
                    Region {
                        intersection: Intersection.Subtract
                        x: barRoot.width - barRoot.cornerOpenCutWidth
                        y: Config.options.bar.bottom ? (barRoot.height - barRoot.cornerOpenCutHeight) : 0
                        width: barRoot.cornerOpenCutWidth
                        height: barRoot.cornerOpenCutHeight
                    }
                }
                color: "transparent"

                anchors {
                    top: !Config.options.bar.bottom
                    bottom: Config.options.bar.bottom
                    left: true
                    right: true
                }

                margins {
                    top: Config.options.mesoBar.cornerStyle === 3 ? 5 : 0
                    bottom: Config.options.mesoBar.cornerStyle === 3 ? 5 : 0
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

                    MesoBarContent {
                        id: barContent
                        screenWidth: barRoot.width

                        implicitHeight: Appearance.sizes.barHeight
                        anchors {
                            horizontalCenter: parent.horizontalCenter
                            top: parent.top
                            bottom: undefined
                            topMargin: (Config?.options.bar.autoHide.enable && !mustShow) ? -barContent.height : 0
                        }
                        Behavior on anchors.topMargin {
                            NumberAnimation { duration: mustShow ? 180 : 140; easing.type: Easing.BezierSpline; easing.bezierCurve: mustShow ? Appearance.animationCurves.emphasizedDecel : Appearance.animationCurves.emphasizedAccel; alwaysRunToEnd: true }
                        }
                        Behavior on anchors.bottomMargin {
                            NumberAnimation { duration: mustShow ? 180 : 140; easing.type: Easing.BezierSpline; easing.bezierCurve: mustShow ? Appearance.animationCurves.emphasizedDecel : Appearance.animationCurves.emphasizedAccel; alwaysRunToEnd: true }
                        }
                        Behavior on opacity {
                            NumberAnimation { duration: mustShow ? 180 : 120; easing.type: Easing.OutCubic }
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
        target: "mesoBar"

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
