import QtQuick
import QtQuick.Layouts
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets

// One home for preferences that affect how the desktop feels rather than a
// single widget. Keeping them together makes a new install approachable while
// retaining the detailed compositor page for people who want every knob.
ContentPage {
    id: page
    forceWidth: true

    function applyTheme(name) {
        Config.options.appearance.builtInTheme = name
        const a = Config.options.appearance
        switch (name) {
        case "midnight":
            a.palette.type = "scheme-expressive"; a.palette.accentColor = "#8ab4f8"
            a.visualEffect = "glass"; a.glass.opacity = 0.72
            break
        case "paper":
            a.palette.type = "scheme-content"; a.palette.accentColor = "#6750a4"
            a.visualEffect = "none"
            break
        case "aurora":
            a.palette.type = "scheme-rainbow"; a.palette.accentColor = "#2dd4bf"
            a.visualEffect = "glass"; a.glass.opacity = 0.82
            break
        case "mono":
            a.palette.type = "scheme-monochrome"; a.palette.accentColor = ""
            a.visualEffect = "none"
            break
        default:
            a.palette.type = "auto"; a.palette.accentColor = ""
            a.visualEffect = "none"
        }
        Config.applyVisualEffectExclusivity(a.visualEffect)
        if (WM.compositor === "hyprland") HyprlandConfig.setMany({
            "decoration:blur:enabled": Config.options.hyprland.decoration.blur.enabled ? 1 : 0,
            "decoration:blur:variant": Config.options.hyprland.decoration.blur.variant,
        })
    }

    function hyprColor(color) {
        const hex = color.toString().replace("#", "")
        return hex.length >= 6 ? "rgb(" + hex.substring(0, 6) + ")" : ""
    }

    function applyThemeBorders() {
        if (WM.compositor !== "hyprland") return
        const h = Config.options.hyprland.general
        h.colActiveBorder = hyprColor(Appearance.colors.colPrimary)
        h.colInactiveBorder = hyprColor(Appearance.colors.colOutlineVariant)
        // Batched: concurrent hyprconfigurator.py runs race on the same file.
        HyprlandConfig.setMany({
            "general:col.active_border": h.colActiveBorder,
            "general:col.inactive_border": h.colInactiveBorder,
        })
    }

    function restoreConfiguredBorders() {
        if (WM.compositor !== "hyprland") return
        // Generated colours are written as explicit shell overrides. Removing
        // those overrides is the only reliable way to return to the user's
        // normal Hyprland border settings when this toggle is switched off.
        const h = Config.options.hyprland.general
        h.colActiveBorder = ""
        h.colInactiveBorder = ""
        HyprlandConfig.resetMany([
            "general:col.active_border",
            "general:col.inactive_border"
        ])
    }

    ColumnLayout {
        visible: page.settingsShow("appearance|effects|notification-rules|notifications|panels|session|session-details");
        Layout.fillWidth: true
        Layout.fillHeight: true
        spacing: 20

        ContentSection {
            visible: page.settingsShow("appearance");
            icon: "palette"
            shape: MaterialShape.Shape.Flower
            title: Translation.tr("Built-in themes")
            GroupedList {
                compact: true;
                visible: page.settingsShow("appearance")
                ConfigSelectionArray {
                    visible: page.settingsShow("appearance");
                    objectName: "ExperienceConfig.theme-starting-point";
                    icon: "auto_awesome"
                    text: Translation.tr("Theme starting point")
                    currentValue: Config.options.appearance.builtInTheme
                    onSelected: newValue => page.applyTheme(newValue)
                    options: [
                        { displayName: Translation.tr("Adaptive"), icon: "wallpaper", value: "adaptive" },
                        { displayName: Translation.tr("Midnight glass"), icon: "nightlight", value: "midnight" },
                        { displayName: Translation.tr("Paper"), icon: "article", value: "paper" },
                        { displayName: Translation.tr("Aurora"), icon: "colors", value: "aurora" },
                        { displayName: Translation.tr("Monochrome"), icon: "contrast", value: "mono" }
                    ]
                }

            }
        }

        ContentSection {
            visible: page.settingsShow("notification-rules|notifications");
            icon: "notifications_active"
            shape: MaterialShape.Shape.Bun
            title: Translation.tr("Notification experience")
            GroupedList {
                compact: true;
                visible: page.settingsShow("notification-rules|notifications")
                ConfigSelectionArray {
                    visible: page.settingsShow("notifications");
                    objectName: "ExperienceConfig.display-mode";
                    icon: "view_carousel"
                    text: Translation.tr("Display mode")
                    currentValue: Config.options.notifications.displayMode
                    onSelected: newValue => Config.options.notifications.displayMode = newValue
                    options: [
                        { displayName: Translation.tr("Toasts"), icon: "notifications", value: "toast" },
                        { displayName: Translation.tr("Compact"), icon: "notification_important", value: "compact" },
                        { displayName: Translation.tr("History only"), icon: "history", value: "history" },
                        { displayName: Translation.tr("Island"), icon: "interests", value: "island" }
                    ]
                }
                ConfigSelectionArray {
                    visible: page.settingsShow("notifications");
                    objectName: "ExperienceConfig.card-style";
                    icon: "format_paint"
                    text: Translation.tr("Card style")
                    currentValue: Config.options.notifications.style
                    onSelected: newValue => Config.options.notifications.style = newValue
                    options: [
                        { displayName: Translation.tr("Material"), icon: "rounded_corner", value: "material" },
                        { displayName: Translation.tr("Glass"), icon: "water_drop", value: "glass" },
                        { displayName: Translation.tr("Minimal"), icon: "minimize", value: "minimal" }
                    ]
                }
                ConfigRow {
                    visible: page.settingsShow("notifications");
                    uniform: true
                    ConfigSwitch {
                        visible: page.settingsShow("notifications");
                        objectName: "ExperienceConfig.pause-timeout-on-hover";
                        buttonIcon: "pause_circle"
                        text: Translation.tr("Pause timeout on hover")
                        checked: Config.options.notifications.pauseOnHover
                        onEdited: Config.options.notifications.pauseOnHover = checked
                    }
                    ConfigSwitch {
                        visible: page.settingsShow("notifications");
                        objectName: "ExperienceConfig.critical-alerts-in-quiet-mode";
                        buttonIcon: "priority_high"
                        text: Translation.tr("Critical alerts in quiet mode")
                        checked: Config.options.notifications.showCriticalWhenQuiet
                        onEdited: Config.options.notifications.showCriticalWhenQuiet = checked
                    }
                }
                ConfigSwitch {
                    visible: page.settingsShow("notifications");
                    objectName: "ExperienceConfig.auto-silence-popups-while-screen-sharing";
                    buttonIcon: "screen_share"
                    text: Translation.tr("Auto-silence popups while screen sharing")
                    checked: Config.options.notifications.autoSilentOnScreenShare
                    onEdited: Config.options.notifications.autoSilentOnScreenShare = checked
                }
                StyledText {
                    property bool groupDescription: true;
                    visible: page.settingsShow("notifications");
                    Layout.fillWidth: true
                    wrapMode: Text.Wrap
                    color: Appearance.colors.colSubtext
                    font.pixelSize: Appearance.font.pixelSize.small
                    text: Translation.tr("Only mutes toast popups for as long as something is actually capturing your screen - notifications still land in the list, and this never touches the quiet-mode switch itself, so it can't un-mute you the moment sharing ends if you muted it yourself. Critical alerts still break through, same as quiet mode above.")
                }
                ConfigSpinBox {
                    visible: page.settingsShow("notification-rules");
                    objectName: "ExperienceConfig.maximum-visible-cards";
                    icon: "stack"
                    text: Translation.tr("Maximum visible cards")
                    value: Config.options.notifications.maxVisible
                    from: 1; to: 10; stepSize: 1
                    onEdited: Config.options.notifications.maxVisible = value
                }
                ConfigSwitch {
                    visible: page.settingsShow("notifications");
                    objectName: "ExperienceConfig.expand-notifications-on-hover";
                    buttonIcon: "unfold_more"
                    text: Translation.tr("Expand notifications on hover")
                    checked: Config.options.notifications.expandOnHover
                    onEdited: Config.options.notifications.expandOnHover = checked
                }
                ConfigSlider {
                    visible: page.settingsShow("notification-rules");
                    objectName: "ExperienceConfig.hover-expand-delay-ms";
                    buttonIcon: "timer"
                    text: Translation.tr("Hover expand delay (ms)")
                    enabled: Config.options.notifications.expandOnHover
                    value: Config.options.notifications.hoverExpandDelay
                    from: 0; to: 1000; stepSize: 20
                    usePercentTooltip: false
                    onEdited: Config.options.notifications.hoverExpandDelay = value
                }
                ConfigRow {
                    visible: page.settingsShow("notification-rules");
                    uniform: true
                    ConfigSwitch {
                        visible: page.settingsShow("notification-rules");
                        objectName: "ExperienceConfig.show-preview-on-system-icons-hover";
                        buttonIcon: "preview"
                        text: Translation.tr("Show preview on system-icons hover")
                        checked: Config.options.bar.systemIconsHover.enable
                        onEdited: Config.options.bar.systemIconsHover.enable = checked
                    }
                    ConfigSpinBox {
                        visible: page.settingsShow("notification-rules");
                        objectName: "ExperienceConfig.recent-items";
                        icon: "format_list_numbered"
                        text: Translation.tr("Recent items")
                        enabled: Config.options.bar.systemIconsHover.enable
                        value: Config.options.bar.systemIconsHover.recentLimit
                        from: 1; to: 8; stepSize: 1
                        onEdited: Config.options.bar.systemIconsHover.recentLimit = value
                    }
                }
                ConfigTextArea {
                    visible: page.settingsShow("notification-rules");
                    objectName: "ExperienceConfig.per-app-notification-rules-json";
                    id: notificationRules
                    Layout.fillWidth: true
                    fieldWidth: 360
                    fieldHeight: 90
                    buttonIcon: "rule_settings"
                    text: Translation.tr("Per-app notification rules (JSON)")
                    description: Translation.tr("Example: [{\"match\":\"discord\",\"mode\":\"history\",\"timeout\":12000}]. Modes: toast, history, silent.")
                    confirmButtonVisible: true
                    Component.onCompleted: value = JSON.stringify(Config.options.notifications.appRules, null, 2)
                    onConfirmClicked: {
                        try {
                            const parsed = JSON.parse(value)
                            if (Array.isArray(parsed)) Config.options.notifications.appRules = parsed
                        } catch (error) {
                            console.warn("[Experience] Invalid notification rules JSON", error)
                        }
                    }
                }
            }
        }

        ContentSection {
            icon: "select_window"
            shape: MaterialShape.Shape.ClamShell
            visible: page.settingsShow("effects") && (WM.compositor === "hyprland")
            title: Translation.tr("Windows & focus")
            GroupedList {
                compact: true;
                visible: page.settingsShow("effects")
                ConfigSwitch {
                    visible: page.settingsShow("effects");
                    objectName: "ExperienceConfig.use-generated-theme-colours-for-window-borders";
                    buttonIcon: "border_color"
                    text: Translation.tr("Use generated theme colours for window borders")
                    checked: Config.options.hyprland.general.autoThemeBorders
                    onEdited: {
                        Config.options.hyprland.general.autoThemeBorders = checked
                        if (checked) page.applyThemeBorders()
                        else page.restoreConfiguredBorders()
                    }
                }

            }
        }

        ContentSection {
            visible: page.settingsShow("session|session-details");
            icon: "power_settings_new"
            shape: MaterialShape.Shape.Pentagon
            title: Translation.tr("Session screen")
            GroupedList {
                compact: true;
                visible: page.settingsShow("session|session-details")
                ConfigSelectionArray {
                    visible: page.settingsShow("session");
                    objectName: "ExperienceConfig.presentation";
                    icon: "view_sidebar"
                    text: Translation.tr("Presentation")
                    currentValue: Config.options.sessionScreen.presentation
                    onSelected: newValue => Config.options.sessionScreen.presentation = newValue
                    options: [
                        { displayName: Translation.tr("Centered screen"), icon: "center_focus_strong", value: "center" },
                        { displayName: Translation.tr("Side sheet"), icon: "right_panel_open", value: "edge" }
                    ]
                }
                ConfigRow {
                    visible: page.settingsShow("session|session-details");
                    uniform: true
                    ConfigSelectionArray {
                        visible: page.settingsShow("session");
                        objectName: "ExperienceConfig.side";
                        enabled: Config.options.sessionScreen.presentation === "edge"
                        icon: "switch_left"
                        text: Translation.tr("Side")
                        currentValue: Config.options.sessionScreen.edge
                        onSelected: newValue => Config.options.sessionScreen.edge = newValue
                        options: [
                            { displayName: Translation.tr("Right"), icon: "right_panel_open", value: "right" },
                            { displayName: Translation.tr("Left"), icon: "left_panel_open", value: "left" }
                        ]
                    }
                    ConfigSpinBox {
                        visible: page.settingsShow("session-details");
                        objectName: "ExperienceConfig.side-sheet-width";
                        enabled: Config.options.sessionScreen.presentation === "edge"
                        icon: "width"
                        text: Translation.tr("Side sheet width")
                        value: Config.options.sessionScreen.edgeWidth
                        from: 330; to: 760; stepSize: 10
                        onEdited: Config.options.sessionScreen.edgeWidth = value
                    }
                }
                ConfigSelectionArray {
                    visible: page.settingsShow("session-details");
                    objectName: "ExperienceConfig.action-layout";
                    icon: "grid_view"
                    text: Translation.tr("Action layout")
                    currentValue: Config.options.sessionScreen.columns
                    onSelected: newValue => Config.options.sessionScreen.columns = newValue
                    options: [
                        { displayName: Translation.tr("Compact grid"), icon: "grid_view", value: 4 },
                        { displayName: Translation.tr("Comfortable"), icon: "view_module", value: 3 },
                        { displayName: Translation.tr("Large actions"), icon: "view_agenda", value: 2 }
                    ]
                }
                ConfigRow {
                    visible: page.settingsShow("session");
                    uniform: true
                    ConfigSwitch {
                        visible: page.settingsShow("session");
                        objectName: "ExperienceConfig.show-hibernate";
                        buttonIcon: "downloading"
                        text: Translation.tr("Show hibernate")
                        checked: Config.options.sessionScreen.showHibernate
                        onEdited: Config.options.sessionScreen.showHibernate = checked
                    }
                    ConfigSwitch {
                        visible: page.settingsShow("session");
                        objectName: "ExperienceConfig.show-task-manager";
                        buttonIcon: "browse_activity"
                        text: Translation.tr("Show task manager")
                        checked: Config.options.sessionScreen.showTaskManager
                        onEdited: Config.options.sessionScreen.showTaskManager = checked
                    }
                }
                ConfigRow {
                    visible: page.settingsShow("session");
                    uniform: true
                    ConfigSwitch {
                        visible: page.settingsShow("session");
                        objectName: "ExperienceConfig.show-firmware-reboot";
                        buttonIcon: "settings_applications"
                        text: Translation.tr("Show firmware reboot")
                        checked: Config.options.sessionScreen.showFirmware
                        onEdited: Config.options.sessionScreen.showFirmware = checked
                    }
                    ConfigSwitch {
                        visible: page.settingsShow("session");
                        objectName: "ExperienceConfig.show-safety-warnings";
                        buttonIcon: "warning"
                        text: Translation.tr("Show safety warnings")
                        checked: Config.options.sessionScreen.showWarnings
                        onEdited: Config.options.sessionScreen.showWarnings = checked
                    }
                }
                ConfigSwitch {
                    visible: page.settingsShow("session");
                    objectName: "ExperienceConfig.confirm-shutdown-reboot-and-firmware-actions";
                    buttonIcon: "verified_user"
                    text: Translation.tr("Confirm shutdown, reboot, and firmware actions")
                    checked: Config.options.sessionScreen.confirmDestructive
                    onEdited: Config.options.sessionScreen.confirmDestructive = checked
                }
            }
        }

        ContentSection {
            visible: page.settingsShow("panels");
            icon: "timer"
            shape: MaterialShape.Shape.Cookie6Sided
            title: Translation.tr("Pomodoro in the bar")
            GroupedList {
                compact: true;
                visible: page.settingsShow("panels")
                StyledText {
                    property bool groupDescription: true;
                    visible: page.settingsShow("panels");
                    Layout.fillWidth: true
                    wrapMode: Text.Wrap
                    color: Appearance.colors.colSubtext
                    text: Translation.tr("Add Pomodoro from Bar → Layout to place this control in any bar or island.")
                }
                ConfigRow {
                    visible: page.settingsShow("panels");
                    uniform: true
                    ConfigSwitch {
                        visible: page.settingsShow("panels");
                        objectName: "ExperienceConfig.show-focus-break-label";
                        buttonIcon: "label"
                        text: Translation.tr("Show focus / break label")
                        checked: Config.options.bar.pomodoro.showLabel
                        onEdited: Config.options.bar.pomodoro.showLabel = checked
                    }
                    ConfigSwitch {
                        visible: page.settingsShow("panels");
                        objectName: "ExperienceConfig.show-seconds";
                        buttonIcon: "timer"
                        text: Translation.tr("Show seconds")
                        checked: Config.options.bar.pomodoro.showSeconds
                        onEdited: Config.options.bar.pomodoro.showSeconds = checked
                    }
                }
                ConfigSelectionArray {
                    visible: page.settingsShow("panels");
                    objectName: "ExperienceConfig.click-action";
                    icon: "ads_click"
                    text: Translation.tr("Click action")
                    currentValue: Config.options.bar.pomodoro.clickAction
                    onSelected: newValue => Config.options.bar.pomodoro.clickAction = newValue
                    options: [
                        { displayName: Translation.tr("Start / pause"), icon: "play_arrow", value: "toggle" },
                        { displayName: Translation.tr("Reset"), icon: "restart_alt", value: "reset" },
                        { displayName: Translation.tr("Open sidebar"), icon: "right_panel_open", value: "sidebar" }
                    ]
                }
            }
        }
    }
}
