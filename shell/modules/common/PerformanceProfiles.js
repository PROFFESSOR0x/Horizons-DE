.pragma library

// One-shot performance/experience presets for Settings > Quick.
//
// Every entry has two halves that must be applied together (see
// Config.applyPerformanceProfile() + QuickConfig.qml's profile buttons):
//   - `configOverrides`: flat "dot.path": value pairs written straight into
//     Config.options via Config.setNestedValue() — anything this shell itself
//     reads reactively (background widgets, resource-polling interval, lock
//     blur, overview animation, motion scale...).
//   - `hyprlandKeys` + `animPreset`: the literal decoration:*/animations:*
//     Hyprland keys pushed via HyprlandConfig.setMany()/setAnimPreset() —
//     the same two-step shape InterfaceConfig.qml's own visual-effect picker
//     already uses to reach the compositor.
//
// Deliberately excluded from every tier: appearance.palette.* (color/scheme
// choice) — the user asked for these profiles to leave color alone and stay
// wallpaper-matched regardless of tier.
//
// `visualEffect` is applied through Config.applyVisualEffectExclusivity()
// rather than being listed in configOverrides directly, because blur/
// transparency/glass are mutually exclusive and that function is the one
// place enforcing it (see Config.qml) — duplicating the exclusivity logic
// here would risk drifting out of sync with it.
//
// Grounding for the ordering/weight of these levers: Hyprland's own
// performance wiki + community reports name blur (blur:size * blur:passes)
// as the dominant GPU cost, shadows and animations next — see
// https://wiki.hypr.land/hyprland-wiki/pages/Configuring/Performance/ and
// https://github.com/hyprwm/Hyprland/issues/7188. blur:new_optimizations is
// a strict no-downside win and is therefore never a lever — it's on in
// every tier, including Max Performance (where blur itself is off anyway).

// Background widgets that work with zero user-provided content/setup —
// safe to flip on in bulk. userCard/notes/todo/images/customImage need the
// user to have entered something (a name, a note, a folder, a file path) to
// not just show an empty/placeholder box, so only Max Experience — "turn
// everything on" — reaches for those too.
const AMBIENT_WIDGETS = [
    "clock", "weather", "calendar", "worldClock", "resources",
    "networkInfo", "uptime", "systemHistory", "media", "timers",
]
const CONTENT_WIDGETS = [
    "notes", "todo", "userCard", "images", "customImage", "visualizer",
]
const ALL_WIDGETS = AMBIENT_WIDGETS.concat(CONTENT_WIDGETS)

function widgetOverrides(enabledNames) {
    const enabled = {}
    for (const name of enabledNames) enabled[name] = true
    const out = {}
    for (const name of ALL_WIDGETS) {
        out[`background.widgets.${name}.enable`] = !!enabled[name]
    }
    return out
}

var profiles = [
    {
        id: "maxPerformance",
        displayName: "Max Performance",
        icon: "speed",
        description: "Everything costly off. No blur, no shadows, no animations, no background widgets.",
        visualEffect: "none",
        animPreset: "snappy",
        configOverrides: Object.assign({
            "hyprland.decoration.dimInactive": false,
            "hyprland.decoration.dimAround": false,
            "hyprland.animations.enable": false,
            "appearance.motion.style": "smooth",
            "appearance.motion.durationScale": 0.5,
            "background.wallpaperAnimation": "",
            "background.parallax.enableWorkspace": false,
            "background.parallax.enableSidebar": false,
            "resources.updateInterval": 8000,
            "overview.centerAnimation": false,
            "lock.blur.enable": false,
        }, widgetOverrides([])),
        hyprlandKeys: {
            "decoration:blur:enabled": 0,
            "decoration:blur:new_optimizations": 1,
            "decoration:shadow:enabled": 0,
            "animations:enabled": 0,
        },
    },
    {
        id: "performance",
        displayName: "Performance",
        icon: "bolt",
        description: "Light and fast, with basic window-open/close animation kept.",
        visualEffect: "none",
        animPreset: "snappy",
        configOverrides: Object.assign({
            "hyprland.decoration.dimInactive": false,
            "hyprland.decoration.dimAround": false,
            "hyprland.animations.enable": true,
            "hyprland.animations.animation": "snappy",
            "appearance.motion.style": "smooth",
            "appearance.motion.durationScale": 0.75,
            "background.wallpaperAnimation": "",
            "background.parallax.enableWorkspace": false,
            "background.parallax.enableSidebar": false,
            "resources.updateInterval": 5000,
            "overview.centerAnimation": true,
            "lock.blur.enable": false,
        }, widgetOverrides([])),
        hyprlandKeys: {
            "decoration:blur:enabled": 0,
            "decoration:blur:new_optimizations": 1,
            "decoration:shadow:enabled": 0,
            "animations:enabled": 1,
        },
    },
    {
        id: "balanced",
        displayName: "Balanced",
        icon: "balance",
        description: "The shipped default look: blur and shadows on, moderate motion.",
        visualEffect: "blur",
        animPreset: "smooth",
        configOverrides: Object.assign({
            "hyprland.decoration.blur.size": 4,
            "hyprland.decoration.blur.passes": 2,
            "hyprland.decoration.shadow.range": 20,
            "hyprland.decoration.shadow.renderPower": 3,
            "hyprland.decoration.dimInactive": false,
            "hyprland.decoration.dimAround": false,
            "hyprland.animations.enable": true,
            "hyprland.animations.animation": "smooth",
            "appearance.motion.style": "smooth",
            "appearance.motion.durationScale": 1.0,
            "background.wallpaperAnimation": "magic",
            "background.parallax.enableWorkspace": true,
            "background.parallax.enableSidebar": true,
            "resources.updateInterval": 3000,
            "overview.centerAnimation": true,
            "lock.blur.enable": true,
        }, widgetOverrides(["clock"])),
        hyprlandKeys: {
            "decoration:blur:enabled": 1,
            "decoration:blur:size": 4,
            "decoration:blur:passes": 2,
            "decoration:blur:new_optimizations": 1,
            "decoration:shadow:enabled": 1,
            "decoration:shadow:range": 20,
            "decoration:shadow:render_power": 3,
            "decoration:dim_inactive": 0,
            "decoration:dim_around": 0,
            "animations:enabled": 1,
        },
    },
    {
        id: "experience",
        displayName: "Experience",
        icon: "auto_awesome",
        description: "Bigger blur, dimmed inactive windows, parallax, and a fuller set of background widgets.",
        visualEffect: "blur",
        animPreset: "expressive",
        configOverrides: Object.assign({
            "hyprland.decoration.blur.size": 6,
            "hyprland.decoration.blur.passes": 3,
            "hyprland.decoration.shadow.range": 25,
            "hyprland.decoration.shadow.renderPower": 3,
            "hyprland.decoration.dimInactive": true,
            "hyprland.decoration.dimAround": false,
            "hyprland.animations.enable": true,
            "hyprland.animations.animation": "expressive",
            "appearance.motion.style": "expressive",
            "appearance.motion.durationScale": 1.15,
            "background.wallpaperAnimation": "magic",
            "background.parallax.enableWorkspace": true,
            "background.parallax.enableSidebar": true,
            "resources.updateInterval": 3000,
            "overview.centerAnimation": true,
            "lock.blur.enable": true,
        }, widgetOverrides(AMBIENT_WIDGETS)),
        hyprlandKeys: {
            "decoration:blur:enabled": 1,
            "decoration:blur:size": 6,
            "decoration:blur:passes": 3,
            "decoration:blur:new_optimizations": 1,
            "decoration:shadow:enabled": 1,
            "decoration:shadow:range": 25,
            "decoration:shadow:render_power": 3,
            "decoration:dim_inactive": 1,
            "decoration:dim_around": 0,
            "animations:enabled": 1,
        },
    },
    {
        id: "maxExperience",
        displayName: "Max Experience",
        icon: "auto_awesome",
        description: "Every effect on, Liquid Glass blur variant, every background widget on.",
        visualEffect: "glass",
        animPreset: "expressive",
        // On a Hyprland build that doesn't support decoration:blur:variant yet
        // (see HyprlandConfig.qml's blurVariantSupported probe), the button
        // still applies everything else and simply falls back to plain
        // Kawase blur instead of acrylic — never silently do nothing.
        configOverrides: Object.assign({
            "hyprland.decoration.blur.size": 8,
            "hyprland.decoration.blur.passes": 4,
            "hyprland.decoration.shadow.range": 30,
            "hyprland.decoration.shadow.renderPower": 4,
            "hyprland.decoration.dimInactive": true,
            "hyprland.decoration.dimAround": true,
            "hyprland.animations.enable": true,
            "hyprland.animations.animation": "expressive",
            "appearance.motion.style": "expressive",
            "appearance.motion.durationScale": 1.3,
            "background.wallpaperAnimation": "magic",
            "background.parallax.enableWorkspace": true,
            "background.parallax.enableSidebar": true,
            "resources.updateInterval": 2000,
            "overview.centerAnimation": true,
            "lock.blur.enable": true,
        }, widgetOverrides(ALL_WIDGETS)),
        hyprlandKeys: {
            "decoration:blur:enabled": 1,
            "decoration:blur:size": 8,
            "decoration:blur:passes": 4,
            "decoration:blur:new_optimizations": 1,
            "decoration:shadow:enabled": 1,
            "decoration:shadow:range": 30,
            "decoration:shadow:render_power": 4,
            "decoration:dim_inactive": 1,
            "decoration:dim_around": 1,
            "animations:enabled": 1,
        },
        // Only sent when the compositor actually supports the variant PR;
        // see QuickConfig.qml's apply function.
        hyprlandKeysIfVariantSupported: {
            "decoration:blur:variant": "acrylic",
        },
    },
]
