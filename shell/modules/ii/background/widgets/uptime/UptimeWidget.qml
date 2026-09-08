import Quickshell
import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.ii.background.widgets

AbstractBackgroundWidget {
    id: root
    property QtObject resourceUsageLease: ResourceUsageLease {
        active: root.visible && (root.QsWindow.window?.visible ?? false)
    }
    configEntryName: "uptime"
    hoverEnabled: true
    implicitWidth: 320
    implicitHeight: col.implicitHeight + 24

    readonly property string uptimeStr: DateTime.uptime
    property string loadStr: "--"

    FileView {
        id: fvLoad
        path: "/proc/loadavg"
        preload: true
        blockLoading: false
        onLoaded: root.updateLoad()
    }
    Timer {
        interval: 5000
        running: root.visible
        repeat: true
        onTriggered: fvLoad.reload()
    }
    function updateLoad() {
        const t = fvLoad.text().trim().split(" ")
        if (t.length>=3) root.loadStr = t[0]+" / "+t[1]+" / "+t[2]
    }

    Rectangle {
        id: bg; anchors.fill: parent; radius: Appearance.rounding.large; color: Appearance.colors.colLayer1; opacity: 0.92
        border.width: 1; border.color: Appearance.colors.colLayer0Border
        StyledRectangularShadow { target: bg; z: -1 }
    }
    ColumnLayout {
        id: col; anchors.centerIn: parent; width: parent.width - 24; spacing: 10
        RowLayout { Layout.fillWidth: true; MaterialSymbol { text: "schedule"; iconSize: 18; color: Appearance.colors.colPrimary } StyledText { text: Translation.tr("Uptime"); font.weight: Font.Medium; color: Appearance.colors.colOnLayer1 } Item{Layout.fillWidth:true} StyledText { text: root.uptimeStr; color: Appearance.colors.colPrimary; font.weight: Font.Medium } }
        Rectangle { Layout.fillWidth: true; height:1; color: Appearance.colors.colLayer0Border; opacity:0.5 }
        RowLayout { Layout.fillWidth: true; MaterialSymbol { text: "monitoring"; iconSize: 18; color: Appearance.colors.colSecondary } StyledText { text: Translation.tr("Load Avg"); color: Appearance.colors.colOnLayer1 } Item{Layout.fillWidth:true} StyledText { text: root.loadStr; font.pixelSize: Appearance.font.pixelSize.small; color: Appearance.colors.colOnLayer1 } }
        RowLayout { Layout.fillWidth: true; MaterialSymbol { text: "memory"; iconSize: 14; color: Appearance.colors.colSubtext } StyledText { text: Math.round(ResourceUsage.memoryUsedPercentage*100)+"% RAM · "+Math.round(ResourceUsage.cpuUsage*100)+"% CPU"; font.pixelSize: Appearance.font.pixelSize.small; color: Appearance.colors.colSubtext; Layout.fillWidth:true; elide: Text.ElideRight } }
    }
}
