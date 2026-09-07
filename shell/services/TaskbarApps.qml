pragma Singleton

import qs.modules.common
import QtQuick
import Quickshell
import Quickshell.Wayland

Singleton {
    id: root

    function isPinned(appId) {
        const normalizedId = String(appId ?? "").toLowerCase()
        return Config.options.dock.pinnedApps.some(id => String(id).toLowerCase() === normalizedId)
    }

    function togglePin(appId) {
        if (root.isPinned(appId)) {
            const normalizedId = String(appId ?? "").toLowerCase()
            Config.options.dock.pinnedApps = Config.options.dock.pinnedApps.filter(id => String(id).toLowerCase() !== normalizedId)
        } else {
            Config.options.dock.pinnedApps = Config.options.dock.pinnedApps.concat([appId])
        }
    }

    function launch(appId, desktopEntry) {
        // `byId` is a direct lookup in Quickshell's already-loaded index. It
        // preserves each application's native launch command without the
        // extra gtk-launch process, while deliberately avoiding the fuzzy
        // heuristic lookup that caused the post-open UI stalls.
        const entry = desktopEntry ?? DesktopEntries.byId(appId)
        AppLaunchService.launchDesktopEntry(appId, entry,
            root.iconFor(appId), appId)
    }

    // A taskbar update happens for every opened, closed, or focused window.
    // Do not fuzzy-search the desktop-entry index from every dock delegate in
    // that hot path: indexing the full applications list can block QML just
    // after a file manager maps a new window. The icon provider resolves this
    // short, stable name lazily when the image is actually drawn.
    property var iconCache: ({})
    function iconFor(appId) {
        const raw = String(appId ?? "").trim()
        const key = raw.toLowerCase()
        if (key === "") return "application-x-executable"
        if (root.iconCache[key] !== undefined) return root.iconCache[key]

        const knownIcons = {
            "code-url-handler": "visual-studio-code",
            "code": "visual-studio-code",
            "org.kde.dolphin": "org.kde.dolphin",
            "dolphin": "org.kde.dolphin",
            "org.xfce.thunar": "org.xfce.thunar",
            "thunar": "org.xfce.thunar",
            "org.gnome.nautilus": "org.gnome.Nautilus",
            "nautilus": "org.gnome.Nautilus",
            "code-oss": "com.visualstudio.code.oss",
            // These two desktop files deliberately use icons outside the
            // current icon-theme lookup paths, so keep their verified image
            // files explicit instead of falling back to an invisible icon.
            "kittiy-ar": "/home/professorx/.local/opt/kittiy-ar/share/icons/hicolor/256x256/apps/kitty.png",
            "chatgpt": "/usr/share/pixmaps/chatgpt.png"
        }
        const icon = knownIcons[key]
            ?? (raw.includes(".") ? raw.split(".").pop() : raw)
        root.iconCache[key] = icon
        return icon
    }

    function iconSourceFor(appId, fallbackIcon) {
        const icon = root.iconFor(appId)
        return icon.startsWith("/") ? "file://" + icon
            : Quickshell.iconPath(icon, fallbackIcon ?? "image-missing")
    }

    property list<var> apps: {
        var map = new Map();

        // Pinned apps
        const pinnedApps = Config.options?.dock.pinnedApps ?? [];
        for (const appId of pinnedApps) {
            if (!map.has(appId.toLowerCase())) map.set(appId.toLowerCase(), ({
                pinned: true,
                toplevels: []
            }));
        }

        // Separator
        if (pinnedApps.length > 0) {
            map.set("SEPARATOR", { pinned: false, toplevels: [] });
        }

        // Ignored apps
        const ignoredRegexStrings = Config.options?.dock.ignoredAppRegexes ?? [];
        const ignoredRegexes = ignoredRegexStrings.map(pattern => new RegExp(pattern, "i"));
        // Open windows
        for (const toplevel of ToplevelManager.toplevels.values) {
            if (ignoredRegexes.some(re => re.test(toplevel.appId))) continue;
            if (!map.has(toplevel.appId.toLowerCase())) map.set(toplevel.appId.toLowerCase(), ({
                pinned: false,
                toplevels: []
            }));
            map.get(toplevel.appId.toLowerCase()).toplevels.push(toplevel);
        }

        var values = [];

        for (const [key, value] of map) {
            // `apps` is a derived value and is rebuilt whenever the toplevel
            // model changes. Creating an unparented QtObject here leaked one
            // object per entry per update, then made the QML GC work hard
            // whenever a file opener added a window. Consumers only need data,
            // so keep these short-lived entries as plain JavaScript objects.
            values.push({ appId: key, toplevels: value.toplevels, pinned: value.pinned });
        }

        return values;
    }
}
