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
            a.glass.enable = true; a.glass.opacity = 0.72; a.transparency.enable = true
            break
        case "paper":
            a.palette.type = "scheme-content"; a.palette.accentColor = "#6750a4"
            a.glass.enable = false; a.transparency.enable = false
            break
        case "aurora":
            a.palette.type = "scheme-rainbow"; a.palette.accentColor = "#2dd4bf"
            a.glass.enable = true; a.glass.opacity = 0.82; a.transparency.enable = true
            break
        case "mono":
            a.palette.type = "scheme-monochrome"; a.palette.accentColor = ""
            a.glass.enable = false; a.transparency.enable = false
            break
        default:
            a.palette.type = "auto"; a.palette.accentColor = ""
            a.glass.enable = false
        }
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
        Layout.fillWidth: true
        Layout.fillHeight: true
        spacing: 20

        ContentSection {
            icon: "palette"
            shape: MaterialShape.Shape.Flower
            title: Translation.tr("Built-in themes")
            GroupedList {
                ConfigSelectionArray {
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
                ConfigRow {
                    uniform: true
                    ConfigSwitch {
                        buttonIcon: "water_drop"
                        text: Translation.tr("Liquid glass surfaces")
                        checked: Config.options.appearance.glass.enable
                        onCheckedChanged: Config.options.appearance.glass.enable = checked
                    }
                    ConfigSwitch {
                        buttonIcon: "animation"
                        text: Translation.tr("Expressive motion")
                        checked: Config.options.appearance.motion.style === "expressive"
                        onCheckedChanged: Config.options.appearance.motion.style = checked ? "expressive" : "smooth"
                    }
                }
                ConfigSpinBox {
                    icon: "opacity"
                    text: Translation.tr("Glass opacity (%)")
                    enabled: Config.options.appearance.glass.enable
                    value: Math.round(Config.options.appearance.glass.opacity * 100)
                    from: 35; to: 95; stepSize: 1
                    onValueChanged: Config.options.appearance.glass.opacity = value / 100
                }
            }
        }

        ContentSection {
            icon: "notifications_active"
            shape: MaterialShape.Shape.Bun
            title: Translation.tr("Notification experience")
            GroupedList {
                ConfigSelectionArray {
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
                    uniform: true
                    ConfigSwitch {
                        buttonIcon: "pause_circle"
                        text: Translation.tr("Pause timeout on hover")
                        checked: Config.options.notifications.pauseOnHover
                        onCheckedChanged: Config.options.notifications.pauseOnHover = checked
                    }
                    ConfigSwitch {
                        buttonIcon: "priority_high"
                        text: Translation.tr("Critical alerts in quiet mode")
                        checked: Config.options.notifications.showCriticalWhenQuiet
                        onCheckedChanged: Config.options.notifications.showCriticalWhenQuiet = checked
                    }
                }
                ConfigSwitch {
                    buttonIcon: "screen_share"
                    text: Translation.tr("Auto-silence popups while screen sharing")
                    checked: Config.options.notifications.autoSilentOnScreenShare
                    onCheckedChanged: Config.options.notifications.autoSilentOnScreenShare = checked
                }
                StyledText {
                    Layout.fillWidth: true
                    wrapMode: Text.Wrap
                    color: Appearance.colors.colSubtext
                    font.pixelSize: Appearance.font.pixelSize.small
                    text: Translation.tr("Only mutes toast popups for as long as something is actually capturing your screen - notifications still land in the list, and this never touches the quiet-mode switch itself, so it can't un-mute you the moment sharing ends if you muted it yourself. Critical alerts still break through, same as quiet mode above.")
                }
                ConfigSpinBox {
                    icon: "stack"
                    text: Translation.tr("Maximum visible cards")
                    value: Config.options.notifications.maxVisible
                    from: 1; to: 10; stepSize: 1
                    onValueChanged: Config.options.notifications.maxVisible = value
                }
                ConfigSwitch {
                    buttonIcon: "unfold_more"
                    text: Translation.tr("Expand notifications on hover")
                    checked: Config.options.notifications.expandOnHover
                    onCheckedChanged: Config.options.notifications.expandOnHover = checked
                }
                ConfigSlider {
                    buttonIcon: "timer"
                    text: Translation.tr("Hover expand delay (ms)")
                    enabled: Config.options.notifications.expandOnHover
                    value: Config.options.notifications.hoverExpandDelay
                    from: 0; to: 1000; stepSize: 20
                    usePercentTooltip: false
                    onValueChanged: Config.options.notifications.hoverExpandDelay = value
                }
                ConfigRow {
                    uniform: true
                    ConfigSwitch {
                        buttonIcon: "preview"
                        text: Translation.tr("Show preview on system-icons hover")
                        checked: Config.options.bar.systemIconsHover.enable
                        onCheckedChanged: Config.options.bar.systemIconsHover.enable = checked
                    }
                    ConfigSpinBox {
                        icon: "format_list_numbered"
                        text: Translation.tr("Recent items")
                        enabled: Config.options.bar.systemIconsHover.enable
                        value: Config.options.bar.systemIconsHover.recentLimit
                        from: 1; to: 8; stepSize: 1
                        onValueChanged: Config.options.bar.systemIconsHover.recentLimit = value
                    }
                }
                ConfigTextArea {
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
            visible: WM.compositor === "hyprland"
            title: Translation.tr("Windows & focus")
            GroupedList {
                ConfigSwitch {
                    buttonIcon: "border_color"
                    text: Translation.tr("Use generated theme colours for window borders")
                    checked: Config.options.hyprland.general.autoThemeBorders
                    onCheckedChanged: {
                        Config.options.hyprland.general.autoThemeBorders = checked
                        if (checked) page.applyThemeBorders()
                        else page.restoreConfiguredBorders()
                    }
                }
                ConfigRow {
                    uniform: true
                    ConfigSpinBox {
                        icon: "opacity"
                        text: Translation.tr("Focused window opacity (%)")
                        value: Math.round(Config.options.hyprland.decoration.activeOpacity * 100)
                        from: 10; to: 100; stepSize: 1
                        onValueChanged: {
                            const v = value / 100
                            Config.options.hyprland.decoration.activeOpacity = v
                            HyprlandConfig.set("decoration:active_opacity", v)
                        }
                    }
                    ConfigSpinBox {
                        icon: "filter_b_and_w"
                        text: Translation.tr("Unfocused opacity (%)")
                        value: Math.round(Config.options.hyprland.decoration.inactiveOpacity * 100)
                        from: 10; to: 100; stepSize: 1
                        onValueChanged: {
                            const v = value / 100
                            Config.options.hyprland.decoration.inactiveOpacity = v
                            HyprlandConfig.set("decoration:inactive_opacity", v)
                        }
                    }
                }
                ConfigSwitch {
                    buttonIcon: "contrast"
                    text: Translation.tr("Dim inactive windows")
                    checked: Config.options.hyprland.decoration.dimInactive
                    onCheckedChanged: {
                        Config.options.hyprland.decoration.dimInactive = checked
                        HyprlandConfig.set("decoration:dim_inactive", checked ? 1 : 0)
                    }
                }
            }
        }

        ContentSection {
            icon: "power_settings_new"
            shape: MaterialShape.Shape.Pentagon
            title: Translation.tr("Session screen")
            GroupedList {
                ConfigSelectionArray {
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
                    uniform: true
                    ConfigSelectionArray {
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
                        enabled: Config.options.sessionScreen.presentation === "edge"
                        icon: "width"
                        text: Translation.tr("Side sheet width")
                        value: Config.options.sessionScreen.edgeWidth
                        from: 330; to: 760; stepSize: 10
                        onValueChanged: Config.options.sessionScreen.edgeWidth = value
                    }
                }
                ConfigSelectionArray {
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
                    uniform: true
                    ConfigSwitch {
                        buttonIcon: "downloading"
                        text: Translation.tr("Show hibernate")
                        checked: Config.options.sessionScreen.showHibernate
                        onCheckedChanged: Config.options.sessionScreen.showHibernate = checked
                    }
                    ConfigSwitch {
                        buttonIcon: "browse_activity"
                        text: Translation.tr("Show task manager")
                        checked: Config.options.sessionScreen.showTaskManager
                        onCheckedChanged: Config.options.sessionScreen.showTaskManager = checked
                    }
                }
                ConfigRow {
                    uniform: true
                    ConfigSwitch {
                        buttonIcon: "settings_applications"
                        text: Translation.tr("Show firmware reboot")
                        checked: Config.options.sessionScreen.showFirmware
                        onCheckedChanged: Config.options.sessionScreen.showFirmware = checked
                    }
                    ConfigSwitch {
                        buttonIcon: "warning"
                        text: Translation.tr("Show safety warnings")
                        checked: Config.options.sessionScreen.showWarnings
                        onCheckedChanged: Config.options.sessionScreen.showWarnings = checked
                    }
                }
                ConfigSwitch {
                    buttonIcon: "verified_user"
                    text: Translation.tr("Confirm shutdown, reboot, and firmware actions")
                    checked: Config.options.sessionScreen.confirmDestructive
                    onCheckedChanged: Config.options.sessionScreen.confirmDestructive = checked
                }
            }
        }

        ContentSection {
            icon: "timer"
            shape: MaterialShape.Shape.Cookie6Sided
            title: Translation.tr("Pomodoro in the bar")
            GroupedList {
                StyledText {
                    Layout.fillWidth: true
                    wrapMode: Text.Wrap
                    color: Appearance.colors.colSubtext
                    text: Translation.tr("Add Pomodoro from Bar → Layout to place this control in any bar or island.")
                }
                ConfigRow {
                    uniform: true
                    ConfigSwitch {
                        buttonIcon: "label"
                        text: Translation.tr("Show focus / break label")
                        checked: Config.options.bar.pomodoro.showLabel
                        onCheckedChanged: Config.options.bar.pomodoro.showLabel = checked
                    }
                    ConfigSwitch {
                        buttonIcon: "timer"
                        text: Translation.tr("Show seconds")
                        checked: Config.options.bar.pomodoro.showSeconds
                        onCheckedChanged: Config.options.bar.pomodoro.showSeconds = checked
                    }
                }
                ConfigSelectionArray {
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
