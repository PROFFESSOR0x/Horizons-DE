import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import Qt.labs.synchronizer
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland

Scope {
    id: overviewScope
    property bool dontAutoCancelSearch: false
    readonly property string launcherPosition: Config?.options.overview.position ?? "top"

    // Settings > Services > Search picks what Super (tap) actually opens.
    // "quickshell" (default) toggles this shell's own overview/search
    // surface as before; anything else hands off to that external tool
    // instead, following the exact kill-if-running/spawn convention already
    // used by the fuzzel fallback bind in hyprland/keybinds.lua ("pkill X
    // || X") so behavior stays consistent with the rest of this config.
    // walker additionally needs its "elephant" companion service already
    // running; vicinae needs its "vicinae-server" daemon already running -
    // neither is started here, both are expected to autostart on their own.
    function toggleSearchLauncher() {
        const launcher = Config?.options.apps?.launcher ?? "quickshell";
        switch (launcher) {
        case "walker":
            Quickshell.execDetached(["bash", "-c", "pkill -x walker || walker"]);
            break;
        case "vicinae":
            Quickshell.execDetached(["bash", "-c", "vicinae"]);
            break;
        case "fuzzel":
            Quickshell.execDetached(["bash", "-c", "pkill -x fuzzel || fuzzel"]);
            break;
        default:
            GlobalStates.overviewOpen = !GlobalStates.overviewOpen;
        }
    }
    readonly property bool isBottom: launcherPosition === "bottom"
        readonly property bool isCenter: launcherPosition === "center"

    PanelWindow {
        id: panelWindow
        property string searchingText: ""
        readonly property var monitor: WM.monitorFor(panelWindow.screen)
        property bool monitorIsFocused: WM.focusedMonitor?.name === monitor?.name
        // When m3Island is active, its inline launcher replaces Overview - suppress duplicate
        readonly property bool m3IslandActive: Config.options.bar.barMode === "m3Island"
        visible: GlobalStates.overviewOpen && !panelWindow.m3IslandActive

        WlrLayershell.namespace: "quickshell:overview"
        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.keyboardFocus: (GlobalStates.overviewOpen && !panelWindow.m3IslandActive) ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
        color: "transparent"

        mask: Region {
            item: (GlobalStates.overviewOpen && !panelWindow.m3IslandActive) ? columnLayout : null
        }

        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }

        Connections {
            target: GlobalStates
            function onOverviewOpenChanged() {
                if (!GlobalStates.overviewOpen) {
                    searchWidget.disableExpandAnimation();
                    overviewScope.dontAutoCancelSearch = false;
                    GlobalFocusGrab.dismiss();
                } else {
                    if (!overviewScope.dontAutoCancelSearch) {
                        searchWidget.cancelSearch();
                    }
                    GlobalFocusGrab.addDismissable(panelWindow);
                }
            }
        }

        Connections {
            target: GlobalFocusGrab
            function onDismissed() {
                GlobalStates.overviewOpen = false;
            }
        }
        implicitWidth: columnLayout.implicitWidth
        implicitHeight: columnLayout.implicitHeight

        function setSearchingText(text) {
            searchWidget.setSearchingText(text);
            searchWidget.focusFirstItem();
        }

        Column {
            id: columnLayout
            visible: GlobalStates.overviewOpen
            anchors.horizontalCenter: parent.horizontalCenter
            // Position via y - animatable for center mode (whole block search+results centered, dynamic with results size)
            y: {
                if (overviewScope.launcherPosition === "top") return 0
                if (overviewScope.launcherPosition === "bottom") return parent.height - implicitHeight
                // center: workspaces counted only before search (when visible), not after (when hidden) - search+workspaces vs search+results
                if (panelWindow.searchingText === "")
                    return (panelWindow.height - implicitHeight) / 2
                else
                    return (panelWindow.height - searchWidget.implicitHeight) / 2
            }
            spacing: overviewScope.isCenter ? -4 : -8
            opacity: GlobalStates.overviewOpen ? 1 : 0
            scale: GlobalStates.overviewOpen ? 1 : 0.97
            Behavior on y { enabled: overviewScope.isCenter && (Config?.options.overview.centerAnimation ?? true); NumberAnimation { duration: Config?.options.overview.centerAnimationDuration ?? 220; easing.type: Easing.BezierSpline; easing.bezierCurve: Appearance.animationCurves.expressiveDefaultSpatial } }
            Behavior on opacity { NumberAnimation { duration: GlobalStates.overviewOpen ? 360 : 220; easing.type: Easing.BezierSpline; easing.bezierCurve: GlobalStates.overviewOpen ? Appearance.animationCurves.emphasizedDecel : Appearance.animationCurves.emphasizedAccel } }
            Behavior on scale { NumberAnimation { duration: GlobalStates.overviewOpen ? 400 : 220; easing.type: Easing.BezierSpline; easing.bezierCurve: GlobalStates.overviewOpen ? Appearance.animationCurves.emphasizedDecel : Appearance.animationCurves.emphasizedAccel } }

            Keys.onPressed: event => {
                if (event.key === Qt.Key_Escape) {
                    GlobalStates.overviewOpen = false;
                } else if (event.key === Qt.Key_Left) {
                    if (!panelWindow.searchingText)
                        WM.switchWorkspaceRelative("prev");
                } else if (event.key === Qt.Key_Right) {
                    if (!panelWindow.searchingText)
                        WM.switchWorkspaceRelative("next");
                }
            }

            // Top/Center: search first, bottom: overview first (so search stays at screen edge)
            Loader {
                active: overviewScope.isBottom
                visible: active
                sourceComponent: overviewScope.isBottom ? overviewLoaderComponent : null
            }
            SearchWidget {
                id: searchWidget
                anchors.horizontalCenter: parent.horizontalCenter
                launcherPosition: overviewScope.launcherPosition
                Synchronizer on searchingText {
                    property alias source: panelWindow.searchingText
                }
            }
            Loader {
                active: !overviewScope.isBottom
                visible: active
                sourceComponent: !overviewScope.isBottom ? overviewLoaderComponent : null
            }

            Component {
                id: overviewLoaderComponent
                Loader {
                    active: GlobalStates.overviewOpen && (Config?.options.overview.enable ?? true) && (Config?.options.overview.showWorkspacesInLauncher ?? true) && panelWindow.searchingText === ""
                    sourceComponent: (Config?.options.overview.style ?? "default") === "niri" ? niriComponent : defaultComponent
                    Component {
                        id: defaultComponent
                        OverviewWidget {
                            screen: panelWindow.screen
                            visible: (panelWindow.searchingText == "") && (Config?.options.overview.showWorkspacesInLauncher ?? true)
                        }
                    }
                    Component {
                        id: niriComponent
                        NiriOverview {
                            screen: panelWindow.screen
                            panelWindow: panelWindow
                            visible: (panelWindow.searchingText == "") && (Config?.options.overview.showWorkspacesInLauncher ?? true)
                        }
                    }
                }
            }
        }
    }

    function toggleClipboard() {
        if (GlobalStates.overviewOpen && overviewScope.dontAutoCancelSearch) {
            GlobalStates.overviewOpen = false;
            return;
        }
        overviewScope.dontAutoCancelSearch = true;
        panelWindow.setSearchingText(Config.options.search.prefix.clipboard);
        GlobalStates.overviewOpen = true;
    }

    function toggleEmojis() {
        if (GlobalStates.overviewOpen && overviewScope.dontAutoCancelSearch) {
            GlobalStates.overviewOpen = false;
            return;
        }
        overviewScope.dontAutoCancelSearch = true;
        panelWindow.setSearchingText(Config.options.search.prefix.emojis);
        GlobalStates.overviewOpen = true;
    }

    function toggleSymbols() {
        if (GlobalStates.overviewOpen && overviewScope.dontAutoCancelSearch) {
            GlobalStates.overviewOpen = false;
            return;
        }
        overviewScope.dontAutoCancelSearch = true;
        panelWindow.setSearchingText(Config.options.search.prefix.symbols);
        GlobalStates.overviewOpen = true;
    }

    IpcHandler {
        target: "search"

        function toggle() {
            overviewScope.toggleSearchLauncher();
        }
        function close() {
            GlobalStates.overviewOpen = false;
        }
        function open() {
            GlobalStates.overviewOpen = true;
        }
        function toggleReleaseInterrupt() {
            GlobalStates.superReleaseMightTrigger = false;
        }
        function clipboardToggle() {
            overviewScope.toggleClipboard();
        }
    }

    CompositorGlobalShortcut {
        name: "searchToggle"
        description: "Toggles search on press"

        onPressed: {
            overviewScope.toggleSearchLauncher();
        }
    }
    // overviewWorkspacesToggle/overviewWorkspacesClose moved to
    // WindowSwitcher.qml - Super+Tab now opens a standalone panel, not this
    // search/launcher overview.
    CompositorGlobalShortcut {
        name: "searchToggleRelease"
        description: "Toggles search on release"

        onPressed: {
            GlobalStates.superReleaseMightTrigger = true;
        }

        onReleased: {
            if (!GlobalStates.superReleaseMightTrigger) {
                GlobalStates.superReleaseMightTrigger = true;
                return;
            }
            overviewScope.toggleSearchLauncher();
        }
    }
    CompositorGlobalShortcut {
        name: "searchToggleReleaseInterrupt"
        description: "Interrupts possibility of search being toggled on release. " + "This is necessary because GlobalShortcut.onReleased in quickshell triggers whether or not you press something else while holding the key. " + "To make sure this works consistently, use binditn = MODKEYS, catchall in an automatically triggered submap that includes everything."

        onPressed: {
            GlobalStates.superReleaseMightTrigger = false;
        }
    }
    CompositorGlobalShortcut {
        name: "overviewClipboardToggle"
        description: "Toggle clipboard query on overview widget"

        onPressed: {
            overviewScope.toggleClipboard();
        }
    }

    CompositorGlobalShortcut {
        name: "overviewEmojiToggle"
        description: "Toggle emoji query on overview widget"

        onPressed: {
            overviewScope.toggleEmojis();
        }
    }

    CompositorGlobalShortcut {
        name: "overviewSymbolsToggle"
        description: "Toggle material symbols search on overview widget"

        onPressed: {
            overviewScope.toggleSymbols();
        }
    }
}
