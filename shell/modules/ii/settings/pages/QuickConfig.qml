import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Io
import Qt.labs.folderlistmodel
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import qs.modules.common.models

ContentPage {
    id: page
    property bool isMinimal: Config.options.settings.style === "minimal"
    forceWidth: true
    baseWidth: !isMinimal ? 720 : 600
    bottomContentPadding: 35

    function goTo(term) {
        const t = term.toLowerCase().trim()
        function findTarget(rootItem) {
            for (let i = 0; i < rootItem.children.length; i++) {
                let child = rootItem.children[i]
                if (child.title && child.title.toLowerCase().includes(t)) return child
            }
            for (let i = 0; i < rootItem.children.length; i++) {
                let found = findTarget(rootItem.children[i])
                if (found) return found
            }
            return null
        }
        let target = findTarget(mainLayout)
        if (target) {
            let pos = target.mapToItem(mainLayout, 0, 0)
            page.contentY = Math.max(0, pos.y - 0)
        }
    }

    component SmallLightDarkPreferenceButton: RippleButton {
        id: smallLightDarkPreferenceButton
        required property bool dark
        property color colText: toggled ? Appearance.colors.colOnPrimary : Appearance.colors.colOnLayer2
        padding: 5
        Layout.fillWidth: true
        Layout.fillHeight: true
        toggled: Appearance.m3colors.darkmode === dark
        colBackground: Appearance.colors.colLayer2
        onClicked: {
            Quickshell.execDetached(["bash", "-c", `${Directories.wallpaperSwitchScriptPath} --mode ${dark ? "dark" : "light"} --noswitch`]);
        }
        contentItem: Item {
            anchors.centerIn: parent
            ColumnLayout {
                anchors.centerIn: parent
                spacing: 0
                MaterialSymbol {
                    Layout.alignment: Qt.AlignHCenter
                    iconSize: 30
                    text: dark ? "dark_mode" : "light_mode"
                    color: smallLightDarkPreferenceButton.colText
                }
                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    text: dark ? Translation.tr("Dark") : Translation.tr("Light")
                    font.pixelSize: Appearance.font.pixelSize.smaller
                    color: smallLightDarkPreferenceButton.colText
                }
            }
        }
    }

    ColumnLayout {
        visible: page.settingsShow("appearance");
        id: mainLayout
        Layout.fillWidth: true
        Layout.fillHeight: true
        spacing: 16
        ContentSection {
            visible: page.settingsShow("appearance");
            title: Translation.tr("Color mode")
            icon: "contrast"
            RowLayout {
                visible: page.settingsShow("appearance");
                Layout.fillWidth: true
                implicitHeight: 64
                SmallLightDarkPreferenceButton {
                    visible: page.settingsShow("appearance");
                    objectName: "QuickConfig.color-mode"; dark: false }
                SmallLightDarkPreferenceButton {
                    visible: page.settingsShow("appearance");
                    objectName: "QuickConfig.color-mode-2"; dark: true }
            }
        }



        ContentSection {
            visible: page.settingsShow("appearance");
            id: performanceSection
            icon: "speed"
            title: Translation.tr("Performance")
            shape: MaterialShape.Shape.SoftBurst

            readonly property var currentProfile: PerformanceProfiles.byId(Config.options.appearance.performanceProfile)

            function applyProfile(id) {
                const resolved = Config.applyPerformanceProfile(id, HyprlandData.blurVariantSupported)
                if (!resolved) return
                if (WM.compositor === "hyprland") {
                    HyprlandConfig.setMany(resolved.hypr)
                    if (resolved.animPreset) HyprlandConfig.setAnimPreset(resolved.animPreset)
                }
            }

            GroupedList {
                compact: true;
                visible: page.settingsShow("appearance")
                StyledText {
                    property bool groupDescription: true;
                    visible: page.settingsShow("appearance");
                    Layout.fillWidth: true
                    wrapMode: Text.Wrap
                    color: Appearance.colors.colSubtext
                    font.pixelSize: Appearance.font.pixelSize.small
                    text: Translation.tr("One click reconfigures blur, shadows, animations, transparency and background widgets to match — everything except colors, which always keep following your wallpaper.")
                }
                ConfigSelectionArray {
                    visible: page.settingsShow("appearance");
                    objectName: "QuickConfig.profile";
                    icon: "tune"
                    text: Translation.tr("Profile")
                    currentValue: Config.options.appearance.performanceProfile
                    onSelected: newValue => performanceSection.applyProfile(newValue)
                    options: PerformanceProfiles.profiles.map(p => ({
                        displayName: Translation.tr(p.name),
                        icon: p.icon,
                        value: p.id
                    }))
                }
                StyledText {
                    property bool groupDescription: true;
                    visible: !!performanceSection.currentProfile
                    Layout.fillWidth: true
                    wrapMode: Text.Wrap
                    color: Appearance.colors.colSubtext
                    font.pixelSize: Appearance.font.pixelSize.small
                    text: performanceSection.currentProfile ? Translation.tr(performanceSection.currentProfile.description) : ""
                }
                StyledText {
                    property bool groupDescription: true;
                    visible: Config.options.appearance.performanceProfile === "maxExperience" && !HyprlandData.blurVariantSupported
                    Layout.fillWidth: true
                    wrapMode: Text.Wrap
                    color: Appearance.m3colors.m3error
                    font.pixelSize: Appearance.font.pixelSize.small
                    text: Translation.tr("Your running Hyprland doesn't support blur styles yet (needs hyprwm/Hyprland PR #15661 — not in any tagged release yet), so Max Experience used a fuller plain blur instead of Liquid Glass. Settings > Hyprland > Blur Style has details.")
                }
            }
        }




    }
}
