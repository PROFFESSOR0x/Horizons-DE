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
        RecordWithSound
    }

    property string imageSearchEngineBaseUrl: Config.options.search.imageSearch.imageSearchEngineBaseUrl
    property string fileUploadApiEndpoint: "https://uguu.se/upload"

    function fullScreenCommand() {
        const format = Config.options.screenSnip.format === "jpg" ? "jpg" : "png"
        const scale = Math.max(25, Math.min(200, Config.options.screenSnip.scalePercent ?? 100))
        const quality = Math.max(1, Math.min(100, Config.options.screenSnip.jpegQuality ?? 92))
        const convert = `magick png:- -resize ${scale}% ${format === "jpg" ? `-quality ${quality} jpg:-` : "png:-"}`
        return ["bash", "-c", `grim - | ${convert} | wl-copy`]
    }

    function getCommand(x, y, width, height, screenshotPath, action, saveDir = "", shellPath = "") {
        const rx = Math.round(x);
        const ry = Math.round(y);
        const rw = Math.round(width);
        const rh = Math.round(height);
        const qsCmd = shellPath ? `qs -p '${StringUtils.shellSingleQuoteEscape(shellPath)}'` : `qs -c end4-pC`;
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
                            `wl-copy < '${croppedTemp}' && ` +
                            `${qsCmd} ipc call captureEditor openImage '${croppedTemp}'`
                        ]
                    } else {
                        return ["bash", "-c",
                            `${cropCmd} && ` +
                            `wl-copy < '${croppedTemp}'`
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
                        `wl-copy < '${croppedTemp}' && ` +
                        `${qsCmd} ipc call captureEditor openImage "$savePath"`
                    ]
                } else {
                    return ["bash", "-c",
                        `mkdir -p '${StringUtils.shellSingleQuoteEscape(saveDir)}' && ` +
                        `saveFileName="screenshot-$(date '+%Y-%m-%d_%H.%M.%S').${format}" && ` +
                        `savePath="${saveDir}/$saveFileName" && ` +
                        `${cropCmd} && ` +
                        `cp '${croppedTemp}' "$savePath" && ` +
                        `wl-copy < '${croppedTemp}'`
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
                    `tesseract '${croppedTemp}' stdout | wl-copy`
                ]

            case ScreenshotAction.Action.Record:
                return ["bash", "-c",
                    `${Directories.recordScriptPath} --region '${slurpRegion}'`
                ]

            case ScreenshotAction.Action.RecordWithSound:
                return ["bash", "-c",
                    `${Directories.recordScriptPath} --region '${slurpRegion}' --sound`
                ]

            default:
                console.warn("[ScreenshotAction] Unknown action, skipping.");
                return;
        }
    }
}
