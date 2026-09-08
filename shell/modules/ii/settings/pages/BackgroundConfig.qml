import QtQuick
import QtQuick.Layouts
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import Quickshell.Hyprland


ContentPage {
    id: page
    forceWidth: true

    function goTo(term) {
        const t = term.toLowerCase().trim()

        function findTarget(rootItem) {
            for (let i = 0; i < rootItem.children.length; i++) {
                let child = rootItem.children[i]
                if (child.title && child.title.toLowerCase().includes(t)) {
                    return child
                }
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

    function displayPathFor(path) {
        return /\.(mp4|webm|mkv|avi|mov)$/i.test(path)
            ? Config.options.background.thumbnailPath
            : path
    }

    function resetPrimaryVisualizer() {
        const visualizer = Config.options.background.widgets.visualizer
        visualizer.x = 80
        visualizer.y = 720
        visualizer.width = 960
        visualizer.height = 220
        visualizer.barCount = 50
        visualizer.spacing = 6
        visualizer.noiseFloor = 1.5
        visualizer.attack = 0.68
        visualizer.release = 0.24
        visualizer.hideWhenObscured = true
    }

    function isWidgetLockOnly(name) {
        return Config.options.background.widgets.lockOnly.indexOf(name) !== -1
    }

    function setWidgetLockOnly(name, on) {
        let values = Config.options.background.widgets.lockOnly.slice()
        if (on && values.indexOf(name) === -1) values.push(name)
        if (!on) values = values.filter(value => value !== name)
        Config.options.background.widgets.lockOnly = values

        if (on) GlobalStates.setWidgetShown(name, true, true)
    }

    ColumnLayout {
        visible: page.settingsShow("appearance|widget-details|widgets");
        id: mainLayout
        Layout.fillWidth: true
        Layout.fillHeight: true
        spacing: 20

        ContentSection {
            visible: page.settingsShow("appearance|widget-details");
            icon: "panorama"
            title: Translation.tr("Wallpaper")
            shape: MaterialShape.Shape.Clover4Leaf

            Rectangle {
                Layout.fillWidth: true
                visible: WM.compositor !== "niri"
                implicitHeight: wrapperCol.implicitHeight + 16
                topLeftRadius: Appearance.rounding.verylarge
                topRightRadius: Appearance.rounding.verylarge
                bottomLeftRadius: Appearance.rounding.normal
                bottomRightRadius: Appearance.rounding.normal
                color: Appearance.colors.colLayer1

                ColumnLayout {
                    id: wrapperCol
                    anchors.fill: parent
                    anchors.margins: 8
                    spacing: 8

                    Carousel {
                        Layout.fillWidth: true
                        implicitHeight: 280
                        largeItemWidthRatio: 0.5
                        mediumItemWidthRatio: 0.485
                        itemSpacing: 8
                        model: [
                            page.displayPathFor(Config.options.background.wallpaperPath),
                            page.displayPathFor(
                                Config.options.background.lockWall !== ""
                                    ? Config.options.background.lockWall
                                    : Config.options.background.wallpaperPath
                            )
                        ]
                        wheelEnabled: false
                        dragEnabled: false
                        clickAction: (index, modelData) => {
                            GlobalStates.wallpaperSelectorTarget = index === 1 ? "lockWall" : "wallpaper"
                            GlobalStates.wallpaperSelectorOpen = true
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        Rectangle {
                            Layout.fillWidth: true
                            implicitHeight: 24
                            radius: Appearance.rounding.normal
                            color: "transparent"

                            RowLayout {
                                anchors.centerIn: parent
                                spacing: 8
                                MaterialSymbol {
                                    text: "desktop_windows"
                                    iconSize: Appearance.font.pixelSize.larger
                                    color: Appearance.colors.colPrimary
                                }
                                StyledText {
                                    text: Translation.tr("Desktop")
                                    font.pixelSize: Appearance.font.pixelSize.normal
                                    font.weight: Font.Medium
                                    color: Appearance.colors.colOnLayer1
                                }
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            implicitHeight: 24
                            radius: Appearance.rounding.normal
                            color: "transparent"

                            RowLayout {
                                anchors.centerIn: parent
                                spacing: 8
                                MaterialSymbol {
                                    text: "lock"
                                    iconSize: Appearance.font.pixelSize.larger
                                    color: Appearance.colors.colPrimary
                                }
                                StyledText {
                                    text: Translation.tr("Lockscreen")
                                    font.pixelSize: Appearance.font.pixelSize.normal
                                    font.weight: Font.Medium
                                    color: Appearance.colors.colOnLayer1
                                }
                            }
                        }
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                visible: WM.compositor === "niri"
                implicitHeight: niriWrapperCol.implicitHeight + 16
                topLeftRadius: Appearance.rounding.verylarge
                topRightRadius: Appearance.rounding.verylarge
                bottomLeftRadius: Appearance.rounding.normal
                bottomRightRadius: Appearance.rounding.normal
                color: Appearance.colors.colLayer1

                ColumnLayout {
                    id: niriWrapperCol
                    anchors.fill: parent
                    anchors.margins: 8
                    spacing: 8

                    Carousel {
                        Layout.fillWidth: true
                        implicitHeight: 280
                        largeItemWidthRatio: 1
                        mediumItemWidthRatio: 0
                        itemSpacing: 8
                        model: [page.displayPathFor(Config.options.background.wallpaperPath)]
                        wheelEnabled: false
                        dragEnabled: false
                        clickAction: (index, modelData) => {
                            GlobalStates.wallpaperSelectorTarget = "wallpaper"
                            GlobalStates.wallpaperSelectorOpen = true
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: 24
                        radius: Appearance.rounding.normal
                        color: "transparent"

                        RowLayout {
                            anchors.centerIn: parent
                            spacing: 8
                            MaterialSymbol {
                                text: "image"
                                iconSize: Appearance.font.pixelSize.larger
                                color: Appearance.colors.colPrimary
                            }
                            StyledText {
                                text: Config.options.background.wallpaperPath.split("/").pop()
                                font.pixelSize: Appearance.font.pixelSize.normal
                                font.weight: Font.Medium
                                color: Appearance.colors.colOnLayer1
                                elide: Text.ElideMiddle
                            }
                        }
                    }
                }
            }

            GroupedList {
                compact: true;
                visible: page.settingsShow("appearance|widget-details");
                Layout.topMargin: -2

                ConfigSwitch {
                    visible: page.settingsShow("appearance");
                    objectName: "BackgroundConfig.use-same-wallpaper-for-both";
                    id: syncWallpaperSwitch
                    buttonIcon: "sync"
                    text: Translation.tr("Use same wallpaper for both")
                    checked: Config.options.background.lockWall === ""
                    onEdited: {
                        if (checked) {
                            Config.options.background.lockWall = "";
                        }
                    }
                }

                ConfigSwitch {
                    visible: page.settingsShow("appearance");
                    objectName: "BackgroundConfig.preview-wallpaper";
                    buttonIcon: "preview"
                    text: Translation.tr("Preview wallpaper")
                    checked: Config.options.background.enableWallpaperPreview
                    onEdited: {
                        Config.options.background.enableWallpaperPreview = checked;
                    }
                }

                ConfigSwitch {
                    visible: page.settingsShow("widget-details");
                    objectName: "BackgroundConfig.blur-wall";
                    buttonIcon: "blur_on"
                    text: Translation.tr("Blur wall")
                    checked: Config.options.background.showBlur
                    onEdited: {
                        Config.options.background.showBlur = checked;
                    }
                }

                ConfigSelectionArray {
                    objectName: "BackgroundConfig.split-blur-amount"
                    // Both split options only do anything while the blur wall
                    // is on - showing them enabled otherwise reads as broken.
                    visible: page.settingsShow("widget-details") && (Config.options.background.showBlur)
                    text: Translation.tr("Split blur amount")
                    icon: "split_scene"
                    currentValue: Config.options.background.splitRatio
                    options: [
                        { "displayName": "25%",  "icon": "thumbnail_bar",              "value": "25" },
                        { "displayName": "50%",  "icon": "side_navigation",              "value": "50" },
                        { "displayName": "100%", "icon": "fullscreen",    "value": "100" },
                    ]
                    onSelected: newValue => {
                        Config.options.background.splitRatio = newValue
                    }
                }

                ConfigSelectionArray {
                    objectName: "BackgroundConfig.split-blur-side";
                    visible: page.settingsShow("widget-details") && (Config.options.background.showBlur)
                    text: Translation.tr("Split blur side")
                    icon: "align_horizontal_left"
                    currentValue: Config.options.background.splitSide
                    options: [
                        { "displayName": Translation.tr("Left"),  "icon": "align_horizontal_left",  "value": "left" },
                        { "displayName": Translation.tr("Right"), "icon": "align_horizontal_right", "value": "right" },
                    ]
                    onSelected: newValue => {
                        Config.options.background.splitSide = newValue
                    }
                }

                ConfigSpinBox {
                    visible: page.settingsShow("appearance");
                    objectName: "BackgroundConfig.wallpaper-change-interval-min";
                    icon: "timer"
                    text: Translation.tr("Wallpaper change interval (min)")
                    value: Config.options.wallpaperSelector.changeInterval / 60000
                    from: 0
                    to: 1440
                    stepSize: 5
                    onEdited: {
                        Config.options.wallpaperSelector.changeInterval = value * 60000;
                    }
                }

                ConfigComboBox {
                    objectName: "BackgroundConfig.transitions";
                    visible: page.settingsShow("widget-details");

                    Layout.fillWidth: true
                    buttonIcon: "texture"
                    text: Translation.tr("Transitions")
                    fieldWidth: 50
                    model: [
                        { displayName: Translation.tr("None"), icon: "block", value: "" },
                        { displayName: Translation.tr("Circle"), icon: "circle", value: "circleSelect" },
                        { displayName: Translation.tr("Circle Pit"), icon: "blur_circular", value: "circlePit" },
                        { displayName: Translation.tr("Magic"), icon: "auto_awesome", value: "magic" },
                        { displayName: Translation.tr("Doom"), icon: "whatshot", value: "Doom" },
                        { displayName: Translation.tr("Peel"), icon: "layers", value: "Peel" },
                        { displayName: Translation.tr("Fade"), icon: "gradient", value: "transition" },
                        { displayName: Translation.tr("Pixelate"), icon: "grain", value: "pixelate" },
                        { displayName: Translation.tr("Stripes"), icon: "texture_minus", value: "stripes" },
                        { displayName: Translation.tr("CRT"), icon: "tv", value: "crt" },
                        { displayName: Translation.tr("Dissolve"), icon: "blur_on", value: "dissolve" },
                        { displayName: Translation.tr("Glitch"), icon: "bug_report", value: "glitch" },
                        { displayName: Translation.tr("Ripple"), icon: "water", value: "ripple" },
                        { displayName: Translation.tr("Shatter"), icon: "broken_image", value: "shatter" },
                        { displayName: Translation.tr("Random"), icon: "shuffle", value: "random" },
                    ]
                    currentValue: Config.options.background.wallpaperAnimation
                    onSelected: newValue => {
                        Config.options.background.wallpaperAnimation = newValue;
                    }
                }
            }

            Connections {
                target: Config.options.background
                function onLockWallChanged() {
                    syncWallpaperSwitch.checked = Qt.binding(() => Config.options.background.lockWall === "")
                }
            }

            ContentSubsection {
                visible: page.settingsShow("widget-details");
                title: Translation.tr("Centered wallpaper")
                Layout.fillWidth: true

                GroupedList {
                    compact: true;
                    visible: page.settingsShow("widget-details")
                    ConfigSwitch {
                        visible: page.settingsShow("widget-details");
                        objectName: "BackgroundConfig.enable";
                        Layout.fillWidth: true
                        buttonIcon: "check"
                        text: Translation.tr("Enable")
                        checked: Config.options.background.centeredWallpaper
                        onClicked: {
                            Config.options.background.centeredWallpaper = !Config.options.background.centeredWallpaper;
                        }
                    }
                    ConfigSwitch {
                        visible: page.settingsShow("widget-details");
                        objectName: "BackgroundConfig.show-only-when-locked";
                        Layout.fillWidth: true
                        buttonIcon: "lock"
                        text: Translation.tr("Show only when locked")
                        checked: Config.options.background.centeredWallpaperOnlyWhenLocked
                        onEdited: {
                            Config.options.background.centeredWallpaperOnlyWhenLocked = checked;
                        }
                        enabled: Config.options.background.centeredWallpaper && WM.compositor !== "niri"
                    }
                }

                GroupedList {
                    compact: true;
                    Layout.topMargin: 0
                    visible: page.settingsShow("widget-details") && (Config.options.background.centeredWallpaper)
                    ConfigSelectionShapeArray {
                        objectName: "BackgroundConfig.centered-wallpaper-shape";
                        visible: page.settingsShow("widget-details");

                        currentValue: Config.options.background.centeredWallpaperShape
                        shapeColor: Appearance.colors.colPrimary
                        backgroundColor: Appearance.colors.colPrimaryContainer
                        options: [
                            "Circle", "Square", "Slanted", "Arch", "Arrow", "SemiCircle", "Oval", "Pill",
                            "Triangle", "Diamond", "ClamShell", "Pentagon", "Gem", "Sunny", "VerySunny",
                            "Cookie4Sided", "Cookie6Sided", "Cookie7Sided", "Cookie9Sided", "Cookie12Sided",
                            "Ghostish", "Clover4Leaf", "Clover8Leaf", "Burst", "SoftBurst", "Flower",
                            "Puffy", "PuffyDiamond", "PixelCircle", "Bun", "Heart"
                        ]
                        onSelected: newValue => {
                            Config.options.background.centeredWallpaperShape = newValue
                        }
                    }
                    ColorSelectionArray {
                        objectName: "BackgroundConfig.background-color";
                        visible: page.settingsShow("widget-details") && (Config.options.background.centeredWallpaper)
                        icon: "palette"
                        text: Translation.tr("Background Color")
                        currentValue: Config.options.background.centeredWallpaperColor
                        onSelected: newValue => {
                            Config.options.background.centeredWallpaperColor = newValue
                        }
                    }
                    ConfigSlider {
                        objectName: "BackgroundConfig.size";
                        visible: page.settingsShow("widget-details") && (Config.options.background.centeredWallpaper)
                        text: Translation.tr("Size")
                        value: Config.options.background.centeredWallpaperSize
                        usePercentTooltip: false
                        buttonIcon: "aspect_ratio"
                        from: 400
                        to: 800
                        stopIndicatorValues: [400]
                        onEdited: {
                            Config.options.background.centeredWallpaperSize = value;
                        }
                    }
                }
            }
        }

        ContentSection {
            visible: page.settingsShow("widget-details|widgets");
            icon: "widgets"
            shape: MaterialShape.Shape.Pill
            title: Translation.tr("Widgets")

            ContentSubsection {
                title: Translation.tr("Show widgets on")
                visible: page.settingsShow("widgets") && (Hyprland.monitors.values.length > 1)
                Layout.bottomMargin: 10

                WidgetsMonitorSelector {
                    visible: page.settingsShow("widgets");
                    objectName: "BackgroundConfig.show-widgets-on";
                    configEntry: Config.options.background
                }
            }

            WidgetsSubmenu {
                visible: page.settingsShow("widgets");
                objectName: "BackgroundConfig.choose-where-each-widget-appears";
                Layout.fillWidth: true
            }

            ContentSubsection {
                title: Translation.tr("Visualizer")
                visible: page.settingsShow("widget-details") && ((GlobalStates.widgetShown("visualizer", false) || GlobalStates.widgetShown("visualizer", true)))

                GroupedList {
                    compact: true;
                    visible: page.settingsShow("widget-details")
                    RippleButton {
                        visible: page.settingsShow("widget-details");
                        objectName: "BackgroundConfig.visualizer";
                        Layout.fillWidth: true
                        implicitHeight: 42
                        buttonRadius: Appearance.rounding.normal
                        colBackground: Appearance.colors.colLayer1
                        colBackgroundHover: Appearance.colors.colLayer1Hover
                        onClicked: page.resetPrimaryVisualizer()
                        contentItem: RowLayout {
                            spacing: 10
                            MaterialSymbol {
                                text: "restart_alt"
                                iconSize: Appearance.font.pixelSize.large
                                color: Appearance.colors.colPrimary
                            }
                            StyledText {
                                Layout.fillWidth: true
                                text: Translation.tr("Reset visualizer settings")
                                color: Appearance.colors.colOnLayer1
                            }
                        }
                    }
                    ConfigSwitch {
                        visible: page.settingsShow("widget-details");
                        objectName: "BackgroundConfig.pause-while-a-window-covers-the-desktop";
                        Layout.fillWidth: true
                        buttonIcon: "energy_savings_leaf"
                        text: Translation.tr("Pause while a window covers the desktop")
                        checked: Config.options.background.widgets.visualizer.hideWhenObscured
                        onEdited: {
                            Config.options.background.widgets.visualizer.hideWhenObscured = checked;
                        }
                    }
                    ConfigSpinBox {
                        visible: page.settingsShow("widget-details");
                        objectName: "BackgroundConfig.width";
                        icon: "width"
                        text: Translation.tr("Width")
                        value: Config.options.background.widgets.visualizer.width
                        from: 240; to: 1920; stepSize: 20
                        onEdited: Config.options.background.widgets.visualizer.width = value
                    }
                    ConfigSpinBox {
                        visible: page.settingsShow("widget-details");
                        objectName: "BackgroundConfig.maximum-height";
                        icon: "height"
                        text: Translation.tr("Maximum height")
                        value: Config.options.background.widgets.visualizer.height
                        from: 80; to: 600; stepSize: 10
                        onEdited: Config.options.background.widgets.visualizer.height = value
                    }
                    ConfigSpinBox {
                        visible: page.settingsShow("widget-details");
                        objectName: "BackgroundConfig.frequency-bands";
                        icon: "equalizer"
                        text: Translation.tr("Frequency bands")
                        value: Config.options.background.widgets.visualizer.barCount
                        from: 8; to: 64; stepSize: 2
                        onEdited: Config.options.background.widgets.visualizer.barCount = value
                    }
                    ConfigSlider {
                        visible: page.settingsShow("widget-details");
                        objectName: "BackgroundConfig.noise-gate";
                        buttonIcon: "noise_aware"
                        text: Translation.tr("Noise gate")
                        value: Config.options.background.widgets.visualizer.noiseFloor
                        from: 0; to: 10
                        onEdited: Config.options.background.widgets.visualizer.noiseFloor = value
                    }
                    ConfigSlider {
                        visible: page.settingsShow("widget-details");
                        objectName: "BackgroundConfig.rise-response";
                        buttonIcon: "speed"
                        text: Translation.tr("Rise response")
                        value: Config.options.background.widgets.visualizer.attack * 100
                        from: 10; to: 100
                        onEdited: Config.options.background.widgets.visualizer.attack = value / 100
                    }
                    ConfigSlider {
                        visible: page.settingsShow("widget-details");
                        objectName: "BackgroundConfig.fall-response";
                        buttonIcon: "south"
                        text: Translation.tr("Fall response")
                        value: Config.options.background.widgets.visualizer.release * 100
                        from: 5; to: 100
                        onEdited: Config.options.background.widgets.visualizer.release = value / 100
                    }
                    StyledText {
                        property bool groupDescription: true;
                        visible: page.settingsShow("widget-details");
                        Layout.fillWidth: true
                        wrapMode: Text.Wrap
                        color: Appearance.colors.colSubtext
                        font.pixelSize: Appearance.font.pixelSize.small
                        text: Translation.tr("The visualizer redraws on every audio frame and keeps cava capturing, so it is the most expensive thing on the desktop. With this on, it is torn down completely on any screen whose active workspace holds a tiled or fullscreen window - and cava stops once no screen is showing one. Floating windows don't count, since the desktop stays visible around them. Each screen is judged on its own: a window on one monitor never stops the visualizer on another.")
                    }
                }
            }
            ContentSubsection {
                title: Translation.tr("Full monitor visualizer")
                visible: page.settingsShow("widget-details") && ((GlobalStates.widgetShown("fullMonitorVisualizer", false) || GlobalStates.widgetShown("fullMonitorVisualizer", true)))

                GroupedList {
                    compact: true;
                    visible: page.settingsShow("widget-details")
                    ConfigSwitch {
                        visible: page.settingsShow("widget-details");
                        objectName: "BackgroundConfig.pause-while-a-window-covers-the-desktop-2";
                        buttonIcon: "energy_savings_leaf"
                        text: Translation.tr("Pause while a window covers the desktop")
                        checked: Config.options.background.widgets.fullMonitorVisualizer.hideWhenObscured
                        onEdited: Config.options.background.widgets.fullMonitorVisualizer.hideWhenObscured = checked
                    }
                    ConfigSpinBox {
                        visible: page.settingsShow("widget-details");
                        objectName: "BackgroundConfig.maximum-height-2";
                        icon: "height"
                        text: Translation.tr("Maximum height")
                        value: Config.options.background.widgets.fullMonitorVisualizer.height
                        from: 40; to: 800; stepSize: 10
                        onEdited: Config.options.background.widgets.fullMonitorVisualizer.height = value
                    }
                    ConfigSpinBox {
                        visible: page.settingsShow("widget-details");
                        objectName: "BackgroundConfig.bar-width";
                        icon: "width"
                        text: Translation.tr("Bar width")
                        value: Config.options.background.widgets.fullMonitorVisualizer.barWidth
                        from: 2; to: 16; stepSize: 1
                        onEdited: Config.options.background.widgets.fullMonitorVisualizer.barWidth = value
                    }
                    ConfigSpinBox {
                        visible: page.settingsShow("widget-details");
                        objectName: "BackgroundConfig.bar-spacing";
                        icon: "space_bar"
                        text: Translation.tr("Bar spacing")
                        value: Config.options.background.widgets.fullMonitorVisualizer.spacing
                        from: 0; to: 24; stepSize: 1
                        onEdited: Config.options.background.widgets.fullMonitorVisualizer.spacing = value
                    }
                    ConfigSpinBox {
                        visible: page.settingsShow("widget-details");
                        objectName: "BackgroundConfig.smoothing-duration";
                        icon: "animation"
                        text: Translation.tr("Smoothing duration")
                        value: Config.options.background.widgets.fullMonitorVisualizer.smoothingDuration
                        from: 0; to: 500; stepSize: 10
                        onEdited: Config.options.background.widgets.fullMonitorVisualizer.smoothingDuration = value
                    }
                    StyledText {
                        property bool groupDescription: true;
                        visible: page.settingsShow("widget-details");
                        Layout.fillWidth: true
                        wrapMode: Text.Wrap
                        color: Appearance.colors.colSubtext
                        font.pixelSize: Appearance.font.pixelSize.small
                        text: Translation.tr("The classic full-width end4 spectrum. It is attached to the bottom of every eligible monitor and is not a draggable canvas widget.")
                    }
                }
            }
            ContentSubsection {
                title: Translation.tr("Mirrored visualizer")
                visible: page.settingsShow("widget-details") && ((GlobalStates.widgetShown("visualizerMirror", false) || GlobalStates.widgetShown("visualizerMirror", true)))

                GroupedList {
                    compact: true;
                    visible: page.settingsShow("widget-details")
                    ConfigSwitch {
                        visible: page.settingsShow("widget-details");
                        objectName: "BackgroundConfig.pause-while-a-window-covers-the-desktop-3";
                        buttonIcon: "energy_savings_leaf"
                        text: Translation.tr("Pause while a window covers the desktop")
                        checked: Config.options.background.widgets.visualizerMirror.hideWhenObscured
                        onEdited: Config.options.background.widgets.visualizerMirror.hideWhenObscured = checked
                    }
                    ConfigSpinBox {
                        visible: page.settingsShow("widget-details");
                        objectName: "BackgroundConfig.width-2";
                        icon: "width"
                        text: Translation.tr("Width")
                        value: Config.options.background.widgets.visualizerMirror.width
                        from: 240; to: 1920; stepSize: 20
                        onEdited: Config.options.background.widgets.visualizerMirror.width = value
                    }
                    ConfigSpinBox {
                        visible: page.settingsShow("widget-details");
                        objectName: "BackgroundConfig.total-height";
                        icon: "height"
                        text: Translation.tr("Total height")
                        value: Config.options.background.widgets.visualizerMirror.height
                        from: 100; to: 800; stepSize: 10
                        onEdited: Config.options.background.widgets.visualizerMirror.height = value
                    }
                    ConfigSpinBox {
                        visible: page.settingsShow("widget-details");
                        objectName: "BackgroundConfig.frequency-bands-2";
                        icon: "equalizer"
                        text: Translation.tr("Frequency bands")
                        value: Config.options.background.widgets.visualizerMirror.barCount
                        from: 8; to: 64; stepSize: 2
                        onEdited: Config.options.background.widgets.visualizerMirror.barCount = value
                    }
                    ConfigSlider {
                        visible: page.settingsShow("widget-details");
                        objectName: "BackgroundConfig.noise-gate-2";
                        buttonIcon: "noise_aware"
                        text: Translation.tr("Noise gate")
                        value: Config.options.background.widgets.visualizerMirror.noiseFloor
                        from: 0; to: 10
                        onEdited: Config.options.background.widgets.visualizerMirror.noiseFloor = value
                    }
                    ConfigSlider {
                        visible: page.settingsShow("widget-details");
                        objectName: "BackgroundConfig.rise-response-2";
                        buttonIcon: "speed"
                        text: Translation.tr("Rise response")
                        value: Config.options.background.widgets.visualizerMirror.attack * 100
                        from: 10; to: 100
                        onEdited: Config.options.background.widgets.visualizerMirror.attack = value / 100
                    }
                    ConfigSlider {
                        visible: page.settingsShow("widget-details");
                        objectName: "BackgroundConfig.fall-response-2";
                        buttonIcon: "south"
                        text: Translation.tr("Fall response")
                        value: Config.options.background.widgets.visualizerMirror.release * 100
                        from: 5; to: 100
                        onEdited: Config.options.background.widgets.visualizerMirror.release = value / 100
                    }
                    StyledText {
                        property bool groupDescription: true;
                        visible: page.settingsShow("widget-details");
                        Layout.fillWidth: true
                        wrapMode: Text.Wrap
                        color: Appearance.colors.colSubtext
                        font.pixelSize: Appearance.font.pixelSize.small
                        text: Translation.tr("This spectrum grows above and below its center line. Unlock desktop widgets, then drag it anywhere on the canvas; its position is saved like the other widgets.")
                    }
                }
            }
            ContentSubsection {
                visible: page.settingsShow("widgets");
                title: Translation.tr("Canvas")
                Layout.bottomMargin: 10

                GroupedList {
                    compact: true;
                    visible: page.settingsShow("widgets")
                    ConfigSwitch {
                        visible: page.settingsShow("widgets");
                        objectName: "BackgroundConfig.show-alignment-grid-while-dragging";
                        Layout.fillWidth: true
                        buttonIcon: "grid_4x4"
                        text: Translation.tr("Show alignment grid while dragging")
                        checked: Config.options.background.showGrid
                        onEdited: {
                            Config.options.background.showGrid = checked;
                        }
                    }
                    ConfigSwitch {
                        visible: page.settingsShow("widgets");
                        objectName: "BackgroundConfig.show-snap-lines-when-dropping";
                        Layout.fillWidth: true
                        buttonIcon: "align_horizontal_center"
                        text: Translation.tr("Show snap lines when dropping")
                        checked: Config.options.background.showSnapLines
                        onEdited: {
                            Config.options.background.showSnapLines = checked;
                        }
                    }
                }
            }
        }

        ContentSection {
            visible: page.settingsShow("widget-details|widgets");
            id: settingsClock
            icon: "clock_loader_40"
            shape: MaterialShape.Shape.Bun
            title: Translation.tr("Clock")

            function stylePresent(styleName) {
                if (!Config.options.background.widgets.clock.showOnlyWhenLocked && Config.options.background.widgets.clock.style === styleName) {
                    return true;
                }
                if (Config.options.background.widgets.clock.styleLocked === styleName) {
                    return true;
                }
                return false;
            }

            readonly property bool digitalPresent: stylePresent("digital")
            readonly property bool cookiePresent: stylePresent("cookie")

            GroupedList {
                compact: true;
                visible: page.settingsShow("widget-details|widgets")



                ConfigSelectionArray {
                    visible: page.settingsShow("widget-details");
                    objectName: "BackgroundConfig.placement-strategy";
                    text: Translation.tr("Placement strategy")
                    icon: "move"
                    Layout.fillWidth: false
                    currentValue: Config.options.background.widgets.clock.placementStrategy
                    onSelected: newValue => {
                        Config.options.background.widgets.clock.placementStrategy = newValue;
                    }
                    options: [
                        {
                            displayName: Translation.tr("Draggable"),
                            icon: "drag_pan",
                            value: "free"
                        },
                        {
                            displayName: Translation.tr("Least busy"),
                            icon: "category",
                            value: "leastBusy"
                        },
                        {
                            displayName: Translation.tr("Most busy"),
                            icon: "shapes",
                            value: "mostBusy"
                        },
                    ]
                }
                ConfigSelectionArray {
                    visible: page.settingsShow("widgets");
                    objectName: "BackgroundConfig.clock-style";
                    text: Translation.tr("Clock style")
                    icon: "nest_clock_farsight_analog"
                    currentValue: Config.options.background.widgets.clock.style
                    onSelected: newValue => {
                        Config.options.background.widgets.clock.style = newValue;
                    }
                    options: [
                        {
                            displayName: Translation.tr("Digital"),
                            icon: "timer_10",
                            value: "digital"
                        },
                        {
                            displayName: Translation.tr("Cookie"),
                            icon: "cookie",
                            value: "cookie"
                        },
                        {
                            displayName: Translation.tr("Pixel"),
                            icon: "grid_view",
                            value: "pixel"
                        }
                    ]
                }
                ConfigSelectionArray {
                    visible: page.settingsShow("widgets");
                    objectName: "BackgroundConfig.clock-style-locked";
                    text: Translation.tr("Clock style (locked)")
                    icon: "shield_watch"
                    currentValue: Config.options.background.widgets.clock.styleLocked
                    onSelected: newValue => {
                        Config.options.background.widgets.clock.styleLocked = newValue;
                    }
                    options: [
                        {
                            displayName: Translation.tr("Digital"),
                            icon: "timer_10",
                            value: "digital"
                        },
                        {
                            displayName: Translation.tr("Cookie"),
                            icon: "cookie",
                            value: "cookie"
                        },
                        {
                            displayName: Translation.tr("Pixel"),
                            icon: "grid_view",
                            value: "pixel"
                        }
                    ]
                }
            }

            ContentSubsection {
                visible: page.settingsShow("widget-details|widgets") && (settingsClock.digitalPresent)
                title: Translation.tr("Digital clock settings")

                ConfigRow {
                    visible: page.settingsShow("widget-details|widgets");
                    uniform: true

                    GroupedList {
                        compact: true;
                        visible: page.settingsShow("widgets")
                        ConfigSwitch {
                            visible: page.settingsShow("widgets");
                            objectName: "BackgroundConfig.vertical";
                            buttonIcon: "vertical_distribute"
                            text: Translation.tr("Vertical")
                            checked: Config.options.background.widgets.clock.digital.vertical
                            onEdited: { Config.options.background.widgets.clock.digital.vertical = checked }
                        }
                        ConfigSwitch {
                            visible: page.settingsShow("widgets");
                            objectName: "BackgroundConfig.show-date";
                            buttonIcon: "date_range"
                            text: Translation.tr("Show date")
                            checked: Config.options.background.widgets.clock.digital.showDate
                            onEdited: { Config.options.background.widgets.clock.digital.showDate = checked }
                        }
                    }

                    GroupedList {
                        compact: true;
                        visible: page.settingsShow("widget-details")
                        ConfigSwitch {
                            visible: page.settingsShow("widget-details");
                            objectName: "BackgroundConfig.animate-time-change";
                            buttonIcon: "animation"
                            text: Translation.tr("Animate time change")
                            checked: Config.options.background.widgets.clock.digital.animateChange
                            onEdited: { Config.options.background.widgets.clock.digital.animateChange = checked }
                        }
                        ConfigSwitch {
                            visible: page.settingsShow("widget-details");
                            objectName: "BackgroundConfig.use-adaptive-alignment";
                            buttonIcon: "activity_zone"
                            text: Translation.tr("Use adaptive alignment")
                            checked: Config.options.background.widgets.clock.digital.adaptiveAlignment
                            onEdited: { Config.options.background.widgets.clock.digital.adaptiveAlignment = checked }
                        }
                    }
                }

                GroupedList {
                    compact: true;
                    visible: page.settingsShow("widgets")
                    ConfigSwitch {
                        visible: page.settingsShow("widgets");
                        objectName: "BackgroundConfig.automatic-colors";
                        id: autoColorSwitch
                        buttonIcon: "auto_awesome"
                        text: Translation.tr("Automatic colors")
                        checked: Config.options.background.widgets.clock.color === ""
                        onEdited: {
                            if (checked) {
                                Config.options.background.widgets.clock.color = ""
                            }
                        }
                    }

                    ColorSelectionArray {
                        visible: page.settingsShow("widgets");
                        objectName: "BackgroundConfig.color";
                        icon: "palette"
                        text: Translation.tr("Color")
                        currentValue: Config.options.background.widgets.clock.color
                        onSelected: newValue => {
                            Config.options.background.widgets.clock.color = newValue
                            autoColorSwitch.checked = false
                        }
                    }
                }

                MaterialTextArea {
                    visible: page.settingsShow("widgets");
                    objectName: "BackgroundConfig.font-family";
                    Layout.fillWidth: true
                    placeholderText: Translation.tr("Font family")
                    text: Config.options.background.widgets.clock.digital.font.family
                    wrapMode: TextEdit.Wrap

                    Timer {
                        id: debounceTimer
                        interval: 500
                        repeat: false
                        onTriggered: {
                            Config.options.background.widgets.clock.digital.font.family = parent.text
                        }
                    }

                    onTextChanged: {
                    if (!activeFocus) return
                        debounceTimer.restart()
                    }
                }
                GroupedList {
                    compact: true;
                    visible: page.settingsShow("widget-details|widgets");
                    Layout.topMargin: 10
                    ConfigSlider {
                        visible: page.settingsShow("widget-details");
                        objectName: "BackgroundConfig.font-weight";
                        text: Translation.tr("Font weight")
                        value: Config.options.background.widgets.clock.digital.font.weight
                        usePercentTooltip: false
                        buttonIcon: "format_bold"
                        from: 1
                        to: 1000
                        stopIndicatorValues: [350]
                        onEdited: {
                            Config.options.background.widgets.clock.digital.font.weight = value;
                        }
                    }

                    ConfigSlider {
                        visible: page.settingsShow("widgets");
                        objectName: "BackgroundConfig.font-size";
                        text: Translation.tr("Font size")
                        value: Config.options.background.widgets.clock.digital.font.size
                        usePercentTooltip: false
                        buttonIcon: "format_size"
                        from: 50
                        to: 700
                        stopIndicatorValues: [90]
                        onEdited: {
                            Config.options.background.widgets.clock.digital.font.size = value;
                        }
                    }

                    ConfigSlider {
                        visible: page.settingsShow("widget-details");
                        objectName: "BackgroundConfig.font-width";
                        text: Translation.tr("Font width")
                        value: Config.options.background.widgets.clock.digital.font.width
                        usePercentTooltip: false
                        buttonIcon: "fit_width"
                        from: 25
                        to: 125
                        stopIndicatorValues: [100]
                        onEdited: {
                            Config.options.background.widgets.clock.digital.font.width = value;
                        }
                    }
                    ConfigSlider {
                        visible: page.settingsShow("widget-details");
                        objectName: "BackgroundConfig.font-roundness";
                        text: Translation.tr("Font roundness")
                        value: Config.options.background.widgets.clock.digital.font.roundness
                        usePercentTooltip: false
                        buttonIcon: "line_curve"
                        from: 0
                        to: 100
                        onEdited: {
                            Config.options.background.widgets.clock.digital.font.roundness = value;
                        }
                    }
                }
            }

            ContentSubsection {
                visible: page.settingsShow("widget-details") && (settingsClock.cookiePresent)
                title: Translation.tr("Cookie clock settings")
                GroupedList {
                    compact: true;
                    visible: page.settingsShow("widget-details")
                    ConfigSwitch {
                        visible: page.settingsShow("widget-details");
                        objectName: "BackgroundConfig.auto-styling-with-gemini";
                        buttonIcon: "wand_stars"
                        text: Translation.tr("Auto styling with Gemini")
                        checked: Config.options.background.widgets.clock.cookie.aiStyling
                        onEdited: {
                            Config.options.background.widgets.clock.cookie.aiStyling = checked;
                        }
                    }

                    ConfigSwitch {
                        visible: page.settingsShow("widget-details");
                        objectName: "BackgroundConfig.use-old-sine-wave-cookie-implementation";
                        buttonIcon: "airwave"
                        text: Translation.tr("Use old sine wave cookie implementation")
                        checked: Config.options.background.widgets.clock.cookie.useSineCookie
                        onEdited: {
                            Config.options.background.widgets.clock.cookie.useSineCookie = checked;
                        }
                    }

                    ConfigSpinBox {
                        visible: page.settingsShow("widget-details");
                        objectName: "BackgroundConfig.sides";
                        icon: "add_triangle"
                        text: Translation.tr("Sides")
                        value: Config.options.background.widgets.clock.cookie.sides
                        from: 0
                        to: 40
                        stepSize: 1
                        onEdited: {
                            Config.options.background.widgets.clock.cookie.sides = value;
                        }
                    }

                    ConfigSwitch {
                        visible: page.settingsShow("widget-details");
                        objectName: "BackgroundConfig.constantly-rotate";
                        buttonIcon: "autoplay"
                        text: Translation.tr("Constantly rotate")
                        checked: Config.options.background.widgets.clock.cookie.constantlyRotate
                        onEdited: {
                            Config.options.background.widgets.clock.cookie.constantlyRotate = checked;
                        }
                    }

                    ConfigRow {
                        visible: page.settingsShow("widget-details")

                        ConfigSwitch {
                            visible: page.settingsShow("widget-details");
                            objectName: "BackgroundConfig.hour-marks";
                            enabled: Config.options.background.widgets.clock.cookie.dialNumberStyle === "dots" || Config.options.background.widgets.clock.cookie.dialNumberStyle === "full"
                            buttonIcon: "brightness_7"
                            text: Translation.tr("Hour marks")
                            checked: Config.options.background.widgets.clock.cookie.hourMarks
                            onEnabledChanged: {
                                checked = Config.options.background.widgets.clock.cookie.hourMarks;
                            }
                            onEdited: {
                                Config.options.background.widgets.clock.cookie.hourMarks = checked;
                            }
                        }

                        ConfigSwitch {
                            visible: page.settingsShow("widget-details");
                            objectName: "BackgroundConfig.digits-in-the-middle";
                            enabled: Config.options.background.widgets.clock.cookie.dialNumberStyle !== "numbers"
                            buttonIcon: "timer_10"
                            text: Translation.tr("Digits in the middle")
                            checked: Config.options.background.widgets.clock.cookie.timeIndicators
                            onEnabledChanged: {
                                checked = Config.options.background.widgets.clock.cookie.timeIndicators;
                            }
                            onEdited: {
                                Config.options.background.widgets.clock.cookie.timeIndicators = checked;
                            }
                        }
                    }
                }
            }

            GroupedList {
                compact: true;
                Layout.topMargin: 10
                visible: page.settingsShow("widget-details") && (settingsClock.cookiePresent)
                ConfigSelectionArray {
                    visible: page.settingsShow("widget-details");
                    objectName: "BackgroundConfig.clock";
                    text: "Dial Style"
                    icon: "graph_6"
                    currentValue: Config.options.background.widgets.clock.cookie.dialNumberStyle
                    onSelected: newValue => {
                        Config.options.background.widgets.clock.cookie.dialNumberStyle = newValue;
                        if (newValue !== "dots" && newValue !== "full") {
                            Config.options.background.widgets.clock.cookie.hourMarks = false;
                        }
                        if (newValue === "numbers") {
                            Config.options.background.widgets.clock.cookie.timeIndicators = false;
                        }
                    }
                    options: [
                        {
                            displayName: "",
                            icon: "block",
                            value: "none"
                        },
                        {
                            displayName: Translation.tr("Dots"),
                            icon: "graph_6",
                            value: "dots"
                        },
                        {
                            displayName: Translation.tr("Full"),
                            icon: "history_toggle_off",
                            value: "full"
                        },
                        {
                            displayName: Translation.tr("Numbers"),
                            icon: "counter_1",
                            value: "numbers"
                        }
                    ]
                }
                ConfigSelectionArray {
                    visible: page.settingsShow("widget-details");
                    objectName: "BackgroundConfig.hour-hand";
                    icon: "highlighter_size_2"
                    text: Translation.tr("Hour hand")
                    currentValue: Config.options.background.widgets.clock.cookie.hourHandStyle
                    onSelected: newValue => {
                        Config.options.background.widgets.clock.cookie.hourHandStyle = newValue;
                    }
                    options: [
                        {
                            displayName: "",
                            icon: "block",
                            value: "hide"
                        },
                        {
                            displayName: Translation.tr("Classic"),
                            icon: "radio",
                            value: "classic"
                        },
                        {
                            displayName: Translation.tr("Hollow"),
                            icon: "circle",
                            value: "hollow"
                        },
                        {
                            displayName: Translation.tr("Fill"),
                            icon: "eraser_size_5",
                            value: "fill"
                        },
                    ]
                }
                ConfigSelectionArray {
                    visible: page.settingsShow("widget-details");
                    objectName: "BackgroundConfig.minute-hand";
                    text: Translation.tr("Minute hand")
                    icon: "eraser_size_1"
                    currentValue: Config.options.background.widgets.clock.cookie.minuteHandStyle
                    onSelected: newValue => {
                        Config.options.background.widgets.clock.cookie.minuteHandStyle = newValue;
                    }
                    options: [
                        {
                            displayName: "",
                            icon: "block",
                            value: "hide"
                        },
                        {
                            displayName: Translation.tr("Classic"),
                            icon: "radio",
                            value: "classic"
                        },
                        {
                            displayName: Translation.tr("Thin"),
                            icon: "line_end",
                            value: "thin"
                        },
                        {
                            displayName: Translation.tr("Medium"),
                            icon: "eraser_size_2",
                            value: "medium"
                        },
                        {
                            displayName: Translation.tr("Bold"),
                            icon: "eraser_size_4",
                            value: "bold"
                        },
                    ]
                }
                ConfigSelectionArray {
                    visible: page.settingsShow("widget-details");
                    objectName: "BackgroundConfig.second-hand";
                    text: Translation.tr("Second hand")
                    icon: "pen_size_1"
                    currentValue: Config.options.background.widgets.clock.cookie.secondHandStyle
                    onSelected: newValue => {
                        Config.options.background.widgets.clock.cookie.secondHandStyle = newValue;
                    }
                    options: [
                        {
                            displayName: "",
                            icon: "block",
                            value: "hide"
                        },
                        {
                            displayName: Translation.tr("Classic"),
                            icon: "radio",
                            value: "classic"
                        },
                        {
                            displayName: Translation.tr("Line"),
                            icon: "line_end",
                            value: "line"
                        },
                        {
                            displayName: Translation.tr("Dot"),
                            icon: "adjust",
                            value: "dot"
                        },
                    ]
                }
                ConfigSelectionArray {
                    visible: page.settingsShow("widget-details");
                    objectName: "BackgroundConfig.date-style";
                    text: Translation.tr("Date style")
                    icon: "date_range"
                    currentValue: Config.options.background.widgets.clock.cookie.dateStyle
                    onSelected: newValue => {
                        Config.options.background.widgets.clock.cookie.dateStyle = newValue;
                    }
                    options: [
                        {
                            displayName: "",
                            icon: "block",
                            value: "hide"
                        },
                        {
                            displayName: Translation.tr("Bubble"),
                            icon: "bubble_chart",
                            value: "bubble"
                        },
                        {
                            displayName: Translation.tr("Border"),
                            icon: "rotate_right",
                            value: "border"
                        },
                        {
                            displayName: Translation.tr("Rect"),
                            icon: "rectangle",
                            value: "rect"
                        }
                    ]
                }
            }

            ContentSubsection {
                visible: page.settingsShow("widgets") && (Config.options.background.widgets.clock.style === "pixel")
                title: Translation.tr("Pixel Clock Settings")
                GroupedList {
                    compact: true;
                    visible: page.settingsShow("widgets") && (Config.options.background.widgets.clock.style === "pixel")
                    ConfigSelectionArray {
                        objectName: "BackgroundConfig.pixel-clock-orientation";
                        text: Translation.tr("Pixel clock orientation")
                        visible: page.settingsShow("widgets") && (Config.options.background.widgets.clock.style === "pixel")
                        icon: "screen_rotation"
                        currentValue: Config.options.background.widgets.clock.pixel.orientation
                        onSelected: newValue => {
                            Config.options.background.widgets.clock.pixel.orientation = newValue;
                        }
                        options: [
                            {
                                displayName: Translation.tr("Horizontal"),
                                icon: "swap_horiz",
                                value: "horizontal"
                            },
                            {
                                displayName: Translation.tr("Vertical"),
                                icon: "swap_vert",
                                value: "vertical"
                            }
                        ]
                    }
                }
            }

            ContentSubsection {
                visible: page.settingsShow("widgets");
                title: Translation.tr("Quote")
                GroupedList {
                    compact: true;
                    visible: page.settingsShow("widgets")

                    ConfigSwitch {
                        objectName: "BackgroundConfig.show-quote"
                        visible: page.settingsShow("widgets")
                        text: Translation.tr("Show quote")
                        buttonIcon: "format_quote"
                        checked: Config.options.background.widgets.clock.quote.enable
                        onEdited: Config.options.background.widgets.clock.quote.enable = checked
                    }
                    ConfigSwitch {
                        visible: page.settingsShow("widgets");
                        objectName: "BackgroundConfig.follow-clock-font";
                        buttonIcon: "font_download"
                        text: Translation.tr("Follow Clock Font")
                        enabled: Config.options.background.widgets.clock.style !== "pixel"
                        checked: Config.options.background.widgets.clock.quote.followClock
                        onEdited: {
                            Config.options.background.widgets.clock.quote.followClock = checked;
                        }
                    }
                    ConfigTextArea {
                        visible: page.settingsShow("widgets");
                        objectName: "BackgroundConfig.quote";
                        id: quoteField
                        Layout.fillWidth: true
                        fieldWidth: 300
                        buttonIcon: "format_quote"
                        text: Translation.tr("Quote")
                        placeholderText: Translation.tr("Quote")
                        value: Config.options.background.widgets.clock.quote.text
                        onEdited: {
                            quoteDebounceTimer.restart();
                        }

                        Timer {
                            id: quoteDebounceTimer
                            interval: 600
                            repeat: false
                            onTriggered: {
                                Config.options.background.widgets.clock.quote.text = quoteField.value;
                            }
                        }
                    }
                }
            }
        }

        ContentSection {
            visible: page.settingsShow("widgets");
            icon: "panorama"
            shape: MaterialShape.Shape.SoftBoom
            title: Translation.tr("Custom Image")
            GroupedList {
                compact: true;
                visible: page.settingsShow("widgets")

                ConfigSelectionShapeArray {
                    objectName: "BackgroundConfig.custom-image-shape";
                    visible: page.settingsShow("widgets");

                    currentValue: Config.options.background.widgets.customImage.shape
                    shapeColor: Appearance.colors.colPrimary
                    backgroundColor: Appearance.colors.colPrimaryContainer
                    options: [
                        "Circle", "Square", "Slanted", "Arch", "Arrow", "SemiCircle", "Oval", "Pill",
                        "Triangle", "Diamond", "ClamShell", "Pentagon", "Gem", "Sunny", "VerySunny",
                        "Cookie4Sided", "Cookie6Sided", "Cookie7Sided", "Cookie9Sided", "Cookie12Sided",
                        "Ghostish", "Clover4Leaf", "Clover8Leaf", "Burst", "SoftBurst", "Flower",
                        "Puffy", "PuffyDiamond", "PixelCircle", "Bun", "Heart"
                    ]
                    onSelected: newValue => {
                        Config.options.background.widgets.customImage.shape = newValue
                    }
                }
            }
        }


    }
}
