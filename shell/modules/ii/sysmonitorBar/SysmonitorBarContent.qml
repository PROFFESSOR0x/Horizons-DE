import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes
import Quickshell
import Quickshell.Io
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions

Item {
    id: root
    implicitHeight: Appearance.sizes.barHeight
    width: parent.width

    // Network speed comes from the shared qs.services.NetworkStats poller
    // (also used by bar/NetworkSpeed.qml) rather than a local independent one.
    function formatRate(bytes) {
        return NetworkStats.formatRate(bytes, false)
    }

    // ─────────────────────────────────────────────────────────────────────────

    Rectangle {
        id: barBackground
        anchors.fill: parent
        color: Config.options.bar.showBackground
            ? (Config.options.bar.followFrameColor
                ? Appearance.getColorFromName(Config.options.bar.frameColor)
                : Appearance.colors.colLayer0)
            : "transparent"
        radius: Config.options.bar.cornerStyle === 1 ? Appearance.rounding.windowRounding : 0
        border.width: Config.options.bar.cornerStyle === 1 ? 1 : 0
        border.color: Appearance.colors.colLayer0Border
    }

    Item {
        id: contentContainer
        anchors.fill: barBackground
        anchors.margins: 6

        RowLayout {
            id: monitorRow
            anchors.fill: parent
            spacing: 12

            // CPU
            MonitorItem {
                visible: Config.options.sysmonitorBar.showCpu
                iconName: "memory"
                label: "CPU"
                percentage: ResourceUsage.cpuUsage / 100
                valueText: Math.round(ResourceUsage.cpuUsage) + "%"
                warningThreshold: Config.options.sysmonitorBar.cpuWarningThreshold
                graphColor: Appearance.colors.colPrimary
                history: ResourceUsage.cpuUsageHistory
            }

            // CPU Temp
            MonitorItem {
                visible: Config.options.sysmonitorBar.showCpuTemp
                iconName: "thermostat"
                label: "TEMP"
                percentage: Math.min(ResourceUsage.cpuTemp / 100, 1)
                valueText: Math.round(ResourceUsage.cpuTemp) + "°C"
                warningThreshold: Config.options.sysmonitorBar.tempWarningThreshold
                graphColor: Appearance.colors.colSecondary
                history: []   // no history for temp in service
            }

            // RAM
            MonitorItem {
                visible: Config.options.sysmonitorBar.showRam
                iconName: "planner_review"
                label: "RAM"
                percentage: ResourceUsage.memoryUsedPercentage
                valueText: Math.round(ResourceUsage.memoryUsedPercentage * 100) + "%"
                warningThreshold: Config.options.sysmonitorBar.memoryWarningThreshold
                graphColor: Appearance.colors.colTertiary
                history: ResourceUsage.memoryUsageHistory
            }

            // Disk
            MonitorItem {
                visible: Config.options.sysmonitorBar.showDisk
                iconName: "hard_drive"
                label: "DISK"
                percentage: ResourceUsage.diskUsedPercentage
                valueText: Math.round(ResourceUsage.diskUsedPercentage * 100) + "%"
                warningThreshold: Config.options.sysmonitorBar.diskWarningThreshold
                graphColor: Appearance.colors.colError
                history: ResourceUsage.diskUsageHistory
            }

            // Swap
            MonitorItem {
                visible: Config.options.sysmonitorBar.showSwap
                iconName: "swap_horiz"
                label: "SWAP"
                percentage: ResourceUsage.swapUsedPercentage
                valueText: Math.round(ResourceUsage.swapUsedPercentage * 100) + "%"
                warningThreshold: Config.options.sysmonitorBar.swapWarningThreshold
                graphColor: Appearance.colors.colOutline
                history: ResourceUsage.swapUsageHistory
            }

            // Network ↓
            MonitorItem {
                visible: Config.options.sysmonitorBar.showNetwork
                iconName: "download"
                label: "NET ↓"
                percentage: 0
                valueText: root.formatRate(NetworkStats.downloadBytesPerSecond)
                showGraph: false
                graphColor: Appearance.colors.colPrimary
                history: NetworkStats.downloadHistory
            }

            // Network ↑
            MonitorItem {
                visible: Config.options.sysmonitorBar.showNetwork
                iconName: "upload"
                label: "NET ↑"
                percentage: 0
                valueText: root.formatRate(NetworkStats.uploadBytesPerSecond)
                showGraph: false
                graphColor: Appearance.colors.colSecondary
                history: NetworkStats.uploadHistory
            }

            Item { Layout.fillWidth: true }
        }
    }

    // ── Monitor item component ────────────────────────────────────────────────
    component MonitorItem: Item {
        id: monitorItem

        required property string iconName
        required property string label
        required property real   percentage     // 0-1
        required property string valueText
        required property color  graphColor
        property real  warningThreshold: 0      // percent 0-100
        property list<real> history: []
        property bool showGraph: true

        Layout.fillHeight: true
        implicitWidth: monitorItem.showGraph ? 80 : miniLayout.implicitWidth + 12

        readonly property bool isWarning: warningThreshold > 0 && percentage * 100 >= warningThreshold

        Rectangle {
            anchors.fill: parent
            color: monitorItem.isWarning
                ? ColorUtils.transparentize(Appearance.colors.colError, 0.12)
                : "transparent"
            radius: Appearance.rounding.unsharpenmore

            // Mini graph at the bottom
            Item {
                id: graphArea
                visible: monitorItem.showGraph
                clip: true
                anchors {
                    left: parent.left; right: parent.right; bottom: parent.bottom
                    leftMargin: 4; rightMargin: 4; bottomMargin: 4
                }
                height: 18

                Shape {
                    anchors.fill: parent
                    ShapePath {
                        strokeWidth: 1.5
                        strokeColor: monitorItem.graphColor
                        fillColor: "transparent"
                        startX: 0; startY: graphArea.height
                        PathPolyline {
                            path: {
                                const h = monitorItem.history
                                if (!h || h.length < 2) return [Qt.point(0, graphArea.height)]
                                const maxVal = Math.max(...h, 0.001)
                                const step = graphArea.width / Math.max(h.length - 1, 1)
                                return h.map((v, i) => Qt.point(
                                    i * step,
                                    graphArea.height - (v / maxVal) * graphArea.height
                                ))
                            }
                        }
                    }
                }
            }

            // Label + value
            RowLayout {
                id: miniLayout
                anchors {
                    top: parent.top; left: parent.left
                    topMargin: 4; leftMargin: 6
                }
                spacing: 4

                MaterialSymbol {
                    text: monitorItem.iconName
                    iconSize: Appearance.font.pixelSize.normal
                    color: monitorItem.isWarning
                        ? Appearance.colors.colError
                        : Appearance.colors.colOnLayer1
                }

                ColumnLayout {
                    spacing: 0
                    StyledText {
                        text: monitorItem.label
                        font.pixelSize: Appearance.font.pixelSize.smallest
                        font.weight: Font.Bold
                        color: Appearance.colors.colOnLayer1
                        opacity: 0.65
                    }
                    StyledText {
                        text: monitorItem.valueText
                        font.pixelSize: Appearance.font.pixelSize.small
                        font.features: { "tnum": 1 }
                        color: monitorItem.isWarning
                            ? Appearance.colors.colError
                            : Appearance.colors.colOnLayer1
                    }
                }
            }
        }
    }
}
