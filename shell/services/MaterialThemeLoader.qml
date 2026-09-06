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

    // Content of the last theme that was actually pushed into
    // Appearance.m3colors. A single colour-scheme switch reaches applyColors()
    // twice - once through FileView's onLoadedChanged and once more through
    // the onFileChanged -> delayedFileRead timer below (which exists for a
    // race where the file is still half-written on the first read) - and each
    // pass re-assigns every m3* property, so every binding in the shell
    // re-evaluated twice per switch. That double cascade is what made
    // switching schemes visibly hitch. Re-applying an identical theme is a
    // no-op, so the second pass is now dropped instead of paid for.
    property string lastAppliedContent: ""

    function applyColors(fileContent) {
        if (fileContent === root.lastAppliedContent) return
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
        root.lastAppliedContent = fileContent
        for (const key in json) {
            if (json.hasOwnProperty(key)) {
                // Convert snake_case to CamelCase
                const camelCaseKey = key.replace(/_([a-z])/g, (g) => g[1].toUpperCase())
                const m3Key = `m3${camelCaseKey}`
                // Skip colours that didn't actually change. Two generated
                // themes usually share a good number of them, and every real
                // assignment re-runs every binding that reads it.
                if (String(Appearance.m3colors[m3Key]).toLowerCase() === String(json[key]).toLowerCase()) continue
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
            // Batched: concurrent hyprconfigurator.py runs race on the same file.
            HyprlandConfig.setMany({
                "general:col.active_border": active,
                "general:col.inactive_border": inactive,
            })
        }
    }

    function resetFilePathNextTime() {
        resetFilePathNextWallpaperChange.enabled = true
    }

    function useLockTheme() {
        root.lastAppliedContent = ""
        root.filePath = ""
        root.filePath = Directories.generatedLockMaterialThemePath
    }

    function useLiveTheme() {
        root.lastAppliedContent = ""
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
