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
Rectangle {
    id: root
    required property var screen

    // The switcher is an overlay, so its own surface—not the wallpaper or the
    // focused application behind it—must define the visual grouping. An opaque
    // card also makes thumbnails, tabs and search read as one deliberate UI.
    color: Appearance.colors.colLayer0
    radius: Appearance.rounding.large
    border.width: 1
    border.color: Appearance.colors.colLayer0Border
    clip: true

    readonly property int workspacesTabIndex: 0
    readonly property int windowsTabIndex: 1
    property int activeTabIndex: root.workspacesTabIndex
    property string filterText: ""

    function toggleTab() {
        const nextIndex = root.activeTabIndex === root.windowsTabIndex
            ? root.workspacesTabIndex
            : root.windowsTabIndex
        // Keep TabBar's internal state and the loaded page in lockstep. This
        // is imperative on purpose: `currentIndex` is also changed by mouse
        // clicks, so a two-way binding here would create a loop.
        tabBar.setCurrentIndex(nextIndex)
        root.activeTabIndex = nextIndex
        if (nextIndex === root.windowsTabIndex)
            Qt.callLater(() => filterField.forceActiveFocus())
        else
            Qt.callLater(() => root.forceActiveFocus())
    }

    function openPowerMenu() {
        // Reuse SessionScreen's existing destructive-action confirmation and
        // optional password gate. This entry point only changes presentation:
        // the sheet hugs the right screen edge instead of using the user's
        // usual centered/left session-menu layout.
        GlobalStates.sessionForceRightEdge = true
        GlobalStates.windowSwitcherOpen = false
        Qt.callLater(() => GlobalStates.sessionOpen = true)
    }

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
    Keys.priority: Keys.BeforeItem
    Keys.onPressed: event => {
        if (event.key === Qt.Key_Tab || event.key === Qt.Key_Backtab) {
            root.toggleTab()
            event.accepted = true
        }
    }

    readonly property real panelPadding: 18
    implicitWidth: columnLayout.implicitWidth + panelPadding * 2
    implicitHeight: columnLayout.implicitHeight + panelPadding * 2

    StyledRectangularShadow { target: root }

    ColumnLayout {
        id: columnLayout
        anchors.fill: parent
        anchors.margins: root.panelPadding
        spacing: 12

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            // Match the power control's width on the other side so the two
            // switcher tabs remain visually centered in the panel.
            Item { Layout.preferredWidth: powerButton.implicitWidth }

            SecondaryTabBar {
                id: tabBar
                Layout.alignment: Qt.AlignHCenter
                Layout.fillWidth: false
                // The switcher floats directly over the wallpaper. Give its tabs
                // an opaque, outlined surface so their labels and active underline
                // keep contrast even on a very light image.
                showSurface: true
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

            RippleButton {
                id: powerButton
                Layout.alignment: Qt.AlignVCenter
                implicitWidth: 38
                implicitHeight: 38
                buttonRadius: Appearance.rounding.full
                colBackground: hovered ? Appearance.colors.colErrorContainer : Appearance.colors.colLayer1
                colBackgroundHover: Appearance.colors.colErrorContainer
                onClicked: root.openPowerMenu()
                contentItem: MaterialSymbol {
                    anchors.centerIn: parent
                    text: "power_settings_new"
                    iconSize: Appearance.font.pixelSize.normal
                    color: powerButton.hovered ? Appearance.colors.colOnErrorContainer : Appearance.colors.colOnLayer1
                }
                StyledToolTip { text: Translation.tr("Power options") }
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
            Keys.priority: Keys.BeforeItem
            Keys.onPressed: event => {
                if (event.key === Qt.Key_Tab || event.key === Qt.Key_Backtab) {
                    root.toggleTab()
                    event.accepted = true
                }
            }
            // Escape has to keep closing the switcher even while the filter
            // field holds focus, otherwise the only way out of the Windows tab
            // is the mouse.
            Keys.onEscapePressed: GlobalStates.windowSwitcherOpen = false
        }
    }
}
