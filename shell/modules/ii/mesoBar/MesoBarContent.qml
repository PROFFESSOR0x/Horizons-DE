import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.UPower
import Quickshell.Services.SystemTray
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import "../bar" as Bar

// Content of the "Mesobar" (see MesoBar.qml / Config.qml for the naming
// rationale). Two width policies, both producing the same floating/pill
// presentation:
//  - "content": hug the widgets, same as the old topIsland pill.
//  - "percent": take a configurable share of the screen width and lay the
//    left/middle/right widget groups out the way BarContent.qml lays out the
//    classic bar's three regions (left-anchored, absolutely-centered middle,
//    right-anchored) so widgets can spread out with real spacing instead of
//    being glued together.
Item {
    id: root
    implicitHeight: Appearance.sizes.barHeight
    readonly property real barPadding: 0
    readonly property bool isMaterial: Config.options.mesoBar.cornerStyle === 3
    readonly property bool trayHasItems: SystemTray.items.values.length > 0

    // Set by MesoBar.qml to the monitor's full width, used by widthMode "percent".
    property real screenWidth: 0
    readonly property bool widthIsPercent: Config.options.mesoBar.widthMode === "percent"

    readonly property var materialPillBlacklist: ["workspaces", "divisor", "powerButton", "docktoPanel", "leftSidebarButton", "activeWindow"]

    // Layout resolution delegates to the shared BarLayoutUtils singleton (also
    // used by Bar/VerticalBar/M3Island) instead of keeping local copies.
    function filterLayout(layout) {
        return BarLayoutUtils.filterLayout(layout, trayHasItems)
    }

    readonly property var effectiveLeftLayout:   filterLayout(Config.options.mesoBar.layouts.leftLayout)
    readonly property var effectiveMiddleLayout: filterLayout(Config.options.mesoBar.layouts.middleLayout)
    readonly property var effectiveRightLayout:  filterLayout(BarLayoutUtils.withAutoXkb(Config.options.mesoBar.layouts.rightLayout, {trayFallback: true, fallback: "prepend"}))

    function getWidgetUrl(name) {
        return BarLayoutUtils.getWidgetUrl(name)
    }

    function getMirroredForIndex(layout, idx) {
        return BarLayoutUtils.getMirroredForIndex(layout, idx)
    }

    function configureVisualizer(item, widgetName, layout, index) {
        BarLayoutUtils.configureVisualizer(item, widgetName, layout, index)
    }

    // mesoBar has its own cornerStyle (independent of Config.options.bar's),
    // so the material-pill checks need root.isMaterial passed in explicitly
    // rather than the singleton's Config.options.bar.cornerStyle default.
    function shouldPaintMaterialPill(name) {
        return BarLayoutUtils.shouldPaintMaterialPill(name, materialPillBlacklist, root.isMaterial)
    }

    function getMaterialPillColor(name) {
        return BarLayoutUtils.getMaterialPillColor(name, root.isMaterial)
    }

    property var screen: root.QsWindow.window?.screen
    property real useShortenedForm: (Appearance.sizes.barHellaShortenScreenWidthThreshold >= screen?.width) ? 2 : (Appearance.sizes.barShortenScreenWidthThreshold >= screen?.width) ? 1 : 0

    // Mirrors BarContent.qml's borderless -> spacing mapping (transparent/segmented
    // pull groups together, anything else keeps the normal breathing room),
    // just against mesoBar's own borderless setting instead of the classic bar's.
    readonly property real islandSpacing: Config.options.mesoBar.borderless === "transparent" ? -7
        : Config.options.mesoBar.borderless === "segmented" ? -1
        : 4
    readonly property real islandPadding: 6

    // Natural (content-hugging) width of each region plus padding/gaps -
    // the floor width so widgets never get clipped or overlap, even when
    // widthPercent is set very small.
    readonly property real naturalContentWidth: {
        let w = islandPadding * 2
        const groups = [leftRow.implicitWidth, middleRow.implicitWidth, rightRow.implicitWidth].filter(x => x > 0)
        groups.forEach(g => w += g)
        if (groups.length > 1)
            w += (groups.length - 1) * 24 // minimum breathing room between regions
        return w
    }

    width: widthIsPercent
        ? Math.max(Math.round((root.screenWidth || 0) * Config.options.mesoBar.widthPercent / 100), naturalContentWidth)
        : naturalContentWidth

    Behavior on width {
        enabled: root.widthIsPercent
        NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
    }

    Rectangle {
        id: islandBackground
        anchors.fill: parent
        anchors.margins: Config.options.mesoBar.cornerStyle === 1 ? Appearance.sizes.hyprlandGapsOut : 0
        color: Config.options.bar.showBackground
            ? (Config.options.mesoBar.followFrameColor
                ? Appearance.getColorFromName(Config.options.mesoBar.frameColor)
                : Appearance.colors.colLayer0)
            : "transparent"
        radius: Config.options.mesoBar.cornerStyle === 1 ? Appearance.rounding.windowRounding : (Config.options.mesoBar.cornerStyle === 0 ? Appearance.rounding.screenRounding : Appearance.rounding.normal)
        border.width: Config.options.mesoBar.showFrame
            ? Config.options.mesoBar.frameThickness
            : (Config.options.mesoBar.cornerStyle === 1 ? 1 : 0)
        border.color: Config.options.mesoBar.showFrame
            ? Appearance.getColorFromName(Config.options.mesoBar.frameColor)
            : Appearance.colors.colLayer0Border

        bottomLeftRadius:  Config.options.mesoBar.cornerStyle === 0 && !Config.options.bar.bottom ? Appearance.rounding.screenRounding : radius
        bottomRightRadius: Config.options.mesoBar.cornerStyle === 0 && !Config.options.bar.bottom ? Appearance.rounding.screenRounding : radius
        topLeftRadius:     Config.options.mesoBar.cornerStyle === 0 && Config.options.bar.bottom  ? Appearance.rounding.screenRounding : radius
        topRightRadius:    Config.options.mesoBar.cornerStyle === 0 && Config.options.bar.bottom  ? Appearance.rounding.screenRounding : radius
    }

    Component {
        id: leftGroupDelegate
        Bar.BarGroup {
            Layout.fillHeight: true
            currentIndex: index
            totalCount: root.effectiveLeftLayout.length
            paintMaterialPill: root.shouldPaintMaterialPill(modelData)
            bgColor: root.getMaterialPillColor(modelData)
            Loader {
                Layout.fillHeight: true
                source: root.getWidgetUrl(modelData)
                onLoaded: root.configureVisualizer(item, modelData, root.effectiveLeftLayout, index)
            }
        }
    }
    Component {
        id: middleGroupDelegate
        Bar.BarGroup {
            Layout.fillHeight: true
            currentIndex: index
            totalCount: root.effectiveMiddleLayout.length
            paintMaterialPill: root.shouldPaintMaterialPill(modelData)
            bgColor: root.getMaterialPillColor(modelData)
            Loader {
                Layout.fillHeight: true
                source: root.getWidgetUrl(modelData)
                onLoaded: root.configureVisualizer(item, modelData, root.effectiveMiddleLayout, index)
            }
        }
    }
    Component {
        id: rightGroupDelegate
        Bar.BarGroup {
            Layout.fillHeight: true
            currentIndex: index
            totalCount: root.effectiveRightLayout.length
            paintMaterialPill: root.shouldPaintMaterialPill(modelData)
            bgColor: root.getMaterialPillColor(modelData)
            Loader {
                Layout.fillHeight: true
                source: root.getWidgetUrl(modelData)
                onLoaded: root.configureVisualizer(item, modelData, root.effectiveRightLayout, index)
            }
        }
    }

    // Left region - anchored to the left edge, like BarContent.qml's left Item.
    Item {
        anchors.left: parent.left
        anchors.leftMargin: root.islandPadding
        anchors.verticalCenter: parent.verticalCenter
        height: parent.height
        width: leftRow.implicitWidth

        RowLayout {
            id: leftRow
            anchors.fill: parent
            spacing: root.isMaterial ? 2 : root.islandSpacing

            Repeater {
                model: root.effectiveLeftLayout
                delegate: leftGroupDelegate
            }
        }
    }

    // Middle region - absolutely centered on the whole bar, independent of
    // how wide the left/right regions are (matches BarContent.qml's center
    // Item, which does the same via anchors.centerIn rather than a shared
    // RowLayout with flex spacers).
    Item {
        anchors.centerIn: parent
        height: parent.height
        width: middleRow.implicitWidth

        RowLayout {
            id: middleRow
            anchors.fill: parent
            spacing: root.isMaterial ? 2 : root.islandSpacing

            Repeater {
                model: root.effectiveMiddleLayout
                delegate: middleGroupDelegate
            }
        }
    }

    // Right region - anchored to the right edge.
    Item {
        anchors.right: parent.right
        anchors.rightMargin: root.islandPadding
        anchors.verticalCenter: parent.verticalCenter
        height: parent.height
        width: rightRow.implicitWidth

        RowLayout {
            id: rightRow
            anchors.fill: parent
            spacing: root.isMaterial ? 2 : root.islandSpacing

            Repeater {
                model: root.effectiveRightLayout
                delegate: rightGroupDelegate
            }
        }
    }
}
