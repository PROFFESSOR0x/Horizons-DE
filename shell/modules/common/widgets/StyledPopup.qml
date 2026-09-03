import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland

LazyLoader {
    id: root
    property Item hoverTarget
    default property Item contentItem
    property real popupBackgroundMargin: 0
    // Keep hover detail windows outside the bar instead of overlapping the
    // item which opened them.
    property real barPopupGap: 8
    active: hoverTarget && hoverTarget.containsMouse

    readonly property bool barVertical: Config.options.bar.vertical
    readonly property string barEdge: {
        if (!barVertical) return Config.options.bar.bottom ? "bottom" : "top"
        return Config.options.bar.bottom ? "right" : "left"
    }
    readonly property real barThickness: barVertical ? Appearance.sizes.verticalBarWidth : Appearance.sizes.barHeight

    component: PanelWindow {
        id: popupWindow

        // Bring contentItem reference into this scope
        property Item innerContent: root.contentItem

        color: "transparent"
        anchors.left: root.barEdge !== "right"
        anchors.right: root.barEdge === "right"
        anchors.top: root.barEdge !== "bottom"
        anchors.bottom: root.barEdge === "bottom"

        implicitWidth: popupBackground.implicitWidth + Appearance.sizes.elevationMargin * 2 + root.popupBackgroundMargin
        implicitHeight: popupBackground.implicitHeight + Appearance.sizes.elevationMargin * 2 + root.popupBackgroundMargin

        readonly property real centerOffsetX: {
            const base = root.QsWindow?.mapFromItem(
                root.hoverTarget,
                (root.hoverTarget.width - popupBackground.implicitWidth) / 2, 0
            ).x ?? 0
            const margin = Appearance.sizes.elevationMargin
            const maxLeft = popupWindow.screen.width - popupBackground.implicitWidth - margin - 10
            return Math.max(margin, Math.min(base, maxLeft))
        }
        readonly property real centerOffsetY: {
            const base = root.QsWindow?.mapFromItem(
                root.hoverTarget,
                0, (root.hoverTarget.height - popupBackground.implicitHeight) / 2
            ).y ?? 0
            const margin = Appearance.sizes.elevationMargin
            const maxTop = popupWindow.screen.height - popupBackground.implicitHeight - margin - 15
            return Math.max(margin, Math.min(base, maxTop))
        }
        // Do not infer the popup's edge from the nominal bar height. Floating
        // and M3 bars can place an item anywhere inside their layer window.
        // Map the actual hovered item and position the popup after its real
        // outer edge instead.
        readonly property var hoverTargetPosition: root.QsWindow?.mapFromItem(root.hoverTarget, 0, 0) ?? Qt.point(0, 0)
        readonly property real hoverTargetLeft: hoverTargetPosition.x
        readonly property real hoverTargetTop: hoverTargetPosition.y
        readonly property real hoverTargetRight: hoverTargetLeft + (root.hoverTarget?.width ?? root.barThickness)
        readonly property real hoverTargetBottom: hoverTargetTop + (root.hoverTarget?.height ?? root.barThickness)

        mask: Region {
            item: popupBackground
        }
        exclusionMode: ExclusionMode.Ignore
        exclusiveZone: 0

        margins {
            left: {
                if (root.barEdge === "right") return 0
                if (root.barEdge === "left") return popupWindow.hoverTargetRight + root.barPopupGap
                return centerOffsetX 
            }
            top: {
                if (root.barEdge === "bottom") return 0
                if (root.barEdge === "top") return popupWindow.hoverTargetBottom + root.barPopupGap
                return centerOffsetY
            }
            right: root.barEdge === "right"
                ? popupWindow.screen.width - popupWindow.hoverTargetLeft + root.barPopupGap : 0
            bottom: root.barEdge === "bottom"
                ? popupWindow.screen.height - popupWindow.hoverTargetTop + root.barPopupGap : 0
        }
        WlrLayershell.namespace: "quickshell:popup"
        WlrLayershell.layer: WlrLayer.Overlay

        StyledRectangularShadow {
            target: popupBackground
        }

        Rectangle {
            id: popupBackground
            readonly property real margin: 8

            anchors {
                fill: parent
                leftMargin: Appearance.sizes.elevationMargin + root.popupBackgroundMargin * (!popupWindow.anchors.left)
                rightMargin: Appearance.sizes.elevationMargin + root.popupBackgroundMargin * (!popupWindow.anchors.right)
                topMargin: Appearance.sizes.elevationMargin + root.popupBackgroundMargin * (!popupWindow.anchors.top)
                bottomMargin: Appearance.sizes.elevationMargin + root.popupBackgroundMargin * (!popupWindow.anchors.bottom)
            }

            // Use local reference instead of crossing LazyLoader scope boundary
            implicitWidth: (popupWindow.innerContent?.implicitWidth ?? 0) + margin * 2
            implicitHeight: (popupWindow.innerContent?.implicitHeight ?? 0) + margin * 2

            // Use the resolved shared layer, not its opaque base, so popups
            // participate in global transparency and Liquid Glass.
            color: Appearance.colors.colLayer1
            radius: Appearance.rounding.normal + 4
            border.width: 1
            border.color: Appearance.effectiveGlassEnabled
                ? ColorUtils.transparentize(Appearance.colors.colOnLayer1, 0.86)
                : Appearance.colors.colLayer0Border

            // Reparent content here once the window is ready
            Component.onCompleted: {
                if (popupWindow.innerContent) {
                    popupWindow.innerContent.parent = popupBackground
                    popupWindow.innerContent.anchors.centerIn = popupBackground
                }
            }
        }
    }
}
