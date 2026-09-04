pragma ComponentBehavior: Bound
import qs
import qs.services
import qs.modules.common
import qs.modules.common.models
import qs.modules.common.widgets
import qs.modules.ii.overview
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland

Scope {
    id: root
    PanelWindow {
        id: win
        visible: (GlobalStates?.workspacesHovered === true) && (Config?.options?.overview?.hoverPreviewInBar === true) && (GlobalStates?.overviewOpen !== true) && (GlobalStates?.workspacesHoveredScreen !== null)
        screen: GlobalStates.workspacesHoveredScreen ?? Quickshell.screens[0]
        // See Bar.qml (shell/modules/ii/bar/Bar.qml) for why this is gated
        // behind a Wayland-only Loader instead of set directly.
        Loader {
            active: WM.isWayland
            sourceComponent: Item {
                Binding { target: win.WlrLayershell; property: "layer"; value: WlrLayer.Overlay }
                Binding { target: win.WlrLayershell; property: "namespace"; value: "quickshell:workspacesHoverPreview" }
                Binding { target: win.WlrLayershell; property: "keyboardFocus"; value: WlrKeyboardFocus.None }
            }
        }
        exclusionMode: ExclusionMode.Ignore
        color: "transparent"
        mask: Region { item: col }
        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }
        implicitWidth: col.implicitWidth
        implicitHeight: col.implicitHeight

        // Close when mouse leaves bar area for a bit
        Timer {
            id: hideTimer
            interval: 200
            onTriggered: GlobalStates.workspacesHovered = false
        }
        Connections {
            target: GlobalStates
            function onWorkspacesHoveredChanged() {
                if (GlobalStates.workspacesHovered) hideTimer.stop()
                else hideTimer.restart()
            }
        }

        // Exactly like launcher's OverviewWidget - no extra window decoration
        ColumnLayout {
            id: col
            anchors.centerIn: parent
            spacing: 0
            OverviewWidget {
                id: overviewPreview
                screen: GlobalStates.workspacesHoveredScreen ?? win.screen
                // Use same scale as launcher for exact match
            }
        }
    }
}
