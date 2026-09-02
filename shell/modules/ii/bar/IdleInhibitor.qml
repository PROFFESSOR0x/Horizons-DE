pragma ComponentBehavior: Bound
import qs.modules.common
import qs.modules.common.widgets
import qs.services
import QtQuick
import QtQuick.Layouts

// Toggles the real Wayland idle-inhibitor (qs.services.Idle), the same
// backing used by the sidebar's "Keep awake" quick toggle. Clicking this
// actually prevents/allows the screen from locking or sleeping - it's not
// a UI-only fake toggle.
MouseArea {
    id: root
    property bool vertical: Config.options.bar.vertical
    property bool isMaterial: Config.options.bar.cornerStyle === 3

    readonly property bool active: Idle.inhibit

    implicitWidth: vertical ? Appearance.sizes.verticalBarWidth : (contentLoader.item?.implicitWidth ?? 0)
    implicitHeight: vertical ? (contentLoader.item?.implicitHeight ?? 0) : Appearance.sizes.barHeight

    cursorShape: Qt.PointingHandCursor
    onClicked: Idle.toggleInhibit()

    StyledToolTip {
        text: root.active ? Translation.tr("Keep awake: on") : Translation.tr("Keep awake: off")
    }

    Loader {
        id: contentLoader
        anchors.centerIn: parent
        sourceComponent: root.vertical ? colContent : rowContent
    }

    Component {
        id: rowContent
        RowLayout {
            spacing: 4
            MaterialSymbol {
                Layout.alignment: Qt.AlignVCenter
                text: "coffee"
                fill: root.active ? 1 : 0
                iconSize: Appearance.font.pixelSize.normal
                color: root.active
                    ? (root.isMaterial ? Appearance.colors.colPrimary : Appearance.colors.colPrimary)
                    : Appearance.colors.colOnLayer1
            }
        }
    }

    Component {
        id: colContent
        ColumnLayout {
            spacing: 4
            MaterialSymbol {
                Layout.alignment: Qt.AlignHCenter
                text: "coffee"
                fill: root.active ? 1 : 0
                iconSize: Appearance.font.pixelSize.normal
                color: root.active
                    ? (root.isMaterial ? Appearance.colors.colPrimary : Appearance.colors.colPrimary)
                    : Appearance.colors.colOnLayer1
            }
        }
    }
}
