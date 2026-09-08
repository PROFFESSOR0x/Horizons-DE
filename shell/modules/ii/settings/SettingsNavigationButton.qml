import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets

RippleButton {
    id: root
    property string iconName: "settings"
    property bool selected: false
    Layout.fillWidth: true
    implicitHeight: Math.max(38, label.implicitHeight + 14)
    horizontalPadding: 10
    buttonRadius: Appearance.rounding.small
    colBackground: selected ? Appearance.colors.colSecondaryContainer : "transparent"
    colBackgroundHover: selected ? Appearance.colors.colSecondaryContainerHover : Appearance.colors.colLayer2Hover
    contentItem: RowLayout {
        spacing: 8
        MaterialSymbol { text: root.iconName; iconSize: 18; color: Appearance.colors.colOnLayer0 }
        StyledText {
            id: label
            Layout.fillWidth: true
            Layout.minimumWidth: 0
            text: root.text
            wrapMode: Text.WordWrap
            font.pixelSize: Appearance.font.pixelSize.small
            color: Appearance.colors.colOnLayer0
        }
    }
}
