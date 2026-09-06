pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Io

// X11/i3 counterpart to the Hyprland and Niri backends. i3 exposes all of
// this state through its stable JSON IPC, so no Wayland or Hyprland type is
// constructed in this file.
Scope {
    id: root

    property var windowList: []
    property var workspaces: []
    property var workspaceById: ({})
    property var activeWorkspace: null
    property var monitors: []
    property var focusedMonitor: null

    function runI3(command) {
        actionProc.command = ["i3-msg", command]
        actionProc.running = true
    }

    function normalizeWindow(node, workspace, floating) {
        const rect = node.rect ?? ({})
        return {
            id: String(node.id),
            address: String(node.id),
            title: node.name ?? "",
            appId: node.app_id ?? node.window_properties?.class ?? "",
            class: node.window_properties?.class ?? node.app_id ?? "",
            workspaceId: workspace?.id ?? -1,
            focused: node.focused ?? false,
            width: rect.width ?? 0,
            height: rect.height ?? 0,
            fullscreen: (node.fullscreen_mode ?? 0) !== 0,
            // i3 reports floating windows in a container's floating_nodes
            // rather than on the node itself, so it is threaded down from
            // collectWindows() instead of read off `node`.
            floating: floating ?? false
        }
    }

    function collectWindows(node, workspace, result, floating) {
        if (!node) return
        const currentWorkspace = node.type === "workspace" ? node : workspace
        if (node.window || node.app_id) result.push(normalizeWindow(node, currentWorkspace, floating))
        for (const child of (node.nodes ?? [])) collectWindows(child, currentWorkspace, result, floating)
        for (const child of (node.floating_nodes ?? [])) collectWindows(child, currentWorkspace, result, true)
    }

    function switchWorkspaceRelative(direction) {
        runI3("workspace " + (direction === "next" ? "next_on_output" : "prev_on_output"))
    }
    function focusWindow(id) { runI3("[con_id=" + id + "] focus") }
    function closeWindow(id) { runI3("[con_id=" + id + "] kill") }
    function switchWorkspace(id) { runI3("workspace \"" + String(id).replace(/\\"/g, "\\\\\"") + "\"") }
    function moveWindowToWorkspace(id, wsId) {
        runI3("[con_id=" + id + "] move container to workspace \"" + String(wsId).replace(/\\"/g, "\\\\\"") + "\"")
    }

    function monitorFor(screen) {
        if (!screen) return null
        return monitors.find(m => m.name === screen.name) ?? null
    }
    function activeWorkspaceForMonitor(monitorName) {
        return workspaces.find(ws => ws.output === monitorName && ws.visible) ?? null
    }
    function biggestWindowForWorkspace(wsId) {
        const wins = windowList.filter(w => w.workspaceId === wsId)
        if (wins.length === 0) return null
        return wins.reduce((a, b) => a.width * a.height >= b.width * b.height ? a : b)
    }
    function fullscreenOnMonitor(monitorName) {
        const ws = activeWorkspaceForMonitor(monitorName)
        return ws ? windowList.some(w => w.workspaceId === ws.id && w.fullscreen) : false
    }
    // See HyprlandBackend.obscuredMonitors.
    readonly property var obscuredMonitors: computeObscuredMonitors()
    function computeObscuredMonitors() {
        const out = ({})
        for (const m of (monitors ?? [])) {
            if (!m?.name) continue
            const ws = activeWorkspaceForMonitor(m.name)
            out[m.name] = !!ws && windowList.some(w => w.workspaceId === ws.id && (w.fullscreen || !w.floating))
        }
        return out
    }
    function monitorGeometry(screen) {
        const monitor = monitorFor(screen)
        if (!monitor) return { x: 0, y: 0, scale: 1 }
        return { x: monitor.rect.x ?? 0, y: monitor.rect.y ?? 0, scale: 1 }
    }

    function updateAll() {
        getTree.running = true
        getWorkspaces.running = true
        getOutputs.running = true
    }

    Component.onCompleted: {
        updateAll()
        eventStream.running = true
    }

    Process { id: actionProc }

    Process {
        id: getTree
        command: ["i3-msg", "-t", "get_tree"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const windows = []
                    root.collectWindows(JSON.parse(text), null, windows, false)
                    root.windowList = windows
                } catch (error) { console.log("[I3Backend] tree parse error: " + error) }
            }
        }
    }
    Process {
        id: getWorkspaces
        command: ["i3-msg", "-t", "get_workspaces"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const raw = JSON.parse(text)
                    root.workspaces = raw.map(ws => ({
                        id: ws.num >= 0 ? ws.num : ws.name,
                        idx: ws.num,
                        name: ws.name,
                        output: ws.output,
                        visible: ws.visible,
                        is_active: ws.visible,
                        is_focused: ws.focused,
                        focused: ws.focused,
                        urgent: ws.urgent,
                        rect: ws.rect
                    }))
                    const byId = {}
                    for (const workspace of root.workspaces) byId[workspace.id] = workspace
                    root.workspaceById = byId
                    root.activeWorkspace = root.workspaces.find(ws => ws.focused) ?? null
                } catch (error) { console.log("[I3Backend] workspace parse error: " + error) }
            }
        }
    }
    Process {
        id: getOutputs
        command: ["i3-msg", "-t", "get_outputs"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.monitors = JSON.parse(text)
                        .filter(output => output.active)
                        .map(output => ({ name: output.name, rect: output.rect, focused: output.focused }))
                    root.focusedMonitor = root.monitors.find(monitor => monitor.focused) ?? null
                } catch (error) { console.log("[I3Backend] output parse error: " + error) }
            }
        }
    }
    Process {
        id: eventStream
        command: ["i3-msg", "-t", "subscribe", "-m", "[\"workspace\",\"window\",\"output\"]"]
        stdout: SplitParser {
            splitMarker: "\n"
            onRead: line => { if (line.trim().length > 0) refreshDebounce.restart() }
        }
        onExited: restartTimer.restart()
    }
    Timer { id: restartTimer; interval: 1000; onTriggered: eventStream.running = true }
    Timer { id: refreshDebounce; interval: 80; onTriggered: root.updateAll() }
}
