import QtQuick
import QtQuick.Layouts
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.widgets.widgetCanvas
import qs.modules.ii.background.widgets

AbstractBackgroundWidget {
    id: root
    configEntryName: "systemHistory"
    hoverEnabled: true

    property bool showCpu: root.configEntry.showCpu ?? true
    property bool showMemory: root.configEntry.showMemory ?? true
    property bool showSwap: root.configEntry.showSwap ?? false

    implicitWidth: 420
    implicitHeight: col.implicitHeight + 24

    Rectangle {
        id: bg
        anchors.fill: parent
        radius: Appearance.rounding.large
        color: Appearance.colors.colLayer1
        opacity: 0.92
        border.width: 1
        border.color: Appearance.colors.colLayer0Border
        StyledRectangularShadow { target: bg; z: -1 }
    }

    ColumnLayout {
        id: col
        anchors.centerIn: parent
        width: parent.width - 24
        spacing: 10

        RowLayout {
            Layout.fillWidth: true
            StyledText {
                text: Translation.tr("System History")
                font.pixelSize: Appearance.font.pixelSize.large
                font.weight: Font.Medium
                color: Appearance.colors.colOnLayer1
            }
            Item { Layout.fillWidth: true }
            StyledText {
                text: ResourceUsage.historyLength + " pts"
                font.pixelSize: Appearance.font.pixelSize.smaller
                color: Appearance.colors.colSubtext
            }
        }

        // CPU graph
        ColumnLayout {
            visible: root.showCpu
            Layout.fillWidth: true
            spacing: 4
            RowLayout {
                Layout.fillWidth: true
                MaterialSymbol { text: "memory"; iconSize: 14; color: Appearance.colors.colPrimary }
                StyledText { text: "CPU " + Math.round(ResourceUsage.cpuUsage*100) + "%"; font.pixelSize: Appearance.font.pixelSize.small; color: Appearance.colors.colOnLayer1 }
                StyledText { visible: ResourceUsage.cpuTemp>0; text: "· " + ResourceUsage.cpuTemp.toFixed(1) + "°C"; font.pixelSize: Appearance.font.pixelSize.small; color: Appearance.colors.colSubtext }
                Item { Layout.fillWidth: true }
                StyledText { text: ResourceUsage.maxAvailableCpuString; font.pixelSize: Appearance.font.pixelSize.smaller; color: Appearance.colors.colSubtext }
            }
            Rectangle {
                Layout.fillWidth: true; Layout.preferredHeight: 56; radius: Appearance.rounding.small; color: Appearance.colors.colLayer2; clip: true
                Graph {
                    anchors.fill: parent; anchors.margins: 6
                    values: ResourceUsage.cpuUsageHistory
                    color: Appearance.colors.colPrimary
                    fillOpacity: 0.35
                }
            }
        }

        // Memory graph
        ColumnLayout {
            visible: root.showMemory
            Layout.fillWidth: true
            spacing: 4
            RowLayout {
                Layout.fillWidth: true
                MaterialSymbol { text: "hard_drive_2"; iconSize: 14; color: Appearance.colors.colSecondary }
                StyledText { text: "RAM " + Math.round(ResourceUsage.memoryUsedPercentage*100) + "%"; font.pixelSize: Appearance.font.pixelSize.small; color: Appearance.colors.colOnLayer1 }
                Item { Layout.fillWidth: true }
                StyledText { text: ResourceUsage.maxAvailableMemoryString; font.pixelSize: Appearance.font.pixelSize.smaller; color: Appearance.colors.colSubtext }
            }
            Rectangle {
                Layout.fillWidth: true; Layout.preferredHeight: 56; radius: Appearance.rounding.small; color: Appearance.colors.colLayer2; clip: true
                Graph {
                    anchors.fill: parent; anchors.margins: 6
                    values: ResourceUsage.memoryUsageHistory
                    color: Appearance.colors.colSecondary
                    fillOpacity: 0.35
                }
            }
        }

        // Swap graph
        ColumnLayout {
            visible: root.showSwap && ResourceUsage.swapTotal > 1*1024
            Layout.fillWidth: true
            spacing: 4
            RowLayout {
                MaterialSymbol { text: "swap_horiz"; iconSize: 14; color: Appearance.colors.colTertiary }
                StyledText { text: "Swap " + Math.round(ResourceUsage.swapUsedPercentage*100) + "%"; font.pixelSize: Appearance.font.pixelSize.small; color: Appearance.colors.colOnLayer1 }
                Item { Layout.fillWidth: true }
                StyledText { text: ResourceUsage.maxAvailableSwapString; font.pixelSize: Appearance.font.pixelSize.smaller; color: Appearance.colors.colSubtext }
            }
            Rectangle {
                Layout.fillWidth: true; Layout.preferredHeight: 40; radius: Appearance.rounding.small; color: Appearance.colors.colLayer2; clip: true
                Graph {
                    anchors.fill: parent; anchors.margins: 6
                    values: ResourceUsage.swapUsageHistory
                    color: Appearance.colors.colTertiary
                    fillOpacity: 0.35
                }
            }
        }

        // Toggles
        RowLayout {
            Layout.fillWidth: true
            spacing: 6
            RippleButtonWithIcon {
                materialIcon: root.showCpu ? "check" : "close"
                mainText: "CPU"
                onClicked: { root.showCpu = !root.showCpu; root.configEntry.showCpu = root.showCpu }
                colBackground: root.showCpu ? Appearance.colors.colPrimaryContainer : Appearance.colors.colLayer2
            }
            RippleButtonWithIcon {
                materialIcon: root.showMemory ? "check" : "close"
                mainText: "RAM"
                onClicked: { root.showMemory = !root.showMemory; root.configEntry.showMemory = root.showMemory }
                colBackground: root.showMemory ? Appearance.colors.colSecondaryContainer : Appearance.colors.colLayer2
            }
            RippleButtonWithIcon {
                materialIcon: root.showSwap ? "check" : "close"
                mainText: "Swap"
                onClicked: { root.showSwap = !root.showSwap; root.configEntry.showSwap = root.showSwap }
                colBackground: root.showSwap ? Appearance.colors.colTertiaryContainer : Appearance.colors.colLayer2
            }
            Item { Layout.fillWidth: true }
            StyledText {
                text: Config.options.resources.updateInterval + "ms"
                font.pixelSize: Appearance.font.pixelSize.smaller
                color: Appearance.colors.colSubtext
            }
        }
    }
}
