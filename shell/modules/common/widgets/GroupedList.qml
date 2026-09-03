import qs.modules.common
import QtQuick
import QtQuick.Layouts

Item {
    id: root
    // The settings rows stay in this ColumnLayout for their entire lifetime.
    // Reparenting them into Repeater delegates changes this list while the
    // delegates are being built; Qt then drops/reorders rows unpredictably.
    default property alias items: contentArea.data
    property real bigRadius: Appearance.rounding.normal
    property real smallRadius: Appearance.rounding.unsharpenmore
    property color bgcolor: Appearance.colors.colLayer1
    property real itemVerticalPadding: 24
    Layout.fillWidth: true
    implicitHeight: contentArea.implicitHeight

    ColumnLayout {
        id: contentArea
        width: parent.width
        spacing: 2

        Component.onCompleted: {
            // Reserve the same vertical space the old wrapper rectangles
            // supplied, but retain the original layout parent of each row.
            for (let i = 0; i < children.length; ++i) {
                const child = children[i]
                child.Layout.topMargin = root.itemVerticalPadding / 2
                child.Layout.bottomMargin = root.itemVerticalPadding / 2
                child.Layout.fillWidth = true
            }
        }
    }

    // Paint each row behind its original item. These rectangles are visual
    // delegates only; they never own or move the actual settings controls.
    Repeater {
        model: root.items.length

        delegate: Rectangle {
            required property int index
            readonly property Item row: root.items[index]
            readonly property bool itemVisible: row ? row.visible : false
            readonly property bool isFirst: {
                for (let i = 0; i < index; ++i) {
                    if (root.items[i]?.visible) return false
                }
                return true
            }
            readonly property bool isLast: {
                for (let i = index + 1; i < root.items.length; ++i) {
                    if (root.items[i]?.visible) return false
                }
                return true
            }

            x: row?.x ?? 0
            y: (row?.y ?? 0) - root.itemVerticalPadding / 2
            width: row?.width ?? 0
            height: itemVisible ? (row.height + root.itemVerticalPadding) : 0
            visible: itemVisible
            z: -1
            color: root.bgcolor
            topLeftRadius: isFirst ? root.bigRadius : root.smallRadius
            topRightRadius: isFirst ? root.bigRadius : root.smallRadius
            bottomLeftRadius: isLast ? root.bigRadius : root.smallRadius
            bottomRightRadius: isLast ? root.bigRadius : root.smallRadius
        }
    }
}
