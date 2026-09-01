pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import qs.modules.common
import qs.modules.common.widgets

ColumnLayout {
    id: root

    property real vidDuration: 30
    property real vidCurrentPos: 0
    property real vidMarkIn: 0
    property real vidMarkOut: 0
    property bool vidIsPlaying: false
    property real fps: 30
    property var annotations: []
    property int selectedAnnotationIndex: -1

    signal tlSeek(real seekPos)
    signal tlStep(int frameDelta)
    signal tlMarkIn()
    signal tlMarkOut()
    signal tlPlayPause()
    signal tlStop()
    signal annotationSelected(int index)
    signal annotationRangeChanged(int index, real startSec, real endSec)
    signal annotationDeleted(int index)

    function formatTime(seconds) {
        if (!seconds || isNaN(seconds) || seconds < 0) seconds = 0
        let m = Math.floor(seconds / 60)
        let s = Math.floor(seconds % 60)
        let ms = Math.floor((seconds % 1) * 100)
        return m.toString().padStart(2, "0") + ":" + s.toString().padStart(2, "0") + "." + ms.toString().padStart(2, "0")
    }

    readonly property var currentAnnotation: (selectedAnnotationIndex >= 0 && annotations && selectedAnnotationIndex < annotations.length)
        ? annotations[selectedAnnotationIndex]
        : null

    spacing: 6

    // 1. Timeline bar with Annotation Chips & Scrubber
    Rectangle {
        id: timelineTrack
        Layout.fillWidth: true
        height: 48
        radius: Appearance.rounding.small
        color: Appearance.colors.colLayer1

        // Inner track area
        Rectangle {
            id: trackInner
            anchors.left: parent.left
            anchors.leftMargin: 12
            anchors.right: parent.right
            anchors.rightMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            height: 14
            radius: 7
            color: Appearance.colors.colLayer2
            clip: false

            // Trim range highlight (Mark In -> Mark Out)
            Rectangle {
                x: (root.vidDuration > 0) ? (root.vidMarkIn / root.vidDuration) * parent.width : 0
                width: (root.vidDuration > 0 && root.vidMarkOut > root.vidMarkIn)
                    ? ((root.vidMarkOut - root.vidMarkIn) / root.vidDuration) * parent.width
                    : 0
                height: parent.height
                radius: 4
                color: Appearance.colors.colPrimary
                opacity: 0.25
                visible: root.vidMarkOut > root.vidMarkIn
            }

            // Annotation markers/chips on the timeline
            Repeater {
                model: root.annotations ? root.annotations : []
                delegate: Item {
                    id: annChipItem
                    required property var modelData
                    required property int index

                    readonly property real annStart: (modelData && modelData.startTime !== undefined) ? modelData.startTime : 0
                    readonly property real annEnd: (modelData && modelData.endTime !== undefined) ? modelData.endTime : (annStart + 3)
                    readonly property bool isSelected: root.selectedAnnotationIndex === index

                    x: (root.vidDuration > 0) ? Math.max(0, (annStart / root.vidDuration) * trackInner.width) : 0
                    width: (root.vidDuration > 0) ? Math.max(10, ((annEnd - annStart) / root.vidDuration) * trackInner.width) : 10
                    height: trackInner.height + (isSelected ? 6 : 2)
                    y: isSelected ? -3 : -1

                    Rectangle {
                        anchors.fill: parent
                        radius: 4
                        color: annChipItem.isSelected
                            ? Appearance.colors.colTertiary
                            : (annChipMa.containsMouse ? Appearance.colors.colPrimary : Appearance.colors.colPrimaryContainer)
                        border.width: annChipItem.isSelected ? 2 : 1
                        border.color: annChipItem.isSelected ? Appearance.colors.colOnTertiary : Appearance.colors.colPrimary
                        opacity: 0.85

                        Row {
                            anchors.centerIn: parent
                            spacing: 2
                            visible: parent.width > 24
                            MaterialSymbol {
                                iconSize: 10
                                text: {
                                    let t = annChipItem.modelData?.tool
                                    if (t === "blur") return "blur_on"
                                    if (t === "arrow") return "north_east"
                                    if (t === "rect") return "rectangle"
                                    if (t === "circle") return "circle"
                                    if (t === "highlight") return "ink_highlighter"
                                    return "draw"
                                }
                                color: annChipItem.isSelected ? Appearance.colors.colOnTertiary : Appearance.colors.colOnPrimaryContainer
                            }
                        }
                    }

                    MouseArea {
                        id: annChipMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            root.selectedAnnotationIndex = annChipItem.index
                            root.annotationSelected(annChipItem.index)
                            root.tlSeek(annChipItem.annStart)
                        }
                    }

                    StyledToolTip {
                        text: (annChipItem.modelData?.tool ? annChipItem.modelData.tool.toUpperCase() : "Annotation") +
                              " [" + root.formatTime(annChipItem.annStart) + " → " + root.formatTime(annChipItem.annEnd) + "]"
                    }
                }
            }

            // Playhead scrubber needle
            Rectangle {
                id: playhead
                x: (root.vidDuration > 0)
                    ? Math.max(0, Math.min(trackInner.width - 2, (root.vidCurrentPos / root.vidDuration) * trackInner.width - 2))
                    : 0
                y: -6
                width: 4
                height: trackInner.height + 12
                radius: 2
                color: Appearance.colors.colPrimary
                z: 10

                Rectangle {
                    anchors.top: parent.top
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: 12
                    height: 12
                    radius: 6
                    color: Appearance.colors.colPrimary
                }
            }

            // Interactive scrubber mouse area
            MouseArea {
                id: scrubArea
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                preventStealing: true

                function updateSeek(mouse) {
                    let ratio = Math.max(0, Math.min(1, mouse.x / width))
                    root.tlSeek(ratio * root.vidDuration)
                }

                onPressed: (mouse) => updateSeek(mouse)
                onPositionChanged: (mouse) => {
                    if (pressed) updateSeek(mouse)
                }
            }
        }
    }

    // 2. Playback & Frame Stepping Controls Row
    RowLayout {
        Layout.fillWidth: true
        spacing: 8

        // Frame -1
        Rectangle {
            width: 32; height: 32; radius: 16
            color: stepBackMa.containsMouse ? Appearance.colors.colLayer2 : "transparent"
            MaterialSymbol {
                anchors.centerIn: parent
                text: "skip_previous"
                iconSize: 18
                color: Appearance.colors.colOnLayer1
            }
            MouseArea {
                id: stepBackMa
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.tlStep(-1)
            }
            StyledToolTip { text: "Step -1 Frame (Left Arrow)" }
        }

        // Play/Pause
        Rectangle {
            width: 36; height: 36; radius: 18
            color: ppMa.containsMouse ? Appearance.colors.colPrimaryContainer : Appearance.colors.colLayer2
            MaterialSymbol {
                anchors.centerIn: parent
                text: root.vidIsPlaying ? "pause" : "play_arrow"
                iconSize: 20
                color: root.vidIsPlaying ? Appearance.colors.colPrimary : Appearance.colors.colOnLayer1
            }
            MouseArea {
                id: ppMa
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.tlPlayPause()
            }
            StyledToolTip { text: "Play / Pause (Space)" }
        }

        // Stop
        Rectangle {
            width: 32; height: 32; radius: 16
            color: stopMa.containsMouse ? Appearance.colors.colErrorContainer : "transparent"
            MaterialSymbol {
                anchors.centerIn: parent
                text: "stop"
                iconSize: 18
                color: Appearance.colors.colOnLayer1
            }
            MouseArea {
                id: stopMa
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.tlStop()
            }
            StyledToolTip { text: "Stop" }
        }

        // Frame +1
        Rectangle {
            width: 32; height: 32; radius: 16
            color: stepFwdMa.containsMouse ? Appearance.colors.colLayer2 : "transparent"
            MaterialSymbol {
                anchors.centerIn: parent
                text: "skip_next"
                iconSize: 18
                color: Appearance.colors.colOnLayer1
            }
            MouseArea {
                id: stepFwdMa
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.tlStep(1)
            }
            StyledToolTip { text: "Step +1 Frame (Right Arrow)" }
        }

        // Timecode & Frame indicators
        Rectangle {
            height: 28
            Layout.preferredWidth: timeRow.implicitWidth + 16
            radius: 6
            color: Appearance.colors.colLayer2

            RowLayout {
                id: timeRow
                anchors.centerIn: parent
                spacing: 6

                StyledText {
                    text: root.formatTime(root.vidCurrentPos)
                    font.pixelSize: Appearance.font.pixelSize.smaller
                    font.weight: Font.DemiBold
                    color: Appearance.colors.colPrimary
                    font.family: Appearance.font.family.monospace
                }

                StyledText {
                    text: "/ " + root.formatTime(root.vidDuration)
                    font.pixelSize: Appearance.font.pixelSize.smaller
                    color: Appearance.colors.colSubtext
                    font.family: Appearance.font.family.monospace
                }

                Rectangle { width: 1; height: 14; color: Appearance.colors.colOutlineVariant }

                StyledText {
                    text: "F: " + Math.floor(root.vidCurrentPos * root.fps) + " / " + Math.floor(root.vidDuration * root.fps)
                    font.pixelSize: Appearance.font.pixelSize.smaller
                    color: Appearance.colors.colOnLayer1
                    font.family: Appearance.font.family.monospace
                }
            }
        }

        Item { Layout.fillWidth: true }

        // Mark In button
        Rectangle {
            Layout.preferredWidth: markInRow.implicitWidth + 14
            height: 28; radius: 14
            color: miMa.containsMouse ? Appearance.colors.colPrimaryContainer : Appearance.colors.colLayer2
            RowLayout {
                id: markInRow
                anchors.centerIn: parent
                spacing: 4
                MaterialSymbol { iconSize: 14; text: "arrow_forward"; color: Appearance.colors.colOnLayer1 }
                StyledText {
                    text: "In: " + root.formatTime(root.vidMarkIn)
                    font.pixelSize: Appearance.font.pixelSize.smaller
                    color: Appearance.colors.colOnLayer1
                    font.family: Appearance.font.family.monospace
                }
            }
            MouseArea {
                id: miMa
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.tlMarkIn()
            }
            StyledToolTip { text: "Set Mark In (I)" }
        }

        // Mark Out button
        Rectangle {
            Layout.preferredWidth: markOutRow.implicitWidth + 14
            height: 28; radius: 14
            color: moMa.containsMouse ? Appearance.colors.colPrimaryContainer : Appearance.colors.colLayer2
            RowLayout {
                id: markOutRow
                anchors.centerIn: parent
                spacing: 4
                MaterialSymbol { iconSize: 14; text: "arrow_back"; color: Appearance.colors.colOnLayer1 }
                StyledText {
                    text: "Out: " + root.formatTime(root.vidMarkOut)
                    font.pixelSize: Appearance.font.pixelSize.smaller
                    color: Appearance.colors.colOnLayer1
                    font.family: Appearance.font.family.monospace
                }
            }
            MouseArea {
                id: moMa
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.tlMarkOut()
            }
            StyledToolTip { text: "Set Mark Out (O)" }
        }
    }

    // 3. Annotation Frame & Duration Range Editor (Visible when an annotation is selected)
    Rectangle {
        Layout.fillWidth: true
        height: 38
        radius: Appearance.rounding.small
        color: Appearance.colors.colLayer2
        visible: root.currentAnnotation !== null

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 10
            anchors.rightMargin: 10
            spacing: 8

            // Badge / Icon
            Rectangle {
                width: 24; height: 24; radius: 12
                color: Appearance.colors.colTertiary
                MaterialSymbol {
                    anchors.centerIn: parent
                    iconSize: 14
                    text: {
                        let t = root.currentAnnotation?.tool
                        if (t === "blur") return "blur_on"
                        if (t === "arrow") return "north_east"
                        if (t === "rect") return "rectangle"
                        if (t === "circle") return "circle"
                        if (t === "highlight") return "ink_highlighter"
                        return "draw"
                    }
                    color: Appearance.colors.colOnTertiary
                }
            }

            StyledText {
                text: "Annotation #" + (root.selectedAnnotationIndex + 1) + " (" + (root.currentAnnotation?.tool ?? "") + "):"
                font.pixelSize: Appearance.font.pixelSize.smaller
                font.weight: Font.DemiBold
                color: Appearance.colors.colOnLayer2
            }

            // Start Time control
            RowLayout {
                spacing: 4
                StyledText {
                    text: "Start:"
                    font.pixelSize: Appearance.font.pixelSize.smaller
                    color: Appearance.colors.colSubtext
                }
                Rectangle {
                    height: 24; width: 75; radius: 4
                    color: Appearance.colors.colLayer1
                    StyledText {
                        anchors.centerIn: parent
                        text: (root.currentAnnotation?.startTime ?? 0).toFixed(2) + "s (F:" + (root.currentAnnotation?.startFrame ?? 0) + ")"
                        font.pixelSize: Appearance.font.pixelSize.smaller
                        font.family: Appearance.font.family.monospace
                        color: Appearance.colors.colOnLayer1
                    }
                }
                Rectangle {
                    width: 24; height: 24; radius: 4
                    color: setStartMa.containsMouse ? Appearance.colors.colPrimaryContainer : Appearance.colors.colLayer1
                    MaterialSymbol { anchors.centerIn: parent; iconSize: 14; text: "my_location"; color: Appearance.colors.colPrimary }
                    MouseArea {
                        id: setStartMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (root.currentAnnotation) {
                                root.annotationRangeChanged(root.selectedAnnotationIndex, root.vidCurrentPos, root.currentAnnotation.endTime)
                            }
                        }
                    }
                    StyledToolTip { text: "Set Start to current video time" }
                }
            }

            // End Time control
            RowLayout {
                spacing: 4
                StyledText {
                    text: "End:"
                    font.pixelSize: Appearance.font.pixelSize.smaller
                    color: Appearance.colors.colSubtext
                }
                Rectangle {
                    height: 24; width: 75; radius: 4
                    color: Appearance.colors.colLayer1
                    StyledText {
                        anchors.centerIn: parent
                        text: (root.currentAnnotation?.endTime ?? 0).toFixed(2) + "s (F:" + (root.currentAnnotation?.endFrame ?? 0) + ")"
                        font.pixelSize: Appearance.font.pixelSize.smaller
                        font.family: Appearance.font.family.monospace
                        color: Appearance.colors.colOnLayer1
                    }
                }
                Rectangle {
                    width: 24; height: 24; radius: 4
                    color: setEndMa.containsMouse ? Appearance.colors.colPrimaryContainer : Appearance.colors.colLayer1
                    MaterialSymbol { anchors.centerIn: parent; iconSize: 14; text: "my_location"; color: Appearance.colors.colPrimary }
                    MouseArea {
                        id: setEndMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (root.currentAnnotation) {
                                root.annotationRangeChanged(root.selectedAnnotationIndex, root.currentAnnotation.startTime, root.vidCurrentPos)
                            }
                        }
                    }
                    StyledToolTip { text: "Set End to current video time" }
                }
            }

            // Quick duration presets
            Row {
                spacing: 4
                Repeater {
                    model: [
                        { label: "+1s", sec: 1.0 },
                        { label: "+3s", sec: 3.0 },
                        { label: "+5s", sec: 5.0 },
                        { label: "To End", sec: -1 }
                    ]
                    delegate: Rectangle {
                        required property var modelData
                        height: 22
                        width: presetText.implicitWidth + 10
                        radius: 4
                        color: presetMa.containsMouse ? Appearance.colors.colPrimaryContainer : Appearance.colors.colLayer1

                        StyledText {
                            id: presetText
                            anchors.centerIn: parent
                            text: parent.modelData.label
                            font.pixelSize: Appearance.font.pixelSize.smaller
                            color: Appearance.colors.colOnLayer1
                        }

                        MouseArea {
                            id: presetMa
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (root.currentAnnotation) {
                                    let s = root.currentAnnotation.startTime
                                    let e = (parent.modelData.sec > 0)
                                        ? Math.min(root.vidDuration > 0 ? root.vidDuration : s + 100, s + parent.modelData.sec)
                                        : (root.vidDuration > 0 ? root.vidDuration : s + 10)
                                    root.annotationRangeChanged(root.selectedAnnotationIndex, s, e)
                                }
                            }
                        }
                    }
                }
            }

            Item { Layout.fillWidth: true }

            // Delete annotation button
            Rectangle {
                width: 24; height: 24; radius: 4
                color: delMa.containsMouse ? Appearance.colors.colErrorContainer : "transparent"
                MaterialSymbol {
                    anchors.centerIn: parent
                    iconSize: 16
                    text: "delete"
                    color: delMa.containsMouse ? Appearance.colors.colOnErrorContainer : Appearance.colors.colSubtext
                }
                MouseArea {
                    id: delMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.annotationDeleted(root.selectedAnnotationIndex)
                }
                StyledToolTip { text: "Delete annotation" }
            }

            // Deselect button
            Rectangle {
                width: 24; height: 24; radius: 4
                color: closeSelMa.containsMouse ? Appearance.colors.colLayer1 : "transparent"
                MaterialSymbol { anchors.centerIn: parent; iconSize: 16; text: "close"; color: Appearance.colors.colSubtext }
                MouseArea {
                    id: closeSelMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: { root.selectedAnnotationIndex = -1 }
                }
                StyledToolTip { text: "Deselect" }
            }
        }
    }
}

