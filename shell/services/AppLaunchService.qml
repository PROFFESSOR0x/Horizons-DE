pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import qs.modules.common
import qs.services

Singleton {
    id: root

    property bool active: false
    property string appId: ""
    property string iconName: "application-x-executable"
    property string appName: ""
    // Addresses are cheap, stable compositor data. Keeping them avoids
    // scanning/constructing Toplevel wrappers when a launcher or Dolphin
    // creates a window under load.
    property var previousWindowAddresses: []
    property string targetScreenName: ""
    property int targetWorkspaceId: -1
    property string targetAddress: ""
    property var targetRect: null
    property real progress: 0
    property double startedAt: 0
    property bool windowSeen: false
    // A launcher we invoke can finish as soon as its first mapped window has
    // geometry. A window opened by Dolphin/Thunar is first observable only at
    // that point, so it needs a short visual dwell instead of vanishing in the
    // same compositor beat.
    property bool externalLaunch: false

    function normalize(value) {
        return String(value ?? "").toLowerCase()
    }

    function normalizeAddress(value) {
        return String(value ?? "").toLowerCase().replace(/^0x/, "")
    }

    function canonicalAppId(value) {
        const raw = normalize(value).replace(/\.desktop$/, "")
        const parts = raw.split(".")
        return parts[parts.length - 1]
    }

    function begin(appIdValue, iconValue, nameValue, addressValue, fromExternal) {
        root.appId = root.normalize(appIdValue)
        root.iconName = iconValue || "application-x-executable"
        root.appName = nameValue || appIdValue
        root.previousWindowAddresses = HyprlandData.windowList
            .map(window => root.normalizeAddress(window?.address))
            .filter(address => address !== "")
        root.targetScreenName = Hyprland.focusedMonitor?.name ?? ""
        root.targetWorkspaceId = Hyprland.focusedMonitor?.activeWorkspace?.id ?? -1
        root.targetAddress = String(addressValue ?? "")
        root.targetRect = null
        root.progress = 0.04
        root.startedAt = Date.now()
        root.windowSeen = false
        root.externalLaunch = Boolean(fromExternal)
        root.active = true
        timeoutTimer.restart()
    }

    function iconForExternalApp(appIdValue) {
        const id = root.normalize(appIdValue)
        const knownIcons = {
            "geany": "geany",
            // Use the applications' actual non-symbolic desktop icons. The
            // generic system-file-manager name commonly resolves to a dark
            // symbolic glyph, which was the black icon seen in the indicator.
            "org.kde.dolphin": "org.kde.dolphin",
            "dolphin": "org.kde.dolphin",
            "org.xfce.thunar": "org.xfce.thunar",
            "thunar": "org.xfce.thunar",
            "org.gnome.nautilus": "org.gnome.Nautilus",
            "nautilus": "org.gnome.Nautilus",
            "firefox": "firefox",
            "kitty": "kitty",
            "code": "visual-studio-code"
        }
        // Most Wayland classes use a reverse-domain desktop id while the
        // icon theme uses its last component (org.kde.gwenview -> gwenview).
        // This is a constant-time fallback and deliberately does not fuzzy
        // search desktop entries on Hyprland's event thread.
        return knownIcons[id] || root.canonicalAppId(id) || id || "application-x-executable"
    }

    function launch(appIdValue, iconValue, nameValue, launcher) {
        const id = normalize(appIdValue)
        if (id === "") {
            launcher()
            return
        }

        if (!Config.options.appLaunch.showIndicator) {
            launcher()
            return
        }

        root.begin(appIdValue, iconValue, nameValue, "", false)
        // The indicator is intentionally cosmetic. Do not delay launching by
        // a frame (or 34 ms): terminal and file-manager launches execute
        // immediately, and the shell must offer the same responsiveness.
        launcher()
    }

    function launchDesktopEntry(appIdValue, desktopEntry, iconValue, nameValue) {
        launch(appIdValue, iconValue, nameValue, () => {
            if (desktopEntry) desktopEntry.execute()
            else if (appIdValue) Quickshell.execDetached(["gtk-launch", appIdValue])
        })
    }

    function windowMatches(window) {
        const expected = canonicalAppId(root.appId)
        return [window?.appId, window?.class, window?.initialClass]
            .some(value => canonicalAppId(value) === expected)
    }

    function checkForWindow() {
        if (!root.active) return
        const geometryReady = root.updateTargetGeometry()
        if (geometryReady) {
            if (!root.windowSeen) {
                root.windowSeen = true
                root.progress = 1
                // A mapped window with a real geometry is ready; leave one
                // short composited beat so the indicator never disappears
                // before the new application is visible.
                readyTimer.restart()
            }
        }
    }

    function updateTargetGeometry() {
        const visibleWindows = HyprlandData.windowList.filter(window => {
            const address = String(window?.address ?? "")
            const hasGeometry = Array.isArray(window?.at) && Array.isArray(window?.size)
                && Number(window.size[0]) > 0 && Number(window.size[1]) > 0
            return window?.mapped !== false && window?.hidden !== true && hasGeometry
                && (root.targetAddress === ""
                    || root.normalizeAddress(address) === root.normalizeAddress(root.targetAddress))
        })
        const newWindows = visibleWindows.filter(window =>
            root.previousWindowAddresses.indexOf(root.normalizeAddress(window?.address)) === -1)
        // Prefer the expected app among newly-created windows. Desktop ids and
        // Wayland classes often differ (org.kde.dolphin vs dolphin), so if a
        // launch created exactly one visible window use it as a safe fallback.
        const candidates = (root.targetAddress !== "" ? visibleWindows
            : newWindows.filter(root.windowMatches))
        const window = candidates[candidates.length - 1]
            ?? (root.targetAddress === "" && newWindows.length === 1 ? newWindows[0] : null)
        if (!window) return false
        root.targetScreenName = root.screenNameForWindow(window)
        root.targetWorkspaceId = Number(window.workspace?.id ?? root.targetWorkspaceId)
        root.targetRect = {
            x: Number(window.at[0]), y: Number(window.at[1]),
            width: Number(window.size[0]), height: Number(window.size[1])
        }
        return true
    }

    function screenNameForWindow(window) {
        const monitor = window?.monitor
        const matchingMonitor = HyprlandData.monitors.find(candidate =>
            String(candidate?.name) === String(monitor)
            || Number(candidate?.id) === Number(monitor))
        return matchingMonitor?.name ?? root.targetScreenName
    }

    function startExternal(appIdValue, addressValue, appNameValue) {
        if (!Config.options.appLaunch.showIndicator || !(Config.options.appLaunch?.trackExternal ?? false) || !appIdValue) return
        // Keep compositor event handling free of desktop-entry and icon index
        // lookups. Those indexes can be busy while a file opener starts.
        root.begin(appIdValue, root.iconForExternalApp(appIdValue), appNameValue, addressValue, true)
        // HyprlandData may already contain the new address by the time the
        // raw event is delivered. Check once on the next event-loop turn
        // rather than waiting for an unrelated compositor refresh.
        Qt.callLater(root.checkForWindow)
    }

    function finish() {
        readyTimer.stop()
        timeoutTimer.stop()
        root.active = false
        root.externalLaunch = false
    }

    Timer {
        id: readyTimer
        // An external opener reports only after the target is mapped. Keep it
        // visible long enough to be perceived, without tying it to I/O or a
        // desktop-entry lookup.
        interval: root.externalLaunch ? 520 : 140
        repeat: false
        onTriggered: root.finish()
    }

    Timer {
        id: timeoutTimer
        repeat: false
        interval: Math.max(1000, Config.options.appLaunch.timeout)
        onTriggered: root.finish()
    }

    Timer {
        id: progressTimer
        interval: 120
        repeat: true
        running: root.active
        onTriggered: root.progress = Math.min(0.92,
            (Date.now() - root.startedAt) / Math.max(1000, Config.options.appLaunch.timeout))
    }

    Connections {
        target: HyprlandData
        function onWindowListChanged() {
            root.checkForWindow()
        }
    }

    Connections {
        target: Hyprland
        enabled: WM.compositor === "hyprland"
        function onRawEvent(event) {
            if (event.name !== "openwindow") return
            const fields = String(event.data ?? "").split(",")
            // Hyprland openwindow is address, workspace, class, title.  The
            // workspace id was previously treated as the app id, forcing the
            // generic dark fallback icon for files launched from a file
            // manager (and every other externally-created window).
            if (fields.length >= 3 && !root.active && Boolean(Config.options.appLaunch?.trackExternal ?? false))
                root.startExternal(fields[2], fields[0], fields[3] || fields[2])
        }
    }

}
