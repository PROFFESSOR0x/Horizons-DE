import QtQuick
import qs
import qs.modules.common
import qs.modules.ii.background.widgets

// A freely placeable, two-sided spectrum. It uses the same CAVA stream and
// response model as VisualizerWidget, so enabling it never starts a second
// audio capture process.
AbstractBackgroundWidget {
    id: root

    configEntryName: "visualizerMirror"
    readonly property var visualizerConfig: Config.options.background.widgets.visualizerMirror
    implicitWidth: Math.min(screenWidth, Math.max(240, visualizerConfig.width))
    implicitHeight: Math.min(screenHeight, Math.max(100, visualizerConfig.height))
    draggable: !Config.options.background.widgetsLocked

    FrequencyBars {
        anchors.centerIn: parent
        width: parent.width
        height: parent.height
        points: GlobalStates.visualizerPoints
        mirrored: true
        barCount: Math.max(8, Math.min(64, root.visualizerConfig.barCount))
        barSpacing: Math.max(0, root.visualizerConfig.spacing)
        maximumBarHeight: Math.max(1, (parent.height - centerGap) / 2)
        noiseFloorPercent: root.visualizerConfig.noiseFloor
        attack: root.visualizerConfig.attack
        release: root.visualizerConfig.release
    }
}
