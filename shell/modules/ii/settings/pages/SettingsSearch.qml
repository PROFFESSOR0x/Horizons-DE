import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.common.widgets

// Full-page settings search, opened by the search FAB next to "Config file"
// in SettingsContent.qml. Matches against settingsContent.searchIndex - one
// entry per ContentSection/ContentSubsection across every page, each
// carrying a "haystack" of its own title plus every descendant setting's
// label (see SettingsContent.buildSearchIndex()) - so a hit on any
// individual setting's text still surfaces its containing section.
// Accepts either a /regex/ (case-insensitive) or falls back to a plain
// substring match if the input isn't valid regex syntax.
Item {
    id: root
    property var settingsContent: null
    property string query: ""
    property var results: []

    function forceFocus() {
        searchField.forceActiveFocus()
    }

    function runSearch() {
        const q = root.query.trim()
        if (q === "" || !root.settingsContent) {
            root.results = []
            return
        }
        let matcher
        try {
            const re = new RegExp(q, "i")
            matcher = s => re.test(s)
        } catch (e) {
            const needle = q.toLowerCase()
            matcher = s => s.toLowerCase().includes(needle)
        }
        root.results = (root.settingsContent.searchIndex ?? []).filter(entry => matcher(entry.haystack))
    }

    onQueryChanged: debounce.restart()
    Timer {
        id: debounce
        interval: 120
        onTriggered: root.runSearch()
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 12

        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            MaterialSymbol {
                text: "search"
                iconSize: Appearance.font.pixelSize.huge
                color: Appearance.colors.colOnLayer1
            }
            ToolbarTextField {
                id: searchField
                Layout.fillWidth: true
                implicitHeight: 44
                focus: true
                placeholderText: Translation.tr("Search every setting… (plain text, or /regex/)")
                onTextChanged: root.query = text
                Keys.onEscapePressed: {
                    if (root.settingsContent) root.settingsContent.showingSearch = false
                }
            }
            RippleButtonWithIcon {
                materialIcon: "close"
                mainText: Translation.tr("Close")
                onClicked: {
                    if (root.settingsContent) root.settingsContent.showingSearch = false
                }
            }
        }

        StyledText {
            visible: root.query.trim() !== ""
            Layout.fillWidth: true
            text: root.results.length === 1
                ? Translation.tr("1 result")
                : Translation.tr("%1 results").arg(root.results.length)
            color: Appearance.colors.colSubtext
            font.pixelSize: Appearance.font.pixelSize.small
        }

        ScrollView {
            visible: root.query.trim() !== "" && root.results.length > 0
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

            ListView {
                model: root.results
                spacing: 4
                boundsBehavior: Flickable.StopAtBounds

                delegate: RippleButton {
                    id: resultButton
                    required property var modelData
                    width: ListView.view.width
                    implicitHeight: 56
                    horizontalPadding: 12
                    onClicked: {
                        if (root.settingsContent) root.settingsContent.navigateToSearchResult(modelData)
                    }
                    contentItem: RowLayout {
                        spacing: 12
                        MaterialSymbol {
                            text: resultButton.modelData.pageIcon || "settings"
                            iconSize: Appearance.font.pixelSize.larger
                            color: Appearance.colors.colOnLayer1
                        }
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 0
                            StyledText {
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                                text: resultButton.modelData.sectionTitle
                                font.pixelSize: Appearance.font.pixelSize.normal
                                color: Appearance.colors.colOnLayer1
                            }
                            StyledText {
                                text: resultButton.modelData.pageName
                                font.pixelSize: Appearance.font.pixelSize.smaller
                                color: Appearance.colors.colSubtext
                            }
                        }
                        MaterialSymbol {
                            text: "chevron_right"
                            iconSize: Appearance.font.pixelSize.larger
                            color: Appearance.colors.colSubtext
                        }
                    }
                }
            }
        }

        ColumnLayout {
            visible: root.query.trim() === ""
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.alignment: Qt.AlignCenter
            spacing: 8
            MaterialSymbol {
                Layout.alignment: Qt.AlignHCenter
                text: "manage_search"
                iconSize: 48
                color: Appearance.colors.colSubtext
            }
            StyledText {
                Layout.alignment: Qt.AlignHCenter
                text: Translation.tr("Type to search across every settings page")
                color: Appearance.colors.colSubtext
            }
        }

        Item {
            visible: root.query.trim() !== "" && root.results.length === 0
            Layout.fillWidth: true
            Layout.fillHeight: true
            ColumnLayout {
                anchors.centerIn: parent
                spacing: 8
                MaterialSymbol {
                    Layout.alignment: Qt.AlignHCenter
                    text: "search_off"
                    iconSize: 48
                    color: Appearance.colors.colSubtext
                }
                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    text: Translation.tr("No settings match \"%1\"").arg(root.query)
                    color: Appearance.colors.colSubtext
                }
            }
        }
    }
}
