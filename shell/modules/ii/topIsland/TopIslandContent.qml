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

Item {
    id: root
    implicitHeight: Appearance.sizes.barHeight
    readonly property real barPadding: 0
    readonly property bool isMaterial: Config.options.topIsland.cornerStyle === 3
    readonly property bool trayHasItems: SystemTray.items.values.length > 0

    function filterLayout(layout) {
        if (trayHasItems) return layout
        return layout.filter(name => name !== "sysTray")
    }

    readonly property bool autoShowXkb: WM.compositor === "hyprland" && (
        (HyprlandXkb.layoutCodes.length > 1) || (Config.options.hyprland.input.kbLayout.split(",").map(s=>s.trim()).filter(s=>s.length>0).length > 1)
    )
    function withAutoXkb(layout, isRight) {
        if (!isRight) return layout
        if (!autoShowXkb) return layout
        if (layout.includes("hyprlandXkbIndicator")) return layout
        let copy = layout.slice()
        const idx = copy.indexOf("systemIcons")
        if (idx !== -1) copy.splice(idx, 0, "hyprlandXkbIndicator")
        else if (copy.includes("sysTray")) {
            const trayIdx = copy.indexOf("sysTray")
            copy.splice(trayIdx+1, 0, "hyprlandXkbIndicator")
        } else copy.unshift("hyprlandXkbIndicator")
        return copy
    }
    readonly property var effectiveLeftLayout:   filterLayout(Config.options.topIsland.layouts.leftLayout)
    readonly property var effectiveMiddleLayout: filterLayout(Config.options.topIsland.layouts.middleLayout)
    readonly property var effectiveRightLayout:  filterLayout(withAutoXkb(Config.options.topIsland.layouts.rightLayout, true))

    function getWidgetUrl(name) {
        if (!name) return "";
        let formattedName = name.charAt(0).toUpperCase() + name.slice(1);
        return Qt.resolvedUrl("../bar/" + formattedName + ".qml");
    }

    function getMirroredForIndex(layout, idx) {
        const prevCount = layout.slice(0, idx).filter(w => w === "visualizer").length
        return prevCount % 2 === 1
    }

    function configureVisualizer(item, widgetName, layout, index) {
        if (item && widgetName === "visualizer")
            item.mirrored = root.getMirroredForIndex(layout, index)
    }

    function shouldPaintMaterialPill(name) {
        if (Config.options.topIsland.cornerStyle !== 3) return false;
        const blacklist = ["workspaces", "divisor", "powerButton", "docktoPanel", "leftSidebarButton", "activeWindow"];
        if (blacklist.includes(name)) {
            return false;
        }
        return true;
    }

    function getMaterialPillColor(name) {
        if (Config.options.topIsland.cornerStyle !== 3) return Appearance.colors.colPrimaryContainer;
        switch(name) {
            case "media":
            case "sysTray":
                return Appearance.colors.colSecondaryContainer;
            case "resources":
                return Appearance.colors.colTertiaryContainer;
            case "systemIcons":
                return Appearance.colors.colPrimary;
            default:
                return Appearance.colors.colPrimaryContainer;
        }
    }

    property var screen: root.QsWindow.window?.screen
    property real useShortenedForm: (Appearance.sizes.barHellaShortenScreenWidthThreshold >= screen?.width) ? 2 : (Appearance.sizes.barShortenScreenWidthThreshold >= screen?.width) ? 1 : 0

    readonly property real islandSpacing: 4
    readonly property real islandPadding: 6

    width: contentRow.implicitWidth + islandPadding * 2

    Rectangle {
        id: islandBackground
        anchors.fill: parent
        anchors.margins: Config.options.topIsland.cornerStyle === 1 ? Appearance.sizes.hyprlandGapsOut : 0
        color: Config.options.bar.showBackground
            ? (Config.options.bar.followFrameColor
                ? Appearance.getColorFromName(Config.options.bar.frameColor)
                : Appearance.colors.colLayer0)
            : "transparent"
        radius: Config.options.topIsland.cornerStyle === 1 ? Appearance.rounding.windowRounding : (Config.options.topIsland.cornerStyle === 0 ? Appearance.rounding.screenRounding : Appearance.rounding.normal)
        border.width: Config.options.topIsland.cornerStyle === 1 ? 1 : 0
        border.color: Appearance.colors.colLayer0Border

        bottomLeftRadius:  Config.options.topIsland.cornerStyle === 0 && !Config.options.bar.bottom ? Appearance.rounding.screenRounding : radius
        bottomRightRadius: Config.options.topIsland.cornerStyle === 0 && !Config.options.bar.bottom ? Appearance.rounding.screenRounding : radius
        topLeftRadius:     Config.options.topIsland.cornerStyle === 0 && Config.options.bar.bottom  ? Appearance.rounding.screenRounding : radius
        topRightRadius:    Config.options.topIsland.cornerStyle === 0 && Config.options.bar.bottom  ? Appearance.rounding.screenRounding : radius
    }

    RowLayout {
        id: contentRow
        anchors.centerIn: parent
        spacing: root.isMaterial ? 2 : root.islandSpacing

        // Left section
        Repeater {
            model: root.effectiveLeftLayout
            delegate: Bar.BarGroup {
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

        // Divisor between left and middle
        Loader {
            active: root.effectiveLeftLayout.length > 0 && root.effectiveMiddleLayout.length > 0
            visible: active
            sourceComponent: Item {
                implicitWidth: 10
                implicitHeight: Appearance.sizes.barHeight
                Rectangle {
                    anchors.centerIn: parent
                    width: 1
                    height: parent.height * 0.4
                    color: Appearance.colors.colOutlineVariant
                }
            }
        }

        // Center section
        Repeater {
            model: root.effectiveMiddleLayout
            delegate: Bar.BarGroup {
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

        // Divisor between middle and right
        Loader {
            active: root.effectiveMiddleLayout.length > 0 && root.effectiveRightLayout.length > 0
            visible: active
            sourceComponent: Item {
                implicitWidth: 10
                implicitHeight: Appearance.sizes.barHeight
                Rectangle {
                    anchors.centerIn: parent
                    width: 1
                    height: parent.height * 0.4
                    color: Appearance.colors.colOutlineVariant
                }
            }
        }

        // Right section
        Repeater {
            model: root.effectiveRightLayout
            delegate: Bar.BarGroup {
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
    }
}
