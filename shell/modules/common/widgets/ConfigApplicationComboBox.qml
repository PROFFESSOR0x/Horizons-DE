import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.common.widgets

RowLayout {
    id: root

    property string text: ""
    property string description: ""
    property string buttonIcon: ""
    property string currentValue: ""
    property string valueMode: "appId"
    property bool allowEmpty: false
    property string emptyLabel: Translation.tr("System default")
    property real fieldWidth: 300

    signal selected(var newValue)

    spacing: 10
    Layout.leftMargin: 8
    Layout.rightMargin: 8

    OptionalMaterialSymbol {
        icon: root.buttonIcon
        iconSize: Appearance.font.pixelSize.larger
        opacity: root.enabled ? 1 : 0.4
    }

    ColumnLayout {
        Layout.fillWidth: true
        Layout.minimumWidth: 0
        spacing: 0
        StyledText {
            Layout.fillWidth: true
            Layout.minimumWidth: 0
            text: root.text
            color: Appearance.colors.colOnSecondaryContainer
            opacity: root.enabled ? 1 : 0.4
            elide: Text.ElideRight
        }
        StyledText {
            Layout.fillWidth: true
            Layout.minimumWidth: 0
            visible: root.description.length > 0
            text: root.description
            font.pixelSize: Appearance.font.pixelSize.smaller
            color: Appearance.colors.colSubtext
            wrapMode: Text.Wrap
            opacity: root.enabled ? 1 : 0.4
        }
    }

    ApplicationComboBox {
        Layout.preferredWidth: root.fieldWidth
        Layout.minimumWidth: Math.min(180, root.fieldWidth)
        Layout.alignment: Qt.AlignVCenter
        enabled: root.enabled
        currentValue: root.currentValue
        valueMode: root.valueMode
        allowEmpty: root.allowEmpty
        emptyLabel: root.emptyLabel
        onSelected: newValue => root.selected(newValue)
    }
}
