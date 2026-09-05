import qs
import qs.modules.common
import qs.modules.common.widgets
import qs.services
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland

Scope {
    id: screenCorners
    readonly property Toplevel activeWindow: ToplevelManager.activeToplevel

    property var actionForCorner: ({
        [RoundCorner.CornerEnum.TopLeft]: Config.options.sidebar.cornerOpen.topLeftAction,
        [RoundCorner.CornerEnum.BottomLeft]: Config.options.sidebar.cornerOpen.bottomLeftAction,
        [RoundCorner.CornerEnum.TopRight]: Config.options.sidebar.cornerOpen.topRightAction,
        [RoundCorner.CornerEnum.BottomRight]: Config.options.sidebar.cornerOpen.bottomRightAction
    })

    function triggerCornerAction(corner, fromHover) {
        const action = actionForCorner[corner];
        if (fromHover)
            GlobalStates.openFromHover(action);
        else
            GlobalStates.toggleState(action);
    }

    component CornerPanelWindow: PanelWindow {
        id: cornerPanelWindow
        property var brightnessMonitor: Brightness.getMonitorForScreen(screen)
        property bool fullscreen
        // Decorative rounding and the hover-to-open-sidebar corner zone are independent
        // features that happen to share this window. Only the decoration should be gated
        // by fakeScreenRounding; the hover zone must stay alive whenever cornerOpen.enable
        // is on, regardless of the decoration setting, or the window (and the MouseArea it
        // hosts) never gets mapped and hovering the corner does nothing.
        readonly property bool showRounding: (Config.options.appearance.fakeScreenRounding === 1 || (Config.options.appearance.fakeScreenRounding === 2 && !fullscreen))
        readonly property bool hoverZoneEnabled: Config.options.sidebar.cornerOpen.enable && !fullscreen
        visible: showRounding || hoverZoneEnabled
        property var corner

        exclusionMode: ExclusionMode.Ignore
        mask: Region {
            item: sidebarCornerOpenInteractionLoader.active ? sidebarCornerOpenInteractionLoader : null
        }
        // See Bar.qml (shell/modules/ii/bar/Bar.qml) for why this is gated
        // behind a Wayland-only Loader instead of set directly.
        Loader {
            active: WM.isWayland
            sourceComponent: Item {
                Binding { target: cornerPanelWindow.WlrLayershell; property: "namespace"; value: "quickshell:screenCorners" }
                Binding { target: cornerPanelWindow.WlrLayershell; property: "layer"; value: WlrLayer.Overlay }
            }
        }
        color: "transparent"

        anchors {
            top: cornerWidget.isTopLeft || cornerWidget.isTopRight
            left: cornerWidget.isBottomLeft || cornerWidget.isTopLeft
            bottom: cornerWidget.isBottomLeft || cornerWidget.isBottomRight
            right: cornerWidget.isTopRight || cornerWidget.isBottomRight
        }
        margins {
            right: (Config.options.interactions.deadPixelWorkaround.enable && cornerPanelWindow.anchors.right) * -1
            bottom: (Config.options.interactions.deadPixelWorkaround.enable && cornerPanelWindow.anchors.bottom) * -1
        }

        implicitWidth: cornerWidget.implicitWidth
        implicitHeight: cornerWidget.implicitHeight

        RoundCorner {
            id: cornerWidget
            anchors.fill: parent
            corner: cornerPanelWindow.corner
            // Only paint the decorative corner fill when the decoration itself is
            // wanted; the window may still be mapped purely to host the hover zone.
            showFill: cornerPanelWindow.showRounding
            rightVisualMargin: (Config.options.interactions.deadPixelWorkaround.enable && cornerPanelWindow.anchors.right) * 1
            bottomVisualMargin: (Config.options.interactions.deadPixelWorkaround.enable && cornerPanelWindow.anchors.bottom) * 1

            implicitSize: Appearance.rounding.screenRounding
            implicitHeight: Math.max(implicitSize, sidebarCornerOpenInteractionLoader.implicitHeight)
            implicitWidth: Math.max(implicitSize, sidebarCornerOpenInteractionLoader.implicitWidth)

            Loader {
                id: sidebarCornerOpenInteractionLoader
                active: {
                    if (!Config.options.sidebar.cornerOpen.enable) return false;
                    if (cornerPanelWindow.fullscreen) return false;
                    return true;
                }
                anchors {
                    top: (cornerWidget.isTopLeft || cornerWidget.isTopRight) ? parent.top : undefined
                    bottom: (cornerWidget.isBottomLeft || cornerWidget.isBottomRight) ? parent.bottom : undefined
                    left: (cornerWidget.isLeft) ? parent.left : undefined
                    right: (cornerWidget.isTopRight || cornerWidget.isBottomRight) ? parent.right : undefined
                }

                sourceComponent: FocusedScrollMouseArea {
                    id: mouseArea
                    implicitWidth: Config.options.sidebar.cornerOpen.cornerRegionWidth
                    implicitHeight: Config.options.sidebar.cornerOpen.cornerRegionHeight
                    hoverEnabled: true
                    onPositionChanged: {
                        if (cornerWidget.isBottom && !Config.options.sidebar.cornerOpen.hoverAllCorners) return;
                        if (!Config.options.sidebar.cornerOpen.clicklessCornerEnd || !Config.options.sidebar.cornerOpen.clickless) return;
                        const verticalOffset = Config.options.sidebar.cornerOpen.clicklessCornerVerticalOffset;
                        const correctX = (cornerWidget.isRight && mouseArea.mouseX >= mouseArea.width - 2) || (cornerWidget.isLeft && mouseArea.mouseX <= 2);
                        const correctY = (cornerWidget.isTop && mouseArea.mouseY > verticalOffset || cornerWidget.isBottom && mouseArea.mouseY < mouseArea.height - verticalOffset);
                        if (correctX && correctY)
                            screenCorners.triggerCornerAction(cornerPanelWindow.corner, true);
                    }
                    onEntered: {
                        if (cornerWidget.isBottom && !Config.options.sidebar.cornerOpen.hoverAllCorners) return;
                        if (Config.options.sidebar.cornerOpen.clickless)
                            screenCorners.triggerCornerAction(cornerPanelWindow.corner, true);
                    }
                    onPressed: {
                        screenCorners.triggerCornerAction(cornerPanelWindow.corner, false);
                    }
                    onScrollDown: {
                        if (!Config.options.sidebar.cornerOpen.valueScroll)
                            return;
                        const action = cornerWidget.isLeft
                            ? Config.options.sidebar.cornerOpen.leftScrollAction
                            : Config.options.sidebar.cornerOpen.rightScrollAction;
                        if (action === "brightness")
                            Brightness.decreaseBrightness()
                        else {
                            const currentVolume = Audio.value;
                            const step = currentVolume < 0.1 ? 0.01 : 0.02 || 0.2;
                            Audio.sink.audio.volume -= step;
                        }
                    }
                    onScrollUp: {
                        if (!Config.options.sidebar.cornerOpen.valueScroll)
                            return;
                        const action = cornerWidget.isLeft
                            ? Config.options.sidebar.cornerOpen.leftScrollAction
                            : Config.options.sidebar.cornerOpen.rightScrollAction;
                        if (action === "brightness")
                            Brightness.increaseBrightness()
                        else {
                            const currentVolume = Audio.value;
                            const step = currentVolume < 0.1 ? 0.01 : 0.02 || 0.2;
                            Audio.sink.audio.volume = Math.min(1, Audio.sink.audio.volume + step);
                        }
                    }
                    onMovedAway: {
                        if (!Config.options.sidebar.cornerOpen.valueScroll)
                            return;
                        const action = cornerWidget.isLeft
                            ? Config.options.sidebar.cornerOpen.leftScrollAction
                            : Config.options.sidebar.cornerOpen.rightScrollAction;
                        if (action === "brightness")
                            GlobalStates.osdBrightnessOpen = false;
                        else
                            GlobalStates.osdVolumeOpen = false;
                    }

                    Loader {
                        active: Config.options.sidebar.cornerOpen.visualize
                        anchors.fill: parent
                        sourceComponent: Rectangle {
                            color: Appearance.colors.colPrimary
                        }
                    }
                }
            }
        }
    }

    Variants {
        model: Quickshell.screens

        Scope {
            id: monitorScope
            required property var modelData
            property HyprlandMonitor monitor: Hyprland.monitorFor(modelData)

            // Hide when fullscreen
            property list<HyprlandWorkspace> workspacesForMonitor: Hyprland.workspaces.values.filter(workspace => workspace.monitor && workspace.monitor.name == monitor.name)
            property var activeWorkspaceWithFullscreen: workspacesForMonitor.filter(workspace => ((workspace.toplevels.values.filter(window => window.wayland?.fullscreen)[0] != undefined) && workspace.active))[0]
            property bool fullscreen: activeWorkspaceWithFullscreen != undefined
            // A special workspace open on top of the fullscreen window should bring corners back,
            // same reasoning as the bar's layer fix: fullscreen only buries them when nothing else is above it.
            property var thisMonitorData: HyprlandData.monitors.find(m => m.name === monitor.name)
            property bool specialOpen: (thisMonitorData?.specialWorkspace?.name ?? "") !== ""

            CornerPanelWindow {
                screen: modelData
                corner: RoundCorner.CornerEnum.TopLeft
                fullscreen: monitorScope.fullscreen && !monitorScope.specialOpen
            }
            CornerPanelWindow {
                screen: modelData
                corner: RoundCorner.CornerEnum.TopRight
                fullscreen: monitorScope.fullscreen && !monitorScope.specialOpen
            }
            CornerPanelWindow {
                screen: modelData
                corner: RoundCorner.CornerEnum.BottomLeft
                fullscreen: monitorScope.fullscreen && !monitorScope.specialOpen
            }
            CornerPanelWindow {
                screen: modelData
                corner: RoundCorner.CornerEnum.BottomRight
                fullscreen: monitorScope.fullscreen && !monitorScope.specialOpen
            }
        }
    }
}
