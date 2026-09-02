import qs.modules.common
import qs.modules.common.widgets
import qs.services
import QtQuick
import QtQuick.Layouts

// Displays system uptime, backed by the existing DateTime.uptime service
// (which already polls /proc/uptime on a timer) - no new polling added.
Item {
    id: root
    property bool vertical: Config.options.bar.vertical
    property bool isMaterial: Config.options.bar.cornerStyle === 3

    implicitWidth: vertical ? Appearance.sizes.verticalBarWidth : (contentLoader.item?.implicitWidth ?? 0)
    implicitHeight: vertical ? (contentLoader.item?.implicitHeight ?? 0) : Appearance.sizes.barHeight

    StyledToolTip {
        text: Translation.tr("System uptime")
    }

    Loader {
        id: contentLoader
        anchors.centerIn: parent
        sourceComponent: root.vertical ? colContent : rowContent
    }

    Component {
        id: rowContent
        RowLayout {
            spacing: 4
            MaterialSymbol {
                Layout.alignment: Qt.AlignVCenter
                text: "avg_pace"
                iconSize: Appearance.font.pixelSize.normal
                color: root.isMaterial ? Appearance.colors.colPrimary : Appearance.colors.colOnLayer1
            }
            StyledText {
                Layout.alignment: Qt.AlignVCenter
                font.pixelSize: Appearance.font.pixelSize.small
                color: root.isMaterial ? Appearance.colors.colPrimary : Appearance.colors.colOnLayer1
                text: DateTime.uptime
            }
        }
    }

    Component {
        id: colContent
        ColumnLayout {
            spacing: 4
            MaterialSymbol {
                Layout.alignment: Qt.AlignHCenter
                text: "avg_pace"
                iconSize: Appearance.font.pixelSize.normal
                color: root.isMaterial ? Appearance.colors.colPrimary : Appearance.colors.colOnLayer1
            }
            StyledText {
                Layout.alignment: Qt.AlignHCenter
                font.pixelSize: Appearance.font.pixelSize.small
                color: root.isMaterial ? Appearance.colors.colPrimary : Appearance.colors.colOnLayer1
                text: DateTime.uptime
            }
        }
    }
}
