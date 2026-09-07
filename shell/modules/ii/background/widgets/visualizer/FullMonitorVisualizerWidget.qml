import QtQuick
import Quickshell.Services.Mpris
import qs
import qs.services
import qs.modules.common
import qs.modules.ii.background.widgets

// The original end4-pC desktop spectrum, retained as a separate widget.
// It deliberately fills the output width and is anchored to its bottom edge;
// it is a monitor decoration rather than a moveable canvas card.
AbstractBackgroundWidget {
    id: root

    configEntryName: "fullMonitorVisualizer"
    readonly property var visualizerConfig: Config.options.background.widgets.fullMonitorVisualizer
    readonly property MprisPlayer activePlayer: MprisController.activePlayer
    readonly property bool isPlaying: activePlayer?.isPlaying ?? false
    readonly property list<real> points: GlobalStates.visualizerPoints

    property real barWidth: visualizerConfig.barWidth
    property real barSpacing: visualizerConfig.spacing
    property real maxBarHeight: visualizerConfig.height
    property real maxVisualizerValue: 1000
    property real smoothingDuration: visualizerConfig.smoothingDuration
    readonly property int barCount: Math.max(1, Math.floor(screenWidth / (barWidth + barSpacing)))
    property bool simulate: DesktopVisualizer.editingPreviewActive
    property real simulationPhase: 0
    property var displayPoints: []

    function targetAt(index) {
        if (simulate) {
            const position = index / Math.max(1, barCount - 1)
            return Math.max(0, 1 - Math.abs(position - simulationPhase) * 8) * 0.82
        }
        if (!points || points.length === 0) return 0
        // Map around the centre so the entire monitor responds, rather than
        // leaving one side visually dead when a frequency range is quiet.
        const fromCenter = Math.abs((index + 0.5) / Math.max(1, barCount) - 0.5) * 2
        const rawIndex = Math.min(points.length - 1, Math.floor(fromCenter * (points.length - 1)))
        let average = 0
        for (let i = 0; i < points.length; ++i) average += Number(points[i]) || 0
        average /= Math.max(1, points.length)
        return Math.max(0, Math.min(1, ((Number(points[rawIndex]) || 0) * 0.82 + average * 0.18)
            / maxVisualizerValue))
    }
    function updateDisplayPoints() {
        const previous = displayPoints
        const next = new Array(barCount)
        for (let i = 0; i < barCount; ++i) {
            const target = targetAt(i)
            const current = previous[i] ?? 0
            const response = target > current ? 0.68 : 0.24
            next[i] = current + (target - current) * response
        }
        displayPoints = next
    }
    function hasAudibleInput() {
        return !!points && points.some(point => (Number(point) || 0) > 1)
    }
    onPointsChanged: updateDisplayPoints()
    onBarCountChanged: updateDisplayPoints()
    onSimulateChanged: updateDisplayPoints()
    Component.onCompleted: updateDisplayPoints()

    Timer {
        interval: 34
        repeat: true
        running: root.simulate
        onTriggered: {
            root.simulationPhase += 0.025
            if (root.simulationPhase > 1) root.simulationPhase = 0
            root.updateDisplayPoints()
        }
    }
    Timer {
        interval: 34
        repeat: true
        running: !root.simulate && !root.hasAudibleInput()
            && root.displayPoints.some(point => point > 0.002)
        onTriggered: root.updateDisplayPoints()
    }

    implicitWidth: screenWidth
    implicitHeight: maxBarHeight + 20
    x: 0
    y: screenHeight - implicitHeight
    draggable: false

    Row {
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: root.barSpacing
        Repeater {
            model: root.barCount
            Rectangle {
                required property int index
                width: root.barWidth
                readonly property real amplitude: (root.displayPoints[index] ?? 0) * root.maxBarHeight
                height: amplitude
                visible: amplitude > 0.5
                topLeftRadius: root.barWidth / 2
                topRightRadius: root.barWidth / 2
                anchors.bottom: parent.bottom
                readonly property real intensity: amplitude / root.maxBarHeight
                color: Qt.rgba(
                    Appearance.colors.colPrimary.r * intensity + Appearance.colors.colPrimaryContainer.r * (1 - intensity),
                    Appearance.colors.colPrimary.g * intensity + Appearance.colors.colPrimaryContainer.g * (1 - intensity),
                    Appearance.colors.colPrimary.b * intensity + Appearance.colors.colPrimaryContainer.b * (1 - intensity), 1)
                Behavior on height { NumberAnimation { duration: root.smoothingDuration; easing.type: Easing.OutQuad } }
            }
        }
    }
}
