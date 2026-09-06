import qs.modules.common.widgets
import qs.modules.common
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

RippleButton {
    id: root
    property string buttonIcon
    property alias iconSize: iconWidget.iconSize
    colBackgroundHover: "transparent"

    Layout.fillWidth: true
    // No self-applied bottom margin. GroupedList overrides top/bottom margin
    // on its own direct children anyway, so this only ever applied to a switch
    // nested inside a ConfigRow - leaving 6px of dead space below it and
    // pushing the control off the row's vertical centre, while an identical
    // switch placed directly in the list sat centred. Rows are padded to a
    // common height by GroupedList.minRowHeight, so dropping this does not
    // change any row's height.
    implicitHeight: contentItem.implicitHeight + 8 
    font.pixelSize: Appearance.font.pixelSize.small
    
    onClicked: checked = !checked

    contentItem: RowLayout {
        spacing: 10
        OptionalMaterialSymbol {
            id: iconWidget
            icon: root.buttonIcon
            opacity: root.enabled ? 1 : 0.4
            iconSize: Appearance.font.pixelSize.larger
        }
        StyledText {
            id: labelWidget
            Layout.fillWidth: true
            Layout.minimumWidth: 0
            text: root.text
            font: root.font
            color: Appearance.colors.colOnSecondaryContainer
            opacity: root.enabled ? 1 : 0.4
            elide: Text.ElideRight
        }
        StyledSwitch {
            id: switchWidget
            down: root.down
            Layout.fillWidth: false
            checked: root.checked
            onClicked: root.clicked()
        }
    }
}

