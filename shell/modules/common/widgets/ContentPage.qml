import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import qs.modules.common
import qs.modules.common.widgets

StyledFlickable {
    id: root
    // A source view can contribute groups to a topic without nested scrolling.
    property bool embedded: false
    property string settingsRoute: ""
    property var settingsRouteAliases: []
    interactive: !embedded
    ScrollBar.vertical.policy: embedded ? ScrollBar.AlwaysOff : ScrollBar.AsNeeded
    function settingsShow(routes) {
        if (settingsRoute === "") return true
        const allowedRoutes = routes.split("|")
        const activeRoutes = [settingsRoute].concat(settingsRouteAliases ?? [])
        return activeRoutes.some(route => allowedRoutes.includes(route))
    }
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
    // An embedded page is instantiated by a Loader, which never resizes its
    // item: without this the page keeps its natural implicit width even when
    // the loader (and the settings window) is narrower, so every row bleeds
    // past the visible edge and gets clipped. Track the loader width instead.
    // Imperative (not a width binding) so non-embedded pages — whose geometry
    // is managed by layouts — are completely untouched.
    onParentChanged: {
        if (root.embedded && root.parent)
            root.width = Qt.binding(() => root.parent.width)
    }

    ColumnLayout {
        id: contentColumn
        width: root.embedded ? root.width : root.forceWidth
            ? Math.min(root.baseWidth, Math.max(0, root.width - root.sidePadding))
            : Math.max(root.baseWidth, implicitWidth)
        anchors {
            top: parent.top
            horizontalCenter: parent.horizontalCenter
            margins: root.embedded ? 0 : 20
        }
        spacing: 30
    }

}
