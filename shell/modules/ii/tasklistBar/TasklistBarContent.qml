pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions

Item {
    id: root
    implicitHeight: Appearance.sizes.barHeight
    width: parent.width

    // ── Pinned apps list from tasklistBar config (not dock) ──────────────────
    readonly property var pinnedApps: Config.options.tasklistBar.pinnedApps

    // ── Running toplevels grouped by appId ───────────────────────────────────
    // Build a map: appId → { toplevels: [...] }
    readonly property var runningGroups: {
        const map = {}
        for (const toplevel of ToplevelManager.toplevels.values) {
            const id = (toplevel.appId ?? "").toLowerCase()
            if (!id) continue
            if (!map[id]) map[id] = []
            map[id].push(toplevel)
        }
        return map
    }

    // ────────────────────────────────────────────────────────────────────────

    Rectangle {
        id: barBackground
        anchors.fill: parent
        color: Config.options.bar.showBackground
            ? (Config.options.bar.followFrameColor
                ? Appearance.getColorFromName(Config.options.bar.frameColor)
                : Appearance.colors.colLayer0)
            : "transparent"
        radius: Config.options.bar.cornerStyle === 1 ? Appearance.rounding.windowRounding : 0
        border.width: Config.options.bar.cornerStyle === 1 ? 1 : 0
        border.color: Appearance.colors.colLayer0Border
    }

    Item {
        id: contentContainer
        anchors.fill: barBackground
        anchors.margins: 4

        // ── Left: pinned apps ────────────────────────────────────────────────
        RowLayout {
            id: pinnedRow
            anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
            spacing: 2

            Repeater {
                model: root.pinnedApps
                delegate: TaskButton {
                    required property string modelData
                    required property int    index
                    appId:     modelData
                    isPinned:  true
                    toplevels: root.runningGroups[modelData.toLowerCase()] ?? []
                    Layout.fillHeight: true
                }
            }

            // Separator between pinned and running
            Rectangle {
                visible: root.pinnedApps.length > 0
                width: 1
                height: parent.height * 0.5
                color: Appearance.colors.colOutlineVariant
                Layout.alignment: Qt.AlignVCenter
            }
        }

        // ── Right: running windows (non-pinned) ──────────────────────────────
        Flickable {
            id: taskFlickable
            anchors {
                left:   pinnedRow.right
                right:  parent.right
                top:    parent.top
                bottom: parent.bottom
                leftMargin: root.pinnedApps.length > 0 ? 4 : 0
            }
            contentWidth: taskRow.implicitWidth
            clip: true
            boundsMovement: Flickable.StopAtBounds
            boundsBehavior: Flickable.DragOverBounds

            RowLayout {
                id: taskRow
                height: parent.height
                spacing: 2

                Repeater {
                    // Show open windows whose appId is not in pinned list
                    model: ToplevelManager.toplevels.values.filter(t =>
                        t.appId && !root.pinnedApps.map(p => p.toLowerCase()).includes(t.appId.toLowerCase())
                    )
                    delegate: TaskButton {
                        required property var modelData
                        appId:    modelData.appId ?? ""
                        isPinned: false
                        toplevels: [modelData]
                        Layout.fillHeight: true
                    }
                }
            }

            ScrollBar.horizontal: StyledScrollBar {
                policy: ScrollBar.AsNeeded
            }
        }
    }

    // ── TaskButton component ──────────────────────────────────────────────────
    component TaskButton: Item {
        id: taskBtn

        required property string  appId
        required property bool    isPinned
        required property var     toplevels   // array of Toplevel objects

        readonly property bool hasWindows:   toplevels.length > 0
        readonly property bool isActive:     toplevels.some(t => t.activated)
        readonly property int  windowCount:  toplevels.length
        readonly property string displayName: {
            if (toplevels.length > 0)
                return toplevels[0].title ?? appId
            return appId
        }

        implicitWidth: Math.min(
            Math.max(btnLabel.implicitWidth + iconImg.implicitWidth + 32, 40),
            Config.options.tasklistBar.maxButtonWidth
        )
        implicitHeight: parent?.height ?? Appearance.sizes.barHeight

        // Cycling: click cycles through windows of the same app
        property int _lastFocused: 0

        Rectangle {
            id: btnBg
            anchors.fill: parent
            anchors.margins: 2
            radius: Appearance.rounding.unsharpenmore
            color: taskBtn.isActive
                ? Appearance.colors.colPrimaryContainer
                : hoverMa.containsMouse
                    ? Appearance.colors.colLayer1
                    : "transparent"
            Behavior on color {
                animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
            }

            // Active indicator dot at bottom
            Rectangle {
                visible: taskBtn.hasWindows
                anchors {
                    horizontalCenter: parent.horizontalCenter
                    bottom: parent.bottom
                    bottomMargin: 3
                }
                width:  taskBtn.isActive ? 12 : 4
                height: 3
                radius: Appearance.rounding.full
                color: taskBtn.isActive
                    ? Appearance.colors.colPrimary
                    : Appearance.colors.colOutlineVariant
                Behavior on width {
                    animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                }
                Behavior on color {
                    animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
                }
            }

            RowLayout {
                anchors.centerIn: parent
                spacing: 4

                // App icon
                IconImage {
                    id: iconImg
                    source: Quickshell.iconPath(AppSearch.guessIcon(taskBtn.appId), "image-missing")
                    implicitSize: Appearance.font.pixelSize.larger
                    opacity: taskBtn.isPinned && !taskBtn.hasWindows ? 0.45 : 1.0
                    Behavior on opacity {
                        animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                    }
                }

                // Label (only for running non-pinned or when showLabels)
                StyledText {
                    id: btnLabel
                    visible: Config.options.tasklistBar.showLabels && taskBtn.hasWindows
                    text: {
                        const name = taskBtn.appId
                        return name.length > 0
                            ? name.charAt(0).toUpperCase() + name.slice(1, 14)
                            : ""
                    }
                    elide: Text.ElideRight
                    font.pixelSize: Appearance.font.pixelSize.small
                    color: taskBtn.isActive
                        ? Appearance.colors.colOnPrimaryContainer
                        : Appearance.colors.colOnLayer1
                }

                // Window count badge
                Rectangle {
                    visible: taskBtn.windowCount > 1
                    width: 16; height: 16; radius: 8
                    color: Appearance.colors.colPrimary
                    StyledText {
                        anchors.centerIn: parent
                        text: taskBtn.windowCount
                        font.pixelSize: Appearance.font.pixelSize.smallest
                        color: Appearance.colors.colOnPrimary
                    }
                }
            }
        }

        MouseArea {
            id: hoverMa
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
            cursorShape: Qt.PointingHandCursor

            onClicked: mouse => {
                if (mouse.button === Qt.LeftButton) {
                    if (!taskBtn.hasWindows) {
                        // Launch via desktop entry
                        const entry = DesktopEntries.heuristicLookup(taskBtn.appId)
                        if (entry) entry.execute()
                    } else {
                        // Cycle through windows
                        const next = taskBtn._lastFocused % taskBtn.toplevels.length
                        taskBtn._lastFocused = (next + 1) % taskBtn.toplevels.length
                        taskBtn.toplevels[next].activate()
                    }
                } else if (mouse.button === Qt.RightButton) {
                    // Toggle pin in tasklistBar config
                    const pinned = Config.options.tasklistBar.pinnedApps.slice()
                    const idx = pinned.indexOf(taskBtn.appId)
                    if (idx >= 0) pinned.splice(idx, 1)
                    else pinned.push(taskBtn.appId)
                    Config.options.tasklistBar.pinnedApps = pinned
                } else if (mouse.button === Qt.MiddleButton) {
                    // Close topmost window
                    if (taskBtn.toplevels.length > 0)
                        taskBtn.toplevels[0].close()
                }
            }

            onWheel: event => {
                WM.switchWorkspaceRelative(event.angleDelta.y > 0 ? "prev" : "next")
            }
        }

        StyledToolTip {
            text: taskBtn.hasWindows
                ? taskBtn.toplevels[0]?.title ?? taskBtn.appId
                : taskBtn.appId
        }
    }
}
