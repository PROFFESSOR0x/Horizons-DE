import QtQuick
import QtQuick.Layouts
import qs
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import qs.modules.common.widgets.widgetCanvas
import qs.modules.ii.background.widgets

AbstractBackgroundWidget {
    id: root

    configEntryName: "clock"
    // Clock is the lock screen's stable visual anchor. All other background
    // widgets continue to obey Lock > Show Widgets and its allow-list.
    visibleWhenLocked: true

    implicitHeight: contentColumn.implicitHeight
    implicitWidth: contentColumn.implicitWidth

    readonly property string clockStyle: root.lockPresentationActive ? Config.options.background.widgets.clock.styleLocked : Config.options.background.widgets.clock.style
    // This remains a real settings choice. The live editor asks before
    // disabling it instead of silently overriding the user's configuration.
    readonly property bool forceCenter: root.lockPresentationActive && Config.options.lock.centerClock
    readonly property bool shouldShow: (!Config.options.background.widgets.clock.showOnlyWhenLocked || root.lockPresentationActive)
    readonly property string customClockColorKey: Config.options.background.widgets.clock.color ?? ""
    readonly property color resolvedClockColor: {
        if (customClockColorKey === "") return root.colText;
        const propName = "col" + customClockColorKey.charAt(0).toUpperCase() + customClockColorKey.slice(1);
        return Appearance.colors[propName] ?? root.colText;
    }
    property bool wallpaperSafetyTriggered: false
    needsColText: clockStyle === "digital"
    property bool centerClockNoticeVisible: false
    // While the lock clock is intentionally centered, a drag would be undone
    // by its centering binding. Show the opt-in action below instead.
    draggable: GlobalStates.lockPreviewOpen ? !forceCenter
        : placementStrategy === "free" && !lockPresentationActive
            && !Config.options.background.widgetsLocked
    onPressed: mouse => {
        if (GlobalStates.lockPreviewOpen && forceCenter) {
            centerClockNoticeVisible = true
            mouse.accepted = true
        }
    }
    x: forceCenter ? ((root.screenWidth - root.width) / 2) : targetX
    y: forceCenter ? ((root.screenHeight - root.height) / 2) : targetY
    // Respects Config.options.lock.enabledWidgets like any other background
    // widget now, so the clock can be selectively hidden on the lock screen too.

    function restoreXYBinding() {
        root.x = Qt.binding(() => root.forceCenter ? ((root.screenWidth - root.width) / 2) : root.targetX);
        root.y = Qt.binding(() => root.forceCenter ? ((root.screenHeight - root.height) / 2) : root.targetY);
    }

    property var textHorizontalAlignment: {
        if (!Config.options.background.widgets.clock.digital.adaptiveAlignment || root.forceCenter || Config.options.background.widgets.clock.digital.vertical) 
            return Text.AlignHCenter;
        if (root.x < root.scaledScreenWidth / 3)
            return Text.AlignLeft;
        if (root.x > root.scaledScreenWidth * 2 / 3)
            return Text.AlignRight;
        return Text.AlignHCenter;
    }

    Column {
        id: contentColumn
        anchors.centerIn: parent
        spacing: 10

        FadeLoader {
            id: cookieClockLoader
            anchors.horizontalCenter: parent.horizontalCenter
            shown: root.clockStyle === "cookie" && (root.shouldShow)
            fade: false
            sourceComponent: CookieClock {
                anchors.horizontalCenter: parent.horizontalCenter
            }
        }

        FadeLoader {
            id: digitalClockLoader
            anchors.horizontalCenter: parent.horizontalCenter
            shown: root.clockStyle === "digital" && (root.shouldShow)
            fade: false
            sourceComponent: DigitalClock {
                colText: root.resolvedClockColor
                textHorizontalAlignment: root.textHorizontalAlignment
            }
        }

        FadeLoader {
            id: pixelClockLoader
            anchors.horizontalCenter: parent.horizontalCenter
            shown: root.clockStyle === "pixel" && (root.shouldShow)
            fade: false
            sourceComponent: PixelClock {}
        }

        FadeLoader {
            id: quoteLoader
            anchors.horizontalCenter: parent.horizontalCenter
            shown: Config.options.background.widgets.clock.quote.enable && (root.clockStyle === "pixel" || root.clockStyle === "cookie") && Config.options.background.widgets.clock.quote.text !== "" && root.shouldShow
            sourceComponent: CookieQuote {}
        }

        StatusRow {
            anchors.horizontalCenter: parent.horizontalCenter
        }
    }

    Rectangle {
        id: centerClockNotice
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.top
        anchors.bottomMargin: 14
        visible: root.centerClockNoticeVisible && GlobalStates.lockPreviewOpen && root.forceCenter
        implicitWidth: noticeRow.implicitWidth + 24
        implicitHeight: noticeRow.implicitHeight + 16
        radius: Appearance.rounding.normal
        color: Appearance.colors.colLayer0
        border.width: 1
        border.color: Appearance.colors.colLayer0Border
        z: 20

        Row {
            id: noticeRow
            anchors.centerIn: parent
            spacing: 10
            MaterialSymbol {
                anchors.verticalCenter: parent.verticalCenter
                text: "center_focus_weak"
                iconSize: Appearance.font.pixelSize.large
                color: Appearance.colors.colPrimary
            }
            StyledText {
                anchors.verticalCenter: parent.verticalCenter
                text: Translation.tr("Center clock is enabled")
                color: Appearance.colors.colOnLayer0
            }
            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                implicitWidth: unlockCenterText.implicitWidth + 18
                implicitHeight: 30
                radius: Appearance.rounding.full
                color: Appearance.colors.colPrimaryContainer
                StyledText {
                    id: unlockCenterText
                    anchors.centerIn: parent
                    text: Translation.tr("Turn it off and move")
                    color: Appearance.colors.colOnPrimaryContainer
                }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        Config.options.lock.centerClock = false
                        root.centerClockNoticeVisible = false
                    }
                }
            }
        }
    }

    component StatusRow: Item {
        id: statusText
        implicitHeight: statusTextBg.implicitHeight
        implicitWidth: statusTextBg.implicitWidth
        StyledRectangularShadow {
            target: statusTextBg
            visible: statusTextBg.visible && root.clockStyle === "cookie"
            opacity: statusTextBg.opacity
        }
        Rectangle {
            id: statusTextBg
            anchors.centerIn: parent
            clip: true
            opacity: (safetyStatusText.shown || lockStatusText.shown) ? 1 : 0
            visible: opacity > 0
            implicitHeight: statusTextRow.implicitHeight + 5 * 2
            implicitWidth: statusTextRow.implicitWidth + 5 * 2
            radius: Appearance.rounding.small
            color: ColorUtils.transparentize(Appearance.colors.colSecondaryContainer, root.clockStyle === "cookie" ? 0 : 1)

            Behavior on implicitWidth {
                animation: Appearance.animation.elementResize.numberAnimation.createObject(this)
            }
            Behavior on implicitHeight {
                animation: Appearance.animation.elementResize.numberAnimation.createObject(this)
            }
            Behavior on opacity {
                animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
            }

            RowLayout {
                id: statusTextRow
                anchors.centerIn: parent
                spacing: 14
                Item {
                    Layout.fillWidth: root.textHorizontalAlignment !== Text.AlignLeft
                    implicitWidth: 1
                }
                ClockStatusText {
                    id: safetyStatusText
                    shown: root.wallpaperSafetyTriggered
                    statusIcon: "hide_image"
                    statusText: Translation.tr("Wallpaper safety enforced")
                }
                ClockStatusText {
                    id: lockStatusText
                    shown: GlobalStates.screenLocked && Config.options.lock.showLockedText
                    statusIcon: "lock"
                    statusText: Translation.tr("Locked")
                }
                Item {
                    Layout.fillWidth: root.textHorizontalAlignment !== Text.AlignRight
                    implicitWidth: 1
                }
            }
        }
    }

    component ClockStatusText: Row {
        id: statusTextRow
        property alias statusIcon: statusIconWidget.text
        property alias statusText: statusTextWidget.text
        property bool shown: true
        property color textColor: root.clockStyle === "cookie" ? Appearance.colors.colOnSecondaryContainer : root.colText
        opacity: shown ? 1 : 0
        visible: opacity > 0
        Behavior on opacity {
            animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
        }
        spacing: 4
        MaterialSymbol {
            id: statusIconWidget
            anchors.verticalCenter: statusTextRow.verticalCenter
            iconSize: Appearance.font.pixelSize.huge
            color: statusTextRow.textColor
            style: Text.Raised
            styleColor: Appearance.colors.colShadow
        }
        ClockText {
            id: statusTextWidget
            color: statusTextRow.textColor
            horizontalAlignment: root.textHorizontalAlignment
            anchors.verticalCenter: statusTextRow.verticalCenter
            font {
                pixelSize: Appearance.font.pixelSize.large
                weight: Font.Normal
            }
            style: Text.Raised
            styleColor: Appearance.colors.colShadow
        }
    }
}
