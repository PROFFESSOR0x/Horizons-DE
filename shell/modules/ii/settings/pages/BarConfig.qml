import QtQuick
import QtQuick.Layouts
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import Quickshell.Hyprland

ContentPage {
    id: page
    forceWidth: true

    function goTo(term) {
        const t = term.toLowerCase().trim()

        function findTarget(rootItem) {
            for (let i = 0; i < rootItem.children.length; i++) {
                let child = rootItem.children[i]
                if (child.title && child.title.toLowerCase().includes(t)) {
                    return child
                }
            }
            for (let i = 0; i < rootItem.children.length; i++) {
                let found = findTarget(rootItem.children[i])
                if (found) return found
            }
            return null
        }

        let target = findTarget(mainLayout)
        if (target) {
            let pos = target.mapToItem(mainLayout, 0, 0)
            page.contentY = Math.max(0, pos.y - 0)
        }
    }

    readonly property string barMode: Config.options.bar.barMode

    property var allWidgets: [
        { id: "leftSidebarButton", name: Translation.tr("Left Sidebar Button"),  icon: "left_panel_open" },
        { id: "workspaces",        name: Translation.tr("Workspaces"),           icon: "steppers" },
        { id: "weatherBar",        name: Translation.tr("Weather"),              icon: "flare" },
        { id: "media",             name: Translation.tr("Media"),                icon: "music_note" },
        { id: "resources",         name: Translation.tr("Resources"),            icon: "empty_dashboard" },
        { id: "systemIcons",       name: Translation.tr("System Icons"),         icon: "info" },
        { id: "networkSpeed",      name: Translation.tr("Network Speed"),        icon: "network_check" },
        { id: "vpnIndicator",      name: Translation.tr("VPN Indicator"),        icon: "vpn_lock" },
        { id: "clockWidget",       name: Translation.tr("Clock"),                icon: "schedule" },
        { id: "utilButtons",       name: Translation.tr("Util Buttons"),         icon: "toggle_on" },
        { id: "sysTray",           name: Translation.tr("Tray"),                 icon: "inbox" },
        { id: "batteryIndicator",  name: Translation.tr("Battery"),              icon: "battery_android_frame_full" },
        { id: "bluetooth",         name: Translation.tr("Bluetooth"),            icon: "bluetooth" },
        { id: "activeWindow",      name: Translation.tr("Active Window"),        icon: "subtitles" },
        { id: "powerButton",       name: Translation.tr("Power Button"),         icon: "power_settings_new" },
        { id: "updatesCount",      name: Translation.tr("Updates"),              icon: "deployed_code_update" },
        { id: "docktoPanel",       name: Translation.tr("Dock to Panel"),        icon: "apps" },
        { id: "visualizer",        name: Translation.tr("Visualizer"),           icon: "graphic_eq" },
        { id: "pomodoroBar",       name: Translation.tr("Pomodoro"),             icon: "timer" },
        { id: "hyprlandXkbIndicator", name: Translation.tr("Keyboard Layout"),  icon: "keyboard" },
        { id: "divisor",           name: Translation.tr("Divider"),              icon: "horizontal_distribute" },
        { id: "launcherButton",    name: Translation.tr("Launcher Button"),      icon: "search" },
        { id: "idleInhibitor",     name: Translation.tr("Idle Inhibitor"),       icon: "coffee" },
        { id: "uptime",            name: Translation.tr("Uptime"),               icon: "avg_pace" },
        { id: "privacyIndicator",  name: Translation.tr("Privacy Indicator"),    icon: "shield_lock" },
    ]

    // Classic bar and Mesobar are mutually-exclusive surfaces (only one is
    // ever loaded, per barMode - see IllogicalImpulseFamily.qml), but each
    // keeps its own independent layouts.* config even while inactive. The
    // "available to add" list for one must therefore only be filtered
    // against that same surface's own layouts - never the other, otherwise
    // a widget that happens to sit in the *other*, currently-untouched
    // surface's (default) layout can never be offered here, and removing it
    // from this surface's layout alone won't bring it back since it's still
    // "used" by the other one. (This previously unioned both surfaces'
    // layouts together, which is why "workspaces" - present in both bar's
    // and mesoBar's default leftLayout - could vanish from the picker
    // entirely after being removed from just one of them; the same applied
    // to every other widget shared between the two default layouts, e.g.
    // clockWidget, systemIcons, powerButton, sysTray, launcherButton and
    // activeWindow.)
    function availableForBar() {
        let used = [
            ...Config.options.bar.layouts.leftLayout,
            ...Config.options.bar.layouts.middleLayout,
            ...Config.options.bar.layouts.rightLayout
        ]
        const multipleAllowed = ["visualizer", "divisor"]
        return allWidgets.filter(w => {
            if (w.id === "divisor" && Config.options.bar.borderless !== "transparent") return false
            return !used.includes(w.id) || multipleAllowed.includes(w.id)
        })
    }

    function availableForMesoBar() {
        let used = [
            ...Config.options.mesoBar.layouts.leftLayout,
            ...Config.options.mesoBar.layouts.middleLayout,
            ...Config.options.mesoBar.layouts.rightLayout
        ]
        const multipleAllowed = ["visualizer", "divisor"]
        return allWidgets.filter(w => {
            if (w.id === "divisor" && Config.options.mesoBar.borderless !== "transparent") return false
            return !used.includes(w.id) || multipleAllowed.includes(w.id)
        })
    }

    // Island-only widgets - built specifically for the m3Island pill format,
    // not resolvable through the shared bar/ widget pool, so kept out of
    // allWidgets to avoid offering them on the classic/mesoBar pickers.
    property var m3OnlyWidgets: [
        { id: "m3Clock",       name: Translation.tr("Clock"),                    icon: "schedule" },
        { id: "m3MiniStats",   name: Translation.tr("Mini Stats (CPU/RAM)"),    icon: "monitoring" },
        { id: "m3NotifStatus", name: Translation.tr("Notification Status"),     icon: "notifications" },
    ]

    function getWidgetName(id) {
        const w = allWidgets.find(w => w.id === id) || m3OnlyWidgets.find(w => w.id === id)
        return w ? w.name : id
    }

    // Only toggle types that actually have real backing in
    // QuickActionsBarContent.qml's QuickToggle component are selectable here.
    property var allToggleTypes: [
        { id: "wifi",       name: Translation.tr("Wi-Fi"),        icon: "wifi" },
        { id: "bluetooth",  name: Translation.tr("Bluetooth"),    icon: "bluetooth" },
        { id: "nightLight", name: Translation.tr("Night Light"),  icon: "bedtime" },
        { id: "darkMode",   name: Translation.tr("Dark Mode"),    icon: "dark_mode" },
        { id: "mic",        name: Translation.tr("Microphone"),   icon: "mic" },
        { id: "dnd",        name: Translation.tr("Do Not Disturb"), icon: "do_not_disturb_on" },
        { id: "airplane",   name: Translation.tr("Airplane Mode"), icon: "flight" },
        { id: "rotation",   name: Translation.tr("Screen Rotation"), icon: "screen_rotation_alt" },
        { id: "location",   name: Translation.tr("Location Services"), icon: "location_on" },
        { id: "nfc",        name: Translation.tr("NFC"),          icon: "nfc" },
        { id: "hotspot",    name: Translation.tr("Wi-Fi Hotspot"), icon: "wifi_tethering" },
    ]

    function getToggleTypeName(id) {
        const t = allToggleTypes.find(t => t.id === id)
        return t ? t.name : id
    }

    function availableToggleTypes() {
        let used = Config.options.quickActionsBar.toggles.map(t => t.type)
        return allToggleTypes.filter(t => !used.includes(t.id))
    }

    function pinnedAppName(id) {
        const app = AppSearch.list.find(a => a.id === id)
        return app ? app.name : id
    }

    function availablePinnableApps() {
        let used = Config.options.tasklistBar.pinnedApps
        return AppSearch.list
            .filter(a => !used.includes(a.id))
            .map(a => ({ id: a.id, name: a.name, icon: "apps" }))
    }

    function availableForM3(currentLayout) {
        let used = [
            ...Config.options.m3Island.layouts.restingLayout,
            ...Config.options.m3Island.layouts.hoverLayout,
            ...Config.options.m3Island.layouts.expandedLayout
        ]
        const localLayout = currentLayout ?? []
        // The clock must be selectable in Hover/Expanded even if it is already
        // used by Resting. M3IslandContent replaces those rows' fallback clock
        // when one is explicitly added. It is deliberately allowed only once
        // *per row*, so repeated clicks cannot create two visible clocks in a
        // single island state.
        const multipleAllowed = ["visualizer", "divisor"]
        return [...m3OnlyWidgets, ...allWidgets].filter(w => {
            if (w.id === "divisor" && Config.options.m3Island.borderless !== "transparent") return false
            if (w.id === "m3Clock") return !localLayout.includes(w.id)
            return !used.includes(w.id) || multipleAllowed.includes(w.id)
        })
    }

    ColumnLayout {
        visible: page.settingsShow("integrations|notification-rules|notifications|panel-details|panels");
        id: mainLayout
        Layout.fillWidth: true
        Layout.fillHeight: true
        spacing: 20

        // ── 1. Bar Mode ───────────────────────────────────────────────────────
        ContentSection {
            visible: page.settingsShow("panels");
            icon: "dashboard_customize"
            shape: MaterialShape.Shape.Gem
            title: Translation.tr("Bar Mode")

            GroupedList {
                compact: true;
                visible: page.settingsShow("panels")
                ConfigSelectionArray {
                    visible: page.settingsShow("panels");
                    objectName: "BarConfig.active-bar";
                    text: Translation.tr("Active bar")
                    icon: "view_quilt"
                    currentValue: Config.options.bar.barMode
                    onSelected: newValue => { Config.options.bar.barMode = newValue }
                    options: [
                        { displayName: Translation.tr("Classic"),      icon: "horizontal_rule",    value: "classic" },
                        { displayName: Translation.tr("Mesobar (formerly Top Island)"), icon: "dock", value: "mesoBar" },
                        { displayName: Translation.tr("M3 Island"),    icon: "interests",          value: "m3Island" },
                        { displayName: Translation.tr("Tasklist"),     icon: "list",               value: "tasklistBar" },
                        { displayName: Translation.tr("Sys Monitor"),  icon: "monitoring",         value: "sysmonitorBar" },
                        { displayName: Translation.tr("Quick Actions"),icon: "tune",               value: "quickActionsBar" },
                        { displayName: Translation.tr("Info Strip"),   icon: "remove",             value: "infoStrip" },
                    ]
                }
            }
        }

        // ── 2. Screens ────────────────────────────────────────────────────────
        ContentSection {
            icon: "monitor"
            shape: MaterialShape.Shape.ClamShell
            visible: page.settingsShow("panels") && (Hyprland.monitors.values.length > 1)
            title: Translation.tr("Screens")
            ContentSubsection {
                visible: page.settingsShow("panels");
                title: Translation.tr("Show bar on")

                ColumnLayout {
                    visible: page.settingsShow("panels");
                    id: monitorsCol
                    Layout.fillWidth: true
                    spacing: 2

                    Rectangle {
                        visible: page.settingsShow("panels");
                        id: allRow
                        Layout.fillWidth: true
                        implicitHeight: allSwitchItem.implicitHeight + 16 + 8
                        color: Appearance.colors.colLayer1
                        topLeftRadius: Appearance.rounding.normal
                        topRightRadius: Appearance.rounding.normal
                        bottomLeftRadius: Appearance.rounding.unsharpenmore
                        bottomRightRadius: Appearance.rounding.unsharpenmore

                        ConfigSwitch {
                            visible: page.settingsShow("panels");
                            objectName: "BarConfig.all";
                            id: allSwitchItem
                            anchors { fill: parent; margins: 8 }
                            buttonIcon: "tv_displays"
                            text: Translation.tr("All")
                            onEdited: {
                                if (checked) Config.options.bar.screenList = []
                            }
                            Binding {
                                target: allSwitchItem
                                property: "checked"
                                value: Config.options.bar.screenList.length === 0
                                restoreMode: Binding.RestoreBinding
                            }
                        }
                    }

                    Repeater {
                        model: Hyprland.monitors
                        delegate: Rectangle {
                                      visible: page.settingsShow("panels");
                            id: monitorRow
                            required property var modelData
                            required property int index
                            readonly property bool isLast: index === Hyprland.monitors.values.length - 1

                            Layout.fillWidth: true
                            implicitHeight: switchItem.implicitHeight + 16 + 8
                            color: Appearance.colors.colLayer1
                            topLeftRadius:     Appearance.rounding.unsharpenmore
                            topRightRadius:    Appearance.rounding.unsharpenmore
                            bottomLeftRadius:  isLast ? Appearance.rounding.normal : Appearance.rounding.unsharpenmore
                            bottomRightRadius: isLast ? Appearance.rounding.normal : Appearance.rounding.unsharpenmore

                            ConfigSwitch {
                                visible: page.settingsShow("panels");
                                objectName: "BarConfig.show-bar-on";
                                id: switchItem
                                anchors { fill: parent; margins: 8 }
                                buttonIcon: "monitor"
                                text: monitorRow.modelData.name
                                onEdited: {
                                    const allNames = Hyprland.monitors.values.map(m => m.name)
                                    let list = Config.options.bar.screenList.length === 0 ? allNames.slice() : Config.options.bar.screenList.slice()
                                    if (checked) {
                                        if (!list.includes(monitorRow.modelData.name)) list.push(monitorRow.modelData.name)
                                    } else {
                                        list = list.filter(s => s !== monitorRow.modelData.name)
                                    }
                                    Config.options.bar.screenList = list.length === allNames.length ? [] : list
                                }
                                Binding {
                                    target: switchItem
                                    property: "checked"
                                    value: Config.options.bar.screenList.length === 0 || Config.options.bar.screenList.includes(monitorRow.modelData.name)
                                    restoreMode: Binding.RestoreBinding
                                }
                            }
                        }
                    }
                }
            }
        }

        // ── 3. Classic Bar Layout (classic mode only) ─────────────────────────
        ContentSection {
            icon: "splitscreen_add"
            shape: MaterialShape.Shape.Cookie6Sided
            visible: page.barMode === "classic"
            title: Translation.tr("Bar Layout")

            GroupedList {
                compact: true;
                LayoutSection {
                    sectionTitle: Config.options.bar.vertical ? Translation.tr("Top") : Translation.tr("Left")
                    layout: Config.options.bar.layouts.leftLayout
                    availableWidgets: page.availableForBar()
                    getWidgetName: page.getWidgetName
                    onUpdate: list => Config.options.bar.layouts.leftLayout = list
                }
                LayoutSection {
                    sectionTitle: Translation.tr("Center")
                    layout: Config.options.bar.layouts.middleLayout
                    availableWidgets: page.availableForBar()
                    getWidgetName: page.getWidgetName
                    onUpdate: list => Config.options.bar.layouts.middleLayout = list
                }
                LayoutSection {
                    sectionTitle: Config.options.bar.vertical ? Translation.tr("Bottom") : Translation.tr("Right")
                    layout: Config.options.bar.layouts.rightLayout
                    availableWidgets: page.availableForBar()
                    getWidgetName: page.getWidgetName
                    onUpdate: list => Config.options.bar.layouts.rightLayout = list
                }
            }
        }

        // ── 4. Mesobar Layout (mesoBar mode only) ─────────────────────────────
        ContentSection {
            icon: "dock"
            shape: MaterialShape.Shape.Cookie6Sided
            visible: page.barMode === "mesoBar"
            title: Translation.tr("Mesobar Layout")

            GroupedList {
                compact: true;
                LayoutSection {
                    sectionTitle: Translation.tr("Left")
                    layout: Config.options.mesoBar.layouts.leftLayout
                    availableWidgets: page.availableForMesoBar()
                    getWidgetName: page.getWidgetName
                    onUpdate: list => Config.options.mesoBar.layouts.leftLayout = list
                }
                LayoutSection {
                    sectionTitle: Translation.tr("Center")
                    layout: Config.options.mesoBar.layouts.middleLayout
                    availableWidgets: page.availableForMesoBar()
                    getWidgetName: page.getWidgetName
                    onUpdate: list => Config.options.mesoBar.layouts.middleLayout = list
                }
                LayoutSection {
                    sectionTitle: Translation.tr("Right")
                    layout: Config.options.mesoBar.layouts.rightLayout
                    availableWidgets: page.availableForMesoBar()
                    getWidgetName: page.getWidgetName
                    onUpdate: list => Config.options.mesoBar.layouts.rightLayout = list
                }
            }
        }

        // ── 4b. M3 Island Layout (m3Island mode only) ─────────────────────────
        ContentSection {
            icon: "interests"
            shape: MaterialShape.Shape.Cookie6Sided
            visible: page.barMode === "m3Island"
            title: Translation.tr("Island layout")

            GroupedList {
                compact: true;
                LayoutSection {
                    sectionTitle: Translation.tr("Resting (idle pill)")
                    layout: Config.options.m3Island.layouts.restingLayout
                    availableWidgets: page.availableForM3(Config.options.m3Island.layouts.restingLayout)
                    getWidgetName: page.getWidgetName
                    onUpdate: list => Config.options.m3Island.layouts.restingLayout = list
                }
                StyledText {
                    property bool groupDescription: true;
                    Layout.fillWidth: true
                    wrapMode: Text.Wrap
                    color: Appearance.colors.colSubtext
                    font.pixelSize: Appearance.font.pixelSize.small
                    text: Translation.tr("\"Clock\" is a normal widget in this list now, not a fixture - put it anywhere, add widgets on either side of it, or remove it and use something else entirely (e.g. Workspaces) as the idle pill.")
                }
                LayoutSection {
                    sectionTitle: Translation.tr("Hover (peek)")
                    layout: Config.options.m3Island.layouts.hoverLayout
                    availableWidgets: page.availableForM3(Config.options.m3Island.layouts.hoverLayout)
                    getWidgetName: page.getWidgetName
                    onUpdate: list => Config.options.m3Island.layouts.hoverLayout = list
                }
                LayoutSection {
                    sectionTitle: Translation.tr("Expanded")
                    layout: Config.options.m3Island.layouts.expandedLayout
                    availableWidgets: page.availableForM3(Config.options.m3Island.layouts.expandedLayout)
                    getWidgetName: page.getWidgetName
                    onUpdate: list => Config.options.m3Island.layouts.expandedLayout = list
                }
            }
        }

        // ── 4c. M3 Island Options ──────────────────────────────────────────
        ContentSection {
            icon: "tune"
            shape: MaterialShape.Shape.SoftBurst
            visible: page.settingsShow("notification-rules|panel-details|panels") && (page.barMode === "m3Island")
            title: Translation.tr("Island behavior")

            GroupedList {
                compact: true;
                visible: page.settingsShow("notification-rules|panel-details|panels")
                ConfigSelectionArray {
                    visible: page.settingsShow("panels");
                    objectName: "BarConfig.clock-style";
                    text: Translation.tr("Clock style")
                    icon: "schedule"
                    currentValue: Config.options.m3Island.clockStyle
                    onSelected: newValue => { Config.options.m3Island.clockStyle = newValue }
                    options: [
                        { displayName: Translation.tr("M3 Pill"), icon: "pill", value: "m3" },
                        { displayName: Translation.tr("Minimal"), icon: "remove", value: "minimal" },
                        { displayName: Translation.tr("Digital"), icon: "timer", value: "digital" },
                    ]
                }
                ConfigRow {
                    visible: page.settingsShow("panels");
                    uniform: true
                    ConfigSwitch {
                        visible: page.settingsShow("panels");
                        objectName: "BarConfig.show-date";
                        buttonIcon: "calendar_today"
                        text: Translation.tr("Show date")
                        checked: Config.options.m3Island.clockShowDate
                        onEdited: { Config.options.m3Island.clockShowDate = checked }
                    }
                    ConfigSwitch {
                        visible: page.settingsShow("panels");
                        objectName: "BarConfig.hover-peek";
                        buttonIcon: "timelapse"
                        text: Translation.tr("Hover peek")
                        checked: Config.options.m3Island.hoverPeek
                        onEdited: { Config.options.m3Island.hoverPeek = checked }
                    }
                }
                ConfigRow {
                    visible: page.settingsShow("panels");
                    uniform: true
                    ConfigSwitch {
                        visible: page.settingsShow("panels");
                        objectName: "BarConfig.show-seconds";
                        buttonIcon: "timer"
                        text: Translation.tr("Show seconds")
                        checked: Config.options.m3Island.clockShowSeconds
                        onEdited: { Config.options.m3Island.clockShowSeconds = checked }
                    }
                    ConfigSwitch {
                        visible: page.settingsShow("panels");
                        objectName: "BarConfig.use-24-hour-clock";
                        buttonIcon: "schedule"
                        text: Translation.tr("Use 24-hour clock")
                        checked: Config.options.m3Island.clockUse24h
                        onEdited: { Config.options.m3Island.clockUse24h = checked }
                    }
                }
                ConfigRow {
                    visible: page.settingsShow("panel-details|panels");
                    uniform: true
                    ConfigSwitch {
                        visible: page.settingsShow("panel-details");
                        objectName: "BarConfig.reserve-screen-space";
                        buttonIcon: "vertical_align_center"
                        text: Translation.tr("Reserve screen space")
                        checked: Config.options.m3Island.reserveScreenSpace ?? false
                        onEdited: {
                            if (!Config.ready || checked === (Config.options.m3Island.reserveScreenSpace ?? false)) return
                            Config.setNestedValue("m3Island.reserveScreenSpace", checked)
                        }
                    }
                    ConfigSwitch {
                        visible: page.settingsShow("panels");
                        objectName: "BarConfig.click-to-expand";
                        buttonIcon: "open_in_full"
                        text: Translation.tr("Click to expand")
                        checked: Config.options.m3Island.clickToExpand
                        onEdited: { Config.options.m3Island.clickToExpand = checked }
                    }
                    ConfigSwitch {
                        visible: page.settingsShow("panel-details");
                        objectName: "BarConfig.launcher-hug";
                        buttonIcon: "search"
                        text: Translation.tr("Launcher hug")
                        checked: Config.options.m3Island.launcherHug
                        onEdited: { Config.options.m3Island.launcherHug = checked }
                    }
                    ConfigSwitch {
                        visible: page.settingsShow("panel-details");
                        objectName: "BarConfig.show-expanded-details";
                        buttonIcon: "more_horiz"
                        text: Translation.tr("Show expanded details")
                        checked: Config.options.m3Island.verbose
                        onEdited: { Config.options.m3Island.verbose = checked }
                    }
                }
                ConfigSpinBox {
                    visible: page.settingsShow("panel-details");
                    objectName: "BarConfig.launcher-maximum-visible-results";
                    icon: "format_list_numbered"
                    text: Translation.tr("Launcher maximum visible results")
                    value: Config.options.m3Island.launcherMaxResults
                    from: 1; to: 10; stepSize: 1
                    onEdited: { Config.options.m3Island.launcherMaxResults = value }
                }
                ConfigSelectionArray {
                    visible: page.settingsShow("panels");
                    objectName: "BarConfig.scroll-over-island";
                    text: Translation.tr("Scroll over island")
                    icon: "mouse"
                    currentValue: Config.options.m3Island.scrollAction
                    onSelected: newValue => { Config.options.m3Island.scrollAction = newValue }
                    options: [
                        { displayName: Translation.tr("Volume"),      icon: "volume_up",  value: "volume" },
                        { displayName: Translation.tr("Media seek"),  icon: "skip_next",  value: "mediaSeek" },
                        { displayName: Translation.tr("Expand/collapse"), icon: "unfold_more", value: "layoutCycle" },
                        { displayName: Translation.tr("Off"),         icon: "block",      value: "none" },
                    ]
                }
                ConfigSpinBox {
                    visible: page.settingsShow("panel-details");
                    objectName: "BarConfig.expanded-height";
                    icon: "height"
                    text: Translation.tr("Expanded height")
                    value: Config.options.m3Island.expandedHeight
                    from: 48; to: 160; stepSize: 4
                    onEdited: { Config.options.m3Island.expandedHeight = value }
                }
                ConfigSelectionArray {
                    visible: page.settingsShow("panel-details");
                    objectName: "BarConfig.animation-speed";
                    text: Translation.tr("Animation speed")
                    icon: "speed"
                    currentValue: Config.options.m3Island.animationSpeed
                    onSelected: newValue => { Config.options.m3Island.animationSpeed = newValue }
                    options: [
                        { displayName: Translation.tr("Fast"),   icon: "fast_forward", value: "fast" },
                        { displayName: Translation.tr("Normal"), icon: "speed",        value: "normal" },
                        { displayName: Translation.tr("Slow"),   icon: "slow_motion_video", value: "slow" },
                    ]
                }
                ConfigSpinBox {
                    objectName: "BarConfig.hug-corner-size";
                    icon: "line_curve"
                    text: Translation.tr("Hug corner size")
                    visible: page.settingsShow("panel-details") && (Config.options.m3Island.cornerStyle === 0)
                    value: Config.options.m3Island.hugCornerSize
                    from: 0; to: 48; stepSize: 2
                    onEdited: { Config.options.m3Island.hugCornerSize = value }
                }
                ConfigSelectionArray {
                    visible: page.settingsShow("panel-details");
                    objectName: "BarConfig.corner-style";
                    text: Translation.tr("Corner style")
                    icon: "style"
                    currentValue: Config.options.m3Island.cornerStyle
                    onSelected: newValue => { Config.options.m3Island.cornerStyle = newValue }
                    options: [
                        { displayName: Translation.tr("Hug"),   icon: "line_curve", value: 0 },
                        { displayName: Translation.tr("Float"), icon: "view_day",   value: 1 },
                    ]
                }
                ConfigSpinBox {
                    visible: page.settingsShow("notification-rules");
                    objectName: "BarConfig.notification-display-time-ms-0-global";
                    icon: "timer"
                    text: Translation.tr("Notification display time (ms, 0 = global)")
                    value: Config.options.m3Island.notificationTimeout
                    from: 0; to: 30000; stepSize: 500
                    onEdited: { Config.options.m3Island.notificationTimeout = value }
                }
                ConfigRow {
                    visible: page.settingsShow("panels");
                    uniform: true
                    ConfigSwitch {
                        visible: page.settingsShow("panels");
                        objectName: "BarConfig.show-background";
                        buttonIcon: "panorama_wide_angle"
                        text: Translation.tr("Show Background")
                        checked: Config.options.m3Island.showBackground
                        onEdited: { Config.options.m3Island.showBackground = checked }
                    }
                    ConfigSwitch {
                        visible: page.settingsShow("panels");
                        objectName: "BarConfig.show-frame";
                        buttonIcon: "border_all"
                        text: Translation.tr("Show Frame")
                        checked: Config.options.m3Island.showFrame
                        onEdited: { Config.options.m3Island.showFrame = checked }
                    }
                }
                ConfigSwitch {
                    visible: page.settingsShow("panels");
                    objectName: "BarConfig.blend-the-wallpaper-into-the-island";
                    buttonIcon: "wallpaper"
                    enabled: Config.options.m3Island.showBackground
                    text: Translation.tr("Blend the wallpaper into the island")
                    checked: Config.options.m3Island.wallpaperBackground.enable
                    onEdited: { Config.options.m3Island.wallpaperBackground.enable = checked }
                }
                ConfigSlider {
                    objectName: "BarConfig.wallpaper-strength";
                    visible: page.settingsShow("panel-details") && (Config.options.m3Island.wallpaperBackground.enable)
                    text: Translation.tr("Wallpaper strength")
                    textWidth: 130
                    buttonIcon: "opacity"
                    value: Config.options.m3Island.wallpaperBackground.opacity * 100
                    from: 0; to: 100
                    onEdited: { Config.options.m3Island.wallpaperBackground.opacity = value / 100 }
                }
                ConfigSlider {
                    objectName: "BarConfig.readability-scrim";
                    visible: page.settingsShow("panel-details") && (Config.options.m3Island.wallpaperBackground.enable)
                    text: Translation.tr("Readability scrim")
                    textWidth: 130
                    buttonIcon: "contrast"
                    value: Config.options.m3Island.wallpaperBackground.scrim * 100
                    from: 0; to: 100
                    onEdited: { Config.options.m3Island.wallpaperBackground.scrim = value / 100 }
                }
                StyledText {
                    property bool groupDescription: true;
                    visible: Config.options.m3Island.wallpaperBackground.enable
                    Layout.fillWidth: true
                    wrapMode: Text.Wrap
                    color: Appearance.colors.colSubtext
                    font.pixelSize: Appearance.font.pixelSize.small
                    text: Translation.tr("The island shows the exact piece of wallpaper it is sitting on, lined up with the desktop behind it, so it reads as carved out of the wallpaper instead of floating on top of it. The scrim lays the island's normal colour back over that image - drop it to 0 for a pure window onto the wallpaper, raise it if the pill's text gets lost over a busy one.")
                }
                ConfigSwitch {
                    visible: page.settingsShow("panel-details");
                    objectName: "BarConfig.use-frame-color-as-background";
                    buttonIcon: "colors"
                    enabled: Config.options.m3Island.showFrame
                    text: Translation.tr("Use Frame Color as Background")
                    checked: Config.options.m3Island.followFrameColor
                    onEdited: { Config.options.m3Island.followFrameColor = checked }
                }
                ConfigSpinBox {
                    visible: page.settingsShow("panel-details");
                    objectName: "BarConfig.frame-thickness";
                    icon: "eraser_size_1"
                    text: Translation.tr("Frame thickness")
                    enabled: Config.options.m3Island.showFrame
                    value: Config.options.m3Island.frameThickness
                    from: 1; to: 10; stepSize: 1
                    onEdited: { Config.options.m3Island.frameThickness = value }
                }
                ColorSelectionArray {
                    visible: page.settingsShow("panel-details");
                    objectName: "BarConfig.frame-color";
                    icon: "imagesearch_roller"
                    text: Translation.tr("Frame Color")
                    options: ["primaryContainer", "secondaryContainer", "tertiaryContainer", "layer0", "black"]
                    currentValue: Config.options.m3Island.frameColor
                    onSelected: newValue => { Config.options.m3Island.frameColor = newValue }
                }
            }
        }

        // ── 5. Positioning & Shared Styles (all modes) ────────────────────────
        ContentSection {
            visible: page.settingsShow("panel-details|panels");
            icon: "pivot_table_chart"
            shape: MaterialShape.Shape.Gem
            title: Translation.tr("Positioning & Style")

            GroupedList {
                compact: true;
                visible: page.settingsShow("panel-details|panels")
                // Position — classic uses all 4 directions; others top/bottom only
                ConfigSelectionArray {
                    objectName: "BarConfig.bar-position";
                    text: Translation.tr("Bar position")
                    icon: "swap_vert"
                    visible: page.settingsShow("panels") && (page.barMode === "classic")
                    currentValue: (Config.options.bar.bottom ? 1 : 0) | (Config.options.bar.vertical ? 2 : 0)
                    onSelected: newValue => {
                        Config.options.bar.bottom   = (newValue & 1) !== 0
                        Config.options.bar.vertical = (newValue & 2) !== 0
                    }
                    options: [
                        { displayName: Translation.tr("Top"),    icon: "arrow_upward",   value: 0 },
                        { displayName: Translation.tr("Left"),   icon: "arrow_back",     value: 2 },
                        { displayName: Translation.tr("Bottom"), icon: "arrow_downward", value: 1 },
                        { displayName: Translation.tr("Right"),  icon: "arrow_forward",  value: 3 }
                    ]
                }
                ConfigSelectionArray {
                    objectName: "BarConfig.bar-position-2";
                    text: Translation.tr("Bar position")
                    icon: "swap_vert"
                    visible: page.settingsShow("panels") && (page.barMode !== "classic")
                    currentValue: Config.options.bar.bottom ? 1 : 0
                    onSelected: newValue => { Config.options.bar.bottom = newValue === 1 }
                    options: [
                        { displayName: Translation.tr("Top"),    icon: "arrow_upward",   value: 0 },
                        { displayName: Translation.tr("Bottom"), icon: "arrow_downward", value: 1 }
                    ]
                }

                // Mesobar-specific corner style
                ConfigSelectionArray {
                    objectName: "BarConfig.mesobar-style";
                    text: Translation.tr("Mesobar style")
                    icon: "style"
                    visible: page.settingsShow("panels") && (page.barMode === "mesoBar")
                    currentValue: Config.options.mesoBar.cornerStyle
                    onSelected: newValue => { Config.options.mesoBar.cornerStyle = newValue }
                    options: [
                        { displayName: Translation.tr("Hug"),     icon: "line_curve",  value: 0 },
                        { displayName: Translation.tr("Float"),   icon: "view_day",    value: 1 },
                        { displayName: Translation.tr("Islands"), icon: "crop_3_2",    value: 2 },
                        { displayName: Translation.tr("M3"),      icon: "interests",   value: 3 }
                    ]
                }

                // Mesobar width policy
                ConfigSelectionArray {
                    objectName: "BarConfig.width";
                    text: Translation.tr("Width")
                    icon: "width"
                    visible: page.settingsShow("panel-details") && (page.barMode === "mesoBar")
                    currentValue: Config.options.mesoBar.widthMode
                    onSelected: newValue => { Config.options.mesoBar.widthMode = newValue }
                    options: [
                        { displayName: Translation.tr("Fit content"), icon: "fit_screen", value: "content" },
                        { displayName: Translation.tr("Percent"),     icon: "width",       value: "percent" }
                    ]
                }
                ConfigSpinBox {
                    objectName: "BarConfig.width-of-screen";
                    icon: "width"
                    text: Translation.tr("Width (% of screen)")
                    visible: page.settingsShow("panel-details") && (page.barMode === "mesoBar" && Config.options.mesoBar.widthMode === "percent")
                    value: Config.options.mesoBar.widthPercent
                    from: 20; to: 100; stepSize: 5
                    onEdited: { Config.options.mesoBar.widthPercent = value }
                }

                // Shared corner style (all other modes)
                ConfigSelectionArray {
                    objectName: "BarConfig.bar-style";
                    text: Translation.tr("Bar style")
                    icon: "style"
                    visible: page.settingsShow("panels") && (page.barMode !== "mesoBar" && page.barMode !== "m3Island")
                    currentValue: Config.options.bar.cornerStyle
                    onSelected: newValue => { Config.options.bar.cornerStyle = newValue }
                    options: [
                        { displayName: Translation.tr("Hug"),     icon: "line_curve",  value: 0 },
                        { displayName: Translation.tr("Float"),   icon: "view_day",    value: 1 },
                        { displayName: Translation.tr("Islands"), icon: "crop_3_2",    value: 2 },
                        { displayName: Translation.tr("M3"),      icon: "interests",   value: 3 }
                    ]
                }

                // Group style (classic only)
                ConfigSelectionArray {
                    objectName: "BarConfig.group-style";
                    text: Translation.tr("Group style")
                    icon: "tab_group"
                    visible: page.settingsShow("panels") && (page.barMode === "classic")
                    currentValue: Config.options.bar.borderless
                    onSelected: newValue => { Config.options.bar.borderless = newValue }
                    options: [
                        { displayName: Translation.tr(""),          icon: "block",         value: "transparent" },
                        { displayName: Translation.tr("Pills"),     icon: "pill",          value: "pills" },
                        { displayName: Translation.tr("Separated"), icon: "view_column_2", value: "separated" },
                        { displayName: Translation.tr("Segmented"), icon: "tablet",        value: "segmented" },
                    ]
                }

                // Mesobar group style
                ConfigSelectionArray {
                    objectName: "BarConfig.group-style-2";
                    text: Translation.tr("Group style")
                    icon: "tab_group"
                    visible: page.settingsShow("panels") && (page.barMode === "mesoBar")
                    currentValue: Config.options.mesoBar.borderless
                    onSelected: newValue => { Config.options.mesoBar.borderless = newValue }
                    options: [
                        { displayName: Translation.tr(""),          icon: "block",         value: "transparent" },
                        { displayName: Translation.tr("Pills"),     icon: "pill",          value: "pills" },
                        { displayName: Translation.tr("Separated"), icon: "view_column_2", value: "separated" },
                        { displayName: Translation.tr("Segmented"), icon: "tablet",        value: "segmented" },
                    ]
                }

                ColorSelectionArray {
                    objectName: "BarConfig.group-color";
                    icon: "brush"
                    text: Translation.tr("Group Color")
                    visible: page.settingsShow("panel-details") && (page.barMode === "classic")
                    options: ["primaryContainer", "secondaryContainer", "tertiaryContainer", "layer1", "layer0"]
                    currentValue: Config.options.bar.groupColor
                    onSelected: newValue => { Config.options.bar.groupColor = newValue }
                }

                ConfigRow {
                    visible: page.settingsShow("panels");
                    uniform: true
                    ConfigSwitch {
                        visible: page.settingsShow("panels");
                        objectName: "BarConfig.show-background-2";
                        buttonIcon: "variable_insert"
                        text: Translation.tr("Show Background")
                        checked: page.barMode === "m3Island" ? Config.options.m3Island.showBackground : Config.options.bar.showBackground
                        onEdited: {
                            if (page.barMode === "m3Island") Config.options.m3Island.showBackground = checked
                            else Config.options.bar.showBackground = checked
                        }
                    }
                    ConfigSelectionArray {
                        visible: page.settingsShow("panels");
                        objectName: "BarConfig.autohide";
                        text: Translation.tr("Autohide")
                        icon: "preview_off"
                        currentValue: Config.options.bar.autoHide.enable
                        onSelected: newValue => { Config.options.bar.autoHide.enable = newValue }
                        options: [
                            { displayName: Translation.tr("No"),  icon: "close", value: false },
                            { displayName: Translation.tr("Yes"), icon: "check", value: true }
                        ]
                    }
                }

                GroupedList {
                    compact: true;
                    visible: page.settingsShow("panel-details") && (Config.options.bar.autoHide.enable)
                    ConfigSpinBox {
                        visible: page.settingsShow("panel-details");
                        objectName: "BarConfig.hover-region-width-px";
                        icon: "width"
                        text: Translation.tr("Hover Region Width (px)")
                        value: Config.options.bar.autoHide.hoverRegionWidth
                        from: 1; to: 20; stepSize: 1
                        onEdited: { Config.options.bar.autoHide.hoverRegionWidth = value }
                    }
                    ConfigSwitch {
                        visible: page.settingsShow("panel-details");
                        objectName: "BarConfig.push-windows-when-hidden";
                        buttonIcon: "open_with"
                        text: Translation.tr("Push Windows When Hidden")
                        checked: Config.options.bar.autoHide.pushWindows
                        onEdited: { Config.options.bar.autoHide.pushWindows = checked }
                    }
                    ConfigSwitch {
                        visible: page.settingsShow("panel-details");
                        objectName: "BarConfig.show-on-super-press";
                        buttonIcon: "keyboard"
                        text: Translation.tr("Show On Super Press")
                        checked: Config.options.bar.autoHide.showWhenPressingSuper.enable
                        onEdited: { Config.options.bar.autoHide.showWhenPressingSuper.enable = checked }
                    }
                }

                ConfigRow {
                    visible: page.settingsShow("panel-details|panels") && (page.barMode !== "m3Island")
                    ConfigSwitch {
                        visible: page.settingsShow("panels");
                        objectName: "BarConfig.show-frame-2";
                        buttonIcon: "panorama_wide_angle"
                        text: Translation.tr("Show Frame")
                        checked: Config.options.bar.showFrame
                        property bool switchReady: false
                        Component.onCompleted: Qt.callLater(() => switchReady = true)
                        onEdited: {
                            if (switchReady && checked) GlobalStates.refreshBar()
                            Config.options.bar.showFrame = checked
                        }
                    }
                    ConfigSwitch {
                        visible: page.settingsShow("panel-details");
                        objectName: "BarConfig.follow-frame-color";
                        buttonIcon: "colors"
                        enabled: Config.options.bar.showFrame
                        text: Translation.tr("Follow Frame Color")
                        checked: Config.options.bar.followFrameColor
                        onEdited: { Config.options.bar.followFrameColor = checked }
                    }
                }
                ConfigSpinBox {
                    objectName: "BarConfig.frame-thickness-2";
                    visible: page.settingsShow("panel-details") && (page.barMode !== "m3Island")
                    icon: "eraser_size_1"
                    text: Translation.tr("Frame thickness")
                    value: Config.options.bar.frameThickness
                    from: 2; to: 10; stepSize: 1
                    onEdited: { Config.options.bar.frameThickness = value }
                }
                ColorSelectionArray {
                    objectName: "BarConfig.frame-color-2";
                    visible: page.settingsShow("panel-details") && (page.barMode !== "m3Island")
                    icon: "imagesearch_roller"
                    text: Translation.tr("Frame Color")
                    options: ["primaryContainer", "secondaryContainer", "tertiaryContainer", "layer0", "black"]
                    currentValue: Config.options.bar.frameColor
                    onSelected: newValue => { Config.options.bar.frameColor = newValue }
                }
            }
        }

        // ── 6. Mesobar — specific options ─────────────────────────────────────
        ContentSection {
            icon: "dock"
            shape: MaterialShape.Shape.Cookie6Sided
            visible: page.settingsShow("panel-details|panels") && (page.barMode === "mesoBar")
            title: Translation.tr("Mesobar")

            GroupedList {
                compact: true;
                visible: page.settingsShow("panel-details|panels")
                ConfigRow {
                    visible: page.settingsShow("panel-details|panels")
                    ConfigSwitch {
                        visible: page.settingsShow("panels");
                        objectName: "BarConfig.show-frame-3";
                        buttonIcon: "panorama_wide_angle"
                        text: Translation.tr("Show Frame")
                        checked: Config.options.mesoBar.showFrame
                        property bool switchReady: false
                        Component.onCompleted: Qt.callLater(() => switchReady = true)
                        onEdited: {
                            if (switchReady && checked) GlobalStates.refreshBar()
                            Config.options.mesoBar.showFrame = checked
                        }
                    }
                    ConfigSwitch {
                        visible: page.settingsShow("panel-details");
                        objectName: "BarConfig.follow-frame-color-2";
                        buttonIcon: "colors"
                        enabled: Config.options.mesoBar.showFrame
                        text: Translation.tr("Follow Frame Color")
                        checked: Config.options.mesoBar.followFrameColor
                        onEdited: { Config.options.mesoBar.followFrameColor = checked }
                    }
                }
                ConfigSpinBox {
                    visible: page.settingsShow("panel-details");
                    objectName: "BarConfig.frame-thickness-3";
                    icon: "eraser_size_1"
                    text: Translation.tr("Frame thickness")
                    value: Config.options.mesoBar.frameThickness
                    from: 2; to: 10; stepSize: 1
                    onEdited: { Config.options.mesoBar.frameThickness = value }
                }
                ColorSelectionArray {
                    visible: page.settingsShow("panel-details");
                    objectName: "BarConfig.frame-color-3";
                    icon: "imagesearch_roller"
                    text: Translation.tr("Frame Color")
                    options: ["primaryContainer", "secondaryContainer", "tertiaryContainer", "layer0", "black"]
                    currentValue: Config.options.mesoBar.frameColor
                    onSelected: newValue => { Config.options.mesoBar.frameColor = newValue }
                }
            }
        }

        // ── 7. Tasklist Bar — specific options ────────────────────────────────
        ContentSection {
            icon: "list"
            shape: MaterialShape.Shape.Cookie6Sided
            visible: page.settingsShow("panel-details|panels") && (page.barMode === "tasklistBar")
            title: Translation.tr("Task list")

            GroupedList {
                compact: true;
                visible: page.settingsShow("panel-details|panels")
                ConfigRow {
                    visible: page.settingsShow("panels");
                    uniform: true
                    ConfigSwitch {
                        visible: page.settingsShow("panels");
                        objectName: "BarConfig.show-labels";
                        buttonIcon: "label"
                        text: Translation.tr("Show Labels")
                        checked: Config.options.tasklistBar.showLabels
                        onEdited: { Config.options.tasklistBar.showLabels = checked }
                    }
                }
                ConfigSpinBox {
                    visible: page.settingsShow("panel-details");
                    objectName: "BarConfig.max-button-width";
                    icon: "width"
                    text: Translation.tr("Max Button Width")
                    value: Config.options.tasklistBar.maxButtonWidth
                    from: 40; to: 400; stepSize: 10
                    onEdited: { Config.options.tasklistBar.maxButtonWidth = value }
                }
                LayoutSection {
                    sectionTitle: Translation.tr("Pinned Apps")
                    layout: Config.options.tasklistBar.pinnedApps
                    availableWidgets: page.availablePinnableApps()
                    getWidgetName: page.pinnedAppName
                    onUpdate: list => Config.options.tasklistBar.pinnedApps = list
                }
            }
        }

        // ── 8. System Monitor Bar — specific options ──────────────────────────
        ContentSection {
            icon: "monitoring"
            shape: MaterialShape.Shape.Cookie6Sided
            visible: page.settingsShow("panel-details|panels") && (page.barMode === "sysmonitorBar")
            title: Translation.tr("System monitor")

            GroupedList {
                compact: true;
                visible: page.settingsShow("panel-details|panels")
                ConfigRow {
                    visible: page.settingsShow("panels");
                    uniform: true
                    ConfigSwitch {
                        visible: page.settingsShow("panels");
                        objectName: "BarConfig.cpu";
                        buttonIcon: "planner_review"
                        text: Translation.tr("CPU")
                        checked: Config.options.sysmonitorBar.showCpu
                        onEdited: { Config.options.sysmonitorBar.showCpu = checked }
                    }
                    ConfigSwitch {
                        visible: page.settingsShow("panels");
                        objectName: "BarConfig.cpu-temperature";
                        buttonIcon: "thermostat"
                        text: Translation.tr("CPU Temperature")
                        checked: Config.options.sysmonitorBar.showCpuTemp
                        onEdited: { Config.options.sysmonitorBar.showCpuTemp = checked }
                    }
                }
                ConfigRow {
                    visible: page.settingsShow("panels");
                    uniform: true
                    ConfigSwitch {
                        visible: page.settingsShow("panels");
                        objectName: "BarConfig.ram";
                        buttonIcon: "memory"
                        text: Translation.tr("RAM")
                        checked: Config.options.sysmonitorBar.showRam
                        onEdited: { Config.options.sysmonitorBar.showRam = checked }
                    }
                    ConfigSwitch {
                        visible: page.settingsShow("panels");
                        objectName: "BarConfig.disk";
                        buttonIcon: "storage"
                        text: Translation.tr("Disk")
                        checked: Config.options.sysmonitorBar.showDisk
                        onEdited: { Config.options.sysmonitorBar.showDisk = checked }
                    }
                }
                ConfigRow {
                    visible: page.settingsShow("panels");
                    uniform: true
                    ConfigSwitch {
                        visible: page.settingsShow("panels");
                        objectName: "BarConfig.swap";
                        buttonIcon: "swap_horiz"
                        text: Translation.tr("Swap")
                        checked: Config.options.sysmonitorBar.showSwap
                        onEdited: { Config.options.sysmonitorBar.showSwap = checked }
                    }
                    ConfigSwitch {
                        visible: page.settingsShow("panels");
                        objectName: "BarConfig.network";
                        buttonIcon: "network_check"
                        text: Translation.tr("Network")
                        checked: Config.options.sysmonitorBar.showNetwork
                        onEdited: { Config.options.sysmonitorBar.showNetwork = checked }
                    }
                }
                ConfigSpinBox {
                    visible: page.settingsShow("panel-details");
                    objectName: "BarConfig.ram-warning-threshold";
                    icon: "memory"
                    text: Translation.tr("RAM warning threshold (%)")
                    value: Config.options.sysmonitorBar.memoryWarningThreshold
                    from: 50; to: 100; stepSize: 1
                    onEdited: { Config.options.sysmonitorBar.memoryWarningThreshold = value }
                }
                ConfigSpinBox {
                    visible: page.settingsShow("panel-details");
                    objectName: "BarConfig.cpu-warning-threshold";
                    icon: "planner_review"
                    text: Translation.tr("CPU warning threshold (%)")
                    value: Config.options.sysmonitorBar.cpuWarningThreshold
                    from: 50; to: 100; stepSize: 1
                    onEdited: { Config.options.sysmonitorBar.cpuWarningThreshold = value }
                }
                ConfigSpinBox {
                    visible: page.settingsShow("panel-details");
                    objectName: "BarConfig.temperature-warning-threshold-c";
                    icon: "thermostat"
                    text: Translation.tr("Temperature warning threshold (°C)")
                    value: Config.options.sysmonitorBar.tempWarningThreshold
                    from: 50; to: 110; stepSize: 1
                    onEdited: { Config.options.sysmonitorBar.tempWarningThreshold = value }
                }
                ConfigSpinBox {
                    visible: page.settingsShow("panel-details");
                    objectName: "BarConfig.disk-warning-threshold";
                    icon: "storage"
                    text: Translation.tr("Disk warning threshold (%)")
                    value: Config.options.sysmonitorBar.diskWarningThreshold
                    from: 50; to: 100; stepSize: 1
                    onEdited: { Config.options.sysmonitorBar.diskWarningThreshold = value }
                }
                ConfigSpinBox {
                    visible: page.settingsShow("panel-details");
                    objectName: "BarConfig.swap-warning-threshold";
                    icon: "swap_horiz"
                    text: Translation.tr("Swap warning threshold (%)")
                    value: Config.options.sysmonitorBar.swapWarningThreshold
                    from: 50; to: 100; stepSize: 1
                    onEdited: { Config.options.sysmonitorBar.swapWarningThreshold = value }
                }
            }
        }

        // ── 9. Quick Actions Bar — specific options ───────────────────────────
        ContentSection {
            icon: "tune"
            shape: MaterialShape.Shape.Cookie6Sided
            visible: page.settingsShow("integrations|panels") && (page.barMode === "quickActionsBar")
            title: Translation.tr("Quick actions")

            GroupedList {
                compact: true;
                visible: page.settingsShow("integrations|panels")
                ConfigRow {
                    visible: page.settingsShow("panels");
                    uniform: true
                    ConfigSwitch {
                        visible: page.settingsShow("panels");
                        objectName: "BarConfig.volume-slider";
                        buttonIcon: "volume_up"
                        text: Translation.tr("Volume Slider")
                        checked: Config.options.quickActionsBar.showVolumeSlider
                        onEdited: { Config.options.quickActionsBar.showVolumeSlider = checked }
                    }
                    ConfigSwitch {
                        visible: page.settingsShow("panels");
                        objectName: "BarConfig.brightness-slider";
                        buttonIcon: "brightness_6"
                        text: Translation.tr("Brightness Slider")
                        checked: Config.options.quickActionsBar.showBrightnessSlider
                        onEdited: { Config.options.quickActionsBar.showBrightnessSlider = checked }
                    }
                }
                LayoutSection {
                    sectionTitle: Translation.tr("Toggles")
                    layout: Config.options.quickActionsBar.toggles.map(t => t.type)
                    availableWidgets: page.availableToggleTypes()
                    getWidgetName: page.getToggleTypeName
                    onUpdate: list => Config.options.quickActionsBar.toggles = list.map(t => ({ type: t }))
                }

                ConfigRow {
                    visible: Config.options.quickActionsBar.toggles.some(t => t.type === "hotspot")
                    uniform: true
                    ColumnLayout {
                        visible: page.settingsShow("integrations");

                        Layout.fillWidth: true
                        spacing: 4
                        StyledText {
                            text: Translation.tr("Hotspot SSID")
                            font.pixelSize: Appearance.font.pixelSize.smaller
                            color: Appearance.colors.colSubtext
                        }
                        MaterialTextField {
                            objectName: "BarConfig.hotspot-ssid";
                            visible: page.settingsShow("integrations");

                            Layout.fillWidth: true
                            placeholderText: Hotspot.ssid
                            text: Config.options.quickActionsBar.hotspotSsid
                            onTextEdited: Config.options.quickActionsBar.hotspotSsid = text
                        }
                    }
                    ColumnLayout {
                        visible: page.settingsShow("integrations");

                        Layout.fillWidth: true
                        spacing: 4
                        StyledText {
                            text: Translation.tr("Hotspot Password")
                            font.pixelSize: Appearance.font.pixelSize.smaller
                            color: Appearance.colors.colSubtext
                        }
                        MaterialTextField {
                            objectName: "BarConfig.hotspot-password";
                            visible: page.settingsShow("integrations");

                            Layout.fillWidth: true
                            placeholderText: Hotspot.password
                            text: Config.options.quickActionsBar.hotspotPassword
                            echoMode: TextInput.Password
                            onTextEdited: Config.options.quickActionsBar.hotspotPassword = text
                        }
                    }
                }
            }
        }

        // ── 10. Info Strip — specific options ─────────────────────────────────
        ContentSection {
            icon: "remove"
            shape: MaterialShape.Shape.Cookie6Sided
            visible: page.settingsShow("panels") && (page.barMode === "infoStrip")
            title: Translation.tr("Info strip")

            GroupedList {
                compact: true;
                visible: page.settingsShow("panels")
                ConfigRow {
                    visible: page.settingsShow("panels");
                    uniform: true
                    ConfigSwitch {
                        visible: page.settingsShow("panels");
                        objectName: "BarConfig.active-window";
                        buttonIcon: "subtitles"
                        text: Translation.tr("Active Window")
                        checked: Config.options.infoStrip.showActiveWindow
                        onEdited: { Config.options.infoStrip.showActiveWindow = checked }
                    }
                    ConfigSwitch {
                        visible: page.settingsShow("panels");
                        objectName: "BarConfig.clock";
                        buttonIcon: "schedule"
                        text: Translation.tr("Clock")
                        checked: Config.options.infoStrip.showClock
                        onEdited: { Config.options.infoStrip.showClock = checked }
                    }
                }
                ConfigRow {
                    visible: page.settingsShow("panels");
                    uniform: true
                    ConfigSwitch {
                        visible: page.settingsShow("panels");
                        objectName: "BarConfig.cpu-usage";
                        buttonIcon: "memory"
                        text: Translation.tr("CPU Usage")
                        checked: Config.options.infoStrip.showCpuUsage
                        onEdited: { Config.options.infoStrip.showCpuUsage = checked }
                    }
                    ConfigSwitch {
                        visible: page.settingsShow("panels");
                        objectName: "BarConfig.memory-usage";
                        buttonIcon: "planner_review"
                        text: Translation.tr("Memory Usage")
                        checked: Config.options.infoStrip.showMemoryUsage
                        onEdited: { Config.options.infoStrip.showMemoryUsage = checked }
                    }
                }
                ConfigSwitch {
                    visible: page.settingsShow("panels");
                    objectName: "BarConfig.notification-dot";
                    buttonIcon: "notifications"
                    text: Translation.tr("Notification Dot")
                    checked: Config.options.infoStrip.showNotificationDot
                    onEdited: { Config.options.infoStrip.showNotificationDot = checked }
                }
            }
        }

        // ── 11. Notifications ─────────────────────────────────────────────────
        ContentSection {
            visible: page.settingsShow("notification-rules|notifications|panels");
            icon: "notifications"
            shape: MaterialShape.Shape.Bun
            title: Translation.tr("Notifications")

            GroupedList {
                compact: true;
                visible: page.settingsShow("notification-rules|notifications|panels")
                ConfigComboBox {
                    objectName: "BarConfig.popup-position";
                    visible: page.settingsShow("notifications");

                    text: Translation.tr("Popup position")
                    buttonIcon: "my_location"
                    currentValue: Config.options.notifications.position
                    fieldWidth: 50
                    onSelected: newValue => { Config.options.notifications.position = newValue }
                    model: [
                        { displayName: Translation.tr("Top left"),      value: "top_left" },
                        { displayName: Translation.tr("Top center"),    value: "top_center" },
                        { displayName: Translation.tr("Top right"),     value: "top_right" },
                        { displayName: Translation.tr("Bottom left"),   value: "bottom_left" },
                        { displayName: Translation.tr("Bottom center"), value: "bottom_center" },
                        { displayName: Translation.tr("Bottom right"),  value: "bottom_right" }
                    ]
                }
                ConfigSwitch {
                    visible: page.settingsShow("panels");
                    objectName: "BarConfig.unread-indicator-show-count";
                    buttonIcon: "counter_2"
                    text: Translation.tr("Unread indicator: show count")
                    checked: Config.options.bar.indicators.notifications.showUnreadCount
                    onEdited: { Config.options.bar.indicators.notifications.showUnreadCount = checked }
                }
                ConfigSpinBox {
                    visible: page.settingsShow("notification-rules");
                    objectName: "BarConfig.timeout-duration-ms";
                    icon: "av_timer"
                    text: Translation.tr("Timeout duration (ms)")
                    value: Config.options.notifications.timeout
                    from: 1000; to: 60000; stepSize: 1000
                    onEdited: { Config.options.notifications.timeout = value }
                }
            }
        }

        // ── 12. Tray ──────────────────────────────────────────────────────────
        ContentSection {
            visible: page.settingsShow("panels");
            shape: MaterialShape.Shape.Square
            icon: "inbox_customize"
            title: Translation.tr("Tray")

            GroupedList {
                compact: true;
                visible: page.settingsShow("panels")
                ConfigSwitch {
                    visible: page.settingsShow("panels");
                    objectName: "BarConfig.make-icons-pinned-by-default";
                    buttonIcon: "keep"
                    text: Translation.tr("Make icons pinned by default")
                    checked: Config.options.tray.invertPinnedItems
                    onEdited: { Config.options.tray.invertPinnedItems = checked }
                }
                ConfigSwitch {
                    visible: page.settingsShow("panels");
                    objectName: "BarConfig.tint-icons";
                    buttonIcon: "colors"
                    text: Translation.tr("Tint icons")
                    checked: Config.options.tray.monochromeIcons
                    onEdited: { Config.options.tray.monochromeIcons = checked }
                }
            }
        }

        // ── 13. Divider (classic only) ────────────────────────────────────────
        ContentSection {
            icon: "vertical_align_center"
            shape: MaterialShape.Shape.Diamond
            visible: page.settingsShow("panel-details|panels") && (page.barMode === "classic")
            title: Translation.tr("Divider")

            GroupedList {
                compact: true;
                visible: page.settingsShow("panel-details|panels")
                ConfigSelectionArray {
                    visible: page.settingsShow("panels");
                    objectName: "BarConfig.style";
                    text: Translation.tr("Style")
                    icon: "style"
                    currentValue: Config.options.bar.divider.style
                    onSelected: newValue => { Config.options.bar.divider.style = newValue }
                    options: [
                        { displayName: Translation.tr("Line"),  icon: "more_vert",           value: "rect" },
                        { displayName: Translation.tr("Dot"),   icon: "fiber_manual_record", value: "dot" },
                        { displayName: Translation.tr("Space"), icon: "space_bar",           value: "space" }
                    ]
                }
                ConfigSpinBox {
                    visible: page.settingsShow("panel-details");
                    objectName: "BarConfig.space-width-px";
                    icon: "width"
                    enabled: Config.options.bar.divider.style === "space"
                    text: Translation.tr("Space width (px)")
                    value: Config.options.bar.divider.spacing
                    from: 4; to: 400; stepSize: 2
                    onEdited: { Config.options.bar.divider.spacing = value }
                }
            }
        }

        // ── 14. Utility Buttons (classic & mesoBar) ────────────────────────────
        ContentSection {
            icon: "buttons_alt"
            shape: MaterialShape.Shape.SoftBurst
            visible: page.settingsShow("panels") && (page.barMode === "classic" || page.barMode === "mesoBar")
            title: Translation.tr("Utility Buttons")

            GroupedList {
                compact: true;
                visible: page.settingsShow("panels")
                ConfigRow {
                    visible: page.settingsShow("panels");
                    uniform: true
                    ConfigSwitch {
                        visible: page.settingsShow("panels");
                        objectName: "BarConfig.screen-snip";
                        buttonIcon: "screenshot_region"
                        text: Translation.tr("Screen snip")
                        checked: Config.options.bar.utilButtons.showScreenSnip
                        onEdited: { Config.options.bar.utilButtons.showScreenSnip = checked }
                    }
                    ConfigSwitch {
                        visible: page.settingsShow("panels");
                        objectName: "BarConfig.color-picker";
                        buttonIcon: "colorize"
                        text: Translation.tr("Color picker")
                        checked: Config.options.bar.utilButtons.showColorPicker
                        onEdited: { Config.options.bar.utilButtons.showColorPicker = checked }
                    }
                }
                ConfigRow {
                    visible: page.settingsShow("panels");
                    uniform: true
                    ConfigSwitch {
                        visible: page.settingsShow("panels");
                        objectName: "BarConfig.keyboard-toggle";
                        buttonIcon: "keyboard"
                        text: Translation.tr("Keyboard toggle")
                        checked: Config.options.bar.utilButtons.showKeyboardToggle
                        onEdited: { Config.options.bar.utilButtons.showKeyboardToggle = checked }
                    }
                    ConfigSwitch {
                        visible: page.settingsShow("panels");
                        objectName: "BarConfig.mic-toggle";
                        buttonIcon: "mic"
                        text: Translation.tr("Mic toggle")
                        checked: Config.options.bar.utilButtons.showMicToggle
                        onEdited: { Config.options.bar.utilButtons.showMicToggle = checked }
                    }
                }
                ConfigRow {
                    visible: page.settingsShow("panels");
                    uniform: true
                    ConfigSwitch {
                        visible: page.settingsShow("panels");
                        objectName: "BarConfig.dark-light-toggle";
                        buttonIcon: "dark_mode"
                        text: Translation.tr("Dark/Light toggle")
                        checked: Config.options.bar.utilButtons.showDarkModeToggle
                        onEdited: { Config.options.bar.utilButtons.showDarkModeToggle = checked }
                    }
                    ConfigSwitch {
                        visible: page.settingsShow("panels");
                        objectName: "BarConfig.performance-profile";
                        buttonIcon: "speed"
                        text: Translation.tr("Performance Profile")
                        checked: Config.options.bar.utilButtons.showPerformanceProfileToggle
                        onEdited: { Config.options.bar.utilButtons.showPerformanceProfileToggle = checked }
                    }
                }
                ConfigRow {
                    visible: page.settingsShow("panels");
                    uniform: true
                    ConfigSwitch {
                        visible: page.settingsShow("panels");
                        objectName: "BarConfig.record-screen";
                        buttonIcon: "screen_record"
                        text: Translation.tr("Record Screen")
                        checked: Config.options.bar.utilButtons.showScreenRecord
                        onEdited: { Config.options.bar.utilButtons.showScreenRecord = checked }
                    }
                    ConfigSwitch {
                        visible: page.settingsShow("panels");
                        objectName: "BarConfig.wallpapers-toggle";
                        buttonIcon: "imagesmode"
                        text: Translation.tr("Wallpapers Toggle")
                        checked: Config.options.bar.utilButtons.showWallpaperToggle
                        onEdited: { Config.options.bar.utilButtons.showWallpaperToggle = checked }
                    }
                }
            }
        }

        // ── 15. Workspaces (classic & mesoBar) ─────────────────────────────────
        ContentSection {
            shape: MaterialShape.Shape.Cookie12Sided
            icon: "steppers"
            visible: page.settingsShow("panels") && (page.barMode === "classic" || page.barMode === "mesoBar")
            title: Translation.tr("Workspaces")

            GroupedList {
                compact: true;
                visible: page.settingsShow("panels")
                ConfigSwitch {
                    visible: page.settingsShow("panels");
                    objectName: "BarConfig.always-show-numbers";
                    buttonIcon: "counter_1"
                    text: Translation.tr("Always show numbers")
                    checked: Config.options.bar.workspaces.alwaysShowNumbers
                    onEdited: { Config.options.bar.workspaces.alwaysShowNumbers = checked }
                }
                ConfigSelectionArray {
                    visible: page.settingsShow("panels");
                    objectName: "BarConfig.numbers-style";
                    text: Translation.tr("Numbers style")
                    icon: "looks_3"
                    currentValue: JSON.stringify(Config.options.bar.workspaces.numberMap)
                    onSelected: newValue => { Config.options.bar.workspaces.numberMap = JSON.parse(newValue) }
                    options: [
                        { displayName: Translation.tr("Normal"),    icon: "timer_10",        value: '[]' },
                        { displayName: Translation.tr("Han chars"), icon: "glyphs",          value: '["一","二","三","四","五","六","七","八","九","十","十一","十二","十三","十四","十五","十六","十七","十八","十九","二十"]' },
                        { displayName: Translation.tr("Roman"),     icon: "account_balance", value: '["I","II","III","IV","V","VI","VII","VIII","IX","X","XI","XII","XIII","XIV","XV","XVI","XVII","XVIII","XIX","XX"]' }
                    ]
                }
                ConfigSwitch {
                    visible: page.settingsShow("panels");
                    objectName: "BarConfig.show-app-icons";
                    buttonIcon: "award_star"
                    text: Translation.tr("Show app icons")
                    checked: Config.options.bar.workspaces.showAppIcons
                    onEdited: { Config.options.bar.workspaces.showAppIcons = checked }
                }
                ConfigSpinBox {
                    visible: page.settingsShow("panels");
                    objectName: "BarConfig.workspaces-shown";
                    icon: "view_column"
                    text: Translation.tr("Workspaces shown")
                    value: Config.options.bar.workspaces.shown
                    from: 1; to: 30
                    onEdited: { Config.options.bar.workspaces.shown = value }
                }
                ConfigSwitch {
                    visible: page.settingsShow("panels");
                    objectName: "BarConfig.show-preview-on-hover";
                    buttonIcon: "preview"
                    text: Translation.tr("Show preview on hover")
                    checked: Config.options.overview.hoverPreviewInBar
                    onEdited: { Config.options.overview.hoverPreviewInBar = checked }
                }
                ConfigSelectionArray {
                    visible: page.settingsShow("panels");
                    objectName: "BarConfig.indicator-style";
                    text: Translation.tr("Indicator style")
                    icon: "page_control"
                    currentValue: Config.options.bar.workspaces.indicatorStyle ?? "icon"
                    onSelected: newValue => { Config.options.bar.workspaces.indicatorStyle = newValue }
                    options: [
                        { displayName: Translation.tr("Dots"),  icon: "radio_button_checked", value: "dot" },
                        { displayName: Translation.tr("Icons"), icon: "interests",            value: "icon" },
                    ]
                }
            }
        }

        // ── 16. Resources (classic only) ──────────────────────────────────────
        ContentSection {
            icon: "empty_dashboard"
            shape: MaterialShape.Shape.Burst
            visible: page.settingsShow("panel-details|panels") && (page.barMode === "classic")
            title: Translation.tr("Resources")

            GroupedList {
                compact: true;
                visible: page.settingsShow("panel-details|panels")
                ConfigRow {
                    visible: page.settingsShow("panels");
                    uniform: true
                    ConfigSwitch {
                        visible: page.settingsShow("panels");
                        objectName: "BarConfig.cpu-2";
                        buttonIcon: "planner_review"
                        text: Translation.tr("CPU")
                        checked: Config.options.bar.resources.alwaysShowCpu
                        onEdited: { Config.options.bar.resources.alwaysShowCpu = checked }
                    }
                    ConfigSwitch {
                        visible: page.settingsShow("panels");
                        objectName: "BarConfig.cpu-temperature-2";
                        buttonIcon: "thermostat"
                        text: Translation.tr("CPU Temperature")
                        checked: Config.options.bar.resources.alwaysShowCpuTemp
                        onEdited: { Config.options.bar.resources.alwaysShowCpuTemp = checked }
                    }
                }
                ConfigRow {
                    visible: page.settingsShow("panels");
                    uniform: true
                    ConfigSwitch {
                        visible: page.settingsShow("panels");
                        objectName: "BarConfig.ram-2";
                        buttonIcon: "memory"
                        text: Translation.tr("RAM")
                        checked: Config.options.bar.resources.alwaysShowRam
                        onEdited: { Config.options.bar.resources.alwaysShowRam = checked }
                    }
                    ConfigSwitch {
                        visible: page.settingsShow("panels");
                        objectName: "BarConfig.disk-2";
                        buttonIcon: "storage"
                        text: Translation.tr("Disk")
                        checked: Config.options.bar.resources.alwaysShowDisk
                        onEdited: { Config.options.bar.resources.alwaysShowDisk = checked }
                    }
                }
                ConfigRow {
                    visible: page.settingsShow("panels");
                    uniform: true
                    ConfigSwitch {
                        visible: page.settingsShow("panels");
                        objectName: "BarConfig.swap-2";
                        buttonIcon: "swap_horiz"
                        text: Translation.tr("Swap")
                        checked: Config.options.bar.resources.alwaysShowSwap
                        onEdited: { Config.options.bar.resources.alwaysShowSwap = checked }
                    }
                }
                ConfigSelectionArray {
                    visible: page.settingsShow("panels");
                    objectName: "BarConfig.style-2";
                    text: Translation.tr("Style")
                    icon: "style"
                    currentValue: Config.options.bar.resources.style
                    onSelected: newValue => { Config.options.bar.resources.style = newValue }
                    options: [
                        { displayName: Translation.tr("Filled"),  icon: "incomplete_circle", value: "filled" },
                        { displayName: Translation.tr("Outline"), icon: "circles",           value: "outline" }
                    ]
                }
                ConfigSwitch {
                    visible: page.settingsShow("panels");
                    objectName: "BarConfig.show-percentage";
                    buttonIcon: "decimal_increase"
                    text: Translation.tr("Show Percentage")
                    checked: Config.options.bar.resources.showValue
                    onEdited: { Config.options.bar.resources.showValue = checked }
                }
                ConfigSpinBox {
                    visible: page.settingsShow("panel-details");
                    objectName: "BarConfig.polling-interval-ms";
                    icon: "av_timer"
                    text: Translation.tr("Polling interval (ms)")
                    value: Config.options.resources.updateInterval
                    from: 100; to: 10000; stepSize: 100
                    onEdited: { Config.options.resources.updateInterval = value }
                }
            }
        }

        // ── 17. Media (classic & mesoBar) ──────────────────────────────────────
        ContentSection {
            icon: "music_note"
            shape: MaterialShape.Shape.Sunny
            visible: page.settingsShow("panel-details|panels") && (page.barMode === "classic" || page.barMode === "mesoBar")
            title: Translation.tr("Media")

            GroupedList {
                compact: true;
                visible: page.settingsShow("panel-details|panels")
                ConfigTextArea {
                    visible: page.settingsShow("panels");
                    objectName: "BarConfig.preferred-player";
                    id: preferredPlayerField
                    Layout.fillWidth: true
                    buttonIcon: "play_circle"
                    text: Translation.tr("Preferred Player")
                    placeholderText: Translation.tr("e.g. spotify, firefox")
                    value: Config.options.bar.media.preferredPlayer
                    onEdited: { mediaDebounceTimer.restart() }

                    Timer {
                        id: mediaDebounceTimer
                        interval: 600
                        repeat: false
                        onTriggered: { Config.options.bar.media.preferredPlayer = preferredPlayerField.value }
                    }
                }
                ConfigSwitch {
                    visible: page.settingsShow("panels");
                    objectName: "BarConfig.pin-media-controls";
                    buttonIcon: "keep"
                    text: Translation.tr("Pin media controls")
                    checked: Config.options.bar.media.alwaysVisible
                    onEdited: { Config.options.bar.media.alwaysVisible = checked }
                }
                ConfigSwitch {
                    visible: page.settingsShow("panels");
                    objectName: "BarConfig.show-only-title";
                    buttonIcon: "titlecase"
                    text: Translation.tr("Show only title")
                    checked: Config.options.bar.media.onlyTitle
                    onEdited: { Config.options.bar.media.onlyTitle = checked }
                }
                ConfigSpinBox {
                    visible: page.settingsShow("panel-details");
                    objectName: "BarConfig.max-media-width";
                    icon: "width"
                    text: Translation.tr("Max media width")
                    value: Config.options.bar.media.maxWidth
                    from: 100; to: 500; stepSize: 10
                    onEdited: { Config.options.bar.media.maxWidth = value }
                }
            }
        }

        // ── 18. Tooltips ──────────────────────────────────────────────────────
        ContentSection {
            visible: page.settingsShow("panels");
            shape: MaterialShape.Shape.Puffy
            icon: "tooltip"
            title: Translation.tr("Tooltips")

            GroupedList {
                compact: true;
                visible: page.settingsShow("panels")
                ConfigSwitch {
                    visible: page.settingsShow("panels");
                    objectName: "BarConfig.click-to-show";
                    buttonIcon: "ads_click"
                    text: Translation.tr("Click to show")
                    checked: Config.options.bar.tooltips.clickToShow
                    onEdited: { Config.options.bar.tooltips.clickToShow = checked }
                }
            }
        }
    }
}
