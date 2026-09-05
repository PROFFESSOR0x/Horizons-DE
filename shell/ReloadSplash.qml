//@ pragma UseQApplication
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.modules.common
import qs.modules.common.widgets
import qs.services

Scope {
    id: root
    readonly property string runtimeDir: Quickshell.env("XDG_RUNTIME_DIR") || "/tmp"
    readonly property string statePath: runtimeDir + "/horizons-reload-state"
    readonly property string splashReadyPath: runtimeDir + "/horizons-reload-splash-ready"
    property string state: "loading"
    property bool rendered: false
    property bool closing: false
    readonly property string configuredWallpaper: Config.options.background.wallpaperPath
    readonly property bool wallpaperIsVideo: /\.(mp4|webm|mkv|avi|mov)$/i.test(configuredWallpaper)
    // Video wallpapers already have a generated still for image-based UI.
    readonly property string wallpaperSource: wallpaperIsVideo
        ? Config.options.background.thumbnailPath : configuredWallpaper

    function readState() {
        stateFile.reload()
    }
    function finish() {
        if (closing) return
        closing = true
        closeAnimation.start()
    }

    FileView {
        id: stateFile
        path: root.statePath
        onLoaded: {
            root.state = text().trim() || "loading"
            if (root.state === "ready") root.finish()
        }
        onFileChanged: reload()
    }
    // Polling only observes the real cross-process state file; it never
    // decides when to dismiss the splash.
    Timer { interval: 80; running: !root.closing; repeat: true; onTriggered: root.readState() }

    FrameAnimation {
        running: !root.rendered
        onTriggered: {
            root.rendered = true
            Quickshell.execDetached(["bash", "-c", "printf visible > '" + root.splashReadyPath.replace(/'/g, "'\\''") + "'"])
        }
    }

    Variants {
        model: Quickshell.screens
        PanelWindow {
            id: window
            required property ShellScreen modelData
            screen: modelData
            anchors { top: true; bottom: true; left: true; right: true }
            exclusionMode: ExclusionMode.Ignore
            // See Bar.qml (shell/modules/ii/bar/Bar.qml) for why this is
            // gated behind a Wayland-only Loader instead of set directly.
            Loader {
                active: WM.isWayland
                sourceComponent: Item {
                    Binding { target: window.WlrLayershell; property: "namespace"; value: "horizons:reload-splash" }
                    Binding { target: window.WlrLayershell; property: "layer"; value: WlrLayer.Overlay }
                    Binding { target: window.WlrLayershell; property: "keyboardFocus"; value: WlrKeyboardFocus.None }
                }
            }
            color: Appearance.m3colors.m3background

            Rectangle {
                id: backdrop
                anchors.fill: parent
                color: "transparent"
                opacity: root.closing ? 0 : 1

                Image {
                    anchors.fill: parent
                    source: root.wallpaperSource
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    cache: true
                }
                // Keep the user's wallpaper visible while protecting contrast
                // for the loading state and the selected Material theme.
                Rectangle {
                    anchors.fill: parent
                    color: Appearance.m3colors.m3background
                    opacity: 0.58
                }

                Rectangle {
                    id: card
                    anchors.centerIn: parent
                    width: 330
                    height: 170
                    radius: Appearance.rounding.large
                    color: Appearance.colors.colLayer1
                    border.width: 1
                    border.color: Appearance.colors.colLayer0Border

                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: 14
                        MaterialSymbol {
                            Layout.alignment: Qt.AlignHCenter
                            text: root.state === "failed" ? "error" : "progress_activity"
                            iconSize: 38
                            color: root.state === "failed" ? Appearance.m3colors.m3error : Appearance.colors.colPrimary
                            RotationAnimator on rotation {
                                running: root.state === "loading"
                                from: 0; to: 360; duration: 900
                                loops: Animation.Infinite
                            }
                        }
                        StyledText {
                            Layout.alignment: Qt.AlignHCenter
                            text: root.state === "failed" ? "Reload failed" : "Reloading Horizons"
                            font.pixelSize: Appearance.font.pixelSize.large
                            font.weight: Font.DemiBold
                            color: Appearance.colors.colOnLayer1
                        }
                        StyledText {
                            Layout.alignment: Qt.AlignHCenter
                            text: root.state === "failed" ? "The previous shell is still running" : "Preparing the shell and its panels…"
                            font.pixelSize: Appearance.font.pixelSize.small
                            color: Appearance.colors.colSubtext
                        }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    enabled: root.state === "failed"
                    onClicked: Qt.quit()
                }
            }
        }
    }

    SequentialAnimation {
        id: closeAnimation
        PauseAnimation { duration: 120 }
        ScriptAction {
            script: {
                Quickshell.execDetached(["bash", "-c", "rm -f '" + root.statePath.replace(/'/g, "'\\''") + "' '" + root.splashReadyPath.replace(/'/g, "'\\''") + "'"])
                Qt.quit()
            }
        }
    }
}
