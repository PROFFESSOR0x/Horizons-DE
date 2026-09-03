pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Reload has to bridge two QML worlds: the one being torn down and the one
// that replaces it. A tiny standalone QuickShell surface owns that bridge so
// the user never sees the gap while the main configuration is unavailable.
Singleton {
    id: root

    readonly property string runtimeDir: Quickshell.env("XDG_RUNTIME_DIR") || "/tmp"
    readonly property string statePath: runtimeDir + "/horizons-reload-state"
    readonly property string splashReadyPath: runtimeDir + "/horizons-reload-splash-ready"
    property bool requested: false

    function quote(value) {
        return "'" + String(value).replace(/'/g, "'\\''") + "'"
    }

    function requestReload() {
        if (requested) return
        requested = true

        const splashPath = Quickshell.shellPath("ReloadSplash.qml")
        // The helper waits for the splash's first rendered frame, then asks
        // this still-running shell to reload through IPC. No timeout controls
        // visibility; every transition is gated by an actual readiness file.
        const command = [
            "rm -f " + quote(splashReadyPath),
            "printf loading > " + quote(statePath),
            "quickshell -p " + quote(splashPath) + " -d",
            "while [ ! -f " + quote(splashReadyPath) + " ]; do sleep 0.02; done",
            "quickshell ipc -c horizons call reloadControl proceed"
        ].join("; ")
        Quickshell.execDetached(["bash", "-c", command])
    }

    function markReady() {
        Quickshell.execDetached(["bash", "-c", "test -f " + quote(statePath) + " && printf ready > " + quote(statePath)])
    }

    function markFailed() {
        requested = false
        Quickshell.execDetached(["bash", "-c", "test -f " + quote(statePath) + " && printf failed > " + quote(statePath)])
    }

    IpcHandler {
        target: "reloadControl"
        function proceed(): void {
            Quickshell.reload(true)
        }
    }
}
