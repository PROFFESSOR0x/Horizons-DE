import QtQuick
import QtQuick.Controls
import qs
import qs.services
import qs.modules.common

Rectangle {
    id: settingsWindow

    property real sizeScale: 1
    property bool nativeWindow: false
    property bool userMoved: false

    signal closeRequested()

    width: nativeWindow && parent
        ? parent.width
        : Math.min((parent ? parent.width : Config.options.settings.preferredWidth * sizeScale) - 48,
            Config.options.settings.preferredWidth * sizeScale)
    height: nativeWindow && parent
        ? parent.height
        : Math.min((parent ? parent.height : Config.options.settings.preferredHeight * sizeScale) - 42,
            Config.options.settings.preferredHeight * sizeScale)
    color: Appearance.colors.colLayer0
    border.width: Config.options.settings.borderSize
    border.color: Appearance.getColorFromName(Config.options.settings.borderColor)
    radius: Appearance.rounding.large + 8
    z: 1
    clip: true
    focus: true

    anchors.centerIn: !nativeWindow && !userMoved ? parent : undefined

    opacity: GlobalStates.settingsOpen ? 1 : 0
    scale: GlobalStates.settingsOpen ? 1 : 0.95

    Behavior on opacity {
        NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
    }
    Behavior on scale {
        NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
    }

    Keys.onPressed: (event) => {
        if (event.key === Qt.Key_Escape) {
            settingsWindow.closeRequested();
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

    Shortcut {
        sequence: "Ctrl+Tab"
        enabled: GlobalStates.settingsOpen
        onActivated: settingsContent.stepPage(1)
    }

    Shortcut {
        sequence: "Ctrl+Shift+Tab"
        enabled: GlobalStates.settingsOpen
        onActivated: settingsContent.stepPage(-1)
    }

    Rectangle {
        id: dragHandle
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.rightMargin: settingsContent.rightToLeft ? 0 : 118
        anchors.leftMargin: settingsContent.rightToLeft ? 118 : 0
        height: 50
        color: "transparent"
        z: 2
        visible: !settingsWindow.nativeWindow
        enabled: !settingsWindow.nativeWindow

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

    MouseArea {
        property real startX: 0
        property real startY: 0
        property int startW: 0
        property int startH: 0

        visible: settingsWindow.nativeWindow
        enabled: settingsWindow.nativeWindow
        width: 26
        height: 26
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: 2
        cursorShape: Qt.SizeFDiagCursor
        z: 3
        onPressed: (mouse) => {
            startX = mouse.x;
            startY = mouse.y;
            startW = Config.options.settings.preferredWidth;
            startH = Config.options.settings.preferredHeight;
        }
        onPositionChanged: (mouse) => {
            if (!pressed)
                return;

            const dx = (mouse.x - startX) / settingsWindow.sizeScale;
            const dy = (mouse.y - startY) / settingsWindow.sizeScale;
            Config.options.settings.preferredWidth = Math.max(640, Math.min(2560, Math.round(startW + dx)));
            Config.options.settings.preferredHeight = Math.max(420, Math.min(1600, Math.round(startH + dy)));
            Config.requestWrite();
        }
    }
}
