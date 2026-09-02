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
        id: mainLayout 
        Layout.fillWidth: true   
        Layout.fillHeight: true
        spacing: 20

        ContentSection {
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
                Layout.topMargin: -2
                ConfigSelectionArray {
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
                    buttonIcon: "pace"
                    text: Translation.tr("Second precision")
                    checked: Config.options.time.secondPrecision
                    onCheckedChanged: {
                        Config.options.time.secondPrecision = checked;
                    }
                }
                ConfigSwitch {
                    buttonIcon: "date_range"
                    text: Translation.tr("Show date")
                    checked: Config.options.time.showDate
                    onCheckedChanged: {
                        Config.options.time.showDate = checked;
                    }
                }
                ConfigTextArea {
                    Layout.fillWidth: true
                    buttonIcon: "scoreboard"
                    text: Translation.tr("Clock String Format")
                    placeholderText: Translation.tr("Clock String Format")
                    value: Config.options.time.format
                    onValueChanged: {
                        Config.options.time.format = value;
                    }
                }
                
                ConfigTextArea {
                    Layout.fillWidth: true
                    buttonIcon: "calendar_month"
                    text: Translation.tr("Date String Format")
                    placeholderText: Translation.tr("Date String Format")
                    value: Config .options.time.dateFormat
                    onValueChanged: {
                        Config.options.time.dateFormat = value;
                    }
                }
            }
        }

        ContentSection {
            icon: "screenshot_monitor"
            shape: MaterialShape.Shape.Slanted
            title: Translation.tr("Screen Canvas — Screenshot & Video Editor")

            StyledText {
                Layout.fillWidth: true
                wrapMode: Text.Wrap
                color: Appearance.colors.colSubtext
                font.pixelSize: Appearance.font.pixelSize.smaller
                text: Translation.tr("Controls how the screenshot / video annotation canvas behaves: auto-open, close after save/copy, and editor defaults.")
            }

            // ── Auto-open ───────────────────────────────────────────────
            ContentSubsectionLabel { text: Translation.tr("Auto-open") }
            GroupedList {
                ConfigSwitch {
                    buttonIcon: "photo_camera"
                    text: Translation.tr("Auto-open editor for screenshots / images")
                    checked: Config.options.screenCanvas.autoOpenImage
                    onCheckedChanged: Config.options.screenCanvas.autoOpenImage = checked
                }
                ConfigSwitch {
                    buttonIcon: "movie"
                    text: Translation.tr("Auto-open editor for screen recordings / videos")
                    checked: Config.options.screenCanvas.autoOpenVideo
                    onCheckedChanged: Config.options.screenCanvas.autoOpenVideo = checked
                }
                StyledText {
                    visible: !Config.options.screenCanvas.autoOpenImage && !Config.options.screenCanvas.autoOpenVideo
                    Layout.fillWidth: true
                    wrapMode: Text.Wrap
                    color: Appearance.colors.colSubtext
                    font.pixelSize: Appearance.font.pixelSize.smaller
                    text: Translation.tr("Tip: when both are off, use right-click → Edit or the notification action to open the editor manually.")
                }
            }

            // ── Close behaviour after Save / Copy ───────────────────────
            ContentSubsectionLabel { text: Translation.tr("After Save / Copy") }
            GroupedList {
                ConfigSwitch {
                    buttonIcon: "save"
                    text: Translation.tr("Close after saving image")
                    checked: Config.options.screenCanvas.closeOnSaveImage
                    onCheckedChanged: Config.options.screenCanvas.closeOnSaveImage = checked
                }
                ConfigSwitch {
                    buttonIcon: "save"
                    text: Translation.tr("Close after exporting video")
                    checked: Config.options.screenCanvas.closeOnSaveVideo
                    onCheckedChanged: Config.options.screenCanvas.closeOnSaveVideo = checked
                }
                ConfigSwitch {
                    buttonIcon: "content_copy"
                    text: Translation.tr("Close after copying image")
                    checked: Config.options.screenCanvas.closeOnCopyImage
                    onCheckedChanged: Config.options.screenCanvas.closeOnCopyImage = checked
                }
                ConfigSwitch {
                    buttonIcon: "content_copy"
                    text: Translation.tr("Close after copying video")
                    checked: Config.options.screenCanvas.closeOnCopyVideo
                    onCheckedChanged: Config.options.screenCanvas.closeOnCopyVideo = checked
                }
                ConfigSwitch {
                    buttonIcon: "open_in_full"
                    text: Translation.tr("Click outside to close")
                    checked: Config.options.screenCanvas.closeOnClickOutside
                    onCheckedChanged: Config.options.screenCanvas.closeOnClickOutside = checked
                }
                ConfigSwitch {
                    buttonIcon: "keyboard_return"
                    text: Translation.tr("Esc closes canvas")
                    checked: Config.options.screenCanvas.closeOnEsc
                    onCheckedChanged: Config.options.screenCanvas.closeOnEsc = checked
                }
                ConfigSwitch {
                    buttonIcon: "warning"
                    text: Translation.tr("Confirm if unsaved annotations")
                    checked: Config.options.screenCanvas.confirmCloseWhenUnsaved
                    onCheckedChanged: Config.options.screenCanvas.confirmCloseWhenUnsaved = checked
                }
                ConfigSwitch {
                    buttonIcon: "cleaning_services"
                    text: Translation.tr("Clear annotations when closing")
                    checked: Config.options.screenCanvas.clearOnClose
                    onCheckedChanged: Config.options.screenCanvas.clearOnClose = checked
                }
            }

            // ── Video editor ────────────────────────────────────────────
            ContentSubsectionLabel { text: Translation.tr("Video editor") }
            GroupedList {
                ConfigRow {
                    uniform: true
                    ConfigSwitch {
                        buttonIcon: "play_arrow"
                        text: Translation.tr("Auto-play video on open")
                        checked: Config.options.screenCanvas.videoAutoPlayOnOpen
                        onCheckedChanged: Config.options.screenCanvas.videoAutoPlayOnOpen = checked
                    }
                    ConfigSwitch {
                        buttonIcon: "repeat"
                        text: Translation.tr("Loop playback")
                        checked: Config.options.screenCanvas.videoLoopPlayback
                        onCheckedChanged: Config.options.screenCanvas.videoLoopPlayback = checked
                    }
                }
                ConfigSwitch {
                    buttonIcon: "volume_off"
                    text: Translation.tr("Start muted")
                    checked: Config.options.screenCanvas.videoMutedOnOpen
                    onCheckedChanged: Config.options.screenCanvas.videoMutedOnOpen = checked
                }
                ConfigRow {
                    uniform: true
                    ConfigSpinBox {
                        icon: "timer"
                        text: Translation.tr("Default annotation duration (s)")
                        value: Config.options.screenCanvas.defaultAnnotationDuration
                        from: 1
                        to: 20
                        stepSize: 1
                        onValueChanged: Config.options.screenCanvas.defaultAnnotationDuration = value
                    }
                }
            }

            // ── Canvas & editor defaults ────────────────────────────────
            ContentSubsectionLabel { text: Translation.tr("Canvas & defaults") }
            GroupedList {
                ConfigSelectionArray {
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
                    icon: "line_weight"
                    text: Translation.tr("Default stroke width")
                    value: Config.options.screenCanvas.defaultStrokeWidth
                    from: 1
                    to: 20
                    stepSize: 1
                    onValueChanged: Config.options.screenCanvas.defaultStrokeWidth = value
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
                ConfigSwitch {
                    buttonIcon: "content_copy"
                    text: Translation.tr("Also copy on save")
                    checked: Config.options.screenCanvas.saveAlsoCopiesToClipboard
                    onCheckedChanged: Config.options.screenCanvas.saveAlsoCopiesToClipboard = checked
                }
                ConfigSelectionArray {
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
                    buttonIcon: "notifications"
                    text: Translation.tr("Show notifications / toasts")
                    checked: Config.options.screenCanvas.showNotifications
                    onCheckedChanged: Config.options.screenCanvas.showNotifications = checked
                }
                ConfigSpinBox {
                    icon: "contrast"
                    text: Translation.tr("Canvas dim opacity %")
                    value: Math.round(Config.options.screenCanvas.canvasDimOpacity * 100)
                    from: 0
                    to: 80
                    stepSize: 5
                    onValueChanged: Config.options.screenCanvas.canvasDimOpacity = value / 100.0
                }
            }

            // Quick hint
            NoticeBox {
                Layout.fillWidth: true
                text: Translation.tr("How it works: Screenshots — region → Copy saves & copies, Edit opens editor directly. These toggles control whether Copy also opens the canvas and whether Save/Copy auto-closes it. Videos — recording → notification action Edit or auto-open if enabled.")
            }
        }

        ContentSection {
            icon: "battery_android_full"
            shape: MaterialShape.Shape.SemiCircle
            title: Translation.tr("Battery")
            visible: Battery.available

            GroupedList {
                ConfigRow {
                    uniform: true
                    ConfigSpinBox {
                        icon: "warning"
                        text: Translation.tr("Low warning")
                        value: Config.options.battery.low
                        from: 0
                        to: 100
                        stepSize: 5
                        onValueChanged: {
                            Config.options.battery.low = value;
                        }
                    }
                    ConfigSpinBox {
                        icon: "dangerous"
                        text: Translation.tr("Critical warning")
                        value: Config.options.battery.critical
                        from: 0
                        to: 100
                        stepSize: 5
                        onValueChanged: {
                            Config.options.battery.critical = value;
                        }
                    }
                }
                ConfigRow {
                    uniform: true
                    ConfigSwitch {
                        buttonIcon: "pause"
                        text: Translation.tr("Automatic suspend")
                        checked: Config.options.battery.automaticSuspend
                        onCheckedChanged: {
                            Config.options.battery.automaticSuspend = checked;
                        }
                    }
                    ConfigSpinBox {
                        enabled: Config.options.battery.automaticSuspend
                        text: Translation.tr("at")
                        value: Config.options.battery.suspend
                        from: 0
                        to: 100
                        stepSize: 5
                        onValueChanged: {
                            Config.options.battery.suspend = value;
                        }
                    }
                }
                ConfigRow {
                    uniform: true
                    ConfigSpinBox {
                        icon: "charger"
                        text: Translation.tr("Full warning")
                        value: Config.options.battery.full
                        from: 0
                        to: 101
                        stepSize: 5
                        onValueChanged: {
                            Config.options.battery.full = value;
                        }
                    }
                }
            }
        }

        ContentSection {
            icon: "volume_up"
            shape: MaterialShape.Shape.Circle
            title: Translation.tr("Audio")
            GroupedList {
                ConfigSwitch {
                    buttonIcon: "hearing"
                    text: Translation.tr("Earbang protection")
                    checked: Config.options.audio.protection.enable
                    onCheckedChanged: {
                        Config.options.audio.protection.enable = checked;
                    }
                }
                ConfigRow {
                    enabled: Config.options.audio.protection.enable
                    ConfigSpinBox {
                        icon: "arrow_warm_up"
                        text: Translation.tr("Max allowed increase")
                        value: Config.options.audio.protection.maxAllowedIncrease
                        from: 0
                        to: 100
                        stepSize: 2
                        onValueChanged: {
                            Config.options.audio.protection.maxAllowedIncrease = value;
                        }
                    }
                    ConfigSpinBox {
                        icon: "vertical_align_top"
                        text: Translation.tr("Volume limit")
                        value: Config.options.audio.protection.maxAllowed
                        from: 0
                        to: 154 // pavucontrol allows up to 153%
                        stepSize: 2
                        onValueChanged: {
                            Config.options.audio.protection.maxAllowed = value;
                        }
                    }
                }
            }
        }

        ContentSection {
            icon: "notification_sound"
            shape: MaterialShape.Shape.Clover8Leaf
            title: Translation.tr("Sounds")
            GroupedList {
                ConfigSwitch {
                    buttonIcon: "battery_android_full"
                    text: Translation.tr("Battery")
                    enabled: Battery.available
                    checked: Config.options.sounds.battery
                    onCheckedChanged: {
                        Config.options.sounds.battery = checked;
                    }
                }
                ConfigSwitch {
                    buttonIcon: "av_timer"
                    text: Translation.tr("Pomodoro")
                    checked: Config.options.sounds.pomodoro
                    onCheckedChanged: {
                        Config.options.sounds.pomodoro = checked;
                    }
                }
            }
        }

        ContentSection {
            icon: "language_japanese_kana"
            shape: MaterialShape.Shape.Gem
            title: Translation.tr("Language")

            GroupedList {
                ConfigComboBox {
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
                    id: translationCol
                    anchors { fill: parent; margins: 0 }
                    spacing: 8

                    ConfigTextArea {
                        id: localeField
                        Layout.fillWidth: true
                        buttonIcon: "translate"
                        text: Translation.tr("Locale code")
                        placeholderText: Translation.tr("e.g. fr_FR, de_DE, zh_CN...")
                        value: Config.options.language.ui === "auto" ? Qt.locale().name : Config.options.language.ui
                    }

                    RippleButtonWithIcon {
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
            icon: "work_alert"
            shape: MaterialShape.Shape.PuffyDiamond
            title: Translation.tr("Work safety")
            GroupedList {
                ConfigSwitch {
                    buttonIcon: "assignment"
                    text: Translation.tr("Hide clipboard images copied from sussy sources")
                    checked: Config.options.workSafety.enable.clipboard
                    onCheckedChanged: {
                        Config.options.workSafety.enable.clipboard = checked;
                    }
                }
                ConfigSwitch {
                    buttonIcon: "wallpaper"
                    text: Translation.tr("Hide sussy/anime wallpapers")
                    checked: Config.options.workSafety.enable.wallpaper
                    onCheckedChanged: {
                        Config.options.workSafety.enable.wallpaper = checked;
                    }
                }
            }
        }
    }
}
