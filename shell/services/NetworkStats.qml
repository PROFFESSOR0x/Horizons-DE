pragma Singleton
pragma ComponentBehavior: Bound
import QtQuick
import Quickshell.Io
import qs.modules.common

// Shared /proc/net/dev poller. Previously bar/NetworkSpeed.qml and
// sysmonitorBar/SysmonitorBarContent.qml each ran their own independent
// poller against the same file; this consolidates that into one singleton
// both consume.
Singleton {
    id: root

    property real downloadBytesPerSecond: 0
    property real uploadBytesPerSecond: 0
    property real downloadedBytes: 0
    property real uploadedBytes: 0
    property real previousReceivedBytes: -1
    property real previousTransmittedBytes: -1
    property double previousSampleTime: 0

    readonly property int historyLength: Config?.options.resources.historyLength ?? 60
    property list<real> downloadHistory: []
    property list<real> uploadHistory: []

    function formatRate(rate, compact) {
        const units = compact
            ? ["B", "K", "M", "G"]
            : ["B/s", "KB/s", "MB/s", "GB/s"]
        let value = Math.max(0, Number(rate) || 0)
        let unitIndex = 0

        while (value >= 1024 && unitIndex < units.length - 1) {
            value /= 1024
            unitIndex++
        }

        const precision = unitIndex > 0 && value < 100 ? 1 : 0
        return `${value.toFixed(precision)}${compact ? "" : " "}${units[unitIndex]}`
    }

    function updateRate(contents) {
        let receivedBytes = 0
        let transmittedBytes = 0
        const lines = contents.split("\n")

        for (const line of lines) {
            const separator = line.indexOf(":")
            if (separator < 0) continue

            const interfaceName = line.slice(0, separator).trim()
            if (!interfaceName || interfaceName === "lo") continue

            const fields = line.slice(separator + 1).trim().split(/\s+/)
            if (fields.length < 9) continue

            const received = Number(fields[0])
            const transmitted = Number(fields[8])
            if (!Number.isFinite(received) || !Number.isFinite(transmitted)) continue

            receivedBytes += received
            transmittedBytes += transmitted
        }

        const sampleTime = Date.now()
        if (root.previousSampleTime > 0 && sampleTime > root.previousSampleTime) {
            const elapsedMilliseconds = sampleTime - root.previousSampleTime
            const receivedDelta = receivedBytes >= root.previousReceivedBytes
                ? receivedBytes - root.previousReceivedBytes
                : 0
            const transmittedDelta = transmittedBytes >= root.previousTransmittedBytes
                ? transmittedBytes - root.previousTransmittedBytes
                : 0

            root.downloadBytesPerSecond = receivedDelta * 1000 / elapsedMilliseconds
            root.uploadBytesPerSecond = transmittedDelta * 1000 / elapsedMilliseconds
            root.downloadedBytes += receivedDelta
            root.uploadedBytes += transmittedDelta

            const dh = [...root.downloadHistory, root.downloadBytesPerSecond]
            const uh = [...root.uploadHistory, root.uploadBytesPerSecond]
            root.downloadHistory = dh.length > root.historyLength ? dh.slice(-root.historyLength) : dh
            root.uploadHistory = uh.length > root.historyLength ? uh.slice(-root.historyLength) : uh
        }

        root.previousReceivedBytes = receivedBytes
        root.previousTransmittedBytes = transmittedBytes
        root.previousSampleTime = sampleTime
    }

    FileView {
        id: networkStatsFile
        path: "/proc/net/dev"
        printErrors: false
        onLoaded: root.updateRate(text())
    }

    Timer {
        interval: 1000
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: networkStatsFile.reload()
    }
}
