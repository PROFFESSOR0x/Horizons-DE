pragma Singleton
pragma ComponentBehavior: Bound

import qs
import qs.services
import qs.modules.common
import QtQuick
import Quickshell
import Quickshell.Io

/**
 * Automatically reloads generated material colors.
 * It is necessary to run reapplyTheme() on startup because Singletons are lazily loaded.
 */
Singleton {
    id: root
    property string filePath: Directories.generatedMaterialThemePath

    function reapplyTheme() {
        themeFileView.reload()
    }

    function applyColors(fileContent) {
        let json
        try {
            json = JSON.parse(fileContent)
        } catch (error) {
            console.log("[MaterialThemeLoader] Ignoring invalid color theme: " + error)
            return
        }
        if (!json || typeof json !== "object" || Array.isArray(json)) {
            console.log("[MaterialThemeLoader] Ignoring color theme with an invalid shape")
            return
        }
        for (const key in json) {
            if (json.hasOwnProperty(key)) {
                // Convert snake_case to CamelCase
                const camelCaseKey = key.replace(/_([a-z])/g, (g) => g[1].toUpperCase())
                const m3Key = `m3${camelCaseKey}`
                Appearance.m3colors[m3Key] = json[key]
            }
        }
        Appearance.m3colors.darkmode = (Appearance.m3colors.m3background.hslLightness < 0.5)

        // Keep compositor borders in sync with wallpaper-generated colours.
        // This is intentionally opt-in because some users manage borders in
        // an external Hyprland include.
        if (WM.compositor === "hyprland" && Config.options.hyprland.general.autoThemeBorders) {
            const active = "rgb(" + Appearance.colors.colPrimary.toString().replace("#", "").substring(0, 6) + ")"
            const inactive = "rgb(" + Appearance.colors.colOutlineVariant.toString().replace("#", "").substring(0, 6) + ")"
            Config.options.hyprland.general.colActiveBorder = active
            Config.options.hyprland.general.colInactiveBorder = inactive
            HyprlandConfig.set("general:col.active_border", active)
            HyprlandConfig.set("general:col.inactive_border", inactive)
        }
    }

    function resetFilePathNextTime() {
        resetFilePathNextWallpaperChange.enabled = true
    }

    function useLockTheme() {
        root.filePath = ""
        root.filePath = Directories.generatedLockMaterialThemePath
    }

    function useLiveTheme() {
        root.filePath = ""
        root.filePath = Directories.generatedMaterialThemePath
    }

    Connections {
        id: resetFilePathNextWallpaperChange
        enabled: false
        target: Config.options.background
        function onWallpaperPathChanged() {
            root.filePath = ""
            root.filePath = Directories.generatedMaterialThemePath
            resetFilePathNextWallpaperChange.enabled = false
        }
    }

    Timer {
        id: delayedFileRead
        interval: Config.options?.hacks?.arbitraryRaceConditionDelay ?? 100
        repeat: false
        running: false
        onTriggered: {
            root.applyColors(themeFileView.text())
        }
    }

    FileView {
        id: themeFileView
        path: Qt.resolvedUrl(root.filePath)
        watchChanges: true
        onFileChanged: {
            this.reload()
            delayedFileRead.start()
        }
        onLoadedChanged: {
            const fileContent = themeFileView.text()
            root.applyColors(fileContent)
        }
        onLoadFailed: root.resetFilePathNextTime();
    }
}
