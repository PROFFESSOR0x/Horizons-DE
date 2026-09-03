pragma ComponentBehavior: Bound
import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Layouts
import Quickshell

// Right-click quick-actions menu for the island. Anchored to the island's own
// PanelWindow (full-width, fixed-height) and positioned at the click point,
// following the same PopupWindow + anchor{window,edges,gravity} pattern used
// by DragApps.qml's window preview - a plain full-window overlay is simpler
// and more robust here than trying to anchor a second layer-shell surface to
// a MouseArea inside another window.
PopupWindow {
    id: root
    property var hostWindow: null
    property real menuX: 0
    property real menuY: 0
    // Each entry: { icon, label, visible, action }
    property var entries: []

    signal dismissed()

    function showAt(x, y) {
        root.menuX = x
        root.menuY = y
        root.visible = true
    }
    function close() {
        root.visible = false
        root.dismissed()
    }

    visible: false
    color: "transparent"
    anchor {
        window: root.hostWindow
        edges: Edges.Top | Edges.Left
        gravity: Edges.Top | Edges.Left
        adjustment: PopupAdjustment.None
    }
    implicitWidth: root.hostWindow ? root.hostWindow.width : 1
    implicitHeight: root.hostWindow ? root.hostWindow.height : 1

    MouseArea {
        anchors.fill: parent
        onClicked: root.close()

        StyledRectangularShadow { target: menuBg; visible: root.visible }

        Rectangle {
            id: menuBg
            x: Math.max(4, Math.min(root.menuX, root.width - width - 4))
            y: Math.max(4, Math.min(root.menuY, root.height - height - 4))
            width: column.implicitWidth + 12
            height: column.implicitHeight + 10
            radius: Appearance.rounding.normal
            color: Appearance.colors.colLayer0
            border.width: 1
            border.color: Appearance.colors.colLayer0Border
            clip: true

            // Swallow clicks inside the menu so they don't fall through to the
            // full-window MouseArea and dismiss the menu before onClicked below runs.
            MouseArea { anchors.fill: parent; onClicked: mouse => mouse.accepted = true }

            ColumnLayout {
                id: column
                anchors.fill: parent
                anchors.margins: 5
                spacing: 1

                Repeater {
                    model: root.entries
                    delegate: Loader {
                        id: entryLoader
                        required property var modelData
                        Layout.fillWidth: true
                        active: modelData.visible !== false
                        visible: active
                        sourceComponent: RippleButton {
                            id: entryButton
                            Layout.fillWidth: true
                            implicitWidth: rowContent.implicitWidth + 24
                            implicitHeight: 34
                            buttonRadius: Appearance.rounding.small
                            onClicked: {
                                entryLoader.modelData.action()
                                root.close()
                            }
                            contentItem: RowLayout {
                                id: rowContent
                                anchors.fill: parent
                                anchors.leftMargin: 10
                                anchors.rightMargin: 12
                                spacing: 10
                                MaterialSymbol {
                                    text: entryLoader.modelData.icon || "circle"
                                    iconSize: 18
                                    color: Appearance.colors.colOnLayer0
                                }
                                StyledText {
                                    Layout.fillWidth: true
                                    text: entryLoader.modelData.label || ""
                                    font.pixelSize: Appearance.font.pixelSize.small
                                    color: Appearance.colors.colOnLayer0
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
