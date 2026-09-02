pragma ComponentBehavior: Bound
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import qs.modules.common.utils
import qs.services
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

// Options toolbar - enhanced with action buttons
Toolbar {
    id: root

    // Use a synchronizer on these
    property var action
    property var selectionMode
    // Signals
    signal dismiss()

    spacing: 6

    // Selection mode tabs
    ToolbarTabBar {
        id: tabBar
        tabButtonList: [
            {"icon": "activity_zone", "name": Translation.tr("Rect")},
            {"icon": "gesture", "name": Translation.tr("Circle")}
        ]
        currentIndex: root.selectionMode === RegionSelection.SelectionMode.RectCorners ? 0 : 1
        onCurrentIndexChanged: {
            const newMode = currentIndex === 0 ? RegionSelection.SelectionMode.RectCorners : RegionSelection.SelectionMode.Circle;
            if (root.selectionMode !== newMode)
                root.selectionMode = newMode;
        }
    }

    // Separator
    Rectangle { width: 1; height: 28; color: Appearance.colors.colOutlineVariant; opacity: 0.5 }

    // Action buttons row
    Row {
        spacing: 2

        // Screenshot region (copy)
        RippleButton {
            id: btnScreenshot
            implicitHeight: 32
            implicitWidth: 32
            buttonRadius: 16
            colBackground: root.action === RegionSelection.SnipAction.Copy ? Appearance.colors.colPrimaryContainer : "transparent"
            colBackgroundHover: Appearance.colors.colLayer3
            colRipple: Appearance.colors.colLayer3Active
            onClicked: root.action = RegionSelection.SnipAction.Copy
            contentItem: MaterialSymbol {
                anchors.centerIn: parent
                text: "screenshot_region"
                iconSize: 18
                color: root.action === RegionSelection.SnipAction.Copy ? Appearance.colors.colOnPrimaryContainer : Appearance.colors.colOnLayer1
            }
            StyledToolTip { text: Translation.tr("Copy screenshot") }
        }

        // Edit screenshot
        RippleButton {
            implicitHeight: 32
            implicitWidth: 32
            buttonRadius: 16
            colBackground: root.action === RegionSelection.SnipAction.Edit ? Appearance.colors.colPrimaryContainer : "transparent"
            colBackgroundHover: Appearance.colors.colLayer3
            colRipple: Appearance.colors.colLayer3Active
            onClicked: root.action = RegionSelection.SnipAction.Edit
            contentItem: MaterialSymbol {
                anchors.centerIn: parent
                text: "edit"
                iconSize: 18
                color: root.action === RegionSelection.SnipAction.Edit ? Appearance.colors.colOnPrimaryContainer : Appearance.colors.colOnLayer1
            }
            StyledToolTip { text: Translation.tr("Edit screenshot") }
        }

        // Search
        RippleButton {
            implicitHeight: 32
            implicitWidth: 32
            buttonRadius: 16
            colBackground: root.action === RegionSelection.SnipAction.Search ? Appearance.colors.colPrimaryContainer : "transparent"
            colBackgroundHover: Appearance.colors.colLayer3
            colRipple: Appearance.colors.colLayer3Active
            onClicked: root.action = RegionSelection.SnipAction.Search
            contentItem: MaterialSymbol {
                anchors.centerIn: parent
                text: "search"
                iconSize: 18
                color: root.action === RegionSelection.SnipAction.Search ? Appearance.colors.colOnPrimaryContainer : Appearance.colors.colOnLayer1
            }
            StyledToolTip { text: Translation.tr("Search region") }
        }

        // OCR
        RippleButton {
            implicitHeight: 32
            implicitWidth: 32
            buttonRadius: 16
            colBackground: root.action === RegionSelection.SnipAction.CharRecognition ? Appearance.colors.colPrimaryContainer : "transparent"
            colBackgroundHover: Appearance.colors.colLayer3
            colRipple: Appearance.colors.colLayer3Active
            onClicked: root.action = RegionSelection.SnipAction.CharRecognition
            contentItem: MaterialSymbol {
                anchors.centerIn: parent
                text: "document_scanner"
                iconSize: 18
                color: root.action === RegionSelection.SnipAction.CharRecognition ? Appearance.colors.colOnPrimaryContainer : Appearance.colors.colOnLayer1
            }
            StyledToolTip { text: Translation.tr("OCR text recognition") }
        }

        // Ask AI about this region
        RippleButton {
            implicitHeight: 32
            implicitWidth: 32
            buttonRadius: 16
            colBackground: root.action === RegionSelection.SnipAction.AskAi ? Appearance.colors.colPrimaryContainer : "transparent"
            colBackgroundHover: Appearance.colors.colLayer3
            colRipple: Appearance.colors.colLayer3Active
            onClicked: root.action = RegionSelection.SnipAction.AskAi
            contentItem: MaterialSymbol {
                anchors.centerIn: parent
                text: "auto_awesome"
                iconSize: 18
                color: root.action === RegionSelection.SnipAction.AskAi ? Appearance.colors.colOnPrimaryContainer : Appearance.colors.colOnLayer1
            }
            StyledToolTip { text: Translation.tr("Ask AI about this region") }
        }

        // Record region
        RippleButton {
            implicitHeight: 32
            implicitWidth: 32
            buttonRadius: 16
            colBackground: root.action === RegionSelection.SnipAction.Record ? Appearance.colors.colErrorContainer : "transparent"
            colBackgroundHover: Appearance.colors.colLayer3
            colRipple: Appearance.colors.colLayer3Active
            onClicked: root.action = RegionSelection.SnipAction.Record
            contentItem: MaterialSymbol {
                anchors.centerIn: parent
                text: "fiber_manual_record"
                iconSize: 18
                color: root.action === RegionSelection.SnipAction.Record ? Appearance.colors.colOnErrorContainer : Appearance.colors.colOnLayer1
            }
            StyledToolTip { text: Translation.tr("Record region") }
        }

        // Record with sound
        RippleButton {
            implicitHeight: 32
            implicitWidth: 32
            buttonRadius: 16
            colBackground: root.action === RegionSelection.SnipAction.RecordWithSound ? Appearance.colors.colErrorContainer : "transparent"
            colBackgroundHover: Appearance.colors.colLayer3
            colRipple: Appearance.colors.colLayer3Active
            onClicked: root.action = RegionSelection.SnipAction.RecordWithSound
            contentItem: MaterialSymbol {
                anchors.centerIn: parent
                text: "mic"
                iconSize: 18
                color: root.action === RegionSelection.SnipAction.RecordWithSound ? Appearance.colors.colOnErrorContainer : Appearance.colors.colOnLayer1
            }
            StyledToolTip { text: Translation.tr("Record with audio") }
        }

        // Separator
        Rectangle { width: 1; height: 24; anchors.verticalCenter: parent.verticalCenter; color: Appearance.colors.colOutlineVariant; opacity: 0.5 }

        // Fullscreen screenshot (direct, no region selection)
        RippleButton {
            implicitHeight: 32
            implicitWidth: 32
            buttonRadius: 16
            colBackground: "transparent"
            colBackgroundHover: Appearance.colors.colLayer3
            colRipple: Appearance.colors.colLayer3Active
            onClicked: {
                root.dismiss();
                Quickshell.execDetached(ScreenshotAction.fullScreenCommand());
            }
            contentItem: MaterialSymbol {
                anchors.centerIn: parent
                text: "photo_camera"
                iconSize: 18
                color: Appearance.colors.colOnLayer1
            }
            StyledToolTip { text: Translation.tr("Full screenshot") }
        }

        // Fullscreen record with sound (direct)
        RippleButton {
            implicitHeight: 32
            implicitWidth: 32
            buttonRadius: 16
            colBackground: "transparent"
            colBackgroundHover: Appearance.colors.colLayer3
            colRipple: Appearance.colors.colLayer3Active
            onClicked: {
                root.dismiss();
                Quickshell.execDetached([Directories.recordScriptPath, "--fullscreen", "--sound"]);
            }
            contentItem: MaterialSymbol {
                anchors.centerIn: parent
                text: "screen_record"
                iconSize: 18
                color: Appearance.colors.colOnLayer1
            }
            StyledToolTip { text: Translation.tr("Record full screen") }
        }
    }
}
