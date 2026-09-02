pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets

ContentPage {
    id: page
    forceWidth: true

    property string searchQuery: ""
    property var selectedBind: null
    property string pendingNewKeyStr: ""
    property var pendingNewMods: []
    property string pendingNewKey: ""

    function goTo(term) {
        const t = term.toLowerCase().trim()
        function findTarget(rootItem) {
            for (let i = 0; i < rootItem.children.length; i++) {
                let child = rootItem.children[i]
                if (child.title && child.title.toLowerCase().includes(t)) return child
            }
            for (let i = 0; i < rootItem.children.length; i++) {
                let found = findTarget(rootItem.children[i])
                if (found) return found
            }
            return null
        }
        let target = findTarget(mainLayout)
        if (target) {
            let pos = target.mapToItem(mainLayout, 0, 0)
            page.contentY = Math.max(0, pos.y - 0)
        }
    }

    function flatSections() {
        const src = HyprlandKeybinds.keybinds
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

    function isEditable(bind) {
        if (!bind) return false
        if (bind.dispatcher === "comment") return false
        // function binds are now editable thanks to rest field
        if (!bind.comment || bind.comment.length === 0) return false
        return true
    }

    function matchesSearch(bind, q) {
        if (!q || q.trim() === "") return true
        const s = q.toLowerCase()
        const kb = formatKeybind(bind.mods, bind.key).toLowerCase()
        const c = (bind.comment ?? "").toLowerCase()
        const d = (bind.dispatcher ?? "").toLowerCase()
        const p = (bind.params ?? "").toLowerCase()
        return kb.includes(s) || c.includes(s) || d.includes(s) || p.includes(s)
    }

    function qtKeyToHyprland(key, text) {
        if (key >= Qt.Key_F1 && key <= Qt.Key_F35) return "F" + (key - Qt.Key_F1 + 1)
        switch (key) {
        case Qt.Key_Print: return "Print"
        case Qt.Key_Escape: return "Escape"
        case Qt.Key_Tab: return "Tab"
        case Qt.Key_Backtab: return "Tab"
        case Qt.Key_Backspace: return "BackSpace"
        case Qt.Key_Return: return "Return"
        case Qt.Key_Enter: return "Return"
        case Qt.Key_Space: return "Space"
        case Qt.Key_Insert: return "Insert"
        case Qt.Key_Delete: return "Delete"
        case Qt.Key_Home: return "Home"
        case Qt.Key_End: return "End"
        case Qt.Key_PageUp: return "Page_Up"
        case Qt.Key_PageDown: return "Page_Down"
        case Qt.Key_Left: return "Left"
        case Qt.Key_Up: return "Up"
        case Qt.Key_Right: return "Right"
        case Qt.Key_Down: return "Down"
        case Qt.Key_Super_L: return "SUPER_L"
        case Qt.Key_Super_R: return "SUPER_R"
        case Qt.Key_Menu: return "Menu"
        case Qt.Key_CapsLock: return "Caps_Lock"
        case Qt.Key_NumLock: return "Num_Lock"
        case Qt.Key_ScrollLock: return "Scroll_Lock"
        case 0x0100005a: return "XF86MonBrightnessUp"
        case 0x0100005b: return "XF86MonBrightnessDown"
        case 0x0100005c: return "XF86AudioLowerVolume"
        case 0x0100005d: return "XF86AudioRaiseVolume"
        case 0x0100005e: return "XF86AudioMute"
        case 0x01000055: return "XF86AudioNext"
        case 0x01000056: return "XF86AudioPrev"
        case 0x01000054: return "XF86AudioPlay"
        default:
            if (text && text.length === 1) return text.toUpperCase()
            return ""
        }
    }

    function captureFromEvent(event) {
        let mods = []
        if (event.modifiers & Qt.ControlModifier) mods.push("CTRL")
        if (event.modifiers & Qt.AltModifier) mods.push("ALT")
        if (event.modifiers & Qt.ShiftModifier) mods.push("SHIFT")
        if (event.modifiers & Qt.MetaModifier) mods.push("SUPER")
        let hyKey = qtKeyToHyprland(event.key, event.text)
        if (hyKey === "SUPER_L" || hyKey === "SUPER_R") {
            if (mods.length === 0) return null
        }
        const modKeys = ["Shift", "Control", "Alt", "Meta", "Super_L", "Super_R", "Hyper_L", "Hyper_R"]
        for (let mk of modKeys) if (hyKey === mk) return null
        if (hyKey === "" ) return null
        return { mods: mods, key: hyKey, str: (mods.length ? mods.join(" + ") + " + " : "") + hyKey }
    }

    Process {
        id: clearAllProc
        command: ["bash", "-c", `> '${StringUtils.shellSingleQuoteEscape(HyprlandConfig.customBindsPath)}'; hyprctl reload 2>/dev/null; echo cleared`]
    }
    Process {
        id: reloadBindsProc
        command: ["bash", "-c", `hyprctl reload 2>/dev/null; echo reloaded`]
    }

    Rectangle {
        id: captureOverlay
        visible: false
        width: page.width
        height: page.height
        color: ColorUtils.transparentize(Appearance.colors.colScrim, 0.55)
        z: 999
        MouseArea { anchors.fill: parent; onClicked: captureOverlay.visible = false }
        Rectangle {
            id: captureBox
            anchors.centerIn: parent
            width: Math.min(parent.width - 40, 520)
            implicitHeight: captureCol.implicitHeight + 24
            radius: Appearance.rounding.normal
            color: Appearance.colors.colLayer0
            border.width: 1
            border.color: Appearance.colors.colOutlineVariant
            focus: true
            Keys.onPressed: (event) => {
                let res = page.captureFromEvent(event)
                if (!res) { event.accepted = true; return }
                page.pendingNewMods = res.mods
                page.pendingNewKey = res.key
                page.pendingNewKeyStr = res.str
                event.accepted = true
            }
            Keys.onReleased: (event) => { event.accepted = true }
            ColumnLayout {
                id: captureCol
                anchors.fill: parent
                anchors.margins: 16
                spacing: 12
                RowLayout {
                    Layout.fillWidth: true
                    MaterialSymbol { text: "keyboard"; iconSize: 20; color: Appearance.colors.colPrimary }
                    StyledText {
                        text: page.selectedBind ? (Translation.tr("Edit: ") + (page.selectedBind.comment ?? "")) : Translation.tr("Capture shortcut")
                        font.weight: Font.Medium
                        color: Appearance.colors.colOnLayer0
                        Layout.fillWidth: true
                        wrapMode: Text.Wrap
                    }
                    Rectangle {
                        width: 32; height: 32; radius: 16
                        color: closeCapMa.containsMouse ? Appearance.colors.colErrorContainer : "transparent"
                        MaterialSymbol { anchors.centerIn: parent; text: "close"; iconSize: 18; color: Appearance.colors.colOnLayer0 }
                        MouseArea { id: closeCapMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: captureOverlay.visible = false }
                    }
                }
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 72
                    radius: Appearance.rounding.small
                    color: Appearance.colors.colLayer1
                    border.width: 1
                    border.color: page.pendingNewKeyStr.length ? Appearance.colors.colPrimary : Appearance.colors.colOutlineVariant
                    StyledText {
                        anchors.centerIn: parent
                        width: parent.width - 24
                        horizontalAlignment: Text.AlignHCenter
                        wrapMode: Text.Wrap
                        font.pixelSize: Appearance.font.pixelSize.large
                        font.weight: Font.Medium
                        color: page.pendingNewKeyStr.length ? Appearance.colors.colPrimary : Appearance.colors.colSubtext
                        text: page.pendingNewKeyStr.length ? page.pendingNewKeyStr : Translation.tr("Press any key combo… (e.g. SUPER + K)")
                    }
                }
                StyledText {
                    Layout.fillWidth: true
                    wrapMode: Text.Wrap
                    font.pixelSize: Appearance.font.pixelSize.smaller
                    color: Appearance.colors.colSubtext
                    text: page.selectedBind ? Translation.tr("Original: ") + formatKeybind(page.selectedBind.mods, page.selectedBind.key) + "  •  " + page.selectedBind.dispatcher : ""
                    visible: page.selectedBind !== null
                }
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8
                    Item { Layout.fillWidth: true }
                    RippleButton {
                        buttonText: Translation.tr("Cancel")
                        onClicked: captureOverlay.visible = false
                    }
                    RippleButtonWithIcon {
                        enabled: page.pendingNewKeyStr.length > 0 && page.selectedBind !== null
                        materialIcon: "check"
                        mainText: Translation.tr("Save")
                        onClicked: {
                            if (!page.selectedBind || !page.pendingNewKeyStr) return
                            if (page.selectedBind.dispatcher === "comment") return
                            let line
                            if (page.selectedBind.rest && page.selectedBind.rest.length > 0) {
                                line = `hl.bind("${page.pendingNewKeyStr}", ${page.selectedBind.rest}`
                            } else {
                                let disp = page.selectedBind.dispatcher
                                let params = page.selectedBind.params
                                let comment = page.selectedBind.comment
                                let safeComment = comment.replace(/"/g, '\\"')
                                line = `hl.bind("${page.pendingNewKeyStr}", ${disp}(${params}), { description = "${safeComment}" })`
                            }
                            const customPath = HyprlandConfig.customBindsPath
                            const customDir = FileUtils.trimFileProtocol(Directories.config) + "/hypr/custom"
                            const escLine = line.replace(/'/g, "'\\''")
                            const escPath = customPath.replace(/'/g, "'\\''")
                            const escDir = customDir.replace(/'/g, "'\\''")
                            Quickshell.execDetached(["bash", "-c", `mkdir -p '${escDir}' && printf '%s\\n' '${escLine}' >> '${escPath}' && hyprctl reload 2>/dev/null; echo saved`])
                            captureToast.text = Translation.tr("Saved: ") + page.pendingNewKeyStr
                            captureToast.opacity = 1
                            hideToast.restart()
                            captureOverlay.visible = false
                        }
                    }
                }
                StyledText {
                    font.pixelSize: Appearance.font.pixelSize.smallest
                    color: Appearance.colors.colSubtext
                    wrapMode: Text.Wrap
                    Layout.fillWidth: true
                    text: Translation.tr("No manual typing needed — just press the keys. Stored in ~/.config/hypr/custom/keybinds.lua and overrides the default.")
                }
            }
        }
        Rectangle {
            id: captureToast
            property alias text: toastTxt.text
            anchors.bottom: parent.bottom
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottomMargin: 24
            width: toastTxt.implicitWidth + 32
            height: 36
            radius: 18
            color: Appearance.colors.colPrimary
            opacity: 0
            visible: opacity > 0
            StyledText { id: toastTxt; anchors.centerIn: parent; color: Appearance.colors.colOnPrimary; font.weight: Font.Medium }
            Behavior on opacity { NumberAnimation { duration: 200 } }
        }
        Timer { id: hideToast; interval: 1800; onTriggered: captureToast.opacity = 0 }
    }

    ColumnLayout {
        id: mainLayout
        Layout.fillWidth: true
        spacing: 20

        ContentSection {
            icon: "keyboard"
            shape: MaterialShape.Shape.Cookie4Sided
            title: Translation.tr("Keybinds — Actions & Shortcuts")
            StyledText {
                Layout.fillWidth: true
                wrapMode: Text.Wrap
                font.pixelSize: Appearance.font.pixelSize.smaller
                color: Appearance.colors.colSubtext
                text: Translation.tr("All shortcuts are read automatically from hyprland/keybinds.lua (+ custom/keybinds.lua). Click Edit to capture a new combo — no typing required. Search filters by action or keys.")
            }
            RowLayout {
                Layout.fillWidth: true
                spacing: 8
                MaterialTextField {
                    id: searchField
                    Layout.fillWidth: true
                    placeholderText: Translation.tr("Search action or keybind… (e.g. ‘screenshot’ or ‘SUPER + S’)")
                    text: page.searchQuery
                    onTextChanged: page.searchQuery = text
                }
                RippleButtonWithIcon {
                    materialIcon: "refresh"
                    mainText: Translation.tr("Reload")
                    onClicked: reloadBindsProc.running = true
                    StyledToolTip { text: Translation.tr("Re-read hyprland/keybinds.lua") }
                }
                RippleButton {
                    buttonText: Translation.tr("Clear custom")
                    onClicked: clearAllProc.running = true
                    StyledToolTip { text: Translation.tr("Clears ~/.config/hypr/custom/keybinds.lua") }
                }
            }
            StyledText {
                Layout.fillWidth: true
                font.pixelSize: Appearance.font.pixelSize.smaller
                color: Appearance.colors.colSubtext
                text: Translation.tr("%1 sections • %2 total binds").arg(flatSections().length).arg(flatSections().reduce((a,s)=>a+(s.keybinds?.length??0),0))
            }
        }

        Repeater {
            model: flatSections()
            delegate: ContentSection {
                required property var modelData
                property var section: modelData
                title: section.name && section.name.length ? section.name : Translation.tr("General")
                icon: {
                    const n = (section.name ?? "").toLowerCase()
                    if (n.includes("utility") || n.includes("screenshot")) return "screenshot_monitor"
                    if (n.includes("window") || n.includes("work")) return "select_window_2"
                    if (n.includes("screen") || n.includes("monitor")) return "monitor"
                    if (n.includes("media")) return "play_circle"
                    if (n.includes("shell")) return "terminal"
                    return "keyboard_command_key"
                }
                shape: MaterialShape.Shape.Pill
                visible: {
                    const q = page.searchQuery
                    if (!q || q.trim() === "") return (section.keybinds?.length ?? 0) > 0
                    for (let b of (section.keybinds ?? [])) if (page.matchesSearch(b, q)) return true
                    return false
                }
                ColumnLayout {
                    spacing: 2
                    Layout.fillWidth: true
                    Repeater {
                        model: {
                            let arr = section.keybinds ?? []
                            if (page.searchQuery && page.searchQuery.trim() !== "") arr = arr.filter(b => page.matchesSearch(b, page.searchQuery))
                            return arr
                        }
                        delegate: Rectangle {
                            required property var modelData
                            property var bind: modelData
                            Layout.fillWidth: true
                            implicitHeight: bindRow.implicitHeight + 16
                            radius: Appearance.rounding.unsharpenmore
                            color: Appearance.colors.colLayer1
                            RowLayout {
                                id: bindRow
                                anchors.fill: parent
                                anchors.margins: 8
                                spacing: 10
                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 2
                                    StyledText {
                                        Layout.fillWidth: true
                                        text: bind.comment && bind.comment.length ? bind.comment : (bind.dispatcher + " " + bind.params)
                                        font.weight: Font.Medium
                                        color: Appearance.colors.colOnLayer1
                                        wrapMode: Text.NoWrap
                                        elide: Text.ElideRight
                                        maximumLineCount: 1
                                    }
                                    StyledText {
                                        visible: bind.dispatcher !== "comment"
                                        font.pixelSize: Appearance.font.pixelSize.smallest
                                        color: Appearance.colors.colSubtext
                                        text: bind.dispatcher
                                        elide: Text.ElideRight
                                        wrapMode: Text.NoWrap
                                        maximumLineCount: 1
                                        Layout.maximumWidth: 220
                                    }
                                    StyledText {
                                        visible: bind.dispatcher !== "comment" && bind.params && bind.params.length
                                        font.pixelSize: Appearance.font.pixelSize.smallest
                                        color: Appearance.colors.colSubtext
                                        text: bind.params.length > 55 ? bind.params.slice(0,55) + "…" : bind.params
                                        elide: Text.ElideRight
                                        wrapMode: Text.NoWrap
                                        maximumLineCount: 1
                                        Layout.fillWidth: true
                                    }
                                }
                                Rectangle {
                                    Layout.preferredWidth: pillRow.implicitWidth + 16
                                    Layout.preferredHeight: 32
                                    radius: 16
                                    color: isEditable(bind) ? Appearance.colors.colPrimaryContainer : Appearance.colors.colLayer1
                                    border.width: 1
                                    border.color: isEditable(bind) ? Appearance.colors.colPrimary : Appearance.colors.colOutlineVariant
                                    RowLayout {
                                        id: pillRow
                                        anchors.centerIn: parent
                                        spacing: 4
                                        Repeater {
                                            model: (bind.mods ?? [])
                                            delegate: Rectangle {
                                                required property string modelData
                                                implicitWidth: lab.implicitWidth + 10
                                                implicitHeight: 20
                                                radius: 6
                                                color: Appearance.colors.colPrimary
                                                StyledText {
                                                    id: lab
                                                    anchors.centerIn: parent
                                                    text: modelData
                                                    font.pixelSize: Appearance.font.pixelSize.smallest
                                                    font.weight: Font.Bold
                                                    color: Appearance.colors.colOnPrimary
                                                }
                                            }
                                        }
                                        Rectangle {
                                            visible: (bind.key ?? "").length > 0
                                            implicitWidth: keyLab.implicitWidth + 10
                                            implicitHeight: 20
                                            radius: 6
                                            color: Appearance.colors.colPrimary
                                            StyledText {
                                                id: keyLab
                                                anchors.centerIn: parent
                                                text: bind.key ?? ""
                                                font.pixelSize: Appearance.font.pixelSize.smallest
                                                font.weight: Font.Bold
                                                color: Appearance.colors.colOnPrimary
                                            }
                                        }
                                        StyledText {
                                            visible: (bind.mods?.length ?? 0) === 0 && (bind.key ?? "").length === 0
                                            text: "—"
                                            color: Appearance.colors.colSubtext
                                        }
                                    }
                                }
                                RippleButtonWithIcon {
                                    visible: isEditable(bind)
                                    materialIcon: "edit"
                                    mainText: Translation.tr("Edit")
                                    onClicked: {
                                        page.selectedBind = bind
                                        page.pendingNewMods = []
                                        page.pendingNewKey = ""
                                        page.pendingNewKeyStr = ""
                                        captureOverlay.visible = true
                                        captureBox.forceActiveFocus()
                                    }
                                    StyledToolTip { text: Translation.tr("Capture new shortcut automatically") }
                                }
                                RippleButton {
                                    visible: {
                                        if (!isEditable(bind) || !HyprlandKeybinds.userKeybinds || !HyprlandKeybinds.userKeybinds.children) return false
                                        let all = []
                                        const ch = HyprlandKeybinds.userKeybinds.children
                                        for (let i=0;i<ch.length;i++) {
                                            let kb = ch[i].keybinds
                                            if (kb) for (let j=0;j<kb.length;j++) all.push(kb[j])
                                        }
                                        for (let n=0;n<all.length;n++) if (all[n].comment === bind.comment) return true
                                        return false
                                    }
                                    buttonText: Translation.tr("Reset")
                                    onClicked: {
                                        const escComment = bind.comment.replace(/'/g, "'\\''")
                                        const escPath = HyprlandConfig.customBindsPath.replace(/'/g, "'\\''")
                                        Quickshell.execDetached(["bash", "-c", `tmp=$(mktemp); grep -vF '${escComment}' '${escPath}' > "$tmp" 2>/dev/null || true; mv "$tmp" '${escPath}'; hyprctl reload 2>/dev/null; echo reset`])
                                    }
                                    StyledToolTip { text: Translation.tr("Remove custom override for this action") }
                                }
                                MaterialSymbol {
                                    visible: !isEditable(bind)
                                    text: "block"
                                    iconSize: 16
                                    color: Appearance.colors.colSubtext
                                }
                            }
                        }
                    }
                }
            }
        }

        ContentSection {
            icon: "info"
            shape: MaterialShape.Shape.Ghostish
            title: Translation.tr("How it works")
            StyledText {
                Layout.fillWidth: true
                wrapMode: Text.Wrap
                font.pixelSize: Appearance.font.pixelSize.smaller
                color: Appearance.colors.colSubtext
                text: Translation.tr("Shortcuts are parsed from ~/.config/hypr/hyprland/keybinds.lua. Editing a shortcut appends an override to ~/.config/hypr/custom/keybinds.lua (e.g. hl.bind(\"SUPER + K\", ...)). Hyprland reloads automatically. Use Clear custom to reset. Synthetic entries (dispatcher=comment) are display-only.")
            }
        }
    }
}
