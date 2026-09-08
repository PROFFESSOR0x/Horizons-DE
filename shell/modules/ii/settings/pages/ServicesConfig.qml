import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.common.widgets

ContentPage {
    id: page
    forceWidth: true
    bottomContentPadding: 15

    //This was intended to go into the results more deeply but in the end I didn't like it but I left it just in case lol
    function goTo(term) {
        const t = term.toLowerCase().trim()

        function findTarget(rootItem) {
            for (let i = 0; i < rootItem.children.length; i++) {
                let child = rootItem.children[i]
                if (child.title && child.title.toLowerCase().includes(t)) {
                    return child
                }
            }

            for (let i = 0; i < rootItem.children.length; i++) {
                let found = findTarget(rootItem.children[i])
                if (found) return found
            }
            return null
        }

        let target = findTarget(mainLayout)
        if (target) {
            let pos = target.mapToItem(mainLayout, 0, 0)
            page.contentY = Math.max(0, pos.y - 0)
        }
    }

    ColumnLayout {
        visible: page.settingsShow("about|apps|capture|capture-details|integrations|system");
        id: mainLayout
        Layout.fillWidth: true
        Layout.fillHeight: true
        spacing: 20

        ContentSection {
            visible: page.settingsShow("integrations");
            icon: "neurology"
            shape: MaterialShape.Shape.Ghostish
            title: Translation.tr("AI")

            MaterialTextArea {
                visible: page.settingsShow("integrations");
                objectName: "ServicesConfig.system-prompt";
                Layout.fillWidth: true
                placeholderText: Translation.tr("System prompt")
                text: Config.options.ai.systemPrompt
                wrapMode: TextEdit.Wrap
                onTextChanged: {
                    if (!activeFocus) return
                    Qt.callLater(() => {
                        Config.options.ai.systemPrompt = text;
                    });
                }
            }
        }

        ContentSection {
            visible: page.settingsShow("integrations");
            icon: "cell_tower"
            shape: MaterialShape.Shape.PixelCircle
            title: Translation.tr("Networking")

            MaterialTextArea {
                visible: page.settingsShow("integrations");
                objectName: "ServicesConfig.user-agent-for-services-that-require-it";
                Layout.fillWidth: true
                placeholderText: Translation.tr("User agent (for services that require it)")
                text: Config.options.networking.userAgent
                wrapMode: TextEdit.Wrap
                onTextChanged: {
                    if (!activeFocus) return
                    Config.options.networking.userAgent = text;
                }
            }
        }

        ContentSection {
            visible: page.settingsShow("integrations");
            icon: "music_cast"
            shape: MaterialShape.Shape.Oval
            title: Translation.tr("Music Recognition")

            GroupedList {
                compact: true;
                visible: page.settingsShow("integrations")
                ConfigSpinBox {
                    visible: page.settingsShow("integrations");
                    objectName: "ServicesConfig.total-duration-timeout-s";
                    icon: "timer_off"
                    text: Translation.tr("Total duration timeout (s)")
                    value: Config.options.musicRecognition.timeout
                    from: 10
                    to: 100
                    stepSize: 2
                    onEdited: {
                        Config.options.musicRecognition.timeout = value;
                    }
                }
                ConfigSpinBox {
                    visible: page.settingsShow("integrations");
                    objectName: "ServicesConfig.polling-interval-s";
                    icon: "av_timer"
                    text: Translation.tr("Polling interval (s)")
                    value: Config.options.musicRecognition.interval
                    from: 2
                    to: 10
                    stepSize: 1
                    onEdited: {
                        Config.options.musicRecognition.interval = value;
                    }
                }
            }
        }

        ContentSection {
            visible: page.settingsShow("capture");
            icon: "file_open"
            shape: MaterialShape.Shape.Slanted
            title: Translation.tr("Save paths")

            GroupedList {
                compact: true;
                visible: page.settingsShow("capture")
                ConfigTextArea {
                    visible: page.settingsShow("capture");
                    objectName: "ServicesConfig.video-recording-path";
                    id: videoRecordPathField
                    Layout.fillWidth: true
                    fieldWidth: 250
                    buttonIcon: "video_file"
                    text: Translation.tr("Video Recording Path")
                    value: Config.options.screenRecord.savePath
                    onEdited: {
                        videoRecordPathDebounceTimer.restart();
                    }

                    Timer {
                        id: videoRecordPathDebounceTimer
                        interval: 600
                        repeat: false
                        onTriggered: {
                            Config.options.screenRecord.savePath = videoRecordPathField.value;
                        }
                    }
                }

                ConfigTextArea {
                    visible: page.settingsShow("capture");
                    objectName: "ServicesConfig.screenshot-path-leave-empty-to-just-copy";
                    id: screenshotPathField
                    Layout.fillWidth: true
                    fieldWidth: 250
                    buttonIcon: "screenshot_monitor"
                    text: Translation.tr("Screenshot Path (leave empty to just copy)")
                    value: Config.options.screenSnip.savePath
                    onEdited: {
                        screenshotPathDebounceTimer.restart();
                    }

                    Timer {
                        id: screenshotPathDebounceTimer
                        interval: 600
                        repeat: false
                        onTriggered: {
                            Config.options.screenSnip.savePath = screenshotPathField.value;
                        }
                    }
                }
            }
        }

        ContentSection {
            visible: page.settingsShow("capture|capture-details");
            icon: "screenshot_monitor"
            shape: MaterialShape.Shape.PixelCircle
            title: Translation.tr("Capture quality")

            ContentSubsection {
                visible: page.settingsShow("capture-details");
                title: Translation.tr("Screenshots")
                GroupedList {
                    compact: true;
                    visible: page.settingsShow("capture-details")
                    ConfigSpinBox {
                        visible: page.settingsShow("capture-details");
                        objectName: "ServicesConfig.image-scale";
                        icon: "zoom_out_map"
                        text: Translation.tr("Image scale (%)")
                        value: Config.options.screenSnip.scalePercent
                        from: 25; to: 200; stepSize: 5
                        onEdited: Config.options.screenSnip.scalePercent = value
                    }
                    ConfigSelectionArray {
                        visible: page.settingsShow("capture-details");
                        objectName: "ServicesConfig.screenshot-format";
                        icon: "image"
                        text: Translation.tr("Screenshot format")
                        currentValue: Config.options.screenSnip.format
                        onSelected: newValue => Config.options.screenSnip.format = newValue
                        options: [
                            { displayName: "PNG", icon: "lossless", value: "png" },
                            { displayName: "JPEG", icon: "photo", value: "jpg" }
                        ]
                    }
                    ConfigSpinBox {
                        visible: page.settingsShow("capture-details");
                        objectName: "ServicesConfig.jpeg-quality";
                        icon: "high_quality"
                        text: Translation.tr("JPEG quality")
                        enabled: Config.options.screenSnip.format === "jpg"
                        value: Config.options.screenSnip.jpegQuality
                        from: 50; to: 100; stepSize: 1
                        onEdited: Config.options.screenSnip.jpegQuality = value
                    }
                }
            }

            ContentSubsection {
                visible: page.settingsShow("capture|capture-details");
                title: Translation.tr("Screen recording")
                GroupedList {
                    compact: true;
                    visible: page.settingsShow("capture|capture-details")
                    ConfigRow {
                        visible: page.settingsShow("capture-details");
                        uniform: true
                        ConfigSpinBox {
                            visible: page.settingsShow("capture-details");
                            objectName: "ServicesConfig.frame-rate";
                            icon: "speed"
                            text: Translation.tr("Frame rate")
                            value: Config.options.screenRecord.frameRate
                            from: 15; to: 120; stepSize: 5
                            onEdited: Config.options.screenRecord.frameRate = value
                        }
                        ConfigComboBox {
                            objectName: "ServicesConfig.codec";
                            visible: page.settingsShow("capture-details");

                            buttonIcon: "video_settings"
                            text: Translation.tr("Codec")
                            currentValue: Config.options.screenRecord.codec
                            onSelected: newValue => Config.options.screenRecord.codec = newValue
                            model: [
                                { displayName: "H.264", value: "libx264" },
                                { displayName: "HEVC", value: "libx265" },
                                { displayName: "VP9", value: "libvpx-vp9" }
                            ]
                        }
                    }
                    ConfigSelectionArray {
                        visible: page.settingsShow("capture-details");
                        objectName: "ServicesConfig.recording-quality";
                        icon: "equalizer"
                        text: Translation.tr("Recording quality")
                        currentValue: Config.options.screenRecord.quality
                        onSelected: newValue => Config.options.screenRecord.quality = newValue
                        options: [
                            { displayName: Translation.tr("Balanced"), icon: "tune", value: "balanced" },
                            { displayName: Translation.tr("High"), icon: "high_quality", value: "high" },
                            { displayName: Translation.tr("Archive"), icon: "inventory_2", value: "archive" }
                        ]
                    }
                    ConfigSelectionArray {
                        visible: page.settingsShow("capture");
                        objectName: "ServicesConfig.audio-capture";
                        icon: "graphic_eq"
                        text: Translation.tr("Audio capture")
                        currentValue: Config.options.screenRecord.audioMode
                        onSelected: newValue => Config.options.screenRecord.audioMode = newValue
                        options: [
                            { displayName: Translation.tr("None"), icon: "volume_off", value: "none" },
                            { displayName: Translation.tr("System output"), icon: "volume_up", value: "output" },
                            { displayName: Translation.tr("Microphone"), icon: "mic", value: "microphone" },
                            { displayName: Translation.tr("Mixed source (PipeWire)"), icon: "surround_sound", value: "both" }
                        ]
                    }
                    ConfigTextArea {
                        visible: page.settingsShow("capture-details");
                        objectName: "ServicesConfig.output-source-override";
                        Layout.fillWidth: true
                        fieldWidth: 300
                        buttonIcon: "speaker"
                        text: Translation.tr("Output source override")
                        description: Translation.tr("Optional PipeWire/Pulse source name. For mixed audio, use a pre-mixed PipeWire source here.")
                        value: Config.options.screenRecord.outputSource
                        onEdited: Config.options.screenRecord.outputSource = value
                    }
                    ConfigTextArea {
                        visible: page.settingsShow("capture-details");
                        objectName: "ServicesConfig.microphone-source-override";
                        Layout.fillWidth: true
                        fieldWidth: 300
                        buttonIcon: "mic"
                        text: Translation.tr("Microphone source override")
                        description: Translation.tr("Optional source name. Leave empty for the default microphone.")
                        value: Config.options.screenRecord.microphoneSource
                        onEdited: Config.options.screenRecord.microphoneSource = value
                    }
                }
            }
        }

        ContentSection {
            visible: page.settingsShow("apps|integrations");
            icon: "search"
            shape: MaterialShape.Shape.Cookie6Sided
            title: Translation.tr("Search")

            GroupedList {
                compact: true;
                visible: page.settingsShow("apps|integrations")
                ConfigSelectionArray {
                    visible: page.settingsShow("apps");
                    objectName: "ServicesConfig.launcher";
                    icon: "rocket_launch"
                    text: Translation.tr("Launcher")
                    currentValue: Config.options.apps.launcher
                    onSelected: newValue => { Config.options.apps.launcher = newValue }
                    options: [
                        { displayName: Translation.tr("Quickshell (built-in)"), icon: "search", value: "quickshell" },
                        { displayName: Translation.tr("Walker"), icon: "rocket_launch", value: "walker" },
                        { displayName: Translation.tr("Vicinae"), icon: "auto_awesome", value: "vicinae" },
                        { displayName: Translation.tr("Fuzzel"), icon: "list", value: "fuzzel" }
                    ]
                }
                StyledText {
                    property bool groupDescription: true;
                    visible: page.settingsShow("apps");
                    Layout.fillWidth: true
                    wrapMode: Text.Wrap
                    color: Appearance.colors.colSubtext
                    font.pixelSize: Appearance.font.pixelSize.small
                    text: Translation.tr("What tapping Super opens. \"Quickshell\" is this shell's own built-in search/overview and needs nothing extra. The other three are separate apps — install them (and their background service, where needed) *before* switching to one here, or Super will just do nothing:\n"
                        + "• Walker + its \"elephant\" search backend — installer.sh --launchers walker (or answer \"yes\" when it asks). It also enables the elephant user service for you.\n"
                        + "• Vicinae + its \"vicinae-server\" daemon — installer.sh --launchers vicinae (or answer \"yes\" when it asks). It also enables the vicinae user service for you.\n"
                        + "• Fuzzel is already installed as a core dependency and works standalone, no extra service needed.\n"
                        + "Re-run installer.sh any time to add Walker/Vicinae later — it never changes this setting for you, so come back here and pick one once it's installed.")
                }
                ConfigSwitch {
                    visible: page.settingsShow("integrations");
                    objectName: "ServicesConfig.use-levenshtein-distance-based-algorithm-instead-of-fuzzy";
                    text: Translation.tr("Use Levenshtein distance-based algorithm instead of fuzzy")
                    checked: Config.options.search.sloppy
                    onEdited: {
                        Config.options.search.sloppy = checked;
                    }
                }
            }

            ContentSubsection {
                visible: page.settingsShow("integrations");
                title: Translation.tr("Prefixes")

                GroupedList {
                    compact: true;
                    visible: page.settingsShow("integrations")
                    ConfigRow {
                        visible: page.settingsShow("integrations");
                        uniform: true
                        ConfigTextArea {
                            visible: page.settingsShow("integrations");
                            objectName: "ServicesConfig.action";
                            Layout.fillWidth: true
                            buttonIcon: "bolt"
                            fieldWidth: 100
                            text: Translation.tr("Action")
                            value: Config.options.search.prefix.action
                            onEdited: {
                                Config.options.search.prefix.action = value;
                            }
                        }
                        ConfigTextArea {
                            visible: page.settingsShow("integrations");
                            objectName: "ServicesConfig.clipboard";
                            Layout.fillWidth: true
                            buttonIcon: "content_paste"
                            fieldWidth: 100
                            text: Translation.tr("Clipboard")
                            value: Config.options.search.prefix.clipboard
                            onEdited: {
                                Config.options.search.prefix.clipboard = value;
                            }
                        }
                    }

                    ConfigRow {
                        visible: page.settingsShow("integrations");
                        uniform: true
                        ConfigTextArea {
                            visible: page.settingsShow("integrations");
                            objectName: "ServicesConfig.emojis";
                            Layout.fillWidth: true
                            buttonIcon: "mood"
                            fieldWidth: 100
                            text: Translation.tr("Emojis")
                            value: Config.options.search.prefix.emojis
                            onEdited: {
                                Config.options.search.prefix.emojis = value;
                            }
                        }
                        ConfigTextArea {
                            visible: page.settingsShow("integrations");
                            objectName: "ServicesConfig.icons";
                            Layout.fillWidth: true
                            buttonIcon: "emoji_symbols"
                            fieldWidth: 100
                            text: Translation.tr("Icons")
                            value: Config.options.search.prefix.symbols
                            onEdited: {
                                Config.options.search.prefix.symbols = value;
                            }
                        }
                    }

                    ConfigRow {
                        visible: page.settingsShow("integrations");
                        uniform: true
                        ConfigTextArea {
                            visible: page.settingsShow("integrations");
                            objectName: "ServicesConfig.shell-command";
                            Layout.fillWidth: true
                            buttonIcon: "terminal"
                            fieldWidth: 100
                            text: Translation.tr("Shell command")
                            value: Config.options.search.prefix.shellCommand
                            onEdited: {
                                Config.options.search.prefix.shellCommand = value;
                            }
                        }
                        ConfigTextArea {
                            visible: page.settingsShow("integrations");
                            objectName: "ServicesConfig.web-search";
                            Layout.fillWidth: true
                            fieldWidth: 100
                            buttonIcon: "travel_explore"
                            text: Translation.tr("Web search")
                            value: Config.options.search.prefix.webSearch
                            onEdited: {
                                Config.options.search.prefix.webSearch = value;
                            }
                        }
                    }

                    ConfigRow {
                        visible: page.settingsShow("integrations");
                        uniform: true
                        ConfigTextArea {
                            visible: page.settingsShow("integrations");
                            objectName: "ServicesConfig.apps";
                            Layout.fillWidth: true
                            buttonIcon: "apps"
                            fieldWidth: 100
                            text: Translation.tr("Apps")
                            value: Config.options.search.prefix.app
                            onEdited: {
                                Config.options.search.prefix.app = value;
                            }
                        }
                        ConfigTextArea {
                            visible: page.settingsShow("integrations");
                            objectName: "ServicesConfig.keybinds";
                            Layout.fillWidth: true
                            buttonIcon: "keyboard_command_key"
                            fieldWidth: 100
                            text: Translation.tr("Keybinds")
                            value: Config.options.search.prefix.keybinds
                            onEdited: {
                                Config.options.search.prefix.keybinds = value;
                            }
                        }
                    }

                    ConfigRow {
                        visible: page.settingsShow("integrations");
                        uniform: true
                        ConfigTextArea {
                            visible: page.settingsShow("integrations");
                            objectName: "ServicesConfig.files";
                            Layout.fillWidth: true
                            buttonIcon: "description"
                            fieldWidth: 100
                            text: Translation.tr("Files")
                            value: Config.options.search.prefix.files
                            onEdited: {
                                Config.options.search.prefix.files = value;
                            }
                        }
                        ConfigTextArea {
                            visible: page.settingsShow("integrations");
                            objectName: "ServicesConfig.ssh-hosts";
                            Layout.fillWidth: true
                            buttonIcon: "dns"
                            fieldWidth: 100
                            text: Translation.tr("SSH hosts")
                            value: Config.options.search.prefix.sshHosts
                            onEdited: {
                                Config.options.search.prefix.sshHosts = value;
                            }
                        }
                    }
                    ConfigRow {
                        visible: page.settingsShow("integrations");
                        uniform: true
                        ConfigTextArea {
                            visible: page.settingsShow("integrations");
                            objectName: "ServicesConfig.system-services";
                            Layout.fillWidth: true
                            buttonIcon: "settings_applications"
                            fieldWidth: 100
                            text: Translation.tr("System services")
                            value: Config.options.search.prefix.systemServices
                            onEdited: {
                                Config.options.search.prefix.systemServices = value;
                            }
                        }
                    }
                    ConfigSwitch {
                        visible: page.settingsShow("integrations");
                        objectName: "ServicesConfig.show-actions-without-typing-their-prefix";
                        buttonIcon: "bolt"
                        text: Translation.tr("Show actions without typing their prefix")
                        checked: Config.options.search.prefix.showActionsWithoutPrefix
                        onEdited: { Config.options.search.prefix.showActionsWithoutPrefix = checked }
                    }
                    ConfigSwitch {
                        visible: page.settingsShow("integrations");
                        objectName: "ServicesConfig.show-files-without-typing-their-prefix";
                        buttonIcon: "description"
                        text: Translation.tr("Show files without typing their prefix")
                        checked: Config.options.search.prefix.showFilesWithoutPrefix
                        onEdited: { Config.options.search.prefix.showFilesWithoutPrefix = checked }
                    }
                    ConfigSpinBox {
                        objectName: "ServicesConfig.minimum-characters-before-searching-files";
                        visible: page.settingsShow("integrations") && (Config.options.search.prefix.showFilesWithoutPrefix)
                        icon: "text_fields"
                        text: Translation.tr("Minimum characters before searching files")
                        value: Config.options.search.prefix.filesWithoutPrefixMinLength
                        from: 1; to: 8; stepSize: 1
                        onEdited: {
                            if (value === Config.options.search.prefix.filesWithoutPrefixMinLength) return
                            Config.options.search.prefix.filesWithoutPrefixMinLength = value
                        }
                    }
                    StyledText {
                        property bool groupDescription: true;
                        visible: page.settingsShow("integrations");
                        Layout.fillWidth: true
                        wrapMode: Text.Wrap
                        color: Appearance.colors.colSubtext
                        font.pixelSize: Appearance.font.pixelSize.small
                        text: Translation.tr("With these on, actions and files also appear in an ordinary search, after the app results, instead of only behind their prefix character. Each new file search term runs one plocate query, which is why there's a minimum length.")
                    }
                    StyledText {
                        property bool groupDescription: true;
                        visible: page.settingsShow("integrations");
                        Layout.fillWidth: true
                        wrapMode: Text.Wrap
                        color: Appearance.colors.colSubtext
                        font.pixelSize: Appearance.font.pixelSize.small
                        text: Translation.tr("Files searches plocate's system-wide index (falls back to mlocate's locate, then a live find under $HOME if neither index exists yet — run `sudo updatedb` once after installing plocate). System services lists systemd user + system units; starting/stopping/restarting a system-wide one prompts for authentication via pkexec.")
                    }
                }
            }
            ContentSubsection {
                visible: page.settingsShow("apps");
                id: defaultApplicationsSection
                title: Translation.tr("Default applications by file type")
                property string pendingDesktopFile: ""
                property var pendingMimeTypes: []

                function scheduleDefaultApplication(desktopFile, mimeTypes) {
                    pendingDesktopFile = desktopFile
                    pendingMimeTypes = mimeTypes
                    defaultApplicationCommit.restart()
                }

                Timer {
                    id: defaultApplicationCommit
                    interval: 550
                    repeat: false
                    onTriggered: SystemTheming.applyDefaultApplication(
                        defaultApplicationsSection.pendingDesktopFile,
                        defaultApplicationsSection.pendingMimeTypes)
                }

                GroupedList {
                    compact: true;
                    visible: page.settingsShow("apps")
                    ConfigTextArea {
                        visible: page.settingsShow("apps");
                        objectName: "ServicesConfig.web-links";
                        buttonIcon: "language"
                        text: Translation.tr("Web links")
                        description: Translation.tr("Desktop-entry ID, e.g. firefox.desktop")
                        value: Config.options.apps.defaultApplications.browser
                        onEdited: {
                            Config.options.apps.defaultApplications.browser = value
                            defaultApplicationsSection.scheduleDefaultApplication(value, ["x-scheme-handler/http", "x-scheme-handler/https", "text/html"])
                        }
                    }
                    ConfigTextArea {
                        visible: page.settingsShow("apps");
                        objectName: "ServicesConfig.folders";
                        buttonIcon: "folder"
                        text: Translation.tr("Folders")
                        description: Translation.tr("Desktop-entry ID for opening directories")
                        value: Config.options.apps.defaultApplications.folders
                        onEdited: {
                            Config.options.apps.defaultApplications.folders = value
                            defaultApplicationsSection.scheduleDefaultApplication(value, ["inode/directory"])
                        }
                    }
                    ConfigTextArea {
                        visible: page.settingsShow("apps");
                        objectName: "ServicesConfig.documents-and-text";
                        buttonIcon: "description"
                        text: Translation.tr("Documents and text")
                        description: Translation.tr("PDF, plain text, and common office documents")
                        value: Config.options.apps.defaultApplications.documents
                        onEdited: {
                            Config.options.apps.defaultApplications.documents = value
                            defaultApplicationsSection.scheduleDefaultApplication(value, ["application/pdf", "text/plain", "application/rtf", "application/vnd.oasis.opendocument.text", "application/vnd.openxmlformats-officedocument.wordprocessingml.document"])
                        }
                    }
                    ConfigTextArea {
                        visible: page.settingsShow("apps");
                        objectName: "ServicesConfig.images";
                        buttonIcon: "image"
                        text: Translation.tr("Images")
                        description: Translation.tr("JPEG, PNG, WebP, GIF, SVG, and AVIF")
                        value: Config.options.apps.defaultApplications.images
                        onEdited: {
                            Config.options.apps.defaultApplications.images = value
                            defaultApplicationsSection.scheduleDefaultApplication(value, ["image/jpeg", "image/png", "image/webp", "image/gif", "image/svg+xml", "image/avif"])
                        }
                    }
                    ConfigTextArea {
                        visible: page.settingsShow("apps");
                        objectName: "ServicesConfig.audio";
                        buttonIcon: "audio_file"
                        text: Translation.tr("Audio")
                        description: Translation.tr("MP3, FLAC, OGG, WAV, and M4A")
                        value: Config.options.apps.defaultApplications.audio
                        onEdited: {
                            Config.options.apps.defaultApplications.audio = value
                            defaultApplicationsSection.scheduleDefaultApplication(value, ["audio/mpeg", "audio/flac", "audio/ogg", "audio/wav", "audio/mp4"])
                        }
                    }
                    ConfigTextArea {
                        visible: page.settingsShow("apps");
                        objectName: "ServicesConfig.video";
                        buttonIcon: "video_file"
                        text: Translation.tr("Video")
                        description: Translation.tr("MP4, Matroska, WebM, and AVI")
                        value: Config.options.apps.defaultApplications.video
                        onEdited: {
                            Config.options.apps.defaultApplications.video = value
                            defaultApplicationsSection.scheduleDefaultApplication(value, ["video/mp4", "video/x-matroska", "video/webm", "video/x-msvideo"])
                        }
                    }
                    ConfigTextArea {
                        visible: page.settingsShow("apps");
                        objectName: "ServicesConfig.archives";
                        buttonIcon: "inventory_2"
                        text: Translation.tr("Archives")
                        description: Translation.tr("ZIP, 7z, RAR, tar, and gzip archives")
                        value: Config.options.apps.defaultApplications.archives
                        onEdited: {
                            Config.options.apps.defaultApplications.archives = value
                            defaultApplicationsSection.scheduleDefaultApplication(value, ["application/zip", "application/x-7z-compressed", "application/vnd.rar", "application/x-rar", "application/x-tar", "application/gzip"])
                        }
                    }
                    StyledText {
                        property bool groupDescription: true;
                        visible: page.settingsShow("apps");
                        Layout.fillWidth: true
                        wrapMode: Text.Wrap
                        color: Appearance.colors.colSubtext
                        font.pixelSize: Appearance.font.pixelSize.small
                        text: Translation.tr("Use the application's .desktop filename. Each change updates your user mimeapps.list, so it applies to file managers, xdg-open, browsers, and launcher results. Leave a field empty to keep its current system default.")
                    }
                }
            }
            ContentSubsection {
                visible: page.settingsShow("apps|integrations");
                title: Translation.tr("Files, SSH & services")
                GroupedList {
                    compact: true;
                    visible: page.settingsShow("apps|integrations")
                    ConfigTextArea {
                        visible: page.settingsShow("integrations");
                        objectName: "ServicesConfig.open-files-with";
                        buttonIcon: "open_in_new"
                        text: Translation.tr("Open files with")
                        value: Config.options.apps.fileOpener
                        placeholderText: "xdg-open"
                        onEdited: { Config.options.apps.fileOpener = value }
                    }
                    StyledText {
                        property bool groupDescription: true;
                        visible: page.settingsShow("integrations");
                        Layout.fillWidth: true
                        wrapMode: Text.Wrap
                        color: Appearance.colors.colSubtext
                        font.pixelSize: Appearance.font.pixelSize.small
                        text: Translation.tr("Left empty, opening a file result hands it to xdg-open, i.e. whatever ~/.config/mimeapps.list says. An editor that registered itself as the handler for every text-like MIME type will therefore claim most files - if everything keeps opening in the same app, that file is why (`xdg-mime query default text/plain` shows the current winner). Put a command here to bypass it entirely; the path is appended as one quoted argument.")
                    }
                    ConfigSwitch {
                        visible: page.settingsShow("apps");
                        objectName: "ServicesConfig.enable-file-search";
                        buttonIcon: "folder"
                        text: Translation.tr("Enable file search")
                        checked: Config.options.search.extras.filesEnable
                        onEdited: {
                            Config.options.search.extras.filesEnable = checked;
                        }
                    }
                    ConfigSpinBox {
                        visible: page.settingsShow("integrations");
                        objectName: "ServicesConfig.max-file-results";
                        icon: "format_list_numbered"
                        text: Translation.tr("Max file results")
                        value: Config.options.search.extras.filesMaxResults
                        from: 5
                        to: 200
                        stepSize: 5
                        enabled: Config.options.search.extras.filesEnable
                        onEdited: {
                            Config.options.search.extras.filesMaxResults = value;
                        }
                    }
                    ConfigSwitch {
                        visible: page.settingsShow("apps");
                        objectName: "ServicesConfig.enable-ssh-quick-connect";
                        buttonIcon: "lan"
                        text: Translation.tr("Enable SSH quick-connect")
                        checked: Config.options.search.extras.sshHostsEnable
                        onEdited: {
                            Config.options.search.extras.sshHostsEnable = checked;
                        }
                    }
                    ConfigSwitch {
                        visible: page.settingsShow("apps");
                        objectName: "ServicesConfig.enable-systemd-service-search";
                        buttonIcon: "settings_applications"
                        text: Translation.tr("Enable systemd service search")
                        checked: Config.options.search.extras.systemServicesEnable
                        onEdited: {
                            Config.options.search.extras.systemServicesEnable = checked;
                        }
                    }
                    ConfigSpinBox {
                        visible: page.settingsShow("integrations");
                        objectName: "ServicesConfig.max-service-results";
                        icon: "format_list_numbered"
                        text: Translation.tr("Max service results")
                        value: Config.options.search.extras.systemServicesMaxResults
                        from: 5
                        to: 200
                        stepSize: 5
                        enabled: Config.options.search.extras.systemServicesEnable
                        onEdited: {
                            Config.options.search.extras.systemServicesMaxResults = value;
                        }
                    }
                    ConfigSwitch {
                        visible: page.settingsShow("apps");
                        objectName: "ServicesConfig.include-system-wide-services-needs-pkexec-to-control";
                        buttonIcon: "shield_lock"
                        text: Translation.tr("Include system-wide services (needs pkexec to control)")
                        checked: Config.options.search.extras.systemServicesIncludeSystemScope
                        enabled: Config.options.search.extras.systemServicesEnable
                        onEdited: {
                            Config.options.search.extras.systemServicesIncludeSystemScope = checked;
                        }
                    }
                    StyledText {
                        property bool groupDescription: true;
                        visible: page.settingsShow("apps");
                        Layout.fillWidth: true
                        wrapMode: Text.Wrap
                        color: Appearance.colors.colSubtext
                        font.pixelSize: Appearance.font.pixelSize.small
                        text: Translation.tr("Turning off \"Include system-wide services\" keeps only your user units in the ! search — nothing that would ever prompt for a password.")
                    }
                }
            }
            ContentSubsection {
                visible: page.settingsShow("integrations");
                title: Translation.tr("Web search")

                GroupedList {
                    compact: true;
                    visible: page.settingsShow("integrations")
                    ConfigTextArea {
                        visible: page.settingsShow("integrations");
                        objectName: "ServicesConfig.base-url";
                        id: baseUrlField
                        Layout.fillWidth: true
                        fieldWidth: 320
                        buttonIcon: "travel_explore"
                        text: Translation.tr("Base URL")
                        value: Config.options.search.engineBaseUrl
                        onEdited: {
                            baseUrlDebounceTimer.restart();
                        }

                        Timer {
                            id: baseUrlDebounceTimer
                            interval: 600
                            repeat: false
                            onTriggered: {
                                Config.options.search.engineBaseUrl = baseUrlField.value;
                            }
                        }
                    }
                }
            }
        }

        ContentSection {
            visible: page.settingsShow("about|system");
            icon: "deployed_code_update"
            title: Translation.tr("System updates (Arch only)")

            GroupedList {
                compact: true;
                visible: page.settingsShow("about|system")
                ConfigSwitch {
                    visible: page.settingsShow("about");
                    objectName: "ServicesConfig.enable-update-checks";
                    buttonIcon: "update"
                    text: Translation.tr("Enable update checks")
                    checked: Config.options.updates.enableCheck
                    onEdited: {
                        Config.options.updates.enableCheck = checked;
                    }
                }

                ConfigSpinBox {
                    visible: page.settingsShow("system");
                    objectName: "ServicesConfig.check-interval-mins";
                    icon: "av_timer"
                    text: Translation.tr("Check interval (mins)")
                    value: Config.options.updates.checkInterval
                    from: 60
                    to: 1440
                    stepSize: 60
                    onEdited: {
                        Config.options.updates.checkInterval = value;
                    }
                }
            }
        }

        ContentSection {
            visible: page.settingsShow("apps|integrations");
            icon: "weather_mix"
            shape: MaterialShape.Shape.Pill
            title: Translation.tr("Weather")
            GroupedList {
                compact: true;
                visible: page.settingsShow("apps|integrations")
                ConfigSwitch {
                    visible: page.settingsShow("apps");
                    objectName: "ServicesConfig.enable-gps-based-location";
                    buttonIcon: "assistant_navigation"
                    text: Translation.tr("Enable GPS based location")
                    checked: Config.options.bar.weather.enableGPS
                    onEdited: {
                        Config.options.bar.weather.enableGPS = checked;
                    }
                }
                ConfigSwitch {
                    visible: page.settingsShow("apps");
                    objectName: "ServicesConfig.fahrenheit-unit";
                    buttonIcon: "thermometer"
                    text: Translation.tr("Fahrenheit unit")
                    checked: Config.options.bar.weather.useUSCS
                    onEdited: {
                        Config.options.bar.weather.useUSCS = checked;
                    }
                }
                ConfigSpinBox {
                    visible: page.settingsShow("integrations");
                    objectName: "ServicesConfig.polling-interval-m";
                    icon: "av_timer"
                    text: Translation.tr("Polling interval (m)")
                    value: Config.options.bar.weather.fetchInterval
                    from: 5
                    to: 50
                    stepSize: 5
                    onEdited: {
                        Config.options.bar.weather.fetchInterval = value;
                    }
                }
                ConfigTextArea {
                    visible: page.settingsShow("apps");
                    objectName: "ServicesConfig.city-name";
                    id: cityField
                    Layout.fillWidth: true
                    buttonIcon: "location_city"
                    text: Translation.tr("City name")
                    value: Config.options.bar.weather.city
                    onEdited: cityDebounceTimer.restart()

                    Timer {
                        id: cityDebounceTimer
                        interval: 1000
                        running: false
                        onTriggered: Config.options.bar.weather.city = cityField.value
                    }
                }
            }
        }
        WorldMap {
            visible: page.settingsShow("apps");
            objectName: "ServicesConfig.weather-map";
            Layout.fillWidth: true
            Layout.preferredHeight: 300
        }
    }
}
