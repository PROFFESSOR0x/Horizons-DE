import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Mpris
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.ii.background.widgets

AbstractBackgroundWidget {
    id: root

    configEntryName: "visualizer"

    readonly property MprisPlayer activePlayer: MprisController.activePlayer
    readonly property bool isPlaying: activePlayer?.isPlaying ?? false
    readonly property list<real> points: GlobalStates.visualizerPoints

    // This widget is driven by cava's raw output (see MediaControls.qml's
    // cavaProc), i.e. it is re-laid-out on every single frame cava emits.
    // Everything below is sized around that fact:
    //
    //  - barCount is capped instead of being derived from the screen width
    //    alone. At the old 4px bar / 8px gap it worked out to ~160 bars on a
    //    1080p screen, all of them re-measured, re-coloured and (before this)
    //    individually animated per frame - which is what made the desktop
    //    visualizer stall the whole shell while music played, since QML runs
    //    the UI on one thread and every other panel waits behind it.
    //  - cava only produces `bars = 50` values anyway (scripts/cava/
    //    raw_output_config.txt), so anything past that was interpolated
    //    detail that isn't in the source data to begin with.
    //  - bars are stretched, not multiplied, to keep covering the full width.
    readonly property int maxBars: 64
    readonly property int barCount: Math.max(1, Math.min(maxBars, Math.floor(screenWidth / 24)))
    readonly property real barSpacing: 8
    readonly property real barWidth: Math.max(4, (screenWidth - barSpacing * (barCount - 1)) / barCount * 0.55)
    property real maxBarHeight: 220
    property real maxVisualizerValue: 1000

    // Hoisted out of the per-bar colour binding: these are two singleton
    // lookups per palette change instead of six per bar per frame.
    readonly property color colLow: Appearance.colors.colPrimaryContainer
    readonly property color colHigh: Appearance.colors.colPrimary

    readonly property var smoothedPoints: {
        let raw = points
        if (!raw || raw.length === 0) return Array(barCount).fill(0)
        let count = barCount
        let mapped = new Array(count)
        let rawLenM1 = raw.length - 1

        for (let i = 0; i < count; i++) {
            let progress = i / (count - 1 || 1)
            let relPos = progress * rawLenM1
            let low = Math.floor(relPos)
            let high = Math.ceil(relPos)
            let mix = relPos - low
            mapped[i] = (raw[low] * (1 - mix)) + (raw[high] * (high < raw.length ? mix : 0))
        }

        let smoothed = new Array(count)
        let sW = 0.2
        for (let j = 0; j < count; j++) {
            let p = mapped[Math.max(0, j - 1)]
            let n = mapped[Math.min(count - 1, j + 1)]
            smoothed[j] = (p * sW) + (mapped[j] * (1.0 - 2 * sW)) + (n * sW)
        }
        return smoothed
    }

    property real activityOpacity: 0
    Behavior on activityOpacity {
        NumberAnimation { duration: 500; easing.type: Easing.OutCubic }
    }

    Timer {
        id: silenceTimer
        interval: 1000
        onTriggered: root.activityOpacity = 0
    }

    onPointsChanged: {
        if (points.some(p => p > 0)) {
            root.activityOpacity = 1.0
            silenceTimer.restart()
        }
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
        opacity: root.activityOpacity
        // Nothing to draw between tracks: keeps the scene graph from
        // rebuilding a full row of (flat, minimum-height) bars while the
        // widget is faded out.
        visible: root.activityOpacity > 0

        Behavior on opacity {
            NumberAnimation { duration: 400; easing.type: Easing.OutCubic }
        }

        Repeater {
            model: root.barCount
            Rectangle {
                required property int index
                width: root.barWidth
                property real pointValue: {
                    const v = root.smoothedPoints[index] ?? 0
                    return Math.max(root.barWidth, (v / root.maxVisualizerValue) * root.maxBarHeight)
                }
                // No Behavior on height on purpose. cava already feeds
                // interpolated values at its own framerate, so a per-bar
                // NumberAnimation added `barCount` concurrently-running
                // animations to every frame while buying no extra smoothness.
                height: pointValue
                topLeftRadius: root.barWidth / 2
                topRightRadius: root.barWidth / 2
                anchors.bottom: parent.bottom

                property real intensity: pointValue / root.maxBarHeight
                color: Qt.rgba(
                    root.colHigh.r * intensity + root.colLow.r * (1 - intensity),
                    root.colHigh.g * intensity + root.colLow.g * (1 - intensity),
                    root.colHigh.b * intensity + root.colLow.b * (1 - intensity),
                    1
                )
            }
        }
    }
}
