pragma ComponentBehavior: Bound
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import QtQuick
import Quickshell
import Quickshell.Wayland

Scope {
    id: root
    required property Component contentComponent
    
    Loader {
        active: PolkitService.active
        sourceComponent: Variants {
            model: Quickshell.screens
            delegate: PanelWindow {
                id: panelWindow
                required property var modelData
                screen: modelData
                
                anchors {
                    top: true
                    left: true
                    right: true
                    bottom: true
                }

                color: "transparent"
                // See Bar.qml (shell/modules/ii/bar/Bar.qml) for why this is
                // gated behind a Wayland-only Loader instead of set directly.
                Loader {
                    active: WM.isWayland
                    sourceComponent: Item {
                        Binding { target: panelWindow.WlrLayershell; property: "namespace"; value: "quickshell:polkit" }
                        Binding { target: panelWindow.WlrLayershell; property: "keyboardFocus"; value: WlrKeyboardFocus.OnDemand }
                        Binding { target: panelWindow.WlrLayershell; property: "layer"; value: WlrLayer.Overlay }
                    }
                }
                exclusionMode: ExclusionMode.Ignore

                Loader {
                    anchors.fill: parent
                    sourceComponent: root.contentComponent
                }
            }
        }
    }
}
