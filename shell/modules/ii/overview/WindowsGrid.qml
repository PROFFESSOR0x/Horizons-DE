pragma ComponentBehavior: Bound
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import QtQuick
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
    readonly property real tileMaxWidth: 240
    readonly property real tileMaxHeight: 155
    readonly property real tileMinWidth: 90
    readonly property real tileMinHeight: 60
    readonly property real tileSpacing: 14
    readonly property real flowWidth: tileMaxWidth * 4 + tileSpacing * 3

    // De-duplicated, filtered {toplevel, win, address} entries - same
    // toplevel/windowByAddress matching OverviewWidget already uses, just
    // without the per-workspace grouping.
    readonly property var matchingWindows: {
        const needle = root.filterText.trim().toLowerCase();
        const seen = ({});
        const out = [];
        ToplevelManager.toplevels.values.forEach(toplevel => {
            const address = `0x${toplevel.HyprlandToplevel?.address}`;
            const win = root.windowByAddress[address];
            if (!win || seen[address]) return;
            if (needle !== "") {
                const title = (win.title ?? "").toLowerCase();
                const cls = (win.class ?? "").toLowerCase();
                if (!title.includes(needle) && !cls.includes(needle)) return;
            }
            seen[address] = true;
            out.push({ toplevel, win, address });
        });
        return out;
    }

    implicitWidth: Math.min(root.flowWidth, Math.max(flow.implicitWidth, emptyText.implicitWidth))
    implicitHeight: Math.max(flow.visible ? flow.implicitHeight : 0, emptyText.visible ? emptyText.implicitHeight + 40 : 0)

    Flow {
        id: flow
        width: root.implicitWidth
        spacing: root.tileSpacing
        visible: root.matchingWindows.length > 0

        Repeater {
            model: root.matchingWindows
            delegate: Rectangle {
                id: tile
                required property var modelData
                readonly property var win: modelData.win
                readonly property var toplevel: modelData.toplevel
                readonly property real rawW: win?.size?.[0] ?? 1
                readonly property real rawH: win?.size?.[1] ?? 1
                readonly property real fitScale: Math.min(root.tileMaxWidth / Math.max(rawW, 1), root.tileMaxHeight / Math.max(rawH, 1), 1)
                width: Math.max(rawW * fitScale, root.tileMinWidth)
                height: Math.max(rawH * fitScale, root.tileMinHeight)
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
                    captureSource: GlobalStates.overviewOpen ? tile.toplevel : null
                    live: true

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
                            GlobalStates.overviewOpen = false;
                            Hyprland.dispatch(`hl.dsp.focus({ window = "address:${tile.win.address}" })`);
                        } else if (event.button === Qt.MiddleButton) {
                            Hyprland.dispatch(`hl.dsp.window.close({ window = "address:${tile.win.address}" })`);
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
