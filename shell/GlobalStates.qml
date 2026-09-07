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
    property var lockPreviewInitialLayout: ({})
    property var lockPreviewInitialLayoutByScreen: ({})
    property bool lockPreviewInitialPerScreenLayout: false
    property bool lockPreviewInitialCenterClock: true
    property bool screenLockContainsCharacters: false
    property bool screenUnlockFailed: false

    function copyLockWidgetPositions() {
        return JSON.parse(JSON.stringify(Config.options.lock.widgetPositions ?? {}))
    }

    function lockPositionWithoutOverrides(record) {
        const value = JSON.parse(JSON.stringify(record ?? {}))
        delete value.byScreen
        return value
    }

    function applyLockLayout(layoutData) {
        const source = layoutData ?? ({})
        const target = Config.options.lock.layout
        target.passwordPlacement = source.passwordPlacement ?? "bottom"
        target.bottomMargin = source.bottomMargin ?? 20
        for (const name of ["password", "leftToolbar", "rightToolbar"]) {
            const value = source[name] ?? ({})
            target[name].offsetX = value.offsetX ?? 0
            target[name].offsetY = value.offsetY ?? 0
            target[name].scale = value.scale ?? 1.0
        }
    }

    function beginLockPreview() {
        if (root.lockPreviewOpen) return
        root.lockPreviewInitialWidgetPositions = root.copyLockWidgetPositions()
        root.lockPreviewInitialLayout = JSON.parse(JSON.stringify(Config.options.lock.layout ?? {}))
        root.lockPreviewInitialLayoutByScreen = JSON.parse(JSON.stringify(Config.options.lock.layoutByScreen ?? {}))
        root.lockPreviewInitialPerScreenLayout = Config.options.lock.perScreenLayout
        root.lockPreviewInitialCenterClock = Config.options.lock.centerClock
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
        root.applyLockLayout(root.lockPreviewInitialLayout)
        Config.options.lock.layoutByScreen = root.lockPreviewInitialLayoutByScreen
        Config.options.lock.perScreenLayout = root.lockPreviewInitialPerScreenLayout
        Config.options.lock.centerClock = root.lockPreviewInitialCenterClock
        root.saveLockPreview()
    }

    function resetLockWidgetLayout() {
        Config.options.lock.widgetPositions = ({})
        Config.options.lock.layoutByScreen = ({})
        Config.options.lock.perScreenLayout = false
        Config.options.lock.centerClock = true
        root.applyLockLayout({
            passwordPlacement: "bottom",
            bottomMargin: 20,
            password: { offsetX: 0, offsetY: 0, scale: 1.0 },
            leftToolbar: { offsetX: 0, offsetY: 0, scale: 1.0 },
            rightToolbar: { offsetX: 0, offsetY: 0, scale: 1.0 },
        })
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

    // Switching from the shared layout to a per-output layout is a migration,
    // not a reset. Seed the current output with the exact visual state so
    // "Apply other screen" can safely make independent copies from it.
    function ensurePerScreenLockLayout(sourceOutput) {
        if (Config.options.lock.perScreenLayout) return
        const source = sourceOutput || root.primaryLockOutputName()
        const positions = JSON.parse(JSON.stringify(Config.options.lock.widgetPositions ?? {}))
        for (const name of Object.keys(positions)) {
            const record = positions[name]
            const overrides = Object.assign({}, record.byScreen ?? {})
            const base = root.lockPositionWithoutOverrides(record)
            overrides[source] = JSON.parse(JSON.stringify(base))
            positions[name] = Object.assign({}, base, { byScreen: overrides })
        }
        const layouts = JSON.parse(JSON.stringify(Config.options.lock.layoutByScreen ?? {}))
        layouts[source] = JSON.parse(JSON.stringify(Config.options.lock.layout ?? {}))
        Config.options.lock.widgetPositions = positions
        Config.options.lock.layoutByScreen = layouts
        Config.options.lock.perScreenLayout = true
    }

    // Copy the complete live-editor design: all widget overrides and all three
    // lower control-bar offsets/scales. This is deliberately explicit rather
    // than assigning a shared object, so later edits remain independent.
    function applyLockDesignToOutput(sourceOutput, targetOutput) {
        if (!sourceOutput || !targetOutput || sourceOutput === targetOutput) return
        root.ensurePerScreenLockLayout(sourceOutput)
        const positions = JSON.parse(JSON.stringify(Config.options.lock.widgetPositions ?? {}))
        for (const name of Object.keys(positions)) {
            const record = positions[name]
            const source = root.lockPositionWithoutOverrides(record.byScreen?.[sourceOutput] ?? record)
            const overrides = Object.assign({}, record.byScreen ?? {})
            overrides[targetOutput] = JSON.parse(JSON.stringify(source))
            positions[name] = Object.assign({}, root.lockPositionWithoutOverrides(record), { byScreen: overrides })
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
    property var workspaceSelectionAnchor: null

    function workspaceKey(workspaceId, monitorName) {
        return String(monitorName ?? "") + "::" + String(workspaceId)
    }

    // Hyprland uses ids close to INT_MAX for internal/special workspaces.
    // They are never selectable through the workspace strip and must not be
    // allowed into a persistent cross-monitor relationship.
    function isRealWorkspaceId(workspaceId) {
        const id = Number(workspaceId)
        return Number.isInteger(id) && id > 0 && id < 2147483000
    }

    function workspaceEntryFromKey(rawKey) {
        const key = String(rawKey ?? "")
        const separator = key.lastIndexOf("::")
        if (separator <= 0) return null
        const monitorName = key.slice(0, separator)
        const workspaceId = Number(key.slice(separator + 2))
        if (!monitorName || !root.isRealWorkspaceId(workspaceId)) return null
        return {
            key: root.workspaceKey(workspaceId, monitorName),
            workspaceId: workspaceId,
            monitorName: monitorName,
        }
    }

    function normalizedWorkspaceGroup(rawGroup) {
        const entries = []
        const seen = new Set()
        for (const rawKey of (rawGroup ?? [])) {
            const entry = root.workspaceEntryFromKey(rawKey)
            if (entry && !seen.has(entry.key)) {
                seen.add(entry.key)
                entries.push(entry)
            }
        }
        return entries
    }

    function workspaceGroupSignature(entries) {
        return entries.map(entry => entry.key).slice().sort().join("|")
    }

    function isDetachedUnifiedGroup(entries) {
        const signature = root.workspaceGroupSignature(entries)
        return (Config.options.workspaceLinking.detachedGroups ?? []).indexOf(signature) !== -1
    }

    function clearDetachedUnifiedGroup(entries) {
        const signature = root.workspaceGroupSignature(entries)
        Config.options.workspaceLinking.detachedGroups = (Config.options.workspaceLinking.detachedGroups ?? [])
            .filter(item => item !== signature)
    }

    function connectedMonitorNames() {
        const names = []
        for (const monitor of (WM.monitors ?? [])) {
            if (monitor?.name && names.indexOf(monitor.name) === -1)
                names.push(monitor.name)
        }
        return names
    }

    function groupCoversConnectedMonitors(entries) {
        const monitorNames = root.connectedMonitorNames()
        if (monitorNames.length < 2 || entries.length < monitorNames.length) return false
        return monitorNames.every(name => entries.filter(entry => entry.monitorName === name).length === 1)
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
        root.workspaceSelectionAnchor = {
            key: key,
            workspaceId: workspaceId,
            monitorName: monitorName,
        }
    }

    function selectWorkspace(workspaceId, monitorName, additive) {
        const entry = {
            key: root.workspaceKey(workspaceId, monitorName),
            workspaceId: workspaceId,
            monitorName: monitorName,
        }
        if (!additive) root.workspaceSelection = [entry]
        else if (!root.workspaceSelectionContains(workspaceId, monitorName))
            root.workspaceSelection = root.workspaceSelection.concat([entry])
        root.workspaceSelectionAnchor = entry
    }

    // Right-click selection is additive by design. It is shared by the
    // workspace strip's click and drag paths so a drag never replaces an
    // earlier selection made on another screen.
    function addWorkspaceSelection(workspaceId, monitorName) {
        if (!root.isRealWorkspaceId(workspaceId) || !monitorName) return
        const entry = {
            key: root.workspaceKey(workspaceId, monitorName),
            workspaceId: workspaceId,
            monitorName: monitorName,
        }
        if (!root.workspaceSelectionContains(workspaceId, monitorName))
            root.workspaceSelection = root.workspaceSelection.concat([entry])
        root.workspaceSelectionAnchor = entry
        console.log("[Workspaces] selection=" + root.workspaceSelection.map(item => item.key).join(","))
    }

    // Shift extends an explicit same-monitor selection range. Ctrl+Shift
    // keeps selections on other monitors too; a plain Shift replaces the
    // current range, matching normal desktop selection behavior.
    function selectWorkspaceRange(workspaceId, monitorName, additive) {
        const anchor = root.workspaceSelectionAnchor
        if (!anchor || anchor.monitorName !== monitorName) {
            root.selectWorkspace(workspaceId, monitorName, additive)
            return
        }
        const selected = additive ? root.workspaceSelection.slice() : []
        const first = Math.min(Number(anchor.workspaceId), Number(workspaceId))
        const last = Math.max(Number(anchor.workspaceId), Number(workspaceId))
        for (let id = first; id <= last; ++id) {
            const key = root.workspaceKey(id, monitorName)
            if (!selected.some(item => item.key === key))
                selected.push({ key: key, workspaceId: id, monitorName: monitorName })
        }
        root.workspaceSelection = selected
    }

    function selectedWorkspaces(fallbackWorkspaceId, fallbackMonitorName) {
        if (root.workspaceSelection.length > 0) return root.workspaceSelection.slice()
        return [{ key: root.workspaceKey(fallbackWorkspaceId, fallbackMonitorName), workspaceId: fallbackWorkspaceId, monitorName: fallbackMonitorName }]
    }

    function linkedWorkspaceMembers(workspaceId, monitorName) {
        const key = root.workspaceKey(workspaceId, monitorName)
        const groups = Config.options.workspaceLinking.groups ?? []
        const group = groups.map(root.normalizedWorkspaceGroup)
            .find(entries => entries.some(entry => entry.key === key))
        if (!group) return []
        return group
    }

    // A logical workspace has one *distinct* real compositor workspace per
    // output.  Do not derive peers by adding a delta to the currently active
    // ids: on two monitors that produced 1+2 then 2+3, which re-assigned the
    // real workspace 2 from one output to the other on the next switch.
    // `unifiedSets` is the stable mapping used by the bar and the switcher.
    function unifiedSets() {
        return (Config.options.workspaceLinking.unifiedSets ?? [])
            .map(root.normalizedWorkspaceGroup)
    }

    function workspaceIdsInUse() {
        const used = new Set()
        for (const workspace of (WM.workspaces ?? [])) {
            const id = Number(workspace?.id)
            if (root.isRealWorkspaceId(id)) used.add(id)
        }
        for (const set of root.unifiedSets()) {
            for (const entry of set) used.add(entry.workspaceId)
        }
        return used
    }

    function nextUnusedWorkspaceId(used) {
        let id = 1
        while (used.has(id)) ++id
        used.add(id)
        return id
    }

    function persistUnifiedSets(sets) {
        Config.options.workspaceLinking.unifiedSets = sets
            .filter(set => set.length > 0)
            .map(set => set.map(entry => entry.key))
    }

    // Build a safe initial mapping from the workspaces that already exist on
    // each screen.  Existing windows therefore stay on their own monitor;
    // missing peers receive a fresh id which Hyprland creates only when the
    // user enters that logical workspace.
    function initializeUnifiedWorkspaceSets() {
        const monitorNames = root.connectedMonitorNames()
        if (monitorNames.length < 2) return []

        const existing = root.unifiedSets()
        if (existing.some(set => root.groupCoversConnectedMonitors(set))) return existing

        // At startup HyprlandData has not necessarily finished its first
        // IPC snapshot.  Waiting for it avoids reserving ids that are already
        // occupied by a real workspace which simply has not been reported yet.
        if ((WM.workspaces ?? []).length === 0) return []

        const byMonitor = ({})
        for (const name of monitorNames) byMonitor[name] = []
        for (const workspace of (WM.workspaces ?? [])) {
            const id = Number(workspace?.id)
            const monitor = String(workspace?.monitor ?? workspace?.output ?? "")
            if (root.isRealWorkspaceId(id) && byMonitor[monitor] !== undefined)
                byMonitor[monitor].push(id)
        }
        for (const name of monitorNames)
            byMonitor[name].sort((a, b) => a - b)

        const count = Math.max(1, ...monitorNames.map(name => byMonitor[name].length))
        const used = root.workspaceIdsInUse()
        const sets = []
        for (let index = 0; index < count; ++index) {
            const set = []
            for (const name of monitorNames) {
                const id = byMonitor[name][index] ?? root.nextUnusedWorkspaceId(used)
                set.push({ key: root.workspaceKey(id, name), workspaceId: id, monitorName: name })
            }
            sets.push(set)
        }
        root.persistUnifiedSets(sets)
        console.log("[Workspaces] initialized unified sets="
            + sets.map(set => root.workspaceGroupSignature(set)).join(" / "))
        return sets
    }

    // Return the real workspace members for a logical slot.  Slots are
    // created lazily, with globally unused ids, so the visible bar can grow
    // without allocating compositor workspaces or colliding with windows.
    function unifiedSetMembers(logicalNumber, createIfMissing) {
        if (!Config.options.workspaceLinking.unifiedMultiMonitor
                || !Number.isInteger(Number(logicalNumber)) || Number(logicalNumber) < 1)
            return []
        const monitorNames = root.connectedMonitorNames()
        if (monitorNames.length < 2) return []

        const sets = root.unifiedSets()
        if (sets.length === 0) root.initializeUnifiedWorkspaceSets()
        const current = root.unifiedSets()
        const setIndex = Number(logicalNumber) - 1
        let members = (current[setIndex] ?? []).slice()
        if (!createIfMissing && !root.groupCoversConnectedMonitors(members)) return []

        const used = root.workspaceIdsInUse()
        const changed = []
        for (const name of monitorNames) {
            const matches = members.filter(entry => entry.monitorName === name)
            if (matches.length === 1) {
                changed.push(matches[0])
                continue
            }
            const id = root.nextUnusedWorkspaceId(used)
            changed.push({ key: root.workspaceKey(id, name), workspaceId: id, monitorName: name })
        }
        const needsSave = !root.groupCoversConnectedMonitors(members)
            || root.workspaceGroupSignature(members) !== root.workspaceGroupSignature(changed)
        if (needsSave && createIfMissing) {
            const next = current.slice()
            next[setIndex] = changed
            root.persistUnifiedSets(next)
        }
        return changed
    }

    function logicalWorkspaceNumber(workspaceId, monitorName) {
        if (!Config.options.workspaceLinking.unifiedMultiMonitor) return Number(workspaceId)
        const key = root.workspaceKey(workspaceId, monitorName)
        const sets = root.unifiedSets()
        const index = sets.findIndex(set => set.some(entry => entry.key === key))
        return index >= 0 ? index + 1 : Number(workspaceId)
    }

    function unifiedWorkspaceIdForSlot(logicalNumber, monitorName) {
        const members = root.unifiedSetMembers(logicalNumber, true)
        return members.find(entry => entry.monitorName === monitorName)?.workspaceId
            ?? Number(logicalNumber)
    }

    function peekUnifiedWorkspaceIdForSlot(logicalNumber, monitorName) {
        const members = root.unifiedSetMembers(logicalNumber, false)
        return members.find(entry => entry.monitorName === monitorName)?.workspaceId
            ?? Number(logicalNumber)
    }

    function unifiedWorkspaceMembers(workspaceId, monitorName, includeDetached) {
        if (!Config.options.workspaceLinking.unifiedMultiMonitor
                || !root.isRealWorkspaceId(workspaceId) || !monitorName)
            return []

        const key = root.workspaceKey(workspaceId, monitorName)
        const members = root.unifiedSets().find(set => set.some(entry => entry.key === key)) ?? []
        if (!root.groupCoversConnectedMonitors(members)) return []
        return includeDetached || !root.isDetachedUnifiedGroup(members) ? members : []
    }

    function ensureUnifiedWorkspaceGroup(workspaceId, monitorName) {
        const members = root.unifiedWorkspaceMembers(workspaceId, monitorName, false)
        return members
    }

    function linkSelectedWorkspaces(fallbackWorkspaceId, fallbackMonitorName) {
        const selected = root.selectedWorkspaces(fallbackWorkspaceId, fallbackMonitorName)
        if (selected.length < 2) return
        // Preserve members of any already-linked selection and merge the
        // groups, rather than silently unlinking their other workspaces.
        const linkedKeys = new Set(selected.map(item => item.key))
        const retained = []
        for (const group of (Config.options.workspaceLinking.groups ?? []).map(root.normalizedWorkspaceGroup)) {
            if (group.some(entry => linkedKeys.has(entry.key))) {
                for (const entry of group) linkedKeys.add(entry.key)
            } else {
                retained.push(group.map(entry => entry.key))
            }
        }
        const linkedGroup = Array.from(linkedKeys)
        retained.push(linkedGroup)
        Config.options.workspaceLinking.groups = retained
        root.clearDetachedUnifiedGroup(root.normalizedWorkspaceGroup(linkedGroup))
        root.workspaceSelection = []
        root.workspaceSelectionAnchor = null
    }

    function detachWorkspace(workspaceId, monitorName) {
        const key = root.workspaceKey(workspaceId, monitorName)
        const unifiedMembers = root.unifiedWorkspaceMembers(workspaceId, monitorName, true)
        if (root.groupCoversConnectedMonitors(unifiedMembers)) {
            const signature = root.workspaceGroupSignature(unifiedMembers)
            const detached = Config.options.workspaceLinking.detachedGroups ?? []
            if (detached.indexOf(signature) === -1)
                Config.options.workspaceLinking.detachedGroups = detached.concat([signature])
        }
        const next = []
        for (const group of (Config.options.workspaceLinking.groups ?? []).map(root.normalizedWorkspaceGroup)) {
            const remaining = group.filter(entry => entry.key !== key)
            if (remaining.length > 1) next.push(remaining.map(entry => entry.key))
        }
        Config.options.workspaceLinking.groups = next
        root.workspaceSelection = root.workspaceSelection.filter(item => item.key !== key)
        if (root.workspaceSelectionAnchor?.key === key)
            root.workspaceSelectionAnchor = root.workspaceSelection[0] ?? null
    }

    function setUnifiedMultiMonitorWorkspaces(enabled) {
        Config.options.workspaceLinking.unifiedMultiMonitor = enabled
        if (!enabled) return
        root.initializeUnifiedWorkspaceSets()
    }

    // The first Hyprland IPC snapshot arrives asynchronously after the shell
    // loads.  If the user already enabled this mode, seed its mapping only
    // once that snapshot is available instead of guessing ids during startup.
    Connections {
        target: WM
        function onWorkspacesChanged() {
            if (Config.options.workspaceLinking.unifiedMultiMonitor
                    && root.unifiedSets().length === 0)
                root.initializeUnifiedWorkspaceSets()
        }
    }

    function activateWorkspace(workspaceId, monitorName) {
        const unified = root.ensureUnifiedWorkspaceGroup(workspaceId, monitorName)
        if (unified.length > 1) {
            console.log("[Workspaces] unified target=" + workspaceId + " source=" + monitorName
                + " members=" + unified.map(item => item.key).join(","))
            WM.switchWorkspacesOnMonitors(unified, monitorName)
            return
        }
        const linked = root.linkedWorkspaceMembers(workspaceId, monitorName)
        if (linked.length > 1) {
            console.log("[Workspaces] linked target=" + workspaceId + " source=" + monitorName
                + " members=" + linked.map(item => item.key).join(","))
            WM.switchWorkspacesOnMonitors(linked, monitorName)
        }
        else WM.switchWorkspaceOnMonitor(workspaceId, monitorName)
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
