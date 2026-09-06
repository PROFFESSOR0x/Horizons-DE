import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets

Rectangle {
    id: root
    property var shape: MaterialShape.Shape.Clover4Leaf
    property string title
    property string icon: ""
    property var bgColor: Appearance.colors.colSecondaryContainer
    default property alias data: sectionContent.data

    Layout.fillWidth: true
    implicitHeight: sectionLayout.implicitHeight + 32
    color: Appearance.colors.colLayer0
    radius: Appearance.rounding.large
    border.width: 1
    border.color: Appearance.colors.colLayer0Border

    ColumnLayout {
        id: sectionLayout
        anchors.fill: parent
        anchors.margins: 16
        spacing: 10

        RowLayout {
            spacing: 8
            MaterialShapeWrappedMaterialSymbol {
                text: root.icon
                iconSize: Appearance.font.pixelSize.large + 1
                wrappedShape: root.shape
                color: root.bgColor
            }
            StyledText {
                text: root.title
                font.pixelSize: Appearance.font.pixelSize.larger
                font.weight: Font.Medium
                color: Appearance.colors.colOnSecondaryContainer
            }
            Item { Layout.fillWidth: true }
        }

        // A section has a distinct header and a single, quiet divider before
        // its controls. Together with GroupedList's individual setting cards,
        // this gives the Settings window a clear visual rhythm.
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 1
            color: Appearance.colors.colOutlineVariant
            opacity: 0.55
        }

        ColumnLayout {
            id: sectionContent
            Layout.fillWidth: true
            spacing: 8
        }
    }
}
