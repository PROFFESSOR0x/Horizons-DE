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
    def test_clock_owns_volume_scrolling(self) -> None:
        clock = source("modules/ii/m3Island/M3ClockCenter.qml")
        island = source("modules/ii/m3Island/M3IslandContent.qml")

        self.assertIn("WheelHandler", clock)
        self.assertIn("scrollVolume", clock)
        self.assertNotIn("onWheel:", island)

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
        self.assertIn("Enable Liquid Glass", settings)

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
        settings = source("modules/ii/settings/pages/HyprlandConfig.qml")
        configurator = source("scripts/hyprland/hyprconfigurator.py")
        unsupported = (
            "decoration:blur:variant",
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


if __name__ == "__main__":
    unittest.main()
