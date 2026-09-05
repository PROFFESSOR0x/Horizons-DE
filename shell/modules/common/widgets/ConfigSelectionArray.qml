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
        // Needs Layout.fillWidth (and an explicit Layout.minimumWidth low
        // enough to actually be reached): a Flow's own `width` only gets set
        // by the layout when it's a fillWidth item, and Flow only wraps
        // children once its `width` is narrower than one unbroken row needs.
        // Without fillWidth here (the previous fix for label/button overlap
        // at squeeze widths), this Flow always reported its full unwrapped
        // width as non-negotiable, so RowLayout could never shrink it —
        // with enough options (the 11 blur variants, the 5 performance
        // profiles, …) that width regularly exceeds the settings window,
        // and the row spills out past the window edge instead of wrapping.
        // GroupedList's own minRowHeight/extraPadFor (see GroupedList.qml)
        // already normalizes every row's background-pill height regardless
        // of how many lines a wrapped Flow ends up needing, so restoring
        // fillWidth here no longer reintroduces the inconsistent-row-height
        // symptom that motivated removing it in the first place.
        Layout.fillWidth: true
        Layout.minimumWidth: 0
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
