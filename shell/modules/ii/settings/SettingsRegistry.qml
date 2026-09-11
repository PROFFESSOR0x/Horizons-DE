import QtQuick
import qs.services
import "SettingsCatalog.js" as Catalog

QtObject {
    // Page ids and option ids never depend on the interface language.
    readonly property var routeAliases: ({
        appearance: ["appearance", "effects"],
        widgets: ["widgets", "widget-details"],
        panels: ["panels", "panel-details"],
        session: ["session", "session-details"],
        notifications: ["notifications", "notification-rules"],
        devices: ["devices", "input-details", "window-rules"],
        apps: ["apps", "integrations"],
        capture: ["capture", "capture-details"],
        personal: ["personal", "system"],
        users: ["users", "login"],
        about: ["about"],
    })
    readonly property var pages: [
        { id: "appearance", name: Translation.tr("Appearance"), icon: "palette" },
        { id: "widgets", name: Translation.tr("Widgets"), icon: "widgets" },
        { id: "panels", name: Translation.tr("Panels"), icon: "dock_to_bottom" },
        { id: "session", name: Translation.tr("Lock & power"), icon: "lock" },
        { id: "notifications", name: Translation.tr("Notifications"), icon: "notifications" },
        { id: "devices", name: Translation.tr("Displays & input"), icon: "devices" },
        { id: "apps", name: Translation.tr("Apps & search"), icon: "apps" },
        { id: "capture", name: Translation.tr("Capture"), icon: "screenshot_monitor" },
        { id: "personal", name: Translation.tr("Personal"), icon: "person" },
        { id: "users", name: Translation.tr("Users"), icon: "group" },
        { id: "about", name: Translation.tr("About"), icon: "info" }
    ]
    readonly property var sources: ["QuickConfig", "ExperienceConfig", "BackgroundConfig", "BarConfig", "GeneralConfig", "InterfaceConfig", "ServicesConfig", "HyprlandSettings", "NiriSettings", "KeybindsConfig", "Profile", "SystemUsers", "About"]
        .filter(name => supported(name))
    function supported(source) {
        return source === "HyprlandSettings" || source === "KeybindsConfig" ? WM.compositor === "hyprland"
            : source !== "NiriSettings" || WM.compositor === "niri"
    }
    function canonicalRoute(route) {
        for (const id of Object.keys(routeAliases)) {
            if ((routeAliases[id] ?? []).includes(route)) return id
        }
        return route
    }
    function aliasesFor(route) {
        const canonical = canonicalRoute(route)
        return routeAliases[canonical] ?? [canonical]
    }
    function contributes(source, route) {
        const aliases = aliasesFor(route)
        if (source === "About") return aliases.includes("about")
        return Catalog.entries.some(entry => entry.source === source
            && entry.routes.some(entryRoute => aliases.includes(entryRoute)))
    }
    function pageFor(id) { return pages.find(page => page.id === id) ?? pages[0] }
    readonly property var searchIndex: Catalog.entries.filter(entry => supported(entry.source)).map(entry => {
        const route = canonicalRoute(entry.route)
        const page = pageFor(route)
        const label = Translation.tr(entry.label)
        const section = Translation.tr(entry.section)
        return Object.assign({}, entry, {
            sourceRoute: entry.route, route: route,
            pageName: page.name, pageIcon: page.icon, sectionTitle: label,
            advanced: false, settingLabels: [section],
            haystack: [label, section, page.name, entry.label, entry.section, entry.legacyPage, entry.keywords,
                ...(entry.legacySections ?? []).map(value => Translation.tr(value))].join(" • ")
        })
    })
    function resolveLegacy(value) {
        const parts = value.split(":")
        const page = parts.shift().trim().toLowerCase()
        const term = parts.join(":").trim().toLowerCase()
        const current = pages.find(item => item.id === page || item.name.toLowerCase() === page)
        const aliased = pages.find(item => item.id === canonicalRoute(page))
        if (current && term === "") return { route: current.id }
        if (aliased && term === "") return { route: aliased.id }
        const candidates = searchIndex.filter(entry => current ? entry.route === current.id
            : aliased ? entry.route === aliased.id
            : entry.legacyPage.toLowerCase() === page || Translation.tr(entry.legacyPage).toLowerCase() === page)
        if (term !== "") {
            const exact = candidates.find(entry => entry.label.toLowerCase() === term || entry.sectionTitle.toLowerCase() === term)
            if (exact) return exact
            const groupMatches = candidates.filter(entry => [entry.section, ...entry.legacySections].some(label => label.toLowerCase() === term || Translation.tr(label).toLowerCase() === term))
            const group = groupMatches.find(entry => !entry.advanced) ?? groupMatches[0]
            if (group) return group
            const partial = candidates.find(entry => entry.haystack.toLowerCase().includes(term))
            if (partial) return partial
        }
        const defaults = { quick: "appearance", general: "personal", desktop: "widgets", bar: "panels", interface: "appearance", experience: "appearance", services: "apps", hyprland: "devices", niri: "devices", keybinds: "devices", profile: "personal", about: "about" }
        const english = Object.keys(defaults).find(name => name === page || Translation.tr(name.charAt(0).toUpperCase() + name.slice(1)).toLowerCase() === page)
        return { route: current?.id ?? aliased?.id ?? defaults[english] ?? "appearance" }
    }
}
