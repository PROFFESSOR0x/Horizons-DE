pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import qs.modules.common.models

Item {
    id: root
    implicitWidth: 500
    // Fixed height when launcher to avoid per-keystroke shaking via outer window animation
    implicitHeight: column.implicitHeight
    property var panelWindow
    // Stable column height: searchRow + optional results (fixed 320)
    property bool hasQuery: LauncherSearch.query !== ""

    Connections {
        target: GlobalStates
        function onOverviewOpenChanged() {
            if (GlobalStates.overviewOpen) {
                Qt.callLater(() => searchInput.forceActiveFocus())
            } else {
                LauncherSearch.query = ""
                searchInput.text = ""
            }
        }
    }

    ColumnLayout {
        id: column
        anchors.fill: parent
        spacing: 0

        // Search bar - morphs from island
        RowLayout {
            id: searchRow
            Layout.fillWidth: true
            Layout.leftMargin: 10
            Layout.rightMargin: 6
            Layout.topMargin: 6
            Layout.bottomMargin: 6
            spacing: 8

            MaterialSymbol {
                text: "search"
                iconSize: Appearance.font.pixelSize.large
                color: Appearance.colors.colOnLayer1
            }
            ToolbarTextField {
                id: searchInput
                Layout.fillWidth: true
                focus: GlobalStates.overviewOpen
                font.pixelSize: Appearance.font.pixelSize.small
                placeholderText: Translation.tr("Search, calculate or run")
                onTextChanged: LauncherSearch.query = text
                onAccepted: {
                    if (resultModel.values.length > 0) {
                        let e = resultModel.values[0]
                        if (e && e.execute) { e.execute(); GlobalStates.overviewOpen = false }
                    }
                }
                Keys.onPressed: event => {
                    if (event.key === Qt.Key_Escape) { GlobalStates.overviewOpen = false; event.accepted = true }
                    else if (event.key === Qt.Key_Down) { resultsView.forceActiveFocus(); if (resultsView.count>0) resultsView.currentIndex = 0; event.accepted = true }
                }
            }
            // Sync back from service
            Connections {
                target: LauncherSearch
                function onQueryChanged() { if (searchInput.text !== LauncherSearch.query) searchInput.text = LauncherSearch.query }
            }

            RippleButton {
                implicitWidth: 32
                implicitHeight: 32
                buttonRadius: Appearance.rounding.full
                colBackground: hovered ? Appearance.colors.colLayer1Hover : "transparent"
                onClicked: GlobalStates.overviewOpen = false
                contentItem: MaterialSymbol { anchors.centerIn: parent; text: "close"; iconSize: Appearance.font.pixelSize.normal; color: Appearance.colors.colOnLayer1 }
            }
        }

        Rectangle {
            visible: LauncherSearch.query !== ""
            Layout.fillWidth: true
            height: 1
            color: Appearance.colors.colOutlineVariant
            opacity: 0.5
        }

        ListView {
            id: resultsView
            visible: LauncherSearch.query !== ""
            Layout.fillWidth: true
            Layout.preferredHeight: visible ? 320 : 0
            implicitHeight: visible ? 320 : 0
            clip: true
            spacing: 2
            topMargin: 6
            bottomMargin: 6
            interactive: true
            cacheBuffer: 200
            model: ScriptModel { id: resultModel; objectProp: "key" }
            // Debounce rapid typing to avoid shaking
            Timer { id: updateTimer; interval: 60; onTriggered: resultModel.values = (LauncherSearch.results ?? []).slice(0, 10) }
            Connections {
                target: LauncherSearch
                function onResultsChanged() { updateTimer.restart() }
            }
            delegate: RippleButton {
                id: delButton
                required property var modelData
                property var entry: modelData
                width: ListView.view.width - 8
                x: 4
                implicitHeight: row.implicitHeight + 12
                buttonRadius: Appearance.rounding.normal
                colBackground: hovered || focus ? Appearance.colors.colPrimaryContainer : ColorUtils.transparentize(Appearance.colors.colPrimaryContainer, 1)
                colBackgroundHover: Appearance.colors.colPrimaryContainer
                onClicked: { entry.execute(); GlobalStates.overviewOpen = false }

                RowLayout {
                    id: row
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    spacing: 10
                    Loader {
                        active: true
                        sourceComponent: {
                            if (delButton.entry.iconType === LauncherSearchResult.IconType.System) return sysIcon
                            if (delButton.entry.iconType === LauncherSearchResult.IconType.Material) return matIcon
                            if (delButton.entry.iconType === LauncherSearchResult.IconType.Text) return txtIcon
                            return matIcon
                        }
                    }
                    Component { id: sysIcon; IconImage { source: Quickshell.iconPath(delButton.entry.iconName, "image-missing"); width: 28; height: 28 } }
                    Component { id: matIcon; MaterialSymbol { text: delButton.entry.iconName || "apps"; iconSize: 22; color: delButton.hovered || delButton.focus ? Appearance.colors.colOnPrimaryContainer : Appearance.colors.colOnLayer1 } }
                    Component { id: txtIcon; StyledText { text: delButton.entry.iconName || ""; font.pixelSize: Appearance.font.pixelSize.large; color: Appearance.colors.colOnLayer1 } }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0
                        StyledText {
                            visible: delButton.entry.type && delButton.entry.type != Translation.tr("App")
                            text: delButton.entry.type
                            font.pixelSize: Appearance.font.pixelSize.smallest
                            color: Appearance.colors.colSubtext
                        }
                        StyledText {
                            Layout.fillWidth: true
                            text: delButton.entry.name
                            font.pixelSize: Appearance.font.pixelSize.small
                            color: delButton.hovered || delButton.focus ? Appearance.colors.colOnPrimaryContainer : Appearance.colors.colOnLayer1
                            elide: Text.ElideRight
                        }
                    }
                    StyledText {
                        visible: delButton.hovered || delButton.focus
                        text: delButton.entry.verb || "Open"
                        font.pixelSize: Appearance.font.pixelSize.smallest
                        color: Appearance.colors.colOnPrimaryContainer
                    }
                }
            }
            Keys.onPressed: event => {
                if (event.key === Qt.Key_Escape) { GlobalStates.overviewOpen = false; event.accepted = true }
                else if (event.key === Qt.Key_Up && currentIndex === 0) { searchInput.forceActiveFocus(); event.accepted = true }
            }
        }
    }
}
