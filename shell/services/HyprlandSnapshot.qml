pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Io

// One in-flight request, one trailing refresh, and a bounded coalescing window.
// Kept independent of shell singletons so it can be exercised in isolation.
Scope {
    id: root
    required property string query
    property var command: ["hyprctl", query, "-j"]
    property string socketPath: ""
    property bool busy: false
    property string response: ""
    property bool timedOut: false
    property string expectedType: "array"
    property int coalesceMs: 16
    property int timeoutMs: 2000
    property bool pending: false
    property string lastPayload: ""
    property int requests: 0
    property int publications: 0
    property int failures: 0
    signal snapshot(var value)

    function request() {
        pending = true
        // start(), not restart(): a continuous event stream must not starve UI.
        if (!busy && !coalesce.running) coalesce.start()
    }

    Timer {
        id: coalesce
        interval: root.coalesceMs
        onTriggered: {
            if (!root.pending || root.busy) return
            root.pending = false
            root.requests++
            root.response = ""
            root.timedOut = false
            root.busy = true
            watchdog.start()
            if (!root.socketPath) process.running = true
        }
    }
    Timer {
        id: watchdog
        interval: root.timeoutMs
        onTriggered: {
            root.timedOut = true
            if (root.socketPath) {
                root.finish("", false)
            } else process.signal(9)
        }
    }
    function finish(text, success) {
        if (!busy) return
        watchdog.stop()
        busy = false
        try {
            if (!success || timedOut) throw new Error("request failed or timed out")
            const value = JSON.parse(text)
            const valid = expectedType === "array" ? Array.isArray(value)
                : value !== null && typeof value === "object" && !Array.isArray(value)
            if (!valid) throw new Error("unexpected JSON shape")
            const payload = JSON.stringify(value)
            if (payload !== lastPayload) {
                lastPayload = payload
                publications++
                snapshot(value)
            }
        } catch (error) {
            failures++
            if (failures === 1 || failures % 100 === 0)
                console.warn("[HyprlandSnapshot] " + query + ": " + error)
        }
        if (pending) coalesce.start()
    }
    Loader {
        // Fresh QLocalSocket per transaction, including after connect failure.
        // Destroying the loader also closes stalled connections on timeout.
        active: root.busy && root.socketPath !== ""
        sourceComponent: Socket {
            id: socket
            path: root.socketPath
            connected: true
            // A request socket must never be kept idle: Hyprland handles it
            // synchronously. Send+flush immediately and consume through EOF.
            onConnectedChanged: {
                if (connected) {
                    write("j/" + root.query)
                    flush()
                } else if (root.busy) root.finish(root.response, true)
            }
            parser: StdioCollector {
                id: socketOutput
                waitForEnd: false
                // Socket does not emit streamFinished. Collect bytes until EOF;
                // decoding individual chunks corrupts split UTF-8 window titles.
                onDataChanged: {
                    root.response = socketOutput.text
                    if (root.response.length > 16 * 1024 * 1024) {
                        root.timedOut = true
                        socket.connected = false
                        root.finish("", false)
                        return
                    }
                    // Hyprland returns exactly one JSON document. Close as soon
                    // as it is complete, avoiding PeerClosedError log spam for
                    // successful requests in Quickshell's generic Socket backend.
                    const tail = root.response.trim().slice(-1)
                    if (tail === "]" || tail === "}") {
                        try { JSON.parse(root.response) } catch (error) { return }
                        root.finish(root.response, true)
                    }
                }
            }
            onError: error => {
                // RemoteHostClosed is also emitted for a normal EOF. Let the
                // disconnect handler publish its complete response first.
                Qt.callLater(() => {
                    if (root.busy && !socket.connected) root.finish("", false)
                })
            }
        }
    }
    Process {
        id: process
        command: root.command
        stdout: StdioCollector { id: output }
        onExited: (code, status) => root.finish(output.text, code === 0 && status === 0)
    }
}
