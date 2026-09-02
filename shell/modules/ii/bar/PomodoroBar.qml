import QtQuick
import QtQuick.Layouts
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets

// A compact control that makes the existing Pomodoro service available in any
// configurable bar layout, rather than only inside the right sidebar.
RippleButton {
    id: root
    property bool vertical: Config.options.bar.vertical
    property bool isMaterial: Config.options.bar.cornerStyle === 3
    readonly property int total: Math.max(0, TimerService.pomodoroSecondsLeft)
    readonly property int minutes: Math.floor(total / 60)
    readonly property int seconds: total % 60

    implicitWidth: vertical ? 32 : content.implicitWidth + 10
    implicitHeight: vertical ? content.implicitHeight + 8 : 30
    buttonRadius: Appearance.rounding.full
    colBackground: isMaterial ? Appearance.colors.colPrimaryContainer : "transparent"
    colBackgroundHover: isMaterial ? Appearance.colors.colPrimaryContainerHover : Appearance.colors.colLayer1Hover
    colRipple: isMaterial ? Appearance.colors.colPrimaryContainerActive : Appearance.colors.colLayer1Active

    onClicked: {
        switch (Config.options.bar.pomodoro.clickAction) {
        case "reset": TimerService.resetPomodoro(); break
        case "sidebar": GlobalStates.sidebarRightOpen = true; break
        default: TimerService.togglePomodoro();
        }
    }

    contentItem: RowLayout {
        id: content
        anchors.centerIn: parent
        spacing: 4
        MaterialSymbol {
            text: TimerService.pomodoroBreak ? "coffee" : "timer"
            fill: TimerService.pomodoroRunning ? 1 : 0
            iconSize: Appearance.font.pixelSize.normal
            color: root.isMaterial ? Appearance.colors.colOnPrimaryContainer : Appearance.colors.colOnLayer1
        }
        StyledText {
            visible: !root.vertical
            font.pixelSize: Appearance.font.pixelSize.small
            color: root.isMaterial ? Appearance.colors.colOnPrimaryContainer : Appearance.colors.colOnLayer1
            text: (Config.options.bar.pomodoro.showLabel
                ? (TimerService.pomodoroBreak ? Translation.tr("Break ") : Translation.tr("Focus ")) : "")
                + minutes.toString().padStart(2, "0") + ":"
                + (Config.options.bar.pomodoro.showSeconds ? seconds.toString().padStart(2, "0") : "00")
        }
    }

    StyledToolTip {
        text: TimerService.pomodoroRunning ? Translation.tr("Click to pause timer") : Translation.tr("Click to start timer")
    }
}
