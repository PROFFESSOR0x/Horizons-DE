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
    property var captureConflict: null
    property bool conflictConfirmed: false
    property bool creatingNew: false
    property string newDispatcher: ""
    property string newDispatcherCustom: ""
    property string newParams: ""
    property string newComment: ""
    property string pendingDeleteComment: ""
    // Set when the user clicks "Add shortcut" on an existing action instead of
    // "New Keybind" — captures a second (or third...) real hl.bind line for the
    // exact same dispatcher+params, only prompting for the new key combo.
    property var duplicatingBind: null

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

    // Flattening/formatting/search-matching now live on the HyprlandKeybinds
    // singleton so the Super+/ cheat-sheet overlay can reuse the exact same
    // logic without duplicating it. Kept as thin wrappers here so the rest of
    // this file doesn't need to change every call site.
    function flatSections() {
        return HyprlandKeybinds.flatSections()
    }

    function formatKeybind(mods, key) {
        return HyprlandKeybinds.formatKeybind(mods, key)
    }

    function isEditable(bind) {
        if (!bind) return false
        if (bind.dispatcher === "comment") return false
        // function binds are now editable thanks to rest field
        if (!bind.comment || bind.comment.length === 0) return false
        return true
    }

    // A small denylist of dispatchers/commands whose loss would be disruptive
    // (closing/killing windows, exiting the session). Binding a new chord onto
    // one of these keys doesn't remove the essential bind — Hyprland would just
    // register both — but it means the chord may no longer reliably do the
    // essential thing, so we treat conflicts with these specially.
    function isEssentialBind(bind) {
        if (!bind) return false
        const d = bind.dispatcher ?? ""
        const p = bind.params ?? ""
        if (d === "hl.dsp.window.close") return true
        if (d === "hl.dsp.exec_cmd" && /hyprctl\s+kill|wlogout|poweroff/i.test(p)) return true
        if (d === "hl.dsp.global" && /sessionToggle/i.test(p)) return true
        return false
    }

    function findDefaultBindByComment(comment) {
        if (!comment) return null
        const src = HyprlandKeybinds.defaultKeybinds
        if (!src || !src.children) return null
        function search(node) {
            if (node.keybinds) for (let kb of node.keybinds) if (kb.comment === comment) return kb
            if (node.children) for (let c of node.children) {
                let r = search(c)
                if (r) return r
            }
            return null
        }
        for (let ch of src.children) {
            let r = search(ch)
            if (r) return r
        }
        return null
    }

    function hasDefaultCounterpart(bind) {
        return !!findDefaultBindByComment(bind?.comment)
    }

    // Finds an existing bind (anywhere in the merged default+custom list) that
    // already uses the exact same modifier+key combination. excludeComment lets
    // callers skip the bind currently being edited (its default/override pair
    // share the same comment).
    function findConflict(mods, key, excludeComment) {
        if (!key) return null
        const wantMods = (mods ?? []).slice().sort().join("+")
        for (let section of flatSections()) {
            for (let b of (section.keybinds ?? [])) {
                if (b.dispatcher === "comment") continue
                if (excludeComment && b.comment === excludeComment) continue
                const bMods = (b.mods ?? []).slice().sort().join("+")
                if (bMods === wantMods && (b.key ?? "") === key) return b
            }
        }
        return null
    }

    // Live list of dispatchers actually seen in the parsed keybinds, so the
    // "new keybind" dispatcher picker never hand-types an incomplete list.
    function allDispatchers() {
        let set = {}
        for (let section of flatSections()) {
            for (let b of (section.keybinds ?? [])) {
                const d = b.dispatcher
                if (!d || d === "comment" || d === "function") continue
                set[d] = true
            }
        }
        return Object.keys(set).sort()
    }

    function effectiveDispatcher() {
        if (page.newDispatcher === "__custom__") return page.newDispatcherCustom.trim()
        return page.newDispatcher
    }

    function matchesSearch(bind, q) {
        return HyprlandKeybinds.matchesSearch(bind, q)
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
    Timer {
        id: deleteConfirmTimer
        interval: 3000
        onTriggered: page.pendingDeleteComment = ""
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
                const excludeComment = (page.creatingNew || page.duplicatingBind) ? null : (page.selectedBind ? page.selectedBind.comment : null)
                page.captureConflict = page.findConflict(res.mods, res.key, excludeComment)
                page.conflictConfirmed = false
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
                        text: page.creatingNew ? Translation.tr("New keybind")
                            : page.duplicatingBind ? (Translation.tr("Add shortcut: ") + (page.duplicatingBind.comment ?? ""))
                            : page.selectedBind ? (Translation.tr("Edit: ") + (page.selectedBind.comment ?? "")) : Translation.tr("Capture shortcut")
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
                    text: page.selectedBind ? Translation.tr("Original: ") + formatKeybind(page.selectedBind.mods, page.selectedBind.key) + "  •  " + page.selectedBind.dispatcher
                        : page.duplicatingBind ? Translation.tr("Existing: ") + formatKeybind(page.duplicatingBind.mods, page.duplicatingBind.key) + "  •  " + page.duplicatingBind.dispatcher
                        : ""
                    visible: !page.creatingNew && (page.selectedBind !== null || page.duplicatingBind !== null)
                }

                // New-keybind form: dispatcher, params, description — only shown
                // when creating a brand-new bind rather than re-keying an existing one.
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 8
                    visible: page.creatingNew
                    StyledText {
                        text: Translation.tr("Dispatcher")
                        font.pixelSize: Appearance.font.pixelSize.smaller
                        color: Appearance.colors.colSubtext
                    }
                    StyledComboBox {
                        id: newDispatcherCombo
                        Layout.fillWidth: true
                        model: page.allDispatchers().map(d => ({ displayName: d, value: d }))
                            .concat([{ displayName: Translation.tr("Custom…"), value: "__custom__" }])
                        textRole: "displayName"
                        onCurrentIndexChanged: {
                            if (currentIndex >= 0 && model[currentIndex]) page.newDispatcher = model[currentIndex].value
                        }
                        Component.onCompleted: {
                            if (currentIndex >= 0 && model[currentIndex]) page.newDispatcher = model[currentIndex].value
                        }
                    }
                    MaterialTextField {
                        Layout.fillWidth: true
                        visible: page.newDispatcher === "__custom__"
                        placeholderText: Translation.tr("e.g. hl.dsp.exec_cmd")
                        text: page.newDispatcherCustom
                        onTextChanged: page.newDispatcherCustom = text
                    }
                    StyledText {
                        text: Translation.tr("Params")
                        font.pixelSize: Appearance.font.pixelSize.smaller
                        color: Appearance.colors.colSubtext
                    }
                    MaterialTextField {
                        Layout.fillWidth: true
                        placeholderText: Translation.tr("e.g. \"kitty\"")
                        text: page.newParams
                        onTextChanged: page.newParams = text
                    }
                    StyledText {
                        text: Translation.tr("Description")
                        font.pixelSize: Appearance.font.pixelSize.smaller
                        color: Appearance.colors.colSubtext
                    }
                    MaterialTextField {
                        Layout.fillWidth: true
                        placeholderText: Translation.tr("What does this bind do? (auto-filled if left blank)")
                        text: page.newComment
                        onTextChanged: page.newComment = text
                    }
                }

                // Conflict warning — shown for both edit and new-bind flows once a
                // combo that's already in use is captured.
                Rectangle {
                    Layout.fillWidth: true
                    visible: page.captureConflict !== null
                    implicitHeight: conflictCol.implicitHeight + 16
                    radius: Appearance.rounding.small
                    color: page.isEssentialBind(page.captureConflict) ? ColorUtils.transparentize(Appearance.colors.colError, 0.85) : ColorUtils.transparentize(Appearance.colors.colSecondary, 0.85)
                    border.width: 1
                    border.color: page.isEssentialBind(page.captureConflict) ? Appearance.colors.colError : Appearance.colors.colSecondary
                    ColumnLayout {
                        id: conflictCol
                        anchors.fill: parent
                        anchors.margins: 8
                        spacing: 6
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 6
                            MaterialSymbol {
                                text: "warning"
                                iconSize: 18
                                color: page.isEssentialBind(page.captureConflict) ? Appearance.colors.colError : Appearance.colors.colOnLayer0
                            }
                            StyledText {
                                Layout.fillWidth: true
                                wrapMode: Text.Wrap
                                font.weight: Font.Medium
                                color: page.isEssentialBind(page.captureConflict) ? Appearance.colors.colError : Appearance.colors.colOnLayer0
                                text: page.captureConflict
                                    ? Translation.tr("Already used by: ") + (page.captureConflict.comment || page.captureConflict.dispatcher) + "  (" + page.captureConflict.dispatcher + ")"
                                    : ""
                            }
                        }
                        StyledText {
                            Layout.fillWidth: true
                            wrapMode: Text.Wrap
                            font.pixelSize: Appearance.font.pixelSize.smaller
                            color: Appearance.colors.colSubtext
                            text: page.captureConflict && page.isEssentialBind(page.captureConflict)
                                ? Translation.tr("This combo is used by an essential system bind (closing windows / exiting the session). Binding it again won't remove that bind — both would fire — so this key combo is blocked. Choose a different combo.")
                                : Translation.tr("Hyprland doesn't replace the old bind — both would be registered on this combo, and which one actually fires depends on Hyprland's own resolution order. Confirm below if you still want to proceed.")
                        }
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8
                            visible: page.captureConflict !== null && !page.isEssentialBind(page.captureConflict)
                            StyledSwitch {
                                id: conflictConfirmSwitch
                                checked: page.conflictConfirmed
                                onCheckedChanged: page.conflictConfirmed = checked
                            }
                            StyledText {
                                Layout.fillWidth: true
                                wrapMode: Text.Wrap
                                font.pixelSize: Appearance.font.pixelSize.smaller
                                color: Appearance.colors.colOnLayer0
                                text: Translation.tr("I understand, save anyway")
                            }
                        }
                    }
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
                        enabled: page.pendingNewKeyStr.length > 0
                            && !(page.captureConflict !== null && page.isEssentialBind(page.captureConflict))
                            && (page.captureConflict === null || page.conflictConfirmed)
                            && (page.creatingNew ? page.effectiveDispatcher().length > 0 : (page.selectedBind !== null || page.duplicatingBind !== null))
                        materialIcon: "check"
                        mainText: (page.creatingNew || page.duplicatingBind) ? Translation.tr("Create") : Translation.tr("Save")
                        onClicked: {
                            if (!page.pendingNewKeyStr) return
                            let line
                            if (page.creatingNew) {
                                const disp = page.effectiveDispatcher()
                                if (!disp) return
                                const params = page.newParams ?? ""
                                let comment = (page.newComment ?? "").trim()
                                if (!comment) comment = (disp + (params ? " " + params : "")).trim()
                                const safeComment = comment.replace(/"/g, '\\"')
                                line = `hl.bind("${page.pendingNewKeyStr}", ${disp}(${params}), { description = "${safeComment}" })`
                            } else if (page.duplicatingBind) {
                                // Adding a second (or third...) real hl.bind line for the
                                // same logical action — reuses dispatcher/params/comment
                                // verbatim from the bind being duplicated and just appends
                                // a brand-new line, leaving every existing chord untouched.
                                const b = page.duplicatingBind
                                if (b.dispatcher === "comment") return
                                if (b.rest && b.rest.length > 0) {
                                    line = `hl.bind("${page.pendingNewKeyStr}", ${b.rest}`
                                } else {
                                    let disp = b.dispatcher
                                    let params = b.params
                                    let comment = b.comment
                                    let safeComment = comment.replace(/"/g, '\\"')
                                    line = `hl.bind("${page.pendingNewKeyStr}", ${disp}(${params}), { description = "${safeComment}" })`
                                }
                            } else {
                                if (!page.selectedBind) return
                                if (page.selectedBind.dispatcher === "comment") return
                                if (page.selectedBind.rest && page.selectedBind.rest.length > 0) {
                                    line = `hl.bind("${page.pendingNewKeyStr}", ${page.selectedBind.rest}`
                                } else {
                                    let disp = page.selectedBind.dispatcher
                                    let params = page.selectedBind.params
                                    let comment = page.selectedBind.comment
                                    let safeComment = comment.replace(/"/g, '\\"')
                                    line = `hl.bind("${page.pendingNewKeyStr}", ${disp}(${params}), { description = "${safeComment}" })`
                                }
                            }
                            const customPath = HyprlandConfig.customBindsPath
                            const customDir = FileUtils.trimFileProtocol(Directories.config) + "/hypr/custom"
                            const escLine = line.replace(/'/g, "'\\''")
                            const escPath = customPath.replace(/'/g, "'\\''")
                            const escDir = customDir.replace(/'/g, "'\\''")
                            Quickshell.execDetached(["bash", "-c", `mkdir -p '${escDir}' && printf '%s\\n' '${escLine}' >> '${escPath}' && hyprctl reload 2>/dev/null; echo saved`])
                            captureToast.text = (page.creatingNew || page.duplicatingBind ? Translation.tr("Created: ") : Translation.tr("Saved: ")) + page.pendingNewKeyStr
                            captureToast.opacity = 1
                            hideToast.restart()
                            captureOverlay.visible = false
                            page.creatingNew = false
                            page.duplicatingBind = null
                            page.newDispatcher = ""
                            page.newDispatcherCustom = ""
                            page.newParams = ""
                            page.newComment = ""
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
                    materialIcon: "add"
                    mainText: Translation.tr("New Keybind")
                    onClicked: {
                        page.creatingNew = true
                        page.selectedBind = null
                        page.duplicatingBind = null
                        page.pendingNewMods = []
                        page.pendingNewKey = ""
                        page.pendingNewKeyStr = ""
                        page.captureConflict = null
                        page.conflictConfirmed = false
                        page.newDispatcher = ""
                        page.newDispatcherCustom = ""
                        page.newParams = ""
                        page.newComment = ""
                        captureOverlay.visible = true
                        captureBox.forceActiveFocus()
                    }
                    StyledToolTip { text: Translation.tr("Create a brand-new keybind from scratch") }
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
            RowLayout {
                Layout.fillWidth: true
                spacing: 12
                StyledText {
                    font.pixelSize: Appearance.font.pixelSize.smaller
                    color: Appearance.colors.colSubtext
                    text: Translation.tr("%1 sections • %2 total binds").arg(flatSections().length).arg(flatSections().reduce((a,s)=>a+(s.keybinds?.length??0),0))
                }
                Item { Layout.fillWidth: true }
                RowLayout {
                    spacing: 4
                    Rectangle { width: 10; height: 10; radius: 3; color: Appearance.colors.colSecondaryContainer }
                    StyledText { font.pixelSize: Appearance.font.pixelSize.smallest; color: Appearance.colors.colSubtext; text: Translation.tr("modifier") }
                    Rectangle { width: 10; height: 10; radius: 3; color: Appearance.colors.colPrimary; Layout.leftMargin: 8 }
                    StyledText { font.pixelSize: Appearance.font.pixelSize.smallest; color: Appearance.colors.colSubtext; text: Translation.tr("key") }
                }
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
                    spacing: 8
                    Layout.fillWidth: true
                    Repeater {
                        // Grouped by logical action (dispatcher+params) so an action
                        // bound to more than one key combo (e.g. SUPER+Q and
                        // SUPER+Return both opening a terminal) renders as one linked
                        // row with multiple chord chips instead of unrelated-looking
                        // duplicate rows.
                        model: {
                            let arr = section.keybinds ?? []
                            if (page.searchQuery && page.searchQuery.trim() !== "") arr = arr.filter(b => page.matchesSearch(b, page.searchQuery))
                            return HyprlandKeybinds.groupKeybinds(arr)
                        }
                        delegate: ColumnLayout {
                            id: groupCol
                            required property var modelData
                            property var group: modelData
                            property var repBind: group.binds[0]
                            property bool multi: group.binds.length > 1
                            Layout.fillWidth: true
                            spacing: 2

                            RowLayout {
                                visible: groupCol.multi
                                Layout.fillWidth: true
                                Layout.leftMargin: 6
                                spacing: 4
                                MaterialSymbol { text: "link"; iconSize: 14; color: Appearance.colors.colPrimary }
                                StyledText {
                                    text: Translation.tr("%1 shortcuts trigger this action").arg(groupCol.group.binds.length)
                                    font.pixelSize: Appearance.font.pixelSize.smallest
                                    font.weight: Font.Medium
                                    color: Appearance.colors.colPrimary
                                }
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                color: groupCol.multi ? ColorUtils.transparentize(Appearance.colors.colPrimary, 0.94) : "transparent"
                                radius: Appearance.rounding.unsharpenmore + 4
                                border.width: groupCol.multi ? 1 : 0
                                border.color: ColorUtils.transparentize(Appearance.colors.colPrimary, 0.75)
                                implicitHeight: memberCol.implicitHeight + (groupCol.multi ? 8 : 0)
                                ColumnLayout {
                                    id: memberCol
                                    anchors.fill: parent
                                    anchors.margins: groupCol.multi ? 4 : 0
                                    spacing: 2
                                    Repeater {
                        model: groupCol.group.binds
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
                                                // Modifier chips use a distinct (secondary) fill from the
                                                // final key chip below, so the combo reads at a glance as
                                                // "modifiers" + "key" instead of one undifferentiated blob.
                                                color: Appearance.colors.colSecondaryContainer
                                                StyledText {
                                                    id: lab
                                                    anchors.centerIn: parent
                                                    text: modelData
                                                    font.pixelSize: Appearance.font.pixelSize.smallest
                                                    font.weight: Font.Bold
                                                    color: Appearance.colors.colOnSecondaryContainer
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
                                        page.creatingNew = false
                                        page.duplicatingBind = null
                                        page.selectedBind = bind
                                        page.pendingNewMods = []
                                        page.pendingNewKey = ""
                                        page.pendingNewKeyStr = ""
                                        page.captureConflict = null
                                        page.conflictConfirmed = false
                                        captureOverlay.visible = true
                                        captureBox.forceActiveFocus()
                                    }
                                    StyledToolTip { text: Translation.tr("Capture new shortcut automatically") }
                                }
                                RippleButton {
                                    id: resetDeleteBtn
                                    property bool hasCustomEntry: {
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
                                    property bool isCustomOnly: !page.hasDefaultCounterpart(bind)
                                    // Keyed by comment+key_str (not comment alone) so arming/
                                    // confirming delete on one chord of a multi-chord action
                                    // doesn't visually arm its sibling chords too.
                                    property string identity: (bind.comment ?? "") + " " + (bind.key_str ?? "")
                                    visible: hasCustomEntry
                                    buttonText: {
                                        if (!isCustomOnly) return Translation.tr("Reset")
                                        return page.pendingDeleteComment === identity ? Translation.tr("Confirm delete?") : Translation.tr("Delete")
                                    }
                                    onClicked: {
                                        if (isCustomOnly && page.pendingDeleteComment !== identity) {
                                            // First click on a permanent delete just arms confirmation.
                                            page.pendingDeleteComment = identity
                                            deleteConfirmTimer.restart()
                                            return
                                        }
                                        page.pendingDeleteComment = ""
                                        const escPath = HyprlandConfig.customBindsPath.replace(/'/g, "'\\''")
                                        // Remove only the one line that matches BOTH this exact
                                        // key combo and this comment — not every line sharing the
                                        // comment — so deleting/resetting one chord of a
                                        // multi-chord action leaves its sibling chords intact.
                                        Quickshell.execDetached(["bash", "-c",
                                            `awk -v k="$1" -v c="$2" 'index($0,k)>0 && index($0,c)>0{next}{print}' "$3" > "$3.kbtmp" 2>/dev/null && mv "$3.kbtmp" "$3"; hyprctl reload 2>/dev/null; echo reset`,
                                            "_", bind.key_str ?? "", bind.comment, HyprlandConfig.customBindsPath])
                                    }
                                    StyledToolTip {
                                        text: resetDeleteBtn.isCustomOnly
                                            ? Translation.tr("Permanently delete this custom keybind (no default to fall back to)")
                                            : Translation.tr("Remove custom override — the default bind returns. Hyprland's Lua config here has no unbind/suppress mechanism, so a default-backed bind can't be truly deleted, only reset.")
                                    }
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

                            RippleButtonWithIcon {
                                Layout.alignment: Qt.AlignRight
                                visible: page.isEditable(groupCol.repBind)
                                materialIcon: "add_circle"
                                mainText: groupCol.multi ? Translation.tr("Add another shortcut") : Translation.tr("Add shortcut for this action")
                                onClicked: {
                                    page.creatingNew = false
                                    page.selectedBind = null
                                    page.duplicatingBind = groupCol.repBind
                                    page.pendingNewMods = []
                                    page.pendingNewKey = ""
                                    page.pendingNewKeyStr = ""
                                    page.captureConflict = null
                                    page.conflictConfirmed = false
                                    captureOverlay.visible = true
                                    captureBox.forceActiveFocus()
                                }
                                StyledToolTip { text: Translation.tr("Bind another key combo to trigger the same action") }
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
