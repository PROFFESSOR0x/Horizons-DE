pragma ComponentBehavior: Bound

import Qt.labs.synchronizer
import Qt5Compat.GraphicalEffects
import QtQuick
import QtQuick.Layouts
import Quickshell

import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions

Item { // Wrapper
    id: root

    readonly property string xdgConfigHome: Directories.config
    readonly property int typingDebounceInterval: 200
    readonly property int typingResultLimit: 15

    property string launcherPosition: "top" // top | bottom | center
    property string searchingText: LauncherSearch.query
    property bool showResults: searchingText != ""
    readonly property real searchBarHeight: searchBar.implicitHeight + searchBar.verticalPadding * 2
    implicitWidth: searchWidgetContent.implicitWidth + Appearance.sizes.elevationMargin * 2
    implicitHeight: searchWidgetContent.implicitHeight + searchBar.verticalPadding * 2 + Appearance.sizes.elevationMargin * 2
    opacity: GlobalStates.overviewOpen ? 1 : 0
    scale: GlobalStates.overviewOpen ? 1 : 0.96
    Behavior on opacity { NumberAnimation { duration: GlobalStates.overviewOpen ? 320 : 180; easing.type: Easing.BezierSpline; easing.bezierCurve: GlobalStates.overviewOpen ? Appearance.animationCurves.emphasizedDecel : Appearance.animationCurves.emphasizedAccel } }
    Behavior on scale { NumberAnimation { duration: GlobalStates.overviewOpen ? 380 : 200; easing.type: Easing.BezierSpline; easing.bezierCurve: GlobalStates.overviewOpen ? Appearance.animationCurves.emphasizedDecel : Appearance.animationCurves.emphasizedAccel } }

    function focusFirstItem() {
        if (root.launcherPosition === "bottom") {
            if (appResultsBottom.count > 0) appResultsBottom.currentIndex = 0
        } else {
            if (appResultsTop.count > 0) appResultsTop.currentIndex = 0
        }
    }

    function focusSearchInput() {
        searchBar.forceFocus();
    }

    function disableExpandAnimation() {
        searchBar.animateWidth = false;
    }

    function cancelSearch() {
        searchBar.searchInput.text = ""; 
        LauncherSearch.query = "";
        searchBar.animateWidth = true;
    }

    function setSearchingText(text) {
        searchBar.searchInput.text = text;
        LauncherSearch.query = text;
    }

    Keys.onPressed: event => {
        if (event.key === Qt.Key_Escape)
            return;
        if (event.key === Qt.Key_Backspace) {
            if (!searchBar.searchInput.activeFocus) {
                root.focusSearchInput();
                if (event.modifiers & Qt.ControlModifier) {
                    let text = searchBar.searchInput.text;
                    let pos = searchBar.searchInput.cursorPosition;
                    if (pos > 0) {
                        let left = text.slice(0, pos);
                        let match = left.match(/(\s*\S+)\s*$/);
                        let deleteLen = match ? match[0].length : 1;
                        searchBar.searchInput.text = text.slice(0, pos - deleteLen) + text.slice(pos);
                        searchBar.searchInput.cursorPosition = pos - deleteLen;
                    }
                } else {
                    if (searchBar.searchInput.cursorPosition > 0) {
                        searchBar.searchInput.text = searchBar.searchInput.text.slice(0, searchBar.searchInput.cursorPosition - 1) + searchBar.searchInput.text.slice(searchBar.searchInput.cursorPosition);
                        searchBar.searchInput.cursorPosition -= 1;
                    }
                }
                searchBar.searchInput.cursorPosition = searchBar.searchInput.text.length;
                event.accepted = true;
            }
            return;
        }
        if (event.text && event.text.length === 1 && event.key !== Qt.Key_Enter && event.key !== Qt.Key_Return && event.key !== Qt.Key_Delete && event.text.charCodeAt(0) >= 0x20)
        {
            if (!searchBar.searchInput.activeFocus) {
                root.focusSearchInput();
                searchBar.searchInput.text = searchBar.searchInput.text.slice(0, searchBar.searchInput.cursorPosition) + event.text + searchBar.searchInput.text.slice(searchBar.searchInput.cursorPosition);
                searchBar.searchInput.cursorPosition += 1;
                event.accepted = true;
                root.focusFirstItem();
            }
        }
    }

    StyledRectangularShadow {
        target: searchWidgetContent
    }
    Rectangle { // Background
        id: searchWidgetContent
        anchors {
            top: parent.top
            horizontalCenter: parent.horizontalCenter
            topMargin: Appearance.sizes.elevationMargin
        }
        clip: true
        implicitWidth: columnLayout.implicitWidth
        implicitHeight: columnLayout.implicitHeight
        radius: searchBar.height / 2 + searchBar.verticalPadding
        color: Appearance.colors.colBackgroundSurfaceContainer

        Behavior on implicitHeight {
            id: searchHeightBehavior
            enabled: GlobalStates.overviewOpen && root.showResults
            animation: Appearance.animation.elementMove.numberAnimation.createObject(this)
        }

        ColumnLayout {
            id: columnLayout
            anchors {
                top: parent.top
                horizontalCenter: parent.horizontalCenter
            }
            spacing: 0

            layer.enabled: true
            layer.effect: OpacityMask {
                maskSource: Rectangle {
                    width: searchWidgetContent.width
                    height: searchWidgetContent.width
                    radius: searchWidgetContent.radius
                }
            }

            // Bottom: results above search
            ListView {
                id: appResultsBottom
                visible: root.launcherPosition === "bottom" && root.showResults
                Layout.fillWidth: true
                implicitHeight: visible ? Math.min(600, contentHeight + topMargin + bottomMargin) : 0
                clip: true
                topMargin: 10
                bottomMargin: 10
                spacing: 2
                KeyNavigation.up: searchBar
                highlightMoveDuration: 100
                opacity: visible ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: 220; easing.type: Easing.BezierSpline; easing.bezierCurve: Appearance.animationCurves.emphasizedDecel } }
                onFocusChanged: { if (focus) currentIndex = 1; }
                Connections { target: root; function onSearchingTextChanged() { if (appResultsBottom.count > 0) appResultsBottom.currentIndex = 0; } }
                Timer { id: debounceBottom; interval: root.typingDebounceInterval; onTriggered: resultModelBottom.values = LauncherSearch.results ?? []; }
                Connections { target: LauncherSearch; function onResultsChanged() { resultModelBottom.values = LauncherSearch.results.slice(0, root.typingResultLimit); if (root.launcherPosition === "bottom") root.focusFirstItem(); debounceBottom.restart(); } }
                model: ScriptModel { id: resultModelBottom; objectProp: "key" }
                delegate: SearchItem {
                    required property var modelData
                    anchors.left: parent?.left
                    anchors.right: parent?.right
                    entry: modelData
                    query: StringUtils.cleanOnePrefix(root.searchingText, [Config.options.search.prefix.action, Config.options.search.prefix.app, Config.options.search.prefix.clipboard, Config.options.search.prefix.emojis, Config.options.search.prefix.symbols, Config.options.search.prefix.math, Config.options.search.prefix.shellCommand, Config.options.search.prefix.webSearch])
                    Keys.onPressed: event => {
                        if (event.key === Qt.Key_Tab) {
                            if (LauncherSearch.results.length === 0) return;
                            const tabbedText = modelData.name;
                            LauncherSearch.query = tabbedText;
                            searchBar.searchInput.text = tabbedText;
                            event.accepted = true;
                            root.focusSearchInput();
                        }
                    }
                }
            }
            Rectangle {
                visible: root.launcherPosition === "bottom" && root.showResults
                Layout.fillWidth: true
                height: 1
                color: Appearance.colors.colOutlineVariant
            }
            SearchBar {
                id: searchBar
                property real verticalPadding: 4
                Layout.fillWidth: true
                Layout.leftMargin: 10
                Layout.rightMargin: 4
                Layout.topMargin: verticalPadding
                Layout.bottomMargin: verticalPadding
                Synchronizer on searchingText { property alias source: root.searchingText }
            }
            Rectangle {
                visible: root.launcherPosition !== "bottom" && root.showResults
                Layout.fillWidth: true
                height: 1
                color: Appearance.colors.colOutlineVariant
            }
            ListView {
                id: appResultsTop
                visible: root.launcherPosition !== "bottom" && root.showResults
                Layout.fillWidth: true
                implicitHeight: visible ? Math.min(600, contentHeight + topMargin + bottomMargin) : 0
                clip: true
                topMargin: 10
                bottomMargin: 10
                spacing: 2
                KeyNavigation.up: searchBar
                highlightMoveDuration: 100
                opacity: visible ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: 220; easing.type: Easing.BezierSpline; easing.bezierCurve: Appearance.animationCurves.emphasizedDecel } }
                onFocusChanged: { if (focus) currentIndex = 1; }
                Connections { target: root; function onSearchingTextChanged() { if (appResultsTop.count > 0) appResultsTop.currentIndex = 0; } }
                Timer { id: debounceTop; interval: root.typingDebounceInterval; onTriggered: resultModelTop.values = LauncherSearch.results ?? []; }
                Connections { target: LauncherSearch; function onResultsChanged() { resultModelTop.values = LauncherSearch.results.slice(0, root.typingResultLimit); if (root.launcherPosition !== "bottom") root.focusFirstItem(); debounceTop.restart(); } }
                model: ScriptModel { id: resultModelTop; objectProp: "key" }
                delegate: SearchItem {
                    required property var modelData
                    anchors.left: parent?.left
                    anchors.right: parent?.right
                    entry: modelData
                    query: StringUtils.cleanOnePrefix(root.searchingText, [Config.options.search.prefix.action, Config.options.search.prefix.app, Config.options.search.prefix.clipboard, Config.options.search.prefix.emojis, Config.options.search.prefix.symbols, Config.options.search.prefix.math, Config.options.search.prefix.shellCommand, Config.options.search.prefix.webSearch])
                    Keys.onPressed: event => {
                        if (event.key === Qt.Key_Tab) {
                            if (LauncherSearch.results.length === 0) return;
                            const tabbedText = modelData.name;
                            LauncherSearch.query = tabbedText;
                            searchBar.searchInput.text = tabbedText;
                            event.accepted = true;
                            root.focusSearchInput();
                        }
                    }
                }
            }
        }
    }
}
