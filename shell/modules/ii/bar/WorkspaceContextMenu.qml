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
    property int workspaceId: -1
    property string monitorName: ""
    property real menuX: 0
    property real menuY: 0

    function showAt(workspace, monitor, x, y) {
        workspaceId = workspace
        monitorName = monitor ?? ""
        menuX = x
        menuY = y
        visible = true
    }
    function close() { visible = false }
    function selected() { return GlobalStates.selectedWorkspaces(workspaceId, monitorName) }
    function closeSelected(force) {
        GlobalStates.closeWorkspaceWindows(selected(), force)
        GlobalStates.workspaceSelection = []
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
            implicitWidth: menuColumn.implicitWidth + 12
            implicitHeight: menuColumn.implicitHeight + 10
            radius: Appearance.rounding.normal
            color: Appearance.colors.colLayer0
            border.width: 1
            border.color: Appearance.colors.colLayer0Border

            MouseArea { anchors.fill: parent; onClicked: mouse => mouse.accepted = true }
            ColumnLayout {
                id: menuColumn
                anchors.fill: parent
                anchors.margins: 5
                spacing: 1

                WorkspaceMenuAction {
                    symbolName: GlobalStates.workspaceSelectionContains(root.workspaceId, root.monitorName)
                        ? "deselect" : "select"
                    menuLabel: GlobalStates.workspaceSelectionContains(root.workspaceId, root.monitorName)
                        ? Translation.tr("Deselect workspace") : Translation.tr("Select workspace")
                    onTriggered: GlobalStates.toggleWorkspaceSelection(root.workspaceId, root.monitorName)
                }
                WorkspaceMenuAction {
                    visible: root.selected().length > 1
                    symbolName: "link"
                    menuLabel: Translation.tr("Link selected workspaces")
                    onTriggered: GlobalStates.linkSelectedWorkspaces(root.workspaceId, root.monitorName)
                }
                WorkspaceMenuAction {
                    visible: GlobalStates.linkedWorkspaceMembers(root.workspaceId, root.monitorName).length > 1
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
                    symbolName: "close"
                    menuLabel: Translation.tr("Close all windows")
                    onTriggered: root.closeSelected(false)
                }
                WorkspaceMenuAction {
                    symbolName: "dangerous"
                    menuLabel: Translation.tr("End task for all windows")
                    onTriggered: root.closeSelected(true)
                }
            }
        }
    }

    component WorkspaceMenuAction: RippleButton {
        required property string symbolName
        required property string menuLabel
        signal triggered()
        Layout.fillWidth: true
        implicitWidth: row.implicitWidth + 24
        implicitHeight: 34
        buttonRadius: Appearance.rounding.small
        opacity: enabled ? 1 : 0.45
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
