pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import qs.modules.common
import qs.modules.common.widgets

RowLayout {
    id: root

    property string currentTool: "pen"
    property color currentColor: "#ff0000"
    property real currentWidth: 3
    property list<color> colorPalette: []
    property bool isVideo: false

    signal toolSelected(string tool)
    signal colorSelected(color selectedColor)
    signal strokeWidthChanged(real newWidth)
    signal undoRequested()
    signal clearRequested()
    signal saveRequested()
    signal copyRequested()

    spacing: 8

    // Drawing tools
    Row {
        spacing: 2

        Repeater {
            model: [
                { tool: "pen",       icon: "draw",           tip: "Pen" },
                { tool: "arrow",     icon: "north_east",     tip: "Arrow" },
                { tool: "rect",      icon: "rectangle",      tip: "Rectangle" },
                { tool: "circle",    icon: "circle",         tip: "Circle" },
                { tool: "highlight", icon: "ink_highlighter", tip: "Highlight" },
                { tool: "blur",      icon: "blur_on",        tip: "Pixelate / Blur" }
            ]
            delegate: Rectangle {
                required property var modelData
                width: 36; height: 36
                radius: 8
                color: root.currentTool === modelData.tool
                    ? Appearance.colors.colPrimaryContainer
                    : (toolMa.containsMouse ? Appearance.colors.colLayer2 : "transparent")

                MaterialSymbol {
                    anchors.centerIn: parent
                    text: modelData.icon
                    iconSize: 18
                    color: root.currentTool === modelData.tool
                        ? Appearance.colors.colOnPrimaryContainer
                        : Appearance.colors.colOnLayer1
                }

                MouseArea {
                    id: toolMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.toolSelected(modelData.tool)
                }

                StyledToolTip {
                    text: modelData.tip
                }
            }
        }
    }

    // Separator
    Rectangle { width: 1; height: 28; color: Appearance.colors.colOutlineVariant; opacity: 0.5 }

    // Color palette
    Row {
        spacing: 2
        Repeater {
            model: root.colorPalette
            delegate: Rectangle {
                required property color modelData
                width: 24; height: 24
                radius: 12
                color: modelData
                border.width: Qt.colorEqual(root.currentColor, modelData) ? 3 : 0
                border.color: Appearance.colors.colOnLayer0

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.colorSelected(modelData)
                }
            }
        }
    }

    // Separator
    Rectangle { width: 1; height: 28; color: Appearance.colors.colOutlineVariant; opacity: 0.5 }

    // Width slider
    Row {
        spacing: 4
        Layout.preferredWidth: 120

        MaterialSymbol {
            iconSize: 16
            text: "line_weight"
            color: Appearance.colors.colOnLayer1
            anchors.verticalCenter: parent.verticalCenter
        }

        Slider {
            id: widthSlider
            Layout.fillWidth: true
            from: 1; to: 20; stepSize: 1
            value: root.currentWidth
            onMoved: root.strokeWidthChanged(value)
        }

        StyledText {
            text: Math.round(root.currentWidth)
            font.pixelSize: Appearance.font.pixelSize.smaller
            color: Appearance.colors.colOnLayer1
            anchors.verticalCenter: parent.verticalCenter
            Layout.preferredWidth: 20
            horizontalAlignment: Text.AlignHCenter
        }
    }

    // Spacer
    Item { Layout.fillWidth: true }

    // Action buttons
    Row {
        spacing: 4

        // Undo
        Rectangle {
            width: 36; height: 36; radius: 8
            color: undoMa.containsMouse ? Appearance.colors.colLayer2 : "transparent"
            MaterialSymbol {
                anchors.centerIn: parent
                text: "undo"
                iconSize: 18
                color: Appearance.colors.colOnLayer1
            }
            MouseArea {
                id: undoMa
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.undoRequested()
            }
            StyledToolTip { text: "Undo (Ctrl+Z)" }
        }

        // Clear
        Rectangle {
            width: 36; height: 36; radius: 8
            color: clearMa.containsMouse ? Appearance.colors.colErrorContainer : "transparent"
            MaterialSymbol {
                anchors.centerIn: parent
                text: "delete"
                iconSize: 18
                color: clearMa.containsMouse ? Appearance.colors.colOnErrorContainer : Appearance.colors.colOnLayer1
            }
            MouseArea {
                id: clearMa
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.clearRequested()
            }
            StyledToolTip { text: "Clear all" }
        }

        // Separator
        Rectangle { width: 1; height: 28; anchors.verticalCenter: parent.verticalCenter; color: Appearance.colors.colOutlineVariant; opacity: 0.5 }

        // Copy
        Rectangle {
            width: 36; height: 36; radius: 8
            color: copyMa.containsMouse ? Appearance.colors.colPrimaryContainer : "transparent"
            MaterialSymbol {
                anchors.centerIn: parent
                text: "content_copy"
                iconSize: 18
                color: Appearance.colors.colOnLayer1
            }
            MouseArea {
                id: copyMa
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.copyRequested()
            }
            StyledToolTip { text: "Copy to clipboard" }
        }

        // Save
        Rectangle {
            width: 36; height: 36; radius: 8
            color: saveMa.containsMouse ? Appearance.colors.colPrimaryContainer : "transparent"
            MaterialSymbol {
                anchors.centerIn: parent
                text: "save"
                iconSize: 18
                color: Appearance.colors.colOnLayer1
            }
            MouseArea {
                id: saveMa
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.saveRequested()
            }
            StyledToolTip { text: "Save file" }
        }
    }
}
