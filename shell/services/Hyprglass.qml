pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import qs.modules.common
import qs.modules.common.functions

// Hyprglass — bridges Config.options.appearance.hyprglass to Hyprland plugin:hyprglass:*
// Mirrors hyprglass/src/PluginConfig.hpp (SPluginConfig + SOverridableConfig)
// and hyprglass/src/BuiltInPresets.hpp.
// Uses HyprlandConfig.set() which edits shellOverrides/main.lua via hl.config().
// For tint_color, hex strings are converted to decimal so hl.config receives an int.
Singleton {
    id: root

    // Plugin options are only valid after Hyprland has loaded hyprglass.so.
    // Keeping this state here lets a disabled or unavailable plugin leave no
    // invalid `plugin:hyprglass:*` entries behind in shellOverrides/main.lua.
    property bool pluginLoaded: false

    // ── Public helpers ────────────────────────────────────────────────────

    // Built-in presets exposed to the UI (matches BuiltInPresets::getAll)
    readonly property var builtInPresets: ["default", "high_contrast", "subtle", "clear", "glass"]
    readonly property var builtInPresetDetails: ({
        "high_contrast": { name: "high_contrast", label: "High Contrast", desc: "Punchy colors, strong tinting" },
        "subtle":        { name: "subtle",        label: "Subtle",        desc: "Minimal blur, reduced refraction" },
        "clear":         { name: "clear",         label: "Clear",         desc: "Transparent rounded border plate" },
        "glass":         { name: "glass",         label: "Glass",         desc: "Solid glass block, strong chromatic aberration" }
    })

    function isValidTheme(t) { return t === "dark" || t === "light" }
    function isValidPreset(p) { return root.builtInPresets.includes(p) || p === "default" }

    // Convert "0xAARRGGBB" or "0xRRGGBBAA" hex -> decimal string for hl.config int
    function tintToDecimal(hexStr) {
        if (!hexStr || hexStr === "") return "[[EMPTY]]"
        let s = String(hexStr).trim()
        if (s.startsWith("0x") || s.startsWith("0X")) {
            let v = parseInt(s, 16)
            return isNaN(v) ? "[[EMPTY]]" : String(v >>> 0)
        }
        let v = parseInt(s, 10)
        return isNaN(v) ? "[[EMPTY]]" : String(v)
    }

    // Sentinel-aware: -1 means "inherit / use theme default" -> reset the key
    function floatOrReset(key, value) {
        if (value === undefined || value === null || value < 0) return "[[EMPTY]]"
        return String(value)
    }
    function intOrReset(key, value) {
        if (value === undefined || value === null || value < 0) return "[[EMPTY]]"
        return String(Math.round(value))
    }
    function tintOrReset(value) {
        if (!value || value === "" || value === "-1") return "[[EMPTY]]"
        return root.tintToDecimal(value)
    }

    // Apply all current Config.options.appearance.hyprglass values to Hyprland.
    // Called on startup and whenever the config changes (debounced).
    function apply() {
        if (!Config.ready) return
        const h = Config.options.appearance.hyprglass
        if (!h) return

        let entries = {}

        // ── Global ───────────────────────────────────────────────────────
        entries["plugin:hyprglass:enabled"] = h.enabled ? 1 : 0
        entries["plugin:hyprglass:manage_window_blur"] = h.manageWindowBlur ? 1 : 0
        entries["plugin:hyprglass:default_theme"] = h.defaultTheme || "dark"
        entries["plugin:hyprglass:default_preset"] = h.defaultPreset || "default"

        // Global overridables
        entries["plugin:hyprglass:blur_strength"]        = root.floatOrReset("", h.blurStrength)
        entries["plugin:hyprglass:blur_iterations"]      = root.intOrReset("", h.blurIterations)
        entries["plugin:hyprglass:refraction_strength"]  = root.floatOrReset("", h.refractionStrength)
        entries["plugin:hyprglass:chromatic_aberration"] = root.floatOrReset("", h.chromaticAberration)
        entries["plugin:hyprglass:fresnel_strength"]     = root.floatOrReset("", h.fresnelStrength)
        entries["plugin:hyprglass:specular_strength"]    = root.floatOrReset("", h.specularStrength)
        entries["plugin:hyprglass:glass_opacity"]        = root.floatOrReset("", h.glassOpacity)
        entries["plugin:hyprglass:edge_thickness"]       = root.floatOrReset("", h.edgeThickness)
        entries["plugin:hyprglass:tint_color"]           = root.tintOrReset(h.tintColor)
        entries["plugin:hyprglass:lens_distortion"]      = root.floatOrReset("", h.lensDistortion)
        entries["plugin:hyprglass:brightness"]           = root.floatOrReset("", h.brightness)
        entries["plugin:hyprglass:contrast"]             = root.floatOrReset("", h.contrast)
        entries["plugin:hyprglass:saturation"]           = root.floatOrReset("", h.saturation)
        entries["plugin:hyprglass:vibrancy"]             = root.floatOrReset("", h.vibrancy)
        entries["plugin:hyprglass:vibrancy_darkness"]    = root.floatOrReset("", h.vibrancyDarkness)
        entries["plugin:hyprglass:adaptive_dim"]         = root.floatOrReset("", h.adaptiveDim)
        entries["plugin:hyprglass:adaptive_boost"]       = root.floatOrReset("", h.adaptiveBoost)

        // Dark theme overrides
        if (h.dark) {
            entries["plugin:hyprglass:dark:blur_strength"]        = root.floatOrReset("", h.dark.blurStrength)
            entries["plugin:hyprglass:dark:blur_iterations"]      = root.intOrReset("", h.dark.blurIterations)
            entries["plugin:hyprglass:dark:refraction_strength"]  = root.floatOrReset("", h.dark.refractionStrength)
            entries["plugin:hyprglass:dark:chromatic_aberration"] = root.floatOrReset("", h.dark.chromaticAberration)
            entries["plugin:hyprglass:dark:fresnel_strength"]     = root.floatOrReset("", h.dark.fresnelStrength)
            entries["plugin:hyprglass:dark:specular_strength"]    = root.floatOrReset("", h.dark.specularStrength)
            entries["plugin:hyprglass:dark:glass_opacity"]        = root.floatOrReset("", h.dark.glassOpacity)
            entries["plugin:hyprglass:dark:edge_thickness"]       = root.floatOrReset("", h.dark.edgeThickness)
            entries["plugin:hyprglass:dark:tint_color"]           = root.tintOrReset(h.dark.tintColor)
            entries["plugin:hyprglass:dark:lens_distortion"]      = root.floatOrReset("", h.dark.lensDistortion)
            entries["plugin:hyprglass:dark:brightness"]           = root.floatOrReset("", h.dark.brightness)
            entries["plugin:hyprglass:dark:contrast"]             = root.floatOrReset("", h.dark.contrast)
            entries["plugin:hyprglass:dark:saturation"]           = root.floatOrReset("", h.dark.saturation)
            entries["plugin:hyprglass:dark:vibrancy"]             = root.floatOrReset("", h.dark.vibrancy)
            entries["plugin:hyprglass:dark:vibrancy_darkness"]    = root.floatOrReset("", h.dark.vibrancyDarkness)
            entries["plugin:hyprglass:dark:adaptive_dim"]         = root.floatOrReset("", h.dark.adaptiveDim)
            entries["plugin:hyprglass:dark:adaptive_boost"]       = root.floatOrReset("", h.dark.adaptiveBoost)
        }

        // Light theme overrides
        if (h.light) {
            entries["plugin:hyprglass:light:blur_strength"]        = root.floatOrReset("", h.light.blurStrength)
            entries["plugin:hyprglass:light:blur_iterations"]      = root.intOrReset("", h.light.blurIterations)
            entries["plugin:hyprglass:light:refraction_strength"]  = root.floatOrReset("", h.light.refractionStrength)
            entries["plugin:hyprglass:light:chromatic_aberration"] = root.floatOrReset("", h.light.chromaticAberration)
            entries["plugin:hyprglass:light:fresnel_strength"]     = root.floatOrReset("", h.light.fresnelStrength)
            entries["plugin:hyprglass:light:specular_strength"]    = root.floatOrReset("", h.light.specularStrength)
            entries["plugin:hyprglass:light:glass_opacity"]        = root.floatOrReset("", h.light.glassOpacity)
            entries["plugin:hyprglass:light:edge_thickness"]       = root.floatOrReset("", h.light.edgeThickness)
            entries["plugin:hyprglass:light:tint_color"]           = root.tintOrReset(h.light.tintColor)
            entries["plugin:hyprglass:light:lens_distortion"]      = root.floatOrReset("", h.light.lensDistortion)
            entries["plugin:hyprglass:light:brightness"]           = root.floatOrReset("", h.light.brightness)
            entries["plugin:hyprglass:light:contrast"]             = root.floatOrReset("", h.light.contrast)
            entries["plugin:hyprglass:light:saturation"]           = root.floatOrReset("", h.light.saturation)
            entries["plugin:hyprglass:light:vibrancy"]             = root.floatOrReset("", h.light.vibrancy)
            entries["plugin:hyprglass:light:vibrancy_darkness"]    = root.floatOrReset("", h.light.vibrancyDarkness)
            entries["plugin:hyprglass:light:adaptive_dim"]         = root.floatOrReset("", h.light.adaptiveDim)
            entries["plugin:hyprglass:light:adaptive_boost"]       = root.floatOrReset("", h.light.adaptiveBoost)
        }

        // Layers
        if (h.layers) {
            entries["plugin:hyprglass:layers:enabled"]                  = h.layers.enabled ? 1 : 0
            entries["plugin:hyprglass:layers:namespaces"]               = h.layers.namespaces || "[[EMPTY]]"
            entries["plugin:hyprglass:layers:exclude_namespaces"]       = h.layers.excludeNamespaces || "[[EMPTY]]"
            entries["plugin:hyprglass:layers:preset"]                   = h.layers.preset || "[[EMPTY]]"
            entries["plugin:hyprglass:layers:namespace_presets"]        = h.layers.namespacePresets || "[[EMPTY]]"
            entries["plugin:hyprglass:layers:namespace_mask_thresholds"]= h.layers.namespaceMaskThresholds || "[[EMPTY]]"
        }

        // Hyprland rejects plugin keys while the plugin is absent. More
        // importantly, a disabled Hyprglass must not leave stale keys that
        // make the whole Hyprland config report errors on every reload.
        if (!h.enabled) {
            HyprlandConfig.resetMany(Object.keys(entries))
            root.writePresetsFile()
            return
        }

        // Loading is asynchronous. Wait until it succeeds before persisting
        // plugin-only keys, so enabling Hyprglass is clean even on first use.
        if (!root.pluginLoaded) {
            root.ensurePluginLoaded()
            return
        }

        HyprlandConfig.setMany(entries)
        // Presets that use keyword syntax are handled via hyprglassPresetsFile below
        root.writePresetsFile()
        if (h.enabled) root.ensurePluginLoaded()
    }

    // For custom presets: generate Lua that calls hl.plugin.hyprglass.preset()
    // This file is loaded via `require("hyprland.shellOverrides.hyprglass")` from main.lua
    readonly property string presetsFilePath: FileUtils.trimFileProtocol(`${Directories.config}/hypr/hyprland/shellOverrides/hyprglass.lua`)

    function writePresetsFile() {
        const h = Config.options.appearance.hyprglass
        if (!h || !h.presets || h.presets.length === 0) {
            presetsFileView.setText("-- Hyprglass custom presets — none configured\n")
            return
        }
        let lua = "-- Hyprglass custom presets — auto-generated by Hyprglass service\n"
        lua += "-- Do not edit manually; managed via Settings > Hyprglass\n"
        lua += "if hl and hl.plugin and hl.plugin.hyprglass then\n"
        lua += "  local hg = hl.plugin.hyprglass\n"
        for (let p of h.presets) {
            if (!p || !p.name) continue
            lua += `  hg.preset("${p.name}", {\n`
            if (p.inherits) lua += `    inherits = "${p.inherits}",\n`
            if (p.shared) {
                for (let k in p.shared) {
                    let v = p.shared[k]
                    if (v !== undefined && v !== null && v !== -1 && v !== "") {
                        if (k === "tint_color") lua += `    ${k} = ${root.tintToDecimal(v)},\n`
                        else lua += `    ${k} = ${v},\n`
                    }
                }
            }
            if (p.dark && Object.keys(p.dark).length > 0) {
                lua += "    dark = {\n"
                for (let k in p.dark) {
                    let v = p.dark[k]
                    if (v !== undefined && v !== null && v !== -1 && v !== "") {
                        if (k === "tint_color") lua += `      ${k} = ${root.tintToDecimal(v)},\n`
                        else lua += `      ${k} = ${v},\n`
                    }
                }
                lua += "    },\n"
            }
            if (p.light && Object.keys(p.light).length > 0) {
                lua += "    light = {\n"
                for (let k in p.light) {
                    let v = p.light[k]
                    if (v !== undefined && v !== null && v !== -1 && v !== "") {
                        if (k === "tint_color") lua += `      ${k} = ${root.tintToDecimal(v)},\n`
                        else lua += `      ${k} = ${v},\n`
                    }
                }
                lua += "    },\n"
            }
            lua += "  })\n"
        }
        lua += "end\n"
        presetsFileView.setText(lua)
    }

    // Sync legacy appearance.glass -> hyprglass (one-way, on load)
    function syncLegacyGlass() {
        const g = Config.options.appearance?.glass
        const h = Config.options.appearance.hyprglass
        if (!g || !h) return
        // Only sync if hyprglass hasn't been explicitly configured yet
        // (detect by checking if hyprglass.enabled was never set by user)
        // For now, whenever appearance.glass.enable changes, mirror to hyprglass
        if (g.enable !== undefined && h.enabled !== g.enable) {
            // Don't overwrite if hyprglass was already toggled independently;
            // this is handled via watcher below — initial sync only.
        }
    }

    // ── Wiring ────────────────────────────────────────────────────────────

    FileView {
        id: presetsFileView
        path: root.presetsFilePath
        watchChanges: false
        blockLoading: true
    }

    // Debounce rapid config changes (slider drags)
    Timer {
        id: applyTimer
        interval: 180
        repeat: false
        onTriggered: root.apply()
    }

    // Watch for any hyprglass config change
    Connections {
        target: Config
        function onReadyChanged() { if (Config.ready) applyTimer.restart() }
    }

    // Also watch appearance.glass as legacy alias -> sync to hyprglass
    Connections {
        target: Config.options.appearance?.glass ?? null
        function onEnableChanged() {
            if (!Config.ready) return
            const g = Config.options.appearance.glass
            const h = Config.options.appearance.hyprglass
            if (h && g.enable !== h.enabled) {
                h.enabled = g.enable
                applyTimer.restart()
            }
        }
        function onOpacityChanged() {
            if (!Config.ready) return
            const g = Config.options.appearance.glass
            const h = Config.options.appearance.hyprglass
            if (h && Math.abs(g.opacity - h.glassOpacity) > 0.001) {
                h.glassOpacity = g.opacity
                applyTimer.restart()
            }
        }
    }

    // ── Auto dark/light theme sync ──────────────────────────────────────
    // Opt-in (hyprglass.autoThemeSync): pushes plugin:hyprglass:default_theme
    // whenever the shell's own system theme (Appearance.m3colors.darkmode)
    // flips, so users don't have to toggle "Default theme" by hand. Additive
    // on top of the existing manual defaultTheme setting — never runs unless
    // the user has explicitly turned the toggle on.
    function syncThemeFromSystem() {
        if (!Config.ready) return
        const h = Config.options.appearance.hyprglass
        if (!h || !h.autoThemeSync) return
        const theme = Appearance.m3colors.darkmode ? "dark" : "light"
        if (h.defaultTheme !== theme) {
            h.defaultTheme = theme
            applyTimer.restart()
        }
    }

    Connections {
        target: Appearance.m3colors
        function onDarkmodeChanged() { root.syncThemeFromSystem() }
    }

    // Auto-load hyprglass plugin if enabled but not yet loaded
    function ensurePluginLoaded() {
        const h = Config.options.appearance.hyprglass
        if (!h || !h.enabled || root.pluginLoaded || pluginLoader.running) return
        // Try hyprpm first, fall back to common manual paths
        pluginLoader.running = true
    }

    Process {
        id: pluginLoader
        running: false
        command: ["bash", "-c", `
            if hyprctl plugin list 2>/dev/null | grep -q hyprglass; then echo __horizons_hyprglass_loaded__; exit 0; fi
            hyprpm enable hyprglass 2>/dev/null || true
            for p in "$HOME/.config/hypr/hyprglass.so" "./hyprglass.so" "/usr/lib/hyprglass.so" "/usr/local/lib/hyprglass.so"; do
                [ -f "$p" ] && hyprctl plugin load "$p" 2>/dev/null || true
                if hyprctl plugin list 2>/dev/null | grep -q hyprglass; then echo __horizons_hyprglass_loaded__; exit 0; fi
            done
            # Also try building from bundled source if available
            if [ -f "$HOME/End4-PXpC/shell/plugins/hyprglass/hyprglass.so" ]; then hyprctl plugin load "$HOME/End4-PXpC/shell/plugins/hyprglass/hyprglass.so" 2>/dev/null || true; fi
            if [ -f "$HOME/.config/quickshell/horizons/plugins/hyprglass/hyprglass.so" ]; then hyprctl plugin load "$HOME/.config/quickshell/horizons/plugins/hyprglass/hyprglass.so" 2>/dev/null || true; fi
            hyprctl plugin list 2>/dev/null | grep -q hyprglass && echo __horizons_hyprglass_loaded__ || exit 1
        `]
        stdout: StdioCollector {
            onStreamFinished: root.pluginLoaded = text.includes("__horizons_hyprglass_loaded__")
        }
        onExited: {
            if (root.pluginLoaded)
                applyTimer.restart()
        }
    }

    Component.onCompleted: {
        if (Config.ready) {
            Qt.callLater(() => { root.syncThemeFromSystem(); root.apply(); root.ensurePluginLoaded() })
        } else {
            let once = false
            let conn = Config.onReadyChanged.connect(() => {
                if (Config.ready && !once) {
                    once = true
                    root.syncThemeFromSystem()
                    root.apply()
                    root.ensurePluginLoaded()
                }
            })
        }
    }
}
