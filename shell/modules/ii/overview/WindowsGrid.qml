pragma ComponentBehavior: Bound
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland

// Flat, filterable grid of every open window's live thumbnail - the
// "Windows" tab of the Super+Tab switcher (WindowSwitcherView.qml). Unlike
// OverviewWidget (the "Workspaces" tab), this ignores workspace/monitor
// position entirely: every window sits in one flowing grid at its own
// aspect ratio, and typing into the filter box (WindowSwitcherView's
// ToolbarTextField, bound to filterText) narrows it by title/class so you
// can jump straight to a window instead of hunting through workspaces.
Item {
    id: root
    required property var screen
    property string filterText: ""

    readonly property var windowByAddress: HyprlandData.windowByAddress
    readonly property string monitorName: root.screen?.name ?? ""
    readonly property var linkedWorkspaceScope: {
        const active = WM.activeWorkspaceForMonitor(root.monitorName)
        if (!active) return []
        return GlobalStates.linkedWorkspaceMembers(active.id, root.monitorName)
    }
    readonly property real tileMaxWidth: 300
    readonly property real tileMaxHeight: 175
    readonly property real tileMinWidth: 90
    readonly property real tileMinHeight: 60
    readonly property real tileSpacing: 14
    // Cell width is deliberately smaller than the largest thumbnail. This
    // gives a narrow/portrait display two useful columns before falling back
    // to one, while wide displays naturally gain more columns.
    readonly property real preferredCellWidth: 220
    // The switcher is often opened on a portrait/narrow display. Its width
    // and column count are therefore derived from the current screen rather
    // than from the first window delegate's implicit size (which is what made
    // the old Flow collapse into one very tall column).
    readonly property real gridWidth: Math.max(320, Math.min(
        1040, Math.floor((root.screen?.width ?? 1280) * 0.82)))
    readonly property int columnCount: Math.max(1, Math.floor(
        (root.gridWidth + root.tileSpacing) / (root.preferredCellWidth + root.tileSpacing)))
    readonly property real cellWidth: Math.floor(
        (root.gridWidth - root.tileSpacing * (root.columnCount - 1)) / root.columnCount)
    readonly property real cellHeight: Math.max(124, Math.min(
        208, Math.round(root.cellWidth * 0.66)))
    // Reserve room for tabs and the filter field, then scroll the thumbnails
    // instead of letting a long window list extend past the screen.
    readonly property real maxGridHeight: Math.max(220, Math.min(
        560, Math.floor((root.screen?.height ?? 900) * 0.58)))

    // De-duplicated, filtered {toplevel, win, address} entries - same
    // toplevel/windowByAddress matching OverviewWidget already uses, just
    // without the per-workspace grouping. Hyprland's focusHistoryID is 0 for
    // the focused client and grows with age, which makes it the natural order
    // for a Super+Tab surface: the currently used window comes first and the
    // rest follow by recency rather than an unstable IPC/toplevel order.
    readonly property var matchingWindows: {
        const needle = root.filterText.trim().toLowerCase();
        const linkedScope = root.linkedWorkspaceScope;
        const seen = ({});
        const out = [];
        ToplevelManager.toplevels.values.forEach(toplevel => {
            const address = `0x${toplevel.HyprlandToplevel?.address}`;
            const win = root.windowByAddress[address];
            if (!win || seen[address]) return;
            // A linked workspace set is navigated as a single desktop. Keep
            // the Windows tab scoped to exactly that set; without a link the
            // familiar all-windows switcher remains unchanged.
            if (linkedScope.length > 1) {
                const monitorName = HyprlandData.monitors.find(m => m.id === win.monitor)?.name ?? "";
                const inLinkedSet = linkedScope.some(entry => String(entry.workspaceId) === String(win.workspace?.id)
                    && entry.monitorName === monitorName);
                if (!inLinkedSet) return;
            }
            if (needle !== "") {
                const title = (win.title ?? "").toLowerCase();
                const cls = (win.class ?? "").toLowerCase();
                if (!title.includes(needle) && !cls.includes(needle)) return;
            }
            seen[address] = true;
            out.push({ toplevel, win, address });
        });
        out.sort((a, b) => {
            const aFocus = a.win?.focusHistoryID ?? Number.MAX_SAFE_INTEGER;
            const bFocus = b.win?.focusHistoryID ?? Number.MAX_SAFE_INTEGER;
            if (aFocus !== bFocus) return aFocus - bFocus;
            return (a.win?.title ?? "").localeCompare(b.win?.title ?? "");
        });
        return out;
    }

    implicitWidth: root.gridWidth
    implicitHeight: root.matchingWindows.length > 0 ? grid.height : 120

    GridView {
        id: grid
        width: root.gridWidth
        height: visible ? Math.min(contentHeight, root.maxGridHeight) : 0
        cellWidth: root.cellWidth + root.tileSpacing
        cellHeight: root.cellHeight + root.tileSpacing
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        interactive: contentHeight > height
        visible: root.matchingWindows.length > 0
        model: root.matchingWindows

        ScrollBar.vertical: StyledScrollBar {}

        delegate: Item {
            id: cell
            required property var modelData
            width: grid.cellWidth
            height: grid.cellHeight

            Rectangle {
                id: tile
                anchors.centerIn: parent
                readonly property var win: cell.modelData.win
                readonly property var toplevel: cell.modelData.toplevel
                readonly property real rawW: win?.size?.[0] ?? 1
                readonly property real rawH: win?.size?.[1] ?? 1
                readonly property real availableWidth: Math.max(root.tileMinWidth, grid.cellWidth - root.tileSpacing)
                readonly property real availableHeight: Math.max(root.tileMinHeight, grid.cellHeight - root.tileSpacing)
                readonly property real fitScale: Math.min(
                    availableWidth / Math.max(rawW, 1),
                    availableHeight / Math.max(rawH, 1), 1)
                width: Math.max(root.tileMinWidth, Math.min(availableWidth, rawW * fitScale))
                height: Math.max(root.tileMinHeight, Math.min(availableHeight, rawH * fitScale))
                property bool hovered: false
                property bool pressed: false

                // Rectangle's own radius + clip (Qt 6.7+) is clip-shape-aware
                // natively - no need for an OpacityMask offscreen render pass
                // just to round the ScreencopyView's corners.
                color: "transparent"
                radius: Appearance.rounding.normal
                clip: true

                ScreencopyView {
                    id: preview
                    anchors.fill: parent
                    // This view is opened by Win+Tab, not by the launcher
                    // overview. The old overviewOpen guard kept every source
                    // null, so the grid showed only each window's icon/title.
                    captureSource: GlobalStates.windowSwitcherOpen ? tile.toplevel : null
                    live: GlobalStates.windowSwitcherOpen

                    Rectangle { // Color overlay for interactions, mirrors OverviewWindow
                        anchors.fill: parent
                        radius: Appearance.rounding.normal
                        color: tile.pressed ? ColorUtils.transparentize(Appearance.colors.colLayer2Active, 0.5)
                            : tile.hovered ? ColorUtils.transparentize(Appearance.colors.colLayer2Hover, 0.7)
                            : ColorUtils.transparentize(Appearance.colors.colLayer2)
                        border.width: 1
                        border.color: ColorUtils.transparentize(Appearance.m3colors.m3outline, 0.88)
                    }

                    RowLayout {
                        anchors {
                            left: parent.left
                            right: parent.right
                            bottom: parent.bottom
                            margins: 6
                        }
                        spacing: 6
                        Image {
                            Layout.preferredWidth: 18
                            // Decode off the UI thread (see StyledImage.qml).
                            asynchronous: true
                            Layout.preferredHeight: 18
                            source: Quickshell.iconPath(AppSearch.guessIcon(tile.win?.class), "image-missing")
                            sourceSize: Qt.size(18, 18)
                        }
                        StyledText {
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                            font.pixelSize: Appearance.font.pixelSize.smaller
                            color: Appearance.colors.colOnLayer1
                            text: tile.win?.title ?? ""
                        }
                    }
                }

                MouseArea {
                    id: tileArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    acceptedButtons: Qt.LeftButton | Qt.MiddleButton
                    onEntered: tile.hovered = true
                    onExited: tile.hovered = false
                    onPressed: tile.pressed = true
                    onReleased: tile.pressed = false
                    onClicked: (event) => {
                        if (!tile.win) return;
                        if (event.button === Qt.LeftButton) {
                            GlobalStates.windowSwitcherOpen = false;
                            WM.focusWindow(tile.win.address);
                        } else if (event.button === Qt.MiddleButton) {
                            WM.closeWindow(tile.win.address);
                        }
                    }

                    StyledToolTip {
                        extraVisibleCondition: false
                        alternativeVisibleCondition: tileArea.containsMouse
                        text: `${tile.win?.title}\n[${tile.win?.class}]${tile.win?.xwayland ? " [XWayland]" : ""}`
                    }
                }
            }
        }
    }

    StyledText {
        id: emptyText
        anchors.centerIn: parent
        visible: root.matchingWindows.length === 0
        color: Appearance.colors.colSubtext
        text: root.filterText.trim() === "" ? Translation.tr("No open windows") : Translation.tr("No windows match \"%1\"").arg(root.filterText)
    }
}
