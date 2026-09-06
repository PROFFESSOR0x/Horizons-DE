pragma ComponentBehavior: Bound
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Layouts
import Quickshell

// Shared by running and pinned dock items. Context actions are intentionally
// derived from the live toplevel list, so a pinned-but-closed application is
// never offered meaningless Close/End-task actions.
PopupWindow {
    id: root
    property var hostWindow: null
    property var appEntry: null
    property var desktopEntry: null
    property real menuX: 0
    property real menuY: 0
    readonly property bool hasWindows: (appEntry?.toplevels?.length ?? 0) > 0
    readonly property bool pinned: appEntry ? TaskbarApps.isPinned(appEntry.appId) : false

    function showAt(x, y) {
        menuX = x
        menuY = y
        visible = true
    }
    function close() { visible = false }
    function activeWindow() {
        return appEntry?.toplevels?.find(window => window.activated) ?? appEntry?.toplevels?.[0] ?? null
    }
    function windowId(window) {
        return window?.id ?? window?.HyprlandToplevel?.address ?? window?.address ?? ""
    }
    function backendWindow(window) {
        const id = windowId(window)
        return WM.windowList.find(candidate => String(candidate.id) === String(id)
            || String(candidate.address) === String(id)) ?? null
    }
    function closeActive() {
        const window = activeWindow()
        if (!window) return
        const id = windowId(window)
        if (id !== "") WM.closeWindow(id)
        else window.close?.()
    }
    function endTask() {
        const window = activeWindow()
        if (!window) return
        const id = windowId(window)
        const backend = backendWindow(window)
        if (id !== "") WM.forceCloseWindow(id, window.pid ?? backend?.pid)
        else window.close?.()
    }

    visible: false
    color: "transparent"
    anchor {
        window: root.hostWindow
        edges: Edges.Top | Edges.Left
        gravity: Edges.Top | Edges.Left
        adjustment: PopupAdjustment.None
    }
    implicitWidth: root.hostWindow?.width ?? 1
    implicitHeight: root.hostWindow?.height ?? 1

    MouseArea {
        anchors.fill: parent
        onClicked: root.close()
        StyledRectangularShadow { target: menuBackground; visible: root.visible }
        Rectangle {
            id: menuBackground
            x: Math.max(4, Math.min(root.menuX, root.width - width - 4))
            y: Math.max(4, Math.min(root.menuY, root.height - height - 4))
            implicitWidth: actions.implicitWidth + 12
            implicitHeight: actions.implicitHeight + 10
            radius: Appearance.rounding.normal
            color: Appearance.colors.colLayer0
            border.width: 1
            border.color: Appearance.colors.colLayer0Border

            MouseArea { anchors.fill: parent; onClicked: mouse => mouse.accepted = true }
            ColumnLayout {
                id: actions
                anchors.fill: parent
                anchors.margins: 5
                spacing: 1

                DockMenuAction {
                    symbolName: "open_in_new"
                    menuLabel: Translation.tr("Open new window")
                    onTriggered: root.desktopEntry?.execute()
                }
                DockMenuAction {
                    visible: root.hasWindows
                    symbolName: "close"
                    menuLabel: Translation.tr("Close window")
                    onTriggered: root.closeActive()
                }
                DockMenuAction {
                    visible: root.hasWindows
                    symbolName: "dangerous"
                    menuLabel: Translation.tr("End task")
                    onTriggered: root.endTask()
                }
                Rectangle {
                    Layout.fillWidth: true
                    Layout.topMargin: 3
                    Layout.bottomMargin: 3
                    implicitHeight: 1
                    color: Appearance.colors.colLayer0Border
                }
                DockMenuAction {
                    visible: !root.pinned
                    symbolName: "keep"
                    menuLabel: Translation.tr("Keep on dock")
                    onTriggered: TaskbarApps.togglePin(root.appEntry.appId)
                }
                DockMenuAction {
                    visible: root.pinned
                    symbolName: "remove_circle"
                    menuLabel: Translation.tr("Remove from dock")
                    onTriggered: TaskbarApps.togglePin(root.appEntry.appId)
                }
            }
        }
    }

    component DockMenuAction: RippleButton {
        required property string symbolName
        required property string menuLabel
        signal triggered()
        Layout.fillWidth: true
        implicitWidth: row.implicitWidth + 24
        implicitHeight: 34
        buttonRadius: Appearance.rounding.small
        onClicked: {
            triggered()
            root.close()
        }
        contentItem: RowLayout {
            id: row
            anchors.fill: parent
            anchors.leftMargin: 10
            anchors.rightMargin: 12
            spacing: 10
            MaterialSymbol { text: parent.parent.symbolName; iconSize: 18; color: Appearance.colors.colOnLayer0 }
            StyledText { text: parent.parent.menuLabel; color: Appearance.colors.colOnLayer0; font.pixelSize: Appearance.font.pixelSize.small }
        }
    }
}
