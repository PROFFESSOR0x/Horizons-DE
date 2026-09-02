import QtQuick
import QtQuick.Layouts
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets

// Hyprglass — Apple-style Liquid Glass for Hyprland
// Mirrors hyprglass/src/PluginConfig.hpp + BuiltInPresets.hpp
// All values are live-synced to Hyprland via Hyprglass service -> HyprlandConfig.set()
ContentPage {
    id: page
    forceWidth: true

    readonly property var h: Config.options.hyprglass

    function tintDisplay(v) {
        if (!v || v === "" || v === "-1") return Translation.tr("Auto (theme default)")
        return v
    }

    ColumnLayout {
        Layout.fillWidth: true
        Layout.fillHeight: true
        spacing: 20

        // ── Enable + Theme + Preset ────────────────────────────────────
        ContentSection {
            icon: "water_drop"
            shape: MaterialShape.Shape.Cookie7Sided
            title: Translation.tr("Hyprglass — Liquid Glass")
            GroupedList {
                ConfigSwitch {
                    buttonIcon: "water_drop"
                    text: Translation.tr("Enable Hyprglass (compositor glass)")
                    checked: page.h ? page.h.enabled : false
                    onCheckedChanged: {
                        page.h.enabled = checked
                        // Keep legacy shell glass in sync so QML transparency matches
                        Config.options.appearance.glass.enable = checked
                        Hyprglass.apply()
                    }
                }
                StyledText {
                    Layout.fillWidth: true
                    wrapMode: Text.Wrap
                    color: Appearance.colors.colSubtext
                    font.pixelSize: Appearance.font.pixelSize.small
                    text: Translation.tr("Requires hyprglass.so plugin. Install via: hyprpm add https://github.com/hyprnux/hyprglass && hyprpm enable hyprglass. Glass replaces Hyprland blur via noblur — manageWindowBlur handles it automatically.")
                }
                ConfigSwitch {
                    enabled: page.h ? page.h.enabled : false
                    buttonIcon: "blur_on"
                    text: Translation.tr("Auto manage window blur (noblur)")
                    checked: page.h ? page.h.manageWindowBlur : true
                    onCheckedChanged: { page.h.manageWindowBlur = checked; Hyprglass.apply() }
                }
                ConfigSelectionArray {
                    enabled: page.h ? page.h.enabled : false
                    icon: "dark_mode"
                    text: Translation.tr("Default theme")
                    currentValue: page.h ? page.h.defaultTheme : "dark"
                    onSelected: newValue => { page.h.defaultTheme = newValue; Hyprglass.apply() }
                    options: [
                        { displayName: Translation.tr("Dark"), icon: "dark_mode", value: "dark" },
                        { displayName: Translation.tr("Light"), icon: "light_mode", value: "light" }
                    ]
                }
                ConfigSelectionArray {
                    enabled: page.h ? page.h.enabled : false
                    icon: "palette"
                    text: Translation.tr("Default preset")
                    currentValue: page.h ? page.h.defaultPreset : "default"
                    onSelected: newValue => { page.h.defaultPreset = newValue; Hyprglass.apply() }
                    options: [
                        { displayName: Translation.tr("Default"), icon: "auto_awesome", value: "default" },
                        { displayName: Translation.tr("High Contrast"), icon: "contrast", value: "high_contrast" },
                        { displayName: Translation.tr("Subtle"), icon: "opacity", value: "subtle" },
                        { displayName: Translation.tr("Clear"), icon: "water", value: "clear" },
                        { displayName: Translation.tr("Glass"), icon: "glass_cup", value: "glass" }
                    ]
                }
            }
            ContentSubsection {
                title: Translation.tr("Quick presets")
                GroupedList {
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8
                        Repeater {
                            model: [
                                { label: "High Contrast", preset: "high_contrast", icon: "contrast" },
                                { label: "Subtle", preset: "subtle", icon: "opacity" },
                                { label: "Clear", preset: "clear", icon: "water" },
                                { label: "Glass", preset: "glass", icon: "glass_cup" }
                            ]
                            delegate: RippleButton {
                                Layout.fillWidth: true
                                colBackground: Appearance.colors.colLayer1
                                onClicked: { page.h.defaultPreset = modelData.preset; Hyprglass.apply() }
                                contentItem: ColumnLayout {
                                    spacing: 4
                                    anchors.centerIn: parent
                                    MaterialSymbol { text: modelData.icon; iconSize: 20; color: Appearance.colors.colOnLayer1 }
                                    StyledText { text: modelData.label; font.pixelSize: Appearance.font.pixelSize.small; color: Appearance.colors.colOnLayer1; Layout.alignment: Qt.AlignHCenter }
                                }
                            }
                        }
                    }
                    StyledText {
                        Layout.fillWidth: true
                        wrapMode: Text.Wrap
                        color: Appearance.colors.colSubtext
                        font.pixelSize: Appearance.font.pixelSize.small
                        text: Translation.tr("Presets are defined in hyprglass/src/BuiltInPresets.hpp — high_contrast: punchy, subtle: minimal, clear: transparent plate, glass: solid block + chromatic aberration.")
                    }
                }
            }
        }

        // ── Core glass geometry ────────────────────────────────────────
        ContentSection {
            icon: "blur_on"
            shape: MaterialShape.Shape.SoftBurst
            title: Translation.tr("Blur & Geometry")
            GroupedList {
                ConfigSlider {
                    enabled: page.h ? page.h.enabled : false
                    text: Translation.tr("Blur strength")
                    buttonIcon: "blur_on"
                    value: (page.h ? page.h.blurStrength : 2.0) * 20
                    from: 0; to: 100
                    onValueChanged: { if (page.h) { page.h.blurStrength = value / 20; Hyprglass.apply() } }
                }
                ConfigSpinBox {
                    enabled: page.h ? page.h.enabled : false
                    icon: "filter"
                    text: Translation.tr("Blur iterations (1-5)")
                    value: page.h ? page.h.blurIterations : 3
                    from: 1; to: 5; stepSize: 1
                    onValueChanged: { page.h.blurIterations = value; Hyprglass.apply() }
                }
                ConfigSlider {
                    enabled: page.h ? page.h.enabled : false
                    text: Translation.tr("Glass opacity")
                    buttonIcon: "opacity"
                    value: (page.h ? page.h.glassOpacity : 1.0) * 100
                    from: 0; to: 100
                    onValueChanged: { if (page.h) { page.h.glassOpacity = value / 100; Config.options.appearance.glass.opacity = value / 100; Hyprglass.apply() } }
                }
                ConfigSlider {
                    enabled: page.h ? page.h.enabled : false
                    text: Translation.tr("Edge thickness")
                    buttonIcon: "border_outer"
                    value: (page.h ? page.h.edgeThickness : 0.06) * 1000
                    from: 0; to: 150
                    onValueChanged: { if (page.h) { page.h.edgeThickness = value / 1000; Hyprglass.apply() } }
                }
                ConfigSlider {
                    enabled: page.h ? page.h.enabled : false
                    text: Translation.tr("Refraction strength")
                    buttonIcon: "water"
                    value: (page.h ? page.h.refractionStrength : 0.6) * 100
                    from: 0; to: 100
                    onValueChanged: { if (page.h) { page.h.refractionStrength = value / 100; Hyprglass.apply() } }
                }
                ConfigSlider {
                    enabled: page.h ? page.h.enabled : false
                    text: Translation.tr("Chromatic aberration")
                    buttonIcon: "palette"
                    value: (page.h ? page.h.chromaticAberration : 0.5) * 100
                    from: 0; to: 100
                    onValueChanged: { if (page.h) { page.h.chromaticAberration = value / 100; Hyprglass.apply() } }
                }
                ConfigSlider {
                    enabled: page.h ? page.h.enabled : false
                    text: Translation.tr("Lens distortion")
                    buttonIcon: "center_focus_strong"
                    value: (page.h ? page.h.lensDistortion : 0.5) * 100
                    from: 0; to: 100
                    onValueChanged: { if (page.h) { page.h.lensDistortion = value / 100; Hyprglass.apply() } }
                }
            }
        }

        // ── Highlights & Tint ──────────────────────────────────────────
        ContentSection {
            icon: "light_mode"
            shape: MaterialShape.Shape.Flower
            title: Translation.tr("Highlights & Tint")
            GroupedList {
                ConfigSlider {
                    enabled: page.h ? page.h.enabled : false
                    text: Translation.tr("Fresnel edge glow")
                    buttonIcon: "light_mode"
                    value: (page.h ? page.h.fresnelStrength : 0.6) * 100
                    from: 0; to: 100
                    onValueChanged: { if (page.h) { page.h.fresnelStrength = value / 100; Hyprglass.apply() } }
                }
                ConfigSlider {
                    enabled: page.h ? page.h.enabled : false
                    text: Translation.tr("Specular highlight")
                    buttonIcon: "flash_on"
                    value: (page.h ? page.h.specularStrength : 0.8) * 100
                    from: 0; to: 100
                    onValueChanged: { if (page.h) { page.h.specularStrength = value / 100; Hyprglass.apply() } }
                }
                ConfigTextArea {
                    enabled: page.h ? page.h.enabled : false
                    buttonIcon: "colorize"
                    text: Translation.tr("Tint color (hex 0xRRGGBBAA)")
                    value: page.h ? page.h.tintColor : "0x8899aa22"
                    placeholderText: "0x8899aa22"
                    onValueChanged: { if (page.h) { page.h.tintColor = value; Hyprglass.apply() } }
                }
                StyledText {
                    Layout.fillWidth: true
                    wrapMode: Text.Wrap
                    color: Appearance.colors.colSubtext
                    font.pixelSize: Appearance.font.pixelSize.small
                    text: Translation.tr("Alpha is tint strength (last 2 hex digits). Example: 0x02142aa9 strong dark blue. Increase alpha for more tint.")
                }
            }
        }

        // ── Frosted tint (tone mapping) ────────────────────────────────
        ContentSection {
            icon: "tonality"
            shape: MaterialShape.Shape.Bun
            title: Translation.tr("Frosted Tint — Tone Mapping")
            GroupedList {
                StyledText {
                    Layout.fillWidth: true
                    wrapMode: Text.Wrap
                    color: Appearance.colors.colSubtext
                    font.pixelSize: Appearance.font.pixelSize.small
                    text: Translation.tr("Set to -1 for theme defaults (dark: brightness 0.82, light: 1.12 etc. See BuiltInPresets.hpp). Values are per-theme tone mapping applied to blurred background.")
                }
                ConfigSlider {
                    enabled: page.h ? page.h.enabled : false
                    text: Translation.tr("Brightness")
                    buttonIcon: "brightness_6"
                    value: (page.h && page.h.brightness >= 0 ? page.h.brightness : 0.82) * 100
                    from: 0; to: 200
                    onValueChanged: { if (page.h) { page.h.brightness = value / 100; Hyprglass.apply() } }
                }
                ConfigSlider {
                    enabled: page.h ? page.h.enabled : false
                    text: Translation.tr("Contrast")
                    buttonIcon: "contrast"
                    value: (page.h && page.h.contrast >= 0 ? page.h.contrast : 0.90) * 100
                    from: 0; to: 200
                    onValueChanged: { if (page.h) { page.h.contrast = value / 100; Hyprglass.apply() } }
                }
                ConfigSlider {
                    enabled: page.h ? page.h.enabled : false
                    text: Translation.tr("Saturation")
                    buttonIcon: "palette"
                    value: (page.h && page.h.saturation >= 0 ? page.h.saturation : 0.80) * 100
                    from: 0; to: 100
                    onValueChanged: { if (page.h) { page.h.saturation = value / 100; Hyprglass.apply() } }
                }
                ConfigSlider {
                    enabled: page.h ? page.h.enabled : false
                    text: Translation.tr("Vibrancy")
                    buttonIcon: "auto_awesome"
                    value: (page.h && page.h.vibrancy >= 0 ? page.h.vibrancy : 0.15) * 100
                    from: 0; to: 100
                    onValueChanged: { if (page.h) { page.h.vibrancy = value / 100; Hyprglass.apply() } }
                }
                ConfigSlider {
                    enabled: page.h ? page.h.enabled : false
                    text: Translation.tr("Vibrancy darkness")
                    buttonIcon: "dark_mode"
                    value: (page.h && page.h.vibrancyDarkness >= 0 ? page.h.vibrancyDarkness : 0.0) * 100
                    from: 0; to: 100
                    onValueChanged: { if (page.h) { page.h.vibrancyDarkness = value / 100; Hyprglass.apply() } }
                }
                ConfigSlider {
                    enabled: page.h ? page.h.enabled : false
                    text: Translation.tr("Adaptive dim")
                    buttonIcon: "brightness_4"
                    value: (page.h && page.h.adaptiveDim >= 0 ? page.h.adaptiveDim : 0.4) * 100
                    from: 0; to: 100
                    onValueChanged: { if (page.h) { page.h.adaptiveDim = value / 100; Hyprglass.apply() } }
                }
                ConfigSlider {
                    enabled: page.h ? page.h.enabled : false
                    text: Translation.tr("Adaptive boost")
                    buttonIcon: "lightbulb"
                    value: (page.h && page.h.adaptiveBoost >= 0 ? page.h.adaptiveBoost : 0.0) * 100
                    from: 0; to: 100
                    onValueChanged: { if (page.h) { page.h.adaptiveBoost = value / 100; Hyprglass.apply() } }
                }
                ConfigRow {
                    uniform: true
                    RippleButton {
                        Layout.fillWidth: true
                        colBackground: Appearance.colors.colLayer2
                        enabled: page.h ? page.h.enabled : false
                        onClicked: {
                            page.h.brightness = -1; page.h.contrast = -1; page.h.saturation = -1
                            page.h.vibrancy = -1; page.h.vibrancyDarkness = -1
                            page.h.adaptiveDim = -1; page.h.adaptiveBoost = -1
                            Hyprglass.apply()
                        }
                        contentItem: StyledText { text: Translation.tr("Reset to theme defaults (-1)"); color: Appearance.colors.colOnLayer2 }
                    }
                }
            }
            ContentSubsection {
                title: Translation.tr("Per-theme overrides (optional)")
                GroupedList {
                    StyledText {
                        Layout.fillWidth: true
                        wrapMode: Text.Wrap
                        color: Appearance.colors.colSubtext
                        font.pixelSize: Appearance.font.pixelSize.small
                        text: Translation.tr("Leave at -1 to inherit global value. Set explicitly to override per dark/light theme (plugin:hyprglass:dark:* / light:*).")
                    }
                    ConfigSlider {
                        text: Translation.tr("Dark brightness override")
                        buttonIcon: "dark_mode"
                        enabled: page.h ? page.h.enabled : false
                        value: (page.h && page.h.dark && page.h.dark.brightness >= 0 ? page.h.dark.brightness : 0.82) * 100
                        from: 0; to: 200
                        onValueChanged: { if (page.h && page.h.dark) { page.h.dark.brightness = value / 100; Hyprglass.apply() } }
                    }
                    ConfigSlider {
                        text: Translation.tr("Light brightness override")
                        buttonIcon: "light_mode"
                        enabled: page.h ? page.h.enabled : false
                        value: (page.h && page.h.light && page.h.light.brightness >= 0 ? page.h.light.brightness : 1.12) * 100
                        from: 0; to: 200
                        onValueChanged: { if (page.h && page.h.light) { page.h.light.brightness = value / 100; Hyprglass.apply() } }
                    }
                }
            }
        }

        // ── Layer surfaces ─────────────────────────────────────────────
        ContentSection {
            icon: "layers"
            shape: MaterialShape.Shape.Gem
            title: Translation.tr("Layer Surfaces (bars, docks, widgets)")
            GroupedList {
                ConfigSwitch {
                    buttonIcon: "layers"
                    text: Translation.tr("Enable glass on layer surfaces")
                    checked: page.h && page.h.layers ? page.h.layers.enabled : false
                    onCheckedChanged: { if (page.h && page.h.layers) { page.h.layers.enabled = checked; Hyprglass.apply() } }
                }
                StyledText {
                    Layout.fillWidth: true
                    wrapMode: Text.Wrap
                    color: Appearance.colors.colSubtext
                    font.pixelSize: Appearance.font.pixelSize.small
                    text: Translation.tr("Disabled by default (hyprglass README). Layer glass uses alpha mask — partially transparent content triggers glass. Fully transparent ignored. Shadows count as visible content — use mask_threshold.")
                }
                ConfigTextArea {
                    enabled: page.h && page.h.layers ? page.h.layers.enabled : false
                    buttonIcon: "filter_list"
                    text: Translation.tr("Whitelist namespaces (comma-separated, empty = all)")
                    value: page.h && page.h.layers ? page.h.layers.namespaces : ""
                    placeholderText: "waybar, swaync, quickshell:bezel"
                    onValueChanged: { if (page.h && page.h.layers) { page.h.layers.namespaces = value; Hyprglass.apply() } }
                }
                ConfigTextArea {
                    enabled: page.h && page.h.layers ? page.h.layers.enabled : false
                    buttonIcon: "block"
                    text: Translation.tr("Exclude namespaces (blacklist)")
                    value: page.h && page.h.layers ? page.h.layers.excludeNamespaces : ""
                    placeholderText: "debug-panel"
                    onValueChanged: { if (page.h && page.h.layers) { page.h.layers.excludeNamespaces = value; Hyprglass.apply() } }
                }
                ConfigTextArea {
                    enabled: page.h && page.h.layers ? page.h.layers.enabled : false
                    buttonIcon: "palette"
                    text: Translation.tr("Layer preset override")
                    value: page.h && page.h.layers ? page.h.layers.preset : ""
                    placeholderText: "subtle"
                    onValueChanged: { if (page.h && page.h.layers) { page.h.layers.preset = value; Hyprglass.apply() } }
                }
                ConfigTextArea {
                    enabled: page.h && page.h.layers ? page.h.layers.enabled : false
                    buttonIcon: "tune"
                    text: Translation.tr("Per-namespace presets (ns:preset, ...)")
                    value: page.h && page.h.layers ? page.h.layers.namespacePresets : ""
                    placeholderText: "quickshell:bezel:ui, waybar:subtle"
                    onValueChanged: { if (page.h && page.h.layers) { page.h.layers.namespacePresets = value; Hyprglass.apply() } }
                }
                ConfigTextArea {
                    enabled: page.h && page.h.layers ? page.h.layers.enabled : false
                    buttonIcon: "opacity"
                    text: Translation.tr("Per-namespace mask thresholds (ns=value, ...)")
                    value: page.h && page.h.layers ? page.h.layers.namespaceMaskThresholds : ""
                    placeholderText: "waybar=0.05, quickshell:bezel=0.3"
                    onValueChanged: { if (page.h && page.h.layers) { page.h.layers.namespaceMaskThresholds = value; Hyprglass.apply() } }
                }
            }
        }

        // ── Per-window overrides info ──────────────────────────────────
        ContentSection {
            icon: "select_window"
            shape: MaterialShape.Shape.ClamShell
            title: Translation.tr("Per-Window Overrides (tags)")
            GroupedList {
                StyledText {
                    Layout.fillWidth: true
                    wrapMode: Text.Wrap
                    color: Appearance.colors.colSubtext
                    font.pixelSize: Appearance.font.pixelSize.small
                    text: Translation.tr("Control per window via window tags/rules:")
                }
                StyledText {
                    Layout.fillWidth: true
                    wrapMode: Text.Wrap
                    color: Appearance.colors.colSubtext
                    font.pixelSize: Appearance.font.pixelSize.small
                    text: "• hyprglass_disabled / hyprglass_enabled (tag)\n• hyprglass_theme_dark / hyprglass_theme_light (tag)\n• hyprglass_preset_<name> (e.g. tag +hyprglass_preset_subtle)"
                }
                StyledText {
                    Layout.fillWidth: true
                    wrapMode: Text.Wrap
                    color: Appearance.colors.colSubtext
                    font.pixelSize: Appearance.font.pixelSize.small
                    text: Translation.tr("Example Lua: hl.window_rule({match={class=\"mpv\"}, tag=\"+hyprglass_disabled\"})")
                }
                ConfigRow {
                    uniform: true
                    RippleButton {
                        Layout.fillWidth: true
                        colBackground: Appearance.colors.colLayer2
                        onClicked: Quickshell.execDetached(["bash", "-c", "hyprctl dispatch tagwindow +hyprglass_disabled; echo tagged"])
                        contentItem: StyledText { text: Translation.tr("Tag focused window: disabled"); color: Appearance.colors.colOnLayer2 }
                    }
                    RippleButton {
                        Layout.fillWidth: true
                        colBackground: Appearance.colors.colPrimary
                        onClicked: Quickshell.execDetached(["bash", "-c", "hyprctl dispatch tagwindow +hyprglass_enabled; echo tagged"])
                        contentItem: StyledText { text: Translation.tr("Tag focused: enabled"); color: Appearance.colors.colOnPrimary }
                    }
                }
            }
        }

        // ── Troubleshooting ────────────────────────────────────────────
        ContentSection {
            icon: "help"
            shape: MaterialShape.Shape.Pentagon
            title: Translation.tr("Troubleshooting")
            GroupedList {
                StyledText {
                    Layout.fillWidth: true
                    wrapMode: Text.Wrap
                    color: Appearance.colors.colSubtext
                    font.pixelSize: Appearance.font.pixelSize.small
                    text: Translation.tr("Plugin auto-enables shadows (required for background sampling). Glass replaces Hyprland blur via noblur — set manageWindowBlur = 0 to manage manually. Layer hook is version-sensitive (renderLayer signature).")
                }
                StyledText {
                    Layout.fillWidth: true
                    wrapMode: Text.Wrap
                    color: Appearance.colors.colSubtext
                    font.pixelSize: Appearance.font.pixelSize.small
                    text: Translation.tr("Version mismatch (hyprland-git): hyprglass compares ABI suffix _aq_…_hu_…. If mismatch persists, rebuild against running headers or set HYPRGLASS_SKIP_VERSION_CHECK=1 (unsupported).")
                }
                ConfigRow {
                    uniform: true
                    RippleButton {
                        Layout.fillWidth: true
                        colBackground: Appearance.colors.colLayer2
                        onClicked: Quickshell.execDetached(["bash", "-c", "hyprctl plugin list | grep -q hyprglass && hyprctl plugin unload hyprglass.so; hyprpm enable hyprglass 2>/dev/null; echo done"])
                        contentItem: StyledText { text: Translation.tr("Reload plugin"); color: Appearance.colors.colOnLayer2 }
                    }
                    RippleButton {
                        Layout.fillWidth: true
                        colBackground: Appearance.colors.colLayer2
                        onClicked: Quickshell.execDetached(["bash", "-c", "hyprctl -j getoption plugin:hyprglass:enabled | head -20; echo ---; ls -lh ~/.config/hypr/hyprland/shellOverrides/hyprglass.lua 2>/dev/null; cat ~/.config/hypr/hyprland/shellOverrides/main.lua 2>/dev/null | grep hyprglass | head -20"])
                        contentItem: StyledText { text: Translation.tr("Debug dump"); color: Appearance.colors.colOnLayer2 }
                    }
                }
            }
        }
    }
}
