import qs
import qs.modules.common
import qs.modules.common.widgets
import qs.services
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland

Scope {
    id: root

    property Component regionComponent: Component {
        Region {}
    }
    
    Loader {
        id: overlayLoader
        active: GlobalStates.overlayOpen || OverlayContext.hasPinnedWidgets
        sourceComponent: PanelWindow {
            id: overlayWindow
            exclusionMode: ExclusionMode.Ignore
            // See Bar.qml (shell/modules/ii/bar/Bar.qml) for why this is
            // gated behind a Wayland-only Loader instead of set directly.
            Loader {
                active: WM.isWayland
                sourceComponent: Item {
                    Binding { target: overlayWindow.WlrLayershell; property: "namespace"; value: "quickshell:overlay" }
                    Binding { target: overlayWindow.WlrLayershell; property: "layer"; value: WlrLayer.Overlay }
                    // Use OnDemand for pinned widgets to allow focus switching with mouse clicks
                    Binding { target: overlayWindow.WlrLayershell; property: "keyboardFocus"; value: GlobalStates.overlayOpen ? WlrKeyboardFocus.Exclusive : (OverlayContext.clickableWidgets.length > 0 ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None) }
                }
            }
            visible: true
            color: "transparent"

            mask: Region {
                item: GlobalStates.overlayOpen ? overlayContent : null
                regions: OverlayContext.clickableWidgets.map((widget) => regionComponent.createObject(this, {
                    item: widget
                }));
            }

            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }

            HyprlandFocusGrab {
                id: grab
                windows: [overlayWindow]
                active: false
                onCleared: () => {
                    if (!active) GlobalStates.overlayOpen = false;
                }
            }

            Connections {
                target: GlobalStates
                function onOverlayOpenChanged() {
                    delayedGrabTimer.restart();
                }
            }

            Timer {
                id: delayedGrabTimer
                interval: Appearance.animation.elementMoveFast.duration
                onTriggered: {
                    grab.active = GlobalStates.overlayOpen;
                }
            }

            OverlayContent {
                id: overlayContent
                anchors.fill: parent
            }
        }
    }

    IpcHandler {
        target: "overlay"

        function toggle(): void {
            GlobalStates.overlayOpen = !GlobalStates.overlayOpen;
        }
    }

    CompositorGlobalShortcut {
        name: "overlayToggle"
        description: "Toggles overlay on press"

        onPressed: {
            GlobalStates.overlayOpen = !GlobalStates.overlayOpen;
        }
    }
}
