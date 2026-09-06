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
    //
    // Both margins have to come off it. The island sizes itself to
    // `launcherInline.implicitHeight + 12` and then anchors this item 6px down
    // from its top, so the space actually available here is the island's
    // height minus 6 above and 6 below. Taking the island height verbatim made
    // this item 12px taller than its slot: searchRow is a RowLayout, which
    // defaults to Layout.fillHeight, so it absorbed the whole surplus and drew
    // the search icon, field and close button ~6px below the island's centre
    // with the bottom edge clipped off.
    height: Math.max(0, (parent?.height ?? 0) - anchors.topMargin * 2)
    clip: true
    property var panelWindow
    property bool hasQuery: LauncherSearch.query !== ""
    readonly property int maximumResults: Math.max(1, Config.options.m3Island.launcherMaxResults)
    // Height of the search bar alone, i.e. the launcher with no results yet.
    // Derived rather than hardcoded so the reveal starts exactly when the
    // surface begins growing past the bar.
    readonly property real collapsedHeight: searchRow.implicitHeight
        + searchRow.Layout.topMargin + searchRow.Layout.bottomMargin
    readonly property real resultsRevealProgress: Math.max(0, Math.min(1, (height - root.collapsedHeight) / 88))

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
            // A nested layout defaults to Layout.fillHeight: true. This row is
            // a fixed-height search bar - any spare height belongs to the
            // results list below it, not here.
            Layout.fillHeight: false
            Layout.leftMargin: 10
            Layout.rightMargin: 6
            Layout.topMargin: 6
            Layout.bottomMargin: 6
            spacing: 8

            MaterialSymbol {
                Layout.alignment: Qt.AlignVCenter
                text: "search"
                iconSize: Appearance.font.pixelSize.large
                color: Appearance.colors.colOnLayer1
            }
            ToolbarTextField {
                id: searchInput
                Layout.fillWidth: true
                // ToolbarTextField hardcodes Layout.fillHeight: true, which is
                // wrong in a fixed-height bar - it stretched the field (and its
                // full-radius background) to whatever height the row was given.
                Layout.fillHeight: false
                Layout.alignment: Qt.AlignVCenter
                Layout.preferredHeight: 36
                focus: GlobalStates.overviewOpen
                font.pixelSize: Appearance.font.pixelSize.small
                // Symmetric now. The old 7/13 split was compensating for the
                // row being mis-sized (see `height` above); with the row the
                // right height, uneven padding just pushes the text off-centre
                // the other way.
                topPadding: 8
                bottomPadding: 8
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
                        // The first result is already selected the moment
                        // results arrive (see updateTimer below), so jumping to
                        // index 0 here moved the highlight nowhere and the first
                        // Down looked like it did nothing - you had to press it
                        // twice to reach the second entry. Step past whatever is
                        // already highlighted instead.
                        resultsView.selectResult(resultsView.currentIndex < 0 ? 0 : resultsView.currentIndex + 1)
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
                Layout.alignment: Qt.AlignVCenter
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

            // Coalesce a burst of service updates (query, calculator and file
            // results) without adding a noticeable delay to the M3 launcher.
            Timer {
                id: updateTimer
                interval: 24
                onTriggered: {
                    // Honour the configured cap (Settings > Bar > M3 Island >
                    // "Launcher results"); this used to be hardcoded to 10, so
                    // raising the setting had no effect.
                    resultModel.values = (LauncherSearch.results ?? []).slice(0, root.maximumResults)
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
