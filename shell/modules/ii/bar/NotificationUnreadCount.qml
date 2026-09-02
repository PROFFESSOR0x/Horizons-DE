import QtQuick
import qs.services
import qs.modules.common
import qs.modules.common.widgets

MaterialSymbol {
    id: root
    readonly property bool showUnreadCount: Config.options.bar.indicators.notifications.showUnreadCount
    text: Notifications.silent ? "notifications_paused" : "notifications"
    iconSize: Appearance.font.pixelSize.larger
    color: Config.options.bar.cornerStyle === 3 ? Appearance.colors.colOnPrimary : Appearance.colors.colOnLayer1

    Rectangle {
        id: notifPing
        visible: !Notifications.silent && Notifications.unread > 0
        anchors {
            right: parent.right
            top: parent.top
            rightMargin: root.showUnreadCount ? 0 : 1
            topMargin: root.showUnreadCount ? 0 : 3
        }
        radius: Appearance.rounding.full
        color: Config.options.bar.cornerStyle === 3 ? Appearance.colors.colOnPrimary : Appearance.colors.colOnLayer0
        z: 1
        scale: 1
        // Entrance pop
        opacity: visible ? 1 : 0
        Behavior on scale { animation: Appearance.animation.clickBounce.numberAnimation.createObject(notifPing) }
        Behavior on opacity { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
        Behavior on implicitWidth { animation: Appearance.animation.elementMoveSmall.numberAnimation.createObject(notifPing) }
        Behavior on implicitHeight { animation: Appearance.animation.elementMoveSmall.numberAnimation.createObject(notifPing) }
        // Subtle breathing pulse when unread
        SequentialAnimation on scale {
            loops: Animation.Infinite
            running: notifPing.visible
            NumberAnimation { from: 1; to: 1.12; duration: 900; easing.type: Easing.InOutQuad }
            NumberAnimation { from: 1.12; to: 1; duration: 900; easing.type: Easing.InOutQuad }
        }
        Connections {
            target: Notifications
            function onUnreadChanged() {
                if (notifPing.visible) bounceOnce.restart()
            }
        }
        SequentialAnimation {
            id: bounceOnce
            NumberAnimation { target: notifPing; property: "scale"; from: 0.6; to: 1.18; duration: 180; easing.type: Easing.OutBack }
            NumberAnimation { target: notifPing; property: "scale"; from: 1.18; to: 1; duration: 220; easing.type: Easing.OutCubic }
        }

        implicitHeight: root.showUnreadCount ? Math.max(notificationCounterText.implicitWidth, notificationCounterText.implicitHeight) + 6 : 8
        implicitWidth: implicitHeight

        StyledText {
            id: notificationCounterText
            visible: root.showUnreadCount
            anchors.centerIn: parent
            font.pixelSize: Appearance.font.pixelSize.smallest
            color: Config.options.bar.cornerStyle === 3 ? Appearance.colors.colPrimary : Appearance.colors.colLayer0
            text: Notifications.unread
        }
    }
}
