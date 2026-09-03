pragma Singleton
pragma ComponentBehavior: Bound

import qs.modules.common
import qs.modules.common.functions
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

/**
 * A service that provides access to Hyprland keybinds.
 * Uses the `get_keybinds.py` script to parse comments in config files in a certain format and convert to JSON.
 */
Singleton {
    id: root
    property string keybindParserPath: FileUtils.trimFileProtocol(`${Directories.scriptPath}/hyprland/get_keybinds.py`)
    property string defaultKeybindConfigPath: FileUtils.trimFileProtocol(`${Directories.config}/hypr/hyprland/keybinds.lua`)
    property string userKeybindConfigPath: FileUtils.trimFileProtocol(`${Directories.config}/hypr/custom/keybinds.lua`)
    property var defaultKeybinds: {"children": []}
    property var userKeybinds: {"children": []}
    property var keybinds: ({
        children: [
            ...(defaultKeybinds.children ?? []),
            ...(userKeybinds.children ?? []),
        ]
    })

    Connections {
        target: Hyprland

        function onRawEvent(event) {
            if (event.name == "configreloaded") {
                getDefaultKeybinds.running = true
                getUserKeybinds.running = true
            }
        }
    }

    Process {
        id: getDefaultKeybinds
        running: true
        command: [root.keybindParserPath, "--path", root.defaultKeybindConfigPath]
        
        stdout: SplitParser {
            onRead: data => {
                try {
                    root.defaultKeybinds = JSON.parse(data)
                } catch (e) {
                    console.error("[CheatsheetKeybinds] Error parsing keybinds:", e)
                }
            }
        }
    }

    Process {
        id: getUserKeybinds
        running: true
        command: [root.keybindParserPath, "--path", root.userKeybindConfigPath]

        stdout: SplitParser {
            onRead: data => {
                try {
                    root.userKeybinds = JSON.parse(data)
                } catch (e) {
                    console.error("[CheatsheetKeybinds] Error parsing keybinds:", e)
                }
            }
        }
    }

    // ── Shared helpers ────────────────────────────────────────────────────
    // Used by both the full Settings > Keybinds page (KeybindsConfig.qml) and
    // the lightweight Super+/ cheat-sheet overlay (KeybindsOverlay.qml) so the
    // "what sections/binds exist" and "does this bind match my search" logic
    // only lives in one place.

    // Flattens the section tree (which nests via children) into a plain list
    // of sections that actually have keybinds to show.
    function flatSections() {
        const src = root.keybinds
        if (!src || !src.children) return []
        let out = []
        function collect(node) {
            if (node.keybinds && node.keybinds.length > 0) out.push(node)
            if (node.children) for (let c of node.children) collect(c)
        }
        for (let ch of src.children) collect(ch)
        return out
    }

    function formatKeybind(mods, key) {
        let arr = []
        if (mods) for (let m of mods) arr.push(m)
        if (key && key.length > 0) arr.push(key)
        return arr.join(" + ")
    }

    function matchesSearch(bind, q) {
        if (!q || q.trim() === "") return true
        const s = q.toLowerCase()
        const kb = root.formatKeybind(bind.mods, bind.key).toLowerCase()
        const c = (bind.comment ?? "").toLowerCase()
        const d = (bind.dispatcher ?? "").toLowerCase()
        const p = (bind.params ?? "").toLowerCase()
        return kb.includes(s) || c.includes(s) || d.includes(s) || p.includes(s)
    }

    // The "logical action" a bind triggers, used to group multiple hl.bind
    // lines (different key combos) that all trigger the same
    // dispatcher+params into one row instead of unrelated-looking duplicates.
    // Returns null for synthetic/display-only entries, which are never grouped.
    function actionKey(bind) {
        if (!bind || bind.dispatcher === "comment") return null
        if (bind.dispatcher === "function") {
            // Inline `function() ... end` binds don't get parsed params, so
            // fall back to the raw call text (description stripped, since two
            // otherwise-identical function binds may carry different
            // descriptions per key combo).
            const stripped = (bind.rest ?? "").replace(/\{[^{}]*description\s*=\s*"[^"]*"[^{}]*\}/, "")
            return "fn:" + stripped.trim()
        }
        return "d:" + (bind.dispatcher ?? "") + "|p:" + (bind.params ?? "")
    }

    // Groups a flat list of binds by actionKey(). Each group is
    // { key, binds: [...] } with binds in encounter order; group.binds[0] is
    // the representative bind (comment/dispatcher/params to display).
    function groupKeybinds(binds) {
        let groups = []
        let indexByKey = {}
        for (let b of (binds ?? [])) {
            const key = root.actionKey(b)
            if (key === null) {
                groups.push({ key: null, binds: [b] })
                continue
            }
            if (indexByKey[key] === undefined) {
                indexByKey[key] = groups.length
                groups.push({ key: key, binds: [] })
            }
            groups[indexByKey[key]].binds.push(b)
        }
        return groups
    }
}

