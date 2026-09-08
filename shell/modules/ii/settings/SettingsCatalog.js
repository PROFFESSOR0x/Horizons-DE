.pragma library

// Stable settings destinations. Search does not instantiate a settings page.
var entries = [
    {
        "id": "QuickConfig.color-mode",
        "source": "QuickConfig",
        "route": "appearance",
        "routes": [
            "appearance"
        ],
        "label": "Color mode",
        "section": "Color mode",
        "legacyPage": "Quick",
        "legacySections": [
            "Color mode"
        ],
        "keywords": ""
    },
    {
        "id": "QuickConfig.color-mode-2",
        "source": "QuickConfig",
        "route": "appearance",
        "routes": [
            "appearance"
        ],
        "label": "Color mode",
        "section": "Color mode",
        "legacyPage": "Quick",
        "legacySections": [
            "Color mode"
        ],
        "keywords": ""
    },
    {
        "id": "QuickConfig.profile",
        "source": "QuickConfig",
        "route": "appearance",
        "routes": [
            "appearance"
        ],
        "label": "Profile",
        "section": "Performance",
        "legacyPage": "Quick",
        "legacySections": [
            "Performance / Experience"
        ],
        "keywords": "Config.options.appearance.performanceProfile"
    },
    {
        "id": "GeneralConfig.format",
        "source": "GeneralConfig",
        "route": "personal",
        "routes": [
            "personal"
        ],
        "label": "Format",
        "section": "Time",
        "legacyPage": "General",
        "legacySections": [
            "Time"
        ],
        "keywords": "Config.options.time.format"
    },
    {
        "id": "GeneralConfig.second-precision",
        "source": "GeneralConfig",
        "route": "personal",
        "routes": [
            "personal"
        ],
        "label": "Second precision",
        "section": "Time",
        "legacyPage": "General",
        "legacySections": [
            "Time"
        ],
        "keywords": "Config.options.time.secondPrecision"
    },
    {
        "id": "GeneralConfig.show-date",
        "source": "GeneralConfig",
        "route": "personal",
        "routes": [
            "personal"
        ],
        "label": "Show date",
        "section": "Time",
        "legacyPage": "General",
        "legacySections": [
            "Time"
        ],
        "keywords": "Config.options.time.showDate"
    },
    {
        "id": "GeneralConfig.clock-string-format",
        "source": "GeneralConfig",
        "route": "system",
        "routes": [
            "system"
        ],
        "label": "Clock String Format",
        "section": "Time",
        "legacyPage": "General",
        "legacySections": [
            "Time"
        ],
        "keywords": "Config.options.time.format"
    },
    {
        "id": "GeneralConfig.date-string-format",
        "source": "GeneralConfig",
        "route": "system",
        "routes": [
            "system"
        ],
        "label": "Date String Format",
        "section": "Time",
        "legacyPage": "General",
        "legacySections": [
            "Time"
        ],
        "keywords": "Config .options.time.dateFormat Config.options.time.dateFormat"
    },
    {
        "id": "GeneralConfig.screenshots",
        "source": "GeneralConfig",
        "route": "capture",
        "routes": [
            "capture"
        ],
        "label": "Screenshots",
        "section": "Capture behavior",
        "legacyPage": "General",
        "legacySections": [
            "Screen Canvas — Screenshot & Video Editor"
        ],
        "keywords": "Config.options.screenCanvas.imageResultMode"
    },
    {
        "id": "GeneralConfig.recordings",
        "source": "GeneralConfig",
        "route": "capture",
        "routes": [
            "capture"
        ],
        "label": "Recordings",
        "section": "Capture behavior",
        "legacyPage": "General",
        "legacySections": [
            "Screen Canvas — Screenshot & Video Editor"
        ],
        "keywords": "Config.options.screenCanvas.videoResultMode"
    },
    {
        "id": "GeneralConfig.close-after-saving-image",
        "source": "GeneralConfig",
        "route": "capture",
        "routes": [
            "capture"
        ],
        "label": "Close after saving image",
        "section": "Capture behavior",
        "legacyPage": "General",
        "legacySections": [
            "Screen Canvas — Screenshot & Video Editor"
        ],
        "keywords": "Config.options.screenCanvas.closeOnSaveImage"
    },
    {
        "id": "GeneralConfig.close-after-exporting-video",
        "source": "GeneralConfig",
        "route": "capture",
        "routes": [
            "capture"
        ],
        "label": "Close after exporting video",
        "section": "Capture behavior",
        "legacyPage": "General",
        "legacySections": [
            "Screen Canvas — Screenshot & Video Editor"
        ],
        "keywords": "Config.options.screenCanvas.closeOnSaveVideo"
    },
    {
        "id": "GeneralConfig.close-after-copying-image",
        "source": "GeneralConfig",
        "route": "capture",
        "routes": [
            "capture"
        ],
        "label": "Close after copying image",
        "section": "Capture behavior",
        "legacyPage": "General",
        "legacySections": [
            "Screen Canvas — Screenshot & Video Editor"
        ],
        "keywords": "Config.options.screenCanvas.closeOnCopyImage"
    },
    {
        "id": "GeneralConfig.close-after-copying-video",
        "source": "GeneralConfig",
        "route": "capture",
        "routes": [
            "capture"
        ],
        "label": "Close after copying video",
        "section": "Capture behavior",
        "legacyPage": "General",
        "legacySections": [
            "Screen Canvas — Screenshot & Video Editor"
        ],
        "keywords": "Config.options.screenCanvas.closeOnCopyVideo"
    },
    {
        "id": "GeneralConfig.click-outside-to-close",
        "source": "GeneralConfig",
        "route": "capture-details",
        "routes": [
            "capture-details"
        ],
        "label": "Click outside to close",
        "section": "Capture behavior",
        "legacyPage": "General",
        "legacySections": [
            "Screen Canvas — Screenshot & Video Editor"
        ],
        "keywords": "Config.options.screenCanvas.closeOnClickOutside"
    },
    {
        "id": "GeneralConfig.esc-closes-canvas",
        "source": "GeneralConfig",
        "route": "capture-details",
        "routes": [
            "capture-details"
        ],
        "label": "Esc closes canvas",
        "section": "Capture behavior",
        "legacyPage": "General",
        "legacySections": [
            "Screen Canvas — Screenshot & Video Editor"
        ],
        "keywords": "Config.options.screenCanvas.closeOnEsc"
    },
    {
        "id": "GeneralConfig.confirm-if-unsaved-annotations",
        "source": "GeneralConfig",
        "route": "capture",
        "routes": [
            "capture"
        ],
        "label": "Confirm if unsaved annotations",
        "section": "Capture behavior",
        "legacyPage": "General",
        "legacySections": [
            "Screen Canvas — Screenshot & Video Editor"
        ],
        "keywords": "Config.options.screenCanvas.confirmCloseWhenUnsaved"
    },
    {
        "id": "GeneralConfig.clear-annotations-when-closing",
        "source": "GeneralConfig",
        "route": "capture-details",
        "routes": [
            "capture-details"
        ],
        "label": "Clear annotations when closing",
        "section": "Capture behavior",
        "legacyPage": "General",
        "legacySections": [
            "Screen Canvas — Screenshot & Video Editor"
        ],
        "keywords": "Config.options.screenCanvas.clearOnClose"
    },
    {
        "id": "GeneralConfig.auto-play-video-on-open",
        "source": "GeneralConfig",
        "route": "capture-details",
        "routes": [
            "capture-details"
        ],
        "label": "Auto-play video on open",
        "section": "Capture behavior",
        "legacyPage": "General",
        "legacySections": [
            "Screen Canvas — Screenshot & Video Editor"
        ],
        "keywords": "Config.options.screenCanvas.videoAutoPlayOnOpen"
    },
    {
        "id": "GeneralConfig.loop-playback",
        "source": "GeneralConfig",
        "route": "capture-details",
        "routes": [
            "capture-details"
        ],
        "label": "Loop playback",
        "section": "Capture behavior",
        "legacyPage": "General",
        "legacySections": [
            "Screen Canvas — Screenshot & Video Editor"
        ],
        "keywords": "Config.options.screenCanvas.videoLoopPlayback"
    },
    {
        "id": "GeneralConfig.start-muted",
        "source": "GeneralConfig",
        "route": "capture-details",
        "routes": [
            "capture-details"
        ],
        "label": "Start muted",
        "section": "Capture behavior",
        "legacyPage": "General",
        "legacySections": [
            "Screen Canvas — Screenshot & Video Editor"
        ],
        "keywords": "Config.options.screenCanvas.videoMutedOnOpen"
    },
    {
        "id": "GeneralConfig.default-annotation-duration-s",
        "source": "GeneralConfig",
        "route": "capture-details",
        "routes": [
            "capture-details"
        ],
        "label": "Default annotation duration (s)",
        "section": "Capture behavior",
        "legacyPage": "General",
        "legacySections": [
            "Screen Canvas — Screenshot & Video Editor"
        ],
        "keywords": "Config.options.screenCanvas.defaultAnnotationDuration"
    },
    {
        "id": "GeneralConfig.default-tool",
        "source": "GeneralConfig",
        "route": "capture-details",
        "routes": [
            "capture-details"
        ],
        "label": "Default tool",
        "section": "Capture behavior",
        "legacyPage": "General",
        "legacySections": [
            "Screen Canvas — Screenshot & Video Editor"
        ],
        "keywords": "Config.options.screenCanvas.defaultTool"
    },
    {
        "id": "GeneralConfig.default-stroke-width",
        "source": "GeneralConfig",
        "route": "capture-details",
        "routes": [
            "capture-details"
        ],
        "label": "Default stroke width",
        "section": "Capture behavior",
        "legacyPage": "General",
        "legacySections": [
            "Screen Canvas — Screenshot & Video Editor"
        ],
        "keywords": "Config.options.screenCanvas.defaultStrokeWidth"
    },
    {
        "id": "GeneralConfig.also-copy-on-save",
        "source": "GeneralConfig",
        "route": "capture",
        "routes": [
            "capture"
        ],
        "label": "Also copy on save",
        "section": "Capture behavior",
        "legacyPage": "General",
        "legacySections": [
            "Screen Canvas — Screenshot & Video Editor"
        ],
        "keywords": "Config.options.screenCanvas.saveAlsoCopiesToClipboard"
    },
    {
        "id": "GeneralConfig.image-save-mode",
        "source": "GeneralConfig",
        "route": "capture",
        "routes": [
            "capture"
        ],
        "label": "Image save mode",
        "section": "Capture behavior",
        "legacyPage": "General",
        "legacySections": [
            "Screen Canvas — Screenshot & Video Editor"
        ],
        "keywords": "Config.options.screenCanvas.imageSaveMode"
    },
    {
        "id": "GeneralConfig.show-notifications-toasts",
        "source": "GeneralConfig",
        "route": "capture",
        "routes": [
            "capture"
        ],
        "label": "Show notifications / toasts",
        "section": "Capture behavior",
        "legacyPage": "General",
        "legacySections": [
            "Screen Canvas — Screenshot & Video Editor"
        ],
        "keywords": "Config.options.screenCanvas.showNotifications"
    },
    {
        "id": "GeneralConfig.canvas-dim-opacity",
        "source": "GeneralConfig",
        "route": "capture-details",
        "routes": [
            "capture-details"
        ],
        "label": "Canvas dim opacity %",
        "section": "Capture behavior",
        "legacyPage": "General",
        "legacySections": [
            "Screen Canvas — Screenshot & Video Editor"
        ],
        "keywords": "Config.options.screenCanvas.canvasDimOpacity"
    },
    {
        "id": "GeneralConfig.low-warning",
        "source": "GeneralConfig",
        "route": "session-details",
        "routes": [
            "session-details"
        ],
        "label": "Low warning",
        "section": "Battery",
        "legacyPage": "General",
        "legacySections": [
            "Battery"
        ],
        "keywords": "Config.options.battery.low"
    },
    {
        "id": "GeneralConfig.critical-warning",
        "source": "GeneralConfig",
        "route": "session-details",
        "routes": [
            "session-details"
        ],
        "label": "Critical warning",
        "section": "Battery",
        "legacyPage": "General",
        "legacySections": [
            "Battery"
        ],
        "keywords": "Config.options.battery.critical"
    },
    {
        "id": "GeneralConfig.automatic-suspend",
        "source": "GeneralConfig",
        "route": "session",
        "routes": [
            "session"
        ],
        "label": "Automatic suspend",
        "section": "Battery",
        "legacyPage": "General",
        "legacySections": [
            "Battery"
        ],
        "keywords": "Config.options.battery.automaticSuspend"
    },
    {
        "id": "GeneralConfig.at",
        "source": "GeneralConfig",
        "route": "session-details",
        "routes": [
            "session-details"
        ],
        "label": "at",
        "section": "Battery",
        "legacyPage": "General",
        "legacySections": [
            "Battery"
        ],
        "keywords": "Config.options.battery.automaticSuspend Config.options.battery.suspend"
    },
    {
        "id": "GeneralConfig.full-warning",
        "source": "GeneralConfig",
        "route": "session-details",
        "routes": [
            "session-details"
        ],
        "label": "Full warning",
        "section": "Battery",
        "legacyPage": "General",
        "legacySections": [
            "Battery"
        ],
        "keywords": "Config.options.battery.full"
    },
    {
        "id": "GeneralConfig.earbang-protection",
        "source": "GeneralConfig",
        "route": "notifications",
        "routes": [
            "notifications"
        ],
        "label": "Earbang protection",
        "section": "Audio",
        "legacyPage": "General",
        "legacySections": [
            "Audio"
        ],
        "keywords": "Config.options.audio.protection.enable"
    },
    {
        "id": "GeneralConfig.max-allowed-increase",
        "source": "GeneralConfig",
        "route": "notification-rules",
        "routes": [
            "notification-rules"
        ],
        "label": "Max allowed increase",
        "section": "Audio",
        "legacyPage": "General",
        "legacySections": [
            "Audio"
        ],
        "keywords": "Config.options.audio.protection.maxAllowedIncrease"
    },
    {
        "id": "GeneralConfig.volume-limit",
        "source": "GeneralConfig",
        "route": "notifications",
        "routes": [
            "notifications"
        ],
        "label": "Volume limit",
        "section": "Audio",
        "legacyPage": "General",
        "legacySections": [
            "Audio"
        ],
        "keywords": "Config.options.audio.protection.maxAllowed"
    },
    {
        "id": "GeneralConfig.battery",
        "source": "GeneralConfig",
        "route": "notifications",
        "routes": [
            "notifications"
        ],
        "label": "Battery",
        "section": "Sounds",
        "legacyPage": "General",
        "legacySections": [
            "Sounds"
        ],
        "keywords": "Config.options.sounds.battery"
    },
    {
        "id": "GeneralConfig.pomodoro",
        "source": "GeneralConfig",
        "route": "notifications",
        "routes": [
            "notifications"
        ],
        "label": "Pomodoro",
        "section": "Sounds",
        "legacyPage": "General",
        "legacySections": [
            "Sounds"
        ],
        "keywords": "Config.options.sounds.pomodoro"
    },
    {
        "id": "GeneralConfig.locale-code",
        "source": "GeneralConfig",
        "route": "system",
        "routes": [
            "system"
        ],
        "label": "Locale code",
        "section": "Language",
        "legacyPage": "General",
        "legacySections": [
            "Language"
        ],
        "keywords": "Config.options.language.ui"
    },
    {
        "id": "GeneralConfig.language",
        "source": "GeneralConfig",
        "route": "system",
        "routes": [
            "system"
        ],
        "label": "Generate interface translations",
        "section": "Language",
        "legacyPage": "General",
        "legacySections": [
            "Language"
        ],
        "keywords": ""
    },
    {
        "id": "GeneralConfig.hide-clipboard-images-copied-from-sussy-sources",
        "source": "GeneralConfig",
        "route": "apps",
        "routes": [
            "apps"
        ],
        "label": "Hide clipboard images copied from sussy sources",
        "section": "Work safety",
        "legacyPage": "General",
        "legacySections": [
            "Work safety"
        ],
        "keywords": "Config.options.workSafety.enable.clipboard"
    },
    {
        "id": "GeneralConfig.hide-sussy-anime-wallpapers",
        "source": "GeneralConfig",
        "route": "apps",
        "routes": [
            "apps"
        ],
        "label": "Hide sussy/anime wallpapers",
        "section": "Work safety",
        "legacyPage": "General",
        "legacySections": [
            "Work safety"
        ],
        "keywords": "Config.options.workSafety.enable.wallpaper"
    },
    {
        "id": "BackgroundConfig.use-same-wallpaper-for-both",
        "source": "BackgroundConfig",
        "route": "appearance",
        "routes": [
            "appearance"
        ],
        "label": "Use same wallpaper for both",
        "section": "Wallpaper",
        "legacyPage": "Desktop",
        "legacySections": [
            "Wallpaper"
        ],
        "keywords": "Config.options.background.lockWall"
    },
    {
        "id": "BackgroundConfig.preview-wallpaper",
        "source": "BackgroundConfig",
        "route": "appearance",
        "routes": [
            "appearance"
        ],
        "label": "Preview wallpaper",
        "section": "Wallpaper",
        "legacyPage": "Desktop",
        "legacySections": [
            "Wallpaper"
        ],
        "keywords": "Config.options.background.enableWallpaperPreview"
    },
    {
        "id": "BackgroundConfig.blur-wall",
        "source": "BackgroundConfig",
        "route": "widget-details",
        "routes": [
            "widget-details"
        ],
        "label": "Blur wall",
        "section": "Wallpaper",
        "legacyPage": "Desktop",
        "legacySections": [
            "Wallpaper"
        ],
        "keywords": "Config.options.background.showBlur"
    },
    {
        "id": "BackgroundConfig.split-blur-amount",
        "source": "BackgroundConfig",
        "route": "widget-details",
        "routes": [
            "widget-details"
        ],
        "label": "Split blur amount",
        "section": "Wallpaper",
        "legacyPage": "Desktop",
        "legacySections": [
            "Wallpaper"
        ],
        "keywords": "Config.options.background.showBlur Config.options.background.splitRatio"
    },
    {
        "id": "BackgroundConfig.split-blur-side",
        "source": "BackgroundConfig",
        "route": "widget-details",
        "routes": [
            "widget-details"
        ],
        "label": "Split blur side",
        "section": "Wallpaper",
        "legacyPage": "Desktop",
        "legacySections": [
            "Wallpaper"
        ],
        "keywords": "Config.options.background.showBlur Config.options.background.splitSide"
    },
    {
        "id": "BackgroundConfig.wallpaper-change-interval-min",
        "source": "BackgroundConfig",
        "route": "appearance",
        "routes": [
            "appearance"
        ],
        "label": "Wallpaper change interval (min)",
        "section": "Wallpaper",
        "legacyPage": "Desktop",
        "legacySections": [
            "Wallpaper"
        ],
        "keywords": "Config.options.wallpaperSelector.changeInterval"
    },
    {
        "id": "BackgroundConfig.enable",
        "source": "BackgroundConfig",
        "route": "widget-details",
        "routes": [
            "widget-details"
        ],
        "label": "Enable",
        "section": "Centered wallpaper",
        "legacyPage": "Desktop",
        "legacySections": [
            "Wallpaper",
            "Centered wallpaper"
        ],
        "keywords": "Config.options.background.centeredWallpaper"
    },
    {
        "id": "BackgroundConfig.show-only-when-locked",
        "source": "BackgroundConfig",
        "route": "widget-details",
        "routes": [
            "widget-details"
        ],
        "label": "Show only when locked",
        "section": "Centered wallpaper",
        "legacyPage": "Desktop",
        "legacySections": [
            "Wallpaper",
            "Centered wallpaper"
        ],
        "keywords": "Config.options.background.centeredWallpaperOnlyWhenLocked Config.options.background.centeredWallpaper"
    },
    {
        "id": "BackgroundConfig.background-color",
        "source": "BackgroundConfig",
        "route": "widget-details",
        "routes": [
            "widget-details"
        ],
        "label": "Background Color",
        "section": "Centered wallpaper",
        "legacyPage": "Desktop",
        "legacySections": [
            "Wallpaper",
            "Centered wallpaper"
        ],
        "keywords": "Config.options.background.centeredWallpaper Config.options.background.centeredWallpaperColor"
    },
    {
        "id": "BackgroundConfig.size",
        "source": "BackgroundConfig",
        "route": "widget-details",
        "routes": [
            "widget-details"
        ],
        "label": "Size",
        "section": "Centered wallpaper",
        "legacyPage": "Desktop",
        "legacySections": [
            "Wallpaper",
            "Centered wallpaper"
        ],
        "keywords": "Config.options.background.centeredWallpaper Config.options.background.centeredWallpaperSize"
    },
    {
        "id": "BackgroundConfig.placement-strategy",
        "source": "BackgroundConfig",
        "route": "widget-details",
        "routes": [
            "widget-details"
        ],
        "label": "Placement strategy",
        "section": "Clock",
        "legacyPage": "Desktop",
        "legacySections": [
            "Clock"
        ],
        "keywords": "Config.options.background.widgets.clock.placementStrategy"
    },
    {
        "id": "BackgroundConfig.clock-style",
        "source": "BackgroundConfig",
        "route": "widgets",
        "routes": [
            "widgets"
        ],
        "label": "Clock style",
        "section": "Clock",
        "legacyPage": "Desktop",
        "legacySections": [
            "Clock"
        ],
        "keywords": "Config.options.background.widgets.clock.style"
    },
    {
        "id": "BackgroundConfig.clock-style-locked",
        "source": "BackgroundConfig",
        "route": "widgets",
        "routes": [
            "widgets"
        ],
        "label": "Clock style (locked)",
        "section": "Clock",
        "legacyPage": "Desktop",
        "legacySections": [
            "Clock"
        ],
        "keywords": "Config.options.background.widgets.clock.styleLocked"
    },
    {
        "id": "BackgroundConfig.vertical",
        "source": "BackgroundConfig",
        "route": "widgets",
        "routes": [
            "widgets"
        ],
        "label": "Vertical",
        "section": "Digital clock settings",
        "legacyPage": "Desktop",
        "legacySections": [
            "Clock",
            "Digital clock settings"
        ],
        "keywords": "Config.options.background.widgets.clock.digital.vertical"
    },
    {
        "id": "BackgroundConfig.show-date",
        "source": "BackgroundConfig",
        "route": "widgets",
        "routes": [
            "widgets"
        ],
        "label": "Show date",
        "section": "Digital clock settings",
        "legacyPage": "Desktop",
        "legacySections": [
            "Clock",
            "Digital clock settings"
        ],
        "keywords": "Config.options.background.widgets.clock.digital.showDate"
    },
    {
        "id": "BackgroundConfig.animate-time-change",
        "source": "BackgroundConfig",
        "route": "widget-details",
        "routes": [
            "widget-details"
        ],
        "label": "Animate time change",
        "section": "Digital clock settings",
        "legacyPage": "Desktop",
        "legacySections": [
            "Clock",
            "Digital clock settings"
        ],
        "keywords": "Config.options.background.widgets.clock.digital.animateChange"
    },
    {
        "id": "BackgroundConfig.use-adaptive-alignment",
        "source": "BackgroundConfig",
        "route": "widget-details",
        "routes": [
            "widget-details"
        ],
        "label": "Use adaptive alignment",
        "section": "Digital clock settings",
        "legacyPage": "Desktop",
        "legacySections": [
            "Clock",
            "Digital clock settings"
        ],
        "keywords": "Config.options.background.widgets.clock.digital.adaptiveAlignment"
    },
    {
        "id": "BackgroundConfig.automatic-colors",
        "source": "BackgroundConfig",
        "route": "widgets",
        "routes": [
            "widgets"
        ],
        "label": "Automatic colors",
        "section": "Digital clock settings",
        "legacyPage": "Desktop",
        "legacySections": [
            "Clock",
            "Digital clock settings"
        ],
        "keywords": "Config.options.background.widgets.clock.color"
    },
    {
        "id": "BackgroundConfig.color",
        "source": "BackgroundConfig",
        "route": "widgets",
        "routes": [
            "widgets"
        ],
        "label": "Color",
        "section": "Digital clock settings",
        "legacyPage": "Desktop",
        "legacySections": [
            "Clock",
            "Digital clock settings"
        ],
        "keywords": "Config.options.background.widgets.clock.color"
    },
    {
        "id": "BackgroundConfig.font-family",
        "source": "BackgroundConfig",
        "route": "widgets",
        "routes": [
            "widgets"
        ],
        "label": "Font family",
        "section": "Digital clock settings",
        "legacyPage": "Desktop",
        "legacySections": [
            "Clock",
            "Digital clock settings"
        ],
        "keywords": "Config.options.background.widgets.clock.digital.font.family"
    },
    {
        "id": "BackgroundConfig.font-weight",
        "source": "BackgroundConfig",
        "route": "widget-details",
        "routes": [
            "widget-details"
        ],
        "label": "Font weight",
        "section": "Digital clock settings",
        "legacyPage": "Desktop",
        "legacySections": [
            "Clock",
            "Digital clock settings"
        ],
        "keywords": "Config.options.background.widgets.clock.digital.font.weight"
    },
    {
        "id": "BackgroundConfig.font-size",
        "source": "BackgroundConfig",
        "route": "widgets",
        "routes": [
            "widgets"
        ],
        "label": "Font size",
        "section": "Digital clock settings",
        "legacyPage": "Desktop",
        "legacySections": [
            "Clock",
            "Digital clock settings"
        ],
        "keywords": "Config.options.background.widgets.clock.digital.font.size"
    },
    {
        "id": "BackgroundConfig.font-width",
        "source": "BackgroundConfig",
        "route": "widget-details",
        "routes": [
            "widget-details"
        ],
        "label": "Font width",
        "section": "Digital clock settings",
        "legacyPage": "Desktop",
        "legacySections": [
            "Clock",
            "Digital clock settings"
        ],
        "keywords": "Config.options.background.widgets.clock.digital.font.width"
    },
    {
        "id": "BackgroundConfig.font-roundness",
        "source": "BackgroundConfig",
        "route": "widget-details",
        "routes": [
            "widget-details"
        ],
        "label": "Font roundness",
        "section": "Digital clock settings",
        "legacyPage": "Desktop",
        "legacySections": [
            "Clock",
            "Digital clock settings"
        ],
        "keywords": "Config.options.background.widgets.clock.digital.font.roundness"
    },
    {
        "id": "BackgroundConfig.auto-styling-with-gemini",
        "source": "BackgroundConfig",
        "route": "widget-details",
        "routes": [
            "widget-details"
        ],
        "label": "Auto styling with Gemini",
        "section": "Cookie clock settings",
        "legacyPage": "Desktop",
        "legacySections": [
            "Clock",
            "Cookie clock settings"
        ],
        "keywords": "Config.options.background.widgets.clock.cookie.aiStyling"
    },
    {
        "id": "BackgroundConfig.use-old-sine-wave-cookie-implementation",
        "source": "BackgroundConfig",
        "route": "widget-details",
        "routes": [
            "widget-details"
        ],
        "label": "Use old sine wave cookie implementation",
        "section": "Cookie clock settings",
        "legacyPage": "Desktop",
        "legacySections": [
            "Clock",
            "Cookie clock settings"
        ],
        "keywords": "Config.options.background.widgets.clock.cookie.useSineCookie"
    },
    {
        "id": "BackgroundConfig.sides",
        "source": "BackgroundConfig",
        "route": "widget-details",
        "routes": [
            "widget-details"
        ],
        "label": "Sides",
        "section": "Cookie clock settings",
        "legacyPage": "Desktop",
        "legacySections": [
            "Clock",
            "Cookie clock settings"
        ],
        "keywords": "Config.options.background.widgets.clock.cookie.sides"
    },
    {
        "id": "BackgroundConfig.constantly-rotate",
        "source": "BackgroundConfig",
        "route": "widget-details",
        "routes": [
            "widget-details"
        ],
        "label": "Constantly rotate",
        "section": "Cookie clock settings",
        "legacyPage": "Desktop",
        "legacySections": [
            "Clock",
            "Cookie clock settings"
        ],
        "keywords": "Config.options.background.widgets.clock.cookie.constantlyRotate"
    },
    {
        "id": "BackgroundConfig.hour-marks",
        "source": "BackgroundConfig",
        "route": "widget-details",
        "routes": [
            "widget-details"
        ],
        "label": "Hour marks",
        "section": "Cookie clock settings",
        "legacyPage": "Desktop",
        "legacySections": [
            "Clock",
            "Cookie clock settings"
        ],
        "keywords": "Config.options.background.widgets.clock.cookie.dialNumberStyle Config.options.background.widgets.clock.cookie.hourMarks"
    },
    {
        "id": "BackgroundConfig.digits-in-the-middle",
        "source": "BackgroundConfig",
        "route": "widget-details",
        "routes": [
            "widget-details"
        ],
        "label": "Digits in the middle",
        "section": "Cookie clock settings",
        "legacyPage": "Desktop",
        "legacySections": [
            "Clock",
            "Cookie clock settings"
        ],
        "keywords": "Config.options.background.widgets.clock.cookie.dialNumberStyle Config.options.background.widgets.clock.cookie.timeIndicators"
    },
    {
        "id": "BackgroundConfig.clock",
        "source": "BackgroundConfig",
        "route": "widget-details",
        "routes": [
            "widget-details"
        ],
        "label": "Dial style",
        "section": "Clock",
        "legacyPage": "Desktop",
        "legacySections": [
            "Clock"
        ],
        "keywords": "Config.options.background.widgets.clock.cookie.dialNumberStyle Config.options.background.widgets.clock.cookie.hourMarks Config.options.background.widgets.clock.cookie.timeIndicators"
    },
    {
        "id": "BackgroundConfig.hour-hand",
        "source": "BackgroundConfig",
        "route": "widget-details",
        "routes": [
            "widget-details"
        ],
        "label": "Hour hand",
        "section": "Clock",
        "legacyPage": "Desktop",
        "legacySections": [
            "Clock"
        ],
        "keywords": "Config.options.background.widgets.clock.cookie.hourHandStyle"
    },
    {
        "id": "BackgroundConfig.minute-hand",
        "source": "BackgroundConfig",
        "route": "widget-details",
        "routes": [
            "widget-details"
        ],
        "label": "Minute hand",
        "section": "Clock",
        "legacyPage": "Desktop",
        "legacySections": [
            "Clock"
        ],
        "keywords": "Config.options.background.widgets.clock.cookie.minuteHandStyle"
    },
    {
        "id": "BackgroundConfig.second-hand",
        "source": "BackgroundConfig",
        "route": "widget-details",
        "routes": [
            "widget-details"
        ],
        "label": "Second hand",
        "section": "Clock",
        "legacyPage": "Desktop",
        "legacySections": [
            "Clock"
        ],
        "keywords": "Config.options.background.widgets.clock.cookie.secondHandStyle"
    },
    {
        "id": "BackgroundConfig.date-style",
        "source": "BackgroundConfig",
        "route": "widget-details",
        "routes": [
            "widget-details"
        ],
        "label": "Date style",
        "section": "Clock",
        "legacyPage": "Desktop",
        "legacySections": [
            "Clock"
        ],
        "keywords": "Config.options.background.widgets.clock.cookie.dateStyle"
    },
    {
        "id": "BackgroundConfig.pixel-clock-orientation",
        "source": "BackgroundConfig",
        "route": "widgets",
        "routes": [
            "widgets"
        ],
        "label": "Pixel clock orientation",
        "section": "Pixel Clock Settings",
        "legacyPage": "Desktop",
        "legacySections": [
            "Clock",
            "Pixel Clock Settings"
        ],
        "keywords": "Config.options.background.widgets.clock.style Config.options.background.widgets.clock.pixel.orientation"
    },
    {
        "id": "BackgroundConfig.follow-clock-font",
        "source": "BackgroundConfig",
        "route": "widgets",
        "routes": [
            "widgets"
        ],
        "label": "Follow Clock Font",
        "section": "Quote",
        "legacyPage": "Desktop",
        "legacySections": [
            "Clock",
            "Quote"
        ],
        "keywords": "Config.options.background.widgets.clock.style Config.options.background.widgets.clock.quote.followClock"
    },
    {
        "id": "BackgroundConfig.quote",
        "source": "BackgroundConfig",
        "route": "widgets",
        "routes": [
            "widgets"
        ],
        "label": "Quote",
        "section": "Quote",
        "legacyPage": "Desktop",
        "legacySections": [
            "Clock",
            "Quote"
        ],
        "keywords": "Config.options.background.widgets.clock.quote.text"
    },
    {
        "id": "BackgroundConfig.show-widgets-on",
        "source": "BackgroundConfig",
        "route": "widgets",
        "routes": [
            "widgets"
        ],
        "label": "Show widgets on",
        "section": "Show widgets on",
        "legacyPage": "Desktop",
        "legacySections": [
            "Widgets",
            "Show widgets on"
        ],
        "keywords": "Config.options.background"
    },
    {
        "id": "BackgroundConfig.choose-where-each-widget-appears",
        "source": "BackgroundConfig",
        "route": "widgets",
        "routes": [
            "widgets"
        ],
        "label": "Choose where each widget appears",
        "section": "Widgets",
        "legacyPage": "Desktop",
        "legacySections": [
            "Widgets"
        ],
        "keywords": ""
    },
    {
        "id": "BackgroundConfig.visualizer",
        "source": "BackgroundConfig",
        "route": "widget-details",
        "routes": [
            "widget-details"
        ],
        "label": "Visualizer",
        "section": "Visualizer",
        "legacyPage": "Desktop",
        "legacySections": [
            "Widgets",
            "Visualizer"
        ],
        "keywords": ""
    },
    {
        "id": "BackgroundConfig.pause-while-a-window-covers-the-desktop",
        "source": "BackgroundConfig",
        "route": "widget-details",
        "routes": [
            "widget-details"
        ],
        "label": "Pause while a window covers the desktop",
        "section": "Visualizer",
        "legacyPage": "Desktop",
        "legacySections": [
            "Widgets",
            "Visualizer"
        ],
        "keywords": "Config.options.background.widgets.visualizer.hideWhenObscured"
    },
    {
        "id": "BackgroundConfig.width",
        "source": "BackgroundConfig",
        "route": "widget-details",
        "routes": [
            "widget-details"
        ],
        "label": "Width",
        "section": "Visualizer",
        "legacyPage": "Desktop",
        "legacySections": [
            "Widgets",
            "Visualizer"
        ],
        "keywords": "Config.options.background.widgets.visualizer.width"
    },
    {
        "id": "BackgroundConfig.maximum-height",
        "source": "BackgroundConfig",
        "route": "widget-details",
        "routes": [
            "widget-details"
        ],
        "label": "Maximum height",
        "section": "Visualizer",
        "legacyPage": "Desktop",
        "legacySections": [
            "Widgets",
            "Visualizer"
        ],
        "keywords": "Config.options.background.widgets.visualizer.height"
    },
    {
        "id": "BackgroundConfig.frequency-bands",
        "source": "BackgroundConfig",
        "route": "widget-details",
        "routes": [
            "widget-details"
        ],
        "label": "Frequency bands",
        "section": "Visualizer",
        "legacyPage": "Desktop",
        "legacySections": [
            "Widgets",
            "Visualizer"
        ],
        "keywords": "Config.options.background.widgets.visualizer.barCount"
    },
    {
        "id": "BackgroundConfig.noise-gate",
        "source": "BackgroundConfig",
        "route": "widget-details",
        "routes": [
            "widget-details"
        ],
        "label": "Noise gate",
        "section": "Visualizer",
        "legacyPage": "Desktop",
        "legacySections": [
            "Widgets",
            "Visualizer"
        ],
        "keywords": "Config.options.background.widgets.visualizer.noiseFloor"
    },
    {
        "id": "BackgroundConfig.rise-response",
        "source": "BackgroundConfig",
        "route": "widget-details",
        "routes": [
            "widget-details"
        ],
        "label": "Rise response",
        "section": "Visualizer",
        "legacyPage": "Desktop",
        "legacySections": [
            "Widgets",
            "Visualizer"
        ],
        "keywords": "Config.options.background.widgets.visualizer.attack"
    },
    {
        "id": "BackgroundConfig.fall-response",
        "source": "BackgroundConfig",
        "route": "widget-details",
        "routes": [
            "widget-details"
        ],
        "label": "Fall response",
        "section": "Visualizer",
        "legacyPage": "Desktop",
        "legacySections": [
            "Widgets",
            "Visualizer"
        ],
        "keywords": "Config.options.background.widgets.visualizer.release"
    },
    {
        "id": "BackgroundConfig.pause-while-a-window-covers-the-desktop-2",
        "source": "BackgroundConfig",
        "route": "widget-details",
        "routes": [
            "widget-details"
        ],
        "label": "Pause while a window covers the desktop",
        "section": "Full monitor visualizer",
        "legacyPage": "Desktop",
        "legacySections": [
            "Widgets",
            "Full monitor visualizer"
        ],
        "keywords": "Config.options.background.widgets.fullMonitorVisualizer.hideWhenObscured"
    },
    {
        "id": "BackgroundConfig.maximum-height-2",
        "source": "BackgroundConfig",
        "route": "widget-details",
        "routes": [
            "widget-details"
        ],
        "label": "Maximum height",
        "section": "Full monitor visualizer",
        "legacyPage": "Desktop",
        "legacySections": [
            "Widgets",
            "Full monitor visualizer"
        ],
        "keywords": "Config.options.background.widgets.fullMonitorVisualizer.height"
    },
    {
        "id": "BackgroundConfig.bar-width",
        "source": "BackgroundConfig",
        "route": "widget-details",
        "routes": [
            "widget-details"
        ],
        "label": "Bar width",
        "section": "Full monitor visualizer",
        "legacyPage": "Desktop",
        "legacySections": [
            "Widgets",
            "Full monitor visualizer"
        ],
        "keywords": "Config.options.background.widgets.fullMonitorVisualizer.barWidth"
    },
    {
        "id": "BackgroundConfig.bar-spacing",
        "source": "BackgroundConfig",
        "route": "widget-details",
        "routes": [
            "widget-details"
        ],
        "label": "Bar spacing",
        "section": "Full monitor visualizer",
        "legacyPage": "Desktop",
        "legacySections": [
            "Widgets",
            "Full monitor visualizer"
        ],
        "keywords": "Config.options.background.widgets.fullMonitorVisualizer.spacing"
    },
    {
        "id": "BackgroundConfig.smoothing-duration",
        "source": "BackgroundConfig",
        "route": "widget-details",
        "routes": [
            "widget-details"
        ],
        "label": "Smoothing duration",
        "section": "Full monitor visualizer",
        "legacyPage": "Desktop",
        "legacySections": [
            "Widgets",
            "Full monitor visualizer"
        ],
        "keywords": "Config.options.background.widgets.fullMonitorVisualizer.smoothingDuration"
    },
    {
        "id": "BackgroundConfig.pause-while-a-window-covers-the-desktop-3",
        "source": "BackgroundConfig",
        "route": "widget-details",
        "routes": [
            "widget-details"
        ],
        "label": "Pause while a window covers the desktop",
        "section": "Mirrored visualizer",
        "legacyPage": "Desktop",
        "legacySections": [
            "Widgets",
            "Mirrored visualizer"
        ],
        "keywords": "Config.options.background.widgets.visualizerMirror.hideWhenObscured"
    },
    {
        "id": "BackgroundConfig.width-2",
        "source": "BackgroundConfig",
        "route": "widget-details",
        "routes": [
            "widget-details"
        ],
        "label": "Width",
        "section": "Mirrored visualizer",
        "legacyPage": "Desktop",
        "legacySections": [
            "Widgets",
            "Mirrored visualizer"
        ],
        "keywords": "Config.options.background.widgets.visualizerMirror.width"
    },
    {
        "id": "BackgroundConfig.total-height",
        "source": "BackgroundConfig",
        "route": "widget-details",
        "routes": [
            "widget-details"
        ],
        "label": "Total height",
        "section": "Mirrored visualizer",
        "legacyPage": "Desktop",
        "legacySections": [
            "Widgets",
            "Mirrored visualizer"
        ],
        "keywords": "Config.options.background.widgets.visualizerMirror.height"
    },
    {
        "id": "BackgroundConfig.frequency-bands-2",
        "source": "BackgroundConfig",
        "route": "widget-details",
        "routes": [
            "widget-details"
        ],
        "label": "Frequency bands",
        "section": "Mirrored visualizer",
        "legacyPage": "Desktop",
        "legacySections": [
            "Widgets",
            "Mirrored visualizer"
        ],
        "keywords": "Config.options.background.widgets.visualizerMirror.barCount"
    },
    {
        "id": "BackgroundConfig.noise-gate-2",
        "source": "BackgroundConfig",
        "route": "widget-details",
        "routes": [
            "widget-details"
        ],
        "label": "Noise gate",
        "section": "Mirrored visualizer",
        "legacyPage": "Desktop",
        "legacySections": [
            "Widgets",
            "Mirrored visualizer"
        ],
        "keywords": "Config.options.background.widgets.visualizerMirror.noiseFloor"
    },
    {
        "id": "BackgroundConfig.rise-response-2",
        "source": "BackgroundConfig",
        "route": "widget-details",
        "routes": [
            "widget-details"
        ],
        "label": "Rise response",
        "section": "Mirrored visualizer",
        "legacyPage": "Desktop",
        "legacySections": [
            "Widgets",
            "Mirrored visualizer"
        ],
        "keywords": "Config.options.background.widgets.visualizerMirror.attack"
    },
    {
        "id": "BackgroundConfig.fall-response-2",
        "source": "BackgroundConfig",
        "route": "widget-details",
        "routes": [
            "widget-details"
        ],
        "label": "Fall response",
        "section": "Mirrored visualizer",
        "legacyPage": "Desktop",
        "legacySections": [
            "Widgets",
            "Mirrored visualizer"
        ],
        "keywords": "Config.options.background.widgets.visualizerMirror.release"
    },
    {
        "id": "BackgroundConfig.show-alignment-grid-while-dragging",
        "source": "BackgroundConfig",
        "route": "widgets",
        "routes": [
            "widgets"
        ],
        "label": "Show alignment grid while dragging",
        "section": "Canvas",
        "legacyPage": "Desktop",
        "legacySections": [
            "Widgets",
            "Canvas"
        ],
        "keywords": "Config.options.background.showGrid"
    },
    {
        "id": "BackgroundConfig.show-snap-lines-when-dropping",
        "source": "BackgroundConfig",
        "route": "widgets",
        "routes": [
            "widgets"
        ],
        "label": "Show snap lines when dropping",
        "section": "Canvas",
        "legacyPage": "Desktop",
        "legacySections": [
            "Widgets",
            "Canvas"
        ],
        "keywords": "Config.options.background.showSnapLines"
    },
    {
        "id": "BarConfig.active-bar",
        "source": "BarConfig",
        "route": "panels",
        "routes": [
            "panels"
        ],
        "label": "Active bar",
        "section": "Bar Mode",
        "legacyPage": "Bar",
        "legacySections": [
            "Bar Mode"
        ],
        "keywords": "Config.options.bar.barMode"
    },
    {
        "id": "BarConfig.all",
        "source": "BarConfig",
        "route": "panels",
        "routes": [
            "panels"
        ],
        "label": "All",
        "section": "Show bar on",
        "legacyPage": "Bar",
        "legacySections": [
            "Screens",
            "Show bar on"
        ],
        "keywords": "Config.options.bar.screenList Config.options.bar.screenList.length"
    },
    {
        "id": "BarConfig.show-bar-on",
        "source": "BarConfig",
        "route": "panels",
        "routes": [
            "panels"
        ],
        "label": "Show bar on",
        "section": "Show bar on",
        "legacyPage": "Bar",
        "legacySections": [
            "Screens",
            "Show bar on"
        ],
        "keywords": "Config.options.bar.screenList.length Config.options.bar.screenList.slice Config.options.bar.screenList Config.options.bar.screenList.includes"
    },
    {
        "id": "BarConfig.clock-style",
        "source": "BarConfig",
        "route": "panels",
        "routes": [
            "panels"
        ],
        "label": "Clock style",
        "section": "Island behavior",
        "legacyPage": "Bar",
        "legacySections": [
            "M3 Island Options"
        ],
        "keywords": "Config.options.m3Island.clockStyle"
    },
    {
        "id": "BarConfig.show-date",
        "source": "BarConfig",
        "route": "panels",
        "routes": [
            "panels"
        ],
        "label": "Show date",
        "section": "Island behavior",
        "legacyPage": "Bar",
        "legacySections": [
            "M3 Island Options"
        ],
        "keywords": "Config.options.m3Island.clockShowDate"
    },
    {
        "id": "BarConfig.hover-peek",
        "source": "BarConfig",
        "route": "panels",
        "routes": [
            "panels"
        ],
        "label": "Hover peek",
        "section": "Island behavior",
        "legacyPage": "Bar",
        "legacySections": [
            "M3 Island Options"
        ],
        "keywords": "Config.options.m3Island.hoverPeek"
    },
    {
        "id": "BarConfig.show-seconds",
        "source": "BarConfig",
        "route": "panels",
        "routes": [
            "panels"
        ],
        "label": "Show seconds",
        "section": "Island behavior",
        "legacyPage": "Bar",
        "legacySections": [
            "M3 Island Options"
        ],
        "keywords": "Config.options.m3Island.clockShowSeconds"
    },
    {
        "id": "BarConfig.use-24-hour-clock",
        "source": "BarConfig",
        "route": "panels",
        "routes": [
            "panels"
        ],
        "label": "Use 24-hour clock",
        "section": "Island behavior",
        "legacyPage": "Bar",
        "legacySections": [
            "M3 Island Options"
        ],
        "keywords": "Config.options.m3Island.clockUse24h"
    },
    {
        "id": "BarConfig.reserve-screen-space",
        "source": "BarConfig",
        "route": "panel-details",
        "routes": [
            "panel-details"
        ],
        "label": "Reserve screen space",
        "section": "Island behavior",
        "legacyPage": "Bar",
        "legacySections": [
            "M3 Island Options"
        ],
        "keywords": "Config.options.m3Island.reserveScreenSpace"
    },
    {
        "id": "BarConfig.click-to-expand",
        "source": "BarConfig",
        "route": "panels",
        "routes": [
            "panels"
        ],
        "label": "Click to expand",
        "section": "Island behavior",
        "legacyPage": "Bar",
        "legacySections": [
            "M3 Island Options"
        ],
        "keywords": "Config.options.m3Island.clickToExpand"
    },
    {
        "id": "BarConfig.launcher-hug",
        "source": "BarConfig",
        "route": "panel-details",
        "routes": [
            "panel-details"
        ],
        "label": "Launcher hug",
        "section": "Island behavior",
        "legacyPage": "Bar",
        "legacySections": [
            "M3 Island Options"
        ],
        "keywords": "Config.options.m3Island.launcherHug"
    },
    {
        "id": "BarConfig.show-expanded-details",
        "source": "BarConfig",
        "route": "panel-details",
        "routes": [
            "panel-details"
        ],
        "label": "Show expanded details",
        "section": "Island behavior",
        "legacyPage": "Bar",
        "legacySections": [
            "M3 Island Options"
        ],
        "keywords": "Config.options.m3Island.verbose"
    },
    {
        "id": "BarConfig.launcher-maximum-visible-results",
        "source": "BarConfig",
        "route": "panel-details",
        "routes": [
            "panel-details"
        ],
        "label": "Launcher maximum visible results",
        "section": "Island behavior",
        "legacyPage": "Bar",
        "legacySections": [
            "M3 Island Options"
        ],
        "keywords": "Config.options.m3Island.launcherMaxResults"
    },
    {
        "id": "BarConfig.scroll-over-island",
        "source": "BarConfig",
        "route": "panels",
        "routes": [
            "panels"
        ],
        "label": "Scroll over island",
        "section": "Island behavior",
        "legacyPage": "Bar",
        "legacySections": [
            "M3 Island Options"
        ],
        "keywords": "Config.options.m3Island.scrollAction"
    },
    {
        "id": "BarConfig.expanded-height",
        "source": "BarConfig",
        "route": "panel-details",
        "routes": [
            "panel-details"
        ],
        "label": "Expanded height",
        "section": "Island behavior",
        "legacyPage": "Bar",
        "legacySections": [
            "M3 Island Options"
        ],
        "keywords": "Config.options.m3Island.expandedHeight"
    },
    {
        "id": "BarConfig.animation-speed",
        "source": "BarConfig",
        "route": "panel-details",
        "routes": [
            "panel-details"
        ],
        "label": "Animation speed",
        "section": "Island behavior",
        "legacyPage": "Bar",
        "legacySections": [
            "M3 Island Options"
        ],
        "keywords": "Config.options.m3Island.animationSpeed"
    },
    {
        "id": "BarConfig.hug-corner-size",
        "source": "BarConfig",
        "route": "panel-details",
        "routes": [
            "panel-details"
        ],
        "label": "Hug corner size",
        "section": "Island behavior",
        "legacyPage": "Bar",
        "legacySections": [
            "M3 Island Options"
        ],
        "keywords": "Config.options.m3Island.cornerStyle Config.options.m3Island.hugCornerSize"
    },
    {
        "id": "BarConfig.corner-style",
        "source": "BarConfig",
        "route": "panel-details",
        "routes": [
            "panel-details"
        ],
        "label": "Corner style",
        "section": "Island behavior",
        "legacyPage": "Bar",
        "legacySections": [
            "M3 Island Options"
        ],
        "keywords": "Config.options.m3Island.cornerStyle"
    },
    {
        "id": "BarConfig.notification-display-time-ms-0-global",
        "source": "BarConfig",
        "route": "notification-rules",
        "routes": [
            "notification-rules"
        ],
        "label": "Notification display time (ms, 0 = global)",
        "section": "Island behavior",
        "legacyPage": "Bar",
        "legacySections": [
            "M3 Island Options"
        ],
        "keywords": "Config.options.m3Island.notificationTimeout"
    },
    {
        "id": "BarConfig.show-background",
        "source": "BarConfig",
        "route": "panels",
        "routes": [
            "panels"
        ],
        "label": "Show Background",
        "section": "Island behavior",
        "legacyPage": "Bar",
        "legacySections": [
            "M3 Island Options"
        ],
        "keywords": "Config.options.m3Island.showBackground"
    },
    {
        "id": "BarConfig.show-frame",
        "source": "BarConfig",
        "route": "panels",
        "routes": [
            "panels"
        ],
        "label": "Show Frame",
        "section": "Island behavior",
        "legacyPage": "Bar",
        "legacySections": [
            "M3 Island Options"
        ],
        "keywords": "Config.options.m3Island.showFrame"
    },
    {
        "id": "BarConfig.blend-the-wallpaper-into-the-island",
        "source": "BarConfig",
        "route": "panels",
        "routes": [
            "panels"
        ],
        "label": "Blend the wallpaper into the island",
        "section": "Island behavior",
        "legacyPage": "Bar",
        "legacySections": [
            "M3 Island Options"
        ],
        "keywords": "Config.options.m3Island.showBackground Config.options.m3Island.wallpaperBackground.enable"
    },
    {
        "id": "BarConfig.wallpaper-strength",
        "source": "BarConfig",
        "route": "panel-details",
        "routes": [
            "panel-details"
        ],
        "label": "Wallpaper strength",
        "section": "Island behavior",
        "legacyPage": "Bar",
        "legacySections": [
            "M3 Island Options"
        ],
        "keywords": "Config.options.m3Island.wallpaperBackground.enable Config.options.m3Island.wallpaperBackground.opacity"
    },
    {
        "id": "BarConfig.readability-scrim",
        "source": "BarConfig",
        "route": "panel-details",
        "routes": [
            "panel-details"
        ],
        "label": "Readability scrim",
        "section": "Island behavior",
        "legacyPage": "Bar",
        "legacySections": [
            "M3 Island Options"
        ],
        "keywords": "Config.options.m3Island.wallpaperBackground.enable Config.options.m3Island.wallpaperBackground.scrim"
    },
    {
        "id": "BarConfig.use-frame-color-as-background",
        "source": "BarConfig",
        "route": "panel-details",
        "routes": [
            "panel-details"
        ],
        "label": "Use Frame Color as Background",
        "section": "Island behavior",
        "legacyPage": "Bar",
        "legacySections": [
            "M3 Island Options"
        ],
        "keywords": "Config.options.m3Island.showFrame Config.options.m3Island.followFrameColor"
    },
    {
        "id": "BarConfig.frame-thickness",
        "source": "BarConfig",
        "route": "panel-details",
        "routes": [
            "panel-details"
        ],
        "label": "Frame thickness",
        "section": "Island behavior",
        "legacyPage": "Bar",
        "legacySections": [
            "M3 Island Options"
        ],
        "keywords": "Config.options.m3Island.showFrame Config.options.m3Island.frameThickness"
    },
    {
        "id": "BarConfig.frame-color",
        "source": "BarConfig",
        "route": "panel-details",
        "routes": [
            "panel-details"
        ],
        "label": "Frame Color",
        "section": "Island behavior",
        "legacyPage": "Bar",
        "legacySections": [
            "M3 Island Options"
        ],
        "keywords": "Config.options.m3Island.frameColor"
    },
    {
        "id": "BarConfig.bar-position",
        "source": "BarConfig",
        "route": "panels",
        "routes": [
            "panels"
        ],
        "label": "Bar position",
        "section": "Positioning & Style",
        "legacyPage": "Bar",
        "legacySections": [
            "Positioning & Style"
        ],
        "keywords": "Config.options.bar.bottom Config.options.bar.vertical"
    },
    {
        "id": "BarConfig.bar-position-2",
        "source": "BarConfig",
        "route": "panels",
        "routes": [
            "panels"
        ],
        "label": "Bar position",
        "section": "Positioning & Style",
        "legacyPage": "Bar",
        "legacySections": [
            "Positioning & Style"
        ],
        "keywords": "Config.options.bar.bottom"
    },
    {
        "id": "BarConfig.mesobar-style",
        "source": "BarConfig",
        "route": "panels",
        "routes": [
            "panels"
        ],
        "label": "Mesobar style",
        "section": "Positioning & Style",
        "legacyPage": "Bar",
        "legacySections": [
            "Positioning & Style"
        ],
        "keywords": "Config.options.mesoBar.cornerStyle"
    },
    {
        "id": "BarConfig.width",
        "source": "BarConfig",
        "route": "panel-details",
        "routes": [
            "panel-details"
        ],
        "label": "Width",
        "section": "Positioning & Style",
        "legacyPage": "Bar",
        "legacySections": [
            "Positioning & Style"
        ],
        "keywords": "Config.options.mesoBar.widthMode"
    },
    {
        "id": "BarConfig.width-of-screen",
        "source": "BarConfig",
        "route": "panel-details",
        "routes": [
            "panel-details"
        ],
        "label": "Width (% of screen)",
        "section": "Positioning & Style",
        "legacyPage": "Bar",
        "legacySections": [
            "Positioning & Style"
        ],
        "keywords": "Config.options.mesoBar.widthMode Config.options.mesoBar.widthPercent"
    },
    {
        "id": "BarConfig.bar-style",
        "source": "BarConfig",
        "route": "panels",
        "routes": [
            "panels"
        ],
        "label": "Bar style",
        "section": "Positioning & Style",
        "legacyPage": "Bar",
        "legacySections": [
            "Positioning & Style"
        ],
        "keywords": "Config.options.bar.cornerStyle"
    },
    {
        "id": "BarConfig.group-style",
        "source": "BarConfig",
        "route": "panels",
        "routes": [
            "panels"
        ],
        "label": "Group style",
        "section": "Positioning & Style",
        "legacyPage": "Bar",
        "legacySections": [
            "Positioning & Style"
        ],
        "keywords": "Config.options.bar.borderless"
    },
    {
        "id": "BarConfig.group-style-2",
        "source": "BarConfig",
        "route": "panels",
        "routes": [
            "panels"
        ],
        "label": "Group style",
        "section": "Positioning & Style",
        "legacyPage": "Bar",
        "legacySections": [
            "Positioning & Style"
        ],
        "keywords": "Config.options.mesoBar.borderless"
    },
    {
        "id": "BarConfig.group-color",
        "source": "BarConfig",
        "route": "panel-details",
        "routes": [
            "panel-details"
        ],
        "label": "Group Color",
        "section": "Positioning & Style",
        "legacyPage": "Bar",
        "legacySections": [
            "Positioning & Style"
        ],
        "keywords": "Config.options.bar.groupColor"
    },
    {
        "id": "BarConfig.show-background-2",
        "source": "BarConfig",
        "route": "panels",
        "routes": [
            "panels"
        ],
        "label": "Show Background",
        "section": "Positioning & Style",
        "legacyPage": "Bar",
        "legacySections": [
            "Positioning & Style"
        ],
        "keywords": "Config.options.m3Island.showBackground Config.options.bar.showBackground"
    },
    {
        "id": "BarConfig.autohide",
        "source": "BarConfig",
        "route": "panels",
        "routes": [
            "panels"
        ],
        "label": "Autohide",
        "section": "Positioning & Style",
        "legacyPage": "Bar",
        "legacySections": [
            "Positioning & Style"
        ],
        "keywords": "Config.options.bar.autoHide.enable"
    },
    {
        "id": "BarConfig.hover-region-width-px",
        "source": "BarConfig",
        "route": "panel-details",
        "routes": [
            "panel-details"
        ],
        "label": "Hover Region Width (px)",
        "section": "Positioning & Style",
        "legacyPage": "Bar",
        "legacySections": [
            "Positioning & Style"
        ],
        "keywords": "Config.options.bar.autoHide.hoverRegionWidth"
    },
    {
        "id": "BarConfig.push-windows-when-hidden",
        "source": "BarConfig",
        "route": "panel-details",
        "routes": [
            "panel-details"
        ],
        "label": "Push Windows When Hidden",
        "section": "Positioning & Style",
        "legacyPage": "Bar",
        "legacySections": [
            "Positioning & Style"
        ],
        "keywords": "Config.options.bar.autoHide.pushWindows"
    },
    {
        "id": "BarConfig.show-on-super-press",
        "source": "BarConfig",
        "route": "panel-details",
        "routes": [
            "panel-details"
        ],
        "label": "Show On Super Press",
        "section": "Positioning & Style",
        "legacyPage": "Bar",
        "legacySections": [
            "Positioning & Style"
        ],
        "keywords": "Config.options.bar.autoHide.showWhenPressingSuper.enable"
    },
    {
        "id": "BarConfig.show-frame-2",
        "source": "BarConfig",
        "route": "panels",
        "routes": [
            "panels"
        ],
        "label": "Show Frame",
        "section": "Positioning & Style",
        "legacyPage": "Bar",
        "legacySections": [
            "Positioning & Style"
        ],
        "keywords": "Config.options.bar.showFrame"
    },
    {
        "id": "BarConfig.follow-frame-color",
        "source": "BarConfig",
        "route": "panel-details",
        "routes": [
            "panel-details"
        ],
        "label": "Follow Frame Color",
        "section": "Positioning & Style",
        "legacyPage": "Bar",
        "legacySections": [
            "Positioning & Style"
        ],
        "keywords": "Config.options.bar.showFrame Config.options.bar.followFrameColor"
    },
    {
        "id": "BarConfig.frame-thickness-2",
        "source": "BarConfig",
        "route": "panel-details",
        "routes": [
            "panel-details"
        ],
        "label": "Frame thickness",
        "section": "Positioning & Style",
        "legacyPage": "Bar",
        "legacySections": [
            "Positioning & Style"
        ],
        "keywords": "Config.options.bar.frameThickness"
    },
    {
        "id": "BarConfig.frame-color-2",
        "source": "BarConfig",
        "route": "panel-details",
        "routes": [
            "panel-details"
        ],
        "label": "Frame Color",
        "section": "Positioning & Style",
        "legacyPage": "Bar",
        "legacySections": [
            "Positioning & Style"
        ],
        "keywords": "Config.options.bar.frameColor"
    },
    {
        "id": "BarConfig.show-frame-3",
        "source": "BarConfig",
        "route": "panels",
        "routes": [
            "panels"
        ],
        "label": "Show Frame",
        "section": "Mesobar",
        "legacyPage": "Bar",
        "legacySections": [
            "Mesobar Options"
        ],
        "keywords": "Config.options.mesoBar.showFrame"
    },
    {
        "id": "BarConfig.follow-frame-color-2",
        "source": "BarConfig",
        "route": "panel-details",
        "routes": [
            "panel-details"
        ],
        "label": "Follow Frame Color",
        "section": "Mesobar",
        "legacyPage": "Bar",
        "legacySections": [
            "Mesobar Options"
        ],
        "keywords": "Config.options.mesoBar.showFrame Config.options.mesoBar.followFrameColor"
    },
    {
        "id": "BarConfig.frame-thickness-3",
        "source": "BarConfig",
        "route": "panel-details",
        "routes": [
            "panel-details"
        ],
        "label": "Frame thickness",
        "section": "Mesobar",
        "legacyPage": "Bar",
        "legacySections": [
            "Mesobar Options"
        ],
        "keywords": "Config.options.mesoBar.frameThickness"
    },
    {
        "id": "BarConfig.frame-color-3",
        "source": "BarConfig",
        "route": "panel-details",
        "routes": [
            "panel-details"
        ],
        "label": "Frame Color",
        "section": "Mesobar",
        "legacyPage": "Bar",
        "legacySections": [
            "Mesobar Options"
        ],
        "keywords": "Config.options.mesoBar.frameColor"
    },
    {
        "id": "BarConfig.show-labels",
        "source": "BarConfig",
        "route": "panels",
        "routes": [
            "panels"
        ],
        "label": "Show Labels",
        "section": "Task list",
        "legacyPage": "Bar",
        "legacySections": [
            "Tasklist Options"
        ],
        "keywords": "Config.options.tasklistBar.showLabels"
    },
    {
        "id": "BarConfig.max-button-width",
        "source": "BarConfig",
        "route": "panel-details",
        "routes": [
            "panel-details"
        ],
        "label": "Max Button Width",
        "section": "Task list",
        "legacyPage": "Bar",
        "legacySections": [
            "Tasklist Options"
        ],
        "keywords": "Config.options.tasklistBar.maxButtonWidth"
    },
    {
        "id": "BarConfig.cpu",
        "source": "BarConfig",
        "route": "panels",
        "routes": [
            "panels"
        ],
        "label": "CPU",
        "section": "System monitor",
        "legacyPage": "Bar",
        "legacySections": [
            "System Monitor Options"
        ],
        "keywords": "Config.options.sysmonitorBar.showCpu"
    },
    {
        "id": "BarConfig.cpu-temperature",
        "source": "BarConfig",
        "route": "panels",
        "routes": [
            "panels"
        ],
        "label": "CPU Temperature",
        "section": "System monitor",
        "legacyPage": "Bar",
        "legacySections": [
            "System Monitor Options"
        ],
        "keywords": "Config.options.sysmonitorBar.showCpuTemp"
    },
    {
        "id": "BarConfig.ram",
        "source": "BarConfig",
        "route": "panels",
        "routes": [
            "panels"
        ],
        "label": "RAM",
        "section": "System monitor",
        "legacyPage": "Bar",
        "legacySections": [
            "System Monitor Options"
        ],
        "keywords": "Config.options.sysmonitorBar.showRam"
    },
    {
        "id": "BarConfig.disk",
        "source": "BarConfig",
        "route": "panels",
        "routes": [
            "panels"
        ],
        "label": "Disk",
        "section": "System monitor",
        "legacyPage": "Bar",
        "legacySections": [
            "System Monitor Options"
        ],
        "keywords": "Config.options.sysmonitorBar.showDisk"
    },
    {
        "id": "BarConfig.swap",
        "source": "BarConfig",
        "route": "panels",
        "routes": [
            "panels"
        ],
        "label": "Swap",
        "section": "System monitor",
        "legacyPage": "Bar",
        "legacySections": [
            "System Monitor Options"
        ],
        "keywords": "Config.options.sysmonitorBar.showSwap"
    },
    {
        "id": "BarConfig.network",
        "source": "BarConfig",
        "route": "panels",
        "routes": [
            "panels"
        ],
        "label": "Network",
        "section": "System monitor",
        "legacyPage": "Bar",
        "legacySections": [
            "System Monitor Options"
        ],
        "keywords": "Config.options.sysmonitorBar.showNetwork"
    },
    {
        "id": "BarConfig.ram-warning-threshold",
        "source": "BarConfig",
        "route": "panel-details",
        "routes": [
            "panel-details"
        ],
        "label": "RAM warning threshold (%)",
        "section": "System monitor",
        "legacyPage": "Bar",
        "legacySections": [
            "System Monitor Options"
        ],
        "keywords": "Config.options.sysmonitorBar.memoryWarningThreshold"
    },
    {
        "id": "BarConfig.cpu-warning-threshold",
        "source": "BarConfig",
        "route": "panel-details",
        "routes": [
            "panel-details"
        ],
        "label": "CPU warning threshold (%)",
        "section": "System monitor",
        "legacyPage": "Bar",
        "legacySections": [
            "System Monitor Options"
        ],
        "keywords": "Config.options.sysmonitorBar.cpuWarningThreshold"
    },
    {
        "id": "BarConfig.temperature-warning-threshold-c",
        "source": "BarConfig",
        "route": "panel-details",
        "routes": [
            "panel-details"
        ],
        "label": "Temperature warning threshold (°C)",
        "section": "System monitor",
        "legacyPage": "Bar",
        "legacySections": [
            "System Monitor Options"
        ],
        "keywords": "Config.options.sysmonitorBar.tempWarningThreshold"
    },
    {
        "id": "BarConfig.disk-warning-threshold",
        "source": "BarConfig",
        "route": "panel-details",
        "routes": [
            "panel-details"
        ],
        "label": "Disk warning threshold (%)",
        "section": "System monitor",
        "legacyPage": "Bar",
        "legacySections": [
            "System Monitor Options"
        ],
        "keywords": "Config.options.sysmonitorBar.diskWarningThreshold"
    },
    {
        "id": "BarConfig.swap-warning-threshold",
        "source": "BarConfig",
        "route": "panel-details",
        "routes": [
            "panel-details"
        ],
        "label": "Swap warning threshold (%)",
        "section": "System monitor",
        "legacyPage": "Bar",
        "legacySections": [
            "System Monitor Options"
        ],
        "keywords": "Config.options.sysmonitorBar.swapWarningThreshold"
    },
    {
        "id": "BarConfig.volume-slider",
        "source": "BarConfig",
        "route": "panels",
        "routes": [
            "panels"
        ],
        "label": "Volume Slider",
        "section": "Quick actions",
        "legacyPage": "Bar",
        "legacySections": [
            "Quick Actions Options"
        ],
        "keywords": "Config.options.quickActionsBar.showVolumeSlider"
    },
    {
        "id": "BarConfig.brightness-slider",
        "source": "BarConfig",
        "route": "panels",
        "routes": [
            "panels"
        ],
        "label": "Brightness Slider",
        "section": "Quick actions",
        "legacyPage": "Bar",
        "legacySections": [
            "Quick Actions Options"
        ],
        "keywords": "Config.options.quickActionsBar.showBrightnessSlider"
    },
    {
        "id": "BarConfig.active-window",
        "source": "BarConfig",
        "route": "panels",
        "routes": [
            "panels"
        ],
        "label": "Active Window",
        "section": "Info strip",
        "legacyPage": "Bar",
        "legacySections": [
            "Info Strip Options"
        ],
        "keywords": "Config.options.infoStrip.showActiveWindow"
    },
    {
        "id": "BarConfig.clock",
        "source": "BarConfig",
        "route": "panels",
        "routes": [
            "panels"
        ],
        "label": "Clock",
        "section": "Info strip",
        "legacyPage": "Bar",
        "legacySections": [
            "Info Strip Options"
        ],
        "keywords": "Config.options.infoStrip.showClock"
    },
    {
        "id": "BarConfig.cpu-usage",
        "source": "BarConfig",
        "route": "panels",
        "routes": [
            "panels"
        ],
        "label": "CPU Usage",
        "section": "Info strip",
        "legacyPage": "Bar",
        "legacySections": [
            "Info Strip Options"
        ],
        "keywords": "Config.options.infoStrip.showCpuUsage"
    },
    {
        "id": "BarConfig.memory-usage",
        "source": "BarConfig",
        "route": "panels",
        "routes": [
            "panels"
        ],
        "label": "Memory Usage",
        "section": "Info strip",
        "legacyPage": "Bar",
        "legacySections": [
            "Info Strip Options"
        ],
        "keywords": "Config.options.infoStrip.showMemoryUsage"
    },
    {
        "id": "BarConfig.notification-dot",
        "source": "BarConfig",
        "route": "panels",
        "routes": [
            "panels"
        ],
        "label": "Notification Dot",
        "section": "Info strip",
        "legacyPage": "Bar",
        "legacySections": [
            "Info Strip Options"
        ],
        "keywords": "Config.options.infoStrip.showNotificationDot"
    },
    {
        "id": "BarConfig.unread-indicator-show-count",
        "source": "BarConfig",
        "route": "panels",
        "routes": [
            "panels"
        ],
        "label": "Unread indicator: show count",
        "section": "Notifications",
        "legacyPage": "Bar",
        "legacySections": [
            "Notifications"
        ],
        "keywords": "Config.options.bar.indicators.notifications.showUnreadCount"
    },
    {
        "id": "BarConfig.timeout-duration-ms",
        "source": "BarConfig",
        "route": "notification-rules",
        "routes": [
            "notification-rules"
        ],
        "label": "Timeout duration (ms)",
        "section": "Notifications",
        "legacyPage": "Bar",
        "legacySections": [
            "Notifications"
        ],
        "keywords": "Config.options.notifications.timeout"
    },
    {
        "id": "BarConfig.make-icons-pinned-by-default",
        "source": "BarConfig",
        "route": "panels",
        "routes": [
            "panels"
        ],
        "label": "Make icons pinned by default",
        "section": "Tray",
        "legacyPage": "Bar",
        "legacySections": [
            "Tray"
        ],
        "keywords": "Config.options.tray.invertPinnedItems"
    },
    {
        "id": "BarConfig.tint-icons",
        "source": "BarConfig",
        "route": "panels",
        "routes": [
            "panels"
        ],
        "label": "Tint icons",
        "section": "Tray",
        "legacyPage": "Bar",
        "legacySections": [
            "Tray"
        ],
        "keywords": "Config.options.tray.monochromeIcons"
    },
    {
        "id": "BarConfig.style",
        "source": "BarConfig",
        "route": "panels",
        "routes": [
            "panels"
        ],
        "label": "Style",
        "section": "Divider",
        "legacyPage": "Bar",
        "legacySections": [
            "Divider"
        ],
        "keywords": "Config.options.bar.divider.style"
    },
    {
        "id": "BarConfig.space-width-px",
        "source": "BarConfig",
        "route": "panel-details",
        "routes": [
            "panel-details"
        ],
        "label": "Space width (px)",
        "section": "Divider",
        "legacyPage": "Bar",
        "legacySections": [
            "Divider"
        ],
        "keywords": "Config.options.bar.divider.style Config.options.bar.divider.spacing"
    },
    {
        "id": "BarConfig.screen-snip",
        "source": "BarConfig",
        "route": "panels",
        "routes": [
            "panels"
        ],
        "label": "Screen snip",
        "section": "Utility Buttons",
        "legacyPage": "Bar",
        "legacySections": [
            "Utility Buttons"
        ],
        "keywords": "Config.options.bar.utilButtons.showScreenSnip"
    },
    {
        "id": "BarConfig.color-picker",
        "source": "BarConfig",
        "route": "panels",
        "routes": [
            "panels"
        ],
        "label": "Color picker",
        "section": "Utility Buttons",
        "legacyPage": "Bar",
        "legacySections": [
            "Utility Buttons"
        ],
        "keywords": "Config.options.bar.utilButtons.showColorPicker"
    },
    {
        "id": "BarConfig.keyboard-toggle",
        "source": "BarConfig",
        "route": "panels",
        "routes": [
            "panels"
        ],
        "label": "Keyboard toggle",
        "section": "Utility Buttons",
        "legacyPage": "Bar",
        "legacySections": [
            "Utility Buttons"
        ],
        "keywords": "Config.options.bar.utilButtons.showKeyboardToggle"
    },
    {
        "id": "BarConfig.mic-toggle",
        "source": "BarConfig",
        "route": "panels",
        "routes": [
            "panels"
        ],
        "label": "Mic toggle",
        "section": "Utility Buttons",
        "legacyPage": "Bar",
        "legacySections": [
            "Utility Buttons"
        ],
        "keywords": "Config.options.bar.utilButtons.showMicToggle"
    },
    {
        "id": "BarConfig.dark-light-toggle",
        "source": "BarConfig",
        "route": "panels",
        "routes": [
            "panels"
        ],
        "label": "Dark/Light toggle",
        "section": "Utility Buttons",
        "legacyPage": "Bar",
        "legacySections": [
            "Utility Buttons"
        ],
        "keywords": "Config.options.bar.utilButtons.showDarkModeToggle"
    },
    {
        "id": "BarConfig.performance-profile",
        "source": "BarConfig",
        "route": "panels",
        "routes": [
            "panels"
        ],
        "label": "Performance Profile",
        "section": "Utility Buttons",
        "legacyPage": "Bar",
        "legacySections": [
            "Utility Buttons"
        ],
        "keywords": "Config.options.bar.utilButtons.showPerformanceProfileToggle"
    },
    {
        "id": "BarConfig.record-screen",
        "source": "BarConfig",
        "route": "panels",
        "routes": [
            "panels"
        ],
        "label": "Record Screen",
        "section": "Utility Buttons",
        "legacyPage": "Bar",
        "legacySections": [
            "Utility Buttons"
        ],
        "keywords": "Config.options.bar.utilButtons.showScreenRecord"
    },
    {
        "id": "BarConfig.wallpapers-toggle",
        "source": "BarConfig",
        "route": "panels",
        "routes": [
            "panels"
        ],
        "label": "Wallpapers Toggle",
        "section": "Utility Buttons",
        "legacyPage": "Bar",
        "legacySections": [
            "Utility Buttons"
        ],
        "keywords": "Config.options.bar.utilButtons.showWallpaperToggle"
    },
    {
        "id": "BarConfig.always-show-numbers",
        "source": "BarConfig",
        "route": "panels",
        "routes": [
            "panels"
        ],
        "label": "Always show numbers",
        "section": "Workspaces",
        "legacyPage": "Bar",
        "legacySections": [
            "Workspaces"
        ],
        "keywords": "Config.options.bar.workspaces.alwaysShowNumbers"
    },
    {
        "id": "BarConfig.numbers-style",
        "source": "BarConfig",
        "route": "panels",
        "routes": [
            "panels"
        ],
        "label": "Numbers style",
        "section": "Workspaces",
        "legacyPage": "Bar",
        "legacySections": [
            "Workspaces"
        ],
        "keywords": "Config.options.bar.workspaces.numberMap"
    },
    {
        "id": "BarConfig.show-app-icons",
        "source": "BarConfig",
        "route": "panels",
        "routes": [
            "panels"
        ],
        "label": "Show app icons",
        "section": "Workspaces",
        "legacyPage": "Bar",
        "legacySections": [
            "Workspaces"
        ],
        "keywords": "Config.options.bar.workspaces.showAppIcons"
    },
    {
        "id": "BarConfig.workspaces-shown",
        "source": "BarConfig",
        "route": "panels",
        "routes": [
            "panels"
        ],
        "label": "Workspaces shown",
        "section": "Workspaces",
        "legacyPage": "Bar",
        "legacySections": [
            "Workspaces"
        ],
        "keywords": "Config.options.bar.workspaces.shown"
    },
    {
        "id": "BarConfig.show-preview-on-hover",
        "source": "BarConfig",
        "route": "panels",
        "routes": [
            "panels"
        ],
        "label": "Show preview on hover",
        "section": "Workspaces",
        "legacyPage": "Bar",
        "legacySections": [
            "Workspaces"
        ],
        "keywords": "Config.options.overview.hoverPreviewInBar"
    },
    {
        "id": "BarConfig.indicator-style",
        "source": "BarConfig",
        "route": "panels",
        "routes": [
            "panels"
        ],
        "label": "Indicator style",
        "section": "Workspaces",
        "legacyPage": "Bar",
        "legacySections": [
            "Workspaces"
        ],
        "keywords": "Config.options.bar.workspaces.indicatorStyle"
    },
    {
        "id": "BarConfig.cpu-2",
        "source": "BarConfig",
        "route": "panels",
        "routes": [
            "panels"
        ],
        "label": "CPU",
        "section": "Resources",
        "legacyPage": "Bar",
        "legacySections": [
            "Resources"
        ],
        "keywords": "Config.options.bar.resources.alwaysShowCpu"
    },
    {
        "id": "BarConfig.cpu-temperature-2",
        "source": "BarConfig",
        "route": "panels",
        "routes": [
            "panels"
        ],
        "label": "CPU Temperature",
        "section": "Resources",
        "legacyPage": "Bar",
        "legacySections": [
            "Resources"
        ],
        "keywords": "Config.options.bar.resources.alwaysShowCpuTemp"
    },
    {
        "id": "BarConfig.ram-2",
        "source": "BarConfig",
        "route": "panels",
        "routes": [
            "panels"
        ],
        "label": "RAM",
        "section": "Resources",
        "legacyPage": "Bar",
        "legacySections": [
            "Resources"
        ],
        "keywords": "Config.options.bar.resources.alwaysShowRam"
    },
    {
        "id": "BarConfig.disk-2",
        "source": "BarConfig",
        "route": "panels",
        "routes": [
            "panels"
        ],
        "label": "Disk",
        "section": "Resources",
        "legacyPage": "Bar",
        "legacySections": [
            "Resources"
        ],
        "keywords": "Config.options.bar.resources.alwaysShowDisk"
    },
    {
        "id": "BarConfig.swap-2",
        "source": "BarConfig",
        "route": "panels",
        "routes": [
            "panels"
        ],
        "label": "Swap",
        "section": "Resources",
        "legacyPage": "Bar",
        "legacySections": [
            "Resources"
        ],
        "keywords": "Config.options.bar.resources.alwaysShowSwap"
    },
    {
        "id": "BarConfig.style-2",
        "source": "BarConfig",
        "route": "panels",
        "routes": [
            "panels"
        ],
        "label": "Style",
        "section": "Resources",
        "legacyPage": "Bar",
        "legacySections": [
            "Resources"
        ],
        "keywords": "Config.options.bar.resources.style"
    },
    {
        "id": "BarConfig.show-percentage",
        "source": "BarConfig",
        "route": "panels",
        "routes": [
            "panels"
        ],
        "label": "Show Percentage",
        "section": "Resources",
        "legacyPage": "Bar",
        "legacySections": [
            "Resources"
        ],
        "keywords": "Config.options.bar.resources.showValue"
    },
    {
        "id": "BarConfig.polling-interval-ms",
        "source": "BarConfig",
        "route": "panel-details",
        "routes": [
            "panel-details"
        ],
        "label": "Polling interval (ms)",
        "section": "Resources",
        "legacyPage": "Bar",
        "legacySections": [
            "Resources"
        ],
        "keywords": "Config.options.resources.updateInterval"
    },
    {
        "id": "BarConfig.preferred-player",
        "source": "BarConfig",
        "route": "panels",
        "routes": [
            "panels"
        ],
        "label": "Preferred Player",
        "section": "Media",
        "legacyPage": "Bar",
        "legacySections": [
            "Media"
        ],
        "keywords": "Config.options.bar.media.preferredPlayer"
    },
    {
        "id": "BarConfig.pin-media-controls",
        "source": "BarConfig",
        "route": "panels",
        "routes": [
            "panels"
        ],
        "label": "Pin media controls",
        "section": "Media",
        "legacyPage": "Bar",
        "legacySections": [
            "Media"
        ],
        "keywords": "Config.options.bar.media.alwaysVisible"
    },
    {
        "id": "BarConfig.show-only-title",
        "source": "BarConfig",
        "route": "panels",
        "routes": [
            "panels"
        ],
        "label": "Show only title",
        "section": "Media",
        "legacyPage": "Bar",
        "legacySections": [
            "Media"
        ],
        "keywords": "Config.options.bar.media.onlyTitle"
    },
    {
        "id": "BarConfig.max-media-width",
        "source": "BarConfig",
        "route": "panel-details",
        "routes": [
            "panel-details"
        ],
        "label": "Max media width",
        "section": "Media",
        "legacyPage": "Bar",
        "legacySections": [
            "Media"
        ],
        "keywords": "Config.options.bar.media.maxWidth"
    },
    {
        "id": "BarConfig.click-to-show",
        "source": "BarConfig",
        "route": "panels",
        "routes": [
            "panels"
        ],
        "label": "Click to show",
        "section": "Tooltips",
        "legacyPage": "Bar",
        "legacySections": [
            "Tooltips"
        ],
        "keywords": "Config.options.bar.tooltips.clickToShow"
    },
    {
        "id": "ExperienceConfig.theme-starting-point",
        "source": "ExperienceConfig",
        "route": "appearance",
        "routes": [
            "appearance"
        ],
        "label": "Theme starting point",
        "section": "Built-in themes",
        "legacyPage": "Experience",
        "legacySections": [
            "Built-in themes"
        ],
        "keywords": "Config.options.appearance.builtInTheme"
    },
    {
        "id": "ExperienceConfig.display-mode",
        "source": "ExperienceConfig",
        "route": "notifications",
        "routes": [
            "notifications"
        ],
        "label": "Display mode",
        "section": "Notification experience",
        "legacyPage": "Experience",
        "legacySections": [
            "Notification experience"
        ],
        "keywords": "Config.options.notifications.displayMode"
    },
    {
        "id": "ExperienceConfig.card-style",
        "source": "ExperienceConfig",
        "route": "notifications",
        "routes": [
            "notifications"
        ],
        "label": "Card style",
        "section": "Notification experience",
        "legacyPage": "Experience",
        "legacySections": [
            "Notification experience"
        ],
        "keywords": "Config.options.notifications.style"
    },
    {
        "id": "ExperienceConfig.pause-timeout-on-hover",
        "source": "ExperienceConfig",
        "route": "notifications",
        "routes": [
            "notifications"
        ],
        "label": "Pause timeout on hover",
        "section": "Notification experience",
        "legacyPage": "Experience",
        "legacySections": [
            "Notification experience"
        ],
        "keywords": "Config.options.notifications.pauseOnHover"
    },
    {
        "id": "ExperienceConfig.critical-alerts-in-quiet-mode",
        "source": "ExperienceConfig",
        "route": "notifications",
        "routes": [
            "notifications"
        ],
        "label": "Critical alerts in quiet mode",
        "section": "Notification experience",
        "legacyPage": "Experience",
        "legacySections": [
            "Notification experience"
        ],
        "keywords": "Config.options.notifications.showCriticalWhenQuiet"
    },
    {
        "id": "ExperienceConfig.auto-silence-popups-while-screen-sharing",
        "source": "ExperienceConfig",
        "route": "notifications",
        "routes": [
            "notifications"
        ],
        "label": "Auto-silence popups while screen sharing",
        "section": "Notification experience",
        "legacyPage": "Experience",
        "legacySections": [
            "Notification experience"
        ],
        "keywords": "Config.options.notifications.autoSilentOnScreenShare"
    },
    {
        "id": "ExperienceConfig.maximum-visible-cards",
        "source": "ExperienceConfig",
        "route": "notification-rules",
        "routes": [
            "notification-rules"
        ],
        "label": "Maximum visible cards",
        "section": "Notification experience",
        "legacyPage": "Experience",
        "legacySections": [
            "Notification experience"
        ],
        "keywords": "Config.options.notifications.maxVisible"
    },
    {
        "id": "ExperienceConfig.expand-notifications-on-hover",
        "source": "ExperienceConfig",
        "route": "notifications",
        "routes": [
            "notifications"
        ],
        "label": "Expand notifications on hover",
        "section": "Notification experience",
        "legacyPage": "Experience",
        "legacySections": [
            "Notification experience"
        ],
        "keywords": "Config.options.notifications.expandOnHover"
    },
    {
        "id": "ExperienceConfig.hover-expand-delay-ms",
        "source": "ExperienceConfig",
        "route": "notification-rules",
        "routes": [
            "notification-rules"
        ],
        "label": "Hover expand delay (ms)",
        "section": "Notification experience",
        "legacyPage": "Experience",
        "legacySections": [
            "Notification experience"
        ],
        "keywords": "Config.options.notifications.expandOnHover Config.options.notifications.hoverExpandDelay"
    },
    {
        "id": "ExperienceConfig.show-preview-on-system-icons-hover",
        "source": "ExperienceConfig",
        "route": "notification-rules",
        "routes": [
            "notification-rules"
        ],
        "label": "Show preview on system-icons hover",
        "section": "Notification experience",
        "legacyPage": "Experience",
        "legacySections": [
            "Notification experience"
        ],
        "keywords": "Config.options.bar.systemIconsHover.enable"
    },
    {
        "id": "ExperienceConfig.recent-items",
        "source": "ExperienceConfig",
        "route": "notification-rules",
        "routes": [
            "notification-rules"
        ],
        "label": "Recent items",
        "section": "Notification experience",
        "legacyPage": "Experience",
        "legacySections": [
            "Notification experience"
        ],
        "keywords": "Config.options.bar.systemIconsHover.enable Config.options.bar.systemIconsHover.recentLimit"
    },
    {
        "id": "ExperienceConfig.per-app-notification-rules-json",
        "source": "ExperienceConfig",
        "route": "notification-rules",
        "routes": [
            "notification-rules"
        ],
        "label": "Per-app notification rules (JSON)",
        "section": "Notification experience",
        "legacyPage": "Experience",
        "legacySections": [
            "Notification experience"
        ],
        "keywords": "Config.options.notifications.appRules"
    },
    {
        "id": "ExperienceConfig.use-generated-theme-colours-for-window-borders",
        "source": "ExperienceConfig",
        "route": "effects",
        "routes": [
            "effects"
        ],
        "label": "Use generated theme colours for window borders",
        "section": "Windows & focus",
        "legacyPage": "Experience",
        "legacySections": [
            "Windows & focus"
        ],
        "keywords": "Config.options.hyprland.general.autoThemeBorders"
    },
    {
        "id": "ExperienceConfig.presentation",
        "source": "ExperienceConfig",
        "route": "session",
        "routes": [
            "session"
        ],
        "label": "Presentation",
        "section": "Session screen",
        "legacyPage": "Experience",
        "legacySections": [
            "Session screen"
        ],
        "keywords": "Config.options.sessionScreen.presentation"
    },
    {
        "id": "ExperienceConfig.side",
        "source": "ExperienceConfig",
        "route": "session",
        "routes": [
            "session"
        ],
        "label": "Side",
        "section": "Session screen",
        "legacyPage": "Experience",
        "legacySections": [
            "Session screen"
        ],
        "keywords": "Config.options.sessionScreen.presentation Config.options.sessionScreen.edge"
    },
    {
        "id": "ExperienceConfig.side-sheet-width",
        "source": "ExperienceConfig",
        "route": "session-details",
        "routes": [
            "session-details"
        ],
        "label": "Side sheet width",
        "section": "Session screen",
        "legacyPage": "Experience",
        "legacySections": [
            "Session screen"
        ],
        "keywords": "Config.options.sessionScreen.presentation Config.options.sessionScreen.edgeWidth"
    },
    {
        "id": "ExperienceConfig.action-layout",
        "source": "ExperienceConfig",
        "route": "session-details",
        "routes": [
            "session-details"
        ],
        "label": "Action layout",
        "section": "Session screen",
        "legacyPage": "Experience",
        "legacySections": [
            "Session screen"
        ],
        "keywords": "Config.options.sessionScreen.columns"
    },
    {
        "id": "ExperienceConfig.show-hibernate",
        "source": "ExperienceConfig",
        "route": "session",
        "routes": [
            "session"
        ],
        "label": "Show hibernate",
        "section": "Session screen",
        "legacyPage": "Experience",
        "legacySections": [
            "Session screen"
        ],
        "keywords": "Config.options.sessionScreen.showHibernate"
    },
    {
        "id": "ExperienceConfig.show-task-manager",
        "source": "ExperienceConfig",
        "route": "session",
        "routes": [
            "session"
        ],
        "label": "Show task manager",
        "section": "Session screen",
        "legacyPage": "Experience",
        "legacySections": [
            "Session screen"
        ],
        "keywords": "Config.options.sessionScreen.showTaskManager"
    },
    {
        "id": "ExperienceConfig.show-firmware-reboot",
        "source": "ExperienceConfig",
        "route": "session",
        "routes": [
            "session"
        ],
        "label": "Show firmware reboot",
        "section": "Session screen",
        "legacyPage": "Experience",
        "legacySections": [
            "Session screen"
        ],
        "keywords": "Config.options.sessionScreen.showFirmware"
    },
    {
        "id": "ExperienceConfig.show-safety-warnings",
        "source": "ExperienceConfig",
        "route": "session",
        "routes": [
            "session"
        ],
        "label": "Show safety warnings",
        "section": "Session screen",
        "legacyPage": "Experience",
        "legacySections": [
            "Session screen"
        ],
        "keywords": "Config.options.sessionScreen.showWarnings"
    },
    {
        "id": "ExperienceConfig.confirm-shutdown-reboot-and-firmware-actions",
        "source": "ExperienceConfig",
        "route": "session",
        "routes": [
            "session"
        ],
        "label": "Confirm shutdown, reboot, and firmware actions",
        "section": "Session screen",
        "legacyPage": "Experience",
        "legacySections": [
            "Session screen"
        ],
        "keywords": "Config.options.sessionScreen.confirmDestructive"
    },
    {
        "id": "ExperienceConfig.show-focus-break-label",
        "source": "ExperienceConfig",
        "route": "panels",
        "routes": [
            "panels"
        ],
        "label": "Show focus / break label",
        "section": "Pomodoro in the bar",
        "legacyPage": "Experience",
        "legacySections": [
            "Pomodoro in the bar"
        ],
        "keywords": "Config.options.bar.pomodoro.showLabel"
    },
    {
        "id": "ExperienceConfig.show-seconds",
        "source": "ExperienceConfig",
        "route": "panels",
        "routes": [
            "panels"
        ],
        "label": "Show seconds",
        "section": "Pomodoro in the bar",
        "legacyPage": "Experience",
        "legacySections": [
            "Pomodoro in the bar"
        ],
        "keywords": "Config.options.bar.pomodoro.showSeconds"
    },
    {
        "id": "ExperienceConfig.click-action",
        "source": "ExperienceConfig",
        "route": "panels",
        "routes": [
            "panels"
        ],
        "label": "Click action",
        "section": "Pomodoro in the bar",
        "legacyPage": "Experience",
        "legacySections": [
            "Pomodoro in the bar"
        ],
        "keywords": "Config.options.bar.pomodoro.clickAction"
    },
    {
        "id": "InterfaceConfig.use-one-workspace-set-across-all-screens",
        "source": "InterfaceConfig",
        "route": "devices",
        "routes": [
            "devices"
        ],
        "label": "Use one workspace set across all screens",
        "section": "Screens & workspaces",
        "legacyPage": "Interface",
        "legacySections": [
            "Screens & workspaces"
        ],
        "keywords": "Config.options.workspaceLinking.unifiedMultiMonitor"
    },
    {
        "id": "InterfaceConfig.extra-background-tint",
        "source": "InterfaceConfig",
        "route": "effects",
        "routes": [
            "effects"
        ],
        "label": "Extra Background Tint",
        "section": "Appearance",
        "legacyPage": "Interface",
        "legacySections": [
            "Appearance"
        ],
        "keywords": "Config.options.appearance.extraBackgroundTint"
    },
    {
        "id": "InterfaceConfig.fake-screen-rounding",
        "source": "InterfaceConfig",
        "route": "effects",
        "routes": [
            "effects"
        ],
        "label": "Fake Screen Rounding",
        "section": "Appearance",
        "legacyPage": "Interface",
        "legacySections": [
            "Appearance"
        ],
        "keywords": "Config.options.appearance.fakeScreenRounding"
    },
    {
        "id": "InterfaceConfig.panel-style",
        "source": "InterfaceConfig",
        "route": "appearance",
        "routes": [
            "appearance"
        ],
        "label": "Panel style",
        "section": "Visual Effect",
        "legacyPage": "Interface",
        "legacySections": [
            "Appearance",
            "Visual Effect"
        ],
        "keywords": "Config.options.appearance.visualEffect Config.options.hyprland.decoration.blur.enabled Config.options.hyprland.decoration.blur.variant"
    },
    {
        "id": "InterfaceConfig.panel-translucency",
        "source": "InterfaceConfig",
        "route": "effects",
        "routes": [
            "effects"
        ],
        "label": "Panel translucency",
        "section": "Window Transparency (for Blur/Glass)",
        "legacyPage": "Interface",
        "legacySections": [
            "Appearance",
            "Window Transparency (for Blur/Glass)"
        ],
        "keywords": "Config.options.appearance.visualEffect Config.options.appearance.blurPanelTransparency"
    },
    {
        "id": "InterfaceConfig.automatic-disables-background-slider",
        "source": "InterfaceConfig",
        "route": "effects",
        "routes": [
            "effects"
        ],
        "label": "Automatic (disables Background slider)",
        "section": "Transparency",
        "legacyPage": "Interface",
        "legacySections": [
            "Appearance",
            "Transparency"
        ],
        "keywords": "Config.options.appearance.transparency.enable Config.options.appearance.transparency.automatic"
    },
    {
        "id": "InterfaceConfig.background",
        "source": "InterfaceConfig",
        "route": "effects",
        "routes": [
            "effects"
        ],
        "label": "Background",
        "section": "Transparency",
        "legacyPage": "Interface",
        "legacySections": [
            "Appearance",
            "Transparency"
        ],
        "keywords": "Config.options.appearance.transparency.enable Config.options.appearance.transparency.automatic Config.options.appearance.transparency.backgroundTransparency"
    },
    {
        "id": "InterfaceConfig.content",
        "source": "InterfaceConfig",
        "route": "effects",
        "routes": [
            "effects"
        ],
        "label": "Content",
        "section": "Transparency",
        "legacyPage": "Interface",
        "legacySections": [
            "Appearance",
            "Transparency"
        ],
        "keywords": "Config.options.appearance.transparency.enable Config.options.appearance.transparency.contentTransparency"
    },
    {
        "id": "InterfaceConfig.glass-opacity",
        "source": "InterfaceConfig",
        "route": "effects",
        "routes": [
            "effects"
        ],
        "label": "Glass opacity",
        "section": "Liquid Glass",
        "legacyPage": "Interface",
        "legacySections": [
            "Appearance",
            "Liquid Glass"
        ],
        "keywords": "Config.options.appearance.glass.enable Config.options.appearance.glass.opacity"
    },
    {
        "id": "InterfaceConfig.animation-style",
        "source": "InterfaceConfig",
        "route": "appearance",
        "routes": [
            "appearance"
        ],
        "label": "Animation style",
        "section": "Motion",
        "legacyPage": "Interface",
        "legacySections": [
            "Appearance",
            "Motion"
        ],
        "keywords": "Config.options.appearance.motion.style"
    },
    {
        "id": "InterfaceConfig.animation-speed",
        "source": "InterfaceConfig",
        "route": "effects",
        "routes": [
            "effects"
        ],
        "label": "Animation speed",
        "section": "Motion",
        "legacyPage": "Interface",
        "legacySections": [
            "Appearance",
            "Motion"
        ],
        "keywords": "Config.options.appearance.motion.durationScale"
    },
    {
        "id": "InterfaceConfig.accent-color-hex-empty-auto",
        "source": "InterfaceConfig",
        "route": "effects",
        "routes": [
            "effects"
        ],
        "label": "Accent Color (hex, empty=auto)",
        "section": "Palette",
        "legacyPage": "Interface",
        "legacySections": [
            "Appearance",
            "Palette"
        ],
        "keywords": "Config.options.appearance.palette.accentColor"
    },
    {
        "id": "InterfaceConfig.style",
        "source": "InterfaceConfig",
        "route": "panel-details",
        "routes": [
            "panel-details"
        ],
        "label": "Style",
        "section": "Settings Panel",
        "legacyPage": "Interface",
        "legacySections": [
            "Settings Panel"
        ],
        "keywords": "Config.options.settings.style"
    },
    {
        "id": "InterfaceConfig.normal-window",
        "source": "InterfaceConfig",
        "route": "panel-details",
        "routes": [
            "panel-details"
        ],
        "label": "Normal window mode",
        "section": "Settings Panel",
        "legacyPage": "Interface",
        "legacySections": [
            "Settings Panel"
        ],
        "keywords": "Config.options.settings.normalWindow"
    },
    {
        "id": "InterfaceConfig.window-width",
        "source": "InterfaceConfig",
        "route": "panel-details",
        "routes": [
            "panel-details"
        ],
        "label": "Window width",
        "section": "Settings Panel",
        "legacyPage": "Interface",
        "legacySections": [
            "Settings Panel"
        ],
        "keywords": "Config.options.settings.preferredWidth"
    },
    {
        "id": "InterfaceConfig.window-height",
        "source": "InterfaceConfig",
        "route": "panel-details",
        "routes": [
            "panel-details"
        ],
        "label": "Window height",
        "section": "Settings Panel",
        "legacyPage": "Interface",
        "legacySections": [
            "Settings Panel"
        ],
        "keywords": "Config.options.settings.preferredHeight"
    },
    {
        "id": "InterfaceConfig.border-width",
        "source": "InterfaceConfig",
        "route": "panel-details",
        "routes": [
            "panel-details"
        ],
        "label": "Border width",
        "section": "Settings Panel",
        "legacyPage": "Interface",
        "legacySections": [
            "Settings Panel"
        ],
        "keywords": "Config.options.settings.borderSize"
    },
    {
        "id": "InterfaceConfig.border-color",
        "source": "InterfaceConfig",
        "route": "panel-details",
        "routes": [
            "panel-details"
        ],
        "label": "Border Color",
        "section": "Settings Panel",
        "legacyPage": "Interface",
        "legacySections": [
            "Settings Panel"
        ],
        "keywords": "Config.options.settings.borderColor"
    },
    {
        "id": "InterfaceConfig.enable",
        "source": "InterfaceConfig",
        "route": "panels",
        "routes": [
            "panels"
        ],
        "label": "Enable",
        "section": "Left Sidebar",
        "legacyPage": "Interface",
        "legacySections": [
            "Left Sidebar"
        ],
        "keywords": "Config.options.sidebar.media.enable"
    },
    {
        "id": "InterfaceConfig.follow-album-colors",
        "source": "InterfaceConfig",
        "route": "panels",
        "routes": [
            "panels"
        ],
        "label": "Follow Album Colors",
        "section": "Left Sidebar",
        "legacyPage": "Interface",
        "legacySections": [
            "Left Sidebar"
        ],
        "keywords": "Config.options.sidebar.media.artColors"
    },
    {
        "id": "InterfaceConfig.left-sidebar",
        "source": "InterfaceConfig",
        "route": "apps",
        "routes": [
            "apps"
        ],
        "label": "Left Sidebar",
        "section": "Left Sidebar",
        "legacyPage": "Interface",
        "legacySections": [
            "Left Sidebar"
        ],
        "keywords": "Config.options.policies.ai"
    },
    {
        "id": "InterfaceConfig.left-sidebar-2",
        "source": "InterfaceConfig",
        "route": "apps",
        "routes": [
            "apps"
        ],
        "label": "Left Sidebar",
        "section": "Left Sidebar",
        "legacyPage": "Interface",
        "legacySections": [
            "Left Sidebar"
        ],
        "keywords": "Config.options.policies.weeb"
    },
    {
        "id": "InterfaceConfig.enable-translator",
        "source": "InterfaceConfig",
        "route": "apps",
        "routes": [
            "apps"
        ],
        "label": "Enable Translator",
        "section": "Left Sidebar",
        "legacyPage": "Interface",
        "legacySections": [
            "Left Sidebar"
        ],
        "keywords": "Config.options.sidebar.translator.enable"
    },
    {
        "id": "InterfaceConfig.banner",
        "source": "InterfaceConfig",
        "route": "panels",
        "routes": [
            "panels"
        ],
        "label": "Banner",
        "section": "Right Sidebar",
        "legacyPage": "Interface",
        "legacySections": [
            "Right Sidebar"
        ],
        "keywords": "Config.options.sidebar.banner"
    },
    {
        "id": "InterfaceConfig.bottom-group",
        "source": "InterfaceConfig",
        "route": "panels",
        "routes": [
            "panels"
        ],
        "label": "Bottom Group",
        "section": "Right Sidebar",
        "legacyPage": "Interface",
        "legacySections": [
            "Right Sidebar"
        ],
        "keywords": "Config.options.sidebar.bottomGroup"
    },
    {
        "id": "InterfaceConfig.media-player",
        "source": "InterfaceConfig",
        "route": "panels",
        "routes": [
            "panels"
        ],
        "label": "Media Player",
        "section": "Right Sidebar",
        "legacyPage": "Interface",
        "legacySections": [
            "Right Sidebar"
        ],
        "keywords": "Config.options.sidebar.mediaPlayer"
    },
    {
        "id": "InterfaceConfig.keep-right-sidebar-loaded",
        "source": "InterfaceConfig",
        "route": "panel-details",
        "routes": [
            "panel-details"
        ],
        "label": "Keep right sidebar loaded",
        "section": "Right Sidebar",
        "legacyPage": "Interface",
        "legacySections": [
            "Right Sidebar"
        ],
        "keywords": "Config.options.sidebar.keepRightSidebarLoaded"
    },
    {
        "id": "InterfaceConfig.style-2",
        "source": "InterfaceConfig",
        "route": "panels",
        "routes": [
            "panels"
        ],
        "label": "Style",
        "section": "Quick toggles",
        "legacyPage": "Interface",
        "legacySections": [
            "Right Sidebar",
            "Quick toggles"
        ],
        "keywords": "Config.options.sidebar.quickToggles.style"
    },
    {
        "id": "InterfaceConfig.columns",
        "source": "InterfaceConfig",
        "route": "panel-details",
        "routes": [
            "panel-details"
        ],
        "label": "Columns",
        "section": "Quick toggles",
        "legacyPage": "Interface",
        "legacySections": [
            "Right Sidebar",
            "Quick toggles"
        ],
        "keywords": "Config.options.sidebar.quickToggles.style Config.options.sidebar.quickToggles.android.columns"
    },
    {
        "id": "InterfaceConfig.enable-2",
        "source": "InterfaceConfig",
        "route": "panels",
        "routes": [
            "panels"
        ],
        "label": "Enable",
        "section": "Sliders",
        "legacyPage": "Interface",
        "legacySections": [
            "Right Sidebar",
            "Sliders"
        ],
        "keywords": "Config.options.sidebar.quickSliders.enable"
    },
    {
        "id": "InterfaceConfig.brightness",
        "source": "InterfaceConfig",
        "route": "panels",
        "routes": [
            "panels"
        ],
        "label": "Brightness",
        "section": "Sliders",
        "legacyPage": "Interface",
        "legacySections": [
            "Right Sidebar",
            "Sliders"
        ],
        "keywords": "Config.options.sidebar.quickSliders.enable Config.options.sidebar.quickSliders.showBrightness"
    },
    {
        "id": "InterfaceConfig.volume",
        "source": "InterfaceConfig",
        "route": "panels",
        "routes": [
            "panels"
        ],
        "label": "Volume",
        "section": "Sliders",
        "legacyPage": "Interface",
        "legacySections": [
            "Right Sidebar",
            "Sliders"
        ],
        "keywords": "Config.options.sidebar.quickSliders.enable Config.options.sidebar.quickSliders.showVolume"
    },
    {
        "id": "InterfaceConfig.microphone",
        "source": "InterfaceConfig",
        "route": "panels",
        "routes": [
            "panels"
        ],
        "label": "Microphone",
        "section": "Sliders",
        "legacyPage": "Interface",
        "legacySections": [
            "Right Sidebar",
            "Sliders"
        ],
        "keywords": "Config.options.sidebar.quickSliders.enable Config.options.sidebar.quickSliders.showMic"
    },
    {
        "id": "InterfaceConfig.enable-3",
        "source": "InterfaceConfig",
        "route": "devices",
        "routes": [
            "devices"
        ],
        "label": "Enable",
        "section": "Top",
        "legacyPage": "Interface",
        "legacySections": [
            "Hot Corners",
            "Top"
        ],
        "keywords": "Config.options.sidebar.cornerOpen.enable"
    },
    {
        "id": "InterfaceConfig.hover-to-trigger",
        "source": "InterfaceConfig",
        "route": "devices",
        "routes": [
            "devices"
        ],
        "label": "Hover to trigger",
        "section": "Top",
        "legacyPage": "Interface",
        "legacySections": [
            "Hot Corners",
            "Top"
        ],
        "keywords": "Config.options.sidebar.cornerOpen.clickless"
    },
    {
        "id": "InterfaceConfig.place-at-bottom",
        "source": "InterfaceConfig",
        "route": "devices",
        "routes": [
            "devices"
        ],
        "label": "Place at bottom",
        "section": "Top",
        "legacyPage": "Interface",
        "legacySections": [
            "Hot Corners",
            "Top"
        ],
        "keywords": "Config.options.sidebar.cornerOpen.bottom"
    },
    {
        "id": "InterfaceConfig.value-scroll",
        "source": "InterfaceConfig",
        "route": "devices",
        "routes": [
            "devices"
        ],
        "label": "Value scroll",
        "section": "Top",
        "legacyPage": "Interface",
        "legacySections": [
            "Hot Corners",
            "Top"
        ],
        "keywords": "Config.options.sidebar.cornerOpen.valueScroll"
    },
    {
        "id": "InterfaceConfig.visualize-region",
        "source": "InterfaceConfig",
        "route": "input-details",
        "routes": [
            "input-details"
        ],
        "label": "Visualize region",
        "section": "Top",
        "legacyPage": "Interface",
        "legacySections": [
            "Hot Corners",
            "Top"
        ],
        "keywords": "Config.options.sidebar.cornerOpen.visualize"
    },
    {
        "id": "InterfaceConfig.force-hover-at-absolute-corner",
        "source": "InterfaceConfig",
        "route": "input-details",
        "routes": [
            "input-details"
        ],
        "label": "Force hover at absolute corner",
        "section": "Top",
        "legacyPage": "Interface",
        "legacySections": [
            "Hot Corners",
            "Top"
        ],
        "keywords": "Config.options.sidebar.cornerOpen.clickless Config.options.sidebar.cornerOpen.clicklessCornerEnd"
    },
    {
        "id": "InterfaceConfig.enable-hover-trigger-on-bottom-corners",
        "source": "InterfaceConfig",
        "route": "input-details",
        "routes": [
            "input-details"
        ],
        "label": "Enable hover trigger on bottom corners",
        "section": "Top",
        "legacyPage": "Interface",
        "legacySections": [
            "Hot Corners",
            "Top"
        ],
        "keywords": "Config.options.sidebar.cornerOpen.clickless Config.options.sidebar.cornerOpen.hoverAllCorners"
    },
    {
        "id": "InterfaceConfig.vertical-offset",
        "source": "InterfaceConfig",
        "route": "input-details",
        "routes": [
            "input-details"
        ],
        "label": "Vertical offset",
        "section": "Top",
        "legacyPage": "Interface",
        "legacySections": [
            "Hot Corners",
            "Top"
        ],
        "keywords": "Config.options.sidebar.cornerOpen.clickless Config.options.sidebar.cornerOpen.clicklessCornerVerticalOffset"
    },
    {
        "id": "InterfaceConfig.region-width",
        "source": "InterfaceConfig",
        "route": "input-details",
        "routes": [
            "input-details"
        ],
        "label": "Region width",
        "section": "Top",
        "legacyPage": "Interface",
        "legacySections": [
            "Hot Corners",
            "Top"
        ],
        "keywords": "Config.options.sidebar.cornerOpen.cornerRegionWidth"
    },
    {
        "id": "InterfaceConfig.region-height",
        "source": "InterfaceConfig",
        "route": "input-details",
        "routes": [
            "input-details"
        ],
        "label": "Region height",
        "section": "Top",
        "legacyPage": "Interface",
        "legacySections": [
            "Hot Corners",
            "Top"
        ],
        "keywords": "Config.options.sidebar.cornerOpen.cornerRegionHeight"
    },
    {
        "id": "InterfaceConfig.left-corner-scroll",
        "source": "InterfaceConfig",
        "route": "devices",
        "routes": [
            "devices"
        ],
        "label": "Left-corner scroll",
        "section": "Top",
        "legacyPage": "Interface",
        "legacySections": [
            "Hot Corners",
            "Top"
        ],
        "keywords": "Config.options.sidebar.cornerOpen.leftScrollAction"
    },
    {
        "id": "InterfaceConfig.right-corner-scroll",
        "source": "InterfaceConfig",
        "route": "devices",
        "routes": [
            "devices"
        ],
        "label": "Right-corner scroll",
        "section": "Top",
        "legacyPage": "Interface",
        "legacySections": [
            "Hot Corners",
            "Top"
        ],
        "keywords": "Config.options.sidebar.cornerOpen.rightScrollAction"
    },
    {
        "id": "InterfaceConfig.show-workspaces-in-launcher-super",
        "source": "InterfaceConfig",
        "route": "panels",
        "routes": [
            "panels"
        ],
        "label": "Show workspaces in launcher (SUPER)",
        "section": "Overview",
        "legacyPage": "Interface",
        "legacySections": [
            "Overview"
        ],
        "keywords": "Config.options.overview.showWorkspacesInLauncher"
    },
    {
        "id": "InterfaceConfig.animate-center-position",
        "source": "InterfaceConfig",
        "route": "panel-details",
        "routes": [
            "panel-details"
        ],
        "label": "Animate center position",
        "section": "Overview",
        "legacyPage": "Interface",
        "legacySections": [
            "Overview"
        ],
        "keywords": "Config.options.overview.centerAnimation"
    },
    {
        "id": "InterfaceConfig.center-animation-delay-ms",
        "source": "InterfaceConfig",
        "route": "panel-details",
        "routes": [
            "panel-details"
        ],
        "label": "Center animation delay (ms)",
        "section": "Overview",
        "legacyPage": "Interface",
        "legacySections": [
            "Overview"
        ],
        "keywords": "Config.options.overview.centerAnimation Config.options.overview.centerAnimationDuration"
    },
    {
        "id": "InterfaceConfig.enable-4",
        "source": "InterfaceConfig",
        "route": "panels",
        "routes": [
            "panels"
        ],
        "label": "Enable",
        "section": "Overview",
        "legacyPage": "Interface",
        "legacySections": [
            "Overview"
        ],
        "keywords": "Config.options.overview.enable"
    },
    {
        "id": "InterfaceConfig.center-icons",
        "source": "InterfaceConfig",
        "route": "panels",
        "routes": [
            "panels"
        ],
        "label": "Center icons",
        "section": "Overview",
        "legacyPage": "Interface",
        "legacySections": [
            "Overview"
        ],
        "keywords": "Config.options.overview.centerIcons"
    },
    {
        "id": "InterfaceConfig.scale",
        "source": "InterfaceConfig",
        "route": "panel-details",
        "routes": [
            "panel-details"
        ],
        "label": "Scale (%)",
        "section": "Overview",
        "legacyPage": "Interface",
        "legacySections": [
            "Overview"
        ],
        "keywords": "Config.options.overview.scale"
    },
    {
        "id": "InterfaceConfig.style-3",
        "source": "InterfaceConfig",
        "route": "panels",
        "routes": [
            "panels"
        ],
        "label": "Style",
        "section": "Overview",
        "legacyPage": "Interface",
        "legacySections": [
            "Overview"
        ],
        "keywords": "Config.options.overview.style"
    },
    {
        "id": "InterfaceConfig.rows",
        "source": "InterfaceConfig",
        "route": "panel-details",
        "routes": [
            "panel-details"
        ],
        "label": "Rows",
        "section": "Grid layout",
        "legacyPage": "Interface",
        "legacySections": [
            "Overview",
            "Default Settings"
        ],
        "keywords": "Config.options.overview.rows"
    },
    {
        "id": "InterfaceConfig.columns-2",
        "source": "InterfaceConfig",
        "route": "panel-details",
        "routes": [
            "panel-details"
        ],
        "label": "Columns",
        "section": "Grid layout",
        "legacyPage": "Interface",
        "legacySections": [
            "Overview",
            "Default Settings"
        ],
        "keywords": "Config.options.overview.columns"
    },
    {
        "id": "InterfaceConfig.default-settings",
        "source": "InterfaceConfig",
        "route": "panels",
        "routes": [
            "panels"
        ],
        "label": "Default Settings",
        "section": "Grid layout",
        "legacyPage": "Interface",
        "legacySections": [
            "Overview",
            "Default Settings"
        ],
        "keywords": "Config.options.overview.orderRightLeft"
    },
    {
        "id": "InterfaceConfig.default-settings-2",
        "source": "InterfaceConfig",
        "route": "panels",
        "routes": [
            "panels"
        ],
        "label": "Default Settings",
        "section": "Grid layout",
        "legacyPage": "Interface",
        "legacySections": [
            "Overview",
            "Default Settings"
        ],
        "keywords": "Config.options.overview.orderBottomUp"
    },
    {
        "id": "InterfaceConfig.enable-5",
        "source": "InterfaceConfig",
        "route": "panels",
        "routes": [
            "panels"
        ],
        "label": "Enable",
        "section": "Dock",
        "legacyPage": "Interface",
        "legacySections": [
            "Dock"
        ],
        "keywords": "Config.options.dock.enable"
    },
    {
        "id": "InterfaceConfig.background-2",
        "source": "InterfaceConfig",
        "route": "panels",
        "routes": [
            "panels"
        ],
        "label": "Background",
        "section": "Dock",
        "legacyPage": "Interface",
        "legacySections": [
            "Dock"
        ],
        "keywords": "Config.options.dock.showBackground"
    },
    {
        "id": "InterfaceConfig.hover-to-reveal",
        "source": "InterfaceConfig",
        "route": "panels",
        "routes": [
            "panels"
        ],
        "label": "Hover to reveal",
        "section": "Dock",
        "legacyPage": "Interface",
        "legacySections": [
            "Dock"
        ],
        "keywords": "Config.options.dock.hoverToReveal"
    },
    {
        "id": "InterfaceConfig.pinned-on-startup",
        "source": "InterfaceConfig",
        "route": "panels",
        "routes": [
            "panels"
        ],
        "label": "Pinned on startup",
        "section": "Dock",
        "legacyPage": "Interface",
        "legacySections": [
            "Dock"
        ],
        "keywords": "Config.options.dock.pinnedOnStartup"
    },
    {
        "id": "InterfaceConfig.media-player-2",
        "source": "InterfaceConfig",
        "route": "panels",
        "routes": [
            "panels"
        ],
        "label": "Media Player",
        "section": "Buttons & Media",
        "legacyPage": "Interface",
        "legacySections": [
            "Dock",
            "Buttons & Media"
        ],
        "keywords": "Config.options.dock.showMedia"
    },
    {
        "id": "InterfaceConfig.show-pin-button",
        "source": "InterfaceConfig",
        "route": "panels",
        "routes": [
            "panels"
        ],
        "label": "Show Pin Button",
        "section": "Buttons & Media",
        "legacyPage": "Interface",
        "legacySections": [
            "Dock",
            "Buttons & Media"
        ],
        "keywords": "Config.options.dock.showPinButton"
    },
    {
        "id": "InterfaceConfig.show-apps-button",
        "source": "InterfaceConfig",
        "route": "panels",
        "routes": [
            "panels"
        ],
        "label": "Show Apps Button",
        "section": "Buttons & Media",
        "legacyPage": "Interface",
        "legacySections": [
            "Dock",
            "Buttons & Media"
        ],
        "keywords": "Config.options.dock.showAppsButton"
    },
    {
        "id": "InterfaceConfig.use-original-icon-colors",
        "source": "InterfaceConfig",
        "route": "panels",
        "routes": [
            "panels"
        ],
        "label": "Use original icon colors",
        "section": "Buttons & Media",
        "legacyPage": "Interface",
        "legacySections": [
            "Dock",
            "Buttons & Media"
        ],
        "keywords": "Config.options.dock.monochromeIcons"
    },
    {
        "id": "InterfaceConfig.cursor-size",
        "source": "InterfaceConfig",
        "route": "appearance",
        "routes": [
            "appearance"
        ],
        "label": "Cursor size",
        "section": "System themes",
        "legacyPage": "Interface",
        "legacySections": [
            "System themes"
        ],
        "keywords": ""
    },
    {
        "id": "InterfaceConfig.use-hyprlock-instead-of-quickshell",
        "source": "InterfaceConfig",
        "route": "session-details",
        "routes": [
            "session-details"
        ],
        "label": "Use Hyprlock (instead of Quickshell)",
        "section": "Lock screen",
        "legacyPage": "Interface",
        "legacySections": [
            "Lock screen"
        ],
        "keywords": "Config.options.lock.useHyprlock"
    },
    {
        "id": "InterfaceConfig.launch-on-startup",
        "source": "InterfaceConfig",
        "route": "session",
        "routes": [
            "session"
        ],
        "label": "Launch on startup",
        "section": "Lock screen",
        "legacyPage": "Interface",
        "legacySections": [
            "Lock screen"
        ],
        "keywords": "Config.options.lock.launchOnStartup"
    },
    {
        "id": "InterfaceConfig.show-widgets",
        "source": "InterfaceConfig",
        "route": "session",
        "routes": [
            "session"
        ],
        "label": "Show Widgets",
        "section": "Lock screen",
        "legacyPage": "Interface",
        "legacySections": [
            "Lock screen"
        ],
        "keywords": "Config.options.lock.showWidgets"
    },
    {
        "id": "InterfaceConfig.show-toolbars",
        "source": "InterfaceConfig",
        "route": "session",
        "routes": [
            "session"
        ],
        "label": "Show Toolbars",
        "section": "Lock screen",
        "legacyPage": "Interface",
        "legacySections": [
            "Lock screen"
        ],
        "keywords": "Config.options.lock.showToolbars"
    },
    {
        "id": "InterfaceConfig.show-left-toolbar-username-media",
        "source": "InterfaceConfig",
        "route": "session",
        "routes": [
            "session"
        ],
        "label": "Show left toolbar (username/media)",
        "section": "Lock screen",
        "legacyPage": "Interface",
        "legacySections": [
            "Lock screen"
        ],
        "keywords": "Config.options.lock.showToolbars Config.options.lock.showLeftToolbar"
    },
    {
        "id": "InterfaceConfig.show-right-toolbar-battery-power",
        "source": "InterfaceConfig",
        "route": "session",
        "routes": [
            "session"
        ],
        "label": "Show right toolbar (battery/power)",
        "section": "Lock screen",
        "legacyPage": "Interface",
        "legacySections": [
            "Lock screen"
        ],
        "keywords": "Config.options.lock.showToolbars Config.options.lock.showRightToolbar"
    },
    {
        "id": "InterfaceConfig.show-media-player-info",
        "source": "InterfaceConfig",
        "route": "session",
        "routes": [
            "session"
        ],
        "label": "Show media player info",
        "section": "Lock screen",
        "legacyPage": "Interface",
        "legacySections": [
            "Lock screen"
        ],
        "keywords": "Config.options.lock.showToolbars Config.options.lock.showLeftToolbar Config.options.lock.showMedia"
    },
    {
        "id": "InterfaceConfig.hide-lock-controls-when-idle",
        "source": "InterfaceConfig",
        "route": "session",
        "routes": [
            "session"
        ],
        "label": "Hide lock controls when idle",
        "section": "Lock screen",
        "legacyPage": "Interface",
        "legacySections": [
            "Lock screen"
        ],
        "keywords": "Config.options.lock.autoHideControls"
    },
    {
        "id": "InterfaceConfig.hide-controls-after-seconds",
        "source": "InterfaceConfig",
        "route": "session",
        "routes": [
            "session"
        ],
        "label": "Hide controls after (seconds)",
        "section": "Lock screen",
        "legacyPage": "Interface",
        "legacySections": [
            "Lock screen"
        ],
        "keywords": "Config.options.lock.autoHideControls Config.options.lock.controlsIdleSeconds"
    },
    {
        "id": "InterfaceConfig.customize-lock-layout-per-display",
        "source": "InterfaceConfig",
        "route": "session-details",
        "routes": [
            "session-details"
        ],
        "label": "Customize lock layout per display",
        "section": "Lock screen",
        "legacyPage": "Interface",
        "legacySections": [
            "Lock screen"
        ],
        "keywords": "Config.options.lock.perScreenLayout"
    },
    {
        "id": "InterfaceConfig.unlock-box-just-on-the-primary-monitor",
        "source": "InterfaceConfig",
        "route": "session-details",
        "routes": [
            "session-details"
        ],
        "label": "Unlock box just on the primary monitor",
        "section": "Lock screen",
        "legacyPage": "Interface",
        "legacySections": [
            "Lock screen"
        ],
        "keywords": "Config.options.lock.unlockBoxPrimaryMonitorOnly"
    },
    {
        "id": "InterfaceConfig.lock-screen-live-preview",
        "source": "InterfaceConfig",
        "route": "session",
        "routes": [
            "session"
        ],
        "label": "Lock screen live preview",
        "section": "Live preview",
        "legacyPage": "Interface",
        "legacySections": [
            "Lock screen",
            "Lock screen live preview"
        ],
        "keywords": "Config.options.lock.showWidgets"
    },
    {
        "id": "InterfaceConfig.require-password-to-power-off-restart",
        "source": "InterfaceConfig",
        "route": "session",
        "routes": [
            "session"
        ],
        "label": "Require password to power off/restart",
        "section": "Security",
        "legacyPage": "Interface",
        "legacySections": [
            "Lock screen",
            "Security"
        ],
        "keywords": "Config.options.lock.security.requirePasswordToPower"
    },
    {
        "id": "InterfaceConfig.also-unlock-keyring",
        "source": "InterfaceConfig",
        "route": "session-details",
        "routes": [
            "session-details"
        ],
        "label": "Also unlock keyring",
        "section": "Security",
        "legacyPage": "Interface",
        "legacySections": [
            "Lock screen",
            "Security"
        ],
        "keywords": "Config.options.lock.security.unlockKeyring"
    },
    {
        "id": "InterfaceConfig.enable-fingerprint-unlock-fprintd-pam",
        "source": "InterfaceConfig",
        "route": "session",
        "routes": [
            "session"
        ],
        "label": "Enable fingerprint unlock (fprintd / PAM)",
        "section": "Biometrics",
        "legacyPage": "Interface",
        "legacySections": [
            "Lock screen",
            "Biometrics"
        ],
        "keywords": "Config.options.lock.biometrics.enableFingerprint"
    },
    {
        "id": "InterfaceConfig.start-fingerprint-scan-when-locked",
        "source": "InterfaceConfig",
        "route": "session-details",
        "routes": [
            "session-details"
        ],
        "label": "Start fingerprint scan when locked",
        "section": "Biometrics",
        "legacyPage": "Interface",
        "legacySections": [
            "Lock screen",
            "Biometrics"
        ],
        "keywords": "Config.options.lock.biometrics.enableFingerprint Config.options.lock.biometrics.autoStartFingerprint"
    },
    {
        "id": "InterfaceConfig.animate-biometric-sensor",
        "source": "InterfaceConfig",
        "route": "session-details",
        "routes": [
            "session-details"
        ],
        "label": "Animate biometric sensor",
        "section": "Biometrics",
        "legacyPage": "Interface",
        "legacySections": [
            "Lock screen",
            "Biometrics"
        ],
        "keywords": "Config.options.lock.biometrics.showSensorAnimation"
    },
    {
        "id": "InterfaceConfig.enable-face-id-ir-camera-authentication",
        "source": "InterfaceConfig",
        "route": "session",
        "routes": [
            "session"
        ],
        "label": "Enable Face ID / IR camera authentication",
        "section": "Biometrics",
        "legacyPage": "Interface",
        "legacySections": [
            "Lock screen",
            "Biometrics"
        ],
        "keywords": "Config.options.lock.biometrics.enableFaceAuth"
    },
    {
        "id": "InterfaceConfig.start-face-id-scan-when-locked",
        "source": "InterfaceConfig",
        "route": "session-details",
        "routes": [
            "session-details"
        ],
        "label": "Start Face ID scan when locked",
        "section": "Biometrics",
        "legacyPage": "Interface",
        "legacySections": [
            "Lock screen",
            "Biometrics"
        ],
        "keywords": "Config.options.lock.biometrics.enableFaceAuth Config.options.lock.biometrics.autoStartFaceAuth"
    },
    {
        "id": "InterfaceConfig.face-scan-timeout-seconds",
        "source": "InterfaceConfig",
        "route": "session-details",
        "routes": [
            "session-details"
        ],
        "label": "Face scan timeout (seconds)",
        "section": "Biometrics",
        "legacyPage": "Interface",
        "legacySections": [
            "Lock screen",
            "Biometrics"
        ],
        "keywords": "Config.options.lock.biometrics.enableFaceAuth Config.options.lock.biometrics.faceTimeoutSeconds"
    },
    {
        "id": "InterfaceConfig.face-authentication-command",
        "source": "InterfaceConfig",
        "route": "session-details",
        "routes": [
            "session-details"
        ],
        "label": "Face authentication command",
        "section": "Biometrics",
        "legacyPage": "Interface",
        "legacySections": [
            "Lock screen",
            "Biometrics"
        ],
        "keywords": "Config.options.lock.biometrics.enableFaceAuth Config.options.lock.biometrics.faceCommand"
    },
    {
        "id": "InterfaceConfig.center-clock",
        "source": "InterfaceConfig",
        "route": "session",
        "routes": [
            "session"
        ],
        "label": "Center clock",
        "section": "Layout",
        "legacyPage": "Interface",
        "legacySections": [
            "Lock screen",
            "Style: General"
        ],
        "keywords": "Config.options.lock.centerClock"
    },
    {
        "id": "InterfaceConfig.show-locked-text",
        "source": "InterfaceConfig",
        "route": "session",
        "routes": [
            "session"
        ],
        "label": "Show \"Locked\" text",
        "section": "Layout",
        "legacyPage": "Interface",
        "legacySections": [
            "Lock screen",
            "Style: General"
        ],
        "keywords": "Config.options.lock.showLockedText"
    },
    {
        "id": "InterfaceConfig.use-varying-shapes-for-password-characters",
        "source": "InterfaceConfig",
        "route": "session-details",
        "routes": [
            "session-details"
        ],
        "label": "Use varying shapes for password characters",
        "section": "Layout",
        "legacyPage": "Interface",
        "legacySections": [
            "Lock screen",
            "Style: General"
        ],
        "keywords": "Config.options.lock.materialShapeChars"
    },
    {
        "id": "InterfaceConfig.password-controls-position",
        "source": "InterfaceConfig",
        "route": "session-details",
        "routes": [
            "session-details"
        ],
        "label": "Password controls position",
        "section": "Password and sensor position",
        "legacyPage": "Interface",
        "legacySections": [
            "Lock screen",
            "Password and sensor position"
        ],
        "keywords": "Config.options.lock.layout.passwordPlacement"
    },
    {
        "id": "InterfaceConfig.bottom-margin",
        "source": "InterfaceConfig",
        "route": "session-details",
        "routes": [
            "session-details"
        ],
        "label": "Bottom margin",
        "section": "Password and sensor position",
        "legacyPage": "Interface",
        "legacySections": [
            "Lock screen",
            "Password and sensor position"
        ],
        "keywords": "Config.options.lock.layout.passwordPlacement Config.options.lock.layout.bottomMargin"
    },
    {
        "id": "InterfaceConfig.element-positions",
        "source": "InterfaceConfig",
        "route": "session-details",
        "routes": [
            "session-details"
        ],
        "label": "Element positions",
        "section": "Element positions",
        "legacyPage": "Interface",
        "legacySections": [
            "Lock screen",
            "Element positions"
        ],
        "keywords": ""
    },
    {
        "id": "InterfaceConfig.element-positions-2",
        "source": "InterfaceConfig",
        "route": "session-details",
        "routes": [
            "session-details"
        ],
        "label": "Element positions",
        "section": "Element positions",
        "legacyPage": "Interface",
        "legacySections": [
            "Lock screen",
            "Element positions"
        ],
        "keywords": "Config.options.lock.showLeftToolbar"
    },
    {
        "id": "InterfaceConfig.element-positions-3",
        "source": "InterfaceConfig",
        "route": "session-details",
        "routes": [
            "session-details"
        ],
        "label": "Element positions",
        "section": "Element positions",
        "legacyPage": "Interface",
        "legacySections": [
            "Lock screen",
            "Element positions"
        ],
        "keywords": "Config.options.lock.showRightToolbar"
    },
    {
        "id": "InterfaceConfig.enable-blur",
        "source": "InterfaceConfig",
        "route": "session-details",
        "routes": [
            "session-details"
        ],
        "label": "Enable blur",
        "section": "Background blur",
        "legacyPage": "Interface",
        "legacySections": [
            "Lock screen",
            "Style: Blurred"
        ],
        "keywords": "Config.options.lock.blur.enable"
    },
    {
        "id": "InterfaceConfig.samples",
        "source": "InterfaceConfig",
        "route": "session-details",
        "routes": [
            "session-details"
        ],
        "label": "Samples",
        "section": "Background blur",
        "legacyPage": "Interface",
        "legacySections": [
            "Lock screen",
            "Style: Blurred"
        ],
        "keywords": "Config.options.lock.blur.size"
    },
    {
        "id": "InterfaceConfig.extra-wallpaper-zoom",
        "source": "InterfaceConfig",
        "route": "session-details",
        "routes": [
            "session-details"
        ],
        "label": "Extra wallpaper zoom (%)",
        "section": "Background blur",
        "legacyPage": "Interface",
        "legacySections": [
            "Lock screen",
            "Style: Blurred"
        ],
        "keywords": "Config.options.lock.blur.extraZoom"
    },
    {
        "id": "InterfaceConfig.show-app-launch-indicator",
        "source": "InterfaceConfig",
        "route": "capture-details",
        "routes": [
            "capture-details"
        ],
        "label": "Show app launch indicator",
        "section": "Overlay",
        "legacyPage": "Interface",
        "legacySections": [
            "Overlay"
        ],
        "keywords": "Config.options.appLaunch.showIndicator"
    },
    {
        "id": "InterfaceConfig.keep-indicator-above-windows",
        "source": "InterfaceConfig",
        "route": "capture-details",
        "routes": [
            "capture-details"
        ],
        "label": "Keep indicator above windows",
        "section": "Overlay",
        "legacyPage": "Interface",
        "legacySections": [
            "Overlay"
        ],
        "keywords": "Config.options.appLaunch.aboveWindows"
    },
    {
        "id": "InterfaceConfig.launch-indicator-timeout-ms",
        "source": "InterfaceConfig",
        "route": "capture-details",
        "routes": [
            "capture-details"
        ],
        "label": "Launch indicator timeout (ms)",
        "section": "Overlay",
        "legacyPage": "Interface",
        "legacySections": [
            "Overlay"
        ],
        "keywords": "Config.options.appLaunch.timeout"
    },
    {
        "id": "InterfaceConfig.track-file-manager-launches",
        "source": "InterfaceConfig",
        "route": "capture-details",
        "routes": [
            "capture-details"
        ],
        "label": "Show indicator for apps opened by file managers",
        "section": "Overlay",
        "legacyPage": "Interface",
        "legacySections": [
            "Overlay"
        ],
        "keywords": "Config.options.appLaunch.trackExternal file manager dolphin thunar indicator"
    },
    {
        "id": "InterfaceConfig.enable-opening-zoom-animation",
        "source": "InterfaceConfig",
        "route": "capture-details",
        "routes": [
            "capture-details"
        ],
        "label": "Enable opening zoom animation",
        "section": "Overlay",
        "legacyPage": "Interface",
        "legacySections": [
            "Overlay"
        ],
        "keywords": "Config.options.overlay.openingZoomAnimation"
    },
    {
        "id": "InterfaceConfig.darken-screen",
        "source": "InterfaceConfig",
        "route": "capture-details",
        "routes": [
            "capture-details"
        ],
        "label": "Darken screen",
        "section": "Overlay",
        "legacyPage": "Interface",
        "legacySections": [
            "Overlay"
        ],
        "keywords": "Config.options.overlay.darkenScreen"
    },
    {
        "id": "InterfaceConfig.image-source",
        "source": "InterfaceConfig",
        "route": "capture-details",
        "routes": [
            "capture-details"
        ],
        "label": "Image source",
        "section": "Floating Image",
        "legacyPage": "Interface",
        "legacySections": [
            "Overlay",
            "Floating Image"
        ],
        "keywords": "Config.options.overlay.floatingImage.imageSource"
    },
    {
        "id": "InterfaceConfig.crosshair-code",
        "source": "InterfaceConfig",
        "route": "capture-details",
        "routes": [
            "capture-details"
        ],
        "label": "Crosshair code",
        "section": "Crosshair",
        "legacyPage": "Interface",
        "legacySections": [
            "Overlay",
            "Crosshair"
        ],
        "keywords": "Config.options.crosshair.code"
    },
    {
        "id": "InterfaceConfig.open-editor",
        "source": "InterfaceConfig",
        "route": "capture-details",
        "routes": [
            "capture-details"
        ],
        "label": "Open editor",
        "section": "Crosshair",
        "legacyPage": "Interface",
        "legacySections": [
            "Overlay",
            "Crosshair"
        ],
        "keywords": "Config.options.crosshair.code"
    },
    {
        "id": "InterfaceConfig.windows",
        "source": "InterfaceConfig",
        "route": "capture-details",
        "routes": [
            "capture-details"
        ],
        "label": "Windows",
        "section": "Hint target regions",
        "legacyPage": "Interface",
        "legacySections": [
            "Region selector (screen snipping/Google Lens)",
            "Hint target regions"
        ],
        "keywords": "Config.options.regionSelector.targetRegions.windows"
    },
    {
        "id": "InterfaceConfig.layers",
        "source": "InterfaceConfig",
        "route": "capture-details",
        "routes": [
            "capture-details"
        ],
        "label": "Layers",
        "section": "Hint target regions",
        "legacyPage": "Interface",
        "legacySections": [
            "Region selector (screen snipping/Google Lens)",
            "Hint target regions"
        ],
        "keywords": "Config.options.regionSelector.targetRegions.layers"
    },
    {
        "id": "InterfaceConfig.content-2",
        "source": "InterfaceConfig",
        "route": "capture-details",
        "routes": [
            "capture-details"
        ],
        "label": "Content",
        "section": "Hint target regions",
        "legacyPage": "Interface",
        "legacySections": [
            "Region selector (screen snipping/Google Lens)",
            "Hint target regions"
        ],
        "keywords": "Config.options.regionSelector.targetRegions.content"
    },
    {
        "id": "InterfaceConfig.selection-type",
        "source": "InterfaceConfig",
        "route": "capture-details",
        "routes": [
            "capture-details"
        ],
        "label": "Selection Type",
        "section": "Google Lens",
        "legacyPage": "Interface",
        "legacySections": [
            "Region selector (screen snipping/Google Lens)",
            "Google Lens"
        ],
        "keywords": "Config.options.search.imageSearch.useCircleSelection"
    },
    {
        "id": "InterfaceConfig.show-aim-lines",
        "source": "InterfaceConfig",
        "route": "capture-details",
        "routes": [
            "capture-details"
        ],
        "label": "Show aim lines",
        "section": "Rectangular selection",
        "legacyPage": "Interface",
        "legacySections": [
            "Region selector (screen snipping/Google Lens)",
            "Rectangular selection"
        ],
        "keywords": "Config.options.regionSelector.rect.showAimLines"
    },
    {
        "id": "InterfaceConfig.stroke-width",
        "source": "InterfaceConfig",
        "route": "capture-details",
        "routes": [
            "capture-details"
        ],
        "label": "Stroke width",
        "section": "Circle selection",
        "legacyPage": "Interface",
        "legacySections": [
            "Region selector (screen snipping/Google Lens)",
            "Circle selection"
        ],
        "keywords": "Config.options.regionSelector.circle.strokeWidth"
    },
    {
        "id": "InterfaceConfig.padding",
        "source": "InterfaceConfig",
        "route": "capture-details",
        "routes": [
            "capture-details"
        ],
        "label": "Padding",
        "section": "Circle selection",
        "legacyPage": "Interface",
        "legacySections": [
            "Region selector (screen snipping/Google Lens)",
            "Circle selection"
        ],
        "keywords": "Config.options.regionSelector.circle.padding"
    },
    {
        "id": "InterfaceConfig.timeout-ms",
        "source": "InterfaceConfig",
        "route": "notification-rules",
        "routes": [
            "notification-rules"
        ],
        "label": "Timeout (ms)",
        "section": "On-screen display",
        "legacyPage": "Interface",
        "legacySections": [
            "On-screen display"
        ],
        "keywords": "Config.options.osd.timeout"
    },
    {
        "id": "InterfaceConfig.attach-to-the-m3-island",
        "source": "InterfaceConfig",
        "route": "panel-details",
        "routes": [
            "panel-details"
        ],
        "label": "Attach to the M3 island",
        "section": "Wallpaper selector",
        "legacyPage": "Interface",
        "legacySections": [
            "Wallpaper selector"
        ],
        "keywords": "Config.options.bar.barMode Config.options.wallpaperSelector.dockToIsland"
    },
    {
        "id": "InterfaceConfig.use-system-file-picker",
        "source": "InterfaceConfig",
        "route": "panel-details",
        "routes": [
            "panel-details"
        ],
        "label": "Use system file picker",
        "section": "Wallpaper selector",
        "legacyPage": "Interface",
        "legacySections": [
            "Wallpaper selector"
        ],
        "keywords": "Config.options.wallpaperSelector.useSystemFileDialog"
    },
    {
        "id": "InterfaceConfig.show-home-directory-in-quick-access",
        "source": "InterfaceConfig",
        "route": "panel-details",
        "routes": [
            "panel-details"
        ],
        "label": "Show home directory in quick access",
        "section": "Wallpaper selector",
        "legacyPage": "Interface",
        "legacySections": [
            "Wallpaper selector"
        ],
        "keywords": "Config.options.wallpaperSelector.showHomePath"
    },
    {
        "id": "InterfaceConfig.close-after-selection",
        "source": "InterfaceConfig",
        "route": "panel-details",
        "routes": [
            "panel-details"
        ],
        "label": "Close after selection",
        "section": "Wallpaper selector",
        "legacyPage": "Interface",
        "legacySections": [
            "Wallpaper selector"
        ],
        "keywords": "Config.options.wallpaperSelector.closeAfterSelection"
    },
    {
        "id": "InterfaceConfig.show-blur-background",
        "source": "InterfaceConfig",
        "route": "panel-details",
        "routes": [
            "panel-details"
        ],
        "label": "Show blur background",
        "section": "Wallpaper selector",
        "legacyPage": "Interface",
        "legacySections": [
            "Wallpaper selector"
        ],
        "keywords": "Config.options.wallpaperSelector.showBlurBackground"
    },
    {
        "id": "InterfaceConfig.columns-in-grid-view",
        "source": "InterfaceConfig",
        "route": "panel-details",
        "routes": [
            "panel-details"
        ],
        "label": "Columns in grid view",
        "section": "Wallpaper selector",
        "legacyPage": "Interface",
        "legacySections": [
            "Wallpaper selector"
        ],
        "keywords": "Config.options.wallpaperSelector.columns"
    },
    {
        "id": "InterfaceConfig.always-show-search-bar",
        "source": "InterfaceConfig",
        "route": "panel-details",
        "routes": [
            "panel-details"
        ],
        "label": "Always show search bar",
        "section": "Wallpaper selector",
        "legacyPage": "Interface",
        "legacySections": [
            "Wallpaper selector"
        ],
        "keywords": "Config.options.wallpaperSelector.showSearchbar"
    },
    {
        "id": "InterfaceConfig.custom-wallpaper-folder",
        "source": "InterfaceConfig",
        "route": "appearance",
        "routes": [
            "appearance"
        ],
        "label": "Custom Wallpaper Folder",
        "section": "Wallpaper selector",
        "legacyPage": "Interface",
        "legacySections": [
            "Wallpaper selector"
        ],
        "keywords": "Config.options.wallpaperSelector.userPath"
    },
    {
        "id": "InterfaceConfig.live-wallpaper-folder",
        "source": "InterfaceConfig",
        "route": "appearance",
        "routes": [
            "appearance"
        ],
        "label": "Live Wallpaper Folder",
        "section": "Wallpaper selector",
        "legacyPage": "Interface",
        "legacySections": [
            "Wallpaper selector"
        ],
        "keywords": "Config.options.wallpaperSelector.liveWallpapersPath"
    },
    {
        "id": "InterfaceConfig.font-family-name-e-g-google-sans-flex",
        "source": "InterfaceConfig",
        "route": "appearance",
        "routes": [
            "appearance"
        ],
        "label": "Font family name (e.g., Google Sans Flex)",
        "section": "Fonts",
        "legacyPage": "Interface",
        "legacySections": [
            "Fonts"
        ],
        "keywords": "Config.options.appearance.fonts.main"
    },
    {
        "id": "InterfaceConfig.numbers-family-name",
        "source": "InterfaceConfig",
        "route": "effects",
        "routes": [
            "effects"
        ],
        "label": "Numbers family name",
        "section": "Fonts",
        "legacyPage": "Interface",
        "legacySections": [
            "Fonts"
        ],
        "keywords": "Config.options.appearance.fonts.numbers"
    },
    {
        "id": "InterfaceConfig.title-family-name",
        "source": "InterfaceConfig",
        "route": "effects",
        "routes": [
            "effects"
        ],
        "label": "Title family name",
        "section": "Fonts",
        "legacyPage": "Interface",
        "legacySections": [
            "Fonts"
        ],
        "keywords": "Config.options.appearance.fonts.title"
    },
    {
        "id": "InterfaceConfig.monospace-font-name-e-g-jetbrains-mono-nf",
        "source": "InterfaceConfig",
        "route": "effects",
        "routes": [
            "effects"
        ],
        "label": "Monospace font name (e.g., JetBrains Mono NF)",
        "section": "Fonts",
        "legacyPage": "Interface",
        "legacySections": [
            "Fonts"
        ],
        "keywords": "Config.options.appearance.fonts.monospace"
    },
    {
        "id": "InterfaceConfig.nerd-fonts-icons-e-g-jetbrains-mono-nf",
        "source": "InterfaceConfig",
        "route": "effects",
        "routes": [
            "effects"
        ],
        "label": "Nerd Fonts Icons (e.g., JetBrains Mono NF)",
        "section": "Fonts",
        "legacyPage": "Interface",
        "legacySections": [
            "Fonts"
        ],
        "keywords": "Config.options.appearance.fonts.iconNerd"
    },
    {
        "id": "InterfaceConfig.reading-font-name-e-g-readex-pro",
        "source": "InterfaceConfig",
        "route": "effects",
        "routes": [
            "effects"
        ],
        "label": "Reading font name (e.g., Readex Pro)",
        "section": "Fonts",
        "legacyPage": "Interface",
        "legacySections": [
            "Fonts"
        ],
        "keywords": "Config.options.appearance.fonts.reading"
    },
    {
        "id": "InterfaceConfig.expressive-font-name-e-g-space-grotesk",
        "source": "InterfaceConfig",
        "route": "effects",
        "routes": [
            "effects"
        ],
        "label": "Expressive font name (e.g., Space Grotesk)",
        "section": "Fonts",
        "legacyPage": "Interface",
        "legacySections": [
            "Fonts"
        ],
        "keywords": "Config.options.appearance.fonts.expressive"
    },
    {
        "id": "InterfaceConfig.shell-utilities",
        "source": "InterfaceConfig",
        "route": "effects",
        "routes": [
            "effects"
        ],
        "label": "Shell & utilities",
        "section": "Color generation",
        "legacyPage": "Interface",
        "legacySections": [
            "Color generation"
        ],
        "keywords": "Config.options.appearance.wallpaperTheming.enableAppsAndShell"
    },
    {
        "id": "InterfaceConfig.qt-apps",
        "source": "InterfaceConfig",
        "route": "effects",
        "routes": [
            "effects"
        ],
        "label": "Qt apps",
        "section": "Color generation",
        "legacyPage": "Interface",
        "legacySections": [
            "Color generation"
        ],
        "keywords": "Config.options.appearance.wallpaperTheming.enableQtApps"
    },
    {
        "id": "InterfaceConfig.terminal",
        "source": "InterfaceConfig",
        "route": "effects",
        "routes": [
            "effects"
        ],
        "label": "Terminal",
        "section": "Color generation",
        "legacyPage": "Interface",
        "legacySections": [
            "Color generation"
        ],
        "keywords": "Config.options.appearance.wallpaperTheming.enableTerminal"
    },
    {
        "id": "InterfaceConfig.force-dark-mode-in-terminal",
        "source": "InterfaceConfig",
        "route": "effects",
        "routes": [
            "effects"
        ],
        "label": "Force dark mode in terminal",
        "section": "Color generation",
        "legacyPage": "Interface",
        "legacySections": [
            "Color generation"
        ],
        "keywords": "Config.options.appearance.wallpaperTheming.terminalGenerationProps.forceDarkMode"
    },
    {
        "id": "InterfaceConfig.terminal-harmony",
        "source": "InterfaceConfig",
        "route": "effects",
        "routes": [
            "effects"
        ],
        "label": "Terminal: Harmony (%)",
        "section": "Color generation",
        "legacyPage": "Interface",
        "legacySections": [
            "Color generation"
        ],
        "keywords": "Config.options.appearance.wallpaperTheming.terminalGenerationProps.harmony"
    },
    {
        "id": "InterfaceConfig.terminal-harmonize-threshold",
        "source": "InterfaceConfig",
        "route": "effects",
        "routes": [
            "effects"
        ],
        "label": "Terminal: Harmonize threshold",
        "section": "Color generation",
        "legacyPage": "Interface",
        "legacySections": [
            "Color generation"
        ],
        "keywords": "Config.options.appearance.wallpaperTheming.terminalGenerationProps.harmonizeThreshold"
    },
    {
        "id": "InterfaceConfig.terminal-foreground-boost",
        "source": "InterfaceConfig",
        "route": "effects",
        "routes": [
            "effects"
        ],
        "label": "Terminal: Foreground boost (%)",
        "section": "Color generation",
        "legacyPage": "Interface",
        "legacySections": [
            "Color generation"
        ],
        "keywords": "Config.options.appearance.wallpaperTheming.terminalGenerationProps.termFgBoost"
    },
    {
        "id": "ServicesConfig.system-prompt",
        "source": "ServicesConfig",
        "route": "integrations",
        "routes": [
            "integrations"
        ],
        "label": "System prompt",
        "section": "AI",
        "legacyPage": "Services",
        "legacySections": [
            "AI"
        ],
        "keywords": "Config.options.ai.systemPrompt"
    },
    {
        "id": "ServicesConfig.user-agent-for-services-that-require-it",
        "source": "ServicesConfig",
        "route": "integrations",
        "routes": [
            "integrations"
        ],
        "label": "User agent (for services that require it)",
        "section": "Networking",
        "legacyPage": "Services",
        "legacySections": [
            "Networking"
        ],
        "keywords": "Config.options.networking.userAgent"
    },
    {
        "id": "ServicesConfig.total-duration-timeout-s",
        "source": "ServicesConfig",
        "route": "integrations",
        "routes": [
            "integrations"
        ],
        "label": "Total duration timeout (s)",
        "section": "Music Recognition",
        "legacyPage": "Services",
        "legacySections": [
            "Music Recognition"
        ],
        "keywords": "Config.options.musicRecognition.timeout"
    },
    {
        "id": "ServicesConfig.polling-interval-s",
        "source": "ServicesConfig",
        "route": "integrations",
        "routes": [
            "integrations"
        ],
        "label": "Polling interval (s)",
        "section": "Music Recognition",
        "legacyPage": "Services",
        "legacySections": [
            "Music Recognition"
        ],
        "keywords": "Config.options.musicRecognition.interval"
    },
    {
        "id": "ServicesConfig.video-recording-path",
        "source": "ServicesConfig",
        "route": "capture",
        "routes": [
            "capture"
        ],
        "label": "Video Recording Path",
        "section": "Save paths",
        "legacyPage": "Services",
        "legacySections": [
            "Save paths"
        ],
        "keywords": "Config.options.screenRecord.savePath"
    },
    {
        "id": "ServicesConfig.screenshot-path-leave-empty-to-just-copy",
        "source": "ServicesConfig",
        "route": "capture",
        "routes": [
            "capture"
        ],
        "label": "Screenshot Path (leave empty to just copy)",
        "section": "Save paths",
        "legacyPage": "Services",
        "legacySections": [
            "Save paths"
        ],
        "keywords": "Config.options.screenSnip.savePath"
    },
    {
        "id": "ServicesConfig.image-scale",
        "source": "ServicesConfig",
        "route": "capture-details",
        "routes": [
            "capture-details"
        ],
        "label": "Image scale (%)",
        "section": "Screenshots",
        "legacyPage": "Services",
        "legacySections": [
            "Capture quality",
            "Screenshots"
        ],
        "keywords": "Config.options.screenSnip.scalePercent"
    },
    {
        "id": "ServicesConfig.screenshot-format",
        "source": "ServicesConfig",
        "route": "capture-details",
        "routes": [
            "capture-details"
        ],
        "label": "Screenshot format",
        "section": "Screenshots",
        "legacyPage": "Services",
        "legacySections": [
            "Capture quality",
            "Screenshots"
        ],
        "keywords": "Config.options.screenSnip.format"
    },
    {
        "id": "ServicesConfig.jpeg-quality",
        "source": "ServicesConfig",
        "route": "capture-details",
        "routes": [
            "capture-details"
        ],
        "label": "JPEG quality",
        "section": "Screenshots",
        "legacyPage": "Services",
        "legacySections": [
            "Capture quality",
            "Screenshots"
        ],
        "keywords": "Config.options.screenSnip.format Config.options.screenSnip.jpegQuality"
    },
    {
        "id": "ServicesConfig.frame-rate",
        "source": "ServicesConfig",
        "route": "capture-details",
        "routes": [
            "capture-details"
        ],
        "label": "Frame rate",
        "section": "Screen recording",
        "legacyPage": "Services",
        "legacySections": [
            "Capture quality",
            "Screen recording"
        ],
        "keywords": "Config.options.screenRecord.frameRate"
    },
    {
        "id": "ServicesConfig.recording-quality",
        "source": "ServicesConfig",
        "route": "capture-details",
        "routes": [
            "capture-details"
        ],
        "label": "Recording quality",
        "section": "Screen recording",
        "legacyPage": "Services",
        "legacySections": [
            "Capture quality",
            "Screen recording"
        ],
        "keywords": "Config.options.screenRecord.quality"
    },
    {
        "id": "ServicesConfig.audio-capture",
        "source": "ServicesConfig",
        "route": "capture",
        "routes": [
            "capture"
        ],
        "label": "Audio capture",
        "section": "Screen recording",
        "legacyPage": "Services",
        "legacySections": [
            "Capture quality",
            "Screen recording"
        ],
        "keywords": "Config.options.screenRecord.audioMode"
    },
    {
        "id": "ServicesConfig.output-source-override",
        "source": "ServicesConfig",
        "route": "capture-details",
        "routes": [
            "capture-details"
        ],
        "label": "Output source override",
        "section": "Screen recording",
        "legacyPage": "Services",
        "legacySections": [
            "Capture quality",
            "Screen recording"
        ],
        "keywords": "Config.options.screenRecord.outputSource"
    },
    {
        "id": "ServicesConfig.microphone-source-override",
        "source": "ServicesConfig",
        "route": "capture-details",
        "routes": [
            "capture-details"
        ],
        "label": "Microphone source override",
        "section": "Screen recording",
        "legacyPage": "Services",
        "legacySections": [
            "Capture quality",
            "Screen recording"
        ],
        "keywords": "Config.options.screenRecord.microphoneSource"
    },
    {
        "id": "ServicesConfig.launcher",
        "source": "ServicesConfig",
        "route": "apps",
        "routes": [
            "apps"
        ],
        "label": "Launcher",
        "section": "Search",
        "legacyPage": "Services",
        "legacySections": [
            "Search"
        ],
        "keywords": "Config.options.apps.launcher"
    },
    {
        "id": "ServicesConfig.use-levenshtein-distance-based-algorithm-instead-of-fuzzy",
        "source": "ServicesConfig",
        "route": "integrations",
        "routes": [
            "integrations"
        ],
        "label": "Use Levenshtein distance-based algorithm instead of fuzzy",
        "section": "Search",
        "legacyPage": "Services",
        "legacySections": [
            "Search"
        ],
        "keywords": "Config.options.search.sloppy"
    },
    {
        "id": "ServicesConfig.action",
        "source": "ServicesConfig",
        "route": "integrations",
        "routes": [
            "integrations"
        ],
        "label": "Action",
        "section": "Prefixes",
        "legacyPage": "Services",
        "legacySections": [
            "Search",
            "Prefixes"
        ],
        "keywords": "Config.options.search.prefix.action"
    },
    {
        "id": "ServicesConfig.clipboard",
        "source": "ServicesConfig",
        "route": "integrations",
        "routes": [
            "integrations"
        ],
        "label": "Clipboard",
        "section": "Prefixes",
        "legacyPage": "Services",
        "legacySections": [
            "Search",
            "Prefixes"
        ],
        "keywords": "Config.options.search.prefix.clipboard"
    },
    {
        "id": "ServicesConfig.emojis",
        "source": "ServicesConfig",
        "route": "integrations",
        "routes": [
            "integrations"
        ],
        "label": "Emojis",
        "section": "Prefixes",
        "legacyPage": "Services",
        "legacySections": [
            "Search",
            "Prefixes"
        ],
        "keywords": "Config.options.search.prefix.emojis"
    },
    {
        "id": "ServicesConfig.icons",
        "source": "ServicesConfig",
        "route": "integrations",
        "routes": [
            "integrations"
        ],
        "label": "Icons",
        "section": "Prefixes",
        "legacyPage": "Services",
        "legacySections": [
            "Search",
            "Prefixes"
        ],
        "keywords": "Config.options.search.prefix.symbols"
    },
    {
        "id": "ServicesConfig.shell-command",
        "source": "ServicesConfig",
        "route": "integrations",
        "routes": [
            "integrations"
        ],
        "label": "Shell command",
        "section": "Prefixes",
        "legacyPage": "Services",
        "legacySections": [
            "Search",
            "Prefixes"
        ],
        "keywords": "Config.options.search.prefix.shellCommand"
    },
    {
        "id": "ServicesConfig.web-search",
        "source": "ServicesConfig",
        "route": "integrations",
        "routes": [
            "integrations"
        ],
        "label": "Web search",
        "section": "Prefixes",
        "legacyPage": "Services",
        "legacySections": [
            "Search",
            "Prefixes"
        ],
        "keywords": "Config.options.search.prefix.webSearch"
    },
    {
        "id": "ServicesConfig.apps",
        "source": "ServicesConfig",
        "route": "integrations",
        "routes": [
            "integrations"
        ],
        "label": "Apps",
        "section": "Prefixes",
        "legacyPage": "Services",
        "legacySections": [
            "Search",
            "Prefixes"
        ],
        "keywords": "Config.options.search.prefix.app"
    },
    {
        "id": "ServicesConfig.keybinds",
        "source": "ServicesConfig",
        "route": "integrations",
        "routes": [
            "integrations"
        ],
        "label": "Keybinds",
        "section": "Prefixes",
        "legacyPage": "Services",
        "legacySections": [
            "Search",
            "Prefixes"
        ],
        "keywords": "Config.options.search.prefix.keybinds"
    },
    {
        "id": "ServicesConfig.files",
        "source": "ServicesConfig",
        "route": "integrations",
        "routes": [
            "integrations"
        ],
        "label": "Files",
        "section": "Prefixes",
        "legacyPage": "Services",
        "legacySections": [
            "Search",
            "Prefixes"
        ],
        "keywords": "Config.options.search.prefix.files"
    },
    {
        "id": "ServicesConfig.ssh-hosts",
        "source": "ServicesConfig",
        "route": "integrations",
        "routes": [
            "integrations"
        ],
        "label": "SSH hosts",
        "section": "Prefixes",
        "legacyPage": "Services",
        "legacySections": [
            "Search",
            "Prefixes"
        ],
        "keywords": "Config.options.search.prefix.sshHosts"
    },
    {
        "id": "ServicesConfig.system-services",
        "source": "ServicesConfig",
        "route": "integrations",
        "routes": [
            "integrations"
        ],
        "label": "System services",
        "section": "Prefixes",
        "legacyPage": "Services",
        "legacySections": [
            "Search",
            "Prefixes"
        ],
        "keywords": "Config.options.search.prefix.systemServices"
    },
    {
        "id": "ServicesConfig.show-actions-without-typing-their-prefix",
        "source": "ServicesConfig",
        "route": "integrations",
        "routes": [
            "integrations"
        ],
        "label": "Show actions without typing their prefix",
        "section": "Prefixes",
        "legacyPage": "Services",
        "legacySections": [
            "Search",
            "Prefixes"
        ],
        "keywords": "Config.options.search.prefix.showActionsWithoutPrefix"
    },
    {
        "id": "ServicesConfig.show-files-without-typing-their-prefix",
        "source": "ServicesConfig",
        "route": "integrations",
        "routes": [
            "integrations"
        ],
        "label": "Show files without typing their prefix",
        "section": "Prefixes",
        "legacyPage": "Services",
        "legacySections": [
            "Search",
            "Prefixes"
        ],
        "keywords": "Config.options.search.prefix.showFilesWithoutPrefix"
    },
    {
        "id": "ServicesConfig.minimum-characters-before-searching-files",
        "source": "ServicesConfig",
        "route": "integrations",
        "routes": [
            "integrations"
        ],
        "label": "Minimum characters before searching files",
        "section": "Prefixes",
        "legacyPage": "Services",
        "legacySections": [
            "Search",
            "Prefixes"
        ],
        "keywords": "Config.options.search.prefix.showFilesWithoutPrefix Config.options.search.prefix.filesWithoutPrefixMinLength"
    },
    {
        "id": "ServicesConfig.web-links",
        "source": "ServicesConfig",
        "route": "apps",
        "routes": [
            "apps"
        ],
        "label": "Web links",
        "section": "Default applications by file type",
        "legacyPage": "Services",
        "legacySections": [
            "Search",
            "Default applications by file type"
        ],
        "keywords": "Config.options.apps.defaultApplications.browser"
    },
    {
        "id": "ServicesConfig.folders",
        "source": "ServicesConfig",
        "route": "apps",
        "routes": [
            "apps"
        ],
        "label": "Folders",
        "section": "Default applications by file type",
        "legacyPage": "Services",
        "legacySections": [
            "Search",
            "Default applications by file type"
        ],
        "keywords": "Config.options.apps.defaultApplications.folders"
    },
    {
        "id": "ServicesConfig.documents-and-text",
        "source": "ServicesConfig",
        "route": "apps",
        "routes": [
            "apps"
        ],
        "label": "Documents and text",
        "section": "Default applications by file type",
        "legacyPage": "Services",
        "legacySections": [
            "Search",
            "Default applications by file type"
        ],
        "keywords": "Config.options.apps.defaultApplications.documents"
    },
    {
        "id": "ServicesConfig.images",
        "source": "ServicesConfig",
        "route": "apps",
        "routes": [
            "apps"
        ],
        "label": "Images",
        "section": "Default applications by file type",
        "legacyPage": "Services",
        "legacySections": [
            "Search",
            "Default applications by file type"
        ],
        "keywords": "Config.options.apps.defaultApplications.images"
    },
    {
        "id": "ServicesConfig.audio",
        "source": "ServicesConfig",
        "route": "apps",
        "routes": [
            "apps"
        ],
        "label": "Audio",
        "section": "Default applications by file type",
        "legacyPage": "Services",
        "legacySections": [
            "Search",
            "Default applications by file type"
        ],
        "keywords": "Config.options.apps.defaultApplications.audio"
    },
    {
        "id": "ServicesConfig.video",
        "source": "ServicesConfig",
        "route": "apps",
        "routes": [
            "apps"
        ],
        "label": "Video",
        "section": "Default applications by file type",
        "legacyPage": "Services",
        "legacySections": [
            "Search",
            "Default applications by file type"
        ],
        "keywords": "Config.options.apps.defaultApplications.video"
    },
    {
        "id": "ServicesConfig.archives",
        "source": "ServicesConfig",
        "route": "apps",
        "routes": [
            "apps"
        ],
        "label": "Archives",
        "section": "Default applications by file type",
        "legacyPage": "Services",
        "legacySections": [
            "Search",
            "Default applications by file type"
        ],
        "keywords": "Config.options.apps.defaultApplications.archives"
    },
    {
        "id": "ServicesConfig.open-files-with",
        "source": "ServicesConfig",
        "route": "integrations",
        "routes": [
            "integrations"
        ],
        "label": "Open files with",
        "section": "Files, SSH & services",
        "legacyPage": "Services",
        "legacySections": [
            "Search",
            "Files, SSH & services"
        ],
        "keywords": "Config.options.apps.fileOpener"
    },
    {
        "id": "ServicesConfig.enable-file-search",
        "source": "ServicesConfig",
        "route": "apps",
        "routes": [
            "apps"
        ],
        "label": "Enable file search",
        "section": "Files, SSH & services",
        "legacyPage": "Services",
        "legacySections": [
            "Search",
            "Files, SSH & services"
        ],
        "keywords": "Config.options.search.extras.filesEnable"
    },
    {
        "id": "ServicesConfig.max-file-results",
        "source": "ServicesConfig",
        "route": "integrations",
        "routes": [
            "integrations"
        ],
        "label": "Max file results",
        "section": "Files, SSH & services",
        "legacyPage": "Services",
        "legacySections": [
            "Search",
            "Files, SSH & services"
        ],
        "keywords": "Config.options.search.extras.filesMaxResults Config.options.search.extras.filesEnable"
    },
    {
        "id": "ServicesConfig.enable-ssh-quick-connect",
        "source": "ServicesConfig",
        "route": "apps",
        "routes": [
            "apps"
        ],
        "label": "Enable SSH quick-connect",
        "section": "Files, SSH & services",
        "legacyPage": "Services",
        "legacySections": [
            "Search",
            "Files, SSH & services"
        ],
        "keywords": "Config.options.search.extras.sshHostsEnable"
    },
    {
        "id": "ServicesConfig.enable-systemd-service-search",
        "source": "ServicesConfig",
        "route": "apps",
        "routes": [
            "apps"
        ],
        "label": "Enable systemd service search",
        "section": "Files, SSH & services",
        "legacyPage": "Services",
        "legacySections": [
            "Search",
            "Files, SSH & services"
        ],
        "keywords": "Config.options.search.extras.systemServicesEnable"
    },
    {
        "id": "ServicesConfig.max-service-results",
        "source": "ServicesConfig",
        "route": "integrations",
        "routes": [
            "integrations"
        ],
        "label": "Max service results",
        "section": "Files, SSH & services",
        "legacyPage": "Services",
        "legacySections": [
            "Search",
            "Files, SSH & services"
        ],
        "keywords": "Config.options.search.extras.systemServicesMaxResults Config.options.search.extras.systemServicesEnable"
    },
    {
        "id": "ServicesConfig.include-system-wide-services-needs-pkexec-to-control",
        "source": "ServicesConfig",
        "route": "apps",
        "routes": [
            "apps"
        ],
        "label": "Include system-wide services (needs pkexec to control)",
        "section": "Files, SSH & services",
        "legacyPage": "Services",
        "legacySections": [
            "Search",
            "Files, SSH & services"
        ],
        "keywords": "Config.options.search.extras.systemServicesIncludeSystemScope Config.options.search.extras.systemServicesEnable"
    },
    {
        "id": "ServicesConfig.base-url",
        "source": "ServicesConfig",
        "route": "integrations",
        "routes": [
            "integrations"
        ],
        "label": "Base URL",
        "section": "Web search",
        "legacyPage": "Services",
        "legacySections": [
            "Search",
            "Web search"
        ],
        "keywords": "Config.options.search.engineBaseUrl"
    },
    {
        "id": "ServicesConfig.enable-update-checks",
        "source": "ServicesConfig",
        "route": "about",
        "routes": [
            "about"
        ],
        "label": "Enable update checks",
        "section": "System updates (Arch only)",
        "legacyPage": "Services",
        "legacySections": [
            "System updates (Arch only)"
        ],
        "keywords": "Config.options.updates.enableCheck"
    },
    {
        "id": "ServicesConfig.check-interval-mins",
        "source": "ServicesConfig",
        "route": "system",
        "routes": [
            "system"
        ],
        "label": "Check interval (mins)",
        "section": "System updates (Arch only)",
        "legacyPage": "Services",
        "legacySections": [
            "System updates (Arch only)"
        ],
        "keywords": "Config.options.updates.checkInterval"
    },
    {
        "id": "ServicesConfig.enable-gps-based-location",
        "source": "ServicesConfig",
        "route": "apps",
        "routes": [
            "apps"
        ],
        "label": "Enable GPS based location",
        "section": "Weather",
        "legacyPage": "Services",
        "legacySections": [
            "Weather"
        ],
        "keywords": "Config.options.bar.weather.enableGPS"
    },
    {
        "id": "ServicesConfig.fahrenheit-unit",
        "source": "ServicesConfig",
        "route": "apps",
        "routes": [
            "apps"
        ],
        "label": "Fahrenheit unit",
        "section": "Weather",
        "legacyPage": "Services",
        "legacySections": [
            "Weather"
        ],
        "keywords": "Config.options.bar.weather.useUSCS"
    },
    {
        "id": "ServicesConfig.polling-interval-m",
        "source": "ServicesConfig",
        "route": "integrations",
        "routes": [
            "integrations"
        ],
        "label": "Polling interval (m)",
        "section": "Weather",
        "legacyPage": "Services",
        "legacySections": [
            "Weather"
        ],
        "keywords": "Config.options.bar.weather.fetchInterval"
    },
    {
        "id": "ServicesConfig.city-name",
        "source": "ServicesConfig",
        "route": "apps",
        "routes": [
            "apps"
        ],
        "label": "City name",
        "section": "Weather",
        "legacyPage": "Services",
        "legacySections": [
            "Weather"
        ],
        "keywords": "Config.options.bar.weather.city"
    },
    {
        "id": "ServicesConfig.weather-map",
        "source": "ServicesConfig",
        "route": "apps",
        "routes": [
            "apps"
        ],
        "label": "Weather map",
        "section": "Weather map",
        "legacyPage": "Services",
        "legacySections": [],
        "keywords": ""
    },
    {
        "id": "HyprlandSettings.arrange-displays",
        "source": "HyprlandSettings",
        "route": "devices",
        "routes": [
            "devices"
        ],
        "label": "Arrange displays",
        "section": "Displays",
        "legacyPage": "Hyprland",
        "legacySections": [
            "Displays"
        ],
        "keywords": ""
    },
    {
        "id": "HyprlandSettings.enabled",
        "source": "HyprlandSettings",
        "route": "devices",
        "routes": [
            "devices"
        ],
        "label": "Enabled",
        "section": "",
        "legacyPage": "Hyprland",
        "legacySections": [
            "Displays",
            ""
        ],
        "keywords": ""
    },
    {
        "id": "HyprlandSettings.orientation",
        "source": "HyprlandSettings",
        "route": "devices",
        "routes": [
            "devices"
        ],
        "label": "Orientation",
        "section": "",
        "legacyPage": "Hyprland",
        "legacySections": [
            "Displays",
            ""
        ],
        "keywords": ""
    },
    {
        "id": "HyprlandSettings.scale",
        "source": "HyprlandSettings",
        "route": "devices",
        "routes": [
            "devices"
        ],
        "label": "Scale",
        "section": "",
        "legacyPage": "Hyprland",
        "legacySections": [
            "Displays",
            ""
        ],
        "keywords": ""
    },
    {
        "id": "HyprlandSettings.position-x",
        "source": "HyprlandSettings",
        "route": "window-rules",
        "routes": [
            "window-rules"
        ],
        "label": "Position X",
        "section": "",
        "legacyPage": "Hyprland",
        "legacySections": [
            "Displays",
            ""
        ],
        "keywords": ""
    },
    {
        "id": "HyprlandSettings.position-y",
        "source": "HyprlandSettings",
        "route": "window-rules",
        "routes": [
            "window-rules"
        ],
        "label": "Position Y",
        "section": "",
        "legacyPage": "Hyprland",
        "legacySections": [
            "Displays",
            ""
        ],
        "keywords": ""
    },
    {
        "id": "HyprlandSettings.bit-depth",
        "source": "HyprlandSettings",
        "route": "window-rules",
        "routes": [
            "window-rules"
        ],
        "label": "Bit Depth",
        "section": "Advanced Monitor Settings",
        "legacyPage": "Hyprland",
        "legacySections": [
            "Displays",
            "",
            "Advanced Monitor Settings"
        ],
        "keywords": ""
    },
    {
        "id": "HyprlandSettings.vrr",
        "source": "HyprlandSettings",
        "route": "window-rules",
        "routes": [
            "window-rules"
        ],
        "label": "VRR",
        "section": "Advanced Monitor Settings",
        "legacyPage": "Hyprland",
        "legacySections": [
            "Displays",
            "",
            "Advanced Monitor Settings"
        ],
        "keywords": ""
    },
    {
        "id": "HyprlandSettings.reserved-area",
        "source": "HyprlandSettings",
        "route": "window-rules",
        "routes": [
            "window-rules"
        ],
        "label": "Reserved Area",
        "section": "Advanced Monitor Settings",
        "legacyPage": "Hyprland",
        "legacySections": [
            "Displays",
            "",
            "Advanced Monitor Settings"
        ],
        "keywords": ""
    },
    {
        "id": "HyprlandSettings.transform",
        "source": "HyprlandSettings",
        "route": "window-rules",
        "routes": [
            "window-rules"
        ],
        "label": "Transform",
        "section": "Advanced Monitor Settings",
        "legacyPage": "Hyprland",
        "legacySections": [
            "Displays",
            "",
            "Advanced Monitor Settings"
        ],
        "keywords": ""
    },
    {
        "id": "HyprlandSettings.tiling-layout",
        "source": "HyprlandSettings",
        "route": "devices",
        "routes": [
            "devices"
        ],
        "label": "Tiling Layout",
        "section": "Layout",
        "legacyPage": "Hyprland",
        "legacySections": [
            "Layout"
        ],
        "keywords": "Config.options.hyprland.general.layout"
    },
    {
        "id": "HyprlandSettings.preserve-split",
        "source": "HyprlandSettings",
        "route": "window-rules",
        "routes": [
            "window-rules"
        ],
        "label": "Preserve Split",
        "section": "Dwindle",
        "legacyPage": "Hyprland",
        "legacySections": [
            "Layout",
            "Dwindle"
        ],
        "keywords": "Config.options.hyprland.dwindle.preserveSplit"
    },
    {
        "id": "HyprlandSettings.smart-split",
        "source": "HyprlandSettings",
        "route": "window-rules",
        "routes": [
            "window-rules"
        ],
        "label": "Smart Split",
        "section": "Dwindle",
        "legacyPage": "Hyprland",
        "legacySections": [
            "Layout",
            "Dwindle"
        ],
        "keywords": "Config.options.hyprland.dwindle.smartSplit"
    },
    {
        "id": "HyprlandSettings.smart-resizing",
        "source": "HyprlandSettings",
        "route": "window-rules",
        "routes": [
            "window-rules"
        ],
        "label": "Smart Resizing",
        "section": "Dwindle",
        "legacyPage": "Hyprland",
        "legacySections": [
            "Layout",
            "Dwindle"
        ],
        "keywords": "Config.options.hyprland.dwindle.smartResizing"
    },
    {
        "id": "HyprlandSettings.new-window-status",
        "source": "HyprlandSettings",
        "route": "window-rules",
        "routes": [
            "window-rules"
        ],
        "label": "New Window Status",
        "section": "Master",
        "legacyPage": "Hyprland",
        "legacySections": [
            "Layout",
            "Master"
        ],
        "keywords": "Config.options.hyprland.master.newStatus"
    },
    {
        "id": "HyprlandSettings.master-factor",
        "source": "HyprlandSettings",
        "route": "window-rules",
        "routes": [
            "window-rules"
        ],
        "label": "Master Factor",
        "section": "Master",
        "legacyPage": "Hyprland",
        "legacySections": [
            "Layout",
            "Master"
        ],
        "keywords": "Config.options.hyprland.master.mfact"
    },
    {
        "id": "HyprlandSettings.orientation-2",
        "source": "HyprlandSettings",
        "route": "window-rules",
        "routes": [
            "window-rules"
        ],
        "label": "Orientation",
        "section": "Master",
        "legacyPage": "Hyprland",
        "legacySections": [
            "Layout",
            "Master"
        ],
        "keywords": "Config.options.hyprland.master.orientation"
    },
    {
        "id": "HyprlandSettings.auto-group",
        "source": "HyprlandSettings",
        "route": "window-rules",
        "routes": [
            "window-rules"
        ],
        "label": "Auto Group",
        "section": "Group",
        "legacyPage": "Hyprland",
        "legacySections": [
            "Layout",
            "Group"
        ],
        "keywords": "Config.options.hyprland.group.autoGroup"
    },
    {
        "id": "HyprlandSettings.drag-into-group",
        "source": "HyprlandSettings",
        "route": "window-rules",
        "routes": [
            "window-rules"
        ],
        "label": "Drag Into Group",
        "section": "Group",
        "legacyPage": "Hyprland",
        "legacySections": [
            "Layout",
            "Group"
        ],
        "keywords": "Config.options.hyprland.group.dragIntoGroup"
    },
    {
        "id": "HyprlandSettings.merge-groups-on-drag",
        "source": "HyprlandSettings",
        "route": "window-rules",
        "routes": [
            "window-rules"
        ],
        "label": "Merge Groups On Drag",
        "section": "Group",
        "legacyPage": "Hyprland",
        "legacySections": [
            "Layout",
            "Group"
        ],
        "keywords": "Config.options.hyprland.group.mergeGroupsOnDrag"
    },
    {
        "id": "HyprlandSettings.group-bar-enabled",
        "source": "HyprlandSettings",
        "route": "window-rules",
        "routes": [
            "window-rules"
        ],
        "label": "Group Bar Enabled",
        "section": "Group",
        "legacyPage": "Hyprland",
        "legacySections": [
            "Layout",
            "Group"
        ],
        "keywords": "Config.options.hyprland.group.groupbar.enabled"
    },
    {
        "id": "HyprlandSettings.add",
        "source": "HyprlandSettings",
        "route": "devices",
        "routes": [
            "devices"
        ],
        "label": "Add",
        "section": "Keyboard",
        "legacyPage": "Hyprland",
        "legacySections": [
            "Input",
            "Keyboard"
        ],
        "keywords": ""
    },
    {
        "id": "HyprlandSettings.extra-xkb-options",
        "source": "HyprlandSettings",
        "route": "input-details",
        "routes": [
            "input-details"
        ],
        "label": "Extra XKB options",
        "section": "Keyboard",
        "legacyPage": "Hyprland",
        "legacySections": [
            "Input",
            "Keyboard"
        ],
        "keywords": "Config.options.hyprland.input.kbOptions"
    },
    {
        "id": "HyprlandSettings.variant-per-layout-comma-separated",
        "source": "HyprlandSettings",
        "route": "input-details",
        "routes": [
            "input-details"
        ],
        "label": "Variant (per layout, comma-separated)",
        "section": "Keyboard",
        "legacyPage": "Hyprland",
        "legacySections": [
            "Input",
            "Keyboard"
        ],
        "keywords": "Config.options.hyprland.input.kbVariant"
    },
    {
        "id": "HyprlandSettings.model",
        "source": "HyprlandSettings",
        "route": "input-details",
        "routes": [
            "input-details"
        ],
        "label": "Model",
        "section": "Keyboard",
        "legacyPage": "Hyprland",
        "legacySections": [
            "Input",
            "Keyboard"
        ],
        "keywords": "Config.options.hyprland.input.kbModel"
    },
    {
        "id": "HyprlandSettings.rules",
        "source": "HyprlandSettings",
        "route": "input-details",
        "routes": [
            "input-details"
        ],
        "label": "Rules",
        "section": "Keyboard",
        "legacyPage": "Hyprland",
        "legacySections": [
            "Input",
            "Keyboard"
        ],
        "keywords": "Config.options.hyprland.input.kbRules"
    },
    {
        "id": "HyprlandSettings.numlock-by-default",
        "source": "HyprlandSettings",
        "route": "devices",
        "routes": [
            "devices"
        ],
        "label": "Numlock by default",
        "section": "Keyboard",
        "legacyPage": "Hyprland",
        "legacySections": [
            "Input",
            "Keyboard"
        ],
        "keywords": "Config.options.hyprland.input.numlock"
    },
    {
        "id": "HyprlandSettings.repeat-delay-ms",
        "source": "HyprlandSettings",
        "route": "input-details",
        "routes": [
            "input-details"
        ],
        "label": "Repeat delay (ms)",
        "section": "Keyboard",
        "legacyPage": "Hyprland",
        "legacySections": [
            "Input",
            "Keyboard"
        ],
        "keywords": "Config.options.hyprland.input.repeatDelay"
    },
    {
        "id": "HyprlandSettings.repeat-rate",
        "source": "HyprlandSettings",
        "route": "input-details",
        "routes": [
            "input-details"
        ],
        "label": "Repeat rate",
        "section": "Keyboard",
        "legacyPage": "Hyprland",
        "legacySections": [
            "Input",
            "Keyboard"
        ],
        "keywords": "Config.options.hyprland.input.repeatRate"
    },
    {
        "id": "HyprlandSettings.follow-mouse",
        "source": "HyprlandSettings",
        "route": "input-details",
        "routes": [
            "input-details"
        ],
        "label": "Follow mouse",
        "section": "Keyboard",
        "legacyPage": "Hyprland",
        "legacySections": [
            "Input",
            "Keyboard"
        ],
        "keywords": "Config.options.hyprland.input.followMouse"
    },
    {
        "id": "HyprlandSettings.natural-scroll",
        "source": "HyprlandSettings",
        "route": "devices",
        "routes": [
            "devices"
        ],
        "label": "Natural scroll",
        "section": "Touchpad",
        "legacyPage": "Hyprland",
        "legacySections": [
            "Input",
            "Touchpad"
        ],
        "keywords": "Config.options.hyprland.input.touchpad.naturalScroll"
    },
    {
        "id": "HyprlandSettings.disable-while-typing",
        "source": "HyprlandSettings",
        "route": "devices",
        "routes": [
            "devices"
        ],
        "label": "Disable while typing",
        "section": "Touchpad",
        "legacyPage": "Hyprland",
        "legacySections": [
            "Input",
            "Touchpad"
        ],
        "keywords": "Config.options.hyprland.input.touchpad.disableWhileTyping"
    },
    {
        "id": "HyprlandSettings.clickfinger-behavior",
        "source": "HyprlandSettings",
        "route": "input-details",
        "routes": [
            "input-details"
        ],
        "label": "Clickfinger behavior",
        "section": "Touchpad",
        "legacyPage": "Hyprland",
        "legacySections": [
            "Input",
            "Touchpad"
        ],
        "keywords": "Config.options.hyprland.input.touchpad.clickfingerBehavior"
    },
    {
        "id": "HyprlandSettings.scroll-factor",
        "source": "HyprlandSettings",
        "route": "input-details",
        "routes": [
            "input-details"
        ],
        "label": "Scroll factor",
        "section": "Touchpad",
        "legacyPage": "Hyprland",
        "legacySections": [
            "Input",
            "Touchpad"
        ],
        "keywords": "Config.options.hyprland.input.touchpad.scrollFactor"
    },
    {
        "id": "HyprlandSettings.tap-to-click",
        "source": "HyprlandSettings",
        "route": "devices",
        "routes": [
            "devices"
        ],
        "label": "Tap to Click",
        "section": "Touchpad Advanced",
        "legacyPage": "Hyprland",
        "legacySections": [
            "Input",
            "Touchpad",
            "Touchpad Advanced"
        ],
        "keywords": "Config.options.hyprland.input.touchpad.tapToClick"
    },
    {
        "id": "HyprlandSettings.tap-button-map",
        "source": "HyprlandSettings",
        "route": "input-details",
        "routes": [
            "input-details"
        ],
        "label": "Tap Button Map",
        "section": "Touchpad Advanced",
        "legacyPage": "Hyprland",
        "legacySections": [
            "Input",
            "Touchpad",
            "Touchpad Advanced"
        ],
        "keywords": "Config.options.hyprland.input.touchpad.tapButtonMap"
    },
    {
        "id": "HyprlandSettings.tap-and-drag",
        "source": "HyprlandSettings",
        "route": "input-details",
        "routes": [
            "input-details"
        ],
        "label": "Tap and Drag",
        "section": "Touchpad Advanced",
        "legacyPage": "Hyprland",
        "legacySections": [
            "Input",
            "Touchpad",
            "Touchpad Advanced"
        ],
        "keywords": "Config.options.hyprland.input.touchpad.tapAndDrag"
    },
    {
        "id": "HyprlandSettings.drag-lock",
        "source": "HyprlandSettings",
        "route": "input-details",
        "routes": [
            "input-details"
        ],
        "label": "Drag Lock",
        "section": "Touchpad Advanced",
        "legacyPage": "Hyprland",
        "legacySections": [
            "Input",
            "Touchpad",
            "Touchpad Advanced"
        ],
        "keywords": "Config.options.hyprland.input.touchpad.dragLock"
    },
    {
        "id": "HyprlandSettings.sensitivity",
        "source": "HyprlandSettings",
        "route": "devices",
        "routes": [
            "devices"
        ],
        "label": "Sensitivity",
        "section": "Mouse & Input",
        "legacyPage": "Hyprland",
        "legacySections": [
            "Input",
            "Mouse & Input"
        ],
        "keywords": "Config.options.hyprland.input.sensitivity"
    },
    {
        "id": "HyprlandSettings.force-no-accel",
        "source": "HyprlandSettings",
        "route": "input-details",
        "routes": [
            "input-details"
        ],
        "label": "Force No Accel",
        "section": "Mouse & Input",
        "legacyPage": "Hyprland",
        "legacySections": [
            "Input",
            "Mouse & Input"
        ],
        "keywords": "Config.options.hyprland.input.forceNoAccel"
    },
    {
        "id": "HyprlandSettings.scroll-factor-2",
        "source": "HyprlandSettings",
        "route": "input-details",
        "routes": [
            "input-details"
        ],
        "label": "Scroll Factor",
        "section": "Mouse & Input",
        "legacyPage": "Hyprland",
        "legacySections": [
            "Input",
            "Mouse & Input"
        ],
        "keywords": "Config.options.hyprland.input.scrollFactor"
    },
    {
        "id": "HyprlandSettings.scroll-button",
        "source": "HyprlandSettings",
        "route": "input-details",
        "routes": [
            "input-details"
        ],
        "label": "Scroll Button",
        "section": "Mouse & Input",
        "legacyPage": "Hyprland",
        "legacySections": [
            "Input",
            "Mouse & Input"
        ],
        "keywords": "Config.options.hyprland.input.scrollButton"
    },
    {
        "id": "HyprlandSettings.left-handed",
        "source": "HyprlandSettings",
        "route": "devices",
        "routes": [
            "devices"
        ],
        "label": "Left Handed",
        "section": "Mouse & Input",
        "legacyPage": "Hyprland",
        "legacySections": [
            "Input",
            "Mouse & Input"
        ],
        "keywords": "Config.options.hyprland.input.leftHanded"
    },
    {
        "id": "HyprlandSettings.window-rounding",
        "source": "HyprlandSettings",
        "route": "effects",
        "routes": [
            "effects"
        ],
        "label": "Window Rounding",
        "section": "Visual & Aesthetics",
        "legacyPage": "Hyprland",
        "legacySections": [
            "Visual & Aesthetics"
        ],
        "keywords": "Config.options.hyprland.decoration.rounding"
    },
    {
        "id": "HyprlandSettings.rounding-power",
        "source": "HyprlandSettings",
        "route": "effects",
        "routes": [
            "effects"
        ],
        "label": "Rounding Power",
        "section": "Visual & Aesthetics",
        "legacyPage": "Hyprland",
        "legacySections": [
            "Visual & Aesthetics"
        ],
        "keywords": "Config.options.hyprland.decoration.roundingPower"
    },
    {
        "id": "HyprlandSettings.blur",
        "source": "HyprlandSettings",
        "route": "effects",
        "routes": [
            "effects"
        ],
        "label": "Blur",
        "section": "Visual & Aesthetics",
        "legacyPage": "Hyprland",
        "legacySections": [
            "Visual & Aesthetics"
        ],
        "keywords": "Config.options.hyprland.decoration.blur.enabled Config.options.appearance.visualEffect Config.options.hyprland.decoration.blur.variant"
    },
    {
        "id": "HyprlandSettings.blur-size",
        "source": "HyprlandSettings",
        "route": "effects",
        "routes": [
            "effects"
        ],
        "label": "Blur Size",
        "section": "Visual & Aesthetics",
        "legacyPage": "Hyprland",
        "legacySections": [
            "Visual & Aesthetics"
        ],
        "keywords": "Config.options.hyprland.decoration.blur.size"
    },
    {
        "id": "HyprlandSettings.blur-passes",
        "source": "HyprlandSettings",
        "route": "effects",
        "routes": [
            "effects"
        ],
        "label": "Blur Passes",
        "section": "Visual & Aesthetics",
        "legacyPage": "Hyprland",
        "legacySections": [
            "Visual & Aesthetics"
        ],
        "keywords": "Config.options.hyprland.decoration.blur.passes"
    },
    {
        "id": "HyprlandSettings.blur-vibrancy",
        "source": "HyprlandSettings",
        "route": "effects",
        "routes": [
            "effects"
        ],
        "label": "Blur Vibrancy",
        "section": "Visual & Aesthetics",
        "legacyPage": "Hyprland",
        "legacySections": [
            "Visual & Aesthetics"
        ],
        "keywords": "Config.options.hyprland.decoration.blur.vibrancy"
    },
    {
        "id": "HyprlandSettings.blur-xray",
        "source": "HyprlandSettings",
        "route": "effects",
        "routes": [
            "effects"
        ],
        "label": "Blur XRay",
        "section": "Visual & Aesthetics",
        "legacyPage": "Hyprland",
        "legacySections": [
            "Visual & Aesthetics"
        ],
        "keywords": "Config.options.hyprland.decoration.blur.xray"
    },
    {
        "id": "HyprlandSettings.blur-new-optimizations",
        "source": "HyprlandSettings",
        "route": "effects",
        "routes": [
            "effects"
        ],
        "label": "Blur New Optimizations",
        "section": "Visual & Aesthetics",
        "legacyPage": "Hyprland",
        "legacySections": [
            "Visual & Aesthetics"
        ],
        "keywords": "Config.options.hyprland.decoration.blur.newOptimizations"
    },
    {
        "id": "HyprlandSettings.blur-style",
        "source": "HyprlandSettings",
        "route": "effects",
        "routes": [
            "effects"
        ],
        "label": "Blur Style",
        "section": "Visual & Aesthetics",
        "legacyPage": "Hyprland",
        "legacySections": [
            "Visual & Aesthetics"
        ],
        "keywords": "Config.options.hyprland.decoration.blur.variant"
    },
    {
        "id": "HyprlandSettings.glass-refraction",
        "source": "HyprlandSettings",
        "route": "effects",
        "routes": [
            "effects"
        ],
        "label": "Glass Refraction",
        "section": "Visual & Aesthetics",
        "legacyPage": "Hyprland",
        "legacySections": [
            "Visual & Aesthetics"
        ],
        "keywords": "Config.options.hyprland.decoration.blur.variant Config.options.hyprland.decoration.blur.glass.refraction"
    },
    {
        "id": "HyprlandSettings.glass-pattern-size",
        "source": "HyprlandSettings",
        "route": "effects",
        "routes": [
            "effects"
        ],
        "label": "Glass Pattern Size",
        "section": "Visual & Aesthetics",
        "legacyPage": "Hyprland",
        "legacySections": [
            "Visual & Aesthetics"
        ],
        "keywords": "Config.options.hyprland.decoration.blur.variant Config.options.hyprland.decoration.blur.glass.size"
    },
    {
        "id": "HyprlandSettings.glass-roughness",
        "source": "HyprlandSettings",
        "route": "effects",
        "routes": [
            "effects"
        ],
        "label": "Glass Roughness",
        "section": "Visual & Aesthetics",
        "legacyPage": "Hyprland",
        "legacySections": [
            "Visual & Aesthetics"
        ],
        "keywords": "Config.options.hyprland.decoration.blur.variant Config.options.hyprland.decoration.blur.glass.roughness"
    },
    {
        "id": "HyprlandSettings.liquid-glass-refraction",
        "source": "HyprlandSettings",
        "route": "effects",
        "routes": [
            "effects"
        ],
        "label": "Liquid Glass Refraction",
        "section": "Visual & Aesthetics",
        "legacyPage": "Hyprland",
        "legacySections": [
            "Visual & Aesthetics"
        ],
        "keywords": "Config.options.hyprland.decoration.blur.variant Config.options.hyprland.decoration.blur.acrylic.refraction"
    },
    {
        "id": "HyprlandSettings.liquid-glass-edge-width",
        "source": "HyprlandSettings",
        "route": "effects",
        "routes": [
            "effects"
        ],
        "label": "Liquid Glass Edge Width",
        "section": "Visual & Aesthetics",
        "legacyPage": "Hyprland",
        "legacySections": [
            "Visual & Aesthetics"
        ],
        "keywords": "Config.options.hyprland.decoration.blur.variant Config.options.hyprland.decoration.blur.acrylic.bulb"
    },
    {
        "id": "HyprlandSettings.liquid-glass-clarity",
        "source": "HyprlandSettings",
        "route": "effects",
        "routes": [
            "effects"
        ],
        "label": "Liquid Glass Clarity",
        "section": "Visual & Aesthetics",
        "legacyPage": "Hyprland",
        "legacySections": [
            "Visual & Aesthetics"
        ],
        "keywords": "Config.options.hyprland.decoration.blur.variant Config.options.hyprland.decoration.blur.acrylic.clarity"
    },
    {
        "id": "HyprlandSettings.liquid-glass-chromatic-aberration",
        "source": "HyprlandSettings",
        "route": "effects",
        "routes": [
            "effects"
        ],
        "label": "Liquid Glass Chromatic Aberration",
        "section": "Visual & Aesthetics",
        "legacyPage": "Hyprland",
        "legacySections": [
            "Visual & Aesthetics"
        ],
        "keywords": "Config.options.hyprland.decoration.blur.variant Config.options.hyprland.decoration.blur.acrylic.aberration"
    },
    {
        "id": "HyprlandSettings.liquid-glass-tint-0xaarrggbb",
        "source": "HyprlandSettings",
        "route": "effects",
        "routes": [
            "effects"
        ],
        "label": "Liquid Glass Tint (0xAARRGGBB)",
        "section": "Visual & Aesthetics",
        "legacyPage": "Hyprland",
        "legacySections": [
            "Visual & Aesthetics"
        ],
        "keywords": "Config.options.hyprland.decoration.blur.variant Config.options.hyprland.decoration.blur.acrylic.tint"
    },
    {
        "id": "HyprlandSettings.ripple-strength",
        "source": "HyprlandSettings",
        "route": "effects",
        "routes": [
            "effects"
        ],
        "label": "Ripple Strength",
        "section": "Visual & Aesthetics",
        "legacyPage": "Hyprland",
        "legacySections": [
            "Visual & Aesthetics"
        ],
        "keywords": "Config.options.hyprland.decoration.blur.variant Config.options.hyprland.decoration.blur.ripple.strength"
    },
    {
        "id": "HyprlandSettings.ripple-radius",
        "source": "HyprlandSettings",
        "route": "effects",
        "routes": [
            "effects"
        ],
        "label": "Ripple Radius",
        "section": "Visual & Aesthetics",
        "legacyPage": "Hyprland",
        "legacySections": [
            "Visual & Aesthetics"
        ],
        "keywords": "Config.options.hyprland.decoration.blur.variant Config.options.hyprland.decoration.blur.ripple.radius"
    },
    {
        "id": "HyprlandSettings.ripple-wave-width",
        "source": "HyprlandSettings",
        "route": "effects",
        "routes": [
            "effects"
        ],
        "label": "Ripple Wave Width",
        "section": "Visual & Aesthetics",
        "legacyPage": "Hyprland",
        "legacySections": [
            "Visual & Aesthetics"
        ],
        "keywords": "Config.options.hyprland.decoration.blur.variant Config.options.hyprland.decoration.blur.ripple.width"
    },
    {
        "id": "HyprlandSettings.ripple-duration",
        "source": "HyprlandSettings",
        "route": "effects",
        "routes": [
            "effects"
        ],
        "label": "Ripple Duration",
        "section": "Visual & Aesthetics",
        "legacyPage": "Hyprland",
        "legacySections": [
            "Visual & Aesthetics"
        ],
        "keywords": "Config.options.hyprland.decoration.blur.variant Config.options.hyprland.decoration.blur.ripple.duration"
    },
    {
        "id": "HyprlandSettings.drops-speed-0-still-costs-more-gpu-above-0",
        "source": "HyprlandSettings",
        "route": "effects",
        "routes": [
            "effects"
        ],
        "label": "Drops Speed (0 = still, costs more GPU above 0)",
        "section": "Visual & Aesthetics",
        "legacyPage": "Hyprland",
        "legacySections": [
            "Visual & Aesthetics"
        ],
        "keywords": "Config.options.hyprland.decoration.blur.variant Config.options.hyprland.decoration.blur.drops.speed"
    },
    {
        "id": "HyprlandSettings.water-strength",
        "source": "HyprlandSettings",
        "route": "effects",
        "routes": [
            "effects"
        ],
        "label": "Water Strength",
        "section": "Visual & Aesthetics",
        "legacyPage": "Hyprland",
        "legacySections": [
            "Visual & Aesthetics"
        ],
        "keywords": "Config.options.hyprland.decoration.blur.variant Config.options.hyprland.decoration.blur.water.strength"
    },
    {
        "id": "HyprlandSettings.water-pointer-radius",
        "source": "HyprlandSettings",
        "route": "effects",
        "routes": [
            "effects"
        ],
        "label": "Water Pointer Radius",
        "section": "Visual & Aesthetics",
        "legacyPage": "Hyprland",
        "legacySections": [
            "Visual & Aesthetics"
        ],
        "keywords": "Config.options.hyprland.decoration.blur.variant Config.options.hyprland.decoration.blur.water.radius"
    },
    {
        "id": "HyprlandSettings.water-propagation-speed",
        "source": "HyprlandSettings",
        "route": "effects",
        "routes": [
            "effects"
        ],
        "label": "Water Propagation Speed",
        "section": "Visual & Aesthetics",
        "legacyPage": "Hyprland",
        "legacySections": [
            "Visual & Aesthetics"
        ],
        "keywords": "Config.options.hyprland.decoration.blur.variant Config.options.hyprland.decoration.blur.water.speed"
    },
    {
        "id": "HyprlandSettings.water-damping",
        "source": "HyprlandSettings",
        "route": "effects",
        "routes": [
            "effects"
        ],
        "label": "Water Damping",
        "section": "Visual & Aesthetics",
        "legacyPage": "Hyprland",
        "legacySections": [
            "Visual & Aesthetics"
        ],
        "keywords": "Config.options.hyprland.decoration.blur.variant Config.options.hyprland.decoration.blur.water.damping"
    },
    {
        "id": "HyprlandSettings.water-max-duration-s",
        "source": "HyprlandSettings",
        "route": "effects",
        "routes": [
            "effects"
        ],
        "label": "Water Max Duration (s)",
        "section": "Visual & Aesthetics",
        "legacyPage": "Hyprland",
        "legacySections": [
            "Visual & Aesthetics"
        ],
        "keywords": "Config.options.hyprland.decoration.blur.variant Config.options.hyprland.decoration.blur.water.duration"
    },
    {
        "id": "HyprlandSettings.fluid-jar-color-0xaarrggbb",
        "source": "HyprlandSettings",
        "route": "effects",
        "routes": [
            "effects"
        ],
        "label": "Fluid Jar Color (0xAARRGGBB)",
        "section": "Visual & Aesthetics",
        "legacyPage": "Hyprland",
        "legacySections": [
            "Visual & Aesthetics"
        ],
        "keywords": "Config.options.hyprland.decoration.blur.variant Config.options.hyprland.decoration.blur.fluidJar.color"
    },
    {
        "id": "HyprlandSettings.fluid-jar-speed",
        "source": "HyprlandSettings",
        "route": "effects",
        "routes": [
            "effects"
        ],
        "label": "Fluid Jar Speed",
        "section": "Visual & Aesthetics",
        "legacyPage": "Hyprland",
        "legacySections": [
            "Visual & Aesthetics"
        ],
        "keywords": "Config.options.hyprland.decoration.blur.variant Config.options.hyprland.decoration.blur.fluidJar.speed"
    },
    {
        "id": "HyprlandSettings.fluid-jar-fill-amount",
        "source": "HyprlandSettings",
        "route": "effects",
        "routes": [
            "effects"
        ],
        "label": "Fluid Jar Fill Amount",
        "section": "Visual & Aesthetics",
        "legacyPage": "Hyprland",
        "legacySections": [
            "Visual & Aesthetics"
        ],
        "keywords": "Config.options.hyprland.decoration.blur.variant Config.options.hyprland.decoration.blur.fluidJar.fillAmount"
    },
    {
        "id": "HyprlandSettings.fluid-jar-mass",
        "source": "HyprlandSettings",
        "route": "effects",
        "routes": [
            "effects"
        ],
        "label": "Fluid Jar Mass",
        "section": "Visual & Aesthetics",
        "legacyPage": "Hyprland",
        "legacySections": [
            "Visual & Aesthetics"
        ],
        "keywords": "Config.options.hyprland.decoration.blur.variant Config.options.hyprland.decoration.blur.fluidJar.mass"
    },
    {
        "id": "HyprlandSettings.fluid-jar-precision-2x-recommended-4x-expensive",
        "source": "HyprlandSettings",
        "route": "effects",
        "routes": [
            "effects"
        ],
        "label": "Fluid Jar Precision (2x recommended, 4x+ expensive)",
        "section": "Visual & Aesthetics",
        "legacyPage": "Hyprland",
        "legacySections": [
            "Visual & Aesthetics"
        ],
        "keywords": "Config.options.hyprland.decoration.blur.variant Config.options.hyprland.decoration.blur.fluidJar.precision"
    },
    {
        "id": "HyprlandSettings.fluid-jar-turbulence",
        "source": "HyprlandSettings",
        "route": "effects",
        "routes": [
            "effects"
        ],
        "label": "Fluid Jar Turbulence",
        "section": "Visual & Aesthetics",
        "legacyPage": "Hyprland",
        "legacySections": [
            "Visual & Aesthetics"
        ],
        "keywords": "Config.options.hyprland.decoration.blur.variant Config.options.hyprland.decoration.blur.fluidJar.turbulence"
    },
    {
        "id": "HyprlandSettings.fluid-jar-distortion",
        "source": "HyprlandSettings",
        "route": "effects",
        "routes": [
            "effects"
        ],
        "label": "Fluid Jar Distortion",
        "section": "Visual & Aesthetics",
        "legacyPage": "Hyprland",
        "legacySections": [
            "Visual & Aesthetics"
        ],
        "keywords": "Config.options.hyprland.decoration.blur.variant Config.options.hyprland.decoration.blur.fluidJar.distortion"
    },
    {
        "id": "HyprlandSettings.heat-shimmer-speed-0-still-costs-more-gpu-above-0",
        "source": "HyprlandSettings",
        "route": "effects",
        "routes": [
            "effects"
        ],
        "label": "Heat Shimmer Speed (0 = still, costs more GPU above 0)",
        "section": "Visual & Aesthetics",
        "legacyPage": "Hyprland",
        "legacySections": [
            "Visual & Aesthetics"
        ],
        "keywords": "Config.options.hyprland.decoration.blur.variant Config.options.hyprland.decoration.blur.heatShimmer.speed"
    },
    {
        "id": "HyprlandSettings.aurora-speed-0-frozen-costs-more-gpu-above-0",
        "source": "HyprlandSettings",
        "route": "effects",
        "routes": [
            "effects"
        ],
        "label": "Aurora Speed (0 = frozen, costs more GPU above 0)",
        "section": "Visual & Aesthetics",
        "legacyPage": "Hyprland",
        "legacySections": [
            "Visual & Aesthetics"
        ],
        "keywords": "Config.options.hyprland.decoration.blur.variant Config.options.hyprland.decoration.blur.aurora.speed"
    },
    {
        "id": "HyprlandSettings.aurora-intensity",
        "source": "HyprlandSettings",
        "route": "effects",
        "routes": [
            "effects"
        ],
        "label": "Aurora Intensity",
        "section": "Visual & Aesthetics",
        "legacyPage": "Hyprland",
        "legacySections": [
            "Visual & Aesthetics"
        ],
        "keywords": "Config.options.hyprland.decoration.blur.variant Config.options.hyprland.decoration.blur.aurora.intensity"
    },
    {
        "id": "HyprlandSettings.aurora-color-1-0xaarrggbb",
        "source": "HyprlandSettings",
        "route": "effects",
        "routes": [
            "effects"
        ],
        "label": "Aurora Color 1 (0xAARRGGBB)",
        "section": "Visual & Aesthetics",
        "legacyPage": "Hyprland",
        "legacySections": [
            "Visual & Aesthetics"
        ],
        "keywords": "Config.options.hyprland.decoration.blur.variant Config.options.hyprland.decoration.blur.aurora.color1"
    },
    {
        "id": "HyprlandSettings.aurora-color-2-0xaarrggbb",
        "source": "HyprlandSettings",
        "route": "effects",
        "routes": [
            "effects"
        ],
        "label": "Aurora Color 2 (0xAARRGGBB)",
        "section": "Visual & Aesthetics",
        "legacyPage": "Hyprland",
        "legacySections": [
            "Visual & Aesthetics"
        ],
        "keywords": "Config.options.hyprland.decoration.blur.variant Config.options.hyprland.decoration.blur.aurora.color2"
    },
    {
        "id": "HyprlandSettings.haze-intensity",
        "source": "HyprlandSettings",
        "route": "effects",
        "routes": [
            "effects"
        ],
        "label": "Haze Intensity",
        "section": "Visual & Aesthetics",
        "legacyPage": "Hyprland",
        "legacySections": [
            "Visual & Aesthetics"
        ],
        "keywords": "Config.options.hyprland.decoration.blur.variant Config.options.hyprland.decoration.blur.haze.intensity"
    },
    {
        "id": "HyprlandSettings.haze-iridescence",
        "source": "HyprlandSettings",
        "route": "effects",
        "routes": [
            "effects"
        ],
        "label": "Haze Iridescence",
        "section": "Visual & Aesthetics",
        "legacyPage": "Hyprland",
        "legacySections": [
            "Visual & Aesthetics"
        ],
        "keywords": "Config.options.hyprland.decoration.blur.variant Config.options.hyprland.decoration.blur.haze.iridescence"
    },
    {
        "id": "HyprlandSettings.border-size",
        "source": "HyprlandSettings",
        "route": "effects",
        "routes": [
            "effects"
        ],
        "label": "Border Size",
        "section": "Visual & Aesthetics",
        "legacyPage": "Hyprland",
        "legacySections": [
            "Visual & Aesthetics"
        ],
        "keywords": "Config.options.hyprland.general.borderSize"
    },
    {
        "id": "HyprlandSettings.gaps-in",
        "source": "HyprlandSettings",
        "route": "effects",
        "routes": [
            "effects"
        ],
        "label": "Gaps In",
        "section": "Visual & Aesthetics",
        "legacyPage": "Hyprland",
        "legacySections": [
            "Visual & Aesthetics"
        ],
        "keywords": "Config.options.hyprland.general.gapsIn"
    },
    {
        "id": "HyprlandSettings.gaps-out",
        "source": "HyprlandSettings",
        "route": "effects",
        "routes": [
            "effects"
        ],
        "label": "Gaps Out",
        "section": "Visual & Aesthetics",
        "legacyPage": "Hyprland",
        "legacySections": [
            "Visual & Aesthetics"
        ],
        "keywords": "Config.options.hyprland.general.gapsOut"
    },
    {
        "id": "HyprlandSettings.gaps-workspaces",
        "source": "HyprlandSettings",
        "route": "effects",
        "routes": [
            "effects"
        ],
        "label": "Gaps Workspaces",
        "section": "Visual & Aesthetics",
        "legacyPage": "Hyprland",
        "legacySections": [
            "Visual & Aesthetics"
        ],
        "keywords": "Config.options.hyprland.general.gapsWorkspaces"
    },
    {
        "id": "HyprlandSettings.active-opacity",
        "source": "HyprlandSettings",
        "route": "effects",
        "routes": [
            "effects"
        ],
        "label": "Active Opacity",
        "section": "Visual & Aesthetics",
        "legacyPage": "Hyprland",
        "legacySections": [
            "Visual & Aesthetics"
        ],
        "keywords": "Config.options.hyprland.decoration.activeOpacity"
    },
    {
        "id": "HyprlandSettings.inactive-opacity",
        "source": "HyprlandSettings",
        "route": "effects",
        "routes": [
            "effects"
        ],
        "label": "Inactive Opacity",
        "section": "Visual & Aesthetics",
        "legacyPage": "Hyprland",
        "legacySections": [
            "Visual & Aesthetics"
        ],
        "keywords": "Config.options.hyprland.decoration.inactiveOpacity"
    },
    {
        "id": "HyprlandSettings.fullscreen-opacity",
        "source": "HyprlandSettings",
        "route": "effects",
        "routes": [
            "effects"
        ],
        "label": "Fullscreen Opacity",
        "section": "Visual & Aesthetics",
        "legacyPage": "Hyprland",
        "legacySections": [
            "Visual & Aesthetics"
        ],
        "keywords": "Config.options.hyprland.decoration.fullscreenOpacity"
    },
    {
        "id": "HyprlandSettings.dim-inactive",
        "source": "HyprlandSettings",
        "route": "effects",
        "routes": [
            "effects"
        ],
        "label": "Dim Inactive",
        "section": "Visual & Aesthetics",
        "legacyPage": "Hyprland",
        "legacySections": [
            "Visual & Aesthetics"
        ],
        "keywords": "Config.options.hyprland.decoration.dimInactive"
    },
    {
        "id": "HyprlandSettings.dim-strength",
        "source": "HyprlandSettings",
        "route": "effects",
        "routes": [
            "effects"
        ],
        "label": "Dim Strength",
        "section": "Visual & Aesthetics",
        "legacyPage": "Hyprland",
        "legacySections": [
            "Visual & Aesthetics"
        ],
        "keywords": "Config.options.hyprland.decoration.dimStrength Config.options.hyprland.decoration.dimInactive"
    },
    {
        "id": "HyprlandSettings.dim-special",
        "source": "HyprlandSettings",
        "route": "effects",
        "routes": [
            "effects"
        ],
        "label": "Dim Special",
        "section": "Visual & Aesthetics",
        "legacyPage": "Hyprland",
        "legacySections": [
            "Visual & Aesthetics"
        ],
        "keywords": "Config.options.hyprland.decoration.dimSpecial"
    },
    {
        "id": "HyprlandSettings.border-part-of-window",
        "source": "HyprlandSettings",
        "route": "effects",
        "routes": [
            "effects"
        ],
        "label": "Border Part Of Window",
        "section": "Visual & Aesthetics",
        "legacyPage": "Hyprland",
        "legacySections": [
            "Visual & Aesthetics"
        ],
        "keywords": "Config.options.hyprland.decoration.borderPartOfWindow"
    },
    {
        "id": "HyprlandSettings.shadow-enabled",
        "source": "HyprlandSettings",
        "route": "effects",
        "routes": [
            "effects"
        ],
        "label": "Shadow Enabled",
        "section": "Visual & Aesthetics",
        "legacyPage": "Hyprland",
        "legacySections": [
            "Visual & Aesthetics"
        ],
        "keywords": "Config.options.hyprland.decoration.shadow.enabled"
    },
    {
        "id": "HyprlandSettings.shadow-range",
        "source": "HyprlandSettings",
        "route": "effects",
        "routes": [
            "effects"
        ],
        "label": "Shadow Range",
        "section": "Visual & Aesthetics",
        "legacyPage": "Hyprland",
        "legacySections": [
            "Visual & Aesthetics"
        ],
        "keywords": "Config.options.hyprland.decoration.shadow.range Config.options.hyprland.decoration.shadow.enabled"
    },
    {
        "id": "HyprlandSettings.shadow-render-power",
        "source": "HyprlandSettings",
        "route": "effects",
        "routes": [
            "effects"
        ],
        "label": "Shadow Render Power",
        "section": "Visual & Aesthetics",
        "legacyPage": "Hyprland",
        "legacySections": [
            "Visual & Aesthetics"
        ],
        "keywords": "Config.options.hyprland.decoration.shadow.renderPower Config.options.hyprland.decoration.shadow.enabled"
    },
    {
        "id": "HyprlandSettings.shadow-sharp",
        "source": "HyprlandSettings",
        "route": "effects",
        "routes": [
            "effects"
        ],
        "label": "Shadow Sharp",
        "section": "Visual & Aesthetics",
        "legacyPage": "Hyprland",
        "legacySections": [
            "Visual & Aesthetics"
        ],
        "keywords": "Config.options.hyprland.decoration.shadow.sharp Config.options.hyprland.decoration.shadow.enabled"
    },
    {
        "id": "HyprlandSettings.shadow-offset-x",
        "source": "HyprlandSettings",
        "route": "effects",
        "routes": [
            "effects"
        ],
        "label": "Shadow Offset X",
        "section": "Visual & Aesthetics",
        "legacyPage": "Hyprland",
        "legacySections": [
            "Visual & Aesthetics"
        ],
        "keywords": "Config.options.hyprland.decoration.shadow.offsetX Config.options.hyprland.decoration.shadow.enabled Config.options.hyprland.decoration.shadow.offsetY"
    },
    {
        "id": "HyprlandSettings.shadow-offset-y",
        "source": "HyprlandSettings",
        "route": "effects",
        "routes": [
            "effects"
        ],
        "label": "Shadow Offset Y",
        "section": "Visual & Aesthetics",
        "legacyPage": "Hyprland",
        "legacySections": [
            "Visual & Aesthetics"
        ],
        "keywords": "Config.options.hyprland.decoration.shadow.offsetY Config.options.hyprland.decoration.shadow.enabled Config.options.hyprland.decoration.shadow.offsetX"
    },
    {
        "id": "HyprlandSettings.shadow-scale",
        "source": "HyprlandSettings",
        "route": "effects",
        "routes": [
            "effects"
        ],
        "label": "Shadow Scale",
        "section": "Visual & Aesthetics",
        "legacyPage": "Hyprland",
        "legacySections": [
            "Visual & Aesthetics"
        ],
        "keywords": "Config.options.hyprland.decoration.shadow.scale Config.options.hyprland.decoration.shadow.enabled"
    },
    {
        "id": "HyprlandSettings.shadow-inactive-color",
        "source": "HyprlandSettings",
        "route": "effects",
        "routes": [
            "effects"
        ],
        "label": "Shadow Inactive Color",
        "section": "Visual & Aesthetics",
        "legacyPage": "Hyprland",
        "legacySections": [
            "Visual & Aesthetics"
        ],
        "keywords": "Config.options.hyprland.decoration.shadow.colorInactive"
    },
    {
        "id": "HyprlandSettings.dim-modal",
        "source": "HyprlandSettings",
        "route": "effects",
        "routes": [
            "effects"
        ],
        "label": "Dim Modal",
        "section": "Advanced Decoration",
        "legacyPage": "Hyprland",
        "legacySections": [
            "Visual & Aesthetics",
            "Advanced Decoration"
        ],
        "keywords": "Config.options.hyprland.decoration.dimModal"
    },
    {
        "id": "HyprlandSettings.dim-around",
        "source": "HyprlandSettings",
        "route": "effects",
        "routes": [
            "effects"
        ],
        "label": "Dim Around",
        "section": "Advanced Decoration",
        "legacyPage": "Hyprland",
        "legacySections": [
            "Visual & Aesthetics",
            "Advanced Decoration"
        ],
        "keywords": "Config.options.hyprland.decoration.dimAround"
    },
    {
        "id": "HyprlandSettings.noise",
        "source": "HyprlandSettings",
        "route": "effects",
        "routes": [
            "effects"
        ],
        "label": "Noise",
        "section": "Advanced Blur",
        "legacyPage": "Hyprland",
        "legacySections": [
            "Visual & Aesthetics",
            "Advanced Blur"
        ],
        "keywords": "Config.options.hyprland.decoration.blur.noise"
    },
    {
        "id": "HyprlandSettings.contrast",
        "source": "HyprlandSettings",
        "route": "effects",
        "routes": [
            "effects"
        ],
        "label": "Contrast",
        "section": "Advanced Blur",
        "legacyPage": "Hyprland",
        "legacySections": [
            "Visual & Aesthetics",
            "Advanced Blur"
        ],
        "keywords": "Config.options.hyprland.decoration.blur.contrast"
    },
    {
        "id": "HyprlandSettings.brightness",
        "source": "HyprlandSettings",
        "route": "effects",
        "routes": [
            "effects"
        ],
        "label": "Brightness",
        "section": "Advanced Blur",
        "legacyPage": "Hyprland",
        "legacySections": [
            "Visual & Aesthetics",
            "Advanced Blur"
        ],
        "keywords": "Config.options.hyprland.decoration.blur.brightness"
    },
    {
        "id": "HyprlandSettings.vibrancy-darkness",
        "source": "HyprlandSettings",
        "route": "effects",
        "routes": [
            "effects"
        ],
        "label": "Vibrancy Darkness",
        "section": "Advanced Blur",
        "legacyPage": "Hyprland",
        "legacySections": [
            "Visual & Aesthetics",
            "Advanced Blur"
        ],
        "keywords": "Config.options.hyprland.decoration.blur.vibrancyDarkness"
    },
    {
        "id": "HyprlandSettings.blur-special",
        "source": "HyprlandSettings",
        "route": "effects",
        "routes": [
            "effects"
        ],
        "label": "Blur Special",
        "section": "Advanced Blur",
        "legacyPage": "Hyprland",
        "legacySections": [
            "Visual & Aesthetics",
            "Advanced Blur"
        ],
        "keywords": "Config.options.hyprland.decoration.blur.special"
    },
    {
        "id": "HyprlandSettings.blur-popups",
        "source": "HyprlandSettings",
        "route": "effects",
        "routes": [
            "effects"
        ],
        "label": "Blur Popups",
        "section": "Advanced Blur",
        "legacyPage": "Hyprland",
        "legacySections": [
            "Visual & Aesthetics",
            "Advanced Blur"
        ],
        "keywords": "Config.options.hyprland.decoration.blur.popups"
    },
    {
        "id": "HyprlandSettings.popups-ignore-alpha",
        "source": "HyprlandSettings",
        "route": "effects",
        "routes": [
            "effects"
        ],
        "label": "Popups Ignore Alpha",
        "section": "Advanced Blur",
        "legacyPage": "Hyprland",
        "legacySections": [
            "Visual & Aesthetics",
            "Advanced Blur"
        ],
        "keywords": "Config.options.hyprland.decoration.blur.popupsIgnorealpha Config.options.hyprland.decoration.blur.popups"
    },
    {
        "id": "HyprlandSettings.resize-on-border",
        "source": "HyprlandSettings",
        "route": "window-rules",
        "routes": [
            "window-rules"
        ],
        "label": "Resize On Border",
        "section": "General & Snap",
        "legacyPage": "Hyprland",
        "legacySections": [
            "General & Snap"
        ],
        "keywords": "Config.options.hyprland.general.resizeOnBorder"
    },
    {
        "id": "HyprlandSettings.allow-tearing",
        "source": "HyprlandSettings",
        "route": "window-rules",
        "routes": [
            "window-rules"
        ],
        "label": "Allow Tearing",
        "section": "General & Snap",
        "legacyPage": "Hyprland",
        "legacySections": [
            "General & Snap"
        ],
        "keywords": "Config.options.hyprland.general.allowTearing"
    },
    {
        "id": "HyprlandSettings.snap-enabled",
        "source": "HyprlandSettings",
        "route": "window-rules",
        "routes": [
            "window-rules"
        ],
        "label": "Snap Enabled",
        "section": "General & Snap",
        "legacyPage": "Hyprland",
        "legacySections": [
            "General & Snap"
        ],
        "keywords": "Config.options.hyprland.general.snapEnabled"
    },
    {
        "id": "HyprlandSettings.snap-window-gap",
        "source": "HyprlandSettings",
        "route": "window-rules",
        "routes": [
            "window-rules"
        ],
        "label": "Snap Window Gap",
        "section": "General & Snap",
        "legacyPage": "Hyprland",
        "legacySections": [
            "General & Snap"
        ],
        "keywords": "Config.options.hyprland.general.snapWindowGap Config.options.hyprland.general.snapEnabled"
    },
    {
        "id": "HyprlandSettings.snap-monitor-gap",
        "source": "HyprlandSettings",
        "route": "window-rules",
        "routes": [
            "window-rules"
        ],
        "label": "Snap Monitor Gap",
        "section": "General & Snap",
        "legacyPage": "Hyprland",
        "legacySections": [
            "General & Snap"
        ],
        "keywords": "Config.options.hyprland.general.snapMonitorGap Config.options.hyprland.general.snapEnabled"
    },
    {
        "id": "HyprlandSettings.snap-border-overlap",
        "source": "HyprlandSettings",
        "route": "window-rules",
        "routes": [
            "window-rules"
        ],
        "label": "Snap Border Overlap",
        "section": "General & Snap",
        "legacyPage": "Hyprland",
        "legacySections": [
            "General & Snap"
        ],
        "keywords": "Config.options.hyprland.general.snapBorderOverlap Config.options.hyprland.general.snapEnabled"
    },
    {
        "id": "HyprlandSettings.snap-respect-gaps",
        "source": "HyprlandSettings",
        "route": "window-rules",
        "routes": [
            "window-rules"
        ],
        "label": "Snap Respect Gaps",
        "section": "General & Snap",
        "legacyPage": "Hyprland",
        "legacySections": [
            "General & Snap"
        ],
        "keywords": "Config.options.hyprland.general.snapRespectGaps Config.options.hyprland.general.snapEnabled"
    },
    {
        "id": "HyprlandSettings.active-border-color",
        "source": "HyprlandSettings",
        "route": "window-rules",
        "routes": [
            "window-rules"
        ],
        "label": "Active Border Color",
        "section": "Advanced General Settings",
        "legacyPage": "Hyprland",
        "legacySections": [
            "General & Snap",
            "Advanced General Settings"
        ],
        "keywords": "Config.options.hyprland.general.colActiveBorder"
    },
    {
        "id": "HyprlandSettings.inactive-border-color",
        "source": "HyprlandSettings",
        "route": "window-rules",
        "routes": [
            "window-rules"
        ],
        "label": "Inactive Border Color",
        "section": "Advanced General Settings",
        "legacyPage": "Hyprland",
        "legacySections": [
            "General & Snap",
            "Advanced General Settings"
        ],
        "keywords": "Config.options.hyprland.general.colInactiveBorder"
    },
    {
        "id": "HyprlandSettings.nogroup-border-color",
        "source": "HyprlandSettings",
        "route": "window-rules",
        "routes": [
            "window-rules"
        ],
        "label": "Nogroup Border Color",
        "section": "Advanced General Settings",
        "legacyPage": "Hyprland",
        "legacySections": [
            "General & Snap",
            "Advanced General Settings"
        ],
        "keywords": "Config.options.hyprland.general.colNogroupBorder"
    },
    {
        "id": "HyprlandSettings.float-gaps",
        "source": "HyprlandSettings",
        "route": "window-rules",
        "routes": [
            "window-rules"
        ],
        "label": "Float Gaps",
        "section": "Advanced General Settings",
        "legacyPage": "Hyprland",
        "legacySections": [
            "General & Snap",
            "Advanced General Settings"
        ],
        "keywords": "Config.options.hyprland.general.floatGaps"
    },
    {
        "id": "HyprlandSettings.extend-border-grab-area",
        "source": "HyprlandSettings",
        "route": "window-rules",
        "routes": [
            "window-rules"
        ],
        "label": "Extend Border Grab Area",
        "section": "Advanced General Settings",
        "legacyPage": "Hyprland",
        "legacySections": [
            "General & Snap",
            "Advanced General Settings"
        ],
        "keywords": "Config.options.hyprland.general.extendBorderGrabArea"
    },
    {
        "id": "HyprlandSettings.hover-icon-on-border",
        "source": "HyprlandSettings",
        "route": "window-rules",
        "routes": [
            "window-rules"
        ],
        "label": "Hover Icon On Border",
        "section": "Advanced General Settings",
        "legacyPage": "Hyprland",
        "legacySections": [
            "General & Snap",
            "Advanced General Settings"
        ],
        "keywords": "Config.options.hyprland.general.hoverIconOnBorder"
    },
    {
        "id": "HyprlandSettings.no-focus-fallback",
        "source": "HyprlandSettings",
        "route": "window-rules",
        "routes": [
            "window-rules"
        ],
        "label": "No Focus Fallback",
        "section": "Advanced General Settings",
        "legacyPage": "Hyprland",
        "legacySections": [
            "General & Snap",
            "Advanced General Settings"
        ],
        "keywords": "Config.options.hyprland.general.noFocusFallback"
    },
    {
        "id": "HyprlandSettings.disable-hyprland-logo",
        "source": "HyprlandSettings",
        "route": "window-rules",
        "routes": [
            "window-rules"
        ],
        "label": "Disable Hyprland Logo",
        "section": "Misc",
        "legacyPage": "Hyprland",
        "legacySections": [
            "Misc"
        ],
        "keywords": "Config.options.hyprland.misc.disableHyprlandLogo"
    },
    {
        "id": "HyprlandSettings.disable-splash-rendering",
        "source": "HyprlandSettings",
        "route": "window-rules",
        "routes": [
            "window-rules"
        ],
        "label": "Disable Splash Rendering",
        "section": "Misc",
        "legacyPage": "Hyprland",
        "legacySections": [
            "Misc"
        ],
        "keywords": "Config.options.hyprland.misc.disableSplashRendering"
    },
    {
        "id": "HyprlandSettings.vrr-2",
        "source": "HyprlandSettings",
        "route": "window-rules",
        "routes": [
            "window-rules"
        ],
        "label": "VRR",
        "section": "Misc",
        "legacyPage": "Hyprland",
        "legacySections": [
            "Misc"
        ],
        "keywords": "Config.options.hyprland.misc.vrr"
    },
    {
        "id": "HyprlandSettings.mouse-move-enables-dpms",
        "source": "HyprlandSettings",
        "route": "window-rules",
        "routes": [
            "window-rules"
        ],
        "label": "Mouse Move Enables DPMS",
        "section": "Misc",
        "legacyPage": "Hyprland",
        "legacySections": [
            "Misc"
        ],
        "keywords": "Config.options.hyprland.misc.mouseMoveEnablesDpms"
    },
    {
        "id": "HyprlandSettings.key-press-enables-dpms",
        "source": "HyprlandSettings",
        "route": "window-rules",
        "routes": [
            "window-rules"
        ],
        "label": "Key Press Enables DPMS",
        "section": "Misc",
        "legacyPage": "Hyprland",
        "legacySections": [
            "Misc"
        ],
        "keywords": "Config.options.hyprland.misc.keyPressEnablesDpms"
    },
    {
        "id": "HyprlandSettings.animate-manual-resizes",
        "source": "HyprlandSettings",
        "route": "window-rules",
        "routes": [
            "window-rules"
        ],
        "label": "Animate Manual Resizes",
        "section": "Misc",
        "legacyPage": "Hyprland",
        "legacySections": [
            "Misc"
        ],
        "keywords": "Config.options.hyprland.misc.animateManualResizes"
    },
    {
        "id": "HyprlandSettings.animate-mouse-window-dragging",
        "source": "HyprlandSettings",
        "route": "window-rules",
        "routes": [
            "window-rules"
        ],
        "label": "Animate Mouse Window Dragging",
        "section": "Misc",
        "legacyPage": "Hyprland",
        "legacySections": [
            "Misc"
        ],
        "keywords": "Config.options.hyprland.misc.animateMouseWindowDragging"
    },
    {
        "id": "HyprlandSettings.focus-on-activate",
        "source": "HyprlandSettings",
        "route": "window-rules",
        "routes": [
            "window-rules"
        ],
        "label": "Focus On Activate",
        "section": "Misc",
        "legacyPage": "Hyprland",
        "legacySections": [
            "Misc"
        ],
        "keywords": "Config.options.hyprland.misc.focusOnActivate"
    },
    {
        "id": "HyprlandSettings.zoom-factor",
        "source": "HyprlandSettings",
        "route": "input-details",
        "routes": [
            "input-details"
        ],
        "label": "Zoom Factor",
        "section": "Cursor",
        "legacyPage": "Hyprland",
        "legacySections": [
            "Cursor"
        ],
        "keywords": "Config.options.hyprland.cursor.zoomFactor"
    },
    {
        "id": "HyprlandSettings.zoom-rigid",
        "source": "HyprlandSettings",
        "route": "input-details",
        "routes": [
            "input-details"
        ],
        "label": "Zoom Rigid",
        "section": "Cursor",
        "legacyPage": "Hyprland",
        "legacySections": [
            "Cursor"
        ],
        "keywords": "Config.options.hyprland.cursor.zoomRigid"
    },
    {
        "id": "HyprlandSettings.hide-on-key-press",
        "source": "HyprlandSettings",
        "route": "input-details",
        "routes": [
            "input-details"
        ],
        "label": "Hide On Key Press",
        "section": "Cursor",
        "legacyPage": "Hyprland",
        "legacySections": [
            "Cursor"
        ],
        "keywords": "Config.options.hyprland.cursor.hideOnKeyPress"
    },
    {
        "id": "HyprlandSettings.inactive-timeout-s",
        "source": "HyprlandSettings",
        "route": "input-details",
        "routes": [
            "input-details"
        ],
        "label": "Inactive Timeout (s)",
        "section": "Cursor",
        "legacyPage": "Hyprland",
        "legacySections": [
            "Cursor"
        ],
        "keywords": "Config.options.hyprland.cursor.inactiveTimeout"
    },
    {
        "id": "HyprlandSettings.hotspot-padding",
        "source": "HyprlandSettings",
        "route": "input-details",
        "routes": [
            "input-details"
        ],
        "label": "Hotspot Padding",
        "section": "Cursor",
        "legacyPage": "Hyprland",
        "legacySections": [
            "Cursor"
        ],
        "keywords": "Config.options.hyprland.cursor.hotspotPadding"
    },
    {
        "id": "HyprlandSettings.no-warps",
        "source": "HyprlandSettings",
        "route": "input-details",
        "routes": [
            "input-details"
        ],
        "label": "No Warps",
        "section": "Cursor",
        "legacyPage": "Hyprland",
        "legacySections": [
            "Cursor"
        ],
        "keywords": "Config.options.hyprland.cursor.noWarps"
    },
    {
        "id": "HyprlandSettings.persistent-warps",
        "source": "HyprlandSettings",
        "route": "input-details",
        "routes": [
            "input-details"
        ],
        "label": "Persistent Warps",
        "section": "Cursor",
        "legacyPage": "Hyprland",
        "legacySections": [
            "Cursor"
        ],
        "keywords": "Config.options.hyprland.cursor.persistentWarps"
    },
    {
        "id": "HyprlandSettings.workspace-swipe-distance",
        "source": "HyprlandSettings",
        "route": "input-details",
        "routes": [
            "input-details"
        ],
        "label": "Workspace Swipe Distance",
        "section": "Gestures",
        "legacyPage": "Hyprland",
        "legacySections": [
            "Gestures"
        ],
        "keywords": "Config.options.hyprland.gestures.workspaceSwipeDistance"
    },
    {
        "id": "HyprlandSettings.swipe-cancel-ratio",
        "source": "HyprlandSettings",
        "route": "input-details",
        "routes": [
            "input-details"
        ],
        "label": "Swipe Cancel Ratio (%)",
        "section": "Gestures",
        "legacyPage": "Hyprland",
        "legacySections": [
            "Gestures"
        ],
        "keywords": "Config.options.hyprland.gestures.workspaceSwipeCancelRatio"
    },
    {
        "id": "HyprlandSettings.swipe-min-speed",
        "source": "HyprlandSettings",
        "route": "input-details",
        "routes": [
            "input-details"
        ],
        "label": "Swipe Min Speed",
        "section": "Gestures",
        "legacyPage": "Hyprland",
        "legacySections": [
            "Gestures"
        ],
        "keywords": "Config.options.hyprland.gestures.workspaceSwipeMinSpeedToForce"
    },
    {
        "id": "HyprlandSettings.swipe-direction-lock",
        "source": "HyprlandSettings",
        "route": "input-details",
        "routes": [
            "input-details"
        ],
        "label": "Swipe Direction Lock",
        "section": "Gestures",
        "legacyPage": "Hyprland",
        "legacySections": [
            "Gestures"
        ],
        "keywords": "Config.options.hyprland.gestures.workspaceSwipeDirectionLock"
    },
    {
        "id": "HyprlandSettings.save-binds",
        "source": "HyprlandSettings",
        "route": "input-details",
        "routes": [
            "input-details"
        ],
        "label": "Save Binds",
        "section": "Custom Binds (Advanced)",
        "legacyPage": "Hyprland",
        "legacySections": [
            "Custom Binds (Advanced)"
        ],
        "keywords": ""
    },
    {
        "id": "HyprlandSettings.reload-hyprland",
        "source": "HyprlandSettings",
        "route": "input-details",
        "routes": [
            "input-details"
        ],
        "label": "Reload Hyprland",
        "section": "Custom Binds (Advanced)",
        "legacyPage": "Hyprland",
        "legacySections": [
            "Custom Binds (Advanced)"
        ],
        "keywords": ""
    },
    {
        "id": "HyprlandSettings.save-rules",
        "source": "HyprlandSettings",
        "route": "window-rules",
        "routes": [
            "window-rules"
        ],
        "label": "Save Rules",
        "section": "Custom Window Rules (Advanced)",
        "legacyPage": "Hyprland",
        "legacySections": [
            "Custom Window Rules (Advanced)"
        ],
        "keywords": ""
    },
    {
        "id": "HyprlandSettings.reload-hyprland-2",
        "source": "HyprlandSettings",
        "route": "window-rules",
        "routes": [
            "window-rules"
        ],
        "label": "Reload Hyprland",
        "section": "Custom Window Rules (Advanced)",
        "legacyPage": "Hyprland",
        "legacySections": [
            "Custom Window Rules (Advanced)"
        ],
        "keywords": ""
    },
    {
        "id": "HyprlandSettings.add-2",
        "source": "HyprlandSettings",
        "route": "window-rules",
        "routes": [
            "window-rules"
        ],
        "label": "Add",
        "section": "Workspace Rules",
        "legacyPage": "Hyprland",
        "legacySections": [
            "Workspace Rules"
        ],
        "keywords": "Config.options.hyprland.general.workspaceRules.slice Config.options.hyprland.general.workspaceRules"
    },
    {
        "id": "HyprlandSettings.save",
        "source": "HyprlandSettings",
        "route": "window-rules",
        "routes": [
            "window-rules"
        ],
        "label": "Save",
        "section": "Workspace Rules",
        "legacyPage": "Hyprland",
        "legacySections": [
            "Workspace Rules"
        ],
        "keywords": ""
    },
    {
        "id": "HyprlandSettings.add-3",
        "source": "HyprlandSettings",
        "route": "window-rules",
        "routes": [
            "window-rules"
        ],
        "label": "Add",
        "section": "Window Rules (Structured)",
        "legacyPage": "Hyprland",
        "legacySections": [
            "Window Rules (Structured)"
        ],
        "keywords": "Config.options.hyprland.general.windowRules.slice Config.options.hyprland.general.windowRules"
    },
    {
        "id": "HyprlandSettings.save-2",
        "source": "HyprlandSettings",
        "route": "window-rules",
        "routes": [
            "window-rules"
        ],
        "label": "Save",
        "section": "Window Rules (Structured)",
        "legacyPage": "Hyprland",
        "legacySections": [
            "Window Rules (Structured)"
        ],
        "keywords": ""
    },
    {
        "id": "HyprlandSettings.startup-applications",
        "source": "HyprlandSettings",
        "route": "apps",
        "routes": [
            "apps"
        ],
        "label": "Startup applications",
        "section": "Autostart Apps",
        "legacyPage": "Hyprland",
        "legacySections": [
            "Autostart Apps"
        ],
        "keywords": ""
    },
    {
        "id": "HyprlandSettings.enable",
        "source": "HyprlandSettings",
        "route": "effects",
        "routes": [
            "effects"
        ],
        "label": "Enable",
        "section": "Animations",
        "legacyPage": "Hyprland",
        "legacySections": [
            "Animations"
        ],
        "keywords": "Config.options.hyprland.animations.enable"
    },
    {
        "id": "HyprlandSettings.workspace-wraparound",
        "source": "HyprlandSettings",
        "route": "effects",
        "routes": [
            "effects"
        ],
        "label": "Workspace Wraparound",
        "section": "Animations",
        "legacyPage": "Hyprland",
        "legacySections": [
            "Animations"
        ],
        "keywords": "Config.options.hyprland.animations.workspaceWraparound"
    },
    {
        "id": "HyprlandSettings.custom-editor-advanced",
        "source": "HyprlandSettings",
        "route": "effects",
        "routes": [
            "effects"
        ],
        "label": "Custom Editor (advanced)",
        "section": "Animations",
        "legacyPage": "Hyprland",
        "legacySections": [
            "Animations"
        ],
        "keywords": "Config.options.hyprland.animations.customEnabled"
    },
    {
        "id": "HyprlandSettings.presets",
        "source": "HyprlandSettings",
        "route": "effects",
        "routes": [
            "effects"
        ],
        "label": "Presets",
        "section": "Animations",
        "legacyPage": "Hyprland",
        "legacySections": [
            "Animations"
        ],
        "keywords": "Config.options.hyprland.animations.customEnabled Config.options.hyprland.animations.animation"
    },
    {
        "id": "HyprlandSettings.add-4",
        "source": "HyprlandSettings",
        "route": "effects",
        "routes": [
            "effects"
        ],
        "label": "Add",
        "section": "Curves (bezier / spring)",
        "legacyPage": "Hyprland",
        "legacySections": [
            "Animations",
            "Curves (bezier / spring)"
        ],
        "keywords": "Config.options.hyprland.animations.customCurves.slice Config.options.hyprland.animations.customCurves"
    },
    {
        "id": "HyprlandSettings.load-preset-into-custom",
        "source": "HyprlandSettings",
        "route": "effects",
        "routes": [
            "effects"
        ],
        "label": "Load Preset Into Custom",
        "section": "Curves (bezier / spring)",
        "legacyPage": "Hyprland",
        "legacySections": [
            "Animations",
            "Curves (bezier / spring)"
        ],
        "keywords": "Config.options.hyprland.animations.customCurves Config.options.hyprland.animations.customAnims"
    },
    {
        "id": "HyprlandSettings.apply-custom",
        "source": "HyprlandSettings",
        "route": "effects",
        "routes": [
            "effects"
        ],
        "label": "Apply Custom",
        "section": "Curves (bezier / spring)",
        "legacyPage": "Hyprland",
        "legacySections": [
            "Animations",
            "Curves (bezier / spring)"
        ],
        "keywords": ""
    },
    {
        "id": "HyprlandSettings.add-leaf",
        "source": "HyprlandSettings",
        "route": "effects",
        "routes": [
            "effects"
        ],
        "label": "Add leaf",
        "section": "Animation Tree (inherits parent if unset)",
        "legacyPage": "Hyprland",
        "legacySections": [
            "Animations",
            "Animation Tree (inherits parent if unset)"
        ],
        "keywords": "Config.options.hyprland.animations.customAnims.slice Config.options.hyprland.animations.customAnims"
    },
    {
        "id": "HyprlandSettings.animations",
        "source": "HyprlandSettings",
        "route": "effects",
        "routes": [
            "effects"
        ],
        "label": "Animations",
        "section": "Animations",
        "legacyPage": "Hyprland",
        "legacySections": [
            "Animations"
        ],
        "keywords": ""
    },
    {
        "id": "NiriSettings.nirisettings",
        "source": "NiriSettings",
        "route": "system",
        "routes": [
            "system"
        ],
        "label": "NiriSettings",
        "section": "NiriSettings",
        "legacyPage": "Niri",
        "legacySections": [],
        "keywords": ""
    },
    {
        "id": "NiriSettings.nirisettings-2",
        "source": "NiriSettings",
        "route": "system",
        "routes": [
            "system"
        ],
        "label": "NiriSettings",
        "section": "NiriSettings",
        "legacyPage": "Niri",
        "legacySections": [],
        "keywords": ""
    },
    {
        "id": "NiriSettings.arrange-displays",
        "source": "NiriSettings",
        "route": "devices",
        "routes": [
            "devices"
        ],
        "label": "Arrange displays",
        "section": "Displays",
        "legacyPage": "Niri",
        "legacySections": [
            "Displays"
        ],
        "keywords": ""
    },
    {
        "id": "NiriSettings.enabled",
        "source": "NiriSettings",
        "route": "devices",
        "routes": [
            "devices"
        ],
        "label": "Enabled",
        "section": "",
        "legacyPage": "Niri",
        "legacySections": [
            "Displays",
            ""
        ],
        "keywords": ""
    },
    {
        "id": "NiriSettings.orientation",
        "source": "NiriSettings",
        "route": "devices",
        "routes": [
            "devices"
        ],
        "label": "Orientation",
        "section": "",
        "legacyPage": "Niri",
        "legacySections": [
            "Displays",
            ""
        ],
        "keywords": ""
    },
    {
        "id": "NiriSettings.variable-refresh-rate-vrr",
        "source": "NiriSettings",
        "route": "devices",
        "routes": [
            "devices"
        ],
        "label": "Variable refresh rate (VRR)",
        "section": "",
        "legacyPage": "Niri",
        "legacySections": [
            "Displays",
            ""
        ],
        "keywords": ""
    },
    {
        "id": "NiriSettings.scale",
        "source": "NiriSettings",
        "route": "devices",
        "routes": [
            "devices"
        ],
        "label": "Scale",
        "section": "",
        "legacyPage": "Niri",
        "legacySections": [
            "Displays",
            ""
        ],
        "keywords": ""
    },
    {
        "id": "NiriSettings.position-x",
        "source": "NiriSettings",
        "route": "window-rules",
        "routes": [
            "window-rules"
        ],
        "label": "Position X",
        "section": "",
        "legacyPage": "Niri",
        "legacySections": [
            "Displays",
            ""
        ],
        "keywords": ""
    },
    {
        "id": "NiriSettings.position-y",
        "source": "NiriSettings",
        "route": "window-rules",
        "routes": [
            "window-rules"
        ],
        "label": "Position Y",
        "section": "",
        "legacyPage": "Niri",
        "legacySections": [
            "Displays",
            ""
        ],
        "keywords": ""
    },
    {
        "id": "NiriSettings.gaps",
        "source": "NiriSettings",
        "route": "devices",
        "routes": [
            "devices"
        ],
        "label": "Gaps",
        "section": "Layout",
        "legacyPage": "Niri",
        "legacySections": [
            "Layout"
        ],
        "keywords": "NiriConfig.options.layout.gaps"
    },
    {
        "id": "NiriSettings.center-focused-column",
        "source": "NiriSettings",
        "route": "window-rules",
        "routes": [
            "window-rules"
        ],
        "label": "Center focused column",
        "section": "Layout",
        "legacyPage": "Niri",
        "legacySections": [
            "Layout"
        ],
        "keywords": "NiriConfig.options.layout.centerFocusedColumn"
    },
    {
        "id": "NiriSettings.default-column-width",
        "source": "NiriSettings",
        "route": "window-rules",
        "routes": [
            "window-rules"
        ],
        "label": "Default column width",
        "section": "Layout",
        "legacyPage": "Niri",
        "legacySections": [
            "Layout"
        ],
        "keywords": "NiriConfig.options.layout.defaultColumnWidth"
    },
    {
        "id": "NiriSettings.keyboard-layout",
        "source": "NiriSettings",
        "route": "devices",
        "routes": [
            "devices"
        ],
        "label": "Keyboard layout",
        "section": "Keyboard",
        "legacyPage": "Niri",
        "legacySections": [
            "Input",
            "Keyboard"
        ],
        "keywords": "NiriConfig.options.input.kbLayout"
    },
    {
        "id": "NiriSettings.numlock-by-default",
        "source": "NiriSettings",
        "route": "devices",
        "routes": [
            "devices"
        ],
        "label": "Numlock by default",
        "section": "Keyboard",
        "legacyPage": "Niri",
        "legacySections": [
            "Input",
            "Keyboard"
        ],
        "keywords": "NiriConfig.options.input.numlock"
    },
    {
        "id": "NiriSettings.repeat-delay-ms",
        "source": "NiriSettings",
        "route": "input-details",
        "routes": [
            "input-details"
        ],
        "label": "Repeat delay (ms)",
        "section": "Keyboard",
        "legacyPage": "Niri",
        "legacySections": [
            "Input",
            "Keyboard"
        ],
        "keywords": "NiriConfig.options.input.repeatDelay"
    },
    {
        "id": "NiriSettings.repeat-rate",
        "source": "NiriSettings",
        "route": "input-details",
        "routes": [
            "input-details"
        ],
        "label": "Repeat rate",
        "section": "Keyboard",
        "legacyPage": "Niri",
        "legacySections": [
            "Input",
            "Keyboard"
        ],
        "keywords": "NiriConfig.options.input.repeatRate"
    },
    {
        "id": "NiriSettings.focus-follows-mouse",
        "source": "NiriSettings",
        "route": "input-details",
        "routes": [
            "input-details"
        ],
        "label": "Focus follows mouse",
        "section": "Keyboard",
        "legacyPage": "Niri",
        "legacySections": [
            "Input",
            "Keyboard"
        ],
        "keywords": "NiriConfig.options.input.focusFollowsMouse"
    },
    {
        "id": "NiriSettings.tap-to-click",
        "source": "NiriSettings",
        "route": "devices",
        "routes": [
            "devices"
        ],
        "label": "Tap to click",
        "section": "Touchpad",
        "legacyPage": "Niri",
        "legacySections": [
            "Input",
            "Touchpad"
        ],
        "keywords": "NiriConfig.options.input.touchpad.tap"
    },
    {
        "id": "NiriSettings.natural-scroll",
        "source": "NiriSettings",
        "route": "devices",
        "routes": [
            "devices"
        ],
        "label": "Natural scroll",
        "section": "Touchpad",
        "legacyPage": "Niri",
        "legacySections": [
            "Input",
            "Touchpad"
        ],
        "keywords": "NiriConfig.options.input.touchpad.naturalScroll"
    },
    {
        "id": "NiriSettings.disable-while-typing",
        "source": "NiriSettings",
        "route": "devices",
        "routes": [
            "devices"
        ],
        "label": "Disable while typing",
        "section": "Touchpad",
        "legacyPage": "Niri",
        "legacySections": [
            "Input",
            "Touchpad"
        ],
        "keywords": "NiriConfig.options.input.touchpad.disableWhileTyping"
    },
    {
        "id": "NiriSettings.scroll-factor",
        "source": "NiriSettings",
        "route": "input-details",
        "routes": [
            "input-details"
        ],
        "label": "Scroll factor",
        "section": "Touchpad",
        "legacyPage": "Niri",
        "legacySections": [
            "Input",
            "Touchpad"
        ],
        "keywords": "NiriConfig.options.input.touchpad.scrollFactor"
    },
    {
        "id": "NiriSettings.acceleration-speed",
        "source": "NiriSettings",
        "route": "devices",
        "routes": [
            "devices"
        ],
        "label": "Acceleration speed",
        "section": "Touchpad",
        "legacyPage": "Niri",
        "legacySections": [
            "Input",
            "Touchpad"
        ],
        "keywords": "NiriConfig.options.input.touchpad.accelSpeed"
    },
    {
        "id": "NiriSettings.natural-scroll-2",
        "source": "NiriSettings",
        "route": "devices",
        "routes": [
            "devices"
        ],
        "label": "Natural scroll",
        "section": "Mouse",
        "legacyPage": "Niri",
        "legacySections": [
            "Input",
            "Mouse"
        ],
        "keywords": "NiriConfig.options.input.mouse.naturalScroll"
    },
    {
        "id": "NiriSettings.acceleration-speed-2",
        "source": "NiriSettings",
        "route": "devices",
        "routes": [
            "devices"
        ],
        "label": "Acceleration speed",
        "section": "Mouse",
        "legacyPage": "Niri",
        "legacySections": [
            "Input",
            "Mouse"
        ],
        "keywords": "NiriConfig.options.input.mouse.accelSpeed"
    },
    {
        "id": "NiriSettings.window-rounding",
        "source": "NiriSettings",
        "route": "effects",
        "routes": [
            "effects"
        ],
        "label": "Window Rounding",
        "section": "Visual & Aesthetics",
        "legacyPage": "Niri",
        "legacySections": [
            "Visual & Aesthetics"
        ],
        "keywords": "NiriConfig.options.decoration.rounding"
    },
    {
        "id": "NiriSettings.border",
        "source": "NiriSettings",
        "route": "effects",
        "routes": [
            "effects"
        ],
        "label": "Border",
        "section": "Visual & Aesthetics",
        "legacyPage": "Niri",
        "legacySections": [
            "Visual & Aesthetics"
        ],
        "keywords": "NiriConfig.options.decoration.border.enable"
    },
    {
        "id": "NiriSettings.border-size",
        "source": "NiriSettings",
        "route": "effects",
        "routes": [
            "effects"
        ],
        "label": "Border Size",
        "section": "Visual & Aesthetics",
        "legacyPage": "Niri",
        "legacySections": [
            "Visual & Aesthetics"
        ],
        "keywords": "NiriConfig.options.decoration.border.width"
    },
    {
        "id": "NiriSettings.focus-ring",
        "source": "NiriSettings",
        "route": "effects",
        "routes": [
            "effects"
        ],
        "label": "Focus ring",
        "section": "Visual & Aesthetics",
        "legacyPage": "Niri",
        "legacySections": [
            "Visual & Aesthetics"
        ],
        "keywords": "NiriConfig.options.decoration.focusRing.enable"
    },
    {
        "id": "NiriSettings.focus-ring-width",
        "source": "NiriSettings",
        "route": "effects",
        "routes": [
            "effects"
        ],
        "label": "Focus ring width",
        "section": "Visual & Aesthetics",
        "legacyPage": "Niri",
        "legacySections": [
            "Visual & Aesthetics"
        ],
        "keywords": "NiriConfig.options.decoration.focusRing.width"
    },
    {
        "id": "NiriSettings.shadows",
        "source": "NiriSettings",
        "route": "effects",
        "routes": [
            "effects"
        ],
        "label": "Shadows",
        "section": "Visual & Aesthetics",
        "legacyPage": "Niri",
        "legacySections": [
            "Visual & Aesthetics"
        ],
        "keywords": "NiriConfig.options.decoration.shadow.enable"
    },
    {
        "id": "NiriSettings.shadow-softness",
        "source": "NiriSettings",
        "route": "effects",
        "routes": [
            "effects"
        ],
        "label": "Shadow softness",
        "section": "Visual & Aesthetics",
        "legacyPage": "Niri",
        "legacySections": [
            "Visual & Aesthetics"
        ],
        "keywords": "NiriConfig.options.decoration.shadow.softness"
    },
    {
        "id": "NiriSettings.shadow-spread",
        "source": "NiriSettings",
        "route": "effects",
        "routes": [
            "effects"
        ],
        "label": "Shadow spread",
        "section": "Visual & Aesthetics",
        "legacyPage": "Niri",
        "legacySections": [
            "Visual & Aesthetics"
        ],
        "keywords": "NiriConfig.options.decoration.shadow.spread"
    },
    {
        "id": "NiriSettings.blur",
        "source": "NiriSettings",
        "route": "effects",
        "routes": [
            "effects"
        ],
        "label": "Blur",
        "section": "Blur",
        "legacyPage": "Niri",
        "legacySections": [
            "Visual & Aesthetics",
            "Blur"
        ],
        "keywords": "NiriConfig.options.decoration.blur.enable"
    },
    {
        "id": "NiriSettings.blur-passes",
        "source": "NiriSettings",
        "route": "effects",
        "routes": [
            "effects"
        ],
        "label": "Blur Passes",
        "section": "Blur",
        "legacyPage": "Niri",
        "legacySections": [
            "Visual & Aesthetics",
            "Blur"
        ],
        "keywords": "NiriConfig.options.decoration.blur.passes"
    },
    {
        "id": "NiriSettings.blur-offset",
        "source": "NiriSettings",
        "route": "effects",
        "routes": [
            "effects"
        ],
        "label": "Blur Offset",
        "section": "Blur",
        "legacyPage": "Niri",
        "legacySections": [
            "Visual & Aesthetics",
            "Blur"
        ],
        "keywords": "NiriConfig.options.decoration.blur.offset"
    },
    {
        "id": "NiriSettings.blur-noise",
        "source": "NiriSettings",
        "route": "effects",
        "routes": [
            "effects"
        ],
        "label": "Blur Noise (%)",
        "section": "Blur",
        "legacyPage": "Niri",
        "legacySections": [
            "Visual & Aesthetics",
            "Blur"
        ],
        "keywords": "NiriConfig.options.decoration.blur.noise"
    },
    {
        "id": "NiriSettings.blur-saturation",
        "source": "NiriSettings",
        "route": "effects",
        "routes": [
            "effects"
        ],
        "label": "Blur Saturation (%)",
        "section": "Blur",
        "legacyPage": "Niri",
        "legacySections": [
            "Visual & Aesthetics",
            "Blur"
        ],
        "keywords": "NiriConfig.options.decoration.blur.saturation"
    },
    {
        "id": "NiriSettings.cursor-size",
        "source": "NiriSettings",
        "route": "appearance",
        "routes": [
            "appearance"
        ],
        "label": "Cursor size",
        "section": "Cursor",
        "legacyPage": "Niri",
        "legacySections": [
            "Cursor"
        ],
        "keywords": "NiriConfig.options.cursor.size NiriConfig.options.cursor.theme"
    },
    {
        "id": "NiriSettings.hide-while-typing",
        "source": "NiriSettings",
        "route": "input-details",
        "routes": [
            "input-details"
        ],
        "label": "Hide while typing",
        "section": "Cursor",
        "legacyPage": "Niri",
        "legacySections": [
            "Cursor"
        ],
        "keywords": "NiriConfig.options.cursor.hideWhenTyping"
    },
    {
        "id": "NiriSettings.enable",
        "source": "NiriSettings",
        "route": "effects",
        "routes": [
            "effects"
        ],
        "label": "Enable",
        "section": "Animations",
        "legacyPage": "Niri",
        "legacySections": [
            "Animations"
        ],
        "keywords": "NiriConfig.options.animations.enable"
    },
    {
        "id": "NiriSettings.slowdown-10",
        "source": "NiriSettings",
        "route": "effects",
        "routes": [
            "effects"
        ],
        "label": "Slowdown (×10)",
        "section": "Animations",
        "legacyPage": "Niri",
        "legacySections": [
            "Animations"
        ],
        "keywords": "NiriConfig.options.animations.slowdown"
    },
    {
        "id": "Profile.avatar-path",
        "source": "Profile",
        "route": "personal",
        "routes": [
            "personal"
        ],
        "label": "Avatar path",
        "section": "Avatar",
        "legacyPage": "Profile",
        "legacySections": [
            "Avatar"
        ],
        "keywords": "Config.options.profile.avatarPath"
    },
    {
        "id": "Profile.display-name",
        "source": "Profile",
        "route": "personal",
        "routes": [
            "personal"
        ],
        "label": "Display name",
        "section": "Identity",
        "legacyPage": "Profile",
        "legacySections": [
            "Avatar",
            "Identity"
        ],
        "keywords": "Config.options.profile.displayName"
    },
    {
        "id": "Profile.hostname",
        "source": "Profile",
        "route": "system",
        "routes": [
            "system"
        ],
        "label": "Hostname",
        "section": "Identity",
        "legacyPage": "Profile",
        "legacySections": [
            "Avatar",
            "Identity"
        ],
        "keywords": ""
    },
    {
        "id": "Profile.description-text",
        "source": "Profile",
        "route": "personal",
        "routes": [
            "personal"
        ],
        "label": "Description text",
        "section": "Identity",
        "legacyPage": "Profile",
        "legacySections": [
            "Avatar",
            "Identity"
        ],
        "keywords": "Config.options.profile.descriptionText"
    },
    {
        "id": "Profile.save-as",
        "source": "Profile",
        "route": "personal",
        "routes": [
            "personal"
        ],
        "label": "Save as",
        "section": "Presets",
        "legacyPage": "Profile",
        "legacySections": [
            "Presets"
        ],
        "keywords": ""
    },
    {
        "id": "KeybindsConfig.actions-and-shortcuts-2",
        "source": "KeybindsConfig",
        "route": "devices",
        "routes": [
            "devices",
            "input-details"
        ],
        "label": "Actions and shortcuts",
        "section": "Actions and shortcuts",
        "legacyPage": "Keybinds",
        "legacySections": [],
        "keywords": ""
    },
    {
        "id": "GeneralConfig.interface-language",
        "source": "GeneralConfig",
        "route": "personal",
        "routes": [
            "personal"
        ],
        "label": "Interface Language",
        "section": "Language",
        "legacyPage": "General",
        "legacySections": [
            "Language"
        ],
        "keywords": ""
    },
    {
        "id": "GeneralConfig.arabic-mode",
        "source": "GeneralConfig",
        "route": "personal",
        "routes": [
            "personal"
        ],
        "label": "Arabic mode",
        "section": "Language",
        "legacyPage": "General",
        "legacySections": [
            "Language"
        ],
        "keywords": "Config.options.language.ui ar_EG arabic العربية"
    },
    {
        "id": "BackgroundConfig.transitions",
        "source": "BackgroundConfig",
        "route": "widget-details",
        "routes": [
            "widget-details"
        ],
        "label": "Transitions",
        "section": "Wallpaper",
        "legacyPage": "Desktop",
        "legacySections": [
            "Wallpaper"
        ],
        "keywords": ""
    },
    {
        "id": "BackgroundConfig.centered-wallpaper-shape",
        "source": "BackgroundConfig",
        "route": "widget-details",
        "routes": [
            "widget-details"
        ],
        "label": "Centered wallpaper shape",
        "section": "Centered wallpaper",
        "legacyPage": "Desktop",
        "legacySections": [
            "Wallpaper",
            "Centered wallpaper"
        ],
        "keywords": ""
    },
    {
        "id": "BackgroundConfig.custom-image-shape",
        "source": "BackgroundConfig",
        "route": "widgets",
        "routes": [
            "widgets"
        ],
        "label": "Custom image shape",
        "section": "Custom Image",
        "legacyPage": "Desktop",
        "legacySections": [
            "Custom Image"
        ],
        "keywords": ""
    },
    {
        "id": "BarConfig.hotspot-ssid",
        "source": "BarConfig",
        "route": "integrations",
        "routes": [
            "integrations"
        ],
        "label": "Hotspot SSID",
        "section": "Quick actions",
        "legacyPage": "Bar",
        "legacySections": [
            "Quick Actions Options"
        ],
        "keywords": ""
    },
    {
        "id": "BarConfig.hotspot-password",
        "source": "BarConfig",
        "route": "integrations",
        "routes": [
            "integrations"
        ],
        "label": "Hotspot password",
        "section": "Quick actions",
        "legacyPage": "Bar",
        "legacySections": [
            "Quick Actions Options"
        ],
        "keywords": ""
    },
    {
        "id": "BarConfig.popup-position",
        "source": "BarConfig",
        "route": "notifications",
        "routes": [
            "notifications"
        ],
        "label": "Popup position",
        "section": "Notifications",
        "legacyPage": "Bar",
        "legacySections": [
            "Notifications"
        ],
        "keywords": ""
    },
    {
        "id": "InterfaceConfig.palette-type",
        "source": "InterfaceConfig",
        "route": "effects",
        "routes": [
            "effects"
        ],
        "label": "Palette Type",
        "section": "Palette",
        "legacyPage": "Interface",
        "legacySections": [
            "Appearance",
            "Palette"
        ],
        "keywords": ""
    },
    {
        "id": "InterfaceConfig.top-left-action",
        "source": "InterfaceConfig",
        "route": "devices",
        "routes": [
            "devices"
        ],
        "label": "Top-left action",
        "section": "Top",
        "legacyPage": "Interface",
        "legacySections": [
            "Hot Corners",
            "Top"
        ],
        "keywords": ""
    },
    {
        "id": "InterfaceConfig.top-right-action",
        "source": "InterfaceConfig",
        "route": "devices",
        "routes": [
            "devices"
        ],
        "label": "Top-right action",
        "section": "Top",
        "legacyPage": "Interface",
        "legacySections": [
            "Hot Corners",
            "Top"
        ],
        "keywords": ""
    },
    {
        "id": "InterfaceConfig.bottom-left",
        "source": "InterfaceConfig",
        "route": "devices",
        "routes": [
            "devices"
        ],
        "label": "Bottom-left",
        "section": "Bottom",
        "legacyPage": "Interface",
        "legacySections": [
            "Hot Corners",
            "Bottom"
        ],
        "keywords": ""
    },
    {
        "id": "InterfaceConfig.bottom-right",
        "source": "InterfaceConfig",
        "route": "devices",
        "routes": [
            "devices"
        ],
        "label": "Bottom-right",
        "section": "Bottom",
        "legacyPage": "Interface",
        "legacySections": [
            "Hot Corners",
            "Bottom"
        ],
        "keywords": ""
    },
    {
        "id": "InterfaceConfig.launcher-position",
        "source": "InterfaceConfig",
        "route": "panels",
        "routes": [
            "panels"
        ],
        "label": "Launcher Position",
        "section": "Overview",
        "legacyPage": "Interface",
        "legacySections": [
            "Overview"
        ],
        "keywords": ""
    },
    {
        "id": "InterfaceConfig.system-icon-theme",
        "source": "InterfaceConfig",
        "route": "appearance",
        "routes": [
            "appearance"
        ],
        "label": "System icon theme",
        "section": "System themes",
        "legacyPage": "Interface",
        "legacySections": [
            "System themes"
        ],
        "keywords": ""
    },
    {
        "id": "InterfaceConfig.mouse-cursor-theme",
        "source": "InterfaceConfig",
        "route": "appearance",
        "routes": [
            "appearance"
        ],
        "label": "Mouse cursor theme",
        "section": "System themes",
        "legacyPage": "Interface",
        "legacySections": [
            "System themes"
        ],
        "keywords": ""
    },
    {
        "id": "InterfaceConfig.primary-lock-controls-monitor",
        "source": "InterfaceConfig",
        "route": "session-details",
        "routes": [
            "session-details"
        ],
        "label": "Primary lock-controls monitor",
        "section": "Lock screen",
        "legacyPage": "Interface",
        "legacySections": [
            "Lock screen"
        ],
        "keywords": ""
    },
    {
        "id": "ServicesConfig.codec",
        "source": "ServicesConfig",
        "route": "capture-details",
        "routes": [
            "capture-details"
        ],
        "label": "Codec",
        "section": "Screen recording",
        "legacyPage": "Services",
        "legacySections": [
            "Capture quality",
            "Screen recording"
        ],
        "keywords": ""
    },
    {
        "id": "HyprlandSettings.resolution-refresh-rate",
        "source": "HyprlandSettings",
        "route": "devices",
        "routes": [
            "devices"
        ],
        "label": "Resolution & Refresh Rate",
        "section": "",
        "legacyPage": "Hyprland",
        "legacySections": [
            "Displays",
            ""
        ],
        "keywords": ""
    },
    {
        "id": "HyprlandSettings.mirror",
        "source": "HyprlandSettings",
        "route": "window-rules",
        "routes": [
            "window-rules"
        ],
        "label": "Mirror",
        "section": "Advanced Monitor Settings",
        "legacyPage": "Hyprland",
        "legacySections": [
            "Displays",
            "",
            "Advanced Monitor Settings"
        ],
        "keywords": ""
    },
    {
        "id": "HyprlandSettings.color-management",
        "source": "HyprlandSettings",
        "route": "window-rules",
        "routes": [
            "window-rules"
        ],
        "label": "Color Management",
        "section": "Advanced Monitor Settings",
        "legacyPage": "Hyprland",
        "legacySections": [
            "Displays",
            "",
            "Advanced Monitor Settings"
        ],
        "keywords": ""
    },
    {
        "id": "HyprlandSettings.layout-switch-shortcut",
        "source": "HyprlandSettings",
        "route": "devices",
        "routes": [
            "devices"
        ],
        "label": "Layout switch shortcut",
        "section": "Keyboard",
        "legacyPage": "Hyprland",
        "legacySections": [
            "Input",
            "Keyboard"
        ],
        "keywords": ""
    },
    {
        "id": "HyprlandSettings.accel-profile",
        "source": "HyprlandSettings",
        "route": "input-details",
        "routes": [
            "input-details"
        ],
        "label": "Accel Profile",
        "section": "Mouse & Input",
        "legacyPage": "Hyprland",
        "legacySections": [
            "Input",
            "Mouse & Input"
        ],
        "keywords": ""
    },
    {
        "id": "HyprlandSettings.custom-shortcuts-lua",
        "source": "HyprlandSettings",
        "route": "input-details",
        "routes": [
            "input-details"
        ],
        "label": "Custom shortcuts (Lua)",
        "section": "Custom Binds (Advanced)",
        "legacyPage": "Hyprland",
        "legacySections": [
            "Custom Binds (Advanced)"
        ],
        "keywords": ""
    },
    {
        "id": "HyprlandSettings.custom-window-rules-lua",
        "source": "HyprlandSettings",
        "route": "window-rules",
        "routes": [
            "window-rules"
        ],
        "label": "Custom window rules (Lua)",
        "section": "Custom Window Rules (Advanced)",
        "legacyPage": "Hyprland",
        "legacySections": [
            "Custom Window Rules (Advanced)"
        ],
        "keywords": ""
    },
    {
        "id": "NiriSettings.resolution-refresh-rate",
        "source": "NiriSettings",
        "route": "devices",
        "routes": [
            "devices"
        ],
        "label": "Resolution & Refresh Rate",
        "section": "",
        "legacyPage": "Niri",
        "legacySections": [
            "Displays",
            ""
        ],
        "keywords": ""
    },
    {
        "id": "NiriSettings.cursor-theme",
        "source": "NiriSettings",
        "route": "appearance",
        "routes": [
            "appearance"
        ],
        "label": "Cursor theme",
        "section": "Cursor",
        "legacyPage": "Niri",
        "legacySections": [
            "Cursor"
        ],
        "keywords": ""
    },
    {
        "id": "BackgroundConfig.show-quote",
        "source": "BackgroundConfig",
        "route": "widgets",
        "routes": [
            "widgets"
        ],
        "label": "Show quote",
        "section": "Quote",
        "legacyPage": "Desktop",
        "legacySections": [
            "Clock",
            "Quote"
        ],
        "keywords": "Config.options.background.widgets.clock.quote.enable"
    },
    {
        "id": "SystemUsers.accounts",
        "source": "SystemUsers",
        "route": "users",
        "routes": [
            "users"
        ],
        "label": "Users",
        "section": "Users",
        "legacyPage": "Users",
        "legacySections": [],
        "keywords": "users login accounts sudo fingerprint face sddm password"
    },
    {
        "id": "SystemUsers.biometrics",
        "source": "SystemUsers",
        "route": "users",
        "routes": [
            "users"
        ],
        "label": "Fingerprints & face",
        "section": "Fingerprints & face",
        "legacyPage": "Users",
        "legacySections": [],
        "keywords": "users login accounts sudo fingerprint face sddm password"
    },
    {
        "id": "SystemUsers.new-account",
        "source": "SystemUsers",
        "route": "users",
        "routes": [
            "users"
        ],
        "label": "Add account",
        "section": "Add account",
        "legacyPage": "Users",
        "legacySections": [],
        "keywords": "users login accounts sudo fingerprint face sddm password"
    },
    {
        "id": "SystemUsers.remove-account",
        "source": "SystemUsers",
        "route": "users",
        "routes": [
            "users"
        ],
        "label": "Remove account",
        "section": "Remove account",
        "legacyPage": "Users",
        "legacySections": [],
        "keywords": "users login accounts sudo fingerprint face sddm password"
    },
    {
        "id": "SystemUsers.login-screen",
        "source": "SystemUsers",
        "route": "login",
        "routes": [
            "login"
        ],
        "label": "Login screen",
        "section": "Login screen",
        "legacyPage": "Users",
        "legacySections": [],
        "keywords": "users login accounts sudo fingerprint face sddm password"
    },
    {
        "id": "SystemUsers.authentication",
        "source": "SystemUsers",
        "route": "login",
        "routes": [
            "login"
        ],
        "label": "Authentication methods",
        "section": "Authentication methods",
        "legacyPage": "Users",
        "legacySections": [],
        "keywords": "users login accounts sudo fingerprint face sddm password"
    }
];
