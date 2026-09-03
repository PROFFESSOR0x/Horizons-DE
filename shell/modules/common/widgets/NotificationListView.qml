pragma ComponentBehavior: Bound

import qs.modules.common.widgets
import qs.modules.common
import qs.services
import QtQuick
import Quickshell

StyledListView { // Scrollable window
    id: root
    property bool popup: false
    // Hovering a card briefly expands it. Defaults to the shared Config option
    // so the main popup/history surfaces stay consistent with the M3 island.
    property bool expandOnHover: Config.options.notifications.expandOnHover ?? false
    property int hoverExpandDelay: Config.options.notifications.hoverExpandDelay ?? 180

    spacing: 3

    model: ScriptModel {
        values: {
            const values = root.popup ? Notifications.popupAppNameList : Notifications.appNameList
            return root.popup ? values.slice(0, Config.options.notifications.maxVisible ?? 4) : values
        }
    }
    delegate: NotificationGroup {
        required property int index
        required property var modelData
        popup: root.popup
        expandOnHover: root.expandOnHover
        hoverExpandDelay: root.hoverExpandDelay
        width: ListView.view.width // https://doc.qt.io/qt-6/qml-qtquick-listview.html
        notificationGroup: popup ?
            Notifications.popupGroupsByAppName[modelData] :
            Notifications.groupsByAppName[modelData]
    }
}
