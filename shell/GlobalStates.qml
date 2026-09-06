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
    // A non-locking, editable rendering of the lock screen used by Settings.
    // It never creates a session lock or captures keyboard input.
    property bool lockPreviewOpen: false
    property string lockInteractionScreenName: ""
    property bool lockPreviewRestoreBarOpen: true
    property var lockPreviewInitialWidgetPositions: ({})
    property bool screenLockContainsCharacters: false
    property bool screenUnlockFailed: false

    function copyLockWidgetPositions() {
        return JSON.parse(JSON.stringify(Config.options.lock.widgetPositions ?? {}))
    }

    function beginLockPreview() {
        if (root.lockPreviewOpen) return
        root.lockPreviewInitialWidgetPositions = root.copyLockWidgetPositions()
        root.lockPreviewRestoreBarOpen = root.barOpen
        root.lockPreviewOpen = true
        root.barOpen = false
        root.overviewOpen = false
        root.windowSwitcherOpen = false
        root.sidebarLeftOpen = false
        root.sidebarRightOpen = false
        root.mediaControlsOpen = false
    }

    function saveLockPreview() {
        root.lockPreviewOpen = false
        root.barOpen = root.lockPreviewRestoreBarOpen
    }

    function cancelLockPreview() {
        Config.options.lock.widgetPositions = root.lockPreviewInitialWidgetPositions
        root.saveLockPreview()
    }

    function resetLockWidgetLayout() {
        Config.options.lock.widgetPositions = ({})
    }

    function lockOutputNames() {
        return Quickshell.screens.map(screen => screen.name).filter(name => name !== "")
    }

    function primaryLockOutputName() {
        const configured = Config.options.lock.primaryMonitor ?? ""
        return configured !== "" ? configured : (Quickshell.screens[0]?.name ?? "")
    }

    function lockLayoutForOutput(outputName) {
        if (!Config.options.lock.perScreenLayout) return Config.options.lock.layout
        return Config.options.lock.layoutByScreen?.[outputName] ?? Config.options.lock.layout
    }

    function updateLockLayoutOffset(outputName, group, offsetX, offsetY) {
        if (!Config.options.lock.perScreenLayout) {
            Config.options.lock.layout[group].offsetX = offsetX
            Config.options.lock.layout[group].offsetY = offsetY
            return
        }
        const layouts = JSON.parse(JSON.stringify(Config.options.lock.layoutByScreen ?? {}))
        const base = lockLayoutForOutput(outputName)
        const layout = JSON.parse(JSON.stringify(base))
        layout[group].offsetX = offsetX
        layout[group].offsetY = offsetY
        layouts[outputName] = layout
        Config.options.lock.layoutByScreen = layouts
    }

    // Copy the complete live-editor design: all widget overrides and all three
    // lower control-bar offsets/scales. This is deliberately explicit rather
    // than assigning a shared object, so later edits remain independent.
    function applyLockDesignToOutput(sourceOutput, targetOutput) {
        if (!sourceOutput || !targetOutput || sourceOutput === targetOutput) return
        const positions = JSON.parse(JSON.stringify(Config.options.lock.widgetPositions ?? {}))
        for (const name of Object.keys(positions)) {
            const record = positions[name]
            const source = record.byScreen?.[sourceOutput] ?? record
            const overrides = Object.assign({}, record.byScreen ?? {})
            overrides[targetOutput] = JSON.parse(JSON.stringify(source))
            positions[name] = Object.assign({}, record, { byScreen: overrides })
        }
        Config.options.lock.widgetPositions = positions

        const layouts = JSON.parse(JSON.stringify(Config.options.lock.layoutByScreen ?? {}))
        const sourceLayout = layouts[sourceOutput] ?? Config.options.lock.layout
        layouts[targetOutput] = JSON.parse(JSON.stringify(sourceLayout))
        Config.options.lock.layoutByScreen = layouts
    }
    property bool screenTranslatorOpen: false
    property bool sessionOpen: false
    // A contextual entry point (currently Window Switcher) can request the
    // session actions as a right-edge sheet without overwriting the user's
    // normal session-screen presentation preference.
    property bool sessionForceRightEdge: false
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
    // Multi-selection is deliberately global so a workspace can be selected
    // from each monitor's bar before opening the contextual action menu.
    property list<var> workspaceSelection: []

    function workspaceKey(workspaceId, monitorName) {
        return String(monitorName ?? "") + "::" + String(workspaceId)
    }

    function workspaceSelectionContains(workspaceId, monitorName) {
        const key = root.workspaceKey(workspaceId, monitorName)
        return root.workspaceSelection.some(item => item.key === key)
    }

    function toggleWorkspaceSelection(workspaceId, monitorName) {
        const key = root.workspaceKey(workspaceId, monitorName)
        const copy = root.workspaceSelection.slice()
        const index = copy.findIndex(item => item.key === key)
        if (index >= 0) copy.splice(index, 1)
        else copy.push({ key: key, workspaceId: workspaceId, monitorName: monitorName })
        root.workspaceSelection = copy
    }

    function selectWorkspace(workspaceId, monitorName, additive) {
        if (!additive) root.workspaceSelection = []
        if (!root.workspaceSelectionContains(workspaceId, monitorName))
            root.toggleWorkspaceSelection(workspaceId, monitorName)
    }

    function selectedWorkspaces(fallbackWorkspaceId, fallbackMonitorName) {
        if (root.workspaceSelection.length > 0) return root.workspaceSelection.slice()
        return [{ key: root.workspaceKey(fallbackWorkspaceId, fallbackMonitorName), workspaceId: fallbackWorkspaceId, monitorName: fallbackMonitorName }]
    }

    function linkedWorkspaceMembers(workspaceId, monitorName) {
        const key = root.workspaceKey(workspaceId, monitorName)
        const groups = Config.options.workspaceLinking.groups ?? []
        const group = groups.find(entry => entry.indexOf(key) !== -1)
        if (!group) return []
        return group.map(linkKey => {
            const separator = linkKey.lastIndexOf("::")
            return {
                key: linkKey,
                monitorName: linkKey.slice(0, separator),
                workspaceId: Number(linkKey.slice(separator + 2))
            }
        })
    }

    function linkSelectedWorkspaces(fallbackWorkspaceId, fallbackMonitorName) {
        const selected = root.selectedWorkspaces(fallbackWorkspaceId, fallbackMonitorName)
        if (selected.length < 2) return
        const keys = selected.map(item => item.key)
        const retained = (Config.options.workspaceLinking.groups ?? []).filter(group => !group.some(key => keys.indexOf(key) !== -1))
        retained.push(keys)
        Config.options.workspaceLinking.groups = retained
        root.workspaceSelection = []
    }

    function detachWorkspace(workspaceId, monitorName) {
        const key = root.workspaceKey(workspaceId, monitorName)
        const next = []
        for (const group of (Config.options.workspaceLinking.groups ?? [])) {
            const remaining = group.filter(entry => entry !== key)
            if (remaining.length > 1) next.push(remaining)
        }
        Config.options.workspaceLinking.groups = next
        root.workspaceSelection = root.workspaceSelection.filter(item => item.key !== key)
    }

    function setUnifiedMultiMonitorWorkspaces(enabled) {
        Config.options.workspaceLinking.unifiedMultiMonitor = enabled
        if (!enabled) return

        // Build one logical group from the workspaces currently visible on
        // every real output. This does not invent compositor workspaces: it
        // links exactly the ones the compositor reports, so mixed DPI and
        // hot-plugged monitor layouts remain safe.
        const active = []
        for (const monitor of WM.monitors) {
            if (!monitor?.name) continue
            const workspace = WM.activeWorkspaceForMonitor(monitor.name)
            if (workspace?.id === undefined || workspace?.id === null) continue
            active.push(root.workspaceKey(workspace.id, monitor.name))
        }
        if (active.length > 1) {
            const kept = (Config.options.workspaceLinking.groups ?? [])
                .filter(group => !group.some(key => active.indexOf(key) !== -1))
            kept.push(active)
            Config.options.workspaceLinking.groups = kept
        }
    }

    function activateWorkspace(workspaceId, monitorName) {
        const linked = root.linkedWorkspaceMembers(workspaceId, monitorName)
        if (linked.length > 1) WM.switchWorkspacesOnMonitors(linked, monitorName)
        else WM.switchWorkspace(workspaceId)
    }

    function closeWorkspaceWindows(entries, force) {
        const selectedKeys = entries.map(item => root.workspaceKey(item.workspaceId, item.monitorName))
        for (const window of WM.windowList) {
            const key = root.workspaceKey(window.workspaceId, window.monitorName ?? "")
            // Non-Hyprland backends expose workspace ids but may not expose a
            // monitor on every window. Falling back to id keeps the action
            // useful there without widening it to unrelated workspaces.
            const matched = selectedKeys.indexOf(key) !== -1
                // Workspace identifiers are globally unique for the supported
                // backends. Use that stable identity if a backend did not
                // supply a matching monitor name on its window record.
                || entries.some(item => String(item.workspaceId) === String(window.workspaceId))
            if (matched) {
                if (force) WM.forceCloseWindow(window.id, window.pid)
                else WM.closeWindow(window.id)
            }
        }
    }

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

    onSessionOpenChanged: {
        if (!root.sessionOpen)
            root.sessionForceRightEdge = false
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
