import qs
import qs.modules.common
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pam

Scope {
    id: root

    enum ActionEnum { Unlock, Poweroff, Reboot }

    signal shouldReFocus()
    signal unlocked(targetAction: var)
    signal failed()

    // These properties are in the context and not individual lock surfaces
    // so all surfaces can share the same state.
    property string currentText: ""
    property bool unlockInProgress: false
    property bool showFailure: false
    property bool fingerprintsConfigured: false
    property bool fingerprintScanning: false
    property bool faceScanning: false
    property string faceStatus: ""
    property var targetAction: LockContext.ActionEnum.Unlock
    property bool alsoInhibitIdle: false

    function resetTargetAction() {
        root.targetAction = LockContext.ActionEnum.Unlock;
    }

    function clearText() {
        root.currentText = "";
    }

    function resetClearTimer() {
        passwordClearTimer.restart();
    }

    function reset() {
        root.resetTargetAction();
        root.clearText();
        root.unlockInProgress = false;
        stopFingerPam();
        stopFaceAuth();
    }

    Timer {
        id: passwordClearTimer
        interval: 10000
        onTriggered: {
            root.reset();
        }
    }

    onCurrentTextChanged: {
        if (currentText.length > 0) {
            showFailure = false;
            GlobalStates.screenUnlockFailed = false;
        }
        GlobalStates.screenLockContainsCharacters = currentText.length > 0;
        passwordClearTimer.restart();
    }

    function tryUnlock(alsoInhibitIdle = false) {
        root.alsoInhibitIdle = alsoInhibitIdle;
        root.unlockInProgress = true;
        pam.start();
    }

    function tryFingerUnlock() {
        if (Config.options.lock.biometrics.enableFingerprint && root.fingerprintsConfigured) {
            root.fingerprintScanning = true;
            fingerPam.start();
        }
    }

    function stopFingerPam() {
        if (fingerPam.active) {
            fingerPam.abort();
        }
        root.fingerprintScanning = false;
    }

    function tryFaceUnlock() {
        if (!Config.options.lock.biometrics.enableFaceAuth || faceAuthProc.running) return;
        const command = (Config.options.lock.biometrics.faceCommand ?? "").trim();
        if (command.length === 0) {
            root.faceStatus = "Face authentication command is not configured";
            return;
        }
        root.faceStatus = "Looking for you…";
        root.faceScanning = true;
        faceAuthProc.running = true;
    }

    function stopFaceAuth() {
        if (faceAuthProc.running) faceAuthProc.running = false;
        root.faceScanning = false;
    }

    Process {
        id: fingerprintCheckProc
        running: Config.options.lock.biometrics.enableFingerprint
        command: ["bash", "-c", "fprintd-list $(whoami)"]
        stdout: StdioCollector {
            id: fingerprintOutputCollector
            onStreamFinished: {
                root.fingerprintsConfigured = fingerprintOutputCollector.text.includes("Fingerprints for user");
            }
        }
        onExited: (exitCode, exitStatus) => {
            if (exitCode !== 0) {
                // console.warn("[LockContext] fprintd-list command exited with error:", exitCode, exitStatus);
                root.fingerprintsConfigured = false;
            }
        }
    }

    Process {
        id: faceAuthProc
        running: false
        command: [
            Quickshell.shellPath("scripts/lock/face-auth.sh"),
            Config.options.lock.biometrics.faceCommand,
            Config.options.lock.biometrics.faceTimeoutSeconds.toString()
        ]
        onExited: (exitCode, exitStatus) => {
            root.faceScanning = false;
            if (exitCode === 0) {
                root.faceStatus = "Face verified";
                root.unlocked(root.targetAction);
            } else if (exitCode === 124) {
                root.faceStatus = "Face scan timed out";
            } else {
                root.faceStatus = "Face not recognised";
            }
        }
    }
    
    PamContext {
        id: pam

        // pam_unix will ask for a response for the password prompt
        onPamMessage: {
            if (this.responseRequired) {
                this.respond(root.currentText);
            }
        }

        // pam_unix won't send any important messages so all we need is the completion status.
        onCompleted: result => {
            root.fingerprintScanning = false;
            if (result == PamResult.Success) {
                root.unlocked(root.targetAction);
                stopFingerPam();
            } else {
                root.clearText();
                root.unlockInProgress = false;
                GlobalStates.screenUnlockFailed = true;
                root.showFailure = true;
            }
        }
    }

    PamContext {
        id: fingerPam

        configDirectory: "pam"
        config: "fprintd.conf"

        onCompleted: result => {
            if (result == PamResult.Success) {
                root.unlocked(root.targetAction);
                stopFingerPam();
            } else if (result == PamResult.Error) { // if timeout or etc..
                tryFingerUnlock()
            }
        }
    }
}
