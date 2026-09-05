pragma ComponentBehavior: Bound
import QtQuick
import QtMultimedia
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.utils
import Quickshell
import Quickshell.Io

Item {
    id: root

    property string currentTool: "pen"
    property color currentColor: "#ff0000"
    property real currentWidth: 3
    property string loadedImagePath: ""
    property bool imageReady: false

    // Video mode properties
    property bool isVideo: false
    property real videoPosition: 0
    property real videoDuration: 0
    property real fps: 30
    property real defaultAnnotationDuration: Config.options.screenCanvas.defaultAnnotationDuration || 3.0
    property int selectedAnnotationIndex: -1
    property bool saving: false
    property bool copying: false

    // Keep in sync with settings when editor is not drawing
    Connections {
        target: Config.options.screenCanvas
        function onDefaultAnnotationDurationChanged() {
            root.defaultAnnotationDuration = Config.options.screenCanvas.defaultAnnotationDuration
        }
    }
    property real videoNativeWidth: 1920
    property real videoNativeHeight: 1080
    property alias videoOutput: videoOutputItem

    property bool isDrawing: false
    property list<var> drawHistory: []
    property list<var> currentStrokePoints: []

    Component.onCompleted: {
        // Pre-create temp dirs so offscreen saveToFile never fails silently
        Quickshell.execDetached(["mkdir", "-p", "/tmp/quickshell/media/overlays"])
        Quickshell.execDetached(["mkdir", "-p", "/tmp/quickshell/media"])
    }

    // Natural dimensions (Image or Video)
    readonly property real contentNativeWidth: root.isVideo
        ? (root.videoNativeWidth > 0 ? root.videoNativeWidth : 1920)
        : (bgImage.implicitWidth > 0 ? bgImage.implicitWidth : 1)

    readonly property real contentNativeHeight: root.isVideo
        ? (root.videoNativeHeight > 0 ? root.videoNativeHeight : 1080)
        : (bgImage.implicitHeight > 0 ? bgImage.implicitHeight : 1)

    // Scale factor to fit inside available viewport preserving aspect ratio
    readonly property real fitScale: (root.width > 0 && root.height > 0 && contentNativeWidth > 0 && contentNativeHeight > 0)
        ? Math.min(root.width / contentNativeWidth, root.height / contentNativeHeight)
        : 1.0

    readonly property real displayWidth: Math.max(1, Math.round(contentNativeWidth * fitScale))
    readonly property real displayHeight: Math.max(1, Math.round(contentNativeHeight * fitScale))

    onVideoPositionChanged: {
        if (root.isVideo) {
            drawCanvas.requestPaint()
        }
    }

    function loadAnnotationImage(path) {
        console.log("[EditorCanvas] loadAnnotationImage:", path)
        root.isVideo = false
        root.drawHistory = []
        root.currentStrokePoints = []
        root.isDrawing = false
        root.imageReady = false
        root.loadedImagePath = path
        root.selectedAnnotationIndex = -1
        bgImage.source = ""
        bgImage.source = path ? ("file://" + path) : ""
    }

    function loadVideo(path) {
        console.log("[EditorCanvas] loadVideo:", path)
        root.isVideo = true
        root.drawHistory = []
        root.currentStrokePoints = []
        root.isDrawing = false
        root.imageReady = false
        root.selectedAnnotationIndex = -1
        drawCanvas.requestPaint()
    }

    function setAnnotationRange(index, startSec, endSec) {
        if (index >= 0 && index < root.drawHistory.length) {
            let h = root.drawHistory.slice()
            let item = Object.assign({}, h[index])
            let s = Math.max(0, Number(startSec.toFixed(2)))
            let e = Math.max(s, Number(endSec.toFixed(2)))
            item.startTime = s
            item.endTime = e
            item.startFrame = Math.round(s * root.fps)
            item.endFrame = Math.round(e * root.fps)
            h[index] = item
            root.drawHistory = h
            drawCanvas.requestPaint()
        }
    }

    function deleteAnnotation(index) {
        if (index >= 0 && index < root.drawHistory.length) {
            let h = root.drawHistory.slice()
            h.splice(index, 1)
            root.drawHistory = h
            if (root.selectedAnnotationIndex >= h.length) {
                root.selectedAnnotationIndex = h.length - 1
            }
            drawCanvas.requestPaint()
        }
    }

    function undo() {
        if (root.drawHistory.length > 0) {
            let h = root.drawHistory.slice()
            h.pop()
            root.drawHistory = h
            if (root.selectedAnnotationIndex >= h.length) {
                root.selectedAnnotationIndex = h.length - 1
            }
            drawCanvas.requestPaint()
        }
    }

    function clearDrawings() {
        root.drawHistory = []
        root.currentStrokePoints = []
        root.isDrawing = false
        root.selectedAnnotationIndex = -1
        drawCanvas.requestPaint()
    }

    function requestPaint() {
        drawCanvas.requestPaint()
    }

    // ---------------------------------------------------------------------------
    // Render all annotations (or a filtered subset) onto an OffscreenCanvas at
    // the given target resolution (nw × nh) and call back with the result image.
    // strokeFilter(stroke) → bool   — pass null to include every stroke.
    // ---------------------------------------------------------------------------
    function renderAnnotationsOffscreen(nw, nh, strokeFilter, callback) {
        // Ensure the overlays directory exists before the offscreen canvas
        // tries to saveToFile() into it. Without this, saveToFile silently
        // fails and the subsequent `magick ... -composite` has no input → copy fails.
        Quickshell.execDetached(["mkdir", "-p", "/tmp/quickshell/media/overlays"])
        let oc = offscreenCanvas
        oc.width  = nw
        oc.height = nh
        oc.strokeFilter   = strokeFilter
        oc.pendingCallback = callback
        oc.requestPaint()
    }

    // ---------------------------------------------------------------------------
    // saveImage  — composite background + annotations at native image resolution
    // ---------------------------------------------------------------------------
    function suggestedImageSavePath(originalPath) {
        return originalPath.indexOf(".") !== -1
            ? originalPath.replace(/\.[^.]+$/, "-edited.png")
            : originalPath + "-edited.png"
    }

    function runProcess(process, command, callback) {
        process.completion = callback
        process.command = command
        process.running = true
    }

    // Copy real PNG bytes, not a file path. wl-copy is correct on Wayland;
    // xclip/xsel keep the canvas functional for the i3/X11 target as well.
    // NOTE: previous version used `A && B || C && D` without grouping which
    // causes bash to evaluate as `((A && B) || C) && D` → runs D even when B
    // succeeded and fails when xclip/xsel are missing. Use if/elif to avoid
    // precedence pitfalls.
    function clipboardCommand(imagePath) {
        const q = StringUtils.shellSingleQuoteEscape
        const file = "'" + q(imagePath) + "'"
        return "test -s " + file + " && { "
            + "if command -v wl-copy >/dev/null 2>&1; then wl-copy --type image/png < " + file + "; "
            + "elif command -v xclip >/dev/null 2>&1; then xclip -selection clipboard -t image/png -i " + file + "; "
            + "elif command -v xsel >/dev/null 2>&1; then xsel --clipboard --input < " + file + "; "
            + "else false; fi; }"
    }

    function saveImage(originalPath, onComplete, explicitPath = "") {
        if (!originalPath) return
        const mode = Config.options.screenCanvas.imageSaveMode || "editedSuffix"
        const savePath = explicitPath || (mode === "overwrite" ? originalPath : suggestedImageSavePath(originalPath))
        const nw = root.contentNativeWidth
        const nh = root.contentNativeHeight
        root.saving = true

        function finish(success) {
            root.saving = false
            if (onComplete) onComplete(success, savePath)
        }

        // If there are no annotations just grab the container as-is (fast path).
        if (root.drawHistory.length === 0) {
            Quickshell.execDetached(["mkdir", "-p", "/tmp/quickshell/media"])
            canvasContainer.grabToImage(function(result) {
                const tmp = "/tmp/quickshell/media/qs-save-nodraw-" + Date.now() + ".png"
                result.saveToFile(tmp)
                root.runProcess(imageSaveProcess, ["bash", "-c", "mkdir -p /tmp/quickshell/media && magick '" + StringUtils.shellSingleQuoteEscape(tmp) + "' -resize " + nw + "x" + nh + "! '" + StringUtils.shellSingleQuoteEscape(savePath) + "'"], finish)
            })
            return
        }

        // Render annotations at native size on the offscreen canvas, then
        // composite them over the original image with ImageMagick.
        renderAnnotationsOffscreen(nw, nh, null, function(annPath) {
            const q = StringUtils.shellSingleQuoteEscape
            root.runProcess(imageSaveProcess, ["bash", "-c", "mkdir -p /tmp/quickshell/media/overlays && mkdir -p \"$(dirname '" + q(savePath) + "')\" && magick '" + q(originalPath) + "' '" + q(annPath) + "' -composite '" + q(savePath) + "'"], finish)
        })
    }

    // ---------------------------------------------------------------------------
    // runOcr — text recognition on the original source file (not the
    // annotated canvas: arrows/highlights/blur only ever hurt recognition
    // accuracy, they don't add real text). Reuses ScreenshotAction's own
    // wl-copy/xclip/xsel fallback chain instead of a third copy of it.
    // ---------------------------------------------------------------------------
    function runOcr(imagePath, onComplete) {
        const q = StringUtils.shellSingleQuoteEscape
        const cmd = "tesseract '" + q(imagePath) + "' stdout | " + ScreenshotAction.clipboardFromStdin("")
        root.runProcess(ocrProcess, ["bash", "-c", cmd], onComplete)
    }

    // ---------------------------------------------------------------------------
    // copyToClipboard — same composite approach, into /tmp then wl-copy
    // ---------------------------------------------------------------------------
    function copyToClipboard(onComplete) {
        const nw = root.contentNativeWidth
        const nh = root.contentNativeHeight
        root.copying = true

        function finish(success) {
            root.copying = false
            if (onComplete) onComplete(success)
        }

        if (!root.isVideo && root.drawHistory.length === 0) {
            // A screenshot already is a PNG. Copy it directly instead of
            // grabbing the visible canvas into a temporary file first: that
            // path races the renderer/file writer and was the source of the
            // intermittent "Could not copy image" failure.
            root.runProcess(clipboardProcess, [
                "bash", "-c",
                root.clipboardCommand(root.loadedImagePath)
            ], finish)
            return
        }

        if (root.isVideo) {
            // Video has no source PNG, so copy the currently rendered frame.
            Quickshell.execDetached(["mkdir", "-p", "/tmp/quickshell/media"])
            canvasContainer.grabToImage(function(result) {
                const tempPath = "/tmp/quickshell/media/capture-editor-copy-" + Date.now() + ".png"
                result.saveToFile(tempPath)
                root.runProcess(clipboardProcess, [
                    "bash", "-c",
                    "mkdir -p /tmp/quickshell/media && " + root.clipboardCommand(tempPath)
                ], finish)
            })
            return
        }

        const outTmp = "/tmp/quickshell/media/capture-editor-copy-" + Date.now() + ".png"
        // Ensure base dir exists before the async render (belt + suspenders with the
        // mkdir inside renderAnnotationsOffscreen)
        Quickshell.execDetached(["mkdir", "-p", "/tmp/quickshell/media"])
        renderAnnotationsOffscreen(nw, nh, null, function(annPath) {
            const q = StringUtils.shellSingleQuoteEscape
            root.runProcess(clipboardProcess, [
                "bash", "-c",
                "mkdir -p /tmp/quickshell/media/overlays && mkdir -p /tmp/quickshell/media && magick '" + q(root.loadedImagePath) + "' '" + q(annPath) + "' -composite '" + q(outTmp) + "' && " + root.clipboardCommand(outTmp)
            ], finish)
        })
    }

    // ---------------------------------------------------------------------------
    // exportVideo — each annotation gets its OWN overlay image at native resolution,
    //               rendered only with the strokes that belong to that annotation.
    // ---------------------------------------------------------------------------
    function exportVideo(originalPath, markIn, markOut, onComplete) {
        if (!originalPath) return
        let savePath = originalPath.indexOf(".") !== -1
            ? originalPath.replace(/\.[^.]+$/, "-edited.mp4")
            : originalPath + "-edited.mp4"

        let trimStart = Math.max(0, markIn)
        let trimEnd = (markOut > trimStart) ? markOut : -1

        // Fast path: trim only, no annotations
        if (root.drawHistory.length === 0) {
            let notifyArg = Config.options.screenCanvas.showNotifications ? ["--notify"] : []
            let cmd = [
                "python3",
                Directories.scriptPath + "/videos/export_video.py",
                "--input", originalPath,
                "--output", savePath,
                "--start", trimStart.toString(),
                "--end", trimEnd.toString(),
            ].concat(notifyArg)
            console.log("[EditorCanvas] Exporting trimmed video (no annotations):", cmd.join(" "))
            root.runProcess(videoExportProcess, cmd, success => {
                if (onComplete) onComplete(success, savePath)
            })
            return
        }

        let tmpDir = "/tmp/quickshell/media/overlays"
        Quickshell.execDetached(["mkdir", "-p", tmpDir])

        let nw = root.videoNativeWidth  > 0 ? root.videoNativeWidth  : 1920
        let nh = root.videoNativeHeight > 0 ? root.videoNativeHeight : 1080

        // Build the overlays array. Each annotation is rendered individually
        // so ffmpeg can apply independent time windows per overlay.
        let overlays = []
        let history  = root.drawHistory.slice()

        function renderNext(idx) {
            if (idx >= history.length) {
                // All annotations rendered — launch ffmpeg
                let jsonStr = JSON.stringify(overlays)
                let notifyArg2 = Config.options.screenCanvas.showNotifications ? ["--notify"] : []
                let cmd = [
                    "python3",
                    Directories.scriptPath + "/videos/export_video.py",
                    "--input", originalPath,
                    "--output", savePath,
                    "--start", trimStart.toString(),
                    "--end", trimEnd.toString(),
                    "--overlays", jsonStr,
                ].concat(notifyArg2)
                console.log("[EditorCanvas] Exporting annotated video:", cmd.join(" "))
                root.runProcess(videoExportProcess, cmd, success => {
                    if (onComplete) onComplete(success, savePath)
                })
                return
            }

            let ann     = history[idx]
            let imgPath = tmpDir + "/ann_" + Date.now() + "_" + idx + ".png"

            // Render ONLY this single annotation stroke at native resolution
            renderAnnotationsOffscreen(nw, nh, function(s) { return s === ann }, function(annPath) {
                overlays.push({
                    image: annPath,
                    start: ann.startTime !== undefined ? ann.startTime : 0,
                    end:   ann.endTime   !== undefined ? ann.endTime   : 999999
                })
                renderNext(idx + 1)
            })
        }

        renderNext(0)
    }

    Process {
        id: imageSaveProcess
        property var completion: null
        command: []
        onExited: exitCode => {
            const callback = completion
            completion = null
            if (callback) callback(exitCode === 0)
        }
    }
    Process {
        id: clipboardProcess
        property var completion: null
        command: []
        onExited: exitCode => {
            console.log("[EditorCanvas] clipboard process exited:", exitCode)
            const callback = completion
            completion = null
            if (callback) callback(exitCode === 0)
        }
    }
    Process {
        id: ocrProcess
        property var completion: null
        command: []
        onExited: exitCode => {
            const callback = completion
            completion = null
            if (callback) callback(exitCode === 0)
        }
    }
    Process {
        id: videoExportProcess
        property var completion: null
        command: []
        onExited: exitCode => {
            const callback = completion
            completion = null
            if (callback) callback(exitCode === 0)
        }
    }

    // Centered container preserving the aspect ratio of the image or video
    Item {
        id: canvasContainer
        anchors.centerIn: parent
        width: root.displayWidth
        height: root.displayHeight

        // 1. Native Image component (Image Mode)
        Image {
            id: bgImage
            anchors.fill: parent
            visible: !root.isVideo
            source: (!root.isVideo && root.loadedImagePath) ? ("file://" + root.loadedImagePath) : ""
            fillMode: Image.PreserveAspectFit
            asynchronous: false
            cache: false
            smooth: true

            onStatusChanged: {
                if (status === Image.Ready) {
                    console.log("[EditorCanvas] bgImage ready:", source, "native size:", implicitWidth, "x", implicitHeight)
                    root.imageReady = true
                    drawCanvas.requestPaint()
                } else if (status === Image.Error) {
                    console.log("[EditorCanvas] bgImage error:", source, errorString)
                }
            }
        }

        // 2. VideoOutput component (Video Mode)
        VideoOutput {
            id: videoOutputItem
            anchors.fill: parent
            visible: root.isVideo
            fillMode: VideoOutput.PreserveAspectFit
        }

        // 3. Transparent Drawing Canvas for annotations
        Canvas {
            id: drawCanvas
            anchors.fill: parent

            onAvailableChanged: {
                if (available) requestPaint()
            }
            onWidthChanged: requestPaint()
            onHeightChanged: requestPaint()

            onPaint: {
                let ctx = getContext("2d")
                ctx.clearRect(0, 0, width, height)

                if (!root.isVideo) {
                    // Image mode: draw all strokes
                    for (let i = 0; i < root.drawHistory.length; i++) {
                        drawStroke(ctx, root.drawHistory[i], width, height)
                    }
                } else {
                    // Video mode: draw strokes active at current video position
                    let cur = root.videoPosition
                    for (let i = 0; i < root.drawHistory.length; i++) {
                        let s = root.drawHistory[i]
                        let st = (s.startTime !== undefined) ? s.startTime : 0
                        let et = (s.endTime !== undefined) ? s.endTime : 999999
                        if (cur >= st && cur <= et) {
                            drawStroke(ctx, s, width, height)
                        }
                    }
                }

                // Live preview of current stroke being drawn.
                // Live points are already in [0,1] normalized space (set by MouseArea).
                if (root.isDrawing && root.currentStrokePoints.length > 0) {
                    drawStroke(ctx, {
                        tool: root.currentTool,
                        color: root.currentColor.toString(),
                        width: root.currentWidth,
                        widthNorm: width > 0 ? root.currentWidth / width : 0,
                        points: root.currentStrokePoints
                    }, width, height)
                }
            }

            // drawStroke renders a stroke whose points are stored in [0,1] normalised
            // space onto a canvas of size (cw × ch).
            // Pass the target canvas dimensions so this same function works both for
            // the on-screen preview (cw = drawCanvas.width) and for the full-resolution
            // export canvas (cw = contentNativeWidth).
            function drawStroke(ctx, stroke, cw, ch) {
                ctx.save()
                ctx.strokeStyle = stroke.color
                ctx.fillStyle = stroke.color

                // Resolve stroke width in pixels for this canvas size.
                // Prefer the normalised width (stored at draw time) so the line
                // scales proportionally; fall back to the raw pixel width when the
                // stroke was created before normalisation was introduced.
                let pw = stroke.widthNorm > 0
                    ? stroke.widthNorm * cw
                    : stroke.width

                ctx.lineWidth = pw
                ctx.lineCap = "round"
                ctx.lineJoin = "round"

                // Convert a normalised point to canvas pixels
                function px(p) { return p.x * cw }
                function py(p) { return p.y * ch }

                let pts = stroke.points
                if (!pts || pts.length === 0) { ctx.restore(); return }
                let p1 = pts[0]
                let p2 = pts[pts.length - 1]

                switch (stroke.tool) {
                case "pen":
                    if (pts.length === 1) {
                        ctx.beginPath()
                        ctx.arc(px(p1), py(p1), Math.max(1, pw / 2), 0, 2 * Math.PI)
                        ctx.fill()
                    } else {
                        ctx.beginPath()
                        ctx.moveTo(px(p1), py(p1))
                        for (let i = 1; i < pts.length; i++) {
                            ctx.lineTo(px(pts[i]), py(pts[i]))
                        }
                        ctx.stroke()
                    }
                    break
                case "arrow":
                    ctx.beginPath()
                    ctx.moveTo(px(p1), py(p1))
                    ctx.lineTo(px(p2), py(p2))
                    ctx.stroke()
                    let ang = Math.atan2(py(p2) - py(p1), px(p2) - px(p1))
                    let hl = 15 + pw * 2
                    ctx.beginPath()
                    ctx.moveTo(px(p2), py(p2))
                    ctx.lineTo(px(p2) - hl * Math.cos(ang - Math.PI / 6), py(p2) - hl * Math.sin(ang - Math.PI / 6))
                    ctx.moveTo(px(p2), py(p2))
                    ctx.lineTo(px(p2) - hl * Math.cos(ang + Math.PI / 6), py(p2) - hl * Math.sin(ang + Math.PI / 6))
                    ctx.stroke()
                    break
                case "rect":
                    ctx.strokeRect(px(p1), py(p1), px(p2) - px(p1), py(p2) - py(p1))
                    break
                case "circle":
                    ctx.beginPath()
                    ctx.ellipse(
                        (px(p1) + px(p2)) / 2, (py(p1) + py(p2)) / 2,
                        Math.abs(px(p2) - px(p1)) / 2, Math.abs(py(p2) - py(p1)) / 2,
                        0, 0, 2 * Math.PI
                    )
                    ctx.stroke()
                    break
                case "blur": {
                    // gridSize and radius are relative to the canvas width so they
                    // scale correctly at export resolution.
                    let gridSize = Math.max(8, Math.round(pw * 1.5))
                    let radius   = Math.max(12, pw * 3.5)
                    let cells = {}

                    function addPointCells(bx, by) {
                        let minGx = Math.floor((bx - radius) / gridSize)
                        let maxGx = Math.floor((bx + radius) / gridSize)
                        let minGy = Math.floor((by - radius) / gridSize)
                        let maxGy = Math.floor((by + radius) / gridSize)
                        let r2 = radius * radius

                        for (let gx = minGx; gx <= maxGx; gx++) {
                            for (let gy = minGy; gy <= maxGy; gy++) {
                                let cellCenterX = (gx + 0.5) * gridSize
                                let cellCenterY = (gy + 0.5) * gridSize
                                let dx = cellCenterX - bx
                                let dy = cellCenterY - by
                                if (dx * dx + dy * dy <= r2) {
                                    cells[gx + "_" + gy] = { gx: gx, gy: gy }
                                }
                            }
                        }
                    }

                    if (pts.length === 1) {
                        addPointCells(px(pts[0]), py(pts[0]))
                    } else {
                        for (let i = 0; i < pts.length - 1; i++) {
                            let pA = pts[i]
                            let pB = pts[i + 1]
                            let dist = Math.hypot(px(pB) - px(pA), py(pB) - py(pA))
                            let steps = Math.max(1, Math.ceil(dist / (gridSize / 2)))
                            for (let s = 0; s <= steps; s++) {
                                let t = s / steps
                                let ix = px(pA) + (px(pB) - px(pA)) * t
                                let iy = py(pA) + (py(pB) - py(pA)) * t
                                addPointCells(ix, iy)
                            }
                        }
                    }

                    // Render all activated mosaic pixel tiles
                    for (let key in cells) {
                        let cell = cells[key]
                        let bx = cell.gx * gridSize
                        let by = cell.gy * gridSize

                        // Hash for consistent mosaic variation based on coordinates
                        let hv = Math.abs(Math.sin(cell.gx * 12.9898 + cell.gy * 78.233) * 43758.5453)
                        let val = Math.floor(130 + (hv % 1) * 75) // 130 to 205

                        ctx.fillStyle = "rgba(" + val + "," + val + "," + val + ",0.94)"
                        ctx.fillRect(bx, by, gridSize, gridSize)

                        ctx.strokeStyle = "rgba(0, 0, 0, 0.1)"
                        ctx.lineWidth = 1
                        ctx.strokeRect(bx + 0.5, by + 0.5, gridSize - 1, gridSize - 1)
                    }
                    break
                }
                case "highlight":
                    if (stroke.color.startsWith("#")) {
                        let r = parseInt(stroke.color.slice(1, 3), 16)
                        let g = parseInt(stroke.color.slice(3, 5), 16)
                        let b = parseInt(stroke.color.slice(5, 7), 16)
                        ctx.fillStyle = "rgba(" + r + "," + g + "," + b + ",0.35)"
                    } else {
                        ctx.fillStyle = "rgba(255,255,0,0.35)"
                    }
                    ctx.fillRect(
                        Math.min(px(p1), px(p2)), Math.min(py(p1), py(p2)),
                        Math.abs(px(p2) - px(p1)), Math.abs(py(p2) - py(p1))
                    )
                    break
                }
                ctx.restore()
            }
        }

        // 4. MouseArea over the image/video canvas container
        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.CrossCursor
            enabled: root.currentTool !== "none"
            hoverEnabled: true

            // Normalize a canvas pixel coordinate to [0,1] range
            function normX(px) { return canvasContainer.width  > 0 ? px / canvasContainer.width  : 0 }
            function normY(py) { return canvasContainer.height > 0 ? py / canvasContainer.height : 0 }

            onPressed: (mouse) => {
                root.isDrawing = true
                root.currentStrokePoints = [{ x: normX(mouse.x), y: normY(mouse.y) }]
                drawCanvas.requestPaint()
            }
            onPositionChanged: (mouse) => {
                if (root.isDrawing) {
                    let cx = Math.max(0, Math.min(canvasContainer.width,  mouse.x))
                    let cy = Math.max(0, Math.min(canvasContainer.height, mouse.y))
                    let pts = root.currentStrokePoints.slice()
                    pts.push({ x: normX(cx), y: normY(cy) })
                    root.currentStrokePoints = pts
                    drawCanvas.requestPaint()
                }
            }
            onReleased: (mouse) => {
                if (root.isDrawing) {
                    let cx = Math.max(0, Math.min(canvasContainer.width,  mouse.x))
                    let cy = Math.max(0, Math.min(canvasContainer.height, mouse.y))
                    let pts = root.currentStrokePoints.slice()
                    pts.push({ x: normX(cx), y: normY(cy) })
                    if (pts.length === 1) {
                        pts.push({ x: normX(cx) + 0.0001, y: normY(cy) + 0.0001 })
                    }
                    let strokeObj = {
                        tool: root.currentTool,
                        color: root.currentColor.toString(),
                        // Store stroke width also normalized to canvas width so it
                        // scales correctly when rendered at different resolutions.
                        width: root.currentWidth,
                        widthNorm: canvasContainer.width > 0 ? root.currentWidth / canvasContainer.width : 0,
                        points: pts   // points are in [0,1] normalized space
                    }
                    if (root.isVideo) {
                        let sTime = Math.max(0, root.videoPosition)
                        let eTime = (root.videoDuration > 0)
                            ? Math.min(root.videoDuration, sTime + root.defaultAnnotationDuration)
                            : sTime + root.defaultAnnotationDuration
                        strokeObj.startTime  = Number(sTime.toFixed(2))
                        strokeObj.endTime    = Number(eTime.toFixed(2))
                        strokeObj.startFrame = Math.round(sTime * root.fps)
                        strokeObj.endFrame   = Math.round(eTime * root.fps)
                    }
                    let h = root.drawHistory.slice()
                    h.push(strokeObj)
                    root.drawHistory = h
                    root.selectedAnnotationIndex = h.length - 1
                    root.currentStrokePoints = []
                    root.isDrawing = false
                    drawCanvas.requestPaint()
                }
            }
        }
    }

    // ---------------------------------------------------------------------------
    // Offscreen Canvas — used exclusively for rendering annotations at native
    // resolution for export. Never visible on screen.
    // ---------------------------------------------------------------------------
    Canvas {
        id: offscreenCanvas
        visible: false
        width:  1
        height: 1

        // Set by renderAnnotationsOffscreen() before each requestPaint() call.
        property var strokeFilter:    null   // function(stroke)→bool or null = all
        property var pendingCallback: null   // function(imagePath)

        onPaint: {
            let ctx = getContext("2d")
            ctx.clearRect(0, 0, width, height)

            let history = root.drawHistory
            for (let i = 0; i < history.length; i++) {
                let s = history[i]
                if (strokeFilter === null || strokeFilter(s)) {
                    drawCanvas.drawStroke(ctx, s, width, height)
                }
            }

            // Grab immediately after painting and invoke the callback
            let cb   = pendingCallback
            let tmpP = "/tmp/quickshell/media/overlays/oc_" + Date.now() + "_" + Math.random().toString(36).slice(2) + ".png"
            pendingCallback = null
            strokeFilter    = null

            grabToImage(function(result) {
                result.saveToFile(tmpP)
                if (cb) cb(tmpP)
            })
        }
    }
}
