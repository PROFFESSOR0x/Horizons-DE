pragma Singleton
import QtQuick

/**
 * The 5 performance/experience profiles offered on Settings > Quick.
 *
 * Each entry is a self-contained bundle of every setting a profile touches,
 * split into three groups so callers know exactly where each value needs
 * to go:
 *   - config:  Config.options.* paths (dot-separated) -> value. Applied by
 *              Config.applyPerformanceProfile(), which only ever touches
 *              Config.options (no compositor calls, so Config.qml never
 *              has to import HyprlandConfig.qml and risk a circular import).
 *   - hypr:    literal "decoration:*"/"misc:*" Hyprland keys -> value,
 *              pushed live via HyprlandConfig.setMany() by whichever page
 *              applies the profile (same two-step shape InterfaceConfig.qml
 *              already uses for its visual-effect picker).
 *   - animPreset: the Hyprland animation preset name to push via
 *              HyprlandConfig.setAnimPreset() (see hyprconfigurator.py's
 *              ANIM_PRESETS) — omitted entirely for "Max Performance",
 *              which turns animations off instead of picking a preset.
 *
 * Deliberately excludes anything palette/color-related (Config.options.
 * appearance.palette, builtInTheme, wallpaperTheming, matugenDisabled) so
 * every tier still follows the user's own wallpaper-derived colors.
 *
 * Priority/ordering of levers matches real measured cost, not guesswork:
 * blur is the dominant GPU cost (Hyprland's own wiki + hyprwm/Hyprland#7188
 * cite ~20% vs ~1% GPU usage with/without it, and blur:size * blur:passes
 * as the tunable "amount" — kept modest even in the top tier since size
 * past ~5-6 just produces artifacts), shadows and animations are the next
 * documented levers, and background-widget polling / the audio visualizer
 * (cava) are this session's own first-hand-measured shell-side costs.
 * decoration:blur:new_optimizations is a strict no-downside win and is
 * never toggled by a profile - it's just always on.
 */
Singleton {
    id: root

    readonly property var profiles: [
        {
            id: "maxPerformance",
            name: "Max Performance",
            description: "No blur, no shadows, no animations, no decorative background widgets. As light as this shell gets.",
            icon: "speed",
            config: {
                "appearance.visualEffect": "none",
                "appearance.transparency.enable": false,
                "appearance.motion.style": "smooth",
                "appearance.motion.durationScale": 0.5,
                "hyprland.decoration.blur.enabled": false,
                "hyprland.decoration.blur.variant": "kawase",
                "hyprland.decoration.shadow.enabled": false,
                "hyprland.decoration.dimInactive": false,
                "hyprland.decoration.dimAround": false,
                "hyprland.animations.enable": false,
                "background.wallpaperAnimation": "",
                "background.parallax.enableWorkspace": false,
                "background.parallax.enableSidebar": false,
                "background.widgets.clock.enable": false,
                "background.widgets.weather.enable": false,
                "background.widgets.calendar.enable": false,
                "background.widgets.worldClock.enable": false,
                "background.widgets.notes.enable": false,
                "background.widgets.todo.enable": false,
                "background.widgets.userCard.enable": false,
                "background.widgets.images.enable": false,
                "background.widgets.visualizer.enable": false,
                "background.widgets.customImage.enable": false,
                "background.widgets.resources.enable": false,
                "background.widgets.networkInfo.enable": false,
                "background.widgets.uptime.enable": false,
                "background.widgets.systemHistory.enable": false,
                "resources.updateInterval": 8000,
                "overview.centerAnimation": false,
                "lock.blur.enable": false,
            },
            hypr: {
                "decoration:blur:enabled": 0,
                "decoration:blur:variant": "kawase",
                "decoration:blur:new_optimizations": 1,
                "decoration:shadow:enabled": 0,
                "decoration:dim_inactive": 0,
                "decoration:dim_around": 0,
                "animations:enabled": 0,
            },
            animPreset: "",
        },
        {
            id: "performance",
            name: "Performance",
            description: "Light blur only, quick snappy animations, background widgets off. Leans fast.",
            icon: "bolt",
            config: {
                "appearance.visualEffect": "none",
                "appearance.transparency.enable": false,
                "appearance.motion.style": "smooth",
                "appearance.motion.durationScale": 0.75,
                "hyprland.decoration.blur.enabled": false,
                "hyprland.decoration.blur.variant": "kawase",
                "hyprland.decoration.shadow.enabled": false,
                "hyprland.decoration.dimInactive": false,
                "hyprland.decoration.dimAround": false,
                "hyprland.animations.enable": true,
                "hyprland.animations.animation": "snappy",
                "background.wallpaperAnimation": "",
                "background.parallax.enableWorkspace": false,
                "background.parallax.enableSidebar": false,
                "background.widgets.clock.enable": false,
                "background.widgets.weather.enable": false,
                "background.widgets.calendar.enable": false,
                "background.widgets.worldClock.enable": false,
                "background.widgets.notes.enable": false,
                "background.widgets.todo.enable": false,
                "background.widgets.userCard.enable": false,
                "background.widgets.images.enable": false,
                "background.widgets.visualizer.enable": false,
                "background.widgets.customImage.enable": false,
                "background.widgets.resources.enable": false,
                "background.widgets.networkInfo.enable": false,
                "background.widgets.uptime.enable": false,
                "background.widgets.systemHistory.enable": false,
                "resources.updateInterval": 5000,
                "overview.centerAnimation": true,
                "lock.blur.enable": false,
            },
            hypr: {
                "decoration:blur:enabled": 0,
                "decoration:blur:variant": "kawase",
                "decoration:blur:new_optimizations": 1,
                "decoration:shadow:enabled": 0,
                "decoration:dim_inactive": 0,
                "decoration:dim_around": 0,
                "animations:enabled": 1,
            },
            animPreset: "snappy",
        },
        {
            id: "balanced",
            name: "Balanced",
            description: "Today's shipped defaults — moderate blur and shadows, standard motion, a couple of background widgets.",
            icon: "balance",
            config: {
                "appearance.visualEffect": "blur",
                "appearance.transparency.enable": false,
                "appearance.motion.style": "smooth",
                "appearance.motion.durationScale": 1.0,
                "hyprland.decoration.blur.enabled": true,
                "hyprland.decoration.blur.size": 4,
                "hyprland.decoration.blur.passes": 2,
                "hyprland.decoration.blur.variant": "kawase",
                "hyprland.decoration.shadow.enabled": true,
                "hyprland.decoration.shadow.range": 20,
                "hyprland.decoration.shadow.renderPower": 3,
                "hyprland.decoration.dimInactive": false,
                "hyprland.decoration.dimAround": false,
                "hyprland.animations.enable": true,
                "hyprland.animations.animation": "smooth",
                "background.wallpaperAnimation": "magic",
                "background.parallax.enableWorkspace": true,
                "background.parallax.enableSidebar": true,
                "background.widgets.clock.enable": true,
                "background.widgets.weather.enable": true,
                "background.widgets.calendar.enable": false,
                "background.widgets.worldClock.enable": false,
                "background.widgets.notes.enable": false,
                "background.widgets.todo.enable": false,
                "background.widgets.userCard.enable": false,
                "background.widgets.images.enable": false,
                "background.widgets.visualizer.enable": false,
                "background.widgets.customImage.enable": false,
                "background.widgets.resources.enable": false,
                "background.widgets.networkInfo.enable": false,
                "background.widgets.uptime.enable": false,
                "background.widgets.systemHistory.enable": false,
                "resources.updateInterval": 3000,
                "overview.centerAnimation": true,
                "lock.blur.enable": true,
            },
            hypr: {
                "decoration:blur:enabled": 1,
                "decoration:blur:size": 4,
                "decoration:blur:passes": 2,
                "decoration:blur:variant": "kawase",
                "decoration:blur:new_optimizations": 1,
                "decoration:shadow:enabled": 1,
                "decoration:shadow:range": 20,
                "decoration:shadow:render_power": 3,
                "decoration:dim_inactive": 0,
                "decoration:dim_around": 0,
                "animations:enabled": 1,
            },
            animPreset: "smooth",
        },
        {
            id: "experience",
            name: "Experience",
            description: "Fuller blur and shadows, expressive motion, dimmed inactive windows, most background widgets on. Leans rich.",
            icon: "auto_awesome",
            config: {
                "appearance.visualEffect": "blur",
                // transparency.enable/glass.enable are derived from
                // visualEffect (mutually exclusive with blur) by
                // Config.applyPerformanceProfile() itself, not set here.
                "appearance.motion.style": "expressive",
                "appearance.motion.durationScale": 1.15,
                "hyprland.decoration.blur.enabled": true,
                "hyprland.decoration.blur.size": 6,
                "hyprland.decoration.blur.passes": 3,
                "hyprland.decoration.blur.variant": "kawase",
                "hyprland.decoration.shadow.enabled": true,
                "hyprland.decoration.shadow.range": 25,
                "hyprland.decoration.shadow.renderPower": 3,
                "hyprland.decoration.dimInactive": true,
                "hyprland.decoration.dimAround": false,
                "hyprland.animations.enable": true,
                "hyprland.animations.animation": "expressive",
                "background.wallpaperAnimation": "magic",
                "background.parallax.enableWorkspace": true,
                "background.parallax.enableSidebar": true,
                "background.widgets.clock.enable": true,
                "background.widgets.weather.enable": true,
                "background.widgets.calendar.enable": true,
                "background.widgets.worldClock.enable": true,
                "background.widgets.notes.enable": true,
                "background.widgets.todo.enable": true,
                "background.widgets.userCard.enable": true,
                "background.widgets.images.enable": false,
                "background.widgets.visualizer.enable": false,
                "background.widgets.customImage.enable": false,
                "background.widgets.resources.enable": true,
                "background.widgets.networkInfo.enable": false,
                "background.widgets.uptime.enable": false,
                "background.widgets.systemHistory.enable": false,
                "resources.updateInterval": 3000,
                "overview.centerAnimation": true,
                "lock.blur.enable": true,
            },
            hypr: {
                "decoration:blur:enabled": 1,
                "decoration:blur:size": 6,
                "decoration:blur:passes": 3,
                "decoration:blur:variant": "kawase",
                "decoration:blur:new_optimizations": 1,
                "decoration:shadow:enabled": 1,
                "decoration:shadow:range": 25,
                "decoration:shadow:render_power": 3,
                "decoration:dim_inactive": 1,
                "decoration:dim_around": 0,
                "animations:enabled": 1,
            },
            animPreset: "expressive",
        },
        {
            id: "maxExperience",
            name: "Max Experience",
            description: "Every animation and every blur on, Liquid Glass (native Hyprland \"acrylic\" variant) by default. Falls back to a fuller plain blur if the running Hyprland doesn't support blur variants yet.",
            icon: "auto_awesome",
            // acrylicVariantOnly is applied only when HyprlandData.blurVariantSupported
            // is true at the time the profile is applied — see PerformanceProfiles.resolve().
            acrylicVariantOnly: {
                config: {
                    "appearance.visualEffect": "glass",
                    "hyprland.decoration.blur.variant": "acrylic",
                },
                hypr: {
                    "decoration:blur:variant": "acrylic",
                },
            },
            config: {
                "appearance.visualEffect": "blur",
                "appearance.transparency.enable": false,
                "appearance.motion.style": "expressive",
                "appearance.motion.durationScale": 1.3,
                "hyprland.decoration.blur.enabled": true,
                "hyprland.decoration.blur.size": 8,
                "hyprland.decoration.blur.passes": 4,
                "hyprland.decoration.blur.variant": "kawase",
                "hyprland.decoration.shadow.enabled": true,
                "hyprland.decoration.shadow.range": 30,
                "hyprland.decoration.shadow.renderPower": 4,
                "hyprland.decoration.dimInactive": true,
                "hyprland.decoration.dimAround": true,
                "hyprland.animations.enable": true,
                "hyprland.animations.animation": "expressive",
                "background.wallpaperAnimation": "magic",
                "background.parallax.enableWorkspace": true,
                "background.parallax.enableSidebar": true,
                "background.widgets.clock.enable": true,
                "background.widgets.weather.enable": true,
                "background.widgets.calendar.enable": true,
                "background.widgets.worldClock.enable": true,
                "background.widgets.notes.enable": true,
                "background.widgets.todo.enable": true,
                "background.widgets.userCard.enable": true,
                "background.widgets.images.enable": true,
                "background.widgets.visualizer.enable": true,
                "background.widgets.customImage.enable": false,
                "background.widgets.resources.enable": true,
                "background.widgets.networkInfo.enable": true,
                "background.widgets.uptime.enable": true,
                "background.widgets.systemHistory.enable": true,
                "resources.updateInterval": 2000,
                "overview.centerAnimation": true,
                "lock.blur.enable": true,
            },
            hypr: {
                "decoration:blur:enabled": 1,
                "decoration:blur:size": 8,
                "decoration:blur:passes": 4,
                "decoration:blur:variant": "kawase",
                "decoration:blur:new_optimizations": 1,
                "decoration:shadow:enabled": 1,
                "decoration:shadow:range": 30,
                "decoration:shadow:render_power": 4,
                "decoration:dim_inactive": 1,
                "decoration:dim_around": 1,
                "animations:enabled": 1,
            },
            animPreset: "expressive",
        },
    ]

    function byId(id) {
        return root.profiles.find(p => p.id === id) ?? null
    }

    // Merges a profile's base config/hypr maps with its acrylicVariantOnly
    // overrides when blurVariantSupported is true (only "maxExperience" has
    // one today, but this stays generic for any future tier that wants a
    // capability-gated override instead of a flat, always-applied value).
    function resolve(id, blurVariantSupported) {
        const profile = root.byId(id)
        if (!profile) return null
        if (!blurVariantSupported || !profile.acrylicVariantOnly) {
            return { config: profile.config, hypr: profile.hypr, animPreset: profile.animPreset ?? "" }
        }
        return {
            config: Object.assign({}, profile.config, profile.acrylicVariantOnly.config),
            hypr: Object.assign({}, profile.hypr, profile.acrylicVariantOnly.hypr),
            animPreset: profile.animPreset ?? "",
        }
    }
}
