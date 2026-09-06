import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Quickshell.Services.UPower
import Quickshell.Services.Mpris
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import qs.modules.common.panels.lock
import qs.modules.ii.bar as Bar
import Quickshell
import Quickshell.Services.SystemTray

MouseArea {
    id: root
    required property LockContext context
    property bool active: false
    property bool showInputField: active || context.currentText.length > 0
    property bool controlsVisible: true
    function resolveSurfaceScreenName() {
        const directScreen = root.QsWindow.window?.screen?.name
        if (directScreen) return directScreen
        let item = root
        while (item) {
            if (item.screen?.name) return item.screen.name
            item = item.parent
        }
        return ""
    }
    readonly property string surfaceScreenName: resolveSurfaceScreenName()
    readonly property bool isInteractionScreen: surfaceScreenName !== ""
        && GlobalStates.lockInteractionScreenName === surfaceScreenName
    // WlSessionLockSurface is created before its window/screen attachment on
    // some compositors.  Treat that short-lived unknown state as interactive:
    // hiding credentials there made every control disappear permanently when
    // the binding did not get another screen-name notification.
    readonly property bool isPrimaryControlsScreen: !Config.options.lock.unlockBoxPrimaryMonitorOnly
        || surfaceScreenName === "" || surfaceScreenName === GlobalStates.primaryLockOutputName()
    readonly property bool controlsShown: controlsVisible && isPrimaryControlsScreen
        && (surfaceScreenName === "" || GlobalStates.lockInteractionScreenName === "" || isInteractionScreen)
    property real controlsVisibility: controlsShown ? 1 : 0
    readonly property bool requirePasswordToPower: Config.options.lock.security.requirePasswordToPower
    readonly property var screenLayout: GlobalStates.lockLayoutForOutput(surfaceScreenName)
    readonly property string passwordPlacement: screenLayout.passwordPlacement
    readonly property MprisPlayer activePlayer: {
        const preferred = Config.options.bar.media.preferredPlayer.trim().toLowerCase()
        if (preferred.length === 0) return MprisController.activePlayer
        const _ = MprisController.players.count
        for (const p of MprisController.players) {
            if ((p.identity ?? "").toLowerCase().includes(preferred) ||
                (p.desktopEntry ?? "").toLowerCase().includes(preferred))
                return p
        }
        return MprisController.activePlayer
    }

    property var    artUrl:      activePlayer?.trackArtUrl ?? ""

    // Force focus on entry
    function forceFieldFocus() {
        passwordBox.forceActiveFocus();
    }
    function registerInteraction() {
        if (root.surfaceScreenName !== "")
            GlobalStates.lockInteractionScreenName = root.surfaceScreenName
        root.controlsVisible = true
        if (Config.options.lock.autoHideControls)
            controlsIdleTimer.restart()
    }
    Timer {
        id: controlsIdleTimer
        interval: Math.max(1, Config.options.lock.controlsIdleSeconds) * 1000
        repeat: false
        onTriggered: {
            if (Config.options.lock.autoHideControls)
                root.controlsVisible = false
        }
    }
    Connections {
        target: context
        function onShouldReFocus() {
            forceFieldFocus();
        }
    }
    hoverEnabled: true
    acceptedButtons: Qt.LeftButton
    onPressed: mouse => {
        registerInteraction();
        forceFieldFocus();
    }
    onPositionChanged: mouse => {
        registerInteraction();
        forceFieldFocus();
    }

    // Toolbar appearing animation
    property real toolbarScale: 0.9
    property real toolbarOpacity: 0
    Behavior on toolbarScale {
        NumberAnimation {
            duration: Appearance.animation.elementMove.duration
            easing.type: Appearance.animation.elementMove.type
            easing.bezierCurve: Appearance.animationCurves.expressiveFastSpatial
        }
    }
    Behavior on toolbarOpacity {
        animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
    }
    Behavior on controlsVisibility {
        NumberAnimation {
            duration: 180
            easing.type: Easing.OutCubic
        }
    }

    // Init
    Component.onCompleted: {
        // Lock.qml chooses an initial screen. Do not let the last session-lock
        // surface constructed win by accident; pointer movement promotes its
        // own surface through registerInteraction().
        if (GlobalStates.lockInteractionScreenName === ""
            || GlobalStates.lockInteractionScreenName === root.surfaceScreenName) {
            registerInteraction();
            forceFieldFocus();
        }
        toolbarScale = 1;
        toolbarOpacity = 1;
    }

    // Key presses
    property bool ctrlHeld: false
    Keys.onPressed: event => {
        registerInteraction();
        root.context.resetClearTimer();
        if (event.key === Qt.Key_Control) {
            root.ctrlHeld = true;
        }
        if (event.key === Qt.Key_Escape) { // Esc to clear
            root.context.currentText = "";
        } 
        forceFieldFocus();
    }
    Keys.onReleased: event => {
        registerInteraction();
        if (event.key === Qt.Key_Control) {
            root.ctrlHeld = false;
        }
        forceFieldFocus();
    }

    Loader {
        anchors.fill: parent
        z: -1
        active: WM.compositor === "niri"

        sourceComponent: Item {
            anchors.fill: parent

            Image {
                id: lockBgSource
                anchors.fill: parent
                source: Config.options.background.wallpaperPath
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                cache: true
                visible: !Config.options.lock.blur.enable
                sourceSize.width: parent.width
                sourceSize.height: parent.height
            }
            // Was a hardcoded, always-on `radius: 0` (a no-op blur that still
            // paid for a shader pass every frame) instead of ever reading
            // Config.options.lock.blur - the lock-screen blur setting simply
            // never did anything on niri. Loader-gated so disabling it
            // (default is enabled) skips the shader entirely rather than
            // just zeroing its radius.
            Loader {
                anchors.fill: parent
                active: Config.options.lock.blur.enable
                sourceComponent: FastBlur {
                    anchors.fill: parent
                    source: lockBgSource
                    radius: Config.options.lock.blur.radius
                }
            }
        }
    }

    // Main toolbar: password box
    Toolbar {
        id: mainIsland
        visible: opacity > 0.01
        anchors {
            horizontalCenter: root.passwordPlacement === "bottom" || root.passwordPlacement === "center" ? parent.horizontalCenter : undefined
            verticalCenter: root.passwordPlacement === "center" ? parent.verticalCenter : undefined
            left: root.passwordPlacement === "left" ? parent.left : undefined
            right: root.passwordPlacement === "right" ? parent.right : undefined
            bottom: root.passwordPlacement !== "center" ? parent.bottom : undefined
            leftMargin: root.passwordPlacement === "left" ? 28 : 0
            rightMargin: root.passwordPlacement === "right" ? 28 : 0
            bottomMargin: root.passwordPlacement !== "center" ? root.screenLayout.bottomMargin : 0
        }
        transform: Translate { x: root.screenLayout.password.offsetX; y: root.screenLayout.password.offsetY }
        Behavior on anchors.bottomMargin {
            animation: Appearance.animation.elementMove.numberAnimation.createObject(this)
        }

        scale: root.toolbarScale * root.screenLayout.password.scale
            * (0.96 + root.controlsVisibility * 0.04)
        opacity: root.toolbarOpacity * root.controlsVisibility

        // Fingerprint sensor; it remains a button so a user can deliberately
        // start a scan even when automatic scanning is turned off.
        Loader {
            Layout.leftMargin: 10
            Layout.rightMargin: 6
            Layout.alignment: Qt.AlignVCenter
            active: Config.options.lock.biometrics.enableFingerprint && root.context.fingerprintsConfigured
            visible: active

            sourceComponent: IconToolbarButton {
                text: "fingerprint"
                toggled: root.context.fingerprintScanning
                onClicked: root.context.tryFingerUnlock()
                contentItem: MaterialSymbol {
                    anchors.centerIn: parent
                    fill: 1
                    text: "fingerprint"
                    iconSize: Appearance.font.pixelSize.larger
                    color: root.context.fingerprintScanning ? Appearance.colors.colPrimary : Appearance.colors.colOnSurfaceVariant
                    opacity: Config.options.lock.biometrics.showSensorAnimation ? 0.8 : 1
                    scale: root.context.fingerprintScanning ? 1.12 : 1
                    Behavior on color { ColorAnimation { duration: 180 } }
                    Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                    SequentialAnimation on opacity {
                        running: Config.options.lock.biometrics.showSensorAnimation && root.context.fingerprintScanning
                        loops: Animation.Infinite
                        NumberAnimation { to: 0.35; duration: 900 }
                        NumberAnimation { to: 0.9; duration: 900 }
                    }
                }
                StyledToolTip { text: Translation.tr("Scan fingerprint") }
            }
        }

        Loader {
            Layout.leftMargin: 2
            Layout.rightMargin: 2
            active: Config.options.lock.biometrics.enableFaceAuth
            visible: active
            sourceComponent: IconToolbarButton {
                text: "face"
                toggled: root.context.faceScanning
                onClicked: root.context.tryFaceUnlock()
                contentItem: MaterialSymbol {
                    anchors.centerIn: parent
                    text: "face"
                    fill: root.context.faceScanning ? 1 : 0
                    iconSize: Appearance.font.pixelSize.larger
                    color: root.context.faceScanning ? Appearance.colors.colPrimary : Appearance.colors.colOnSurfaceVariant
                    RotationAnimator on rotation {
                        running: root.context.faceScanning && Config.options.lock.biometrics.showSensorAnimation
                        from: 0; to: 360; duration: 1300; loops: Animation.Infinite
                    }
                }
                StyledToolTip { text: root.context.faceStatus || Translation.tr("Scan face") }
            }
        }

        ToolbarTextField {
            id: passwordBox
            Layout.rightMargin: -Layout.leftMargin
            placeholderText: GlobalStates.screenUnlockFailed ? Translation.tr("Incorrect password") : Translation.tr("Enter password")

            // Style
            clip: true
            font.pixelSize: Appearance.font.pixelSize.small
            selectedTextColor: materialShapeChars ? "transparent" : Appearance.colors.colOnSecondaryContainer
            selectionColor: materialShapeChars ? "transparent" : Appearance.colors.colSecondaryContainer

            // Password
            enabled: !root.context.unlockInProgress
            echoMode: TextInput.Password
            inputMethodHints: Qt.ImhSensitiveData

            // Synchronizing (across monitors) and unlocking
            onTextChanged: root.context.currentText = this.text
            onAccepted: {
                root.context.tryUnlock(ctrlHeld);
            }
            Connections {
                target: root.context
                function onCurrentTextChanged() {
                    passwordBox.text = root.context.currentText;
                }
            }

            Keys.onPressed: event => {
                root.context.resetClearTimer();
            }
            
            layer.enabled: true
            layer.effect: OpacityMask {
                maskSource: Rectangle {
                    width: passwordBox.width - 8
                    height: passwordBox.height
                    radius: height / 2
                }
            }

            // Shake when wrong password
            ErrorShakeAnimation {
                id: wrongPasswordShakeAnim
                target: passwordBox
            }
            Connections {
                target: GlobalStates
                function onScreenUnlockFailedChanged() {
                    if (GlobalStates.screenUnlockFailed) wrongPasswordShakeAnim.restart();
                }
            }

            // We're drawing dots manually
            property bool materialShapeChars: Config.options.lock.materialShapeChars
            color: ColorUtils.transparentize(Appearance.colors.colOnLayer1, materialShapeChars ? 1 : 0)
            Loader {
                active: passwordBox.materialShapeChars
                anchors {
                    fill: parent
                    leftMargin: passwordBox.padding
                    rightMargin: passwordBox.padding
                }
                sourceComponent: PasswordChars {
                    length: root.context.currentText.length
                    selectionStart: passwordBox.selectionStart
                    selectionEnd: passwordBox.selectionEnd
                    cursorPosition: passwordBox.cursorPosition
                }
            }
        }

        ToolbarButton {
            id: confirmButton
            implicitWidth: height
            toggled: true
            enabled: !root.context.unlockInProgress
            colBackgroundToggled: Appearance.colors.colPrimary

            onClicked: root.context.tryUnlock()

            contentItem: MaterialSymbol {
                anchors.centerIn: parent
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                iconSize: 24
                text: {
                    if (root.context.targetAction === LockContext.ActionEnum.Unlock) {
                        return root.ctrlHeld ? "coffee" : "arrow_right_alt";
                    } else if (root.context.targetAction === LockContext.ActionEnum.Poweroff) {
                        return "power_settings_new";
                    } else if (root.context.targetAction === LockContext.ActionEnum.Reboot) {
                        return "restart_alt";
                    }
                }
                color: confirmButton.enabled ? Appearance.colors.colOnPrimary : Appearance.colors.colSubtext
            }
        }
    }

    // Left toolbar
    Toolbar {
        id: leftIsland
        // When the password controls are anchored to the left edge, this toolbar
        // can't sensibly sit further left (it would run off-screen), so it stacks
        // above the main island on the same edge instead of flanking it.
        readonly property bool stackedAboveMain: root.passwordPlacement === "left"
        visible: opacity > 0.01
        anchors {
            left: stackedAboveMain ? mainIsland.left : undefined
            right: stackedAboveMain ? undefined : mainIsland.left
            top: stackedAboveMain ? undefined : mainIsland.top
            bottom: stackedAboveMain ? mainIsland.top : mainIsland.bottom
            rightMargin: stackedAboveMain ? 0 : 10
            bottomMargin: stackedAboveMain ? 10 : 0
        }
        Behavior on anchors.bottomMargin {
            animation: Appearance.animation.elementMove.numberAnimation.createObject(this)
        }
        // Own independent offset/scale (Settings > Interface > Lock screen) -
        // no longer tied to the password box or the right toolbar's.
        transform: Translate { x: root.screenLayout.leftToolbar.offsetX; y: root.screenLayout.leftToolbar.offsetY }
        scale: root.toolbarScale * root.screenLayout.leftToolbar.scale
            * (0.96 + root.controlsVisibility * 0.04)
        opacity: root.toolbarOpacity * root.controlsVisibility
            * (Config.options.lock.showToolbars && Config.options.lock.showLeftToolbar ? 1 : 0)

        // Username
        IconAndTextPair {
            Layout.leftMargin: 8
            icon: "account_circle"
            visible: !Config.options.lock.showMedia || MprisController.activePlayer === null
            text: SystemInfo.username
        }

        // Media player info 
        Loader {
            Layout.leftMargin: 2
            Layout.rightMargin: 2
            Layout.alignment: Qt.AlignVCenter
            active: MprisController.activePlayer !== null
            visible: active && Config.options.lock.showMedia
            
            sourceComponent: Item {
                implicitWidth: mediaRow.implicitWidth
                implicitHeight: mediaRow.implicitHeight
                
                readonly property MprisPlayer activePlayer: MprisController.activePlayer
                readonly property string cleanedTitle: StringUtils.cleanMusicTitle(activePlayer?.trackTitle) || ""
                
                Timer {
                    running: activePlayer?.playbackState == MprisPlaybackState.Playing
                    interval: Config.options.resources.updateInterval
                    repeat: true
                    onTriggered: activePlayer.positionChanged()
                }
                
                RowLayout {
                    id: mediaRow
                    spacing: 8
                    anchors.centerIn: parent
                    
                    Rectangle {
                        id: artRect
                        implicitWidth: 40
                        implicitHeight: 40
                        radius: Appearance.rounding.full
                        color: Appearance.colors.colPrimaryContainer
                        Layout.alignment: Qt.AlignVCenter
                        clip: true 

                        layer.enabled: true
                        layer.effect: OpacityMask {
                            maskSource: Rectangle {
                                width: artRect.width
                                height: artRect.height
                                radius: artRect.radius
                            }
                        }

                        StyledImage {
                            anchors.centerIn: parent
                            width: artRect.width
                            height: artRect.height
                            source: root.artUrl
                            fillMode: Image.PreserveAspectCrop
                            cache: false
                            antialiasing: true
                            sourceSize.width: artRect.width * 2
                            sourceSize.height: artRect.height * 2
                            visible: root.artUrl !== ""
                        }

                        MaterialSymbol {
                            anchors.centerIn: parent
                            fill: 1
                            text: "music_note"
                            iconSize: Appearance.font.pixelSize.normal
                            color: Appearance.colors.colOnSecondaryContainer
                            visible: root.artUrl === ""
                        }
                    }
                    
                    Column {
                        Layout.alignment: Qt.AlignVCenter
                        spacing: -2
                        
                        StyledText {
                            horizontalAlignment: Text.AlignLeft
                            elide: Text.ElideRight
                            maximumLineCount: 1
                            width: Math.min(implicitWidth, 180) 
                            color: Appearance.colors.colOnSurfaceVariant
                            text: {
                                var artist = activePlayer?.trackArtist || " ";
                                return artist.length > 25 ? artist.substring(0, 25) + "..." : artist;
                            }
                            font.pixelSize: Appearance.font.pixelSize.smaller
                        }
                        
                        StyledText {
                            horizontalAlignment: Text.AlignLeft
                            elide: Text.ElideRight
                            maximumLineCount: 1
                            width: Math.min(implicitWidth, 180) 
                            color: Appearance.colors.colOnSurfaceVariant
                            text: {
                                var title = cleanedTitle;
                                return title.length > 30 ? title.substring(0, 30) + "..." : title;
                            }
                            font.weight: Font.Medium
                            font.pixelSize: Appearance.font.pixelSize.small
                        }
                    }
                    
                    ClippedFilledCircularProgress {
                        id: mediaCircProg
                        Layout.alignment: Qt.AlignVCenter
                        lineWidth: Appearance.rounding.unsharpen
                        value: activePlayer?.position / activePlayer?.length
                        implicitSize: 24
                        colPrimary: Appearance.colors.colOnSurfaceVariant
                        enableAnimation: false
                        
                        Item {
                            anchors.centerIn: parent
                            width: mediaCircProg.implicitSize
                            height: mediaCircProg.implicitSize
                            
                            MaterialSymbol {
                                anchors.centerIn: parent
                                fill: 1
                                text: "music_note"
                                iconSize: Appearance.font.pixelSize.normal
                                color: Appearance.colors.colOnSurfaceVariant
                            }
                        }
                    }
                }
            }
        }

        // Keyboard layout (Xkb) - always visible, unlike the username above:
        // not knowing your current layout while typing an unlock password is
        // a real usability problem, not just visual crowding, so this one
        // doesn't yield its slot to the media widget.
        Loader {
            Layout.rightMargin: 8
            Layout.fillHeight: true
            visible: true

            sourceComponent: Row {
                spacing: 8

                MaterialSymbol {
                    id: keyboardIcon
                    anchors.verticalCenter: parent.verticalCenter
                    fill: 1
                    text: "keyboard_alt"
                    iconSize: Appearance.font.pixelSize.huge
                    color: Appearance.colors.colOnSurfaceVariant
                }
                Loader {
                    anchors.verticalCenter: parent.verticalCenter
                    sourceComponent: StyledText {
                        text: HyprlandXkb.currentLayoutCode
                        color: Appearance.colors.colOnSurfaceVariant
                        animateChange: true
                    }
                }
            }
        }

        // Keyboard layout (Fcitx)
        Bar.SysTray {
            Layout.rightMargin: 10
            Layout.alignment: Qt.AlignVCenter
            showSeparator: false
            showOverflowMenu: false
            pinnedItems: SystemTray.items.values.filter(i => i.id == "Fcitx")
            visible: pinnedItems.length > 0
        }
    }

    // Right toolbar
    Toolbar {
        id: rightIsland
        // Mirror of leftIsland's logic: when the password controls hug the right
        // edge, stack above main on that edge instead of flanking off-screen.
        readonly property bool stackedAboveMain: root.passwordPlacement === "right"
        visible: opacity > 0.01
        anchors {
            right: stackedAboveMain ? mainIsland.right : undefined
            left: stackedAboveMain ? undefined : mainIsland.right
            top: stackedAboveMain ? undefined : mainIsland.top
            bottom: stackedAboveMain ? mainIsland.top : mainIsland.bottom
            leftMargin: stackedAboveMain ? 0 : 10
            bottomMargin: stackedAboveMain ? 10 : 0
        }
        Behavior on anchors.bottomMargin {
            animation: Appearance.animation.elementMove.numberAnimation.createObject(this)
        }
        // Own independent offset/scale, same as the left toolbar above.
        transform: Translate { x: root.screenLayout.rightToolbar.offsetX; y: root.screenLayout.rightToolbar.offsetY }
        scale: root.toolbarScale * root.screenLayout.rightToolbar.scale
            * (0.96 + root.controlsVisibility * 0.04)
        opacity: root.toolbarOpacity * root.controlsVisibility
            * (Config.options.lock.showToolbars && Config.options.lock.showRightToolbar ? 1 : 0)

        IconAndTextPair {
            visible: Battery.available
            icon: Battery.isCharging ? "bolt" : "battery_android_full"
            text: Math.round(Battery.percentage * 100)
            color: (Battery.isLow && !Battery.isCharging) ? Appearance.colors.colError : Appearance.colors.colOnSurfaceVariant
        }

        IconToolbarButton {
            id: sleepButton
            onClicked: Session.suspend()
            text: "dark_mode"
        }

        PasswordGuardedIconToolbarButton {
            id: powerButton
            text: "power_settings_new"
            targetAction: LockContext.ActionEnum.Poweroff
        }

        PasswordGuardedIconToolbarButton {
            id: rebootButton
            text: "restart_alt"
            targetAction: LockContext.ActionEnum.Reboot
        }
    }

    component PasswordGuardedIconToolbarButton: IconToolbarButton {
        id: guardedBtn
        required property var targetAction

        toggled: root.context.targetAction === guardedBtn.targetAction

        onClicked: {
            if (!root.requirePasswordToPower) {
                root.context.unlocked(guardedBtn.targetAction);
                return;
            }
            if (root.context.targetAction === guardedBtn.targetAction) {
                root.context.resetTargetAction();
            } else {
                root.context.targetAction = guardedBtn.targetAction;
                root.context.shouldReFocus();
            }
        }
    }

    component IconAndTextPair: Row {
        id: pair
        required property string icon
        required property string text
        property color color: Appearance.colors.colOnSurfaceVariant

        spacing: 4
        Layout.fillHeight: true
        Layout.leftMargin: 10
        Layout.rightMargin: 10
        

        MaterialSymbol {
            anchors.verticalCenter: parent.verticalCenter
            fill: 1
            text: pair.icon
            iconSize: Appearance.font.pixelSize.huge
            animateChange: true
            color: pair.color
        }
        StyledText {
            anchors.verticalCenter: parent.verticalCenter
            text: pair.text
            color: pair.color
        }
    }
}
