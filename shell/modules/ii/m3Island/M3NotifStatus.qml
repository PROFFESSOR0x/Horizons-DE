import qs.modules.common
import qs.modules.common.widgets
import qs.services
import QtQuick
import QtQuick.Layouts

// Compact "focus status + notification count" combo, purpose-built for the
// island pill. Backed by the real Notifications service (silent/unread) -
// the same state the sidebar's notification list and the bell quick toggle
// use. Clicking toggles Do Not Disturb for real, it isn't a UI-only fake.
Item {
    id: root
    property bool useM3IslandConfig: false
    property bool isMaterial: true

    readonly property bool dnd: Notifications.silent
    readonly property int unread: Notifications.unread

    implicitWidth: row.implicitWidth
    implicitHeight: Appearance.sizes.barHeight

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: Notifications.silent = !Notifications.silent
    }

    StyledToolTip {
        text: root.dnd
            ? Translation.tr("Do Not Disturb is on")
            : Translation.tr("%1 unread notification(s)").arg(root.unread)
    }

    RowLayout {
        id: row
        anchors.centerIn: parent
        spacing: 4
        MaterialSymbol {
            text: root.dnd ? "notifications_paused" : (root.unread > 0 ? "notifications_active" : "notifications")
            fill: (root.unread > 0 && !root.dnd) ? 1 : 0
            iconSize: Appearance.font.pixelSize.small
            color: Appearance.colors.colOnLayer1
        }
        StyledText {
            visible: !root.dnd && root.unread > 0
            text: root.unread
            font.pixelSize: Appearance.font.pixelSize.smallest
            font.features: { "tnum": 1 }
            color: Appearance.colors.colOnLayer1
        }
    }
}
