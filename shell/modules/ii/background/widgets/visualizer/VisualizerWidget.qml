import QtQuick
import qs
import qs.services
import qs.modules.common
import qs.modules.ii.background.widgets

AbstractBackgroundWidget {
    id: root

    configEntryName: "visualizer"

    readonly property var visualizerConfig: Config.options.background.widgets.visualizer
    implicitWidth: Math.min(screenWidth, Math.max(240, visualizerConfig.width))
    implicitHeight: Math.min(screenHeight, Math.max(80, visualizerConfig.height))
    draggable: !Config.options.background.widgetsLocked

    FrequencyBars {
        anchors.centerIn: parent
        width: parent.width
        height: parent.height
        points: GlobalStates.visualizerPoints
        simulate: DesktopVisualizer.editingPreviewActive
        barCount: Math.max(8, Math.min(64, root.visualizerConfig.barCount))
        barSpacing: Math.max(0, root.visualizerConfig.spacing)
        maximumBarHeight: parent.height
        noiseFloorPercent: root.visualizerConfig.noiseFloor
        attack: root.visualizerConfig.attack
        release: root.visualizerConfig.release
    }
}
