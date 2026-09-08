pragma Singleton
pragma ComponentBehavior: Bound

import qs.modules.common
import QtQuick
import Quickshell
import Quickshell.Io

/**
 * Simple polled resource usage service with RAM, Swap, CPU and Disk usage.
 */
Singleton {
    id: root
    property int activeConsumers: 0
    function acquire() {
        activeConsumers++
        if (activeConsumers !== 1) return
        // Paused time is not a CPU sample. Establish a fresh baseline.
        previousCpuStats = undefined
        fileMeminfo.reload()
        fileStat.reload()
        requestHardware()
        if (!diskProc.running) diskProc.running = true
    }
    function release() {
        activeConsumers = Math.max(0, activeConsumers - 1)
        if (activeConsumers !== 0) return
        hardwareWatchdog.stop()
        hardwareProc.running = false
    }
    property real memoryTotal: 1
    property real memoryFree: 0
    property real memoryUsed: memoryTotal - memoryFree
    property real memoryUsedPercentage: memoryUsed / memoryTotal
    property real swapTotal: 1
    property real swapFree: 0
    property real swapUsed: swapTotal - swapFree
    property real swapUsedPercentage: swapTotal > 0 ? (swapUsed / swapTotal) : 0
    property real cpuUsage: 0
    property var previousCpuStats

    property string maxAvailableMemoryString: kbToGbString(ResourceUsage.memoryTotal)
    property string maxAvailableSwapString: kbToGbString(ResourceUsage.swapTotal)
    property string maxAvailableCpuString: "--"

    readonly property int historyLength: Math.max(1, Config?.options.resources.historyLength ?? 60)
    property list<real> cpuUsageHistory: []
    property list<real> memoryUsageHistory: []
    property list<real> swapUsageHistory: []

    property real cpuTemp: 0

    // GPU usage/temp: NVIDIA via nvidia-smi where present, else the sysfs
    // path amdgpu/i915 both expose (gpu_busy_percent + hwmon temp1_input,
    // millidegrees). gpuAvailable stays false (rather than showing a fake
    // 0%) when neither source produced a real reading, so widgets can hide
    // themselves cleanly instead of displaying a misleading "0% / 0°C" on
    // hardware/drivers that don't expose this at all.
    property bool gpuAvailable: false
    property real gpuUsage: 0
    property real gpuTemp: 0
    property list<real> gpuUsageHistory: []

    property real diskTotal: 1
    property real diskUsed: 0
    property real diskFree: 0
    property real diskUsedPercentage: diskTotal > 0 ? diskUsed / diskTotal : 0
    property list<real> diskUsageHistory: []
    property string maxAvailableDiskString: kbToGbString(diskTotal)

    property bool hardwarePending: false
    function requestHardware() {
        if (activeConsumers === 0 || hardwarePending) return
        if (!hardwareProc.running) { hardwareProc.running = true; return }
        hardwarePending = true
        hardwareWatchdog.start()
        hardwareProc.write("sample\n")
    }
    Timer {
        id: hardwareWatchdog
        interval: 2500
        onTriggered: hardwareProc.signal(9)
    }
    Process {
        id: hardwareProc
        command: ["python3", Directories.scriptPath + "/system/hardware_sample.py", "--serve"]
        stdinEnabled: true
        onStarted: root.requestHardware()
        onExited: {
            hardwareWatchdog.stop()
            root.hardwarePending = false
            root.gpuAvailable = false
            // The sampling timer retries; do not create a crash/restart loop.
        }
        stdout: SplitParser {
            onRead: text => {
                hardwareWatchdog.stop()
                root.hardwarePending = false
                try {
                    const data = JSON.parse(text)
                    if (Number.isFinite(data.cpuTemp)) root.cpuTemp = data.cpuTemp
                    root.gpuAvailable = Number.isFinite(data.gpuUsage)
                    if (root.gpuAvailable) {
                        root.gpuUsage = data.gpuUsage
                        root.gpuTemp = Number.isFinite(data.gpuTemp) ? data.gpuTemp : 0
                        root.updateGpuUsageHistory()
                    }
                } catch (error) { console.warn("[ResourceUsage] Invalid hardware sample") }
            }
        }
    }
    Process {
        id: diskProc
        command: ["df", "-k", "--output=size,used,avail", "/"]
        environment: ({ LC_ALL: "C" })
        stdout: StdioCollector { id: diskOutput }
        onExited: (code, status) => {
            if (code !== 0 || status !== 0) return
            const parts = diskOutput.text.trim().split("\n").pop().trim().split(/\s+/).map(Number)
            if (parts.length === 3 && parts.every(Number.isFinite) && parts[0] > 0) {
                root.diskTotal = parts[0]
                root.diskUsed = parts[1]
                root.diskFree = parts[2]
                root.updateDiskUsageHistory()
            }
        }
    }
    Timer {
        interval: Math.max(1000, Config?.options.resources.updateInterval ?? 3000)
        running: root.activeConsumers > 0
        repeat: true
        onTriggered: root.requestHardware()
    }
    // Capacity is slow-changing; CPU's refresh rate should not drive df.
    Timer {
        interval: 60000
        running: root.activeConsumers > 0
        repeat: true
        onTriggered: if (!diskProc.running) diskProc.running = true
    }

    function kbToGbString(kb) {
        return (kb / (1024 * 1024)).toFixed(1) + " GB"
    }

    function updateMemoryUsageHistory() {
        memoryUsageHistory = [...memoryUsageHistory, memoryUsedPercentage].slice(-historyLength)
    }
    function updateSwapUsageHistory() {
        swapUsageHistory = [...swapUsageHistory, swapUsedPercentage].slice(-historyLength)
    }
    function updateCpuUsageHistory() {
        cpuUsageHistory = [...cpuUsageHistory, cpuUsage].slice(-historyLength)
    }
    function updateDiskUsageHistory() {
        diskUsageHistory = [...diskUsageHistory, diskUsedPercentage].slice(-historyLength)
    }
    function updateGpuUsageHistory() {
        gpuUsageHistory = [...gpuUsageHistory, gpuUsage].slice(-historyLength)
    }
    function acceptMemory(text) {
        const total = Number(text.match(/MemTotal: *(\d+)/)?.[1] ?? 0)
        const available = Number(text.match(/MemAvailable: *(\d+)/)?.[1] ?? NaN)
        if (total <= 0 || !Number.isFinite(available)) return
        memoryTotal = total
        memoryFree = available
        swapTotal = Number(text.match(/SwapTotal: *(\d+)/)?.[1] ?? 0)
        swapFree = Number(text.match(/SwapFree: *(\d+)/)?.[1] ?? 0)
        updateMemoryUsageHistory()
        updateSwapUsageHistory()
    }
    function acceptCpu(text) {
        const line = text.match(/^cpu\s+(.+)$/m)
        if (!line) return
        // guest/guest_nice are already included in user/nice. Include steal,
        // and count iowait as idle instead of reporting it as CPU execution.
        const stats = line[1].trim().split(/\s+/).slice(0, 8).map(Number)
        if (stats.length < 8 || !stats.every(Number.isFinite)) return
        const total = stats.reduce((a, b) => a + b, 0)
        const idle = stats[3] + stats[4]
        if (previousCpuStats) {
            const delta = total - previousCpuStats.total
            const idleDelta = idle - previousCpuStats.idle
            if (delta > 0 && idleDelta >= 0) {
                cpuUsage = Math.max(0, Math.min(1, 1 - idleDelta / delta))
                updateCpuUsageHistory()
            }
        }
        previousCpuStats = { total, idle }
    }
    Timer {
        interval: Math.max(1000, Config?.options.resources.updateInterval ?? 3000)
        running: root.activeConsumers > 0
        repeat: true
        // preload performs the first read. Parse only completed async loads.
        onTriggered: { fileMeminfo.reload(); fileStat.reload() }
    }
    FileView {
        id: fileMeminfo
        path: "/proc/meminfo"
        preload: root.activeConsumers > 0
        blockLoading: false
        onLoaded: root.acceptMemory(text())
    }
    FileView {
        id: fileStat
        path: "/proc/stat"
        preload: root.activeConsumers > 0
        blockLoading: false
        onLoaded: root.acceptCpu(text())
    }

    Process {
        id: findCpuMaxFreqProc
        environment: ({ LANG: "C", LC_ALL: "C" })
        command: ["bash", "-c", "lscpu | grep 'CPU max MHz' | awk '{print $4}'"]
        running: true
        stdout: StdioCollector {
            id: outputCollector
            onStreamFinished: {
                root.maxAvailableCpuString = (parseFloat(outputCollector.text) / 1000).toFixed(0) + " GHz"
            }
        }
    }
}
