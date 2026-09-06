import QtQuick
import Quickshell
import Quickshell.Io
import qs
import qs.services
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
    readonly property bool lockPresentationActive: GlobalStates.screenLocked || GlobalStates.lockPreviewOpen
    readonly property bool onlyWhenLocked: Config.options.background.widgets.lockOnly.indexOf(configEntryName) !== -1
    property var configEntry: Config.options.background.widgets[configEntryName]
    property string placementStrategy: configEntry.placementStrategy
    readonly property var lockPosition: Config.options.lock.widgetPositions[configEntryName] ?? null
    // Keep a shared normalized fallback, but preserve an override for every
    // output the user has arranged independently in the live editor.
    readonly property string outputName: root.QsWindow.window?.screen?.name ?? ""
    readonly property var outputLockPosition: {
        const overrides = lockPosition?.byScreen ?? ({})
        return Config.options.lock.perScreenLayout && outputName !== "" && overrides[outputName] !== undefined
            ? overrides[outputName] : lockPosition
    }
    // Lock positions are shared across outputs.  Store the *centre* as a
    // fraction of the QML output area, rather than the item's top-left corner.
    // QML's screen geometry is already in the correct logical coordinate space
    // for each Wayland output, so this deliberately does not mix in physical
    // pixels/devicePixelRatio.  Reconstructing from the centre compensates for
    // both a different output resolution/scale and a widget whose own size is
    // different on that output.
    readonly property real outputWidth: Math.max(1, scaledScreenWidth)
    readonly property real outputHeight: Math.max(1, scaledScreenHeight)
    readonly property real usableWidth: Math.max(1, outputWidth - width)
    readonly property real usableHeight: Math.max(1, outputHeight - height)
    readonly property real savedX: lockPresentationActive && outputLockPosition !== null
        ? (outputLockPosition.relativeCenterX !== undefined
            ? outputLockPosition.relativeCenterX * outputWidth - width / 2
            : (outputLockPosition.relativeX !== undefined
                ? outputLockPosition.relativeX * usableWidth
                : outputLockPosition.x))
        : configEntry.x
    readonly property real savedY: lockPresentationActive && outputLockPosition !== null
        ? (outputLockPosition.relativeCenterY !== undefined
            ? outputLockPosition.relativeCenterY * outputHeight - height / 2
            : (outputLockPosition.relativeY !== undefined
                ? outputLockPosition.relativeY * usableHeight
                : outputLockPosition.y))
        : configEntry.y

    // Old configurations only contain raw x/y.  The first time their owner
    // opens the live preview, convert that legacy position on the interaction
    // output itself.  Waiting for this screen is essential: doing the upgrade
    // from every output would race and make the result depend on construction
    // order.  Subsequent outputs immediately consume the shared centre values.
    readonly property string interactionOutputName:
        WM.focusedMonitor?.name ?? Quickshell.screens[0]?.name ?? ""
    function migrateLegacyLockPosition() {
        if (!GlobalStates.lockPreviewOpen || !lockPosition
            || lockPosition.relativeCenterX !== undefined || width <= 0 || height <= 0)
            return
        if (interactionOutputName !== "" && outputName !== "" && outputName !== interactionOutputName)
            return
        const positions = Object.assign({}, Config.options.lock.widgetPositions)
        const normalized = {
            relativeCenterX: (savedX + width / 2) / outputWidth,
            relativeCenterY: (savedY + height / 2) / outputHeight,
            sourceWidth: outputWidth,
            sourceHeight: outputHeight,
        }
        const overrides = Object.assign({}, lockPosition.byScreen ?? {})
        if (Config.options.lock.perScreenLayout && outputName !== "") overrides[outputName] = normalized
        positions[configEntryName] = Object.assign({}, lockPosition, normalized, { byScreen: overrides })
        Config.options.lock.widgetPositions = positions
    }
    property real targetX: Math.max(0, Math.min(savedX, scaledScreenWidth - width))
    property real targetY : Math.max(0, Math.min(savedY, scaledScreenHeight - height))
    x: targetX
    y: targetY
    visible: opacity > 0
    opacity: lockPresentationActive
        ? (visibleWhenLocked ? 1 : 0)
        : (onlyWhenLocked ? 0 : 1)
    Behavior on opacity {
        animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
    }
    scale: (draggable && containsPress) ? 1.05 : 1
    Behavior on scale {
        animation: Appearance.animation.elementResize.numberAnimation.createObject(this)
    }

    // Preview is a layout editor: every widget must be movable there, including
    // widgets normally placed automatically in a least/busiest region. Its
    // position is saved only to lock.widgetPositions, never to desktop layout.
    draggable: GlobalStates.lockPreviewOpen || (placementStrategy === "free"
        && !lockPresentationActive && !Config.options.background.widgetsLocked)
    onLockPresentationActiveChanged: Qt.callLater(migrateLegacyLockPosition)
    onWidthChanged: migrateLegacyLockPosition()
    onHeightChanged: migrateLegacyLockPosition()
    function restoreXYBinding() {
        root.x = Qt.binding(() => root.targetX);
        root.y = Qt.binding(() => root.targetY);
    }

    onReleased: {
        if (GlobalStates.lockPreviewOpen) {
            const positions = Object.assign({}, Config.options.lock.widgetPositions)
            const normalized = {
                x: root.x,
                y: root.y,
                // Keep x/y for backwards compatibility, but use the centre
                // for every future output mapping.  source dimensions are
                // retained for diagnostics/migration and make the stored
                // coordinate system explicit in the user config.
                relativeCenterX: (root.x + root.width / 2) / root.outputWidth,
                relativeCenterY: (root.y + root.height / 2) / root.outputHeight,
                relativeX: root.x / root.usableWidth,
                relativeY: root.y / root.usableHeight,
                sourceWidth: root.outputWidth,
                sourceHeight: root.outputHeight,
            }
            const existing = positions[configEntryName] ?? ({})
            const overrides = Object.assign({}, existing.byScreen ?? {})
            if (Config.options.lock.perScreenLayout && root.outputName !== "") overrides[root.outputName] = normalized
            // The first saved normalized position remains the fallback for a
            // new display. Moving one known display no longer moves the rest.
            const fallback = Config.options.lock.perScreenLayout && existing.relativeCenterX !== undefined
                ? existing : normalized
            positions[configEntryName] = Object.assign({}, fallback, { byScreen: overrides })
            Config.options.lock.widgetPositions = positions
        } else {
            configEntry.x = root.x;
            configEntry.y = root.y;
        }
        root.targetX = Qt.binding(() => Math.max(0, Math.min(root.savedX, scaledScreenWidth - width)));
        root.targetY = Qt.binding(() => Math.max(0, Math.min(root.savedY, scaledScreenHeight - height)));
        root.restoreXYBinding();
    }

    property bool needsColText: false
    property color dominantColor: Appearance.colors.colPrimary
    property bool dominantColorIsDark: dominantColor.hslLightness < 0.5
    property color colText: {
        const onNormalBackground = (lockPresentationActive && Config.options.lock.blur.enable)
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
