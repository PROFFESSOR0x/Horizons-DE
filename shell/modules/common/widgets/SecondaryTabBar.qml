import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.models

TabBar {
    id: root
    property real indicatorPadding: 8
    Layout.fillWidth: true

    background: Item {
        WheelHandler {
            onWheel: (event) => {
                if (event.angleDelta.y < 0) root.incrementCurrentIndex();
                else if (event.angleDelta.y > 0) root.decrementCurrentIndex();
            }
            acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
        }

        Rectangle {
            id: activeIndicator
            z: 9999
            anchors.bottom: parent.bottom
            topLeftRadius: height
            topRightRadius: height
            bottomLeftRadius: 0
            bottomRightRadius: 0
            color: Appearance.colors.colPrimary
            // Animation
            property real baseWidth: root.width / root.count
            AnimatedTabIndexPair {
                id: idxPair
                index: root.currentIndex
            }
            height: 3
            // Measured from the actual tab items rather than assuming every tab
            // is root.width / root.count wide - tabs are sized by their own
            // label now (see SecondaryTabButton's contentItem), so equal-width
            // maths put the underline under the wrong place. baseWidth stays as
            // the fallback for the frame before the items exist.
            function tabX(i) {
                root.count // dependency: re-measure once the tab items exist
                const item = root.itemAt(Math.round(i))
                return item ? item.x : Math.round(i) * baseWidth
            }
            function tabRight(i) {
                root.count // dependency: re-measure once the tab items exist
                const item = root.itemAt(Math.round(i))
                return item ? item.x + item.width : (Math.round(i) + 1) * baseWidth
            }
            readonly property real spanLeft: Math.min(tabX(idxPair.idx1), tabX(idxPair.idx2))
            readonly property real spanRight: Math.max(tabRight(idxPair.idx1), tabRight(idxPair.idx2))
            x: spanLeft + root.indicatorPadding
            width: Math.max(0, spanRight - root.indicatorPadding - x)
        }

        Rectangle { // Tabbar bottom border
            id: tabBarBottomBorder
            z: 9998
            anchors.bottom: parent.bottom
            height: 1
            anchors {
                left: parent.left
                right: parent.right
            }
            color: Appearance.colors.colOutlineVariant
        }
    }
}
