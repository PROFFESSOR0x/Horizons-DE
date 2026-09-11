pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import qs.services
import qs.modules.common
import qs.modules.common.widgets

StyledComboBoxSearch {
    id: root

    property string currentValue: ""
    property string valueMode: "appId"
    property bool allowEmpty: false
    property string emptyLabel: Translation.tr("System default")

    signal selected(var newValue)

    textRole: "displayName"
    model: applicationModel

    readonly property string normalizedCurrentValue: normalizeValue(root.currentValue)
    readonly property var applicationModel: {
        const seen = new Set()
        const entries = []
        for (const app of Array.from(DesktopEntries.applications.values)) {
            const id = String(app?.id ?? "").trim()
            if (id === "") continue
            const value = root.valueForId(id)
            const key = value.toLowerCase()
            if (seen.has(key)) continue
            seen.add(key)
            const name = String(app?.name ?? id).trim()
            entries.push({
                displayName: (name || value) + " (" + value + ")",
                value: value,
                sortName: (name || value).toLowerCase()
            })
        }
        entries.sort((a, b) => a.sortName.localeCompare(b.sortName)
            || a.value.localeCompare(b.value))
        if (root.normalizedCurrentValue !== ""
                && !entries.some(entry => entry.value.toLowerCase() === root.normalizedCurrentValue.toLowerCase())) {
            entries.unshift({
                displayName: Translation.tr("Current value: %1").arg(root.normalizedCurrentValue),
                value: root.normalizedCurrentValue,
                sortName: ""
            })
        }
        if (root.allowEmpty)
            entries.unshift({displayName: root.emptyLabel, value: "", sortName: ""})
        return entries
    }

    currentIndex: {
        const index = root.model.findIndex(entry =>
            String(entry.value).toLowerCase() === root.normalizedCurrentValue.toLowerCase())
        return index >= 0 ? index : 0
    }

    function valueForId(id) {
        const value = String(id ?? "").trim()
        if (root.valueMode === "desktopFile" && value !== "" && !value.endsWith(".desktop"))
            return value + ".desktop"
        if (root.valueMode === "appId" && value.endsWith(".desktop"))
            return value.slice(0, -8)
        return value
    }

    function normalizeValue(value) {
        return root.valueForId(value)
    }

    onActivated: index => {
        root.selected(root.model[index]?.value ?? "")
    }
}
