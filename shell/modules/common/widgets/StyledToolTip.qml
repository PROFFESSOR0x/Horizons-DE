import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ToolTip {
    id: root
    property bool extraVisibleCondition: true
    property bool alternativeVisibleCondition: false

    // A tooltip must never treat an item without a `hovered` property as
    // hovered. Most bar widgets are MouseAreas and expose `containsMouse`
    // instead; the old fallback made their tooltips visible all the time.
    readonly property bool parentIsHovered: parent?.hovered === true || parent?.containsMouse === true
    readonly property bool internalVisibleCondition: (extraVisibleCondition && parentIsHovered) || alternativeVisibleCondition
    verticalPadding: 5
    horizontalPadding: 10
    background: null
    font {
        family: Appearance.font.family.main
        variableAxes: Appearance.font.variableAxes.main
        pixelSize: Appearance?.font.pixelSize.smaller ?? 14
        hintingPreference: Font.PreferNoHinting // Prevent shaky text
    }

    delay: 0
    visible: internalVisibleCondition
    
    contentItem: StyledToolTipContent {
        id: contentItem
        font: root.font
        text: root.text
        shown: root.internalVisibleCondition
        horizontalPadding: root.horizontalPadding
        verticalPadding: root.verticalPadding
    }
}
