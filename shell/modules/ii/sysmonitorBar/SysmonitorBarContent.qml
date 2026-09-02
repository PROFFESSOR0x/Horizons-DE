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

    // ── Local network speed tracking (like NetworkSpeed.qml) ─────────────────
    property real netDown: 0
    property real netUp: 0
    property real _prevRx: -1
    property real _prevTx: -1
    property real _prevTime: 0
    property list<real> netDownHistory: []
    property list<real> netUpHistory: []
    readonly property int historyLen: Config?.options.resources.historyLength ?? 60

    Process {
        id: netProc
        command: ["cat", "/proc/net/dev"]
        stdout: StdioCollector {
            onStreamFinished: {
                let rx = 0, tx = 0
                const lines = text.split("\n")
                for (const line of lines) {
                    const sep = line.indexOf(":")
                    if (sep < 0) continue
                    const iface = line.slice(0, sep).trim()
                    if (!iface || iface === "lo") continue
                    const fields = line.slice(sep + 1).trim().split(/\s+/)
                    if (fields.length < 9) continue
                    rx += Number(fields[0]) || 0
                    tx += Number(fields[8]) || 0
                }
                const now = Date.now()
                if (root._prevTime > 0 && now > root._prevTime) {
                    const dt = (now - root._prevTime) / 1000
                    root.netDown = root._prevRx >= 0 ? Math.max(0, (rx - root._prevRx) / dt) : 0
                    root.netUp   = root._prevTx >= 0 ? Math.max(0, (tx - root._prevTx) / dt) : 0
                    const dh = [...root.netDownHistory, root.netDown]
                    const uh = [...root.netUpHistory,   root.netUp]
                    root.netDownHistory = dh.length > root.historyLen ? dh.slice(-root.historyLen) : dh
                    root.netUpHistory   = uh.length > root.historyLen ? uh.slice(-root.historyLen) : uh
                }
                root._prevRx   = rx
                root._prevTx   = tx
                root._prevTime = now
            }
        }
    }

    Timer {
        interval: Config?.options.resources.updateInterval ?? 3000
        running: true
        repeat: true
        onTriggered: { netProc.running = false; netProc.running = true }
    }

    function formatRate(bytes) {
        if (bytes < 1024)        return bytes.toFixed(0)  + " B/s"
        if (bytes < 1048576)     return (bytes / 1024).toFixed(1) + " KB/s"
        if (bytes < 1073741824)  return (bytes / 1048576).toFixed(1) + " MB/s"
        return (bytes / 1073741824).toFixed(2) + " GB/s"
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
                warningThreshold: 85
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
                warningThreshold: 90
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
                warningThreshold: 85
                graphColor: Appearance.colors.colOutline
                history: ResourceUsage.swapUsageHistory
            }

            // Network ↓
            MonitorItem {
                visible: Config.options.sysmonitorBar.showNetwork
                iconName: "download"
                label: "NET ↓"
                percentage: 0
                valueText: root.formatRate(root.netDown)
                showGraph: false
                graphColor: Appearance.colors.colPrimary
                history: root.netDownHistory
            }

            // Network ↑
            MonitorItem {
                visible: Config.options.sysmonitorBar.showNetwork
                iconName: "upload"
                label: "NET ↑"
                percentage: 0
                valueText: root.formatRate(root.netUp)
                showGraph: false
                graphColor: Appearance.colors.colSecondary
                history: root.netUpHistory
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
