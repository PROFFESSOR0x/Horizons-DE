import qs.modules.common
import qs.modules.common.functions
import QtQuick
import QtQuick.Layouts

Item {
    id: root
    property bool vertical: false
    property int currentIndex: 0
    property int totalCount: 0
    property bool isMaterial: Config.options.bar.cornerStyle === 3
    property bool paintMaterialPill: false
    property real padding: (root.isMaterial && !root.paintMaterialPill) ? 0 : 5
    property color bgColor: Appearance.colors.colPrimaryContainer

    readonly property color resolvedGroupColor: {
        const name = Config.options.bar.groupColor
        const key = `col${name.charAt(0).toUpperCase()}${name.slice(1)}`
        return Appearance.colors[key] ?? Appearance.colors.colLayer1
    }

    readonly property bool isSegmented: Config.options?.bar.borderless === "segmented"

    readonly property real fullRadius: height / 2
    readonly property real midRadius: root.isSegmented ? 0 : (Config.options.bar.cornerStyle === 2 ? Appearance.rounding.unsharpenmore + 2 : Appearance.rounding.unsharpenmore)
    property real startRadius: {
        if (totalCount <= 1) return fullRadius;
        if (currentIndex === 0) return fullRadius;
        return midRadius;
    }
    property real endRadius: {
        if (totalCount <= 1) return fullRadius;
        if (currentIndex === totalCount - 1) return fullRadius;
        return midRadius;
    }

    implicitWidth: vertical && root.isMaterial ? Appearance.sizes.baseVerticalBarWidth - 6 : (gridLayout.implicitWidth + padding * 2)
    implicitHeight: vertical ? (gridLayout.implicitHeight + padding * 2) : Appearance.sizes.baseBarHeight
    // Stagger entrance: delay per index for natural cascade (scale removed)
    property real entranceScale: 0.86
    property real entranceOpacity: 0
    opacity: entranceOpacity
    scale: entranceScale
    Component.onCompleted: {
        const d = Math.min(currentIndex * 45, 180)
        Qt.callLater(() => { entranceDelay.interval = d; entranceDelay.restart() })
    }
    Timer { id: entranceDelay; interval: 0; repeat: false; onTriggered: { root.entranceOpacity = 1; root.entranceScale = 1 } }
    Behavior on entranceOpacity { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }
    Behavior on entranceScale { animation: Appearance.animation.elementMoveSmall.numberAnimation.createObject(root) }

    default property alias items: gridLayout.children

    // Hover lift state — HoverHandler works alongside children's MouseAreas without stealing hover
    HoverHandler {
        id: hoverHandler
    }
    readonly property bool hovered: hoverHandler.hovered

    // Lift transform
    transform: Translate {
        id: liftTr
        y: root.hovered ? -1.2 : 0
        Behavior on y { animation: Appearance.animation.elementMoveSmall.numberAnimation.createObject(liftTr) }
    }

    Rectangle {
        id: background
        anchors {
            fill: parent
            topMargin: root.vertical ? 0 : 4
            bottomMargin: root.vertical ? 0 : 4
            leftMargin: root.vertical ? 4 : 0
            rightMargin: root.vertical ? 4 : 0
        }
        color: (root.isMaterial && !root.paintMaterialPill)
            ? "transparent"
            : (root.isMaterial && root.paintMaterialPill)
                ? root.bgColor
                : (Config.options?.bar.borderless === "transparent"
                    ? "transparent"
                    : Config.options.bar.cornerStyle === 2 || (Config.options?.bar.borderless === "segmented" && !Config.options.bar.showBackground)
                        ? Appearance.colors.colLayer0
                        : root.hovered ? ColorUtils.mix(root.resolvedGroupColor, Appearance.colors.colOnLayer1, 0.92)
                                       : root.resolvedGroupColor)

        border.width: root.isSegmented ? 1 : 0
        border.color: root.hovered ? Appearance.colors.colLayer0Border : Appearance.colors.colLayer0Border
        opacity: root.hovered ? 1 : 0.98

        topLeftRadius: (root.isMaterial && root.paintMaterialPill) ? root.fullRadius : (Config.options?.bar.borderless === "separated" ? root.fullRadius : root.startRadius)
        bottomLeftRadius: (root.isMaterial && root.paintMaterialPill) ? root.fullRadius : (Config.options?.bar.borderless === "separated" ? root.fullRadius : root.vertical ? root.endRadius : root.startRadius)
        topRightRadius: (root.isMaterial && root.paintMaterialPill) ? root.fullRadius : (Config.options?.bar.borderless === "separated" ? root.fullRadius : root.vertical ? root.startRadius : root.endRadius)
        bottomRightRadius: (root.isMaterial && root.paintMaterialPill) ? root.fullRadius : (Config.options?.bar.borderless === "separated" ? root.fullRadius : root.endRadius)

        Behavior on color {
            animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
        }
        Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
        Behavior on border.color { animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(background) }
    }

    GridLayout {
        id: gridLayout
        columns: root.vertical ? 1 : -1
        anchors.centerIn: parent
        columnSpacing: 0
        rowSpacing: 0
    }
}