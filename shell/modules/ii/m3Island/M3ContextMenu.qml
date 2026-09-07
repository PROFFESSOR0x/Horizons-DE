pragma ComponentBehavior: Bound
import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Layouts
import Quickshell

// Right-click quick-actions menu for the island. It uses a real, compact
// PopupWindow anchored at the exact click point in the island PanelWindow,
// so compositor edge adjustment can choose the safe side of the bar.
PopupWindow {
    id: root
    property var hostWindow: null
    property var hostItem: null
    property real menuX: 0
    property real menuY: 0
    // Each entry: { icon, label, visible, action }
    property var entries: []

    signal dismissed()

    function showAt(x, y) {
        const point = root.hostItem?.mapToItem(root.hostWindow?.contentItem ?? null, x, y)
        root.menuX = point?.x ?? x
        root.menuY = point?.y ?? y
        root.visible = true
    }
    function close() {
        root.visible = false
        root.dismissed()
    }

    visible: false
    grabFocus: true
    color: "transparent"
    anchor {
        window: root.hostWindow
        rect.x: root.menuX
        rect.y: root.menuY
        rect.width: 1
        rect.height: 1
        edges: Edges.Bottom | Edges.Left
        gravity: Edges.Top | Edges.Left
        adjustment: PopupAdjustment.All
    }
    implicitWidth: column.implicitWidth + 12
    implicitHeight: column.implicitHeight + 10

    Rectangle {
        id: menuBg
        anchors.fill: parent
        StyledRectangularShadow { target: menuBg; visible: root.visible }
        radius: Appearance.rounding.normal
        color: Appearance.colors.colLayer0
        border.width: 1
        border.color: Appearance.colors.colLayer0Border

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
                                Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
                                text: entryLoader.modelData.label || ""
                                horizontalAlignment: Text.AlignLeft
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
