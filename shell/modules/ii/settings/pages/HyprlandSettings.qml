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

    // decoration:blur:variant support is checked once, shared across every
    // settings page, in services/HyprlandData.qml (see its
    // blurVariantSupported / checkBlurVariantSupport() — same reasoning
    // as before: PR #15661 isn't in any tagged Hyprland release yet).
    readonly property bool blurVariantSupported: HyprlandData.blurVariantSupported

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



    MonitorConfigOption { id: monitorConfig }

    ColumnLayout {
        visible: page.settingsShow("apps|devices|effects|input-details|window-rules");
        id: mainLayout
        Layout.fillWidth: true
        Layout.fillHeight: true
        spacing: 20

        // Displays
        ContentSection {
            icon: "monitor"
            shape: MaterialShape.Shape.ClamShell
            title: Translation.tr("Displays")
            visible: page.settingsShow("devices|window-rules") && (monitorConfig.monitors.length > 0)

            MonitorCanvas {
                visible: page.settingsShow("devices");
                objectName: "HyprlandSettings.arrange-displays";
                id: monitorCanvas
                Layout.fillWidth: true
                monitorConfig: monitorConfig
            }

            ContentSubsection {
                visible: page.settingsShow("devices|window-rules");
                Layout.topMargin: 10
                title: (monitorConfig.monitors[monitorCanvas.selectedIndex]?.name ?? "")
                    + " · "
                    + (monitorConfig.monitors[monitorCanvas.selectedIndex]?.description ?? "")

                GroupedList {
                    compact: true;
                    visible: page.settingsShow("devices|window-rules")
                    ConfigSwitch {
                        visible: page.settingsShow("devices");
                        objectName: "HyprlandSettings.enabled";
                        buttonIcon: "tv_off"
                        text: Translation.tr("Enabled")
                        checked: !(monitorConfig.monitors[monitorCanvas.selectedIndex]?.disabled ?? false)
                        onEdited: {
                            if (checked === !(monitorConfig.monitors[monitorCanvas.selectedIndex]?.disabled ?? false)) return
                            monitorConfig.updateMonitor(monitorCanvas.selectedIndex, { disabled: !checked })
                            monitorConfig.applyAndSave(monitorCanvas.selectedIndex)
                        }
                    }

                    ConfigComboBox {
                        objectName: "HyprlandSettings.resolution-refresh-rate";
                        visible: page.settingsShow("devices");

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
                        visible: page.settingsShow("devices");
                        objectName: "HyprlandSettings.orientation";
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
                        visible: page.settingsShow("devices");
                        objectName: "HyprlandSettings.scale";
                        icon: "zoom_in"
                        text: Translation.tr("Scale")
                        value: Math.round((monitorConfig.monitors[monitorCanvas.selectedIndex]?.scale ?? 1.0) * 100)
                        from: 50; to: 300; stepSize: 25
                        onEdited: {
                            const newVal = value / 100.0
                            if (newVal === (monitorConfig.monitors[monitorCanvas.selectedIndex]?.scale ?? 1.0)) return
                            monitorConfig.updateMonitor(monitorCanvas.selectedIndex, { scale: newVal })
                            monitorConfig.applyAndSave(monitorCanvas.selectedIndex)
                        }
                    }

                    ConfigSpinBox {
                        visible: page.settingsShow("window-rules");
                        objectName: "HyprlandSettings.position-x";
                        icon: "swap_horiz"
                        text: Translation.tr("Position X")
                        value: monitorConfig.monitors[monitorCanvas.selectedIndex]?.x ?? 0
                        from: 0; to: 7680; stepSize: 1
                        onEdited: {
                            if (value === (monitorConfig.monitors[monitorCanvas.selectedIndex]?.x ?? 0)) return
                            monitorConfig.updateMonitor(monitorCanvas.selectedIndex, { x: value })
                            monitorConfig.applyAndSave(monitorCanvas.selectedIndex)
                        }
                    }

                    ConfigSpinBox {
                        visible: page.settingsShow("window-rules");
                        objectName: "HyprlandSettings.position-y";
                        icon: "swap_vert"
                        text: Translation.tr("Position Y")
                        value: monitorConfig.monitors[monitorCanvas.selectedIndex]?.y ?? 0
                        from: 0; to: 4320; stepSize: 1
                        onEdited: {
                            if (value === (monitorConfig.monitors[monitorCanvas.selectedIndex]?.y ?? 0)) return
                            monitorConfig.updateMonitor(monitorCanvas.selectedIndex, { y: value })
                            monitorConfig.applyAndSave(monitorCanvas.selectedIndex)
                        }
                    }

                    // Logical size display
                    StyledText {
                        property bool groupDescription: true;
                        visible: page.settingsShow("window-rules");
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
                    visible: page.settingsShow("window-rules") && (monitorConfig.monitors.length > 0)

                    GroupedList {
                        compact: true;
                        visible: page.settingsShow("window-rules")
                        // Mirror
                        ConfigComboBox {
                            objectName: "HyprlandSettings.mirror";
                            visible: page.settingsShow("window-rules");

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
                            visible: page.settingsShow("window-rules");
                            objectName: "HyprlandSettings.bit-depth";
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
                            visible: page.settingsShow("window-rules");
                            objectName: "HyprlandSettings.vrr";
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
                            objectName: "HyprlandSettings.color-management";
                            visible: page.settingsShow("window-rules");

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
                            visible: page.settingsShow("window-rules");
                            objectName: "HyprlandSettings.reserved-area";
                            icon: "space_bar"
                            text: Translation.tr("Reserved Area")
                            value: {
                                const r = monitorConfig.monitors[monitorCanvas.selectedIndex]?.reservedArea ?? 0
                                return (typeof r === "object") ? (r.top || 0) : r
                            }
                            from: 0; to: 200; stepSize: 1
                            onEdited: {
                                monitorConfig.updateMonitor(monitorCanvas.selectedIndex, { reservedArea: value })
                                monitorConfig.applyAndSave(monitorCanvas.selectedIndex)
                            }
                        }

                        // Transform (extended: 0-7)
                        ConfigSelectionArray {
                            visible: page.settingsShow("window-rules");
                            objectName: "HyprlandSettings.transform";
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
            visible: page.settingsShow("devices|window-rules");
            icon: "auto_awesome_mosaic"
            shape: MaterialShape.Shape.Gem
            title: Translation.tr("Layout")

            GroupedList {
                compact: true;
                visible: page.settingsShow("devices")
                ConfigSelectionArray {
                    visible: page.settingsShow("devices");
                    objectName: "HyprlandSettings.tiling-layout";
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
                visible: page.settingsShow("window-rules") && (Config.options.hyprland.general.layout === "dwindle")
                title: Translation.tr("Dwindle")
                GroupedList {
                    compact: true;
                    visible: page.settingsShow("window-rules")
                    ConfigSwitch {
                        visible: page.settingsShow("window-rules");
                        objectName: "HyprlandSettings.preserve-split";
                        buttonIcon: "splitscreen"
                        text: Translation.tr("Preserve Split")
                        checked: Config.options.hyprland.dwindle.preserveSplit
                        onEdited: { if (checked === Config.options.hyprland.dwindle.preserveSplit) return; Config.options.hyprland.dwindle.preserveSplit = checked; HyprlandConfig.set("dwindle:preserve_split", checked?1:0) }
                    }
                    ConfigSwitch {
                        visible: page.settingsShow("window-rules");
                        objectName: "HyprlandSettings.smart-split";
                        buttonIcon: "auto_awesome"
                        text: Translation.tr("Smart Split")
                        checked: Config.options.hyprland.dwindle.smartSplit
                        onEdited: { if (checked === Config.options.hyprland.dwindle.smartSplit) return; Config.options.hyprland.dwindle.smartSplit = checked; HyprlandConfig.set("dwindle:smart_split", checked?1:0) }
                    }
                    ConfigSwitch {
                        visible: page.settingsShow("window-rules");
                        objectName: "HyprlandSettings.smart-resizing";
                        buttonIcon: "open_with"
                        text: Translation.tr("Smart Resizing")
                        checked: Config.options.hyprland.dwindle.smartResizing
                        onEdited: { if (checked === Config.options.hyprland.dwindle.smartResizing) return; Config.options.hyprland.dwindle.smartResizing = checked; HyprlandConfig.set("dwindle:smart_resizing", checked?1:0) }
                    }
                }
            }
            // Master options
            ContentSubsection {
                visible: page.settingsShow("window-rules") && (Config.options.hyprland.general.layout === "master")
                title: Translation.tr("Master")
                GroupedList {
                    compact: true;
                    visible: page.settingsShow("window-rules")
                    ConfigSelectionArray {
                        visible: page.settingsShow("window-rules");
                        objectName: "HyprlandSettings.new-window-status";
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
                        visible: page.settingsShow("window-rules");
                        objectName: "HyprlandSettings.master-factor";
                        text: Translation.tr("Master Factor")
                        buttonIcon: "splitscreen"
                        value: Config.options.hyprland.master.mfact
                        from: 0.1; to: 0.9
                        onEdited: { Config.options.hyprland.master.mfact = value; HyprlandConfig.set("master:mfact", value) }
                    }
                    ConfigSelectionArray {
                        visible: page.settingsShow("window-rules");
                        objectName: "HyprlandSettings.orientation-2";
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
                visible: page.settingsShow("window-rules");
                title: Translation.tr("Group")
                GroupedList {
                    compact: true;
                    visible: page.settingsShow("window-rules")
                    ConfigSwitch {
                        visible: page.settingsShow("window-rules");
                        objectName: "HyprlandSettings.auto-group";
                        buttonIcon: "group"
                        text: Translation.tr("Auto Group")
                        checked: Config.options.hyprland.group.autoGroup
                        onEdited: { if (checked === Config.options.hyprland.group.autoGroup) return; Config.options.hyprland.group.autoGroup = checked; HyprlandConfig.set("group:auto_group", checked?1:0) }
                    }
                    ConfigSwitch {
                        visible: page.settingsShow("window-rules");
                        objectName: "HyprlandSettings.drag-into-group";
                        buttonIcon: "group_add"
                        text: Translation.tr("Drag Into Group")
                        checked: Config.options.hyprland.group.dragIntoGroup
                        onEdited: { if (checked === Config.options.hyprland.group.dragIntoGroup) return; Config.options.hyprland.group.dragIntoGroup = checked; HyprlandConfig.set("group:drag_into_group", checked?1:0) }
                    }
                    ConfigSwitch {
                        visible: page.settingsShow("window-rules");
                        objectName: "HyprlandSettings.merge-groups-on-drag";
                        buttonIcon: "merge"
                        text: Translation.tr("Merge Groups On Drag")
                        checked: Config.options.hyprland.group.mergeGroupsOnDrag
                        onEdited: { if (checked === Config.options.hyprland.group.mergeGroupsOnDrag) return; Config.options.hyprland.group.mergeGroupsOnDrag = checked; HyprlandConfig.set("group:merge_groups_on_drag", checked?1:0) }
                    }
                    ConfigSwitch {
                        visible: page.settingsShow("window-rules");
                        objectName: "HyprlandSettings.group-bar-enabled";
                        buttonIcon: "view_agenda"
                        text: Translation.tr("Group Bar Enabled")
                        checked: Config.options.hyprland.group.groupbar.enabled
                        onEdited: { if (checked === Config.options.hyprland.group.groupbar.enabled) return; Config.options.hyprland.group.groupbar.enabled = checked; HyprlandConfig.set("group:groupbar:enabled", checked?1:0) }
                    }
                }
            }
        }

        // Input
        ContentSection {
            visible: page.settingsShow("devices|input-details");
            icon: "trackpad_input"
            shape: MaterialShape.Shape.Pentagon
            title: Translation.tr("Input")

            ContentSubsection {
                visible: page.settingsShow("devices|input-details");
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
                    compact: true;
                    visible: page.settingsShow("devices|input-details")
                    // Current layouts chips
                    ColumnLayout {
                        visible: page.settingsShow("devices");
                        Layout.fillWidth: true
                        spacing: 8
                        StyledText {
                            visible: page.settingsShow("devices");
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
                            visible: page.settingsShow("devices");
                            Layout.fillWidth: true
                            spacing: 8
                            // Let the row shrink rather than pushing the Add button off-screen
                            // (narrow window / large font / long displayName). Combo takes the flex space.
                            StyledComboBox {
                                id: addLayoutCombo
                                Layout.fillWidth: true
                                Layout.minimumWidth: 120
                                Layout.preferredWidth: 200
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
                                Layout.minimumWidth: 70
                                Layout.preferredWidth: 110
                                Layout.maximumWidth: 140
                                Layout.preferredHeight: 36
                                Layout.alignment: Qt.AlignVCenter
                                radius: Appearance.rounding.small
                                color: Appearance.colors.colLayer1
                                border.width: customLayoutField.activeFocus ? 1 : 0
                                border.color: Appearance.colors.colPrimary
                                clip: true
                                TextInput {
                                    id: customLayoutField
                                    anchors.fill: parent
                                    anchors.margins: 8
                                    verticalAlignment: TextInput.AlignVCenter
                                    selectByMouse: true
                                    color: Appearance.colors.colOnLayer1
                                    font.pixelSize: Appearance.font.pixelSize.small
                                    property string placeholderText: "ara"
                                    clip: true
                                    onAccepted: addBtn.clicked()
                                }
                                StyledText {
                                    visible: customLayoutField.text.length === 0
                                    anchors.verticalCenter: parent.verticalCenter
                                    anchors.left: parent.left
                                    anchors.leftMargin: 8
                                    anchors.right: parent.right
                                    anchors.rightMargin: 8
                                    elide: Text.ElideRight
                                    text: "ara"
                                    color: Appearance.colors.colSubtext
                                    font.pixelSize: Appearance.font.pixelSize.small
                                }
                            }
                            RippleButtonWithIcon {
                                visible: page.settingsShow("devices");
                                objectName: "HyprlandSettings.add";
                                id: addBtn
                                Layout.alignment: Qt.AlignVCenter
                                Layout.preferredWidth: implicitWidth
                                Layout.minimumWidth: implicitWidth
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
                            visible: page.settingsShow("devices");
                            Layout.fillWidth: true
                            wrapMode: Text.Wrap
                            font.pixelSize: Appearance.font.pixelSize.smaller
                            color: Appearance.colors.colSubtext
                            text: Translation.tr("Hyprland uses comma-separated layouts. Example: us,ara. Indicator in bar shows active layout. Click bar indicator to switch.")
                        }
                    }

                    // Extra xkb options / switch shortcut
                    ConfigComboBox {
                        objectName: "HyprlandSettings.layout-switch-shortcut";
                        visible: page.settingsShow("devices");

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
                        visible: page.settingsShow("input-details");
                        objectName: "HyprlandSettings.extra-xkb-options";
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
                        onEdited: kbOptionsDebounce.restart()
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
                        visible: page.settingsShow("input-details");
                        objectName: "HyprlandSettings.variant-per-layout-comma-separated";
                        id: kbVariantField
                        Layout.fillWidth: true
                        buttonIcon: "polyline"
                        text: Translation.tr("Variant (per layout, comma-separated)")
                        placeholderText: Translation.tr("e.g., ,, or dvorak")
                        Component.onCompleted: value = Config.options.hyprland.input.kbVariant ?? ""
                        onEdited: kbVariantDebounce.restart()
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
                        visible: page.settingsShow("input-details");
                        Layout.fillWidth: true
                        spacing: 10
                        ConfigTextArea {
                            visible: page.settingsShow("input-details");
                            objectName: "HyprlandSettings.model";
                            id: kbModelField
                            Layout.fillWidth: true
                            buttonIcon: "keyboard_alt"
                            text: Translation.tr("Model")
                            placeholderText: "pc104"
                            Component.onCompleted: value = Config.options.hyprland.input.kbModel ?? ""
                            onEdited: kbModelDebounce.restart()
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
                            visible: page.settingsShow("input-details");
                            objectName: "HyprlandSettings.rules";
                            id: kbRulesField
                            Layout.fillWidth: true
                            buttonIcon: "rule"
                            text: Translation.tr("Rules")
                            placeholderText: "evdev"
                            Component.onCompleted: value = Config.options.hyprland.input.kbRules ?? ""
                            onEdited: kbRulesDebounce.restart()
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
                        visible: page.settingsShow("devices");
                        objectName: "HyprlandSettings.numlock-by-default";
                        buttonIcon: "numbers"
                        text: Translation.tr("Numlock by default")
                        checked: Config.options.hyprland.input.numlock
                        onEdited: {
                            if (checked === Config.options.hyprland.input.numlock) return
                            Config.options.hyprland.input.numlock = checked
                            HyprlandConfig.set("input:numlock_by_default", checked ? 1 : 0)
                        }
                    }

                    ConfigSpinBox {
                        visible: page.settingsShow("input-details");
                        objectName: "HyprlandSettings.repeat-delay-ms";
                        icon: "keyboard_return"
                        text: Translation.tr("Repeat delay (ms)")
                        value: Config.options.hyprland.input.repeatDelay
                        from: 100; to: 1000; stepSize: 10
                        onEdited: {
                            if (value === Config.options.hyprland.input.repeatDelay) return
                            Config.options.hyprland.input.repeatDelay = value
                            HyprlandConfig.set("input:repeat_delay", value)
                        }
                    }

                    ConfigSpinBox {
                        visible: page.settingsShow("input-details");
                        objectName: "HyprlandSettings.repeat-rate";
                        icon: "speed"
                        text: Translation.tr("Repeat rate")
                        value: Config.options.hyprland.input.repeatRate
                        from: 10; to: 100; stepSize: 1
                        onEdited: {
                            if (value === Config.options.hyprland.input.repeatRate) return
                            Config.options.hyprland.input.repeatRate = value
                            HyprlandConfig.set("input:repeat_rate", value)
                        }
                    }
                    ConfigSelectionArray {
                        visible: page.settingsShow("input-details");
                        objectName: "HyprlandSettings.follow-mouse";
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
                visible: page.settingsShow("devices|input-details");
                title: Translation.tr("Touchpad")
                GroupedList {
                    compact: true;
                    visible: page.settingsShow("devices|input-details")
                    ConfigSwitch {
                        visible: page.settingsShow("devices");
                        objectName: "HyprlandSettings.natural-scroll";
                        buttonIcon: "swap_vert"
                        text: Translation.tr("Natural scroll")
                        checked: Config.options.hyprland.input.touchpad.naturalScroll
                        onEdited: {
                            if (checked === Config.options.hyprland.input.touchpad.naturalScroll) return
                            Config.options.hyprland.input.touchpad.naturalScroll = checked
                            HyprlandConfig.set("input:touchpad:natural_scroll", checked ? 1 : 0)
                        }
                    }

                    ConfigSwitch {
                        visible: page.settingsShow("devices");
                        objectName: "HyprlandSettings.disable-while-typing";
                        buttonIcon: "keyboard_hide"
                        text: Translation.tr("Disable while typing")
                        checked: Config.options.hyprland.input.touchpad.disableWhileTyping
                        onEdited: {
                            if (checked === Config.options.hyprland.input.touchpad.disableWhileTyping) return
                            Config.options.hyprland.input.touchpad.disableWhileTyping = checked
                            HyprlandConfig.set("input:touchpad:disable_while_typing", checked ? 1 : 0)
                        }
                    }

                    ConfigSwitch {
                        visible: page.settingsShow("input-details");
                        objectName: "HyprlandSettings.clickfinger-behavior";
                        buttonIcon: "touch_app"
                        text: Translation.tr("Clickfinger behavior")
                        checked: Config.options.hyprland.input.touchpad.clickfingerBehavior
                        onEdited: {
                            if (checked === Config.options.hyprland.input.touchpad.clickfingerBehavior) return
                            Config.options.hyprland.input.touchpad.clickfingerBehavior = checked
                            HyprlandConfig.set("input:touchpad:clickfinger_behavior", checked ? 1 : 0)
                        }
                    }

                    ConfigSpinBox {
                        visible: page.settingsShow("input-details");
                        objectName: "HyprlandSettings.scroll-factor";
                        icon: "swipe"
                        text: Translation.tr("Scroll factor")
                        value: Math.round(Config.options.hyprland.input.touchpad.scrollFactor * 10)
                        from: 1; to: 30; stepSize: 1
                        onEdited: {
                            const newVal = value / 10.0
                            if (newVal === Config.options.hyprland.input.touchpad.scrollFactor) return
                            Config.options.hyprland.input.touchpad.scrollFactor = newVal
                            HyprlandConfig.set("input:touchpad:scroll_factor", newVal)
                        }
                    }
                }

                // Touchpad advanced
                ContentSubsection {
                    visible: page.settingsShow("devices|input-details");
                    title: Translation.tr("Touchpad Advanced")
                    GroupedList {
                        compact: true;
                        visible: page.settingsShow("devices|input-details")
                        ConfigSwitch {
                            visible: page.settingsShow("devices");
                            objectName: "HyprlandSettings.tap-to-click";
                            buttonIcon: "touch_app"
                            text: Translation.tr("Tap to Click")
                            checked: Config.options.hyprland.input.touchpad.tapToClick
                            onEdited: {
                                if (checked === Config.options.hyprland.input.touchpad.tapToClick) return
                                Config.options.hyprland.input.touchpad.tapToClick = checked
                                HyprlandConfig.set("input:touchpad:tap_to_click", checked ? 1 : 0)
                            }
                        }
                        ConfigSelectionArray {
                            visible: page.settingsShow("input-details");
                            objectName: "HyprlandSettings.tap-button-map";
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
                            visible: page.settingsShow("input-details");
                            objectName: "HyprlandSettings.tap-and-drag";
                            buttonIcon: "drag_indicator"
                            text: Translation.tr("Tap and Drag")
                            checked: Config.options.hyprland.input.touchpad.tapAndDrag
                            onEdited: {
                                if (checked === Config.options.hyprland.input.touchpad.tapAndDrag) return
                                Config.options.hyprland.input.touchpad.tapAndDrag = checked
                                HyprlandConfig.set("input:touchpad:tap_and_drag", checked ? 1 : 0)
                            }
                        }
                        ConfigSwitch {
                            visible: page.settingsShow("input-details");
                            objectName: "HyprlandSettings.drag-lock";
                            buttonIcon: "lock"
                            text: Translation.tr("Drag Lock")
                            checked: Config.options.hyprland.input.touchpad.dragLock
                            onEdited: {
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
                visible: page.settingsShow("devices|input-details");
                title: Translation.tr("Mouse & Input")
                GroupedList {
                    compact: true;
                    visible: page.settingsShow("devices|input-details")
                    // Sensitivity
                    ConfigSlider {
                        visible: page.settingsShow("devices");
                        objectName: "HyprlandSettings.sensitivity";
                        text: Translation.tr("Sensitivity")
                        buttonIcon: "speed"
                        value: Math.round(Config.options.hyprland.input.sensitivity * 100)
                        from: -100; to: 100
                        onEdited: {
                            const v = value / 100.0
                            if (v === Config.options.hyprland.input.sensitivity) return
                            Config.options.hyprland.input.sensitivity = v
                            HyprlandConfig.set("input:sensitivity", v)
                        }
                    }
                    // Accel Profile
                    ConfigComboBox {
                        objectName: "HyprlandSettings.accel-profile";
                        visible: page.settingsShow("input-details");

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
                        visible: page.settingsShow("input-details");
                        objectName: "HyprlandSettings.force-no-accel";
                        buttonIcon: "speed"
                        text: Translation.tr("Force No Accel")
                        checked: Config.options.hyprland.input.forceNoAccel
                        onEdited: {
                            if (checked === Config.options.hyprland.input.forceNoAccel) return
                            Config.options.hyprland.input.forceNoAccel = checked
                            HyprlandConfig.set("input:force_no_accel", checked ? 1 : 0)
                        }
                    }
                    // Scroll Factor
                    ConfigSpinBox {
                        visible: page.settingsShow("input-details");
                        objectName: "HyprlandSettings.scroll-factor-2";
                        icon: "swap_vert"
                        text: Translation.tr("Scroll Factor")
                        value: Math.round(Config.options.hyprland.input.scrollFactor * 10)
                        from: 1; to: 30; stepSize: 1
                        onEdited: {
                            const v = value / 10.0
                            if (v === Config.options.hyprland.input.scrollFactor) return
                            Config.options.hyprland.input.scrollFactor = v
                            HyprlandConfig.set("input:scroll_factor", v)
                        }
                    }
                    // Scroll Button
                    ConfigSpinBox {
                        visible: page.settingsShow("input-details");
                        objectName: "HyprlandSettings.scroll-button";
                        icon: "mouse"
                        text: Translation.tr("Scroll Button")
                        value: Config.options.hyprland.input.scrollButton
                        from: 0; to: 12; stepSize: 1
                        onEdited: {
                            if (value === Config.options.hyprland.input.scrollButton) return
                            Config.options.hyprland.input.scrollButton = value
                            HyprlandConfig.set("input:scroll_button", value)
                        }
                    }
                    // Left Handed
                    ConfigSwitch {
                        visible: page.settingsShow("devices");
                        objectName: "HyprlandSettings.left-handed";
                        buttonIcon: "back_hand"
                        text: Translation.tr("Left Handed")
                        checked: Config.options.hyprland.input.leftHanded
                        onEdited: {
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
            visible: page.settingsShow("effects");
            icon: "deblur"
            shape: MaterialShape.Shape.PixelCircle
            title: Translation.tr("Visual & Aesthetics")

            GroupedList {
                compact: true;
                visible: page.settingsShow("effects")
                ConfigSpinBox {
                    visible: page.settingsShow("effects");
                    objectName: "HyprlandSettings.window-rounding";
                    icon: "rounded_corner"
                    text: Translation.tr("Window Rounding")
                    value: Config.options.hyprland.decoration.rounding
                    from: 0; to: 30; stepSize: 1
                    onEdited: {
                        if (value === Config.options.hyprland.decoration.rounding) return
                        Config.options.hyprland.decoration.rounding = value
                        HyprlandConfig.set("decoration:rounding", value)
                    }
                }
                ConfigSpinBox {
                    visible: page.settingsShow("effects");
                    objectName: "HyprlandSettings.rounding-power";
                    icon: "spline"
                    text: Translation.tr("Rounding Power")
                    value: Math.round(Config.options.hyprland.decoration.roundingPower * 10)
                    from: 10; to: 100; stepSize: 5
                    onEdited: {
                        const v = value / 10.0
                        if (v === Config.options.hyprland.decoration.roundingPower) return
                        Config.options.hyprland.decoration.roundingPower = v
                        HyprlandConfig.set("decoration:rounding_power", v)
                    }
                }
                ConfigSwitch {
                    visible: page.settingsShow("effects");
                    objectName: "HyprlandSettings.blur";
                    buttonIcon: "blur_on"
                    text: Translation.tr("Blur")
                    checked: Config.options.hyprland.decoration.blur.enabled
                    onEdited: {
                        if (checked === Config.options.hyprland.decoration.blur.enabled) return
                        // Blur, transparency and Liquid Glass are mutually exclusive
                        // (Settings > Interface > Visual Effect) — enabling blur here
                        // must turn the other two off too, and disabling it should
                        // fall back to "none" rather than leaving the Interface page's
                        // selector pointing at a style that's actually off.
                        if (checked) {
                            Config.options.appearance.visualEffect = "blur"
                            Config.applyVisualEffectExclusivity("blur")
                        } else {
                            Config.options.hyprland.decoration.blur.enabled = false
                            if (Config.options.appearance.visualEffect === "blur")
                                Config.options.appearance.visualEffect = "none"
                        }
                        // Single batched write: two overlapping set() calls
                        // each spawn hyprconfigurator.py against the same
                        // shellOverrides/main.lua and clobber each other.
                        HyprlandConfig.setMany({
                            "decoration:blur:enabled": Config.options.hyprland.decoration.blur.enabled ? 1 : 0,
                            "decoration:blur:variant": Config.options.hyprland.decoration.blur.variant,
                        })
                    }
                }
                ConfigSpinBox {
                    visible: page.settingsShow("effects");
                    objectName: "HyprlandSettings.blur-size";
                    icon: "blur_circular"
                    text: Translation.tr("Blur Size")
                    value: Config.options.hyprland.decoration.blur.size
                    from: 1; to: 20; stepSize: 1
                    onEdited: {
                        if (value === Config.options.hyprland.decoration.blur.size) return
                        Config.options.hyprland.decoration.blur.size = value
                        HyprlandConfig.set("decoration:blur:size", value)
                    }
                }
                ConfigSpinBox {
                    visible: page.settingsShow("effects");
                    objectName: "HyprlandSettings.blur-passes";
                    icon: "layers"
                    text: Translation.tr("Blur Passes")
                    value: Config.options.hyprland.decoration.blur.passes
                    from: 1; to: 6; stepSize: 1
                    onEdited: {
                        if (value === Config.options.hyprland.decoration.blur.passes) return
                        Config.options.hyprland.decoration.blur.passes = value
                        HyprlandConfig.set("decoration:blur:passes", value)
                    }
                }
                ConfigSpinBox {
                    visible: page.settingsShow("effects");
                    objectName: "HyprlandSettings.blur-vibrancy";
                    icon: "water_drop"
                    text: Translation.tr("Blur Vibrancy")
                    value: Math.round(Config.options.hyprland.decoration.blur.vibrancy * 100)
                    from: 0; to: 100; stepSize: 5
                    onEdited: {
                        const v = value/100.0
                        if (v === Config.options.hyprland.decoration.blur.vibrancy) return
                        Config.options.hyprland.decoration.blur.vibrancy = v
                        HyprlandConfig.set("decoration:blur:vibrancy", v)
                    }
                }
                ConfigSwitch {
                    visible: page.settingsShow("effects");
                    objectName: "HyprlandSettings.blur-xray";
                    buttonIcon: "visibility"
                    text: Translation.tr("Blur XRay")
                    checked: Config.options.hyprland.decoration.blur.xray
                    onEdited: {
                        if (checked === Config.options.hyprland.decoration.blur.xray) return
                        Config.options.hyprland.decoration.blur.xray = checked
                        HyprlandConfig.set("decoration:blur:xray", checked ? 1 : 0)
                    }
                }
                ConfigSwitch {
                    visible: page.settingsShow("effects");
                    objectName: "HyprlandSettings.blur-new-optimizations";
                    buttonIcon: "bolt"
                    text: Translation.tr("Blur New Optimizations")
                    checked: Config.options.hyprland.decoration.blur.newOptimizations
                    onEdited: {
                        if (checked === Config.options.hyprland.decoration.blur.newOptimizations) return
                        Config.options.hyprland.decoration.blur.newOptimizations = checked
                        HyprlandConfig.set("decoration:blur:new_optimizations", checked ? 1 : 0)
                    }
                }
                StyledText {
                    property bool groupDescription: true;
                    visible: !HyprlandData.blurVariantSupported
                    Layout.fillWidth: true
                    wrapMode: Text.Wrap
                    color: Appearance.m3colors.m3error
                    font.pixelSize: Appearance.font.pixelSize.small
                    text: Translation.tr("Your running Hyprland doesn't support blur styles yet (decoration:blur:variant needs hyprwm/Hyprland PR #15661, merged 2026-08-22 — not in any tagged release yet, only in a from-source/-git build past that commit). Picking one below will be silently ignored until Hyprland is updated to a build that includes it; plain blur still works normally.")
                }
                ConfigSelectionArray {
                    visible: page.settingsShow("effects");
                    objectName: "HyprlandSettings.blur-style";
                    icon: "blur_on"
                    text: Translation.tr("Blur Style")
                    // Picking a variant the running Hyprland doesn't have is a
                    // silent no-op: hyprconfigurator.py's option_is_supported()
                    // drops the key on write, so the UI would keep showing a
                    // style that isn't applied. Grey the control out instead of
                    // only warning above it.
                    enabled: page.blurVariantSupported
                    currentValue: Config.options.hyprland.decoration.blur.variant
                    onSelected: newValue => {
                        if (newValue === Config.options.hyprland.decoration.blur.variant) return
                        Config.options.hyprland.decoration.blur.variant = newValue
                        HyprlandConfig.set("decoration:blur:variant", newValue)
                    }
                    options: [
                        { displayName: Translation.tr("Kawase (Classic)"), icon: "blur_on", value: "kawase" },
                        { displayName: Translation.tr("Frost"), icon: "ac_unit", value: "frost" },
                        { displayName: Translation.tr("Liquid Glass (Acrylic)"), icon: "water_drop", value: "acrylic" },
                        { displayName: Translation.tr("Prism"), icon: "diamond", value: "prism" },
                        { displayName: Translation.tr("Ripple"), icon: "waves", value: "ripple" },
                        { displayName: Translation.tr("Drops"), icon: "water_drop", value: "drops" },
                        { displayName: Translation.tr("Water"), icon: "water", value: "water" },
                        { displayName: Translation.tr("Fluid Jar"), icon: "science", value: "fluid_jar" },
                        { displayName: Translation.tr("Heat Shimmer"), icon: "thermostat", value: "heat_shimmer" },
                        { displayName: Translation.tr("Aurora"), icon: "auto_awesome", value: "aurora" },
                        { displayName: Translation.tr("Haze"), icon: "blur_circular", value: "haze" }
                    ]
                }
                StyledText {
                    property bool groupDescription: true;
                    visible: page.settingsShow("effects");
                    Layout.fillWidth: true
                    wrapMode: Text.Wrap
                    color: Appearance.colors.colSubtext
                    font.pixelSize: Appearance.font.pixelSize.small
                    text: Translation.tr("Native Hyprland blur variants (decoration:blur:variant, merged upstream Aug 2026) — applies to every window Hyprland blurs, not just this shell's panels. Fancier styles cost more GPU/CPU, especially the animated ones.")
                }
                ConfigSpinBox {
                    objectName: "HyprlandSettings.glass-refraction";
                    visible: page.settingsShow("effects") && (page.blurVariantSupported && Config.options.hyprland.decoration.blur.variant === "acrylic" || Config.options.hyprland.decoration.blur.variant === "prism")
                    icon: "water"
                    text: Translation.tr("Glass Refraction")
                    value: Config.options.hyprland.decoration.blur.glass.refraction
                    from: 0; to: 20; stepSize: 1
                    onEdited: {
                        if (value === Config.options.hyprland.decoration.blur.glass.refraction) return
                        Config.options.hyprland.decoration.blur.glass.refraction = value
                        HyprlandConfig.set("decoration:blur:glass:refraction", value)
                    }
                }
                ConfigSpinBox {
                    objectName: "HyprlandSettings.glass-pattern-size";
                    visible: page.settingsShow("effects") && (page.blurVariantSupported && Config.options.hyprland.decoration.blur.variant === "acrylic" || Config.options.hyprland.decoration.blur.variant === "prism")
                    icon: "texture"
                    text: Translation.tr("Glass Pattern Size")
                    value: Config.options.hyprland.decoration.blur.glass.size
                    from: 4; to: 512; stepSize: 4
                    onEdited: {
                        if (value === Config.options.hyprland.decoration.blur.glass.size) return
                        Config.options.hyprland.decoration.blur.glass.size = value
                        HyprlandConfig.set("decoration:blur:glass:size", value)
                    }
                }
                ConfigSpinBox {
                    objectName: "HyprlandSettings.glass-roughness";
                    visible: page.settingsShow("effects") && (page.blurVariantSupported && Config.options.hyprland.decoration.blur.variant === "acrylic" || Config.options.hyprland.decoration.blur.variant === "prism")
                    icon: "grain"
                    text: Translation.tr("Glass Roughness")
                    value: Math.round(Config.options.hyprland.decoration.blur.glass.roughness * 100)
                    from: 0; to: 100; stepSize: 5
                    onEdited: {
                        const v = value / 100.0
                        if (v === Config.options.hyprland.decoration.blur.glass.roughness) return
                        Config.options.hyprland.decoration.blur.glass.roughness = v
                        HyprlandConfig.set("decoration:blur:glass:roughness", v)
                    }
                }
                ConfigSpinBox {
                    objectName: "HyprlandSettings.liquid-glass-refraction";
                    visible: page.settingsShow("effects") && (page.blurVariantSupported && Config.options.hyprland.decoration.blur.variant === "acrylic")
                    icon: "water_drop"
                    text: Translation.tr("Liquid Glass Refraction")
                    value: Config.options.hyprland.decoration.blur.acrylic.refraction
                    from: 0; to: 48; stepSize: 1
                    onEdited: {
                        if (value === Config.options.hyprland.decoration.blur.acrylic.refraction) return
                        Config.options.hyprland.decoration.blur.acrylic.refraction = value
                        HyprlandConfig.set("decoration:blur:acrylic:refraction", value)
                    }
                }
                ConfigSpinBox {
                    objectName: "HyprlandSettings.liquid-glass-edge-width";
                    visible: page.settingsShow("effects") && (page.blurVariantSupported && Config.options.hyprland.decoration.blur.variant === "acrylic")
                    icon: "border_outer"
                    text: Translation.tr("Liquid Glass Edge Width")
                    value: Config.options.hyprland.decoration.blur.acrylic.bulb
                    from: 4; to: 256; stepSize: 4
                    onEdited: {
                        if (value === Config.options.hyprland.decoration.blur.acrylic.bulb) return
                        Config.options.hyprland.decoration.blur.acrylic.bulb = value
                        HyprlandConfig.set("decoration:blur:acrylic:bulb", value)
                    }
                }
                ConfigSpinBox {
                    objectName: "HyprlandSettings.liquid-glass-clarity";
                    visible: page.settingsShow("effects") && (page.blurVariantSupported && Config.options.hyprland.decoration.blur.variant === "acrylic")
                    icon: "visibility"
                    text: Translation.tr("Liquid Glass Clarity")
                    value: Math.round(Config.options.hyprland.decoration.blur.acrylic.clarity * 100)
                    from: 0; to: 100; stepSize: 5
                    onEdited: {
                        const v = value / 100.0
                        if (v === Config.options.hyprland.decoration.blur.acrylic.clarity) return
                        Config.options.hyprland.decoration.blur.acrylic.clarity = v
                        HyprlandConfig.set("decoration:blur:acrylic:clarity", v)
                    }
                }
                ConfigSpinBox {
                    objectName: "HyprlandSettings.liquid-glass-chromatic-aberration";
                    visible: page.settingsShow("effects") && (page.blurVariantSupported && Config.options.hyprland.decoration.blur.variant === "acrylic")
                    icon: "palette"
                    text: Translation.tr("Liquid Glass Chromatic Aberration")
                    value: Math.round(Config.options.hyprland.decoration.blur.acrylic.aberration * 400)
                    from: 0; to: 100; stepSize: 5
                    onEdited: {
                        const v = value / 400.0
                        if (v === Config.options.hyprland.decoration.blur.acrylic.aberration) return
                        Config.options.hyprland.decoration.blur.acrylic.aberration = v
                        HyprlandConfig.set("decoration:blur:acrylic:aberration", v)
                    }
                }
                ConfigTextArea {
                    objectName: "HyprlandSettings.liquid-glass-tint-0xaarrggbb";
                    visible: page.settingsShow("effects") && (page.blurVariantSupported && Config.options.hyprland.decoration.blur.variant === "acrylic")
                    buttonIcon: "colorize"
                    text: Translation.tr("Liquid Glass Tint (0xAARRGGBB)")
                    value: Config.options.hyprland.decoration.blur.acrylic.tint
                    placeholderText: "0x14EEF5FF"
                    onEdited: {
                        if (value === Config.options.hyprland.decoration.blur.acrylic.tint) return
                        Config.options.hyprland.decoration.blur.acrylic.tint = value
                        HyprlandConfig.set("decoration:blur:acrylic:tint", value)
                    }
                }
                // ── Ripple ──────────────────────────────────────────────────
                ConfigSpinBox {
                    objectName: "HyprlandSettings.ripple-strength";
                    visible: page.settingsShow("effects") && (page.blurVariantSupported && Config.options.hyprland.decoration.blur.variant === "ripple")
                    icon: "waves"
                    text: Translation.tr("Ripple Strength")
                    value: Config.options.hyprland.decoration.blur.ripple.strength
                    from: 0; to: 32; stepSize: 1
                    onEdited: {
                        if (value === Config.options.hyprland.decoration.blur.ripple.strength) return
                        Config.options.hyprland.decoration.blur.ripple.strength = value
                        HyprlandConfig.set("decoration:blur:ripple:strength", value)
                    }
                }
                ConfigSpinBox {
                    objectName: "HyprlandSettings.ripple-radius";
                    visible: page.settingsShow("effects") && (page.blurVariantSupported && Config.options.hyprland.decoration.blur.variant === "ripple")
                    icon: "radio_button_unchecked"
                    text: Translation.tr("Ripple Radius")
                    value: Config.options.hyprland.decoration.blur.ripple.radius
                    from: 1; to: 1000; stepSize: 10
                    onEdited: {
                        if (value === Config.options.hyprland.decoration.blur.ripple.radius) return
                        Config.options.hyprland.decoration.blur.ripple.radius = value
                        HyprlandConfig.set("decoration:blur:ripple:radius", value)
                    }
                }
                ConfigSpinBox {
                    objectName: "HyprlandSettings.ripple-wave-width";
                    visible: page.settingsShow("effects") && (page.blurVariantSupported && Config.options.hyprland.decoration.blur.variant === "ripple")
                    icon: "line_weight"
                    text: Translation.tr("Ripple Wave Width")
                    value: Config.options.hyprland.decoration.blur.ripple.width
                    from: 1; to: 200; stepSize: 2
                    onEdited: {
                        if (value === Config.options.hyprland.decoration.blur.ripple.width) return
                        Config.options.hyprland.decoration.blur.ripple.width = value
                        HyprlandConfig.set("decoration:blur:ripple:width", value)
                    }
                }
                ConfigSpinBox {
                    objectName: "HyprlandSettings.ripple-duration";
                    visible: page.settingsShow("effects") && (page.blurVariantSupported && Config.options.hyprland.decoration.blur.variant === "ripple")
                    icon: "timer"
                    text: Translation.tr("Ripple Duration")
                    value: Math.round(Config.options.hyprland.decoration.blur.ripple.duration * 100)
                    from: 5; to: 500; stepSize: 5
                    onEdited: {
                        const v = value / 100.0
                        if (v === Config.options.hyprland.decoration.blur.ripple.duration) return
                        Config.options.hyprland.decoration.blur.ripple.duration = v
                        HyprlandConfig.set("decoration:blur:ripple:duration", v)
                    }
                }
                // ── Drops ───────────────────────────────────────────────────
                ConfigSpinBox {
                    objectName: "HyprlandSettings.drops-speed-0-still-costs-more-gpu-above-0";
                    visible: page.settingsShow("effects") && (page.blurVariantSupported && Config.options.hyprland.decoration.blur.variant === "drops")
                    icon: "water_drop"
                    text: Translation.tr("Drops Speed (0 = still, costs more GPU above 0)")
                    value: Config.options.hyprland.decoration.blur.drops.speed
                    from: 0; to: 10; stepSize: 1
                    onEdited: {
                        if (value === Config.options.hyprland.decoration.blur.drops.speed) return
                        Config.options.hyprland.decoration.blur.drops.speed = value
                        HyprlandConfig.set("decoration:blur:drops:speed", value)
                    }
                }
                // ── Water ───────────────────────────────────────────────────
                ConfigSpinBox {
                    objectName: "HyprlandSettings.water-strength";
                    visible: page.settingsShow("effects") && (page.blurVariantSupported && Config.options.hyprland.decoration.blur.variant === "water")
                    icon: "water"
                    text: Translation.tr("Water Strength")
                    value: Config.options.hyprland.decoration.blur.water.strength
                    from: 0; to: 32; stepSize: 1
                    onEdited: {
                        if (value === Config.options.hyprland.decoration.blur.water.strength) return
                        Config.options.hyprland.decoration.blur.water.strength = value
                        HyprlandConfig.set("decoration:blur:water:strength", value)
                    }
                }
                ConfigSpinBox {
                    objectName: "HyprlandSettings.water-pointer-radius";
                    visible: page.settingsShow("effects") && (page.blurVariantSupported && Config.options.hyprland.decoration.blur.variant === "water")
                    icon: "radio_button_unchecked"
                    text: Translation.tr("Water Pointer Radius")
                    value: Config.options.hyprland.decoration.blur.water.radius
                    from: 1; to: 1000; stepSize: 10
                    onEdited: {
                        if (value === Config.options.hyprland.decoration.blur.water.radius) return
                        Config.options.hyprland.decoration.blur.water.radius = value
                        HyprlandConfig.set("decoration:blur:water:radius", value)
                    }
                }
                ConfigSpinBox {
                    objectName: "HyprlandSettings.water-propagation-speed";
                    visible: page.settingsShow("effects") && (page.blurVariantSupported && Config.options.hyprland.decoration.blur.variant === "water")
                    icon: "speed"
                    text: Translation.tr("Water Propagation Speed")
                    value: Math.round(Config.options.hyprland.decoration.blur.water.speed * 100)
                    from: 0; to: 1000; stepSize: 5
                    onEdited: {
                        const v = value / 100.0
                        if (v === Config.options.hyprland.decoration.blur.water.speed) return
                        Config.options.hyprland.decoration.blur.water.speed = v
                        HyprlandConfig.set("decoration:blur:water:speed", v)
                    }
                }
                ConfigSpinBox {
                    objectName: "HyprlandSettings.water-damping";
                    visible: page.settingsShow("effects") && (page.blurVariantSupported && Config.options.hyprland.decoration.blur.variant === "water")
                    icon: "trending_down"
                    text: Translation.tr("Water Damping")
                    value: Math.round(Config.options.hyprland.decoration.blur.water.damping * 100)
                    from: 0; to: 100; stepSize: 5
                    onEdited: {
                        const v = value / 100.0
                        if (v === Config.options.hyprland.decoration.blur.water.damping) return
                        Config.options.hyprland.decoration.blur.water.damping = v
                        HyprlandConfig.set("decoration:blur:water:damping", v)
                    }
                }
                ConfigSpinBox {
                    objectName: "HyprlandSettings.water-max-duration-s";
                    visible: page.settingsShow("effects") && (page.blurVariantSupported && Config.options.hyprland.decoration.blur.variant === "water")
                    icon: "timer"
                    text: Translation.tr("Water Max Duration (s)")
                    value: Math.round(Config.options.hyprland.decoration.blur.water.duration * 10)
                    from: 5; to: 600; stepSize: 5
                    onEdited: {
                        const v = value / 10.0
                        if (v === Config.options.hyprland.decoration.blur.water.duration) return
                        Config.options.hyprland.decoration.blur.water.duration = v
                        HyprlandConfig.set("decoration:blur:water:duration", v)
                    }
                }
                // ── Fluid Jar ───────────────────────────────────────────────
                ConfigTextArea {
                    objectName: "HyprlandSettings.fluid-jar-color-0xaarrggbb";
                    visible: page.settingsShow("effects") && (page.blurVariantSupported && Config.options.hyprland.decoration.blur.variant === "fluid_jar")
                    buttonIcon: "colorize"
                    text: Translation.tr("Fluid Jar Color (0xAARRGGBB)")
                    value: Config.options.hyprland.decoration.blur.fluidJar.color
                    placeholderText: "0xCC3399FF"
                    onEdited: {
                        if (value === Config.options.hyprland.decoration.blur.fluidJar.color) return
                        Config.options.hyprland.decoration.blur.fluidJar.color = value
                        HyprlandConfig.set("decoration:blur:fluid_jar:color", value)
                    }
                }
                ConfigSpinBox {
                    objectName: "HyprlandSettings.fluid-jar-speed";
                    visible: page.settingsShow("effects") && (page.blurVariantSupported && Config.options.hyprland.decoration.blur.variant === "fluid_jar")
                    icon: "speed"
                    text: Translation.tr("Fluid Jar Speed")
                    value: Math.round(Config.options.hyprland.decoration.blur.fluidJar.speed * 100)
                    from: 0; to: 1000; stepSize: 5
                    onEdited: {
                        const v = value / 100.0
                        if (v === Config.options.hyprland.decoration.blur.fluidJar.speed) return
                        Config.options.hyprland.decoration.blur.fluidJar.speed = v
                        HyprlandConfig.set("decoration:blur:fluid_jar:speed", v)
                    }
                }
                ConfigSpinBox {
                    objectName: "HyprlandSettings.fluid-jar-fill-amount";
                    visible: page.settingsShow("effects") && (page.blurVariantSupported && Config.options.hyprland.decoration.blur.variant === "fluid_jar")
                    icon: "opacity"
                    text: Translation.tr("Fluid Jar Fill Amount")
                    value: Math.round(Config.options.hyprland.decoration.blur.fluidJar.fillAmount * 100)
                    from: 0; to: 100; stepSize: 5
                    onEdited: {
                        const v = value / 100.0
                        if (v === Config.options.hyprland.decoration.blur.fluidJar.fillAmount) return
                        Config.options.hyprland.decoration.blur.fluidJar.fillAmount = v
                        HyprlandConfig.set("decoration:blur:fluid_jar:fill_amount", v)
                    }
                }
                ConfigSpinBox {
                    objectName: "HyprlandSettings.fluid-jar-mass";
                    visible: page.settingsShow("effects") && (page.blurVariantSupported && Config.options.hyprland.decoration.blur.variant === "fluid_jar")
                    icon: "fitness_center"
                    text: Translation.tr("Fluid Jar Mass")
                    value: Math.round(Config.options.hyprland.decoration.blur.fluidJar.mass * 100)
                    from: 10; to: 1000; stepSize: 10
                    onEdited: {
                        const v = value / 100.0
                        if (v === Config.options.hyprland.decoration.blur.fluidJar.mass) return
                        Config.options.hyprland.decoration.blur.fluidJar.mass = v
                        HyprlandConfig.set("decoration:blur:fluid_jar:mass", v)
                    }
                }
                ConfigSpinBox {
                    objectName: "HyprlandSettings.fluid-jar-precision-2x-recommended-4x-expensive";
                    visible: page.settingsShow("effects") && (page.blurVariantSupported && Config.options.hyprland.decoration.blur.variant === "fluid_jar")
                    icon: "grain"
                    text: Translation.tr("Fluid Jar Precision (2x recommended, 4x+ expensive)")
                    value: Math.round(Config.options.hyprland.decoration.blur.fluidJar.precision * 100)
                    from: 50; to: 800; stepSize: 10
                    onEdited: {
                        const v = value / 100.0
                        if (v === Config.options.hyprland.decoration.blur.fluidJar.precision) return
                        Config.options.hyprland.decoration.blur.fluidJar.precision = v
                        HyprlandConfig.set("decoration:blur:fluid_jar:precision", v)
                    }
                }
                ConfigSpinBox {
                    objectName: "HyprlandSettings.fluid-jar-turbulence";
                    visible: page.settingsShow("effects") && (page.blurVariantSupported && Config.options.hyprland.decoration.blur.variant === "fluid_jar")
                    icon: "air"
                    text: Translation.tr("Fluid Jar Turbulence")
                    value: Math.round(Config.options.hyprland.decoration.blur.fluidJar.turbulence * 100)
                    from: 0; to: 500; stepSize: 5
                    onEdited: {
                        const v = value / 100.0
                        if (v === Config.options.hyprland.decoration.blur.fluidJar.turbulence) return
                        Config.options.hyprland.decoration.blur.fluidJar.turbulence = v
                        HyprlandConfig.set("decoration:blur:fluid_jar:turbulence", v)
                    }
                }
                ConfigSpinBox {
                    objectName: "HyprlandSettings.fluid-jar-distortion";
                    visible: page.settingsShow("effects") && (page.blurVariantSupported && Config.options.hyprland.decoration.blur.variant === "fluid_jar")
                    icon: "water"
                    text: Translation.tr("Fluid Jar Distortion")
                    value: Config.options.hyprland.decoration.blur.fluidJar.distortion
                    from: 0; to: 10; stepSize: 1
                    onEdited: {
                        if (value === Config.options.hyprland.decoration.blur.fluidJar.distortion) return
                        Config.options.hyprland.decoration.blur.fluidJar.distortion = value
                        HyprlandConfig.set("decoration:blur:fluid_jar:distortion", value)
                    }
                }
                // ── Heat Shimmer ────────────────────────────────────────────
                ConfigSpinBox {
                    objectName: "HyprlandSettings.heat-shimmer-speed-0-still-costs-more-gpu-above-0";
                    visible: page.settingsShow("effects") && (page.blurVariantSupported && Config.options.hyprland.decoration.blur.variant === "heat_shimmer")
                    icon: "thermostat"
                    text: Translation.tr("Heat Shimmer Speed (0 = still, costs more GPU above 0)")
                    value: Config.options.hyprland.decoration.blur.heatShimmer.speed
                    from: 0; to: 10; stepSize: 1
                    onEdited: {
                        if (value === Config.options.hyprland.decoration.blur.heatShimmer.speed) return
                        Config.options.hyprland.decoration.blur.heatShimmer.speed = value
                        HyprlandConfig.set("decoration:blur:heat_shimmer:speed", value)
                    }
                }
                // ── Aurora ──────────────────────────────────────────────────
                ConfigSpinBox {
                    objectName: "HyprlandSettings.aurora-speed-0-frozen-costs-more-gpu-above-0";
                    visible: page.settingsShow("effects") && (page.blurVariantSupported && Config.options.hyprland.decoration.blur.variant === "aurora")
                    icon: "auto_awesome"
                    text: Translation.tr("Aurora Speed (0 = frozen, costs more GPU above 0)")
                    value: Config.options.hyprland.decoration.blur.aurora.speed
                    from: 0; to: 10; stepSize: 1
                    onEdited: {
                        if (value === Config.options.hyprland.decoration.blur.aurora.speed) return
                        Config.options.hyprland.decoration.blur.aurora.speed = value
                        HyprlandConfig.set("decoration:blur:aurora:speed", value)
                    }
                }
                ConfigSpinBox {
                    objectName: "HyprlandSettings.aurora-intensity";
                    visible: page.settingsShow("effects") && (page.blurVariantSupported && Config.options.hyprland.decoration.blur.variant === "aurora")
                    icon: "gradient"
                    text: Translation.tr("Aurora Intensity")
                    value: Math.round(Config.options.hyprland.decoration.blur.aurora.intensity * 100)
                    from: 0; to: 100; stepSize: 5
                    onEdited: {
                        const v = value / 100.0
                        if (v === Config.options.hyprland.decoration.blur.aurora.intensity) return
                        Config.options.hyprland.decoration.blur.aurora.intensity = v
                        HyprlandConfig.set("decoration:blur:aurora:intensity", v)
                    }
                }
                ConfigTextArea {
                    objectName: "HyprlandSettings.aurora-color-1-0xaarrggbb";
                    visible: page.settingsShow("effects") && (page.blurVariantSupported && Config.options.hyprland.decoration.blur.variant === "aurora")
                    buttonIcon: "colorize"
                    text: Translation.tr("Aurora Color 1 (0xAARRGGBB)")
                    value: Config.options.hyprland.decoration.blur.aurora.color1
                    placeholderText: "0x29F0A0FF"
                    onEdited: {
                        if (value === Config.options.hyprland.decoration.blur.aurora.color1) return
                        Config.options.hyprland.decoration.blur.aurora.color1 = value
                        HyprlandConfig.set("decoration:blur:aurora:color1", value)
                    }
                }
                ConfigTextArea {
                    objectName: "HyprlandSettings.aurora-color-2-0xaarrggbb";
                    visible: page.settingsShow("effects") && (page.blurVariantSupported && Config.options.hyprland.decoration.blur.variant === "aurora")
                    buttonIcon: "colorize"
                    text: Translation.tr("Aurora Color 2 (0xAARRGGBB)")
                    value: Config.options.hyprland.decoration.blur.aurora.color2
                    placeholderText: "0x7A4DFFFF"
                    onEdited: {
                        if (value === Config.options.hyprland.decoration.blur.aurora.color2) return
                        Config.options.hyprland.decoration.blur.aurora.color2 = value
                        HyprlandConfig.set("decoration:blur:aurora:color2", value)
                    }
                }
                // ── Haze ────────────────────────────────────────────────────
                ConfigSpinBox {
                    objectName: "HyprlandSettings.haze-intensity";
                    visible: page.settingsShow("effects") && (page.blurVariantSupported && Config.options.hyprland.decoration.blur.variant === "haze")
                    icon: "blur_circular"
                    text: Translation.tr("Haze Intensity")
                    value: Math.round(Config.options.hyprland.decoration.blur.haze.intensity * 100)
                    from: 0; to: 100; stepSize: 5
                    onEdited: {
                        const v = value / 100.0
                        if (v === Config.options.hyprland.decoration.blur.haze.intensity) return
                        Config.options.hyprland.decoration.blur.haze.intensity = v
                        HyprlandConfig.set("decoration:blur:haze:intensity", v)
                    }
                }
                ConfigSpinBox {
                    objectName: "HyprlandSettings.haze-iridescence";
                    visible: page.settingsShow("effects") && (page.blurVariantSupported && Config.options.hyprland.decoration.blur.variant === "haze")
                    icon: "auto_awesome"
                    text: Translation.tr("Haze Iridescence")
                    value: Math.round(Config.options.hyprland.decoration.blur.haze.iridescence * 100)
                    from: 0; to: 100; stepSize: 5
                    onEdited: {
                        const v = value / 100.0
                        if (v === Config.options.hyprland.decoration.blur.haze.iridescence) return
                        Config.options.hyprland.decoration.blur.haze.iridescence = v
                        HyprlandConfig.set("decoration:blur:haze:iridescence", v)
                    }
                }
                ConfigSpinBox {
                    visible: page.settingsShow("effects");
                    objectName: "HyprlandSettings.border-size";
                    icon: "border_outer"
                    text: Translation.tr("Border Size")
                    value: Config.options.hyprland.general.borderSize
                    from: 0; to: 10; stepSize: 1
                    onEdited: {
                        if (value === Config.options.hyprland.general.borderSize) return
                        Config.options.hyprland.general.borderSize = value
                        HyprlandConfig.set("general:border_size", value)
                    }
                }
                ConfigSpinBox {
                    visible: page.settingsShow("effects");
                    objectName: "HyprlandSettings.gaps-in";
                    icon: "margin"
                    text: Translation.tr("Gaps In")
                    value: Config.options.hyprland.general.gapsIn
                    from: 0; to: 40; stepSize: 1
                    onEdited: {
                        if (value === Config.options.hyprland.general.gapsIn) return
                        Config.options.hyprland.general.gapsIn = value
                        HyprlandConfig.set("general:gaps_in", value)
                    }
                }
                ConfigSpinBox {
                    visible: page.settingsShow("effects");
                    objectName: "HyprlandSettings.gaps-out";
                    icon: "open_in_full"
                    text: Translation.tr("Gaps Out")
                    value: Config.options.hyprland.general.gapsOut
                    from: 0; to: 60; stepSize: 1
                    onEdited: {
                        if (value === Config.options.hyprland.general.gapsOut) return
                        Config.options.hyprland.general.gapsOut = value
                        HyprlandConfig.set("general:gaps_out", value)
                    }
                }
                ConfigSpinBox {
                    visible: page.settingsShow("effects");
                    objectName: "HyprlandSettings.gaps-workspaces";
                    icon: "view_agenda"
                    text: Translation.tr("Gaps Workspaces")
                    value: Config.options.hyprland.general.gapsWorkspaces
                    from: 0; to: 100; stepSize: 5
                    onEdited: {
                        if (value === Config.options.hyprland.general.gapsWorkspaces) return
                        Config.options.hyprland.general.gapsWorkspaces = value
                        HyprlandConfig.set("general:gaps_workspaces", value)
                    }
                }
                ConfigSpinBox {
                    visible: page.settingsShow("effects");
                    objectName: "HyprlandSettings.active-opacity";
                    icon: "opacity"
                    text: Translation.tr("Active Opacity")
                    value: Math.round(Config.options.hyprland.decoration.activeOpacity * 100)
                    from: 10; to: 100; stepSize: 5
                    onEdited: {
                        const newVal = value / 100.0
                        if (newVal === Config.options.hyprland.decoration.activeOpacity) return
                        Config.options.hyprland.decoration.activeOpacity = newVal
                        HyprlandConfig.set("decoration:active_opacity", newVal)
                    }
                }
                ConfigSpinBox {
                    visible: page.settingsShow("effects");
                    objectName: "HyprlandSettings.inactive-opacity";
                    icon: "opacity"
                    text: Translation.tr("Inactive Opacity")
                    value: Math.round(Config.options.hyprland.decoration.inactiveOpacity * 100)
                    from: 10; to: 100; stepSize: 5
                    onEdited: {
                        const newVal = value / 100.0
                        if (newVal === Config.options.hyprland.decoration.inactiveOpacity) return
                        Config.options.hyprland.decoration.inactiveOpacity = newVal
                        HyprlandConfig.set("decoration:inactive_opacity", newVal)
                    }
                }
                ConfigSpinBox {
                    visible: page.settingsShow("effects");
                    objectName: "HyprlandSettings.fullscreen-opacity";
                    icon: "opacity"
                    text: Translation.tr("Fullscreen Opacity")
                    value: Math.round(Config.options.hyprland.decoration.fullscreenOpacity * 100)
                    from: 10; to: 100; stepSize: 5
                    onEdited: {
                        const v = value/100.0
                        if (v === Config.options.hyprland.decoration.fullscreenOpacity) return
                        Config.options.hyprland.decoration.fullscreenOpacity = v
                        HyprlandConfig.set("decoration:fullscreen_opacity", v)
                    }
                }
                ConfigSwitch {
                    visible: page.settingsShow("effects");
                    objectName: "HyprlandSettings.dim-inactive";
                    buttonIcon: "contrast"
                    text: Translation.tr("Dim Inactive")
                    checked: Config.options.hyprland.decoration.dimInactive
                    onEdited: {
                        if (checked === Config.options.hyprland.decoration.dimInactive) return
                        Config.options.hyprland.decoration.dimInactive = checked
                        HyprlandConfig.set("decoration:dim_inactive", checked ? 1 : 0)
                    }
                }
                ConfigSpinBox {
                    visible: page.settingsShow("effects");
                    objectName: "HyprlandSettings.dim-strength";
                    icon: "brightness_6"
                    text: Translation.tr("Dim Strength")
                    value: Math.round(Config.options.hyprland.decoration.dimStrength * 100)
                    from: 0; to: 100; stepSize: 5
                    enabled: Config.options.hyprland.decoration.dimInactive
                    onEdited: {
                        const v = value/100.0
                        if (v === Config.options.hyprland.decoration.dimStrength) return
                        Config.options.hyprland.decoration.dimStrength = v
                        HyprlandConfig.set("decoration:dim_strength", v)
                    }
                }
                ConfigSpinBox {
                    visible: page.settingsShow("effects");
                    objectName: "HyprlandSettings.dim-special";
                    icon: "dark_mode"
                    text: Translation.tr("Dim Special")
                    value: Math.round(Config.options.hyprland.decoration.dimSpecial * 100)
                    from: 0; to: 100; stepSize: 5
                    onEdited: {
                        const v = value/100.0
                        if (v === Config.options.hyprland.decoration.dimSpecial) return
                        Config.options.hyprland.decoration.dimSpecial = v
                        HyprlandConfig.set("decoration:dim_special", v)
                    }
                }
                ConfigSwitch {
                    visible: page.settingsShow("effects");
                    objectName: "HyprlandSettings.border-part-of-window";
                    buttonIcon: "crop_5_4"
                    text: Translation.tr("Border Part Of Window")
                    checked: Config.options.hyprland.decoration.borderPartOfWindow
                    onEdited: {
                        if (checked === Config.options.hyprland.decoration.borderPartOfWindow) return
                        Config.options.hyprland.decoration.borderPartOfWindow = checked
                        HyprlandConfig.set("decoration:border_part_of_window", checked ? 1 : 0)
                    }
                }
                // Shadow
                ConfigSwitch {
                    visible: page.settingsShow("effects");
                    objectName: "HyprlandSettings.shadow-enabled";
                    buttonIcon: "shadow"
                    text: Translation.tr("Shadow Enabled")
                    checked: Config.options.hyprland.decoration.shadow.enabled
                    onEdited: {
                        if (checked === Config.options.hyprland.decoration.shadow.enabled) return
                        Config.options.hyprland.decoration.shadow.enabled = checked
                        HyprlandConfig.set("decoration:shadow:enabled", checked ? 1 : 0)
                    }
                }
                ConfigSpinBox {
                    visible: page.settingsShow("effects");
                    objectName: "HyprlandSettings.shadow-range";
                    icon: "expand"
                    text: Translation.tr("Shadow Range")
                    value: Config.options.hyprland.decoration.shadow.range
                    from: 0; to: 100; stepSize: 1
                    enabled: Config.options.hyprland.decoration.shadow.enabled
                    onEdited: {
                        if (value === Config.options.hyprland.decoration.shadow.range) return
                        Config.options.hyprland.decoration.shadow.range = value
                        HyprlandConfig.set("decoration:shadow:range", value)
                    }
                }
                ConfigSpinBox {
                    visible: page.settingsShow("effects");
                    objectName: "HyprlandSettings.shadow-render-power";
                    icon: "filter_b_and_w"
                    text: Translation.tr("Shadow Render Power")
                    value: Config.options.hyprland.decoration.shadow.renderPower
                    from: 1; to: 4; stepSize: 1
                    enabled: Config.options.hyprland.decoration.shadow.enabled
                    onEdited: {
                        if (value === Config.options.hyprland.decoration.shadow.renderPower) return
                        Config.options.hyprland.decoration.shadow.renderPower = value
                        HyprlandConfig.set("decoration:shadow:render_power", value)
                    }
                }
                ConfigSwitch {
                    visible: page.settingsShow("effects");
                    objectName: "HyprlandSettings.shadow-sharp";
                    buttonIcon: "motion_photos_off"
                    text: Translation.tr("Shadow Sharp")
                    checked: Config.options.hyprland.decoration.shadow.sharp
                    enabled: Config.options.hyprland.decoration.shadow.enabled
                    onEdited: {
                        if (checked === Config.options.hyprland.decoration.shadow.sharp) return
                        Config.options.hyprland.decoration.shadow.sharp = checked
                        HyprlandConfig.set("decoration:shadow:sharp", checked ? 1 : 0)
                    }
                }
                ConfigSpinBox {
                    visible: page.settingsShow("effects");
                    objectName: "HyprlandSettings.shadow-offset-x";
                    icon: "open_with"
                    text: Translation.tr("Shadow Offset X")
                    value: Config.options.hyprland.decoration.shadow.offsetX
                    from: -50; to: 50; stepSize: 1
                    enabled: Config.options.hyprland.decoration.shadow.enabled
                    onEdited: {
                        if (value === Config.options.hyprland.decoration.shadow.offsetX) return
                        Config.options.hyprland.decoration.shadow.offsetX = value
                        HyprlandConfig.set("decoration:shadow:offset", `${value}, ${Config.options.hyprland.decoration.shadow.offsetY}`)
                    }
                }
                ConfigSpinBox {
                    visible: page.settingsShow("effects");
                    objectName: "HyprlandSettings.shadow-offset-y";
                    icon: "open_with"
                    text: Translation.tr("Shadow Offset Y")
                    value: Config.options.hyprland.decoration.shadow.offsetY
                    from: -50; to: 50; stepSize: 1
                    enabled: Config.options.hyprland.decoration.shadow.enabled
                    onEdited: {
                        if (value === Config.options.hyprland.decoration.shadow.offsetY) return
                        Config.options.hyprland.decoration.shadow.offsetY = value
                        HyprlandConfig.set("decoration:shadow:offset", `${Config.options.hyprland.decoration.shadow.offsetX}, ${value}`)
                    }
                }
                ConfigSpinBox {
                    visible: page.settingsShow("effects");
                    objectName: "HyprlandSettings.shadow-scale";
                    icon: "zoom_out_map"
                    text: Translation.tr("Shadow Scale")
                    value: Math.round(Config.options.hyprland.decoration.shadow.scale * 100)
                    from: 5; to: 200; stepSize: 5
                    enabled: Config.options.hyprland.decoration.shadow.enabled
                    onEdited: {
                        const v = value/100.0
                        if (v === Config.options.hyprland.decoration.shadow.scale) return
                        Config.options.hyprland.decoration.shadow.scale = v
                        HyprlandConfig.set("decoration:shadow:scale", v)
                    }
                }
                // Shadow inactive color
                ConfigTextArea {
                    visible: page.settingsShow("effects");
                    objectName: "HyprlandSettings.shadow-inactive-color";
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
                visible: page.settingsShow("effects");
                title: Translation.tr("Advanced Decoration")
                GroupedList {
                    compact: true;
                    visible: page.settingsShow("effects")
                    // Dim Modal
                    ConfigSwitch {
                        visible: page.settingsShow("effects");
                        objectName: "HyprlandSettings.dim-modal";
                        buttonIcon: "window"
                        text: Translation.tr("Dim Modal")
                        checked: Config.options.hyprland.decoration.dimModal
                        onEdited: {
                            if (checked === Config.options.hyprland.decoration.dimModal) return
                            Config.options.hyprland.decoration.dimModal = checked
                            HyprlandConfig.set("decoration:dim_modal", checked ? 1 : 0)
                        }
                    }
                    // Dim Around
                    ConfigSwitch {
                        visible: page.settingsShow("effects");
                        objectName: "HyprlandSettings.dim-around";
                        buttonIcon: "center_focus_weak"
                        text: Translation.tr("Dim Around")
                        checked: Config.options.hyprland.decoration.dimAround
                        onEdited: {
                            if (checked === Config.options.hyprland.decoration.dimAround) return
                            Config.options.hyprland.decoration.dimAround = checked
                            HyprlandConfig.set("decoration:dim_around", checked ? 1 : 0)
                        }
                    }
                }
            }

            // Advanced Blur
            ContentSubsection {
                visible: page.settingsShow("effects");
                title: Translation.tr("Advanced Blur")
                GroupedList {
                    compact: true;
                    visible: page.settingsShow("effects")
                    // Noise
                    ConfigSlider {
                        visible: page.settingsShow("effects");
                        objectName: "HyprlandSettings.noise";
                        text: Translation.tr("Noise")
                        buttonIcon: "grain"
                        value: Math.round(Config.options.hyprland.decoration.blur.noise * 100)
                        from: 0; to: 100
                        onEdited: {
                            const v = value / 100.0
                            if (v === Config.options.hyprland.decoration.blur.noise) return
                            Config.options.hyprland.decoration.blur.noise = v
                            HyprlandConfig.set("decoration:blur:noise", v)
                        }
                    }
                    // Contrast
                    ConfigSlider {
                        visible: page.settingsShow("effects");
                        objectName: "HyprlandSettings.contrast";
                        text: Translation.tr("Contrast")
                        buttonIcon: "contrast"
                        value: Math.round(Config.options.hyprland.decoration.blur.contrast * 100)
                        from: 0; to: 100
                        onEdited: {
                            const v = value / 100.0
                            if (v === Config.options.hyprland.decoration.blur.contrast) return
                            Config.options.hyprland.decoration.blur.contrast = v
                            HyprlandConfig.set("decoration:blur:contrast", v)
                        }
                    }
                    // Brightness
                    ConfigSlider {
                        visible: page.settingsShow("effects");
                        objectName: "HyprlandSettings.brightness";
                        text: Translation.tr("Brightness")
                        buttonIcon: "brightness_6"
                        value: Math.round(Config.options.hyprland.decoration.blur.brightness * 100)
                        from: 0; to: 100
                        onEdited: {
                            const v = value / 100.0
                            if (v === Config.options.hyprland.decoration.blur.brightness) return
                            Config.options.hyprland.decoration.blur.brightness = v
                            HyprlandConfig.set("decoration:blur:brightness", v)
                        }
                    }
                    // Vibrancy Darkness
                    ConfigSlider {
                        visible: page.settingsShow("effects");
                        objectName: "HyprlandSettings.vibrancy-darkness";
                        text: Translation.tr("Vibrancy Darkness")
                        buttonIcon: "dark_mode"
                        value: Math.round(Config.options.hyprland.decoration.blur.vibrancyDarkness * 100)
                        from: 0; to: 100
                        onEdited: {
                            const v = value / 100.0
                            if (v === Config.options.hyprland.decoration.blur.vibrancyDarkness) return
                            Config.options.hyprland.decoration.blur.vibrancyDarkness = v
                            HyprlandConfig.set("decoration:blur:vibrancy_darkness", v)
                        }
                    }
                    // Blur Special
                    ConfigSwitch {
                        visible: page.settingsShow("effects");
                        objectName: "HyprlandSettings.blur-special";
                        buttonIcon: "blur_on"
                        text: Translation.tr("Blur Special")
                        checked: Config.options.hyprland.decoration.blur.special
                        onEdited: {
                            if (checked === Config.options.hyprland.decoration.blur.special) return
                            Config.options.hyprland.decoration.blur.special = checked
                            HyprlandConfig.set("decoration:blur:special", checked ? 1 : 0)
                        }
                    }
                    // Blur Popups
                    ConfigSwitch {
                        visible: page.settingsShow("effects");
                        objectName: "HyprlandSettings.blur-popups";
                        buttonIcon: "web_asset"
                        text: Translation.tr("Blur Popups")
                        checked: Config.options.hyprland.decoration.blur.popups
                        onEdited: {
                            if (checked === Config.options.hyprland.decoration.blur.popups) return
                            Config.options.hyprland.decoration.blur.popups = checked
                            HyprlandConfig.set("decoration:blur:popups", checked ? 1 : 0)
                        }
                    }
                    // Blur Popups Ignore Alpha
                    ConfigSwitch {
                        visible: page.settingsShow("effects");
                        objectName: "HyprlandSettings.popups-ignore-alpha";
                        buttonIcon: "visibility"
                        text: Translation.tr("Popups Ignore Alpha")
                        checked: Config.options.hyprland.decoration.blur.popupsIgnorealpha
                        enabled: Config.options.hyprland.decoration.blur.popups
                        onEdited: {
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
            visible: page.settingsShow("window-rules");
            icon: "tune"
            shape: MaterialShape.Shape.Cookie9Sided
            title: Translation.tr("General & Snap")
            GroupedList {
                compact: true;
                visible: page.settingsShow("window-rules")
                ConfigSwitch {
                    visible: page.settingsShow("window-rules");
                    objectName: "HyprlandSettings.resize-on-border";
                    buttonIcon: "border_outer"
                    text: Translation.tr("Resize On Border")
                    checked: Config.options.hyprland.general.resizeOnBorder
                    onEdited: {
                        if (checked === Config.options.hyprland.general.resizeOnBorder) return
                        Config.options.hyprland.general.resizeOnBorder = checked
                        HyprlandConfig.set("general:resize_on_border", checked ? 1 : 0)
                    }
                }
                ConfigSwitch {
                    visible: page.settingsShow("window-rules");
                    objectName: "HyprlandSettings.allow-tearing";
                    buttonIcon: "tear_off"
                    text: Translation.tr("Allow Tearing")
                    checked: Config.options.hyprland.general.allowTearing
                    onEdited: {
                        if (checked === Config.options.hyprland.general.allowTearing) return
                        Config.options.hyprland.general.allowTearing = checked
                        HyprlandConfig.set("general:allow_tearing", checked ? 1 : 0)
                    }
                }
                ConfigSwitch {
                    visible: page.settingsShow("window-rules");
                    objectName: "HyprlandSettings.snap-enabled";
                    buttonIcon: "magnet"
                    text: Translation.tr("Snap Enabled")
                    checked: Config.options.hyprland.general.snapEnabled
                    onEdited: {
                        if (checked === Config.options.hyprland.general.snapEnabled) return
                        Config.options.hyprland.general.snapEnabled = checked
                        HyprlandConfig.set("general:snap:enabled", checked ? 1 : 0)
                    }
                }
                ConfigSpinBox {
                    visible: page.settingsShow("window-rules");
                    objectName: "HyprlandSettings.snap-window-gap";
                    icon: "space_bar"
                    text: Translation.tr("Snap Window Gap")
                    value: Config.options.hyprland.general.snapWindowGap
                    from: 0; to: 100; stepSize: 1
                    enabled: Config.options.hyprland.general.snapEnabled
                    onEdited: {
                        if (value === Config.options.hyprland.general.snapWindowGap) return
                        Config.options.hyprland.general.snapWindowGap = value
                        HyprlandConfig.set("general:snap:window_gap", value)
                    }
                }
                ConfigSpinBox {
                    visible: page.settingsShow("window-rules");
                    objectName: "HyprlandSettings.snap-monitor-gap";
                    icon: "monitor"
                    text: Translation.tr("Snap Monitor Gap")
                    value: Config.options.hyprland.general.snapMonitorGap
                    from: 0; to: 100; stepSize: 1
                    enabled: Config.options.hyprland.general.snapEnabled
                    onEdited: {
                        if (value === Config.options.hyprland.general.snapMonitorGap) return
                        Config.options.hyprland.general.snapMonitorGap = value
                        HyprlandConfig.set("general:snap:monitor_gap", value)
                    }
                }
                ConfigSwitch {
                    visible: page.settingsShow("window-rules");
                    objectName: "HyprlandSettings.snap-border-overlap";
                    buttonIcon: "overlap"
                    text: Translation.tr("Snap Border Overlap")
                    checked: Config.options.hyprland.general.snapBorderOverlap
                    enabled: Config.options.hyprland.general.snapEnabled
                    onEdited: {
                        if (checked === Config.options.hyprland.general.snapBorderOverlap) return
                        Config.options.hyprland.general.snapBorderOverlap = checked
                        HyprlandConfig.set("general:snap:border_overlap", checked ? 1 : 0)
                    }
                }
                ConfigSwitch {
                    visible: page.settingsShow("window-rules");
                    objectName: "HyprlandSettings.snap-respect-gaps";
                    buttonIcon: "grid_on"
                    text: Translation.tr("Snap Respect Gaps")
                    checked: Config.options.hyprland.general.snapRespectGaps
                    enabled: Config.options.hyprland.general.snapEnabled
                    onEdited: {
                        if (checked === Config.options.hyprland.general.snapRespectGaps) return
                        Config.options.hyprland.general.snapRespectGaps = checked
                        HyprlandConfig.set("general:snap:respect_gaps", checked ? 1 : 0)
                    }
                }
            }

            // Advanced General Settings
            ContentSubsection {
                visible: page.settingsShow("window-rules");
                title: Translation.tr("Advanced General Settings")
                GroupedList {
                    compact: true;
                    visible: page.settingsShow("window-rules")
                    // Active border color
                    ConfigTextArea {
                        visible: page.settingsShow("window-rules");
                        objectName: "HyprlandSettings.active-border-color";
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
                        visible: page.settingsShow("window-rules");
                        objectName: "HyprlandSettings.inactive-border-color";
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
                        visible: page.settingsShow("window-rules");
                        objectName: "HyprlandSettings.nogroup-border-color";
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
                        visible: page.settingsShow("window-rules");
                        objectName: "HyprlandSettings.float-gaps";
                        icon: "view_carousel"
                        text: Translation.tr("Float Gaps")
                        value: Config.options.hyprland.general.floatGaps
                        from: 0; to: 100; stepSize: 1
                        onEdited: {
                            if (value === Config.options.hyprland.general.floatGaps) return
                            Config.options.hyprland.general.floatGaps = value
                            HyprlandConfig.set("general:float_gaps", value)
                        }
                    }
                    // Extend border grab area
                    ConfigSwitch {
                        visible: page.settingsShow("window-rules");
                        objectName: "HyprlandSettings.extend-border-grab-area";
                        buttonIcon: "drag_indicator"
                        text: Translation.tr("Extend Border Grab Area")
                        checked: Config.options.hyprland.general.extendBorderGrabArea
                        onEdited: {
                            if (checked === Config.options.hyprland.general.extendBorderGrabArea) return
                            Config.options.hyprland.general.extendBorderGrabArea = checked
                            HyprlandConfig.set("general:extend_border_grab_area", checked ? 1 : 0)
                        }
                    }
                    // Hover icon on border
                    ConfigSwitch {
                        visible: page.settingsShow("window-rules");
                        objectName: "HyprlandSettings.hover-icon-on-border";
                        buttonIcon: "cursor"
                        text: Translation.tr("Hover Icon On Border")
                        checked: Config.options.hyprland.general.hoverIconOnBorder
                        onEdited: {
                            if (checked === Config.options.hyprland.general.hoverIconOnBorder) return
                            Config.options.hyprland.general.hoverIconOnBorder = checked
                            HyprlandConfig.set("general:hover_icon_on_border", checked ? 1 : 0)
                        }
                    }
                    // No focus fallback
                    ConfigSwitch {
                        visible: page.settingsShow("window-rules");
                        objectName: "HyprlandSettings.no-focus-fallback";
                        buttonIcon: "focus_disabled"
                        text: Translation.tr("No Focus Fallback")
                        checked: Config.options.hyprland.general.noFocusFallback
                        onEdited: {
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
            visible: page.settingsShow("window-rules");
            icon: "settings"
            shape: MaterialShape.Shape.Sunny
            title: Translation.tr("Misc")
            GroupedList {
                compact: true;
                visible: page.settingsShow("window-rules")
                ConfigSwitch {
                    visible: page.settingsShow("window-rules");
                    objectName: "HyprlandSettings.disable-hyprland-logo";
                    buttonIcon: "image_not_supported"
                    text: Translation.tr("Disable Hyprland Logo")
                    checked: Config.options.hyprland.misc.disableHyprlandLogo
                    onEdited: {
                        if (checked === Config.options.hyprland.misc.disableHyprlandLogo) return
                        Config.options.hyprland.misc.disableHyprlandLogo = checked
                        HyprlandConfig.set("misc:disable_hyprland_logo", checked ? 1 : 0)
                    }
                }
                ConfigSwitch {
                    visible: page.settingsShow("window-rules");
                    objectName: "HyprlandSettings.disable-splash-rendering";
                    buttonIcon: "wallpaper"
                    text: Translation.tr("Disable Splash Rendering")
                    checked: Config.options.hyprland.misc.disableSplashRendering
                    onEdited: {
                        if (checked === Config.options.hyprland.misc.disableSplashRendering) return
                        Config.options.hyprland.misc.disableSplashRendering = checked
                        HyprlandConfig.set("misc:disable_splash_rendering", checked ? 1 : 0)
                    }
                }
                ConfigSelectionArray {
                    visible: page.settingsShow("window-rules");
                    objectName: "HyprlandSettings.vrr-2";
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
                    visible: page.settingsShow("window-rules");
                    objectName: "HyprlandSettings.mouse-move-enables-dpms";
                    buttonIcon: "mouse"
                    text: Translation.tr("Mouse Move Enables DPMS")
                    checked: Config.options.hyprland.misc.mouseMoveEnablesDpms
                    onEdited: {
                        if (checked === Config.options.hyprland.misc.mouseMoveEnablesDpms) return
                        Config.options.hyprland.misc.mouseMoveEnablesDpms = checked
                        HyprlandConfig.set("misc:mouse_move_enables_dpms", checked ? 1 : 0)
                    }
                }
                ConfigSwitch {
                    visible: page.settingsShow("window-rules");
                    objectName: "HyprlandSettings.key-press-enables-dpms";
                    buttonIcon: "keyboard"
                    text: Translation.tr("Key Press Enables DPMS")
                    checked: Config.options.hyprland.misc.keyPressEnablesDpms
                    onEdited: {
                        if (checked === Config.options.hyprland.misc.keyPressEnablesDpms) return
                        Config.options.hyprland.misc.keyPressEnablesDpms = checked
                        HyprlandConfig.set("misc:key_press_enables_dpms", checked ? 1 : 0)
                    }
                }
                ConfigSwitch {
                    visible: page.settingsShow("window-rules");
                    objectName: "HyprlandSettings.animate-manual-resizes";
                    buttonIcon: "open_with"
                    text: Translation.tr("Animate Manual Resizes")
                    checked: Config.options.hyprland.misc.animateManualResizes
                    onEdited: {
                        if (checked === Config.options.hyprland.misc.animateManualResizes) return
                        Config.options.hyprland.misc.animateManualResizes = checked
                        HyprlandConfig.set("misc:animate_manual_resizes", checked ? 1 : 0)
                    }
                }
                ConfigSwitch {
                    visible: page.settingsShow("window-rules");
                    objectName: "HyprlandSettings.animate-mouse-window-dragging";
                    buttonIcon: "drag_indicator"
                    text: Translation.tr("Animate Mouse Window Dragging")
                    checked: Config.options.hyprland.misc.animateMouseWindowDragging
                    onEdited: {
                        if (checked === Config.options.hyprland.misc.animateMouseWindowDragging) return
                        Config.options.hyprland.misc.animateMouseWindowDragging = checked
                        HyprlandConfig.set("misc:animate_mouse_windowdragging", checked ? 1 : 0)
                    }
                }
                ConfigSelectionArray {
                    visible: page.settingsShow("window-rules");
                    objectName: "HyprlandSettings.focus-on-activate";
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
            visible: page.settingsShow("input-details");
            icon: "mouse"
            shape: MaterialShape.Shape.Oval
            title: Translation.tr("Cursor")
            GroupedList {
                compact: true;
                visible: page.settingsShow("input-details")
                ConfigSpinBox {
                    visible: page.settingsShow("input-details");
                    objectName: "HyprlandSettings.zoom-factor";
                    icon: "zoom_in"
                    text: Translation.tr("Zoom Factor")
                    value: Math.round(Config.options.hyprland.cursor.zoomFactor * 10)
                    from: 10; to: 30; stepSize: 1
                    onEdited: {
                        const v = value/10.0
                        if (v === Config.options.hyprland.cursor.zoomFactor) return
                        Config.options.hyprland.cursor.zoomFactor = v
                        HyprlandConfig.set("cursor:zoom_factor", v)
                    }
                }
                ConfigSwitch {
                    visible: page.settingsShow("input-details");
                    objectName: "HyprlandSettings.zoom-rigid";
                    buttonIcon: "open_with"
                    text: Translation.tr("Zoom Rigid")
                    checked: Config.options.hyprland.cursor.zoomRigid
                    onEdited: {
                        if (checked === Config.options.hyprland.cursor.zoomRigid) return
                        Config.options.hyprland.cursor.zoomRigid = checked
                        HyprlandConfig.set("cursor:zoom_rigid", checked ? 1 : 0)
                    }
                }
                ConfigSwitch {
                    visible: page.settingsShow("input-details");
                    objectName: "HyprlandSettings.hide-on-key-press";
                    buttonIcon: "keyboard_hide"
                    text: Translation.tr("Hide On Key Press")
                    checked: Config.options.hyprland.cursor.hideOnKeyPress
                    onEdited: {
                        if (checked === Config.options.hyprland.cursor.hideOnKeyPress) return
                        Config.options.hyprland.cursor.hideOnKeyPress = checked
                        HyprlandConfig.set("cursor:hide_on_key_press", checked ? 1 : 0)
                    }
                }
                ConfigSpinBox {
                    visible: page.settingsShow("input-details");
                    objectName: "HyprlandSettings.inactive-timeout-s";
                    icon: "timer"
                    text: Translation.tr("Inactive Timeout (s)")
                    value: Config.options.hyprland.cursor.inactiveTimeout
                    from: 0; to: 60; stepSize: 1
                    onEdited: {
                        if (value === Config.options.hyprland.cursor.inactiveTimeout) return
                        Config.options.hyprland.cursor.inactiveTimeout = value
                        HyprlandConfig.set("cursor:inactive_timeout", value)
                    }
                }
                ConfigSpinBox {
                    visible: page.settingsShow("input-details");
                    objectName: "HyprlandSettings.hotspot-padding";
                    icon: "padding"
                    text: Translation.tr("Hotspot Padding")
                    value: Config.options.hyprland.cursor.hotspotPadding
                    from: 0; to: 10; stepSize: 1
                    onEdited: {
                        if (value === Config.options.hyprland.cursor.hotspotPadding) return
                        Config.options.hyprland.cursor.hotspotPadding = value
                        HyprlandConfig.set("cursor:hotspot_padding", value)
                    }
                }
                ConfigSwitch {
                    visible: page.settingsShow("input-details");
                    objectName: "HyprlandSettings.no-warps";
                    buttonIcon: "block"
                    text: Translation.tr("No Warps")
                    checked: Config.options.hyprland.cursor.noWarps
                    onEdited: {
                        if (checked === Config.options.hyprland.cursor.noWarps) return
                        Config.options.hyprland.cursor.noWarps = checked
                        HyprlandConfig.set("cursor:no_warps", checked ? 1 : 0)
                    }
                }
                ConfigSwitch {
                    visible: page.settingsShow("input-details");
                    objectName: "HyprlandSettings.persistent-warps";
                    buttonIcon: "repeat"
                    text: Translation.tr("Persistent Warps")
                    checked: Config.options.hyprland.cursor.persistentWarps
                    onEdited: {
                        if (checked === Config.options.hyprland.cursor.persistentWarps) return
                        Config.options.hyprland.cursor.persistentWarps = checked
                        HyprlandConfig.set("cursor:persistent_warps", checked ? 1 : 0)
                    }
                }
            }
        }

        // Gestures
        ContentSection {
            visible: page.settingsShow("input-details");
            icon: "gesture"
            shape: MaterialShape.Shape.Diamond
            title: Translation.tr("Gestures")
            GroupedList {
                compact: true;
                visible: page.settingsShow("input-details")
                ConfigSpinBox {
                    visible: page.settingsShow("input-details");
                    objectName: "HyprlandSettings.workspace-swipe-distance";
                    icon: "swipe"
                    text: Translation.tr("Workspace Swipe Distance")
                    value: Config.options.hyprland.gestures.workspaceSwipeDistance
                    from: 100; to: 1000; stepSize: 10
                    onEdited: {
                        if (value === Config.options.hyprland.gestures.workspaceSwipeDistance) return
                        Config.options.hyprland.gestures.workspaceSwipeDistance = value
                        HyprlandConfig.set("gestures:workspace_swipe_distance", value)
                    }
                }
                ConfigSpinBox {
                    visible: page.settingsShow("input-details");
                    objectName: "HyprlandSettings.swipe-cancel-ratio";
                    icon: "cancel"
                    text: Translation.tr("Swipe Cancel Ratio (%)")
                    value: Math.round(Config.options.hyprland.gestures.workspaceSwipeCancelRatio * 100)
                    from: 0; to: 100; stepSize: 5
                    onEdited: {
                        const v = value/100.0
                        if (v === Config.options.hyprland.gestures.workspaceSwipeCancelRatio) return
                        Config.options.hyprland.gestures.workspaceSwipeCancelRatio = v
                        HyprlandConfig.set("gestures:workspace_swipe_cancel_ratio", v)
                    }
                }
                ConfigSpinBox {
                    visible: page.settingsShow("input-details");
                    objectName: "HyprlandSettings.swipe-min-speed";
                    icon: "speed"
                    text: Translation.tr("Swipe Min Speed")
                    value: Config.options.hyprland.gestures.workspaceSwipeMinSpeedToForce
                    from: 0; to: 50; stepSize: 1
                    onEdited: {
                        if (value === Config.options.hyprland.gestures.workspaceSwipeMinSpeedToForce) return
                        Config.options.hyprland.gestures.workspaceSwipeMinSpeedToForce = value
                        HyprlandConfig.set("gestures:workspace_swipe_min_speed_to_force", value)
                    }
                }
                ConfigSwitch {
                    visible: page.settingsShow("input-details");
                    objectName: "HyprlandSettings.swipe-direction-lock";
                    buttonIcon: "lock"
                    text: Translation.tr("Swipe Direction Lock")
                    checked: Config.options.hyprland.gestures.workspaceSwipeDirectionLock
                    onEdited: {
                        if (checked === Config.options.hyprland.gestures.workspaceSwipeDirectionLock) return
                        Config.options.hyprland.gestures.workspaceSwipeDirectionLock = checked
                        HyprlandConfig.set("gestures:workspace_swipe_direction_lock", checked ? 1 : 0)
                    }
                }
            }
        }

        // Custom Binds — power user (writes to ~/.config/hypr/custom/keybinds.lua)
        ContentSection {
            visible: page.settingsShow("input-details");
            id: customBindsSection
            property bool draftEdited: false
            FileView {
                id: bindsSourceFile
                path: HyprlandConfig.customBindsPath
                printErrors: false
                watchChanges: true
                onFileChanged: if (!customBindsSection.draftEdited) reload()
                onLoaded: if (!customBindsSection.draftEdited) bindsArea.text = text()
            }
            icon: "keyboard"
            shape: MaterialShape.Shape.Pill
            title: Translation.tr("Custom Binds (Advanced)")
            GroupedList {
                compact: true;
                StyledText {
                    property bool groupDescription: true;
                    Layout.fillWidth: true
                    wrapMode: Text.Wrap
                    font.pixelSize: Appearance.font.pixelSize.small
                    color: Appearance.colors.colSubtext
                    text: Translation.tr("Add any hl.bind(...) lines. File is ~/.config/hypr/custom/keybinds.lua and is auto-sourced by hyprland.lua. Example: hl.bind(\"SUPER + T\", hl.dsp.exec_cmd(\"kitty\"))")
                }
            }
            Rectangle {
                visible: page.settingsShow("input-details");

                Layout.fillWidth: true
                implicitHeight: bindsArea.implicitHeight + 16
                radius: Appearance.rounding.normal
                color: Appearance.colors.colLayer1
                TextArea {
                    objectName: "HyprlandSettings.custom-shortcuts-lua";
                    visible: page.settingsShow("input-details");

                    id: bindsArea
                    onTextChanged: if (activeFocus) customBindsSection.draftEdited = true
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

                }
            }
            RowLayout {
                visible: page.settingsShow("input-details");
                Layout.fillWidth: true
                RippleButtonWithIcon {
                    visible: page.settingsShow("input-details");
                    objectName: "HyprlandSettings.save-binds";
                    materialIcon: "save"
                    mainText: Translation.tr("Save Binds")
                    onClicked: customBindsSection.saveBinds()
                    colBackground: Appearance.colors.colPrimaryContainer
                }
                RippleButtonWithIcon {
                    visible: page.settingsShow("input-details");
                    objectName: "HyprlandSettings.reload-hyprland";
                    materialIcon: "refresh"
                    mainText: Translation.tr("Reload Hyprland")
                    onClicked: reloadProc.running = true
                    colBackground: Appearance.colors.colSecondaryContainer
                }
                Item { Layout.fillWidth: true }
                StyledText {
                    visible: page.settingsShow("input-details");
                    id: bindsStatus
                    font.pixelSize: Appearance.font.pixelSize.small
                    color: Appearance.colors.colSubtext
                }
            }
            function saveBinds() {
                Config.options.hyprland.customBindsLua = bindsArea.text
                saveBindsProc.command = ["python3", HyprlandConfig.configuratorScriptPath, "--custom-binds", bindsArea.text, "--custom-binds-file", HyprlandConfig.customBindsPath]
                saveBindsProc.running = true
            }
            Process { id: saveBindsProc; onExited: (code, status) => { if (code === 0) { customBindsSection.draftEdited = false; bindsSourceFile.reload() }; bindsStatus.text = code===0 ? Translation.tr("Saved") : Translation.tr("Failed"); clearBindsStatus.restart() } }
            Timer { id: clearBindsStatus; interval: 2000; onTriggered: bindsStatus.text = "" }
            Process { id: reloadProc; command: ["hyprctl", "reload"] }
        }

        // Custom Rules
        ContentSection {
            visible: page.settingsShow("window-rules");
            id: customRulesSection
            property bool draftEdited: false
            FileView {
                id: rulesSourceFile
                path: HyprlandConfig.customRulesPath
                printErrors: false
                watchChanges: true
                onFileChanged: if (!customRulesSection.draftEdited) reload()
                onLoaded: if (!customRulesSection.draftEdited) rulesArea.text = text()
            }
            icon: "rule"
            shape: MaterialShape.Shape.Square
            title: Translation.tr("Custom Window Rules (Advanced)")
            GroupedList {
                compact: true;
                StyledText {
                    property bool groupDescription: true;
                    Layout.fillWidth: true
                    wrapMode: Text.Wrap
                    font.pixelSize: Appearance.font.pixelSize.small
                    color: Appearance.colors.colSubtext
                    text: Translation.tr("Add any hl.window_rule / hl.workspace_rule / hl.layer_rule lines. File is ~/.config/hypr/custom/rules.lua. Example: hl.window_rule({match={class=\"kitty\"}, float=true})")
                }
            }
            Rectangle {
                visible: page.settingsShow("window-rules");

                Layout.fillWidth: true
                implicitHeight: rulesArea.implicitHeight + 16
                radius: Appearance.rounding.normal
                color: Appearance.colors.colLayer1
                TextArea {
                    objectName: "HyprlandSettings.custom-window-rules-lua";
                    visible: page.settingsShow("window-rules");

                    id: rulesArea
                    onTextChanged: if (activeFocus) customRulesSection.draftEdited = true
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

                }
            }
            RowLayout {
                visible: page.settingsShow("window-rules");
                Layout.fillWidth: true
                RippleButtonWithIcon {
                    visible: page.settingsShow("window-rules");
                    objectName: "HyprlandSettings.save-rules";
                    materialIcon: "save"
                    mainText: Translation.tr("Save Rules")
                    onClicked: customRulesSection.saveRules()
                    colBackground: Appearance.colors.colPrimaryContainer
                }
                RippleButtonWithIcon {
                    visible: page.settingsShow("window-rules");
                    objectName: "HyprlandSettings.reload-hyprland-2";
                    materialIcon: "refresh"
                    mainText: Translation.tr("Reload Hyprland")
                    onClicked: reloadRulesProc.running = true
                    colBackground: Appearance.colors.colSecondaryContainer
                }
                Item { Layout.fillWidth: true }
                StyledText {
                    visible: page.settingsShow("window-rules"); id: rulesStatus; font.pixelSize: Appearance.font.pixelSize.small; color: Appearance.colors.colSubtext }
            }
            function saveRules() {
                Config.options.hyprland.customRulesLua = rulesArea.text
                saveRulesProc.command = ["python3", HyprlandConfig.configuratorScriptPath, "--custom-rules", rulesArea.text, "--custom-rules-file", HyprlandConfig.customRulesPath]
                saveRulesProc.running = true
            }
            Process { id: saveRulesProc; onExited: (code, s) => { if (code === 0) { customRulesSection.draftEdited = false; rulesSourceFile.reload() }; rulesStatus.text = code===0 ? Translation.tr("Saved") : Translation.tr("Failed"); clearRulesStatus.restart() } }
            Timer { id: clearRulesStatus; interval: 2000; onTriggered: rulesStatus.text = "" }
            Process { id: reloadRulesProc; command: ["hyprctl", "reload"] }
        }

        // Workspace Rules (Structured)
        ContentSection {
            visible: page.settingsShow("window-rules");
            id: workspaceRulesSection
            icon: "workspaces"
            shape: MaterialShape.Shape.Diamond
            title: Translation.tr("Workspace Rules")
            GroupedList {
                compact: true;
                StyledText {
                    property bool groupDescription: true;
                    Layout.fillWidth: true
                    wrapMode: Text.Wrap
                    font.pixelSize: Appearance.font.pixelSize.small
                    color: Appearance.colors.colSubtext
                    text: Translation.tr("Bind workspaces to monitors, set per-workspace gaps, border, rounding, etc. Each rule generates a hl.workspace_rule() line.")
                }
            }
            // List of workspace rules
            ColumnLayout {
                visible: page.settingsShow("window-rules");
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
                    visible: page.settingsShow("window-rules");
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
                        visible: page.settingsShow("window-rules");
                        objectName: "HyprlandSettings.add-2";
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
                StyledText {
                    visible: page.settingsShow("window-rules"); Layout.fillWidth: true; wrapMode: Text.Wrap; font.pixelSize: Appearance.font.pixelSize.smaller; color: Appearance.colors.colSubtext; text: Translation.tr("Workspace: number/name/* for all. Monitor: output name or empty. Example: '1' on 'DP-1' binds workspace 1 to DP-1.") }
            }
            // Save & reload
            Process { id: saveWrProc; onExited: (code) => { wrStatus.text = code===0 ? Translation.tr("Saved") : Translation.tr("Failed"); clearWrStatus.restart() } }
            Timer { id: clearWrStatus; interval: 2000; onTriggered: wrStatus.text = "" }
            Process { id: reloadWrProc; command: ["hyprctl", "reload"] }
            RowLayout {
                visible: page.settingsShow("window-rules");
                Layout.fillWidth: true
                RippleButtonWithIcon {
                    visible: page.settingsShow("window-rules");
                    objectName: "HyprlandSettings.save";
                    materialIcon: "save"
                    mainText: Translation.tr("Save")
                    onClicked: workspaceRulesSection.saveWorkspaceRules()
                    colBackground: Appearance.colors.colPrimaryContainer
                }
                Item { Layout.fillWidth: true }
                StyledText {
                    visible: page.settingsShow("window-rules"); id: wrStatus; font.pixelSize: Appearance.font.pixelSize.small; color: Appearance.colors.colSubtext }
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
            visible: page.settingsShow("window-rules");
            id: windowRulesSection
            icon: "select_window"
            shape: MaterialShape.Shape.Slanted
            title: Translation.tr("Window Rules (Structured)")
            GroupedList {
                compact: true;
                StyledText {
                    property bool groupDescription: true;
                    Layout.fillWidth: true
                    wrapMode: Text.Wrap
                    font.pixelSize: Appearance.font.pixelSize.small
                    color: Appearance.colors.colSubtext
                    text: Translation.tr("Apply rules to windows by class/title. Each rule generates a hl.window_rule() line.")
                }
            }
            ColumnLayout {
                visible: page.settingsShow("window-rules");
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
                    visible: page.settingsShow("window-rules");
                    Layout.fillWidth: true
                    spacing: 6
                    Rectangle {
                        Layout.preferredWidth: 80; Layout.preferredHeight: 32
                        radius: Appearance.rounding.small; color: Appearance.colors.colLayer2
                        TextInput { id: newWrClass; anchors.fill: parent; anchors.margins: 6; verticalAlignment: TextInput.AlignVCenter; selectByMouse: true; color: Appearance.colors.colOnLayer1; font.pixelSize: Appearance.font.pixelSize.small }
                        StyledText { visible: newWrClass.text.length===0; anchors.verticalCenter: parent.verticalCenter; anchors.left: parent.left; anchors.leftMargin: 6; text: "class"; color: Appearance.colors.colSubtext; font.pixelSize: Appearance.font.pixelSize.small }
                    }
                    StyledText {
                        visible: page.settingsShow("window-rules"); text: Translation.tr("→"); color: Appearance.colors.colSubtext }
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
                        visible: page.settingsShow("window-rules");
                        objectName: "HyprlandSettings.add-3";
                        materialIcon: "add"; mainText: Translation.tr("Add")
                        onClicked: {
                            let cls = newWrClass.text.trim()
                            if (!cls) return
                            const action = newWrAction.model[newWrAction.currentIndex].value
                            let arr = Config.options.hyprland.general.windowRules.slice()
                            let rule = { class: cls }
                            if (action) rule[action] = true
                            arr.push(rule)
                            Config.options.hyprland.general.windowRules = arr
                            newWrClass.text = ""
                            windowRulesSection.saveWindowRules()
                        }
                        colBackground: Appearance.colors.colPrimaryContainer
                    }
                }
                StyledText {
                    visible: page.settingsShow("window-rules"); Layout.fillWidth: true; wrapMode: Text.Wrap; font.pixelSize: Appearance.font.pixelSize.smaller; color: Appearance.colors.colSubtext; text: Translation.tr("Match by class name. Actions: Float, Pin, No Focus, No Shadow, No Blur (per-window blur/glass opt-out — blur itself is configured globally under Settings > Hyprland > Blur Style). For advanced rules, use the Custom Rules textarea below.") }
            }
            Process { id: saveWr2Proc; onExited: (code) => { wr2Status.text = code===0 ? Translation.tr("Saved") : Translation.tr("Failed"); clearWr2Status.restart() } }
            Timer { id: clearWr2Status; interval: 2000; onTriggered: wr2Status.text = "" }
            RowLayout {
                visible: page.settingsShow("window-rules");
                Layout.fillWidth: true
                RippleButtonWithIcon {
                    visible: page.settingsShow("window-rules");
                    objectName: "HyprlandSettings.save-2";
                    materialIcon: "save"
                    mainText: Translation.tr("Save")
                    onClicked: windowRulesSection.saveWindowRules()
                    colBackground: Appearance.colors.colPrimaryContainer
                }
                Item { Layout.fillWidth: true }
                StyledText {
                    visible: page.settingsShow("window-rules"); id: wr2Status; font.pixelSize: Appearance.font.pixelSize.small; color: Appearance.colors.colSubtext }
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
            visible: page.settingsShow("apps");
            icon: "app_registration"
            shape: MaterialShape.Shape.Sunny
            title: Translation.tr("Autostart Apps")
            Layout.fillWidth: true

            AutostartApps {
                visible: page.settingsShow("apps");
                objectName: "HyprlandSettings.startup-applications"}
        }

        // Animations — comprehensive editor (lua, bezier/spring, full tree)
        ContentSection {
            visible: page.settingsShow("effects");
            icon: "animation"
            shape: MaterialShape.Shape.Oval
            title: Translation.tr("Animations")
            GroupedList {
                compact: true;
                visible: page.settingsShow("effects")
                ConfigSwitch {
                    visible: page.settingsShow("effects");
                    objectName: "HyprlandSettings.enable";
                    buttonIcon: "check"
                    text: Translation.tr("Enable")
                    checked: Config.options.hyprland.animations.enable
                    onEdited: {
                        if (checked === Config.options.hyprland.animations.enable) return
                        Config.options.hyprland.animations.enable = checked
                        HyprlandConfig.set("animations:enabled", checked ? 1 : 0)
                    }
                }
                ConfigSwitch {
                    visible: page.settingsShow("effects");
                    objectName: "HyprlandSettings.workspace-wraparound";
                    buttonIcon: "tune"
                    text: Translation.tr("Workspace Wraparound")
                    checked: Config.options.hyprland.animations.workspaceWraparound
                    onEdited: {
                        if (checked === Config.options.hyprland.animations.workspaceWraparound) return
                        Config.options.hyprland.animations.workspaceWraparound = checked
                        HyprlandConfig.set("animations:workspace_wraparound", checked ? 1 : 0)
                    }
                }
                ConfigSwitch {
                    visible: page.settingsShow("effects");
                    objectName: "HyprlandSettings.custom-editor-advanced";
                    buttonIcon: "edit"
                    text: Translation.tr("Custom Editor (advanced)")
                    checked: Config.options.hyprland.animations.customEnabled
                    onEdited: {
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
                    objectName: "HyprlandSettings.presets";
                    visible: page.settingsShow("effects") && (!Config.options.hyprland.animations.customEnabled)
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
                    property bool groupDescription: true;
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
                visible: page.settingsShow("effects") && (Config.options.hyprland.animations.customEnabled)
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
                    visible: page.settingsShow("effects");
                    title: Translation.tr("Curves (bezier / spring)")
                    GroupedList {
                        compact: true;
                        visible: page.settingsShow("effects")
                        ColumnLayout {
                            visible: page.settingsShow("effects");
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
                                visible: page.settingsShow("effects");
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
                                    visible: page.settingsShow("effects");
                                    objectName: "HyprlandSettings.add-4";
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
                            StyledText {
                                visible: page.settingsShow("effects"); Layout.fillWidth: true; wrapMode: Text.Wrap; font.pixelSize: Appearance.font.pixelSize.smaller; color: Appearance.colors.colSubtext; text: Translation.tr("Bezier: points {x0,y0} {x1,y1} (0-1+) — Spring: mass 1, stiffness 50-500, damping 5-50. Example presets imported from hyprland.lua: easeOutQuint, easy (spring).") }
                            RowLayout {
                                visible: page.settingsShow("effects")
                                RippleButtonWithIcon {
                                    visible: page.settingsShow("effects");
                                    objectName: "HyprlandSettings.load-preset-into-custom";
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
                                    visible: page.settingsShow("effects");
                                    objectName: "HyprlandSettings.apply-custom";
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
                    visible: page.settingsShow("effects");
                    title: Translation.tr("Animation Tree (inherits parent if unset)")
                    GroupedList {
                        compact: true;
                        visible: page.settingsShow("effects")
                        ColumnLayout {
                            visible: page.settingsShow("effects");
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
                                            onToggled: {
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
                                visible: page.settingsShow("effects");
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
                                    visible: page.settingsShow("effects");
                                    objectName: "HyprlandSettings.add-leaf";
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
                            StyledText {
                                visible: page.settingsShow("effects"); Layout.fillWidth: true; wrapMode: Text.Wrap; font.pixelSize: Appearance.font.pixelSize.smaller; color: Appearance.colors.colSubtext; text: Translation.tr("Speed: 1ds=100ms. Styles: windows/layers → slide/popin/gnomed, workspaces → slide/slidevert/fade/slidefade, borderangle → once/loop, popin needs % e.g. popin 80%. Leave empty to inherit parent.") }
                        }
                    }
                }
            }

            NoticeBox {
                visible: page.settingsShow("effects");
                Layout.fillWidth: true
                Layout.topMargin: 15
                text: Translation.tr("New installs load this file automatically. If nothing changes when you pick a preset, your hyprland.lua predates that and needs this line added manually:") + '\n\nrequire("hyprland/shellOverrides/animations")'

                Item { Layout.fillWidth: true }

                RippleButtonWithIcon {
                    visible: page.settingsShow("effects");
                    objectName: "HyprlandSettings.animations";
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
