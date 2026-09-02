import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Bluetooth
import Quickshell.Services.UPower
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions

Item {
    id: root
    implicitHeight: Appearance.sizes.barHeight

    readonly property real islandPadding: 8
    width: contentRow.implicitWidth + islandPadding * 2

    Rectangle {
        id: islandBackground
        anchors.fill: parent
        anchors.margins: Config.options.bar.cornerStyle === 1 ? Appearance.sizes.hyprlandGapsOut : 0
        color: Config.options.bar.showBackground
            ? (Config.options.bar.followFrameColor
                ? Appearance.getColorFromName(Config.options.bar.frameColor)
                : Appearance.colors.colLayer0)
            : "transparent"
        radius: Config.options.bar.cornerStyle === 1 ? Appearance.rounding.windowRounding
              : Config.options.bar.cornerStyle === 0 ? Appearance.rounding.screenRounding
              : Appearance.rounding.full
        border.width: Config.options.bar.cornerStyle === 1 ? 1 : 0
        border.color: Appearance.colors.colLayer0Border

        bottomLeftRadius:  Config.options.bar.cornerStyle === 0 && !Config.options.bar.bottom ? Appearance.rounding.screenRounding : radius
        bottomRightRadius: Config.options.bar.cornerStyle === 0 && !Config.options.bar.bottom ? Appearance.rounding.screenRounding : radius
        topLeftRadius:     Config.options.bar.cornerStyle === 0 &&  Config.options.bar.bottom ? Appearance.rounding.screenRounding : radius
        topRightRadius:    Config.options.bar.cornerStyle === 0 &&  Config.options.bar.bottom ? Appearance.rounding.screenRounding : radius
    }

    RowLayout {
        id: contentRow
        anchors.centerIn: parent
        spacing: 4

        // ── Toggle buttons — state bound to real services ──────────────────
        Repeater {
            model: Config.options.quickActionsBar.toggles
            delegate: QuickToggle {
                required property var modelData
                toggleType: modelData.type
            }
        }

        // Separator if both toggles and sliders present
        Rectangle {
            visible: Config.options.quickActionsBar.toggles.length > 0
                  && (Config.options.quickActionsBar.showVolumeSlider || Config.options.quickActionsBar.showBrightnessSlider)
            width: 1
            height: Appearance.sizes.barHeight * 0.5
            color: Appearance.colors.colOutlineVariant
            Layout.alignment: Qt.AlignVCenter
        }

        // ── Volume Slider ─────────────────────────────────────────────────
        Loader {
            active: Config.options.quickActionsBar.showVolumeSlider
            visible: active
            sourceComponent: RowLayout {
                spacing: 4
                MaterialSymbol {
                    text: Audio.sink?.audio?.muted ? "volume_off" : "volume_up"
                    iconSize: Appearance.font.pixelSize.larger
                    color: Appearance.colors.colOnLayer1
                    MouseArea {
                        anchors.fill: parent
                        onClicked: { if (Audio.sink?.audio) Audio.sink.audio.muted = !Audio.sink.audio.muted }
                    }
                }
                StyledSlider {
                    Layout.preferredWidth: 80
                    from: 0; to: 100
                    value: (Audio.sink?.audio?.volume ?? 0) * 100
                    onMoved: { if (Audio.sink?.audio) Audio.sink.audio.volume = value / 100 }
                }
            }
        }

        // ── Brightness Slider ─────────────────────────────────────────────
        Loader {
            active: Config.options.quickActionsBar.showBrightnessSlider
            visible: active
            sourceComponent: RowLayout {
                id: brightnessRow
                spacing: 4
                readonly property var monitor: root.QsWindow?.window?.screen
                    ? Brightness.getMonitorForScreen(root.QsWindow.window.screen)
                    : null

                MaterialSymbol {
                    text: "brightness_6"
                    iconSize: Appearance.font.pixelSize.larger
                    color: Appearance.colors.colOnLayer1
                }
                StyledSlider {
                    Layout.preferredWidth: 80
                    from: 0; to: 100
                    value: brightnessRow.monitor?.brightness ?? 50
                    onMoved: { if (brightnessRow.monitor) brightnessRow.monitor.brightness = value }
                }
            }
        }
    }

    // ── QuickToggle component ─────────────────────────────────────────────────
    component QuickToggle: Rectangle {
        id: toggleBtn
        required property string toggleType

        // Read state from real services. Unknown/legacy toggle types (e.g. a
        // stale config value from before removal) fall through to the
        // default rather than crashing.
        readonly property bool toggled: {
            switch (toggleType) {
                case "wifi":       return Network.wifiEnabled
                case "bluetooth":  return BluetoothStatus.enabled
                case "nightLight": return Hyprsunset.temperatureActive
                case "darkMode":   return Appearance.m3colors.darkmode
                case "mic":        return !(Audio.source?.audio?.muted ?? true)
                case "dnd":        return Notifications.silent
                case "airplane":   return AirplaneMode.enabled
                case "rotation":   return ScreenRotation.transform !== 0
                case "location":   return LocationAgent.running
                case "nfc":        return NfcStatus.enabled
                case "hotspot":    return Hotspot.active
                default:           return false
            }
        }

        // Toggles backed by a system mechanism that may not be present on
        // this machine (missing binary, no matching hardware, wrong
        // compositor). Unavailable ones are dimmed and inert rather than
        // silently failing on click.
        readonly property bool available: {
            switch (toggleType) {
                case "airplane": return AirplaneMode.available
                case "rotation": return ScreenRotation.available
                case "location": return LocationAgent.available
                case "nfc":      return NfcStatus.available
                case "hotspot":  return Hotspot.available
                default:         return true
            }
        }

        readonly property string unavailableReason: {
            switch (toggleType) {
                case "airplane": return AirplaneMode.unavailableReason
                case "rotation": return ScreenRotation.unavailableReason
                case "location": return LocationAgent.unavailableReason
                case "nfc":      return NfcStatus.unavailableReason
                case "hotspot":  return Hotspot.unavailableReason
                default:         return ""
            }
        }

        implicitWidth:  36
        implicitHeight: 36
        radius: Appearance.rounding.normal
        opacity: toggleBtn.available ? 1 : 0.4

        color: toggleBtn.toggled
            ? Appearance.colors.colPrimaryContainer
            : hoverMa.containsMouse
                ? Appearance.colors.colLayer1
                : "transparent"

        Behavior on color {
            animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
        }

        StyledToolTip {
            text: toggleBtn.available
                ? toggleBtn.toggleType
                : `${toggleBtn.toggleType} (${toggleBtn.unavailableReason})`
        }

        MouseArea {
            id: hoverMa
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: toggleBtn.available ? Qt.PointingHandCursor : Qt.ArrowCursor
            onClicked: if (toggleBtn.available) toggleBtn.activate()
        }

        MaterialSymbol {
            anchors.centerIn: parent
            text: toggleBtn.icon
            iconSize: Appearance.font.pixelSize.larger
            color: toggleBtn.toggled
                ? Appearance.colors.colOnPrimaryContainer
                : Appearance.colors.colOnLayer1
        }

        // Icon depends on type + state
        readonly property string icon: {
            switch (toggleType) {
                case "wifi":       return toggled ? "wifi"                : "wifi_off"
                case "bluetooth":  return toggled ? "bluetooth_connected" : "bluetooth_disabled"
                case "nightLight": return "bedtime"
                case "darkMode":   return toggled ? "light_mode"          : "dark_mode"
                case "mic":        return toggled ? "mic"                 : "mic_off"
                case "dnd":        return toggled ? "do_not_disturb_off"  : "do_not_disturb_on"
                case "airplane":   return toggled ? "flight" : "airplanemode_inactive"
                case "rotation":   return "screen_rotation_alt"
                case "location":   return toggled ? "location_on" : "location_off"
                case "nfc":        return "nfc"
                case "hotspot":    return toggled ? "wifi_tethering" : "wifi_tethering_off"
                default:           return "toggle_on"
            }
        }

        // Dispatch to real service. Unknown toggle types (e.g. a stale config
        // value referencing a type that's no longer implemented) are ignored
        // rather than crashing.
        function activate() {
            switch (toggleType) {
                case "wifi":
                    Network.toggleWifi()
                    break
                case "bluetooth":
                    BluetoothStatus.togglePower()
                    break
                case "nightLight":
                    Hyprsunset.toggleTemperature()
                    break
                case "darkMode":
                    if (Appearance.m3colors.darkmode)
                        Quickshell.execDetached(["bash", "-c",
                            `${Directories.wallpaperSwitchScriptPath} --mode light --noswitch`])
                    else
                        Quickshell.execDetached(["bash", "-c",
                            `${Directories.wallpaperSwitchScriptPath} --mode dark --noswitch`])
                    break
                case "mic":
                    if (Audio.source?.audio) Audio.source.audio.muted = !Audio.source.audio.muted
                    break
                case "dnd":
                    Notifications.silent = !Notifications.silent
                    break
                case "airplane":
                    AirplaneMode.toggle()
                    break
                case "rotation":
                    ScreenRotation.toggle()
                    break
                case "location":
                    LocationAgent.toggle()
                    break
                case "nfc":
                    NfcStatus.toggle()
                    break
                case "hotspot":
                    Hotspot.toggle()
                    break
                default:
                    break
            }
        }
    }
}
