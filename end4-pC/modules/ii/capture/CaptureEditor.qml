pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtMultimedia
import Qt5Compat.GraphicalEffects
import qs
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import qs.services
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

PanelWindow {
    id: root
    visible: false
    color: "transparent"
    WlrLayershell.namespace: "quickshell:captureEditor"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    exclusionMode: ExclusionMode.Ignore
    anchors {
        left: true
        right: true
        top: true
        bottom: true
    }

    // Editor state
    property string imagePath: ""
    property string videoPath: ""
    property bool isVideo: false
    property bool isRecording: false

    // Drawing state
    property string currentTool: "pen" // pen, arrow, rect, circle, highlight, blur
    property color currentColor: "#ff0000"
    property real currentWidth: 3
    property bool isDrawing: false
    property point drawStart: Qt.point(0, 0)
    property point drawEnd: Qt.point(0, 0)

    // Video playback state
    property real videoPosition: 0
    property real videoDuration: 0
    property bool videoPlaying: false
    property real markIn: 0
    property real markOut: 0

    // Colors palette
    property list<color> colorPalette: [
        "#ff0000", "#ff6600", "#ffcc00", "#00cc00",
        "#0066ff", "#9933ff", "#ff0099", "#000000",
        "#ffffff", "#808080"
    ]

    AudioOutput {
        id: audioOutput
    }

    MediaPlayer {
        id: player
        audioOutput: audioOutput
        videoOutput: editorCanvas.videoOutput

        onPositionChanged: {
            root.videoPosition = player.position / 1000.0
        }

        onDurationChanged: {
            let dur = player.duration / 1000.0
            root.videoDuration = dur
            if (root.markOut === 0 || root.markOut > dur) {
                root.markOut = dur
            }
        }

        onMetaDataChanged: {
            let fr = player.metaData.value(MediaMetaData.VideoFrameRate)
            if (fr && fr > 0) {
                editorCanvas.fps = fr
                console.log("[CaptureEditor] Detected FPS from metadata:", fr)
            }
            let w = player.metaData.value(MediaMetaData.Resolution)
            if (w) {
                editorCanvas.videoNativeWidth = w.width
                editorCanvas.videoNativeHeight = w.height
                console.log("[CaptureEditor] Video resolution:", w.width, "x", w.height)
            }
        }

        onPlaybackStateChanged: {
            root.videoPlaying = (player.playbackState === MediaPlayer.PlayingState)
        }

        onErrorOccurred: (error, errorString) => {
            console.log("[CaptureEditor] MediaPlayer error:", error, errorString)
        }
    }

    function togglePlayPause() {
        if (!root.isVideo) return
        if (player.playbackState === MediaPlayer.PlayingState) {
            player.pause()
        } else {
            player.play()
        }
    }

    function seekVideo(seconds) {
        if (!root.isVideo) return
        let clamped = Math.max(0, Math.min(root.videoDuration > 0 ? root.videoDuration : 9999, seconds))
        player.position = Math.round(clamped * 1000)
    }

    function stepFrame(delta) {
        if (!root.isVideo) return
        let frameDuration = 1.0 / (editorCanvas.fps > 0 ? editorCanvas.fps : 30)
        let newPos = Math.max(0, Math.min(root.videoDuration > 0 ? root.videoDuration : 9999, root.videoPosition + delta * frameDuration))
        player.pause()
        seekVideo(newPos)
    }

    function dismiss() {
        if (player.playbackState === MediaPlayer.PlayingState) {
            player.pause()
        }
        player.stop()
        root.visible = false
        root.imagePath = ""
        root.videoPath = ""
        root.isVideo = false
        root.videoPlaying = false
        root.videoPosition = 0
        root.videoDuration = 0
        root.markIn = 0
        root.markOut = 0
        if (editorCanvas) {
            editorCanvas.clearDrawings()
        }
    }

    function openImage(path) {
        console.log("[CaptureEditor] openImage called with path:", path)
        if (player.playbackState === MediaPlayer.PlayingState) {
            player.pause()
        }
        player.stop()
        root.imagePath = path
        root.videoPath = ""
        root.isVideo = false
        root._dismissGuard = true
        root.visible = true
        editorContainer.forceActiveFocus()
        console.log("[CaptureEditor] visible set to:", root.visible)
        editorCanvas.loadAnnotationImage(path)
        dismissGuardTimer.restart()
    }

    function openVideo(path) {
        console.log("[CaptureEditor] openVideo called with path:", path)
        player.stop()
        root.imagePath = ""
        root.videoPath = path
        root.isVideo = true
        root.videoPosition = 0
        root.videoDuration = 0
        root.markIn = 0
        root.markOut = 0
        editorCanvas.loadVideo(path)
        // Set source AFTER stop to avoid binding conflicts
        player.source = Qt.resolvedUrl("file://" + path)
        root._dismissGuard = true
        root.visible = true
        // Delay forceActiveFocus slightly to avoid immediate dismiss
        focusTimer.restart()
        dismissGuardTimer.restart()
    }

    Timer {
        id: focusTimer
        interval: 80
        repeat: false
        onTriggered: editorContainer.forceActiveFocus()
    }

    // Guard: prevent accidental dismiss immediately after opening
    property bool _dismissGuard: false

    Timer {
        id: dismissGuardTimer
        interval: 500
        repeat: false
        onTriggered: root._dismissGuard = false
    }

    // Background darkening
    Rectangle {
        anchors.fill: parent
        color: ColorUtils.transparentize("#000000", 0.3)
        MouseArea {
            anchors.fill: parent
            onClicked: {
                if (!root._dismissGuard) root.dismiss()
            }
        }
    }

    // Main editor container
    Rectangle {
        id: editorContainer
        anchors.centerIn: parent
        width: Math.min(parent.width - 80, 1200)
        height: Math.min(parent.height - 80, 800)
        radius: Appearance.rounding.normal
        color: Appearance.colors.colLayer0
        border.width: 1
        border.color: Appearance.colors.colOutlineVariant

        // Absorb clicks inside the editor so they don't fall through to the
        // background MouseArea and accidentally dismiss the window.
        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.AllButtons
            onClicked: (mouse) => { mouse.accepted = true }
            onPressed: (mouse) => { mouse.accepted = true }
            z: -1
        }

        focus: true
        Keys.onPressed: (event) => {
            if (event.key === Qt.Key_Escape) {
                root.dismiss()
                event.accepted = true
            } else if ((event.modifiers & Qt.ControlModifier) && event.key === Qt.Key_Z) {
                editorCanvas.undo()
                event.accepted = true
            } else if ((event.modifiers & Qt.ControlModifier) && event.key === Qt.Key_S) {
                if (root.isVideo) {
                    root.showToast(Translation.tr("Exporting video..."))
                    editorCanvas.exportVideo(root.videoPath, root.markIn, root.markOut, function(savedPath) {
                        root.showToast(Translation.tr("Video Saved!"))
                    })
                } else {
                    editorCanvas.saveImage(root.imagePath)
                    root.showToast(Translation.tr("Saved!"))
                }
                event.accepted = true
            } else if ((event.modifiers & Qt.ControlModifier) && event.key === Qt.Key_C) {
                editorCanvas.copyToClipboard()
                root.showToast(Translation.tr("Copied!"))
                event.accepted = true
            } else if (root.isVideo && event.key === Qt.Key_Space) {
                root.togglePlayPause()
                event.accepted = true
            } else if (root.isVideo && event.key === Qt.Key_Left) {
                root.stepFrame(-1)
                event.accepted = true
            } else if (root.isVideo && event.key === Qt.Key_Right) {
                root.stepFrame(1)
                event.accepted = true
            } else if (root.isVideo && event.key === Qt.Key_I) {
                root.markIn = root.videoPosition
                root.showToast("Mark In: " + root.videoPosition.toFixed(2) + "s")
                event.accepted = true
            } else if (root.isVideo && event.key === Qt.Key_O) {
                root.markOut = root.videoPosition
                root.showToast("Mark Out: " + root.videoPosition.toFixed(2) + "s")
                event.accepted = true
            }
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 12
            spacing: 8

            // Title bar
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                MaterialSymbol {
                    text: root.isVideo ? "movie" : "photo_camera"
                    iconSize: 20
                    color: Appearance.colors.colPrimary
                }

                StyledText {
                    text: root.isVideo ? Translation.tr("Video Editor & Timeline") : Translation.tr("Screenshot Editor")
                    font.pixelSize: Appearance.font.pixelSize.normal
                    font.weight: Font.Medium
                    color: Appearance.colors.colOnLayer0
                    Layout.fillWidth: true
                }

                // Close button
                Rectangle {
                    Layout.preferredWidth: 32
                    Layout.preferredHeight: 32
                    radius: 16
                    color: closeMa.containsMouse ? Appearance.colors.colErrorContainer : "transparent"

                    MaterialSymbol {
                        anchors.centerIn: parent
                        text: "close"
                        iconSize: 18
                        color: Appearance.colors.colOnLayer0
                    }

                    MouseArea {
                        id: closeMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.dismiss()
                    }
                }
            }

            // Canvas & Video display area
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: Appearance.rounding.small
                color: Appearance.colors.colLayer1
                clip: true

                // Unified Canvas (handles background image / video output + annotations + interaction)
                EditorCanvas {
                    id: editorCanvas
                    anchors.fill: parent
                    currentTool: root.currentTool
                    currentColor: root.currentColor
                    currentWidth: root.currentWidth
                    isVideo: root.isVideo
                    videoPosition: root.videoPosition
                    videoDuration: root.videoDuration
                }
            }

            // Video timeline (only for video mode)
            VideoTimeline {
                Layout.fillWidth: true
                visible: root.isVideo
                vidDuration: root.videoDuration
                vidCurrentPos: root.videoPosition
                vidMarkIn: root.markIn
                vidMarkOut: root.markOut
                vidIsPlaying: root.videoPlaying
                fps: editorCanvas.fps
                annotations: editorCanvas.drawHistory
                selectedAnnotationIndex: editorCanvas.selectedAnnotationIndex
                onTlSeek: (pos) => root.seekVideo(pos)
                onTlStep: (delta) => root.stepFrame(delta)
                onTlMarkIn: { root.markIn = root.videoPosition }
                onTlMarkOut: { root.markOut = root.videoPosition }
                onTlPlayPause: { root.togglePlayPause() }
                onTlStop: {
                    player.pause()
                    root.seekVideo(0)
                }
                onAnnotationSelected: (idx) => {
                    editorCanvas.selectedAnnotationIndex = idx
                }
                onAnnotationRangeChanged: (idx, s, e) => {
                    editorCanvas.setAnnotationRange(idx, s, e)
                }
                onAnnotationDeleted: (idx) => {
                    editorCanvas.deleteAnnotation(idx)
                }
            }

            // Toolbar
            EditorToolbar {
                Layout.fillWidth: true
                currentTool: root.currentTool
                currentColor: root.currentColor
                currentWidth: root.currentWidth
                colorPalette: root.colorPalette
                isVideo: root.isVideo
                onToolSelected: (tool) => { root.currentTool = tool }
                onColorSelected: (color) => { root.currentColor = color }
                onStrokeWidthChanged: (w) => { root.currentWidth = w }
                onUndoRequested: { editorCanvas.undo() }
                onClearRequested: { editorCanvas.clearDrawings() }
                onSaveRequested: {
                    if (root.isVideo) {
                        root.showToast(Translation.tr("Exporting video..."))
                        editorCanvas.exportVideo(root.videoPath, root.markIn, root.markOut, function(savedPath) {
                            root.showToast(Translation.tr("Video Saved!"))
                        })
                    } else {
                        editorCanvas.saveImage(root.imagePath)
                        root.showToast(Translation.tr("Saved!"))
                    }
                }
                onCopyRequested: {
                    editorCanvas.copyToClipboard()
                    root.showToast(Translation.tr("Copied!"))
                }
            }
        }
    }

    // Status toast
    Rectangle {
        id: statusToast
        anchors.centerIn: editorContainer
        width: statusText.implicitWidth + 40
        height: 44
        radius: 22
        color: Appearance.colors.colPrimary
        opacity: 0
        visible: opacity > 0
        z: 9999

        StyledText {
            id: statusText
            anchors.centerIn: parent
            color: Appearance.colors.colOnPrimary
            font.pixelSize: Appearance.font.pixelSize.normal
            font.weight: Font.Medium
        }

        Behavior on opacity {
            NumberAnimation { duration: 200 }
        }
    }

    Timer {
        id: hideStatusTimer
        interval: 1500
        onTriggered: statusToast.opacity = 0
    }

    function showToast(msg) {
        statusText.text = msg
        statusToast.opacity = 1
        hideStatusTimer.restart()
    }

    IpcHandler {
        target: "captureEditor"

        function openImage(path: string): void {
            console.log("[CaptureEditor] IPC openImage received, path:", path)
            root.openImage(path)
        }

        function openVideo(path: string): void {
            console.log("[CaptureEditor] IPC openVideo received, path:", path)
            root.openVideo(path)
        }
    }
}

