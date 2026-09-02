import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import Quickshell
import QtQuick.Controls
import qs.modules.common.functions
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.models.hyprland

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
    // Helpers for keyboard and custom anims (page level for delegate access)
    function buildKbOptionsString() { return keyboardSection ? keyboardSection.buildKbOptionsString() : "" }
    function applyKbOptions() { if (keyboardSection) keyboardSection.applyKbOptions() }
    function layoutsList() { return keyboardSection ? keyboardSection.layoutsList() : [] }
    function setLayouts(list) { if (keyboardSection) keyboardSection.setLayouts(list) }
    function applyCustomAnims() {
        const curves = Config.options.hyprland.animations.customCurves
        const anims = Config.options.hyprland.animations.customAnims
        HyprlandConfig.setCustomAnims(JSON.stringify(curves), JSON.stringify(anims))
        // find custom timer if exists
        if (typeof customReloadTimer !== 'undefined') customReloadTimer.restart()
    }



    Component.onCompleted: {
        const h = Config.options.hyprland
        // Build combined kb_options (base + switch shortcut)
        let kbOptionsCombined = (h.input.kbOptions ?? "").trim()
        const sw = (h.input.kbLayoutSwitchShortcut ?? "").trim()
        if (sw) {
            if (kbOptionsCombined && !kbOptionsCombined.includes(sw)) kbOptionsCombined = kbOptionsCombined ? kbOptionsCombined + "," + sw : sw
            else if (!kbOptionsCombined) kbOptionsCombined = sw
        }
        // Helpers to write optional shadow color
        const shadowColor = (h.decoration.shadow.color ?? "").trim()
        const shadowColorInactive = (h.decoration.shadow.colorInactive ?? "").trim()
        HyprlandConfig.setMany({
            "decoration:rounding":                  h.decoration.rounding,
            "decoration:rounding_power":            h.decoration.roundingPower,
            "decoration:blur:enabled":              h.decoration.blur.enabled ? 1 : 0,
            "decoration:blur:size":                 h.decoration.blur.size,
            "decoration:blur:passes":               h.decoration.blur.passes,
            "decoration:blur:vibrancy":             h.decoration.blur.vibrancy,
            "decoration:blur:xray":                 h.decoration.blur.xray ? 1 : 0,
            "decoration:blur:new_optimizations":    h.decoration.blur.newOptimizations ? 1 : 0,
            "decoration:active_opacity":            h.decoration.activeOpacity,
            "decoration:inactive_opacity":          h.decoration.inactiveOpacity,
            "decoration:fullscreen_opacity":        h.decoration.fullscreenOpacity,
            "decoration:dim_inactive":              h.decoration.dimInactive ? 1 : 0,
            "decoration:dim_strength":              h.decoration.dimStrength,
            "decoration:dim_special":               h.decoration.dimSpecial,
            "decoration:border_part_of_window":     h.decoration.borderPartOfWindow ? 1 : 0,
            "decoration:shadow:enabled":            h.decoration.shadow.enabled ? 1 : 0,
            "decoration:shadow:range":              h.decoration.shadow.range,
            "decoration:shadow:render_power":       h.decoration.shadow.renderPower,
            "decoration:shadow:sharp":              h.decoration.shadow.sharp ? 1 : 0,
            "decoration:shadow:color":              shadowColor || "[[EMPTY]]",
            "decoration:shadow:color_inactive":     shadowColorInactive || "[[EMPTY]]",
            "decoration:shadow:offset":             `${h.decoration.shadow.offsetX}, ${h.decoration.shadow.offsetY}`,
            "decoration:shadow:scale":              h.decoration.shadow.scale,
            "general:border_size":                  h.general.borderSize,
            "general:gaps_in":                      h.general.gapsIn,
            "general:gaps_out":                     h.general.gapsOut,
            "general:gaps_workspaces":              h.general.gapsWorkspaces,
            "general:layout":                       h.general.layout,
            "general:resize_on_border":             h.general.resizeOnBorder ? 1 : 0,
            "general:allow_tearing":                h.general.allowTearing ? 1 : 0,
            "general:snap:enabled":                 h.general.snapEnabled ? 1 : 0,
            "general:snap:window_gap":              h.general.snapWindowGap,
            "general:snap:monitor_gap":             h.general.snapMonitorGap,
            "general:snap:border_overlap":          h.general.snapBorderOverlap ? 1 : 0,
            "general:snap:respect_gaps":            h.general.snapRespectGaps ? 1 : 0,
            "animations:enabled":                   h.animations.enable ? 1 : 0,
            "input:kb_layout":                      h.input.kbLayout,
            "input:kb_variant":                     h.input.kbVariant || "[[EMPTY]]",
            "input:kb_model":                       h.input.kbModel || "[[EMPTY]]",
            "input:kb_rules":                       h.input.kbRules || "[[EMPTY]]",
            "input:kb_options":                     kbOptionsCombined || "[[EMPTY]]",
            "input:numlock_by_default":             h.input.numlock ? 1 : 0,
            "input:repeat_delay":                   h.input.repeatDelay,
            "input:repeat_rate":                    h.input.repeatRate,
            "input:follow_mouse":                   h.input.followMouse,
            "input:touchpad:natural_scroll":        h.input.touchpad.naturalScroll ? 1 : 0,
            "input:touchpad:disable_while_typing":  h.input.touchpad.disableWhileTyping ? 1 : 0,
            "input:touchpad:clickfinger_behavior":  h.input.touchpad.clickfingerBehavior ? 1 : 0,
            "input:touchpad:scroll_factor":         h.input.touchpad.scrollFactor,
            "misc:disable_hyprland_logo":           h.misc.disableHyprlandLogo ? 1 : 0,
            "misc:disable_splash_rendering":        h.misc.disableSplashRendering ? 1 : 0,
            "misc:vrr":                             h.misc.vrr,
            "misc:mouse_move_enables_dpms":         h.misc.mouseMoveEnablesDpms ? 1 : 0,
            "misc:key_press_enables_dpms":          h.misc.keyPressEnablesDpms ? 1 : 0,
            "misc:animate_manual_resizes":          h.misc.animateManualResizes ? 1 : 0,
            "misc:animate_mouse_windowdragging":    h.misc.animateMouseWindowDragging ? 1 : 0,
            "misc:allow_session_lock_restore":      h.misc.allowSessionLockRestore ? 1 : 0,
            "misc:focus_on_activate":               h.misc.focusOnActivate,
            "cursor:zoom_factor":                   h.cursor.zoomFactor,
            "cursor:zoom_rigid":                    h.cursor.zoomRigid ? 1 : 0,
            "cursor:hide_on_key_press":             h.cursor.hideOnKeyPress ? 1 : 0,
            "cursor:hide_on_touch":                 h.cursor.hideOnTouch ? 1 : 0,
            "cursor:hotspot_padding":               h.cursor.hotspotPadding,
            "cursor:inactive_timeout":              h.cursor.inactiveTimeout,
            "cursor:no_warps":                      h.cursor.noWarps ? 1 : 0,
            "cursor:persistent_warps":              h.cursor.persistentWarps ? 1 : 0,
            "gestures:workspace_swipe_distance":                 h.gestures.workspaceSwipeDistance,
            "gestures:workspace_swipe_cancel_ratio":             h.gestures.workspaceSwipeCancelRatio,
            "gestures:workspace_swipe_min_speed_to_force":       h.gestures.workspaceSwipeMinSpeedToForce,
            "gestures:workspace_swipe_direction_lock":           h.gestures.workspaceSwipeDirectionLock ? 1 : 0,
            "gestures:workspace_swipe_direction_lock_threshold": h.gestures.workspaceSwipeDirectionLockThreshold,
            "gestures:workspace_swipe_create_new":               h.gestures.workspaceSwipeCreateNew ? 1 : 0,
            "dwindle:preserve_split":                     h.dwindle.preserveSplit ? 1 : 0,
            "dwindle:smart_split":                        h.dwindle.smartSplit ? 1 : 0,
            "dwindle:smart_resizing":                     h.dwindle.smartResizing ? 1 : 0,
            "master:new_status":                          h.master.newStatus,
            "master:mfact":                               h.master.mfact,
            "master:orientation":                         h.master.orientation,
            "group:auto_group":                           h.group.autoGroup ? 1 : 0,
            "group:drag_into_group":                     h.group.dragIntoGroup ? 1 : 0,
            "group:merge_groups_on_drag":               h.group.mergeGroupsOnDrag ? 1 : 0,
            "group:groupbar:enabled":                   h.group.groupbar.enabled ? 1 : 0,
            // Advanced fields supported by current Hyprland.
            "decoration:blur:noise":                   h.decoration.blur.noise,
            "decoration:blur:contrast":                h.decoration.blur.contrast,
            "decoration:blur:brightness":               h.decoration.blur.brightness,
            "decoration:blur:vibrancy_darkness":        h.decoration.blur.vibrancyDarkness,
            "decoration:blur:special":                  h.decoration.blur.special ? 1 : 0,
            "decoration:blur:popups":                   h.decoration.blur.popups ? 1 : 0,
            "decoration:blur:popups_ignorealpha":       h.decoration.blur.popupsIgnorealpha ? 1 : 0,
            "decoration:dim_modal":                     h.decoration.dimModal ? 1 : 0,
            "decoration:dim_around":                    h.decoration.dimAround ? 1 : 0,
            "general:col.active_border":                (h.general.colActiveBorder ?? "") || "[[EMPTY]]",
            "general:col.inactive_border":              (h.general.colInactiveBorder ?? "") || "[[EMPTY]]",
            "general:col.nogroup_border":               (h.general.colNogroupBorder ?? "") || "[[EMPTY]]",
            "general:float_gaps":                       h.general.floatGaps,
            "general:extend_border_grab_area":          h.general.extendBorderGrabArea ? 1 : 0,
            "general:hover_icon_on_border":             h.general.hoverIconOnBorder ? 1 : 0,
            "general:no_focus_fallback":                h.general.noFocusFallback ? 1 : 0,
            "input:sensitivity":                        h.input.sensitivity,
            "input:accel_profile":                      (h.input.accelProfile ?? "") || "[[EMPTY]]",
            "input:force_no_accel":                     h.input.forceNoAccel ? 1 : 0,
            "input:scroll_factor":                      h.input.scrollFactor,
            "input:scroll_button":                      h.input.scrollButton,
            "input:left_handed":                        h.input.leftHanded ? 1 : 0,
            "input:touchpad:tap_to_click":              h.input.touchpad.tapToClick ? 1 : 0,
            "input:touchpad:tap_button_map":            h.input.touchpad.tapButtonMap,
            "input:touchpad:tap_and_drag":              h.input.touchpad.tapAndDrag ? 1 : 0,
            "input:touchpad:drag_lock":                 h.input.touchpad.dragLock ? 1 : 0,
        })
    }
    MonitorConfigOption { id: monitorConfig }

    ColumnLayout {
        id: mainLayout
        Layout.fillWidth: true
        Layout.fillHeight: true
        spacing: 20

        // Displays
        ContentSection {
            icon: "monitor"
            shape: MaterialShape.Shape.ClamShell
            title: Translation.tr("Displays")
            visible: monitorConfig.monitors.length > 0

            MonitorCanvas {
                id: monitorCanvas
                Layout.fillWidth: true
                monitorConfig: monitorConfig
            }

            ContentSubsection {
                Layout.topMargin: 10
                title: (monitorConfig.monitors[monitorCanvas.selectedIndex]?.name ?? "")
                    + " · "
                    + (monitorConfig.monitors[monitorCanvas.selectedIndex]?.description ?? "")

                GroupedList {
                    ConfigSwitch {
                        buttonIcon: "tv_off"
                        text: Translation.tr("Enabled")
                        checked: !(monitorConfig.monitors[monitorCanvas.selectedIndex]?.disabled ?? false)
                        onCheckedChanged: {
                            if (checked === !(monitorConfig.monitors[monitorCanvas.selectedIndex]?.disabled ?? false)) return
                            monitorConfig.updateMonitor(monitorCanvas.selectedIndex, { disabled: !checked })
                            monitorConfig.applyAndSave(monitorCanvas.selectedIndex)
                        }
                    }

                    ConfigComboBox {
                        Layout.fillWidth: true
                        buttonIcon: "aspect_ratio"
                        text: Translation.tr("Resolution & Refresh Rate")
                        textRole: "display"
                        model: (monitorConfig.monitors[monitorCanvas.selectedIndex]?.availableModes ?? [])
                            .map(mode => ({ display: mode, value: mode }))
                        currentValue: monitorConfig.monitors[monitorCanvas.selectedIndex]?.currentMode ?? ""
                        onSelected: newValue => {
                            const mode = newValue
                            const parts = mode.match(/(\d+)x(\d+)@([\d.]+)Hz/)
                            monitorConfig.updateMonitor(monitorCanvas.selectedIndex, {
                                currentMode: mode,
                                width: parseInt(parts[1]),
                                height: parseInt(parts[2]),
                                refreshRate: parseFloat(parts[3])
                            })
                            monitorConfig.applyAndSave(monitorCanvas.selectedIndex)
                        }
                    }

                    ConfigSelectionArray {
                        text: Translation.tr("Orientation")
                        icon: "mobile_rotate"
                        currentValue: monitorConfig.monitors[monitorCanvas.selectedIndex]?.transform ?? 0
                        onSelected: newValue => {
                            monitorConfig.updateMonitor(monitorCanvas.selectedIndex, { transform: newValue })
                            monitorConfig.applyAndSave(monitorCanvas.selectedIndex)
                        }
                        options: [
                            { displayName: Translation.tr("Normal"), icon: "screen_rotation_alt", value: 0 },
                            { displayName: "90°",                    icon: "rotate_90_degrees_cw",  value: 1 },
                            { displayName: "180°",                   icon: "screen_rotation",       value: 2 },
                            { displayName: "270°",                   icon: "rotate_90_degrees_ccw", value: 3 },
                        ]
                    }
    
                    ConfigSpinBox {
                        icon: "zoom_in"
                        text: Translation.tr("Scale")
                        value: Math.round((monitorConfig.monitors[monitorCanvas.selectedIndex]?.scale ?? 1.0) * 100)
                        from: 50; to: 300; stepSize: 25
                        onValueChanged: {
                            const newVal = value / 100.0
                            if (newVal === (monitorConfig.monitors[monitorCanvas.selectedIndex]?.scale ?? 1.0)) return
                            monitorConfig.updateMonitor(monitorCanvas.selectedIndex, { scale: newVal })
                            monitorConfig.applyAndSave(monitorCanvas.selectedIndex)
                        }
                    }

                    ConfigSpinBox {
                        icon: "swap_horiz"
                        text: Translation.tr("Position X")
                        value: monitorConfig.monitors[monitorCanvas.selectedIndex]?.x ?? 0
                        from: 0; to: 7680; stepSize: 1
                        onValueChanged: {
                            if (value === (monitorConfig.monitors[monitorCanvas.selectedIndex]?.x ?? 0)) return
                            monitorConfig.updateMonitor(monitorCanvas.selectedIndex, { x: value })
                            monitorConfig.applyAndSave(monitorCanvas.selectedIndex)
                        }
                    }

                    ConfigSpinBox {
                        icon: "swap_vert"
                        text: Translation.tr("Position Y")
                        value: monitorConfig.monitors[monitorCanvas.selectedIndex]?.y ?? 0
                        from: 0; to: 4320; stepSize: 1
                        onValueChanged: {
                            if (value === (monitorConfig.monitors[monitorCanvas.selectedIndex]?.y ?? 0)) return
                            monitorConfig.updateMonitor(monitorCanvas.selectedIndex, { y: value })
                            monitorConfig.applyAndSave(monitorCanvas.selectedIndex)
                        }
                    }

                    // Logical size display
                    StyledText {
                        Layout.fillWidth: true
                        font.pixelSize: Appearance.font.pixelSize.smaller
                        color: Appearance.colors.colSubtext
                        text: {
                            const m = monitorConfig.monitors[monitorCanvas.selectedIndex]
                            if (!m) return ""
                            return Translation.tr("Logical: %1px").arg(monitorConfig.logicalSizeDisplay(m))
                        }
                    }
                }

                // Advanced Monitor Settings
                ContentSubsection {
                    title: Translation.tr("Advanced Monitor Settings")
                    visible: monitorConfig.monitors.length > 0

                    GroupedList {
                        // Mirror
                        ConfigComboBox {
                            Layout.fillWidth: true
                            buttonIcon: "flip_camera_android"
                            text: Translation.tr("Mirror")
                            textRole: "displayName"
                            model: {
                                let result = [{ displayName: Translation.tr("None"), value: "" }]
                                for (let i = 0; i < monitorConfig.monitors.length; i++) {
                                    if (i === monitorCanvas.selectedIndex) continue
                                    if (monitorConfig.monitors[i].disabled) continue
                                    result.push({ displayName: monitorConfig.monitors[i].name, value: monitorConfig.monitors[i].name })
                                }
                                return result
                            }
                            currentValue: monitorConfig.monitors[monitorCanvas.selectedIndex]?.mirror ?? ""
                            onSelected: newValue => {
                                monitorConfig.updateMonitor(monitorCanvas.selectedIndex, { mirror: newValue })
                                monitorConfig.applyAndSave(monitorCanvas.selectedIndex)
                            }
                        }

                        // Bitdepth
                        ConfigSelectionArray {
                            text: Translation.tr("Bit Depth")
                            icon: "palette"
                            currentValue: monitorConfig.monitors[monitorCanvas.selectedIndex]?.bitdepth ?? 8
                            onSelected: newValue => {
                                monitorConfig.updateMonitor(monitorCanvas.selectedIndex, { bitdepth: newValue })
                                monitorConfig.applyAndSave(monitorCanvas.selectedIndex)
                            }
                            options: [
                                { displayName: "8", icon: "looks_one", value: 8 },
                                { displayName: "10", icon: "looks_two", value: 10 }
                            ]
                        }

                        // VRR (Variable Refresh Rate)
                        ConfigSelectionArray {
                            text: Translation.tr("VRR")
                            icon: "speed"
                            currentValue: monitorConfig.monitors[monitorCanvas.selectedIndex]?.vrr ?? 0
                            onSelected: newValue => {
                                monitorConfig.updateMonitor(monitorCanvas.selectedIndex, { vrr: newValue })
                                monitorConfig.applyAndSave(monitorCanvas.selectedIndex)
                            }
                            options: [
                                { displayName: Translation.tr("Off"), icon: "block", value: 0 },
                                { displayName: Translation.tr("On"), icon: "check", value: 1 },
                                { displayName: Translation.tr("Fullscreen"), icon: "fullscreen", value: 2 }
                            ]
                        }

                        // Color Management
                        ConfigComboBox {
                            Layout.fillWidth: true
                            buttonIcon: "color_lens"
                            text: Translation.tr("Color Management")
                            textRole: "displayName"
                            model: [
                                { displayName: Translation.tr("Auto"), value: "auto" },
                                { displayName: "sRGB", value: "srgb" },
                                { displayName: Translation.tr("Wide Color"), value: "wide" },
                                { displayName: "HDR", value: "hdr" },
                                { displayName: "EDID", value: "edid" }
                            ]
                            currentValue: monitorConfig.monitors[monitorCanvas.selectedIndex]?.cm ?? "auto"
                            onSelected: newValue => {
                                monitorConfig.updateMonitor(monitorCanvas.selectedIndex, { cm: newValue })
                                monitorConfig.applyAndSave(monitorCanvas.selectedIndex)
                            }
                        }

                        // Reserved Area
                        ConfigSpinBox {
                            icon: "space_bar"
                            text: Translation.tr("Reserved Area")
                            value: {
                                const r = monitorConfig.monitors[monitorCanvas.selectedIndex]?.reservedArea ?? 0
                                return (typeof r === "object") ? (r.top || 0) : r
                            }
                            from: 0; to: 200; stepSize: 1
                            onValueChanged: {
                                monitorConfig.updateMonitor(monitorCanvas.selectedIndex, { reservedArea: value })
                                monitorConfig.applyAndSave(monitorCanvas.selectedIndex)
                            }
                        }

                        // Transform (extended: 0-7)
                        ConfigSelectionArray {
                            text: Translation.tr("Transform")
                            icon: "rotate_right"
                            currentValue: monitorConfig.monitors[monitorCanvas.selectedIndex]?.transform ?? 0
                            onSelected: newValue => {
                                monitorConfig.updateMonitor(monitorCanvas.selectedIndex, { transform: newValue })
                                monitorConfig.applyAndSave(monitorCanvas.selectedIndex)
                            }
                            options: [
                                { displayName: Translation.tr("Normal"),  icon: "screen_rotation_alt",  value: 0 },
                                { displayName: "90°",                     icon: "rotate_90_degrees_cw",  value: 1 },
                                { displayName: "180°",                    icon: "screen_rotation",       value: 2 },
                                { displayName: "270°",                    icon: "rotate_90_degrees_ccw", value: 3 },
                                { displayName: Translation.tr("Flipped"), icon: "flip",                  value: 4 },
                                { displayName: "90° + Flip",             icon: "flip_camera_android",   value: 5 },
                                { displayName: "180° + Flip",            icon: "screen_lock_portrait",  value: 6 },
                                { displayName: "270° + Flip",            icon: "switch_video",          value: 7 }
                            ]
                        }
                    }
                }       
            }
        }

        // Layout
        ContentSection {
            icon: "auto_awesome_mosaic"
            shape: MaterialShape.Shape.Gem
            title: Translation.tr("Layout")

            GroupedList {
                ConfigSelectionArray {
                    text: Translation.tr("Tiling Layout")
                    icon: "responsive_layout"
                    currentValue: Config.options.hyprland.general.layout
                    onSelected: newValue => {
                        Config.options.hyprland.general.layout = newValue
                        HyprlandConfig.set("general:layout", newValue)
                    }
                    options: [
                        { displayName: Translation.tr("Dwindle"),   icon: "browse",             value: "dwindle"   },
                        { displayName: Translation.tr("Master"),    icon: "auto_awesome_mosaic", value: "master"    },
                        { displayName: Translation.tr("Scrolling"), icon: "view_carousel",       value: "scrolling" },
                    ]
                }
            }
            // Dwindle options
            ContentSubsection {
                visible: Config.options.hyprland.general.layout === "dwindle"
                title: Translation.tr("Dwindle")
                GroupedList {
                    ConfigSwitch {
                        buttonIcon: "splitscreen"
                        text: Translation.tr("Preserve Split")
                        checked: Config.options.hyprland.dwindle.preserveSplit
                        onCheckedChanged: { if (checked === Config.options.hyprland.dwindle.preserveSplit) return; Config.options.hyprland.dwindle.preserveSplit = checked; HyprlandConfig.set("dwindle:preserve_split", checked?1:0) }
                    }
                    ConfigSwitch {
                        buttonIcon: "auto_awesome"
                        text: Translation.tr("Smart Split")
                        checked: Config.options.hyprland.dwindle.smartSplit
                        onCheckedChanged: { if (checked === Config.options.hyprland.dwindle.smartSplit) return; Config.options.hyprland.dwindle.smartSplit = checked; HyprlandConfig.set("dwindle:smart_split", checked?1:0) }
                    }
                    ConfigSwitch {
                        buttonIcon: "open_with"
                        text: Translation.tr("Smart Resizing")
                        checked: Config.options.hyprland.dwindle.smartResizing
                        onCheckedChanged: { if (checked === Config.options.hyprland.dwindle.smartResizing) return; Config.options.hyprland.dwindle.smartResizing = checked; HyprlandConfig.set("dwindle:smart_resizing", checked?1:0) }
                    }
                }
            }
            // Master options
            ContentSubsection {
                visible: Config.options.hyprland.general.layout === "master"
                title: Translation.tr("Master")
                GroupedList {
                    ConfigSelectionArray {
                        text: Translation.tr("New Window Status")
                        icon: "add"
                        currentValue: Config.options.hyprland.master.newStatus
                        onSelected: v => { Config.options.hyprland.master.newStatus = v; HyprlandConfig.set("master:new_status", v) }
                        options: [
                            { displayName: "Slave", icon: "person", value: "slave" },
                            { displayName: "Master", icon: "star", value: "master" },
                            { displayName: "Inherit", icon: "history", value: "inherit" }
                        ]
                    }
                    ConfigSlider {
                        text: Translation.tr("Master Factor")
                        buttonIcon: "splitscreen"
                        value: Config.options.hyprland.master.mfact
                        from: 0.1; to: 0.9
                        onValueChanged: { Config.options.hyprland.master.mfact = value; HyprlandConfig.set("master:mfact", value) }
                    }
                    ConfigSelectionArray {
                        text: Translation.tr("Orientation")
                        icon: "rotate_90_degrees_ccw"
                        currentValue: Config.options.hyprland.master.orientation
                        onSelected: v => { Config.options.hyprland.master.orientation = v; HyprlandConfig.set("master:orientation", v) }
                        options: [
                            { displayName: Translation.tr("Left"), icon: "arrow_back", value: "left" },
                            { displayName: Translation.tr("Right"), icon: "arrow_forward", value: "right" },
                            { displayName: Translation.tr("Top"), icon: "arrow_upward", value: "top" },
                            { displayName: Translation.tr("Bottom"), icon: "arrow_downward", value: "bottom" },
                            { displayName: Translation.tr("Center"), icon: "center_focus_strong", value: "center" }
                        ]
                    }
                }
            }
            // Group
            ContentSubsection {
                title: Translation.tr("Group")
                GroupedList {
                    ConfigSwitch {
                        buttonIcon: "group"
                        text: Translation.tr("Auto Group")
                        checked: Config.options.hyprland.group.autoGroup
                        onCheckedChanged: { if (checked === Config.options.hyprland.group.autoGroup) return; Config.options.hyprland.group.autoGroup = checked; HyprlandConfig.set("group:auto_group", checked?1:0) }
                    }
                    ConfigSwitch {
                        buttonIcon: "group_add"
                        text: Translation.tr("Drag Into Group")
                        checked: Config.options.hyprland.group.dragIntoGroup
                        onCheckedChanged: { if (checked === Config.options.hyprland.group.dragIntoGroup) return; Config.options.hyprland.group.dragIntoGroup = checked; HyprlandConfig.set("group:drag_into_group", checked?1:0) }
                    }
                    ConfigSwitch {
                        buttonIcon: "merge"
                        text: Translation.tr("Merge Groups On Drag")
                        checked: Config.options.hyprland.group.mergeGroupsOnDrag
                        onCheckedChanged: { if (checked === Config.options.hyprland.group.mergeGroupsOnDrag) return; Config.options.hyprland.group.mergeGroupsOnDrag = checked; HyprlandConfig.set("group:merge_groups_on_drag", checked?1:0) }
                    }
                    ConfigSwitch {
                        buttonIcon: "view_agenda"
                        text: Translation.tr("Group Bar Enabled")
                        checked: Config.options.hyprland.group.groupbar.enabled
                        onCheckedChanged: { if (checked === Config.options.hyprland.group.groupbar.enabled) return; Config.options.hyprland.group.groupbar.enabled = checked; HyprlandConfig.set("group:groupbar:enabled", checked?1:0) }
                    }
                }
            }
        }

        // Input
        ContentSection {
            icon: "trackpad_input"
            shape: MaterialShape.Shape.Pentagon
            title: Translation.tr("Input")

            ContentSubsection {
                id: keyboardSection
                title: Translation.tr("Keyboard")

                // Helpers for layout + options -> hyprland
                function buildKbOptionsString() {
                    const base = (Config.options.hyprland.input.kbOptions ?? "").trim()
                    const sw = (Config.options.hyprland.input.kbLayoutSwitchShortcut ?? "").trim()
                    if (base && sw) {
                        if (base.includes(sw)) return base
                        return base + "," + sw
                    }
                    if (sw) return sw
                    return base
                }
                function applyKbOptions() {
                    const combined = keyboardSection.buildKbOptionsString()
                    if (!combined) HyprlandConfig.set("input:kb_options", "[[EMPTY]]")
                    else HyprlandConfig.set("input:kb_options", combined)
                    kbReloadTimer.restart()
                }
                function layoutsList() {
                    const raw = Config.options.hyprland.input.kbLayout ?? "us"
                    return raw.split(",").map(s => s.trim()).filter(s => s.length > 0)
                }
                function setLayouts(list) {
                    const v = list.join(",")
                    Config.options.hyprland.input.kbLayout = v
                    HyprlandConfig.set("input:kb_layout", v)
                    kbReloadTimer.restart()
                }
                Timer { id: kbReloadTimer; interval: 400; repeat: false; onTriggered: kbReloadProc.running = true }
                Process { id: kbReloadProc; command: ["hyprctl", "reload"] }

                GroupedList {
                    // Current layouts chips
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 8
                        StyledText {
                            text: Translation.tr("Keyboard layouts")
                            color: Appearance.colors.colOnSecondaryContainer
                        }
                        Flow {
                            Layout.fillWidth: true
                            spacing: 6
                            Repeater {
                                model: keyboardSection.layoutsList()
                                delegate: Rectangle {
                                    required property var modelData
                                    required property int index
                                    radius: Appearance.rounding.small
                                    color: Appearance.colors.colSecondaryContainer
                                    implicitHeight: 32
                                    implicitWidth: row.implicitWidth + 16
                                    RowLayout {
                                        id: row
                                        anchors.centerIn: parent
                                        spacing: 6
                                        StyledText {
                                            text: modelData
                                            color: Appearance.colors.colOnSecondaryContainer
                                            font.pixelSize: Appearance.font.pixelSize.small
                                        }
                                        Rectangle {
                                            visible: keyboardSection.layoutsList().length > 1
                                            implicitWidth: 20; implicitHeight: 20
                                            radius: 10
                                            color: delHover.containsMouse ? Appearance.colors.colOnSecondaryContainer : "transparent"
                                            MaterialSymbol {
                                                anchors.centerIn: parent
                                                text: "close"
                                                iconSize: 16
                                                color: delHover.containsMouse ? Appearance.colors.colSecondaryContainer : Appearance.colors.colOnSecondaryContainer
                                            }
                                            MouseArea { id: delHover; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: {
                                                let lst = keyboardSection.layoutsList()
                                                lst.splice(index, 1)
                                                keyboardSection.setLayouts(lst)
                                            }}
                                        }
                                    }
                                }
                            }
                        }
                        // Add new layout row
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8
                            StyledComboBox {
                                id: addLayoutCombo
                                Layout.fillWidth: true
                                model: [
                                    { displayName: "us — English (US)", value: "us" },
                                    { displayName: "ara — Arabic", value: "ara" },
                                    { displayName: "eg — Arabic (Egypt)", value: "eg" },
                                    { displayName: "sa — Arabic (Saudi)", value: "sa" },
                                    { displayName: "fr — French", value: "fr" },
                                    { displayName: "de — German", value: "de" },
                                    { displayName: "es — Spanish", value: "es" },
                                    { displayName: "ru — Russian", value: "ru" },
                                    { displayName: "tr — Turkish", value: "tr" },
                                    { displayName: "fa — Persian", value: "fa" },
                                    { displayName: "ir — Persian (Iran)", value: "ir" },
                                    { displayName: "gb — English (UK)", value: "gb" },
                                    { displayName: "it — Italian", value: "it" },
                                    { displayName: "latam — Latin American", value: "latam" },
                                    { displayName: "in — Indian", value: "in" },
                                    { displayName: "cn — Chinese", value: "cn" },
                                    { displayName: "jp — Japanese", value: "jp" }
                                ]
                                textRole: "displayName"
                                onActivated: idx => { customLayoutField.text = model[idx].value }
                            }
                            Rectangle {
                                Layout.preferredWidth: 140
                                Layout.preferredHeight: 36
                                radius: Appearance.rounding.small
                                color: Appearance.colors.colLayer1
                                border.width: customLayoutField.activeFocus ? 1 : 0
                                border.color: Appearance.colors.colPrimary
                                TextInput {
                                    id: customLayoutField
                                    anchors.fill: parent
                                    anchors.margins: 8
                                    verticalAlignment: TextInput.AlignVCenter
                                    selectByMouse: true
                                    color: Appearance.colors.colOnLayer1
                                    font.pixelSize: Appearance.font.pixelSize.small
                                    property string placeholderText: "ara"
                                    onAccepted: addBtn.clicked()
                                }
                                StyledText {
                                    visible: customLayoutField.text.length === 0
                                    anchors.verticalCenter: parent.verticalCenter
                                    anchors.left: parent.left
                                    anchors.leftMargin: 8
                                    text: "ara"
                                    color: Appearance.colors.colSubtext
                                    font.pixelSize: Appearance.font.pixelSize.small
                                }
                            }
                            RippleButtonWithIcon {
                                id: addBtn
                                materialIcon: "add"
                                mainText: Translation.tr("Add")
                                onClicked: {
                                    const code = (customLayoutField.text || addLayoutCombo.currentText.split(" — ")[0] || "").trim()
                                    if (!code) return
                                    let lst = keyboardSection.layoutsList()
                                    if (lst.includes(code)) return
                                    lst.push(code)
                                    keyboardSection.setLayouts(lst)
                                    customLayoutField.text = ""
                                }
                                colBackground: Appearance.colors.colPrimaryContainer
                                colRipple: Appearance.colors.colPrimaryContainerActive
                            }
                        }
                        StyledText {
                            Layout.fillWidth: true
                            wrapMode: Text.Wrap
                            font.pixelSize: Appearance.font.pixelSize.smaller
                            color: Appearance.colors.colSubtext
                            text: Translation.tr("Hyprland uses comma-separated layouts. Example: us,ara. Indicator in bar shows active layout. Click bar indicator to switch.")
                        }
                    }

                    // Extra xkb options / switch shortcut
                    ConfigComboBox {
                        text: Translation.tr("Layout switch shortcut")
                        buttonIcon: "swap_horiz"
                        currentValue: Config.options.hyprland.input.kbLayoutSwitchShortcut ?? ""
                        onSelected: newValue => {
                            Config.options.hyprland.input.kbLayoutSwitchShortcut = newValue
                            keyboardSection.applyKbOptions()
                        }
                        model: [
                            { displayName: Translation.tr("None"), value: "" },
                            { displayName: "Alt+Shift", value: "grp:alt_shift_toggle" },
                            { displayName: "Ctrl+Shift", value: "grp:ctrl_shift_toggle" },
                            { displayName: "Win+Space", value: "grp:win_space_toggle" },
                            { displayName: "Caps Lock", value: "grp:caps_toggle" },
                            { displayName: "Alt+Caps", value: "grp:alt_caps_toggle" },
                            { displayName: "Both Shifts", value: "grp:shifts_toggle" },
                            { displayName: "Both Alts", value: "grp:alts_toggle" },
                            { displayName: "Ctrl+Alt", value: "grp:ctrl_alt_toggle" },
                            { displayName: "Shift+Caps", value: "grp:shift_caps_toggle" }
                        ]
                    }

                    ConfigTextArea {
                        id: kbOptionsField
                        Layout.fillWidth: true
                        buttonIcon: "tune"
                        text: Translation.tr("Extra XKB options")
                        placeholderText: Translation.tr("e.g., caps:swapescape, compose:ralt")
                        Component.onCompleted: value = Config.options.hyprland.input.kbOptions ?? ""
                        confirmButtonVisible: true
                        onConfirmClicked: {
                            Config.options.hyprland.input.kbOptions = kbOptionsField.value.trim()
                            keyboardSection.applyKbOptions()
                        }
                        // also auto debounce
                        onValueChanged: kbOptionsDebounce.restart()
                        Timer {
                            id: kbOptionsDebounce
                            interval: 1000
                            repeat: false
                            onTriggered: {
                                Config.options.hyprland.input.kbOptions = kbOptionsField.value.trim()
                                keyboardSection.applyKbOptions()
                            }
                        }
                    }
                    ConfigTextArea {
                        id: kbVariantField
                        Layout.fillWidth: true
                        buttonIcon: "polyline"
                        text: Translation.tr("Variant (per layout, comma-separated)")
                        placeholderText: Translation.tr("e.g., ,, or dvorak")
                        Component.onCompleted: value = Config.options.hyprland.input.kbVariant ?? ""
                        onValueChanged: kbVariantDebounce.restart()
                        Timer {
                            id: kbVariantDebounce
                            interval: 1000
                            repeat: false
                            onTriggered: {
                                Config.options.hyprland.input.kbVariant = kbVariantField.value
                                HyprlandConfig.set("input:kb_variant", kbVariantField.value || "[[EMPTY]]")
                                kbReloadTimer.restart()
                            }
                        }
                    }
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10
                        ConfigTextArea {
                            id: kbModelField
                            Layout.fillWidth: true
                            buttonIcon: "keyboard_alt"
                            text: Translation.tr("Model")
                            placeholderText: "pc104"
                            Component.onCompleted: value = Config.options.hyprland.input.kbModel ?? ""
                            onValueChanged: kbModelDebounce.restart()
                            Timer {
                                id: kbModelDebounce
                                interval: 1000
                                repeat: false
                                onTriggered: {
                                    Config.options.hyprland.input.kbModel = kbModelField.value
                                    HyprlandConfig.set("input:kb_model", kbModelField.value || "[[EMPTY]]")
                                    kbReloadTimer.restart()
                                }
                            }
                        }
                        ConfigTextArea {
                            id: kbRulesField
                            Layout.fillWidth: true
                            buttonIcon: "rule"
                            text: Translation.tr("Rules")
                            placeholderText: "evdev"
                            Component.onCompleted: value = Config.options.hyprland.input.kbRules ?? ""
                            onValueChanged: kbRulesDebounce.restart()
                            Timer {
                                id: kbRulesDebounce
                                interval: 1000
                                repeat: false
                                onTriggered: {
                                    Config.options.hyprland.input.kbRules = kbRulesField.value
                                    HyprlandConfig.set("input:kb_rules", kbRulesField.value || "[[EMPTY]]")
                                    kbReloadTimer.restart()
                                }
                            }
                        }
                    }
                    ConfigSwitch {
                        buttonIcon: "numbers"
                        text: Translation.tr("Numlock by default")
                        checked: Config.options.hyprland.input.numlock
                        onCheckedChanged: {
                            if (checked === Config.options.hyprland.input.numlock) return
                            Config.options.hyprland.input.numlock = checked
                            HyprlandConfig.set("input:numlock_by_default", checked ? 1 : 0)
                        }
                    }

                    ConfigSpinBox {
                        icon: "keyboard_return"
                        text: Translation.tr("Repeat delay (ms)")
                        value: Config.options.hyprland.input.repeatDelay
                        from: 100; to: 1000; stepSize: 10
                        onValueChanged: {
                            if (value === Config.options.hyprland.input.repeatDelay) return
                            Config.options.hyprland.input.repeatDelay = value
                            HyprlandConfig.set("input:repeat_delay", value)
                        }
                    }

                    ConfigSpinBox {
                        icon: "speed"
                        text: Translation.tr("Repeat rate")
                        value: Config.options.hyprland.input.repeatRate
                        from: 10; to: 100; stepSize: 1
                        onValueChanged: {
                            if (value === Config.options.hyprland.input.repeatRate) return
                            Config.options.hyprland.input.repeatRate = value
                            HyprlandConfig.set("input:repeat_rate", value)
                        }
                    }
                    ConfigSelectionArray {
                        text: Translation.tr("Follow mouse")
                        icon: "mouse"
                        currentValue: Config.options.hyprland.input.followMouse
                        onSelected: newValue => {
                            Config.options.hyprland.input.followMouse = newValue
                            HyprlandConfig.set("input:follow_mouse", newValue)
                        }
                        options: [
                            { displayName: Translation.tr("Disabled"), icon: "mouse",     value: 0 },
                            { displayName: Translation.tr("Full"),     icon: "open_with",  value: 1 },
                            { displayName: Translation.tr("Loose"),    icon: "drag_pan",   value: 2 },
                            { displayName: Translation.tr("Explicit"), icon: "ads_click",  value: 3 },
                        ]
                    }
                }
            }

            ContentSubsection {
                title: Translation.tr("Touchpad")
                GroupedList {
                    ConfigSwitch {
                        buttonIcon: "swap_vert"
                        text: Translation.tr("Natural scroll")
                        checked: Config.options.hyprland.input.touchpad.naturalScroll
                        onCheckedChanged: {
                            if (checked === Config.options.hyprland.input.touchpad.naturalScroll) return
                            Config.options.hyprland.input.touchpad.naturalScroll = checked
                            HyprlandConfig.set("input:touchpad:natural_scroll", checked ? 1 : 0)
                        }
                    }

                    ConfigSwitch {
                        buttonIcon: "keyboard_hide"
                        text: Translation.tr("Disable while typing")
                        checked: Config.options.hyprland.input.touchpad.disableWhileTyping
                        onCheckedChanged: {
                            if (checked === Config.options.hyprland.input.touchpad.disableWhileTyping) return
                            Config.options.hyprland.input.touchpad.disableWhileTyping = checked
                            HyprlandConfig.set("input:touchpad:disable_while_typing", checked ? 1 : 0)
                        }
                    }

                    ConfigSwitch {
                        buttonIcon: "touch_app"
                        text: Translation.tr("Clickfinger behavior")
                        checked: Config.options.hyprland.input.touchpad.clickfingerBehavior
                        onCheckedChanged: {
                            if (checked === Config.options.hyprland.input.touchpad.clickfingerBehavior) return
                            Config.options.hyprland.input.touchpad.clickfingerBehavior = checked
                            HyprlandConfig.set("input:touchpad:clickfinger_behavior", checked ? 1 : 0)
                        }
                    }

                    ConfigSpinBox {
                        icon: "swipe"
                        text: Translation.tr("Scroll factor")
                        value: Math.round(Config.options.hyprland.input.touchpad.scrollFactor * 10)
                        from: 1; to: 30; stepSize: 1
                        onValueChanged: {
                            const newVal = value / 10.0
                            if (newVal === Config.options.hyprland.input.touchpad.scrollFactor) return
                            Config.options.hyprland.input.touchpad.scrollFactor = newVal
                            HyprlandConfig.set("input:touchpad:scroll_factor", newVal)
                        }
                    }
                }

                // Touchpad advanced
                ContentSubsection {
                    title: Translation.tr("Touchpad Advanced")
                    GroupedList {
                        ConfigSwitch {
                            buttonIcon: "touch_app"
                            text: Translation.tr("Tap to Click")
                            checked: Config.options.hyprland.input.touchpad.tapToClick
                            onCheckedChanged: {
                                if (checked === Config.options.hyprland.input.touchpad.tapToClick) return
                                Config.options.hyprland.input.touchpad.tapToClick = checked
                                HyprlandConfig.set("input:touchpad:tap_to_click", checked ? 1 : 0)
                            }
                        }
                        ConfigSelectionArray {
                            text: Translation.tr("Tap Button Map")
                            icon: "swap_horiz"
                            currentValue: Config.options.hyprland.input.touchpad.tapButtonMap
                            onSelected: newValue => {
                                Config.options.hyprland.input.touchpad.tapButtonMap = newValue
                                HyprlandConfig.set("input:touchpad:tap_button_map", newValue)
                            }
                            options: [
                                { displayName: "LRM", icon: "mouse", value: 0 },
                                { displayName: "LMR", icon: "mouse", value: 1 }
                            ]
                        }
                        ConfigSwitch {
                            buttonIcon: "drag_indicator"
                            text: Translation.tr("Tap and Drag")
                            checked: Config.options.hyprland.input.touchpad.tapAndDrag
                            onCheckedChanged: {
                                if (checked === Config.options.hyprland.input.touchpad.tapAndDrag) return
                                Config.options.hyprland.input.touchpad.tapAndDrag = checked
                                HyprlandConfig.set("input:touchpad:tap_and_drag", checked ? 1 : 0)
                            }
                        }
                        ConfigSwitch {
                            buttonIcon: "lock"
                            text: Translation.tr("Drag Lock")
                            checked: Config.options.hyprland.input.touchpad.dragLock
                            onCheckedChanged: {
                                if (checked === Config.options.hyprland.input.touchpad.dragLock) return
                                Config.options.hyprland.input.touchpad.dragLock = checked
                                HyprlandConfig.set("input:touchpad:drag_lock", checked ? 1 : 0)
                            }
                        }
                    }
                }
            }

            // Mouse & General Input
            ContentSubsection {
                title: Translation.tr("Mouse & Input")
                GroupedList {
                    // Sensitivity
                    ConfigSlider {
                        text: Translation.tr("Sensitivity")
                        buttonIcon: "speed"
                        value: Math.round(Config.options.hyprland.input.sensitivity * 100)
                        from: -100; to: 100
                        onValueChanged: {
                            const v = value / 100.0
                            if (v === Config.options.hyprland.input.sensitivity) return
                            Config.options.hyprland.input.sensitivity = v
                            HyprlandConfig.set("input:sensitivity", v)
                        }
                    }
                    // Accel Profile
                    ConfigComboBox {
                        Layout.fillWidth: true
                        buttonIcon: "speed"
                        text: Translation.tr("Accel Profile")
                        textRole: "displayName"
                        model: [
                            { displayName: Translation.tr("None"), value: "" },
                            { displayName: "Flat", value: "flat" },
                            { displayName: "Adaptive", value: "adaptive" }
                        ]
                        currentValue: Config.options.hyprland.input.accelProfile ?? ""
                        onSelected: newValue => {
                            Config.options.hyprland.input.accelProfile = newValue
                            HyprlandConfig.set("input:accel_profile", newValue || "[[EMPTY]]")
                        }
                    }
                    // Force No Accel
                    ConfigSwitch {
                        buttonIcon: "speed"
                        text: Translation.tr("Force No Accel")
                        checked: Config.options.hyprland.input.forceNoAccel
                        onCheckedChanged: {
                            if (checked === Config.options.hyprland.input.forceNoAccel) return
                            Config.options.hyprland.input.forceNoAccel = checked
                            HyprlandConfig.set("input:force_no_accel", checked ? 1 : 0)
                        }
                    }
                    // Scroll Factor
                    ConfigSpinBox {
                        icon: "swap_vert"
                        text: Translation.tr("Scroll Factor")
                        value: Math.round(Config.options.hyprland.input.scrollFactor * 10)
                        from: 1; to: 30; stepSize: 1
                        onValueChanged: {
                            const v = value / 10.0
                            if (v === Config.options.hyprland.input.scrollFactor) return
                            Config.options.hyprland.input.scrollFactor = v
                            HyprlandConfig.set("input:scroll_factor", v)
                        }
                    }
                    // Scroll Button
                    ConfigSpinBox {
                        icon: "mouse"
                        text: Translation.tr("Scroll Button")
                        value: Config.options.hyprland.input.scrollButton
                        from: 0; to: 12; stepSize: 1
                        onValueChanged: {
                            if (value === Config.options.hyprland.input.scrollButton) return
                            Config.options.hyprland.input.scrollButton = value
                            HyprlandConfig.set("input:scroll_button", value)
                        }
                    }
                    // Left Handed
                    ConfigSwitch {
                        buttonIcon: "back_hand"
                        text: Translation.tr("Left Handed")
                        checked: Config.options.hyprland.input.leftHanded
                        onCheckedChanged: {
                            if (checked === Config.options.hyprland.input.leftHanded) return
                            Config.options.hyprland.input.leftHanded = checked
                            HyprlandConfig.set("input:left_handed", checked ? 1 : 0)
                        }
                    }
                }
            }
        }

        // Visual & Aesthetics
        ContentSection {
            icon: "deblur"
            shape: MaterialShape.Shape.PixelCircle
            title: Translation.tr("Visual & Aesthetics")

            GroupedList {
                ConfigSpinBox {
                    icon: "rounded_corner"
                    text: Translation.tr("Window Rounding")
                    value: Config.options.hyprland.decoration.rounding
                    from: 0; to: 30; stepSize: 1
                    onValueChanged: {
                        if (value === Config.options.hyprland.decoration.rounding) return
                        Config.options.hyprland.decoration.rounding = value
                        HyprlandConfig.set("decoration:rounding", value)
                    }
                }
                ConfigSpinBox {
                    icon: "spline"
                    text: Translation.tr("Rounding Power")
                    value: Math.round(Config.options.hyprland.decoration.roundingPower * 10)
                    from: 10; to: 100; stepSize: 5
                    onValueChanged: {
                        const v = value / 10.0
                        if (v === Config.options.hyprland.decoration.roundingPower) return
                        Config.options.hyprland.decoration.roundingPower = v
                        HyprlandConfig.set("decoration:rounding_power", v)
                    }
                }
                ConfigSwitch {
                    buttonIcon: "blur_on"
                    text: Translation.tr("Blur")
                    checked: Config.options.hyprland.decoration.blur.enabled
                    onCheckedChanged: {
                        if (checked === Config.options.hyprland.decoration.blur.enabled) return
                        Config.options.hyprland.decoration.blur.enabled = checked
                        HyprlandConfig.set("decoration:blur:enabled", checked ? 1 : 0)
                    }
                }
                ConfigSpinBox {
                    icon: "blur_circular"
                    text: Translation.tr("Blur Size")
                    value: Config.options.hyprland.decoration.blur.size
                    from: 1; to: 20; stepSize: 1
                    onValueChanged: {
                        if (value === Config.options.hyprland.decoration.blur.size) return
                        Config.options.hyprland.decoration.blur.size = value
                        HyprlandConfig.set("decoration:blur:size", value)
                    }
                }
                ConfigSpinBox {
                    icon: "layers"
                    text: Translation.tr("Blur Passes")
                    value: Config.options.hyprland.decoration.blur.passes
                    from: 1; to: 6; stepSize: 1
                    onValueChanged: {
                        if (value === Config.options.hyprland.decoration.blur.passes) return
                        Config.options.hyprland.decoration.blur.passes = value
                        HyprlandConfig.set("decoration:blur:passes", value)
                    }
                }
                ConfigSpinBox {
                    icon: "water_drop"
                    text: Translation.tr("Blur Vibrancy")
                    value: Math.round(Config.options.hyprland.decoration.blur.vibrancy * 100)
                    from: 0; to: 100; stepSize: 5
                    onValueChanged: {
                        const v = value/100.0
                        if (v === Config.options.hyprland.decoration.blur.vibrancy) return
                        Config.options.hyprland.decoration.blur.vibrancy = v
                        HyprlandConfig.set("decoration:blur:vibrancy", v)
                    }
                }
                ConfigSwitch {
                    buttonIcon: "visibility"
                    text: Translation.tr("Blur XRay")
                    checked: Config.options.hyprland.decoration.blur.xray
                    onCheckedChanged: {
                        if (checked === Config.options.hyprland.decoration.blur.xray) return
                        Config.options.hyprland.decoration.blur.xray = checked
                        HyprlandConfig.set("decoration:blur:xray", checked ? 1 : 0)
                    }
                }
                ConfigSwitch {
                    buttonIcon: "bolt"
                    text: Translation.tr("Blur New Optimizations")
                    checked: Config.options.hyprland.decoration.blur.newOptimizations
                    onCheckedChanged: {
                        if (checked === Config.options.hyprland.decoration.blur.newOptimizations) return
                        Config.options.hyprland.decoration.blur.newOptimizations = checked
                        HyprlandConfig.set("decoration:blur:new_optimizations", checked ? 1 : 0)
                    }
                }
                ConfigSpinBox {
                    icon: "border_outer"
                    text: Translation.tr("Border Size")
                    value: Config.options.hyprland.general.borderSize
                    from: 0; to: 10; stepSize: 1
                    onValueChanged: {
                        if (value === Config.options.hyprland.general.borderSize) return
                        Config.options.hyprland.general.borderSize = value
                        HyprlandConfig.set("general:border_size", value)
                    }
                }
                ConfigSpinBox {
                    icon: "margin"
                    text: Translation.tr("Gaps In")
                    value: Config.options.hyprland.general.gapsIn
                    from: 0; to: 40; stepSize: 1
                    onValueChanged: {
                        if (value === Config.options.hyprland.general.gapsIn) return
                        Config.options.hyprland.general.gapsIn = value
                        HyprlandConfig.set("general:gaps_in", value)
                    }
                }
                ConfigSpinBox {
                    icon: "open_in_full"
                    text: Translation.tr("Gaps Out")
                    value: Config.options.hyprland.general.gapsOut
                    from: 0; to: 60; stepSize: 1
                    onValueChanged: {
                        if (value === Config.options.hyprland.general.gapsOut) return
                        Config.options.hyprland.general.gapsOut = value
                        HyprlandConfig.set("general:gaps_out", value)
                    }
                }
                ConfigSpinBox {
                    icon: "view_agenda"
                    text: Translation.tr("Gaps Workspaces")
                    value: Config.options.hyprland.general.gapsWorkspaces
                    from: 0; to: 100; stepSize: 5
                    onValueChanged: {
                        if (value === Config.options.hyprland.general.gapsWorkspaces) return
                        Config.options.hyprland.general.gapsWorkspaces = value
                        HyprlandConfig.set("general:gaps_workspaces", value)
                    }
                }
                ConfigSpinBox {
                    icon: "opacity"
                    text: Translation.tr("Active Opacity")
                    value: Math.round(Config.options.hyprland.decoration.activeOpacity * 100)
                    from: 10; to: 100; stepSize: 5
                    onValueChanged: {
                        const newVal = value / 100.0
                        if (newVal === Config.options.hyprland.decoration.activeOpacity) return
                        Config.options.hyprland.decoration.activeOpacity = newVal
                        HyprlandConfig.set("decoration:active_opacity", newVal)
                    }
                }
                ConfigSpinBox {
                    icon: "opacity"
                    text: Translation.tr("Inactive Opacity")
                    value: Math.round(Config.options.hyprland.decoration.inactiveOpacity * 100)
                    from: 10; to: 100; stepSize: 5
                    onValueChanged: {
                        const newVal = value / 100.0
                        if (newVal === Config.options.hyprland.decoration.inactiveOpacity) return
                        Config.options.hyprland.decoration.inactiveOpacity = newVal
                        HyprlandConfig.set("decoration:inactive_opacity", newVal)
                    }
                }
                ConfigSpinBox {
                    icon: "opacity"
                    text: Translation.tr("Fullscreen Opacity")
                    value: Math.round(Config.options.hyprland.decoration.fullscreenOpacity * 100)
                    from: 10; to: 100; stepSize: 5
                    onValueChanged: {
                        const v = value/100.0
                        if (v === Config.options.hyprland.decoration.fullscreenOpacity) return
                        Config.options.hyprland.decoration.fullscreenOpacity = v
                        HyprlandConfig.set("decoration:fullscreen_opacity", v)
                    }
                }
                ConfigSwitch {
                    buttonIcon: "contrast"
                    text: Translation.tr("Dim Inactive")
                    checked: Config.options.hyprland.decoration.dimInactive
                    onCheckedChanged: {
                        if (checked === Config.options.hyprland.decoration.dimInactive) return
                        Config.options.hyprland.decoration.dimInactive = checked
                        HyprlandConfig.set("decoration:dim_inactive", checked ? 1 : 0)
                    }
                }
                ConfigSpinBox {
                    icon: "brightness_6"
                    text: Translation.tr("Dim Strength")
                    value: Math.round(Config.options.hyprland.decoration.dimStrength * 100)
                    from: 0; to: 100; stepSize: 5
                    enabled: Config.options.hyprland.decoration.dimInactive
                    onValueChanged: {
                        const v = value/100.0
                        if (v === Config.options.hyprland.decoration.dimStrength) return
                        Config.options.hyprland.decoration.dimStrength = v
                        HyprlandConfig.set("decoration:dim_strength", v)
                    }
                }
                ConfigSpinBox {
                    icon: "dark_mode"
                    text: Translation.tr("Dim Special")
                    value: Math.round(Config.options.hyprland.decoration.dimSpecial * 100)
                    from: 0; to: 100; stepSize: 5
                    onValueChanged: {
                        const v = value/100.0
                        if (v === Config.options.hyprland.decoration.dimSpecial) return
                        Config.options.hyprland.decoration.dimSpecial = v
                        HyprlandConfig.set("decoration:dim_special", v)
                    }
                }
                ConfigSwitch {
                    buttonIcon: "crop_5_4"
                    text: Translation.tr("Border Part Of Window")
                    checked: Config.options.hyprland.decoration.borderPartOfWindow
                    onCheckedChanged: {
                        if (checked === Config.options.hyprland.decoration.borderPartOfWindow) return
                        Config.options.hyprland.decoration.borderPartOfWindow = checked
                        HyprlandConfig.set("decoration:border_part_of_window", checked ? 1 : 0)
                    }
                }
                // Shadow
                ConfigSwitch {
                    buttonIcon: "shadow"
                    text: Translation.tr("Shadow Enabled")
                    checked: Config.options.hyprland.decoration.shadow.enabled
                    onCheckedChanged: {
                        if (checked === Config.options.hyprland.decoration.shadow.enabled) return
                        Config.options.hyprland.decoration.shadow.enabled = checked
                        HyprlandConfig.set("decoration:shadow:enabled", checked ? 1 : 0)
                    }
                }
                ConfigSpinBox {
                    icon: "expand"
                    text: Translation.tr("Shadow Range")
                    value: Config.options.hyprland.decoration.shadow.range
                    from: 0; to: 100; stepSize: 1
                    enabled: Config.options.hyprland.decoration.shadow.enabled
                    onValueChanged: {
                        if (value === Config.options.hyprland.decoration.shadow.range) return
                        Config.options.hyprland.decoration.shadow.range = value
                        HyprlandConfig.set("decoration:shadow:range", value)
                    }
                }
                ConfigSpinBox {
                    icon: "filter_b_and_w"
                    text: Translation.tr("Shadow Render Power")
                    value: Config.options.hyprland.decoration.shadow.renderPower
                    from: 1; to: 4; stepSize: 1
                    enabled: Config.options.hyprland.decoration.shadow.enabled
                    onValueChanged: {
                        if (value === Config.options.hyprland.decoration.shadow.renderPower) return
                        Config.options.hyprland.decoration.shadow.renderPower = value
                        HyprlandConfig.set("decoration:shadow:render_power", value)
                    }
                }
                ConfigSwitch {
                    buttonIcon: "motion_photos_off"
                    text: Translation.tr("Shadow Sharp")
                    checked: Config.options.hyprland.decoration.shadow.sharp
                    enabled: Config.options.hyprland.decoration.shadow.enabled
                    onCheckedChanged: {
                        if (checked === Config.options.hyprland.decoration.shadow.sharp) return
                        Config.options.hyprland.decoration.shadow.sharp = checked
                        HyprlandConfig.set("decoration:shadow:sharp", checked ? 1 : 0)
                    }
                }
                ConfigSpinBox {
                    icon: "open_with"
                    text: Translation.tr("Shadow Offset X")
                    value: Config.options.hyprland.decoration.shadow.offsetX
                    from: -50; to: 50; stepSize: 1
                    enabled: Config.options.hyprland.decoration.shadow.enabled
                    onValueChanged: {
                        if (value === Config.options.hyprland.decoration.shadow.offsetX) return
                        Config.options.hyprland.decoration.shadow.offsetX = value
                        HyprlandConfig.set("decoration:shadow:offset", `${value}, ${Config.options.hyprland.decoration.shadow.offsetY}`)
                    }
                }
                ConfigSpinBox {
                    icon: "open_with"
                    text: Translation.tr("Shadow Offset Y")
                    value: Config.options.hyprland.decoration.shadow.offsetY
                    from: -50; to: 50; stepSize: 1
                    enabled: Config.options.hyprland.decoration.shadow.enabled
                    onValueChanged: {
                        if (value === Config.options.hyprland.decoration.shadow.offsetY) return
                        Config.options.hyprland.decoration.shadow.offsetY = value
                        HyprlandConfig.set("decoration:shadow:offset", `${Config.options.hyprland.decoration.shadow.offsetX}, ${value}`)
                    }
                }
                ConfigSpinBox {
                    icon: "zoom_out_map"
                    text: Translation.tr("Shadow Scale")
                    value: Math.round(Config.options.hyprland.decoration.shadow.scale * 100)
                    from: 5; to: 200; stepSize: 5
                    enabled: Config.options.hyprland.decoration.shadow.enabled
                    onValueChanged: {
                        const v = value/100.0
                        if (v === Config.options.hyprland.decoration.shadow.scale) return
                        Config.options.hyprland.decoration.shadow.scale = v
                        HyprlandConfig.set("decoration:shadow:scale", v)
                    }
                }
                // Shadow inactive color
                ConfigTextArea {
                    Layout.fillWidth: true
                    buttonIcon: "palette"
                    text: Translation.tr("Shadow Inactive Color")
                    placeholderText: "rgba(00000020)"
                    Component.onCompleted: value = Config.options.hyprland.decoration.shadow.colorInactive ?? ""
                    confirmButtonVisible: true
                    onConfirmClicked: {
                        Config.options.hyprland.decoration.shadow.colorInactive = value.trim()
                        HyprlandConfig.set("decoration:shadow:color_inactive", value.trim() || "[[EMPTY]]")
                    }
                }
            }

            // Advanced Decoration
            ContentSubsection {
                title: Translation.tr("Advanced Decoration")
                GroupedList {
                    // Dim Modal
                    ConfigSwitch {
                        buttonIcon: "window"
                        text: Translation.tr("Dim Modal")
                        checked: Config.options.hyprland.decoration.dimModal
                        onCheckedChanged: {
                            if (checked === Config.options.hyprland.decoration.dimModal) return
                            Config.options.hyprland.decoration.dimModal = checked
                            HyprlandConfig.set("decoration:dim_modal", checked ? 1 : 0)
                        }
                    }
                    // Dim Around
                    ConfigSwitch {
                        buttonIcon: "center_focus_weak"
                        text: Translation.tr("Dim Around")
                        checked: Config.options.hyprland.decoration.dimAround
                        onCheckedChanged: {
                            if (checked === Config.options.hyprland.decoration.dimAround) return
                            Config.options.hyprland.decoration.dimAround = checked
                            HyprlandConfig.set("decoration:dim_around", checked ? 1 : 0)
                        }
                    }
                }
            }

            // Advanced Blur
            ContentSubsection {
                title: Translation.tr("Advanced Blur")
                GroupedList {
                    // Noise
                    ConfigSlider {
                        text: Translation.tr("Noise")
                        buttonIcon: "grain"
                        value: Math.round(Config.options.hyprland.decoration.blur.noise * 100)
                        from: 0; to: 100
                        onValueChanged: {
                            const v = value / 100.0
                            if (v === Config.options.hyprland.decoration.blur.noise) return
                            Config.options.hyprland.decoration.blur.noise = v
                            HyprlandConfig.set("decoration:blur:noise", v)
                        }
                    }
                    // Contrast
                    ConfigSlider {
                        text: Translation.tr("Contrast")
                        buttonIcon: "contrast"
                        value: Math.round(Config.options.hyprland.decoration.blur.contrast * 100)
                        from: 0; to: 100
                        onValueChanged: {
                            const v = value / 100.0
                            if (v === Config.options.hyprland.decoration.blur.contrast) return
                            Config.options.hyprland.decoration.blur.contrast = v
                            HyprlandConfig.set("decoration:blur:contrast", v)
                        }
                    }
                    // Brightness
                    ConfigSlider {
                        text: Translation.tr("Brightness")
                        buttonIcon: "brightness_6"
                        value: Math.round(Config.options.hyprland.decoration.blur.brightness * 100)
                        from: 0; to: 100
                        onValueChanged: {
                            const v = value / 100.0
                            if (v === Config.options.hyprland.decoration.blur.brightness) return
                            Config.options.hyprland.decoration.blur.brightness = v
                            HyprlandConfig.set("decoration:blur:brightness", v)
                        }
                    }
                    // Vibrancy Darkness
                    ConfigSlider {
                        text: Translation.tr("Vibrancy Darkness")
                        buttonIcon: "dark_mode"
                        value: Math.round(Config.options.hyprland.decoration.blur.vibrancyDarkness * 100)
                        from: 0; to: 100
                        onValueChanged: {
                            const v = value / 100.0
                            if (v === Config.options.hyprland.decoration.blur.vibrancyDarkness) return
                            Config.options.hyprland.decoration.blur.vibrancyDarkness = v
                            HyprlandConfig.set("decoration:blur:vibrancy_darkness", v)
                        }
                    }
                    // Blur Special
                    ConfigSwitch {
                        buttonIcon: "blur_on"
                        text: Translation.tr("Blur Special")
                        checked: Config.options.hyprland.decoration.blur.special
                        onCheckedChanged: {
                            if (checked === Config.options.hyprland.decoration.blur.special) return
                            Config.options.hyprland.decoration.blur.special = checked
                            HyprlandConfig.set("decoration:blur:special", checked ? 1 : 0)
                        }
                    }
                    // Blur Popups
                    ConfigSwitch {
                        buttonIcon: "web_asset"
                        text: Translation.tr("Blur Popups")
                        checked: Config.options.hyprland.decoration.blur.popups
                        onCheckedChanged: {
                            if (checked === Config.options.hyprland.decoration.blur.popups) return
                            Config.options.hyprland.decoration.blur.popups = checked
                            HyprlandConfig.set("decoration:blur:popups", checked ? 1 : 0)
                        }
                    }
                    // Blur Popups Ignore Alpha
                    ConfigSwitch {
                        buttonIcon: "visibility"
                        text: Translation.tr("Popups Ignore Alpha")
                        checked: Config.options.hyprland.decoration.blur.popupsIgnorealpha
                        enabled: Config.options.hyprland.decoration.blur.popups
                        onCheckedChanged: {
                            if (checked === Config.options.hyprland.decoration.blur.popupsIgnorealpha) return
                            Config.options.hyprland.decoration.blur.popupsIgnorealpha = checked
                            HyprlandConfig.set("decoration:blur:popups_ignorealpha", checked ? 1 : 0)
                        }
                    }
                }
            }
        }

        // General & Snap
        ContentSection {
            icon: "tune"
            shape: MaterialShape.Shape.Cookie9Sided
            title: Translation.tr("General & Snap")
            GroupedList {
                ConfigSwitch {
                    buttonIcon: "border_outer"
                    text: Translation.tr("Resize On Border")
                    checked: Config.options.hyprland.general.resizeOnBorder
                    onCheckedChanged: {
                        if (checked === Config.options.hyprland.general.resizeOnBorder) return
                        Config.options.hyprland.general.resizeOnBorder = checked
                        HyprlandConfig.set("general:resize_on_border", checked ? 1 : 0)
                    }
                }
                ConfigSwitch {
                    buttonIcon: "tear_off"
                    text: Translation.tr("Allow Tearing")
                    checked: Config.options.hyprland.general.allowTearing
                    onCheckedChanged: {
                        if (checked === Config.options.hyprland.general.allowTearing) return
                        Config.options.hyprland.general.allowTearing = checked
                        HyprlandConfig.set("general:allow_tearing", checked ? 1 : 0)
                    }
                }
                ConfigSwitch {
                    buttonIcon: "magnet"
                    text: Translation.tr("Snap Enabled")
                    checked: Config.options.hyprland.general.snapEnabled
                    onCheckedChanged: {
                        if (checked === Config.options.hyprland.general.snapEnabled) return
                        Config.options.hyprland.general.snapEnabled = checked
                        HyprlandConfig.set("general:snap:enabled", checked ? 1 : 0)
                    }
                }
                ConfigSpinBox {
                    icon: "space_bar"
                    text: Translation.tr("Snap Window Gap")
                    value: Config.options.hyprland.general.snapWindowGap
                    from: 0; to: 100; stepSize: 1
                    enabled: Config.options.hyprland.general.snapEnabled
                    onValueChanged: {
                        if (value === Config.options.hyprland.general.snapWindowGap) return
                        Config.options.hyprland.general.snapWindowGap = value
                        HyprlandConfig.set("general:snap:window_gap", value)
                    }
                }
                ConfigSpinBox {
                    icon: "monitor"
                    text: Translation.tr("Snap Monitor Gap")
                    value: Config.options.hyprland.general.snapMonitorGap
                    from: 0; to: 100; stepSize: 1
                    enabled: Config.options.hyprland.general.snapEnabled
                    onValueChanged: {
                        if (value === Config.options.hyprland.general.snapMonitorGap) return
                        Config.options.hyprland.general.snapMonitorGap = value
                        HyprlandConfig.set("general:snap:monitor_gap", value)
                    }
                }
                ConfigSwitch {
                    buttonIcon: "overlap"
                    text: Translation.tr("Snap Border Overlap")
                    checked: Config.options.hyprland.general.snapBorderOverlap
                    enabled: Config.options.hyprland.general.snapEnabled
                    onCheckedChanged: {
                        if (checked === Config.options.hyprland.general.snapBorderOverlap) return
                        Config.options.hyprland.general.snapBorderOverlap = checked
                        HyprlandConfig.set("general:snap:border_overlap", checked ? 1 : 0)
                    }
                }
                ConfigSwitch {
                    buttonIcon: "grid_on"
                    text: Translation.tr("Snap Respect Gaps")
                    checked: Config.options.hyprland.general.snapRespectGaps
                    enabled: Config.options.hyprland.general.snapEnabled
                    onCheckedChanged: {
                        if (checked === Config.options.hyprland.general.snapRespectGaps) return
                        Config.options.hyprland.general.snapRespectGaps = checked
                        HyprlandConfig.set("general:snap:respect_gaps", checked ? 1 : 0)
                    }
                }
            }

            // Advanced General Settings
            ContentSubsection {
                title: Translation.tr("Advanced General Settings")
                GroupedList {
                    // Active border color
                    ConfigTextArea {
                        Layout.fillWidth: true
                        buttonIcon: "palette"
                        text: Translation.tr("Active Border Color")
                        placeholderText: Translation.tr("rgba(33, 33, 33, 1.0)")
                        Component.onCompleted: value = Config.options.hyprland.general.colActiveBorder ?? ""
                        confirmButtonVisible: true
                        onConfirmClicked: {
                            Config.options.hyprland.general.colActiveBorder = value.trim()
                            HyprlandConfig.set("general:col.active_border", value.trim() || "[[EMPTY]]")
                        }
                    }
                    // Inactive border color
                    ConfigTextArea {
                        Layout.fillWidth: true
                        buttonIcon: "palette"
                        text: Translation.tr("Inactive Border Color")
                        placeholderText: Translation.tr("rgba(33, 33, 33, 0.8)")
                        Component.onCompleted: value = Config.options.hyprland.general.colInactiveBorder ?? ""
                        confirmButtonVisible: true
                        onConfirmClicked: {
                            Config.options.hyprland.general.colInactiveBorder = value.trim()
                            HyprlandConfig.set("general:col.inactive_border", value.trim() || "[[EMPTY]]")
                        }
                    }
                    // Nogroup border color
                    ConfigTextArea {
                        Layout.fillWidth: true
                        buttonIcon: "palette"
                        text: Translation.tr("Nogroup Border Color")
                        placeholderText: Translation.tr("rgba(33, 33, 33, 0.8)")
                        Component.onCompleted: value = Config.options.hyprland.general.colNogroupBorder ?? ""
                        confirmButtonVisible: true
                        onConfirmClicked: {
                            Config.options.hyprland.general.colNogroupBorder = value.trim()
                            HyprlandConfig.set("general:col.nogroup_border", value.trim() || "[[EMPTY]]")
                        }
                    }
                    // Float gaps
                    ConfigSpinBox {
                        icon: "view_carousel"
                        text: Translation.tr("Float Gaps")
                        value: Config.options.hyprland.general.floatGaps
                        from: 0; to: 100; stepSize: 1
                        onValueChanged: {
                            if (value === Config.options.hyprland.general.floatGaps) return
                            Config.options.hyprland.general.floatGaps = value
                            HyprlandConfig.set("general:float_gaps", value)
                        }
                    }
                    // Extend border grab area
                    ConfigSwitch {
                        buttonIcon: "drag_indicator"
                        text: Translation.tr("Extend Border Grab Area")
                        checked: Config.options.hyprland.general.extendBorderGrabArea
                        onCheckedChanged: {
                            if (checked === Config.options.hyprland.general.extendBorderGrabArea) return
                            Config.options.hyprland.general.extendBorderGrabArea = checked
                            HyprlandConfig.set("general:extend_border_grab_area", checked ? 1 : 0)
                        }
                    }
                    // Hover icon on border
                    ConfigSwitch {
                        buttonIcon: "cursor"
                        text: Translation.tr("Hover Icon On Border")
                        checked: Config.options.hyprland.general.hoverIconOnBorder
                        onCheckedChanged: {
                            if (checked === Config.options.hyprland.general.hoverIconOnBorder) return
                            Config.options.hyprland.general.hoverIconOnBorder = checked
                            HyprlandConfig.set("general:hover_icon_on_border", checked ? 1 : 0)
                        }
                    }
                    // No focus fallback
                    ConfigSwitch {
                        buttonIcon: "focus_disabled"
                        text: Translation.tr("No Focus Fallback")
                        checked: Config.options.hyprland.general.noFocusFallback
                        onCheckedChanged: {
                            if (checked === Config.options.hyprland.general.noFocusFallback) return
                            Config.options.hyprland.general.noFocusFallback = checked
                            HyprlandConfig.set("general:no_focus_fallback", checked ? 1 : 0)
                        }
                    }
                }
            }
        }

        // Misc
        ContentSection {
            icon: "settings"
            shape: MaterialShape.Shape.Sunny
            title: Translation.tr("Misc")
            GroupedList {
                ConfigSwitch {
                    buttonIcon: "image_not_supported"
                    text: Translation.tr("Disable Hyprland Logo")
                    checked: Config.options.hyprland.misc.disableHyprlandLogo
                    onCheckedChanged: {
                        if (checked === Config.options.hyprland.misc.disableHyprlandLogo) return
                        Config.options.hyprland.misc.disableHyprlandLogo = checked
                        HyprlandConfig.set("misc:disable_hyprland_logo", checked ? 1 : 0)
                    }
                }
                ConfigSwitch {
                    buttonIcon: "wallpaper"
                    text: Translation.tr("Disable Splash Rendering")
                    checked: Config.options.hyprland.misc.disableSplashRendering
                    onCheckedChanged: {
                        if (checked === Config.options.hyprland.misc.disableSplashRendering) return
                        Config.options.hyprland.misc.disableSplashRendering = checked
                        HyprlandConfig.set("misc:disable_splash_rendering", checked ? 1 : 0)
                    }
                }
                ConfigSelectionArray {
                    text: Translation.tr("VRR")
                    icon: "monitor"
                    currentValue: Config.options.hyprland.misc.vrr
                    onSelected: newValue => {
                        Config.options.hyprland.misc.vrr = newValue
                        HyprlandConfig.set("misc:vrr", newValue)
                    }
                    options: [
                        { displayName: Translation.tr("Off"), icon: "block", value: 0 },
                        { displayName: Translation.tr("On"), icon: "check", value: 1 },
                        { displayName: Translation.tr("Fullscreen Only"), icon: "fullscreen", value: 2 }
                    ]
                }
                ConfigSwitch {
                    buttonIcon: "mouse"
                    text: Translation.tr("Mouse Move Enables DPMS")
                    checked: Config.options.hyprland.misc.mouseMoveEnablesDpms
                    onCheckedChanged: {
                        if (checked === Config.options.hyprland.misc.mouseMoveEnablesDpms) return
                        Config.options.hyprland.misc.mouseMoveEnablesDpms = checked
                        HyprlandConfig.set("misc:mouse_move_enables_dpms", checked ? 1 : 0)
                    }
                }
                ConfigSwitch {
                    buttonIcon: "keyboard"
                    text: Translation.tr("Key Press Enables DPMS")
                    checked: Config.options.hyprland.misc.keyPressEnablesDpms
                    onCheckedChanged: {
                        if (checked === Config.options.hyprland.misc.keyPressEnablesDpms) return
                        Config.options.hyprland.misc.keyPressEnablesDpms = checked
                        HyprlandConfig.set("misc:key_press_enables_dpms", checked ? 1 : 0)
                    }
                }
                ConfigSwitch {
                    buttonIcon: "open_with"
                    text: Translation.tr("Animate Manual Resizes")
                    checked: Config.options.hyprland.misc.animateManualResizes
                    onCheckedChanged: {
                        if (checked === Config.options.hyprland.misc.animateManualResizes) return
                        Config.options.hyprland.misc.animateManualResizes = checked
                        HyprlandConfig.set("misc:animate_manual_resizes", checked ? 1 : 0)
                    }
                }
                ConfigSwitch {
                    buttonIcon: "drag_indicator"
                    text: Translation.tr("Animate Mouse Window Dragging")
                    checked: Config.options.hyprland.misc.animateMouseWindowDragging
                    onCheckedChanged: {
                        if (checked === Config.options.hyprland.misc.animateMouseWindowDragging) return
                        Config.options.hyprland.misc.animateMouseWindowDragging = checked
                        HyprlandConfig.set("misc:animate_mouse_windowdragging", checked ? 1 : 0)
                    }
                }
                ConfigSelectionArray {
                    text: Translation.tr("Focus On Activate")
                    icon: "center_focus_strong"
                    currentValue: Config.options.hyprland.misc.focusOnActivate
                    onSelected: newValue => {
                        Config.options.hyprland.misc.focusOnActivate = newValue
                        HyprlandConfig.set("misc:focus_on_activate", newValue)
                    }
                    options: [
                        { displayName: "0 - Next candidate", icon: "looks_one", value: 0 },
                        { displayName: "1 - Window under cursor", icon: "mouse", value: 1 },
                        { displayName: "2 - Most recent", icon: "history", value: 2 }
                    ]
                }
            }
        }

        // Cursor
        ContentSection {
            icon: "mouse"
            shape: MaterialShape.Shape.Oval
            title: Translation.tr("Cursor")
            GroupedList {
                ConfigSpinBox {
                    icon: "zoom_in"
                    text: Translation.tr("Zoom Factor")
                    value: Math.round(Config.options.hyprland.cursor.zoomFactor * 10)
                    from: 10; to: 30; stepSize: 1
                    onValueChanged: {
                        const v = value/10.0
                        if (v === Config.options.hyprland.cursor.zoomFactor) return
                        Config.options.hyprland.cursor.zoomFactor = v
                        HyprlandConfig.set("cursor:zoom_factor", v)
                    }
                }
                ConfigSwitch {
                    buttonIcon: "open_with"
                    text: Translation.tr("Zoom Rigid")
                    checked: Config.options.hyprland.cursor.zoomRigid
                    onCheckedChanged: {
                        if (checked === Config.options.hyprland.cursor.zoomRigid) return
                        Config.options.hyprland.cursor.zoomRigid = checked
                        HyprlandConfig.set("cursor:zoom_rigid", checked ? 1 : 0)
                    }
                }
                ConfigSwitch {
                    buttonIcon: "keyboard_hide"
                    text: Translation.tr("Hide On Key Press")
                    checked: Config.options.hyprland.cursor.hideOnKeyPress
                    onCheckedChanged: {
                        if (checked === Config.options.hyprland.cursor.hideOnKeyPress) return
                        Config.options.hyprland.cursor.hideOnKeyPress = checked
                        HyprlandConfig.set("cursor:hide_on_key_press", checked ? 1 : 0)
                    }
                }
                ConfigSpinBox {
                    icon: "timer"
                    text: Translation.tr("Inactive Timeout (s)")
                    value: Config.options.hyprland.cursor.inactiveTimeout
                    from: 0; to: 60; stepSize: 1
                    onValueChanged: {
                        if (value === Config.options.hyprland.cursor.inactiveTimeout) return
                        Config.options.hyprland.cursor.inactiveTimeout = value
                        HyprlandConfig.set("cursor:inactive_timeout", value)
                    }
                }
                ConfigSpinBox {
                    icon: "padding"
                    text: Translation.tr("Hotspot Padding")
                    value: Config.options.hyprland.cursor.hotspotPadding
                    from: 0; to: 10; stepSize: 1
                    onValueChanged: {
                        if (value === Config.options.hyprland.cursor.hotspotPadding) return
                        Config.options.hyprland.cursor.hotspotPadding = value
                        HyprlandConfig.set("cursor:hotspot_padding", value)
                    }
                }
                ConfigSwitch {
                    buttonIcon: "block"
                    text: Translation.tr("No Warps")
                    checked: Config.options.hyprland.cursor.noWarps
                    onCheckedChanged: {
                        if (checked === Config.options.hyprland.cursor.noWarps) return
                        Config.options.hyprland.cursor.noWarps = checked
                        HyprlandConfig.set("cursor:no_warps", checked ? 1 : 0)
                    }
                }
                ConfigSwitch {
                    buttonIcon: "repeat"
                    text: Translation.tr("Persistent Warps")
                    checked: Config.options.hyprland.cursor.persistentWarps
                    onCheckedChanged: {
                        if (checked === Config.options.hyprland.cursor.persistentWarps) return
                        Config.options.hyprland.cursor.persistentWarps = checked
                        HyprlandConfig.set("cursor:persistent_warps", checked ? 1 : 0)
                    }
                }
            }
        }

        // Gestures
        ContentSection {
            icon: "gesture"
            shape: MaterialShape.Shape.Diamond
            title: Translation.tr("Gestures")
            GroupedList {
                ConfigSpinBox {
                    icon: "swipe"
                    text: Translation.tr("Workspace Swipe Distance")
                    value: Config.options.hyprland.gestures.workspaceSwipeDistance
                    from: 100; to: 1000; stepSize: 10
                    onValueChanged: {
                        if (value === Config.options.hyprland.gestures.workspaceSwipeDistance) return
                        Config.options.hyprland.gestures.workspaceSwipeDistance = value
                        HyprlandConfig.set("gestures:workspace_swipe_distance", value)
                    }
                }
                ConfigSpinBox {
                    icon: "cancel"
                    text: Translation.tr("Swipe Cancel Ratio (%)")
                    value: Math.round(Config.options.hyprland.gestures.workspaceSwipeCancelRatio * 100)
                    from: 0; to: 100; stepSize: 5
                    onValueChanged: {
                        const v = value/100.0
                        if (v === Config.options.hyprland.gestures.workspaceSwipeCancelRatio) return
                        Config.options.hyprland.gestures.workspaceSwipeCancelRatio = v
                        HyprlandConfig.set("gestures:workspace_swipe_cancel_ratio", v)
                    }
                }
                ConfigSpinBox {
                    icon: "speed"
                    text: Translation.tr("Swipe Min Speed")
                    value: Config.options.hyprland.gestures.workspaceSwipeMinSpeedToForce
                    from: 0; to: 50; stepSize: 1
                    onValueChanged: {
                        if (value === Config.options.hyprland.gestures.workspaceSwipeMinSpeedToForce) return
                        Config.options.hyprland.gestures.workspaceSwipeMinSpeedToForce = value
                        HyprlandConfig.set("gestures:workspace_swipe_min_speed_to_force", value)
                    }
                }
                ConfigSwitch {
                    buttonIcon: "lock"
                    text: Translation.tr("Swipe Direction Lock")
                    checked: Config.options.hyprland.gestures.workspaceSwipeDirectionLock
                    onCheckedChanged: {
                        if (checked === Config.options.hyprland.gestures.workspaceSwipeDirectionLock) return
                        Config.options.hyprland.gestures.workspaceSwipeDirectionLock = checked
                        HyprlandConfig.set("gestures:workspace_swipe_direction_lock", checked ? 1 : 0)
                    }
                }
            }
        }

        // Custom Binds — power user (writes to ~/.config/hypr/custom/keybinds.lua)
        ContentSection {
            id: customBindsSection
            icon: "keyboard"
            shape: MaterialShape.Shape.Pill
            title: Translation.tr("Custom Binds (Advanced)")
            GroupedList {
                StyledText {
                    Layout.fillWidth: true
                    wrapMode: Text.Wrap
                    font.pixelSize: Appearance.font.pixelSize.small
                    color: Appearance.colors.colSubtext
                    text: Translation.tr("Add any hl.bind(...) lines. File is ~/.config/hypr/custom/keybinds.lua and is auto-sourced by hyprland.lua. Example: hl.bind(\"SUPER + T\", hl.dsp.exec_cmd(\"kitty\"))")
                }
            }
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: bindsArea.implicitHeight + 16
                radius: Appearance.rounding.normal
                color: Appearance.colors.colLayer1
                TextArea {
                    id: bindsArea
                    anchors.fill: parent
                    anchors.margins: 8
                    text: Config.options.hyprland.customBindsLua
                    placeholderText: "-- hl.bind(\"SUPER + T\", hl.dsp.exec_cmd(\"kitty\"))"
                    selectByMouse: true
                    wrapMode: Text.Wrap
                    font.family: Appearance.font.family.monospace
                    font.pixelSize: Appearance.font.pixelSize.small
                    color: Appearance.colors.colOnLayer1
                    background: null
                    onTextChanged: bindsDebounce.restart()
                }
            }
            RowLayout {
                Layout.fillWidth: true
                RippleButtonWithIcon {
                    materialIcon: "save"
                    mainText: Translation.tr("Save Binds")
                    onClicked: customBindsSection.saveBinds()
                    colBackground: Appearance.colors.colPrimaryContainer
                }
                RippleButtonWithIcon {
                    materialIcon: "refresh"
                    mainText: Translation.tr("Reload Hyprland")
                    onClicked: reloadProc.running = true
                    colBackground: Appearance.colors.colSecondaryContainer
                }
                Item { Layout.fillWidth: true }
                StyledText {
                    id: bindsStatus
                    font.pixelSize: Appearance.font.pixelSize.small
                    color: Appearance.colors.colSubtext
                }
            }
            Timer { id: bindsDebounce; interval: 1500; onTriggered: customBindsSection.saveBinds() }
            function saveBinds() {
                Config.options.hyprland.customBindsLua = bindsArea.text
                saveBindsProc.command = ["python3", HyprlandConfig.configuratorScriptPath, "--custom-binds", bindsArea.text, "--custom-binds-file", HyprlandConfig.customBindsPath]
                saveBindsProc.running = true
            }
            Process { id: saveBindsProc; onExited: (code, status) => { bindsStatus.text = code===0 ? Translation.tr("Saved") : Translation.tr("Failed"); clearBindsStatus.restart() } }
            Timer { id: clearBindsStatus; interval: 2000; onTriggered: bindsStatus.text = "" }
            Process { id: reloadProc; command: ["hyprctl", "reload"] }
        }

        // Custom Rules
        ContentSection {
            id: customRulesSection
            icon: "rule"
            shape: MaterialShape.Shape.Square
            title: Translation.tr("Custom Window Rules (Advanced)")
            GroupedList {
                StyledText {
                    Layout.fillWidth: true
                    wrapMode: Text.Wrap
                    font.pixelSize: Appearance.font.pixelSize.small
                    color: Appearance.colors.colSubtext
                    text: Translation.tr("Add any hl.window_rule / hl.workspace_rule / hl.layer_rule lines. File is ~/.config/hypr/custom/rules.lua. Example: hl.window_rule({match={class=\"kitty\"}, float=true})")
                }
            }
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: rulesArea.implicitHeight + 16
                radius: Appearance.rounding.normal
                color: Appearance.colors.colLayer1
                TextArea {
                    id: rulesArea
                    anchors.fill: parent
                    anchors.margins: 8
                    text: Config.options.hyprland.customRulesLua
                    placeholderText: "-- hl.window_rule({match={class=\"kitty\"}, float=true})"
                    selectByMouse: true
                    wrapMode: Text.Wrap
                    font.family: Appearance.font.family.monospace
                    font.pixelSize: Appearance.font.pixelSize.small
                    color: Appearance.colors.colOnLayer1
                    background: null
                    onTextChanged: rulesDebounce.restart()
                }
            }
            RowLayout {
                Layout.fillWidth: true
                RippleButtonWithIcon {
                    materialIcon: "save"
                    mainText: Translation.tr("Save Rules")
                    onClicked: customRulesSection.saveRules()
                    colBackground: Appearance.colors.colPrimaryContainer
                }
                RippleButtonWithIcon {
                    materialIcon: "refresh"
                    mainText: Translation.tr("Reload Hyprland")
                    onClicked: reloadRulesProc.running = true
                    colBackground: Appearance.colors.colSecondaryContainer
                }
                Item { Layout.fillWidth: true }
                StyledText { id: rulesStatus; font.pixelSize: Appearance.font.pixelSize.small; color: Appearance.colors.colSubtext }
            }
            Timer { id: rulesDebounce; interval: 1500; onTriggered: customRulesSection.saveRules() }
            function saveRules() {
                Config.options.hyprland.customRulesLua = rulesArea.text
                saveRulesProc.command = ["python3", HyprlandConfig.configuratorScriptPath, "--custom-rules", rulesArea.text, "--custom-rules-file", HyprlandConfig.customRulesPath]
                saveRulesProc.running = true
            }
            Process { id: saveRulesProc; onExited: (code, s) => { rulesStatus.text = code===0 ? Translation.tr("Saved") : Translation.tr("Failed"); clearRulesStatus.restart() } }
            Timer { id: clearRulesStatus; interval: 2000; onTriggered: rulesStatus.text = "" }
            Process { id: reloadRulesProc; command: ["hyprctl", "reload"] }
        }

        // Workspace Rules (Structured)
        ContentSection {
            id: workspaceRulesSection
            icon: "workspaces"
            shape: MaterialShape.Shape.Diamond
            title: Translation.tr("Workspace Rules")
            GroupedList {
                StyledText {
                    Layout.fillWidth: true
                    wrapMode: Text.Wrap
                    font.pixelSize: Appearance.font.pixelSize.small
                    color: Appearance.colors.colSubtext
                    text: Translation.tr("Bind workspaces to monitors, set per-workspace gaps, border, rounding, etc. Each rule generates a hl.workspace_rule() line.")
                }
            }
            // List of workspace rules
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4
                Repeater {
                    model: Config.options.hyprland.general.workspaceRules
                    delegate: Rectangle {
                        required property var modelData
                        required property int index
                        Layout.fillWidth: true
                        implicitHeight: wrRow.implicitHeight + 12
                        radius: Appearance.rounding.small
                        color: Appearance.colors.colLayer1
                        RowLayout {
                            id: wrRow
                            anchors.fill: parent
                            anchors.margins: 6
                            spacing: 6
                            StyledText {
                                text: modelData.workspace || "*"
                                color: Appearance.colors.colOnLayer1
                                Layout.preferredWidth: 60
                                elide: Text.ElideRight
                                font.pixelSize: Appearance.font.pixelSize.small
                            }
                            StyledText {
                                text: modelData.monitor || ""
                                color: Appearance.colors.colSubtext
                                Layout.preferredWidth: 70
                                elide: Text.ElideRight
                                font.pixelSize: Appearance.font.pixelSize.small
                            }
                            StyledText {
                                text: {
                                    let props = []
                                    if (modelData.float) props.push("float")
                                    if (modelData.gapsIn !== undefined) props.push("gaps:" + modelData.gapsIn)
                                    if (modelData.border !== undefined) props.push("border:" + modelData.border)
                                    if (modelData.rounding !== undefined) props.push("rounding:" + modelData.rounding)
                                    if (modelData.decorate !== undefined) props.push("decorate:" + modelData.decorate)
                                    if (modelData.defaultName) props.push("name:" + modelData.defaultName)
                                    return props.join("  ")
                                }
                                Layout.fillWidth: true
                                color: Appearance.colors.colSubtext
                                font.pixelSize: Appearance.font.pixelSize.smaller
                                elide: Text.ElideRight
                            }
                            Rectangle {
                                implicitWidth: 28; implicitHeight: 28; radius: 14
                                color: delWrHover.containsMouse ? Appearance.colors.colPrimaryContainer : Appearance.colors.colLayer2
                                MaterialSymbol { anchors.centerIn: parent; text: "delete"; iconSize: 16; color: Appearance.colors.colOnLayer1 }
                                MouseArea { id: delWrHover; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: {
                                    let arr = Config.options.hyprland.general.workspaceRules.slice()
                                    arr.splice(index, 1)
                                    Config.options.hyprland.general.workspaceRules = arr
                                    workspaceRulesSection.saveWorkspaceRules()
                                }}
                            }
                        }
                    }
                }
                // Add new rule row
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 6
                    Rectangle {
                        Layout.preferredWidth: 60; Layout.preferredHeight: 32
                        radius: Appearance.rounding.small; color: Appearance.colors.colLayer2
                        TextInput { id: newWrWorkspace; anchors.fill: parent; anchors.margins: 6; verticalAlignment: TextInput.AlignVCenter; selectByMouse: true; color: Appearance.colors.colOnLayer1; font.pixelSize: Appearance.font.pixelSize.small }
                        StyledText { visible: newWrWorkspace.text.length===0; anchors.verticalCenter: parent.verticalCenter; anchors.left: parent.left; anchors.leftMargin: 6; text: "ws"; color: Appearance.colors.colSubtext; font.pixelSize: Appearance.font.pixelSize.small }
                    }
                    Rectangle {
                        Layout.preferredWidth: 70; Layout.preferredHeight: 32
                        radius: Appearance.rounding.small; color: Appearance.colors.colLayer2
                        TextInput { id: newWrMonitor; anchors.fill: parent; anchors.margins: 6; verticalAlignment: TextInput.AlignVCenter; selectByMouse: true; color: Appearance.colors.colOnLayer1; font.pixelSize: Appearance.font.pixelSize.small }
                        StyledText { visible: newWrMonitor.text.length===0; anchors.verticalCenter: parent.verticalCenter; anchors.left: parent.left; anchors.leftMargin: 6; text: "monitor"; color: Appearance.colors.colSubtext; font.pixelSize: Appearance.font.pixelSize.small }
                    }
                    RippleButtonWithIcon {
                        materialIcon: "add"; mainText: Translation.tr("Add")
                        onClicked: {
                            let ws = newWrWorkspace.text.trim()
                            if (!ws) return
                            let arr = Config.options.hyprland.general.workspaceRules.slice()
                            arr.push({ workspace: ws, monitor: newWrMonitor.text.trim() || "", float: false })
                            Config.options.hyprland.general.workspaceRules = arr
                            newWrWorkspace.text = ""
                            newWrMonitor.text = ""
                            workspaceRulesSection.saveWorkspaceRules()
                        }
                        colBackground: Appearance.colors.colPrimaryContainer
                    }
                }
                StyledText { Layout.fillWidth: true; wrapMode: Text.Wrap; font.pixelSize: Appearance.font.pixelSize.smaller; color: Appearance.colors.colSubtext; text: Translation.tr("Workspace: number/name/* for all. Monitor: output name or empty. Example: '1' on 'DP-1' binds workspace 1 to DP-1.") }
            }
            // Save & reload
            Process { id: saveWrProc; onExited: (code) => { wrStatus.text = code===0 ? Translation.tr("Saved") : Translation.tr("Failed"); clearWrStatus.restart() } }
            Timer { id: clearWrStatus; interval: 2000; onTriggered: wrStatus.text = "" }
            Process { id: reloadWrProc; command: ["hyprctl", "reload"] }
            RowLayout {
                Layout.fillWidth: true
                RippleButtonWithIcon {
                    materialIcon: "save"
                    mainText: Translation.tr("Save")
                    onClicked: workspaceRulesSection.saveWorkspaceRules()
                    colBackground: Appearance.colors.colPrimaryContainer
                }
                Item { Layout.fillWidth: true }
                StyledText { id: wrStatus; font.pixelSize: Appearance.font.pixelSize.small; color: Appearance.colors.colSubtext }
            }
            function saveWorkspaceRules() {
                const rules = Config.options.hyprland.general.workspaceRules
                let lines = []
                for (let i = 0; i < rules.length; i++) {
                    const r = rules[i]
                    let parts = [`workspace = ${r.workspace}`]
                    if (r.monitor) parts.push(`monitor = ${r.monitor}`)
                    if (r.float) parts.push(`float = 1`)
                    if (r.gapsIn !== undefined) parts.push(`gaps_in = ${r.gapsIn}`)
                    if (r.gapsOut !== undefined) parts.push(`gaps_out = ${r.gapsOut}`)
                    if (r.border !== undefined) parts.push(`border = ${r.border}`)
                    if (r.rounding !== undefined) parts.push(`rounding = ${r.rounding}`)
                    if (r.decorate !== undefined) parts.push(`decorate = ${r.decorate}`)
                    if (r.defaultName) parts.push(`defaultName = ${r.defaultName}`)
                    lines.push(parts.join(", "))
                }
                // Merge into customRulesLua as workspace_rule lines
                const wrLines = lines.map(l => `hl.workspace_rule({ ${l} })`).join("\n")
                // Also keep existing custom rules text
                let existing = Config.options.hyprland.customRulesLua || ""
                // Remove old workspace rule lines
                existing = existing.replace(/-- Begin Workspace Rules[\s\S]*?-- End Workspace Rules\n?/g, "")
                if (wrLines) {
                    existing = "-- Begin Workspace Rules\n" + wrLines + "\n-- End Workspace Rules\n" + existing
                }
                Config.options.hyprland.customRulesLua = existing
                rulesArea.text = existing
                customRulesSection.saveRules()
            }
        }

        // Window Rules (Structured)
        ContentSection {
            id: windowRulesSection
            icon: "select_window"
            shape: MaterialShape.Shape.Slanted
            title: Translation.tr("Window Rules (Structured)")
            GroupedList {
                StyledText {
                    Layout.fillWidth: true
                    wrapMode: Text.Wrap
                    font.pixelSize: Appearance.font.pixelSize.small
                    color: Appearance.colors.colSubtext
                    text: Translation.tr("Apply rules to windows by class/title. Each rule generates a hl.window_rule() line.")
                }
            }
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4
                Repeater {
                    model: Config.options.hyprland.general.windowRules
                    delegate: Rectangle {
                        required property var modelData
                        required property int index
                        Layout.fillWidth: true
                        implicitHeight: wrRow2.implicitHeight + 12
                        radius: Appearance.rounding.small
                        color: Appearance.colors.colLayer1
                        RowLayout {
                            id: wrRow2
                            anchors.fill: parent
                            anchors.margins: 6
                            spacing: 6
                            StyledText {
                                text: modelData.class || modelData.title || "*"
                                color: Appearance.colors.colOnLayer1
                                Layout.preferredWidth: 100
                                elide: Text.ElideRight
                                font.pixelSize: Appearance.font.pixelSize.small
                            }
                            StyledText {
                                text: {
                                    let props = []
                                    if (modelData.float) props.push("float")
                                    if (modelData.pinned) props.push("pinned")
                                    if (modelData.nofocus) props.push("nofocus")
                                    if (modelData.noshadow) props.push("noshadow")
                                    if (modelData.noblur) props.push("noblur")
                                    if (modelData.monitor) props.push("monitor:" + modelData.monitor)
                                    if (modelData.size) props.push("size:" + modelData.size)
                                    if (modelData.workspace) props.push("ws:" + modelData.workspace)
                                    if (modelData.hyprglassTag) props.push("glass:" + modelData.hyprglassTag)
                                    return props.join("  ")
                                }
                                Layout.fillWidth: true
                                color: Appearance.colors.colSubtext
                                font.pixelSize: Appearance.font.pixelSize.smaller
                                elide: Text.ElideRight
                            }
                            Rectangle {
                                implicitWidth: 28; implicitHeight: 28; radius: 14
                                color: delWr2Hover.containsMouse ? Appearance.colors.colPrimaryContainer : Appearance.colors.colLayer2
                                MaterialSymbol { anchors.centerIn: parent; text: "delete"; iconSize: 16; color: Appearance.colors.colOnLayer1 }
                                MouseArea { id: delWr2Hover; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: {
                                    let arr = Config.options.hyprland.general.windowRules.slice()
                                    arr.splice(index, 1)
                                    Config.options.hyprland.general.windowRules = arr
                                    windowRulesSection.saveWindowRules()
                                }}
                            }
                        }
                    }
                }
                // Add new window rule row
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 6
                    Rectangle {
                        Layout.preferredWidth: 80; Layout.preferredHeight: 32
                        radius: Appearance.rounding.small; color: Appearance.colors.colLayer2
                        TextInput { id: newWrClass; anchors.fill: parent; anchors.margins: 6; verticalAlignment: TextInput.AlignVCenter; selectByMouse: true; color: Appearance.colors.colOnLayer1; font.pixelSize: Appearance.font.pixelSize.small }
                        StyledText { visible: newWrClass.text.length===0; anchors.verticalCenter: parent.verticalCenter; anchors.left: parent.left; anchors.leftMargin: 6; text: "class"; color: Appearance.colors.colSubtext; font.pixelSize: Appearance.font.pixelSize.small }
                    }
                    StyledText { text: Translation.tr("→"); color: Appearance.colors.colSubtext }
                    StyledComboBox {
                        id: newWrAction
                        Layout.preferredWidth: 90
                        model: [
                            { displayName: "Float", value: "float" },
                            { displayName: "Pin", value: "pinned" },
                            { displayName: "No Focus", value: "nofocus" },
                            { displayName: "No Shadow", value: "noshadow" },
                            { displayName: "No Blur", value: "noblur" },
                            { displayName: "None", value: "" }
                        ]
                        textRole: "displayName"
                    }
                    RippleButtonWithIcon {
                        materialIcon: "add"; mainText: Translation.tr("Add")
                        onClicked: {
                            let cls = newWrClass.text.trim()
                            if (!cls) return
                            const action = newWrAction.model[newWrAction.currentIndex].value
                            let arr = Config.options.hyprland.general.windowRules.slice()
                            let rule = { class: cls }
                            if (action) rule[action] = true
                            const glassTag = newWrGlassTag.model[newWrGlassTag.currentIndex].value
                            if (glassTag === "preset") {
                                const presetName = newWrGlassPreset.text.trim()
                                if (presetName) rule.hyprglassTag = "hyprglass_preset_" + presetName
                            } else if (glassTag) {
                                rule.hyprglassTag = glassTag
                            }
                            arr.push(rule)
                            Config.options.hyprland.general.windowRules = arr
                            newWrClass.text = ""
                            newWrGlassPreset.text = ""
                            windowRulesSection.saveWindowRules()
                        }
                        colBackground: Appearance.colors.colPrimaryContainer
                    }
                }
                // Hyprglass per-window tag row
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 6
                    MaterialSymbol { text: "water_drop"; iconSize: 18; color: Appearance.colors.colSubtext }
                    StyledComboBox {
                        id: newWrGlassTag
                        Layout.preferredWidth: 150
                        model: [
                            { displayName: Translation.tr("No glass tag"), value: "" },
                            { displayName: Translation.tr("Disable glass"), value: "hyprglass_disabled" },
                            { displayName: Translation.tr("Force enable glass"), value: "hyprglass_enabled" },
                            { displayName: Translation.tr("Force dark theme"), value: "hyprglass_theme_dark" },
                            { displayName: Translation.tr("Force light theme"), value: "hyprglass_theme_light" },
                            { displayName: Translation.tr("Custom preset..."), value: "preset" }
                        ]
                        textRole: "displayName"
                    }
                    Rectangle {
                        visible: newWrGlassTag.model[newWrGlassTag.currentIndex].value === "preset"
                        Layout.preferredWidth: 110; Layout.preferredHeight: 32
                        radius: Appearance.rounding.small; color: Appearance.colors.colLayer2
                        TextInput { id: newWrGlassPreset; anchors.fill: parent; anchors.margins: 6; verticalAlignment: TextInput.AlignVCenter; selectByMouse: true; color: Appearance.colors.colOnLayer1; font.pixelSize: Appearance.font.pixelSize.small }
                        StyledText { visible: newWrGlassPreset.text.length===0; anchors.verticalCenter: parent.verticalCenter; anchors.left: parent.left; anchors.leftMargin: 6; text: "preset name"; color: Appearance.colors.colSubtext; font.pixelSize: Appearance.font.pixelSize.small }
                    }
                    Item { Layout.fillWidth: true }
                }
                StyledText { Layout.fillWidth: true; wrapMode: Text.Wrap; font.pixelSize: Appearance.font.pixelSize.smaller; color: Appearance.colors.colSubtext; text: Translation.tr("Match by class name. Actions: Float, Pin, No Focus, No Shadow, No Blur. The glass tag row applies a hyprglass window tag (see Settings > Hyprglass) without hand-writing hyprctl dispatch tagwindow. For advanced rules, use the Custom Rules textarea below.") }
            }
            Process { id: saveWr2Proc; onExited: (code) => { wr2Status.text = code===0 ? Translation.tr("Saved") : Translation.tr("Failed"); clearWr2Status.restart() } }
            Timer { id: clearWr2Status; interval: 2000; onTriggered: wr2Status.text = "" }
            RowLayout {
                Layout.fillWidth: true
                RippleButtonWithIcon {
                    materialIcon: "save"
                    mainText: Translation.tr("Save")
                    onClicked: windowRulesSection.saveWindowRules()
                    colBackground: Appearance.colors.colPrimaryContainer
                }
                Item { Layout.fillWidth: true }
                StyledText { id: wr2Status; font.pixelSize: Appearance.font.pixelSize.small; color: Appearance.colors.colSubtext }
            }
            function saveWindowRules() {
                const rules = Config.options.hyprland.general.windowRules
                let lines = []
                for (let i = 0; i < rules.length; i++) {
                    const r = rules[i]
                    let matchParts = []
                    if (r.class) matchParts.push(`class = "${r.class}"`)
                    if (r.title) matchParts.push(`title = "${r.title}"`)
                    let actionParts = []
                    if (r.float) actionParts.push(`float = true`)
                    if (r.pinned) actionParts.push(`pinned = true`)
                    if (r.nofocus) actionParts.push(`focus = false`)
                    if (r.noshadow) actionParts.push(`shadow = false`)
                    if (r.noblur) actionParts.push(`blur = false`)
                    if (r.monitor) actionParts.push(`monitor = "${r.monitor}"`)
                    if (r.workspace) actionParts.push(`workspace = "${r.workspace}"`)
                    if (r.size) actionParts.push(`size = "${r.size}"`)
                    if (r.hyprglassTag) actionParts.push(`tag = "+${r.hyprglassTag}"`)
                    lines.push(`{match={${matchParts.join(", ")}}, ${actionParts.join(", ")}}`)
                }
                const wrLines = lines.map(l => `hl.window_rule(${l})`).join("\n")
                let existing = Config.options.hyprland.customRulesLua || ""
                existing = existing.replace(/-- Begin Window Rules[\s\S]*?-- End Window Rules\n?/g, "")
                if (wrLines) {
                    existing = "-- Begin Window Rules\n" + wrLines + "\n-- End Window Rules\n" + existing
                }
                Config.options.hyprland.customRulesLua = existing
                rulesArea.text = existing
                customRulesSection.saveRules()
            }
        }

        // Autostart Apps
        ContentSection {
            icon: "app_registration"
            shape: MaterialShape.Shape.Sunny
            title: Translation.tr("Autostart Apps")
            Layout.fillWidth: true

            AutostartApps {}
        }

        // Animations — comprehensive editor (lua, bezier/spring, full tree)
        ContentSection {
            icon: "animation"
            shape: MaterialShape.Shape.Oval
            title: Translation.tr("Animations")
            GroupedList {
                ConfigSwitch {
                    buttonIcon: "check"
                    text: Translation.tr("Enable")
                    checked: Config.options.hyprland.animations.enable
                    onCheckedChanged: {
                        if (checked === Config.options.hyprland.animations.enable) return
                        Config.options.hyprland.animations.enable = checked
                        HyprlandConfig.set("animations:enabled", checked ? 1 : 0)
                    }
                }
                ConfigSwitch {
                    buttonIcon: "tune"
                    text: Translation.tr("Workspace Wraparound")
                    checked: Config.options.hyprland.animations.workspaceWraparound
                    onCheckedChanged: {
                        if (checked === Config.options.hyprland.animations.workspaceWraparound) return
                        Config.options.hyprland.animations.workspaceWraparound = checked
                        HyprlandConfig.set("animations:workspace_wraparound", checked ? 1 : 0)
                    }
                }
                ConfigSwitch {
                    buttonIcon: "edit"
                    text: Translation.tr("Custom Editor (advanced)")
                    checked: Config.options.hyprland.animations.customEnabled
                    onCheckedChanged: {
                        Config.options.hyprland.animations.customEnabled = checked
                        if (!checked) {
                            // revert to preset handling
                        } else {
                            // push current custom to file
                            page.applyCustomAnims()
                        }
                    }
                }
                // Preset mode (when customEnabled false)
                ConfigSelectionArray {
                    visible: !Config.options.hyprland.animations.customEnabled
                    text: Translation.tr("Presets")
                    icon: "present_to_all"
                    currentValue: Config.options.hyprland.animations.animation
                    onSelected: newValue => {
                        Config.options.hyprland.animations.animation = newValue
                        saveAnimProc.command = [
                            "python3",
                            HyprlandConfig.configuratorScriptPath,
                            "--anim-preset", newValue
                        ]
                        saveAnimProc.running = true
                    }
                    options: [
                        { displayName: Translation.tr("Smooth"),         icon: "animation",             value: "smooth"         },
                        { displayName: Translation.tr("Snappy"),         icon: "bolt",                  value: "snappy"         },
                        { displayName: Translation.tr("Expressive"),     icon: "move_selection_right",  value: "expressive"     },
                        { displayName: Translation.tr("Reduced Motion"), icon: "accessibility_new",     value: "reduced_motion" },
                        { displayName: Translation.tr("Niri Like"),      icon: "mobiledata_arrows",     value: "niri"           },
                    ]
                }
                StyledText {
                    visible: !Config.options.hyprland.animations.customEnabled
                    Layout.fillWidth: true
                    Layout.leftMargin: 8
                    Layout.rightMargin: 8
                    wrapMode: Text.Wrap
                    font.pixelSize: Appearance.font.pixelSize.smaller
                    color: Appearance.colors.colSubtext
                    text: {
                        switch (Config.options.hyprland.animations.animation) {
                        case "smooth": return Translation.tr("Material Design standard easing — balanced, everyday motion. Recommended default.")
                        case "snappy": return Translation.tr("Minimal-latency, no-frills motion — short durations, no overshoot, angle flourishes off.")
                        case "expressive": return Translation.tr("Material 3 expressive motion — pronounced overshoot and a bouncy spring on window open.")
                        case "reduced_motion": return Translation.tr("Accessibility preset — disables parallax/slide/zoom/rotation and uses short plain crossfades only.")
                        case "niri": return Translation.tr("Mimics the niri scrollable-tiling compositor's motion language.")
                        default: return ""
                        }
                    }
                }
            }

            // Custom editor visible only when enabled
            ColumnLayout {
                visible: Config.options.hyprland.animations.customEnabled
                Layout.fillWidth: true
                spacing: 12
                Layout.topMargin: 8

                // Helper JS
                function applyCustomAnims() {
                    const curves = Config.options.hyprland.animations.customCurves
                    const anims = Config.options.hyprland.animations.customAnims
                    HyprlandConfig.setCustomAnims(JSON.stringify(curves), JSON.stringify(anims))
                    customReloadTimer.restart()
                }
                Timer { id: customReloadTimer; interval: 500; onTriggered: customReloadProc.running = true }
                Process { id: customReloadProc; command: ["hyprctl", "reload"] }

                // Curves editor
                ContentSubsection {
                    title: Translation.tr("Curves (bezier / spring)")
                    GroupedList {
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 6
                            Repeater {
                                model: Config.options.hyprland.animations.customCurves
                                delegate: Rectangle {
                                    required property var modelData
                                    required property int index
                                    Layout.fillWidth: true
                                    implicitHeight: curveRow.implicitHeight + 12
                                    radius: Appearance.rounding.small
                                    color: Appearance.colors.colLayer1
                                    RowLayout {
                                        id: curveRow
                                        anchors.fill: parent
                                        anchors.margins: 8
                                        spacing: 8
                                        StyledText { text: modelData.name; color: Appearance.colors.colOnLayer1; Layout.preferredWidth: 120; elide: Text.ElideRight }
                                        StyledText { text: modelData.type; color: Appearance.colors.colSubtext; Layout.preferredWidth: 60 }
                                        StyledText {
                                            Layout.fillWidth: true
                                            color: Appearance.colors.colSubtext
                                            font.pixelSize: Appearance.font.pixelSize.smaller
                                            elide: Text.ElideRight
                                            text: {
                                                if (modelData.type === "spring") return "m:" + modelData.mass + " s:" + modelData.stiffness + " d:" + modelData.damping
                                                if (modelData.points) return modelData.points[0][0].toFixed(2)+","+modelData.points[0][1].toFixed(2)+" → "+modelData.points[1][0].toFixed(2)+","+modelData.points[1][1].toFixed(2)
                                                return ""
                                            }
                                        }
                                        Rectangle {
                                            implicitWidth: 28; implicitHeight: 28; radius: 14; color: delCurHover.containsMouse ? Appearance.colors.colPrimaryContainer : Appearance.colors.colLayer2
                                            MaterialSymbol { anchors.centerIn: parent; text: "delete"; iconSize: 16; color: Appearance.colors.colOnLayer1 }
                                            MouseArea { id: delCurHover; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: {
                                                let arr = Config.options.hyprland.animations.customCurves.slice()
                                                arr.splice(index,1)
                                                Config.options.hyprland.animations.customCurves = arr
                                                page.applyCustomAnims()
                                            }}
                                        }
                                    }
                                }
                            }
                            // Add curve row
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 6
                                Rectangle {
                                    Layout.fillWidth: true; Layout.preferredHeight: 36; radius: Appearance.rounding.small; color: Appearance.colors.colLayer2
                                    TextInput {
                                        id: newCurveName; anchors.fill: parent; anchors.margins: 8; verticalAlignment: TextInput.AlignVCenter; selectByMouse: true; color: Appearance.colors.colOnLayer1; font.pixelSize: Appearance.font.pixelSize.small
                                        property string placeholderText: "myCurve"
                                    }
                                    StyledText { visible: newCurveName.text.length===0; anchors.verticalCenter: parent.verticalCenter; anchors.left: parent.left; anchors.leftMargin: 8; text: "name"; color: Appearance.colors.colSubtext }
                                }
                                StyledComboBox {
                                    id: newCurveType; Layout.preferredWidth: 110; model: [{displayName:"bezier", value:"bezier"}, {displayName:"spring", value:"spring"}]; textRole: "displayName"
                                }
                                RippleButtonWithIcon {
                                    materialIcon: "add"; mainText: Translation.tr("Add")
                                    onClicked: {
                                        const n = newCurveName.text.trim()
                                        if (!n) return
                                        let arr = Config.options.hyprland.animations.customCurves.slice()
                                        if (arr.find(c=>c.name===n)) return
                                        const t = newCurveType.model[newCurveType.currentIndex].value
                                        if (t==="spring") arr.push({name:n, type:"spring", mass:1, stiffness:100, damping:15})
                                        else arr.push({name:n, type:"bezier", points:[[0.4,0],[0.2,1]]})
                                        Config.options.hyprland.animations.customCurves = arr
                                        newCurveName.text=""
                                        page.applyCustomAnims()
                                    }
                                    colBackground: Appearance.colors.colPrimaryContainer
                                }
                            }
                            StyledText { Layout.fillWidth: true; wrapMode: Text.Wrap; font.pixelSize: Appearance.font.pixelSize.smaller; color: Appearance.colors.colSubtext; text: Translation.tr("Bezier: points {x0,y0} {x1,y1} (0-1+) — Spring: mass 1, stiffness 50-500, damping 5-50. Example presets imported from hyprland.lua: easeOutQuint, easy (spring).") }
                            RowLayout {
                                RippleButtonWithIcon {
                                    materialIcon: "download"; mainText: Translation.tr("Load Preset Into Custom")
                                    onClicked: {
                                        // Seed the custom editor with the Material 3 emphasized curves
                                        // (the same ones behind the "Expressive" preset) as a starting point.
                                        let curves = [
                                            {name:"emphasizedDecel", type:"bezier", points:[[0.05,0.7],[0.1,1]]},
                                            {name:"emphasizedAccel", type:"bezier", points:[[0.3,0],[0.8,0.15]]},
                                            {name:"menu_decel", type:"bezier", points:[[0.1,1],[0,1]]},
                                            {name:"menu_accel", type:"bezier", points:[[0.52,0.03],[0.72,0.08]]},
                                            {name:"stall", type:"bezier", points:[[1,-0.1],[0.7,0.85]]}
                                        ]
                                        let anims = [
                                            {leaf:"windowsIn", enabled:true, speed:3, bezier:"emphasizedDecel", style:"popin 80%"},
                                            {leaf:"windowsOut", enabled:true, speed:2, bezier:"emphasizedDecel", style:"popin 90%"},
                                            {leaf:"windowsMove", enabled:true, speed:3, bezier:"emphasizedDecel", style:"slide"},
                                            {leaf:"fadeIn", enabled:true, speed:3, bezier:"emphasizedDecel", style:""},
                                            {leaf:"fadeOut", enabled:true, speed:2, bezier:"emphasizedDecel", style:""},
                                            {leaf:"border", enabled:true, speed:10, bezier:"emphasizedDecel", style:""},
                                            {leaf:"workspaces", enabled:true, speed:7, bezier:"menu_decel", style:"slide"}
                                        ]
                                        Config.options.hyprland.animations.customCurves = curves
                                        Config.options.hyprland.animations.customAnims = anims
                                        page.applyCustomAnims()
                                    }
                                    colBackground: Appearance.colors.colSecondaryContainer
                                }
                                RippleButtonWithIcon {
                                    materialIcon: "save"; mainText: Translation.tr("Apply Custom")
                                    onClicked: page.applyCustomAnims()
                                    colBackground: Appearance.colors.colPrimaryContainer
                                }
                            }
                        }
                    }
                }

                // Animations tree editor
                ContentSubsection {
                    title: Translation.tr("Animation Tree (inherits parent if unset)")
                    GroupedList {
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 4
                            // Header
                            RowLayout {
                                Layout.fillWidth: true
                                StyledText { text: Translation.tr("Leaf"); color: Appearance.colors.colSubtext; Layout.preferredWidth: 140; font.pixelSize: Appearance.font.pixelSize.smaller }
                                StyledText { text: Translation.tr("Enabled"); color: Appearance.colors.colSubtext; Layout.preferredWidth: 70; font.pixelSize: Appearance.font.pixelSize.smaller; horizontalAlignment: Text.AlignHCenter }
                                StyledText { text: Translation.tr("Speed (ds)"); color: Appearance.colors.colSubtext; Layout.preferredWidth: 90; font.pixelSize: Appearance.font.pixelSize.smaller; horizontalAlignment: Text.AlignHCenter }
                                StyledText { text: Translation.tr("Curve"); color: Appearance.colors.colSubtext; Layout.fillWidth: true; font.pixelSize: Appearance.font.pixelSize.smaller }
                                StyledText { text: Translation.tr("Style"); color: Appearance.colors.colSubtext; Layout.preferredWidth: 110; font.pixelSize: Appearance.font.pixelSize.smaller }
                            }
                            Repeater {
                                model: Config.options.hyprland.animations.customAnims
                                delegate: Rectangle {
                                    required property var modelData
                                    required property int index
                                    Layout.fillWidth: true
                                    implicitHeight: 44
                                    radius: Appearance.rounding.small
                                    color: Appearance.colors.colLayer1
                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.margins: 6
                                        spacing: 6
                                        StyledText { text: modelData.leaf; color: Appearance.colors.colOnLayer1; Layout.preferredWidth: 140; elide: Text.ElideRight; font.pixelSize: Appearance.font.pixelSize.small }
                                        StyledSwitch {
                                            Layout.preferredWidth: 70
                                            checked: modelData.enabled
                                            onCheckedChanged: {
                                                let arr = Config.options.hyprland.animations.customAnims.slice()
                                                arr[index].enabled = checked
                                                Config.options.hyprland.animations.customAnims = arr
                                                page.applyCustomAnims()
                                            }
                                        }
                                        Rectangle {
                                            Layout.preferredWidth: 90; Layout.preferredHeight: 30; radius: Appearance.rounding.small; color: Appearance.colors.colLayer2
                                            TextInput {
                                                anchors.fill: parent; anchors.margins: 6; verticalAlignment: TextInput.AlignVCenter; horizontalAlignment: TextInput.AlignHCenter; selectByMouse: true; color: Appearance.colors.colOnLayer1; font.pixelSize: Appearance.font.pixelSize.small
                                                text: String(modelData.speed)
                                                onAccepted: {
                                                    let v = parseFloat(text)
                                                    if (isNaN(v)) return
                                                    let arr = Config.options.hyprland.animations.customAnims.slice()
                                                    arr[index].speed = v
                                                    Config.options.hyprland.animations.customAnims = arr
                                                    page.applyCustomAnims()
                                                }
                                            }
                                        }
                                        StyledComboBox {
                                            Layout.fillWidth: true
                                            model: {
                                                let names = Config.options.hyprland.animations.customCurves.map(c=>({displayName:c.name, value:c.name}))
                                                names.unshift({displayName:"default", value:"default"})
                                                return names
                                            }
                                            textRole: "displayName"
                                            currentIndex: {
                                                const cur = modelData.bezier || modelData.spring || "default"
                                                const idx = model.findIndex(m=>m.value===cur)
                                                return idx>=0?idx:0
                                            }
                                            onActivated: idx => {
                                                let arr = Config.options.hyprland.animations.customAnims.slice()
                                                const chosen = model[idx].value
                                                // detect type
                                                const curveObj = Config.options.hyprland.animations.customCurves.find(c=>c.name===chosen)
                                                if (curveObj && curveObj.type==="spring") {
                                                    delete arr[index].bezier; arr[index].spring = chosen
                                                } else {
                                                    delete arr[index].spring; arr[index].bezier = chosen
                                                }
                                                Config.options.hyprland.animations.customAnims = arr
                                                page.applyCustomAnims()
                                            }
                                        }
                                        Rectangle {
                                            Layout.preferredWidth: 110; Layout.preferredHeight: 30; radius: Appearance.rounding.small; color: Appearance.colors.colLayer2
                                            TextInput {
                                                anchors.fill: parent; anchors.margins: 6; verticalAlignment: TextInput.AlignVCenter; selectByMouse: true; color: Appearance.colors.colOnLayer1; font.pixelSize: Appearance.font.pixelSize.small
                                                text: modelData.style || ""
                                                property string placeholderText: "slide"
                                                onAccepted: {
                                                    let arr = Config.options.hyprland.animations.customAnims.slice()
                                                    arr[index].style = text
                                                    Config.options.hyprland.animations.customAnims = arr
                                                    page.applyCustomAnims()
                                                }
                                            }
                                        }
                                        Rectangle {
                                            implicitWidth: 28; implicitHeight: 28; radius: 14; color: delAnimHover.containsMouse ? Appearance.colors.colPrimaryContainer : Appearance.colors.colLayer2
                                            MaterialSymbol { anchors.centerIn: parent; text: "delete"; iconSize: 16; color: Appearance.colors.colOnLayer1 }
                                            MouseArea { id: delAnimHover; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: {
                                                let arr = Config.options.hyprland.animations.customAnims.slice()
                                                arr.splice(index,1)
                                                Config.options.hyprland.animations.customAnims = arr
                                                page.applyCustomAnims()
                                            }}
                                        }
                                    }
                                }
                            }
                            // Add leaf row
                            RowLayout {
                                Layout.fillWidth: true; spacing: 6
                                StyledComboBox {
                                    id: newLeafCombo; Layout.fillWidth: true
                                    model: [
                                        {displayName:"global", value:"global"}, {displayName:"windows", value:"windows"}, {displayName:"windowsIn", value:"windowsIn"}, {displayName:"windowsOut", value:"windowsOut"}, {displayName:"windowsMove", value:"windowsMove"},
                                        {displayName:"layers", value:"layers"}, {displayName:"layersIn", value:"layersIn"}, {displayName:"layersOut", value:"layersOut"},
                                        {displayName:"fade", value:"fade"}, {displayName:"fadeIn", value:"fadeIn"}, {displayName:"fadeOut", value:"fadeOut"}, {displayName:"fadeSwitch", value:"fadeSwitch"}, {displayName:"fadeShadow", value:"fadeShadow"}, {displayName:"fadeDim", value:"fadeDim"}, {displayName:"fadeLayers", value:"fadeLayers"}, {displayName:"fadeLayersIn", value:"fadeLayersIn"}, {displayName:"fadeLayersOut", value:"fadeLayersOut"}, {displayName:"fadePopups", value:"fadePopups"}, {displayName:"fadePopupsIn", value:"fadePopupsIn"}, {displayName:"fadePopupsOut", value:"fadePopupsOut"}, {displayName:"fadeDpms", value:"fadeDpms"},
                                        {displayName:"border", value:"border"}, {displayName:"borderangle", value:"borderangle"}, {displayName:"shadowangle", value:"shadowangle"}, {displayName:"glowangle", value:"glowangle"}, {displayName:"workspaces", value:"workspaces"}, {displayName:"workspacesIn", value:"workspacesIn"}, {displayName:"workspacesOut", value:"workspacesOut"}, {displayName:"specialWorkspace", value:"specialWorkspace"}, {displayName:"specialWorkspaceIn", value:"specialWorkspaceIn"}, {displayName:"specialWorkspaceOut", value:"specialWorkspaceOut"}, {displayName:"zoomFactor", value:"zoomFactor"}, {displayName:"monitorAdded", value:"monitorAdded"}
                                    ]; textRole: "displayName"
                                }
                                RippleButtonWithIcon {
                                    materialIcon: "add"; mainText: Translation.tr("Add leaf")
                                    onClicked: {
                                        const leaf = newLeafCombo.model[newLeafCombo.currentIndex].value
                                        let arr = Config.options.hyprland.animations.customAnims.slice()
                                        if (arr.find(a=>a.leaf===leaf)) return
                                        arr.push({leaf:leaf, enabled:true, speed:3, bezier:"default", style:""})
                                        Config.options.hyprland.animations.customAnims = arr
                                        page.applyCustomAnims()
                                    }
                                    colBackground: Appearance.colors.colPrimaryContainer
                                }
                            }
                            StyledText { Layout.fillWidth: true; wrapMode: Text.Wrap; font.pixelSize: Appearance.font.pixelSize.smaller; color: Appearance.colors.colSubtext; text: Translation.tr("Speed: 1ds=100ms. Styles: windows/layers → slide/popin/gnomed, workspaces → slide/slidevert/fade/slidefade, borderangle → once/loop, popin needs % e.g. popin 80%. Leave empty to inherit parent.") }
                        }
                    }
                }
            }

            NoticeBox {
                Layout.fillWidth: true
                Layout.topMargin: 15
                text: Translation.tr("New installs load this file automatically. If nothing changes when you pick a preset, your hyprland.lua predates that and needs this line added manually:") + '\n\nrequire("hyprland/shellOverrides/animations")'

                Item { Layout.fillWidth: true }

                RippleButtonWithIcon {
                    id: copySourceButton
                    property bool justCopied: false
                    Layout.fillWidth: false
                    buttonRadius: Appearance.rounding.small
                    materialIcon: justCopied ? "check" : "content_copy"
                    mainText: justCopied ? Translation.tr("Copied!") : Translation.tr("Copy line")
                    onClicked: {
                        copySourceButton.justCopied = true
                        Quickshell.clipboardText = 'require("hyprland/shellOverrides/animations")'
                        revertSourceTimer.restart()
                    }
                    colBackground: ColorUtils.transparentize(Appearance.colors.colPrimaryContainer)
                    colBackgroundHover: Appearance.colors.colPrimaryContainerHover
                    colRipple: Appearance.colors.colPrimaryContainerActive
                    Timer {
                        id: revertSourceTimer
                        interval: 1500
                        onTriggered: copySourceButton.justCopied = false
                    }
                }
            }

            Process {
                id: saveAnimProc
                onRunningChanged: if (!running) reloadAnimProc.running = true
            }
            Process {
                id: reloadAnimProc
                command: ["hyprctl", "reload"]
            }
        }
    }
}
