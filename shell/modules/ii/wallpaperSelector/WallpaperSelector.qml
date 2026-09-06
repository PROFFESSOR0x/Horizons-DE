import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import qs.modules.ii.m3Island
import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland

Scope {
    id: root

    property bool reallyOpen: false
    // In M3 mode the selector is hosted by M3IslandContent itself so the
    // island morphs into one continuous surface (the same pattern used by
    // the inline launcher). Keeping a second PanelWindow under the pill made
    // the two surfaces look merely adjacent, especially over light wallpaper.
    readonly property bool embeddedInM3Island: Config.options.bar.barMode === "m3Island"
        && (Config.options.wallpaperSelector.dockToIsland ?? true)
        && !Config.options.bar.vertical

    Connections {
        target: GlobalStates
        function onWallpaperSelectorOpenChanged() {
            if (GlobalStates.wallpaperSelectorOpen) {
                closeAnimTimer.stop();
                root.reallyOpen = true;
            } else {
                closeAnimTimer.restart();
            }
        }
    }

    Timer {
        id: closeAnimTimer
        interval: Appearance.animation.sidebarSlideExit.duration
        onTriggered: root.reallyOpen = false
    }

    Loader {
        id: wallpaperSelectorLoader
        active: root.reallyOpen && !root.embeddedInM3Island

        sourceComponent: PanelWindow {
            id: panelWindow
            readonly property var monitor: WM.monitorFor(panelWindow.screen)
            property bool monitorIsFocused: WM.compositor === "hyprland"
                ? (Hyprland.focusedMonitor?.name == monitor?.name)
                : (WM.focusedMonitor?.name == monitor?.name)

            exclusionMode: ExclusionMode.Ignore
            // See Bar.qml (shell/modules/ii/bar/Bar.qml) for why this is
            // gated behind a Wayland-only Loader instead of set directly.
            Loader {
                active: WM.isWayland
                sourceComponent: Item {
                    Binding { target: panelWindow.WlrLayershell; property: "namespace"; value: "quickshell:wallpaperSelector" }
                    Binding { target: panelWindow.WlrLayershell; property: "layer"; value: WlrLayer.Overlay }
                    Binding { target: panelWindow.WlrLayershell; property: "keyboardFocus"; value: WlrKeyboardFocus.OnDemand }
                }
            }
            color: "transparent"

            // ── Docking to the M3 island ──────────────────────────────────
            // With the island bar the selector used to open as an unrelated
            // slab under a bar-height offset the island doesn't even have.
            // Docked, it attaches to the pill's real, live edge (published by
            // M3IslandContent into M3IslandState.geometry) and reads as a
            // drawer pulled out of the island - the content side draws the
            // fillets that join the two shapes, see WallpaperSelectorContent.
            readonly property var islandGeometry: M3IslandState.geometryFor(panelWindow.screen?.name ?? "")
            readonly property bool dockedToIsland: Config.options.bar.barMode === "m3Island"
                && (Config.options.wallpaperSelector.dockToIsland ?? true)
                && !Config.options.bar.vertical
                && panelWindow.islandGeometry !== null
            // The island lives at whichever edge the bar is on, so the drawer
            // comes out of the matching side.
            readonly property bool dockedAtBottom: panelWindow.dockedToIsland && Config.options.bar.bottom
            // How far the drawer's own surface sits inside this window on the
            // island side: its shadow inset plus the band the junction fillets
            // are drawn in. Subtracted from the window offset so the surface
            // edge still lands exactly on the pill's edge.
            // Same corner size the island uses to blend into the screen edge,
            // so both junctions speak the same shape language. Clamped to the
            // drawer's own corner radius so the fillet can't outgrow it.
            readonly property real junctionCornerSize: panelWindow.dockedToIsland
                ? Math.max(0, Math.min(Config.options.m3Island.hugCornerSize ?? 22,
                                       Appearance.rounding.screenRounding + 5))
                : 0
            readonly property real dockSurfaceInset: Appearance.sizes.elevationMargin + panelWindow.junctionCornerSize

            anchors.top: !panelWindow.dockedAtBottom
            anchors.bottom: panelWindow.dockedAtBottom
            margins {
                // WallpaperSelectorContent insets its own surface by
                // elevationMargin (that inset is where its shadow is drawn), so
                // the window has to start that much earlier for the surface's
                // edge to land exactly on the island's.
                top: {
                    if (panelWindow.dockedAtBottom) return 0
                    if (panelWindow.dockedToIsland)
                        return Math.max(0, panelWindow.islandGeometry.bottom - panelWindow.dockSurfaceInset)
                    return Config?.options.bar.vertical ? Appearance.sizes.hyprlandGapsOut : Appearance.sizes.barHeight + Appearance.sizes.hyprlandGapsOut
                }
                bottom: {
                    if (!panelWindow.dockedAtBottom) return 0
                    const screenHeight = panelWindow.screen?.height ?? 0
                    return Math.max(0, screenHeight - panelWindow.islandGeometry.top - panelWindow.dockSurfaceInset)
                }
            }

            mask: Region {
                item: content
            }

            implicitHeight: Appearance.sizes.wallpaperSelectorHeight
            implicitWidth: Appearance.sizes.wallpaperSelectorWidth

            Component.onCompleted: {
                GlobalFocusGrab.addDismissable(panelWindow);
                content.slideIn();
            }
            Component.onDestruction: {
                GlobalFocusGrab.removeDismissable(panelWindow);
            }
            Connections {
                target: GlobalFocusGrab
                function onDismissed() {
                    GlobalStates.wallpaperSelectorOpen = false;
                }
            }

            WallpaperSelectorContent {
                id: content
                width: parent.width
                height: parent.height
                x: 0
                y: 0

                // Told where the island is (in this window's coordinates) so it
                // can draw the junction between the pill and this surface.
                dockedToIsland: panelWindow.dockedToIsland
                dockedAtBottom: panelWindow.dockedAtBottom
                junctionCornerSize: panelWindow.junctionCornerSize
                // The window is centred by the compositor and doesn't report a
                // usable x under layer-shell, so the island's offset inside it
                // is derived from the two known widths rather than read back.
                islandLeft: panelWindow.dockedToIsland
                    ? (panelWindow.islandGeometry.x - ((panelWindow.screen?.width ?? panelWindow.width) - panelWindow.width) / 2)
                    : 0
                islandWidth: panelWindow.dockedToIsland ? panelWindow.islandGeometry.width : 0

                // Docked, the drawer emerges from the pill: a short travel plus
                // a fade, instead of falling a full panel-height from off-screen
                // and sweeping across the island on the way.
                readonly property real hiddenOffset: panelWindow.dockedToIsland
                    ? (panelWindow.dockedAtBottom ? 36 : -36)
                    : -content.height

                function slideIn() {
                    content.y = content.hiddenOffset;
                    if (WM.compositor === "niri") {
                        Qt.callLater(() => { Qt.callLater(() => { content.y = 0; }); });
                    } else {
                        Qt.callLater(() => { content.y = 0; });
                    }
                }

                opacity: GlobalStates.wallpaperSelectorOpen ? 1 : 0
                Behavior on opacity {
                    NumberAnimation {
                        duration: Appearance.animation.elementMoveFast.duration
                        easing.type: Easing.OutCubic
                    }
                }

                Connections {
                    target: GlobalStates
                    function onWallpaperSelectorOpenChanged() {
                        if (!GlobalStates.wallpaperSelectorOpen) {
                            content.y = content.hiddenOffset;
                        }
                    }
                }

                Behavior on y {
                    NumberAnimation {
                        duration: WM.compositor === "niri"
                            ? Appearance.animation.sidebarSlideEnter.duration
                            : Appearance.animation.sidebarSlideExit.duration
                        easing.type: GlobalStates.wallpaperSelectorOpen
                            ? Appearance.animation.sidebarSlideEnter.type
                            : Appearance.animation.sidebarSlideExit.type
                        easing.bezierCurve: GlobalStates.wallpaperSelectorOpen
                            ? Appearance.animation.sidebarSlideEnter.bezierCurve
                            : Appearance.animation.sidebarSlideExit.bezierCurve
                    }
                }
            }
        }
    }

    function toggleWallpaperSelector() {
        if (Config.options.wallpaperSelector.useSystemFileDialog) {
            Wallpapers.openFallbackPicker(Appearance.m3colors.darkmode);
            return;
        }
        GlobalStates.wallpaperSelectorOpen = !GlobalStates.wallpaperSelectorOpen
    }

    IpcHandler {
        target: "wallpaperSelector"

        function toggle(): void {
            root.toggleWallpaperSelector();
        }

        function random(): void {
            Wallpapers.randomFromCurrentFolder();
        }
    }

    CompositorGlobalShortcut {
        name: "wallpaperSelectorToggle"
        description: "Toggle wallpaper selector"
        onPressed: {
            root.toggleWallpaperSelector();
        }
    }

    CompositorGlobalShortcut {
        name: "wallpaperSelectorRandom"
        description: "Select random wallpaper in current folder"
        onPressed: {
            Wallpapers.randomFromCurrentFolder();
        }
    }
}
