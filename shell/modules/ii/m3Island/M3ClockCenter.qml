import qs.modules.common
import qs.modules.common.widgets
import qs.services
import QtQuick
import QtQuick.Layouts
import Quickshell

Item {
    id: root
    property string clockStyle: Config.options.m3Island.clockStyle // m3 | minimal | digital
    property bool showDate: Config.options.m3Island.clockShowDate
    property bool showSeconds: Config.options.m3Island.clockShowSeconds
    property bool use24Hour: Config.options.m3Island.clockUse24h
    implicitWidth: clockLoader.implicitWidth
    implicitHeight: Appearance.sizes.barHeight

    // Use the shell-wide format verbatim. This keeps the island in sync with
    // the selected 12/24-hour mode, AM/PM casing, and custom clock formats.
    readonly property string configuredTimeFormat: Config.options?.time?.format ?? "hh:mm"
    function formatWithSeconds(format) {
        if (!showSeconds || /s/.test(format)) return format
        const suffixMatch = format.match(/\s+(?:AP|ap)$/)
        const suffix = suffixMatch ? suffixMatch[0] : ""
        const base = suffixMatch ? format.slice(0, -suffix.length) : format
        return base + ":ss" + suffix
    }
    function formatForHourMode(format) {
        let result = format
        if (use24Hour) {
            result = result.replace(/h{1,2}/, "HH")
            return result.replace(/\s+(?:AP|ap)$/, "")
        }
        result = result.replace(/H{1,2}/, "h")
        return /(?:AP|ap)/.test(result) ? result : result + " AP"
    }
    readonly property string timeFormat: formatWithSeconds(formatForHourMode(configuredTimeFormat))
    readonly property string displayTime: Qt.locale().toString(clock.date, timeFormat)

    // DateTime is intentionally minute-precision by default. The island owns a
    // seconds clock so enabling seconds here takes effect immediately.
    SystemClock {
        id: clock
        precision: root.showSeconds ? SystemClock.Seconds : SystemClock.Minutes
    }

    // Scroll handling (volume/mediaSeek/layoutCycle) is centralized in
    // M3IslandContent's islandWheelHandler so it covers the whole pill, not
    // just the clock, and so the three modes never compete for the same
    // wheel event.

    // Reuse DateTime service
    Loader {
        id: clockLoader
        anchors.centerIn: parent
        sourceComponent: {
            if (root.clockStyle === "minimal") return minimalComp
            if (root.clockStyle === "digital") return digitalComp
            return m3Comp
        }
    }

    Component {
        id: m3Comp
        RowLayout {
            spacing: 6
            property var suffixMatch: root.displayTime.match(/\s+([AaPp][Mm])$/)
            property string ampm: suffixMatch ? suffixMatch[1] : ""
            property string timeOnly: ampm === "" ? root.displayTime : root.displayTime.slice(0, -ampm.length).trim()
            StyledText {
                visible: root.showDate
                font.pixelSize: Appearance.font.pixelSize.small
                color: Appearance.colors.colOnPrimaryContainer
                text: DateTime.longDate
                Layout.alignment: Qt.AlignVCenter
                leftPadding: 4
            }
            Rectangle {
                implicitWidth: timeText.implicitWidth + 16
                implicitHeight: 26
                radius: Appearance.rounding.full
                color: Appearance.colors.colPrimary
                StyledText {
                    id: timeText
                    anchors.centerIn: parent
                    font.pixelSize: Appearance.font.pixelSize.smallie
                    color: Appearance.colors.colOnPrimary
                    font.weight: Font.Bold
                    font.features: { "tnum": 1 }
                    text: timeOnly
                }
            }
            Rectangle {
                visible: ampm !== ""
                implicitWidth: ampmText.implicitWidth + 10
                implicitHeight: 26
                radius: Appearance.rounding.full
                color: Appearance.colors.colTertiaryContainer
                Layout.leftMargin: -8
                StyledText {
                    id: ampmText
                    anchors.centerIn: parent
                    font.pixelSize: Appearance.font.pixelSize.smaller
                    color: Appearance.colors.colOnTertiaryContainer
                    text: ampm
                }
            }
        }
    }

    Component {
        id: minimalComp
        RowLayout {
            spacing: 6
            StyledText {
                visible: root.showDate
                font.pixelSize: Appearance.font.pixelSize.small
                color: Appearance.colors.colOnLayer1
                text: DateTime.longDate
            }
            StyledText {
                visible: root.showDate
                font.pixelSize: Appearance.font.pixelSize.small
                color: Appearance.colors.colOnLayer1
                text: "•"
            }
            StyledText {
                font.pixelSize: Appearance.font.pixelSize.large
                color: Appearance.colors.colOnLayer1
                font.features: { "tnum": 1 }
                text: root.displayTime
            }
        }
    }

    Component {
        id: digitalComp
        ColumnLayout {
            spacing: 0
            anchors.centerIn: parent
            StyledText {
                Layout.alignment: Qt.AlignHCenter
                font.pixelSize: Appearance.font.pixelSize.larger
                font.weight: Font.Bold
                font.features: { "tnum": 1 }
                color: Appearance.colors.colOnLayer1
                text: root.displayTime
            }
            StyledText {
                visible: root.showDate
                Layout.alignment: Qt.AlignHCenter
                font.pixelSize: Appearance.font.pixelSize.smallest
                color: Appearance.colors.colOnLayer1
                text: DateTime.shortDate
            }
        }
    }
}
