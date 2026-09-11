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

    function widgetShown(name, locked) {
        if (locked) return Config.options.lock.showWidgets
            && Config.options.lock.enabledWidgets.includes(name)
        return Config.options.background.widgets[name].enable
            && !Config.options.background.widgets.lockOnly.includes(name)
            && !(name === "clock" && Config.options.background.widgets.clock.showOnlyWhenLocked)
    }

    function setWidgetShown(name, locked, shown) {
        if (locked) {
            const names = Config.options.lock.enabledWidgets.filter(value => value !== name)
            if (shown) {
                names.push(name)
                if (!Config.options.lock.widgetPositions[name]) {
                    const widget = Config.options.background.widgets[name]
                    Config.options.lock.widgetPositions = Object.assign({}, Config.options.lock.widgetPositions,
                        { [name]: { x: widget.x, y: widget.y } })
                }
            }
            Config.options.lock.enabledWidgets = names
            if (shown) Config.options.lock.showWidgets = true
        } else {
            Config.options.background.widgets[name].enable = shown
            Config.options.background.widgets.lockOnly = Config.options.background.widgets.lockOnly.filter(value => value !== name)
            if (name === "clock") Config.options.background.widgets.clock.showOnlyWhenLocked = false
        }
    }

    property var lockPreviewInitialVisibility: ({})
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
        root.lockPreviewInitialVisibility = {
            names: Config.options.lock.enabledWidgets.slice(),
            show: Config.options.lock.showWidgets,
            desktop: Object.fromEntries(Object.keys(Config.options.background.widgets)
                .filter(name => Config.options.background.widgets[name]?.enable !== undefined)
                .map(name => [name, Config.options.background.widgets[name].enable])),
            lockOnly: Config.options.background.widgets.lockOnly.slice(),
            clockOnly: Config.options.background.widgets.clock.showOnlyWhenLocked,
        }
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
        const initial = root.lockPreviewInitialVisibility
        Config.options.lock.enabledWidgets = initial.names
        Config.options.lock.showWidgets = initial.show
        for (const name of Object.keys(initial.desktop))
            Config.options.background.widgets[name].enable = initial.desktop[name]
        Config.options.background.widgets.lockOnly = initial.lockOnly
        Config.options.background.widgets.clock.showOnlyWhenLocked = initial.clockOnly
        Config.options.lock.widgetPositions = root.lockPreviewInitialWidgetPositions
        root.applyLockLayout(root.lockPreviewInitialLayout)
        Config.options.lock.layoutByScreen = root.lockPreviewInitialLayoutByScreen
        Config.options.lock.perScreenLayout = root.lockPreviewInitialPerScreenLayout
        Config.options.lock.centerClock = root.lockPreviewInitialCenterClock
        root.saveLockPreview()
    }

    function resetLockWidgetLayout() {
        const positions = {}
        const widgets = Config.options.background.widgets
        for (const name of Object.keys(widgets)) {
            if (widgets[name]?.x !== undefined)
                positions[name] = { x: widgets[name].x, y: widgets[name].y }
        }
        Config.options.lock.widgetPositions = positions
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
        if (entries.length === 0) return false
        const stored = root.unifiedSets().find(set => entries.every(entry => set.some(item => item.key === entry.key))) ?? entries
        return (Config.options.workspaceLinking.detachedGroups ?? [])
            .includes(root.workspaceGroupSignature(stored))
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
        if (monitorNames.length === 0 || entries.length !== monitorNames.length) return false
        if (new Set(entries.map(entry => Number(entry.workspaceId))).size !== entries.length) return false
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
        const reserved = root.unifiedSets().concat(
            (Config.options.workspaceLinking.groups ?? []).map(root.normalizedWorkspaceGroup))
        for (const set of reserved) {
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

    function activeWorkspaceEntriesForConnectedMonitors() {
        const entries = []
        for (const name of root.connectedMonitorNames()) {
            const id = Number(WM.activeWorkspaceForMonitor(name)?.id)
            if (root.isRealWorkspaceId(id))
                entries.push({key: root.workspaceKey(id, name), workspaceId: id, monitorName: name})
        }
        return entries
    }

    function resetUnifiedWorkspaceSetsToActiveMonitors() {
        const activeEntries = root.activeWorkspaceEntriesForConnectedMonitors()
        Config.options.workspaceLinking.detachedGroups = []
        Config.options.workspaceLinking.unifiedSets =
            root.groupCoversConnectedMonitors(activeEntries)
                ? [activeEntries.map(entry => entry.key)]
                : []
        return root.initializeUnifiedWorkspaceSets()
    }

    readonly property bool unifiedWorkspacesEnabled: WM.compositor === "hyprland"
        && Config.options.workspaceLinking.unifiedMultiMonitor
    onUnifiedWorkspacesEnabledChanged: {
        if (unifiedWorkspacesEnabled) Qt.callLater(root.initializeUnifiedWorkspaceSets)
    }

    // Reconcile only after the first IPC snapshot. Keep disconnected outputs'
    // reservations so reconnecting an output restores its logical positions.
    function initializeUnifiedWorkspaceSets() {
        if (!root.unifiedWorkspacesEnabled || !HyprlandData.workspacesReady) return []
        const names = root.connectedMonitorNames()
        if (names.length === 0) return []
        const previous = root.unifiedSets()
        const used = root.workspaceIdsInUse()
        const assigned = new Set()
        const actual = new Map()
        for (const ws of WM.workspaces ?? []) {
            if (root.isRealWorkspaceId(ws.id) && !actual.has(Number(ws.id)))
                actual.set(Number(ws.id), String(ws.monitor ?? ws.output ?? ""))
        }
        const makeEntry = (id, name) => ({key: root.workspaceKey(id, name), workspaceId: id, monitorName: name})
        const sets = previous.map(set => {
            const outputs = new Set()
            return set.filter(entry => {
                if (outputs.has(entry.monitorName)) return false
                outputs.add(entry.monitorName)
                return true
            }).map(entry => {
                let id = Number(entry.workspaceId)
                if (assigned.has(id) || (actual.has(id) && actual.get(id) !== entry.monitorName))
                    id = root.nextUnusedWorkspaceId(used)
                assigned.add(id)
                return makeEntry(id, entry.monitorName)
            })
        })
        // Adopt live IDs before allocating peers. Also handles late snapshots
        // and workspaces created outside the shell without renumbering slots.
        for (const [id, name] of actual) {
            if (!names.includes(name) || assigned.has(id)) continue
            let set = sets.find(items => !items.some(entry => entry.monitorName === name))
            if (!set) { set = []; sets.push(set) }
            set.push(makeEntry(id, name))
            assigned.add(id)
        }
        if (sets.length === 0) sets.push([])
        for (const set of sets) {
            for (const name of names) {
                if (set.some(entry => entry.monitorName === name)) continue
                const id = root.nextUnusedWorkspaceId(used)
                assigned.add(id)
                set.push(makeEntry(id, name))
            }
        }
        if (JSON.stringify(previous) !== JSON.stringify(sets)) {
            // Carry detach intent when reconciliation adds/removes peers.
            const oldDetached = Config.options.workspaceLinking.detachedGroups ?? []
            const detached = sets.filter((set, index) => previous[index]
                && oldDetached.includes(root.workspaceGroupSignature(previous[index])))
                .map(set => root.workspaceGroupSignature(set))
            root.persistUnifiedSets(sets)
            Config.options.workspaceLinking.detachedGroups = detached
        }
        return sets
    }

    function unifiedSetMembers(logicalNumber, createIfMissing) {
        if (!root.unifiedWorkspacesEnabled || !HyprlandData.workspacesReady
                || !Number.isInteger(Number(logicalNumber)) || Number(logicalNumber) < 1)
            return []
        const names = root.connectedMonitorNames()
        if (names.length === 0) return []
        let sets = root.unifiedSets()
        if (createIfMissing) {
            sets = root.initializeUnifiedWorkspaceSets().slice()
            const used = root.workspaceIdsInUse()
            // Fill intervening slots: sparse arrays must never collapse and
            // silently change persisted logical numbering.
            while (sets.length < Number(logicalNumber)) {
                sets.push(names.map(name => {
                    const id = root.nextUnusedWorkspaceId(used)
                    return {key: root.workspaceKey(id, name), workspaceId: id, monitorName: name}
                }))
            }
            if (JSON.stringify(sets) !== JSON.stringify(root.unifiedSets())) root.persistUnifiedSets(sets)
        }
        return (sets[Number(logicalNumber) - 1] ?? []).filter(entry => names.includes(entry.monitorName))
    }

    function logicalWorkspaceNumber(workspaceId, monitorName) {
        if (!root.unifiedWorkspacesEnabled) return Number(workspaceId)
        if (!root.isRealWorkspaceId(workspaceId)) return 1
        const key = root.workspaceKey(workspaceId, monitorName)
        const sets = root.unifiedSets()
        const index = sets.findIndex(set => set.some(entry => entry.key === key))
        return index >= 0 ? index + 1 : Number(workspaceId)
    }

    function unifiedWorkspaceIdForSlot(logicalNumber, monitorName) {
        const members = root.unifiedSetMembers(logicalNumber, true)
        return members.find(entry => entry.monitorName === monitorName)?.workspaceId
            ?? 0
    }

    function peekUnifiedWorkspaceIdForSlot(logicalNumber, monitorName) {
        const members = root.unifiedSetMembers(logicalNumber, false)
        return members.find(entry => entry.monitorName === monitorName)?.workspaceId
            ?? 0
    }

    function unifiedWorkspaceMembers(workspaceId, monitorName, includeDetached) {
        if (!root.unifiedWorkspacesEnabled
                || !root.isRealWorkspaceId(workspaceId) || !monitorName)
            return []

        const key = root.workspaceKey(workspaceId, monitorName)
        const stored = root.unifiedSets().find(set => set.some(entry => entry.key === key)) ?? []
        const names = root.connectedMonitorNames()
        const members = stored.filter(entry => names.includes(entry.monitorName))
        if (!root.groupCoversConnectedMonitors(members)) return []
        return includeDetached || !root.isDetachedUnifiedGroup(stored) ? members : []
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
        Config.options.workspaceLinking.unifiedMultiMonitor = enabled && WM.compositor === "hyprland"
        if (!enabled) {
            Config.options.workspaceLinking.detachedGroups = []
            Config.requestWrite()
            return
        }
        root.resetUnifiedWorkspaceSetsToActiveMonitors()
        Config.requestWrite()
    }

    function unifiedFocusedMonitorName() {
        const focused = WM.focusedMonitor
        if (focused?.name) return focused.name
        return (WM.monitors ?? []).find(monitor => monitor?.focused)?.name ?? ""
    }

    function reportUnifiedWorkspaceError(action, detail) {
        console.error("[UnifiedWorkspaces] " + action + " failed: " + detail)
    }

    function monitorNameForWindow(window) {
        if (!window) return ""
        const directName = String(window.monitor ?? "")
        if (directName && !/^\d+$/.test(directName)) return directName
        return (WM.monitors ?? []).find(monitor => Number(monitor?.id) === Number(window.monitor))?.name ?? ""
    }

    function isUnifiedSetActive(members) {
        return members.length > 0 && members.every(member =>
            Number(WM.activeWorkspaceForMonitor(member.monitorName)?.id) === Number(member.workspaceId))
    }

    // Keep all entry points that focus a running application — dock buttons,
    // thumbnail popups, window switcher, and tray activations — inside the
    // same all-monitor workspace set. Hyprland's stock toplevel.activate()
    // only changes the target window's monitor, which is the regression this
    // wrapper deliberately prevents.
    function focusWindowInUnifiedSet(address) {
        if (!root.unifiedWorkspacesEnabled) {
            WM.focusWindow(address)
            return true
        }
        root.initializeUnifiedWorkspaceSets()
        const window = (HyprlandData.windowByAddress ?? {})[address]
            ?? (HyprlandData.windowList ?? []).find(candidate => candidate?.address === address)
        if (!window) {
            root.reportUnifiedWorkspaceError("window focus", "unknown window " + address)
            return false
        }
        const monitorName = root.monitorNameForWindow(window)
        const members = root.unifiedWorkspaceMembers(window.workspace?.id, monitorName, false)
        if (!root.groupCoversConnectedMonitors(members)) {
            // Explicitly detached and special workspaces remain focusable.
            WM.focusWindow(address)
            return true
        }
        if (root.isUnifiedSetActive(members)) {
            WM.focusWindow(address)
            return true
        }
        console.log("[UnifiedWorkspaces] focus window=" + address + " source=" + monitorName
            + " members=" + members.map(member => member.key).join(","))
        WM.switchWorkspacesOnMonitors(members, monitorName, address)
        return true
    }

    // StatusNotifier applications focus their windows themselves, outside the
    // dock's click handler. Call this after their activation settles so tray
    // icons obey the exact same workspace-set rule.
    function synchronizeFocusedWindowInUnifiedSet() {
        if (!root.unifiedWorkspacesEnabled) return false
        const address = HyprlandData.activeWorkspace?.lastwindow ?? ""
        if (!address) return false
        const window = (HyprlandData.windowByAddress ?? {})[address]
        if (!window) return false
        const members = root.unifiedWorkspaceMembers(window.workspace?.id,
            root.monitorNameForWindow(window), false)
        if (!root.groupCoversConnectedMonitors(members) || root.isUnifiedSetActive(members)) return false
        return root.focusWindowInUnifiedSet(address)
    }

    // These paths intentionally have no local-workspace fallback. A shared
    // shortcut must either operate on every monitor in the logical set or do
    // nothing and leave a precise diagnostic in the QuickShell log.
    function activateUnifiedWorkspaceNumber(logicalNumber) {
        if (!root.unifiedWorkspacesEnabled) {
            root.reportUnifiedWorkspaceError("activate", "all-screens mode is disabled")
            return false
        }
        const monitorName = root.unifiedFocusedMonitorName()
        if (!monitorName) {
            root.reportUnifiedWorkspaceError("activate", "no focused monitor")
            return false
        }
        const members = root.unifiedSetMembers(Number(logicalNumber), true)
        if (!root.groupCoversConnectedMonitors(members)) {
            root.reportUnifiedWorkspaceError("activate", "logical workspace " + logicalNumber
                + " has no complete monitor set")
            return false
        }
        if (root.isDetachedUnifiedGroup(members)) {
            root.reportUnifiedWorkspaceError("activate", "logical workspace " + logicalNumber
                + " is explicitly separated")
            return false
        }
        console.log("[UnifiedWorkspaces] activate logical=" + logicalNumber
            + " source=" + monitorName + " members="
            + members.map(member => member.key).join(","))
        WM.switchWorkspacesOnMonitors(members, monitorName)
        return true
    }

    function switchUnifiedWorkspaceRelative(direction) {
        if (!root.unifiedWorkspacesEnabled) {
            root.reportUnifiedWorkspaceError("relative switch", "all-screens mode is disabled")
            return false
        }
        const monitorName = root.unifiedFocusedMonitorName()
        const active = WM.activeWorkspaceForMonitor(monitorName)
        if (!monitorName || !root.isRealWorkspaceId(active?.id)) {
            root.reportUnifiedWorkspaceError("relative switch", "focused monitor has no real active workspace")
            return false
        }
        const logical = root.logicalWorkspaceNumber(active.id, monitorName)
        const members = root.unifiedWorkspaceMembers(active.id, monitorName, true)
        if (!root.groupCoversConnectedMonitors(members)) {
            root.reportUnifiedWorkspaceError("relative switch", "active workspace "
                + monitorName + "::" + active.id + " is not in a unified set")
            return false
        }
        const delta = (direction === "previous" || direction === "prev") ? -1 : 1
        return root.activateUnifiedWorkspaceNumber(Math.max(1, logical + delta))
    }

    function cycleUnifiedWindows() {
        if (!root.unifiedWorkspacesEnabled) {
            root.reportUnifiedWorkspaceError("Alt+Tab", "all-screens mode is disabled")
            return false
        }
        const monitorName = root.unifiedFocusedMonitorName()
        const active = WM.activeWorkspaceForMonitor(monitorName)
        const members = root.unifiedWorkspaceMembers(active?.id, monitorName, false)
        if (!root.groupCoversConnectedMonitors(members)) {
            root.reportUnifiedWorkspaceError("Alt+Tab", "active workspace "
                + monitorName + "::" + (active?.id ?? "none") + " is not in a unified set")
            return false
        }
        const candidates = []
        for (const window of (HyprlandData.windowList ?? [])) {
            if (window?.mapped === false || window?.hidden === true) continue
            const windowMonitor = (WM.monitors ?? []).find(monitor => Number(monitor?.id) === Number(window?.monitor))?.name ?? ""
            if (!members.some(member => member.monitorName === windowMonitor
                    && Number(member.workspaceId) === Number(window?.workspace?.id)))
                continue
            candidates.push({
                address: window.address,
                focusHistoryId: Number(window.focusHistoryID ?? Number.MAX_SAFE_INTEGER),
                focused: window.address === HyprlandData.activeWorkspace?.lastwindow,
            })
        }
        candidates.sort((a, b) => a.focusHistoryId - b.focusHistoryId
            || String(a.address).localeCompare(String(b.address)))
        if (candidates.length === 0) {
            root.reportUnifiedWorkspaceError("Alt+Tab", "the unified set has no mapped windows")
            return false
        }
        const focusedIndex = candidates.findIndex(candidate => candidate.focused)
        const next = candidates[focusedIndex < 0 ? 0 : (focusedIndex + 1) % candidates.length]
        console.log("[UnifiedWorkspaces] Alt+Tab members=" + members.map(member => member.key).join(",")
            + " target=" + next.address)
        WM.focusWindow(next.address)
        return true
    }

    // The first Hyprland IPC snapshot arrives asynchronously after the shell
    // loads.  If the user already enabled this mode, seed its mapping only
    // once that snapshot is available instead of guessing ids during startup.
    Connections {
        target: WM
        function onWorkspacesChanged() { root.initializeUnifiedWorkspaceSets() }
        function onMonitorsChanged() { root.initializeUnifiedWorkspaceSets() }
    }
    Connections {
        target: HyprlandData
        function onWorkspacesReadyChanged() { root.initializeUnifiedWorkspaceSets() }
    }

    function activateWorkspaceSlot(logicalNumber, monitorName) {
        if (!root.unifiedWorkspacesEnabled) {
            root.activateWorkspace(logicalNumber, monitorName)
            return
        }
        const members = root.unifiedSetMembers(logicalNumber, true)
        if (!root.groupCoversConnectedMonitors(members)) return
        const id = members.find(entry => entry.monitorName === monitorName)?.workspaceId
        if (id) root.activateWorkspace(id, monitorName)
    }

    function newWorkspaceId(monitorName) {
        if (!root.unifiedWorkspacesEnabled) return WM.nextWorkspaceId()
        root.initializeUnifiedWorkspaceSets()
        const members = root.unifiedSetMembers(root.unifiedSets().length + 1, true)
        return members.find(entry => entry.monitorName === monitorName)?.workspaceId ?? 0
    }

    function activateWorkspace(workspaceId, monitorName) {
        if (!root.isRealWorkspaceId(workspaceId)) return
        if (root.unifiedWorkspacesEnabled) root.initializeUnifiedWorkspaceSets()
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
                || (WM.compositor !== "hyprland" && !window.monitorName
                    && entries.some(item => String(item.workspaceId) === String(window.workspaceId)))
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

    // These are invoked by Hyprland's native `hl.dsp.global()` dispatcher.
    // Unlike spawning `qs ipc`, the key event crosses no process boundary;
    // Hyprland dispatches it directly to QuickShell while the grouping state
    // remains in exactly one place.
    CompositorGlobalShortcut {
        name: "unifiedWorkspacePrevious"
        description: "Focus the previous shared workspace set"
        onPressed: root.switchUnifiedWorkspaceRelative("previous")
    }
    CompositorGlobalShortcut {
        name: "unifiedWorkspaceNext"
        description: "Focus the next shared workspace set"
        onPressed: root.switchUnifiedWorkspaceRelative("next")
    }
    CompositorGlobalShortcut {
        name: "unifiedWorkspaceCycleWindows"
        description: "Cycle windows in the shared workspace set"
        onPressed: root.cycleUnifiedWindows()
    }
    CompositorGlobalShortcut {
        name: "unifiedWorkspace1"
        description: "Focus shared workspace 1"
        onPressed: root.activateUnifiedWorkspaceNumber(1)
    }
    CompositorGlobalShortcut {
        name: "unifiedWorkspace2"
        description: "Focus shared workspace 2"
        onPressed: root.activateUnifiedWorkspaceNumber(2)
    }
    CompositorGlobalShortcut {
        name: "unifiedWorkspace3"
        description: "Focus shared workspace 3"
        onPressed: root.activateUnifiedWorkspaceNumber(3)
    }
    CompositorGlobalShortcut {
        name: "unifiedWorkspace4"
        description: "Focus shared workspace 4"
        onPressed: root.activateUnifiedWorkspaceNumber(4)
    }
    CompositorGlobalShortcut {
        name: "unifiedWorkspace5"
        description: "Focus shared workspace 5"
        onPressed: root.activateUnifiedWorkspaceNumber(5)
    }
    CompositorGlobalShortcut {
        name: "unifiedWorkspace6"
        description: "Focus shared workspace 6"
        onPressed: root.activateUnifiedWorkspaceNumber(6)
    }
    CompositorGlobalShortcut {
        name: "unifiedWorkspace7"
        description: "Focus shared workspace 7"
        onPressed: root.activateUnifiedWorkspaceNumber(7)
    }
    CompositorGlobalShortcut {
        name: "unifiedWorkspace8"
        description: "Focus shared workspace 8"
        onPressed: root.activateUnifiedWorkspaceNumber(8)
    }
    CompositorGlobalShortcut {
        name: "unifiedWorkspace9"
        description: "Focus shared workspace 9"
        onPressed: root.activateUnifiedWorkspaceNumber(9)
    }
    CompositorGlobalShortcut {
        name: "unifiedWorkspace10"
        description: "Focus shared workspace 10"
        onPressed: root.activateUnifiedWorkspaceNumber(10)
    }

     CompositorGlobalShortcut {
        name: "centeredWallpaperToggle"
        description: "Toggles centered wallpaper"
        onPressed: {
            Config.options.background.centeredWallpaper = !Config.options.background.centeredWallpaper
        }
    }
}
