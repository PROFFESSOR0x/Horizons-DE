pragma Singleton
import QtQuick
import qs.services

// Shared helpers for the bar family (Bar, VerticalBar, M3Island, TopIsland).
// Consolidates logic that was previously duplicated near-identically across
// BarContent.qml, VerticalBarContent.qml and (partially) M3IslandContent.qml.
// Callers that had slightly different behavior (e.g. differing material-pill
// blacklists, or how the xkb indicator falls back when there's no systemIcons
// widget) pass that difference in explicitly via parameters/options instead
// of the helper silently unifying it.
Singleton {
    id: root

    // True when more than one keyboard layout is configured under Hyprland,
    // in which case the xkb layout indicator should be auto-injected into
    // the bar even if the user hasn't added it to their layout manually.
    readonly property bool autoShowXkb: WM.compositor === "hyprland" && (
        (HyprlandXkb.layoutCodes.length > 1)
        || (Config.options.hyprland.input.kbLayout.split(",").map(s => s.trim()).filter(s => s.length > 0).length > 1)
    )

    // Removes the sysTray widget from a layout when the tray has no items.
    function filterLayout(layout, trayHasItems) {
        if (trayHasItems)
            return layout;
        return layout.filter(name => name !== "sysTray");
    }

    // Injects "hyprlandXkbIndicator" into a layout when autoShowXkb is active
    // and it isn't already present.
    // opts.trayFallback: if true and there's no systemIcons widget, fall back
    //   to inserting right after sysTray (BarContent's behavior).
    // opts.fallback: "append" or "prepend" (default) - what to do when
    //   neither systemIcons nor (optionally) sysTray are present.
    function withAutoXkb(layout, opts) {
        opts = opts || {};
        if (!root.autoShowXkb)
            return layout;
        if (layout.includes("hyprlandXkbIndicator"))
            return layout;
        let copy = layout.slice();
        const idx = copy.indexOf("systemIcons");
        if (idx !== -1) {
            copy.splice(idx, 0, "hyprlandXkbIndicator");
        } else if (opts.trayFallback && copy.includes("sysTray")) {
            const trayIdx = copy.indexOf("sysTray");
            copy.splice(trayIdx + 1, 0, "hyprlandXkbIndicator");
        } else if (opts.fallback === "append") {
            copy.push("hyprlandXkbIndicator");
        } else {
            copy.unshift("hyprlandXkbIndicator");
        }
        return copy;
    }

    // Resolves a widget name (e.g. "clockWidget") to its .qml file under
    // shell/modules/ii/bar/, which is where every bar-family surface loads
    // its widgets from regardless of which surface is asking.
    function getWidgetUrl(name) {
        if (!name || typeof name !== "string")
            return "";
        let formattedName = name.charAt(0).toUpperCase() + name.slice(1);
        return Qt.resolvedUrl("../ii/bar/" + formattedName + ".qml");
    }

    // Only Visualizer exposes a writable `mirrored` property. Several QtQuick
    // items expose a read-only property with the same name, so probing every
    // loaded widget caused a runtime TypeError on each bar rebuild.
    function getMirroredForIndex(layout, idx) {
        const prevCount = layout.slice(0, idx).filter(w => w === "visualizer").length;
        return prevCount % 2 === 1;
    }

    function configureVisualizer(item, widgetName, layout, index) {
        if (item && widgetName === "visualizer")
            item.mirrored = root.getMirroredForIndex(layout, index);
    }

    // blacklist: widget names that should never get a material pill drawn
    // around them, even in material (cornerStyle === 3) mode. Differs
    // slightly between callers, so it's passed in rather than hardcoded here.
    function shouldPaintMaterialPill(name, blacklist) {
        if (Config.options.bar.cornerStyle !== 3)
            return false;
        if (blacklist && blacklist.includes(name))
            return false;
        return true;
    }

    function getMaterialPillColor(name) {
        if (Config.options.bar.cornerStyle !== 3)
            return Appearance.colors.colPrimaryContainer;
        switch (name) {
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
}
