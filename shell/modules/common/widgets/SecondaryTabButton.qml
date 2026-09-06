import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects

TabButton {
    id: root
    property string buttonText
    property string buttonIcon
    property int rippleDuration: 1200
    property int tabContentWidth: buttonBackground.width - buttonBackground.radius*2

    // Breathing room around the (now correctly measured, see contentItem)
    // icon+label row so tabs don't sit label-to-label.
    leftPadding: 14
    rightPadding: 14

    property color colBackground: ColorUtils.transparentize(Appearance.colors.colSurfaceContainer)
    property color colBackgroundHover: ColorUtils.transparentize(Appearance.colors.colOnSurface, root.checked ? 1 : 0.95)
    property color colRipple: ColorUtils.transparentize(Appearance.colors.colOnSurface, 0.95)

    PointingHandInteraction {}

    component RippleAnim: NumberAnimation {
        duration: rippleDuration
        easing.type: Appearance.animation.elementMoveEnter.type
        easing.bezierCurve: Appearance.animationCurves.standardDecel
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onPressed: (event) => {
            root.click() // Because the MouseArea already consumed the event
            const {x,y} = event
            const stateY = buttonBackground.y;
            rippleAnim.x = x;
            rippleAnim.y = y - stateY;

            const dist = (ox,oy) => ox*ox + oy*oy
            const stateEndY = stateY + buttonBackground.height
            rippleAnim.radius = Math.sqrt(Math.max(dist(0, stateY), dist(0, stateEndY), dist(width, stateY), dist(width, stateEndY)))

            rippleFadeAnim.complete();
            rippleAnim.restart();
        }
        onReleased: (event) => {
            rippleFadeAnim.restart();
        }
    }

    RippleAnim {
        id: rippleFadeAnim
        duration: rippleDuration * 2
        target: ripple
        property: "opacity"
        to: 0
    }

    SequentialAnimation {
        id: rippleAnim

        property real x
        property real y
        property real radius

        PropertyAction {
            target: ripple
            property: "x"
            value: rippleAnim.x
        }
        PropertyAction {
            target: ripple
            property: "y"
            value: rippleAnim.y
        }
        PropertyAction {
            target: ripple
            property: "opacity"
            value: 1
        }
        ParallelAnimation {
            RippleAnim {
                target: ripple
                properties: "implicitWidth,implicitHeight"
                from: 0
                to: rippleAnim.radius * 2
            }
        }
    }

    background: Rectangle {
        id: buttonBackground
        anchors {
            fill: parent
            margins: 3
        }
        radius: Appearance?.rounding.normal
        implicitHeight: 42
        color: (root.hovered ? root.colBackgroundHover : root.colBackground)
        // See RippleButton.qml for why this is Rectangle.clip (Qt 6.7+,
        // clip-shape-aware) instead of an OpacityMask offscreen pass - same
        // "keep the ripple inside my own rounded corners" job.
        clip: true

        Behavior on color {
            animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
        }

        Item {
            id: ripple
            width: ripple.implicitWidth
            height: ripple.implicitHeight
            opacity: 0

            property real implicitWidth: 0
            property real implicitHeight: 0
            visible: width > 0 && height > 0

            Behavior on opacity {
                animation: Appearance?.animation.elementMoveFast.colorAnimation.createObject(this)
            }

            RadialGradient {
                anchors.fill: parent
                gradient: Gradient {
                    GradientStop { position: 0.0; color: root.colRipple }
                    GradientStop { position: 0.3; color: root.colRipple }
                    GradientStop { position: 0.5 ; color: Qt.rgba(root.colRipple.r, root.colRipple.g, root.colRipple.b, 0) }
                }
            }

            transform: Translate {
                x: -ripple.width / 2
                y: -ripple.height / 2
            }
        }
    }

    contentItem: Item {
        anchors.centerIn: buttonBackground
        // The icon+label row is centered inside this Item, which means the Item
        // itself has to report the row's size - with no implicit size of its
        // own it reported 0, so TabBar handed every tab a width of just its
        // padding and the labels of neighbouring tabs drew straight on top of
        // each other (visible wherever the bar isn't stretched to fill, e.g.
        // the Super+Tab switcher's Workspaces/Windows tabs).
        implicitWidth: tabContentRow.implicitWidth
        implicitHeight: tabContentRow.implicitHeight
        RowLayout {
            id: tabContentRow
            anchors.centerIn: parent
            spacing: 0
            
            Loader {
                id: iconLoader
                active: buttonIcon?.length > 0
                sourceComponent: buttonIcon?.length > 0 ? materialSymbolComponent : null
                Layout.rightMargin: 5
            }

            Component {
                id: materialSymbolComponent
                MaterialSymbol {
                    verticalAlignment: Text.AlignVCenter
                    text: buttonIcon
                    iconSize: Appearance.font.pixelSize.huge
                    fill: root.checked ? 1 : 0
                    color: root.checked ? Appearance.colors.colPrimary : Appearance.colors.colOnLayer1
                    Behavior on color {
                        animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
                    }
                }
            }
            StyledText {
                id: buttonTextWidget
                verticalAlignment: Text.AlignVCenter
                font.pixelSize: Appearance.font.pixelSize.small
                color: root.checked ? Appearance.colors.colPrimary : Appearance.colors.colOnLayer1
                text: buttonText
                Behavior on color {
                    animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
                }
            }
        }
    }
}
