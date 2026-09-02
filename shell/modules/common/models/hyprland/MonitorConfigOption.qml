pragma ComponentBehavior: Bound
import QtQml
import QtQuick
import Quickshell.Io
import qs.services
import "../"

NestableObject {
    id: root

    property var monitors: []

    Component.onCompleted: fetchProc.running = true

    function updateMonitor(index, changes) {
        let m = root.monitors.slice()
        m[index] = Object.assign({}, m[index], changes)
        root.monitors = m
    }

    function _buildLuaLine(m) {
        if (m.disabled)
            return `hl.monitor({ output = "${m.name}", mode = "disabled" })`

        let parts = []
        parts.push(`output = "${m.name}"`)
        parts.push(`mode = "${m.currentMode}"`)

        const pos = `${m.x}x${m.y}`
        parts.push(`position = "${pos}"`)
        parts.push(`scale = ${m.scale}`)

        if (m.transform && m.transform !== 0)
            parts.push(`transform = ${m.transform}`)

        // Mirror
        if (m.mirror && m.mirror.length > 0 && m.mirror !== "" && m.mirror !== "none")
            parts.push(`mirror = "${m.mirror}"`)

        // Bitdepth
        if (m.bitdepth && m.bitdepth !== 8)
            parts.push(`bitdepth = ${m.bitdepth}`)

        // VRR (variable refresh rate)
        if (m.vrr && m.vrr !== 0)
            parts.push(`vrr = ${m.vrr}`)

        // Color management
        if (m.cm && m.cm !== "" && m.cm !== "auto")
            parts.push(`cm = "${m.cm}"`)

        // ICC profile
        if (m.iccProfile && m.iccProfile.length > 0)
            parts.push(`icc_profile = "${m.iccProfile}"`)

        // Reserved area (per-side)
        if (m.reservedArea) {
            const r = m.reservedArea
            if (typeof r === "object" && (r.top || r.bottom || r.left || r.right)) {
                parts.push(`reserved_area = { top = ${r.top || 0}, bottom = ${r.bottom || 0}, left = ${r.left || 0}, right = ${r.right || 0} }`)
            } else if (typeof r === "number" && r > 0) {
                parts.push(`reserved_area = ${r}`)
            }
        }

        return `hl.monitor({ ${parts.join(", ")} })`
    }

    function save() {
        if (root.monitors.length === 0) return
        if (root.monitors.some(m => !m.name)) return

        const lines = root.monitors.map(m => {
            const line = root._buildLuaLine(m)
            console.log(`[MonitorConfig] saving line: "${line}"`)
            return line
        }).join("\n")

        console.log(`[MonitorConfig] full file:\n${lines}`)

        const escaped = lines.replace(/'/g, "'\\''")
        saveProc.command = ["bash", "-c",
            `printf '%s\n' '${escaped}' > ~/.config/hypr/monitors.lua`]
        saveProc.running = true
    }

    function applyMonitor(m) {
        if (!m.name) return

        const base = `${m.name},${m.currentMode},${m.x}x${m.y},${m.scale}`
        let extra = []
        if (m.transform && m.transform !== 0)
            extra.push(`transform,${m.transform}`)
        if (m.mirror && m.mirror.length > 0 && m.mirror !== "" && m.mirror !== "none")
            extra.push(`mirror,${m.mirror}`)
        if (m.bitdepth && m.bitdepth !== 8)
            extra.push(`bitdepth,${m.bitdepth}`)
        if (m.vrr && m.vrr !== 0)
            extra.push(`vrr,${m.vrr}`)
        if (m.cm && m.cm !== "" && m.cm !== "auto")
            extra.push(`cm,${m.cm}`)

        let arg
        if (m.disabled) {
            arg = `${m.name},disable`
        } else if (extra.length > 0) {
            arg = `${base},${extra.join(",")}`
        } else {
            arg = base
        }

        applyProc.command = ["hyprctl", "keyword", "monitor", arg]
        applyProc.running = true
    }

    function applyAndSave(index) {
        root.applyMonitor(root.monitors[index])
        root.save()
    }

    function logicalWidth(m) {
        return (m.transform === 1 || m.transform === 3) ? m.height : m.width
    }

    function logicalHeight(m) {
        return (m.transform === 1 || m.transform === 3) ? m.width : m.height
    }

    function logicalSizeDisplay(m) {
        const w = logicalWidth(m)
        const h = logicalHeight(m)
        const scale = m.scale || 1
        return `${Math.round(w / scale)}×${Math.round(h / scale)}`
    }

    Process {
        id: fetchProc
        command: ["hyprctl", "monitors", "all", "-j"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.monitors = JSON.parse(text).map(m => ({
                        name:          m.name,
                        description:   m.description,
                        width:         m.width,
                        height:        m.height,
                        refreshRate:   m.refreshRate,
                        x:             m.x,
                        y:             m.y,
                        scale:         m.scale,
                        transform:     m.transform ?? 0,
                        disabled:      m.disabled,
                        availableModes: m.availableModes,
                        currentMode:   `${m.width}x${m.height}@${m.refreshRate.toFixed(2)}Hz`,
                        // New fields for advanced settings
                        mirror:        m.mirror ?? "",
                        bitdepth:      m.bitdepth ?? 8,
                        vrr:           m.vrr ?? 0,
                        cm:            m.cm ?? "",
                        iccProfile:    m.iccProfile ?? "",
                        reservedArea:  m.reserved_area ?? 0
                    }))
                } catch(e) {
                    console.log("[MonitorConfig] Error parsing JSON:", e)
                }
            }
        }
    }

    Process { id: applyProc }

    Process {
        id: saveProc
        onRunningChanged: if (!running) reloadProc.running = true
    }

    Process {
        id: reloadProc
        command: ["hyprctl", "reload"]
    }
}
