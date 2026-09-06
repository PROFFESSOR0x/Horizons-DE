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
        id: mainLayout 
        Layout.fillWidth: true   
        Layout.fillHeight: true
        spacing: 20

        ContentSection {
            icon: "neurology"
            shape: MaterialShape.Shape.Ghostish
            title: Translation.tr("AI")

            MaterialTextArea {
                Layout.fillWidth: true
                placeholderText: Translation.tr("System prompt")
                text: Config.options.ai.systemPrompt
                wrapMode: TextEdit.Wrap
                onTextChanged: {
                    Qt.callLater(() => {
                        Config.options.ai.systemPrompt = text;
                    });
                }
            }
        }

        ContentSection {
            icon: "cell_tower"
            shape: MaterialShape.Shape.PixelCircle
            title: Translation.tr("Networking")

            MaterialTextArea {
                Layout.fillWidth: true
                placeholderText: Translation.tr("User agent (for services that require it)")
                text: Config.options.networking.userAgent
                wrapMode: TextEdit.Wrap
                onTextChanged: {
                    Config.options.networking.userAgent = text;
                }
            }
        }

        ContentSection {
            icon: "music_cast"
            shape: MaterialShape.Shape.Oval
            title: Translation.tr("Music Recognition")

            GroupedList {
                ConfigSpinBox {
                    icon: "timer_off"
                    text: Translation.tr("Total duration timeout (s)")
                    value: Config.options.musicRecognition.timeout
                    from: 10
                    to: 100
                    stepSize: 2
                    onValueChanged: {
                        Config.options.musicRecognition.timeout = value;
                    }
                }
                ConfigSpinBox {
                    icon: "av_timer"
                    text: Translation.tr("Polling interval (s)")
                    value: Config.options.musicRecognition.interval
                    from: 2
                    to: 10
                    stepSize: 1
                    onValueChanged: {
                        Config.options.musicRecognition.interval = value;
                    }
                }
            }
        }

        ContentSection {
            icon: "file_open"
            shape: MaterialShape.Shape.Slanted
            title: Translation.tr("Save paths")

            GroupedList {
                ConfigTextArea {
                    id: videoRecordPathField
                    Layout.fillWidth: true
                    fieldWidth: 250
                    buttonIcon: "video_file"
                    text: Translation.tr("Video Recording Path")
                    value: Config.options.screenRecord.savePath
                    onValueChanged: {
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
                    id: screenshotPathField
                    Layout.fillWidth: true
                    fieldWidth: 250
                    buttonIcon: "screenshot_monitor"
                    text: Translation.tr("Screenshot Path (leave empty to just copy)")
                    value: Config.options.screenSnip.savePath
                    onValueChanged: {
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
            icon: "screenshot_monitor"
            shape: MaterialShape.Shape.PixelCircle
            title: Translation.tr("Capture quality")

            ContentSubsection {
                title: Translation.tr("Screenshots")
                GroupedList {
                    ConfigSpinBox {
                        icon: "zoom_out_map"
                        text: Translation.tr("Image scale (%)")
                        value: Config.options.screenSnip.scalePercent
                        from: 25; to: 200; stepSize: 5
                        onValueChanged: Config.options.screenSnip.scalePercent = value
                    }
                    ConfigSelectionArray {
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
                        icon: "high_quality"
                        text: Translation.tr("JPEG quality")
                        enabled: Config.options.screenSnip.format === "jpg"
                        value: Config.options.screenSnip.jpegQuality
                        from: 50; to: 100; stepSize: 1
                        onValueChanged: Config.options.screenSnip.jpegQuality = value
                    }
                }
            }

            ContentSubsection {
                title: Translation.tr("Screen recording")
                GroupedList {
                    ConfigRow {
                        uniform: true
                        ConfigSpinBox {
                            icon: "speed"
                            text: Translation.tr("Frame rate")
                            value: Config.options.screenRecord.frameRate
                            from: 15; to: 120; stepSize: 5
                            onValueChanged: Config.options.screenRecord.frameRate = value
                        }
                        ConfigComboBox {
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
                        Layout.fillWidth: true
                        fieldWidth: 300
                        buttonIcon: "speaker"
                        text: Translation.tr("Output source override")
                        description: Translation.tr("Optional PipeWire/Pulse source name. For mixed audio, use a pre-mixed PipeWire source here.")
                        value: Config.options.screenRecord.outputSource
                        onValueChanged: Config.options.screenRecord.outputSource = value
                    }
                    ConfigTextArea {
                        Layout.fillWidth: true
                        fieldWidth: 300
                        buttonIcon: "mic"
                        text: Translation.tr("Microphone source override")
                        description: Translation.tr("Optional source name. Leave empty for the default microphone.")
                        value: Config.options.screenRecord.microphoneSource
                        onValueChanged: Config.options.screenRecord.microphoneSource = value
                    }
                }
            }
        }

        ContentSection {
            icon: "search"
            shape: MaterialShape.Shape.Cookie6Sided
            title: Translation.tr("Search")

            GroupedList {
                ConfigSelectionArray {
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
                    text: Translation.tr("Use Levenshtein distance-based algorithm instead of fuzzy")
                    checked: Config.options.search.sloppy
                    onCheckedChanged: {
                        Config.options.search.sloppy = checked;
                    }
                }
            }

            ContentSubsection {
                title: Translation.tr("Prefixes")

                GroupedList {
                    ConfigRow {
                        uniform: true
                        ConfigTextArea {
                            Layout.fillWidth: true
                            buttonIcon: "bolt"
                            fieldWidth: 100
                            text: Translation.tr("Action")
                            value: Config.options.search.prefix.action
                            onValueChanged: {
                                Config.options.search.prefix.action = value;
                            }
                        }
                        ConfigTextArea {
                            Layout.fillWidth: true
                            buttonIcon: "content_paste"
                            fieldWidth: 100
                            text: Translation.tr("Clipboard")
                            value: Config.options.search.prefix.clipboard
                            onValueChanged: {
                                Config.options.search.prefix.clipboard = value;
                            }
                        }
                    }

                    ConfigRow {
                        uniform: true
                        ConfigTextArea {
                            Layout.fillWidth: true
                            buttonIcon: "mood"
                            fieldWidth: 100
                            text: Translation.tr("Emojis")
                            value: Config.options.search.prefix.emojis
                            onValueChanged: {
                                Config.options.search.prefix.emojis = value;
                            }
                        }
                        ConfigTextArea {
                            Layout.fillWidth: true
                            buttonIcon: "emoji_symbols"
                            fieldWidth: 100
                            text: Translation.tr("Icons")
                            value: Config.options.search.prefix.symbols
                            onValueChanged: {
                                Config.options.search.prefix.symbols = value;
                            }
                        }
                    }

                    ConfigRow {
                        uniform: true
                        ConfigTextArea {
                            Layout.fillWidth: true
                            buttonIcon: "terminal"
                            fieldWidth: 100
                            text: Translation.tr("Shell command")
                            value: Config.options.search.prefix.shellCommand
                            onValueChanged: {
                                Config.options.search.prefix.shellCommand = value;
                            }
                        }
                        ConfigTextArea {
                            Layout.fillWidth: true
                            fieldWidth: 100
                            buttonIcon: "travel_explore"
                            text: Translation.tr("Web search")
                            value: Config.options.search.prefix.webSearch
                            onValueChanged: {
                                Config.options.search.prefix.webSearch = value;
                            }
                        }
                    }

                    ConfigRow {
                        uniform: true
                        ConfigTextArea {
                            Layout.fillWidth: true
                            buttonIcon: "apps"
                            fieldWidth: 100
                            text: Translation.tr("Apps")
                            value: Config.options.search.prefix.app
                            onValueChanged: {
                                Config.options.search.prefix.app = value;
                            }
                        }
                        ConfigTextArea {
                            Layout.fillWidth: true
                            buttonIcon: "keyboard_command_key"
                            fieldWidth: 100
                            text: Translation.tr("Keybinds")
                            value: Config.options.search.prefix.keybinds
                            onValueChanged: {
                                Config.options.search.prefix.keybinds = value;
                            }
                        }
                    }

                    ConfigRow {
                        uniform: true
                        ConfigTextArea {
                            Layout.fillWidth: true
                            buttonIcon: "description"
                            fieldWidth: 100
                            text: Translation.tr("Files")
                            value: Config.options.search.prefix.files
                            onValueChanged: {
                                Config.options.search.prefix.files = value;
                            }
                        }
                        ConfigTextArea {
                            Layout.fillWidth: true
                            buttonIcon: "dns"
                            fieldWidth: 100
                            text: Translation.tr("SSH hosts")
                            value: Config.options.search.prefix.sshHosts
                            onValueChanged: {
                                Config.options.search.prefix.sshHosts = value;
                            }
                        }
                    }
                    ConfigRow {
                        uniform: true
                        ConfigTextArea {
                            Layout.fillWidth: true
                            buttonIcon: "settings_applications"
                            fieldWidth: 100
                            text: Translation.tr("System services")
                            value: Config.options.search.prefix.systemServices
                            onValueChanged: {
                                Config.options.search.prefix.systemServices = value;
                            }
                        }
                    }
                    ConfigSwitch {
                        buttonIcon: "bolt"
                        text: Translation.tr("Show actions without typing their prefix")
                        checked: Config.options.search.prefix.showActionsWithoutPrefix
                        onCheckedChanged: { Config.options.search.prefix.showActionsWithoutPrefix = checked }
                    }
                    ConfigSwitch {
                        buttonIcon: "description"
                        text: Translation.tr("Show files without typing their prefix")
                        checked: Config.options.search.prefix.showFilesWithoutPrefix
                        onCheckedChanged: { Config.options.search.prefix.showFilesWithoutPrefix = checked }
                    }
                    ConfigSpinBox {
                        visible: Config.options.search.prefix.showFilesWithoutPrefix
                        icon: "text_fields"
                        text: Translation.tr("Minimum characters before searching files")
                        value: Config.options.search.prefix.filesWithoutPrefixMinLength
                        from: 1; to: 8; stepSize: 1
                        onValueChanged: {
                            if (value === Config.options.search.prefix.filesWithoutPrefixMinLength) return
                            Config.options.search.prefix.filesWithoutPrefixMinLength = value
                        }
                    }
                    StyledText {
                        Layout.fillWidth: true
                        wrapMode: Text.Wrap
                        color: Appearance.colors.colSubtext
                        font.pixelSize: Appearance.font.pixelSize.small
                        text: Translation.tr("With these on, actions and files also appear in an ordinary search, after the app results, instead of only behind their prefix character. Each new file search term runs one plocate query, which is why there's a minimum length.")
                    }
                    StyledText {
                        Layout.fillWidth: true
                        wrapMode: Text.Wrap
                        color: Appearance.colors.colSubtext
                        font.pixelSize: Appearance.font.pixelSize.small
                        text: Translation.tr("Files searches plocate's system-wide index (falls back to mlocate's locate, then a live find under $HOME if neither index exists yet — run `sudo updatedb` once after installing plocate). System services lists systemd user + system units; starting/stopping/restarting a system-wide one prompts for authentication via pkexec.")
                    }
                }
            }
            ContentSubsection {
                title: Translation.tr("Files, SSH & services")
                GroupedList {
                    ConfigTextArea {
                        buttonIcon: "open_in_new"
                        text: Translation.tr("Open files with")
                        value: Config.options.apps.fileOpener
                        placeholderText: "xdg-open"
                        onValueChanged: { Config.options.apps.fileOpener = value }
                    }
                    StyledText {
                        Layout.fillWidth: true
                        wrapMode: Text.Wrap
                        color: Appearance.colors.colSubtext
                        font.pixelSize: Appearance.font.pixelSize.small
                        text: Translation.tr("Left empty, opening a file result hands it to xdg-open, i.e. whatever ~/.config/mimeapps.list says. An editor that registered itself as the handler for every text-like MIME type will therefore claim most files - if everything keeps opening in the same app, that file is why (`xdg-mime query default text/plain` shows the current winner). Put a command here to bypass it entirely; the path is appended as one quoted argument.")
                    }
                    ConfigSwitch {
                        buttonIcon: "folder"
                        text: Translation.tr("Enable file search")
                        checked: Config.options.search.extras.filesEnable
                        onCheckedChanged: {
                            Config.options.search.extras.filesEnable = checked;
                        }
                    }
                    ConfigSpinBox {
                        icon: "format_list_numbered"
                        text: Translation.tr("Max file results")
                        value: Config.options.search.extras.filesMaxResults
                        from: 5
                        to: 200
                        stepSize: 5
                        enabled: Config.options.search.extras.filesEnable
                        onValueChanged: {
                            Config.options.search.extras.filesMaxResults = value;
                        }
                    }
                    ConfigSwitch {
                        buttonIcon: "lan"
                        text: Translation.tr("Enable SSH quick-connect")
                        checked: Config.options.search.extras.sshHostsEnable
                        onCheckedChanged: {
                            Config.options.search.extras.sshHostsEnable = checked;
                        }
                    }
                    ConfigSwitch {
                        buttonIcon: "settings_applications"
                        text: Translation.tr("Enable systemd service search")
                        checked: Config.options.search.extras.systemServicesEnable
                        onCheckedChanged: {
                            Config.options.search.extras.systemServicesEnable = checked;
                        }
                    }
                    ConfigSpinBox {
                        icon: "format_list_numbered"
                        text: Translation.tr("Max service results")
                        value: Config.options.search.extras.systemServicesMaxResults
                        from: 5
                        to: 200
                        stepSize: 5
                        enabled: Config.options.search.extras.systemServicesEnable
                        onValueChanged: {
                            Config.options.search.extras.systemServicesMaxResults = value;
                        }
                    }
                    ConfigSwitch {
                        buttonIcon: "shield_lock"
                        text: Translation.tr("Include system-wide services (needs pkexec to control)")
                        checked: Config.options.search.extras.systemServicesIncludeSystemScope
                        enabled: Config.options.search.extras.systemServicesEnable
                        onCheckedChanged: {
                            Config.options.search.extras.systemServicesIncludeSystemScope = checked;
                        }
                    }
                    StyledText {
                        Layout.fillWidth: true
                        wrapMode: Text.Wrap
                        color: Appearance.colors.colSubtext
                        font.pixelSize: Appearance.font.pixelSize.small
                        text: Translation.tr("Turning off \"Include system-wide services\" keeps only your user units in the ! search — nothing that would ever prompt for a password.")
                    }
                }
            }
            ContentSubsection {
                title: Translation.tr("Web search")

                GroupedList {
                    ConfigTextArea {
                        id: baseUrlField
                        Layout.fillWidth: true
                        fieldWidth: 320
                        buttonIcon: "travel_explore"
                        text: Translation.tr("Base URL")
                        value: Config.options.search.engineBaseUrl
                        onValueChanged: {
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
            icon: "deployed_code_update"
            title: Translation.tr("System updates (Arch only)")

            GroupedList {
                ConfigSwitch {
                    buttonIcon: "update"
                    text: Translation.tr("Enable update checks")
                    checked: Config.options.updates.enableCheck
                    onCheckedChanged: {
                        Config.options.updates.enableCheck = checked;
                    }
                }

                ConfigSpinBox {
                    icon: "av_timer"
                    text: Translation.tr("Check interval (mins)")
                    value: Config.options.updates.checkInterval
                    from: 60
                    to: 1440
                    stepSize: 60
                    onValueChanged: {
                        Config.options.updates.checkInterval = value;
                    }
                }
            }
        }

        ContentSection {
            icon: "weather_mix"
            shape: MaterialShape.Shape.Pill
            title: Translation.tr("Weather")
            GroupedList {
                ConfigSwitch {
                    buttonIcon: "assistant_navigation"
                    text: Translation.tr("Enable GPS based location")
                    checked: Config.options.bar.weather.enableGPS
                    onCheckedChanged: {
                        Config.options.bar.weather.enableGPS = checked;
                    }
                }
                ConfigSwitch {
                    buttonIcon: "thermometer"
                    text: Translation.tr("Fahrenheit unit")
                    checked: Config.options.bar.weather.useUSCS
                    onCheckedChanged: {
                        Config.options.bar.weather.useUSCS = checked;
                    }
                }
                ConfigSpinBox {
                    icon: "av_timer"
                    text: Translation.tr("Polling interval (m)")
                    value: Config.options.bar.weather.fetchInterval
                    from: 5
                    to: 50
                    stepSize: 5
                    onValueChanged: {
                        Config.options.bar.weather.fetchInterval = value;
                    }
                }
                ConfigTextArea {
                    id: cityField
                    Layout.fillWidth: true
                    buttonIcon: "location_city"
                    text: Translation.tr("City name")
                    value: Config.options.bar.weather.city
                    onValueChanged: cityDebounceTimer.restart()

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
            Layout.fillWidth: true
            Layout.preferredHeight: 300
        }
    }
}
