pragma ComponentBehavior: Bound
import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell

Item {
    id: root
    property string text: ""
    property bool extraVisibleCondition: true
    property bool alternativeVisibleCondition: false
    property real horizontalPadding: 10
    property real verticalPadding: 5
    property real horizontalMargin: horizontalPadding
    property real verticalMargin: verticalPadding
    
    function updateAnchor() {
        tooltipLoader.item?.anchor.updateAnchor();
    }

    // Do not interpret a missing `hovered` property as an active hover. Bar
    // widgets often use MouseArea, whose equivalent state is `containsMouse`.
    readonly property bool parentIsHovered: parent?.hovered === true || parent?.containsMouse === true
    readonly property bool internalVisibleCondition: (extraVisibleCondition && parentIsHovered) || alternativeVisibleCondition
    // Bar tooltips open toward the usable desktop area: above a bottom bar,
    // below a top bar, and inward from either vertical edge.
    property var anchorEdges: {
        if (Config.options.bar.vertical)
            return Config.options.bar.bottom ? Edges.Left : Edges.Right
        return Config.options.bar.bottom ? Edges.Top : Edges.Bottom
    }
    property var anchorGravity: anchorEdges

    property Item contentItem: StyledToolTipContent {
        id: contentItem
        anchors.centerIn: parent
        text: root.text
        shown: false
        Component.onCompleted: shown = true
        horizontalPadding: root.horizontalPadding
        verticalPadding: root.verticalPadding
    }

    Loader {
        id: tooltipLoader
        anchors.fill: parent
        active: root.internalVisibleCondition
        sourceComponent: PopupWindow {
            visible: true
            anchor {
                window: root.QsWindow.window
                item: root.parent
                edges: root.anchorEdges
                gravity: root.anchorGravity
            }
            mask: Region {
                item: null
            }

            color: "transparent"
            implicitWidth: root.contentItem.implicitWidth + root.horizontalMargin * 2
            implicitHeight: root.contentItem.implicitHeight + root.verticalMargin * 2

            data: [root.contentItem]
        }
    }
}
