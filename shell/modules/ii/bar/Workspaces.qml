pragma ComponentBehavior: Bound
import qs
import qs.services
import qs.modules.common
import qs.modules.common.models
import qs.modules.common.widgets
import qs.modules.common.functions
import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell

ButtonMouseArea {
    id: root
    property bool useM3IslandConfig: false
    readonly property var workspaceOptions: useM3IslandConfig
        ? Config.options.m3Island.workspaces : Config.options.bar.workspaces
    onContainsMouseChanged: {
        GlobalStates.workspacesHovered = containsMouse && (Config?.options.overview.hoverPreviewInBar ?? false) && !GlobalStates.overviewOpen && !GlobalStates.screenLocked
        if (containsMouse) {
            GlobalStates.workspacesHoveredScreen = root.QsWindow.window?.screen ?? null
            GlobalStates.workspacesHoveredIndex = hoverIndex
            GlobalStates.workspacesHoveredId = wsModel.getWorkspaceIdAt(hoverIndex)
        }
    }
    onHoverIndexChanged: if (containsMouse) { GlobalStates.workspacesHoveredIndex = hoverIndex; GlobalStates.workspacesHoveredId = wsModel.getWorkspaceIdAt(hoverIndex) }

    WorkspaceModel {
        id: wsModel
        screen: root.QsWindow.window?.screen
        workspaceOptions: root.workspaceOptions
    }

    property bool vertical: useM3IslandConfig ? false : Config.options.bar.vertical
    property bool superPressAndHeld: false // Relevant modifications at bottom of file

    property real workspaceButtonWidth: (useM3IslandConfig || Config.options.bar.cornerStyle === 3) ? 30 : 26
    property real activeWorkspaceMargin: 2
    property real activeWorkspaceSize: workspaceButtonWidth - activeWorkspaceMargin * 2
    property real workspaceIconSize: workspaceButtonWidth * 0.69
    property real workspaceIconSizeShrinked: workspaceButtonWidth * 0.55
    property real workspaceIconOpacityShrinked: 1
    property real workspaceIconMarginShrinked: -4
    property int workspaceIndexInGroup: (wsModel.activeNumber - 1) % wsModel.shownCount
    property real specialTextSize: workspaceButtonWidth * 0.5

    Layout.alignment: vertical ? Qt.AlignHCenter : Qt.AlignVCenter
    Layout.fillWidth: vertical
    Layout.fillHeight: !vertical
    readonly property real barThickness: vertical ? Appearance.sizes.verticalBarWidth : Appearance.sizes.barHeight
    implicitWidth: vertical ? barThickness : occupiedIndicators.implicitWidth
    implicitHeight: vertical ? occupiedIndicators.implicitHeight : barThickness

    property real specialBlur: (wsModel.specialWorkspaceActive && !containsMouse) ? 1 : 0
    Behavior on specialBlur {
        animation: Appearance.animation.elementMoveSmall.numberAnimation.createObject(this)
    }

    // Interactions
    acceptedButtons: Qt.LeftButton | Qt.RightButton
    hoverEnabled: true
    property int hoverIndex: {
        const position = root.vertical ? mouseY : mouseX;
        return Math.floor(position / root.workspaceButtonWidth);
    }

    function switchWorkspaceToHovered() {
        WM.switchWorkspace(wsModel.getWorkspaceIdAt(hoverIndex));
    }
    onPressed: mouse => {
        if (mouse.button == Qt.LeftButton)
            switchWorkspaceToHovered();
        else if (mouse.button == Qt.RightButton)
            GlobalStates.overviewOpen = !GlobalStates.overviewOpen;
    }
    onWheel: event => {
        if (event.angleDelta.y < 0)
            WM.switchWorkspaceRelative("next");
        else if (event.angleDelta.y > 0)
            WM.switchWorkspaceRelative("prev");
    }

    // Indications
    Item {
        id: regularWorkspaces
        anchors.fill: parent

        scale: 1 - 0.08 * root.specialBlur
        layer.smooth: true
        layer.enabled: root.specialBlur > 0
        layer.effect: MultiEffect {
            brightness: -0.1 * root.specialBlur
            blurEnabled: true
            blur: root.specialBlur
            blurMax: 32
        }

        /////////////////// Occupied indicators ///////////////////
        StyledRectangle {
            id: occupiedIndicatorsBg
            anchors.fill: parent
            contentLayer: StyledRectangle.ContentLayer.Group
            color: ColorUtils.transparentize(Appearance.m3colors.m3secondaryContainer, 0.4)
            visible: false
        }

        WorkspaceLayout {
            id: occupiedIndicators
            anchors.centerIn: parent

            layer.enabled: true
            visible: false

            Repeater {
                model: wsModel.shownCount
                delegate: Item {
                    id: wsBg
                    required property int index
                    readonly property int wsId: wsModel.getWorkspaceIdAt(index)
                    property bool currentOccupied: wsModel.occupied[index] && wsId != wsModel.fakeWorkspace
                    property bool previousOccupied: index > 0 && wsModel.occupied[index - 1] && (wsId - 1) != wsModel.fakeWorkspace
                    property bool nextOccupied: index < wsModel.shownCount - 1 && wsModel.occupied[index + 1] && (wsId + 1) != wsModel.fakeWorkspace
                    implicitWidth: root.workspaceButtonWidth
                    implicitHeight: root.workspaceButtonWidth

                    // The idea: over-stretch to occupied sides, animate this for a smooth transition.
                    //           masking already prevents weird overlaps
                    Pill {
                        property real undirectionalWidth: root.workspaceButtonWidth * wsBg.currentOccupied
                        property real undirectionalLength: root.workspaceButtonWidth * (1 + 0.5 * wsBg.previousOccupied + 0.5 * wsBg.nextOccupied) * currentOccupied
                        property real undirectionalOffset: (!wsBg.currentOccupied ? 0.5 : -0.5 * wsBg.previousOccupied) * root.workspaceButtonWidth
                        anchors.verticalCenter: root.vertical ? undefined : parent.verticalCenter
                        anchors.horizontalCenter: root.vertical ? parent.horizontalCenter : undefined
                        x: root.vertical ? 0 : undirectionalOffset
                        y: root.vertical ? undirectionalOffset : 0
                        implicitWidth: root.vertical ? undirectionalWidth : undirectionalLength
                        implicitHeight: root.vertical ? undirectionalLength : undirectionalWidth

                        Behavior on undirectionalWidth {
                            animation: Appearance.animation.elementMoveSmall.numberAnimation.createObject(this)
                        }
                        Behavior on undirectionalLength {
                            animation: Appearance.animation.elementMoveSmall.numberAnimation.createObject(this)
                        }
                        Behavior on undirectionalOffset {
                            animation: Appearance.animation.elementMoveSmall.numberAnimation.createObject(this)
                        }
                    }
                }
            }
        }

        MaskMultiEffect {
            id: occupiedIndicatorsMultiEffect
            z: 1
            anchors.centerIn: parent
            implicitWidth: occupiedIndicators.implicitWidth
            implicitHeight: occupiedIndicators.implicitHeight
            source: occupiedIndicatorsBg
            maskSource: occupiedIndicators
        }

        /////////////////// Active indicator ///////////////////
        TrailingIndicator {
            id: activeIndicator
            anchors.fill: parent
            z: 2

            index: root.workspaceIndexInGroup
        }

        /////////////////// Hover ///////////////////
        TrailingIndicator {
            id: interactionIndicator
            z: 3
            index: root.containsMouse ? root.hoverIndex : root.workspaceIndexInGroup
            color: "transparent"
            StateOverlay {
                id: hoverOverlay
                anchors.fill: interactionIndicator.indicatorRectangle
                radius: root.activeWorkspaceSize / 2
                hover: root.containsMouse
                press: root.containsPress
                drag: true // There are too many layers so we need to force this to be a lil more opaque
                contentColor: Appearance.colors.colPrimary
            }
        }

        /////////////////// Numbers ///////////////////
        WorkspaceLayout {
            id: numbersGrid
            z: 4
            layer.enabled: true // For the masking

            Repeater {
                model: wsModel.shownCount
                delegate: NumberWorkspaceItem {}
            }
        }
        Colorizer {
            z: 5
            anchors.fill: numbersGrid
            colorizationColor: Appearance.colors.colOnPrimary
            sourceColor: Appearance.colors.colOnSecondaryContainer

            source: activeIndicator
            maskEnabled: true
            maskSource: numbersGrid

            maskThresholdMin: 0.5
            maskSpreadAtMin: 1
        }

        /////////////////// App icons ///////////////////
        WorkspaceLayout {
            id: appsGrid
            z: 6

            Repeater {
                model: wsModel.shownCount
                delegate: WorkspaceItem {
                    id: wsApp
                    property var biggestWindow: wsModel.biggestWindow[index]
                    property var mainAppIconSource: Quickshell.iconPath(AppSearch.guessIcon(biggestWindow?.class), "image-missing")

                    AppIcon {
                        id: appIcon
                        property real cornerMargin: (!root.superPressAndHeld && root.workspaceOptions.showAppIcons && wsApp.biggestWindow) ? (root.workspaceButtonWidth - root.workspaceIconSize) / 2 : root.workspaceIconMarginShrinked
                        anchors {
                            bottom: parent.bottom
                            right: parent.right
                            bottomMargin: (parent.implicitHeight - root.workspaceButtonWidth) / 2 + cornerMargin
                            rightMargin: (parent.implicitWidth - root.workspaceButtonWidth) / 2 + cornerMargin
                        }

                        animated: !wsApp.biggestWindow // Prevent the "image-missing" icon
                        visible: false // Prevent dupe: the colorizer already copies the icon

                        source: wsApp.mainAppIconSource
                        implicitSize: NumberUtils.roundToEven(root.workspaceIconSize)

                        Behavior on opacity {
                            animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                        }
                        Behavior on cornerMargin {
                            animation: Appearance.animation.elementMoveSmall.numberAnimation.createObject(this)
                        }
                    }

                    Circle {
                        id: iconMask
                        visible: false
                        layer.enabled: true
                        diameter: appIcon.implicitSize
                    }

                    Loader { // Somehow putting this multieffect in a loader prevents it from not showing up
                        id: colorizer
                        anchors.fill: appIcon
                        sourceComponent: Colorizer {
                            implicitWidth: appIcon.implicitWidth
                            implicitHeight: appIcon.implicitHeight
                            colorizationColor: Appearance.m3colors.darkmode ? Appearance.colors.colOnSecondaryContainer : Appearance.colors.colOnPrimary
                            colorization: root.workspaceOptions.monochromeIcons ? 0.8 : 0.5
                            brightness: 0
                            source: appIcon

                            opacity: !root.workspaceOptions.showAppIcons ? 0 : (wsApp.biggestWindow && !root.superPressAndHeld && root.workspaceOptions.showAppIcons) ? 1 : wsApp.biggestWindow ? root.workspaceIconOpacityShrinked : 0
                            visible: opacity > 0
                            scale: ((!root.superPressAndHeld && root.workspaceOptions.showAppIcons) ? root.workspaceIconSize : root.workspaceIconSizeShrinked) / root.workspaceIconSize

                            Behavior on opacity {
                                animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                            }
                            Behavior on scale {
                                animation: Appearance.animation.elementMoveSmall.numberAnimation.createObject(this)
                            }

                            maskEnabled: true
                            maskSource: iconMask
                            maskThresholdMin: 0.5
                            maskSpreadAtMin: 1
                        }
                    }
                }
            }
        }
    }

    FadeLoader {
        anchors.centerIn: parent
        shown: wsModel.specialWorkspaceActive
        scale: 0.8 + 0.2 * root.specialBlur

        opacity: root.specialBlur
        Behavior on opacity {} // Don't animate, as specialBlur is already animated

        sourceComponent: Pill {
            anchors.centerIn: parent
            property real undirectionalWidth: root.activeWorkspaceSize
            property real undirectionalLength: {
                const base = root.workspaceButtonWidth * Math.min(1.35, wsModel.shownCount); // Who tf only configures only 2 workspaces shown anyway?
                if (root.vertical)
                    return base;
                return specialWsText.implicitWidth + undirectionalWidth;
            }
            color: Appearance.colors.colPrimary

            implicitWidth: root.vertical ? undirectionalWidth : undirectionalLength
            implicitHeight: root.vertical ? undirectionalLength : undirectionalWidth

            StyledText {
                id: specialWsText
                anchors.centerIn: parent
                text: (!root.vertical ? wsModel.specialWorkspaceName : "S")
                color: Appearance.colors.colOnPrimary
                font.pixelSize: root.specialTextSize
            }

            Behavior on undirectionalLength {
                animation: Appearance.animation.elementMoveEnter.numberAnimation.createObject(this)
            }
        }
    }

    /////////////////// Super key press handling ///////////////////
    Timer {
        id: superPressAndHeldTimer
        interval: (Config?.options.bar.autoHide.showWhenPressingSuper.delay ?? 100)
        repeat: false
        onTriggered: {
            root.superPressAndHeld = true;
        }
    }
    property bool superNumbersVisible: false
    Timer {
        id: numberRevealTimer
        interval: Math.max(0, root.workspaceOptions.showNumberDelay)
        repeat: false
        onTriggered: root.superNumbersVisible = true
    }
    Connections {
        target: GlobalStates
        function onSuperDownChanged() {
            if (!Config?.options.bar.autoHide.showWhenPressingSuper.enable)
                return;
            if (GlobalStates.superDown)
                superPressAndHeldTimer.restart();
            else {
                superPressAndHeldTimer.stop();
                root.superPressAndHeld = false;
            }
            if (GlobalStates.superDown) numberRevealTimer.restart()
            else {
                numberRevealTimer.stop()
                root.superNumbersVisible = false
            }
        }
        function onSuperReleaseMightTriggerChanged() {
            superPressAndHeldTimer.stop();
        }
    }

    component WorkspaceLayout: Box {
        anchors {
            top: !root.vertical ? parent.top : undefined
            bottom: !root.vertical ? parent.bottom : undefined
            left: root.vertical ? parent.left : undefined
            right: root.vertical ? parent.right : undefined
        }

        rowSpacing: 0
        columnSpacing: 0
        vertical: root.vertical
    }

    component WorkspaceItem: Item {
        required property int index
        readonly property int wsId: wsModel.getWorkspaceIdAt(index)
        implicitWidth: root.vertical ? root.barThickness : root.workspaceButtonWidth
        implicitHeight: root.vertical ? root.workspaceButtonWidth : root.barThickness
    }

    component NumberWorkspaceItem: WorkspaceItem {
        id: wsNum
        property bool hasBiggestWindow: !!wsModel.biggestWindow[index]
        property int wsId: wsModel.getWorkspaceIdAt(index)
        property bool isCurrentWs: wsNum.index === root.workspaceIndexInGroup
        property color contentColor: (wsModel.occupied[wsNum.index] && wsId !== wsModel.fakeWorkspace) ? Appearance.colors.colOnSecondaryContainer : Appearance.colors.colOnLayer1Inactive
        property bool showingNumbers: {
            if (root.superNumbersVisible)
                return true;
            if (GlobalStates.screenLocked)
                return false;
            if (root.workspaceOptions.alwaysShowNumbers && (!root.workspaceOptions.showAppIcons || !wsNum.hasBiggestWindow))
                return true;
            return false;
        }

        // Pop when becoming current
        scale: isCurrentWs ? 1.04 : 1
        Behavior on scale { animation: Appearance.animation.elementMoveSmall.numberAnimation.createObject(wsNum) }

        FadeLoader {
            shown: !wsNum.showingNumbers
            anchors.centerIn: parent
            scale: wsNum.isCurrentWs ? 1.06 : 1
            Behavior on scale { animation: Appearance.animation.elementMoveSmall.numberAnimation.createObject(this) }
            Loader {
                anchors.centerIn: parent
                sourceComponent: (root.workspaceOptions.indicatorStyle ?? "dot") === "icon" ? iconComponent : dotComponent

                Component {
                    id: dotComponent
                    Circle {
                        anchors.centerIn: parent
                        diameter: root.workspaceButtonWidth * (wsNum.isCurrentWs ? 0.26 : 0.18)
                        color: wsNum.contentColor
                        scale: wsNum.isCurrentWs ? 1.12 : 1
                        Behavior on diameter { animation: Appearance.animation.elementMoveSmall.numberAnimation.createObject(this) }
                        Behavior on scale { animation: Appearance.animation.clickBounce.numberAnimation.createObject(this) }
                        // Pulse when occupied just became true
                        SequentialAnimation on opacity {
                            loops: 1
                            running: wsModel.occupied[wsNum.index] && wsNum.isCurrentWs
                            NumberAnimation { from: 0.6; to: 1; duration: 260; easing.type: Easing.OutCubic }
                        }
                    }
                }

                Component {
                    id: iconComponent
                    MaterialSymbol {
                        anchors.centerIn: parent
                        iconSize: root.workspaceButtonWidth * 0.50
                        color: wsNum.contentColor
                        text: {
                            switch (wsNum.wsId) {
                                case 1:  return "code"
                                case 2:  return "public"
                                case 3:  return "music_note"
                                case 4:  return "edit_square"
                                case 5:  return "image"
                                case 6:  return "forum"
                                case 7:  return "browser_updated"
                                case 8:  return "finance_mode"
                                case 9:  return "monitor"
                                case 10: return "analytics"
                                default: return "circle"
                            }
                        }
                    }
                }
            }
        }
        FadeLoader {
            shown: wsNum.showingNumbers
            anchors.centerIn: parent
            scale: wsNum.isCurrentWs ? 1.12 : 1
            Behavior on scale { animation: Appearance.animation.elementMoveSmall.numberAnimation.createObject(this) }
            StyledText {
                anchors.centerIn: parent
                scale: wsNum.isCurrentWs ? 1.08 : 1
                Behavior on scale { animation: Appearance.animation.clickBounce.numberAnimation.createObject(this) }
                font {
                    pixelSize: Appearance.font.pixelSize.small - ((text.length - 1) * (text !== "10") * 2)
                    family: root.workspaceOptions.useNerdFont ? Appearance.font.family.iconNerd : defaultFont
                }
                color: wsNum.contentColor
                text: root.workspaceOptions.numberMap[wsNum.wsId - 1] || wsNum.wsId
            }
        }
    }

    component TrailingIndicator: Item {
        id: trailingIndicator
        anchors.fill: parent
        required property int index
        property alias indicatorRectangle: indicatorRect
        property alias color: indicatorRect.color

        property var indexPair: AnimatedTabIndexPair {
            id: idxPair
            index: trailingIndicator.index
            idx1Duration: 180
            idx2Duration: 420
        }
        readonly property bool isMoving: Math.abs(idxPair.idx1 - idxPair.idx2) > 0.08

        StyledRectangle {
            id: indicatorRect

            anchors {
                verticalCenter: root.vertical ? undefined : parent.verticalCenter
                horizontalCenter: root.vertical ? parent.horizontalCenter : undefined
            }

            property real indicatorPosition: Math.min(idxPair.idx1, idxPair.idx2) * root.workspaceButtonWidth + root.activeWorkspaceMargin
            property real indicatorLength: Math.abs(idxPair.idx1 - idxPair.idx2) * root.workspaceButtonWidth + root.activeWorkspaceSize
            property real indicatorThickness: root.activeWorkspaceSize

            contentLayer: StyledRectangle.ContentLayer.Group
            radius: indicatorThickness / 2
            color: Appearance.colors.colPrimary
            scale: trailingIndicator.isMoving ? (root.vertical ? 0.94 : 1.06) : 1
            Behavior on scale { animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(indicatorRect) }

            x: root.vertical ? null : indicatorPosition
            y: root.vertical ? indicatorPosition : null
            implicitWidth: root.vertical ? indicatorThickness : indicatorLength
            implicitHeight: root.vertical ? indicatorLength : indicatorThickness
            Behavior on implicitWidth { animation: Appearance.animation.elementMove.numberAnimation.createObject(indicatorRect) }
            Behavior on implicitHeight { animation: Appearance.animation.elementMove.numberAnimation.createObject(indicatorRect) }
        }
    }
}
