import qs.modules.common
import qs.modules.common.widgets
import qs.services
import QtQuick
import QtQuick.Layouts

// Compact CPU + RAM combo glyph, purpose-built for the island's pill format
// (the bar's own Resources widget is a full circular-progress pair, too wide
// for a hover-peek row). Backed by the real ResourceUsage polling service -
// the same data source the bar and sysmonitorBar widgets use.
Item {
    id: root
    // Accepted for API parity with bar/ widgets loaded through the same
    // configureM3Widget() path; this widget only ever renders one way.
    property bool useM3IslandConfig: false
    property bool isMaterial: true

    readonly property real cpu: ResourceUsage.cpuUsage
    readonly property real mem: ResourceUsage.memoryUsedPercentage

    implicitWidth: row.implicitWidth
    implicitHeight: Appearance.sizes.barHeight

    StyledToolTip {
        text: Translation.tr("CPU %1% • RAM %2%")
            .arg(Math.round(root.cpu * 100))
            .arg(Math.round(root.mem * 100))
    }

    RowLayout {
        id: row
        anchors.centerIn: parent
        spacing: 6

        RowLayout {
            spacing: 3
            MaterialSymbol {
                text: "memory"
                iconSize: Appearance.font.pixelSize.small
                color: Appearance.colors.colOnLayer1
            }
            StyledText {
                text: Math.round(root.cpu * 100) + "%"
                font.pixelSize: Appearance.font.pixelSize.smallest
                font.features: { "tnum": 1 }
                color: Appearance.colors.colOnLayer1
            }
        }

        Rectangle { width: 1; height: 12; color: Appearance.colors.colOutlineVariant; opacity: 0.5 }

        RowLayout {
            spacing: 3
            MaterialSymbol {
                text: "dns"
                iconSize: Appearance.font.pixelSize.small
                color: Appearance.colors.colOnLayer1
            }
            StyledText {
                text: Math.round(root.mem * 100) + "%"
                font.pixelSize: Appearance.font.pixelSize.smallest
                font.features: { "tnum": 1 }
                color: Appearance.colors.colOnLayer1
            }
        }
    }
}
