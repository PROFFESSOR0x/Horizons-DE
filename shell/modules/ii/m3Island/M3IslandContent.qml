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
                duration: 420
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Appearance.animationCurves.expressiveDefaultSpatial
            }
            NumberAnimation {
                target: root; property: "launcherEntryOpacity"; to: 1
                duration: 300
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
        if (isLauncher) return 52 + (LauncherSearch.query !== "" ? 328 : 0) + 12
        if (isNotification) return notifContainer.implicitHeight + 16
        if (isExpanded) return Math.max(Config.options.m3Island.expandedHeight, expandedRow.implicitHeight + 16) + 8
        return Appearance.sizes.barHeight
    }
    implicitWidth: contentWidth + islandPadding * 2
    width: contentWidth + islandPadding * 2
    clip: false
    // Single source of morph - smooth spring, no double window anim
    Behavior on implicitHeight { NumberAnimation { duration: Appearance.animation.elementMove.duration; easing.type: Easing.BezierSpline; easing.bezierCurve: Appearance.animationCurves.expressiveDefaultSpatial; alwaysRunToEnd: true } }
    Behavior on implicitWidth { NumberAnimation { duration: Appearance.animation.elementMoveSmall.duration; easing.type: Easing.BezierSpline; easing.bezierCurve: Appearance.animationCurves.expressiveFastSpatial; alwaysRunToEnd: true } }
    Behavior on width { NumberAnimation { duration: Appearance.animation.elementMoveSmall.duration; easing.type: Easing.BezierSpline; easing.bezierCurve: Appearance.animationCurves.expressiveFastSpatial } }

    readonly property real islandPadding: 10
    readonly property real islandSpacing: 6
    readonly property real notificationWidth: Math.max(300, Math.min(520, Appearance.sizes.notificationPopupWidth))
    property real contentWidth: {
        if (isLauncher) return 500
        if (isNotification) return notificationWidth
        if (isExpanded) return Math.max(expandedRow.implicitWidth + 8, clockCenter.implicitWidth + 120)
        if (isHoverPeek) return hoverRow.implicitWidth + 8
        return clockCenter.implicitWidth + 16
    }

    // Helpers to resolve widget loader like TopIsland. A couple of widget ids
    // are island-only (built specifically for the pill format rather than
    // reused from bar/), so resolve those locally before falling back to the
    // shared bar/ widget pool.
    function getWidgetUrl(name) {
        if (name === "m3MiniStats") return Qt.resolvedUrl("M3MiniStats.qml")
        if (name === "m3NotifStatus") return Qt.resolvedUrl("M3NotifStatus.qml")
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
        if (item && "useM3IslandConfig" in item)
            item.useM3IslandConfig = true
        if (item && "isMaterial" in item)
            item.isMaterial = true
    }

    readonly property var hoverLayout: Config.options.m3Island?.layouts?.hoverLayout ?? ["media", "systemIcons"]
    readonly property var expandedLayout: Config.options.m3Island?.layouts?.expandedLayout ?? ["resources", "batteryIndicator"]
    readonly property var filteredExpandedLayout: expandedLayout.filter(n => n !== "systemIcons" && n !== "utilButtons")

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
        radius: root.isLauncher || root.isExpanded || root.isNotification ? Appearance.rounding.large : Appearance.rounding.full
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
        Behavior on radius { NumberAnimation { duration: 260; easing.type: Easing.BezierSpline; easing.bezierCurve: Appearance.animationCurves.expressiveDefaultSpatial } }
        Behavior on color { ColorAnimation { duration: 180; easing.type: Easing.OutCubic } }
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
        width: root.contentWidth
        height: parent.height
        clip: false

        // Idle - clock always centered (morphs out when launcher/notification)
        M3ClockCenter {
            id: clockCenter
            anchors.centerIn: parent
            visible: !root.isLauncher && !root.isNotification && !root.isHoverPeek && !root.isExpanded
            opacity: visible ? 1 : 0
            scale: visible ? 1 : 0.88
            Behavior on opacity { NumberAnimation { duration: 220; easing.type: Easing.BezierSpline; easing.bezierCurve: Appearance.animationCurves.emphasizedAccel } }
            Behavior on scale { NumberAnimation { duration: 280; easing.type: Easing.BezierSpline; easing.bezierCurve: Appearance.animationCurves.expressiveDefaultSpatial } }
            clockStyle: Config.options.m3Island.clockStyle
            showDate: Config.options.m3Island.clockShowDate
        }

        // Hover peek - clock + hover widgets with scale morph
        RowLayout {
            id: hoverRow
            anchors.centerIn: parent
            spacing: root.islandSpacing
            visible: root.isHoverPeek
            opacity: visible ? 1 : 0
            scale: visible ? 1 : 0.96
            Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutCubic; alwaysRunToEnd: true } }
            Behavior on scale { NumberAnimation { duration: 260; easing.type: Easing.BezierSpline; easing.bezierCurve: Appearance.animationCurves.expressiveFastSpatial } }

            M3ClockCenter {
                clockStyle: Config.options.m3Island.clockStyle
                showDate: false
                use24Hour: Config.options.m3Island.clockUse24h
            }
            Rectangle { width: 1; height: 18; color: Appearance.colors.colOutlineVariant; opacity: 0.5 }
            Repeater {
                model: root.hoverLayout
                delegate: Item {
                    required property var modelData
                    required property int index
                    readonly property bool isSys: modelData === "systemIcons"
                    implicitWidth: isSys ? sysBg.implicitWidth : barGroup.implicitWidth
                    implicitHeight: isSys ? sysBg.implicitHeight : barGroup.implicitHeight
                    Bar.BarGroup {
                        id: barGroup
                        visible: !isSys
                        anchors.centerIn: parent
                        currentIndex: index
                        totalCount: root.hoverLayout.length
                        Loader {
                            source: root.getWidgetUrl(modelData)
                            onLoaded: root.configureM3Widget(item)
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
            spacing: 4
            Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

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
                        Bar.BarGroup {
                            id: barGroup2
                            anchors.centerIn: parent
                            currentIndex: index
                            totalCount: root.filteredExpandedLayout.length
                            Loader {
                                source: root.getWidgetUrl(modelData)
                                onLoaded: root.configureM3Widget(item)
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
                        Bar.BarGroup {
                            id: barGroup3
                            anchors.centerIn: parent
                            currentIndex: index
                            totalCount: Config.options.m3Island.expandedQuickToggles.length
                            Loader {
                                source: root.getWidgetUrl(modelData)
                                onLoaded: root.configureM3Widget(item)
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
            anchors.centerIn: parent
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
            Behavior on opacity { NumberAnimation { duration: 260; easing.type: Easing.BezierSpline; easing.bezierCurve: Appearance.animationCurves.emphasizedDecel } }
            Behavior on scale {
                id: scaleBehavior
                NumberAnimation { duration: 320; easing.type: Easing.BezierSpline; easing.bezierCurve: Appearance.animationCurves.expressiveDefaultSpatial }
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
                NumberAnimation { target: notifContainer; property: "scale"; to: 1.08; duration: 150; easing.type: Easing.BezierSpline; easing.bezierCurve: Appearance.animationCurves.expressiveFastSpatial }
                NumberAnimation { target: notifContainer; property: "scale"; to: 1.0; duration: 190; easing.type: Easing.BezierSpline; easing.bezierCurve: Appearance.animationCurves.expressiveFastSpatial }
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
            anchors.centerIn: parent
            width: parent.width
            visible: root.isLauncher
            opacity: visible ? 1 : 0
            scale: visible ? 1 : 0.94
            panelWindow: root.panelWindow
            Behavior on opacity { NumberAnimation { duration: 220; easing.type: Easing.BezierSpline; easing.bezierCurve: Appearance.animationCurves.emphasizedDecel } }
            Behavior on scale { NumberAnimation { duration: 300; easing.type: Easing.BezierSpline; easing.bezierCurve: Appearance.animationCurves.expressiveDefaultSpatial } }
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
