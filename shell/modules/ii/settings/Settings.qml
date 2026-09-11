//@ pragma Env QS_NO_RELOAD_POPUP=1
//@ pragma Env QT_QUICK_CONTROLS_STYLE=Basic
//@ pragma Env QT_QUICK_FLICKABLE_WHEEL_DECELERATION=10000
import Quickshell.Io
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import qs
import qs.services
import qs.modules.common

Scope {
    id: root

    readonly property real sizeScale: Config.options.settings.style === "minimal" ? 0.75 : 1.0
    property bool isMinimal: Config.options.settings.style === "minimal"
    readonly property bool normalWindow: (Config.options.settings.normalWindow ?? false)

    Component.onCompleted: {
        GlobalStates.settingsOpen = false;
    }

    PanelWindow {
        id: panelWindow
        visible: GlobalStates.settingsOpen && !root.normalWindow

        function hide() {
            GlobalStates.settingsOpen = false;
        }

        exclusiveZone: 0
        // See Bar.qml (shell/modules/ii/bar/Bar.qml) for why this is gated
        // behind a Wayland-only Loader instead of set directly.
        Loader {
            active: WM.isWayland
            sourceComponent: Item {
                Binding { target: panelWindow.WlrLayershell; property: "namespace"; value: "quickshell:settings" }
                Binding { target: panelWindow.WlrLayershell; property: "layer"; value: WlrLayer.Overlay }
                Binding { target: panelWindow.WlrLayershell; property: "keyboardFocus"; value: GlobalStates.settingsOpen ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None }
            }
        }
        color: "transparent"

        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }

        onVisibleChanged: {
            if (visible) {
                GlobalFocusGrab.addDismissable(panelWindow);
                if (overlaySettingsLoader.item)
                    overlaySettingsLoader.item.userMoved = false;
            } else {
                GlobalFocusGrab.removeDismissable(panelWindow);
            }
        }

        Connections {
            target: GlobalFocusGrab
            function onDismissed() {
                if (panelWindow.visible)
                    panelWindow.hide();
            }
        }

        Rectangle {
            anchors.fill: parent
            color: "transparent"
            opacity: GlobalStates.settingsOpen ? 1 : 0
            z: 0
            Behavior on opacity {
                NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
            }
            MouseArea {
                anchors.fill: parent
                propagateComposedEvents: false
                onClicked: panelWindow.hide()
            }
        }

        Loader {
            id: overlaySettingsLoader
            anchors.fill: parent
            active: panelWindow.visible

            sourceComponent: SettingsWindowChrome {
                sizeScale: root.sizeScale
                nativeWindow: false
                onCloseRequested: panelWindow.hide()
            }
            onLoaded: item.userMoved = false
        }
    }

    FloatingWindow {
        id: floatingWindow
        visible: GlobalStates.settingsOpen && root.normalWindow
        color: "transparent"
        implicitWidth: Config.options.settings.preferredWidth * root.sizeScale
        implicitHeight: Config.options.settings.preferredHeight * root.sizeScale

        onVisibleChanged: {
            if (!visible && root.normalWindow)
                GlobalStates.settingsOpen = false;
        }

        Loader {
            anchors.fill: parent
            active: floatingWindow.visible

            sourceComponent: SettingsWindowChrome {
                anchors.fill: parent
                sizeScale: root.sizeScale
                nativeWindow: true
                onCloseRequested: GlobalStates.settingsOpen = false
            }
        }
    }

    IpcHandler {
        target: "settings"
        function toggle(): void { GlobalStates.settingsOpen = !GlobalStates.settingsOpen; }
        function open(): void   { GlobalStates.settingsOpen = true; }
        function close(): void  { GlobalStates.settingsOpen = false; }
    }

    CompositorGlobalShortcut {
        name: "settingsToggle"
        description: "Toggles settings panel"
        onPressed: GlobalStates.settingsOpen = !GlobalStates.settingsOpen;
    }
}
