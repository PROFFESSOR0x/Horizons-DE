import QtQuick
import qs.modules.common

// Draws CAVA's raw ASCII data. CAVA uses a 0..1000 range when
// ascii_max_range is 1000; normalizing anywhere else is what caused the old
// desktop visualizer to look either almost still or abruptly saturated.
Item {
    id: root

    property var points: []
    property int barCount: 50
    property real barSpacing: 6
    property real maximumBarHeight: 220
    property real noiseFloorPercent: 1.5
    // Fast rise + slower fall is the usual spectrum-meter response. This is
    // temporal smoothing, not a per-frame QML animation, so it cannot queue
    // dozens of overlapping animations when CAVA sends a new frame.
    property real attack: 0.68
    property real release: 0.24
    property bool mirrored: false
    property real centerGap: 4
    // Editing must make the spectrum's footprint understandable even while
    // no media is playing. This is a deliberately simple travelling pulse,
    // not fake audio; it only runs in a layout editor and stops immediately
    // when that editor closes.
    property bool simulate: false
    property real simulationPhase: 0

    readonly property real rawMaximum: 1000
    readonly property real floorValue: Math.max(0, Math.min(95, noiseFloorPercent)) / 100 * rawMaximum
    readonly property real columnWidth: Math.max(2, (width - barSpacing * (barCount - 1)) / Math.max(1, barCount))
    property var displayPoints: []

    function normalized(rawValue) {
        const raw = Math.max(0, Math.min(rawMaximum, Number(rawValue) || 0))
        const linear = Math.max(0, (raw - floorValue) / Math.max(1, rawMaximum - floorValue))
        // A mild gamma curve keeps quiet frequency bands readable while
        // retaining CAVA's actual relative amplitudes.
        return Math.pow(linear, 0.72)
    }

    function targetAt(index) {
        if (simulate) {
            const position = index / Math.max(1, barCount - 1)
            const distance = Math.abs(position - simulationPhase)
            // A narrow crest moves cleanly from the first column to the last
            // and then starts again. A small tail makes its shape readable
            // without looking like real audio activity.
            return Math.max(0, 1 - distance * 8) * 0.82
        }
        if (!points || points.length === 0) return 0
        // Present the spectrum symmetrically from the centre outwards. CAVA's
        // left-to-right data is still the source of truth, but duplicating it
        // around the centre prevents one quiet half of the frequency range
        // from making an entire side of a wide desktop widget look dead.
        const fromCenter = Math.abs((index + 0.5) / Math.max(1, barCount) - 0.5) * 2
        const rawIndex = Math.min(points.length - 1,
            Math.floor(fromCenter * (points.length - 1)))
        let average = 0
        for (let i = 0; i < points.length; i++) average += Number(points[i]) || 0
        average /= Math.max(1, points.length)
        // Preserve the band shape while sharing a small amount of total
        // energy. Every area then reacts to the track without becoming a
        // uniform, fake-looking block.
        return normalized((Number(points[rawIndex]) || 0) * 0.82 + average * 0.18)
    }

    function updateDisplayPoints() {
        const previous = displayPoints
        const next = new Array(barCount)
        for (let i = 0; i < barCount; i++) {
            const target = targetAt(i)
            const current = previous[i] ?? 0
            const response = target > current ? attack : release
            next[i] = current + (target - current) * Math.max(0.01, Math.min(1, response))
        }
        // Reassigning a fresh array is important: changing an array element in
        // place is invisible to QML bindings in Repeater delegates.
        root.displayPoints = next
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

    function hasAudibleInput() {
        if (!points || points.length === 0) return false
        return points.some(point => (Number(point) || 0) > floorValue + 1)
    }

    // CAVA may stop with either an empty array or a final all-zero frame. In
    // both cases, keep ticking the release tail until every bar is actually
    // gone; otherwise the last spectrum frame remains as dead bounds.
    Timer {
        interval: 34
        repeat: true
        running: !root.simulate && !root.hasAudibleInput()
            && root.displayPoints.some(point => point > 0.002)
        onTriggered: root.updateDisplayPoints()
    }

    Repeater {
        model: root.barCount
        Item {
            required property int index
            x: index * (root.columnWidth + root.barSpacing)
            width: root.columnWidth
            height: root.height
            readonly property real amplitude: root.displayPoints[index] ?? 0
            readonly property real barHeight: amplitude * root.maximumBarHeight

            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: root.mirrored ? parent.verticalCenter : parent.bottom
                anchors.bottomMargin: root.mirrored ? root.centerGap / 2 : 0
                width: parent.width
                height: parent.barHeight
                radius: width / 2
                color: Qt.rgba(
                    Appearance.colors.colPrimaryContainer.r
                        + (Appearance.colors.colPrimary.r - Appearance.colors.colPrimaryContainer.r) * parent.amplitude,
                    Appearance.colors.colPrimaryContainer.g
                        + (Appearance.colors.colPrimary.g - Appearance.colors.colPrimaryContainer.g) * parent.amplitude,
                    Appearance.colors.colPrimaryContainer.b
                        + (Appearance.colors.colPrimary.b - Appearance.colors.colPrimaryContainer.b) * parent.amplitude,
                    0.55 + parent.amplitude * 0.45)
                visible: height > 0.5
            }

            Rectangle {
                visible: root.mirrored && height > 0.5
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.verticalCenter
                anchors.topMargin: root.centerGap / 2
                width: parent.width
                height: parent.barHeight
                radius: width / 2
                color: Qt.rgba(
                    Appearance.colors.colPrimaryContainer.r
                        + (Appearance.colors.colPrimary.r - Appearance.colors.colPrimaryContainer.r) * parent.amplitude,
                    Appearance.colors.colPrimaryContainer.g
                        + (Appearance.colors.colPrimary.g - Appearance.colors.colPrimaryContainer.g) * parent.amplitude,
                    Appearance.colors.colPrimaryContainer.b
                        + (Appearance.colors.colPrimary.b - Appearance.colors.colPrimaryContainer.b) * parent.amplitude,
                    0.55 + parent.amplitude * 0.45)
            }
        }
    }
}
