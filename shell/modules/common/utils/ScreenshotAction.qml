pragma ComponentBehavior: Bound
pragma Singleton
import qs.modules.common
import qs.modules.common.utils
import qs.modules.common.functions
import qs.modules.common.widgets
import qs.services
import QtQuick
import QtQuick.Controls
import Qt.labs.synchronizer
import Quickshell

Singleton {
    id: root

    enum Action {
        Copy,
        Edit,
        Search,
        CharRecognition,
        Record,
        RecordWithSound,
        AskAi
    }

    property string imageSearchEngineBaseUrl: Config.options.search.imageSearch.imageSearchEngineBaseUrl
    property string fileUploadApiEndpoint: "https://uguu.se/upload"

    // wl-copy is Wayland-only; xclip/xsel keep every command below working on
    // the i3/X11 target too — same fallback chain (and same reasoning: avoid
    // unparenthesized `&&`/`||` precedence pitfalls) as
    // shell/modules/ii/capture/EditorCanvas.qml's clipboardCommand().
    // `source` is a shell snippet either producing bytes on stdout (piped in)
    // or empty when copying an existing file via `fromFile`.
    function clipboardFromStdin(mimeType) {
        const typeArg = mimeType ? ` --type ${mimeType}` : ""
        const xArg = mimeType ? ` -t ${mimeType}` : ""
        return `if command -v wl-copy >/dev/null 2>&1; then wl-copy${typeArg}; `
            + `elif command -v xclip >/dev/null 2>&1; then xclip -selection clipboard${xArg}; `
            + `elif command -v xsel >/dev/null 2>&1; then xsel --clipboard --input; `
            + `else cat >/dev/null; false; fi`
    }
    function clipboardFromFile(filePath, mimeType) {
        const file = `'${StringUtils.shellSingleQuoteEscape(filePath)}'`
        const xArg = mimeType ? ` -t ${mimeType}` : ""
        return `if command -v wl-copy >/dev/null 2>&1; then wl-copy${mimeType ? ` --type ${mimeType}` : ""} < ${file}; `
            + `elif command -v xclip >/dev/null 2>&1; then xclip -selection clipboard${xArg} -i ${file}; `
            + `elif command -v xsel >/dev/null 2>&1; then xsel --clipboard --input < ${file}; `
            + `else false; fi`
    }
    // grim captures the Wayland output to stdout; the X11 fallback captures
    // the whole (single, shared-across-monitors) root window the same way.
    function fullScreenCapture() {
        return `if command -v grim >/dev/null 2>&1; then grim -; else import -window root png:-; fi`
    }

    // imageResultMode "notification": crops once, then waits (notify-send
    // -w) for the user to pick exactly one of Edit/Copy/Save/OCR — nothing
    // happens automatically, unlike "editor"/"silent" which always copy.
    // Mirrors record.sh's own notify-send -w --action=... idiom for videos,
    // but that path only offers Edit/Open Folder; OCR/Copy/Save as
    // first-class choices are new here.
    function notificationCommand(cropCmd, croppedTemp, qsCmd, saveDir, format) {
        // Set SAVE_DIR as a real shell variable rather than splicing a
        // possibly-$(command-substitution) default path directly into a
        // quoted string — mixing single-quoted (literal, safely escaped)
        // and unquoted-for-substitution forms in one string is exactly the
        // kind of quoting mismatch this codebase has already been bitten by
        // (see generate-thumbnails-magick.sh's urlencode() fix history).
        const saveDirSetup = saveDir !== ""
            ? `SAVE_DIR='${StringUtils.shellSingleQuoteEscape(saveDir)}'`
            : `SAVE_DIR="$(xdg-user-dir PICTURES 2>/dev/null || echo "$HOME/Pictures")/Screenshots"`
        return `${cropCmd} && ${saveDirSetup} && ` +
            `ACTION=$(notify-send -w "Screenshot taken" "Choose what to do with it" -a 'Screenshot' ` +
            `--action="edit=Edit" --action="copy=Copy" --action="save=Save" --action="ocr=Run OCR" ` +
            `-i '${croppedTemp}' 2>/dev/null); ` +
            `case "$ACTION" in ` +
            `edit) ${qsCmd} ipc call captureEditor openImage '${croppedTemp}' ;; ` +
            `copy) ${root.clipboardFromFile(croppedTemp, "image/png")} ;; ` +
            `save) mkdir -p "$SAVE_DIR" && cp '${croppedTemp}' "$SAVE_DIR/screenshot-$(date '+%Y-%m-%d_%H.%M.%S').${format}" ;; ` +
            `ocr) tesseract '${croppedTemp}' stdout | ${root.clipboardFromStdin("")} ;; ` +
            `esac`
    }

    function fullScreenCommand() {
        const format = Config.options.screenSnip.format === "jpg" ? "jpg" : "png"
        const scale = Math.max(25, Math.min(200, Config.options.screenSnip.scalePercent ?? 100))
        const quality = Math.max(1, Math.min(100, Config.options.screenSnip.jpegQuality ?? 92))
        const convert = `magick png:- -resize ${scale}% ${format === "jpg" ? `-quality ${quality} jpg:-` : "png:-"}`
        return ["bash", "-c", `${root.fullScreenCapture()} | ${convert} | ${root.clipboardFromStdin("image/png")}`]
    }

    function getCommand(x, y, width, height, screenshotPath, action, saveDir = "", shellPath = "") {
        const rx = Math.round(x);
        const ry = Math.round(y);
        const rw = Math.round(width);
        const rh = Math.round(height);
        const qsCmd = shellPath ? `qs -p '${StringUtils.shellSingleQuoteEscape(shellPath)}'` : `qs -c horizons`;
        // Crop to a unique temp file (unique per screenshot so editor detects new image)
        const format = Config.options.screenSnip.format === "jpg" ? "jpg" : "png"
        const scale = Math.max(25, Math.min(200, Config.options.screenSnip.scalePercent ?? 100))
        const quality = Math.max(1, Math.min(100, Config.options.screenSnip.jpegQuality ?? 92))
        const croppedTemp = `/tmp/quickshell/media/screenshot/cropped-${Date.now()}-${Math.floor(Math.random()*10000)}.${format}`;
        const formatArgs = format === "jpg" ? `-quality ${quality}` : ""
        const cropCmd = `magick '${StringUtils.shellSingleQuoteEscape(screenshotPath)}' -crop ${rw}x${rh}+${rx}+${ry} +repage -resize ${scale}% ${formatArgs} '${croppedTemp}'`;
        const slurpRegion = `${rx},${ry} ${rw}x${rh}`;
        const uploadAndGetUrl = (filePath) => {
            return `curl -sF files[]=@'${StringUtils.shellSingleQuoteEscape(filePath)}' ${root.fileUploadApiEndpoint} | jq -r '.files[0].url'`
        };

        // imageResultMode replaces the old plain autoOpenImage boolean with a
        // third choice: "editor" (old true) crops+copies+opens the canvas,
        // "silent" (old false) crops+copies with no further UI, and the new
        // "notification" posts an actionable notification instead of
        // deciding anything for the user — Edit/Copy/Save/OCR are each only
        // done if that specific button is clicked, matching the 4 explicit
        // choices asked for rather than guessing which ones to also do
        // automatically.
        const imageResultMode = Config.options.screenCanvas.imageResultMode

        switch (action) {
            case ScreenshotAction.Action.Copy:
                if (imageResultMode === "notification") {
                    return ["bash", "-c", root.notificationCommand(cropCmd, croppedTemp, qsCmd, saveDir, format)]
                }
                if (saveDir === "") {
                    if (imageResultMode === "editor") {
                        return ["bash", "-c",
                            `${cropCmd} && ` +
                            `${root.clipboardFromFile(croppedTemp, "image/png")} && ` +
                            `${qsCmd} ipc call captureEditor openImage '${croppedTemp}'`
                        ]
                    } else {
                        return ["bash", "-c",
                            `${cropCmd} && ` +
                            `${root.clipboardFromFile(croppedTemp, "image/png")}`
                        ]
                    }
                }
                if (imageResultMode === "editor") {
                    return ["bash", "-c",
                        `mkdir -p '${StringUtils.shellSingleQuoteEscape(saveDir)}' && ` +
                        `saveFileName="screenshot-$(date '+%Y-%m-%d_%H.%M.%S').${format}" && ` +
                        `savePath="${saveDir}/$saveFileName" && ` +
                        `${cropCmd} && ` +
                        `cp '${croppedTemp}' "$savePath" && ` +
                        `${root.clipboardFromFile(croppedTemp, "image/png")} && ` +
                        `${qsCmd} ipc call captureEditor openImage "$savePath"`
                    ]
                } else {
                    return ["bash", "-c",
                        `mkdir -p '${StringUtils.shellSingleQuoteEscape(saveDir)}' && ` +
                        `saveFileName="screenshot-$(date '+%Y-%m-%d_%H.%M.%S').${format}" && ` +
                        `savePath="${saveDir}/$saveFileName" && ` +
                        `${cropCmd} && ` +
                        `cp '${croppedTemp}' "$savePath" && ` +
                        `${root.clipboardFromFile(croppedTemp, "image/png")}`
                    ]
                }

            case ScreenshotAction.Action.Edit:
                return ["bash", "-c",
                    `${cropCmd} && ` +
                    `${qsCmd} ipc call captureEditor openImage '${croppedTemp}'`
                ]

            case ScreenshotAction.Action.Search:
                return ["bash", "-c",
                    `${cropCmd} && ` +
                    `xdg-open "${root.imageSearchEngineBaseUrl}$(curl -sF files[]=@'${croppedTemp}' ${root.fileUploadApiEndpoint} | jq -r '.files[0].url')"`
                ]

            case ScreenshotAction.Action.CharRecognition:
                return ["bash", "-c",
                    `${cropCmd} && ` +
                    `tesseract '${croppedTemp}' stdout | ${root.clipboardFromStdin("")}`
                ]

            case ScreenshotAction.Action.Record:
                return ["bash", "-c",
                    `${Directories.recordScriptPath} --region '${slurpRegion}'`
                ]

            case ScreenshotAction.Action.RecordWithSound:
                return ["bash", "-c",
                    `${Directories.recordScriptPath} --region '${slurpRegion}' --sound`
                ]

            case ScreenshotAction.Action.AskAi:
                return ["bash", "-c",
                    `${cropCmd} && ` +
                    `${qsCmd} ipc call aiChat askAboutImage '${croppedTemp}'`
                ]

            default:
                console.warn("[ScreenshotAction] Unknown action, skipping.");
                return;
        }
    }
}
