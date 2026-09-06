import qs.modules.common
import qs.modules.common.functions
import QtQuick
import QtQuick.Controls.Material
import QtQuick.Controls

/**
 * Material 3 styled TextArea (filled style)
 * https://m3.material.io/components/text-fields/overview
 * Note: We don't use NativeRendering because it makes the small placeholder text look weird
 */
TextArea {
    id: root
    Material.theme: Material.System
    Material.accent: Appearance.m3colors.m3primary
    Material.primary: Appearance.m3colors.m3primary
    Material.background: Appearance.m3colors.m3surface
    Material.foreground: Appearance.m3colors.m3onSurface
    Material.containerStyle: Material.Filled
    renderType: Text.QtRendering

    selectedTextColor: Appearance.m3colors.m3onSecondaryContainer
    selectionColor: Appearance.colors.colSecondaryContainer
    placeholderTextColor: Appearance.m3colors.m3outline

    background: Rectangle {
        implicitHeight: 56
        color: root.focus ? Appearance.colors.colLayer2 : Appearance.colors.colLayer1
        radius: Appearance.rounding.small
        border.width: root.focus ? 2 : 1
        border.color: root.focus ? Appearance.m3colors.m3primary : Appearance.m3colors.m3outlineVariant

        Behavior on color { ColorAnimation { duration: Appearance.animation.elementMoveFast.duration } }
        Behavior on border.color { ColorAnimation { duration: Appearance.animation.elementMoveFast.duration } }
    }

    font {
        family: Appearance.font.family.main
        pixelSize: Appearance?.font.pixelSize.small ?? 15
        hintingPreference: Font.PreferFullHinting
        variableAxes: Appearance.font.variableAxes.main
    }
    wrapMode: TextEdit.Wrap
}
