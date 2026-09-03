import QtQuick
import Quickshell.Services.Pam

// Minimal PAM-backed password verifier, reusing the same authentication
// mechanism as the lock screen (Quickshell.Services.Pam PamContext) so that
// "Require password to power off" is enforced consistently everywhere a
// destructive power action can be triggered, not just from the lock screen.
Item {
    id: root

    signal succeeded()
    signal failed()

    readonly property bool inProgress: pam.active

    property string _pendingPassword: ""

    function verify(password) {
        if (pam.active)
            return;
        root._pendingPassword = password;
        pam.start();
    }

    PamContext {
        id: pam

        onPamMessage: {
            if (this.responseRequired) {
                this.respond(root._pendingPassword);
            }
        }

        onCompleted: result => {
            root._pendingPassword = "";
            if (result === PamResult.Success) {
                root.succeeded();
            } else {
                root.failed();
            }
        }
    }
}
