import QtQuick
import qs.services
import "SettingsCatalog.js" as Catalog

QtObject {
    // Page ids and option ids never depend on the interface language.
    readonly property var pages: [
        { id: "appearance", name: Translation.tr("Appearance"), icon: "palette", advanced: false, details: "effects" },
        { id: "widgets", name: Translation.tr("Widgets"), icon: "widgets", advanced: false, details: "widget-details" },
        { id: "panels", name: Translation.tr("Panels"), icon: "dock_to_bottom", advanced: false, details: "panel-details" },
        { id: "session", name: Translation.tr("Lock & power"), icon: "lock", advanced: false, details: "session-details" },
        { id: "notifications", name: Translation.tr("Notifications"), icon: "notifications", advanced: false, details: "notification-rules" },
        { id: "devices", name: Translation.tr("Displays & input"), icon: "devices", advanced: false, details: "input-details" },
        { id: "apps", name: Translation.tr("Apps & search"), icon: "apps", advanced: false, details: "integrations" },
        { id: "capture", name: Translation.tr("Capture"), icon: "screenshot_monitor", advanced: false, details: "capture-details" },
        { id: "personal", name: Translation.tr("Personal"), icon: "person", advanced: false, details: "system" },
        { id: "users", name: Translation.tr("Users"), icon: "group", advanced: false, details: "login" },
        { id: "login", name: Translation.tr("Login options"), icon: "login", advanced: true },
        { id: "effects", name: Translation.tr("Visual effects"), icon: "animation", advanced: true },
        { id: "widget-details", name: Translation.tr("Widget options"), icon: "tune", advanced: true },
        { id: "panel-details", name: Translation.tr("Panel options"), icon: "dashboard_customize", advanced: true },
        { id: "session-details", name: Translation.tr("Lock options"), icon: "lock_open", advanced: true },
        { id: "notification-rules", name: Translation.tr("Alert rules"), icon: "notifications_active", advanced: true },
        { id: "window-rules", name: Translation.tr("Window rules"), icon: "select_window", advanced: true },
        { id: "input-details", name: Translation.tr("Shortcuts"), icon: "keyboard", advanced: true },
        { id: "integrations", name: Translation.tr("Integrations"), icon: "manage_search", advanced: true },
        { id: "capture-details", name: Translation.tr("Capture options"), icon: "movie_edit", advanced: true },
        { id: "system", name: Translation.tr("System"), icon: "settings", advanced: true },
        { id: "about", name: Translation.tr("About"), icon: "info", advanced: false }
    ]
    readonly property var sources: ["QuickConfig", "ExperienceConfig", "BackgroundConfig", "BarConfig", "GeneralConfig", "InterfaceConfig", "ServicesConfig", "HyprlandSettings", "NiriSettings", "KeybindsConfig", "Profile", "SystemUsers", "About"]
        .filter(name => supported(name))
    function supported(source) {
        return source === "HyprlandSettings" || source === "KeybindsConfig" ? WM.compositor === "hyprland"
            : source !== "NiriSettings" || WM.compositor === "niri"
    }
    function contributes(source, route) {
        if (source === "About") return route === "about"
        return Catalog.entries.some(entry => entry.source === source && entry.routes.includes(route))
    }
    function pageFor(id) { return pages.find(page => page.id === id) ?? pages[0] }
    readonly property var searchIndex: Catalog.entries.filter(entry => supported(entry.source)).map(entry => {
        const page = pageFor(entry.route)
        const label = Translation.tr(entry.label)
        const section = Translation.tr(entry.section)
        return Object.assign({}, entry, {
            pageName: page.name, pageIcon: page.icon, sectionTitle: label,
            advanced: page.advanced, settingLabels: [section],
            haystack: [label, section, page.name, entry.label, entry.section, entry.legacyPage, entry.keywords,
                ...(entry.legacySections ?? []).map(value => Translation.tr(value))].join(" • ")
        })
    })
    function resolveLegacy(value) {
        const parts = value.split(":")
        const page = parts.shift().trim().toLowerCase()
        const term = parts.join(":").trim().toLowerCase()
        const current = pages.find(item => item.id === page || item.name.toLowerCase() === page)
        if (current && term === "") return { route: current.id }
        const candidates = searchIndex.filter(entry => current ? entry.routes.includes(current.id)
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
        return { route: current?.id ?? defaults[english] ?? "appearance" }
    }
}
