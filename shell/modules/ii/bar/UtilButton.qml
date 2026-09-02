import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.models
import qs.modules.common.functions

Item {
    id: root
    signal clicked(event: var)
    property alias iconText: symbol.text
    property bool isActive: false
    property bool forceHovered: false

    implicitWidth: vertical ? 26 : (hovered ? 54 : 26)
    implicitHeight: vertical ? (hovered ? 54 : 26) : 26

    property bool hovered: mouseArea.containsMouse || forceHovered
    property bool pressed: mouseArea.pressed
    // Click bounce scale
    scale: pressed ? 0.88 : hovered ? 1.08 : 1.0
    Behavior on scale { animation: Appearance.animation.clickBounce.numberAnimation.createObject(root) }

    Behavior on implicitWidth {
        NumberAnimation {
            duration: Appearance.animation.elementMoveFast.duration
            easing.type: Appearance.animation.elementMoveFast.type
            easing.bezierCurve: Appearance.animation.elementMoveFast.bezierCurve
        }
    }

    Behavior on implicitHeight {
        NumberAnimation {
            duration: Appearance.animation.elementMoveFast.duration
            easing.type: Appearance.animation.elementMoveFast.type
            easing.bezierCurve: Appearance.animation.elementMoveFast.bezierCurve
        }
    }

    Rectangle {
        id: bg
        anchors.fill: parent
        radius: Appearance.rounding.full
        color: root.hovered ? Appearance.colors.colPrimary : ColorUtils.transparentize(Appearance.colors.colLayer0, 0.8)
        // Lift + shadow illusion
        y: root.hovered ? -0.8 : 0
        Behavior on y { animation: Appearance.animation.elementMoveSmall.numberAnimation.createObject(bg) }

        Behavior on color {
            ColorAnimation { duration: Appearance.animation.elementMoveFast.duration }
        }
        Behavior on opacity {
            NumberAnimation { duration: Appearance.animation.elementMoveFast.duration }
        }

        MaterialSymbol {
            id: symbol
            anchors.centerIn: parent
            iconSize: root.hovered ? Appearance.font.pixelSize.large + 1 : Appearance.font.pixelSize.large
            color: root.hovered ? Appearance.colors.colOnPrimary : Appearance.colors.colPrimary
            scale: root.pressed ? 0.9 : 1
            Behavior on iconSize { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
            Behavior on scale { animation: Appearance.animation.clickBounce.numberAnimation.createObject(symbol) }

            Behavior on color {
                ColorAnimation { duration: Appearance.animation.elementMoveFast.duration }
            }
        }

        // Ripple click feedback
        Rectangle {
            id: ripple
            anchors.centerIn: parent
            width: parent.width
            height: parent.height
            radius: parent.radius
            color: Appearance.colors.colOnPrimary
            opacity: 0
            scale: 0.4
        }
        SequentialAnimation {
            id: rippleAnim
            NumberAnimation { target: ripple; property: "opacity"; from: 0.22; to: 0; duration: 420; easing.type: Easing.OutCubic }
            NumberAnimation { target: ripple; property: "scale"; from: 0.4; to: 1.4; duration: 420; easing.type: Easing.OutCubic }
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        onClicked: (e) => { rippleAnim.restart(); root.clicked(e) }
    }
}
