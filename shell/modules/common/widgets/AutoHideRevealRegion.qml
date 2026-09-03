import QtQuick
import qs.modules.common

// Hit-test region for every auto-hidden bar.  It follows the actual bar item
// while visible and falls back to a narrow strip on the screen edge while it
// is hidden.  This avoids assuming a bar height/width or a particular style.
Item {
    id: root

    required property Item barItem
    property bool vertical: false
    // false = top/left, true = bottom/right
    property bool edgeAtEnd: false
    property real revealWidth: Config.options.bar.autoHide.hoverRegionWidth
    // Start the reveal just inside the physical edge, so the entrance motion
    // is already underway by the time the pointer reaches it.
    property real edgePreload: 1.5

    readonly property real safeRevealWidth: Math.max(1, revealWidth) + edgePreload

    x: {
        if (!vertical) return Math.max(0, Math.min(barItem?.x ?? 0, parent?.width ?? 0))
        if (!edgeAtEnd) return 0
        return Math.min(barItem?.x ?? (parent?.width ?? 0), (parent?.width ?? 0) - safeRevealWidth)
    }
    y: {
        if (vertical) return Math.max(0, Math.min(barItem?.y ?? 0, parent?.height ?? 0))
        if (!edgeAtEnd) return 0
        return Math.min(barItem?.y ?? (parent?.height ?? 0), (parent?.height ?? 0) - safeRevealWidth)
    }
    width: {
        if (!vertical) return Math.max(0, Math.min(barItem?.width ?? 0, (parent?.width ?? 0) - x))
        if (!edgeAtEnd)
            return Math.max(safeRevealWidth, Math.max(0, (barItem?.x ?? 0) + (barItem?.width ?? 0)))
        return Math.max(safeRevealWidth, (parent?.width ?? 0) - x)
    }
    height: {
        if (vertical) return Math.max(0, Math.min(barItem?.height ?? 0, (parent?.height ?? 0) - y))
        if (!edgeAtEnd)
            return Math.max(safeRevealWidth, Math.max(0, (barItem?.y ?? 0) + (barItem?.height ?? 0)))
        return Math.max(safeRevealWidth, (parent?.height ?? 0) - y)
    }
}
