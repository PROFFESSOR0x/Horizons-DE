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
            // The inline launcher belongs to the island, but it must still be
            // available when the user opens it while the bar itself is closed.
            active: (GlobalStates.barOpen || GlobalStates.overviewOpen) && !GlobalStates.screenLocked
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
                // A launcher/notification/expanded island is meaningful content,
                // not an idle bar: it must reveal the island even while auto-hide
                // has tucked the idle pill against the screen edge.
                property bool mustShow: hoverRegion.containsMouse || superShow
                    || barContent.isLauncher || barContent.isNotification || barContent.isExpanded
                // Default remains a floating island. When requested, reserve
                // exactly the currently visible island height so clients are
                // pushed away from its screen edge instead of sitting beneath it.
                exclusionMode: ExclusionMode.Ignore
                readonly property bool reserveSpace: (Config.options.m3Island.reserveScreenSpace ?? false)
                    && !(Config?.options.bar.autoHide.enable && !mustShow)
                // Layer-shell compositors negotiate exclusive zones from the
                // panel's edge geometry. A stable bar-height zone is reliable
                // here; binding it to the morphing child can be ignored by
                // Hyprland after the first surface commit.
                exclusiveZone: reserveSpace ? Appearance.sizes.barHeight
                    + (Config.options.m3Island.cornerStyle === 1 ? Appearance.sizes.hyprlandGapsOut : 0) : 0
                // See Bar.qml for why this is gated behind a Wayland-only
                // Loader instead of set directly.
                Loader {
                    active: WM.isWayland
                    sourceComponent: Item {
                        Binding { target: barRoot.WlrLayershell; property: "namespace"; value: "quickshell:m3Island" }
                        Binding { target: barRoot.WlrLayershell; property: "layer"; value: WlrLayer.Top }
                    }
                }
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
                // Keep the two inverted edge corners tight. Using the global
                // screen radius here makes a short bottom island look overly
                // flat because the curves extend too far to either side.
                readonly property real hugCornerSize: Math.min(Appearance.rounding.screenRounding, 14)
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
                        implicitSize: barRoot.hugCornerSize
                        color: barRoot.hugColor
                        corner: Config.options.bar.bottom ? RoundCorner.CornerEnum.BottomRight : RoundCorner.CornerEnum.TopRight
                        x: barContent.x - implicitSize
                        y: Config.options.bar.bottom ? barContent.y + barContent.height - implicitSize : barContent.y
                    }
                    RoundCorner {
                        id: rightHugCorner
                        visible: barRoot.isHug && barContent.visible && Config.options.m3Island.showBackground
                        implicitSize: barRoot.hugCornerSize
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
                        // Auto-hide is deliberately a full edge transition: the
                        // island travels beyond the edge, scales slightly into
                        // it, then returns with a clear decelerating reveal.
                        readonly property bool autoHidden: Config?.options.bar.autoHide.enable && !mustShow
                        property real hiddenOffset: -height - 28
                        anchors.topMargin: autoHidden ? hiddenOffset : 0
                        opacity: (autoHidden ? 0 : 1) * launcherEntryOpacity
                        scale: (autoHidden ? 0.82 : 1) * launcherEntryScale
                        transformOrigin: Config.options.bar.bottom ? Item.Bottom : Item.Top
                        Behavior on anchors.topMargin {
                            NumberAnimation {
                                duration: mustShow ? 360 : 240
                                easing.type: Easing.BezierSpline
                                easing.bezierCurve: mustShow ? Appearance.animationCurves.emphasizedDecel : Appearance.animationCurves.emphasizedAccel
                                alwaysRunToEnd: true
                            }
                        }
                        Behavior on opacity {
                            NumberAnimation {
                                duration: mustShow ? 280 : 180
                                easing.type: Easing.BezierSpline
                                easing.bezierCurve: mustShow ? Appearance.animationCurves.emphasizedDecel : Appearance.animationCurves.emphasizedAccel
                            }
                        }
                        Behavior on scale {
                            NumberAnimation {
                                duration: mustShow ? 360 : 220
                                easing.type: Easing.BezierSpline
                                easing.bezierCurve: mustShow ? Appearance.animationCurves.expressiveDefaultSpatial : Appearance.animationCurves.emphasizedAccel
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

                    AutoHideRevealRegion {
                        id: hoverMaskRegion
                        barItem: barContent
                        edgeAtEnd: Config.options.bar.bottom
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
        // Forwarded to every screen's M3IslandContent via M3IslandState, since
        // the actual expand/collapse and notification state lives per-screen
        // inside the LazyLoader below, not here at the Scope level.
        function expand(): void { M3IslandState.requestExpand() }
        function collapse(): void { M3IslandState.requestCollapse() }
        function toggleExpand(): void { M3IslandState.requestToggleExpand() }
        function dismissNotification(): void { M3IslandState.requestDismissNotification() }
    }
}
