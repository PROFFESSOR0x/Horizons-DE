//@ pragma UseQApplication
//@ pragma Env QS_NO_RELOAD_POPUP=1
//@ pragma Env QT_QUICK_CONTROLS_STYLE=Basic
//@ pragma Env QT_QUICK_FLICKABLE_WHEEL_DECELERATION=10000
// Remove two slashes below and adjust the value to change the UI scale
////@ pragma Env QT_SCALE_FACTOR=1
import "modules/common"
import "services"
import "panelFamilies"
import QtQuick
import QtQuick.Window
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

ShellRoot {
    id: root

    ReloadPopup {}

    Process {
        id: autostartProc
        command: ["python3", `${Directories.scriptPath}/hyprland/autostart.py`]
    }

    Connections {
        target: Config
        function onReadyChanged() {
            if (!Config.ready) return

            if (WM.compositor === "niri") {
                Config.options.background.lockWall = ""
                Config.options.overview.enable = false
            }

            if (WM.compositor === "hyprland" &&
                Config.options.hyprland.autostartApps.enable &&
                Config.options.hyprland.autostartApps.apps.length > 0) {
                autostartProc.running = true
            }
        }
    }

    Component.onCompleted: {
        Logger.log("Shell started, config: " + Config.filePath)
        MaterialThemeLoader.reapplyTheme()
        Hyprsunset.load()
        FirstRunExperience.load()
        ConflictKiller.load()
        Cliphist.refresh()
        Wallpapers.load()
        Updates.load()
        LyricsService.restartLyrics()
        // This is reached only after the new QML root and its startup services
        // exist, so it is the real hand-off point for an external reload splash.
        ReloadController.markReady()
    }
    
    PanelFamilyLoader {
        identifier: "ii"
        component: IllogicalImpulseFamily {}
    }

    component PanelFamilyLoader: LazyLoader {
        required property string identifier
        active: Config.ready && Config.options.panelFamily === identifier
    }
}
