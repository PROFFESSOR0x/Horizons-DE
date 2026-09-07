pragma ComponentBehavior: Bound
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Layouts
import Quickshell

// A small PopupWindow instead of QtQuick.Controls.Menu.  It remains attached
// to a bar on the correct monitor and works the same under Hyprland, niri and
// i3/Xwayland.
PopupWindow {
    id: root
    property var hostWindow: null
    property var hostItem: null
    property int workspaceId: -1
    property string monitorName: ""
    property real menuX: 0
    property real menuY: 0

    function showAt(workspace, monitor, x, y) {
        workspaceId = workspace
        monitorName = monitor ?? ""
        const point = root.hostItem?.mapToItem(root.hostWindow?.contentItem ?? null, x, y)
        menuX = point?.x ?? x
        menuY = point?.y ?? y
        visible = true
    }
    function close() { visible = false }
    function selected() { return GlobalStates.selectedWorkspaces(workspaceId, monitorName) }
    function closeSelected(force) {
        GlobalStates.closeWorkspaceWindows(selected(), force)
        GlobalStates.workspaceSelection = []
        GlobalStates.workspaceSelectionAnchor = null
    }

    visible: false
    grabFocus: true
    color: "transparent"
    anchor {
        window: root.hostWindow
        // The anchor point is mapped from the exact right-click position to
        // the bar window. Do not set `item` here: PopupAnchor intentionally
        // clears `window` when item is set, leaving the popup unanchored.
        rect.x: root.menuX
        rect.y: root.menuY
        rect.width: 1
        rect.height: 1
        edges: Edges.Bottom | Edges.Left
        gravity: Edges.Top | Edges.Left
        adjustment: PopupAdjustment.All
    }
    implicitWidth: menuColumn.implicitWidth + 12
    implicitHeight: menuColumn.implicitHeight + 10

    Rectangle {
        id: menuBackground
        anchors.fill: parent
        StyledRectangularShadow { target: menuBackground; visible: root.visible }
        radius: Appearance.rounding.normal
        color: Appearance.colors.colLayer0
        border.width: 1
        border.color: Appearance.colors.colLayer0Border

        ColumnLayout {
            id: menuColumn
            anchors.fill: parent
            anchors.margins: 5
            spacing: 1

            WorkspaceMenuAction {
                dismissAction: () => root.close()
                symbolName: GlobalStates.workspaceSelectionContains(root.workspaceId, root.monitorName)
                    ? "deselect" : "select"
                menuLabel: GlobalStates.workspaceSelectionContains(root.workspaceId, root.monitorName)
                    ? Translation.tr("Deselect workspace") : Translation.tr("Select workspace")
                onTriggered: GlobalStates.toggleWorkspaceSelection(root.workspaceId, root.monitorName)
            }
            WorkspaceMenuAction {
                dismissAction: () => root.close()
                visible: root.selected().length > 1
                symbolName: "link"
                menuLabel: Translation.tr("Link selected workspaces")
                onTriggered: GlobalStates.linkSelectedWorkspaces(root.workspaceId, root.monitorName)
            }
            WorkspaceMenuAction {
                dismissAction: () => root.close()
                // Detaching is the companion action for the global
                // multi-monitor workspace mode; manual groups stay linked
                // until explicitly changed through their own selection.
                visible: Config.options.workspaceLinking.unifiedMultiMonitor
                    && GlobalStates.linkedWorkspaceMembers(root.workspaceId, root.monitorName).length > 1
                symbolName: "link_off"
                menuLabel: Translation.tr("Separate this workspace from the group")
                onTriggered: GlobalStates.detachWorkspace(root.workspaceId, root.monitorName)
            }
            Rectangle {
                Layout.fillWidth: true
                Layout.topMargin: 3
                Layout.bottomMargin: 3
                implicitHeight: 1
                color: Appearance.colors.colLayer0Border
            }
            WorkspaceMenuAction {
                dismissAction: () => root.close()
                symbolName: "close"
                menuLabel: Translation.tr("Close all windows")
                onTriggered: root.closeSelected(false)
            }
            WorkspaceMenuAction {
                dismissAction: () => root.close()
                symbolName: "dangerous"
                menuLabel: Translation.tr("End task for all windows")
                onTriggered: root.closeSelected(true)
            }
        }
    }

    component WorkspaceMenuAction: RippleButton {
        required property string symbolName
        required property string menuLabel
        property var dismissAction: null
        signal triggered()
        Layout.fillWidth: true
        implicitWidth: row.implicitWidth + 24
        implicitHeight: 34
        buttonRadius: Appearance.rounding.small
        opacity: enabled ? 1 : 0.45
        onClicked: {
            triggered()
            dismissAction?.()
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
