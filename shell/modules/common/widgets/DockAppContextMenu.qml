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
    property var hostItem: null
    property var appEntry: null
    property var desktopEntry: null
    property string applicationId: appEntry?.appId ?? ""
    // Pinned applications do not have a live taskbar entry while closed.
    // Resolve their desktop file independently so launch actions stay useful.
    property var launchEntry: null
    // The dock's hover reveal would otherwise retract as soon as the mouse
    // enters this separate PopupWindow. The holder is local to the dock panel
    // that created the menu, so a context menu on one screen does not affect
    // another screen's dock.
    property var dockHold: null
    property real menuX: 0
    property real menuY: 0
    readonly property bool hasWindows: (appEntry?.toplevels?.length ?? 0) > 0
    readonly property bool pinned: applicationId !== "" && TaskbarApps.isPinned(applicationId)
    // A pinned entry is launchable by its desktop id even while the desktop
    // entry index is still warming up. Do not gray out its actions simply
    // because heuristicLookup has not completed yet.
    readonly property bool canLaunch: applicationId !== ""

    function showAt(x, y) {
        // DesktopEntries finishes indexing asynchronously. Re-resolve here,
        // when the user opens the menu, instead of retaining the null value
        // from the dock delegate's construction at shell startup.
        launchEntry = root.desktopEntry
            ?? (root.applicationId !== "" ? DesktopEntries.heuristicLookup(root.applicationId) : null)
        console.log("[Dock] launch entry: appId=" + root.applicationId
            + " resolved=" + Boolean(root.launchEntry))
        const point = root.hostItem?.mapToItem(root.hostWindow?.contentItem ?? null, x, y)
        menuX = point?.x ?? x
        menuY = point?.y ?? y
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
    function launch() {
        if (root.launchEntry) {
            root.launchEntry.execute()
            return
        }
        // `pinnedApps` stores desktop-entry ids. gtk-launch accepts that id
        // and gives us a reliable fallback while Quickshell is still indexing
        // entries, which is exactly when a closed dock item used to be gray.
        if (root.applicationId !== "")
            Quickshell.execDetached(["gtk-launch", root.applicationId])
    }
    function openInNewWorkspace() {
        const monitorName = WM.monitorFor(root.hostWindow?.screen)?.name ?? ""
        const workspaceId = WM.nextWorkspaceId()
        if (workspaceId < 1) {
            root.launch()
            return
        }
        // GlobalStates keeps the all-screens workspace mode coherent; the
        // normal path still targets the monitor that owns this dock.
        GlobalStates.activateWorkspace(workspaceId, monitorName)
        launchTimer.restart()
    }

    onVisibleChanged: {
        if (!root.dockHold) return
        if (root.visible) root.dockHold.openContextMenu = root
        else if (root.dockHold.openContextMenu === root) root.dockHold.openContextMenu = null
    }
    Component.onDestruction: {
        if (root.dockHold?.openContextMenu === root)
            root.dockHold.openContextMenu = null
    }

    Timer {
        id: launchTimer
        interval: 120
        repeat: false
        onTriggered: root.launch()
    }

    visible: false
    grabFocus: true
    color: "transparent"
    anchor {
        window: root.hostWindow
        // `menuX`/`menuY` are mapped to this panel window in showAt(), so the
        // popup grows from the actual right-click point and never from an
        // arbitrary dock edge.
        rect.x: root.menuX
        rect.y: root.menuY
        rect.width: 1
        rect.height: 1
        edges: Edges.Top | Edges.Left
        gravity: Edges.Bottom | Edges.Left
        adjustment: PopupAdjustment.All
    }
    implicitWidth: actions.implicitWidth + 12
    implicitHeight: actions.implicitHeight + 10

    Rectangle {
        id: menuBackground
        anchors.fill: parent
        StyledRectangularShadow { target: menuBackground; visible: root.visible }
        radius: Appearance.rounding.normal
        color: Appearance.colors.colLayer0
        border.width: 1
        border.color: Appearance.colors.colLayer0Border

        ColumnLayout {
            id: actions
            anchors.fill: parent
            anchors.margins: 5
            spacing: 1

            DockMenuAction {
                // Keep launch choices present for every item. Some desktop
                // entries arrive shortly after their taskbar counterpart;
                // a disabled action is clearer than a jumping menu layout.
                enabled: root.canLaunch
                symbolName: "open_in_new"
                menuLabel: Translation.tr("Open new window")
                onTriggered: root.launch()
            }
            DockMenuAction {
                enabled: root.canLaunch
                symbolName: "add_to_queue"
                menuLabel: Translation.tr("Open in new workspace")
                onTriggered: root.openInNewWorkspace()
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
                visible: root.applicationId !== "" && !root.pinned
                symbolName: "keep"
                menuLabel: Translation.tr("Keep on dock")
                onTriggered: TaskbarApps.togglePin(root.applicationId)
            }
            DockMenuAction {
                visible: root.applicationId !== "" && root.pinned
                symbolName: "remove_circle"
                menuLabel: Translation.tr("Remove from dock")
                onTriggered: TaskbarApps.togglePin(root.applicationId)
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
            // Inline component ids are not lexically visible in QML. The
            // action is parented by actions -> menuBackground -> PopupWindow.
            parent.parent.parent.close()
        }
        contentItem: RowLayout {
            id: row
            anchors.fill: parent
            anchors.leftMargin: 10
            anchors.rightMargin: 12
            spacing: 10
            MaterialSymbol { text: parent.parent.symbolName; iconSize: 18; color: Appearance.colors.colOnLayer0 }
            StyledText {
                Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
                text: parent.parent.menuLabel
                horizontalAlignment: Text.AlignLeft
                color: Appearance.colors.colOnLayer0
                font.pixelSize: Appearance.font.pixelSize.small
            }
        }
    }
}
