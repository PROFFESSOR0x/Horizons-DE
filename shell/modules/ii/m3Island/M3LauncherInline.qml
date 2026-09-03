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
    // The outer island animates this height, so it can follow the actual
    // number of matches without a fixed empty results area.
    implicitHeight: column.implicitHeight
    // This follows the *animated* island height rather than the launcher's
    // final implicit height. Together with clipping, results are revealed only
    // as the black launcher surface has physically expanded underneath them.
    height: parent?.height ?? 0
    clip: true
    property var panelWindow
    property bool hasQuery: LauncherSearch.query !== ""
    readonly property int maximumResults: Math.max(1, Config.options.m3Island.launcherMaxResults)
    readonly property real resultsRevealProgress: Math.max(0, Math.min(1, (height - 52) / 88))

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
                onTextChanged: {
                    LauncherSearch.query = text
                    resultsView.currentIndex = -1
                }
                onAccepted: {
                    resultsView.executeCurrent()
                }
                Keys.onPressed: event => {
                    if (event.key === Qt.Key_Escape) { GlobalStates.overviewOpen = false; event.accepted = true }
                    else if (event.key === Qt.Key_Down) {
                        resultsView.selectResult(0)
                        resultsView.forceActiveFocus()
                        event.accepted = true
                    }
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
            opacity: 0.5 * root.resultsRevealProgress
        }

        ListView {
            id: resultsView
            visible: LauncherSearch.query !== ""
            opacity: root.resultsRevealProgress
            enabled: root.resultsRevealProgress >= 0.98
            Layout.fillWidth: true
            // Use each delegate's measured content height, capped by the
            // setting. More matches remain keyboard/scroll accessible.
            readonly property real maximumVisibleHeight: root.maximumResults * 56
            readonly property real desiredHeight: count > 0
                ? Math.min(contentHeight + topMargin + bottomMargin, maximumVisibleHeight)
                : 0
            Layout.preferredHeight: visible ? desiredHeight : 0
            implicitHeight: visible ? desiredHeight : 0
            clip: true
            spacing: 2
            topMargin: 6
            bottomMargin: 6
            interactive: true
            cacheBuffer: 200
            model: ScriptModel { id: resultModel; objectProp: "key" }

            function selectResult(index) {
                if (count <= 0) return
                currentIndex = Math.max(0, Math.min(index, count - 1))
                positionViewAtIndex(currentIndex, ListView.Contain)
            }

            function executeCurrent() {
                if (currentIndex < 0 || currentIndex >= resultModel.values.length) return
                const entry = resultModel.values[currentIndex]
                if (entry?.execute) {
                    entry.execute()
                    GlobalStates.overviewOpen = false
                }
            }

            // Debounce rapid typing to avoid shaking
            Timer {
                id: updateTimer
                interval: 60
                onTriggered: {
                    resultModel.values = (LauncherSearch.results ?? []).slice(0, 10)
                    Qt.callLater(() => resultsView.selectResult(0))
                }
            }
            Connections {
                target: LauncherSearch
                function onResultsChanged() { updateTimer.restart() }
            }
            delegate: RippleButton {
                id: delButton
                required property var modelData
                required property int index
                property var entry: modelData
                readonly property bool selected: ListView.isCurrentItem
                width: ListView.view.width - 8
                x: 4
                implicitHeight: row.implicitHeight + 12
                buttonRadius: Appearance.rounding.normal
                colBackground: hovered || selected ? Appearance.colors.colPrimaryContainer : ColorUtils.transparentize(Appearance.colors.colPrimaryContainer, 1)
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
                    Component { id: matIcon; MaterialSymbol { text: delButton.entry.iconName || "apps"; iconSize: 22; color: delButton.hovered || delButton.selected ? Appearance.colors.colOnPrimaryContainer : Appearance.colors.colOnLayer1 } }
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
                            color: delButton.hovered || delButton.selected ? Appearance.colors.colOnPrimaryContainer : Appearance.colors.colOnLayer1
                            elide: Text.ElideRight
                        }
                    }
                    StyledText {
                        visible: delButton.hovered || delButton.selected
                        text: delButton.entry.verb || "Open"
                        font.pixelSize: Appearance.font.pixelSize.smallest
                        color: Appearance.colors.colOnPrimaryContainer
                    }
                }
            }
            Keys.onPressed: event => {
                if (event.key === Qt.Key_Escape) { GlobalStates.overviewOpen = false; event.accepted = true }
                else if (event.key === Qt.Key_Down) { selectResult(currentIndex + 1); event.accepted = true }
                else if (event.key === Qt.Key_Up) {
                    if (currentIndex <= 0) searchInput.forceActiveFocus()
                    else selectResult(currentIndex - 1)
                    event.accepted = true
                } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                    executeCurrent()
                    event.accepted = true
                }
            }
        }
    }
}
