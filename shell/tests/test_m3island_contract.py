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
        xkb = source("services/HyprlandXkb.qml")
        theme_loader = source("services/MaterialThemeLoader.qml")
        styled_popup = source("modules/common/widgets/StyledPopup.qml")

        self.assertIn("Corrupt storage", todo)
        # Hyprland failure preservation is exercised by test_performance_runtime.
        self.assertIn("Failed to parse devices", xkb)
        self.assertIn("Ignoring invalid color theme", theme_loader)
        self.assertIn("Appearance.liquidGlassEnabled", styled_popup)

    # Scheduler semantics now have real QML tests in test_performance_runtime.py.

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
        self.assertIn("function persistentImage(image)", notifications)
        self.assertIn('value.startsWith("image://qsimage/")', notifications)
        self.assertIn("image = \"\"", notifications)

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

    def test_taskbar_refresh_does_not_index_desktop_entries_or_fuzzy_search(self) -> None:
        """Opening a window must leave the QML event loop's hot path cheap.

        The taskbar model is rebuilt after every toplevel update.  Dock
        delegates used to call DesktopEntries.heuristicLookup and
        AppSearch.guessIcon while that rebuild was propagating, which can
        synchronously scan the desktop-entry index after a file opener maps a
        window.  Context-menu lookup is deliberately retained, but only when
        the user requests it.
        """
        taskbar = source("services/TaskbarApps.qml")
        dock_button = source("modules/common/widgets/DockAppButton.qml")
        drag_apps = source("modules/common/widgets/DragApps.qml")
        dock_to_panel = source("modules/ii/bar/DocktoPanel.qml")
        tasklist = source("modules/ii/tasklistBar/TasklistBarContent.qml")
        active_window = source("modules/ii/bar/ActiveWindow.qml")
        workspaces = source("modules/ii/bar/Workspaces.qml")
        info_strip = source("modules/ii/infoStrip/InfoStripContent.qml")
        menu = source("modules/common/widgets/DockAppContextMenu.qml")

        self.assertIn("function iconFor(appId)", taskbar)
        self.assertIn("property var iconCache", taskbar)
        self.assertNotIn("AppSearch.guessIcon", taskbar)
        self.assertNotIn("DesktopEntries.heuristicLookup", dock_button)
        self.assertNotIn("DesktopEntries.heuristicLookup", drag_apps)
        self.assertNotIn("DesktopEntries.heuristicLookup", dock_to_panel)
        self.assertNotIn("AppSearch.guessIcon", dock_button)
        self.assertNotIn("AppSearch.guessIcon", drag_apps)
        self.assertNotIn("AppSearch.guessIcon", dock_to_panel)
        self.assertNotIn("AppSearch.guessIcon", tasklist)
        self.assertNotIn("DesktopEntries.heuristicLookup", tasklist)
        self.assertNotIn("AppSearch.guessIcon", active_window)
        self.assertNotIn("AppSearch.guessIcon", workspaces)
        self.assertNotIn("AppSearch.guessIcon", info_strip)
        self.assertIn("function showAt(x, y)", menu)
        self.assertIn("DesktopEntries.heuristicLookup(root.applicationId)", menu)

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
        self.assertIn("function addWorkspaceSelection", states)
        self.assertIn("workspaceSelectionAnchor", states)
        self.assertIn("function ensureUnifiedWorkspaceGroup", states)
        self.assertIn("function unifiedWorkspaceMembers", states)
        self.assertIn("function isRealWorkspaceId", states)
        self.assertIn("detachedGroups", config)
        self.assertIn("cleanDetachedWorkspaceGroups", config)
        self.assertIn("GlobalStates.activateWorkspace", bar)
        self.assertIn("rightSelectionDrag", bar)
        self.assertIn("rightSelectionLastWorkspace", bar)
        self.assertIn("GlobalStates.addWorkspaceSelection", bar)
        self.assertIn("onPositionChanged: mouse", bar)
        self.assertIn("mouse.buttons & Qt.RightButton", bar)
        self.assertIn("switchWorkspace(workspaceId)", bar)
        self.assertIn("onClicked: mouse", bar)
        self.assertIn("workspaceIdForMouse", bar)
        self.assertIn("function unifiedSetMembers", states)
        self.assertIn("function initializeUnifiedWorkspaceSets", states)
        self.assertIn("function unifiedWorkspaceIdForSlot", states)
        self.assertIn("nextUnusedWorkspaceId", states)
        self.assertIn("function activateUnifiedWorkspaceNumber", states)
        self.assertIn("function switchUnifiedWorkspaceRelative", states)
        self.assertIn("function cycleUnifiedWindows", states)
        self.assertIn("function focusWindowInUnifiedSet", states)
        self.assertIn("function synchronizeFocusedWindowInUnifiedSet", states)
        self.assertIn('name: "unifiedWorkspaceNext"', states)
        self.assertIn('name: "unifiedWorkspaceCycleWindows"', states)
        self.assertIn("unifiedSets", config)
        self.assertIn("HyprlandData.monitors.find", source("services/HyprlandBackend.qml"))
        self.assertIn('Quickshell.execDetached(["hyprctl", "eval"', source("services/HyprlandBackend.qml"))
        self.assertIn("hl.dsp.workspace.move", source("services/HyprlandBackend.qml"))
        self.assertIn("hl.dsp.cursor.move", source("services/HyprlandBackend.qml"))
        self.assertIn("math.floor(m.width / 2)", source("services/HyprlandBackend.qml"))
        self.assertIn("math.floor(m.height / 2)", source("services/HyprlandBackend.qml"))
        self.assertNotIn("m.position.x + 1", source("services/HyprlandBackend.qml"))
        self.assertIn("windowToFocus", source("services/HyprlandBackend.qml"))
        self.assertIn("focusWindowInUnifiedSet", source("modules/common/widgets/DragApps.qml"))
        self.assertIn("focusWindowInUnifiedSet", source("modules/common/widgets/DockAppButton.qml"))
        self.assertIn("synchronizeFocusedWindowInUnifiedSet", source("modules/ii/bar/SysTrayItem.qml"))
        self.assertIn("function clientForToplevel", source("services/HyprlandData.qml"))
        self.assertIn("windowByAddress[address]", source("services/HyprlandData.qml"))
        self.assertIn("toplevel.appId", source("services/HyprlandData.qml"))
        self.assertIn("WorkspaceContextMenu", bar)
        self.assertIn("Link selected workspaces", menu)
        self.assertIn("Close all windows", menu)
        self.assertIn("End task for all windows", menu)
        self.assertIn("Separate this workspace from the group", menu)
        self.assertIn("rect.x: root.menuX", menu)
        self.assertIn("grabFocus: true", menu)
        self.assertIn("property var dismissAction", menu)
        self.assertIn("dismissAction?.()", menu)
        self.assertIn("linkedWorkspaceScope", grid)
        self.assertIn("Use one workspace set across all screens", settings)
        self.assertIn("onClicked: GlobalStates.setUnifiedMultiMonitorWorkspaces", settings)

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
        self.assertIn("Open in new workspace", menu)
        self.assertIn("openInNewWorkspace", menu)
        self.assertIn("dockHold", menu)
        # Closed pinned apps can be launched before DesktopEntries has finished
        # indexing, so launch choices must use the stable app id and fall back
        # to gtk-launch instead of being disabled.
        self.assertIn("readonly property bool canLaunch", menu)
        self.assertIn("enabled: root.canLaunch", menu)
        self.assertIn("AppLaunchService.launchDesktopEntry", menu)
        self.assertIn("onTriggered: root.launch()", menu)
        self.assertIn("DesktopEntries.heuristicLookup(root.applicationId)", menu)
        self.assertIn("Keep on dock", menu)
        self.assertIn("Remove from dock", menu)
        self.assertIn("rect.x: root.menuX", menu)
        self.assertIn("grabFocus: true", menu)
        self.assertIn("DockAppContextMenu", dock_button)
        self.assertIn("DockAppContextMenu", drag_apps)
        self.assertIn("DockAppContextMenu", dock_to_panel)
        self.assertIn("openContextMenu", drag_apps)
        self.assertIn("function forceCloseWindow", wm)
        self.assertIn("function forceCloseWindow", hyprland)

    def test_app_launch_indicator_never_delays_launch_and_finishes_on_mapped_window(self) -> None:
        launcher = source("services/AppLaunchService.qml")
        indicator = source("modules/ii/overlay/AppLaunchIndicator.qml")

        self.assertIn("property bool externalLaunch", launcher)
        self.assertIn("root.begin(appIdValue, iconValue, nameValue, \"\", false)", launcher)
        self.assertIn("launcher()", launcher)
        self.assertNotIn("pendingLauncher", launcher)
        self.assertNotIn("launchTimer", launcher)
        self.assertIn("previousWindowAddresses", launcher)
        self.assertIn("window?.mapped !== false", launcher)
        self.assertIn("id: readyTimer", launcher)
        self.assertIn("root.canonicalAppId(id)", launcher)
        self.assertIn("function screenNameForWindow", launcher)
        self.assertIn("HyprlandData.monitors.find", launcher)
        # An externally-opened file must not synchronously walk the desktop
        # entry index on the UI thread; that was the launch-freeze regression.
        self.assertNotIn("DesktopEntries.", launcher)
        self.assertIn('"org.kde.dolphin": "org.kde.dolphin"', launcher)
        self.assertIn('"org.xfce.thunar": "org.xfce.thunar"', launcher)
        self.assertIn("root.startExternal(fields[2], fields[0], fields[3] || fields[2])", launcher)
        self.assertNotIn("root.startExternal(fields[1], fields[0], fields[2])", launcher)
        self.assertIn("interval: root.externalLaunch ? 520 : 140", launcher)
        self.assertIn("onTriggered: root.finish()", launcher)
        self.assertIn("Qt.callLater(root.checkForWindow)", launcher)
        self.assertIn("indicatorWindow.targetRect", indicator)

    def test_taskbar_rebuild_does_not_allocate_unparented_qt_objects(self) -> None:
        taskbar = source("services/TaskbarApps.qml")

        self.assertIn("values.push({ appId: key, toplevels: value.toplevels, pinned: value.pinned })", taskbar)
        self.assertNotIn("appEntryComp.createObject(null", taskbar)
        self.assertNotIn("component TaskbarAppEntry", taskbar)
        self.assertIn("DesktopEntries.byId(appId)", taskbar)
        self.assertNotIn("DesktopEntries.heuristicLookup", taskbar)
        self.assertIn("function iconSourceFor(appId, fallbackIcon)", taskbar)
        self.assertIn('"kittiy-ar": "/home/professorx/.local/opt/kittiy-ar', taskbar)
        self.assertIn('"chatgpt": "/usr/share/pixmaps/chatgpt.png"', taskbar)

    def test_lock_preview_and_full_monitor_visualizer_keep_their_own_state(self) -> None:
        states = source("GlobalStates.qml")
        config = source("modules/common/Config.qml")
        background = source("modules/ii/background/Background.qml")
        full_visualizer = source("modules/ii/background/widgets/visualizer/FullMonitorVisualizerWidget.qml")
        settings = source("modules/ii/settings/pages/BackgroundConfig.qml")

        self.assertIn("lockPreviewInitialWidgetPositions", states)
        self.assertIn("lockPreviewInitialLayout", states)
        self.assertIn("function cancelLockPreview", states)
        self.assertIn("function resetLockWidgetLayout", states)
        self.assertIn("function applyLockLayout", states)
        self.assertIn("fullMonitorVisualizer", config)
        self.assertIn("FullMonitorVisualizerWidget", background)
        self.assertIn('configEntryName: "fullMonitorVisualizer"', full_visualizer)
        self.assertIn("Full monitor visualizer", settings)

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

        registry = source("modules/ii/settings/SettingsRegistry.qml")
        self.assertIn("settingLabels", registry)
        self.assertIn("registry.searchIndex", settings_content)
        self.assertNotIn("collectSearchData", settings_content)
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
        self.assertIn('GlobalStates.widgetShown("clock", bgRoot.lockPresentationActive)', background)
        self.assertIn("visibleWhenLocked: GlobalStates.widgetShown(configEntryName, true)", clock)
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
        self.assertIn("Live preview", interface)
        self.assertIn("visualizerMirror", interface)
        self.assertIn("setWidgetLockOnly", widget_settings)
        self.assertIn("WidgetsSubmenu", widget_settings)

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
        self.assertNotIn("function applyLockDesignToOutput", states)
        self.assertIn("byScreen", abstract_widget)
        self.assertIn("lockLayoutForOutput", lock)
        self.assertNotIn("Apply other screen", background)
        self.assertIn("WidgetsSubmenu", background)
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
        full = source("modules/ii/background/widgets/visualizer/FullMonitorVisualizerWidget.qml")
        service = source("services/DesktopVisualizer.qml")
        background = source("modules/ii/background/Background.qml")
        settings = source("modules/ii/settings/pages/BackgroundConfig.qml")

        self.assertIn("ascii_max_range = 1000", cava)
        self.assertIn("property real rawMaximum: 1000", bars)
        self.assertIn("property real attack", bars)
        self.assertIn("property real release", bars)
        self.assertIn("root.displayPoints = next", bars)
        self.assertIn("property bool simulate", bars)
        self.assertIn("simulationPhase", bars)
        self.assertIn("hasAudibleInput", bars)
        self.assertIn("final all-zero frame", bars)
        self.assertIn("property JsonObject visualizerMirror", config)
        self.assertIn('configEntryName: "visualizerMirror"', mirrored)
        self.assertIn("mirrored: true", mirrored)
        self.assertIn("FrequencyBars", normal)
        self.assertIn("simulate: DesktopVisualizer.editingPreviewActive", normal)
        self.assertIn("simulate: DesktopVisualizer.editingPreviewActive", mirrored)
        self.assertIn("mirroredEnabled", service)
        self.assertIn("editingPreviewActive", service)
        self.assertIn("property bool simulate", full)
        self.assertIn("hasAudibleInput", full)
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
