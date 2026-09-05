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

        // Respect Screen Canvas auto-open setting for images.
        // Edit action always opens the canvas — it's an explicit user request.
        // Copy action only auto-opens when autoOpenImage is true.
        const autoOpenImage = Config.options.screenCanvas.autoOpenImage

        switch (action) {
            case ScreenshotAction.Action.Copy:
                if (saveDir === "") {
                    if (autoOpenImage) {
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
                if (autoOpenImage) {
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
