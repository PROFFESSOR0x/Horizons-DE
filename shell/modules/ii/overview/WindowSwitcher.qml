import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland

// Super+Tab's Workspaces/Windows switcher - a standalone panel, deliberately
// separate from Overview.qml (the app search/launcher, toggled by tapping
// Super alone). They used to share one panel with the switcher's tabs
// rendered directly under the search box, which looked like one merged
// surface and had nothing to do with searching - GlobalStates.windowSwitcherOpen
// is its own state, this is its own PanelWindow.
Scope {
    id: windowSwitcherScope

    PanelWindow {
        id: panelWindow
        readonly property var monitor: WM.monitorFor(panelWindow.screen)
        property bool monitorIsFocused: WM.focusedMonitor?.name === monitor?.name
        // Same reasoning as Overview.qml: m3Island has its own inline
        // launcher/switcher surface built into the bar itself.
        readonly property bool m3IslandActive: Config.options.bar.barMode === "m3Island"
        visible: GlobalStates.windowSwitcherOpen && !panelWindow.m3IslandActive

        color: "transparent"

        // See Bar.qml for why WlrLayershell is gated behind a Wayland-only
        // Loader instead of set directly.
        Loader {
            active: WM.isWayland
            sourceComponent: Item {
                Binding {
                    target: panelWindow.WlrLayershell
                    property: "namespace"
                    value: "quickshell:windowSwitcher"
                }
                Binding {
                    target: panelWindow.WlrLayershell
                    property: "layer"
                    value: WlrLayer.Top
                }
                Binding {
                    target: panelWindow.WlrLayershell
                    property: "keyboardFocus"
                    value: (GlobalStates.windowSwitcherOpen && !panelWindow.m3IslandActive) ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
                }
            }
        }

        mask: Region {
            item: (GlobalStates.windowSwitcherOpen && !panelWindow.m3IslandActive) ? content : null
        }

        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }

        Connections {
            target: GlobalStates
            function onWindowSwitcherOpenChanged() {
                if (!GlobalStates.windowSwitcherOpen) {
                    GlobalFocusGrab.dismiss();
                } else {
                    GlobalFocusGrab.addDismissable(panelWindow);
                }
            }
        }

        Connections {
            target: GlobalFocusGrab
            function onDismissed() {
                GlobalStates.windowSwitcherOpen = false;
            }
        }

        implicitWidth: content.implicitWidth
        implicitHeight: content.implicitHeight

        WindowSwitcherView {
            id: content
            anchors.centerIn: parent
            screen: panelWindow.screen
            visible: GlobalStates.windowSwitcherOpen
            opacity: GlobalStates.windowSwitcherOpen ? 1 : 0
            scale: GlobalStates.windowSwitcherOpen ? 1 : 0.97

            Behavior on opacity {
                NumberAnimation {
                    duration: GlobalStates.windowSwitcherOpen ? 360 : 220
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: GlobalStates.windowSwitcherOpen ? Appearance.animationCurves.emphasizedDecel : Appearance.animationCurves.emphasizedAccel
                }
            }
            Behavior on scale {
                NumberAnimation {
                    duration: GlobalStates.windowSwitcherOpen ? 400 : 220
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: GlobalStates.windowSwitcherOpen ? Appearance.animationCurves.emphasizedDecel : Appearance.animationCurves.emphasizedAccel
                }
            }

            Keys.onPressed: event => {
                if (event.key === Qt.Key_Escape) {
                    GlobalStates.windowSwitcherOpen = false;
                } else if (event.key === Qt.Key_Left) {
                    WM.switchWorkspaceRelative("prev");
                } else if (event.key === Qt.Key_Right) {
                    WM.switchWorkspaceRelative("next");
                }
            }
        }
    }

    // Same shortcut names Overview.qml used to own - keybinds.lua's
    // `SUPER + Tab -> quickshell:overviewWorkspacesToggle` bind needs no change.
    CompositorGlobalShortcut {
        name: "overviewWorkspacesToggle"
        description: "Toggles the window switcher on press"
        onPressed: {
            GlobalStates.windowSwitcherOpen = !GlobalStates.windowSwitcherOpen;
        }
    }
    CompositorGlobalShortcut {
        name: "overviewWorkspacesClose"
        description: "Closes the window switcher on press"
        onPressed: {
            GlobalStates.windowSwitcherOpen = false;
        }
    }

    IpcHandler {
        target: "windowSwitcher"
        function toggle() {
            GlobalStates.windowSwitcherOpen = !GlobalStates.windowSwitcherOpen;
        }
        function close() {
            GlobalStates.windowSwitcherOpen = false;
        }
        function open() {
            GlobalStates.windowSwitcherOpen = true;
        }
    }
}
