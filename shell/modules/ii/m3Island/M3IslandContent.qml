pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.UPower
import Quickshell.Services.SystemTray
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import "../bar" as Bar

Item {
    id: root
    property var screen
    property var panelWindow
    property bool mustShow: true
    property bool launcherOpen: GlobalStates.overviewOpen
    property bool hovered: hoverHandler.hovered
    property bool expanded: false
    // A launcher opened from an auto-hidden island needs its own arrival;
    // otherwise a freshly-loaded island starts at its final size with no motion.
    property real launcherEntryScale: 1
    property real launcherEntryOpacity: 1

    readonly property bool isLauncher: launcherOpen
    property var pendingNotif: null
    property var notificationQueue: []
    readonly property bool isNotification: pendingNotif !== null && !isLauncher
    readonly property bool isExpanded: !isLauncher && !isNotification && expanded
    readonly property bool isHoverPeek: !isLauncher && !isNotification && !expanded && hoveredDebounced && Config.options.m3Island.hoverPeek

    // Close expanded when launcher/notification opens. Keep a pending toast in
    // the queue so opening the launcher never silently drops a notification.
    onLauncherOpenChanged: {
        if (launcherOpen) {
            launcherEntrance.restart()
            expanded = false
            if (pendingNotif) {
                notificationQueue = [pendingNotif, ...notificationQueue]
                pendingNotif = null
            }
        } else {
            showNextNotification()
        }
    }

    Component.onCompleted: {
        if (launcherOpen)
            launcherEntrance.restart()
    }

    SequentialAnimation {
        id: launcherEntrance
        PropertyAction { target: root; property: "launcherEntryScale"; value: 0.82 }
        PropertyAction { target: root; property: "launcherEntryOpacity"; value: 0 }
        ParallelAnimation {
            NumberAnimation {
                target: root; property: "launcherEntryScale"; to: 1
                duration: root.animMs(420)
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Appearance.animationCurves.expressiveDefaultSpatial
            }
            NumberAnimation {
                target: root; property: "launcherEntryOpacity"; to: 1
                duration: root.animMs(300)
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Appearance.animationCurves.emphasizedDecel
            }
        }
    }
    onIsNotificationChanged: if (isNotification) expanded = false
    onIsExpandedChanged: if (!isExpanded) showNextNotification()

    property bool notifHoverEnabled: false
    Timer { id: notifHoverEnableTimer; interval: 500; onTriggered: root.notifHoverEnabled = true }

    Connections {
        target: Notifications
        function onNotify(notif) {
            if (Config.options.bar.barMode !== "m3Island") return
            if (Config.options.notifications.displayMode !== "island") return
            // Notifications that are silent or inhibited never become popups.
            // Respect that state instead of showing them through the island.
            if (!notif.popup) return
            root.enqueueNotification(notif)
        }
        function onDiscard(id) {
            root.notificationQueue = root.notificationQueue.filter(notif => notif.notificationId !== id)
            if (root.pendingNotif && root.pendingNotif.notificationId === id) {
                root.pendingNotif = null
                root.showNextNotification()
            }
        }
    }
    Timer {
        id: notifTimer
        interval: Config.options.notifications.timeout
        onTriggered: {
            root.pendingNotif = null
            root.notifHovered = false
            root.showNextNotification()
        }
    }

    function enqueueNotification(notif) {
        if (!notif || !notif.popup) return
        if (pendingNotif && pendingNotif.notificationId === notif.notificationId) return
        if (notificationQueue.some(queued => queued.notificationId === notif.notificationId)) return
        notificationQueue = [...notificationQueue, notif]
        showNextNotification()
    }

    function showNextNotification() {
        if (pendingNotif || isLauncher || isExpanded) return
        while (notificationQueue.length > 0) {
            const next = notificationQueue[0]
            notificationQueue = notificationQueue.slice(1)
            // A queued popup can expire before it reaches the front.
            if (!next.popup) continue
            pendingNotif = next
            notifHovered = false
            notifHoverEnabled = false
            notifHoverEnableTimer.restart()
            const configuredTimeout = Config.options.m3Island.notificationTimeout
            notifTimer.interval = configuredTimeout > 0
                ? configuredTimeout
                : (next.timer ? next.timer.interval : Config.options.notifications.timeout)
            notifTimer.restart()
            return
        }
    }

    // Tap outside to collapse when expanded
    Connections {
        target: GlobalFocusGrab
        function onDismissed() { if (root.isExpanded) root.expanded = false }
    }

    // Shared expand/collapse helper - used by click, scroll (layoutCycle),
    // the right-click menu, and the m3Island IPC handler so they all agree
    // on the focus-grab bookkeeping instead of duplicating it.
    function setExpanded(value) {
        if (root.isLauncher) return
        const target = !!value
        if (target === root.expanded) return
        root.expanded = target
        if (root.expanded) GlobalFocusGrab.addDismissable(root.panelWindow)
        else GlobalFocusGrab.dismiss()
    }

    // Advances past whatever notification is currently pending/queued without
    // waiting for its timeout. Used by the m3Island IPC dismissNotification().
    function dismissCurrentNotification() {
        if (root.pendingNotif) {
            Notifications.discardNotification(root.pendingNotif.notificationId)
        } else if (root.notificationQueue.length > 0) {
            root.notificationQueue = root.notificationQueue.slice(1)
        }
    }

    property bool notifHovered: false
    implicitHeight: {
        // The inline launcher reports the height of its actual result list.
        // This keeps the island compact for one match and grows it only as
        // more matches arrive (up to the configured visible-result limit).
        if (isLauncher) return launcherInline.implicitHeight + 12
        if (isNotification) return notifContainer.implicitHeight + 16
        if (isExpanded) return Math.max(Config.options.m3Island.expandedHeight, expandedRow.implicitHeight + 16) + 8
        return Appearance.sizes.barHeight
    }
    implicitWidth: contentWidth + islandPadding * 2
    width: contentWidth + islandPadding * 2
    clip: false
    // One visible surface morph. Hover expansion gets enough travel time to be
    // perceived as a deliberate widening of the island, not a one-frame jump.
    Behavior on implicitHeight { NumberAnimation { duration: root.animMs(root.isHoverPeek || root.isExpanded ? 360 : 240); easing.type: Easing.BezierSpline; easing.bezierCurve: Appearance.animationCurves.expressiveDefaultSpatial; alwaysRunToEnd: true } }
    Behavior on implicitWidth { NumberAnimation { duration: root.animMs(root.isHoverPeek || root.isExpanded ? 440 : 260); easing.type: Easing.BezierSpline; easing.bezierCurve: Appearance.animationCurves.expressiveDefaultSpatial; alwaysRunToEnd: true } }
    Behavior on width { NumberAnimation { duration: root.animMs(root.isHoverPeek || root.isExpanded ? 440 : 260); easing.type: Easing.BezierSpline; easing.bezierCurve: Appearance.animationCurves.expressiveDefaultSpatial; alwaysRunToEnd: true } }

    readonly property real islandPadding: 10
    readonly property real islandSpacing: 6
    readonly property real notificationWidth: Math.max(300, Math.min(520, Appearance.sizes.notificationPopupWidth))
    property real contentWidth: {
        if (isLauncher) return 500
        if (isNotification) return notificationWidth
        if (isExpanded) return Math.max(expandedRow.implicitWidth + 8, restingRow.implicitWidth + 120)
        if (isHoverPeek) return hoverRow.implicitWidth + 8
        return restingRow.implicitWidth + 16
    }

    // Helpers to resolve widget loader like TopIsland. A couple of widget ids
    // are island-only (built specifically for the pill format rather than
    // reused from bar/), so resolve those locally before falling back to the
    // shared bar/ widget pool.
    function getWidgetUrl(name) {
        if (name === "m3MiniStats") return Qt.resolvedUrl("M3MiniStats.qml")
        if (name === "m3NotifStatus") return Qt.resolvedUrl("M3NotifStatus.qml")
        // The clock used to be a hardcoded fixture of the resting pill,
        // unreachable through restingLayout like every other widget here -
        // exposing it as a normal loadable widget is what lets it sit next to
        // other widgets (on either side) instead of always alone, or be left
        // out of restingLayout entirely.
        if (name === "m3Clock") return Qt.resolvedUrl("M3ClockCenter.qml")
        return BarLayoutUtils.getWidgetUrl(name)
    }

    // Animation duration multiplier driven by Config.options.m3Island.animationSpeed.
    // Curves are left untouched - this only changes how fast the existing
    // motion plays out.
    readonly property real animScale: {
        const speed = Config.options.m3Island.animationSpeed
        if (speed === "slow") return 1.5
        if (speed === "fast") return 0.6
        return 1.0
    }
    // animScale used to be declared and then never read, so the "Animation
    // speed" setting did nothing at all. Every island duration goes through
    // here now. Appearance.motionDurationScale is folded in as well so the
    // island follows the global motion setting like the rest of the shell.
    function animMs(baseDuration) {
        return Math.max(1, Math.round(baseDuration * root.animScale * Appearance.motionDurationScale))
    }

    // Right-click quick-actions menu contents. Kept as a plain reactive array
    // so entries can hide themselves (e.g. no media player) without the menu
    // component needing to know anything about island state.
    readonly property var contextMenuEntries: [
        {
            icon: root.isExpanded ? "collapse_content" : "open_in_full",
            label: root.isExpanded ? Translation.tr("Collapse") : Translation.tr("Expand"),
            visible: !root.isLauncher && !root.isNotification,
            action: () => root.setExpanded(!root.isExpanded)
        },
        {
            icon: "schedule",
            label: Translation.tr("Cycle clock style"),
            visible: true,
            action: () => {
                const styles = ["m3", "minimal", "digital"]
                const idx = styles.indexOf(Config.options.m3Island.clockStyle)
                Config.options.m3Island.clockStyle = styles[(idx + 1) % styles.length]
            }
        },
        {
            icon: MprisController.isPlaying ? "pause" : "play_arrow",
            label: MprisController.isPlaying ? Translation.tr("Pause media") : Translation.tr("Play media"),
            visible: !!MprisController.activePlayer,
            action: () => MprisController.togglePlaying()
        },
        {
            icon: (Audio.sink?.audio.muted ?? false) ? "volume_off" : "volume_up",
            label: (Audio.sink?.audio.muted ?? false) ? Translation.tr("Unmute audio") : Translation.tr("Mute audio"),
            visible: true,
            action: () => Audio.toggleMute()
        },
        {
            icon: "settings",
            label: Translation.tr("Island settings"),
            visible: true,
            action: () => {
                GlobalStates.settingsOpen = true
                GlobalStates.settingsPage = "bar:m3 island"
            }
        }
    ]

    // Reused bar widgets normally read Config.options.bar. Give them an
    // explicit M3 scope instead of duplicating their implementation.
    function configureM3Widget(item) {
        if (!item) return
        if ("useM3IslandConfig" in item)
            item.useM3IslandConfig = true
        // `in` is true for read-only properties too, and a widget that binds
        // isMaterial read-only would throw on assignment - don't let one
        // widget's declaration break the whole row.
        if ("isMaterial" in item) {
            try { item.isMaterial = true } catch (e) {}
        }
    }

    // Every row loads widgets by id, and "m3Clock" needs its own options
    // applied instead of the generic bar-widget ones. Keep that in one place so
    // the clock behaves identically wherever it is placed in a layout.
    function applyWidgetConfig(name, item) {
        if (!item) return
        if (name === "m3Clock") {
            item.clockStyle = Config.options.m3Island.clockStyle
            item.showDate = Config.options.m3Island.clockShowDate
            item.use24Hour = Config.options.m3Island.clockUse24h
        } else {
            root.configureM3Widget(item)
        }
    }

    readonly property var restingLayout: Config.options.m3Island?.layouts?.restingLayout ?? ["m3Clock"]
    readonly property var hoverLayout: Config.options.m3Island?.layouts?.hoverLayout ?? ["media", "systemIcons"]
    readonly property var expandedLayout: Config.options.m3Island?.layouts?.expandedLayout ?? ["resources", "batteryIndicator"]
    readonly property var filteredExpandedLayout: expandedLayout.filter(n => n !== "systemIcons" && n !== "utilButtons")
    // The hover/expanded rows each still draw a clock of their own so the
    // stock layouts look unchanged, but it has to step aside as soon as the
    // user places "m3Clock" in that row themselves.
    readonly property bool hoverLayoutHasClock: hoverLayout.includes("m3Clock")
    readonly property bool expandedLayoutHasClock: expandedLayout.includes("m3Clock")

    HoverHandler { id: hoverHandler }
    // Debounce hover to avoid flicker when mouse jitters at edge
    property bool hoveredDebounced: false
    Timer { id: hoverDebounceIn; interval: Config.options.m3Island.hoverPeekDelayIn; onTriggered: hoveredDebounced = true }
    Timer { id: hoverDebounceOut; interval: Config.options.m3Island.hoverPeekDelayOut; onTriggered: hoveredDebounced = false }
    onHoveredChanged: {
        if (hovered) { hoverDebounceOut.stop(); hoverDebounceIn.restart() }
        else { hoverDebounceIn.stop(); hoverDebounceOut.restart() }
    }

    // Bridges the m3Island IPC handler (in M3Island.qml, one level up and
    // outside this per-screen content item) to the same helpers used by
    // click/scroll/the right-click menu.
    Connections {
        target: M3IslandState
        function onRequestExpand() { root.setExpanded(true) }
        function onRequestCollapse() { root.setExpanded(false) }
        function onRequestToggleExpand() { root.setExpanded(!root.isExpanded) }
        function onRequestDismissNotification() { root.dismissCurrentNotification() }
    }

    // Island-wide scroll handling. Volume used to be handled locally inside
    // M3ClockCenter (clock area only) - centralized here so it also covers
    // the rest of the pill, and so mediaSeek/layoutCycle share the same wheel
    // accounting instead of adding competing handlers that could double-fire
    // on the same event.
    property real wheelRemainder: 0
    WheelHandler {
        id: islandWheelHandler
        target: root
        enabled: !root.isLauncher && Config.options.m3Island.scrollAction !== "none"
        onWheel: event => {
            const action = Config.options.m3Island.scrollAction
            const delta = event.angleDelta.y !== 0 ? event.angleDelta.y : event.pixelDelta.y
            if (delta === 0) return

            if (action === "volume") {
                root.wheelRemainder += delta
                const threshold = event.angleDelta.y !== 0 ? 120 : 24
                while (root.wheelRemainder >= threshold) {
                    Audio.incrementVolume()
                    root.wheelRemainder -= threshold
                }
                while (root.wheelRemainder <= -threshold) {
                    Audio.decrementVolume()
                    root.wheelRemainder += threshold
                }
            } else if (action === "mediaSeek") {
                if (delta > 0) MprisController.next()
                else if (delta < 0) MprisController.previous()
            } else if (action === "layoutCycle") {
                root.setExpanded(!root.isExpanded)
            }
            event.accepted = true
        }
    }

    // Right-click quick-actions menu, anchored to this island's own window.
    Loader {
        id: contextMenuLoader
        active: Config.options.m3Island.rightClickMenu
        sourceComponent: M3ContextMenu {
            hostWindow: root.panelWindow
            entries: root.contextMenuEntries
        }
    }

    // Background pill - morphs radius and hug corners
    Rectangle {
        id: islandBg
        anchors.fill: parent
        // Hug: top edge square against screen, float: all rounded; notification uses secondary container
        // Appearance.rounding.full is a 9999 sentinel that Rectangle clamps to
        // min(w,h)/2 at paint time. Animating 9999 -> 23 therefore looked like
        // nothing at all until the value finally dropped under the clamp near
        // the very end of the transition, where it popped square in one frame.
        // Resolving the pill state to its *effective* radius (half the current,
        // already-animating height) makes the corners morph continuously with
        // the surface instead.
        radius: (root.isLauncher || root.isExpanded || root.isNotification)
            ? Appearance.rounding.large
            : Math.max(0, root.height / 2)
        readonly property bool hugsScreen: Config.options.m3Island.cornerStyle === 0
            && (!root.isLauncher || Config.options.m3Island.launcherHug)
        topLeftRadius: hugsScreen && !Config.options.bar.bottom ? 0 : radius
        topRightRadius: hugsScreen && !Config.options.bar.bottom ? 0 : radius
        bottomLeftRadius: hugsScreen && Config.options.bar.bottom ? 0 : radius
        bottomRightRadius: hugsScreen && Config.options.bar.bottom ? 0 : radius
        color: {
            if (!Config.options.m3Island.showBackground) return "transparent"
            if (Config.options.m3Island.followFrameColor) return Appearance.getColorFromName(Config.options.m3Island.frameColor)
            if (root.isLauncher) return Appearance.colors.colBackgroundSurfaceContainer
            if (root.isNotification) return Appearance.colors.colSecondaryContainer
            return Appearance.colors.colLayer0
        }
        border.width: Config.options.m3Island.showFrame ? Config.options.m3Island.frameThickness : (Config.options.m3Island.cornerStyle === 1 ? 1 : 0)
        border.color: Config.options.m3Island.showFrame
            ? Appearance.getColorFromName(Config.options.m3Island.frameColor)
            : Appearance.colors.colLayer0Border
        // Matches the surface's own height/width durations so the corner and
        // the box arrive together.
        Behavior on radius { NumberAnimation { duration: root.animMs(root.isHoverPeek || root.isExpanded ? 360 : 240); easing.type: Easing.BezierSpline; easing.bezierCurve: Appearance.animationCurves.expressiveDefaultSpatial } }
        Behavior on color { ColorAnimation { duration: root.animMs(180); easing.type: Easing.OutCubic } }
    }
    StyledRectangularShadow {
        target: islandBg
        visible: Config.options.m3Island.cornerStyle === 1
    }

    // Tap to expand / collapse, right-click for the quick-actions menu
    MouseArea {
        id: clickArea
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        // Let hover pass through to HoverHandler, but handle click
        onClicked: mouse => {
            if (mouse.button === Qt.RightButton) {
                if (!Config.options.m3Island.rightClickMenu || !contextMenuLoader.item) return
                const pt = clickArea.mapToItem(null, mouse.x, mouse.y)
                contextMenuLoader.item.showAt(pt.x, pt.y)
                return
            }
            if (root.isLauncher) return
            if (Config.options.m3Island.clickToExpand) {
                root.setExpanded(!root.expanded)
            }
        }
        // Prevent stealing hover from children. Scroll is handled by
        // islandWheelHandler above, so scrollable content remains scrollable.
        hoverEnabled: false
    }

    // Content stack - no clip, allow expanded to show fully
    Item {
        id: contentStack
        anchors.centerIn: parent
        // Use the current animated island width, not the destination width.
        // This makes the widgets emerge from within the widening surface.
        width: parent.width
        height: parent.height
        // The launcher grows the island's height while results are created.
        // Clip the stack during that growth so result text can never paint
        // outside the animated background.
        clip: root.isLauncher || root.isHoverPeek || root.isExpanded

        // Idle - restingLayout, customizable (used to be a hardcoded, always-
        // alone clock with no way to add widgets beside it or remove it -
        // "m3Clock" is just this list's default entry now, like any other
        // widget id, so it can share the row with others on either side).
        RowLayout {
            id: restingRow
            anchors.centerIn: parent
            spacing: root.islandSpacing
            visible: !root.isLauncher && !root.isNotification && !root.isHoverPeek && !root.isExpanded
            opacity: visible ? 1 : 0
            scale: visible ? 1 : 0.88
            Behavior on opacity { NumberAnimation { duration: root.animMs(220); easing.type: Easing.BezierSpline; easing.bezierCurve: Appearance.animationCurves.emphasizedAccel } }
            Behavior on scale { NumberAnimation { duration: root.animMs(280); easing.type: Easing.BezierSpline; easing.bezierCurve: Appearance.animationCurves.expressiveDefaultSpatial } }

            Repeater {
                model: root.restingLayout
                delegate: Loader {
                    required property var modelData
                    source: root.getWidgetUrl(modelData)
                    onLoaded: root.applyWidgetConfig(modelData, item)
                }
            }
        }

        // Hover peek - let the surface widen first, then reveal its contents
        // in reading order instead of dropping every widget in at once.
        RowLayout {
            id: hoverRow
            anchors.centerIn: parent
            spacing: root.islandSpacing
            visible: root.isHoverPeek
            opacity: visible ? 1 : 0
            scale: visible ? 1 : 0.96
            Behavior on opacity { NumberAnimation { duration: root.animMs(180); easing.type: Easing.OutCubic; alwaysRunToEnd: true } }
            Behavior on scale { NumberAnimation { duration: root.animMs(260); easing.type: Easing.BezierSpline; easing.bezierCurve: Appearance.animationCurves.expressiveFastSpatial } }

            // Only a fallback now. If "m3Clock" is in hoverLayout the clock is
            // rendered by the Repeater below at the position the user chose -
            // keeping this one unconditionally is what put two clocks in the
            // peeked island at once.
            M3ClockCenter {
                visible: !root.hoverLayoutHasClock
                opacity: root.isHoverPeek ? 1 : 0
                scale: root.isHoverPeek ? 1 : 0.84
                Behavior on opacity {
                    SequentialAnimation {
                        PauseAnimation { duration: root.isHoverPeek ? root.animMs(20) : 0 }
                        NumberAnimation { duration: root.animMs(160); easing.type: Easing.OutCubic }
                    }
                }
                Behavior on scale {
                    SequentialAnimation {
                        PauseAnimation { duration: root.isHoverPeek ? root.animMs(20) : 0 }
                        NumberAnimation { duration: root.animMs(220); easing.type: Easing.BezierSpline; easing.bezierCurve: Appearance.animationCurves.expressiveFastSpatial }
                    }
                }
                clockStyle: Config.options.m3Island.clockStyle
                showDate: false
                use24Hour: Config.options.m3Island.clockUse24h
            }
            Rectangle {
                visible: !root.hoverLayoutHasClock
                width: 1; height: 18; color: Appearance.colors.colOutlineVariant
                opacity: root.isHoverPeek ? 0.5 : 0
                Behavior on opacity {
                    SequentialAnimation {
                        PauseAnimation { duration: root.isHoverPeek ? root.animMs(40) : 0 }
                        NumberAnimation { duration: root.animMs(140); easing.type: Easing.OutCubic }
                    }
                }
            }
            Repeater {
                model: root.hoverLayout
                delegate: Item {
                    required property var modelData
                    required property int index
                    readonly property bool isSys: modelData === "systemIcons"
                    implicitWidth: isSys ? sysBg.implicitWidth : barGroup.implicitWidth
                    implicitHeight: isSys ? sysBg.implicitHeight : barGroup.implicitHeight
                    opacity: root.isHoverPeek ? 1 : 0
                    scale: root.isHoverPeek ? 1 : 0.78
                    transformOrigin: Item.Center
                    Behavior on opacity {
                        SequentialAnimation {
                            PauseAnimation { duration: root.isHoverPeek ? root.animMs(60 + index * 32) : 0 }
                            NumberAnimation { duration: root.animMs(170); easing.type: Easing.OutCubic }
                        }
                    }
                    Behavior on scale {
                        SequentialAnimation {
                            PauseAnimation { duration: root.isHoverPeek ? root.animMs(60 + index * 32) : 0 }
                            NumberAnimation { duration: root.animMs(250); easing.type: Easing.BezierSpline; easing.bezierCurve: Appearance.animationCurves.expressiveDefaultSpatial }
                        }
                    }
                    Bar.BarGroup {
                        id: barGroup
                        visible: !isSys
                        anchors.centerIn: parent
                        currentIndex: index
                        totalCount: root.hoverLayout.length
                        Loader {
                            source: root.getWidgetUrl(modelData)
                            onLoaded: root.applyWidgetConfig(modelData, item)
                        }
                    }
                    Rectangle {
                        id: sysBg
                        visible: isSys
                        anchors.centerIn: parent
                        implicitWidth: sysLoader.implicitWidth + 16
                        implicitHeight: 30
                        radius: Appearance.rounding.full
                        color: Appearance.colors.colPrimary
                        border.width: 0
                        Loader {
                            id: sysLoader
                            anchors.centerIn: parent
                            source: visible ? root.getWidgetUrl(modelData) : ""
                            onLoaded: root.configureM3Widget(item)
                        }
                    }
                }
            }
        }

        // Expanded - two rows layout centered
        ColumnLayout {
            id: expandedRow
            anchors.centerIn: parent
            visible: root.isExpanded
            opacity: visible ? 1 : 0
            scale: visible ? 1 : 0.9
            spacing: 4
            Behavior on opacity { NumberAnimation { duration: root.animMs(200); easing.type: Easing.OutCubic } }
            Behavior on scale { NumberAnimation { duration: root.animMs(280); easing.type: Easing.BezierSpline; easing.bezierCurve: Appearance.animationCurves.expressiveDefaultSpatial } }

            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: 8
                // Left: util buttons
                Rectangle {
                    implicitWidth: utilLoader.implicitWidth + 10
                    implicitHeight: 28
                    radius: Appearance.rounding.full
                    color: Appearance.colors.colSecondaryContainer
                    visible: utilLoader.source.toString() !== ""
                    Loader {
                        id: utilLoader
                        anchors.centerIn: parent
                        source: root.getWidgetUrl("utilButtons")
                        onLoaded: root.configureM3Widget(item)
                    }
                }
                M3ClockCenter {
                    visible: !root.expandedLayoutHasClock
                    clockStyle: Config.options.m3Island.clockStyle
                    showDate: true
                    use24Hour: Config.options.m3Island.clockUse24h
                }
                Rectangle { visible: Config.options.m3Island.verbose; width: 1; height: 20; color: Appearance.colors.colOutlineVariant; opacity: 0.4 }
                StyledText { visible: Config.options.m3Island.verbose; text: DateTime.uptime; font.pixelSize: Appearance.font.pixelSize.smallest; color: Appearance.colors.colOnLayer1 }
                Rectangle { visible: Config.options.m3Island.verbose; width: 1; height: 20; color: Appearance.colors.colOutlineVariant; opacity: 0.4 }
                // Right: system icons
                Rectangle {
                    implicitWidth: sysTopLoader.implicitWidth + 12
                    implicitHeight: 28
                    radius: Appearance.rounding.full
                    color: Appearance.colors.colPrimary
                    Loader {
                        id: sysTopLoader
                        anchors.centerIn: parent
                        source: root.getWidgetUrl("systemIcons")
                        onLoaded: root.configureM3Widget(item)
                    }
                }
            }
            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: root.islandSpacing
                visible: Config.options.m3Island.verbose && filteredExpandedLayout.length > 0
                Repeater {
                    model: root.filteredExpandedLayout
                    delegate: Item {
                        required property var modelData
                        required property int index
                        implicitWidth: barGroup2.implicitWidth
                        implicitHeight: barGroup2.implicitHeight
                        opacity: root.isExpanded ? 1 : 0
                        scale: root.isExpanded ? 1 : 0.82
                        Behavior on opacity {
                            SequentialAnimation {
                                PauseAnimation { duration: root.isExpanded ? root.animMs(60 + index * 30) : 0 }
                                NumberAnimation { duration: root.animMs(160); easing.type: Easing.OutCubic }
                            }
                        }
                        Behavior on scale {
                            SequentialAnimation {
                                PauseAnimation { duration: root.isExpanded ? root.animMs(60 + index * 30) : 0 }
                                NumberAnimation { duration: root.animMs(230); easing.type: Easing.BezierSpline; easing.bezierCurve: Appearance.animationCurves.expressiveDefaultSpatial }
                            }
                        }
                        Bar.BarGroup {
                            id: barGroup2
                            anchors.centerIn: parent
                            currentIndex: index
                            totalCount: root.filteredExpandedLayout.length
                            Loader {
                                source: root.getWidgetUrl(modelData)
                                onLoaded: root.applyWidgetConfig(modelData, item)
                            }
                        }
                    }
                }
            }
            // Extra quick-toggle row, shown only while expanded and opted in.
            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: root.islandSpacing
                visible: Config.options.m3Island.showExpandedQuickToggles
                    && Config.options.m3Island.expandedQuickToggles.length > 0
                Repeater {
                    model: Config.options.m3Island.expandedQuickToggles
                    delegate: Item {
                        required property var modelData
                        required property int index
                        implicitWidth: barGroup3.implicitWidth
                        implicitHeight: barGroup3.implicitHeight
                        opacity: root.isExpanded ? 1 : 0
                        scale: root.isExpanded ? 1 : 0.82
                        Behavior on opacity {
                            SequentialAnimation {
                                PauseAnimation { duration: root.isExpanded ? root.animMs(90 + index * 30) : 0 }
                                NumberAnimation { duration: root.animMs(160); easing.type: Easing.OutCubic }
                            }
                        }
                        Behavior on scale {
                            SequentialAnimation {
                                PauseAnimation { duration: root.isExpanded ? root.animMs(90 + index * 30) : 0 }
                                NumberAnimation { duration: root.animMs(230); easing.type: Easing.BezierSpline; easing.bezierCurve: Appearance.animationCurves.expressiveDefaultSpatial }
                            }
                        }
                        Bar.BarGroup {
                            id: barGroup3
                            anchors.centerIn: parent
                            currentIndex: index
                            totalCount: Config.options.m3Island.expandedQuickToggles.length
                            Loader {
                                source: root.getWidgetUrl(modelData)
                                onLoaded: root.applyWidgetConfig(modelData, item)
                            }
                        }
                    }
                }
            }
        }

        // Reuse the regular notification card inside the island. It retains the
        // normal popup's rich body, action buttons, and height animation.
        NotificationGroup {
            id: notifContainer
            // Same reasoning as launcherInline below: root's implicitHeight
            // is notifContainer.implicitHeight + 16 (8px at rest either
            // side), but root's *actual* height animates toward that
            // target (Behavior on implicitHeight above) on its own timing
            // while notifContainer's own height changes on hover-expand at
            // a different pace - centering read that mismatch as "the
            // whole card needs to slide," which is the "bar's expansion
            // doesn't match the notification's own expansion" symptom.
            // Top-anchoring means a lagging frame only ever shows as
            // extra/missing space below the card.
            anchors.top: parent.top
            anchors.topMargin: 8
            anchors.horizontalCenter: parent.horizontalCenter
            width: root.notificationWidth
            implicitWidth: width
            visible: root.isNotification
            opacity: visible ? 1 : 0
            scale: visible ? 1 : 0.92
            z: 10
            popup: true
            managePopupTimeout: false
            allowDrag: false
            expandOnHover: root.notifHoverEnabled
            hoverExpandDelay: 180
            expanded: root.notifHovered
            notificationGroup: root.pendingNotif ? ({
                appName: root.pendingNotif.appName,
                appIcon: root.pendingNotif.appIcon,
                notifications: [root.pendingNotif],
                time: root.pendingNotif.time
            }) : null
            Behavior on opacity { NumberAnimation { duration: root.animMs(260); easing.type: Easing.BezierSpline; easing.bezierCurve: Appearance.animationCurves.emphasizedDecel } }
            Behavior on scale {
                id: scaleBehavior
                NumberAnimation { duration: root.animMs(320); easing.type: Easing.BezierSpline; easing.bezierCurve: Appearance.animationCurves.expressiveDefaultSpatial }
            }
            // Subtle overscale/overshoot spring on arrival, opt-in via
            // Config.options.m3Island.expressiveNotifications. Reuses the same
            // expressive spatial curve as the rest of the island's motion
            // (just applied twice, out then back) instead of inventing new
            // easing constants. Runs as an explicit animation instead of
            // through the Behavior above so it can overshoot past 1.0 before
            // settling; the Behavior is disabled for its duration so the two
            // don't fight over the same property.
            SequentialAnimation {
                id: expressiveArrival
                onStopped: scaleBehavior.enabled = true
                NumberAnimation { target: notifContainer; property: "scale"; to: 1.08; duration: root.animMs(150); easing.type: Easing.BezierSpline; easing.bezierCurve: Appearance.animationCurves.expressiveFastSpatial }
                NumberAnimation { target: notifContainer; property: "scale"; to: 1.0; duration: root.animMs(190); easing.type: Easing.BezierSpline; easing.bezierCurve: Appearance.animationCurves.expressiveFastSpatial }
            }
            onExpandedChanged: {
                root.notifHovered = expanded
                if (expanded) notifTimer.stop()
                else if (root.isNotification) notifTimer.restart()
            }
            onVisibleChanged: {
                if (!visible) { root.notifHovered = false; root.notifHoverEnabled = false; return }
                if (Config.options.m3Island.expressiveNotifications) {
                    scaleBehavior.enabled = false
                    notifContainer.scale = 0.92
                    expressiveArrival.restart()
                }
            }
        }

        // Launcher - morphs from same pill
        M3LauncherInline {
            id: launcherInline
            // Anchored to the top edge, not centered: root's own
            // implicitHeight is launcherInline.implicitHeight + 12 (see
            // above), so at rest centering leaves the same 6px on both
            // sides either way - but root's *actual* height animates
            // toward that target (Behavior on implicitHeight below) while
            // launcherInline's own height jumps instantly as results
            // appear/disappear. For that whole transition, root.height
            // lags behind launcherInline.implicitHeight, and centering
            // read that mismatch as "launcherInline (search bar included)
            // needs to slide" every time. Top-anchoring means a lagging
            // frame only ever shows up as extra/missing space below the
            // results, never as the search bar moving.
            anchors.top: parent.top
            anchors.topMargin: 6
            anchors.horizontalCenter: parent.horizontalCenter
            width: parent.width
            visible: root.isLauncher
            opacity: visible ? 1 : 0
            scale: visible ? 1 : 0.94
            panelWindow: root.panelWindow
            Behavior on opacity { NumberAnimation { duration: root.animMs(220); easing.type: Easing.BezierSpline; easing.bezierCurve: Appearance.animationCurves.emphasizedDecel } }
            Behavior on scale { NumberAnimation { duration: root.animMs(300); easing.type: Easing.BezierSpline; easing.bezierCurve: Appearance.animationCurves.expressiveDefaultSpatial } }
        }
    }

    // When launcher opens, ensure island is focused
    Connections {
        target: GlobalStates
        function onOverviewOpenChanged() {
            if (GlobalStates.overviewOpen) {
                // Ensure panelWindow gets focus for input
                if (root.panelWindow) GlobalFocusGrab.addDismissable(root.panelWindow)
            }
        }
    }
}
