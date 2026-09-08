import QtQuick
import Quickshell
import Quickshell.Io
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets

ContentPage {
    id: page
    forceWidth: true

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

    Process {
        id: translationProc
        property string locale: ""
        command: [Directories.aiTranslationScriptPath, translationProc.locale]
    }

    ColumnLayout {
        visible: page.settingsShow("apps|capture|capture-details|notification-rules|notifications|personal|session|session-details|system");
        id: mainLayout
        Layout.fillWidth: true
        Layout.fillHeight: true
        spacing: 20

        ContentSection {
            visible: page.settingsShow("personal|system");
            icon: "nest_clock_farsight_analog"
            shape: MaterialShape.Shape.Bun
            title: Translation.tr("Time")

            Rectangle {
                id: previewCard
                Layout.fillWidth: true
                implicitHeight: 180
                radius: Appearance.rounding.normal
                clip: true

                gradient: Gradient { // I didn't like how it turned out but in case I regret it
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0.0; color: Appearance.colors.colLayer1  }
                    GradientStop { position: 0.6; color: Appearance.colors.colLayer1  }
                    GradientStop { position: 1.0; color: Appearance.colors.colLayer1  }
                }

                property date now: new Date()

                Timer {
                    interval: Config.options.time.secondPrecision ? 1000 : 15000
                    running: true
                    repeat: true
                    triggeredOnStart: true
                    onTriggered: previewCard.now = new Date()
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 24
                    spacing: 16

                    ColumnLayout {
                        StyledText {
                            Layout.fillWidth: true
                            horizontalAlignment: Text.AlignHCenter
                            font.family: Appearance.font.family.expressive
                            font.pixelSize: 42
                            font.letterSpacing: 1
                            font.features: { "tnum": 1 }
                            font.weight: Font.Medium
                            color: Appearance.colors.colPrimary
                            text: {
                                const fmt = Config.options.time.format;
                                if (Config.options.time.secondPrecision) {
                                    if (fmt === "hh:mm") return Qt.formatTime(previewCard.now, "hh:mm:ss");
                                    if (fmt === "h:mm ap") return Qt.formatTime(previewCard.now, "h:mm:ss ap");
                                    if (fmt === "h:mm AP") return Qt.formatTime(previewCard.now, "h:mm:ss AP");
                                }
                                return Qt.formatTime(previewCard.now, fmt);
                            }
                        }
                        StyledText {
                            Layout.fillWidth: true
                            text: DateTime.longDate
                            horizontalAlignment: Text.AlignHCenter
                            font.pixelSize: 32
                            font.weight: Font.Normal
                            opacity: 0.6
                            color: Appearance.colors.colPrimary
                        }
                    }

                    AndroidClock {
                        Layout.rightMargin: 6
                        width: 130
                        height: 130
                        backgroundColor: Appearance.colors.colPrimaryContainer
                        handColor:       Appearance.colors.colPrimary
                        centerDotColor:  Appearance.colors.colPrimary
                    }
                }
            }

            GroupedList {
                compact: true;
                visible: page.settingsShow("personal|system");
                Layout.topMargin: -2
                ConfigSelectionArray {
                    visible: page.settingsShow("personal");
                    objectName: "GeneralConfig.format";
                    text: Translation.tr("Format")
                    icon: "schedule"
                    currentValue: Config.options.time.format
                    onSelected: newValue => {
                        if (newValue === "hh:mm") {
                            Quickshell.execDetached(["bash", "-c", `sed -i 's/\\TIME12\\b/TIME/' '${FileUtils.trimFileProtocol(Directories.config)}/hypr/hyprlock.conf'`]);
                        } else {
                            Quickshell.execDetached(["bash", "-c", `sed -i 's/\\TIME\\b/TIME12/' '${FileUtils.trimFileProtocol(Directories.config)}/hypr/hyprlock.conf'`]);
                        }
                        Config.options.time.format = newValue;
                    }
                    options: [
                        { displayName: Translation.tr("24h"), value: "hh:mm" },
                        { displayName: Translation.tr("12h am/pm"), value: "h:mm ap" },
                        { displayName: Translation.tr("12h AM/PM"), value: "h:mm AP" }
                    ]
                }
                ConfigSwitch {
                    visible: page.settingsShow("personal");
                    objectName: "GeneralConfig.show-date";
                    buttonIcon: "date_range"
                    text: Translation.tr("Show date")
                    checked: Config.options.time.showDate
                    onEdited: {
                        Config.options.time.showDate = checked;
                    }
                }
                ConfigSwitch {
                    visible: page.settingsShow("personal");
                    objectName: "GeneralConfig.second-precision";
                    buttonIcon: "pace"
                    text: Translation.tr("Second precision")
                    checked: Config.options.time.secondPrecision
                    onEdited: {
                        Config.options.time.secondPrecision = checked;
                    }
                }
                ConfigTextArea {
                    visible: page.settingsShow("system");
                    objectName: "GeneralConfig.clock-string-format";
                    Layout.fillWidth: true
                    buttonIcon: "scoreboard"
                    text: Translation.tr("Clock String Format")
                    placeholderText: Translation.tr("Clock String Format")
                    value: Config.options.time.format
                    onEdited: {
                        Config.options.time.format = value;
                    }
                }

                ConfigTextArea {
                    visible: page.settingsShow("system");
                    objectName: "GeneralConfig.date-string-format";
                    Layout.fillWidth: true
                    buttonIcon: "calendar_month"
                    text: Translation.tr("Date String Format")
                    placeholderText: Translation.tr("Date String Format")
                    value: Config .options.time.dateFormat
                    onEdited: {
                        Config.options.time.dateFormat = value;
                    }
                }
            }
        }

        ContentSection {
            visible: page.settingsShow("capture|capture-details");
            icon: "screenshot_monitor"
            shape: MaterialShape.Shape.Slanted
            title: Translation.tr("Capture behavior")

            StyledText {
                visible: page.settingsShow("capture|capture-details");
                Layout.fillWidth: true
                wrapMode: Text.Wrap
                color: Appearance.colors.colSubtext
                font.pixelSize: Appearance.font.pixelSize.smaller
                text: Translation.tr("Controls how the screenshot / video annotation canvas behaves: auto-open, close after save/copy, and editor defaults.")
            }

            // ── After capture ─────────────────────────────────────────────
            ContentSubsectionLabel {
                visible: page.settingsShow("capture|capture-details"); text: Translation.tr("After capture") }
            GroupedList {
                compact: true;
                visible: page.settingsShow("capture")
                ConfigSelectionArray {
                    visible: page.settingsShow("capture");
                    objectName: "GeneralConfig.screenshots";
                    icon: "photo_camera"
                    text: Translation.tr("Screenshots")
                    currentValue: Config.options.screenCanvas.imageResultMode
                    onSelected: newValue => Config.options.screenCanvas.imageResultMode = newValue
                    options: [
                        { displayName: Translation.tr("Open editor"), icon: "edit", value: "editor" },
                        { displayName: Translation.tr("Notify"), icon: "notifications", value: "notification" },
                        { displayName: Translation.tr("Just copy"), icon: "content_copy", value: "silent" }
                    ]
                }
                ConfigSelectionArray {
                    visible: page.settingsShow("capture");
                    objectName: "GeneralConfig.recordings";
                    icon: "movie"
                    text: Translation.tr("Recordings")
                    currentValue: Config.options.screenCanvas.videoResultMode
                    onSelected: newValue => Config.options.screenCanvas.videoResultMode = newValue
                    options: [
                        { displayName: Translation.tr("Open editor"), icon: "edit", value: "editor" },
                        { displayName: Translation.tr("Notify"), icon: "notifications", value: "notification" },
                        { displayName: Translation.tr("Just save"), icon: "save", value: "silent" }
                    ]
                }
                StyledText {
                    property bool groupDescription: true;
                    visible: page.settingsShow("capture");
                    Layout.fillWidth: true
                    wrapMode: Text.Wrap
                    color: Appearance.colors.colSubtext
                    font.pixelSize: Appearance.font.pixelSize.smaller
                    text: {
                        const img = Config.options.screenCanvas.imageResultMode
                        if (img === "notification") return Translation.tr("Notify: a notification with Edit / Copy / Save / Run OCR buttons appears instead — nothing happens until you pick one.")
                        if (img === "silent") return Translation.tr("Just copy: the screenshot is copied to the clipboard only. Right-click → Edit still opens it manually any time.")
                        return Translation.tr("Open editor: the canvas opens automatically every time.")
                    }
                }
            }

            // ── Close behaviour after Save / Copy ───────────────────────
            ContentSubsectionLabel {
                visible: page.settingsShow("capture"); text: Translation.tr("After Save / Copy") }
            GroupedList {
                compact: true;
                visible: page.settingsShow("capture|capture-details")
                ConfigSwitch {
                    visible: page.settingsShow("capture");
                    objectName: "GeneralConfig.close-after-saving-image";
                    buttonIcon: "save"
                    text: Translation.tr("Close after saving image")
                    checked: Config.options.screenCanvas.closeOnSaveImage
                    onEdited: Config.options.screenCanvas.closeOnSaveImage = checked
                }
                ConfigSwitch {
                    visible: page.settingsShow("capture");
                    objectName: "GeneralConfig.close-after-exporting-video";
                    buttonIcon: "save"
                    text: Translation.tr("Close after exporting video")
                    checked: Config.options.screenCanvas.closeOnSaveVideo
                    onEdited: Config.options.screenCanvas.closeOnSaveVideo = checked
                }
                ConfigSwitch {
                    visible: page.settingsShow("capture");
                    objectName: "GeneralConfig.close-after-copying-image";
                    buttonIcon: "content_copy"
                    text: Translation.tr("Close after copying image")
                    checked: Config.options.screenCanvas.closeOnCopyImage
                    onEdited: Config.options.screenCanvas.closeOnCopyImage = checked
                }
                ConfigSwitch {
                    visible: page.settingsShow("capture");
                    objectName: "GeneralConfig.close-after-copying-video";
                    buttonIcon: "content_copy"
                    text: Translation.tr("Close after copying video")
                    checked: Config.options.screenCanvas.closeOnCopyVideo
                    onEdited: Config.options.screenCanvas.closeOnCopyVideo = checked
                }
                // Daily save/copy behavior with the close toggles above, so
                // the basic capture page reads top-to-bottom without jumping
                // to the technical canvas defaults below.
                ConfigSwitch {
                    visible: page.settingsShow("capture");
                    objectName: "GeneralConfig.also-copy-on-save";
                    buttonIcon: "content_copy"
                    text: Translation.tr("Also copy on save")
                    checked: Config.options.screenCanvas.saveAlsoCopiesToClipboard
                    onEdited: Config.options.screenCanvas.saveAlsoCopiesToClipboard = checked
                }
                ConfigSelectionArray {
                    visible: page.settingsShow("capture");
                    objectName: "GeneralConfig.image-save-mode";
                    icon: "save_as"
                    text: Translation.tr("Image save mode")
                    currentValue: Config.options.screenCanvas.imageSaveMode
                    onSelected: newValue => Config.options.screenCanvas.imageSaveMode = newValue
                    options: [
                        { displayName: Translation.tr("Edited suffix"), icon: "note_add", value: "editedSuffix" },
                        { displayName: Translation.tr("Overwrite"), icon: "save", value: "overwrite" },
                        { displayName: Translation.tr("Ask"), icon: "help", value: "ask" }
                    ]
                }
                ConfigSwitch {
                    visible: page.settingsShow("capture");
                    objectName: "GeneralConfig.show-notifications-toasts";
                    buttonIcon: "notifications"
                    text: Translation.tr("Show notifications / toasts")
                    checked: Config.options.screenCanvas.showNotifications
                    onEdited: Config.options.screenCanvas.showNotifications = checked
                }
                ConfigSwitch {
                    visible: page.settingsShow("capture-details");
                    objectName: "GeneralConfig.click-outside-to-close";
                    buttonIcon: "open_in_full"
                    text: Translation.tr("Click outside to close")
                    checked: Config.options.screenCanvas.closeOnClickOutside
                    onEdited: Config.options.screenCanvas.closeOnClickOutside = checked
                }
                ConfigSwitch {
                    visible: page.settingsShow("capture-details");
                    objectName: "GeneralConfig.esc-closes-canvas";
                    buttonIcon: "keyboard_return"
                    text: Translation.tr("Esc closes canvas")
                    checked: Config.options.screenCanvas.closeOnEsc
                    onEdited: Config.options.screenCanvas.closeOnEsc = checked
                }
                ConfigSwitch {
                    visible: page.settingsShow("capture");
                    objectName: "GeneralConfig.confirm-if-unsaved-annotations";
                    buttonIcon: "warning"
                    text: Translation.tr("Confirm if unsaved annotations")
                    checked: Config.options.screenCanvas.confirmCloseWhenUnsaved
                    onEdited: Config.options.screenCanvas.confirmCloseWhenUnsaved = checked
                }
                ConfigSwitch {
                    visible: page.settingsShow("capture-details");
                    objectName: "GeneralConfig.clear-annotations-when-closing";
                    buttonIcon: "cleaning_services"
                    text: Translation.tr("Clear annotations when closing")
                    checked: Config.options.screenCanvas.clearOnClose
                    onEdited: Config.options.screenCanvas.clearOnClose = checked
                }
            }

            // ── Video editor ────────────────────────────────────────────
            ContentSubsectionLabel {
                visible: page.settingsShow("capture|capture-details"); text: Translation.tr("Video editor") }
            GroupedList {
                compact: true;
                visible: page.settingsShow("capture-details")
                ConfigRow {
                    visible: page.settingsShow("capture-details");
                    uniform: true
                    ConfigSwitch {
                        visible: page.settingsShow("capture-details");
                        objectName: "GeneralConfig.auto-play-video-on-open";
                        buttonIcon: "play_arrow"
                        text: Translation.tr("Auto-play video on open")
                        checked: Config.options.screenCanvas.videoAutoPlayOnOpen
                        onEdited: Config.options.screenCanvas.videoAutoPlayOnOpen = checked
                    }
                    ConfigSwitch {
                        visible: page.settingsShow("capture-details");
                        objectName: "GeneralConfig.loop-playback";
                        buttonIcon: "repeat"
                        text: Translation.tr("Loop playback")
                        checked: Config.options.screenCanvas.videoLoopPlayback
                        onEdited: Config.options.screenCanvas.videoLoopPlayback = checked
                    }
                }
                ConfigSwitch {
                    visible: page.settingsShow("capture-details");
                    objectName: "GeneralConfig.start-muted";
                    buttonIcon: "volume_off"
                    text: Translation.tr("Start muted")
                    checked: Config.options.screenCanvas.videoMutedOnOpen
                    onEdited: Config.options.screenCanvas.videoMutedOnOpen = checked
                }
                ConfigRow {
                    visible: page.settingsShow("capture-details");
                    uniform: true
                    ConfigSpinBox {
                        visible: page.settingsShow("capture-details");
                        objectName: "GeneralConfig.default-annotation-duration-s";
                        icon: "timer"
                        text: Translation.tr("Default annotation duration (s)")
                        value: Config.options.screenCanvas.defaultAnnotationDuration
                        from: 1
                        to: 20
                        stepSize: 1
                        onEdited: Config.options.screenCanvas.defaultAnnotationDuration = value
                    }
                }
            }

            // ── Canvas & editor defaults ────────────────────────────────
            ContentSubsectionLabel {
                visible: page.settingsShow("capture-details"); text: Translation.tr("Canvas & defaults") }
            GroupedList {
                compact: true;
                visible: page.settingsShow("capture|capture-details")
                ConfigSelectionArray {
                    visible: page.settingsShow("capture-details");
                    objectName: "GeneralConfig.default-tool";
                    icon: "draw"
                    text: Translation.tr("Default tool")
                    currentValue: Config.options.screenCanvas.defaultTool
                    onSelected: newValue => Config.options.screenCanvas.defaultTool = newValue
                    options: [
                        { displayName: Translation.tr("Pen"), icon: "draw", value: "pen" },
                        { displayName: Translation.tr("Arrow"), icon: "north_east", value: "arrow" },
                        { displayName: Translation.tr("Rect"), icon: "rectangle", value: "rect" },
                        { displayName: Translation.tr("Circle"), icon: "circle", value: "circle" },
                        { displayName: Translation.tr("Highlight"), icon: "ink_highlighter", value: "highlight" },
                        { displayName: Translation.tr("Blur"), icon: "blur_on", value: "blur" }
                    ]
                }
                ConfigSpinBox {
                    visible: page.settingsShow("capture-details");
                    objectName: "GeneralConfig.default-stroke-width";
                    icon: "line_weight"
                    text: Translation.tr("Default stroke width")
                    value: Config.options.screenCanvas.defaultStrokeWidth
                    from: 1
                    to: 20
                    stepSize: 1
                    onEdited: Config.options.screenCanvas.defaultStrokeWidth = value
                }
                // Default color palette
                RowLayout {
                    Layout.fillWidth: true
                    Layout.leftMargin: 8
                    Layout.rightMargin: 8
                    spacing: 10
                    StyledText {
                        text: Translation.tr("Default color")
                        color: Appearance.colors.colOnSecondaryContainer
                        Layout.fillWidth: true
                    }
                    Row {
                        spacing: 6
                        Repeater {
                            model: ["#ff0000", "#ff6600", "#ffcc00", "#00cc00", "#0066ff", "#9933ff", "#ff0099", "#000000", "#ffffff", "#808080"]
                            delegate: Rectangle {
                                required property var modelData
                                width: 26; height: 26; radius: 13
                                color: modelData
                                border.width: Config.options.screenCanvas.defaultColor === modelData ? 3 : 1
                                border.color: Config.options.screenCanvas.defaultColor === modelData ? Appearance.colors.colPrimary : Appearance.colors.colOutlineVariant
                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: Config.options.screenCanvas.defaultColor = parent.modelData
                                }
                            }
                        }
                    }
                }
                ConfigSpinBox {
                    visible: page.settingsShow("capture-details");
                    objectName: "GeneralConfig.canvas-dim-opacity";
                    icon: "contrast"
                    text: Translation.tr("Canvas dim opacity %")
                    value: Math.round(Config.options.screenCanvas.canvasDimOpacity * 100)
                    from: 0
                    to: 80
                    stepSize: 5
                    onEdited: Config.options.screenCanvas.canvasDimOpacity = value / 100.0
                }
            }

            // Quick hint
            NoticeBox {
                visible: page.settingsShow("capture|capture-details");
                Layout.fillWidth: true
                text: Translation.tr("How it works: Screenshots — region → Copy saves & copies, Edit opens editor directly. These toggles control whether Copy also opens the canvas and whether Save/Copy auto-closes it. Videos — recording → notification action Edit or auto-open if enabled.")
            }
        }

        ContentSection {
            icon: "battery_android_full"
            shape: MaterialShape.Shape.SemiCircle
            title: Translation.tr("Battery")
            visible: page.settingsShow("session|session-details") && (Battery.available)

            GroupedList {
                compact: true;
                visible: page.settingsShow("session|session-details")
                // Order: daily behavior first, numeric thresholds last.
                ConfigRow {
                    visible: page.settingsShow("session|session-details");
                    uniform: true
                    ConfigSwitch {
                        visible: page.settingsShow("session");
                        objectName: "GeneralConfig.automatic-suspend";
                        buttonIcon: "pause"
                        text: Translation.tr("Automatic suspend")
                        checked: Config.options.battery.automaticSuspend
                        onEdited: {
                            Config.options.battery.automaticSuspend = checked;
                        }
                    }
                    ConfigSpinBox {
                        visible: page.settingsShow("session-details");
                        objectName: "GeneralConfig.at";
                        enabled: Config.options.battery.automaticSuspend
                        text: Translation.tr("at")
                        value: Config.options.battery.suspend
                        from: 0
                        to: 100
                        stepSize: 5
                        onEdited: {
                            Config.options.battery.suspend = value;
                        }
                    }
                }
                ConfigRow {
                    visible: page.settingsShow("session-details");
                    uniform: true
                    ConfigSpinBox {
                        visible: page.settingsShow("session-details");
                        objectName: "GeneralConfig.low-warning";
                        icon: "warning"
                        text: Translation.tr("Low warning")
                        value: Config.options.battery.low
                        from: 0
                        to: 100
                        stepSize: 5
                        onEdited: {
                            Config.options.battery.low = value;
                        }
                    }
                    ConfigSpinBox {
                        visible: page.settingsShow("session-details");
                        objectName: "GeneralConfig.critical-warning";
                        icon: "dangerous"
                        text: Translation.tr("Critical warning")
                        value: Config.options.battery.critical
                        from: 0
                        to: 100
                        stepSize: 5
                        onEdited: {
                            Config.options.battery.critical = value;
                        }
                    }
                }
                ConfigRow {
                    visible: page.settingsShow("session-details");
                    uniform: true
                    ConfigSpinBox {
                        visible: page.settingsShow("session-details");
                        objectName: "GeneralConfig.full-warning";
                        icon: "charger"
                        text: Translation.tr("Full warning")
                        value: Config.options.battery.full
                        from: 0
                        to: 101
                        stepSize: 5
                        onEdited: {
                            Config.options.battery.full = value;
                        }
                    }
                }
            }
        }

        ContentSection {
            visible: page.settingsShow("notification-rules|notifications");
            icon: "volume_up"
            shape: MaterialShape.Shape.Circle
            title: Translation.tr("Audio")
            GroupedList {
                compact: true;
                visible: page.settingsShow("notification-rules|notifications")
                ConfigSwitch {
                    visible: page.settingsShow("notifications");
                    objectName: "GeneralConfig.earbang-protection";
                    buttonIcon: "hearing"
                    text: Translation.tr("Earbang protection")
                    checked: Config.options.audio.protection.enable
                    onEdited: {
                        Config.options.audio.protection.enable = checked;
                    }
                }
                ConfigRow {
                    visible: page.settingsShow("notification-rules|notifications");
                    enabled: Config.options.audio.protection.enable
                    // Daily limit first, fine-tuning step second.
                    ConfigSpinBox {
                        visible: page.settingsShow("notifications");
                        objectName: "GeneralConfig.volume-limit";
                        icon: "vertical_align_top"
                        text: Translation.tr("Volume limit")
                        value: Config.options.audio.protection.maxAllowed
                        from: 0
                        to: 154 // pavucontrol allows up to 153%
                        stepSize: 2
                        onEdited: {
                            Config.options.audio.protection.maxAllowed = value;
                        }
                    }
                    ConfigSpinBox {
                        visible: page.settingsShow("notification-rules");
                        objectName: "GeneralConfig.max-allowed-increase";
                        icon: "arrow_warm_up"
                        text: Translation.tr("Max allowed increase")
                        value: Config.options.audio.protection.maxAllowedIncrease
                        from: 0
                        to: 100
                        stepSize: 2
                        onEdited: {
                            Config.options.audio.protection.maxAllowedIncrease = value;
                        }
                    }
                }
            }
        }

        ContentSection {
            visible: page.settingsShow("notifications");
            icon: "notification_sound"
            shape: MaterialShape.Shape.Clover8Leaf
            title: Translation.tr("Sounds")
            GroupedList {
                compact: true;
                visible: page.settingsShow("notifications")
                ConfigSwitch {
                    visible: page.settingsShow("notifications");
                    objectName: "GeneralConfig.battery";
                    buttonIcon: "battery_android_full"
                    text: Translation.tr("Battery")
                    enabled: Battery.available
                    checked: Config.options.sounds.battery
                    onEdited: {
                        Config.options.sounds.battery = checked;
                    }
                }
                ConfigSwitch {
                    visible: page.settingsShow("notifications");
                    objectName: "GeneralConfig.pomodoro";
                    buttonIcon: "av_timer"
                    text: Translation.tr("Pomodoro")
                    checked: Config.options.sounds.pomodoro
                    onEdited: {
                        Config.options.sounds.pomodoro = checked;
                    }
                }
            }
        }

        ContentSection {
            visible: page.settingsShow("personal|system");
            icon: "language_japanese_kana"
            shape: MaterialShape.Shape.Gem
            title: Translation.tr("Language")

            GroupedList {
                compact: true;
                visible: page.settingsShow("personal|system")
                // 1) Daily: one-tap Arabic mode first, then the full language picker.
                ConfigSwitch {
                    visible: page.settingsShow("personal");
                    objectName: "GeneralConfig.arabic-mode";
                    buttonIcon: "language"
                    text: Translation.tr("Arabic mode")
                    checked: (Config.options.language.ui ?? "auto").indexOf("ar") === 0
                    onEdited: {
                        if (checked) {
                            const current = Config.options.language.ui ?? "auto";
                            if (current.indexOf("ar") !== 0)
                                Config.options.settings.prevLanguage = current;
                            Config.options.language.ui = "ar_EG";
                        } else {
                            const prev = Config.options.settings.prevLanguage ?? "auto";
                            Config.options.language.ui = (prev.indexOf("ar") === 0) ? "auto" : prev;
                        }
                    }
                }
                ConfigComboBox {
                    objectName: "GeneralConfig.interface-language";
                    visible: page.settingsShow("personal");

                    Layout.fillWidth: true
                    buttonIcon: "language"
                    text: Translation.tr("Interface Language")
                    fieldWidth: 240
                    model: [
                        { displayName: Translation.tr("Auto (System)"), value: "auto" },
                        ...Translation.allAvailableLanguages.map(lang => ({ displayName: lang, value: lang }))
                    ]
                    currentValue: Config.options.language.ui
                    onSelected: newValue => {
                        Config.options.language.ui = newValue;
                    }
                }

                ColumnLayout {
                    visible: page.settingsShow("system");
                    id: translationCol
                    // This is a row in GroupedList's ColumnLayout. Anchoring it
                    // to the parent makes it overlap the language selector
                    // above; let the layout position and size it instead.
                    Layout.fillWidth: true
                    spacing: 8

                    ConfigTextArea {
                        visible: page.settingsShow("system");
                        objectName: "GeneralConfig.locale-code";
                        id: localeField
                        Layout.fillWidth: true
                        buttonIcon: "translate"
                        text: Translation.tr("Locale code")
                        placeholderText: Translation.tr("e.g. fr_FR, de_DE, zh_CN...")
                        value: Config.options.language.ui === "auto" ? Qt.locale().name : Config.options.language.ui
                    }

                    RippleButtonWithIcon {
                        visible: page.settingsShow("system");
                        objectName: "GeneralConfig.language";
                        id: generateTranslationBtn
                        Layout.fillWidth: false
                        Layout.alignment: Qt.AlignRight
                        Layout.preferredHeight: 50
                        Layout.rightMargin: 8
                        nerdIcon: ""
                        enabled: !translationProc.running || (translationProc.locale !== localeField.value.trim())
                        mainText: enabled ? Translation.tr("Generate\nTypically takes 2 minutes") : Translation.tr("Generating...\nDon't close this window!")
                        onClicked: {
                            translationProc.locale = localeField.value.trim();
                            translationProc.running = false;
                            translationProc.running = true;
                        }
                    }
                }
            }
        }

        ContentSection {
            visible: page.settingsShow("apps");
            icon: "work_alert"
            shape: MaterialShape.Shape.PuffyDiamond
            title: Translation.tr("Work safety")
            GroupedList {
                compact: true;
                visible: page.settingsShow("apps")
                ConfigSwitch {
                    visible: page.settingsShow("apps");
                    objectName: "GeneralConfig.hide-clipboard-images-copied-from-sussy-sources";
                    buttonIcon: "assignment"
                    text: Translation.tr("Hide clipboard images copied from sussy sources")
                    checked: Config.options.workSafety.enable.clipboard
                    onEdited: {
                        Config.options.workSafety.enable.clipboard = checked;
                    }
                }
                ConfigSwitch {
                    visible: page.settingsShow("apps");
                    objectName: "GeneralConfig.hide-sussy-anime-wallpapers";
                    buttonIcon: "wallpaper"
                    text: Translation.tr("Hide sussy/anime wallpapers")
                    checked: Config.options.workSafety.enable.wallpaper
                    onEdited: {
                        Config.options.workSafety.enable.wallpaper = checked;
                    }
                }
            }
        }
    }
}
