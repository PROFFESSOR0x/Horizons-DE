pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions

// A fast, read-only "what are my keybinds" cheat sheet — Super+/ (or
// `qs ipc call keybindsOverlay toggle`) pops it up, listing every keybind
// HyprlandKeybinds already parses, grouped by section, with a search field.
// Dismisses on Escape, click-away, or pressing the same shortcut again.
// Editing binds stays exclusive to Settings > Keybinds (KeybindsConfig.qml).
Scope {
    id: root

    property string searchQuery: ""

    PanelWindow {
        id: panelWindow
        visible: GlobalStates.keybindsOverlayOpen

        function hide() {
            GlobalStates.keybindsOverlayOpen = false;
        }

        exclusiveZone: 0
        WlrLayershell.namespace: "quickshell:keybindsOverlay"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: GlobalStates.keybindsOverlayOpen ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
        color: "transparent"

        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }

        onVisibleChanged: {
            if (visible) {
                GlobalFocusGrab.addDismissable(panelWindow);
                root.searchQuery = "";
                box.forceActiveFocus();
            } else {
                GlobalFocusGrab.removeDismissable(panelWindow);
            }
        }

        Connections {
            target: GlobalFocusGrab
            function onDismissed() {
                panelWindow.hide();
            }
        }

        Rectangle {
            id: scrim
            anchors.fill: parent
            color: ColorUtils.transparentize(Appearance.colors.colScrim, 0.45)
            opacity: GlobalStates.keybindsOverlayOpen ? 1 : 0
            z: 0
            Behavior on opacity {
                NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
            }
            MouseArea {
                anchors.fill: parent
                onClicked: panelWindow.hide()
            }
        }

        Rectangle {
            id: box
            anchors.centerIn: parent
            width: Math.min(parent.width - 64, 780)
            height: Math.min(parent.height - 96, 840)
            radius: Appearance.rounding.windowRounding
            color: Appearance.colors.colLayer0
            border.width: 1
            border.color: Appearance.colors.colOutlineVariant
            z: 1
            focus: true

            opacity: GlobalStates.keybindsOverlayOpen ? 1 : 0
            scale: GlobalStates.keybindsOverlayOpen ? 1 : 0.96
            Behavior on opacity {
                NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
            }
            Behavior on scale {
                NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
            }

            Keys.onPressed: (event) => {
                if (event.key === Qt.Key_Escape) {
                    panelWindow.hide();
                    event.accepted = true;
                }
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 18
                spacing: 10

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8
                    MaterialSymbol { text: "keyboard_command_key"; iconSize: 22; color: Appearance.colors.colPrimary }
                    StyledText {
                        text: Translation.tr("Keybinds cheat sheet")
                        font.pixelSize: Appearance.font.pixelSize.large
                        font.weight: Font.Medium
                        color: Appearance.colors.colOnLayer0
                        Layout.fillWidth: true
                    }
                    StyledText {
                        text: Translation.tr("Esc to close")
                        font.pixelSize: Appearance.font.pixelSize.smaller
                        color: Appearance.colors.colSubtext
                    }
                    Rectangle {
                        width: 32; height: 32; radius: 16
                        color: closeMa.containsMouse ? Appearance.colors.colErrorContainer : "transparent"
                        MaterialSymbol { anchors.centerIn: parent; text: "close"; iconSize: 18; color: Appearance.colors.colOnLayer0 }
                        MouseArea {
                            id: closeMa
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: panelWindow.hide()
                        }
                    }
                }

                MaterialTextField {
                    id: searchField
                    Layout.fillWidth: true
                    placeholderText: Translation.tr("Search action or keybind… (e.g. ‘screenshot’ or ‘SUPER + S’)")
                    text: root.searchQuery
                    onTextChanged: root.searchQuery = text
                }

                StyledText {
                    Layout.fillWidth: true
                    font.pixelSize: Appearance.font.pixelSize.smaller
                    color: Appearance.colors.colSubtext
                    text: Translation.tr("%1 sections • %2 total binds — read-only. Edit shortcuts in Settings > Keybinds.")
                        .arg(HyprlandKeybinds.flatSections().length)
                        .arg(HyprlandKeybinds.flatSections().reduce((a, s) => a + (s.keybinds?.length ?? 0), 0))
                }

                ContentPage {
                    id: listPage
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    forceWidth: true
                    baseWidth: box.width - 36

                    Repeater {
                        model: HyprlandKeybinds.flatSections()
                        delegate: ContentSection {
                            required property var modelData
                            property var section: modelData
                            title: section.name && section.name.length ? section.name : Translation.tr("General")
                            icon: {
                                const n = (section.name ?? "").toLowerCase();
                                if (n.includes("utility") || n.includes("screenshot")) return "screenshot_monitor";
                                if (n.includes("window") || n.includes("work")) return "select_window_2";
                                if (n.includes("screen") || n.includes("monitor")) return "monitor";
                                if (n.includes("media")) return "play_circle";
                                if (n.includes("shell")) return "terminal";
                                return "keyboard_command_key";
                            }
                            shape: MaterialShape.Shape.Pill
                            visible: {
                                const q = root.searchQuery;
                                if (!q || q.trim() === "") return (section.keybinds?.length ?? 0) > 0;
                                for (let b of (section.keybinds ?? [])) if (HyprlandKeybinds.matchesSearch(b, q)) return true;
                                return false;
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 4
                                Repeater {
                                    model: {
                                        let arr = section.keybinds ?? [];
                                        if (root.searchQuery && root.searchQuery.trim() !== "") arr = arr.filter(b => HyprlandKeybinds.matchesSearch(b, root.searchQuery));
                                        return HyprlandKeybinds.groupKeybinds(arr);
                                    }
                                    delegate: Rectangle {
                                        required property var modelData
                                        property var group: modelData
                                        property var repBind: group.binds[0]
                                        Layout.fillWidth: true
                                        implicitHeight: rowLayout.implicitHeight + 14
                                        radius: Appearance.rounding.unsharpenmore
                                        color: Appearance.colors.colLayer1

                                        RowLayout {
                                            id: rowLayout
                                            anchors.fill: parent
                                            anchors.margins: 7
                                            spacing: 10

                                            ColumnLayout {
                                                Layout.fillWidth: true
                                                spacing: 1
                                                StyledText {
                                                    Layout.fillWidth: true
                                                    text: repBind.comment && repBind.comment.length ? repBind.comment : (repBind.dispatcher + " " + repBind.params)
                                                    font.weight: Font.Medium
                                                    color: Appearance.colors.colOnLayer1
                                                    wrapMode: Text.NoWrap
                                                    elide: Text.ElideRight
                                                    maximumLineCount: 1
                                                }
                                                StyledText {
                                                    visible: repBind.dispatcher !== "comment" && repBind.params && repBind.params.length
                                                    font.pixelSize: Appearance.font.pixelSize.smallest
                                                    color: Appearance.colors.colSubtext
                                                    text: repBind.params.length > 55 ? repBind.params.slice(0, 55) + "…" : repBind.params
                                                    elide: Text.ElideRight
                                                    wrapMode: Text.NoWrap
                                                    maximumLineCount: 1
                                                    Layout.fillWidth: true
                                                }
                                            }

                                            // One chord pill per key combo bound to this action —
                                            // multiple pills read at a glance as "any of these
                                            // triggers the same thing" rather than unrelated rows.
                                            RowLayout {
                                                spacing: 6
                                                Repeater {
                                                    model: group.binds
                                                    delegate: Rectangle {
                                                        required property var modelData
                                                        property var chordBind: modelData
                                                        Layout.preferredWidth: chordPillRow.implicitWidth + 16
                                                        Layout.preferredHeight: 30
                                                        radius: 15
                                                        color: chordBind.dispatcher === "comment" ? Appearance.colors.colLayer1 : Appearance.colors.colPrimaryContainer
                                                        border.width: 1
                                                        border.color: chordBind.dispatcher === "comment" ? Appearance.colors.colOutlineVariant : Appearance.colors.colPrimary
                                                        RowLayout {
                                                            id: chordPillRow
                                                            anchors.centerIn: parent
                                                            spacing: 4
                                                            Repeater {
                                                                model: (chordBind.mods ?? [])
                                                                delegate: Rectangle {
                                                                    required property string modelData
                                                                    implicitWidth: modLab.implicitWidth + 10
                                                                    implicitHeight: 20
                                                                    radius: 6
                                                                    color: Appearance.colors.colSecondaryContainer
                                                                    StyledText {
                                                                        id: modLab
                                                                        anchors.centerIn: parent
                                                                        text: modelData
                                                                        font.pixelSize: Appearance.font.pixelSize.smallest
                                                                        font.weight: Font.Bold
                                                                        color: Appearance.colors.colOnSecondaryContainer
                                                                    }
                                                                }
                                                            }
                                                            Rectangle {
                                                                visible: (chordBind.key ?? "").length > 0
                                                                implicitWidth: keyLab.implicitWidth + 10
                                                                implicitHeight: 20
                                                                radius: 6
                                                                color: Appearance.colors.colPrimary
                                                                StyledText {
                                                                    id: keyLab
                                                                    anchors.centerIn: parent
                                                                    text: chordBind.key ?? ""
                                                                    font.pixelSize: Appearance.font.pixelSize.smallest
                                                                    font.weight: Font.Bold
                                                                    color: Appearance.colors.colOnPrimary
                                                                }
                                                            }
                                                            StyledText {
                                                                visible: (chordBind.mods?.length ?? 0) === 0 && (chordBind.key ?? "").length === 0
                                                                text: "—"
                                                                color: Appearance.colors.colSubtext
                                                            }
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    IpcHandler {
        target: "keybindsOverlay"
        function toggle(): void { GlobalStates.keybindsOverlayOpen = !GlobalStates.keybindsOverlayOpen; }
        function open(): void   { GlobalStates.keybindsOverlayOpen = true; }
        function close(): void  { GlobalStates.keybindsOverlayOpen = false; }
    }

    // Hooks the "SUPER + Slash" bind already declared in the default
    // hyprland/keybinds.lua (`hl.dsp.global("quickshell:cheatsheetToggle")`) —
    // no compositor-side keybind change is needed for Super+/ to work.
    CompositorGlobalShortcut {
        name: "cheatsheetToggle"
        description: "Toggles the keybinds cheat sheet"
        onPressed: GlobalStates.keybindsOverlayOpen = !GlobalStates.keybindsOverlayOpen;
    }
}
