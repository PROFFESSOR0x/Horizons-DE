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
    // Config* rows have genuinely different natural heights (a ConfigSwitch
    // is just an icon/label/toggle; a ConfigTextArea carries a description
    // line and an input field), which otherwise makes their background
    // pills visibly different sizes row to row. Padding every row up to at
    // least this tall (via extra top/bottom margin, split evenly so the
    // control stays vertically centered) keeps the pills a consistent
    // height without touching genuinely-taller rows (wrapped multi-line
    // text, etc.) — they simply exceed the minimum and keep their own size.
    property real minRowHeight: 48
    // Rows taller than this are genuinely tall (a wrapped multi-line
    // description, a text area, a two-line Flow of option buttons) and keep
    // their own height. Rows below it are all normalized to the tallest of
    // them, not just to minRowHeight - a control row whose natural height is,
    // say, 52 used to skip padding entirely and end up a few pixels taller
    // than every 48-and-under neighbour, which is the uneven-pill look in a
    // group of otherwise identical-looking settings.
    property real maxNormalizedRowHeight: 64
    readonly property real normalizedRowHeight: {
        let tallest = root.minRowHeight
        const rows = root.items
        for (let i = 0; i < rows.length; ++i) {
            const it = rows[i]
            if (!it || !it.visible) continue
            const h = it.implicitHeight
            if (h > tallest && h <= root.maxNormalizedRowHeight) tallest = h
        }
        return tallest
    }
    Layout.fillWidth: true
    implicitHeight: contentArea.implicitHeight

    function extraPadFor(item) {
        return item ? Math.max(0, (root.normalizedRowHeight - item.implicitHeight) / 2) : 0
    }

    ColumnLayout {
        id: contentArea
        width: parent.width
        spacing: 2

        Component.onCompleted: {
            // Reserve the same vertical space the old wrapper rectangles
            // supplied, but retain the original layout parent of each row.
            // Margins are bound (not just set once) so a row that changes
            // its own natural height later (e.g. a description wrapping to
            // a 2nd line) keeps its pill sized correctly.
            for (let i = 0; i < children.length; ++i) {
                const child = children[i]
                child.Layout.fillWidth = true
                child.Layout.topMargin = Qt.binding(() => root.itemVerticalPadding / 2 + root.extraPadFor(child))
                child.Layout.bottomMargin = Qt.binding(() => root.itemVerticalPadding / 2 + root.extraPadFor(child))
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

            readonly property real extraPad: root.extraPadFor(row)

            x: row?.x ?? 0
            y: (row?.y ?? 0) - root.itemVerticalPadding / 2 - extraPad
            width: row?.width ?? 0
            height: itemVisible ? (row.height + root.itemVerticalPadding + 2 * extraPad) : 0
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
