import QtQuick
import QtQuick.Layouts
import qs
import qs.services
import qs.modules.common
import qs.modules.common.models
import qs.modules.common.widgets
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland

Loader {
    id: root
    property bool vertical: false
    property color color: Appearance.colors.colOnSurfaceVariant
    // Auto-visible only when >1 layout (manual layout string or runtime codes)
    readonly property bool hasMultipleLayouts: {
        const fromConfig = (Config.options.hyprland.input.kbLayout || "").split(",").map(s=>s.trim()).filter(s=>s.length>0).length > 1
        const fromRuntime = HyprlandXkb.layoutCodes.length > 1
        return fromConfig || fromRuntime
    }
    function displayFor(code) {
        if (!code) return "--"
        const lc = code.toLowerCase()
        if (lc === "us" || lc === "en") return "EN"
        if (lc === "ara" || lc === "ar" || lc === "eg" || lc === "sa") return "AR"
        return code.toUpperCase().substring(0, 3)
    }

    // Keep Loader alive but collapse when single layout (BarContent also auto-injects, so this avoids duplicate space when user manually added)
    // BarContent injects only when hasMultipleLayouts, so manual single-layout will naturally be hidden here.
    sourceComponent: Item {
        id: container
        // Auto-collapse when single layout (BarContent also injects only when >1, so avoid duplicate spacing)
        implicitWidth: root.hasMultipleLayouts ? (root.vertical ? 32 : rowLayout.implicitWidth + 10) : 0
        implicitHeight: root.hasMultipleLayouts ? (root.vertical ? 24 : rowLayout.implicitHeight + 6) : 0
        visible: root.hasMultipleLayouts
        opacity: root.hasMultipleLayouts ? 1 : 0
        Behavior on implicitWidth { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
        Behavior on opacity { NumberAnimation { duration: 200 } }
        clip: true

        RowLayout {
            id: rowLayout
            visible: !root.vertical
            anchors.centerIn: parent
            spacing: 4
            opacity: root.hasMultipleLayouts && !root.vertical ? 1 : 0

            MaterialSymbol {
                text: "keyboard"
                iconSize: Appearance.font.pixelSize.normal
                color: root.color
            }

            StyledText {
                id: layoutCodeText
                horizontalAlignment: Text.AlignHCenter
                text: {
                    const raw = WM.compositor === "niri" ? NiriXkb.currentLayoutCode : HyprlandXkb.currentLayoutCode
                    return root.displayFor(raw)
                }
                font.pixelSize: Appearance.font.pixelSize.small
                font.weight: 600
                color: root.color
                animateChange: true
            }
        }
        // Vertical bar: just the code text centered, no keyboard icon to avoid 32px clipping ("E" truncation)
        StyledText {
            id: verticalText
            visible: root.vertical
            anchors.centerIn: parent
            opacity: root.hasMultipleLayouts && root.vertical ? 1 : 0
            horizontalAlignment: Text.AlignHCenter
            text: {
                const raw = WM.compositor === "niri" ? NiriXkb.currentLayoutCode : HyprlandXkb.currentLayoutCode
                return root.displayFor(raw)
            }
            font.pixelSize: Appearance.font.pixelSize.small
            font.weight: 600
            color: root.color
            animateChange: true
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            hoverEnabled: true
            enabled: root.hasMultipleLayouts
            onClicked: {
                if (WM.compositor === "hyprland") HyprlandXkb.switchLayoutNext()
            }
            onWheel: wheel => {
                if (wheel.angleDelta.y > 0) {
                    if (WM.compositor === "hyprland") HyprlandXkb.switchLayoutNext()
                } else {
                    if (WM.compositor === "hyprland") HyprlandXkb.switchLayoutPrev()
                }
            }
        }

        // Fallback proc when HyprlandXkb service fails
        Process {
            id: switchProc
            command: ["sh", "-c", "device=$(hyprctl -j devices | python3 -c 'import json,sys; d=json.load(sys.stdin); print([k for k in d[\"keyboards\"] if k.get(\"main\")][0][\"name\"])'); hyprctl switchxkblayout \"$device\" next"]
        }
    }
}
