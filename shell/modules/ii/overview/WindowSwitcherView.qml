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
    //
    // Watches windowSwitcherOpen, not overviewOpen. This view was split out of
    // Overview.qml into its own panel but this handler kept listening to the
    // launcher's state, so opening the switcher never reset it (and opening the
    // launcher reset a panel that wasn't even on screen).
    Connections {
        target: GlobalStates
        function onWindowSwitcherOpenChanged() {
            if (GlobalStates.windowSwitcherOpen) {
                root.activeTabIndex = root.workspacesTabIndex;
                root.filterText = "";
                Qt.callLater(() => root.forceActiveFocus());
            }
        }
    }

    // The panel requests keyboard focus on demand, but key events only reach
    // this item's Keys.onPressed (Escape / left / right) if it actually holds
    // focus - nothing ever gave it any while the Workspaces tab was up, since
    // the filter field is hidden there.
    focus: true

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
            // Driven one way only. TabBar assigns its own currentIndex when a
            // tab is activated, so pairing a `currentIndex: <expr>` binding
            // with onCurrentIndexChanged writing back to that same expression
            // is a binding loop.
            Component.onCompleted: tabBar.setCurrentIndex(root.activeTabIndex)
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
            // ToolbarTextField hardcodes Layout.fillHeight: true, which lets it
            // stretch to whatever spare height the column has and, with its
            // full-radius background, balloon into an oval.
            Layout.fillHeight: false
            Layout.preferredHeight: 40
            visible: root.activeTabIndex === root.windowsTabIndex
            implicitWidth: 320
            implicitHeight: 40
            focus: visible
            placeholderText: Translation.tr("Type to filter windows...")
            text: root.filterText
            onTextChanged: root.filterText = text
            // Escape has to keep closing the switcher even while the filter
            // field holds focus, otherwise the only way out of the Windows tab
            // is the mouse.
            Keys.onEscapePressed: GlobalStates.windowSwitcherOpen = false
        }
    }
}
