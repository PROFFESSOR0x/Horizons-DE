import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import qs.modules.common
import qs.modules.common.widgets
import qs.services

ContentPage {
    id: page
    property var state: ({users: [], themes: [], sessions: [], authentication: {}})
    property string selectedUser: ""
    readonly property var account: state.users.find(user => user.name === selectedUser) ?? ({})
    property string message: ""
    property string pendingAction: ""
    property var pendingData: ({})
    property string pendingSummary: ""
    property string fullNameDraft: ""
    property string newName: ""
    property string newFullName: ""
    property string themeDraft: ""
    property string sessionDraft: ""
    property string autoUserDraft: ""
    property bool rememberUserDraft: true
    property bool rememberSessionDraft: true
    property string finger: "right-index-finger"
    readonly property string helper: Directories.scriptPath + "/settings/system_settings.py"
    readonly property bool busy: statusProcess.running || actionProcess.running

    function refresh() { if (!busy) statusProcess.running = true }
    function request(action, data, summary) {
        pendingAction = action
        pendingData = data
        pendingSummary = summary
    }
    function enroll(action) {
        actionProcess.command = ["python3", helper, "terminal", JSON.stringify({
            action: action, name: selectedUser, finger: finger, terminal: Config.options.apps.terminal
        })]
        actionProcess.running = true
    }
    function authentication(service, kind, enabled) {
        const previous = state.authentication[service] ?? {}
        const data = {service: service, fingerprint: !!previous.fingerprint, face: !!previous.face}
        data[kind] = enabled
        request("authentication", data, Translation.tr("Apply authentication methods for %1?").arg(service))
    }
    onSelectedUserChanged: fullNameDraft = account.fullName ?? ""
    Component.onCompleted: refresh()
    Process {
        id: statusProcess
        command: ["python3", page.helper, "status"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const result = JSON.parse(text)
                    if (result.error) { page.message = result.error; return }
                    page.state = result
                    if (!result.users.some(user => user.name === page.selectedUser))
                        page.selectedUser = (result.users.find(user => user.current) ?? result.users[0] ?? {}).name ?? ""
                    page.fullNameDraft = page.account.fullName ?? ""
                    page.themeDraft = result.theme
                    page.sessionDraft = result.autoSession
                    page.autoUserDraft = result.autoUser
                    page.rememberUserDraft = result.rememberUser
                    page.rememberSessionDraft = result.rememberSession
                } catch (error) { page.message = Translation.tr("Could not read system settings") }
            }
        }
    }
    Process {
        id: actionProcess
        property string output: ""
        stdout: StdioCollector { onStreamFinished: actionProcess.output = text }
        onExited: (code, status) => {
            page.message = code === 0 ? Translation.tr("Operation completed. Refresh after finishing enrollment in the terminal.") : Translation.tr("Operation failed or authorization was cancelled.") + "\n" + output
            output = ""
            page.pendingAction = ""
            Qt.callLater(page.refresh)
        }
    }

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 20
        RowLayout {
            Layout.fillWidth: true
            StyledText {
                Layout.fillWidth: true
                text: page.settingsRoute === "users" ? Translation.tr("Local accounts on this computer") : Translation.tr("Login manager: %1").arg(page.state.manager || Translation.tr("Not detected"))
                wrapMode: Text.WordWrap
            }
            RippleButtonWithIcon { mainText: Translation.tr("Refresh"); materialIcon: "refresh"; enabled: !page.busy; onClicked: page.refresh() }
        }
        StyledText { Layout.fillWidth: true; visible: page.message !== ""; text: page.message; wrapMode: Text.Wrap }
        ContentSection {
            visible: page.pendingAction !== ""
            title: Translation.tr("Review change")
            icon: "admin_panel_settings"
            StyledText { Layout.fillWidth: true; text: page.pendingSummary; wrapMode: Text.WordWrap }
            RowLayout {
                RippleButtonWithIcon {
                    mainText: Translation.tr("Apply as administrator")
                    materialIcon: "check"
                    enabled: !page.busy && !!page.state.pkexec
                    onClicked: {
                        if (["fingerprint-delete", "face-clear"].includes(page.pendingAction)) {
                            page.enroll(page.pendingAction)
                        } else {
                            actionProcess.command = ["pkexec", "python3", page.helper, page.pendingAction, JSON.stringify(page.pendingData)]
                            actionProcess.running = true
                        }
                    }
                }
                RippleButtonWithIcon { mainText: Translation.tr("Cancel"); materialIcon: "close"; enabled: !page.busy; onClicked: page.pendingAction = "" }
            }
        }
        ContentSection {
            visible: page.settingsShow("users")
            objectName: "SystemUsers.accounts"
            title: Translation.tr("Users")
            icon: "group"
            ConfigSelectionArray {
                text: Translation.tr("Selected account")
                currentValue: page.selectedUser
                options: page.state.users.map(user => ({displayName: user.name + (user.current ? " • " + Translation.tr("You") : ""), value: user.name}))
                onSelected: value => page.selectedUser = value
            }
            StyledText {
                Layout.fillWidth: true
                text: (page.account.administrator ? Translation.tr("Administrator") : Translation.tr("Standard user")) + "\n" + (page.account.home ?? "")
                wrapMode: Text.WordWrap
            }
            ConfigTextArea { text: Translation.tr("Full name"); value: page.fullNameDraft; onEdited: value => page.fullNameDraft = value }
            RowLayout {
                RippleButtonWithIcon {
                    mainText: Translation.tr("Save name"); materialIcon: "save"; enabled: !page.busy && page.selectedUser !== ""
                    onClicked: page.request("rename-user", {name: page.selectedUser, fullName: page.fullNameDraft}, Translation.tr("Change the name of %1 to %2?").arg(page.selectedUser).arg(page.fullNameDraft))
                }
                RippleButtonWithIcon { mainText: Translation.tr("Change password"); materialIcon: "password"; enabled: !page.busy && page.selectedUser !== ""; onClicked: page.enroll("password") }
            }
            ConfigSwitch {
                text: Translation.tr("Administrator access")
                checked: !!page.account.administrator
                autoToggle: false
                enabled: !page.busy && !page.account.current && page.selectedUser !== ""
                onClicked: page.request("administrator", {name: page.selectedUser, enabled: !page.account.administrator}, Translation.tr("Change administrator access for %1?").arg(page.selectedUser))
            }
            StyledText { Layout.fillWidth: true; text: Translation.tr("Administrator groups are wheel or sudo. Existing custom sudo rules remain in effect."); wrapMode: Text.WordWrap }
        }
        ContentSection {
            visible: page.settingsShow("users")
            objectName: "SystemUsers.biometrics"
            title: Translation.tr("Fingerprints & face")
            icon: "fingerprint"
            StyledText { Layout.fillWidth: true; text: Translation.tr("Enrollment applies to the selected account. Login and sudo methods are configured under Login options."); wrapMode: Text.WordWrap }
            ConfigSelectionArray {
                text: Translation.tr("Finger")
                currentValue: page.finger
                options: [
                    {displayName: Translation.tr("Right index"), value: "right-index-finger"},
                    {displayName: Translation.tr("Left index"), value: "left-index-finger"},
                    {displayName: Translation.tr("Right thumb"), value: "right-thumb"},
                    {displayName: Translation.tr("Left thumb"), value: "left-thumb"}
                ]
                onSelected: value => page.finger = value
            }
            Flow {
                Layout.fillWidth: true
                spacing: 8
                enabled: !!page.state.fingerprint && !page.busy && page.selectedUser !== ""
                RippleButtonWithIcon { mainText: Translation.tr("Add fingerprint"); materialIcon: "fingerprint"; onClicked: page.enroll("fingerprint-enroll") }
                RippleButtonWithIcon { mainText: Translation.tr("List fingerprints"); materialIcon: "list"; onClicked: page.enroll("fingerprint-list") }
                RippleButtonWithIcon { mainText: Translation.tr("Test fingerprint"); materialIcon: "verified_user"; onClicked: page.enroll("fingerprint-verify") }
                RippleButtonWithIcon { mainText: Translation.tr("Remove fingerprints"); materialIcon: "delete"; onClicked: page.request("fingerprint-delete", {}, Translation.tr("Remove all fingerprints for %1?").arg(page.selectedUser)) }
            }
            StyledText { visible: !page.state.fingerprint; text: Translation.tr("Install fprintd to manage fingerprints."); wrapMode: Text.WordWrap; Layout.fillWidth: true }
            Flow {
                Layout.fillWidth: true
                spacing: 8
                enabled: !!page.state.face && !page.busy && page.selectedUser !== ""
                RippleButtonWithIcon { mainText: Translation.tr("Add face"); materialIcon: "face"; onClicked: page.enroll("face-add") }
                RippleButtonWithIcon { mainText: Translation.tr("List faces"); materialIcon: "list"; onClicked: page.enroll("face-list") }
                RippleButtonWithIcon { mainText: Translation.tr("Test camera"); materialIcon: "camera"; onClicked: page.enroll("face-test") }
                RippleButtonWithIcon { mainText: Translation.tr("Remove faces"); materialIcon: "delete"; onClicked: page.request("face-clear", {}, Translation.tr("Remove all face models for %1?").arg(page.selectedUser)) }
            }
            StyledText { visible: !page.state.face; text: Translation.tr("Install Howdy to manage face authentication."); wrapMode: Text.WordWrap; Layout.fillWidth: true }
        }
        ContentSection {
            visible: page.settingsShow("users")
            objectName: "SystemUsers.new-account"
            title: Translation.tr("Add account")
            icon: "person_add"
            ConfigTextArea { text: Translation.tr("User name"); placeholderText: "username"; value: page.newName; onEdited: value => page.newName = value }
            ConfigTextArea { text: Translation.tr("Full name"); value: page.newFullName; onEdited: value => page.newFullName = value }
            StyledText { Layout.fillWidth: true; text: Translation.tr("New accounts start without a usable password. Select the new account and set its password before signing in."); wrapMode: Text.WordWrap }
            RippleButtonWithIcon {
                mainText: Translation.tr("Create account"); materialIcon: "person_add"; enabled: !page.busy && /^[a-z_][a-z0-9_-]{0,31}$/.test(page.newName)
                onClicked: page.request("create-user", {name: page.newName, fullName: page.newFullName}, Translation.tr("Create local account %1?").arg(page.newName))
            }
        }
        ContentSection {
            visible: page.settingsShow("users")
            objectName: "SystemUsers.remove-account"
            title: Translation.tr("Remove account")
            icon: "person_remove"
            StyledText { Layout.fillWidth: true; text: Translation.tr("The home directory is kept. Your current account cannot be removed here."); wrapMode: Text.WordWrap }
            RippleButtonWithIcon {
                mainText: Translation.tr("Remove selected account"); materialIcon: "delete"; enabled: !page.busy && !page.account.current && page.selectedUser !== ""
                onClicked: page.request("delete-user", {name: page.selectedUser}, Translation.tr("Remove account %1 and keep its files?").arg(page.selectedUser))
            }
        }
        ContentSection {
            visible: page.settingsShow("login")
            objectName: "SystemUsers.login-screen"
            title: Translation.tr("Login screen")
            icon: "login"
            StyledText { Layout.fillWidth: true; text: Translation.tr("Changes apply at the next login. The current session is not restarted."); wrapMode: Text.WordWrap }
            StyledText { visible: page.state.manager !== "sddm"; Layout.fillWidth: true; text: Translation.tr("Login screen editing currently supports SDDM."); wrapMode: Text.WordWrap }
            ColumnLayout {
                Layout.fillWidth: true
                enabled: page.state.manager === "sddm" && !page.busy
                ConfigSelectionArray { text: Translation.tr("Login theme"); currentValue: page.themeDraft; options: page.state.themes.map(name => ({displayName: name, value: name})); onSelected: value => page.themeDraft = value }
                ConfigSwitch { text: Translation.tr("Remember last user"); checked: page.rememberUserDraft; onEdited: value => page.rememberUserDraft = value }
                ConfigSwitch { text: Translation.tr("Remember last session"); checked: page.rememberSessionDraft; onEdited: value => page.rememberSessionDraft = value }
                ConfigSelectionArray {
                    text: Translation.tr("Automatic login")
                    currentValue: page.autoUserDraft
                    options: [{displayName: Translation.tr("Disabled"), value: ""}].concat(page.state.users.map(user => ({displayName: user.name, value: user.name})))
                    onSelected: value => page.autoUserDraft = value
                }
                ConfigSelectionArray { visible: page.autoUserDraft !== ""; text: Translation.tr("Login session"); currentValue: page.sessionDraft; options: page.state.sessions.map(name => ({displayName: name, value: name})); onSelected: value => page.sessionDraft = value }
                StyledText { visible: page.autoUserDraft !== ""; Layout.fillWidth: true; text: Translation.tr("Automatic login opens this account without authentication at startup."); wrapMode: Text.WordWrap }
                RippleButtonWithIcon {
                    mainText: Translation.tr("Apply login settings"); materialIcon: "save"
                    enabled: page.autoUserDraft === "" || page.sessionDraft !== ""
                    onClicked: page.request("login", {theme: page.themeDraft, user: page.autoUserDraft, session: page.sessionDraft, rememberUser: page.rememberUserDraft, rememberSession: page.rememberSessionDraft}, Translation.tr("Apply login screen changes? Automatic login: %1. Theme: %2.").arg(page.autoUserDraft || Translation.tr("Disabled")).arg(page.themeDraft))
                }
            }
        }
        ContentSection {
            visible: page.settingsShow("login")
            objectName: "SystemUsers.authentication"
            title: Translation.tr("Authentication methods")
            icon: "admin_panel_settings"
            StyledText { Layout.fillWidth: true; text: Translation.tr("Password fallback stays enabled. These switches manage Horizons biometric rules; distribution-managed or custom PAM layouts are shown read-only."); wrapMode: Text.WordWrap }
            Repeater {
                model: ["sudo", "sddm"]
                delegate: ColumnLayout {
                    required property string modelData
                    readonly property var methods: page.state.authentication[modelData] ?? ({})
                    Layout.fillWidth: true
                    StyledText { text: modelData === "sudo" ? Translation.tr("Administrative commands (sudo)") : Translation.tr("Login screen (SDDM)") }
                    ConfigSwitch {
                        text: Translation.tr("Use fingerprint")
                        checked: !!methods.fingerprint
                        autoToggle: false
                        enabled: !!methods.supported && !!page.state.fingerprintPam && !page.busy && (modelData !== "sddm" || page.state.manager === "sddm")
                        onClicked: page.authentication(modelData, "fingerprint", !methods.fingerprint)
                    }
                    ConfigSwitch {
                        text: Translation.tr("Use face recognition")
                        checked: !!methods.face
                        autoToggle: false
                        enabled: !!methods.supported && !!page.state.facePam && !page.busy && (modelData !== "sddm" || page.state.manager === "sddm")
                        onClicked: page.authentication(modelData, "face", !methods.face)
                    }
                    StyledText { Layout.fillWidth: true; visible: !methods.supported; text: Translation.tr("Managed or custom authentication layout: use your distribution tool."); wrapMode: Text.WordWrap }
                }
            }
        }
    }
}
