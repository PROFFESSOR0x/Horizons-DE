pragma ComponentBehavior: Bound

import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Layouts

Item {
    id: root
    implicitHeight: col.implicitHeight + 16

    readonly property var widgetList: [
        { key: "networkInfo", icon: "wifi", name: Translation.tr("Network info") },
        { key: "systemHistory", icon: "monitor_heart", name: Translation.tr("System history") },
        { key: "uptime", icon: "schedule", name: Translation.tr("Uptime") },
        { key: "visualizerMirror", icon: "graphic_eq", name: Translation.tr("Mirrored visualizer") },
        { key: "fullMonitorVisualizer", icon: "graphic_eq", name: Translation.tr("Full monitor visualizer") },
        { key: "visualizer",  icon: "graphic_eq",         name: Translation.tr("Visualizer") },
        { key: "customImage", icon: "image",              name: Translation.tr("Custom Image") },
        { key: "weather",     icon: "partly_cloudy_day",  name: Translation.tr("Weather") },
        { key: "clock",       icon: "schedule",           name: Translation.tr("Clock") },
        { key: "media",       icon: "music_note",         name: Translation.tr("Media") },
        { key: "images",      icon: "photo_library",      name: Translation.tr("Image Converter") },
        { key: "resources",   icon: "monitor_heart",      name: Translation.tr("Resources") },
        { key: "calendar",    icon: "calendar_month",     name: Translation.tr("Calendar") },
        { key: "worldClock",  icon: "public",             name: Translation.tr("World Clock") },
        { key: "userCard",    icon: "person",             name: Translation.tr("User Card") },
        { key: "notes",       icon: "note_stack_add",     name: Translation.tr("Notes") },
        { key: "timers",      icon: "timer",              name: Translation.tr("Timers") },
        { key: "todo",        icon: "add_task",           name: Translation.tr("To-Do") },
    ]

    Rectangle {
        anchors.fill: parent
        radius: Appearance.rounding.verylarge
        color: Appearance.colors.colLayer0
    }

    ColumnLayout {
        id: col
        anchors { fill: parent; margins: 8 }
        spacing: 2

        StyledText {
            Layout.fillWidth: true
            text: Translation.tr("Choose where each widget appears")
            wrapMode: Text.WordWrap
        }

        ConfigSwitch {
            visible: !GlobalStates.lockPreviewOpen
            Layout.fillWidth: true
            buttonIcon: "lock"
            text: Translation.tr("Lock widget positions")
            checked: Config.options.background.widgetsLocked
            autoToggle: false
            onClicked: Config.options.background.widgetsLocked = !Config.options.background.widgetsLocked
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.topMargin: 4
            Layout.bottomMargin: 4
            implicitHeight: 1
            color: Appearance.colors.colOutlineVariant
            opacity: 0.4
        }

        Repeater {
            model: root.widgetList
            delegate: ColumnLayout {
                required property var modelData
                Layout.fillWidth: true
                StyledText { text: modelData.name }
                RowLayout {
                    Layout.fillWidth: true
                    ConfigSwitch {
                        autoToggle: false
                        text: Translation.tr("Desktop")
                        checked: GlobalStates.widgetShown(modelData.key, false)
                        onClicked: GlobalStates.setWidgetShown(modelData.key, false, !GlobalStates.widgetShown(modelData.key, false))
                    }
                    ConfigSwitch {
                        autoToggle: false
                        text: Translation.tr("Lock screen")
                        checked: GlobalStates.widgetShown(modelData.key, true)
                        onClicked: GlobalStates.setWidgetShown(modelData.key, true, !GlobalStates.widgetShown(modelData.key, true))
                    }
                }
            }
        }
        RippleButton {
            Layout.fillWidth: true
            text: Translation.tr("Customize lock screen")
            visible: !GlobalStates.lockPreviewOpen
            onClicked: GlobalStates.beginLockPreview()
        }
    }
}
