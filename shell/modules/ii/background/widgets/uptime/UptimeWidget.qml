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
    configEntryName: "uptime"
    hoverEnabled: true
    implicitWidth: 320
    implicitHeight: col.implicitHeight + 24

    property string uptimeStr: "--"
    property string loadStr: "--"

    FileView { id: fvUptime; path: "/proc/uptime" }
    FileView { id: fvLoad; path: "/proc/loadavg" }

    Timer {
        interval: 5000; running: true; repeat: true
        onTriggered: { fvUptime.reload(); fvLoad.reload() }
        Component.onCompleted: { fvUptime.reload(); fvLoad.reload() }
    }
    Connections { target: fvUptime; function onFileChanged() { updateUptime() } }
    Connections { target: fvLoad; function onFileChanged() { updateLoad() } }
    function updateUptime() {
        const txt = fvUptime.text()
        const sec = parseFloat(txt.split(" ")[0])
        if (isNaN(sec)) return
        const d = Math.floor(sec/86400)
        const h = Math.floor((sec%86400)/3600)
        const m = Math.floor((sec%3600)/60)
        if (d>0) root.uptimeStr = d+"d "+h+"h "+m+"m"
        else if (h>0) root.uptimeStr = h+"h "+m+"m"
        else root.uptimeStr = m+"m"
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
