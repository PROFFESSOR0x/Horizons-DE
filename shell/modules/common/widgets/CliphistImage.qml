import qs.modules.common
import qs.modules.common.widgets
import qs.services
import qs.modules.common.functions
import Qt5Compat.GraphicalEffects
import QtQuick
import Quickshell
import Quickshell.Io

Rectangle {
    id: root
    property string entry
    property real maxWidth
    property real maxHeight
    property bool blur: false
    property string blurText: "Image hidden"

    property string imageDecodePath: Directories.cliphistDecode
    property string imageDecodeFileName: `${entryNumber}`
    property string imageDecodeFilePath: `${imageDecodePath}/${imageDecodeFileName}`
    property string source

    property int entryNumber: {
        if (!root.entry)
            return 0;
        const match = root.entry.match(/^(\d+)\t/);
        return match ? parseInt(match[1]) : 0;
    }
    property int imageWidth: {
        if (!root.entry)
            return 0;
        const match = root.entry.match(/(\d+)x(\d+)/);
        return match ? parseInt(match[1]) : 0;
    }
    property int imageHeight: {
        if (!root.entry)
            return 0;
        const match = root.entry.match(/(\d+)x(\d+)/);
        return match ? parseInt(match[2]) : 0;
    }
    property real scale: {
        return (imageWidth > 0 && imageHeight > 0) ? Math.min(root.maxWidth / imageWidth, root.maxHeight / imageHeight, 1) : 0;
    }

    color: Appearance.colors.colLayer1
    radius: Appearance.rounding.small
    implicitHeight: imageHeight * scale
    implicitWidth: imageWidth * scale

    function decode() {
        root.source = ""
        if (decodeImageProcess.running || root.entryNumber < 1) return
        decodeImageProcess.requestedPath = root.imageDecodeFilePath
        decodeImageProcess.exec(["bash", "-c",
            `set -e; umask 077; mkdir -p -- "$1"; if [ ! -s "$2" ]; then tmp=$(mktemp "$2.XXXXXX"); trap 'rm -f -- "$tmp"' EXIT; printf "%s\\n" "$3" | "$4" decode > "$tmp"; test -s "$tmp"; mv -- "$tmp" "$2"; fi`,
            "cliphist-thumbnail", root.imageDecodePath, root.imageDecodeFilePath,
            String(root.entryNumber), Cliphist.cliphistBinary])
    }
    Component.onCompleted: decode()
    onEntryChanged: Qt.callLater(root.decode)

    Process {
        id: decodeImageProcess
        property string requestedPath: ""
        onExited: (exitCode, exitStatus) => {
            if (requestedPath !== root.imageDecodeFilePath) {
                Qt.callLater(root.decode)
                return
            }
            root.source = exitCode === 0 ? "file://" + requestedPath : ""
        }
    }
    // Files are shared by delegates: destroying one must not delete another
    // view's image. Cache cleanup belongs to the service, never to a row.

    layer.enabled: true
    layer.effect: OpacityMask {
        maskSource: Rectangle {
            width: image.width
            height: image.height
            radius: root.radius
        }
    }

    StyledImage {
        id: image
        anchors.fill: parent

        source: Qt.resolvedUrl(root.source)
        fillMode: Image.PreserveAspectFit
        antialiasing: true
        asynchronous: true

        width: root.imageWidth * root.scale
        height: root.imageHeight * root.scale
        sourceSize.width: width
        sourceSize.height: height
    }

    Loader {
        id: blurLoader
        active: root.blur
        anchors.fill: image
        sourceComponent: GaussianBlur {
            source: image
            radius: 35
            samples: radius * 2 + 1

            Rectangle {
                anchors.fill: parent
                color: ColorUtils.transparentize(Appearance.colors.colLayer0, 0.5)

                Column {
                    anchors {
                        left: parent.left
                        right: parent.right
                        verticalCenter: parent.verticalCenter
                    }
                    MaterialSymbol {
                        visible: width <= image.width
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "visibility_off"
                        font.pixelSize: 28
                    }
                    StyledText {
                        visible: width <= image.width
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: root.blurText
                        color: Appearance.colors.colOnSurface
                        font.pixelSize: Appearance.font.pixelSize.smallie
                    }
                }
            }
        }
    }
}
