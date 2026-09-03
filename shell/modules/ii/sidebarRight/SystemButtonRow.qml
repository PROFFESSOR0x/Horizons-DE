import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.ii.sidebarRight.quickToggles.classicStyle
import QtQuick
import QtQuick.Layouts

// The sidebar's "normal" (non-banner) header — shown when Config.options.sidebar.banner
// is false. Mirrors the button row already present in the banner variant (edit quick
// toggles / reload / settings / session) so both header styles offer the same actions,
// plus a compact avatar+name so this mode isn't just a bare row of icon buttons with no
// identity/content of its own.
//
// This component was referenced (SidebarRightContent.qml's normalComponent) but never
// defined anywhere in the codebase - selecting the non-banner header style would fail
// to instantiate a type and leave that part of the sidebar broken/empty.
RowLayout {
    id: root
    Layout.fillWidth: true
    spacing: 8

    // Bound from SidebarRightContent's own editMode (shared with AndroidQuickPanel) -
    // this component doesn't own that state, it only surfaces the toggle button for it.
    property bool editMode: false
    signal editModeToggleRequested()

    Rectangle {
        id: avatarRect
        width: 36; height: 36; radius: width / 2
        color: Appearance.colors.colPrimaryContainer

        Image {
            id: avatarImage
            anchors.fill: parent
            source: Config.options.profile.avatarPath !== ""
                ? "file://" + Config.options.profile.avatarPicture
                : "file:///home/" + (Quickshell.env("USER") ?? "user") + "/.face"
            sourceSize.width: avatarImage.width * 2
            sourceSize.height: avatarImage.height * 2
            fillMode: Image.PreserveAspectCrop
            visible: status === Image.Ready
            onStatusChanged: {
                if (status === Image.Error) visible = false
            }
        }

        MaterialSymbol {
            anchors.centerIn: parent
            text: "account_circle"
            iconSize: 24
            color: Appearance.colors.colOnPrimaryContainer
            visible: avatarImage.status !== Image.Ready
        }
    }

    StyledText {
        Layout.fillWidth: true
        elide: Text.ElideRight
        text: Config.options.profile.displayName === "" ? SystemInfo.username : Config.options.profile.displayName
        font.pixelSize: Appearance.font.pixelSize.small
        font.weight: Font.DemiBold
        color: Appearance.colors.colOnLayer1
    }

    ButtonGroup {
        color: "transparent"
        padding: 4

        QuickToggleButton {
            toggled: root.editMode
            visible: Config.options.sidebar.quickToggles.style === "android"
            buttonIcon: "edit"
            onClicked: root.editModeToggleRequested()
            StyledToolTip {
                text: Translation.tr("Edit quick toggles") + (root.editMode ? Translation.tr("\nLMB to enable/disable\nRMB to toggle size\nScroll to swap position") : "")
            }
        }
        QuickToggleButton {
            toggled: false
            buttonIcon: "restart_alt"
            onClicked: {
                Quickshell.execDetached(["hyprctl", "reload"])
                Quickshell.reload(true);
            }
            StyledToolTip {
                text: Translation.tr("Reload Hyprland & Quickshell")
            }
        }
        QuickToggleButton {
            toggled: GlobalStates.settingsOpen
            buttonIcon: "settings"
            onClicked: {
                GlobalStates.sidebarRightOpen = false;
                GlobalStates.settingsOpen = !GlobalStates.settingsOpen
            }
            StyledToolTip {
                text: Translation.tr("Settings")
            }
        }
        QuickToggleButton {
            toggled: false
            buttonIcon: "mode_off_on"
            onClicked: GlobalStates.sessionOpen = true
            StyledToolTip {
                text: Translation.tr("Session")
            }
        }
    }
}
