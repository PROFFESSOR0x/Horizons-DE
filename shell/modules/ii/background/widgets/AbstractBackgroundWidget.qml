import QtQuick
import Quickshell
import Quickshell.Io
import qs
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets.widgetCanvas

AbstractWidget {
    id: root

    required property string configEntryName
    required property int screenWidth
    required property int screenHeight
    required property int scaledScreenWidth
    required property int scaledScreenHeight
    required property real wallpaperScale
    // Per-widget lock-screen visibility: an empty lock.enabledWidgets list means
    // "no restriction" (every desktop-enabled widget may show, preserving legacy
    // behavior), otherwise only widgets named in that list are allowed.
    property bool visibleWhenLocked: Config.options.lock.showWidgets
        && (Config.options.lock.enabledWidgets.length === 0
            || Config.options.lock.enabledWidgets.indexOf(configEntryName) !== -1)
    property var configEntry: Config.options.background.widgets[configEntryName]
    property string placementStrategy: configEntry.placementStrategy
    property real targetX: Math.max(0, Math.min(configEntry.x, scaledScreenWidth - width))
    property real targetY : Math.max(0, Math.min(configEntry.y, scaledScreenHeight - height))
    x: targetX
    y: targetY
    visible: opacity > 0
    opacity: (GlobalStates.screenLocked && !visibleWhenLocked) ? 0 : 1
    Behavior on opacity {
        animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
    }
    scale: (draggable && containsPress) ? 1.05 : 1
    Behavior on scale {
        animation: Appearance.animation.elementResize.numberAnimation.createObject(this)
    }

    draggable: placementStrategy === "free" && !Config.options.background.widgetsLocked
    function restoreXYBinding() {
        root.x = Qt.binding(() => root.targetX);
        root.y = Qt.binding(() => root.targetY);
    }

    onReleased: {
        configEntry.x = root.x;
        configEntry.y = root.y;
        root.targetX = Qt.binding(() => Math.max(0, Math.min(configEntry.x, scaledScreenWidth - width)));
        root.targetY = Qt.binding(() => Math.max(0, Math.min(configEntry.y, scaledScreenHeight - height)));
        root.restoreXYBinding();
    }

    property bool needsColText: false
    property color dominantColor: Appearance.colors.colPrimary
    property bool dominantColorIsDark: dominantColor.hslLightness < 0.5
    property color colText: {
        const onNormalBackground = (GlobalStates.screenLocked && Config.options.lock.blur.enable)
        const adaptiveColor = ColorUtils.colorWithLightness(Appearance.colors.colPrimary, (dominantColorIsDark ? 0.8 : 0.12))
        return onNormalBackground ? Appearance.colors.colOnLayer0 : adaptiveColor;
    }

    property bool wallpaperIsVideo: Config.options.background.wallpaperPath.endsWith(".mp4") || Config.options.background.wallpaperPath.endsWith(".webm") || Config.options.background.wallpaperPath.endsWith(".mkv") || Config.options.background.wallpaperPath.endsWith(".avi") || Config.options.background.wallpaperPath.endsWith(".mov")
    property string wallpaperPath: wallpaperIsVideo ? Config.options.background.thumbnailPath : Config.options.background.wallpaperPath
    
    onWallpaperPathChanged: refreshPlacementIfNeeded()
    onPlacementStrategyChanged: refreshPlacementIfNeeded()
    Connections {
        target: Config
        function onReadyChanged() { refreshPlacementIfNeeded() }
    }
    function refreshPlacementIfNeeded() {
        if (!Config.ready) return;
        if (root.placementStrategy === "free" && !root.needsColText) return;
        leastBusyRegionProc.wallpaperPath = root.wallpaperPath;
        leastBusyRegionProc.running = false;
        leastBusyRegionProc.running = true;
    }
    Process {
        id: leastBusyRegionProc
        property string wallpaperPath: root.wallpaperPath
        // Sample a region sized like the widget itself (falling back to a reasonable default
        // before its content has laid out) so "least/most busy region" detection reflects what
        // will actually sit there, instead of a fixed guess that's wrong for most widgets.
        // Keep the search away from the screen edges by roughly a widget's worth of space, in
        // proportion to the screen size, so results don't hug a corner on very large/small displays.
        property int contentWidth: root.width > 0 ? Math.round(root.width) : 300
        property int contentHeight: root.height > 0 ? Math.round(root.height) : 300
        property int horizontalPadding: Math.max(contentWidth, Math.round(root.scaledScreenWidth * 0.1))
        property int verticalPadding: Math.max(contentHeight, Math.round(root.scaledScreenHeight * 0.1))
        command: [Quickshell.shellPath("scripts/images/least-busy-region-venv.sh") // Comments to force the formatter to break lines
            , "--screen-width", Math.round(root.scaledScreenWidth) //
            , "--screen-height", Math.round(root.scaledScreenHeight) //
            , "--width", contentWidth //
            , "--height", contentHeight //
            , "--horizontal-padding", horizontalPadding //
            , "--vertical-padding", verticalPadding //
            , wallpaperPath //
            , ...(root.placementStrategy === "mostBusy" ? ["--busiest"] : [])
            // "--visual-output",
        ]
        stdout: StdioCollector {
            id: leastBusyRegionOutputCollector
            onStreamFinished: {
                const output = leastBusyRegionOutputCollector.text;
                // console.log("[Background] Least busy region output:", output)
                if (output.length === 0) return;
                const parsedContent = JSON.parse(output);
                root.dominantColor = parsedContent.dominant_color || Appearance.colors.colPrimary;
                if (root.placementStrategy === "free") return;
                root.targetX = parsedContent.center_x * root.wallpaperScale - root.width / 2;
                root.targetY  = parsedContent.center_y * root.wallpaperScale - root.height / 2;
            }
        }
    }
}