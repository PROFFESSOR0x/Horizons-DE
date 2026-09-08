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
import qs.modules.common.widgets
import qs.modules.common.functions as CF

Scope {
    id: root

    readonly property real sizeScale: Config.options.settings.style === "minimal" ? 0.75 : 1.0
    property bool isMinimal: Config.options.settings.style === "minimal"
    // Normal-window mode: behaves like a regular window instead of an
    // overlay panel. Disabling it restores the centered overlay with dimmed
    // backdrop + click-outside/FocusGrab dismiss.
    readonly property bool normalWindow: (Config.options.settings.normalWindow ?? false)

    Component.onCompleted: {
        GlobalStates.settingsOpen = false;
    }

    PanelWindow {
        id: panelWindow
        visible: GlobalStates.settingsOpen

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
                if (!root.normalWindow)
                    GlobalFocusGrab.addDismissable(panelWindow);
                settingsWindow.userMoved = false;
            } else {
                GlobalFocusGrab.removeDismissable(panelWindow);
            }
        }

        Connections {
            target: root
            function onNormalWindowChanged() {
                if (!panelWindow.visible)
                    return;
                if (root.normalWindow)
                    GlobalFocusGrab.removeDismissable(panelWindow);
                else
                    GlobalFocusGrab.addDismissable(panelWindow);
            }
        }

        Connections {
            target: GlobalFocusGrab
            function onDismissed() {
                if (!root.normalWindow)
                    panelWindow.hide();
            }
        }

        Rectangle {
            visible: !root.normalWindow
            anchors.fill: parent
            color: "transparent"
            opacity: GlobalStates.settingsOpen ? 1 : 0
            z: 0
            Behavior on opacity {
                NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
            }
            MouseArea {
                anchors.fill: parent
                enabled: !root.normalWindow
                propagateComposedEvents: false
                onClicked: panelWindow.hide()
            }
        }

        Rectangle {
            id: settingsWindow
            width: Math.min(parent.width - 48, Config.options.settings.preferredWidth * sizeScale)
            height: Math.min(parent.height - 42, Config.options.settings.preferredHeight * sizeScale)
            color: Appearance.colors.colLayer0
            border.width: Config.options.settings.borderSize
            border.color: Appearance.getColorFromName(Config.options.settings.borderColor)
            radius: Appearance.rounding.large + 8
            z: 1
            // Safety net: this window has a fixed width (settings.preferredWidth,
            // not user-resizable) - a row with enough options to not wrap in
            // time (or any future sizing slip) used to render straight past
            // this Rectangle's edge onto the desktop behind it instead of
            // just looking cramped. Popups/tooltips (QtQuick.Controls
            // Overlay-based) aren't affected by clipping an ordinary ancestor.
            clip: true

            property bool userMoved: false
            anchors.centerIn: userMoved ? undefined : parent

            opacity: GlobalStates.settingsOpen ? 1 : 0
            scale: GlobalStates.settingsOpen ? 1 : 0.95

            Behavior on opacity {
                NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
            }
            Behavior on scale {
                NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
            }

            Shortcut {
            sequence: "Ctrl+Tab"
            enabled: panelWindow.visible
            onActivated: settingsContent.stepPage(1)
        }
        Shortcut {
            sequence: "Ctrl+Shift+Tab"
            enabled: panelWindow.visible
            onActivated: settingsContent.stepPage(-1)
        }

        Keys.onPressed: (event) => {
            if (event.key === Qt.Key_Escape) {
                panelWindow.hide();
                event.accepted = true;
                return;
            }

            if (event.key === Qt.Key_Down || event.key === Qt.Key_Up) {
                const instance = GlobalStates.currentPageInstance;
                if (instance && instance.contentY !== undefined) {
                    const step = 60;
                    const delta = event.key === Qt.Key_Down ? step : -step;
                    const maxY = Math.max(0, (instance.contentHeight ?? 0) - instance.height);
                    instance.contentY = Math.max(0, Math.min(maxY, instance.contentY + delta));
                }
                event.accepted = true;
                return;
            }
        }

            Rectangle {
                id: dragHandle
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.rightMargin: settingsContent.rightToLeft ? 0 : 62
                anchors.leftMargin: settingsContent.rightToLeft ? 62 : 0
                height: 50
                color: "transparent"
                z: 2

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.SizeAllCursor
                    drag.target: settingsWindow
                    drag.axis: Drag.XAndYAxis
                    onPressed: settingsWindow.userMoved = true
                    onDoubleClicked: settingsWindow.userMoved = false
                }
            }

            SettingsContent {
                id: settingsContent
                anchors.fill: parent
            }

            // Normal-window mode: corner resize handle that persists the size
            // into settings.preferredWidth/Height. Hidden in overlay mode so
            // the current fixed-size centered look is untouched.
            MouseArea {
                visible: root.normalWindow
                enabled: root.normalWindow
                width: 26
                height: 26
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.margins: 2
                cursorShape: Qt.SizeFDiagCursor
                z: 3
                property real startX: 0
                property real startY: 0
                property int startW: 0
                property int startH: 0
                onPressed: (mouse) => {
                    startX = mouse.x;
                    startY = mouse.y;
                    startW = Config.options.settings.preferredWidth;
                    startH = Config.options.settings.preferredHeight;
                }
                onPositionChanged: (mouse) => {
                    if (!pressed)
                        return;
                    const dx = (mouse.x - startX) / root.sizeScale;
                    const dy = (mouse.y - startY) / root.sizeScale;
                    Config.options.settings.preferredWidth = Math.max(640, Math.min(2560, Math.round(startW + dx)));
                    Config.options.settings.preferredHeight = Math.max(420, Math.min(1600, Math.round(startH + dy)));
                }
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
