import QtQuick
import QtQuick.Layouts
import qs
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import qs.modules.common.widgets.widgetCanvas
import qs.modules.ii.background.widgets

AbstractBackgroundWidget {
    id: root
    configEntryName: "networkInfo"
    hoverEnabled: true

    property bool showDetails: root.configEntry.showDetails ?? true

    implicitWidth: container.implicitWidth + 24
    implicitHeight: container.implicitHeight + 24

    Rectangle {
        id: bg
        anchors.fill: parent
        radius: Appearance.rounding.large
        color: Appearance.colors.colLayer1
        opacity: 0.92
        border.width: 1
        border.color: Appearance.colors.colLayer0Border
        StyledRectangularShadow { target: bg; z: -1 }
    }

    ColumnLayout {
        id: container
        anchors.centerIn: parent
        spacing: 10

        RowLayout {
            spacing: 10
            MaterialShapeWrappedMaterialSymbol {
                shape: MaterialShape.Shape.Cookie9Sided
                color: Network.ethernet ? Appearance.colors.colSecondaryContainer : Appearance.colors.colPrimaryContainer
                text: Network.materialSymbol
                iconSize: 20
                fill: 1
                padding: 8
            }
            ColumnLayout {
                spacing: 2
                StyledText {
                    text: Network.networkName.length > 0 ? Network.networkName : Translation.tr("Not connected")
                    font.pixelSize: Appearance.font.pixelSize.large
                    font.weight: Font.Medium
                    color: Appearance.colors.colOnLayer1
                    elide: Text.ElideRight
                    Layout.maximumWidth: 220
                }
                StyledText {
                    text: Network.ethernet ? Translation.tr("Ethernet") : Network.wifi ? Translation.tr("Wi-Fi") : Network.wifiStatus
                    font.pixelSize: Appearance.font.pixelSize.small
                    color: Appearance.colors.colSubtext
                }
            }
            Item { Layout.fillWidth: true }
            Rectangle {
                visible: Network.wifi && !Network.ethernet
                implicitWidth: 36; implicitHeight: 22; radius: 11
                color: Appearance.colors.colSecondaryContainer
                RowLayout {
                    anchors.centerIn: parent; spacing: 2
                    MaterialSymbol { text: "signal_wifi_4_bar"; iconSize: 14; color: Appearance.colors.colOnSecondaryContainer }
                    StyledText { text: Network.networkStrength + "%"; font.pixelSize: Appearance.font.pixelSize.smaller; color: Appearance.colors.colOnSecondaryContainer }
                }
            }
        }

        // Details
        ColumnLayout {
            visible: root.showDetails
            spacing: 6
            Layout.fillWidth: true

            RowLayout {
                visible: Network.ipAddress.length > 0
                spacing: 6
                MaterialSymbol { text: "language"; iconSize: 14; color: Appearance.colors.colSubtext }
                StyledText { text: Network.ipAddress; font.pixelSize: Appearance.font.pixelSize.small; color: Appearance.colors.colOnLayer1; Layout.fillWidth: true; elide: Text.ElideRight }
                MaterialSymbol { visible: Network.publicIpAddress.length>0; text: "public"; iconSize: 12; color: Appearance.colors.colSubtext }
                StyledText { visible: Network.publicIpAddress.length>0; text: Network.publicIpAddress; font.pixelSize: Appearance.font.pixelSize.smaller; color: Appearance.colors.colSubtext; elide: Text.ElideRight }
            }
            RowLayout {
                visible: Network.gateway.length > 0
                spacing: 6
                MaterialSymbol { text: "router"; iconSize: 14; color: Appearance.colors.colSubtext }
                StyledText { text: Translation.tr("Gateway") + ": " + Network.gateway; font.pixelSize: Appearance.font.pixelSize.small; color: Appearance.colors.colOnLayer1; Layout.fillWidth: true; elide: Text.ElideRight }
            }
            RowLayout {
                visible: Network.networkInterface.length > 0
                spacing: 6
                MaterialSymbol { text: "lan"; iconSize: 14; color: Appearance.colors.colSubtext }
                StyledText { text: Network.networkInterface + (Network.macAddress.length>0 ? " · " + Network.macAddress : ""); font.pixelSize: Appearance.font.pixelSize.small; color: Appearance.colors.colOnLayer1; Layout.fillWidth: true; elide: Text.ElideRight }
            }

            Rectangle { Layout.fillWidth: true; height: 1; color: Appearance.colors.colLayer0Border; opacity: 0.5 }

            RowLayout {
                spacing: 6
                RippleButtonWithIcon {
                    materialIcon: "refresh"
                    mainText: Translation.tr("Rescan")
                    onClicked: Network.rescanWifi()
                    colBackground: Appearance.colors.colSecondaryContainer
                }
                RippleButtonWithIcon {
                    materialIcon: Network.wifiEnabled ? "wifi" : "wifi_off"
                    mainText: Network.wifiEnabled ? Translation.tr("Disable Wi-Fi") : Translation.tr("Enable Wi-Fi")
                    onClicked: Network.toggleWifi()
                    colBackground: Appearance.colors.colTertiaryContainer
                }
                RippleButtonWithIcon {
                    visible: root.showDetails
                    materialIcon: "visibility_off"
                    mainText: Translation.tr("Hide")
                    onClicked: {
                        root.showDetails = false
                        root.configEntry.showDetails = false
                    }
                    colBackground: Appearance.colors.colLayer2
                }
            }
            RowLayout {
                visible: !root.showDetails
                RippleButtonWithIcon {
                    materialIcon: "visibility"
                    mainText: Translation.tr("Show details")
                    onClicked: {
                        root.showDetails = true
                        root.configEntry.showDetails = true
                    }
                    colBackground: Appearance.colors.colLayer2
                }
            }
        }
    }

    // Toggle details via corner handle (like resources)
    Rectangle {
        width: 16; height: 16; radius: 6
        color: Appearance.colors.colOnPrimaryContainer
        anchors { right: parent.right; bottom: parent.bottom; margins: -6 }
        opacity: root.containsMouse ? 0.7 : 0
        visible: opacity > 0 && !Config.options.background.widgetsLocked
        Behavior on opacity { NumberAnimation { duration: 150 } }
        MaterialSymbol { anchors.centerIn: parent; text: "tune"; iconSize: 11; color: Appearance.colors.colPrimaryContainer }
        MouseArea {
            anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
            onClicked: {
                root.showDetails = !root.showDetails
                root.configEntry.showDetails = root.showDetails
            }
        }
    }
}
