pragma ComponentBehavior: Bound

import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.widgets.widgetCanvas
import qs.modules.common.functions as CF
import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland

import qs.modules.ii.background.widgets
import qs.modules.ii.background.widgets.clock
import qs.modules.ii.background.widgets.weather
import qs.modules.ii.background.widgets.media
import qs.modules.ii.background.widgets.images
import qs.modules.ii.background.widgets.resources
import qs.modules.ii.background.widgets.networkInfo
import qs.modules.ii.background.widgets.systemHistory
import qs.modules.ii.background.widgets.uptime
import qs.modules.ii.background.widgets.visualizer
import qs.modules.ii.background.widgets.calendar
import qs.modules.ii.background.widgets.worldclock
import qs.modules.ii.background.widgets.usercard
import qs.modules.ii.background.widgets.notes
import qs.modules.ii.background.widgets.todo
import qs.modules.ii.background.widgets.timers
import qs.modules.ii.bar as Bar
import Quickshell.Services.SystemTray

Variants {
    id: root
    model: Quickshell.screens

    function getShapeFromName(name) {
        switch (name) {
            case "Circle":        return MaterialShape.Shape.Circle
            case "Square":        return MaterialShape.Shape.Square
            case "Slanted":       return MaterialShape.Shape.Slanted
            case "Arch":          return MaterialShape.Shape.Arch
            case "Fan":           return MaterialShape.Shape.Fan
            case "Arrow":         return MaterialShape.Shape.Arrow
            case "SemiCircle":    return MaterialShape.Shape.SemiCircle
            case "Oval":          return MaterialShape.Shape.Oval
            case "Pill":          return MaterialShape.Shape.Pill
            case "Triangle":      return MaterialShape.Shape.Triangle
            case "Diamond":       return MaterialShape.Shape.Diamond
            case "ClamShell":     return MaterialShape.Shape.ClamShell
            case "Pentagon":      return MaterialShape.Shape.Pentagon
            case "Gem":           return MaterialShape.Shape.Gem
            case "Sunny":         return MaterialShape.Shape.Sunny
            case "VerySunny":     return MaterialShape.Shape.VerySunny
            case "Cookie4Sided":  return MaterialShape.Shape.Cookie4Sided
            case "Cookie6Sided":  return MaterialShape.Shape.Cookie6Sided
            case "Cookie7Sided":  return MaterialShape.Shape.Cookie7Sided
            case "Cookie9Sided":  return MaterialShape.Shape.Cookie9Sided
            case "Cookie12Sided": return MaterialShape.Shape.Cookie12Sided
            case "Ghostish":      return MaterialShape.Shape.Ghostish
            case "Clover4Leaf":   return MaterialShape.Shape.Clover4Leaf
            case "Clover8Leaf":   return MaterialShape.Shape.Clover8Leaf
            case "Burst":         return MaterialShape.Shape.Burst
            case "SoftBurst":     return MaterialShape.Shape.SoftBurst
            case "Boom":          return MaterialShape.Shape.Boom
            case "SoftBoom":      return MaterialShape.Shape.SoftBoom
            case "Flower":        return MaterialShape.Shape.Flower
            case "Puffy":         return MaterialShape.Shape.Puffy
            case "PuffyDiamond":  return MaterialShape.Shape.PuffyDiamond
            case "PixelCircle":   return MaterialShape.Shape.PixelCircle
            case "PixelTriangle": return MaterialShape.Shape.PixelTriangle
            case "Bun":           return MaterialShape.Shape.Bun
            case "Heart":         return MaterialShape.Shape.Heart
            default:              return MaterialShape.Shape.Cookie7Sided
        }
    }

    function getColorFromName(name) {
        switch (name) {
            case "primary":            return Appearance.colors.colPrimary
            case "secondary":          return Appearance.colors.colSecondary
            case "tertiary":           return Appearance.colors.colTertiary
            case "primaryContainer":   return Appearance.colors.colPrimaryContainer
            case "secondaryContainer": return Appearance.colors.colSecondaryContainer
            case "tertiaryContainer":  return Appearance.colors.colTertiaryContainer
            case "layer0":             return Appearance.colors.colLayer0
            case "layer1":             return Appearance.colors.colLayer1
            default:                  return Appearance.colors.colPrimaryContainer
        }
    }

    PanelWindow {
        id: bgRoot

        required property var modelData
        property string currentWallpaperSource: Config.options.background.wallpaperPath
        property string previousWallpaperSource: Config.options.background.wallpaperPath
        property bool videoRevealed: false
        // Preview uses the same visual rules as a real lock screen without
        // taking a session lock or moving this layer above applications.
        readonly property bool lockPresentationActive: GlobalStates.screenLocked || GlobalStates.lockPreviewOpen

        readonly property real splitFraction: {
            switch (Config.options.background.splitRatio) {
                case "25": return 0.28
                case "50": return 0.54
                default:   return 1.0
            }
        }
        readonly property bool overviewBlurActive: Config.options.overview.style === "niri" && GlobalStates.overviewOpen && Config.options.overview.enable
        readonly property bool userBlurActive: Config.options.background.showBlur && !bgRoot.wallpaperIsVideo
        readonly property bool blurFullScreen: bgRoot.overviewBlurActive || bgRoot.splitFraction >= 1.0

        //centered Wallpaper
        property bool centeredWallpaperEnabled: Config.options.background.centeredWallpaper && (!Config.options.background.centeredWallpaperOnlyWhenLocked || bgRoot.lockPresentationActive)
        property int centeredWallpaperShape: getShapeFromName(Config.options.background.centeredWallpaperShape)
        property int centeredWallpaperSize: Config.options.background.centeredWallpaperSize
        property color centeredWallpaperColor: root.getColorFromName(Config.options.background.centeredWallpaperColor)

        property var shaderList: ["circlePit", "circleSelect", "magic", "Doom", "Peel", "transition", "pixelate", "stripes", "crt", "dissolve", "glitch", "ripple", "shatter"]
        property string currentShader: "pixelate"
        property string wallpaperAnimation: Config.options.background.wallpaperAnimation ?? "random"

        // Fullscreen state comes from the active WM backend. This keeps the
        // wallpaper policy working on i3/X11 without constructing Hyprland
        // workspace objects there.
        readonly property var monitor: WM.monitorFor(modelData)
        readonly property bool activeWorkspaceWithFullscreen: WM.fullscreenOnMonitor(monitor?.name)
        visible: true

        readonly property bool hiddenForFullscreen: !bgRoot.lockPresentationActive
            && activeWorkspaceWithFullscreen
            && Config?.options.background.hideWhenFullscreen

        property string effectiveWallpaperPath: {
            if (bgRoot.lockPresentationActive && Config.options.background.lockWall !== "")
                return Config.options.background.lockWall;
            return Wallpapers.previewPath || Wallpapers.confirmedPath || Config.options.background.wallpaperPath;
        }

        property bool wallpaperIsVideo: bgRoot.effectiveWallpaperPath.endsWith(".mp4") || bgRoot.effectiveWallpaperPath.endsWith(".webm") || bgRoot.effectiveWallpaperPath.endsWith(".mkv") || bgRoot.effectiveWallpaperPath.endsWith(".avi") || bgRoot.effectiveWallpaperPath.endsWith(".mov")
        property string wallpaperPath: wallpaperIsVideo ? Config.options.background.thumbnailPath : bgRoot.effectiveWallpaperPath
        property bool wallpaperSafetyTriggered: {
            const enabled = Config.options.workSafety.enable.wallpaper;
            const sensitiveWallpaper = (CF.StringUtils.stringListContainsSubstring(wallpaperPath.toLowerCase(), Config.options.workSafety.triggerCondition.fileKeywords));
            const sensitiveNetwork = (CF.StringUtils.stringListContainsSubstring(Network.networkName.toLowerCase(), Config.options.workSafety.triggerCondition.networkNameKeywords));
            return enabled && sensitiveWallpaper && sensitiveNetwork;
        }

        property bool shouldBlur: (bgRoot.lockPresentationActive && Config.options.lock.blur.enable)
        property color dominantColor: Appearance.colors.colPrimary
        property bool dominantColorIsDark: dominantColor.hslLightness < 0.5
        property color colText: {
            if (wallpaperSafetyTriggered)
                return CF.ColorUtils.mix(Appearance.colors.colOnLayer0, Appearance.colors.colPrimary, 0.75);
            return (bgRoot.lockPresentationActive && shouldBlur) ? Appearance.colors.colOnLayer0 : CF.ColorUtils.colorWithLightness(Appearance.colors.colPrimary, (dominantColorIsDark ? 0.8 : 0.12));
        }
        Behavior on colText {
            animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
        }

        property real transitionProgress: 1.0

        screen: modelData
        exclusionMode: ExclusionMode.Ignore
        // See Bar.qml for why this is gated behind a Wayland-only Loader
        // instead of setting WlrLayershell.* directly: merely referencing it
        // forces attachment creation regardless of the value, which hard-fails
        // under i3/X11 and was taking the whole wallpaper surface down with it.
        Loader {
            active: WM.isWayland
            sourceComponent: Item {
                Binding {
                    target: bgRoot.WlrLayershell
                    property: "layer"
                    value: (bgRoot.lockPresentationActive && !scaleAnim.running) ? WlrLayer.Overlay : WlrLayer.Bottom
                }
                Binding {
                    target: bgRoot.WlrLayershell
                    property: "namespace"
                    value: "quickshell:background"
                }
                Binding {
                    target: bgRoot.WlrLayershell
                    property: "keyboardFocus"
                    value: GlobalStates.desktopWidgetKeyboardFocus
                        ? WlrKeyboardFocus.OnDemand
                        : WlrKeyboardFocus.None
                }
            }
        }
        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }
        color: {
            if (!bgRoot.wallpaperSafetyTriggered || bgRoot.wallpaperIsVideo)
                return "transparent";
            return CF.ColorUtils.mix(Appearance.colors.colLayer0, Appearance.colors.colPrimary, 0.75);
        }
        Behavior on color {
            animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
        }

        Component.onCompleted: {
            previousWallpaper.source = ""
            wallpaper.source = bgRoot.wallpaperSafetyTriggered ? "" : bgRoot.wallpaperPath
            bgRoot.currentWallpaperSource = bgRoot.wallpaperPath
            bgRoot.previousWallpaperSource = ""
            bgRoot.transitionProgress = 1.0
            if (bgRoot.wallpaperAnimation !== "") {
                bgRoot.currentShader = bgRoot.wallpaperAnimation === "random"
                    ? bgRoot.shaderList[Math.floor(Math.random() * bgRoot.shaderList.length)]
                    : bgRoot.wallpaperAnimation
            }
            bgRoot.videoRevealed = bgRoot.wallpaperIsVideo
        }

        onWallpaperPathChanged: {
            bgRoot.videoRevealed = false
            if (wallpaperSafetyTriggered) {
                previousWallpaper.source = ""
                wallpaper.source = ""
                bgRoot.transitionProgress = 1.0
                return
            }
            if (bgRoot.wallpaperAnimation === "") {
                wallpaper.source = wallpaperPath
                bgRoot.currentWallpaperSource = wallpaperPath
                if (!bgRoot.wallpaperIsVideo) return
                bgRoot.videoRevealed = true
                return
            }

            previousWallpaper.source = bgRoot.currentWallpaperSource
            wallpaper.source = wallpaperPath
            bgRoot.currentWallpaperSource = wallpaperPath
            if (bgRoot.wallpaperAnimation === "random") {
                bgRoot.currentShader = bgRoot.shaderList[Math.floor(Math.random() * bgRoot.shaderList.length)]
            } else {
                bgRoot.currentShader = bgRoot.wallpaperAnimation
            }
            bgRoot.transitionProgress = 0.0
        }

        NumberAnimation {
            id: transitionAnim
            target: bgRoot
            property: "transitionProgress"
            from: 0.0
            to: 1.0
            duration: 1200
            easing.type: Easing.InOutCubic
            onFinished: {
                previousWallpaper.source = ""
                bgRoot.previousWallpaperSource = ""
                bgRoot.transitionProgress = 1.0
                bgRoot.videoRevealed = bgRoot.wallpaperIsVideo
            }
        }

        Timer {
            id: wallpaperChangeTimer
            interval: Config.options.wallpaperSelector.changeInterval
            running: Config.options.wallpaperSelector.changeInterval > 0
            repeat: true
            onTriggered: {
                if (Wallpapers.folderModel.count > 0) {
                    Wallpapers.randomFromCurrentFolder()
                }
            }
        }

        Connections {
            target: GlobalStates
            function onScreenLockedChanged() {
                if (!GlobalStates.screenLocked) {
                    bgRoot.videoRevealed = bgRoot.wallpaperIsVideo
                }
            }
        }

        Item {
            anchors.fill: parent
            opacity: bgRoot.hiddenForFullscreen ? 0 : 1
            enabled: !bgRoot.hiddenForFullscreen
            
            Behavior on opacity {
                NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
            }

            Image {
                id: previousWallpaper
                anchors.fill: parent
                fillMode: Image.PreserveAspectCrop
                cache: true
                smooth: true
                asynchronous: true
                layer.enabled: true
                visible: false
                // Decode at output resolution instead of the wallpaper file's
                // native size - without this a large (e.g. 4K/8K) wallpaper is
                // fully decoded into memory at full resolution for no visual
                // benefit, since it's cropped down to screen size anyway.
                sourceSize.width: parent.width
                sourceSize.height: parent.height
            }

            StyledImage {
                id: wallpaper
                anchors.fill: parent
                fillMode: Image.PreserveAspectCrop
                cache: true
                smooth: true
                asynchronous: true
                layer.enabled: blurLoader.active
                visible: !blurLoader.active && !bgRoot.centeredWallpaperEnabled && !bgRoot.videoRevealed
                    && (bgRoot.wallpaperAnimation === "" || bgRoot.transitionProgress >= 1.0)
                sourceSize.width: parent.width
                sourceSize.height: parent.height
                onStatusChanged: {
                    if (status === Image.Ready && bgRoot.transitionProgress === 0.0) {
                        transitionAnim.restart()
                    }
                }
            }

            ShaderEffect {
                id: transitionEffect
                anchors.fill: parent
                layer.enabled: blurLoader.active
                visible: !blurLoader.active && !bgRoot.centeredWallpaperEnabled && !bgRoot.videoRevealed
                    && bgRoot.wallpaperAnimation !== "" && bgRoot.transitionProgress < 1.0

                property var fromImage: previousWallpaper
                property var toImage: wallpaper
                property var source1: previousWallpaper
                property var source2: wallpaper
                property real time: 0.0
                property real progress: bgRoot.transitionProgress
                property real aspectX: width / height
                property real aspectY: 1.0
                property vector2d aspectRatio: Qt.vector2d(aspectX, aspectY)
                property vector2d origin: Qt.vector2d(0.5, 0.5)

                fragmentShader: bgRoot.wallpaperAnimation !== ""
                    ? Qt.resolvedUrl(`shaders/${bgRoot.currentShader}.frag.qsb`)
                    : ""

                Timer {
                    interval: 16
                    repeat: true
                    running: transitionEffect.visible
                    onTriggered: transitionEffect.time += interval / 1000.0
                }
                onVisibleChanged: if (!visible) transitionEffect.time = 0.0
            }

            Loader {
                id: blurLoader
                active: Config.options.lock.blur.enable && (bgRoot.lockPresentationActive || scaleAnim.running)
                    && !(bgRoot.userBlurActive || bgRoot.overviewBlurActive)
                anchors.fill: parent
                scale: bgRoot.lockPresentationActive ? Config.options.lock.blur.extraZoom : 1
                Behavior on scale {
                    NumberAnimation {
                        id: scaleAnim
                        duration: 400
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: Appearance.animationCurves.expressiveDefaultSpatial
                    }
                }
                sourceComponent: GaussianBlur {
                    source: bgRoot.wallpaperAnimation === "" || bgRoot.transitionProgress >= 1.0 ? wallpaper : transitionEffect
                    radius: bgRoot.lockPresentationActive ? Config.options.lock.blur.radius : 0
                    samples: Config.options.lock.blur.size 
                    Rectangle {
                        opacity: bgRoot.lockPresentationActive ? 1 : 0
                        anchors.fill: parent
                        color: CF.ColorUtils.transparentize(Appearance.colors.colLayer0, 0.7)
                    }
                }
            }

            Loader {
                id: fastBlurLoader
                active: (bgRoot.userBlurActive || bgRoot.overviewBlurActive)
                    && (!bgRoot.centeredWallpaperEnabled || bgRoot.blurFullScreen)
                anchors.fill: parent
                sourceComponent: Item {
                    id: blurRoot
                    anchors.fill: parent

                    readonly property real fadeWidth: 140
                    readonly property real blurRadius: 48
                    readonly property bool alignRight: Config.options.background.splitSide === "right"
                    property real coreWidth: bgRoot.blurFullScreen ? blurRoot.width : blurRoot.width * bgRoot.splitFraction

                    Behavior on coreWidth {
                        NumberAnimation { duration: 250; easing.type: Easing.OutCubic }
                    }

                    FastBlur {
                        id: blurLayer
                        anchors.fill: parent
                        source: bgRoot.wallpaperAnimation === "" || bgRoot.transitionProgress >= 1.0 ? wallpaper : transitionEffect
                        radius: blurRoot.blurRadius

                        layer.enabled: !bgRoot.blurFullScreen
                        layer.effect: OpacityMask {
                            maskSource: Rectangle {
                                width: blurLayer.width
                                height: blurLayer.height
                                gradient: Gradient {
                                    orientation: Gradient.Horizontal
                                    GradientStop { position: blurRoot.alignRight ? 1 - (blurRoot.coreWidth / blurRoot.width) : Math.max(0, (blurRoot.coreWidth - blurRoot.fadeWidth) / blurRoot.width); color: blurRoot.alignRight ? "transparent" : "white" }
                                    GradientStop { position: blurRoot.alignRight ? Math.min(1, 1 - (blurRoot.coreWidth - blurRoot.fadeWidth) / blurRoot.width) : Math.min(1, blurRoot.coreWidth / blurRoot.width); color: blurRoot.alignRight ? "white" : "transparent" }
                                }
                            }
                        }
                    }
                }
            }

            Rectangle {
                id: centeredWallpaperBg
                anchors.fill: parent
                color: bgRoot.centeredWallpaperColor
                opacity: bgRoot.centeredWallpaperEnabled ? 1 : 0
                visible: opacity > 0

                Behavior on opacity {
                    animation: Appearance.animation.elementMove.numberAnimation.createObject(this)
                }
            }

            MaterialShape {
                id: centeredWallpaperShapeItem
                anchors.centerIn: parent
                width: bgRoot.centeredWallpaperSize
                height: bgRoot.centeredWallpaperSize
                color: bgRoot.centeredWallpaperColor
                shape: bgRoot.centeredWallpaperShape
                transformOrigin: Item.Center
                visible: opacity > 0

                state: bgRoot.centeredWallpaperEnabled ? "shown" : "hidden"

                states: [
                    State {
                        name: "shown"
                        PropertyChanges { target: centeredWallpaperShapeItem; scale: 1; opacity: 1 }
                    },
                    State {
                        name: "hidden"
                        PropertyChanges { target: centeredWallpaperShapeItem; scale: 1.4; opacity: 0 }
                    }
                ]

                transitions: [
                    Transition {
                        to: "shown"
                        ParallelAnimation {
                            NumberAnimation { target: centeredWallpaperShapeItem; property: "scale"; from: 0; duration: Appearance.animation.elementMove.duration; easing.type: Easing.InOutCubic }
                            NumberAnimation { target: centeredWallpaperShapeItem; property: "opacity"; duration: Appearance.animation.elementMove.duration; easing.type: Easing.InOutCubic }
                        }
                    },
                    Transition {
                        to: "hidden"
                        ParallelAnimation {
                            NumberAnimation { target: centeredWallpaperShapeItem; property: "scale"; duration: Appearance.animation.elementMove.duration; easing.type: Easing.InOutCubic }
                            NumberAnimation { target: centeredWallpaperShapeItem; property: "opacity"; duration: Appearance.animation.elementMove.duration; easing.type: Easing.InOutCubic }
                        }
                    }
                ]

                layer.enabled: true
                layer.effect: OpacityMask {
                    maskSource: MaterialShape {
                        width: centeredWallpaperShapeItem.width
                        height: centeredWallpaperShapeItem.height
                        shape: bgRoot.centeredWallpaperShape
                    }
                }

                StyledImage {
                    anchors.fill: parent
                    source: bgRoot.wallpaperPath
                    fillMode: Image.PreserveAspectCrop
                    cache: false
                    antialiasing: true
                    sourceSize.width: parent.width
                    sourceSize.height: parent.height
                }
            }

            DropArea {
                id: wallpaperDropArea
                anchors.fill: parent
                keys: ["text/uri-list"]

                property var currentUrls: []

                onEntered: (drag) => {
                    drag.accepted = drag.hasUrls
                    wallpaperDropArea.currentUrls = drag.hasUrls ? drag.urls : []
                }

                onExited: {
                    wallpaperDropArea.currentUrls = []
                }

                onDropped: (drop) => {
                    if (!drop.hasUrls) {
                        drop.accepted = false
                        wallpaperDropArea.currentUrls = []
                        return
                    }

                    if (drop.urls.length === 1) {
                        const path = CF.FileUtils.trimFileProtocol(decodeURIComponent(drop.urls[0].toString()))
                        const validExt = /\.(png|jpe?g|webp|bmp|gif)$/i.test(path)
                        if (validExt) {
                            Wallpapers.select(path, Appearance.m3colors.darkmode)
                        } else {
                            const globalPos = wallpaperDropArea.mapToGlobal(drop.x, drop.y)
                            DropShelf.show(drop.urls, globalPos.x, globalPos.y)
                        }
                    } else {
                        const globalPos = wallpaperDropArea.mapToGlobal(drop.x, drop.y)
                        DropShelf.show(drop.urls, globalPos.x, globalPos.y)
                    }
                    drop.accept()
                    wallpaperDropArea.currentUrls = []
                }

                Rectangle {
                    id: dropOverlay
                    anchors.fill: parent
                    visible: wallpaperDropArea.containsDrag
                    color: CF.ColorUtils.transparentize(Appearance.colors.colPrimary, 0.6)

                    property bool isSingleImage: wallpaperDropArea.currentUrls.length === 1
                        && /\.(png|jpe?g|webp|bmp|gif)$/i.test(
                            CF.FileUtils.trimFileProtocol(wallpaperDropArea.currentUrls[0].toString())
                        )

                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: 8
                        MaterialSymbol {
                            Layout.alignment: Qt.AlignHCenter
                            text: dropOverlay.isSingleImage ? "wallpaper" : "stacks"
                            iconSize: 64
                            color: Appearance.colors.colOnPrimary
                        }
                        StyledText {
                            Layout.alignment: Qt.AlignHCenter
                            text: dropOverlay.isSingleImage
                                ? Translation.tr("Drop to set as wallpaper")
                                : Translation.tr("Drop to add to shelf")
                            font.pixelSize: Appearance.font.pixelSize.large
                            color: Appearance.colors.colOnPrimary
                        }
                    }
                }
            }

            WidgetCanvas {
                id: widgetCanvas
                anchors.fill: parent
                // The clock is the one intentional exception to the private
                // desktop-widget rule: it remains the lock-screen anchor even
                // when notes, media, and every other desktop widget are hidden.
                // Individual widgets still decide their own lock visibility.
                visible: !bgRoot.lockPresentationActive
                    || Config.options.lock.showWidgets
                    || Config.options.background.widgets.clock.enable

                transitions: Transition {
                    PropertyAnimation {
                        properties: "width,height"
                        duration: Appearance.animation.elementMove.duration
                        easing.type: Appearance.animation.elementMove.type
                        easing.bezierCurve: Appearance.animation.elementMove.bezierCurve
                    }
                    AnchorAnimation {
                        duration: Appearance.animation.elementMove.duration
                        easing.type: Appearance.animation.elementMove.type
                        easing.bezierCurve: Appearance.animation.elementMove.bezierCurve
                    }
                }
                FadeLoader {
                    // DesktopVisualizer folds in the per-screen "is anything
                    // covering the desktop here" check on top of the usual
                    // enable/screenList pair. FadeLoader ties `active` to
                    // opacity, so going false really destroys the widget (and
                    // with it every per-frame binding it owns) rather than
                    // leaving it invisible but still animating.
                    shown: DesktopVisualizer.shownOnScreen(
                        bgRoot.screen.name, Config.options.background.widgets.visualizer)
                    sourceComponent: VisualizerWidget {
                        screenWidth: bgRoot.screen.width
                        screenHeight: bgRoot.screen.height
                        scaledScreenWidth: bgRoot.screen.width
                        scaledScreenHeight: bgRoot.screen.height
                        wallpaperScale: 1
                    }
                }
                FadeLoader {
                    shown: DesktopVisualizer.shownOnScreen(
                        bgRoot.screen.name, Config.options.background.widgets.visualizerMirror)
                    sourceComponent: MirroredVisualizerWidget {
                        screenWidth: bgRoot.screen.width
                        screenHeight: bgRoot.screen.height
                        scaledScreenWidth: bgRoot.screen.width
                        scaledScreenHeight: bgRoot.screen.height
                        wallpaperScale: 1
                    }
                }
                FadeLoader {
                    shown: Config.options.background.widgets.customImage.enable
                        && (Config.options.background.screenList.length === 0
                            || Config.options.background.screenList.includes(bgRoot.screen.name))
                    sourceComponent: CustomImage {
                        screenWidth:        bgRoot.screen.width
                        screenHeight:       bgRoot.screen.height
                        scaledScreenWidth:  bgRoot.screen.width
                        scaledScreenHeight: bgRoot.screen.height
                        wallpaperScale:     1
                    }
                }
                FadeLoader {
                    shown: Config.options.background.widgets.calendar.enable
                        && (Config.options.background.screenList.length === 0
                            || Config.options.background.screenList.includes(bgRoot.screen.name))
                    sourceComponent: CalendarWidget {
                        screenWidth: bgRoot.screen.width
                        screenHeight: bgRoot.screen.height
                        scaledScreenWidth: bgRoot.screen.width
                        scaledScreenHeight: bgRoot.screen.height
                        wallpaperScale: 1
                    }
                }
                FadeLoader {
                    shown: Config.options.background.widgets.weather.enable
                        && (Config.options.background.screenList.length === 0
                            || Config.options.background.screenList.includes(bgRoot.screen.name))
                    sourceComponent: WeatherWidget {
                        screenWidth: bgRoot.screen.width
                        screenHeight: bgRoot.screen.height
                        scaledScreenWidth: bgRoot.screen.width
                        scaledScreenHeight: bgRoot.screen.height
                        wallpaperScale: 1
                    }
                }
                FadeLoader {
                    shown: Config.options.background.widgets.clock.enable
                        && (bgRoot.lockPresentationActive
                            || Config.options.background.screenList.length === 0
                            || Config.options.background.screenList.includes(bgRoot.screen.name))
                    sourceComponent: ClockWidget {
                        screenWidth: bgRoot.screen.width
                        screenHeight: bgRoot.screen.height
                        scaledScreenWidth: bgRoot.screen.width
                        scaledScreenHeight: bgRoot.screen.height
                        wallpaperScale: 1
                        wallpaperSafetyTriggered: bgRoot.wallpaperSafetyTriggered
                    }
                }
                FadeLoader {
                    shown: Config.options.background.widgets.notes.enable
                        && (Config.options.background.screenList.length === 0
                            || Config.options.background.screenList.includes(bgRoot.screen.name))
                    sourceComponent: NotesWidget {
                        screenWidth: bgRoot.screen.width
                        screenHeight: bgRoot.screen.height
                        scaledScreenWidth: bgRoot.screen.width
                        scaledScreenHeight: bgRoot.screen.height
                        wallpaperScale: 1
                    }
                }
                FadeLoader {
                    id: mediaLoader
                    property bool enableLoading: true
                    shown: Config.options.background.widgets.media.enable && enableLoading
                        && (Config.options.background.screenList.length === 0
                            || Config.options.background.screenList.includes(bgRoot.screen.name))
                    sourceComponent: MediaWidget {
                        screenWidth: bgRoot.screen.width
                        screenHeight: bgRoot.screen.height
                        scaledScreenWidth: bgRoot.screen.width
                        scaledScreenHeight: bgRoot.screen.height
                        wallpaperScale: 1
                    }
                    onLoaded: {
                        if (item && item.requestReset) {
                            item.requestReset.connect(() => {
                                mediaLoader.enableLoading = false
                                mediaTimer.running = true
                            })
                        }
                    }
                }
                FadeLoader {
                    shown: Config.options.background.widgets.images.enable
                        && (Config.options.background.screenList.length === 0
                            || Config.options.background.screenList.includes(bgRoot.screen.name))
                    sourceComponent: ImageConverterWidget {
                        screenWidth:        bgRoot.screen.width
                        screenHeight:       bgRoot.screen.height
                        scaledScreenWidth:  bgRoot.screen.width
                        scaledScreenHeight: bgRoot.screen.height
                        wallpaperScale:     1
                    }
                }
                FadeLoader {
                    shown: Config.options.background.widgets.resources.enable
                        && (Config.options.background.screenList.length === 0
                            || Config.options.background.screenList.includes(bgRoot.screen.name))
                    sourceComponent: ResourcesWidget {
                        screenWidth:        bgRoot.screen.width
                        screenHeight:       bgRoot.screen.height
                        scaledScreenWidth:  bgRoot.screen.width
                        scaledScreenHeight: bgRoot.screen.height
                        wallpaperScale:     1
                    }
                }
                FadeLoader {
                    shown: Config.options.background.widgets.networkInfo.enable
                        && (Config.options.background.screenList.length === 0
                            || Config.options.background.screenList.includes(bgRoot.screen.name))
                    sourceComponent: NetworkInfoWidget {
                        screenWidth:        bgRoot.screen.width
                        screenHeight:       bgRoot.screen.height
                        scaledScreenWidth:  bgRoot.screen.width
                        scaledScreenHeight: bgRoot.screen.height
                        wallpaperScale:     1
                    }
                }
                FadeLoader {
                    shown: Config.options.background.widgets.systemHistory.enable
                        && (Config.options.background.screenList.length === 0
                            || Config.options.background.screenList.includes(bgRoot.screen.name))
                    sourceComponent: SystemHistoryWidget {
                        screenWidth:        bgRoot.screen.width
                        screenHeight:       bgRoot.screen.height
                        scaledScreenWidth:  bgRoot.screen.width
                        scaledScreenHeight: bgRoot.screen.height
                        wallpaperScale:     1
                    }
                }
                FadeLoader {
                    shown: Config.options.background.widgets.uptime.enable
                        && (Config.options.background.screenList.length === 0
                            || Config.options.background.screenList.includes(bgRoot.screen.name))
                    sourceComponent: UptimeWidget {
                        screenWidth:        bgRoot.screen.width
                        screenHeight:       bgRoot.screen.height
                        scaledScreenWidth:  bgRoot.screen.width
                        scaledScreenHeight: bgRoot.screen.height
                        wallpaperScale:     1
                    }
                }
                FadeLoader {
                    shown: Config.options.background.widgets.worldClock.enable
                        && (Config.options.background.screenList.length === 0
                            || Config.options.background.screenList.includes(bgRoot.screen.name))
                    sourceComponent: WorldClockWidget {
                        screenWidth: bgRoot.screen.width
                        screenHeight: bgRoot.screen.height
                        scaledScreenWidth: bgRoot.screen.width
                        scaledScreenHeight: bgRoot.screen.height
                        wallpaperScale: 1
                    }
                }
                FadeLoader {
                    shown: Config.options.background.widgets.userCard.enable
                        && (Config.options.background.screenList.length === 0
                            || Config.options.background.screenList.includes(bgRoot.screen.name))
                    sourceComponent: UserCardWidget {
                        screenWidth: bgRoot.screen.width
                        screenHeight: bgRoot.screen.height
                        scaledScreenWidth: bgRoot.screen.width
                        scaledScreenHeight: bgRoot.screen.height
                        wallpaperScale: 1
                    }
                }
                FadeLoader {
                    shown: Config.options.background.widgets.todo.enable
                        && (Config.options.background.screenList.length === 0
                            || Config.options.background.screenList.includes(bgRoot.screen.name))
                    sourceComponent: TodoWidget {
                        screenWidth: bgRoot.screen.width
                        screenHeight: bgRoot.screen.height
                        scaledScreenWidth: bgRoot.screen.width
                        scaledScreenHeight: bgRoot.screen.height
                        wallpaperScale: 1
                    }
                }
                FadeLoader {
                    shown: Config.options.background.widgets.timers.enable
                        && (Config.options.background.screenList.length === 0
                            || Config.options.background.screenList.includes(bgRoot.screen.name))
                    sourceComponent: TimerWidget {
                        screenWidth:        bgRoot.screen.width
                        screenHeight:       bgRoot.screen.height
                        scaledScreenWidth:  bgRoot.screen.width
                        scaledScreenHeight: bgRoot.screen.height
                        wallpaperScale:     1
                    }
                }
            }

            // The real password, identity/media and power toolbars belong to
            // WlSessionLockSurface, so they do not exist while Settings is
            // showing its non-locking preview.  Render a deliberately
            // non-interactive counterpart here so the preview matches the
            // actual lower lock-screen composition without ever accepting a
            // password or creating a second session lock.
            Item {
                id: lockControlsPreview
                anchors.fill: parent
                z: 50
                readonly property string interactionScreenName:
                    WM.focusedMonitor?.name ?? Quickshell.screens[0]?.name ?? ""
                readonly property bool isInteractionScreen:
                    interactionScreenName === "" || bgRoot.screen.name === interactionScreenName
                readonly property bool isPrimaryControlsScreen: !Config.options.lock.unlockBoxPrimaryMonitorOnly
                    || bgRoot.screen.name === GlobalStates.primaryLockOutputName()
                readonly property bool shown: GlobalStates.lockPreviewOpen && isInteractionScreen
                    && isPrimaryControlsScreen
                readonly property var screenLayout: GlobalStates.lockLayoutForOutput(bgRoot.screen.name)
                readonly property string passwordPlacement: screenLayout.passwordPlacement
                property string draggedToolbar: ""
                property var toolbarDraftOffsets: ({})
                property real dragStartX: 0
                property real dragStartY: 0
                property real dragStartOffsetX: 0
                property real dragStartOffsetY: 0

                function snapToGrid(value) {
                    return Math.round(value / widgetCanvas.gridSize) * widgetCanvas.gridSize
                }
                function toolbarOffset(group) {
                    return toolbarDraftOffsets[group] ?? screenLayout[group]
                }
                function toolbarOffsetX(group) { return toolbarOffset(group)?.offsetX ?? 0 }
                function toolbarOffsetY(group) { return toolbarOffset(group)?.offsetY ?? 0 }
                function toolbarFor(group) {
                    if (group === "password") return previewPasswordToolbar
                    if (group === "leftToolbar") return previewLeftToolbar
                    return previewRightToolbar
                }
                // Drag handles are translated with the toolbar. MouseArea's
                // local coordinates therefore change while the pointer is held;
                // using them directly fed the moving offset back into itself
                // and caused the visible left/right jitter. Always work in the
                // stable coordinate system of this preview surface instead.
                function previewPoint(item, mouse) {
                    return item.mapToItem(lockControlsPreview, mouse.x, mouse.y)
                }
                function toolbarGuideRect(group) {
                    const item = toolbarFor(group)
                    const factor = item.scale
                    const width = item.width * factor
                    const height = item.height * factor
                    return {
                        x: item.x + toolbarOffsetX(group) + (item.width - width) / 2,
                        y: item.y + toolbarOffsetY(group) + (item.height - height) / 2,
                        width: width,
                        height: height,
                    }
                }
                function updateToolbarGuides(group) {
                    const rect = toolbarGuideRect(group)
                    widgetCanvas.setCenterActive(
                        Math.abs(rect.x + rect.width / 2 - widgetCanvas.width / 2) < widgetCanvas.gridSize,
                        Math.abs(rect.y + rect.height / 2 - widgetCanvas.height / 2) < widgetCanvas.gridSize
                    )
                }
                function beginToolbarDrag(group, x, y) {
                    const layout = screenLayout[group]
                    if (!layout) return
                    draggedToolbar = group
                    dragStartX = x
                    dragStartY = y
                    dragStartOffsetX = layout.offsetX
                    dragStartOffsetY = layout.offsetY
                    const drafts = Object.assign({}, toolbarDraftOffsets)
                    drafts[group] = { offsetX: layout.offsetX, offsetY: layout.offsetY }
                    toolbarDraftOffsets = drafts
                    widgetCanvas.setDragging(true)
                }
                function updateToolbarDrag(x, y) {
                    if (draggedToolbar === "") return
                    const drafts = Object.assign({}, toolbarDraftOffsets)
                    drafts[draggedToolbar] = {
                        offsetX: snapToGrid(dragStartOffsetX + x - dragStartX),
                        offsetY: snapToGrid(dragStartOffsetY + y - dragStartY),
                    }
                    toolbarDraftOffsets = drafts
                    updateToolbarGuides(draggedToolbar)
                }
                function endToolbarDrag() {
                    const group = draggedToolbar
                    const draft = toolbarDraftOffsets[group]
                    const layout = screenLayout[group]
                    if (draft && layout) {
                        GlobalStates.updateLockLayoutOffset(bgRoot.screen.name, group, draft.offsetX, draft.offsetY)
                        const rect = toolbarGuideRect(group)
                        widgetCanvas.flashLines([rect.x, rect.x + rect.width], [rect.y, rect.y + rect.height])
                    }
                    const remaining = Object.assign({}, toolbarDraftOffsets)
                    delete remaining[group]
                    toolbarDraftOffsets = remaining
                    draggedToolbar = ""
                    widgetCanvas.setDragging(false)
                }

                Toolbar {
                    id: previewPasswordToolbar
                    visible: lockControlsPreview.shown
                    anchors {
                        horizontalCenter: lockControlsPreview.passwordPlacement === "bottom"
                            || lockControlsPreview.passwordPlacement === "center" ? parent.horizontalCenter : undefined
                        verticalCenter: lockControlsPreview.passwordPlacement === "center" ? parent.verticalCenter : undefined
                        left: lockControlsPreview.passwordPlacement === "left" ? parent.left : undefined
                        right: lockControlsPreview.passwordPlacement === "right" ? parent.right : undefined
                        bottom: lockControlsPreview.passwordPlacement !== "center" ? parent.bottom : undefined
                        leftMargin: lockControlsPreview.passwordPlacement === "left" ? 28 : 0
                        rightMargin: lockControlsPreview.passwordPlacement === "right" ? 28 : 0
                        bottomMargin: lockControlsPreview.passwordPlacement !== "center"
                            ? lockControlsPreview.screenLayout.bottomMargin : 0
                    }
                    transform: Translate {
                        x: lockControlsPreview.toolbarOffsetX("password")
                        y: lockControlsPreview.toolbarOffsetY("password")
                    }
                    scale: lockControlsPreview.screenLayout.password.scale

                    Item {
                        // These are the exact 40px slots and margins used by
                        // LockSurface.qml.  The preview must reserve them too:
                        // using a bare icon made its password island visibly
                        // narrower than the real session-lock island.
                        Layout.leftMargin: 10
                        Layout.rightMargin: 6
                        Layout.preferredWidth: Config.options.lock.biometrics.enableFingerprint ? 40 : 0
                        Layout.preferredHeight: 40
                        visible: Config.options.lock.biometrics.enableFingerprint
                        MaterialSymbol {
                            anchors.centerIn: parent
                            text: "fingerprint"
                            iconSize: Appearance.font.pixelSize.larger
                            color: Appearance.colors.colOnSurfaceVariant
                        }
                    }
                    Item {
                        Layout.leftMargin: 2
                        Layout.rightMargin: 2
                        Layout.preferredWidth: Config.options.lock.biometrics.enableFaceAuth ? 40 : 0
                        Layout.preferredHeight: 40
                        visible: Config.options.lock.biometrics.enableFaceAuth
                        MaterialSymbol {
                            anchors.centerIn: parent
                            text: "face"
                            iconSize: Appearance.font.pixelSize.larger
                            color: Appearance.colors.colOnSurfaceVariant
                        }
                    }
                    Rectangle {
                        // ToolbarTextField's real implicit width is 200.
                        Layout.preferredWidth: 200
                        Layout.preferredHeight: 36
                        radius: Appearance.rounding.full
                        color: Appearance.colors.colLayer1
                        border.width: 1
                        border.color: Appearance.colors.colLayer0Border
                        StyledText {
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.left: parent.left
                            anchors.leftMargin: 14
                            text: Translation.tr("Enter password")
                            color: Appearance.colors.colSubtext
                        }
                    }
                    Item {
                        Layout.preferredWidth: 40
                        Layout.preferredHeight: 40
                        MaterialSymbol {
                            anchors.centerIn: parent
                            text: "arrow_right_alt"
                            iconSize: 24
                            color: Appearance.colors.colPrimary
                        }
                    }
                }

                Toolbar {
                    id: previewLeftToolbar
                    readonly property bool stackedAboveMain: lockControlsPreview.passwordPlacement === "left"
                    visible: lockControlsPreview.shown && Config.options.lock.showToolbars
                        && Config.options.lock.showLeftToolbar
                    anchors {
                        left: stackedAboveMain ? previewPasswordToolbar.left : undefined
                        right: stackedAboveMain ? undefined : previewPasswordToolbar.left
                        top: stackedAboveMain ? undefined : previewPasswordToolbar.top
                        bottom: stackedAboveMain ? previewPasswordToolbar.top : previewPasswordToolbar.bottom
                        rightMargin: stackedAboveMain ? 0 : 10
                        bottomMargin: stackedAboveMain ? 10 : 0
                    }
                    transform: Translate {
                        x: lockControlsPreview.toolbarOffsetX("leftToolbar")
                        y: lockControlsPreview.toolbarOffsetY("leftToolbar")
                    }
                    scale: lockControlsPreview.screenLayout.leftToolbar.scale

                    Row {
                        Layout.leftMargin: 10
                        Layout.rightMargin: 10
                        spacing: 4
                        visible: !Config.options.lock.showMedia || MprisController.activePlayer === null
                        MaterialSymbol {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "account_circle"
                            iconSize: Appearance.font.pixelSize.huge
                            color: Appearance.colors.colOnSurfaceVariant
                        }
                        StyledText {
                            anchors.verticalCenter: parent.verticalCenter
                            text: SystemInfo.username
                            color: Appearance.colors.colOnSurfaceVariant
                        }
                    }
                    Item {
                        Layout.leftMargin: 2
                        Layout.rightMargin: 2
                        visible: Config.options.lock.showMedia && MprisController.activePlayer !== null
                        implicitWidth: previewMediaRow.implicitWidth
                        implicitHeight: previewMediaRow.implicitHeight

                        RowLayout {
                            id: previewMediaRow
                            anchors.centerIn: parent
                            spacing: 8
                            Rectangle {
                                implicitWidth: 40
                                implicitHeight: 40
                                radius: Appearance.rounding.full
                                color: Appearance.colors.colPrimaryContainer
                                MaterialSymbol {
                                    anchors.centerIn: parent
                                    text: "music_note"
                                    iconSize: Appearance.font.pixelSize.normal
                                    color: Appearance.colors.colOnSecondaryContainer
                                }
                            }
                            Column {
                                Layout.alignment: Qt.AlignVCenter
                                spacing: -2
                                StyledText {
                                    horizontalAlignment: Text.AlignLeft
                                    elide: Text.ElideRight
                                    maximumLineCount: 1
                                    width: Math.min(implicitWidth, 180)
                                    color: Appearance.colors.colOnSurfaceVariant
                                    text: {
                                        const artist = MprisController.activePlayer?.trackArtist || " "
                                        return artist.length > 25 ? artist.substring(0, 25) + "..." : artist
                                    }
                                    font.pixelSize: Appearance.font.pixelSize.smaller
                                }
                                StyledText {
                                    horizontalAlignment: Text.AlignLeft
                                    elide: Text.ElideRight
                                    maximumLineCount: 1
                                    width: Math.min(implicitWidth, 180)
                                    color: Appearance.colors.colOnSurfaceVariant
                                    text: {
                                        const title = CF.StringUtils.cleanMusicTitle(MprisController.activePlayer?.trackTitle) || ""
                                        return title.length > 30 ? title.substring(0, 30) + "..." : title
                                    }
                                    font.weight: Font.Medium
                                    font.pixelSize: Appearance.font.pixelSize.small
                                }
                            }
                            ClippedFilledCircularProgress {
                                Layout.alignment: Qt.AlignVCenter
                                lineWidth: Appearance.rounding.unsharpen
                                value: MprisController.activePlayer?.position / MprisController.activePlayer?.length
                                implicitSize: 24
                                colPrimary: Appearance.colors.colOnSurfaceVariant
                                enableAnimation: false
                                MaterialSymbol {
                                    anchors.centerIn: parent
                                    text: "music_note"
                                    iconSize: Appearance.font.pixelSize.normal
                                    color: Appearance.colors.colOnSurfaceVariant
                                }
                            }
                        }
                    }
                    Row {
                        Layout.rightMargin: 8
                        Layout.fillHeight: true
                        spacing: 8
                        MaterialSymbol {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "keyboard_alt"
                            iconSize: Appearance.font.pixelSize.huge
                            color: Appearance.colors.colOnSurfaceVariant
                        }
                        StyledText {
                            anchors.verticalCenter: parent.verticalCenter
                            text: HyprlandXkb.currentLayoutCode
                            color: Appearance.colors.colOnSurfaceVariant
                        }
                    }
                    // The real lock surface includes a pinned Fcitx tray item
                    // when present.  Keeping this conditional copy prevents a
                    // real-only width jump on systems using Fcitx.
                    Bar.SysTray {
                        Layout.rightMargin: 10
                        Layout.alignment: Qt.AlignVCenter
                        showSeparator: false
                        showOverflowMenu: false
                        pinnedItems: SystemTray.items.values.filter(i => i.id == "Fcitx")
                        visible: pinnedItems.length > 0
                    }
                }

                Toolbar {
                    id: previewRightToolbar
                    readonly property bool stackedAboveMain: lockControlsPreview.passwordPlacement === "right"
                    visible: lockControlsPreview.shown && Config.options.lock.showToolbars
                        && Config.options.lock.showRightToolbar
                    anchors {
                        right: stackedAboveMain ? previewPasswordToolbar.right : undefined
                        left: stackedAboveMain ? undefined : previewPasswordToolbar.right
                        top: stackedAboveMain ? undefined : previewPasswordToolbar.top
                        bottom: stackedAboveMain ? previewPasswordToolbar.top : previewPasswordToolbar.bottom
                        leftMargin: stackedAboveMain ? 0 : 10
                        bottomMargin: stackedAboveMain ? 10 : 0
                    }
                    transform: Translate {
                        x: lockControlsPreview.toolbarOffsetX("rightToolbar")
                        y: lockControlsPreview.toolbarOffsetY("rightToolbar")
                    }
                    scale: lockControlsPreview.screenLayout.rightToolbar.scale

                    Row {
                        Layout.leftMargin: 10
                        Layout.rightMargin: 10
                        spacing: 4
                        visible: Battery.available
                        MaterialSymbol {
                            anchors.verticalCenter: parent.verticalCenter
                            text: Battery.isCharging ? "bolt" : "battery_android_full"
                            iconSize: Appearance.font.pixelSize.huge
                            color: Appearance.colors.colOnSurfaceVariant
                        }
                        StyledText {
                            anchors.verticalCenter: parent.verticalCenter
                            text: Math.round(Battery.percentage * 100)
                            color: Appearance.colors.colOnSurfaceVariant
                        }
                    }
                    Item {
                        Layout.preferredWidth: 40
                        Layout.preferredHeight: 40
                        MaterialSymbol {
                            anchors.centerIn: parent
                            text: "dark_mode"
                            iconSize: 22
                            color: Appearance.colors.colOnSurfaceVariant
                        }
                    }
                    Item {
                        Layout.preferredWidth: 40
                        Layout.preferredHeight: 40
                        MaterialSymbol {
                            anchors.centerIn: parent
                            text: "power_settings_new"
                            iconSize: 22
                            color: Appearance.colors.colOnSurfaceVariant
                        }
                    }
                    Item {
                        Layout.rightMargin: 8
                        Layout.preferredWidth: 40
                        Layout.preferredHeight: 40
                        MaterialSymbol {
                            anchors.centerIn: parent
                            text: "restart_alt"
                            iconSize: 22
                            color: Appearance.colors.colOnSurfaceVariant
                        }
                    }
                }

                // Toolbar is anchored in the real lock surface, so dragging it
                // directly would break those anchors. These transparent handles
                // edit its persisted translation instead; the same values are
                // used by LockSurface.qml when the session is actually locked.
                MouseArea {
                    id: previewPasswordDragHandle
                    anchors.fill: previewPasswordToolbar
                    visible: previewPasswordToolbar.visible
                    z: 2
                    hoverEnabled: true
                    cursorShape: pressed ? Qt.ClosedHandCursor : Qt.OpenHandCursor
                    transform: Translate {
                        x: lockControlsPreview.toolbarOffsetX("password")
                        y: lockControlsPreview.toolbarOffsetY("password")
                    }
                    scale: lockControlsPreview.screenLayout.password.scale
                    onPressed: mouse => {
                        const point = lockControlsPreview.previewPoint(previewPasswordDragHandle, mouse)
                        lockControlsPreview.beginToolbarDrag("password", point.x, point.y)
                    }
                    onPositionChanged: mouse => {
                        if (pressed) {
                            const point = lockControlsPreview.previewPoint(previewPasswordDragHandle, mouse)
                            lockControlsPreview.updateToolbarDrag(point.x, point.y)
                        }
                    }
                    onReleased: lockControlsPreview.endToolbarDrag()
                }

                MouseArea {
                    id: previewLeftDragHandle
                    anchors.fill: previewLeftToolbar
                    visible: previewLeftToolbar.visible
                    z: 2
                    hoverEnabled: true
                    cursorShape: pressed ? Qt.ClosedHandCursor : Qt.OpenHandCursor
                    transform: Translate {
                        x: lockControlsPreview.toolbarOffsetX("leftToolbar")
                        y: lockControlsPreview.toolbarOffsetY("leftToolbar")
                    }
                    scale: lockControlsPreview.screenLayout.leftToolbar.scale
                    onPressed: mouse => {
                        const point = lockControlsPreview.previewPoint(previewLeftDragHandle, mouse)
                        lockControlsPreview.beginToolbarDrag("leftToolbar", point.x, point.y)
                    }
                    onPositionChanged: mouse => {
                        if (pressed) {
                            const point = lockControlsPreview.previewPoint(previewLeftDragHandle, mouse)
                            lockControlsPreview.updateToolbarDrag(point.x, point.y)
                        }
                    }
                    onReleased: lockControlsPreview.endToolbarDrag()
                }

                MouseArea {
                    id: previewRightDragHandle
                    anchors.fill: previewRightToolbar
                    visible: previewRightToolbar.visible
                    z: 2
                    hoverEnabled: true
                    cursorShape: pressed ? Qt.ClosedHandCursor : Qt.OpenHandCursor
                    transform: Translate {
                        x: lockControlsPreview.toolbarOffsetX("rightToolbar")
                        y: lockControlsPreview.toolbarOffsetY("rightToolbar")
                    }
                    scale: lockControlsPreview.screenLayout.rightToolbar.scale
                    onPressed: mouse => {
                        const point = lockControlsPreview.previewPoint(previewRightDragHandle, mouse)
                        lockControlsPreview.beginToolbarDrag("rightToolbar", point.x, point.y)
                    }
                    onPositionChanged: mouse => {
                        if (pressed) {
                            const point = lockControlsPreview.previewPoint(previewRightDragHandle, mouse)
                            lockControlsPreview.updateToolbarDrag(point.x, point.y)
                        }
                    }
                    onReleased: lockControlsPreview.endToolbarDrag()
                }
            }

            Rectangle {
                id: lockPreviewToolbar
                z: 100
                anchors.top: parent.top
                anchors.topMargin: 24
                anchors.horizontalCenter: parent.horizontalCenter
                visible: GlobalStates.lockPreviewOpen
                implicitWidth: previewButtons.implicitWidth + 16
                implicitHeight: previewButtons.implicitHeight + 12
                property bool applyTargetMenuOpen: false
                readonly property var otherOutputs: GlobalStates.lockOutputNames()
                    .filter(name => name !== bgRoot.screen.name)
                radius: Appearance.rounding.full
                color: Appearance.colors.colLayer0
                border.width: 1
                border.color: Appearance.colors.colLayer0Border

                RowLayout {
                    id: previewButtons
                    anchors.centerIn: parent
                    spacing: 6

                    IconAndTextToolbarButton {
                        iconText: "close"
                        text: Translation.tr("Close")
                        onClicked: GlobalStates.cancelLockPreview()
                    }
                    IconAndTextToolbarButton {
                        iconText: "save"
                        text: Translation.tr("Save")
                        onClicked: GlobalStates.saveLockPreview()
                    }
                    IconAndTextToolbarButton {
                        iconText: "restart_alt"
                        text: Translation.tr("Reset")
                        onClicked: GlobalStates.resetLockWidgetLayout()
                    }
                    IconAndTextToolbarButton {
                        visible: Config.options.lock.perScreenLayout
                        iconText: "content_copy"
                        text: Translation.tr("Apply other screen")
                        onClicked: {
                            if (lockPreviewToolbar.otherOutputs.length === 1) {
                                GlobalStates.applyLockDesignToOutput(
                                    bgRoot.screen.name, lockPreviewToolbar.otherOutputs[0])
                            } else if (lockPreviewToolbar.otherOutputs.length > 1) {
                                lockPreviewToolbar.applyTargetMenuOpen = !lockPreviewToolbar.applyTargetMenuOpen
                            }
                        }
                    }
                }

                Rectangle {
                    id: applyTargetMenu
                    visible: lockPreviewToolbar.applyTargetMenuOpen
                    anchors.top: parent.bottom
                    anchors.topMargin: 8
                    anchors.horizontalCenter: parent.horizontalCenter
                    implicitWidth: targetMenuColumn.implicitWidth + 16
                    implicitHeight: targetMenuColumn.implicitHeight + 16
                    radius: Appearance.rounding.normal
                    color: Appearance.colors.colLayer0
                    border.width: 1
                    border.color: Appearance.colors.colLayer0Border
                    z: 120
                    Column {
                        id: targetMenuColumn
                        anchors.centerIn: parent
                        spacing: 4
                        Repeater {
                            model: lockPreviewToolbar.otherOutputs
                            delegate: RippleButton {
                                required property string modelData
                                implicitWidth: targetText.implicitWidth + 20
                                implicitHeight: 34
                                buttonRadius: Appearance.rounding.small
                                contentItem: StyledText {
                                    id: targetText
                                    anchors.centerIn: parent
                                    text: modelData
                                    color: Appearance.colors.colOnLayer0
                                }
                                onClicked: {
                                    GlobalStates.applyLockDesignToOutput(bgRoot.screen.name, modelData)
                                    lockPreviewToolbar.applyTargetMenuOpen = false
                                }
                            }
                        }
                    }
                }
            }

            MouseArea {
                id: desktopRightClickArea
                anchors.fill: parent
                z: -2
                acceptedButtons: Qt.RightButton
                onClicked: (mouse) => {
                    GlobalStates.desktopMenuScreen = bgRoot.screen
                    GlobalStates.desktopMenuX = mouse.x
                    GlobalStates.desktopMenuY = mouse.y
                    GlobalStates.desktopMenuOpen = true
                }
            }
        }
    }
}
