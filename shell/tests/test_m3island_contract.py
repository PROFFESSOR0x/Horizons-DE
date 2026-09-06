"""Regression checks for the M3 island's non-visual interaction contracts.

These tests intentionally inspect the QML source: the behavior is driven by
Quickshell singletons and is not practical to instantiate in a headless unit
test.  A short Quickshell smoke test complements these checks in CI/local use.
"""

from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[1]


def source(relative_path: str) -> str:
    return (ROOT / relative_path).read_text(encoding="utf-8")


class M3IslandContractTests(unittest.TestCase):
    def test_exactly_one_wheel_handler_owns_island_scrolling(self) -> None:
        """Scroll handling has exactly one owner.

        It used to be M3ClockCenter (clock area only).  It now lives in
        M3IslandContent so it covers the whole pill and so the three scroll
        actions (volume / mediaSeek / layoutCycle) share one wheel accounting
        instead of competing handlers double-firing on the same event.  What
        this test protects is unchanged: one handler, not two.
        """
        clock = source("modules/ii/m3Island/M3ClockCenter.qml")
        island = source("modules/ii/m3Island/M3IslandContent.qml")

        self.assertIn("id: islandWheelHandler", island)
        self.assertIn("onWheel: event =>", island)
        for action in ('"volume"', '"mediaSeek"', '"layoutCycle"'):
            self.assertIn(action, island)
        self.assertIn("Config.options.m3Island.scrollAction", island)

        # The clock must not bring a second handler back.
        self.assertNotIn("WheelHandler {", clock)
        self.assertNotIn("onWheel:", clock)

    def test_notification_queue_respects_popup_state(self) -> None:
        island = source("modules/ii/m3Island/M3IslandContent.qml")
        notification_group = source("modules/common/widgets/NotificationGroup.qml")

        self.assertIn("property var notificationQueue", island)
        self.assertIn("if (!notif.popup) return", island)
        self.assertIn("function enqueueNotification", island)
        self.assertIn("function showNextNotification", island)
        self.assertIn("next.timer ? next.timer.interval", island)
        self.assertIn("NotificationGroup", island)
        self.assertIn("expandOnHover", island)
        self.assertIn("managePopupTimeout: false", island)
        self.assertIn("property bool expandOnHover", notification_group)

    def test_m3_visual_settings_have_a_complete_binding_chain(self) -> None:
        config = source("modules/common/Config.qml")
        content = source("modules/ii/m3Island/M3IslandContent.qml")
        settings = source("modules/ii/settings/pages/BarConfig.qml")

        options = {
            "showBackground": "bool",
            "showFrame": "bool",
            "frameThickness": "real",
            "frameColor": "string",
            "followFrameColor": "bool",
            "clockShowSeconds": "bool",
            "notificationTimeout": "int",
        }
        for option, option_type in options.items():
            self.assertIn(f"property {option_type} {option}", config)
            self.assertIn(f"Config.options.m3Island.{option}", settings)

        self.assertIn("Appearance.getColorFromName(Config.options.m3Island.frameColor)", content)
        self.assertIn("launcherHug", content)
        self.assertIn("property JsonObject wallpaperBackground", config)
        self.assertIn("Config.options.m3Island.wallpaperBackground", settings)
        self.assertIn("opts.m3Island.wallpaperBackground === undefined", config)

    def test_m3_clock_is_available_per_layout_without_duplicate_rows(self) -> None:
        settings = source("modules/ii/settings/pages/BarConfig.qml")
        content = source("modules/ii/m3Island/M3IslandContent.qml")

        self.assertIn("function availableForM3(currentLayout)", settings)
        self.assertIn("if (w.id === \"m3Clock\") return !localLayout.includes(w.id)", settings)
        self.assertIn("availableForM3(Config.options.m3Island.layouts.hoverLayout)", settings)
        self.assertIn("hoverLayoutHasClock", content)
        self.assertIn("expandedLayoutHasClock", content)

    def test_m3_clock_honors_its_hour_mode_and_shared_format(self) -> None:
        clock = source("modules/ii/m3Island/M3ClockCenter.qml")

        self.assertIn("Config.options?.time?.format", clock)
        self.assertIn("formatWithSeconds", clock)
        self.assertIn("property bool use24Hour", clock)
        self.assertIn("formatForHourMode", clock)
        self.assertIn("Config.options.m3Island.clockUse24h", clock)

    def test_global_glass_and_motion_are_centrally_configured(self) -> None:
        config = source("modules/common/Config.qml")
        appearance = source("modules/common/Appearance.qml")
        settings = source("modules/ii/settings/pages/InterfaceConfig.qml")

        self.assertIn("property JsonObject glass", config)
        self.assertIn("property JsonObject motion", config)
        self.assertIn("liquidGlassEnabled", appearance)
        self.assertIn("configuredContentTransparency: Config?.options.appearance.transparency.enable", appearance)
        self.assertIn('motionStyle === "smooth"', appearance)

        # Blur / transparency / glass are no longer three independent switches
        # ("Enable Liquid Glass" and friends) - they are one exclusive
        # appearance.visualEffect choice, applied through
        # Config.applyVisualEffectExclusivity().  The settings page must drive
        # that single value rather than poking the individual flags.
        self.assertIn("property string visualEffect", config)
        self.assertIn("function applyVisualEffectExclusivity", config)
        self.assertIn("Config.options.appearance.visualEffect", settings)
        self.assertIn("Config.applyVisualEffectExclusivity(newValue)", settings)
        for effect in ('"none"', '"blur"', '"transparency"', '"glass"'):
            self.assertIn(f"value: {effect}", settings)

        # Each effect still has to reach its own knobs from the same page.
        self.assertIn("Config.options.appearance.glass.opacity", settings)
        self.assertIn("Config.options.appearance.motion.style", settings)
        self.assertIn("Config.options.appearance.motion.durationScale", settings)

        # "Blur" is invisible behind a fully opaque panel, so panel
        # translucency in blur mode is part of the same central chain:
        # config -> Appearance -> settings.
        self.assertIn("property real blurPanelTransparency", config)
        self.assertIn("blurPanelsEnabled", appearance)
        self.assertIn("Config.options.appearance.blurPanelTransparency", settings)

    def test_persistent_and_compositor_data_fail_closed(self) -> None:
        todo = source("services/Todo.qml")
        hyprland_data = source("services/HyprlandData.qml")
        xkb = source("services/HyprlandXkb.qml")
        theme_loader = source("services/MaterialThemeLoader.qml")
        styled_popup = source("modules/common/widgets/StyledPopup.qml")

        self.assertIn("Corrupt storage", todo)
        self.assertIn("function parseHyprctlJson", hyprland_data)
        self.assertIn("Failed to parse devices", xkb)
        self.assertIn("Ignoring invalid color theme", theme_loader)
        self.assertIn("Appearance.liquidGlassEnabled", styled_popup)

    def test_compositor_refreshes_are_debounced(self) -> None:
        hyprland_data = source("services/HyprlandData.qml")

        self.assertIn("id: refreshDebounce", hyprland_data)
        self.assertIn("function scheduleUpdateAll", hyprland_data)
        self.assertIn("scheduleUpdateAll()", hyprland_data)

    def test_hyprland_customization_never_writes_removed_options(self) -> None:
        config = source("modules/common/Config.qml")
        settings = source("modules/ii/settings/pages/HyprlandSettings.qml")
        configurator = source("scripts/hyprland/hyprconfigurator.py")
        # decoration:blur:variant is deliberately no longer in this list: it is
        # a real Hyprland option that simply predates no tagged release, so it
        # is offered but gated at runtime instead of removed - see the two
        # assertions below.  The rest were removed upstream outright and must
        # never be written again.
        unsupported = (
            "input:scroll_lock",
            "input:scroll_point_scroll",
            "input:touchpad:dragfinger_distance",
            "input:touchpad:emulate_scroll",
            "input:touchpad:emulation_scroll_factor",
        )

        for option in unsupported:
            self.assertNotIn(option, settings)
        self.assertNotIn("property int variant", config)
        self.assertNotIn("scrollLock", config)
        self.assertNotIn("dragfingerDistance", config)
        self.assertIn("def option_is_supported", configurator)

        # Runtime gating for decoration:blur:variant, in both directions:
        # the settings page warns instead of silently no-opping, and the
        # configurator drops the key (and clears any stale line) when the
        # running compositor says it does not exist.
        self.assertIn("property string variant", config)
        self.assertIn("HyprlandData.blurVariantSupported", settings)
        self.assertIn("blurVariantSupported", source("services/HyprlandData.qml"))
        self.assertIn("option_is_supported(key) is False", configurator)

    def test_notification_expiry_reassigns_the_derived_popup_model(self) -> None:
        notifications = source("services/Notifications.qml")
        start = notifications.index("function timeoutNotification")
        end = notifications.index("function timeoutAll", start)

        self.assertIn("triggerListChange()", notifications[start:end])
        self.assertIn("Ignoring invalid notification storage", notifications)

    def test_sidebar_uses_the_service_filtered_player_list(self) -> None:
        sidebar = source("modules/ii/sidebarRight/SidebarRightContent.qml")

        self.assertIn("MprisController.players", sidebar)
        self.assertNotIn("filterDuplicatePlayers(", sidebar)

    def test_window_switcher_keeps_live_previews_and_recency_order(self) -> None:
        grid = source("modules/ii/overview/WindowsGrid.qml")

        # Win+Tab is independent from the launcher Overview, so using
        # overviewOpen here silently turns every ScreencopyView into an empty
        # tile. The same state must also close when a thumbnail is activated.
        self.assertIn("focusHistoryID", grid)
        self.assertIn("out.sort", grid)
        self.assertIn("GridView", grid)
        self.assertIn("columnCount", grid)
        self.assertIn("preferredCellWidth", grid)
        self.assertIn("maxGridHeight", grid)
        self.assertIn("ScrollBar.vertical: StyledScrollBar", grid)
        self.assertIn("captureSource: GlobalStates.windowSwitcherOpen", grid)
        self.assertIn("live: GlobalStates.windowSwitcherOpen", grid)
        self.assertIn("GlobalStates.windowSwitcherOpen = false", grid)

    def test_window_switcher_has_its_own_surface(self) -> None:
        view = source("modules/ii/overview/WindowSwitcherView.qml")

        self.assertIn("Rectangle {", view)
        self.assertIn("color: Appearance.colors.colLayer0", view)
        self.assertIn("StyledRectangularShadow { target: root }", view)

    def test_window_switcher_tab_key_toggles_its_two_views(self) -> None:
        view = source("modules/ii/overview/WindowSwitcherView.qml")

        self.assertIn("function toggleTab()", view)
        self.assertIn("Qt.Key_Tab", view)
        self.assertIn("Qt.Key_Backtab", view)
        self.assertIn("tabBar.setCurrentIndex(nextIndex)", view)
        self.assertIn("filterField.forceActiveFocus", view)

    def test_workspace_groups_have_context_actions_and_shared_switcher_scope(self) -> None:
        config = source("modules/common/Config.qml")
        states = source("GlobalStates.qml")
        bar = source("modules/ii/bar/Workspaces.qml")
        menu = source("modules/ii/bar/WorkspaceContextMenu.qml")
        grid = source("modules/ii/overview/WindowsGrid.qml")
        settings = source("modules/ii/settings/pages/InterfaceConfig.qml")

        self.assertIn("property JsonObject workspaceLinking", config)
        self.assertIn("property list<var> groups", config)
        self.assertIn("opts.workspaceLinking === undefined", config)
        self.assertIn("function linkSelectedWorkspaces", states)
        self.assertIn("function detachWorkspace", states)
        self.assertIn("function closeWorkspaceWindows", states)
        self.assertIn("GlobalStates.activateWorkspace", bar)
        self.assertIn("WorkspaceContextMenu", bar)
        self.assertIn("Link selected workspaces", menu)
        self.assertIn("Close all windows", menu)
        self.assertIn("End task for all windows", menu)
        self.assertIn("Separate this workspace from the group", menu)
        self.assertIn("linkedWorkspaceScope", grid)
        self.assertIn("Use one workspace set across all screens", settings)

    def test_dock_context_menu_only_exposes_window_actions_for_running_apps(self) -> None:
        menu = source("modules/common/widgets/DockAppContextMenu.qml")
        dock_button = source("modules/common/widgets/DockAppButton.qml")
        drag_apps = source("modules/common/widgets/DragApps.qml")
        dock_to_panel = source("modules/ii/bar/DocktoPanel.qml")
        wm = source("services/WM.qml")
        hyprland = source("services/HyprlandBackend.qml")

        self.assertIn("readonly property bool hasWindows", menu)
        self.assertIn("visible: root.hasWindows", menu)
        self.assertIn("Close window", menu)
        self.assertIn("End task", menu)
        self.assertIn("Keep on dock", menu)
        self.assertIn("Remove from dock", menu)
        self.assertIn("DockAppContextMenu", dock_button)
        self.assertIn("DockAppContextMenu", drag_apps)
        self.assertIn("DockAppContextMenu", dock_to_panel)
        self.assertIn("function forceCloseWindow", wm)
        self.assertIn("function forceCloseWindow", hyprland)

    def test_window_switcher_opens_power_actions_as_a_right_edge_sheet(self) -> None:
        view = source("modules/ii/overview/WindowSwitcherView.qml")
        session = source("modules/ii/sessionScreen/SessionScreen.qml")
        states = source("GlobalStates.qml")

        self.assertIn("function openPowerMenu()", view)
        self.assertIn("GlobalStates.sessionForceRightEdge = true", view)
        self.assertIn("power_settings_new", view)
        self.assertIn("sessionForceRightEdge", states)
        self.assertIn("GlobalStates.sessionForceRightEdge", session)

    def test_region_toolbar_sync_is_imperative_not_a_binding_loop(self) -> None:
        toolbar = source("modules/ii/regionSelector/OptionsToolbar.qml")

        self.assertIn("function selectionModeToIndex()", toolbar)
        self.assertIn("onSelectionModeChanged", toolbar)
        self.assertNotIn("selectionModeIndex", toolbar)

    def test_launcher_results_are_scheduled_without_a_binding_loop(self) -> None:
        launcher = source("services/LauncherSearch.qml")
        m3_launcher = source("modules/ii/m3Island/M3LauncherInline.qml")

        self.assertIn("property list<var> results: []", launcher)
        self.assertNotIn("property list<var> results: {", launcher)
        self.assertIn("function buildResults()", launcher)
        self.assertIn("function updateResults()", launcher)
        self.assertIn("onQueryChanged:", launcher)
        self.assertIn("fileSearchRevision", launcher)
        self.assertIn("filesProc.searchRevision === root.fileSearchRevision", launcher)
        self.assertIn("interval: 24", m3_launcher)

    def test_settings_search_names_the_matching_option(self) -> None:
        settings_content = source("modules/ii/settings/SettingsContent.qml")
        settings_search = source("modules/ii/settings/pages/SettingsSearch.qml")

        self.assertIn("settingLabels", settings_content)
        self.assertIn("collectSearchData", settings_content)
        self.assertIn("matchingSettings", settings_search)
        self.assertIn("resultButton.modelData.matchingSettings", settings_search)

    def test_settings_text_inputs_keep_a_resting_outline(self) -> None:
        config_text_area = source("modules/common/widgets/ConfigTextArea.qml")
        text_field = source("modules/common/widgets/MaterialTextField.qml")
        text_area = source("modules/common/widgets/MaterialTextArea.qml")

        self.assertIn("border.width: textArea.activeFocus ? 2 : 1", config_text_area)
        self.assertIn("border.width: root.activeFocus ? 2 : 1", text_field)
        self.assertIn("border.width: root.focus ? 2 : 1", text_area)

    def test_default_application_categories_update_mimeapps_once_per_edit(self) -> None:
        config = source("modules/common/Config.qml")
        theming = source("services/SystemTheming.qml")
        settings = source("modules/ii/settings/pages/ServicesConfig.qml")
        script = source("scripts/theming/set-default-app.sh")

        self.assertIn("property JsonObject defaultApplications", config)
        self.assertIn("opts.apps.defaultApplications === undefined", config)
        for category in ("browser", "folders", "documents", "images", "audio", "video", "archives"):
            self.assertIn(f"defaultApplications.{category}", settings)
        self.assertIn("id: defaultApplicationCommit", settings)
        self.assertIn("scheduleDefaultApplication", settings)
        self.assertIn("set-default-app.sh", theming)
        self.assertIn('handler.endsWith(".desktop")', theming)
        self.assertIn("xdg-mime default", script)

    def test_lock_keeps_clock_but_hides_controls_on_non_pointer_screens(self) -> None:
        config = source("modules/common/Config.qml")
        lock = source("modules/ii/lock/LockSurface.qml")
        background = source("modules/ii/background/Background.qml")
        clock = source("modules/ii/background/widgets/clock/ClockWidget.qml")
        settings = source("modules/ii/settings/pages/InterfaceConfig.qml")
        states = source("GlobalStates.qml")

        self.assertIn("property bool autoHideControls", config)
        self.assertIn("property int controlsIdleSeconds", config)
        self.assertIn("id: controlsIdleTimer", lock)
        self.assertIn("function registerInteraction()", lock)
        self.assertIn("surfaceScreenName", lock)
        self.assertIn("isInteractionScreen", lock)
        self.assertIn("Behavior on controlsVisibility", lock)
        self.assertIn("surfaceScreenName === \"\"", lock)
        self.assertIn("Config.options.background.widgets.clock.enable", background)
        self.assertIn("visibleWhenLocked: true", clock)
        self.assertNotIn("lockVisualizerRing", clock)
        self.assertNotIn("clockVisualizer", settings)
        self.assertIn("Hide lock controls when idle", settings)
        self.assertIn("lockInteractionScreenName", states)
        self.assertIn("Center clock is enabled", clock)
        self.assertIn("Turn it off and move", clock)
        self.assertIn("Config.options.lock.centerClock = false", clock)

    def test_lock_preview_and_lock_only_widget_controls_share_the_desktop_canvas(self) -> None:
        states = source("GlobalStates.qml")
        config = source("modules/common/Config.qml")
        abstract_widget = source("modules/ii/background/widgets/AbstractBackgroundWidget.qml")
        background = source("modules/ii/background/Background.qml")
        interface = source("modules/ii/settings/pages/InterfaceConfig.qml")
        widget_settings = source("modules/ii/settings/pages/BackgroundConfig.qml")

        self.assertIn("property bool lockPreviewOpen", states)
        self.assertIn("property list<string> lockOnly", config)
        self.assertIn("lockPresentationActive", abstract_widget)
        self.assertIn("onlyWhenLocked", abstract_widget)
        self.assertIn("draggable: GlobalStates.lockPreviewOpen", abstract_widget)
        self.assertIn("drag.filterChildren: GlobalStates.lockPreviewOpen", source("modules/common/widgets/widgetCanvas/AbstractWidget.qml"))
        self.assertIn("GlobalStates.lockPreviewOpen", source("modules/common/widgets/widgetCanvas/WidgetCanvas.qml"))
        self.assertIn("GlobalStates.lockPreviewOpen", background)
        self.assertIn("lockPreviewToolbar", background)
        self.assertIn("lockControlsPreview", background)
        self.assertIn("previewPasswordToolbar", background)
        self.assertIn("previewLeftToolbar", background)
        self.assertIn("previewRightToolbar", background)
        self.assertIn("beginToolbarDrag", background)
        self.assertIn("previewPasswordDragHandle", background)
        self.assertIn("previewLeftDragHandle", background)
        self.assertIn("previewRightDragHandle", background)
        self.assertIn("function previewPoint(item, mouse)", background)
        self.assertIn("mapToItem(lockControlsPreview", background)
        self.assertIn("GlobalStates.saveLockPreview()", background)
        self.assertIn("GlobalStates.resetLockWidgetLayout()", background)
        self.assertIn("Lock screen live preview", interface)
        self.assertIn("visualizerMirror", interface)
        self.assertIn("setWidgetLockOnly", widget_settings)
        self.assertIn("Show only on the lock screen", widget_settings)

    def test_lock_layout_can_be_shared_or_saved_per_output(self) -> None:
        config = source("modules/common/Config.qml")
        states = source("GlobalStates.qml")
        abstract_widget = source("modules/ii/background/widgets/AbstractBackgroundWidget.qml")
        lock = source("modules/ii/lock/LockSurface.qml")
        background = source("modules/ii/background/Background.qml")
        settings = source("modules/ii/settings/pages/InterfaceConfig.qml")

        self.assertIn("property bool perScreenLayout", config)
        self.assertIn("property var layoutByScreen", config)
        self.assertIn("property bool unlockBoxPrimaryMonitorOnly", config)
        self.assertIn("function applyLockDesignToOutput", states)
        self.assertIn("byScreen", abstract_widget)
        self.assertIn("lockLayoutForOutput", lock)
        self.assertIn("Apply other screen", background)
        self.assertIn("Customize lock layout per display", settings)
        self.assertIn("Unlock box just on the primary monitor", settings)

    def test_system_icon_and_cursor_theme_settings_are_wired_to_global_theming(self) -> None:
        settings = source("modules/ii/settings/pages/InterfaceConfig.qml")
        theming = source("services/SystemTheming.qml")

        self.assertIn("System icon theme", settings)
        self.assertIn("Mouse cursor theme", settings)
        self.assertIn("id: cursorSizeControl", settings)
        self.assertIn("SystemTheming.applyIconTheme(theme)", settings)
        self.assertIn("SystemTheming.applyCursorTheme", settings)
        self.assertIn("set-icon-theme.sh", theming)
        self.assertIn("set-cursor-theme.sh", theming)

    def test_desktop_visualizers_use_cava_standard_range_and_shared_response_model(self) -> None:
        config = source("modules/common/Config.qml")
        cava = source("scripts/cava/raw_output_config.txt")
        bars = source("modules/ii/background/widgets/visualizer/FrequencyBars.qml")
        normal = source("modules/ii/background/widgets/visualizer/VisualizerWidget.qml")
        mirrored = source("modules/ii/background/widgets/visualizer/MirroredVisualizerWidget.qml")
        service = source("services/DesktopVisualizer.qml")
        background = source("modules/ii/background/Background.qml")
        settings = source("modules/ii/settings/pages/BackgroundConfig.qml")

        self.assertIn("ascii_max_range = 1000", cava)
        self.assertIn("property real rawMaximum: 1000", bars)
        self.assertIn("property real attack", bars)
        self.assertIn("property real release", bars)
        self.assertIn("root.displayPoints = next", bars)
        self.assertIn("CAVA is deliberately stopped", bars)
        self.assertIn("property JsonObject visualizerMirror", config)
        self.assertIn('configEntryName: "visualizerMirror"', mirrored)
        self.assertIn("mirrored: true", mirrored)
        self.assertIn("FrequencyBars", normal)
        self.assertIn("mirroredEnabled", service)
        self.assertIn("MirroredVisualizerWidget", background)
        self.assertIn("Mirrored visualizer", settings)
        self.assertIn("Noise gate", settings)
        self.assertIn("Reset visualizer settings", settings)
        self.assertIn("fromCenter", bars)
        self.assertIn("browser video, games and PipeWire clients", source("modules/ii/mediaControls/MediaControls.qml"))

    def test_classic_launcher_arrows_select_and_enter_activates_that_selection(self) -> None:
        search_bar = source("modules/ii/overview/SearchBar.qml")
        search_widget = source("modules/ii/overview/SearchWidget.qml")
        item = source("modules/ii/overview/SearchItem.qml")

        self.assertIn("property var resultsView", search_bar)
        self.assertIn("function moveResult(step)", search_bar)
        self.assertIn("Keys.priority: Keys.BeforeItem", search_bar)
        self.assertIn("Qt.Key_Down", search_bar)
        self.assertIn("Qt.Key_Up", search_bar)
        self.assertIn("view.positionViewAtIndex(next, ListView.Contain)", search_bar)
        self.assertIn("signal activateResult()", search_bar)
        self.assertIn("onActivateResult: root.activateCurrentResult()", search_widget)
        self.assertIn("function activateCurrentResult()", search_widget)
        self.assertIn("ListView.isCurrentItem", item)


if __name__ == "__main__":
    unittest.main()
