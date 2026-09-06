import QtQuick
import Quickshell
import Quickshell.Widgets
import Qt5Compat.GraphicalEffects

Item {
    id: root
    
    property bool colorize: false
    property color color
    property string source: ""
    property string iconFolder: Qt.resolvedUrl(Quickshell.shellPath("assets/icons"))  // The folder to check first
    width: 30
    height: 30
    
    IconImage {
        id: iconImage
        anchors.fill: parent
        source: {
            if (!root.source) return ""
            // An absolute path/URL is used as-is.
            if (root.source.startsWith("/") || root.source.includes("://")) return root.source
            if (!root.iconFolder) return root.source
            // Icon *names* are stored without an extension (IconPickerDialog
            // strips ".svg", SystemInfo hands out e.g. "arch-symbolic"), but
            // this used to concatenate the bare name straight onto the folder
            // and hand IconImage an extensionless path it cannot open. Add the
            // asset's extension unless the caller already supplied one.
            const name = /\.[a-zA-Z0-9]+$/.test(root.source) ? root.source : root.source + ".svg"
            return root.iconFolder + "/" + name
        }
        implicitSize: root.height
    }

    Loader {
        active: root.colorize
        anchors.fill: iconImage
        sourceComponent: ColorOverlay {
            source: iconImage
            color: root.color
        }
    }
}
