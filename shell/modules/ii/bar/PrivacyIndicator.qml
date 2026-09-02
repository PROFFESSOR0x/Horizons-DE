import qs.modules.common
import qs.modules.common.widgets
import qs.services
import QtQuick
import QtQuick.Layouts

// Shows a small indicator when the mic or screen is actively being captured,
// backed by the existing Privacy service (Pipewire link-group inspection).
// Hidden entirely when nothing is active, so it stays out of the way.
Item {
    id: root
    property bool vertical: Config.options.bar.vertical
    property bool isMaterial: Config.options.bar.cornerStyle === 3

    readonly property bool micActive: Privacy.micActive
    readonly property bool screenSharing: Privacy.screenSharing
    readonly property bool anyActive: micActive || screenSharing

    visible: anyActive
    implicitWidth: visible ? (vertical ? Appearance.sizes.verticalBarWidth : (contentLoader.item?.implicitWidth ?? 0)) : 0
    implicitHeight: visible ? (vertical ? (contentLoader.item?.implicitHeight ?? 0) : Appearance.sizes.barHeight) : 0

    StyledToolTip {
        text: root.micActive && root.screenSharing
            ? Translation.tr("Mic and screen are being captured")
            : root.micActive
                ? Translation.tr("Mic is being captured")
                : Translation.tr("Screen is being captured")
    }

    Loader {
        id: contentLoader
        active: root.anyActive
        anchors.centerIn: parent
        sourceComponent: root.vertical ? colContent : rowContent
    }

    Component {
        id: rowContent
        RowLayout {
            spacing: 2
            MaterialSymbol {
                visible: root.micActive
                Layout.alignment: Qt.AlignVCenter
                text: "mic"
                fill: 1
                iconSize: Appearance.font.pixelSize.normal
                color: Appearance.m3colors.m3error
            }
            MaterialSymbol {
                visible: root.screenSharing
                Layout.alignment: Qt.AlignVCenter
                text: "screen_share"
                fill: 1
                iconSize: Appearance.font.pixelSize.normal
                color: Appearance.m3colors.m3error
            }
        }
    }

    Component {
        id: colContent
        ColumnLayout {
            spacing: 2
            MaterialSymbol {
                visible: root.micActive
                Layout.alignment: Qt.AlignHCenter
                text: "mic"
                fill: 1
                iconSize: Appearance.font.pixelSize.normal
                color: Appearance.m3colors.m3error
            }
            MaterialSymbol {
                visible: root.screenSharing
                Layout.alignment: Qt.AlignHCenter
                text: "screen_share"
                fill: 1
                iconSize: Appearance.font.pixelSize.normal
                color: Appearance.m3colors.m3error
            }
        }
    }
}
