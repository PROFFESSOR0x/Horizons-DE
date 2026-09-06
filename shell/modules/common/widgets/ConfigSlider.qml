import qs.modules.common.widgets
import qs.modules.common
import QtQuick
import QtQuick.Layouts
import qs.services

RowLayout {
    id: root
    spacing: 10
    Layout.leftMargin: 8
    Layout.rightMargin: 8

    property string text: ""
    property string buttonIcon: ""
    property alias value: slider.value
    property alias stepSize: slider.stepSize
    property alias stopIndicatorValues: slider.stopIndicatorValues
    property bool usePercentTooltip: true
    property real from: slider.from
    property real to: slider.to
    property real textWidth: 120
    // Keep the interactive part compact so the setting label and description
    // retain the majority of a wide settings card.
    property real controlWidth: 184
    property bool showLabel: true

    RowLayout {
        id: row
        Layout.fillWidth: true
        visible: root.showLabel
        spacing: 10

        OptionalMaterialSymbol {
            id: iconWidget
            icon: root.buttonIcon
            iconSize: Appearance.font.pixelSize.larger
        }
        StyledText {
            id: labelWidget
            Layout.fillWidth: true
            Layout.preferredWidth: root.textWidth
            Layout.minimumWidth: 0
            text: root.text
            color: Appearance.colors.colOnSecondaryContainer
            elide: Text.ElideRight
        }
    }
    StyledSlider {
        id: slider
        Layout.fillWidth: false
        Layout.minimumWidth: 120
        Layout.preferredWidth: Math.min(root.controlWidth, Math.max(120, root.width * 0.32))
        Layout.maximumWidth: root.controlWidth
        configuration: StyledSlider.Configuration.XS
        usePercentTooltip: root.usePercentTooltip
        value: root.value
        from: root.from
        to: root.to
    }
}
