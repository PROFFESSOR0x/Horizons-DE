pragma Singleton
import QtQuick
import Qt.labs.platform
import Quickshell
import Quickshell.Io
import qs.modules.common.functions
import qs.modules.common

Singleton {
    id: root
    property string logDir: Directories.cache + "/horizons/logs"
    property string logFile: logDir + "/qs.log"
    property bool enabled: true

    Component.onCompleted: {
        console.log("[Logger] Directories.cache:", Directories.cache)
        console.log("[Logger] logDir:", logDir)
        console.log("[Logger] logFile:", logFile)
        Quickshell.execDetached(["mkdir", "-p", FileUtils.trimFileProtocol(logDir)])
        log("Logger initialized, file: " + logFile)
    }

    function log(msg) {
        if (!enabled) return
        const ts = new Date().toISOString()
        const line = `[${ts}] ${msg}`
        console.log(line)
        // Append to file via bash (trim file://)
        const fp = FileUtils.trimFileProtocol(logFile)
        Quickshell.execDetached(["bash", "-c", `echo '${line.replace(/'/g, "'\\''")}' >> "${fp}"`])
    }
    function warn(msg) { log("WARN: " + msg) }
    function error(msg) { log("ERROR: " + msg) }
}
