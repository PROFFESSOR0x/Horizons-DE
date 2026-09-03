import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets

StyledFlickable {
    id: root
    // The settings window itself (Settings.qml) was widened to make room for
    // wider content; this default is the corresponding "sensible increase"
    // for the per-page content column so pages actually use that space
    // instead of leaving it empty on the sides. It's a target/max, not a
    // fixed value: the Math.min below still clamps it to whatever width is
    // actually available (narrower windows, the "minimal" style, etc.), so
    // this never causes horizontal overflow.
    property real baseWidth: 900
    property bool forceWidth: false
    // Minimum breathing room kept on each side even when baseWidth is
    // clamped down to the available width.
    property real sidePadding: 24
    property real bottomContentPadding: Config.options.settings.style === "minimal" ? 40 : 90

    default property alias data: contentColumn.data

    clip: true
    contentHeight: contentColumn.implicitHeight + root.bottomContentPadding // Add some padding at the bottom
    implicitWidth: contentColumn.implicitWidth

    ColumnLayout {
        id: contentColumn
        width: root.forceWidth
            ? Math.min(root.baseWidth, Math.max(0, root.width - root.sidePadding))
            : Math.max(root.baseWidth, implicitWidth)
        anchors {
            top: parent.top
            horizontalCenter: parent.horizontalCenter
            margins: 20
        }
        spacing: 30
    }

}
