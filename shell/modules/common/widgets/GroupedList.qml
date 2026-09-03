import qs.modules.common
import QtQuick
import QtQuick.Layouts

Item {
    id: root
    default property list<Item> items
    property real bigRadius: Appearance.rounding.normal
    property real smallRadius: Appearance.rounding.unsharpenmore
    property color bgcolor: Appearance.colors.colLayer1
    property real itemVerticalPadding: 24
    Layout.fillWidth: true
    implicitHeight: col.implicitHeight

    ColumnLayout {
        id: col
        anchors.fill: parent
        spacing: 2

        Repeater {
            model: root.items.length
            delegate: Rectangle {
                required property int index
                // An item that's conditionally hidden (e.g. a sub-option whose
                // parent toggle is off) must not reserve a visible, empty pill
                // here. Track its visibility live so this wrapper collapses
                // to zero size and drops out of the ColumnLayout right along
                // with it, instead of showing an empty background block.
                readonly property bool itemVisible: root.items[index] ? root.items[index].visible : true
                // "First"/"last" (for corner rounding) must skip hidden items
                // too, otherwise an invisible leading/trailing row leaves the
                // visible edge row with a squared-off corner instead of the
                // big rounded one.
                readonly property bool isFirst: {
                    for (let i = 0; i < index; i++) {
                        if (root.items[i] && root.items[i].visible) return false
                    }
                    return true
                }
                readonly property bool isLast: {
                    for (let i = index + 1; i < root.items.length; i++) {
                        if (root.items[i] && root.items[i].visible) return false
                    }
                    return true
                }
                Layout.fillWidth: true
                visible: itemVisible
                implicitHeight: itemVisible ? ((root.items[index]?.implicitHeight ?? 0) + root.itemVerticalPadding) : 0
                color: root.bgcolor
                topLeftRadius:     isFirst ? root.bigRadius : root.smallRadius
                topRightRadius:    isFirst ? root.bigRadius : root.smallRadius
                bottomLeftRadius:  isLast  ? root.bigRadius : root.smallRadius
                bottomRightRadius: isLast  ? root.bigRadius : root.smallRadius

                Component.onCompleted: {
                    const child = root.items[index]
                    if (child) {
                        child.parent = contentArea
                        child.Layout.fillWidth = true
                    }
                }

                ColumnLayout {
                    id: contentArea
                    anchors { fill: parent; margins: 8 }
                    spacing: 0
                }
            }
        }
    }
}