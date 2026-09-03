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

    function availableForM3() {
        let used = [
            ...Config.options.m3Island.layouts.hoverLayout,
            ...Config.options.m3Island.layouts.expandedLayout
        ]
        const multipleAllowed = ["visualizer", "divisor"]
        return [...allWidgets, ...m3OnlyWidgets].filter(w => {
            if (w.id === "divisor" && Config.options.m3Island.borderless !== "transparent") return false
            return !used.includes(w.id) || multipleAllowed.includes(w.id)
        })
    }

    ColumnLayout {
        id: mainLayout
        Layout.fillWidth: true
        Layout.fillHeight: true
        spacing: 20

        // ── 1. Bar Mode ───────────────────────────────────────────────────────
        ContentSection {
            icon: "dashboard_customize"
            shape: MaterialShape.Shape.Gem
            title: Translation.tr("Bar Mode")

            GroupedList {
                ConfigSelectionArray {
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
            visible: Hyprland.monitors.values.length > 1
            title: Translation.tr("Screens")
            ContentSubsection {
                title: Translation.tr("Show bar on")

                ColumnLayout {
                    id: monitorsCol
                    Layout.fillWidth: true
                    spacing: 2

                    Rectangle {
                        id: allRow
                        Layout.fillWidth: true
                        implicitHeight: allSwitchItem.implicitHeight + 16 + 8
                        color: Appearance.colors.colLayer1
                        topLeftRadius: Appearance.rounding.normal
                        topRightRadius: Appearance.rounding.normal
                        bottomLeftRadius: Appearance.rounding.unsharpenmore
                        bottomRightRadius: Appearance.rounding.unsharpenmore

                        ConfigSwitch {
                            id: allSwitchItem
                            anchors { fill: parent; margins: 8 }
                            buttonIcon: "tv_displays"
                            text: Translation.tr("All")
                            onCheckedChanged: {
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
                                id: switchItem
                                anchors { fill: parent; margins: 8 }
                                buttonIcon: "monitor"
                                text: monitorRow.modelData.name
                                onCheckedChanged: {
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
            title: Translation.tr("M3 Island Layout")

            GroupedList {
                LayoutSection {
                    sectionTitle: Translation.tr("Hover (peek)")
                    layout: Config.options.m3Island.layouts.hoverLayout
                    availableWidgets: page.availableForM3()
                    getWidgetName: page.getWidgetName
                    onUpdate: list => Config.options.m3Island.layouts.hoverLayout = list
                }
                LayoutSection {
                    sectionTitle: Translation.tr("Expanded")
                    layout: Config.options.m3Island.layouts.expandedLayout
                    availableWidgets: page.availableForM3()
                    getWidgetName: page.getWidgetName
                    onUpdate: list => Config.options.m3Island.layouts.expandedLayout = list
                }
            }
        }

        // ── 4c. M3 Island Options ──────────────────────────────────────────
        ContentSection {
            icon: "tune"
            shape: MaterialShape.Shape.SoftBurst
            visible: page.barMode === "m3Island"
            title: Translation.tr("M3 Island Options")

            GroupedList {
                ConfigSelectionArray {
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
                    uniform: true
                    ConfigSwitch {
                        buttonIcon: "calendar_today"
                        text: Translation.tr("Show date")
                        checked: Config.options.m3Island.clockShowDate
                        onCheckedChanged: { Config.options.m3Island.clockShowDate = checked }
                    }
                    ConfigSwitch {
                        buttonIcon: "timelapse"
                        text: Translation.tr("Hover peek")
                        checked: Config.options.m3Island.hoverPeek
                        onCheckedChanged: { Config.options.m3Island.hoverPeek = checked }
                    }
                }
                ConfigRow {
                    uniform: true
                    ConfigSwitch {
                        buttonIcon: "timer"
                        text: Translation.tr("Show seconds")
                        checked: Config.options.m3Island.clockShowSeconds
                        onCheckedChanged: { Config.options.m3Island.clockShowSeconds = checked }
                    }
                    ConfigSwitch {
                        buttonIcon: "schedule"
                        text: Translation.tr("Use 24-hour clock")
                        checked: Config.options.m3Island.clockUse24h
                        onCheckedChanged: { Config.options.m3Island.clockUse24h = checked }
                    }
                }
                ConfigRow {
                    uniform: true
                    ConfigSwitch {
                        buttonIcon: "vertical_align_center"
                        text: Translation.tr("Reserve screen space")
                        checked: Config.options.m3Island.reserveScreenSpace ?? false
                        onCheckedChanged: {
                            if (!Config.ready || checked === (Config.options.m3Island.reserveScreenSpace ?? false)) return
                            Config.setNestedValue("m3Island.reserveScreenSpace", checked)
                        }
                    }
                    ConfigSwitch {
                        buttonIcon: "open_in_full"
                        text: Translation.tr("Click to expand")
                        checked: Config.options.m3Island.clickToExpand
                        onCheckedChanged: { Config.options.m3Island.clickToExpand = checked }
                    }
                    ConfigSwitch {
                        buttonIcon: "search"
                        text: Translation.tr("Launcher hug")
                        checked: Config.options.m3Island.launcherHug
                        onCheckedChanged: { Config.options.m3Island.launcherHug = checked }
                    }
                    ConfigSwitch {
                        buttonIcon: "more_horiz"
                        text: Translation.tr("Show expanded details")
                        checked: Config.options.m3Island.verbose
                        onCheckedChanged: { Config.options.m3Island.verbose = checked }
                    }
                }
                ConfigSpinBox {
                    icon: "format_list_numbered"
                    text: Translation.tr("Launcher maximum visible results")
                    value: Config.options.m3Island.launcherMaxResults
                    from: 1; to: 10; stepSize: 1
                    onValueChanged: { Config.options.m3Island.launcherMaxResults = value }
                }
                ConfigSelectionArray {
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
                    icon: "height"
                    text: Translation.tr("Expanded height")
                    value: Config.options.m3Island.expandedHeight
                    from: 48; to: 160; stepSize: 4
                    onValueChanged: { Config.options.m3Island.expandedHeight = value }
                }
                ConfigSelectionArray {
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
                    icon: "timer"
                    text: Translation.tr("Notification display time (ms, 0 = global)")
                    value: Config.options.m3Island.notificationTimeout
                    from: 0; to: 30000; stepSize: 500
                    onValueChanged: { Config.options.m3Island.notificationTimeout = value }
                }
                ConfigRow {
                    uniform: true
                    ConfigSwitch {
                        buttonIcon: "panorama_wide_angle"
                        text: Translation.tr("Show Background")
                        checked: Config.options.m3Island.showBackground
                        onCheckedChanged: { Config.options.m3Island.showBackground = checked }
                    }
                    ConfigSwitch {
                        buttonIcon: "border_all"
                        text: Translation.tr("Show Frame")
                        checked: Config.options.m3Island.showFrame
                        onCheckedChanged: { Config.options.m3Island.showFrame = checked }
                    }
                }
                ConfigSwitch {
                    buttonIcon: "colors"
                    enabled: Config.options.m3Island.showFrame
                    text: Translation.tr("Use Frame Color as Background")
                    checked: Config.options.m3Island.followFrameColor
                    onCheckedChanged: { Config.options.m3Island.followFrameColor = checked }
                }
                ConfigSpinBox {
                    icon: "eraser_size_1"
                    text: Translation.tr("Frame thickness")
                    enabled: Config.options.m3Island.showFrame
                    value: Config.options.m3Island.frameThickness
                    from: 1; to: 10; stepSize: 1
                    onValueChanged: { Config.options.m3Island.frameThickness = value }
                }
                ColorSelectionArray {
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
            icon: "pivot_table_chart"
            shape: MaterialShape.Shape.Gem
            title: Translation.tr("Positioning & Style")

            GroupedList {
                // Position — classic uses all 4 directions; others top/bottom only
                ConfigSelectionArray {
                    text: Translation.tr("Bar position")
                    icon: "swap_vert"
                    visible: page.barMode === "classic"
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
                    text: Translation.tr("Bar position")
                    icon: "swap_vert"
                    visible: page.barMode !== "classic"
                    currentValue: Config.options.bar.bottom ? 1 : 0
                    onSelected: newValue => { Config.options.bar.bottom = newValue === 1 }
                    options: [
                        { displayName: Translation.tr("Top"),    icon: "arrow_upward",   value: 0 },
                        { displayName: Translation.tr("Bottom"), icon: "arrow_downward", value: 1 }
                    ]
                }

                // Mesobar-specific corner style
                ConfigSelectionArray {
                    text: Translation.tr("Mesobar style")
                    icon: "style"
                    visible: page.barMode === "mesoBar"
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
                    text: Translation.tr("Width")
                    icon: "width"
                    visible: page.barMode === "mesoBar"
                    currentValue: Config.options.mesoBar.widthMode
                    onSelected: newValue => { Config.options.mesoBar.widthMode = newValue }
                    options: [
                        { displayName: Translation.tr("Fit content"), icon: "fit_screen", value: "content" },
                        { displayName: Translation.tr("Percent"),     icon: "width",       value: "percent" }
                    ]
                }
                ConfigSpinBox {
                    icon: "width"
                    text: Translation.tr("Width (% of screen)")
                    visible: page.barMode === "mesoBar" && Config.options.mesoBar.widthMode === "percent"
                    value: Config.options.mesoBar.widthPercent
                    from: 20; to: 100; stepSize: 5
                    onValueChanged: { Config.options.mesoBar.widthPercent = value }
                }

                // Shared corner style (all other modes)
                ConfigSelectionArray {
                    text: Translation.tr("Bar style")
                    icon: "style"
                    visible: page.barMode !== "mesoBar" && page.barMode !== "m3Island"
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
                    text: Translation.tr("Group style")
                    icon: "tab_group"
                    visible: page.barMode === "classic"
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
                    text: Translation.tr("Group style")
                    icon: "tab_group"
                    visible: page.barMode === "mesoBar"
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
                    icon: "brush"
                    text: Translation.tr("Group Color")
                    visible: page.barMode === "classic"
                    options: ["primaryContainer", "secondaryContainer", "tertiaryContainer", "layer1", "layer0"]
                    currentValue: Config.options.bar.groupColor
                    onSelected: newValue => { Config.options.bar.groupColor = newValue }
                }

                ConfigRow {
                    uniform: true
                    ConfigSwitch {
                        buttonIcon: "variable_insert"
                        text: Translation.tr("Show Background")
                        checked: page.barMode === "m3Island" ? Config.options.m3Island.showBackground : Config.options.bar.showBackground
                        onCheckedChanged: {
                            if (page.barMode === "m3Island") Config.options.m3Island.showBackground = checked
                            else Config.options.bar.showBackground = checked
                        }
                    }
                    ConfigSelectionArray {
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
                    visible: Config.options.bar.autoHide.enable
                    ConfigSpinBox {
                        icon: "width"
                        text: Translation.tr("Hover Region Width (px)")
                        value: Config.options.bar.autoHide.hoverRegionWidth
                        from: 1; to: 20; stepSize: 1
                        onValueChanged: { Config.options.bar.autoHide.hoverRegionWidth = value }
                    }
                    ConfigSwitch {
                        buttonIcon: "open_with"
                        text: Translation.tr("Push Windows When Hidden")
                        checked: Config.options.bar.autoHide.pushWindows
                        onCheckedChanged: { Config.options.bar.autoHide.pushWindows = checked }
                    }
                    ConfigSwitch {
                        buttonIcon: "keyboard"
                        text: Translation.tr("Show On Super Press")
                        checked: Config.options.bar.autoHide.showWhenPressingSuper.enable
                        onCheckedChanged: { Config.options.bar.autoHide.showWhenPressingSuper.enable = checked }
                    }
                }

                ConfigRow {
                    visible: page.barMode !== "m3Island"
                    ConfigSwitch {
                        buttonIcon: "panorama_wide_angle"
                        text: Translation.tr("Show Frame")
                        checked: Config.options.bar.showFrame
                        property bool switchReady: false
                        Component.onCompleted: Qt.callLater(() => switchReady = true)
                        onCheckedChanged: {
                            if (switchReady && checked) GlobalStates.refreshBar()
                            Config.options.bar.showFrame = checked
                        }
                    }
                    ConfigSwitch {
                        buttonIcon: "colors"
                        enabled: Config.options.bar.showFrame
                        text: Translation.tr("Follow Frame Color")
                        checked: Config.options.bar.followFrameColor
                        onCheckedChanged: { Config.options.bar.followFrameColor = checked }
                    }
                }
                ConfigSpinBox {
                    visible: page.barMode !== "m3Island"
                    icon: "eraser_size_1"
                    text: Translation.tr("Frame thickness")
                    value: Config.options.bar.frameThickness
                    from: 2; to: 10; stepSize: 1
                    onValueChanged: { Config.options.bar.frameThickness = value }
                }
                ColorSelectionArray {
                    visible: page.barMode !== "m3Island"
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
            visible: page.barMode === "mesoBar"
            title: Translation.tr("Mesobar Options")

            GroupedList {
                ConfigRow {
                    ConfigSwitch {
                        buttonIcon: "panorama_wide_angle"
                        text: Translation.tr("Show Frame")
                        checked: Config.options.mesoBar.showFrame
                        property bool switchReady: false
                        Component.onCompleted: Qt.callLater(() => switchReady = true)
                        onCheckedChanged: {
                            if (switchReady && checked) GlobalStates.refreshBar()
                            Config.options.mesoBar.showFrame = checked
                        }
                    }
                    ConfigSwitch {
                        buttonIcon: "colors"
                        enabled: Config.options.mesoBar.showFrame
                        text: Translation.tr("Follow Frame Color")
                        checked: Config.options.mesoBar.followFrameColor
                        onCheckedChanged: { Config.options.mesoBar.followFrameColor = checked }
                    }
                }
                ConfigSpinBox {
                    icon: "eraser_size_1"
                    text: Translation.tr("Frame thickness")
                    value: Config.options.mesoBar.frameThickness
                    from: 2; to: 10; stepSize: 1
                    onValueChanged: { Config.options.mesoBar.frameThickness = value }
                }
                ColorSelectionArray {
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
            visible: page.barMode === "tasklistBar"
            title: Translation.tr("Tasklist Options")

            GroupedList {
                ConfigRow {
                    uniform: true
                    ConfigSwitch {
                        buttonIcon: "label"
                        text: Translation.tr("Show Labels")
                        checked: Config.options.tasklistBar.showLabels
                        onCheckedChanged: { Config.options.tasklistBar.showLabels = checked }
                    }
                }
                ConfigSpinBox {
                    icon: "width"
                    text: Translation.tr("Max Button Width")
                    value: Config.options.tasklistBar.maxButtonWidth
                    from: 40; to: 400; stepSize: 10
                    onValueChanged: { Config.options.tasklistBar.maxButtonWidth = value }
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
            visible: page.barMode === "sysmonitorBar"
            title: Translation.tr("System Monitor Options")

            GroupedList {
                ConfigRow {
                    uniform: true
                    ConfigSwitch {
                        buttonIcon: "planner_review"
                        text: Translation.tr("CPU")
                        checked: Config.options.sysmonitorBar.showCpu
                        onCheckedChanged: { Config.options.sysmonitorBar.showCpu = checked }
                    }
                    ConfigSwitch {
                        buttonIcon: "thermostat"
                        text: Translation.tr("CPU Temperature")
                        checked: Config.options.sysmonitorBar.showCpuTemp
                        onCheckedChanged: { Config.options.sysmonitorBar.showCpuTemp = checked }
                    }
                }
                ConfigRow {
                    uniform: true
                    ConfigSwitch {
                        buttonIcon: "memory"
                        text: Translation.tr("RAM")
                        checked: Config.options.sysmonitorBar.showRam
                        onCheckedChanged: { Config.options.sysmonitorBar.showRam = checked }
                    }
                    ConfigSwitch {
                        buttonIcon: "storage"
                        text: Translation.tr("Disk")
                        checked: Config.options.sysmonitorBar.showDisk
                        onCheckedChanged: { Config.options.sysmonitorBar.showDisk = checked }
                    }
                }
                ConfigRow {
                    uniform: true
                    ConfigSwitch {
                        buttonIcon: "swap_horiz"
                        text: Translation.tr("Swap")
                        checked: Config.options.sysmonitorBar.showSwap
                        onCheckedChanged: { Config.options.sysmonitorBar.showSwap = checked }
                    }
                    ConfigSwitch {
                        buttonIcon: "network_check"
                        text: Translation.tr("Network")
                        checked: Config.options.sysmonitorBar.showNetwork
                        onCheckedChanged: { Config.options.sysmonitorBar.showNetwork = checked }
                    }
                }
                ConfigSpinBox {
                    icon: "memory"
                    text: Translation.tr("RAM warning threshold (%)")
                    value: Config.options.sysmonitorBar.memoryWarningThreshold
                    from: 50; to: 100; stepSize: 1
                    onValueChanged: { Config.options.sysmonitorBar.memoryWarningThreshold = value }
                }
                ConfigSpinBox {
                    icon: "planner_review"
                    text: Translation.tr("CPU warning threshold (%)")
                    value: Config.options.sysmonitorBar.cpuWarningThreshold
                    from: 50; to: 100; stepSize: 1
                    onValueChanged: { Config.options.sysmonitorBar.cpuWarningThreshold = value }
                }
                ConfigSpinBox {
                    icon: "thermostat"
                    text: Translation.tr("Temperature warning threshold (°C)")
                    value: Config.options.sysmonitorBar.tempWarningThreshold
                    from: 50; to: 110; stepSize: 1
                    onValueChanged: { Config.options.sysmonitorBar.tempWarningThreshold = value }
                }
                ConfigSpinBox {
                    icon: "storage"
                    text: Translation.tr("Disk warning threshold (%)")
                    value: Config.options.sysmonitorBar.diskWarningThreshold
                    from: 50; to: 100; stepSize: 1
                    onValueChanged: { Config.options.sysmonitorBar.diskWarningThreshold = value }
                }
                ConfigSpinBox {
                    icon: "swap_horiz"
                    text: Translation.tr("Swap warning threshold (%)")
                    value: Config.options.sysmonitorBar.swapWarningThreshold
                    from: 50; to: 100; stepSize: 1
                    onValueChanged: { Config.options.sysmonitorBar.swapWarningThreshold = value }
                }
            }
        }

        // ── 9. Quick Actions Bar — specific options ───────────────────────────
        ContentSection {
            icon: "tune"
            shape: MaterialShape.Shape.Cookie6Sided
            visible: page.barMode === "quickActionsBar"
            title: Translation.tr("Quick Actions Options")

            GroupedList {
                ConfigRow {
                    uniform: true
                    ConfigSwitch {
                        buttonIcon: "volume_up"
                        text: Translation.tr("Volume Slider")
                        checked: Config.options.quickActionsBar.showVolumeSlider
                        onCheckedChanged: { Config.options.quickActionsBar.showVolumeSlider = checked }
                    }
                    ConfigSwitch {
                        buttonIcon: "brightness_6"
                        text: Translation.tr("Brightness Slider")
                        checked: Config.options.quickActionsBar.showBrightnessSlider
                        onCheckedChanged: { Config.options.quickActionsBar.showBrightnessSlider = checked }
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
                        Layout.fillWidth: true
                        spacing: 4
                        StyledText {
                            text: Translation.tr("Hotspot SSID")
                            font.pixelSize: Appearance.font.pixelSize.smaller
                            color: Appearance.colors.colSubtext
                        }
                        MaterialTextField {
                            Layout.fillWidth: true
                            placeholderText: Hotspot.ssid
                            text: Config.options.quickActionsBar.hotspotSsid
                            onTextChanged: Config.options.quickActionsBar.hotspotSsid = text
                        }
                    }
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 4
                        StyledText {
                            text: Translation.tr("Hotspot Password")
                            font.pixelSize: Appearance.font.pixelSize.smaller
                            color: Appearance.colors.colSubtext
                        }
                        MaterialTextField {
                            Layout.fillWidth: true
                            placeholderText: Hotspot.password
                            text: Config.options.quickActionsBar.hotspotPassword
                            echoMode: TextInput.Password
                            onTextChanged: Config.options.quickActionsBar.hotspotPassword = text
                        }
                    }
                }
            }
        }

        // ── 10. Info Strip — specific options ─────────────────────────────────
        ContentSection {
            icon: "remove"
            shape: MaterialShape.Shape.Cookie6Sided
            visible: page.barMode === "infoStrip"
            title: Translation.tr("Info Strip Options")

            GroupedList {
                ConfigRow {
                    uniform: true
                    ConfigSwitch {
                        buttonIcon: "subtitles"
                        text: Translation.tr("Active Window")
                        checked: Config.options.infoStrip.showActiveWindow
                        onCheckedChanged: { Config.options.infoStrip.showActiveWindow = checked }
                    }
                    ConfigSwitch {
                        buttonIcon: "schedule"
                        text: Translation.tr("Clock")
                        checked: Config.options.infoStrip.showClock
                        onCheckedChanged: { Config.options.infoStrip.showClock = checked }
                    }
                }
                ConfigRow {
                    uniform: true
                    ConfigSwitch {
                        buttonIcon: "memory"
                        text: Translation.tr("CPU Usage")
                        checked: Config.options.infoStrip.showCpuUsage
                        onCheckedChanged: { Config.options.infoStrip.showCpuUsage = checked }
                    }
                    ConfigSwitch {
                        buttonIcon: "planner_review"
                        text: Translation.tr("Memory Usage")
                        checked: Config.options.infoStrip.showMemoryUsage
                        onCheckedChanged: { Config.options.infoStrip.showMemoryUsage = checked }
                    }
                }
                ConfigSwitch {
                    buttonIcon: "notifications"
                    text: Translation.tr("Notification Dot")
                    checked: Config.options.infoStrip.showNotificationDot
                    onCheckedChanged: { Config.options.infoStrip.showNotificationDot = checked }
                }
            }
        }

        // ── 11. Notifications ─────────────────────────────────────────────────
        ContentSection {
            icon: "notifications"
            shape: MaterialShape.Shape.Bun
            title: Translation.tr("Notifications")

            GroupedList {
                ConfigComboBox {
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
                    buttonIcon: "counter_2"
                    text: Translation.tr("Unread indicator: show count")
                    checked: Config.options.bar.indicators.notifications.showUnreadCount
                    onCheckedChanged: { Config.options.bar.indicators.notifications.showUnreadCount = checked }
                }
                ConfigSpinBox {
                    icon: "av_timer"
                    text: Translation.tr("Timeout duration (ms)")
                    value: Config.options.notifications.timeout
                    from: 1000; to: 60000; stepSize: 1000
                    onValueChanged: { Config.options.notifications.timeout = value }
                }
            }
        }

        // ── 12. Tray ──────────────────────────────────────────────────────────
        ContentSection {
            shape: MaterialShape.Shape.Square
            icon: "inbox_customize"
            title: Translation.tr("Tray")

            GroupedList {
                ConfigSwitch {
                    buttonIcon: "keep"
                    text: Translation.tr("Make icons pinned by default")
                    checked: Config.options.tray.invertPinnedItems
                    onCheckedChanged: { Config.options.tray.invertPinnedItems = checked }
                }
                ConfigSwitch {
                    buttonIcon: "colors"
                    text: Translation.tr("Tint icons")
                    checked: Config.options.tray.monochromeIcons
                    onCheckedChanged: { Config.options.tray.monochromeIcons = checked }
                }
            }
        }

        // ── 13. Divider (classic only) ────────────────────────────────────────
        ContentSection {
            icon: "vertical_align_center"
            shape: MaterialShape.Shape.Diamond
            visible: page.barMode === "classic"
            title: Translation.tr("Divider")

            GroupedList {
                ConfigSelectionArray {
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
                    icon: "width"
                    enabled: Config.options.bar.divider.style === "space"
                    text: Translation.tr("Space width (px)")
                    value: Config.options.bar.divider.spacing
                    from: 4; to: 400; stepSize: 2
                    onValueChanged: { Config.options.bar.divider.spacing = value }
                }
            }
        }

        // ── 14. Utility Buttons (classic & mesoBar) ────────────────────────────
        ContentSection {
            icon: "buttons_alt"
            shape: MaterialShape.Shape.SoftBurst
            visible: page.barMode === "classic" || page.barMode === "mesoBar"
            title: Translation.tr("Utility Buttons")

            GroupedList {
                ConfigRow {
                    uniform: true
                    ConfigSwitch {
                        buttonIcon: "screenshot_region"
                        text: Translation.tr("Screen snip")
                        checked: Config.options.bar.utilButtons.showScreenSnip
                        onCheckedChanged: { Config.options.bar.utilButtons.showScreenSnip = checked }
                    }
                    ConfigSwitch {
                        buttonIcon: "colorize"
                        text: Translation.tr("Color picker")
                        checked: Config.options.bar.utilButtons.showColorPicker
                        onCheckedChanged: { Config.options.bar.utilButtons.showColorPicker = checked }
                    }
                }
                ConfigRow {
                    uniform: true
                    ConfigSwitch {
                        buttonIcon: "keyboard"
                        text: Translation.tr("Keyboard toggle")
                        checked: Config.options.bar.utilButtons.showKeyboardToggle
                        onCheckedChanged: { Config.options.bar.utilButtons.showKeyboardToggle = checked }
                    }
                    ConfigSwitch {
                        buttonIcon: "mic"
                        text: Translation.tr("Mic toggle")
                        checked: Config.options.bar.utilButtons.showMicToggle
                        onCheckedChanged: { Config.options.bar.utilButtons.showMicToggle = checked }
                    }
                }
                ConfigRow {
                    uniform: true
                    ConfigSwitch {
                        buttonIcon: "dark_mode"
                        text: Translation.tr("Dark/Light toggle")
                        checked: Config.options.bar.utilButtons.showDarkModeToggle
                        onCheckedChanged: { Config.options.bar.utilButtons.showDarkModeToggle = checked }
                    }
                    ConfigSwitch {
                        buttonIcon: "speed"
                        text: Translation.tr("Performance Profile")
                        checked: Config.options.bar.utilButtons.showPerformanceProfileToggle
                        onCheckedChanged: { Config.options.bar.utilButtons.showPerformanceProfileToggle = checked }
                    }
                }
                ConfigRow {
                    uniform: true
                    ConfigSwitch {
                        buttonIcon: "screen_record"
                        text: Translation.tr("Record Screen")
                        checked: Config.options.bar.utilButtons.showScreenRecord
                        onCheckedChanged: { Config.options.bar.utilButtons.showScreenRecord = checked }
                    }
                    ConfigSwitch {
                        buttonIcon: "imagesmode"
                        text: Translation.tr("Wallpapers Toggle")
                        checked: Config.options.bar.utilButtons.showWallpaperToggle
                        onCheckedChanged: { Config.options.bar.utilButtons.showWallpaperToggle = checked }
                    }
                }
            }
        }

        // ── 15. Workspaces (classic & mesoBar) ─────────────────────────────────
        ContentSection {
            shape: MaterialShape.Shape.Cookie12Sided
            icon: "steppers"
            visible: page.barMode === "classic" || page.barMode === "mesoBar"
            title: Translation.tr("Workspaces")

            GroupedList {
                ConfigSwitch {
                    buttonIcon: "counter_1"
                    text: Translation.tr("Always show numbers")
                    checked: Config.options.bar.workspaces.alwaysShowNumbers
                    onCheckedChanged: { Config.options.bar.workspaces.alwaysShowNumbers = checked }
                }
                ConfigSelectionArray {
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
                    buttonIcon: "award_star"
                    text: Translation.tr("Show app icons")
                    checked: Config.options.bar.workspaces.showAppIcons
                    onCheckedChanged: { Config.options.bar.workspaces.showAppIcons = checked }
                }
                ConfigSpinBox {
                    icon: "view_column"
                    text: Translation.tr("Workspaces shown")
                    value: Config.options.bar.workspaces.shown
                    from: 1; to: 30
                    onValueChanged: { Config.options.bar.workspaces.shown = value }
                }
                ConfigSwitch {
                    buttonIcon: "preview"
                    text: Translation.tr("Show preview on hover")
                    checked: Config.options.overview.hoverPreviewInBar
                    onCheckedChanged: { Config.options.overview.hoverPreviewInBar = checked }
                }
                ConfigSelectionArray {
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
            visible: page.barMode === "classic"
            title: Translation.tr("Resources")

            GroupedList {
                ConfigRow {
                    uniform: true
                    ConfigSwitch {
                        buttonIcon: "planner_review"
                        text: Translation.tr("CPU")
                        checked: Config.options.bar.resources.alwaysShowCpu
                        onCheckedChanged: { Config.options.bar.resources.alwaysShowCpu = checked }
                    }
                    ConfigSwitch {
                        buttonIcon: "thermostat"
                        text: Translation.tr("CPU Temperature")
                        checked: Config.options.bar.resources.alwaysShowCpuTemp
                        onCheckedChanged: { Config.options.bar.resources.alwaysShowCpuTemp = checked }
                    }
                }
                ConfigRow {
                    uniform: true
                    ConfigSwitch {
                        buttonIcon: "memory"
                        text: Translation.tr("RAM")
                        checked: Config.options.bar.resources.alwaysShowRam
                        onCheckedChanged: { Config.options.bar.resources.alwaysShowRam = checked }
                    }
                    ConfigSwitch {
                        buttonIcon: "storage"
                        text: Translation.tr("Disk")
                        checked: Config.options.bar.resources.alwaysShowDisk
                        onCheckedChanged: { Config.options.bar.resources.alwaysShowDisk = checked }
                    }
                }
                ConfigRow {
                    uniform: true
                    ConfigSwitch {
                        buttonIcon: "swap_horiz"
                        text: Translation.tr("Swap")
                        checked: Config.options.bar.resources.alwaysShowSwap
                        onCheckedChanged: { Config.options.bar.resources.alwaysShowSwap = checked }
                    }
                }
                ConfigSelectionArray {
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
                    buttonIcon: "decimal_increase"
                    text: Translation.tr("Show Percentage")
                    checked: Config.options.bar.resources.showValue
                    onCheckedChanged: { Config.options.bar.resources.showValue = checked }
                }
                ConfigSpinBox {
                    icon: "av_timer"
                    text: Translation.tr("Polling interval (ms)")
                    value: Config.options.resources.updateInterval
                    from: 100; to: 10000; stepSize: 100
                    onValueChanged: { Config.options.resources.updateInterval = value }
                }
            }
        }

        // ── 17. Media (classic & mesoBar) ──────────────────────────────────────
        ContentSection {
            icon: "music_note"
            shape: MaterialShape.Shape.Sunny
            visible: page.barMode === "classic" || page.barMode === "mesoBar"
            title: Translation.tr("Media")

            GroupedList {
                ConfigTextArea {
                    id: preferredPlayerField
                    Layout.fillWidth: true
                    buttonIcon: "play_circle"
                    text: Translation.tr("Preferred Player")
                    placeholderText: Translation.tr("e.g. spotify, firefox")
                    value: Config.options.bar.media.preferredPlayer
                    onValueChanged: { mediaDebounceTimer.restart() }

                    Timer {
                        id: mediaDebounceTimer
                        interval: 600
                        repeat: false
                        onTriggered: { Config.options.bar.media.preferredPlayer = preferredPlayerField.value }
                    }
                }
                ConfigSwitch {
                    buttonIcon: "keep"
                    text: Translation.tr("Pin media controls")
                    checked: Config.options.bar.media.alwaysVisible
                    onCheckedChanged: { Config.options.bar.media.alwaysVisible = checked }
                }
                ConfigSwitch {
                    buttonIcon: "titlecase"
                    text: Translation.tr("Show only title")
                    checked: Config.options.bar.media.onlyTitle
                    onCheckedChanged: { Config.options.bar.media.onlyTitle = checked }
                }
                ConfigSpinBox {
                    icon: "width"
                    text: Translation.tr("Max media width")
                    value: Config.options.bar.media.maxWidth
                    from: 100; to: 500; stepSize: 10
                    onValueChanged: { Config.options.bar.media.maxWidth = value }
                }
            }
        }

        // ── 18. Tooltips ──────────────────────────────────────────────────────
        ContentSection {
            shape: MaterialShape.Shape.Puffy
            icon: "tooltip"
            title: Translation.tr("Tooltips")

            GroupedList {
                ConfigSwitch {
                    buttonIcon: "ads_click"
                    text: Translation.tr("Click to show")
                    checked: Config.options.bar.tooltips.clickToShow
                    onCheckedChanged: { Config.options.bar.tooltips.clickToShow = checked }
                }
            }
        }
    }
}
