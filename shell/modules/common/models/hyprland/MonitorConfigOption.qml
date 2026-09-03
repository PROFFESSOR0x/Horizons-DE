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

    // Indices touched by the most recent updateMonitor() call: the monitor that was
    // directly edited, plus any neighbors whose position was recomputed because a
    // scale change moved the edited monitor's right/bottom edge (see updateMonitor).
    property var _affectedIndices: []

    function updateMonitor(index, changes) {
        let m = root.monitors.slice()
        const old = m[index]
        const scaleChanging = Object.prototype.hasOwnProperty.call(changes, "scale")
            && changes.scale !== old.scale

        if (!scaleChanging) {
            m[index] = Object.assign({}, old, changes)
            root.monitors = m
            root._affectedIndices = [index]
            return
        }

        // Hyprland positions are logical (post-scale) pixels. When this monitor's
        // scale changes, its logical width/height changes even though its physical
        // resolution and its x/y anchor do not. Any other monitor that was placed
        // flush against this monitor's OLD right or bottom edge must be shifted by
        // the resulting delta, or it is left with a stale position: no gap at
        // scale 1.0 (physical == logical), but a real empty gap (and an
        // uncrossable cursor dead zone) once the scale changes.
        // Rounded to whole logical pixels: monitor positions are integers, and
        // Hyprland's own scale values (e.g. 1.75x) don't always divide evenly.
        const oldLogW = Math.round(root.logicalWidth(old))
        const oldLogH = Math.round(root.logicalHeight(old))
        m[index] = Object.assign({}, old, changes)
        const newLogW = Math.round(root.logicalWidth(m[index]))
        const newLogH = Math.round(root.logicalHeight(m[index]))
        const dx = newLogW - oldLogW
        const dy = newLogH - oldLogH

        let affected = [index]
        if (dx !== 0 || dy !== 0) {
            const oldRight = old.x + oldLogW
            const oldBottom = old.y + oldLogH
            for (let i = 0; i < m.length; i++) {
                if (i === index || m[i].disabled) continue
                let nx = m[i].x, ny = m[i].y, changed = false
                if (dx !== 0 && m[i].x === oldRight) { nx += dx; changed = true }
                if (dy !== 0 && m[i].y === oldBottom) { ny += dy; changed = true }
                if (changed) {
                    m[i] = Object.assign({}, m[i], { x: nx, y: ny })
                    affected.push(i)
                }
            }
        }

        root.monitors = m
        root._affectedIndices = affected
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
        // If the last updateMonitor() call recomputed neighbor positions (a scale
        // change moved this monitor's edge), push all of them to hyprctl too --
        // otherwise the live layout keeps the stale gap until the next full reload.
        const indices = (root._affectedIndices.length > 0 && root._affectedIndices.indexOf(index) !== -1)
            ? root._affectedIndices : [index]
        for (let i = 0; i < indices.length; i++)
            root.applyMonitor(root.monitors[indices[i]])
        root.save()
    }

    // Physical pixel width/height (post-transform, pre-scale). Do NOT use this for
    // positioning math -- Hyprland's monitor "position" field is in LOGICAL
    // (post-scale) pixels, so adjacent-monitor offsets must use logicalWidth()/
    // logicalHeight() below instead.
    function physicalWidth(m) {
        return (m.transform === 1 || m.transform === 3) ? m.height : m.width
    }

    function physicalHeight(m) {
        return (m.transform === 1 || m.transform === 3) ? m.width : m.height
    }

    // Logical (post-scale) width/height, i.e. what Hyprland actually uses for
    // monitor "position" arithmetic. physical / scale.
    function logicalWidth(m) {
        return root.physicalWidth(m) / (m.scale || 1)
    }

    function logicalHeight(m) {
        return root.physicalHeight(m) / (m.scale || 1)
    }

    function logicalSizeDisplay(m) {
        return `${Math.round(logicalWidth(m))}×${Math.round(logicalHeight(m))}`
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
