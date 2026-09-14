import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import qs.modules.ii.overview
import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell.Io
import Quickshell
import Quickshell.Widgets
import Quickshell.Wayland

Scope {
    id: root
    property var pinnedMonitors: ({})

    function defaultPinned() {
        return Config.options?.dock.pinnedOnStartup ?? false
    }

    function monitorPinned(monitorName) {
        if (!monitorName) return defaultPinned()
        const value = pinnedMonitors[monitorName]
        return value === undefined ? defaultPinned() : value
    }

    function setMonitorPinned(monitorName, pinned) {
        if (!monitorName) return
        const next = Object.assign({}, pinnedMonitors)
        next[monitorName] = pinned
        pinnedMonitors = next
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: dockRoot
            required property var modelData
            screen: modelData
            visible: !GlobalStates.screenLocked && !GlobalStates.lockPreviewOpen

            property var monitor: WM.monitorFor(modelData)
            property string monitorName: modelData?.name ?? monitor?.name ?? ""
            property bool fullscreenOnThisMonitor: WM.fullscreenOnMonitor(monitorName)
            property bool obscuredOnThisMonitor: !!WM.obscuredMonitors[monitorName]
            property bool floatStyle: (Config.options?.dock.cornerStyle ?? 1) === 1
            property bool launcherInDock: Config.options?.dock.enable
                && Config.options?.dock.launcherInDock
            property bool focusedMonitor: WM.focusedMonitor?.name === monitorName
            property bool launcherActive: launcherInDock && GlobalStates.overviewOpen && focusedMonitor
            property bool pinned: root.monitorPinned(monitorName)
            property real edgeGap: floatStyle ? Appearance.sizes.hyprlandGapsOut : 0
            property real launcherSurfaceHeight: dockLauncherLoader.active && dockLauncherLoader.item
                ? dockLauncherLoader.item.implicitHeight
                : 0
            property real surfaceHeight: launcherActive
                ? Math.max(Config.options?.dock.height ?? 70, launcherSurfaceHeight)
                : (Config.options?.dock.height ?? 70)

            property bool reveal: {
                if (launcherActive)
                    return true
                if (fullscreenOnThisMonitor)
                    return Config.options?.dock.hoverToReveal && dockMouseArea.containsMouse
                if (obscuredOnThisMonitor)
                    return dockRoot.pinned
                        || (Config.options?.dock.hoverToReveal && dockMouseArea.containsMouse)
                        || activeAppsArea.requestDockShow
                        || dragSlots.requestDockShow
                return dockRoot.pinned
                    || (Config.options?.dock.hoverToReveal && dockMouseArea.containsMouse)
                    || activeAppsArea.requestDockShow
                    || dragSlots.requestDockShow
                    || !obscuredOnThisMonitor
            }

            exclusiveZone: (dockRoot.pinned && !fullscreenOnThisMonitor && !launcherActive)
                ? surfaceHeight + edgeGap
                : 0

            anchors { bottom: true; left: true; right: true }
            implicitWidth: dockBackground.implicitWidth
            // See Bar.qml (shell/modules/ii/bar/Bar.qml) for why this is
            // gated behind a Wayland-only Loader instead of set directly.
            Loader {
                active: WM.isWayland
                sourceComponent: Item {
                    Binding { target: dockRoot.WlrLayershell; property: "namespace"; value: "quickshell:dock" }
                    Binding {
                        target: dockRoot.WlrLayershell
                        property: "keyboardFocus"
                        value: dockRoot.launcherActive ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
                    }
                }
            }
            color: "transparent"

            implicitHeight: surfaceHeight
                + Appearance.sizes.elevationMargin
                + edgeGap

            mask: Region { item: dockMouseArea }

            onLauncherActiveChanged: {
                if (launcherActive)
                    GlobalFocusGrab.addDismissable(dockRoot)
                else
                    GlobalFocusGrab.removeDismissable(dockRoot)
            }

            Connections {
                target: GlobalFocusGrab
                function onDismissed() {
                    if (dockRoot.launcherActive)
                        GlobalStates.overviewOpen = false
                }
            }

            MouseArea {
                id: dockMouseArea
                height: parent.height
                anchors {
                    top: parent.top
                    topMargin: dockRoot.reveal
                        ? 0
                        : Config.options?.dock.hoverToReveal
                            ? (dockRoot.implicitHeight - Config.options.dock.hoverRegionHeight)
                            : (dockRoot.implicitHeight + 1)
                    horizontalCenter: parent.horizontalCenter
                }
                implicitWidth: Math.max(
                    dockHoverRegion.implicitWidth,
                    dockLauncherLoader.active && dockLauncherLoader.item ? dockLauncherLoader.item.implicitWidth : 0
                ) + Appearance.sizes.elevationMargin * 2
                hoverEnabled: true

                Behavior on anchors.topMargin {
                    animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                }

                Item {
                    id: dockHoverRegion
                    anchors.fill: parent
                    implicitWidth: dockBackground.implicitWidth

                    Item {
                        id: dockBackground
                        anchors {
                            top: parent.top
                            bottom: parent.bottom
                            horizontalCenter: parent.horizontalCenter
                        }
                        implicitWidth: (dockRoot.launcherActive && dockLauncherLoader.item)
                            ? dockLauncherLoader.item.implicitWidth
                            : dockRow.implicitWidth + 5 * 2
                        height: parent.height
                            - Appearance.sizes.elevationMargin
                            - dockRoot.edgeGap

                        StyledRectangularShadow {
                            target: dockVisualBackground
                            visible: dockRoot.floatStyle && Config.options.dock.showBackground
                        }

                        Rectangle {
                            id: dockVisualBackground
                            property real margin: Appearance.sizes.elevationMargin
                            anchors.fill: parent
                            anchors.topMargin:    Appearance.sizes.elevationMargin
                            anchors.bottomMargin: dockRoot.edgeGap
                            color: Config.options.dock.showBackground
                                   ? Appearance.colors.colLayer0 : "transparent"
                            border.width: Config.options.dock.showBackground ? 1 : 0
                            border.color: Appearance.colors.colLayer0Border
                            radius: Appearance.rounding.normal + 6
                            bottomLeftRadius: dockRoot.floatStyle ? radius : 0
                            bottomRightRadius: dockRoot.floatStyle ? radius : 0
                        }

                        Loader {
                            id: dockLauncherLoader
                            active: dockRoot.launcherActive
                            visible: active
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.bottom: parent.bottom
                            width: active && item ? item.implicitWidth : 0
                            height: active && item ? item.implicitHeight : 0
                            opacity: active ? 1 : 0
                            scale: active ? 1 : 0.96
                            Behavior on opacity { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
                            Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

                            sourceComponent: SearchWidget {
                                launcherPosition: "bottom"
                            }
                        }

                        RowLayout {
                            id: dockRow
                            visible: !dockRoot.launcherActive
                            anchors.top: parent.top
                            anchors.bottom: parent.bottom
                            anchors.horizontalCenter: parent.horizontalCenter
                            spacing: 3
                            property real padding: 5
                            property bool hasPinnedApps: (Config.options?.dock.pinnedApps?.length ?? 0) > 0

                            VerticalButtonGroup {
                                Layout.topMargin: 3
                                Layout.leftMargin:  dockRoot.pinned
                                    ? Appearance.sizes.hyprlandGapsOut + 4
                                    : Appearance.sizes.hyprlandGapsOut
                                Layout.rightMargin: dockRoot.pinned
                                    ? Appearance.sizes.hyprlandGapsOut + 4
                                    : Appearance.sizes.hyprlandGapsOut

                                GroupButton {
                                    baseWidth: 35; baseHeight: 35
                                    visible: Config.options.dock.showPinButton
                                    clickedWidth: baseWidth; clickedHeight: baseHeight + 20
                                    buttonRadius: Appearance.rounding.normal
                                    toggled: dockRoot.pinned
                                    onClicked: root.setMonitorPinned(dockRoot.monitorName, !dockRoot.pinned)
                                    contentItem: MaterialSymbol {
                                        text: "keep"
                                        horizontalAlignment: Text.AlignHCenter
                                        iconSize: Appearance.font.pixelSize.larger
                                        color: dockRoot.pinned
                                               ? Appearance.m3colors.m3onPrimary
                                               : Appearance.colors.colOnLayer0
                                    }
                                }
                            }

                            DockSeparator {
                                visible: Config.options.dock.showPinButton
                                    && (dockRow.hasPinnedApps
                                        || !(Config.options.dock.showMedia && dockMedia.hasTrack))
                            }

                            DragApps {
                                id: dragSlots
                                visible: dockRow.hasPinnedApps
                                Layout.fillHeight: false
                                Layout.topMargin: 2
                                Layout.leftMargin: Config.options.dock.showPinButton ? 0 : -18
                                pinnedApps:    Config.options?.dock.pinnedApps ?? []
                                buttonPadding: dockRow.padding
                                btnSize:       46
                                btnSpacing:    1
                            }

                            DockSeparator {
                                visible: dockRow.hasPinnedApps && (activeAppsArea.activeUnpinned.length > 0 || (Config.options.dock.showMedia && MprisController.activePlayer !== null))
                            }

                            Item {
                                id: activeAppsArea
                                Layout.fillHeight: true
                                Layout.topMargin: 0
                                property bool requestDockShow: appListBridge.openContextMenu !== null

                                property var activeUnpinned: {
                                    return TaskbarApps.apps.filter(
                                        a => !a.pinned
                                          && a.appId !== "SEPARATOR"
                                          && a.toplevels.length > 0
                                    )
                                }
                                property bool hasActiveUnpinned: activeUnpinned.length > 0 || dockMedia.visible

                                implicitWidth:  activeRow.implicitWidth
                                implicitHeight: parent.height

                                Behavior on implicitWidth {
                                    animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                                }

                                RowLayout {
                                    id: activeRow
                                    anchors.fill: parent
                                    Layout.rightMargin: 10
                                    spacing: -4

                                    DockMedia {
                                        id: dockMedia
                                        visible: Config.options.dock.showMedia
                                        Layout.fillHeight: true
                                        Layout.topMargin: 12
                                        Layout.bottomMargin: 8
                                        Layout.leftMargin: 0
                                        buttonPadding: dockRow.padding
                                    }

                                    Repeater {
                                        model: activeAppsArea.activeUnpinned
                                        delegate: DockAppButton {
                                            required property var modelData
                                            appToplevel: modelData
                                            Layout.fillHeight: true
                                            Layout.topMargin: 2
                                            appListRoot: appListBridge
                                            topInset:    dockRow.padding + 8
                                            bottomInset: dockRow.padding + 8
                                        }
                                    }
                                }

                                QtObject {
                                    id: appListBridge
                                    property Item lastHoveredButton: null
                                    property bool buttonHovered: false
                                    property var openContextMenu: null
                                }
                            }

                            DockSeparator {
                                visible: Config.options.dock.showAppsButton
                                Layout.leftMargin: Config.options.dock.showAppsButton ? 0 : -3
                            }

                            DockButton {
                                Layout.fillHeight: true
                                Layout.topMargin: 0
                                visible: Config.options.dock.showAppsButton
                                onClicked: GlobalStates.overviewOpen = !GlobalStates.overviewOpen
                                topInset:    dockRow.padding + 10
                                bottomInset: dockRow.padding + 7
                                contentItem: MaterialSymbol {
                                    anchors.fill: parent
                                    horizontalAlignment: Text.AlignHCenter
                                    font.pixelSize: parent.width / 2
                                    text: "apps"
                                    color: Appearance.colors.colOnLayer0
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
