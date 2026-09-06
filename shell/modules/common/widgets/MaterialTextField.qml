import qs.modules.common
import QtQuick
import QtQuick.Controls.Material
import QtQuick.Controls

/**
 * Material 3 styled TextField (filled style)
 * https://m3.material.io/components/text-fields/overview
 * Note: We don't use NativeRendering because it makes the small placeholder text look weird
 */
TextField {
    id: root
    Material.theme: Material.System
    Material.accent: Appearance.m3colors.m3primary
    Material.primary: Appearance.m3colors.m3primary
    Material.background: Appearance.m3colors.m3surface
    Material.foreground: Appearance.m3colors.m3onSurface
    Material.containerStyle: Material.Outlined
    renderType: Text.QtRendering

    selectedTextColor: Appearance.m3colors.m3onSecondaryContainer
    selectionColor: Appearance.colors.colSecondaryContainer
    placeholderTextColor: Appearance.m3colors.m3outline
    clip: true

    font {
        family: Appearance.font.family.main
        pixelSize: Appearance?.font.pixelSize.small ?? 15
        hintingPreference: Font.PreferFullHinting
        variableAxes: Appearance.font.variableAxes.main
    }
    wrapMode: TextEdit.Wrap

    // Qt's Material outline can disappear against our custom Layer colours.
    // Draw the resting outline ourselves so settings fields always read as
    // editable controls, not as unlabelled text on a card.
    background: Rectangle {
        implicitHeight: 44
        radius: Appearance.rounding.small
        color: root.activeFocus ? Appearance.colors.colLayer2 : Appearance.colors.colLayer1
        border.width: root.activeFocus ? 2 : 1
        border.color: root.activeFocus ? Appearance.colors.colPrimary : Appearance.colors.colOutlineVariant

        Behavior on color { ColorAnimation { duration: Appearance.animation.elementMoveFast.duration } }
        Behavior on border.color { ColorAnimation { duration: Appearance.animation.elementMoveFast.duration } }
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.NoButton
        hoverEnabled: true
        cursorShape: Qt.IBeamCursor
    }
}
