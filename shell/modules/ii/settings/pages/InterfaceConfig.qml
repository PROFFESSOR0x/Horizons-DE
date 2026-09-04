import QtQuick
import QtQuick.Layouts
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets

ContentPage {
    id: page
    forceWidth: true

    // Background widget types that can be independently shown/hidden on the
    // lock screen via Config.options.lock.enabledWidgets, keyed by their
    // qs.modules.ii.background.widgets configEntryName.
    readonly property var lockWidgetOptions: [
        { name: "clock", label: Translation.tr("Clock"), icon: "schedule" },
        { name: "weather", label: Translation.tr("Weather"), icon: "partly_cloudy_day" },
        { name: "calendar", label: Translation.tr("Calendar"), icon: "calendar_month" },
        { name: "worldClock", label: Translation.tr("World clock"), icon: "public" },
        { name: "notes", label: Translation.tr("Notes"), icon: "sticky_note_2" },
        { name: "todo", label: Translation.tr("To-do list"), icon: "checklist" },
        { name: "userCard", label: Translation.tr("User card"), icon: "badge" },
        { name: "media", label: Translation.tr("Media player"), icon: "music_note" },
        { name: "timers", label: Translation.tr("Timers"), icon: "timer" },
        { name: "images", label: Translation.tr("Images"), icon: "image" },
        { name: "visualizer", label: Translation.tr("Audio visualizer"), icon: "graphic_eq" },
        { name: "customImage", label: Translation.tr("Custom image"), icon: "photo" },
        { name: "resources", label: Translation.tr("System resources"), icon: "monitoring" },
        { name: "networkInfo", label: Translation.tr("Network info"), icon: "wifi" },
        { name: "uptime", label: Translation.tr("Uptime"), icon: "hourglass_top" },
        { name: "systemHistory", label: Translation.tr("System history graphs"), icon: "monitor_heart" }
    ]

    function isLockWidgetEnabled(name) {
        const arr = Config.options.lock.enabledWidgets;
        return arr.length === 0 || arr.indexOf(name) !== -1;
    }

    function setLockWidgetEnabled(name, on) {
        const allNames = page.lockWidgetOptions.map(w => w.name);
        let current = Config.options.lock.enabledWidgets.length === 0
            ? allNames.slice()
            : Config.options.lock.enabledWidgets.slice();
        if (on) {
            if (current.indexOf(name) === -1) current.push(name);
        } else {
            current = current.filter(n => n !== name);
        }
        Config.options.lock.enabledWidgets = current;
    }

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

    ColumnLayout {
        id: mainLayout 
        Layout.fillWidth: true   
        Layout.fillHeight: true
        spacing: 20

        ContentSection {
            icon: "palette"
            shape: MaterialShape.Shape.Cookie7Sided
            title: Translation.tr("Appearance")
            GroupedList {
                ConfigSwitch {
                    buttonIcon: "format_paint"
                    text: Translation.tr("Extra Background Tint")
                    checked: Config.options.appearance.extraBackgroundTint
                    onCheckedChanged: { Config.options.appearance.extraBackgroundTint = checked }
                }
                ConfigSelectionArray {
                    text: Translation.tr("Fake Screen Rounding")
                    icon: "rounded_corner"
                    currentValue: Config.options.appearance.fakeScreenRounding
                    onSelected: v => { Config.options.appearance.fakeScreenRounding = v }
                    options: [
                        { displayName: Translation.tr("None"), icon: "block", value: 0 },
                        { displayName: Translation.tr("Always"), icon: "check", value: 1 },
                        { displayName: Translation.tr("When not fullscreen"), icon: "fullscreen_exit", value: 2 }
                    ]
                }
            }
            ContentSubsection {
                title: Translation.tr("Visual Effect")
                tooltip: Translation.tr("Blur, transparency and Liquid Glass all change how panels look and don't layer well together, so only one can be active at a time. Choosing one here automatically turns the other two off.")
                GroupedList {
                    ConfigSelectionArray {
                        icon: "styles"
                        text: Translation.tr("Panel style")
                        currentValue: Config.options.appearance.visualEffect
                        onSelected: newValue => {
                            Config.options.appearance.visualEffect = newValue;
                            Config.applyVisualEffectExclusivity(newValue);
                            HyprlandConfig.set("decoration:blur:enabled", Config.options.hyprland.decoration.blur.enabled ? 1 : 0);
                            HyprlandConfig.set("decoration:blur:variant", Config.options.hyprland.decoration.blur.variant);
                        }
                        options: [
                            { displayName: Translation.tr("None"), icon: "block", value: "none" },
                            { displayName: Translation.tr("Blur"), icon: "blur_on", value: "blur" },
                            { displayName: Translation.tr("Transparency"), icon: "opacity", value: "transparency" },
                            { displayName: Translation.tr("Liquid Glass"), icon: "water_drop", value: "glass" }
                        ]
                    }
                }
            }
            ContentSubsection {
                title: Translation.tr("Window Transparency (for Blur/Glass)")
                visible: Config.options.appearance.visualEffect === "blur" || Config.options.appearance.visualEffect === "glass"
                GroupedList {
                    ConfigSwitch {
                        buttonIcon: "opacity"
                        text: Translation.tr("Make regular app windows slightly transparent")
                        checked: Config.options.hyprland.decoration.activeOpacity < 1.0
                        onCheckedChanged: {
                            if (checked === (Config.options.hyprland.decoration.activeOpacity < 1.0)) return
                            if (checked) {
                                Config.options.hyprland.decoration.activeOpacity = 0.95
                                Config.options.hyprland.decoration.inactiveOpacity = 0.85
                            } else {
                                Config.options.hyprland.decoration.activeOpacity = 1.0
                                Config.options.hyprland.decoration.inactiveOpacity = 1.0
                            }
                            HyprlandConfig.set("decoration:active_opacity", Config.options.hyprland.decoration.activeOpacity)
                            HyprlandConfig.set("decoration:inactive_opacity", Config.options.hyprland.decoration.inactiveOpacity)
                        }
                    }
                    StyledText {
                        Layout.fillWidth: true
                        wrapMode: Text.Wrap
                        color: Appearance.colors.colSubtext
                        font.pixelSize: Appearance.font.pixelSize.small
                        text: Translation.tr("Blur/Glass only shows through a window that isn't fully opaque — a normal app window has no transparency of its own, so the effect stays invisible on it even though it now applies compositor-wide. This gives every window (focused and unfocused) a modest default transparency so Blur/Glass is visible everywhere without hand-writing a windowrulev2 opacity rule per app. Off by default — no visual change until you turn it on. Fine-tune the exact amounts under Settings > Hyprland > Decoration (\"Active/Inactive Opacity\"), or exclude specific apps there via Window Rules.")
                    }
                }
            }
            ContentSubsection {
                title: Translation.tr("Transparency")
                visible: Config.options.appearance.visualEffect === "transparency"
                GroupedList {
                    ConfigSwitch {
                        buttonIcon: "auto_awesome"
                        text: Translation.tr("Automatic (disables Background slider)")
                        enabled: Config.options.appearance.transparency.enable
                        checked: Config.options.appearance.transparency.automatic
                        onCheckedChanged: { Config.options.appearance.transparency.automatic = checked }
                    }
                    ConfigSlider {
                        text: Translation.tr("Background")
                        textWidth: 110
                        buttonIcon: "wallpaper"
                        enabled: Config.options.appearance.transparency.enable && !Config.options.appearance.transparency.automatic
                        value: Config.options.appearance.transparency.backgroundTransparency * 100
                        from: 0; to: 50
                        onValueChanged: { Config.options.appearance.transparency.backgroundTransparency = value / 100 }
                    }
                    ConfigSlider {
                        text: Translation.tr("Content")
                        textWidth: 110
                        buttonIcon: "layers"
                        enabled: Config.options.appearance.transparency.enable
                        value: Config.options.appearance.transparency.contentTransparency * 100
                        from: 0; to: 100
                        onValueChanged: { Config.options.appearance.transparency.contentTransparency = value / 100 }
                    }
                }
            }
            ContentSubsection {
                title: Translation.tr("Liquid Glass")
                visible: Config.options.appearance.visualEffect === "glass"
                GroupedList {
                    ConfigSlider {
                        text: Translation.tr("Glass opacity")
                        textWidth: 110
                        buttonIcon: "opacity"
                        enabled: Config.options.appearance.glass.enable
                        value: Config.options.appearance.glass.opacity * 100
                        from: 35; to: 95
                        onValueChanged: { Config.options.appearance.glass.opacity = value / 100 }
                    }
                    StyledText {
                        Layout.fillWidth: true
                        wrapMode: Text.Wrap
                        color: Appearance.colors.colSubtext
                        font.pixelSize: Appearance.font.pixelSize.small
                        text: Translation.tr("Liquid Glass is Hyprland's native \"acrylic\" blur variant, applied compositor-wide to every window. Fine-tune refraction, tint and the other blur styles under Settings > Hyprland > Blur Style.")
                    }
                }
            }
            ContentSubsection {
                title: Translation.tr("Motion")
                GroupedList {
                    ConfigSelectionArray {
                        text: Translation.tr("Animation style")
                        icon: "animation"
                        currentValue: Config.options.appearance.motion.style
                        onSelected: value => { Config.options.appearance.motion.style = value }
                        options: [
                            { displayName: Translation.tr("Smooth"), icon: "water", value: "smooth" },
                            { displayName: Translation.tr("Expressive"), icon: "auto_awesome", value: "expressive" }
                        ]
                    }
                    ConfigSlider {
                        text: Translation.tr("Animation speed")
                        textWidth: 110
                        buttonIcon: "slow_motion_video"
                        value: Config.options.appearance.motion.durationScale * 100
                        from: 50; to: 200
                        onValueChanged: { Config.options.appearance.motion.durationScale = value / 100 }
                    }
                }
            }
            ContentSubsection {
                title: Translation.tr("Palette")
                GroupedList {
                    ConfigComboBox {
                        text: Translation.tr("Palette Type")
                        buttonIcon: "palette"
                        currentValue: Config.options.appearance.palette.type
                        onSelected: v => { Config.options.appearance.palette.type = v }
                        model: [
                            { displayName: "Auto", display: "Auto", value: "auto" },
                            { displayName: "Tonal Spot", display: "Tonal Spot", value: "scheme-tonal-spot" },
                            { displayName: "Expressive", display: "Expressive", value: "scheme-expressive" },
                            { displayName: "Vibrant", display: "Vibrant", value: "scheme-vibrant" },
                            { displayName: "Rainbow", display: "Rainbow", value: "scheme-rainbow" },
                            { displayName: "Fruit Salad", display: "Fruit Salad", value: "scheme-fruit-salad" },
                            { displayName: "Monochrome", display: "Monochrome", value: "scheme-monochrome" }
                        ]
                    }
                    ConfigTextArea {
                        id: accentColorField
                        Layout.fillWidth: true
                        buttonIcon: "colorize"
                        text: Translation.tr("Accent Color (hex, empty=auto)")
                        placeholderText: "#ff0000"
                        value: Config.options.appearance.palette.accentColor
                        onValueChanged: accentDebounce.restart()
                        Timer { id: accentDebounce; interval: 800; onTriggered: Config.options.appearance.palette.accentColor = accentColorField.value }
                    }
                }
            }
        }

        ContentSection {
            icon: "settings"
            shape: MaterialShape.Shape.SoftBurst
            title: Translation.tr("Settings Panel")
            GroupedList {
                ConfigSelectionArray {
                    text: Translation.tr("Style")
                    icon: "style"
                    currentValue: Config.options.settings.style
                    onSelected: newValue => { Config.options.settings.style = newValue }
                    options: [
                        { displayName: Translation.tr("Default"), icon: "settings_panorama", value: "default" },
                        { displayName: Translation.tr("Minimal"), icon: "settings_heart", value: "minimal" }
                    ]
                }
                ConfigSpinBox {
                    icon: "border_style"
                    text: Translation.tr("Border width")
                    value: Config.options.settings.borderSize
                    from: 0
                    to: 10
                    stepSize: 1
                    onValueChanged: { Config.options.settings.borderSize = value }
                }
                ColorSelectionArray {
                    icon: "format_paint"
                    text: Translation.tr("Border Color")
                    options: ["primary", "secondary", "tertiary", "primaryContainer", "secondaryContainer", "tertiaryContainer", "layer0Border"]
                    currentValue: Config.options.settings.borderColor 
                    onSelected: newValue => {
                        Config.options.settings.borderColor = newValue
                    }
                }
            } 
        }

        ContentSection {
            icon: "splitscreen_left"
            shape: MaterialShape.Shape.Clover4Leaf
            title: Translation.tr("Left Sidebar")

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    implicitHeight: mediaCol.implicitHeight + 24
                    radius: Appearance.rounding.normal
                    color: Appearance.colors.colLayer1
                    border.width: 1
                    border.color: "transparent"

                    ColumnLayout {
                        id: mediaCol
                        anchors { fill: parent; margins: 12 }
                        spacing: 8

                        MaterialSymbol {
                            text: "music_note_2"
                            iconSize: Appearance.font.pixelSize.huge
                            color: Appearance.colors.colPrimary
                        }
                        StyledText {
                            text: Translation.tr("Media Player")
                            font.pixelSize: Appearance.font.pixelSize.normal
                            font.weight: Font.Medium
                            color: Appearance.colors.colOnLayer1
                        }
                        Item { Layout.fillHeight: true }
                        GroupedList {
                            Layout.fillWidth: true
                            bgcolor: Appearance.colors.colLayer2
                            ConfigSwitch {
                                buttonIcon: "check"
                                text: Translation.tr("Enable")
                                checked: Config.options.sidebar.media.enable
                                onCheckedChanged: { Config.options.sidebar.media.enable = checked }
                            }
                            ConfigSwitch {
                                buttonIcon: "radio_button_partial"
                                text: Translation.tr("Follow Album Colors")
                                checked: Config.options.sidebar.media.artColors
                                onCheckedChanged: { Config.options.sidebar.media.artColors = checked }
                            }
                        }
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: aiCol.implicitHeight + 24
                        radius: Appearance.rounding.normal
                        color: Appearance.colors.colLayer1
                        border.width: 1
                        border.color: "transparent"

                        ColumnLayout {
                            id: aiCol
                            anchors { fill: parent; margins: 12 }
                            spacing: 8

                            MaterialSymbol {
                                text: "smart_toy"
                                iconSize: Appearance.font.pixelSize.huge
                                color: Appearance.colors.colPrimary
                            }
                            StyledText {
                                text: Translation.tr("AI")
                                font.pixelSize: Appearance.font.pixelSize.normal
                                font.weight: Font.Medium
                                color: Appearance.colors.colOnLayer1
                            }
                            ConfigSelectionArray {
                                Layout.fillWidth: false
                                Layout.alignment: Qt.AlignRight
                                currentValue: Config.options.policies.ai
                                onSelected: newValue => { Config.options.policies.ai = newValue }
                                options: [
                                    { displayName: Translation.tr("No"), icon: "close", value: 0 },
                                    { displayName: Translation.tr("Yes"), icon: "check", value: 1 },
                                    { displayName: Translation.tr("Local"), icon: "sync_saved_locally", value: 2 }
                                ]
                            }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: weebCol.implicitHeight + 24
                        radius: Appearance.rounding.normal
                        color: Appearance.colors.colLayer1
                        border.width: 1
                        border.color: "transparent"

                        ColumnLayout {
                            id: weebCol
                            anchors { fill: parent; margins: 12 }
                            spacing: 8

                            MaterialSymbol {
                                text: "playing_cards"
                                iconSize: Appearance.font.pixelSize.huge
                                color: Appearance.colors.colPrimary
                            }
                            StyledText {
                                text: Translation.tr("Weeb")
                                font.pixelSize: Appearance.font.pixelSize.normal
                                font.weight: Font.Medium
                                color: Appearance.colors.colOnLayer1
                            }
                            ConfigSelectionArray {
                                Layout.fillWidth: false
                                Layout.alignment: Qt.AlignRight
                                currentValue: Config.options.policies.weeb
                                onSelected: newValue => { Config.options.policies.weeb = newValue }
                                options: [
                                    { displayName: Translation.tr("No"), icon: "close", value: 0 },
                                    { displayName: Translation.tr("Yes"), icon: "check", value: 1 },
                                    { displayName: Translation.tr("Closet"), icon: "ev_shadow", value: 2 }
                                ]
                            }
                        }
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.topMargin: 4
                implicitHeight: translatorCol.implicitHeight + 24
                radius: Appearance.rounding.normal
                color: Appearance.colors.colLayer1
                border.width: 1
                border.color: "transparent"

                ColumnLayout {
                    id: translatorCol
                    anchors { fill: parent; margins: 12 }
                    spacing: 8

                    RowLayout {
                        spacing: 8
                        ConfigSwitch {
                            buttonIcon: "translate"
                            text: Translation.tr("Enable Translator")
                            checked: Config.options.sidebar.translator.enable
                            onCheckedChanged: { Config.options.sidebar.translator.enable = checked }
                        }
                    }
                }
            }
        }

        ContentSection {
            icon: "splitscreen_right"
            shape: MaterialShape.Shape.Slanted
            title: Translation.tr("Right Sidebar")

            GroupedList {
                ConfigSwitch {
                    buttonIcon: "planner_banner_ad_pt"
                    text: Translation.tr('Banner')
                    checked: Config.options.sidebar.banner
                    onCheckedChanged: {
                        Config.options.sidebar.banner = checked;
                    }
                }

                ConfigSwitch {
                    buttonIcon: "bottom_navigation"
                    text: Translation.tr('Bottom Group')
                    checked: Config.options.sidebar.bottomGroup
                    onCheckedChanged: {
                        Config.options.sidebar.bottomGroup = checked;
                    }
                }

                ConfigSwitch {
                    buttonIcon: "music_note"
                    text: Translation.tr('Media Player')
                    checked: Config.options.sidebar.mediaPlayer
                    onCheckedChanged: {
                        Config.options.sidebar.mediaPlayer = checked;
                    }
                }

                ConfigSwitch {
                    buttonIcon: "memory"
                    text: Translation.tr('Keep right sidebar loaded')
                    checked: Config.options.sidebar.keepRightSidebarLoaded
                    onCheckedChanged: {
                        Config.options.sidebar.keepRightSidebarLoaded = checked;
                    }
                }
            }

            ContentSubsection {
                title: Translation.tr("Quick toggles")
                GroupedList {
                    ConfigSelectionArray {
                        text: Translation.tr("Style")
                        icon: "toggle_on"
                        Layout.fillWidth: false
                        currentValue: Config.options.sidebar.quickToggles.style
                        onSelected: newValue => {
                            Config.options.sidebar.quickToggles.style = newValue;
                        }
                        options: [
                            {
                                displayName: Translation.tr("Classic"),
                                icon: "password_2",
                                value: "classic"
                            },
                            {
                                displayName: Translation.tr("Android"),
                                icon: "action_key",
                                value: "android"
                            }
                        ]
                    }
                    ConfigSpinBox {
                        enabled: Config.options.sidebar.quickToggles.style === "android"
                        icon: "add_column_left"
                        text: Translation.tr("Columns")
                        value: Config.options.sidebar.quickToggles.android.columns
                        from: 1
                        to: 8
                        stepSize: 1
                        onValueChanged: {
                            Config.options.sidebar.quickToggles.android.columns = value;
                        }
                    }
                }
            }

            ContentSubsection {
                title: Translation.tr("Sliders")
                GroupedList {
                    ConfigSwitch {
                        buttonIcon: "check"
                        text: Translation.tr("Enable")
                        checked: Config.options.sidebar.quickSliders.enable
                        onCheckedChanged: {
                            Config.options.sidebar.quickSliders.enable = checked;
                        }
                    }

                    ConfigSwitch {
                        buttonIcon: "brightness_6"
                        text: Translation.tr("Brightness")
                        enabled: Config.options.sidebar.quickSliders.enable
                        checked: Config.options.sidebar.quickSliders.showBrightness
                        onCheckedChanged: {
                            Config.options.sidebar.quickSliders.showBrightness = checked;
                        }
                    }

                    ConfigSwitch {
                        buttonIcon: "volume_up"
                        text: Translation.tr("Volume")
                        enabled: Config.options.sidebar.quickSliders.enable
                        checked: Config.options.sidebar.quickSliders.showVolume
                        onCheckedChanged: {
                            Config.options.sidebar.quickSliders.showVolume = checked;
                        }
                    }

                    ConfigSwitch {
                        buttonIcon: "mic"
                        text: Translation.tr("Microphone")
                        enabled: Config.options.sidebar.quickSliders.enable
                        checked: Config.options.sidebar.quickSliders.showMic
                        onCheckedChanged: {
                            Config.options.sidebar.quickSliders.showMic = checked;
                        }
                    }
                }
            }
        }

        ContentSection {
            icon: "screenshot_frame_2"
            shape: MaterialShape.Shape.Gem
            title: Translation.tr("Hot Corners")

            ContentSubsection {
                title: Translation.tr("Top")

                GroupedList {
                    ConfigSwitch {
                        buttonIcon: "check"
                        text: Translation.tr("Enable")
                        checked: Config.options.sidebar.cornerOpen.enable
                        onCheckedChanged: { Config.options.sidebar.cornerOpen.enable = checked }
                    }
                    ConfigSwitch {
                        buttonIcon: "highlight_mouse_cursor"
                        text: Translation.tr("Hover to trigger")
                        checked: Config.options.sidebar.cornerOpen.clickless
                        onCheckedChanged: { Config.options.sidebar.cornerOpen.clickless = checked }
                    }
                    ConfigSwitch {
                        buttonIcon: "vertical_align_bottom"
                        text: Translation.tr("Place at bottom")
                        checked: Config.options.sidebar.cornerOpen.bottom
                        onCheckedChanged: { Config.options.sidebar.cornerOpen.bottom = checked }
                    }
                    ConfigSwitch {
                        buttonIcon: "unfold_more_double"
                        text: Translation.tr("Value scroll")
                        checked: Config.options.sidebar.cornerOpen.valueScroll
                        onCheckedChanged: { Config.options.sidebar.cornerOpen.valueScroll = checked }
                    }
                    ConfigSwitch {
                        buttonIcon: "visibility"
                        text: Translation.tr("Visualize region")
                        checked: Config.options.sidebar.cornerOpen.visualize
                        onCheckedChanged: { Config.options.sidebar.cornerOpen.visualize = checked }
                    }
                    ConfigSwitch {
                        enabled: Config.options.sidebar.cornerOpen.clickless
                        buttonIcon: "ads_click"
                        text: Translation.tr("Force hover at absolute corner")
                        checked: Config.options.sidebar.cornerOpen.clicklessCornerEnd
                        onCheckedChanged: { Config.options.sidebar.cornerOpen.clicklessCornerEnd = checked }
                    }
                    ConfigSwitch {
                        enabled: Config.options.sidebar.cornerOpen.clickless
                        buttonIcon: "select_all"
                        text: Translation.tr("Enable hover trigger on bottom corners")
                        checked: Config.options.sidebar.cornerOpen.hoverAllCorners
                        onCheckedChanged: { Config.options.sidebar.cornerOpen.hoverAllCorners = checked }
                    }
                    ConfigSpinBox {
                        enabled: Config.options.sidebar.cornerOpen.clickless
                        icon: "arrow_cool_down"
                        text: Translation.tr("Vertical offset")
                        value: Config.options.sidebar.cornerOpen.clicklessCornerVerticalOffset
                        from: 0; to: 20; stepSize: 1
                        onValueChanged: { Config.options.sidebar.cornerOpen.clicklessCornerVerticalOffset = value }
                    }
                    ConfigSpinBox {
                        icon: "arrow_range"
                        text: Translation.tr("Region width")
                        value: Config.options.sidebar.cornerOpen.cornerRegionWidth
                        from: 1; to: 300; stepSize: 1
                        onValueChanged: { Config.options.sidebar.cornerOpen.cornerRegionWidth = value }
                    }
                    ConfigSpinBox {
                        icon: "height"
                        text: Translation.tr("Region height")
                        value: Config.options.sidebar.cornerOpen.cornerRegionHeight
                        from: 1; to: 300; stepSize: 1
                        onValueChanged: { Config.options.sidebar.cornerOpen.cornerRegionHeight = value }
                    }
                    ConfigComboBox {
                        Layout.fillWidth: true
                        buttonIcon: "position_top_left"
                        text: Translation.tr("Top-left action")
                        textRole: "displayName"
                        fieldWidth: 55
                        model: GlobalStates.hotCornerOptions
                        currentValue: Config.options.sidebar.cornerOpen.topLeftAction
                        onSelected: newValue => Config.options.sidebar.cornerOpen.topLeftAction = newValue
                    }
                    ConfigComboBox {
                        Layout.fillWidth: true
                        buttonIcon: "position_top_right"
                        text: Translation.tr("Top-right action")
                        textRole: "displayName"
                        fieldWidth: 55
                        model: GlobalStates.hotCornerOptions
                        currentValue: Config.options.sidebar.cornerOpen.topRightAction
                        onSelected: newValue => Config.options.sidebar.cornerOpen.topRightAction = newValue
                    }
                    ConfigSelectionArray {
                        icon: "swipe"
                        text: Translation.tr("Left-corner scroll")
                        currentValue: Config.options.sidebar.cornerOpen.leftScrollAction
                        onSelected: newValue => Config.options.sidebar.cornerOpen.leftScrollAction = newValue
                        options: [
                            { displayName: Translation.tr("Brightness"), icon: "brightness_6", value: "brightness" },
                            { displayName: Translation.tr("Volume"), icon: "volume_up", value: "volume" }
                        ]
                    }
                    ConfigSelectionArray {
                        icon: "swipe"
                        text: Translation.tr("Right-corner scroll")
                        currentValue: Config.options.sidebar.cornerOpen.rightScrollAction
                        onSelected: newValue => Config.options.sidebar.cornerOpen.rightScrollAction = newValue
                        options: [
                            { displayName: Translation.tr("Volume"), icon: "volume_up", value: "volume" },
                            { displayName: Translation.tr("Brightness"), icon: "brightness_6", value: "brightness" }
                        ]
                    }
                }
            }
            ContentSubsection {
                title: Translation.tr("Bottom")
                GroupedList {
                    ConfigComboBox {
                        Layout.fillWidth: true
                        buttonIcon: "position_bottom_left"
                        text: Translation.tr("Bottom-left")
                        textRole: "displayName"
                        fieldWidth: 50
                        model: GlobalStates.hotCornerOptions
                        currentValue: Config.options.sidebar.cornerOpen.bottomLeftAction
                        onSelected: newValue => { Config.options.sidebar.cornerOpen.bottomLeftAction = newValue }
                    }
                    ConfigComboBox {
                        Layout.fillWidth: true
                        buttonIcon: "position_bottom_right"
                        text: Translation.tr("Bottom-right")
                        textRole: "displayName"
                        fieldWidth: 55
                        model: GlobalStates.hotCornerOptions
                        currentValue: Config.options.sidebar.cornerOpen.bottomRightAction
                        onSelected: newValue => { Config.options.sidebar.cornerOpen.bottomRightAction = newValue }
                    }
                }
            }
        }
    
        ContentSection { // I see that for many the overview is important, I put it first why not
            visible: WM.compositor !== "niri"
            icon: "overview_key"
            shape: MaterialShape.Shape.Gem
            title: Translation.tr("Overview")

            GroupedList {
                ConfigSwitch {
                    buttonIcon: "workspaces"
                    text: Translation.tr("Show workspaces in launcher (SUPER)")
                    checked: Config.options.overview.showWorkspacesInLauncher
                    onCheckedChanged: { Config.options.overview.showWorkspacesInLauncher = checked }
                }
                ConfigSwitch {
                    buttonIcon: "visibility"
                    text: Translation.tr("Show preview on hover over workspaces in bar")
                    checked: Config.options.overview.hoverPreviewInBar
                    onCheckedChanged: { Config.options.overview.hoverPreviewInBar = checked }
                }
                ConfigComboBox {
                    text: Translation.tr("Launcher Position")
                    buttonIcon: "vertical_align_top"
                    currentValue: Config.options.overview.position ?? "top"
                    onSelected: newValue => { Config.options.overview.position = newValue }
                    model: [
                        { displayName: Translation.tr("Top"), display: Translation.tr("Top - results below"), value: "top" },
                        { displayName: Translation.tr("Bottom"), display: Translation.tr("Bottom - results above"), value: "bottom" },
                        { displayName: Translation.tr("Center"), display: Translation.tr("Center - centered"), value: "center" }
                    ]
                }
                ConfigSwitch {
                    buttonIcon: "animation"
                    text: Translation.tr("Animate center position")
                    checked: Config.options.overview.centerAnimation ?? true
                    onCheckedChanged: { Config.options.overview.centerAnimation = checked }
                }
                ConfigSlider {
                    text: Translation.tr("Center animation delay (ms)")
                    textWidth: 180
                    buttonIcon: "timer"
                    enabled: Config.options.overview.centerAnimation ?? true
                    value: Config.options.overview.centerAnimationDuration ?? 220
                    from: 0; to: 600
                    onValueChanged: { Config.options.overview.centerAnimationDuration = Math.round(value) }
                }
                ConfigSwitch {
                    buttonIcon: "check"
                    text: Translation.tr("Enable")
                    checked: Config.options.overview.enable
                    onCheckedChanged: {
                        Config.options.overview.enable = checked;
                    }
                }
                ConfigSwitch {
                    buttonIcon: "center_focus_strong"
                    text: Translation.tr("Center icons")
                    checked: Config.options.overview.centerIcons
                    onCheckedChanged: {
                        Config.options.overview.centerIcons = checked;
                    }
                }
                ConfigSpinBox {
                    icon: "loupe"
                    text: Translation.tr("Scale (%)")
                    value: Config.options.overview.scale * 100
                    from: 1
                    to: 100
                    stepSize: 1
                    onValueChanged: {
                        Config.options.overview.scale = value / 100;
                    }
                }
                ConfigSelectionArray {
                    text: Translation.tr("Style")
                    icon: "style"
                    currentValue: Config.options.overview.style
                    onSelected: newValue => {
                        Config.options.overview.style = newValue
                    }
                    options: [
                        {
                            displayName: Translation.tr("Default"),
                            icon: "grid_on",
                            value: "default"
                        },
                        {
                            displayName: Translation.tr("Niri Like"),
                            icon: "mobiledata_arrows",
                            value: "niri"
                        }
                    ]
                }
            }

            ContentSubsection {
                title: Translation.tr("Default Settings")
                visible: Config.options.overview.style !== "niri"

                GroupedList {
                    visible: Config.options.overview.style !== "niri"
                    ConfigRow {
                        uniform: true
                        visible: Config.options.overview.style !== "niri"
                        ConfigSpinBox {
                            icon: "splitscreen_bottom"
                            text: Translation.tr("Rows")
                            value: Config.options.overview.rows
                            from: 1
                            to: 20
                            stepSize: 1
                            onValueChanged: {
                                Config.options.overview.rows = value;
                            }
                        }
                        ConfigSpinBox {
                            icon: "splitscreen_right"
                            text: Translation.tr("Columns")
                            value: Config.options.overview.columns
                            from: 1
                            to: 20
                            stepSize: 1
                            onValueChanged: {
                                Config.options.overview.columns = value;
                            }
                        }
                    }

                    ConfigRow {
                        uniform: true
                        visible: Config.options.overview.style !== "niri"
                        Layout.alignment: Qt.AlignHCenter
                        Layout.leftMargin: 24
                        ConfigSelectionArray {
                            Layout.alignment: Qt.AlignHCenter
                            currentValue: Config.options.overview.orderRightLeft
                            onSelected: newValue => {
                                Config.options.overview.orderRightLeft = newValue
                            }
                            options: [
                                {
                                    displayName: Translation.tr("Left to right"),
                                    icon: "arrow_forward",
                                    value: 0
                                },
                                {
                                    displayName: Translation.tr("Right to left"),
                                    icon: "arrow_back",
                                    value: 1
                                }
                            ]
                        }
                        ConfigSelectionArray {
                            Layout.alignment: Qt.AlignHCenter
                            currentValue: Config.options.overview.orderBottomUp
                            onSelected: newValue => {
                                Config.options.overview.orderBottomUp = newValue
                            }
                            options: [
                                {
                                    displayName: Translation.tr("Top-down"),
                                    icon: "arrow_downward",
                                    value: 0
                                },
                                {
                                    displayName: Translation.tr("Bottom-up"),
                                    icon: "arrow_upward",
                                    value: 1
                                }
                            ]
                        }
                    }
                }
            }
        }

        ContentSection {
            icon: "call_to_action"
            title: Translation.tr("Dock")
            shape: MaterialShape.Shape.Cookie6Sided

            GroupedList {
                ConfigSwitch {
                    buttonIcon: "check"
                    text: Translation.tr("Enable")
                    checked: Config.options.dock.enable
                    onCheckedChanged: { Config.options.dock.enable = checked }
                }
                ConfigSwitch {
                    buttonIcon: "background_dot_small"
                    text: Translation.tr("Background")
                    checked: Config.options.dock.showBackground
                    onCheckedChanged: { Config.options.dock.showBackground = checked }
                }
                ConfigSwitch {
                    buttonIcon: "highlight_mouse_cursor"
                    text: Translation.tr("Hover to reveal")
                    checked: Config.options.dock.hoverToReveal
                    onCheckedChanged: { Config.options.dock.hoverToReveal = checked }
                }
                ConfigSwitch {
                    buttonIcon: "push_pin"
                    text: Translation.tr("Pinned on startup")
                    checked: Config.options.dock.pinnedOnStartup
                    onCheckedChanged: { Config.options.dock.pinnedOnStartup = checked }
                }
            }


            ContentSubsection {
                title: Translation.tr("Buttons & Media")
                GroupedList {
                    ConfigSwitch {
                        buttonIcon: "music_note"
                        text: Translation.tr("Media Player")
                        checked: Config.options.dock.showMedia
                        onCheckedChanged: { Config.options.dock.showMedia = checked }
                    }
                    ConfigSwitch {
                        buttonIcon: "keep"
                        text: Translation.tr("Show Pin Button")
                        checked: Config.options.dock.showPinButton
                        onCheckedChanged: { Config.options.dock.showPinButton = checked }
                    }
                    ConfigSwitch {
                        buttonIcon: "apps"
                        text: Translation.tr("Show Apps Button")
                        checked: Config.options.dock.showAppsButton
                        onCheckedChanged: { Config.options.dock.showAppsButton = checked }
                    }
                    ConfigSwitch {
                        buttonIcon: "colors"
                        text: Translation.tr("Tint app icons")
                        checked: Config.options.dock.monochromeIcons
                        onCheckedChanged: { Config.options.dock.monochromeIcons = checked }
                    }
                }
            }
        }

        ContentSection {
            icon: "lock"
            title: Translation.tr("Lock screen")
            shape: MaterialShape.Shape.Pentagon

            GroupedList {
                ConfigSwitch {
                    buttonIcon: "water_drop"
                    text: Translation.tr("Use Hyprlock (instead of Quickshell)")
                    checked: Config.options.lock.useHyprlock
                    onCheckedChanged: { Config.options.lock.useHyprlock = checked }
                }
                ConfigSwitch {
                    buttonIcon: "account_circle"
                    text: Translation.tr("Launch on startup")
                    checked: Config.options.lock.launchOnStartup
                    onCheckedChanged: { Config.options.lock.launchOnStartup = checked }
                }
                ConfigSwitch {
                    buttonIcon: "widgets"
                    enabled: WM.compositor !== "niri"
                    text: Translation.tr("Show Widgets")
                    checked: Config.options.lock.showWidgets
                    onCheckedChanged: { Config.options.lock.showWidgets = checked }
                }
                ConfigSwitch {
                    buttonIcon: "tools_installation_kit"
                    text: Translation.tr("Show Toolbars")
                    checked: Config.options.lock.showToolbars
                    onCheckedChanged: { Config.options.lock.showToolbars = checked }
                }
                ConfigSwitch {
                    buttonIcon: "left_panel_open"
                    enabled: Config.options.lock.showToolbars
                    text: Translation.tr("Show left toolbar (username/media)")
                    checked: Config.options.lock.showLeftToolbar
                    onCheckedChanged: { Config.options.lock.showLeftToolbar = checked }
                }
                ConfigSwitch {
                    buttonIcon: "right_panel_open"
                    enabled: Config.options.lock.showToolbars
                    text: Translation.tr("Show right toolbar (battery/power)")
                    checked: Config.options.lock.showRightToolbar
                    onCheckedChanged: { Config.options.lock.showRightToolbar = checked }
                }
                ConfigSwitch {
                    buttonIcon: "music_note"
                    enabled: Config.options.lock.showToolbars && Config.options.lock.showLeftToolbar
                    text: Translation.tr("Show media player info")
                    checked: Config.options.lock.showMedia
                    onCheckedChanged: { Config.options.lock.showMedia = checked }
                }
            }

            ContentSubsection {
                title: Translation.tr("Widgets shown when locked")
                visible: WM.compositor !== "niri"

                StyledText {
                    Layout.fillWidth: true
                    Layout.bottomMargin: 4
                    wrapMode: Text.Wrap
                    color: Appearance.colors.colSubtext
                    text: Translation.tr("Choose which desktop widgets are also allowed to appear on the lock screen. This only applies while \"Show Widgets\" above is on; a widget must also be enabled on the desktop (Background settings) to show up here.")
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2
                    Repeater {
                        model: page.lockWidgetOptions
                        ConfigSwitch {
                            required property var modelData
                            buttonIcon: modelData.icon
                            enabled: Config.options.lock.showWidgets
                            text: modelData.label
                            checked: page.isLockWidgetEnabled(modelData.name)
                            onCheckedChanged: page.setLockWidgetEnabled(modelData.name, checked)
                        }
                    }
                }
            }

            ContentSubsection {
                title: Translation.tr("Security")
                GroupedList {
                    ConfigSwitch {
                        buttonIcon: "settings_power"
                        text: Translation.tr("Require password to power off/restart")
                        checked: Config.options.lock.security.requirePasswordToPower
                        onCheckedChanged: { Config.options.lock.security.requirePasswordToPower = checked }
                    }
                    ConfigSwitch {
                        buttonIcon: "key_vertical"
                        text: Translation.tr("Also unlock keyring")
                        checked: Config.options.lock.security.unlockKeyring
                        onCheckedChanged: { Config.options.lock.security.unlockKeyring = checked }
                    }
                }
            }

            ContentSubsection {
                title: Translation.tr("Biometrics")
                GroupedList {
                    ConfigSwitch {
                        buttonIcon: "fingerprint"
                        text: Translation.tr("Enable fingerprint unlock (fprintd / PAM)")
                        checked: Config.options.lock.biometrics.enableFingerprint
                        onCheckedChanged: Config.options.lock.biometrics.enableFingerprint = checked
                    }
                    ConfigSwitch {
                        buttonIcon: "touch_app"
                        enabled: Config.options.lock.biometrics.enableFingerprint
                        text: Translation.tr("Start fingerprint scan when locked")
                        checked: Config.options.lock.biometrics.autoStartFingerprint
                        onCheckedChanged: Config.options.lock.biometrics.autoStartFingerprint = checked
                    }
                    ConfigSwitch {
                        buttonIcon: "animation"
                        text: Translation.tr("Animate biometric sensor")
                        checked: Config.options.lock.biometrics.showSensorAnimation
                        onCheckedChanged: Config.options.lock.biometrics.showSensorAnimation = checked
                    }
                    ConfigSwitch {
                        buttonIcon: "face"
                        text: Translation.tr("Enable Face ID / IR camera authentication")
                        checked: Config.options.lock.biometrics.enableFaceAuth
                        onCheckedChanged: Config.options.lock.biometrics.enableFaceAuth = checked
                    }
                    ConfigSwitch {
                        buttonIcon: "visibility"
                        enabled: Config.options.lock.biometrics.enableFaceAuth
                        text: Translation.tr("Start Face ID scan when locked")
                        checked: Config.options.lock.biometrics.autoStartFaceAuth
                        onCheckedChanged: Config.options.lock.biometrics.autoStartFaceAuth = checked
                    }
                    ConfigSpinBox {
                        icon: "timer"
                        enabled: Config.options.lock.biometrics.enableFaceAuth
                        text: Translation.tr("Face scan timeout (seconds)")
                        value: Config.options.lock.biometrics.faceTimeoutSeconds
                        from: 1; to: 60; stepSize: 1
                        onValueChanged: Config.options.lock.biometrics.faceTimeoutSeconds = value
                    }
                    ConfigTextArea {
                        Layout.fillWidth: true
                        fieldWidth: 330
                        enabled: Config.options.lock.biometrics.enableFaceAuth
                        buttonIcon: "terminal"
                        text: Translation.tr("Face authentication command")
                        description: Translation.tr("Runs only from the lock screen. It must return exit code 0 only after successful identity verification.")
                        value: Config.options.lock.biometrics.faceCommand
                        onValueChanged: Config.options.lock.biometrics.faceCommand = value
                    }
                    StyledText {
                        Layout.fillWidth: true
                        wrapMode: Text.Wrap
                        color: Appearance.colors.colSubtext
                        text: Translation.tr("The default command is ‘howdy test’. Replace it with your installed Face ID script if needed; the lock unlocks only when that command exits successfully.")
                    }
                }
            }

            ContentSubsection {
                title: Translation.tr("Style: General")
                GroupedList {
                    ConfigSwitch {
                        buttonIcon: "center_focus_weak"
                        text: Translation.tr("Center clock")
                        checked: Config.options.lock.centerClock
                        onCheckedChanged: { Config.options.lock.centerClock = checked }
                    }
                    ConfigSwitch {
                        buttonIcon: "info"
                        text: Translation.tr('Show "Locked" text')
                        checked: Config.options.lock.showLockedText
                        onCheckedChanged: { Config.options.lock.showLockedText = checked }
                    }
                    ConfigSwitch {
                        buttonIcon: "shapes"
                        text: Translation.tr("Use varying shapes for password characters")
                        checked: Config.options.lock.materialShapeChars
                        onCheckedChanged: { Config.options.lock.materialShapeChars = checked }
                    }
                }
            }

            ContentSubsection {
                title: Translation.tr("Password and sensor position")
                GroupedList {
                    ConfigSelectionArray {
                        icon: "open_with"
                        text: Translation.tr("Password controls position")
                        currentValue: Config.options.lock.layout.passwordPlacement
                        onSelected: newValue => Config.options.lock.layout.passwordPlacement = newValue
                        options: [
                            { displayName: Translation.tr("Bottom center"), icon: "south", value: "bottom" },
                            { displayName: Translation.tr("Screen center"), icon: "center_focus_strong", value: "center" },
                            { displayName: Translation.tr("Left edge"), icon: "left_panel_open", value: "left" },
                            { displayName: Translation.tr("Right edge"), icon: "right_panel_open", value: "right" }
                        ]
                    }
                    ConfigRow {
                        uniform: true
                        ConfigSpinBox {
                            icon: "swap_horiz"
                            text: Translation.tr("Horizontal offset")
                            value: Config.options.lock.layout.offsetX
                            from: -600; to: 600; stepSize: 4
                            onValueChanged: Config.options.lock.layout.offsetX = value
                        }
                        ConfigSpinBox {
                            icon: "swap_vert"
                            text: Translation.tr("Vertical offset")
                            value: Config.options.lock.layout.offsetY
                            from: -500; to: 500; stepSize: 4
                            onValueChanged: Config.options.lock.layout.offsetY = value
                        }
                    }
                    ConfigRow {
                        uniform: true
                        ConfigSpinBox {
                            icon: "vertical_align_bottom"
                            text: Translation.tr("Bottom margin")
                            enabled: Config.options.lock.layout.passwordPlacement !== "center"
                            value: Config.options.lock.layout.bottomMargin
                            from: 0; to: 400; stepSize: 4
                            onValueChanged: Config.options.lock.layout.bottomMargin = value
                        }
                        ConfigSpinBox {
                            icon: "zoom_in"
                            text: Translation.tr("Controls scale (%)")
                            value: Math.round(Config.options.lock.layout.scale * 100)
                            from: 70; to: 160; stepSize: 5
                            onValueChanged: Config.options.lock.layout.scale = value / 100
                        }
                    }
                }
            }

            ContentSubsection {
                title: Translation.tr("Style: Blurred")
                GroupedList {
                    ConfigSwitch {
                        buttonIcon: "blur_on"
                        text: Translation.tr("Enable blur")
                        checked: Config.options.lock.blur.enable
                        onCheckedChanged: { Config.options.lock.blur.enable = checked }
                    }
                    ConfigSpinBox {
                        icon: "deblur"
                        text: Translation.tr("Samples")
                        value: Config.options.lock.blur.size
                        from: 20; to: 200; stepSize: 10
                        onValueChanged: { Config.options.lock.blur.size = value }
                    }
                    ConfigSpinBox {
                        icon: "loupe"
                        text: Translation.tr("Extra wallpaper zoom (%)")
                        value: Config.options.lock.blur.extraZoom * 100
                        from: 1; to: 150; stepSize: 2
                        onValueChanged: { Config.options.lock.blur.extraZoom = value / 100 }
                    }
                }
            }
        }

        ContentSection {
            icon: "select_window"
            shape: MaterialShape.Shape.SoftBurst
            title: Translation.tr("Overlay")

            GroupedList {
                ConfigSwitch {
                    buttonIcon: "high_density"
                    text: Translation.tr("Enable opening zoom animation")
                    checked: Config.options.overlay.openingZoomAnimation
                    onCheckedChanged: {
                        Config.options.overlay.openingZoomAnimation = checked;
                    }
                }
                ConfigSwitch {
                    buttonIcon: "texture"
                    text: Translation.tr("Darken screen")
                    checked: Config.options.overlay.darkenScreen
                    onCheckedChanged: {
                        Config.options.overlay.darkenScreen = checked;
                    }
                }
            }

            ContentSubsection {
                title: Translation.tr("Floating Image")
                GroupedList {
                    ConfigTextArea {
                        id: floatingImageSourceField
                        Layout.fillWidth: true
                        fieldWidth: 430
                        buttonIcon: "imagesmode"
                        text: Translation.tr("Image source")
                        value: Config.options.overlay.floatingImage.imageSource
                        onValueChanged: {
                            floatingImageSourceDebounceTimer.restart();
                        }

                        Timer {
                            id: floatingImageSourceDebounceTimer
                            interval: 1000
                            repeat: false
                            onTriggered: {
                                Config.options.overlay.floatingImage.imageSource = floatingImageSourceField.value;
                            }
                        }
                    }
                }
            }

            ContentSubsection {
                title: Translation.tr("Crosshair")

                Rectangle {
                    id: crosshairCard
                    Layout.fillWidth: true
                    implicitHeight: crosshairCol.implicitHeight + 28
                    radius: Appearance.rounding.normal
                    color: Appearance.colors.colLayer1

                    ColumnLayout {
                        id: crosshairCol
                        anchors { fill: parent; margins: 14 }
                        spacing: 8

                        ConfigTextArea {
                            id: crosshairCodeField
                            Layout.fillWidth: true
                            buttonIcon: "point_scan"
                            text: Translation.tr("Crosshair code")
                            placeholderText: Translation.tr("Crosshair code (in Valorant's format)")
                            value: Config.options.crosshair.code
                            onValueChanged: {
                                crosshairCodeDebounceTimer.restart();
                            }

                            Timer {
                                id: crosshairCodeDebounceTimer
                                interval: 1000
                                repeat: false
                                onTriggered: {
                                    Config.options.crosshair.code = crosshairCodeField.value;
                                }
                            }
                        }
                        
                        RowLayout {
                            Layout.fillWidth: true
                            StyledText {
                                Layout.leftMargin: 8
                                Layout.fillWidth: true
                                text: Translation.tr("Press Super+G to open the overlay and pin the crosshair")
                                font.pixelSize: Appearance.font.pixelSize.smaller
                                color: Appearance.colors.colSubtext
                                wrapMode: Text.Wrap
                            }
                            RippleButtonWithIcon {
                                id: editorButton
                                Layout.fillWidth: true
                                Layout.rightMargin: 6
                                Layout.preferredHeight: 40
                                buttonRadius: Appearance.rounding.normal
                                materialIcon: "open_in_new"
                                mainText: Translation.tr("Open editor")
                                onClicked: {
                                    Qt.openUrlExternally(`https://www.vcrdb.net/builder?c=${Config.options.crosshair.code}`);
                                }
                            }
                        }
                    }
                }
            }
        }

        ContentSection {
            icon: "screenshot_frame_2"
            shape: MaterialShape.Shape.PuffyDiamond
            title: Translation.tr("Region selector (screen snipping/Google Lens)")

            ContentSubsection {
                title: Translation.tr("Hint target regions")
                GroupedList {
                    ConfigSwitch {
                        buttonIcon: "select_window"
                        text: Translation.tr('Windows')
                        checked: Config.options.regionSelector.targetRegions.windows
                        onCheckedChanged: {
                            Config.options.regionSelector.targetRegions.windows = checked;
                        }
                    }
                    ConfigSwitch {
                        buttonIcon: "right_panel_open"
                        text: Translation.tr('Layers')
                        checked: Config.options.regionSelector.targetRegions.layers
                        onCheckedChanged: {
                            Config.options.regionSelector.targetRegions.layers = checked;
                        }
                    }
                    ConfigSwitch {
                        buttonIcon: "nearby"
                        text: Translation.tr('Content')
                        checked: Config.options.regionSelector.targetRegions.content
                        onCheckedChanged: {
                            Config.options.regionSelector.targetRegions.content = checked;
                        }
                    }
                }
            }

            ContentSubsection {
                title: Translation.tr("Google Lens")
                    
                GroupedList {
                    ConfigSelectionArray {
                        text: Translation.tr("Selection Type")
                        icon: "ink_selection"
                        currentValue: Config.options.search.imageSearch.useCircleSelection ? "circle" : "rectangles"
                        onSelected: newValue => {
                            Config.options.search.imageSearch.useCircleSelection = (newValue === "circle");
                        }
                        options: [
                            { icon: "activity_zone", value: "rectangles", displayName: Translation.tr("Rectangular selection") },
                            { icon: "gesture", value: "circle", displayName: Translation.tr("Circle to Search") }
                        ]
                    }
                }
            }

            ContentSubsection {
                title: Translation.tr("Rectangular selection")
                GroupedList {
                    ConfigSwitch {
                        buttonIcon: "point_scan"
                        text: Translation.tr("Show aim lines")
                        checked: Config.options.regionSelector.rect.showAimLines
                        onCheckedChanged: {
                            Config.options.regionSelector.rect.showAimLines = checked;
                        }
                    }
                }
            }

            ContentSubsection {
                title: Translation.tr("Circle selection")

                GroupedList {
                    ConfigSpinBox {
                        icon: "eraser_size_3"
                        text: Translation.tr("Stroke width")
                        value: Config.options.regionSelector.circle.strokeWidth
                        from: 1
                        to: 20
                        stepSize: 1
                        onValueChanged: {
                            Config.options.regionSelector.circle.strokeWidth = value;
                        }
                    }

                    ConfigSpinBox {
                        icon: "screenshot_frame_2"
                        text: Translation.tr("Padding")
                        value: Config.options.regionSelector.circle.padding
                        from: 0
                        to: 100
                        stepSize: 5
                        onValueChanged: {
                            Config.options.regionSelector.circle.padding = value;
                        }
                    }
                }
            }
        }

        ContentSection {
            icon: "voting_chip"
            shape: MaterialShape.Shape.Sunny
            title: Translation.tr("On-screen display")
            GroupedList {
                ConfigSpinBox {
                    icon: "av_timer"
                    text: Translation.tr("Timeout (ms)")
                    value: Config.options.osd.timeout
                    from: 100
                    to: 3000
                    stepSize: 100
                    onValueChanged: {
                        Config.options.osd.timeout = value;
                    }
                }
            }
        }

        ContentSection {
            shape: MaterialShape.Shape.Puffy
            icon: "panorama"
            title: Translation.tr("Wallpaper selector")

            GroupedList {
                ConfigSwitch {
                    buttonIcon: "ad"
                    text: Translation.tr('Use system file picker')
                    checked: Config.options.wallpaperSelector.useSystemFileDialog
                    onCheckedChanged: {
                        Config.options.wallpaperSelector.useSystemFileDialog = checked;
                    }
                }

                ConfigSwitch {
                    buttonIcon: "home"
                    text: Translation.tr('Show home directory in quick access')
                    checked: Config.options.wallpaperSelector.showHomePath
                    onCheckedChanged: {
                        Config.options.wallpaperSelector.showHomePath = checked;
                    }
                }

                ConfigSwitch {
                    buttonIcon: "done"
                    text: Translation.tr('Close after selection')
                    checked: Config.options.wallpaperSelector.closeAfterSelection
                    onCheckedChanged: {
                        Config.options.wallpaperSelector.closeAfterSelection = checked;
                    }
                }

                ConfigSwitch {
                    buttonIcon: "blur_on"
                    text: Translation.tr('Show blur background')
                    checked: Config.options.wallpaperSelector.showBlurBackground
                    onCheckedChanged: {
                        Config.options.wallpaperSelector.showBlurBackground = checked;
                    }
                }

                ConfigSpinBox {
                    icon: "grid_on"
                    text: Translation.tr("Columns in grid view")
                    value: Config.options.wallpaperSelector.columns
                    from: 3
                    to: 10
                    stepSize: 1
                    onValueChanged: {
                        Config.options.wallpaperSelector.columns = value;
                    }
                }

                ConfigSpinBox {
                    icon: "timer"
                    text: Translation.tr("Wallpaper change interval (min)")
                    value: Config.options.wallpaperSelector.changeInterval / 60000
                    from: 0
                    to: 1440
                    stepSize: 5
                    onValueChanged: {
                        Config.options.wallpaperSelector.changeInterval = value * 60000;
                    }
                }

                ConfigSwitch {
                    buttonIcon: "search"
                    text: Translation.tr('Always show search bar')
                    checked: Config.options.wallpaperSelector.showSearchbar
                    onCheckedChanged: {
                        Config.options.wallpaperSelector.showSearchbar = checked;
                    }
                }
                ConfigTextArea {
                    id: userPathField
                    Layout.fillWidth: true
                    buttonIcon: "folder"
                    text: Translation.tr("Custom Wallpaper Folder")
                    placeholderText: Translation.tr("e.g., /home/user/Pictures")
                    fieldWidth: 300
                    value: Config.options.wallpaperSelector.userPath ?? ""

                    onValueChanged: {
                        userPathDebounceTimer.restart()
                    }

                    Timer {
                        id: userPathDebounceTimer
                        interval: 1000
                        running: false
                        onTriggered: {
                            Config.options.wallpaperSelector.userPath = userPathField.value
                        }
                    }
                }
                ConfigTextArea {
                    id: liveWallpapersPathField
                    Layout.fillWidth: true
                    buttonIcon: "video_template"
                    text: Translation.tr("Live Wallpaper Folder")
                    placeholderText: Translation.tr("e.g., /home/user/Videos/Wallpapers")
                    fieldWidth: 300
                    value: Config.options.wallpaperSelector.liveWallpapersPath ?? ""

                    onValueChanged: {
                        liveWallpapersPathDebounceTimer.restart()
                    }

                    Timer {
                        id: liveWallpapersPathDebounceTimer
                        interval: 1000
                        running: false
                        onTriggered: {
                            Config.options.wallpaperSelector.liveWallpapersPath = liveWallpapersPathField.value
                        }
                    }
                } 
            }
        }

        ContentSection {
            icon: "text_format"
            shape: MaterialShape.Shape.Arrow
            title: Translation.tr("Fonts")

            GroupedList {
                ConfigTextArea {
                    id: mainFontField
                    Layout.fillWidth: true
                    buttonIcon: "font_download"
                    text: Translation.tr("Font family name (e.g., Google Sans Flex)")
                    value: Config.options.appearance.fonts.main
                    onValueChanged: {
                        mainFontDebounceTimer.restart();
                    }

                    Timer {
                        id: mainFontDebounceTimer
                        interval: 1000
                        running: false
                        onTriggered: {
                            Config.options.appearance.fonts.main = mainFontField.value;
                        }
                    }
                }

                ConfigTextArea {
                    id: numbersFontField
                    Layout.fillWidth: true
                    buttonIcon: "123"
                    text: Translation.tr("Numbers family name")
                    value: Config.options.appearance.fonts.numbers
                    onValueChanged: {
                        numbersFontDebounceTimer.restart();
                    }

                    Timer {
                        id: numbersFontDebounceTimer
                        interval: 1000
                        running: false
                        onTriggered: {
                            Config.options.appearance.fonts.numbers = numbersFontField.value;
                        }
                    }
                }

                ConfigTextArea {
                    id: titleFontField
                    Layout.fillWidth: true
                    buttonIcon: "title"
                    text: Translation.tr("Title family name")
                    value: Config.options.appearance.fonts.title
                    onValueChanged: {
                        titleFontDebounceTimer.restart();
                    }

                    Timer {
                        id: titleFontDebounceTimer
                        interval: 1000
                        running: false
                        onTriggered: {
                            Config.options.appearance.fonts.title = titleFontField.value;
                        }
                    }
                }

                ConfigTextArea {
                    id: monospaceFontField
                    Layout.fillWidth: true
                    buttonIcon: "space_bar"
                    text: Translation.tr("Monospace font name (e.g., JetBrains Mono NF)")
                    value: Config.options.appearance.fonts.monospace
                    onValueChanged: {
                        monospaceFontDebounceTimer.restart();
                    }

                    Timer {
                        id: monospaceFontDebounceTimer
                        interval: 1000
                        running: false
                        onTriggered: {
                            Config.options.appearance.fonts.monospace = monospaceFontField.value;
                        }
                    }
                }

                ConfigTextArea {
                    id: iconNerdFontField
                    Layout.fillWidth: true
                    buttonIcon: "emoticon"
                    text: Translation.tr("Nerd Fonts Icons (e.g., JetBrains Mono NF)")
                    value: Config.options.appearance.fonts.iconNerd
                    onValueChanged: {
                        iconNerdFontDebounceTimer.restart();
                    }

                    Timer {
                        id: iconNerdFontDebounceTimer
                        interval: 1000
                        running: false
                        onTriggered: {
                            Config.options.appearance.fonts.iconNerd = iconNerdFontField.value;
                        }
                    }
                }

                ConfigTextArea {
                    id: readingFontField
                    Layout.fillWidth: true
                    buttonIcon: "book_ribbon"
                    text: Translation.tr("Reading font name (e.g., Readex Pro)")
                    value: Config.options.appearance.fonts.reading
                    onValueChanged: {
                        readingFontDebounceTimer.restart();
                    }

                    Timer {
                        id: readingFontDebounceTimer
                        interval: 1000
                        running: false
                        onTriggered: {
                            Config.options.appearance.fonts.reading = readingFontField.value;
                        }
                    }
                }

                ConfigTextArea {
                    id: expressiveFontField
                    Layout.fillWidth: true
                    buttonIcon: "mood_heart"
                    text: Translation.tr("Expressive font name (e.g., Space Grotesk)")
                    value: Config.options.appearance.fonts.expressive
                    onValueChanged: {
                        expressiveFontDebounceTimer.restart();
                    }

                    Timer {
                        id: expressiveFontDebounceTimer
                        interval: 1000
                        running: false
                        onTriggered: {
                            Config.options.appearance.fonts.expressive = expressiveFontField.value;
                        }
                    }
                }
            }
        }

        ContentSection {
            icon: "colors"
            title: Translation.tr("Color generation")
            shape: MaterialShape.Shape.VerySunny

            GroupedList {
                ConfigSwitch {
                    buttonIcon: "hardware"
                    text: Translation.tr("Shell & utilities")
                    checked: Config.options.appearance.wallpaperTheming.enableAppsAndShell
                    onCheckedChanged: { Config.options.appearance.wallpaperTheming.enableAppsAndShell = checked }
                }
                ConfigSwitch {
                    buttonIcon: "tv_options_input_settings"
                    text: Translation.tr("Qt apps")
                    checked: Config.options.appearance.wallpaperTheming.enableQtApps
                    onCheckedChanged: { Config.options.appearance.wallpaperTheming.enableQtApps = checked }
                }
                ConfigSwitch {
                    buttonIcon: "terminal"
                    text: Translation.tr("Terminal")
                    checked: Config.options.appearance.wallpaperTheming.enableTerminal
                    onCheckedChanged: { Config.options.appearance.wallpaperTheming.enableTerminal = checked }
                }
                ConfigRow {
                    uniform: true
                    ConfigSwitch {
                        buttonIcon: "dark_mode"
                        text: Translation.tr("Force dark mode in terminal")
                        checked: Config.options.appearance.wallpaperTheming.terminalGenerationProps.forceDarkMode
                        onCheckedChanged: { Config.options.appearance.wallpaperTheming.terminalGenerationProps.forceDarkMode = checked }
                    }
                }
                ConfigSpinBox {
                    icon: "invert_colors"
                    text: Translation.tr("Terminal: Harmony (%)")
                    value: Config.options.appearance.wallpaperTheming.terminalGenerationProps.harmony * 100
                    from: 0; to: 100; stepSize: 10
                    onValueChanged: { Config.options.appearance.wallpaperTheming.terminalGenerationProps.harmony = value / 100 }
                }
                ConfigSpinBox {
                    icon: "gradient"
                    text: Translation.tr("Terminal: Harmonize threshold")
                    value: Config.options.appearance.wallpaperTheming.terminalGenerationProps.harmonizeThreshold
                    from: 0; to: 100; stepSize: 10
                    onValueChanged: { Config.options.appearance.wallpaperTheming.terminalGenerationProps.harmonizeThreshold = value }
                }
                ConfigSpinBox {
                    icon: "format_color_text"
                    text: Translation.tr("Terminal: Foreground boost (%)")
                    value: Config.options.appearance.wallpaperTheming.terminalGenerationProps.termFgBoost * 100
                    from: 0; to: 100; stepSize: 10
                    onValueChanged: { Config.options.appearance.wallpaperTheming.terminalGenerationProps.termFgBoost = value / 100 }
                }
            }
        }
    }
}
