import qs.modules.common
import qs.services
import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
pragma Singleton
pragma ComponentBehavior: Bound

Singleton {
    id: root
    signal requestBluetoothDialog()
    property bool barOpen: true
    property bool crosshairOpen: false
    property bool sidebarLeftOpen: false
    property bool sidebarRightOpen: false
    // A hot corner opens panels without a click.  Keep that origin so a sidebar
    // can close itself when the pointer leaves instead of staying latched open.
    property string hoverOpenedState: ""
    property bool mediaControlsOpen: false
    property bool osdBrightnessOpen: false
    property bool settingsOpen: false
    property bool keybindsOverlayOpen: false
    property bool osdVolumeOpen: false
    property bool oskOpen: false
    property bool overlayOpen: false
    property bool overviewOpen: false
    // Super+Tab's Workspaces/Windows switcher (WindowSwitcher.qml) - separate
    // from overviewOpen (the app search/launcher, tap-Super) on purpose: they
    // used to share one panel, stacked directly under the search box, which
    // looked like one merged surface with nothing to do with searching.
    property bool windowSwitcherOpen: false
    property bool regionSelectorOpen: false
    property bool captureEditorOpen: false
    property string captureEditorImagePath: ""
    property string captureEditorVideoPath: ""
    property bool searchOpen: false
    property bool screenLocked: false
    property bool screenLockContainsCharacters: false
    property bool screenUnlockFailed: false
    property bool screenTranslatorOpen: false
    property bool sessionOpen: false
    property bool superDown: false
    property bool superReleaseMightTrigger: true
    property bool wallpaperSelectorOpen: false
    property bool workspaceShowNumbers: false
    property string settingsPage: ""
    property Item currentPageInstance: null
    property list<real> visualizerPoints: []
    property bool desktopWidgetKeyboardFocus: false
    property bool desktopMenuOpen: false
    property var desktopMenuScreen: null
    property real desktopMenuX: 0
    property real desktopMenuY: 0
    property string wallpaperSelectorTarget: "wallpaper"
    property bool dropShelfOpen: false
    property real dropShelfX: 0
    property real dropShelfY: 0
    property bool workspacesHovered: false
    property var workspacesHoveredScreen: null
    property int workspacesHoveredIndex: -1
    property int workspacesHoveredId: -1

    readonly property var hotCornerOptions: [
        { displayName: Translation.tr("None"),                  value: "none" },
        { displayName: Translation.tr("Left Sidebar"),           value: "sidebarLeftOpen" },
        { displayName: Translation.tr("Right Sidebar"),          value: "sidebarRightOpen" },
        { displayName: Translation.tr("Overview Launcher"),               value: "overviewOpen" },
        { displayName: Translation.tr("Window Switcher"),        value: "windowSwitcherOpen" },
        { displayName: Translation.tr("Wallpaper Selector"),     value: "wallpaperSelectorOpen" },
        { displayName: Translation.tr("Media Controls"),         value: "mediaControlsOpen" },
        { displayName: Translation.tr("Overlay"),                value: "overlayOpen" },
        { displayName: Translation.tr("Bar"),                    value: "barOpen" },
        { displayName: Translation.tr("ScreenShot Region"),        value: "regionSelectorOpen" },
        { displayName: Translation.tr("Screen Translator"),      value: "screenTranslatorOpen" },
        { displayName: Translation.tr("On-screen Keyboard"),     value: "oskOpen" },
        { displayName: Translation.tr("Session Menu"),           value: "sessionOpen" },
        { displayName: Translation.tr("Settings"),               value: "settingsOpen" },
        { displayName: Translation.tr("Keybinds Cheatsheet"),    value: "keybindsOverlayOpen" },
        { displayName: Translation.tr("Application Search"),     value: "searchOpen" },
        { displayName: Translation.tr("Drop Shelf"),             value: "dropShelfOpen" },
        { displayName: Translation.tr("Crosshair"),              value: "crosshairOpen" }
    ]

    function toggleState(name) {
        if (!name || name === "none") return;
        if (root[name] === undefined) return;
        if (root.hoverOpenedState === name)
            root.hoverOpenedState = "";
        root[name] = !root[name];
    }

    function openFromHover(name) {
        if (!name || name === "none" || root[name] === undefined) return;
        root.hoverOpenedState = name;
        root[name] = true;
    }

    // Non-zero while something that lives *outside* a hover-opened panel's own
    // window is on screen on its behalf - today that's StyledComboBox's
    // dropdown. Qt renders those as their own surface, so the pointer moving
    // onto the dropdown leaves the panel's HoverHandler and the panel decides
    // the pointer left and closes itself, taking the dropdown with it (the
    // "right sidebar vanishes when I reach for an audio output device" bug).
    // Panels that auto-close on hover-out check this first.
    property int hoverCloseGuard: 0
    function pushHoverCloseGuard() { root.hoverCloseGuard++ }
    function popHoverCloseGuard() { root.hoverCloseGuard = Math.max(0, root.hoverCloseGuard - 1) }

    function closeHoverState(name) {
        if (root.hoverCloseGuard > 0) return;
        if (root.hoverOpenedState !== name) return;
        root.hoverOpenedState = "";
        root[name] = false;
    }
    
    onSidebarRightOpenChanged: {
        if (GlobalStates.sidebarRightOpen) {
            Notifications.timeoutAll();
            Notifications.markAllRead();
        }
    }

    Timer {
        id: barRefreshTimer
        interval: 200
        repeat: false
        onTriggered: {
            root.barOpen = true
        }
    }

    function refreshBar() {
        if (!root.barOpen) return;
        root.barOpen = false
        barRefreshTimer.restart()
    }

    CompositorGlobalShortcut {
        name: "workspaceNumber"
        description: "Hold to show workspace numbers, release to show icons"
        onPressed: { root.superDown = true }
        onReleased: { root.superDown = false }
    }

    IpcHandler {
        target: "background"
        function toggleCenteredWallpaper(): void {
            Config.options.background.centeredWallpaper = !Config.options.background.centeredWallpaper
        }
    }

     CompositorGlobalShortcut {
        name: "centeredWallpaperToggle"
        description: "Toggles centered wallpaper"
        onPressed: {
            Config.options.background.centeredWallpaper = !Config.options.background.centeredWallpaper
        }
    }
}
