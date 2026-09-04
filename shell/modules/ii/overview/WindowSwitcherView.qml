pragma ComponentBehavior: Bound
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Layouts
import Quickshell

// Super+Tab's switcher: the existing per-workspace OverviewWidget ("Workspaces")
// plus a new flat, filterable window grid ("Windows"), behind two tabs. Sits
// in Overview.qml's overviewLoaderComponent exactly where OverviewWidget used
// to sit directly, so every existing open/close/search-cancel flow (Escape,
// left/right arrow workspace switching, search auto-cancel) keeps working
// unchanged - this only decides what's shown when there's no search text.
Item {
    id: root
    required property var screen

    readonly property int workspacesTabIndex: 0
    readonly property int windowsTabIndex: 1
    property int activeTabIndex: root.workspacesTabIndex
    property string filterText: ""

    // Fresh state (Workspaces tab, empty filter) every time the switcher is
    // opened again, so a previous windows-tab search doesn't linger silently.
    Connections {
        target: GlobalStates
        function onOverviewOpenChanged() {
            if (GlobalStates.overviewOpen) {
                root.activeTabIndex = root.workspacesTabIndex;
                root.filterText = "";
            }
        }
    }

    implicitWidth: columnLayout.implicitWidth
    implicitHeight: columnLayout.implicitHeight

    ColumnLayout {
        id: columnLayout
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: 8

        SecondaryTabBar {
            id: tabBar
            Layout.alignment: Qt.AlignHCenter
            Layout.fillWidth: false
            currentIndex: root.activeTabIndex
            onCurrentIndexChanged: root.activeTabIndex = tabBar.currentIndex

            SecondaryTabButton {
                buttonIcon: "grid_view"
                buttonText: Translation.tr("Workspaces")
            }
            SecondaryTabButton {
                buttonIcon: "web_asset"
                buttonText: Translation.tr("Windows")
            }
        }

        Loader {
            id: contentLoader
            Layout.alignment: Qt.AlignHCenter
            sourceComponent: root.activeTabIndex === root.windowsTabIndex ? windowsComponent : workspacesComponent

            Component {
                id: workspacesComponent
                OverviewWidget {
                    screen: root.screen
                }
            }
            Component {
                id: windowsComponent
                WindowsGrid {
                    screen: root.screen
                    filterText: root.filterText
                }
            }
        }

        ToolbarTextField {
            id: filterField
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: 2
            visible: root.activeTabIndex === root.windowsTabIndex
            implicitWidth: 320
            implicitHeight: 40
            focus: visible
            placeholderText: Translation.tr("Type to filter windows...")
            text: root.filterText
            onTextChanged: root.filterText = text
        }
    }
}
