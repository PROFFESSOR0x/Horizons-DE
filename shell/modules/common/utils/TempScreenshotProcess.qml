import QtQuick
import Quickshell
import Quickshell.Io
import qs.modules.common
import qs.modules.common.functions

Process {
    id: screenshotProc
    running: true
    property string screenshotDir: Directories.screenshotTemp
    required property ShellScreen screen
    property string screenshotPath: `${screenshotDir}/image-${screen.name}`
    // grim captures one Wayland output directly. X11 has no per-output
    // capture surface — one shared root window spans every monitor — so the
    // ImageMagick fallback crops that shared root window down to just this
    // screen's rectangle instead, using its position in the virtual desktop
    // (virtualX/virtualY, Qt's standard multi-monitor screen properties).
    // Cropping here means the result is already local-origin (0,0 = this
    // screen's own top-left) exactly like grim's per-output capture is, so
    // every consumer downstream (RegionSelection.qml's crop math,
    // ScreenshotAction.qml) needs no X11-specific changes at all.
    command: ["bash", "-c",
        `mkdir -p '${StringUtils.shellSingleQuoteEscape(screenshotDir)}' && ` +
        `if command -v grim >/dev/null 2>&1; then ` +
        `grim -o '${StringUtils.shellSingleQuoteEscape(screen.name)}' '${StringUtils.shellSingleQuoteEscape(screenshotPath)}'; ` +
        `else ` +
        `import -window root -crop ${screen.width}x${screen.height}+${screen.virtualX}+${screen.virtualY} +repage '${StringUtils.shellSingleQuoteEscape(screenshotPath)}'; ` +
        `fi`
    ]
}
