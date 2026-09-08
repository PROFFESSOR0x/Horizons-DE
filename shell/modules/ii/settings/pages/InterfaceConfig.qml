import QtQuick
import QtQuick.Layouts
import Quickshell
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
        { name: "visualizerMirror", label: Translation.tr("Mirrored visualizer"), icon: "vertical_align_center" },
        { name: "fullMonitorVisualizer", label: Translation.tr("Full monitor visualizer"), icon: "fullscreen" },
        { name: "customImage", label: Translation.tr("Custom image"), icon: "photo" },
        { name: "resources", label: Translation.tr("System resources"), icon: "monitoring" },
        { name: "networkInfo", label: Translation.tr("Network info"), icon: "wifi" },
        { name: "uptime", label: Translation.tr("Uptime"), icon: "hourglass_top" },
        { name: "systemHistory", label: Translation.tr("System history graphs"), icon: "monitor_heart" }
    ]

    function isLockWidgetEnabled(name) {
        return Config.options.lock.enabledWidgets.includes(name)
    }

    function setLockWidgetEnabled(name, on) {
        GlobalStates.setWidgetShown(name, true, on)
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
        visible: page.settingsShow("appearance|apps|capture-details|devices|effects|input-details|notification-rules|panel-details|panels|session|session-details");
        id: mainLayout
        Layout.fillWidth: true
        Layout.fillHeight: true
        spacing: 20

        ContentSection {
            icon: "desktop_windows"
            title: Translation.tr("Screens & workspaces")
            visible: page.settingsShow("devices") && WM.compositor === "hyprland" && (WM.monitors.length > 1)
            GroupedList {
                compact: true;
                visible: page.settingsShow("devices")
                ConfigSwitch {
                    visible: page.settingsShow("devices");
                    objectName: "InterfaceConfig.use-one-workspace-set-across-all-screens";
                    buttonIcon: "view_carousel"
                    text: Translation.tr("Use one workspace set across all screens")
                    checked: Config.options.workspaceLinking.unifiedMultiMonitor
                    // Write the requested value directly. ConfigSwitch is a
                    // Button subclass and its checked binding can otherwise
                    // be replaced by a click before the changed handler sees
                    // the persisted option, leaving the visual toggle and the
                    // workspace controller out of sync.
                    onClicked: GlobalStates.setUnifiedMultiMonitorWorkspaces(
                        !Config.options.workspaceLinking.unifiedMultiMonitor)
                }
            }
        }

        ContentSection {
            visible: page.settingsShow("appearance|effects");
            icon: "palette"
            shape: MaterialShape.Shape.Cookie7Sided
            title: Translation.tr("Appearance")
            GroupedList {
                compact: true;
                visible: page.settingsShow("effects")
                ConfigSwitch {
                    visible: page.settingsShow("effects");
                    objectName: "InterfaceConfig.extra-background-tint";
                    buttonIcon: "format_paint"
                    text: Translation.tr("Extra Background Tint")
                    checked: Config.options.appearance.extraBackgroundTint
                    onEdited: { Config.options.appearance.extraBackgroundTint = checked }
                }
                ConfigSelectionArray {
                    visible: page.settingsShow("effects");
                    objectName: "InterfaceConfig.fake-screen-rounding";
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
                visible: page.settingsShow("appearance");
                title: Translation.tr("Visual Effect")
                tooltip: Translation.tr("Blur, transparency and Liquid Glass all change how panels look and don't layer well together, so only one can be active at a time. Choosing one here automatically turns the other two off.")
                GroupedList {
                    compact: true;
                    visible: page.settingsShow("appearance")
                    ConfigSelectionArray {
                        visible: page.settingsShow("appearance");
                        objectName: "InterfaceConfig.panel-style";
                        icon: "styles"
                        text: Translation.tr("Panel style")
                        currentValue: Config.options.appearance.visualEffect
                        onSelected: newValue => {
                            Config.options.appearance.visualEffect = newValue;
                            Config.applyVisualEffectExclusivity(newValue);
                            // One setMany, not two set() calls. Every set()
                            // spawns its own hyprconfigurator.py, and two of
                            // them race on the same shellOverrides/main.lua:
                            // whichever reads the file first has its edit
                            // silently overwritten by the other's atomic
                            // rewrite. That is why picking a panel style
                            // sometimes landed on the previous one's blur
                            // state instead of the one just chosen.
                            HyprlandConfig.setMany({
                                "decoration:blur:enabled": Config.options.hyprland.decoration.blur.enabled ? 1 : 0,
                                "decoration:blur:variant": Config.options.hyprland.decoration.blur.variant,
                            });
                        }
                        options: [
                            { displayName: Translation.tr("None"), icon: "block", value: "none" },
                            { displayName: Translation.tr("Blur"), icon: "blur_on", value: "blur" },
                            { displayName: Translation.tr("Transparency"), icon: "opacity", value: "transparency" },
                            { displayName: Translation.tr("Liquid Glass"), icon: "water_drop", value: "glass" }
                        ]
                    }
                    StyledText {
                        property bool groupDescription: true;
                        visible: page.settingsShow("appearance");
                        Layout.fillWidth: true
                        wrapMode: Text.Wrap
                        color: Appearance.colors.colSubtext
                        font.pixelSize: Appearance.font.pixelSize.small
                        text: Translation.tr("What each one actually changes:\n• None - shell panels are painted solid. Compositor blur is turned off.\n• Blur - turns Hyprland's blur on (decoration:blur) and makes this shell's own panels translucent so there is something for it to show through. Windows stay opaque unless you also turn on the switch below.\n• Transparency - only this shell's panels; the compositor is left alone, so what shows through is the raw wallpaper/windows, unblurred. The sliders below set how much.\n• Liquid Glass - Blur plus Hyprland's \"acrylic\" blur variant (decoration:blur:variant), which adds refraction and tint on top.\nAll three of the non-None options are mutually exclusive, and none of them touch app windows' own opacity.")
                    }
                    StyledText {
                        property bool groupDescription: true;
                        // Liquid Glass silently degrades to plain blur on any
                        // Hyprland that predates the blur-variant patch: the
                        // shell-side translucency still applies (which is what
                        // makes it look like a "fake" glass that only affects
                        // this shell's panels), but the compositor half of the
                        // effect never arrives. Say so here rather than only
                        // on the Hyprland page, since this is where the option
                        // is picked.
                        visible: Config.options.appearance.visualEffect === "glass" && !HyprlandData.blurVariantSupported
                        Layout.fillWidth: true
                        wrapMode: Text.Wrap
                        color: Appearance.m3colors.m3error
                        font.pixelSize: Appearance.font.pixelSize.small
                        text: Translation.tr("Your running Hyprland has no decoration:blur:variant support (it needs a build newer than any tagged release), so the compositor half of Liquid Glass - the refraction and tint on windows - is being ignored. What you're seeing is the shell's own panel translucency over ordinary blur. Settings > Hyprland > Blur Style has the details.")
                    }
                }
            }
            ContentSubsection {
                title: Translation.tr("Panel translucency")
                visible: page.settingsShow("effects") && (Config.options.appearance.visualEffect === "blur" || Config.options.appearance.visualEffect === "glass")
                GroupedList {
                    compact: true;
                    visible: page.settingsShow("effects")
                    ConfigSlider {
                        objectName: "InterfaceConfig.panel-translucency"
                        // Blur behind an opaque panel is invisible - this is
                        // how much of the blurred background this shell's own
                        // panels let through. 0 = the old fully-opaque look,
                        // where "Blur" was indistinguishable from "None".
                        visible: page.settingsShow("effects") && (Config.options.appearance.visualEffect === "blur")
                        text: Translation.tr("Panel translucency")
                        textWidth: 110
                        buttonIcon: "deblur"
                        value: Config.options.appearance.blurPanelTransparency * 100
                        from: 0; to: 60
                        onEdited: { Config.options.appearance.blurPanelTransparency = value / 100 }
                    }


                }
            }
            ContentSubsection {
                title: Translation.tr("Transparency")
                visible: page.settingsShow("effects") && (Config.options.appearance.visualEffect === "transparency")
                GroupedList {
                    compact: true;
                    visible: page.settingsShow("effects")
                    ConfigSwitch {
                        visible: page.settingsShow("effects");
                        objectName: "InterfaceConfig.automatic-disables-background-slider";
                        buttonIcon: "auto_awesome"
                        text: Translation.tr("Automatic (disables Background slider)")
                        enabled: Config.options.appearance.transparency.enable
                        checked: Config.options.appearance.transparency.automatic
                        onEdited: { Config.options.appearance.transparency.automatic = checked }
                    }
                    ConfigSlider {
                        visible: page.settingsShow("effects");
                        objectName: "InterfaceConfig.background";
                        text: Translation.tr("Background")
                        textWidth: 110
                        buttonIcon: "wallpaper"
                        enabled: Config.options.appearance.transparency.enable && !Config.options.appearance.transparency.automatic
                        value: Config.options.appearance.transparency.backgroundTransparency * 100
                        from: 0; to: 50
                        onEdited: { Config.options.appearance.transparency.backgroundTransparency = value / 100 }
                    }
                    ConfigSlider {
                        visible: page.settingsShow("effects");
                        objectName: "InterfaceConfig.content";
                        text: Translation.tr("Content")
                        textWidth: 110
                        buttonIcon: "layers"
                        enabled: Config.options.appearance.transparency.enable
                        value: Config.options.appearance.transparency.contentTransparency * 100
                        from: 0; to: 100
                        onEdited: { Config.options.appearance.transparency.contentTransparency = value / 100 }
                    }
                }
            }
            ContentSubsection {
                title: Translation.tr("Liquid Glass")
                visible: page.settingsShow("effects") && (Config.options.appearance.visualEffect === "glass")
                GroupedList {
                    compact: true;
                    visible: page.settingsShow("effects")
                    ConfigSlider {
                        visible: page.settingsShow("effects");
                        objectName: "InterfaceConfig.glass-opacity";
                        text: Translation.tr("Glass opacity")
                        textWidth: 110
                        buttonIcon: "opacity"
                        enabled: Config.options.appearance.glass.enable
                        value: Config.options.appearance.glass.opacity * 100
                        from: 35; to: 95
                        onEdited: { Config.options.appearance.glass.opacity = value / 100 }
                    }
                    StyledText {
                        property bool groupDescription: true;
                        visible: page.settingsShow("effects");
                        Layout.fillWidth: true
                        wrapMode: Text.Wrap
                        color: Appearance.colors.colSubtext
                        font.pixelSize: Appearance.font.pixelSize.small
                        text: Translation.tr("Liquid Glass is Hyprland's native \"acrylic\" blur variant, applied compositor-wide to every window. Fine-tune refraction, tint and the other blur styles under Settings > Hyprland > Blur Style.")
                    }
                }
            }
            ContentSubsection {
                visible: page.settingsShow("appearance|effects");
                title: Translation.tr("Motion")
                GroupedList {
                    compact: true;
                    visible: page.settingsShow("appearance|effects")
                    ConfigSelectionArray {
                        visible: page.settingsShow("appearance");
                        objectName: "InterfaceConfig.animation-style";
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
                        visible: page.settingsShow("effects");
                        objectName: "InterfaceConfig.animation-speed";
                        text: Translation.tr("Animation speed")
                        textWidth: 110
                        buttonIcon: "slow_motion_video"
                        value: Config.options.appearance.motion.durationScale * 100
                        from: 50; to: 200
                        onEdited: { Config.options.appearance.motion.durationScale = value / 100 }
                    }
                }
            }
            ContentSubsection {
                visible: page.settingsShow("effects");
                title: Translation.tr("Palette")
                GroupedList {
                    compact: true;
                    visible: page.settingsShow("effects")
                    ConfigComboBox {
                        objectName: "InterfaceConfig.palette-type";
                        visible: page.settingsShow("effects");

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
                        visible: page.settingsShow("effects");
                        objectName: "InterfaceConfig.accent-color-hex-empty-auto";
                        id: accentColorField
                        Layout.fillWidth: true
                        buttonIcon: "colorize"
                        text: Translation.tr("Accent Color (hex, empty=auto)")
                        placeholderText: "#ff0000"
                        value: Config.options.appearance.palette.accentColor
                        onEdited: accentDebounce.restart()
                        Timer { id: accentDebounce; interval: 800; onTriggered: Config.options.appearance.palette.accentColor = accentColorField.value }
                    }
                }
            }
        }

        ContentSection {
            visible: page.settingsShow("panel-details");
            icon: "settings"
            shape: MaterialShape.Shape.SoftBurst
            title: Translation.tr("Settings Panel")
            GroupedList {
                compact: true;
                visible: page.settingsShow("panel-details")
                // Order: daily look first, window behavior second, numeric
                // decoration details last.
                ConfigSelectionArray {
                    visible: page.settingsShow("panel-details");
                    objectName: "InterfaceConfig.style";
                    text: Translation.tr("Style")
                    icon: "style"
                    currentValue: Config.options.settings.style
                    onSelected: newValue => { Config.options.settings.style = newValue }
                    options: [
                        { displayName: Translation.tr("Default"), icon: "settings_panorama", value: "default" },
                        { displayName: Translation.tr("Minimal"), icon: "settings_heart", value: "minimal" }
                    ]
                }
                ConfigSwitch {
                    visible: page.settingsShow("panel-details");
                    objectName: "InterfaceConfig.normal-window";
                    buttonIcon: "open_in_new"
                    text: Translation.tr("Normal window mode")
                    checked: Config.options.settings.normalWindow
                    onEdited: { Config.options.settings.normalWindow = checked }
                }
                ConfigSpinBox {
                    visible: page.settingsShow("panel-details");
                    objectName: "InterfaceConfig.window-width";
                    icon: "width_normal"
                    text: Translation.tr("Window width")
                    value: Config.options.settings.preferredWidth
                    from: 640
                    to: 2560
                    stepSize: 20
                    onEdited: { Config.options.settings.preferredWidth = value }
                }
                ConfigSpinBox {
                    visible: page.settingsShow("panel-details");
                    objectName: "InterfaceConfig.window-height";
                    icon: "height"
                    text: Translation.tr("Window height")
                    value: Config.options.settings.preferredHeight
                    from: 420
                    to: 1600
                    stepSize: 20
                    onEdited: { Config.options.settings.preferredHeight = value }
                }
                ConfigSpinBox {
                    visible: page.settingsShow("panel-details");
                    objectName: "InterfaceConfig.border-width";
                    icon: "border_style"
                    text: Translation.tr("Border width")
                    value: Config.options.settings.borderSize
                    from: 0
                    to: 10
                    stepSize: 1
                    onEdited: { Config.options.settings.borderSize = value }
                }
                ColorSelectionArray {
                    visible: page.settingsShow("panel-details");
                    objectName: "InterfaceConfig.border-color";
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
            visible: page.settingsShow("apps|panels");
            icon: "splitscreen_left"
            shape: MaterialShape.Shape.Clover4Leaf
            title: Translation.tr("Left Sidebar")

            RowLayout {
                visible: page.settingsShow("apps|panels");
                Layout.fillWidth: true
                spacing: 8

                Rectangle {
                    visible: page.settingsShow("panels");
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    implicitHeight: mediaCol.implicitHeight + 24
                    radius: Appearance.rounding.normal
                    color: Appearance.colors.colLayer1
                    border.width: 1
                    border.color: "transparent"

                    ColumnLayout {
                        visible: page.settingsShow("panels");
                        id: mediaCol
                        anchors { fill: parent; margins: 12 }
                        spacing: 8

                        MaterialSymbol {
                            text: "music_note_2"
                            iconSize: Appearance.font.pixelSize.huge
                            color: Appearance.colors.colPrimary
                        }
                        StyledText {
                            visible: page.settingsShow("panels");
                            text: Translation.tr("Media Player")
                            font.pixelSize: Appearance.font.pixelSize.normal
                            font.weight: Font.Medium
                            color: Appearance.colors.colOnLayer1
                        }
                        Item { Layout.fillHeight: true }
                        GroupedList {
                            compact: true;
                            visible: page.settingsShow("panels");
                            Layout.fillWidth: true
                            bgcolor: Appearance.colors.colLayer2
                            ConfigSwitch {
                                visible: page.settingsShow("panels");
                                objectName: "InterfaceConfig.enable";
                                buttonIcon: "check"
                                text: Translation.tr("Enable")
                                checked: Config.options.sidebar.media.enable
                                onEdited: { Config.options.sidebar.media.enable = checked }
                            }
                            ConfigSwitch {
                                visible: page.settingsShow("panels");
                                objectName: "InterfaceConfig.follow-album-colors";
                                buttonIcon: "radio_button_partial"
                                text: Translation.tr("Follow Album Colors")
                                checked: Config.options.sidebar.media.artColors
                                onEdited: { Config.options.sidebar.media.artColors = checked }
                            }
                        }
                    }
                }

                ColumnLayout {
                    visible: page.settingsShow("apps");
                    Layout.fillWidth: true
                    spacing: 8

                    Rectangle {
                        visible: page.settingsShow("apps");
                        Layout.fillWidth: true
                        implicitHeight: aiCol.implicitHeight + 24
                        radius: Appearance.rounding.normal
                        color: Appearance.colors.colLayer1
                        border.width: 1
                        border.color: "transparent"

                        ColumnLayout {
                            visible: page.settingsShow("apps");
                            id: aiCol
                            anchors { fill: parent; margins: 12 }
                            spacing: 8

                            MaterialSymbol {
                                text: "smart_toy"
                                iconSize: Appearance.font.pixelSize.huge
                                color: Appearance.colors.colPrimary
                            }
                            StyledText {
                                visible: page.settingsShow("apps");
                                text: Translation.tr("AI")
                                font.pixelSize: Appearance.font.pixelSize.normal
                                font.weight: Font.Medium
                                color: Appearance.colors.colOnLayer1
                            }
                            ConfigSelectionArray {
                                visible: page.settingsShow("apps");
                                objectName: "InterfaceConfig.left-sidebar";
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
                        visible: page.settingsShow("apps");
                        Layout.fillWidth: true
                        implicitHeight: weebCol.implicitHeight + 24
                        radius: Appearance.rounding.normal
                        color: Appearance.colors.colLayer1
                        border.width: 1
                        border.color: "transparent"

                        ColumnLayout {
                            visible: page.settingsShow("apps");
                            id: weebCol
                            anchors { fill: parent; margins: 12 }
                            spacing: 8

                            MaterialSymbol {
                                text: "playing_cards"
                                iconSize: Appearance.font.pixelSize.huge
                                color: Appearance.colors.colPrimary
                            }
                            StyledText {
                                visible: page.settingsShow("apps");
                                text: Translation.tr("Weeb")
                                font.pixelSize: Appearance.font.pixelSize.normal
                                font.weight: Font.Medium
                                color: Appearance.colors.colOnLayer1
                            }
                            ConfigSelectionArray {
                                visible: page.settingsShow("apps");
                                objectName: "InterfaceConfig.left-sidebar-2";
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
                visible: page.settingsShow("apps");
                Layout.fillWidth: true
                Layout.topMargin: 4
                implicitHeight: translatorCol.implicitHeight + 24
                radius: Appearance.rounding.normal
                color: Appearance.colors.colLayer1
                border.width: 1
                border.color: "transparent"

                ColumnLayout {
                    visible: page.settingsShow("apps");
                    id: translatorCol
                    anchors { fill: parent; margins: 12 }
                    spacing: 8

                    RowLayout {
                        visible: page.settingsShow("apps");
                        spacing: 8
                        ConfigSwitch {
                            visible: page.settingsShow("apps");
                            objectName: "InterfaceConfig.enable-translator";
                            buttonIcon: "translate"
                            text: Translation.tr("Enable Translator")
                            checked: Config.options.sidebar.translator.enable
                            onEdited: { Config.options.sidebar.translator.enable = checked }
                        }
                    }
                }
            }
        }

        ContentSection {
            visible: page.settingsShow("panel-details|panels");
            icon: "splitscreen_right"
            shape: MaterialShape.Shape.Slanted
            title: Translation.tr("Right Sidebar")

            GroupedList {
                compact: true;
                visible: page.settingsShow("panel-details|panels")
                ConfigSwitch {
                    visible: page.settingsShow("panels");
                    objectName: "InterfaceConfig.banner";
                    buttonIcon: "planner_banner_ad_pt"
                    text: Translation.tr('Banner')
                    checked: Config.options.sidebar.banner
                    onEdited: {
                        Config.options.sidebar.banner = checked;
                    }
                }

                ConfigSwitch {
                    visible: page.settingsShow("panels");
                    objectName: "InterfaceConfig.bottom-group";
                    buttonIcon: "bottom_navigation"
                    text: Translation.tr('Bottom Group')
                    checked: Config.options.sidebar.bottomGroup
                    onEdited: {
                        Config.options.sidebar.bottomGroup = checked;
                    }
                }

                ConfigSwitch {
                    visible: page.settingsShow("panels");
                    objectName: "InterfaceConfig.media-player";
                    buttonIcon: "music_note"
                    text: Translation.tr('Media Player')
                    checked: Config.options.sidebar.mediaPlayer
                    onEdited: {
                        Config.options.sidebar.mediaPlayer = checked;
                    }
                }

                ConfigSwitch {
                    visible: page.settingsShow("panel-details");
                    objectName: "InterfaceConfig.keep-right-sidebar-loaded";
                    buttonIcon: "memory"
                    text: Translation.tr('Keep right sidebar loaded')
                    checked: Config.options.sidebar.keepRightSidebarLoaded
                    onEdited: {
                        Config.options.sidebar.keepRightSidebarLoaded = checked;
                    }
                }
            }

            ContentSubsection {
                visible: page.settingsShow("panel-details|panels");
                title: Translation.tr("Quick toggles")
                GroupedList {
                    compact: true;
                    visible: page.settingsShow("panel-details|panels")
                    ConfigSelectionArray {
                        visible: page.settingsShow("panels");
                        objectName: "InterfaceConfig.style-2";
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
                        visible: page.settingsShow("panel-details");
                        objectName: "InterfaceConfig.columns";
                        enabled: Config.options.sidebar.quickToggles.style === "android"
                        icon: "add_column_left"
                        text: Translation.tr("Columns")
                        value: Config.options.sidebar.quickToggles.android.columns
                        from: 1
                        to: 8
                        stepSize: 1
                        onEdited: {
                            Config.options.sidebar.quickToggles.android.columns = value;
                        }
                    }
                }
            }

            ContentSubsection {
                visible: page.settingsShow("panels");
                title: Translation.tr("Sliders")
                GroupedList {
                    compact: true;
                    visible: page.settingsShow("panels")
                    ConfigSwitch {
                        visible: page.settingsShow("panels");
                        objectName: "InterfaceConfig.enable-2";
                        buttonIcon: "check"
                        text: Translation.tr("Enable")
                        checked: Config.options.sidebar.quickSliders.enable
                        onEdited: {
                            Config.options.sidebar.quickSliders.enable = checked;
                        }
                    }

                    ConfigSwitch {
                        visible: page.settingsShow("panels");
                        objectName: "InterfaceConfig.brightness";
                        buttonIcon: "brightness_6"
                        text: Translation.tr("Brightness")
                        enabled: Config.options.sidebar.quickSliders.enable
                        checked: Config.options.sidebar.quickSliders.showBrightness
                        onEdited: {
                            Config.options.sidebar.quickSliders.showBrightness = checked;
                        }
                    }

                    ConfigSwitch {
                        visible: page.settingsShow("panels");
                        objectName: "InterfaceConfig.volume";
                        buttonIcon: "volume_up"
                        text: Translation.tr("Volume")
                        enabled: Config.options.sidebar.quickSliders.enable
                        checked: Config.options.sidebar.quickSliders.showVolume
                        onEdited: {
                            Config.options.sidebar.quickSliders.showVolume = checked;
                        }
                    }

                    ConfigSwitch {
                        visible: page.settingsShow("panels");
                        objectName: "InterfaceConfig.microphone";
                        buttonIcon: "mic"
                        text: Translation.tr("Microphone")
                        enabled: Config.options.sidebar.quickSliders.enable
                        checked: Config.options.sidebar.quickSliders.showMic
                        onEdited: {
                            Config.options.sidebar.quickSliders.showMic = checked;
                        }
                    }
                }
            }
        }

        ContentSection {
            visible: page.settingsShow("devices|input-details");
            icon: "screenshot_frame_2"
            shape: MaterialShape.Shape.Gem
            title: Translation.tr("Hot Corners")

            ContentSubsection {
                visible: page.settingsShow("devices|input-details");
                title: Translation.tr("Top")

                GroupedList {
                    compact: true;
                    visible: page.settingsShow("devices|input-details")
                    ConfigSwitch {
                        visible: page.settingsShow("devices");
                        objectName: "InterfaceConfig.enable-3";
                        buttonIcon: "check"
                        text: Translation.tr("Enable")
                        checked: Config.options.sidebar.cornerOpen.enable
                        onEdited: { Config.options.sidebar.cornerOpen.enable = checked }
                    }
                    ConfigSwitch {
                        visible: page.settingsShow("devices");
                        objectName: "InterfaceConfig.hover-to-trigger";
                        buttonIcon: "highlight_mouse_cursor"
                        text: Translation.tr("Hover to trigger")
                        checked: Config.options.sidebar.cornerOpen.clickless
                        onEdited: { Config.options.sidebar.cornerOpen.clickless = checked }
                    }
                    ConfigSwitch {
                        visible: page.settingsShow("devices");
                        objectName: "InterfaceConfig.place-at-bottom";
                        buttonIcon: "vertical_align_bottom"
                        text: Translation.tr("Place at bottom")
                        checked: Config.options.sidebar.cornerOpen.bottom
                        onEdited: { Config.options.sidebar.cornerOpen.bottom = checked }
                    }
                    ConfigSwitch {
                        visible: page.settingsShow("devices");
                        objectName: "InterfaceConfig.value-scroll";
                        buttonIcon: "unfold_more_double"
                        text: Translation.tr("Value scroll")
                        checked: Config.options.sidebar.cornerOpen.valueScroll
                        onEdited: { Config.options.sidebar.cornerOpen.valueScroll = checked }
                    }
                    ConfigSwitch {
                        visible: page.settingsShow("input-details");
                        objectName: "InterfaceConfig.visualize-region";
                        buttonIcon: "visibility"
                        text: Translation.tr("Visualize region")
                        checked: Config.options.sidebar.cornerOpen.visualize
                        onEdited: { Config.options.sidebar.cornerOpen.visualize = checked }
                    }
                    ConfigSwitch {
                        visible: page.settingsShow("input-details");
                        objectName: "InterfaceConfig.force-hover-at-absolute-corner";
                        enabled: Config.options.sidebar.cornerOpen.clickless
                        buttonIcon: "ads_click"
                        text: Translation.tr("Force hover at absolute corner")
                        checked: Config.options.sidebar.cornerOpen.clicklessCornerEnd
                        onEdited: { Config.options.sidebar.cornerOpen.clicklessCornerEnd = checked }
                    }
                    ConfigSwitch {
                        visible: page.settingsShow("input-details");
                        objectName: "InterfaceConfig.enable-hover-trigger-on-bottom-corners";
                        enabled: Config.options.sidebar.cornerOpen.clickless
                        buttonIcon: "select_all"
                        text: Translation.tr("Enable hover trigger on bottom corners")
                        checked: Config.options.sidebar.cornerOpen.hoverAllCorners
                        onEdited: { Config.options.sidebar.cornerOpen.hoverAllCorners = checked }
                    }
                    ConfigSpinBox {
                        visible: page.settingsShow("input-details");
                        objectName: "InterfaceConfig.vertical-offset";
                        enabled: Config.options.sidebar.cornerOpen.clickless
                        icon: "arrow_cool_down"
                        text: Translation.tr("Vertical offset")
                        value: Config.options.sidebar.cornerOpen.clicklessCornerVerticalOffset
                        from: 0; to: 20; stepSize: 1
                        onEdited: { Config.options.sidebar.cornerOpen.clicklessCornerVerticalOffset = value }
                    }
                    ConfigSpinBox {
                        visible: page.settingsShow("input-details");
                        objectName: "InterfaceConfig.region-width";
                        icon: "arrow_range"
                        text: Translation.tr("Region width")
                        value: Config.options.sidebar.cornerOpen.cornerRegionWidth
                        from: 1; to: 300; stepSize: 1
                        onEdited: { Config.options.sidebar.cornerOpen.cornerRegionWidth = value }
                    }
                    ConfigSpinBox {
                        visible: page.settingsShow("input-details");
                        objectName: "InterfaceConfig.region-height";
                        icon: "height"
                        text: Translation.tr("Region height")
                        value: Config.options.sidebar.cornerOpen.cornerRegionHeight
                        from: 1; to: 300; stepSize: 1
                        onEdited: { Config.options.sidebar.cornerOpen.cornerRegionHeight = value }
                    }
                    ConfigComboBox {
                        objectName: "InterfaceConfig.top-left-action";
                        visible: page.settingsShow("devices");

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
                        objectName: "InterfaceConfig.top-right-action";
                        visible: page.settingsShow("devices");

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
                        visible: page.settingsShow("devices");
                        objectName: "InterfaceConfig.left-corner-scroll";
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
                        visible: page.settingsShow("devices");
                        objectName: "InterfaceConfig.right-corner-scroll";
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
                visible: page.settingsShow("devices");

                title: Translation.tr("Bottom")
                GroupedList {
                    compact: true;
                    visible: page.settingsShow("devices");

                    ConfigComboBox {
                        objectName: "InterfaceConfig.bottom-left";
                        visible: page.settingsShow("devices");

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
                        objectName: "InterfaceConfig.bottom-right";
                        visible: page.settingsShow("devices");

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
            visible: page.settingsShow("panel-details|panels") && (WM.compositor !== "niri")
            icon: "overview_key"
            shape: MaterialShape.Shape.Gem
            title: Translation.tr("Overview")

            GroupedList {
                compact: true;
                visible: page.settingsShow("panel-details|panels")
                ConfigSwitch {
                    visible: page.settingsShow("panels");
                    objectName: "InterfaceConfig.show-workspaces-in-launcher-super";
                    buttonIcon: "workspaces"
                    text: Translation.tr("Show workspaces in launcher (SUPER)")
                    checked: Config.options.overview.showWorkspacesInLauncher
                    onEdited: { Config.options.overview.showWorkspacesInLauncher = checked }
                }

                ConfigComboBox {
                    objectName: "InterfaceConfig.launcher-position";
                    visible: page.settingsShow("panels");

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
                    visible: page.settingsShow("panel-details");
                    objectName: "InterfaceConfig.animate-center-position";
                    buttonIcon: "animation"
                    text: Translation.tr("Animate center position")
                    checked: Config.options.overview.centerAnimation ?? true
                    onEdited: { Config.options.overview.centerAnimation = checked }
                }
                ConfigSlider {
                    visible: page.settingsShow("panel-details");
                    objectName: "InterfaceConfig.center-animation-delay-ms";
                    text: Translation.tr("Center animation delay (ms)")
                    textWidth: 180
                    buttonIcon: "timer"
                    enabled: Config.options.overview.centerAnimation ?? true
                    value: Config.options.overview.centerAnimationDuration ?? 220
                    from: 0; to: 600
                    onEdited: { Config.options.overview.centerAnimationDuration = Math.round(value) }
                }
                ConfigSwitch {
                    visible: page.settingsShow("panels");
                    objectName: "InterfaceConfig.enable-4";
                    buttonIcon: "check"
                    text: Translation.tr("Enable")
                    checked: Config.options.overview.enable
                    onEdited: {
                        Config.options.overview.enable = checked;
                    }
                }
                ConfigSwitch {
                    visible: page.settingsShow("panels");
                    objectName: "InterfaceConfig.center-icons";
                    buttonIcon: "center_focus_strong"
                    text: Translation.tr("Center icons")
                    checked: Config.options.overview.centerIcons
                    onEdited: {
                        Config.options.overview.centerIcons = checked;
                    }
                }
                ConfigSpinBox {
                    visible: page.settingsShow("panel-details");
                    objectName: "InterfaceConfig.scale";
                    icon: "loupe"
                    text: Translation.tr("Scale (%)")
                    value: Config.options.overview.scale * 100
                    from: 1
                    to: 100
                    stepSize: 1
                    onEdited: {
                        Config.options.overview.scale = value / 100;
                    }
                }
                ConfigSelectionArray {
                    visible: page.settingsShow("panels");
                    objectName: "InterfaceConfig.style-3";
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
                title: Translation.tr("Grid layout")
                visible: page.settingsShow("panel-details|panels") && (Config.options.overview.style !== "niri")

                GroupedList {
                    compact: true;
                    visible: page.settingsShow("panel-details|panels") && (Config.options.overview.style !== "niri")
                    ConfigRow {
                        uniform: true
                        visible: page.settingsShow("panel-details") && (Config.options.overview.style !== "niri")
                        ConfigSpinBox {
                            visible: page.settingsShow("panel-details");
                            objectName: "InterfaceConfig.rows";
                            icon: "splitscreen_bottom"
                            text: Translation.tr("Rows")
                            value: Config.options.overview.rows
                            from: 1
                            to: 20
                            stepSize: 1
                            onEdited: {
                                Config.options.overview.rows = value;
                            }
                        }
                        ConfigSpinBox {
                            visible: page.settingsShow("panel-details");
                            objectName: "InterfaceConfig.columns-2";
                            icon: "splitscreen_right"
                            text: Translation.tr("Columns")
                            value: Config.options.overview.columns
                            from: 1
                            to: 20
                            stepSize: 1
                            onEdited: {
                                Config.options.overview.columns = value;
                            }
                        }
                    }

                    ConfigRow {
                        uniform: true
                        visible: page.settingsShow("panels") && (Config.options.overview.style !== "niri")
                        Layout.alignment: Qt.AlignHCenter
                        Layout.leftMargin: 24
                        ConfigSelectionArray {
                            visible: page.settingsShow("panels");
                            objectName: "InterfaceConfig.default-settings";
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
                            visible: page.settingsShow("panels");
                            objectName: "InterfaceConfig.default-settings-2";
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
            visible: page.settingsShow("panels");
            icon: "call_to_action"
            title: Translation.tr("Dock")
            shape: MaterialShape.Shape.Cookie6Sided

            GroupedList {
                compact: true;
                visible: page.settingsShow("panels")
                ConfigSwitch {
                    visible: page.settingsShow("panels");
                    objectName: "InterfaceConfig.enable-5";
                    buttonIcon: "check"
                    text: Translation.tr("Enable")
                    checked: Config.options.dock.enable
                    onEdited: { Config.options.dock.enable = checked }
                }
                ConfigSwitch {
                    visible: page.settingsShow("panels");
                    objectName: "InterfaceConfig.background-2";
                    buttonIcon: "background_dot_small"
                    text: Translation.tr("Background")
                    checked: Config.options.dock.showBackground
                    onEdited: { Config.options.dock.showBackground = checked }
                }
                ConfigSwitch {
                    visible: page.settingsShow("panels");
                    objectName: "InterfaceConfig.hover-to-reveal";
                    buttonIcon: "highlight_mouse_cursor"
                    text: Translation.tr("Hover to reveal")
                    checked: Config.options.dock.hoverToReveal
                    onEdited: { Config.options.dock.hoverToReveal = checked }
                }
                ConfigSwitch {
                    visible: page.settingsShow("panels");
                    objectName: "InterfaceConfig.pinned-on-startup";
                    buttonIcon: "push_pin"
                    text: Translation.tr("Pinned on startup")
                    checked: Config.options.dock.pinnedOnStartup
                    onEdited: { Config.options.dock.pinnedOnStartup = checked }
                }
            }


            ContentSubsection {
                visible: page.settingsShow("panels");
                title: Translation.tr("Buttons & Media")
                GroupedList {
                    compact: true;
                    visible: page.settingsShow("panels")
                    ConfigSwitch {
                        visible: page.settingsShow("panels");
                        objectName: "InterfaceConfig.media-player-2";
                        buttonIcon: "music_note"
                        text: Translation.tr("Media Player")
                        checked: Config.options.dock.showMedia
                        onEdited: { Config.options.dock.showMedia = checked }
                    }
                    ConfigSwitch {
                        visible: page.settingsShow("panels");
                        objectName: "InterfaceConfig.show-pin-button";
                        buttonIcon: "keep"
                        text: Translation.tr("Show Pin Button")
                        checked: Config.options.dock.showPinButton
                        onEdited: { Config.options.dock.showPinButton = checked }
                    }
                    ConfigSwitch {
                        visible: page.settingsShow("panels");
                        objectName: "InterfaceConfig.show-apps-button";
                        buttonIcon: "apps"
                        text: Translation.tr("Show Apps Button")
                        checked: Config.options.dock.showAppsButton
                        onEdited: { Config.options.dock.showAppsButton = checked }
                    }
                    ConfigSwitch {
                        visible: page.settingsShow("panels");
                        objectName: "InterfaceConfig.use-original-icon-colors";
                        buttonIcon: "colors"
                        text: Translation.tr("Use original icon colors")
                        checked: !Config.options.dock.monochromeIcons
                        onEdited: { Config.options.dock.monochromeIcons = !checked }
                    }
                }
            }
        }

        ContentSection {
            visible: page.settingsShow("appearance");
            icon: "palette"
            title: Translation.tr("System themes")
            shape: MaterialShape.Shape.Cookie7Sided

            GroupedList {
                compact: true;
                visible: page.settingsShow("appearance")
                ConfigComboBox {
                    objectName: "InterfaceConfig.system-icon-theme";
                    visible: page.settingsShow("appearance");

                    buttonIcon: "palette"
                    text: Translation.tr("System icon theme")
                    description: Translation.tr("Applies to GTK, Qt/XSettings, and desktop applications")
                    model: SystemTheming.iconThemes.map(theme => ({ displayName: theme, value: theme }))
                    currentValue: SystemTheming.currentIconTheme
                    onSelected: theme => SystemTheming.applyIconTheme(theme)
                }
                ConfigComboBox {
                    objectName: "InterfaceConfig.mouse-cursor-theme";
                    visible: page.settingsShow("appearance");

                    buttonIcon: "mouse"
                    text: Translation.tr("Mouse cursor theme")
                    description: Translation.tr("Applies across the desktop and compatible applications")
                    model: SystemTheming.cursorThemes.map(theme => ({ displayName: theme, value: theme }))
                    currentValue: SystemTheming.currentCursorTheme
                    onSelected: theme => SystemTheming.applyCursorTheme(theme, SystemTheming.currentCursorSize)
                }
                ConfigSpinBox {
                    visible: page.settingsShow("appearance");
                    objectName: "InterfaceConfig.cursor-size";
                    id: cursorSizeControl
                    icon: "format_size"
                    text: Translation.tr("Cursor size")
                    value: SystemTheming.currentCursorSize
                    from: 16; to: 96; stepSize: 2
                    onEdited: cursorSizeTimer.restart()
                    Timer {
                        id: cursorSizeTimer
                        interval: 400
                        onTriggered: SystemTheming.applyCursorTheme(SystemTheming.currentCursorTheme, cursorSizeControl.value)
                    }
                }
            }
        }

        ContentSection {
            visible: page.settingsShow("session|session-details");
            icon: "lock"
            title: Translation.tr("Lock screen")
            shape: MaterialShape.Shape.Pentagon

            GroupedList {
                compact: true;
                visible: page.settingsShow("session|session-details")
                ConfigSwitch {
                    visible: page.settingsShow("session-details");
                    objectName: "InterfaceConfig.use-hyprlock-instead-of-quickshell";
                    buttonIcon: "water_drop"
                    text: Translation.tr("Use Hyprlock (instead of Quickshell)")
                    checked: Config.options.lock.useHyprlock
                    onEdited: { Config.options.lock.useHyprlock = checked }
                }
                ConfigSwitch {
                    visible: page.settingsShow("session");
                    objectName: "InterfaceConfig.launch-on-startup";
                    buttonIcon: "account_circle"
                    text: Translation.tr("Launch on startup")
                    checked: Config.options.lock.launchOnStartup
                    onEdited: { Config.options.lock.launchOnStartup = checked }
                }
                ConfigSwitch {
                    visible: page.settingsShow("session");
                    objectName: "InterfaceConfig.show-widgets";
                    buttonIcon: "widgets"
                    enabled: WM.compositor !== "niri"
                    text: Translation.tr("Show Widgets")
                    checked: Config.options.lock.showWidgets
                    onEdited: { Config.options.lock.showWidgets = checked }
                }
                ConfigSwitch {
                    visible: page.settingsShow("session");
                    objectName: "InterfaceConfig.show-toolbars";
                    buttonIcon: "tools_installation_kit"
                    text: Translation.tr("Show Toolbars")
                    checked: Config.options.lock.showToolbars
                    onEdited: { Config.options.lock.showToolbars = checked }
                }
                ConfigSwitch {
                    visible: page.settingsShow("session");
                    objectName: "InterfaceConfig.show-left-toolbar-username-media";
                    buttonIcon: "left_panel_open"
                    enabled: Config.options.lock.showToolbars
                    text: Translation.tr("Show left toolbar (username/media)")
                    checked: Config.options.lock.showLeftToolbar
                    onEdited: { Config.options.lock.showLeftToolbar = checked }
                }
                ConfigSwitch {
                    visible: page.settingsShow("session");
                    objectName: "InterfaceConfig.show-right-toolbar-battery-power";
                    buttonIcon: "right_panel_open"
                    enabled: Config.options.lock.showToolbars
                    text: Translation.tr("Show right toolbar (battery/power)")
                    checked: Config.options.lock.showRightToolbar
                    onEdited: { Config.options.lock.showRightToolbar = checked }
                }
                ConfigSwitch {
                    visible: page.settingsShow("session");
                    objectName: "InterfaceConfig.show-media-player-info";
                    buttonIcon: "music_note"
                    enabled: Config.options.lock.showToolbars && Config.options.lock.showLeftToolbar
                    text: Translation.tr("Show media player info")
                    checked: Config.options.lock.showMedia
                    onEdited: { Config.options.lock.showMedia = checked }
                }
                ConfigSwitch {
                    visible: page.settingsShow("session");
                    objectName: "InterfaceConfig.hide-lock-controls-when-idle";
                    buttonIcon: "visibility_off"
                    text: Translation.tr("Hide lock controls when idle")
                    checked: Config.options.lock.autoHideControls
                    onEdited: Config.options.lock.autoHideControls = checked
                }
                ConfigSpinBox {
                    visible: page.settingsShow("session");
                    objectName: "InterfaceConfig.hide-controls-after-seconds";
                    icon: "timer"
                    enabled: Config.options.lock.autoHideControls
                    text: Translation.tr("Hide controls after (seconds)")
                    value: Config.options.lock.controlsIdleSeconds
                    from: 5; to: 120; stepSize: 5
                    onEdited: Config.options.lock.controlsIdleSeconds = value
                }
                ConfigSwitch {
                    visible: page.settingsShow("session-details");
                    objectName: "InterfaceConfig.customize-lock-layout-per-display";
                    buttonIcon: "monitor"
                    text: Translation.tr("Customize lock layout per display")
                    checked: Config.options.lock.perScreenLayout
                    onEdited: Config.options.lock.perScreenLayout = checked
                }
                ConfigComboBox {
                    objectName: "InterfaceConfig.primary-lock-controls-monitor";
                    visible: page.settingsShow("session-details");

                    buttonIcon: "desktop_windows"
                    text: Translation.tr("Primary lock-controls monitor")
                    description: Translation.tr("Used when the unlock box is limited to one monitor")
                    model: [
                        { displayName: Translation.tr("First connected monitor"), value: "" },
                        ...Quickshell.screens.map(screen => ({ displayName: screen.name, value: screen.name }))
                    ]
                    currentValue: Config.options.lock.primaryMonitor
                    onSelected: newValue => Config.options.lock.primaryMonitor = newValue
                }
                ConfigSwitch {
                    visible: page.settingsShow("session-details");
                    objectName: "InterfaceConfig.unlock-box-just-on-the-primary-monitor";
                    buttonIcon: "lock"
                    text: Translation.tr("Unlock box just on the primary monitor")
                    checked: Config.options.lock.unlockBoxPrimaryMonitorOnly
                    onEdited: Config.options.lock.unlockBoxPrimaryMonitorOnly = checked
                }
            }

            ContentSubsection {
                visible: page.settingsShow("session");
                title: Translation.tr("Live preview")
                GroupedList {
                    compact: true;
                    visible: page.settingsShow("session")
                    RippleButton {
                        visible: page.settingsShow("session");
                        objectName: "InterfaceConfig.lock-screen-live-preview";
                        Layout.fillWidth: true
                        implicitHeight: 44
                        toggled: GlobalStates.lockPreviewOpen
                        buttonRadius: Appearance.rounding.normal
                        colBackground: Appearance.colors.colLayer1
                        colBackgroundToggled: Appearance.colors.colPrimaryContainer
                        onClicked: {
                            if (GlobalStates.lockPreviewOpen) {
                                GlobalStates.cancelLockPreview()
                            } else {
                                GlobalStates.beginLockPreview()
                                Config.options.lock.showWidgets = true
                            }
                        }
                        contentItem: RowLayout {
                            spacing: 10
                            MaterialSymbol {
                                text: GlobalStates.lockPreviewOpen ? "visibility_off" : "preview"
                                iconSize: Appearance.font.pixelSize.large
                                color: GlobalStates.lockPreviewOpen ? Appearance.colors.colOnPrimaryContainer : Appearance.colors.colPrimary
                            }
                            StyledText {
                                Layout.fillWidth: true
                                text: GlobalStates.lockPreviewOpen
                                    ? Translation.tr("Exit live lock-screen preview")
                                    : Translation.tr("Edit lock-screen layout live")
                                color: GlobalStates.lockPreviewOpen ? Appearance.colors.colOnPrimaryContainer : Appearance.colors.colOnLayer1
                            }
                        }
                    }
                    StyledText {
                        property bool groupDescription: true;
                        visible: page.settingsShow("session");
                        Layout.fillWidth: true
                        wrapMode: Text.Wrap
                        color: Appearance.colors.colSubtext
                        font.pixelSize: Appearance.font.pixelSize.small
                        text: Translation.tr("Shows the lock wallpaper and all permitted widgets on every monitor without locking the session. Drag widgets directly; positions are saved independently of the desktop. Choose widgets in the editor or below.")
                    }
                }
            }



            ContentSubsection {
                visible: page.settingsShow("session|session-details");
                title: Translation.tr("Security")
                GroupedList {
                    compact: true;
                    visible: page.settingsShow("session|session-details")
                    ConfigSwitch {
                        visible: page.settingsShow("session");
                        objectName: "InterfaceConfig.require-password-to-power-off-restart";
                        buttonIcon: "settings_power"
                        text: Translation.tr("Require password to power off/restart")
                        checked: Config.options.lock.security.requirePasswordToPower
                        onEdited: { Config.options.lock.security.requirePasswordToPower = checked }
                    }
                    ConfigSwitch {
                        visible: page.settingsShow("session-details");
                        objectName: "InterfaceConfig.also-unlock-keyring";
                        buttonIcon: "key_vertical"
                        text: Translation.tr("Also unlock keyring")
                        checked: Config.options.lock.security.unlockKeyring
                        onEdited: { Config.options.lock.security.unlockKeyring = checked }
                    }
                }
            }

            ContentSubsection {
                visible: page.settingsShow("session|session-details");
                title: Translation.tr("Biometrics")
                GroupedList {
                    compact: true;
                    visible: page.settingsShow("session|session-details")
                    ConfigSwitch {
                        visible: page.settingsShow("session");
                        objectName: "InterfaceConfig.enable-fingerprint-unlock-fprintd-pam";
                        buttonIcon: "fingerprint"
                        text: Translation.tr("Enable fingerprint unlock (fprintd / PAM)")
                        checked: Config.options.lock.biometrics.enableFingerprint
                        onEdited: Config.options.lock.biometrics.enableFingerprint = checked
                    }
                    ConfigSwitch {
                        visible: page.settingsShow("session-details");
                        objectName: "InterfaceConfig.start-fingerprint-scan-when-locked";
                        buttonIcon: "touch_app"
                        enabled: Config.options.lock.biometrics.enableFingerprint
                        text: Translation.tr("Start fingerprint scan when locked")
                        checked: Config.options.lock.biometrics.autoStartFingerprint
                        onEdited: Config.options.lock.biometrics.autoStartFingerprint = checked
                    }
                    ConfigSwitch {
                        visible: page.settingsShow("session-details");
                        objectName: "InterfaceConfig.animate-biometric-sensor";
                        buttonIcon: "animation"
                        text: Translation.tr("Animate biometric sensor")
                        checked: Config.options.lock.biometrics.showSensorAnimation
                        onEdited: Config.options.lock.biometrics.showSensorAnimation = checked
                    }
                    ConfigSwitch {
                        visible: page.settingsShow("session");
                        objectName: "InterfaceConfig.enable-face-id-ir-camera-authentication";
                        buttonIcon: "face"
                        text: Translation.tr("Enable Face ID / IR camera authentication")
                        checked: Config.options.lock.biometrics.enableFaceAuth
                        onEdited: Config.options.lock.biometrics.enableFaceAuth = checked
                    }
                    ConfigSwitch {
                        visible: page.settingsShow("session-details");
                        objectName: "InterfaceConfig.start-face-id-scan-when-locked";
                        buttonIcon: "visibility"
                        enabled: Config.options.lock.biometrics.enableFaceAuth
                        text: Translation.tr("Start Face ID scan when locked")
                        checked: Config.options.lock.biometrics.autoStartFaceAuth
                        onEdited: Config.options.lock.biometrics.autoStartFaceAuth = checked
                    }
                    ConfigSpinBox {
                        visible: page.settingsShow("session-details");
                        objectName: "InterfaceConfig.face-scan-timeout-seconds";
                        icon: "timer"
                        enabled: Config.options.lock.biometrics.enableFaceAuth
                        text: Translation.tr("Face scan timeout (seconds)")
                        value: Config.options.lock.biometrics.faceTimeoutSeconds
                        from: 1; to: 60; stepSize: 1
                        onEdited: Config.options.lock.biometrics.faceTimeoutSeconds = value
                    }
                    ConfigTextArea {
                        visible: page.settingsShow("session-details");
                        objectName: "InterfaceConfig.face-authentication-command";
                        Layout.fillWidth: true
                        fieldWidth: 330
                        enabled: Config.options.lock.biometrics.enableFaceAuth
                        buttonIcon: "terminal"
                        text: Translation.tr("Face authentication command")
                        description: Translation.tr("Runs only from the lock screen. It must return exit code 0 only after successful identity verification.")
                        value: Config.options.lock.biometrics.faceCommand
                        onEdited: Config.options.lock.biometrics.faceCommand = value
                    }
                    StyledText {
                        property bool groupDescription: true;
                        visible: page.settingsShow("session-details");
                        Layout.fillWidth: true
                        wrapMode: Text.Wrap
                        color: Appearance.colors.colSubtext
                        text: Translation.tr("The default command is ‘howdy test’. Replace it with your installed Face ID script if needed; the lock unlocks only when that command exits successfully.")
                    }
                }
            }

            ContentSubsection {
                visible: page.settingsShow("session|session-details");
                title: Translation.tr("Layout")
                GroupedList {
                    compact: true;
                    visible: page.settingsShow("session|session-details")
                    ConfigSwitch {
                        visible: page.settingsShow("session");
                        objectName: "InterfaceConfig.center-clock";
                        buttonIcon: "center_focus_weak"
                        text: Translation.tr("Center clock")
                        checked: Config.options.lock.centerClock
                        onEdited: { Config.options.lock.centerClock = checked }
                    }
                    ConfigSwitch {
                        visible: page.settingsShow("session");
                        objectName: "InterfaceConfig.show-locked-text";
                        buttonIcon: "info"
                        text: Translation.tr('Show "Locked" text')
                        checked: Config.options.lock.showLockedText
                        onEdited: { Config.options.lock.showLockedText = checked }
                    }
                    ConfigSwitch {
                        visible: page.settingsShow("session-details");
                        objectName: "InterfaceConfig.use-varying-shapes-for-password-characters";
                        buttonIcon: "shapes"
                        text: Translation.tr("Use varying shapes for password characters")
                        checked: Config.options.lock.materialShapeChars
                        onEdited: { Config.options.lock.materialShapeChars = checked }
                    }
                }
            }

            ContentSubsection {
                visible: page.settingsShow("session-details");
                title: Translation.tr("Password and sensor position")
                GroupedList {
                    compact: true;
                    visible: page.settingsShow("session-details")
                    ConfigSelectionArray {
                        visible: page.settingsShow("session-details");
                        objectName: "InterfaceConfig.password-controls-position";
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
                    ConfigSpinBox {
                        visible: page.settingsShow("session-details");
                        objectName: "InterfaceConfig.bottom-margin";
                        icon: "vertical_align_bottom"
                        text: Translation.tr("Bottom margin")
                        enabled: Config.options.lock.layout.passwordPlacement !== "center"
                        value: Config.options.lock.layout.bottomMargin
                        from: 0; to: 400; stepSize: 4
                        onEdited: Config.options.lock.layout.bottomMargin = value
                    }
                    StyledText {
                        property bool groupDescription: true;
                        visible: page.settingsShow("session-details");
                        Layout.fillWidth: true
                        wrapMode: Text.Wrap
                        color: Appearance.colors.colSubtext
                        font.pixelSize: Appearance.font.pixelSize.small
                        text: Translation.tr("Fine-tune each element below independently - the password box, and the left/right toolbars, each used to share one offset and could only move together. Now every one below moves on its own.")
                    }
                }
            }

            ContentSubsection {
                visible: page.settingsShow("session-details");
                title: Translation.tr("Element positions")

                component ElementOffsetControls: GroupedList {
                                                     compact: true;
                    required property string label
                    required property string groupKey
                    ConfigRow {
                        uniform: true
                        StyledText {
                            Layout.fillWidth: true
                            text: label
                            font.pixelSize: Appearance.font.pixelSize.normal
                            color: Appearance.colors.colOnLayer1
                        }
                    }
                    ConfigRow {
                        uniform: true
                        ConfigSpinBox {
                            icon: "swap_horiz"
                            text: Translation.tr("Horizontal offset")
                            value: Config.options.lock.layout[groupKey].offsetX
                            from: -800; to: 800; stepSize: 4
                            onEdited: Config.options.lock.layout[groupKey].offsetX = value
                        }
                        ConfigSpinBox {
                            icon: "swap_vert"
                            text: Translation.tr("Vertical offset")
                            value: Config.options.lock.layout[groupKey].offsetY
                            from: -600; to: 600; stepSize: 4
                            onEdited: Config.options.lock.layout[groupKey].offsetY = value
                        }
                        ConfigSpinBox {
                            icon: "zoom_in"
                            text: Translation.tr("Scale (%)")
                            value: Math.round(Config.options.lock.layout[groupKey].scale * 100)
                            from: 70; to: 160; stepSize: 5
                            onEdited: Config.options.lock.layout[groupKey].scale = value / 100
                        }
                    }
                }

                ColumnLayout {
                    visible: page.settingsShow("session-details");
                    Layout.fillWidth: true
                    spacing: 12
                    ElementOffsetControls {
                        visible: page.settingsShow("session-details");
                        objectName: "InterfaceConfig.element-positions"; Layout.fillWidth: true; label: Translation.tr("Password box"); groupKey: "password" }
                    ElementOffsetControls {
                        objectName: "InterfaceConfig.element-positions-2"; Layout.fillWidth: true; label: Translation.tr("Left toolbar (username, media, keyboard layout)"); groupKey: "leftToolbar"; visible: page.settingsShow("session-details") && (Config.options.lock.showLeftToolbar)}
                    ElementOffsetControls {
                        objectName: "InterfaceConfig.element-positions-3"; Layout.fillWidth: true; label: Translation.tr("Right toolbar (battery, sleep, power)"); groupKey: "rightToolbar"; visible: page.settingsShow("session-details") && (Config.options.lock.showRightToolbar)}
                }
            }

            ContentSubsection {
                visible: page.settingsShow("session-details");
                title: Translation.tr("Background blur")
                GroupedList {
                    compact: true;
                    visible: page.settingsShow("session-details")
                    ConfigSwitch {
                        visible: page.settingsShow("session-details");
                        objectName: "InterfaceConfig.enable-blur";
                        buttonIcon: "blur_on"
                        text: Translation.tr("Enable blur")
                        checked: Config.options.lock.blur.enable
                        onEdited: { Config.options.lock.blur.enable = checked }
                    }
                    ConfigSpinBox {
                        visible: page.settingsShow("session-details");
                        objectName: "InterfaceConfig.samples";
                        icon: "deblur"
                        text: Translation.tr("Samples")
                        value: Config.options.lock.blur.size
                        from: 20; to: 200; stepSize: 10
                        onEdited: { Config.options.lock.blur.size = value }
                    }
                    ConfigSpinBox {
                        visible: page.settingsShow("session-details");
                        objectName: "InterfaceConfig.extra-wallpaper-zoom";
                        icon: "loupe"
                        text: Translation.tr("Extra wallpaper zoom (%)")
                        value: Config.options.lock.blur.extraZoom * 100
                        from: 1; to: 150; stepSize: 2
                        onEdited: { Config.options.lock.blur.extraZoom = value / 100 }
                    }
                }
            }
        }

        ContentSection {
            visible: page.settingsShow("capture-details");
            icon: "select_window"
            shape: MaterialShape.Shape.SoftBurst
            title: Translation.tr("Overlay")

            GroupedList {
                compact: true;
                visible: page.settingsShow("capture-details")
                ConfigSwitch {
                    visible: page.settingsShow("capture-details");
                    objectName: "InterfaceConfig.show-app-launch-indicator";
                    buttonIcon: "hourglass_top"
                    text: Translation.tr("Show app launch indicator")
                    checked: Config.options.appLaunch.showIndicator
                    onEdited: { Config.options.appLaunch.showIndicator = checked }
                }
                ConfigSwitch {
                    visible: page.settingsShow("capture-details");
                    objectName: "InterfaceConfig.keep-indicator-above-windows";
                    buttonIcon: "layers"
                    text: Translation.tr("Keep indicator above windows")
                    checked: Config.options.appLaunch.aboveWindows
                    onEdited: { Config.options.appLaunch.aboveWindows = checked }
                }
                ConfigSpinBox {
                    visible: page.settingsShow("capture-details");
                    objectName: "InterfaceConfig.launch-indicator-timeout-ms";
                    icon: "timer"
                    text: Translation.tr("Launch indicator timeout (ms)")
                    value: Config.options.appLaunch.timeout
                    from: 1000; to: 30000; stepSize: 500
                    onEdited: { Config.options.appLaunch.timeout = value }
                }
                ConfigSwitch {
                    visible: page.settingsShow("capture-details");
                    objectName: "InterfaceConfig.track-file-manager-launches";
                    buttonIcon: "folder_open"
                    text: Translation.tr("Show indicator for apps opened by file managers")
                    checked: Config.options.appLaunch.trackExternal ?? false
                    onEdited: { Config.options.appLaunch.trackExternal = checked }
                }
                Rectangle {
                    visible: page.settingsShow("capture-details") && (Config.options.appLaunch.trackExternal ?? false);
                    Layout.fillWidth: true
                    implicitHeight: warnCol.implicitHeight + 20
                    radius: Appearance.rounding.normal
                    color: Qt.rgba(Appearance.colors.colError.r, Appearance.colors.colError.g, Appearance.colors.colError.b, 0.12)
                    border.width: 1
                    border.color: Qt.rgba(Appearance.colors.colError.r, Appearance.colors.colError.g, Appearance.colors.colError.b, 0.45)

                    ColumnLayout {
                        id: warnCol
                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 6

                        RowLayout {
                            spacing: 8
                            MaterialSymbol {
                                text: "warning"
                                iconSize: 20
                                color: Appearance.colors.colError
                            }
                            StyledText {
                                text: Translation.tr("Warning: Performance & Cursor Hang Risks")
                                font.weight: Font.DemiBold
                                font.pixelSize: Appearance.font.pixelSize.small
                                color: Appearance.colors.colError
                            }
                        }

                        StyledText {
                            Layout.fillWidth: true
                            wrapMode: Text.Wrap
                            font.pixelSize: Appearance.font.pixelSize.smaller
                            color: Appearance.colors.colOnSecondaryContainer
                            text: Translation.tr("Enabling this triggers the indicator whenever files are opened from Dolphin, Thunar, or other file managers. Outside KDE Plasma (such as in Hyprland), file managers can cause the system busy cursor to freeze, introduce launch lag, or delay desktop interactions.")
                        }
                    }
                }
                ConfigSwitch {
                    visible: page.settingsShow("capture-details");
                    objectName: "InterfaceConfig.enable-opening-zoom-animation";
                    buttonIcon: "high_density"
                    text: Translation.tr("Enable opening zoom animation")
                    checked: Config.options.overlay.openingZoomAnimation
                    onEdited: {
                        Config.options.overlay.openingZoomAnimation = checked;
                    }
                }
                ConfigSwitch {
                    visible: page.settingsShow("capture-details");
                    objectName: "InterfaceConfig.darken-screen";
                    buttonIcon: "texture"
                    text: Translation.tr("Darken screen")
                    checked: Config.options.overlay.darkenScreen
                    onEdited: {
                        Config.options.overlay.darkenScreen = checked;
                    }
                }
            }

            ContentSubsection {
                visible: page.settingsShow("capture-details");
                title: Translation.tr("Floating Image")
                GroupedList {
                    compact: true;
                    visible: page.settingsShow("capture-details")
                    ConfigTextArea {
                        visible: page.settingsShow("capture-details");
                        objectName: "InterfaceConfig.image-source";
                        id: floatingImageSourceField
                        Layout.fillWidth: true
                        fieldWidth: 430
                        buttonIcon: "imagesmode"
                        text: Translation.tr("Image source")
                        value: Config.options.overlay.floatingImage.imageSource
                        onEdited: {
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
                visible: page.settingsShow("capture-details");
                title: Translation.tr("Crosshair")

                Rectangle {
                    visible: page.settingsShow("capture-details");
                    id: crosshairCard
                    Layout.fillWidth: true
                    implicitHeight: crosshairCol.implicitHeight + 28
                    radius: Appearance.rounding.normal
                    color: Appearance.colors.colLayer1

                    ColumnLayout {
                        visible: page.settingsShow("capture-details");
                        id: crosshairCol
                        anchors { fill: parent; margins: 14 }
                        spacing: 8

                        ConfigTextArea {
                            visible: page.settingsShow("capture-details");
                            objectName: "InterfaceConfig.crosshair-code";
                            id: crosshairCodeField
                            Layout.fillWidth: true
                            buttonIcon: "point_scan"
                            text: Translation.tr("Crosshair code")
                            placeholderText: Translation.tr("Crosshair code (in Valorant's format)")
                            value: Config.options.crosshair.code
                            onEdited: {
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
                            visible: page.settingsShow("capture-details");
                            Layout.fillWidth: true
                            StyledText {
                                visible: page.settingsShow("capture-details");
                                Layout.leftMargin: 8
                                Layout.fillWidth: true
                                text: Translation.tr("Press Super+G to open the overlay and pin the crosshair")
                                font.pixelSize: Appearance.font.pixelSize.smaller
                                color: Appearance.colors.colSubtext
                                wrapMode: Text.Wrap
                            }
                            RippleButtonWithIcon {
                                visible: page.settingsShow("capture-details");
                                objectName: "InterfaceConfig.open-editor";
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
            visible: page.settingsShow("capture-details");
            icon: "screenshot_frame_2"
            shape: MaterialShape.Shape.PuffyDiamond
            title: Translation.tr("Region selection")

            ContentSubsection {
                visible: page.settingsShow("capture-details");
                title: Translation.tr("Hint target regions")
                GroupedList {
                    compact: true;
                    visible: page.settingsShow("capture-details")
                    ConfigSwitch {
                        visible: page.settingsShow("capture-details");
                        objectName: "InterfaceConfig.windows";
                        buttonIcon: "select_window"
                        text: Translation.tr('Windows')
                        checked: Config.options.regionSelector.targetRegions.windows
                        onEdited: {
                            Config.options.regionSelector.targetRegions.windows = checked;
                        }
                    }
                    ConfigSwitch {
                        visible: page.settingsShow("capture-details");
                        objectName: "InterfaceConfig.layers";
                        buttonIcon: "right_panel_open"
                        text: Translation.tr('Layers')
                        checked: Config.options.regionSelector.targetRegions.layers
                        onEdited: {
                            Config.options.regionSelector.targetRegions.layers = checked;
                        }
                    }
                    ConfigSwitch {
                        visible: page.settingsShow("capture-details");
                        objectName: "InterfaceConfig.content-2";
                        buttonIcon: "nearby"
                        text: Translation.tr('Content')
                        checked: Config.options.regionSelector.targetRegions.content
                        onEdited: {
                            Config.options.regionSelector.targetRegions.content = checked;
                        }
                    }
                }
            }

            ContentSubsection {
                visible: page.settingsShow("capture-details");
                title: Translation.tr("Google Lens")

                GroupedList {
                    compact: true;
                    visible: page.settingsShow("capture-details")
                    ConfigSelectionArray {
                        visible: page.settingsShow("capture-details");
                        objectName: "InterfaceConfig.selection-type";
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
                visible: page.settingsShow("capture-details");
                title: Translation.tr("Rectangular selection")
                GroupedList {
                    compact: true;
                    visible: page.settingsShow("capture-details")
                    ConfigSwitch {
                        visible: page.settingsShow("capture-details");
                        objectName: "InterfaceConfig.show-aim-lines";
                        buttonIcon: "point_scan"
                        text: Translation.tr("Show aim lines")
                        checked: Config.options.regionSelector.rect.showAimLines
                        onEdited: {
                            Config.options.regionSelector.rect.showAimLines = checked;
                        }
                    }
                }
            }

            ContentSubsection {
                visible: page.settingsShow("capture-details");
                title: Translation.tr("Circle selection")

                GroupedList {
                    compact: true;
                    visible: page.settingsShow("capture-details")
                    ConfigSpinBox {
                        visible: page.settingsShow("capture-details");
                        objectName: "InterfaceConfig.stroke-width";
                        icon: "eraser_size_3"
                        text: Translation.tr("Stroke width")
                        value: Config.options.regionSelector.circle.strokeWidth
                        from: 1
                        to: 20
                        stepSize: 1
                        onEdited: {
                            Config.options.regionSelector.circle.strokeWidth = value;
                        }
                    }

                    ConfigSpinBox {
                        visible: page.settingsShow("capture-details");
                        objectName: "InterfaceConfig.padding";
                        icon: "screenshot_frame_2"
                        text: Translation.tr("Padding")
                        value: Config.options.regionSelector.circle.padding
                        from: 0
                        to: 100
                        stepSize: 5
                        onEdited: {
                            Config.options.regionSelector.circle.padding = value;
                        }
                    }
                }
            }
        }

        ContentSection {
            visible: page.settingsShow("notification-rules");
            icon: "voting_chip"
            shape: MaterialShape.Shape.Sunny
            title: Translation.tr("On-screen display")
            GroupedList {
                compact: true;
                visible: page.settingsShow("notification-rules")
                ConfigSpinBox {
                    visible: page.settingsShow("notification-rules");
                    objectName: "InterfaceConfig.timeout-ms";
                    icon: "av_timer"
                    text: Translation.tr("Timeout (ms)")
                    value: Config.options.osd.timeout
                    from: 100
                    to: 3000
                    stepSize: 100
                    onEdited: {
                        Config.options.osd.timeout = value;
                    }
                }
            }
        }

        ContentSection {
            visible: page.settingsShow("appearance|panel-details");
            shape: MaterialShape.Shape.Puffy
            icon: "panorama"
            title: Translation.tr("Wallpaper selector")

            GroupedList {
                compact: true;
                visible: page.settingsShow("appearance|panel-details")
                ConfigSwitch {
                    objectName: "InterfaceConfig.attach-to-the-m3-island";
                    buttonIcon: "dock_to_bottom"
                    visible: page.settingsShow("panel-details") && (Config.options.bar.barMode === "m3Island")
                    text: Translation.tr('Attach to the M3 island')
                    checked: Config.options.wallpaperSelector.dockToIsland
                    onEdited: {
                        Config.options.wallpaperSelector.dockToIsland = checked;
                    }
                }
                StyledText {
                    property bool groupDescription: true;
                    visible: Config.options.bar.barMode === "m3Island"
                    Layout.fillWidth: true
                    wrapMode: Text.Wrap
                    color: Appearance.colors.colSubtext
                    font.pixelSize: Appearance.font.pixelSize.small
                    text: Translation.tr("Opens the selector against the island's real edge - tracking it as the pill morphs and moves - with the same concave corners the island uses to meet the screen edge, so it reads as a drawer pulled out of the island instead of a separate panel underneath it. Off falls back to the fixed bar-height offset, which the island doesn't actually have.")
                }
                ConfigSwitch {
                    visible: page.settingsShow("panel-details");
                    objectName: "InterfaceConfig.use-system-file-picker";
                    buttonIcon: "ad"
                    text: Translation.tr('Use system file picker')
                    checked: Config.options.wallpaperSelector.useSystemFileDialog
                    onEdited: {
                        Config.options.wallpaperSelector.useSystemFileDialog = checked;
                    }
                }

                ConfigSwitch {
                    visible: page.settingsShow("panel-details");
                    objectName: "InterfaceConfig.show-home-directory-in-quick-access";
                    buttonIcon: "home"
                    text: Translation.tr('Show home directory in quick access')
                    checked: Config.options.wallpaperSelector.showHomePath
                    onEdited: {
                        Config.options.wallpaperSelector.showHomePath = checked;
                    }
                }

                ConfigSwitch {
                    visible: page.settingsShow("panel-details");
                    objectName: "InterfaceConfig.close-after-selection";
                    buttonIcon: "done"
                    text: Translation.tr('Close after selection')
                    checked: Config.options.wallpaperSelector.closeAfterSelection
                    onEdited: {
                        Config.options.wallpaperSelector.closeAfterSelection = checked;
                    }
                }

                ConfigSwitch {
                    visible: page.settingsShow("panel-details");
                    objectName: "InterfaceConfig.show-blur-background";
                    buttonIcon: "blur_on"
                    text: Translation.tr('Show blur background')
                    checked: Config.options.wallpaperSelector.showBlurBackground
                    onEdited: {
                        Config.options.wallpaperSelector.showBlurBackground = checked;
                    }
                }

                ConfigSpinBox {
                    visible: page.settingsShow("panel-details");
                    objectName: "InterfaceConfig.columns-in-grid-view";
                    icon: "grid_on"
                    text: Translation.tr("Columns in grid view")
                    value: Config.options.wallpaperSelector.columns
                    from: 3
                    to: 10
                    stepSize: 1
                    onEdited: {
                        Config.options.wallpaperSelector.columns = value;
                    }
                }



                ConfigSwitch {
                    visible: page.settingsShow("panel-details");
                    objectName: "InterfaceConfig.always-show-search-bar";
                    buttonIcon: "search"
                    text: Translation.tr('Always show search bar')
                    checked: Config.options.wallpaperSelector.showSearchbar
                    onEdited: {
                        Config.options.wallpaperSelector.showSearchbar = checked;
                    }
                }
                ConfigTextArea {
                    visible: page.settingsShow("appearance");
                    objectName: "InterfaceConfig.custom-wallpaper-folder";
                    id: userPathField
                    Layout.fillWidth: true
                    buttonIcon: "folder"
                    text: Translation.tr("Custom Wallpaper Folder")
                    placeholderText: Translation.tr("e.g., /home/user/Pictures")
                    fieldWidth: 300
                    value: Config.options.wallpaperSelector.userPath ?? ""

                    onEdited: {
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
                    visible: page.settingsShow("appearance");
                    objectName: "InterfaceConfig.live-wallpaper-folder";
                    id: liveWallpapersPathField
                    Layout.fillWidth: true
                    buttonIcon: "video_template"
                    text: Translation.tr("Live Wallpaper Folder")
                    placeholderText: Translation.tr("e.g., /home/user/Videos/Wallpapers")
                    fieldWidth: 300
                    value: Config.options.wallpaperSelector.liveWallpapersPath ?? ""

                    onEdited: {
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
            visible: page.settingsShow("appearance|effects");
            icon: "text_format"
            shape: MaterialShape.Shape.Arrow
            title: Translation.tr("Fonts")

            GroupedList {
                compact: true;
                visible: page.settingsShow("appearance|effects")
                ConfigTextArea {
                    visible: page.settingsShow("appearance");
                    objectName: "InterfaceConfig.font-family-name-e-g-google-sans-flex";
                    id: mainFontField
                    Layout.fillWidth: true
                    buttonIcon: "font_download"
                    text: Translation.tr("Font family name (e.g., Google Sans Flex)")
                    value: Config.options.appearance.fonts.main
                    onEdited: {
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
                    visible: page.settingsShow("effects");
                    objectName: "InterfaceConfig.numbers-family-name";
                    id: numbersFontField
                    Layout.fillWidth: true
                    buttonIcon: "123"
                    text: Translation.tr("Numbers family name")
                    value: Config.options.appearance.fonts.numbers
                    onEdited: {
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
                    visible: page.settingsShow("effects");
                    objectName: "InterfaceConfig.title-family-name";
                    id: titleFontField
                    Layout.fillWidth: true
                    buttonIcon: "title"
                    text: Translation.tr("Title family name")
                    value: Config.options.appearance.fonts.title
                    onEdited: {
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
                    visible: page.settingsShow("effects");
                    objectName: "InterfaceConfig.monospace-font-name-e-g-jetbrains-mono-nf";
                    id: monospaceFontField
                    Layout.fillWidth: true
                    buttonIcon: "space_bar"
                    text: Translation.tr("Monospace font name (e.g., JetBrains Mono NF)")
                    value: Config.options.appearance.fonts.monospace
                    onEdited: {
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
                    visible: page.settingsShow("effects");
                    objectName: "InterfaceConfig.nerd-fonts-icons-e-g-jetbrains-mono-nf";
                    id: iconNerdFontField
                    Layout.fillWidth: true
                    buttonIcon: "emoticon"
                    text: Translation.tr("Nerd Fonts Icons (e.g., JetBrains Mono NF)")
                    value: Config.options.appearance.fonts.iconNerd
                    onEdited: {
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
                    visible: page.settingsShow("effects");
                    objectName: "InterfaceConfig.reading-font-name-e-g-readex-pro";
                    id: readingFontField
                    Layout.fillWidth: true
                    buttonIcon: "book_ribbon"
                    text: Translation.tr("Reading font name (e.g., Readex Pro)")
                    value: Config.options.appearance.fonts.reading
                    onEdited: {
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
                    visible: page.settingsShow("effects");
                    objectName: "InterfaceConfig.expressive-font-name-e-g-space-grotesk";
                    id: expressiveFontField
                    Layout.fillWidth: true
                    buttonIcon: "mood_heart"
                    text: Translation.tr("Expressive font name (e.g., Space Grotesk)")
                    value: Config.options.appearance.fonts.expressive
                    onEdited: {
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
            visible: page.settingsShow("effects");
            icon: "colors"
            title: Translation.tr("Color generation")
            shape: MaterialShape.Shape.VerySunny

            GroupedList {
                compact: true;
                visible: page.settingsShow("effects")
                ConfigSwitch {
                    visible: page.settingsShow("effects");
                    objectName: "InterfaceConfig.shell-utilities";
                    buttonIcon: "hardware"
                    text: Translation.tr("Shell & utilities")
                    checked: Config.options.appearance.wallpaperTheming.enableAppsAndShell
                    onEdited: { Config.options.appearance.wallpaperTheming.enableAppsAndShell = checked }
                }
                ConfigSwitch {
                    visible: page.settingsShow("effects");
                    objectName: "InterfaceConfig.qt-apps";
                    buttonIcon: "tv_options_input_settings"
                    text: Translation.tr("Qt apps")
                    checked: Config.options.appearance.wallpaperTheming.enableQtApps
                    onEdited: { Config.options.appearance.wallpaperTheming.enableQtApps = checked }
                }
                ConfigSwitch {
                    visible: page.settingsShow("effects");
                    objectName: "InterfaceConfig.terminal";
                    buttonIcon: "terminal"
                    text: Translation.tr("Terminal")
                    checked: Config.options.appearance.wallpaperTheming.enableTerminal
                    onEdited: { Config.options.appearance.wallpaperTheming.enableTerminal = checked }
                }
                ConfigRow {
                    visible: page.settingsShow("effects");
                    uniform: true
                    ConfigSwitch {
                        visible: page.settingsShow("effects");
                        objectName: "InterfaceConfig.force-dark-mode-in-terminal";
                        buttonIcon: "dark_mode"
                        text: Translation.tr("Force dark mode in terminal")
                        checked: Config.options.appearance.wallpaperTheming.terminalGenerationProps.forceDarkMode
                        onEdited: { Config.options.appearance.wallpaperTheming.terminalGenerationProps.forceDarkMode = checked }
                    }
                }
                ConfigSpinBox {
                    visible: page.settingsShow("effects");
                    objectName: "InterfaceConfig.terminal-harmony";
                    icon: "invert_colors"
                    text: Translation.tr("Terminal: Harmony (%)")
                    value: Config.options.appearance.wallpaperTheming.terminalGenerationProps.harmony * 100
                    from: 0; to: 100; stepSize: 10
                    onEdited: { Config.options.appearance.wallpaperTheming.terminalGenerationProps.harmony = value / 100 }
                }
                ConfigSpinBox {
                    visible: page.settingsShow("effects");
                    objectName: "InterfaceConfig.terminal-harmonize-threshold";
                    icon: "gradient"
                    text: Translation.tr("Terminal: Harmonize threshold")
                    value: Config.options.appearance.wallpaperTheming.terminalGenerationProps.harmonizeThreshold
                    from: 0; to: 100; stepSize: 10
                    onEdited: { Config.options.appearance.wallpaperTheming.terminalGenerationProps.harmonizeThreshold = value }
                }
                ConfigSpinBox {
                    visible: page.settingsShow("effects");
                    objectName: "InterfaceConfig.terminal-foreground-boost";
                    icon: "format_color_text"
                    text: Translation.tr("Terminal: Foreground boost (%)")
                    value: Config.options.appearance.wallpaperTheming.terminalGenerationProps.termFgBoost * 100
                    from: 0; to: 100; stepSize: 10
                    onEdited: { Config.options.appearance.wallpaperTheming.terminalGenerationProps.termFgBoost = value / 100 }
                }
            }
        }
    }
}
