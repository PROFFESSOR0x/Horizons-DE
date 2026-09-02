import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.common.widgets

MouseArea {
    id: root

    property bool vertical: false

    implicitWidth: vertical ? 36 : speedColumn.implicitWidth + 8
    implicitHeight: vertical ? speedColumn.implicitHeight + 6 : 32

    hoverEnabled: !Config.options.bar.tooltips.clickToShow

    function formatRate(rate, compact) {
        return NetworkStats.formatRate(rate, compact)
    }

    TextMetrics {
        id: regularRateMetrics
        text: "999.9 MB/s"
        font.pixelSize: Appearance.font.pixelSize.smallest
        font.weight: Font.Medium
    }

    component SpeedLine: RowLayout {
        id: speedLine

        required property string iconName
        required property real rate
        required property color accentColor

        readonly property string rateText: root.formatRate(rate, root.vertical)

        spacing: root.vertical ? 1 : 3

        MaterialSymbol {
            text: speedLine.iconName
            iconSize: root.vertical
                ? Appearance.font.pixelSize.smallest
                : Appearance.font.pixelSize.smaller
            color: speedLine.accentColor
            opacity: speedLine.rate > 0 ? 1 : 0.45

            Behavior on opacity {
                animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
            }
        }

        StyledText {
            Layout.preferredWidth: root.vertical ? -1 : regularRateMetrics.width
            horizontalAlignment: Text.AlignRight
            text: speedLine.rateText
            color: Appearance.colors.colOnLayer1
            font.pixelSize: Appearance.font.pixelSize.smallest
            font.weight: Font.Medium
            font.features: { "tnum": 1 }
        }
    }

    ColumnLayout {
        id: speedColumn
        anchors.centerIn: parent
        spacing: -3

        SpeedLine {
            iconName: "arrow_upward"
            rate: NetworkStats.uploadBytesPerSecond
            accentColor: Appearance.colors.colTertiary
        }

        SpeedLine {
            iconName: "arrow_downward"
            rate: NetworkStats.downloadBytesPerSecond
            accentColor: Appearance.colors.colPrimary
        }
    }

    NetworkSpeedPopup {
        hoverTarget: root
        downloadSpeed: NetworkStats.downloadBytesPerSecond
        uploadSpeed: NetworkStats.uploadBytesPerSecond
        downloadedBytes: NetworkStats.downloadedBytes
        uploadedBytes: NetworkStats.uploadedBytes
    }
}
