import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions

RowLayout {
    id: root
    property string text: ""
    property string icon: ""
    property list<var> options: [
        {
            "displayName": "Option 1",
            "icon": "check",
            "value": 1
        },
        {
            "displayName": "Option 2",
            "icon": "close",
            "value": 2
        },
    ]
    property var currentValue: null

    signal selected(var newValue)

    spacing: 6
    Layout.leftMargin: 8
    Layout.rightMargin: 8

    RowLayout {
        spacing: 6
        visible: root.text !== ""
        Layout.fillWidth: true
        OptionalMaterialSymbol {
            icon: root.icon
            opacity: root.enabled ? 1 : 0.4
        }
        StyledText {
            id: labelWidget
            Layout.fillWidth: true
            Layout.minimumWidth: 0
            text: root.text
            color: Appearance.colors.colOnSecondaryContainer
            opacity: root.enabled ? 1 : 0.4
            elide: Text.ElideRight
        }
    }

    Flow {
        id: buttonsFlow
        // Deliberately NOT Layout.fillWidth: competing with the label's own
        // fillWidth left the split between them up to however Qt Quick
        // Layouts happened to resolve two fillWidth siblings that frame,
        // which could shrink this Flow below what a single row of buttons
        // needs even while there was still room — wrapping to an extra line
        // (and inflating the GroupedList row's height inconsistently between
        // otherwise-identical rows) or visually colliding with the label.
        // Sizing to its own natural (unwrapped) width instead means it only
        // ever wraps when the row is genuinely too narrow to fit it, and the
        // label (which does keep fillWidth + elide) is always the side that
        // absorbs the squeeze.
        Layout.alignment: Qt.AlignRight
        spacing: 2

        Repeater {
            model: root.options
            delegate: SelectionGroupButton {
                id: paletteButton
                required property var modelData
                required property int index
                onYChanged: {
                    if (index === 0) {
                        paletteButton.leftmost = true
                    } else {
                        var prev = buttonsFlow.children[index - 1]
                        var thisIsOnNewLine = prev && prev.y !== paletteButton.y
                        paletteButton.leftmost = thisIsOnNewLine
                        if (prev) prev.rightmost = thisIsOnNewLine
                    }
                }
                leftmost: index === 0
                rightmost: index === root.options.length - 1
                buttonIcon: modelData.icon || ""
                buttonText: modelData.displayName
                toggled: root.currentValue == modelData.value
                onClicked: root.selected(modelData.value)
            }
        }
    }
}
