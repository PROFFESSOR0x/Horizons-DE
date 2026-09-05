pragma Singleton
pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Io
import qs.modules.common.functions

Singleton {
    id: root
    property string filePath: Directories.shellConfigPath
    property alias options: configOptionsJsonAdapter
    property bool ready: false
    property int readWriteDelay: 50 // milliseconds
    property bool blockWrites: false

    function setNestedValue(nestedKey, value) {
        let keys = nestedKey.split(".");
        let obj = root.options;
        let parents = [obj];

        // Traverse and collect parent objects
        for (let i = 0; i < keys.length - 1; ++i) {
            if (!obj[keys[i]] || typeof obj[keys[i]] !== "object") {
                obj[keys[i]] = {};
            }
            obj = obj[keys[i]];
            parents.push(obj);
        }

        // Convert value to correct type using JSON.parse when safe
        let convertedValue = value;
        if (typeof value === "string") {
            let trimmed = value.trim();
            if (trimmed === "true" || trimmed === "false" || !isNaN(Number(trimmed))) {
                try {
                    convertedValue = JSON.parse(trimmed);
                } catch (e) {
                    convertedValue = value;
                }
            }
        }

        obj[keys[keys.length - 1]] = convertedValue;
    }

    // Back-compat shim for the "topIsland" -> "mesoBar" bar mode rename.
    // Runs once per config load (see FileView.onLoaded below). Old configs
    // saved before the rename have `bar.barMode === "topIsland"` and their
    // island appearance/layout under the (now-deprecated) `options.topIsland`
    // JsonObject; this remaps the mode string so the bar doesn't silently
    // fall back to "classic", and copies the old island settings into
    // `options.mesoBar` the first time only, so later user edits to mesoBar
    // are never overwritten by this function again.
    function migrateLegacyConfig() {
        const opts = root.options;
        const wasTopIsland = opts.bar.barMode === "topIsland";
        if (wasTopIsland) {
            opts.bar.barMode = "mesoBar";
        }
        if (wasTopIsland && !opts.mesoBar.legacyMigrated) {
            const legacy = opts.topIsland;
            opts.mesoBar.cornerStyle = legacy.cornerStyle;
            opts.mesoBar.borderless = legacy.borderless;
            opts.mesoBar.showFrame = legacy.showFrame;
            opts.mesoBar.frameThickness = legacy.frameThickness;
            opts.mesoBar.frameColor = legacy.frameColor;
            opts.mesoBar.followFrameColor = legacy.followFrameColor;
            opts.mesoBar.showBackground = legacy.showBackground;
            opts.mesoBar.verbose = legacy.verbose;
            opts.mesoBar.layouts.leftLayout = legacy.layouts.leftLayout;
            opts.mesoBar.layouts.middleLayout = legacy.layouts.middleLayout;
            opts.mesoBar.layouts.rightLayout = legacy.layouts.rightLayout;
            // A migrated-over config keeps the old content-hugging look by
            // default; the wider "percent" mode is opt-in for these users.
            opts.mesoBar.widthMode = "content";
            opts.mesoBar.legacyMigrated = true;
        }

        // Back-compat shim for the m3Island "scrollVolume" bool -> "scrollAction"
        // enum rename. Runs once; a config saved with scrollVolume disabled keeps
        // scroll disabled instead of silently regaining volume control.
        if (!opts.m3Island.scrollActionMigrated) {
            if (opts.m3Island.scrollVolume === false) {
                opts.m3Island.scrollAction = "none";
            }
            opts.m3Island.scrollActionMigrated = true;
        }

        // Added after the first M3 Island release. JsonObject does not write
        // newly declared defaults into an existing config automatically, so
        // persist this value once or the settings switch resets on reload.
        if (opts.m3Island.reserveScreenSpace === undefined) {
            opts.m3Island.reserveScreenSpace = false;
        }

        // Back-compat shim for the blur/transparency/glass exclusivity rule.
        // Before this, blur (hyprland.decoration.blur.enabled), transparency
        // (appearance.transparency.enable) and glass (appearance.glass.enable)
        // could all be turned on independently and silently conflict. Pick
        // whichever was already active, using the priority glass > transparency
        // > blur > none (glass is the most deliberate/heavyweight choice a user
        // would have made), so an existing user's look is preserved as closely
        // as possible instead of the config being left in an ambiguous
        // multi-enabled state.
        if (!opts.appearance.visualEffectMigrated) {
            const hadGlass = opts.appearance.glass.enable;
            const hadTransparency = opts.appearance.transparency.enable;
            const hadBlur = opts.hyprland.decoration.blur.enabled;
            let effect;
            if (hadGlass) effect = "glass";
            else if (hadTransparency) effect = "transparency";
            else if (hadBlur) effect = "blur";
            else effect = "none";
            opts.appearance.visualEffect = effect;
            root.applyVisualEffectExclusivity(effect);
            opts.appearance.visualEffectMigrated = true;
        }

        // One-time forced-off migration for hyprland.misc.allowSessionLockRestore
        // (see its schema comment above and github.com/quickshell-mirror/
        // quickshell#1054) — this is a stability/lockout-risk fix, not a
        // preference, so unlike the migrations above it overrides an
        // existing "true" rather than preserving it. Runs once regardless of
        // the option's current value so a user who already flipped it back
        // on themselves (accepting the risk) isn't fought with on reload.
        if (!opts.hyprland.misc.sessionLockRestoreMigrated) {
            opts.hyprland.misc.allowSessionLockRestore = false;
            opts.hyprland.misc.sessionLockRestoreMigrated = true;
        }
    }

    // Enforces that exactly one of blur / transparency / glass is enabled in
    // the JSON config, matching `effect`. "Glass" ("Liquid Glass") is just
    // Hyprland's native blur with the "acrylic" variant (decoration:blur:
    // variant — see HyprlandConfig.qml's "Blur Style" control), not a separate
    // mechanism, so it also turns blur.enabled on and only differs in variant.
    // This only touches Config.options; callers that need the change to
    // actually reach the compositor (HyprlandConfig.set(...)) do so themselves
    // after calling this — see InterfaceConfig.qml.
    function applyVisualEffectExclusivity(effect) {
        const opts = root.options;
        opts.hyprland.decoration.blur.enabled = effect === "blur" || effect === "glass";
        if (effect === "glass") {
            opts.hyprland.decoration.blur.variant = "acrylic";
        } else if (effect === "blur" && opts.hyprland.decoration.blur.variant === "acrylic") {
            opts.hyprland.decoration.blur.variant = "kawase";
        }
        opts.appearance.transparency.enable = effect === "transparency";
        opts.appearance.glass.enable = effect === "glass";
    }

    // Applies one of the 5 Settings > Quick performance/experience profiles
    // (see PerformanceProfiles.qml) - writes every Config.options.* value the
    // profile specifies via the existing setNestedValue() path-setter, then
    // re-derives the blur/transparency/glass exclusivity flags from whatever
    // visualEffect the (already capability-resolved) profile ended up with,
    // exactly like the Interface page's own visual-effect picker does.
    //
    // Only touches Config.options - like applyVisualEffectExclusivity(), it
    // never calls into HyprlandConfig.qml (avoiding a circular import back
    // into this foundational singleton). The caller (a settings page) must
    // still push the returned `hypr` keys via HyprlandConfig.setMany() and
    // `animPreset` via HyprlandConfig.setAnimPreset() for the compositor-side
    // half of the profile to actually reach Hyprland.
    //
    // blurVariantSupported should come from HyprlandData.blurVariantSupported
    // - pass false (or omit) to always get the plain-blur fallback.
    function applyPerformanceProfile(id, blurVariantSupported) {
        const resolved = PerformanceProfiles.resolve(id, blurVariantSupported ?? false)
        if (!resolved) return null
        for (const key in resolved.config) {
            root.setNestedValue(key, resolved.config[key])
        }
        root.applyVisualEffectExclusivity(root.options.appearance.visualEffect)
        root.options.appearance.performanceProfile = id
        return resolved
    }

    Timer {
        id: fileReloadTimer
        interval: root.readWriteDelay
        repeat: false
        onTriggered: {
            configFileView.reload()
        }
    }

    Timer {
        id: fileWriteTimer
        interval: root.readWriteDelay
        repeat: false
        onTriggered: {
            configFileView.writeAdapter()
        }
    }

    FileView {
        id: configFileView
        path: root.filePath
        watchChanges: true
        blockWrites: root.blockWrites
        onFileChanged: fileReloadTimer.restart()
        onAdapterUpdated: fileWriteTimer.restart()
        onLoaded: {
            root.migrateLegacyConfig();
            root.ready = true;
        }
        onLoadFailed: error => {
            if (error == FileViewError.FileNotFound) {
                writeAdapter();
            }
        }

        JsonAdapter {
            id: configOptionsJsonAdapter

            property string panelFamily: "ii" // "ii", "waffle"

            property JsonObject policies: JsonObject {
                property int ai: 1 // 0: No | 1: Yes | 2: Local
                property int weeb: 1 // 0: No | 1: Open | 2: Closet
            }

            property JsonObject ai: JsonObject {
                property string systemPrompt: "## Style\n- Use casual tone, don't be formal!\n- Always be brief and to the point, unless asked otherwise\n- Don't repeat the user's question\n- Be approachable: Avoid using overly complicated, domain-specific terms and provide analogies when asked to explain a concept\n\n## Context (ignore when irrelevant)\n- You are a helpful and inspiring sidebar assistant on a {DISTRO} Linux system\n- Desktop environment: {DE}\n- Current date & time: {DATETIME}\n- Focused app: {WINDOWCLASS}\n\n## Presentation\n- Use Markdown features in your response: \n  - **Bold** text to **highlight keywords** in your response\n  - **Split long information into small sections** with h2 headers and a relevant emoji at the start of it (for example `## 🐧 Linux`). Bullet points are preferred over long paragraphs, unless you're offering writing support or instructed otherwise by the user.\n- Asked to compare different options? You should firstly use a table to compare the main aspects, then elaborate or include relevant comments from online forums *after* the table. Make sure to provide a final recommendation for the user's use case!\n- Use LaTeX formatting for mathematical and scientific notations whenever appropriate. Enclose all LaTeX '$$' delimiters. NEVER generate LaTeX code in a latex block unless the user explicitly asks for it. DO NOT use LaTeX for regular documents (resumes, letters, essays, CVs, etc.).\n\nThanks!\n"
                property string tool: "functions" // search, functions, or none
                property list<var> extraModels: [
                    {
                        "api_format": "openai", // Most of the time you want "openai". Use "gemini" for Google's models
                        "description": "This is a custom model. Edit the config to add more! | Anyway, this is DeepSeek R1 Distill LLaMA 70B",
                        "endpoint": "https://openrouter.ai/api/v1/chat/completions",
                        "homepage": "https://openrouter.ai/deepseek/deepseek-r1-distill-llama-70b:free", // Not mandatory
                        "icon": "spark-symbolic", // Not mandatory
                        "key_get_link": "https://openrouter.ai/settings/keys", // Not mandatory
                        "key_id": "openrouter",
                        "model": "deepseek/deepseek-r1-distill-llama-70b:free",
                        "name": "Custom: DS R1 Dstl. LLaMA 70B",
                        "requires_key": true
                    }
                ]
            }

            property JsonObject appearance: JsonObject {
                property bool extraBackgroundTint: true
                property int fakeScreenRounding: 2 // 0: None | 1: Always | 2: When not fullscreen
                // Blur (hyprland.decoration.blur.enabled), transparency
                // (appearance.transparency.enable) and glass (appearance.glass.enable,
                // backed by hyprland.decoration.blur.variant === "acrylic") all change
                // how the same surfaces look and visibly conflict when stacked. Settings
                // > Interface exposes them as one exclusive choice; this is the persisted
                // selection. See Config.applyVisualEffectExclusivity().
                property string visualEffect: "blur" // "none" | "blur" | "transparency" | "glass"
                // Set once migrateLegacyConfig() has resolved a pre-existing config's
                // (possibly simultaneously-enabled) blur/transparency/glass flags into a
                // single visualEffect choice, so later user edits are never overwritten.
                property bool visualEffectMigrated: false
                // Last performance/experience profile applied from Settings > Quick
                // (see PerformanceProfiles.qml + Config.applyPerformanceProfile()).
                // Purely a "which button to highlight" marker - applying a profile is
                // a one-time bulk mutation, not an enforced mode, so hand-tuning any
                // individual setting afterward is never reverted or fought with.
                property string performanceProfile: "balanced" // maxPerformance|performance|balanced|experience|maxExperience
                property JsonObject fonts: JsonObject {
                    property string main: "Google Sans Flex"
                    property string numbers: "Google Sans Flex"
                    property string title: "Google Sans Flex"
                    property string iconNerd: "JetBrains Mono NF"
                    property string monospace: "JetBrains Mono NF"
                    property string reading: "Readex Pro"
                    property string expressive: "Space Grotesk"
                }
                property JsonObject transparency: JsonObject {
                    property bool enable: false
                    property bool automatic: true
                    property real backgroundTransparency: 0.11
                    property real contentTransparency: 0.57
                }
                property JsonObject glass: JsonObject {
                    // Applies to every shared surface through Appearance.qml.
                    // "Glass" ("Liquid Glass") is backed by Hyprland's own native
                    // decoration:blur:variant=acrylic (see hyprland.decoration.blur
                    // below) — no separate plugin involved.
                    property bool enable: false
                    property real opacity: 0.78
                }
                property JsonObject motion: JsonObject {
                    // Smooth is non-overshooting; expressive keeps the legacy feel.
                    property string style: "smooth" // smooth | expressive
                    property real durationScale: 1.0
                }
                property JsonObject wallpaperTheming: JsonObject {
                    property bool enableAppsAndShell: true
                    property bool enableQtApps: true
                    property bool enableTerminal: true
                    property JsonObject terminalGenerationProps: JsonObject {
                        property real harmony: 0.6
                        property real harmonizeThreshold: 100
                        property real termFgBoost: 0.35
                        property bool forceDarkMode: false
                    }
                }
                property JsonObject palette: JsonObject {
                    property string type: "auto" // Allowed: auto, scheme-content, scheme-expressive, scheme-fidelity, scheme-fruit-salad, scheme-monochrome, scheme-neutral, scheme-rainbow, scheme-tonal-spot
                    property string accentColor: ""
                }
                // A named starting point; each value remains editable afterwards.
                property string builtInTheme: "adaptive" // adaptive | midnight | paper | aurora | mono
                // Names of matugen templates (see SystemTheming.matugenTemplates) the
                // user has disabled via Settings > Interface. Referenced by
                // SystemTheming.templateEnabled()/setTemplateEnabled().
                property list<string> matugenDisabled: []
            }

            property JsonObject audio: JsonObject {
                // Values in %
                property JsonObject protection: JsonObject {
                    // Prevent sudden bangs
                    property bool enable: false
                    property real maxAllowedIncrease: 10
                    property real maxAllowed: 99
                }
            }

            property JsonObject profile: JsonObject {
                property string avatarPath: ""
                property string avatarPicture: ""
                property string descriptionText: "::distro::"
                property string displayName: ""

            }

            property JsonObject hyprland: JsonObject {
                property JsonObject animations: JsonObject {
                    property string animation: "smooth"
                    property bool enable: true
                    property bool workspaceWraparound: false
                    property bool customEnabled: false
                    // Custom curves: [{name, type:"bezier", points:[[0.23,1],[0.32,1]]}, {name, type:"spring", mass:1, stiffness:71, dampening:15}]
                    // Defaults mirror the "Smooth" preset (Material Design standard easing)
                    // shipped in shellOverrides/animations.lua, so opening the custom editor
                    // for the first time starts from the same motion the user already has.
                    property list<var> customCurves: [
                        { "name": "sm_standard", "type": "bezier", "points": [[0.4, 0], [0.2, 1]] },
                        { "name": "sm_decel", "type": "bezier", "points": [[0, 0], [0.2, 1]] },
                        { "name": "sm_accel", "type": "bezier", "points": [[0.4, 0], [1, 1]] },
                        { "name": "sm_linear", "type": "bezier", "points": [[0, 0], [1, 1]] }
                    ]
                    // Custom anims: [{leaf, enabled, speed, bezier/spring, style}]
                    // speed in ds (1ds=100ms), style like "popin 87%", "slide", "fade", "slide left"
                    property list<var> customAnims: [
                        { "leaf": "global", "enabled": true, "speed": 10, "bezier": "sm_standard", "style": "" },
                        { "leaf": "windows", "enabled": true, "speed": 4.2, "bezier": "sm_standard", "style": "" },
                        { "leaf": "windowsIn", "enabled": true, "speed": 3.6, "bezier": "sm_decel", "style": "popin 85%" },
                        { "leaf": "windowsOut", "enabled": true, "speed": 2.6, "bezier": "sm_accel", "style": "popin 85%" },
                        { "leaf": "windowsMove", "enabled": true, "speed": 4, "bezier": "sm_standard", "style": "" },
                        { "leaf": "fadeIn", "enabled": true, "speed": 3, "bezier": "sm_decel", "style": "" },
                        { "leaf": "fadeOut", "enabled": true, "speed": 2.4, "bezier": "sm_accel", "style": "" },
                        { "leaf": "border", "enabled": true, "speed": 6, "bezier": "sm_standard", "style": "" },
                        { "leaf": "workspaces", "enabled": true, "speed": 5, "bezier": "sm_standard", "style": "slide" },
                        { "leaf": "zoomFactor", "enabled": true, "speed": 6, "bezier": "sm_standard", "style": "" }
                    ]
                }
                property JsonObject autostartApps: JsonObject {
                    property bool enable: false
                    property list<var> apps: []
                }
                property JsonObject decoration: JsonObject {
                    property int rounding: 22
                    property real roundingPower: 2.5
                    property real activeOpacity: 1.0
                    property real inactiveOpacity: 0.9
                    property real fullscreenOpacity: 1.0
                    property bool dimInactive: false
                    property real dimStrength: 0.5
                    property real dimSpecial: 0.2
                    property bool borderPartOfWindow: true
                    // dim_modal dims modal dialogs
                    property bool dimModal: true
                    // dim_around dims around a fullscreened dimmed window
                    property bool dimAround: false
                    // screen_shader path
                    property string screenShader: ""
                    property JsonObject blur: JsonObject {
                        property bool enabled: true
                        property int size: 1
                        property int passes: 3
                        property real vibrancy: 0.5
                        property bool xray: true
                        property bool newOptimizations: true
                        // Advanced blur keys supported by current Hyprland.
                        property real noise: 0.0
                        property real contrast: 0.0
                        property real brightness: 0.6
                        property real vibrancyDarkness: 0.0
                        property bool special: false
                        property bool popups: false
                        property bool popupsIgnorealpha: true
                        // Native blur variants (Hyprland decoration:blur:variant,
                        // merged upstream 2026-08-22). "acrylic" is Hyprland's own
                        // Liquid Glass-style effect — see Config.applyVisualEffectExclusivity()
                        // and Settings > Hyprland > "Blur Style".
                        property string variant: "kawase" // kawase|frost|ripple|drops|water|fluid_jar|prism|heat_shimmer|acrylic|aurora|haze
                        // Shared params for the glass-family variants (decoration:blur:glass:*)
                        property JsonObject glass: JsonObject {
                            property real refraction: 20
                            property real size: 40
                            property real roughness: 1.0
                        }
                        // "Liquid Glass" variant params (decoration:blur:acrylic:*)
                        property JsonObject acrylic: JsonObject {
                            property real refraction: 24
                            property real bulb: 48
                            property real clarity: 0.82
                            property real aberration: 0.025
                            property string tint: "0x14EEF5FF"
                        }
                        // Remaining native variants (decoration:blur:<variant>:*).
                        // kawase/frost/prism have no variant-specific params of
                        // their own — prism reuses the shared `glass` block above.
                        property JsonObject ripple: JsonObject {
                            property real strength: 30
                            property real radius: 400
                            property real width: 32
                            property real duration: 0.45
                        }
                        // 0 disables the animation; enabling costs more GPU.
                        property JsonObject drops: JsonObject {
                            property real speed: 3
                        }
                        property JsonObject water: JsonObject {
                            property real strength: 32
                            property real radius: 20
                            property real speed: 0.76
                            property real damping: 0.95
                            property real duration: 12
                        }
                        property JsonObject fluidJar: JsonObject {
                            property string color: "0xCC3399FF"
                            property real speed: 3.7
                            property real fillAmount: 0.5
                            property real mass: 1.4
                            property real precision: 2
                            property real turbulence: 1.2
                            property real distortion: 8
                        }
                        // 0 disables the animation; enabling costs more GPU.
                        property JsonObject heatShimmer: JsonObject {
                            property real speed: 1
                        }
                        // 0 freezes the animation; enabling costs more GPU.
                        property JsonObject aurora: JsonObject {
                            property real speed: 1
                            property real intensity: 0.35
                            property string color1: "0x29F0A0FF"
                            property string color2: "0x7A4DFFFF"
                        }
                        property JsonObject haze: JsonObject {
                            property real intensity: 0.35
                            property real iridescence: 0.7
                        }
                    }
                    property JsonObject shadow: JsonObject {
                        property bool enabled: true
                        property int range: 20
                        property int renderPower: 3
                        property bool sharp: false
                        property string color: "rgba(00000020)"
                        property string colorInactive: ""
                        property int offsetX: 0
                        property int offsetY: 2
                        property real scale: 1.0
                    }
                }
                property JsonObject general: JsonObject {
                    property int borderSize: 1
                    property int gapsIn: 2
                    property int gapsOut: 5
                    property int gapsWorkspaces: 0
                    property string layout: "dwindle"
                    property bool resizeOnBorder: false
                    property bool allowTearing: true
                    property bool snapEnabled: false
                    property int snapWindowGap: 10
                    property int snapMonitorGap: 10
                    property bool snapBorderOverlap: false
                    property bool snapRespectGaps: true
                    // Border colors (hyprland 0.55 wiki)
                    property string colActiveBorder: ""
                    property string colInactiveBorder: ""
                    property string colNogroupBorder: ""
                    property bool autoThemeBorders: false
                    // Float gaps (gaps for floating windows)
                    property int floatGaps: 0
                    // Extend grab area for border resize
                    property bool extendBorderGrabArea: true
                    // Show hover icon on border resize
                    property bool hoverIconOnBorder: true
                    // Disable focus fallback
                    property bool noFocusFallback: false
                    // Workspace rules
                    property list<var> workspaceRules: []
                    // Window rules
                    property list<var> windowRules: []
                }
                property JsonObject misc: JsonObject {
                    property bool disableHyprlandLogo: true
                    property bool disableSplashRendering: true
                    property int vrr: 0
                    property bool mouseMoveEnablesDpms: true
                    property bool keyPressEnablesDpms: true
                    property bool animateManualResizes: false
                    property bool animateMouseWindowDragging: false
                    // Off by default: quickshell has a known, currently-open
                    // crash (github.com/quickshell-mirror/quickshell#1054)
                    // when re-requesting a session lock the compositor
                    // already holds from a previous instance — this option is
                    // the precondition that makes that reachable (e.g. after
                    // a config reload, or a previous crash, while locked),
                    // and the crash can leave the session stuck locked with
                    // no lock surface to authenticate against. See
                    // migrateLegacyConfig()'s one-time forced-off migration
                    // for existing configs. Re-enable once fixed upstream.
                    property bool allowSessionLockRestore: false
                    // Set once migrateLegacyConfig() has forced
                    // allowSessionLockRestore off for a pre-existing config;
                    // see the migration and the property comment above.
                    property bool sessionLockRestoreMigrated: false
                    property int focusOnActivate: 0
                }
                property JsonObject cursor: JsonObject {
                    property real zoomFactor: 1.0
                    property bool zoomRigid: false
                    property bool hideOnKeyPress: false
                    property bool hideOnTouch: true
                    property int hotspotPadding: 1
                    property int inactiveTimeout: 0
                    property bool noWarps: false
                    property bool persistentWarps: false
                }
                property JsonObject gestures: JsonObject {
                    property int workspaceSwipeDistance: 700
                    property real workspaceSwipeCancelRatio: 0.2
                    property int workspaceSwipeMinSpeedToForce: 5
                    property bool workspaceSwipeDirectionLock: true
                    property int workspaceSwipeDirectionLockThreshold: 10
                    property bool workspaceSwipeCreateNew: true
                }
                property JsonObject dwindle: JsonObject {
                    property bool preserveSplit: true
                    property bool smartSplit: false
                    property bool smartResizing: false
                }
                property JsonObject master: JsonObject {
                    property string newStatus: "slave" // master, slave, inherit
                    property real mfact: 0.55
                    property string orientation: "left" // left, right, top, bottom, center
                    property bool allowSmallSplit: false
                    property bool slaveCountNoGaps: false
                }
                property JsonObject group: JsonObject {
                    property bool autoGroup: false
                    property bool dragIntoGroup: true
                    property bool mergeGroupsOnDrag: true
                    property JsonObject groupbar: JsonObject {
                        property bool enabled: true
                        property int height: 14
                        property bool gradients: true
                        property bool scrolling: true
                    }
                }
                property string customBindsLua: "-- Custom binds (hl.bind)\n-- Example: hl.bind(\"SUPER + T\", hl.dsp.exec_cmd(\"kitty\"))\n"
                property string customRulesLua: "-- Custom window/workspace rules\n-- Example: hl.window_rule({match={class=\"kitty\"}, float=true})\n"
                property JsonObject input: JsonObject {
                    property string kbLayout: "us"
                    property string kbVariant: ""
                    property string kbModel: ""
                    property string kbOptions: ""
                    property string kbRules: ""
                    property string kbLayoutSwitchShortcut: "grp:alt_shift_toggle" // grp:alt_shift_toggle, grp:ctrl_shift_toggle, grp:win_space_toggle, grp:caps_toggle, etc. Empty = no toggle
                    property bool numlock: true
                    property int repeatDelay: 250
                    property int repeatRate: 35
                    property int followMouse: 1
                    // Mouse / touchpad per-device overrides (hyprland 0.55 wiki)
                    property real sensitivity: 0.0 // -1.0 to 1.0
                    property string accelProfile: "" // empty, flat, adaptive
                    property bool forceNoAccel: false
                    property real scrollFactor: 1.0
                    property int scrollButton: 0 // 0=disable, 8/9=back/forward
                    property bool leftHanded: false
                    property JsonObject touchpad: JsonObject {
                        property bool naturalScroll: false
                        property bool disableWhileTyping: true
                        property bool clickfingerBehavior: false
                        property real scrollFactor: 0.7
                        property bool tapToClick: true
                        property int tapButtonMap: 0 // 0: lrm, 1: lmr
                        property bool tapAndDrag: true
                        property bool dragLock: false
                    }
                }
            }

            property JsonObject apps: JsonObject {
                property string bluetooth: "kcmshell6 kcm_bluetooth"
                property string changePassword: "kitty -1 --hold=yes fish -i -c 'passwd'"
                property string network: "kcmshell6 kcm_networkmanagement"
                property string manageUser: "kcmshell6 kcm_users"
                property string networkEthernet: "kcmshell6 kcm_networkmanagement"
                property string taskManager: "plasma-systemmonitor --page-name Processes"
                property string terminal: "kitty -1" // This is only for shell actions
                property string update: "kitty -1 --hold=yes fish -i -c 'pkexec pacman -Syu'"
                property string volumeMixer: `~/.config/hypr/hyprland/scripts/launch_first_available.sh "pavucontrol-qt" "pavucontrol"`
                // What Super (tap) / Settings > Services > Search opens.
                // "quickshell" is the shell's own built-in search/overview
                // (modules/ii/overview/Overview.qml) - the other three are
                // external tools the shell hands off to instead, each
                // expected to already be installed and (for walker) running
                // its companion "elephant" service. See Overview.qml's
                // searchToggle/searchToggleRelease handlers for the actual
                // launch commands.
                property string launcher: "quickshell" // quickshell | walker | vicinae | fuzzel
            }

            property JsonObject settings: JsonObject {
                property string style: "default" // default - minimal
                property real borderSize: 1
                property string borderColor: "layer0Border"
                property int preferredWidth: 1180
                property int preferredHeight: 780
            }

            property JsonObject sessionScreen: JsonObject {
                property string presentation: "center" // center | edge
                property string edge: "right" // left | right
                property int edgeWidth: 460
                property bool edgeBackdrop: false
                property int columns: 4
                property bool showHibernate: true
                property bool showTaskManager: true
                property bool showFirmware: true
                property bool showWarnings: true
                property bool confirmDestructive: true
            }

            property JsonObject background: JsonObject {
                property string lockWall: ""
                property bool widgetsLocked: false
                property bool showGrid: true
                property bool showBlur: false
                property string splitRatio: "100" // 25 50 100
                property string splitSide: "left"
                property bool showSnapLines: true
                property JsonObject widgets: JsonObject {
                    property JsonObject clock: JsonObject {
                        property bool enable: true
                        property bool showOnlyWhenLocked: false
                        property string placementStrategy: "leastBusy" // "free", "leastBusy", "mostBusy"
                        property real x: 100
                        property real y: 100
                        property string style: "cookie"        // Options: "cookie", "digital"
                        property string color: ""
                        property string styleLocked: "cookie"  // Options: "cookie", "digital"
                        property JsonObject cookie: JsonObject {
                            property bool aiStyling: false
                            property int sides: 14
                            property string dialNumberStyle: "full"   // Options: "dots" , "numbers", "full" , "none"
                            property string hourHandStyle: "fill"     // Options: "classic", "fill", "hollow", "hide"
                            property string minuteHandStyle: "medium" // Options "classic", "thin", "medium", "bold", "hide"
                            property string secondHandStyle: "dot"    // Options: "dot", "line", "classic", "hide"
                            property string dateStyle: "bubble"       // Options: "border", "rect", "bubble" , "hide"
                            property bool timeIndicators: true
                            property bool hourMarks: false
                            property bool dateInClock: true
                            property bool constantlyRotate: false
                            property bool useSineCookie: false
                        }
                        property JsonObject digital: JsonObject {
                            property bool adaptiveAlignment: true
                            property bool showDate: true
                            property bool animateChange: true
                            property bool vertical: false
                            property JsonObject font: JsonObject {
                                property string family: "Google Sans Flex"
                                property real weight: 350
                                property real width: 100
                                property real size: 90
                                property real roundness: 0
                            }
                        }
                        property JsonObject pixel: JsonObject {
                            property string orientation: "vertical"
                        }
                        property JsonObject quote: JsonObject {
                            property bool enable: false
                            property string text: ""
                            property bool followClock: false
                        }
                    }
                    property JsonObject weather: JsonObject {
                        property bool enable: false
                        property string placementStrategy: "free" // "free", "leastBusy", "mostBusy"
                        property real x: 400
                        property real y: 100
                        property string sizeMode: "1x3"
                        property bool expanded: false
                    }

                    property JsonObject calendar: JsonObject {
                        property bool enable: false
                        property string placementStrategy: "free" // "free", "leastBusy", "mostBusy"
                        property real x: 400
                        property real y: 100
                        property string sizeMode: "2x2"
                    }
                    property JsonObject worldClock: JsonObject {
                        property bool enable: false
                        property list<string> timezones: ["Australia/Sydney", "Asia/Tokyo", "Europe/London", "America/New_York"]
                        property string placementStrategy: "free"
                        property real x: 400
                        property real y: 100
                        property string sizeMode: "2x2"
                        property int clockCount: 4 
                    }

                    property JsonObject notes: JsonObject {
                        property bool enable: false
                        property string placementStrategy: "free"
                        property real x: 400
                        property real y: 100
                    }

                    property JsonObject todo: JsonObject {
                        property bool enable: false
                        property string placementStrategy: "free"
                        property real x: 400
                        property real y: 100
                    }

                    property JsonObject userCard: JsonObject {
                        property bool enable: false
                        property string placementStrategy: "free"
                        property real x: 400
                        property real y: 100
                        property string sizeMode: "1x2" 
                    }

                    property JsonObject images: JsonObject {
                        property bool enable: false
                        property string placementStrategy: "free"
                        property real x: 400
                        property real y: 100
                    }

                    property JsonObject visualizer: JsonObject {
                        property bool enable: false
                        property string placementStrategy: "free"
                        property real x: 0
                        property real y: 0
                    }

                    property JsonObject customImage: JsonObject {
                        property bool enable: false
                        property string placementStrategy: "free"
                        property real x: 400
                        property real y: 100
                        property string path: ""
                        property string shape: "Cookie4Sided"
                        property real size: 200
                    }

                    property JsonObject resources: JsonObject {
                        property bool enable: false
                        property string placementStrategy: "free"
                        property real x: 400
                        property real y: 100
                        property bool vertical: false
                    }

                    property JsonObject networkInfo: JsonObject {
                        property bool enable: false
                        property string placementStrategy: "free"
                        property real x: 400
                        property real y: 100
                        property bool showDetails: true
                    }

                    property JsonObject uptime: JsonObject {
                        property bool enable: false
                        property string placementStrategy: "free"
                        property real x: 400
                        property real y: 100
                    }

                    property JsonObject systemHistory: JsonObject {
                        property bool enable: false
                        property string placementStrategy: "free"
                        property real x: 400
                        property real y: 100
                        property bool showCpu: true
                        property bool showMemory: true
                        property bool showSwap: false
                        property bool showDisk: false
                        property bool showGpu: false
                    }

                    property JsonObject timers: JsonObject {
                        property bool enable: false
                        property string placementStrategy: "free"
                        property real x: 400
                        property real y: 100
                        property bool vertical: false
                    }

                    property JsonObject media: JsonObject {
                        property bool enable: false
                        property bool showControls: true
                        property bool showLyrics: false
                        property bool showTitles: true
                        property string backgroundShape: "Cookie4Sided"
                        property string placementStrategy: "free" // "free", "leastBusy", "mostBusy"
                        property real x: 800
                        property real y: 500
                        property string sizeMode: "1x3" 
                    }
                }
                property list<string> screenList: [] 
                property string wallpaperPath: ""
                property bool centeredWallpaper: false
                property string centeredWallpaperShape: "Cookie7Sided"
                property int centeredWallpaperSize: 400
                property string centeredWallpaperColor: "primaryContainer"
                property bool centeredWallpaperOnlyWhenLocked: false
                property string wallpaperAnimation: "magic"
                property bool enableWallpaperPreview: false
                property string thumbnailPath: ""
                property bool hideWhenFullscreen: true
                property JsonObject parallax: JsonObject {
                    property bool vertical: false
                    property bool autoVertical: false
                    property bool enableWorkspace: true
                    property real workspaceZoom: 1.0 // Relative to wallpaper size
                    property bool enableSidebar: true
                    property real widgetsFactor: 1.2
                }
            }

            property JsonObject bar: JsonObject {
                // ── Bar Mode ─────────────────────────────────────────────────────────
                // Selects which bar is active. All shared settings below apply to it.
                // Values: "classic" | "mesoBar" | "tasklistBar" | "sysmonitorBar"
                //         | "quickActionsBar" | "infoStrip" | "m3Island"
                // NOTE: "mesoBar" was called "topIsland" before it grew into a real
                // configurable-width bar (see Config.options.mesoBar below). An old
                // config's literal "topIsland" value is remapped by
                // Config.migrateLegacyConfig(), called once the config file loads.
                property string barMode: "classic"

                // ── Shared settings (apply to every barMode) ──────────────────────
                property JsonObject autoHide: JsonObject {
                    property bool enable: false
                    property int hoverRegionWidth: 2
                    property bool pushWindows: false
                    property JsonObject showWhenPressingSuper: JsonObject {
                        property bool enable: true
                        property int delay: 140
                    }
                }
                property bool showFrame: false
                property real frameThickness: 4
                property string frameColor: "black"
                property bool followFrameColor: false
                property bool bottom: false // Instead of top
                property int cornerStyle: 0 // 0: Hug | 1: Float | 2: Plain rectangle
                property string groupColor: "layer1"
                property bool floatStyleShadow: true // Show shadow behind bar when cornerStyle == 1 (Float)
                property string borderless: "pills"
                property string topLeftIcon: "spark" // Options: "distro" or any icon name in ~/.config/quickshell/ii/assets/icons
                property bool showBackground: true
                property bool verbose: true
                property bool vertical: false
                property JsonObject resources: JsonObject {
                    property string style: "filled"
                    property bool showValue: false
                    property bool alwaysShowSwap: false
                    property bool alwaysShowCpu: true
                    property bool alwaysShowCpuTemp: false
                    property bool alwaysShowDisk: false
                    property bool alwaysShowRam: true
                    property int memoryWarningThreshold: 95
                    property int swapWarningThreshold: 85
                    property int cpuWarningThreshold: 90
                }
                property JsonObject divider: JsonObject {
                    property string style: "rect" // rect - dot - space
                    property int spacing: 20
                }

                property JsonObject layouts: JsonObject {
                    property list<string> leftLayout: ["launcherButton", "workspaces", "activeWindow"]
                    property list<string> middleLayout: ["clockWidget"]
                    property list<string> rightLayout: ["sysTray", "utilButtons", "systemIcons", "powerButton"]
                }
                
                property list<string> screenList: [] // List of names, like "eDP-1", find out with 'hyprctl monitors' command
                property JsonObject utilButtons: JsonObject {
                    property bool showScreenSnip: true
                    property bool showColorPicker: true
                    property bool showMicToggle: false
                    property bool showKeyboardToggle: false
                    property bool showWallpaperToggle: true
                    property bool showDarkModeToggle: false
                    property bool showPerformanceProfileToggle: false
                    property bool showScreenRecord: false       
                    property bool isRecording: false
                }

                property JsonObject workspaces: JsonObject {
                    property bool monochromeIcons: true
                    property int shown: 10
                    property bool showAppIcons: false
                    property string indicatorStyle: "dot" // "dot" or "icon"
                    property bool alwaysShowNumbers: true
                    property int showNumberDelay: 300 // milliseconds
                    property list<string> numberMap: ["1", "2"] // Characters to show instead of numbers on workspace indicator
                    property bool useNerdFont: false
                }
                property JsonObject weather: JsonObject {
                    property bool enable: false
                    property bool enableGPS: true // gps based location
                    property string city: "" // When 'enableGPS' is false
                    property bool useUSCS: false // Instead of metric (SI) units
                    property int fetchInterval: 10 // minutes
                }
                property JsonObject indicators: JsonObject {
                    property JsonObject notifications: JsonObject {
                        property bool showUnreadCount: false
                    }
                }
                property JsonObject tooltips: JsonObject {
                    property bool clickToShow: false
                }
                property JsonObject systemIconsHover: JsonObject {
                    property bool enable: true
                    property string content: "notifications" // notifications | status
                    property int recentLimit: 3
                }
                property JsonObject media: JsonObject {
                    property string preferredPlayer: ""
                    property bool alwaysVisible: false
                    property bool onlyTitle: false
                    property int maxWidth: 280
                    property int minWidth: 100
                }
                property JsonObject pomodoro: JsonObject {
                    property bool showLabel: false
                    property bool showSeconds: false
                    property string clickAction: "toggle" // toggle | reset | sidebar
                }
            }

            // "Meso-" (Greek μέσος, mesos = "middle") is the standard scientific
            // prefix for something middle-sized or positioned in-between two
            // extremes (mesosphere, mesoderm, mesophyll) - which is exactly what
            // this bar mode is: a real bar, wider than a content-hugging pill but
            // deliberately narrower than the edge-to-edge "classic" bar. "Median"
            // was considered but rejected - it names a statistical midpoint of a
            // data set, not a spatial middle, so it reads oddly for a UI element.
            // This mode was called "topIsland" before it grew widget-spreading
            // layout, width-percent sizing and bar-family autohide/corner support;
            // see Config.migrateLegacyConfig() and the deprecated "topIsland"
            // JsonObject below for the back-compat shim that carries old configs
            // (and old barMode: "topIsland" values) over to this one.
            property JsonObject mesoBar: JsonObject {
                // ── Shared settings are in Config.options.bar ─────────────────────
                // (autoHide, bottom, showBackground, showFrame, etc.)
                property bool showFrame: false
                property real frameThickness: 4
                property string frameColor: "black"
                property bool followFrameColor: false
                property int cornerStyle: 1 // 0: Hug | 1: Float | 2: Plain rectangle | 3: Material
                property string borderless: "pills"
                property bool showBackground: true
                property bool verbose: true

                // ── Width policy ────────────────────────────────────────────────
                // "content": hug the widgets' content width (the old topIsland pill
                //            behavior, kept as an option)
                // "percent": span a configurable percentage of the screen width,
                //            spreading the left/middle/right groups apart like a
                //            real bar instead of gluing them together
                property string widthMode: "percent"
                property real widthPercent: 55 // 1-100, used when widthMode === "percent"

                property JsonObject layouts: JsonObject {
                    property list<string> leftLayout: ["launcherButton", "workspaces", "activeWindow"]
                    property list<string> middleLayout: ["media", "clockWidget"]
                    property list<string> rightLayout: ["privacyIndicator", "resources", "sysTray", "systemIcons", "idleInhibitor", "powerButton"]
                }
                property JsonObject utilButtons: JsonObject {
                    property bool showScreenSnip: true
                    property bool showColorPicker: true
                    property bool showMicToggle: false
                    property bool showKeyboardToggle: false
                    property bool showWallpaperToggle: true
                    property bool showDarkModeToggle: false
                    property bool showPerformanceProfileToggle: false
                    property bool showScreenRecord: false
                    property bool isRecording: false
                }
                property JsonObject workspaces: JsonObject {
                    property bool monochromeIcons: true
                    property int shown: 10
                    property bool showAppIcons: false
                    property string indicatorStyle: "dot"
                    property bool alwaysShowNumbers: true
                    property int showNumberDelay: 300
                    property list<string> numberMap: ["1", "2"]
                    property bool useNerdFont: false
                }
                property JsonObject indicators: JsonObject {
                    property JsonObject notifications: JsonObject {
                        property bool showUnreadCount: false
                    }
                }
                property JsonObject tooltips: JsonObject {
                    property bool clickToShow: false
                }
                property JsonObject media: JsonObject {
                    property string preferredPlayer: ""
                    property bool alwaysVisible: false
                    property bool onlyTitle: false
                    property int maxWidth: 280
                    property int minWidth: 100
                }

                // Set once Config.migrateLegacyConfig() has copied a pre-rename
                // "topIsland" config's appearance/layout into this object, so that
                // migration never runs twice and clobbers the user's own edits.
                property bool legacyMigrated: false
            }

            // ── DEPRECATED - kept only for backward compatibility ──────────────────
            // Before the "topIsland" -> "mesoBar" rename above, this was the live
            // JsonObject for that bar mode. It is kept, unused, purely so that an
            // old config file's top-level "topIsland" JSON object still has
            // somewhere to bind to on load; Config.migrateLegacyConfig() reads the
            // fields below once and copies recognized ones into "mesoBar". Nothing
            // else in the codebase should read or write this property.
            property JsonObject topIsland: JsonObject {
                property bool showFrame: false
                property real frameThickness: 4
                property string frameColor: "black"
                property bool followFrameColor: false
                property int cornerStyle: 1
                property string borderless: "pills"
                property bool showBackground: true
                property bool verbose: true
                property JsonObject layouts: JsonObject {
                    property list<string> leftLayout: ["workspaces"]
                    property list<string> middleLayout: ["clockWidget"]
                    property list<string> rightLayout: ["systemIcons", "powerButton"]
                }
            }

            property JsonObject tasklistBar: JsonObject {
                // ── Shared settings are in Config.options.bar ─────────────────────
                property int maxButtonWidth: 160
                property bool showLabels: true
                property list<string> pinnedApps: ["org.kde.dolphin", "kitty"]
            }

            property JsonObject sysmonitorBar: JsonObject {
                // ── Shared settings are in Config.options.bar ─────────────────────
                property bool showCpu: true
                property bool showCpuTemp: false
                property bool showRam: true
                property bool showDisk: false
                property bool showSwap: false
                property bool showNetwork: true
                property int memoryWarningThreshold: 95
                property int cpuWarningThreshold: 90
                property int tempWarningThreshold: 85
                property int diskWarningThreshold: 90
                property int swapWarningThreshold: 85
            }

            property JsonObject quickActionsBar: JsonObject {
                // ── Shared settings are in Config.options.bar ─────────────────────
                property bool showVolumeSlider: true
                property bool showBrightnessSlider: true
                property list<var> toggles: [
                    { "type": "wifi" },
                    { "type": "bluetooth" },
                    { "type": "nightLight" },
                    { "type": "darkMode" },
                    { "type": "mic" },
                    { "type": "dnd" }
                ]
                // Empty until the hotspot toggle is first used; Hotspot.qml fills
                // these in with a hostname-derived default the first time it needs
                // them, and persists whatever the user edits in BarConfig.
                property string hotspotSsid: ""
                property string hotspotPassword: ""
            }

            property JsonObject infoStrip: JsonObject {
                // ── Shared settings are in Config.options.bar ─────────────────────
                property bool showActiveWindow: true
                property bool showClock: true
                property bool showCpuUsage: false
                property bool showMemoryUsage: false
                property bool showNotificationDot: true
            }

            property JsonObject m3Island: JsonObject {
                // ── Shared settings are in Config.options.bar (autoHide, bottom, showBackground, etc.) ──
                property int cornerStyle: 0 // 0: Hug (emerges from screen edge with inverted corners) | 1: Float
                property string borderless: "pills"
                property bool showBackground: true
                property bool verbose: true
                // Reserve a layer-shell exclusive zone so tiled windows never
                // occupy the island's edge. Disabled by default: the island
                // otherwise remains a floating overlay.
                property bool reserveScreenSpace: false
                // Clock
                property string clockStyle: "m3" // "m3" | "minimal" | "digital"
                property bool clockShowDate: true
                property bool clockShowSeconds: false
                property bool clockUse24h: true
                // Deprecated - superseded by `scrollAction` below. Kept only so
                // migrateLegacyConfig() can read a pre-existing user's value once;
                // do not read this directly anywhere else.
                property bool scrollVolume: true
                // What scrolling over the island does. "volume" reproduces the
                // old scrollVolume behavior (also extended to the whole pill, not
                // just the clock). "mediaSeek" skips tracks via MprisController.
                // "layoutCycle" expands/collapses the island. "none" disables it.
                property string scrollAction: "volume" // "volume" | "mediaSeek" | "layoutCycle" | "none"
                property bool scrollActionMigrated: false
                // Interaction
                property bool hoverPeek: true
                property bool clickToExpand: true
                property bool launcherHug: true
                // Number of launcher matches visible before its list scrolls.
                property int launcherMaxResults: 6
                property bool rightClickMenu: true
                property int expandedHeight: 72
                // A value of 0 follows the global notification timeout.
                property int notificationTimeout: 0
                property bool showFrame: false
                property real frameThickness: 4
                property string frameColor: "black"
                property bool followFrameColor: false
                // Animation - scales the morph/transition durations used throughout
                // the island. Curves are untouched, only speed changes.
                property string animationSpeed: "normal" // "slow" | "normal" | "fast"
                // Subtle overscale/overshoot spring on notification-card arrival.
                property bool expressiveNotifications: true
                // Debounce before/after entering hover-peek state (ms).
                property int hoverPeekDelayIn: 60
                property int hoverPeekDelayOut: 120
                // Extra quick-toggle icon row shown only while expanded.
                property bool showExpandedQuickToggles: false
                property list<string> expandedQuickToggles: ["idleInhibitor", "privacyIndicator"]
                // Layouts per state - reuse widget ids from bar
                property JsonObject layouts: JsonObject {
                    property list<string> hoverLayout: ["media", "systemIcons"]
                    property list<string> expandedLayout: ["resources", "batteryIndicator"]
                }
                property JsonObject utilButtons: JsonObject {
                    property bool showScreenSnip: true
                    property bool showColorPicker: true
                    property bool showMicToggle: false
                    property bool showKeyboardToggle: false
                    property bool showWallpaperToggle: true
                    property bool showDarkModeToggle: false
                    property bool showPerformanceProfileToggle: false
                    property bool showScreenRecord: false
                    property bool isRecording: false
                }
                property JsonObject workspaces: JsonObject {
                    property bool monochromeIcons: true
                    property int shown: 10
                    property bool showAppIcons: false
                    property string indicatorStyle: "dot"
                    property bool alwaysShowNumbers: true
                    property int showNumberDelay: 300
                    property list<string> numberMap: ["1", "2"]
                    property bool useNerdFont: false
                }
                property JsonObject media: JsonObject {
                    property string preferredPlayer: ""
                    property bool alwaysVisible: false
                    property bool onlyTitle: false
                    property int maxWidth: 220
                    property int minWidth: 100
                }
            }

            property JsonObject battery: JsonObject {
                property int low: 20
                property int critical: 5
                property int full: 101
                property bool automaticSuspend: true
                property int suspend: 3
            }

            property JsonObject calendar: JsonObject {
                property string locale: "en-GB"
            }

            property JsonObject conflictKiller: JsonObject {
                property bool autoKillNotificationDaemons: false
                property bool autoKillTrays: false
            }

            property JsonObject crosshair: JsonObject {
                // Valorant crosshair format. Use https://www.vcrdb.net/builder
                property string code: "0;P;d;1;0l;10;0o;2;1b;0"
            }

            property JsonObject dock: JsonObject {
                property bool enable: false
                property bool showBackground: true
                property bool showPinButton: true
                property bool showAppsButton: true
                property bool showMedia: true
                property bool monochromeIcons: true
                property real height: 60
                property real hoverRegionHeight: 2
                property bool pinnedOnStartup: false
                property bool hoverToReveal: true // When false, only reveals on empty workspace
                property list<string> pinnedApps: [ // IDs of pinned entries
                    "org.kde.dolphin", "kitty",]
                property list<string> ignoredAppRegexes: []
            }

            property JsonObject interactions: JsonObject {
                property JsonObject scrolling: JsonObject {
                    property bool fasterTouchpadScroll: false // Enable faster scrolling with touchpad
                    property int mouseScrollDeltaThreshold: 120 // delta >= this then it gets detected as mouse scroll rather than touchpad
                    property int mouseScrollFactor: 120
                    property int touchpadScrollFactor: 450
                }
                property JsonObject deadPixelWorkaround: JsonObject { // Hyprland leaves out 1 pixel on the right for interactions
                    property bool enable: false
                }
            }

            property JsonObject language: JsonObject {
                property string ui: "auto" // UI language. "auto" for system locale, or specific language code like "zh_CN", "en_US"
                property JsonObject translator: JsonObject {
                    property string engine: "auto" // Run `trans -list-engines` for available engines. auto should use google
                    property string targetLanguage: "auto" // Run `trans -list-all` for available languages
                    property string sourceLanguage: "auto"
                }
            }

            property JsonObject launcher: JsonObject {
                property list<string> pinnedApps: [ "org.kde.dolphin", "kitty", "cmake-gui"]
            }

            property JsonObject light: JsonObject {
                property JsonObject night: JsonObject {
                    property bool automatic: true
                    property string from: "19:00" // Format: "HH:mm", 24-hour time
                    property string to: "06:30"   // Format: "HH:mm", 24-hour time
                    property int colorTemperature: 5000
                }
                property JsonObject antiFlashbang: JsonObject {
                    property bool enable: false
                }
            }

            property JsonObject lock: JsonObject {
                property bool useHyprlock: false
                property bool launchOnStartup: false
                property bool showWidgets: false
                // Which background widgets (by their qs.modules.ii.background.widgets
                // configEntryName, e.g. "clock", "weather", "todo") are allowed to show
                // on the lock screen, independent of their desktop configuration. An
                // empty list means "no restriction" (all desktop-enabled widgets may
                // show, matching legacy behavior); a non-empty list is treated as the
                // explicit allow-list. Only takes effect when showWidgets is true.
                property list<string> enabledWidgets: []
                property bool showMedia: true
                property bool showToolbars: true
                // Independent visibility for the left (username/media/keyboard) and
                // right (battery/sleep/power) toolbars, on top of the showToolbars
                // master switch.
                property bool showLeftToolbar: true
                property bool showRightToolbar: true
                property JsonObject blur: JsonObject {
                    property bool enable: true
                    property real radius: 100
                    property real extraZoom: 1.1
                    property int size: 20
                }
                property bool centerClock: true
                property bool showLockedText: true
                property JsonObject security: JsonObject {
                    property bool unlockKeyring: true
                    property bool requirePasswordToPower: false
                }
                property JsonObject biometrics: JsonObject {
                    // Fingerprint uses fprintd/PAM. Face auth is opt-in and requires
                    // a correctly configured PAM provider such as Howdy.
                    property bool enableFingerprint: true
                    property bool enableFaceAuth: false
                    property bool autoStartFingerprint: true
                    property bool autoStartFaceAuth: false
                    property bool showSensorAnimation: true
                    property int faceTimeoutSeconds: 8
                    // The command must exit 0 only after successful identity
                    // verification. `howdy test` is a sensible default for Howdy.
                    property string faceCommand: "howdy test"
                }
                property JsonObject layout: JsonObject {
                    property string passwordPlacement: "bottom" // bottom | center | left | right
                    property int offsetX: 0
                    property int offsetY: 0
                    property int bottomMargin: 20
                    property real scale: 1.0
                }
                property bool materialShapeChars: true
            }

            property JsonObject media: JsonObject {
                // Attempt to remove dupes (the aggregator playerctl one and browsers' native ones when there's plasma browser integration)
                property bool filterDuplicatePlayers: true
            }

            property JsonObject networking: JsonObject {
                property string userAgent: "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/123.0.0.0 Safari/537.36"
            }

            property JsonObject notifications: JsonObject {
                property int timeout: 7000
                property string position: "top_right"
                property string displayMode: "toast" // toast | compact | history | island
                property string style: "material" // material | glass | minimal
                property int maxVisible: 4
                property bool pauseOnHover: true
                property bool showCriticalWhenQuiet: true
                // Auto-DND: popups (not the persistent notification list)
                // stay quiet for as long as Privacy.screenSharing is true -
                // separate from the manual "silent" toggle so ending a share
                // never silently un-mutes someone who'd muted notifications
                // themselves, and starting one never silently overrides a
                // critical-alert allowance. See Notifications.qml's
                // popupInhibited/showCriticalWhenQuiet.
                property bool autoSilentOnScreenShare: true
                // Hovering a notification card briefly expands it, mirroring the
                // M3 island's embedded card behavior on the main popup/history surfaces.
                property bool expandOnHover: false
                property int hoverExpandDelay: 180
                // Optional per-app policy: [{ match: "discord", mode: "history",
                // timeout: 12000 }]. Modes are toast, history, and silent.
                property list<var> appRules: []
            }

            property JsonObject osd: JsonObject {
                property int timeout: 1000
            }

            property JsonObject osk: JsonObject {
                property string layout: "qwerty_full"
                property bool pinnedOnStartup: false
            }

            property JsonObject overlay: JsonObject {
                property bool openingZoomAnimation: true
                property bool darkenScreen: true
                property real clickthroughOpacity: 0.8
                property JsonObject floatingImage: JsonObject {
                    property string imageSource: "https://media.tenor.com/H5U5bJzj3oAAAAAi/kukuru.gif"
                    property real scale: 0.5
                }
            }

            property JsonObject overview: JsonObject {
                property bool enable: true
                property string style: "default"
                property string position: "top" // top | bottom | center
                property bool centerAnimation: true // animate centering in center mode
                property int centerAnimationDuration: 220 // ms
                property real scale: 0.18 // Relative to screen size
                property real rows: 2
                property real columns: 5
                property bool orderRightLeft: false
                property bool orderBottomUp: false
                property bool centerIcons: true
                property bool showWorkspacesInLauncher: true
                property bool hoverPreviewInBar: false
            }

            property JsonObject regionSelector: JsonObject {
                property JsonObject targetRegions: JsonObject {
                    property bool windows: true
                    property bool layers: false
                    property bool content: true
                    property bool showLabel: false
                    property real opacity: 0.3
                    property real contentRegionOpacity: 0.8
                    property int selectionPadding: 5
                }
                property JsonObject rect: JsonObject {
                    property bool showAimLines: true
                }
                property JsonObject circle: JsonObject {
                    property int strokeWidth: 6
                    property int padding: 10
                }
                property JsonObject annotation: JsonObject {
                    property bool useSatty: false
                }
            }

            property JsonObject resources: JsonObject {
                property int updateInterval: 3000
                property int historyLength: 60
            }

            property JsonObject tray: JsonObject {
                property bool monochromeIcons: true
                property bool showItemId: false
                property bool invertPinnedItems: true // Makes the below a whitelist for the tray and blacklist for the pinned area
                property list<var> pinnedItems: [ "Fcitx" ]
                property bool filterPassive: true
            }

            property JsonObject musicRecognition: JsonObject {
                property int timeout: 16
                property int interval: 4
            }

            property JsonObject search: JsonObject {
                property int nonAppResultDelay: 30 // This prevents lagging when typing
                property string engineBaseUrl: "https://www.google.com/search?q="
                property list<string> excludedSites: ["quora.com", "facebook.com"]
                property bool sloppy: false // Uses levenshtein distance based scoring instead of fuzzy sort. Very weird.
                property JsonObject prefix: JsonObject {
                    property bool showDefaultActionsWithoutPrefix: true
                    property string action: "/"
                    property string app: ">"
                    property string clipboard: ";"
                    property string emojis: ":"
                    property string keybinds: "<"
                    property string symbols: "."
                    property string math: "="
                    property string shellCommand: "$"
                    property string webSearch: "?"
                    property string files: "~"
                    property string sshHosts: "@"
                    property string systemServices: "!"
                }
                property JsonObject imageSearch: JsonObject {
                    property string imageSearchEngineBaseUrl: "https://lens.google.com/uploadbyurl?url="
                    property bool useCircleSelection: false
                }
                // Per-mode settings for the file/SSH-host/systemd-service search
                // prefixes (LauncherSearch.qml) - separate from prefix.* (which is
                // just the trigger character) so each mode can be tuned or turned
                // off independently.
                property JsonObject extras: JsonObject {
                    property bool filesEnable: true
                    property int filesMaxResults: 40
                    property bool sshHostsEnable: true
                    property bool systemServicesEnable: true
                    property int systemServicesMaxResults: 40
                    // System-scope units need pkexec to start/stop/restart; off by
                    // default is *not* the choice here since it's opt-out, not
                    // opt-in, but this lets someone who'd rather not see
                    // privileged actions in a launcher hide them entirely.
                    property bool systemServicesIncludeSystemScope: true
                }
            }

            property JsonObject sidebar: JsonObject {
                property bool banner: true
                property bool bottomGroup: true
                property bool mediaPlayer: false
                property string bannerImage: ""
                property bool keepRightSidebarLoaded: true
                property JsonObject translator: JsonObject {
                    property bool enable: false
                    property int delay: 300 // Delay before sending request. Reduces (potential) rate limits and lag.
                }
                property JsonObject media: JsonObject {
                    property bool enable: true
                    property bool artColors: false
                }
                
                property JsonObject ai: JsonObject {
                    property bool textFadeIn: false
                }
                property JsonObject booru: JsonObject {
                    property bool allowNsfw: false
                    property string defaultProvider: "yandere"
                    property int limit: 20
                    property JsonObject zerochan: JsonObject {
                        property string username: "[unset]"
                    }
                }
                property JsonObject cornerOpen: JsonObject {
                    property bool enable: true
                    property bool bottom: false
                    property bool valueScroll: true
                    property bool clickless: false
                    property int cornerRegionWidth: 250
                    property int cornerRegionHeight: 5
                    property string bottomLeftAction: "sidebarLeftOpen"
                    property string bottomRightAction: "sidebarRightOpen"
                    property string topLeftAction: "sidebarLeftOpen"
                    property string topRightAction: "sidebarRightOpen"
                    property bool visualize: false
                    property bool clicklessCornerEnd: true
                    property bool hoverAllCorners: false
                    property int clicklessCornerVerticalOffset: 1
                    property string leftScrollAction: "brightness" // brightness | volume
                    property string rightScrollAction: "volume" // brightness | volume
                }

                property JsonObject quickToggles: JsonObject {
                    property string style: "android" // Options: classic, android
                    property JsonObject android: JsonObject {
                        property int columns: 5
                        property list<var> toggles: [
                            { "size": 2, "type": "network" },
                            { "size": 2, "type": "bluetooth"  },
                            { "size": 1, "type": "idleInhibitor" },
                            { "size": 1, "type": "mic" },
                            { "size": 2, "type": "audio" },
                            { "size": 2, "type": "nightLight" }
                        ]
                    }
                }

                property JsonObject quickSliders: JsonObject {
                    property bool enable: true
                    property bool showMic: false
                    property bool showVolume: true
                    property bool showBrightness: true
                }
            }

            property JsonObject custom: JsonObject {
                property string distroIcon: "spark"
                property bool colorizeIcon: true
            }

            property JsonObject screenRecord: JsonObject {
                property string savePath: Directories.videos.replace("file://","") // strip "file://"
                property int frameRate: 60
                property string codec: "libx264"
                property string quality: "balanced" // balanced | high | archive
                property string audioMode: "output" // none | output | microphone | both
                property string outputSource: ""
                property string microphoneSource: ""
            }

            property JsonObject screenSnip: JsonObject {
                property string savePath: "" // only copy to clipboard when empty
                property int scalePercent: 100
                property string format: "png" // png | jpg
                property int jpegQuality: 92
            }

            property JsonObject screenCanvas: JsonObject {
                // ── Auto-open behaviour ─────────────────────────────────────
                property bool autoOpenImage: true          // Open editor automatically for screenshots
                property bool autoOpenVideo: true          // Open editor automatically for screen recordings
                // ── Close behaviour ─────────────────────────────────────────
                property bool closeOnSaveImage: false      // Close canvas after saving image
                property bool closeOnSaveVideo: false      // Close canvas after saving/exporting video
                property bool closeOnCopyImage: false      // Close canvas after copying image
                property bool closeOnCopyVideo: false      // Close canvas after copying video frame
                property bool closeOnClickOutside: true    // Click outside editor closes canvas
                property bool closeOnEsc: true             // Esc closes canvas
                property bool confirmCloseWhenUnsaved: true // Confirm if there are unsaved annotations
                // ── Video editor ────────────────────────────────────────────
                property bool videoAutoPlayOnOpen: false   // Auto-play video when opened
                property bool videoLoopPlayback: false     // Loop video playback
                property bool videoMutedOnOpen: false      // Start video muted
                property real defaultAnnotationDuration: 3.0 // Seconds a new annotation stays visible
                // ── Canvas / UX extras ──────────────────────────────────────
                property bool clearOnClose: true           // Clear drawings when canvas closes
                property bool showNotifications: true      // Show toast on save/copy/export
                property bool saveAlsoCopiesToClipboard: false // Also copy to clipboard when saving image
                property string defaultTool: "pen"         // pen, arrow, rect, circle, highlight, blur
                property int defaultStrokeWidth: 3         // 1..20
                property string defaultColor: "#ff0000"    // Default annotation colour
                property string imageSaveMode: "editedSuffix" // editedSuffix, overwrite, ask
                property real canvasDimOpacity: 0.3        // Background dim behind editor 0..1
            }

            property JsonObject sounds: JsonObject {
                property bool battery: false
                property bool pomodoro: false
                property string theme: "freedesktop"
            }

            property JsonObject time: JsonObject {
                // https://doc.qt.io/qt-6/qtime.html#toString
                property string format: "hh:mm"
                property bool showDate: true
                property string shortDateFormat: "dd/MM"
                property string dateWithYearFormat: "dd/MM/yyyy"
                property string dateFormat: "ddd, dd/MM"
                property JsonObject pomodoro: JsonObject {
                    property int breakTime: 300
                    property int cyclesBeforeLongBreak: 4
                    property int focus: 1500
                    property int longBreak: 900
                }
                property bool secondPrecision: false
            }

            property JsonObject updates: JsonObject {
                property bool enableCheck: true
                property int checkInterval: 120 // minutes
                property int adviseUpdateThreshold: 75 // packages
                property int stronglyAdviseUpdateThreshold: 200 // packages
            }
            
            property JsonObject wallpaperSelector: JsonObject {
                property bool useSystemFileDialog: false
                property bool showBlurBackground: false
                property bool showHomePath: true
                property string userPath: "" // This can be set to any path and it will show up as a quick access in the wallpaper selector"
                property string liveWallpapersPath: ""
                property bool showSearchbar: true
                property int columns: 4
                property bool closeAfterSelection: true
                property int changeInterval: 0 
            }

            property JsonObject windows: JsonObject {
                property bool showTitlebar: true // Client-side decoration for shell apps
                property bool centerTitle: true
            }

            property JsonObject hacks: JsonObject {
                property int arbitraryRaceConditionDelay: 20 // milliseconds
            }

            property JsonObject workSafety: JsonObject {
                property JsonObject enable: JsonObject {
                    property bool wallpaper: false
                    property bool clipboard: false
                }
                property JsonObject triggerCondition: JsonObject {
                    property list<string> networkNameKeywords: ["airport", "cafe", "college", "company", "eduroam", "free", "guest", "public", "school", "university"]
                    property list<string> fileKeywords: ["anime", "booru", "ecchi", "hentai", "yande.re", "konachan", "breast", "nipples", "pussy", "nsfw", "spoiler", "girl"]
                    property list<string> linkKeywords: ["hentai", "porn", "sukebei", "hitomi.la", "rule34", "gelbooru", "fanbox", "dlsite"]
                }
            }
        }
    }
}
