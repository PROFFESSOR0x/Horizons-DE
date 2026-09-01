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

    function getCommand(x, y, width, height, screenshotPath, action, saveDir = "", shellPath = "") {
        const rx = Math.round(x);
        const ry = Math.round(y);
        const rw = Math.round(width);
        const rh = Math.round(height);
        const qsCmd = shellPath ? `qs -p '${StringUtils.shellSingleQuoteEscape(shellPath)}'` : `qs -c end4-pC`;
        // Crop to a unique temp file (unique per screenshot so editor detects new image)
        const croppedTemp = `/tmp/quickshell/media/screenshot/cropped-${Date.now()}-${Math.floor(Math.random()*10000)}.png`;
        const cropCmd = `magick '${StringUtils.shellSingleQuoteEscape(screenshotPath)}' -crop ${rw}x${rh}+${rx}+${ry} +repage '${croppedTemp}'`;
        const slurpRegion = `${rx},${ry} ${rw}x${rh}`;
        const uploadAndGetUrl = (filePath) => {
            return `curl -sF files[]=@'${StringUtils.shellSingleQuoteEscape(filePath)}' ${root.fileUploadApiEndpoint} | jq -r '.files[0].url'`
        };

        switch (action) {
            case ScreenshotAction.Action.Copy:
                if (saveDir === "") {
                    return ["bash", "-c",
                        `${cropCmd} && ` +
                        `wl-copy < '${croppedTemp}' && ` +
                        `${qsCmd} ipc call captureEditor openImage '${croppedTemp}'`
                    ]
                }
                return ["bash", "-c",
                    `mkdir -p '${StringUtils.shellSingleQuoteEscape(saveDir)}' && ` +
                    `saveFileName="screenshot-$(date '+%Y-%m-%d_%H.%M.%S').png" && ` +
                    `savePath="${saveDir}/$saveFileName" && ` +
                    `${cropCmd} && ` +
                    `cp '${croppedTemp}' "$savePath" && ` +
                    `wl-copy < '${croppedTemp}' && ` +
                    `${qsCmd} ipc call captureEditor openImage "$savePath"`
                ]

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
