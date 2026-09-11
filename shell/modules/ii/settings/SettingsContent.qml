import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets

Item {
    id: root
    property real contentPadding: 8
    readonly property bool rightToLeft: /^(ar|he|fa|ur)(_|$)/.test(Translation.languageCode)
    LayoutMirroring.enabled: rightToLeft
    LayoutMirroring.childrenInherit: true
    property int currentPage: Math.max(0, registry.pages.findIndex(page => page.id === registry.canonicalRoute(Config.options.settings.lastPage)))
    property bool showingSearch: false
    property bool showingProfile: false
    readonly property bool isMinimal: Config.options.settings.style === "minimal"
    readonly property var pages: registry.pages
    readonly property var searchIndex: registry.searchIndex
    readonly property var selectedPage: pages[currentPage] ?? pages[0]
    readonly property string route: selectedPage.id
    property var pendingTarget: null
    property string navigationNotice: ""

    SettingsRegistry { id: registry }

    // Preserve the public hooks used by Settings.qml and existing callers.
    onShowingProfileChanged: if (showingProfile) { navigate("personal"); showingProfile = false }
    onCurrentPageChanged: {
        navigationNotice = ""
        Qt.callLater(() => { GlobalStates.currentPageInstance = routedPage })
    }
    function navigate(id, target) {
        const route = registry.canonicalRoute(id)
        const index = pages.findIndex(page => page.id === route)
        if (index < 0) return
        pendingTarget = target ?? null
        currentPage = index
        showingSearch = false
        Config.options.settings.lastPage = route
        Qt.callLater(revealTarget)
        if (route === "about") { SystemInfo.refresh(); Updates.refresh() }
    }
    function stepPage(direction) {
        const index = pages.findIndex(page => page.id === route)
        navigate(pages[(Math.max(0, index) + direction + pages.length) % pages.length].id)
    }
    Shortcut {
        sequence: "Ctrl+F"
        enabled: root.visible
        onActivated: root.showingSearch = true
    }
    function navigateToSearchResult(entry) { navigate(entry.route, entry) }
    function buildSearchIndex() {} // The catalogue exists before any source view loads.
    function findTarget(item, name) {
        if (!item) return null
        if (item.objectName === name) return item
        for (const child of item.children ?? []) {
            const found = findTarget(child, name)
            if (found) return found
        }
        return null
    }
    function revealTarget() {
        if (!pendingTarget?.id) return
        for (let i = 0; i < sourceRepeater.count; ++i) {
            const loader = sourceRepeater.itemAt(i)
            if (loader.modelData !== pendingTarget.source || !loader.item) continue
            const target = findTarget(loader.item, pendingTarget.id)
            if (!target) continue
            if (!target.visible) {
                navigationNotice = Translation.tr("This option is available when its feature or layout is active.")
                pendingTarget = null
                return
            }
            const point = target.mapToItem(routedPage.contentItem, 0, 0)
            routedPage.contentY = Math.max(0, Math.min(point.y - 24, routedPage.contentHeight - routedPage.height))
            focusOutline.targetItem = target
            highlightTimer.restart()
            pendingTarget = null
            return
        }
    }
    Connections {
        target: GlobalStates
        function onSettingsPageChanged() {
            if (!GlobalStates.settingsPage) return
            const target = registry.resolveLegacy(GlobalStates.settingsPage)
            root.navigate(target.route, target)
            GlobalStates.settingsPage = ""
        }
    }
    Component.onCompleted: {
        GlobalStates.currentPageInstance = routedPage
        if (GlobalStates.settingsPage) {
            const target = registry.resolveLegacy(GlobalStates.settingsPage)
            navigate(target.route, target)
            GlobalStates.settingsPage = ""
        }
    }

    RowLayout {
        id: windowHeader
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: 14
        height: 36
        spacing: 10
        MaterialSymbol {
            text: "settings"
            iconSize: 22
            color: Appearance.colors.colPrimary
        }
        StyledText {
            text: Translation.tr("Settings")
            font.pixelSize: Appearance.font.pixelSize.large
            font.weight: Font.Medium
            color: Appearance.colors.colOnLayer0
        }
        Item { Layout.fillWidth: true }
        IconToolbarButton {
            text: "language"
            implicitHeight: 34
            Accessible.name: Translation.tr("Arabic mode")
            toggled: (Config.options.language.ui ?? "auto").indexOf("ar") === 0
            onClicked: {
                const current = Config.options.language.ui ?? "auto";
                if (current.indexOf("ar") === 0) {
                    const prev = Config.options.settings.prevLanguage ?? "auto";
                    Config.options.language.ui = (prev.indexOf("ar") === 0) ? "auto" : prev;
                } else {
                    Config.options.settings.prevLanguage = current;
                    Config.options.language.ui = "ar_EG";
                }
                Config.requestWrite()
            }
            StyledToolTip { text: Translation.tr("Arabic mode") }
        }
        IconToolbarButton {
            text: "close"
            implicitHeight: 34
            Accessible.name: Translation.tr("Close settings")
            onClicked: GlobalStates.settingsOpen = false
            StyledToolTip { text: Translation.tr("Close settings") }
        }
    }
    RowLayout {
        anchors.top: windowHeader.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: root.contentPadding
        spacing: 14
        Rectangle {
            Layout.fillHeight: true
            Layout.preferredWidth: root.width < 780 ? 174 : 208
            color: Appearance.colors.colLayer1
            radius: Appearance.rounding.large
            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 10
                spacing: 8
                RippleButtonWithIcon {
                    Layout.fillWidth: true
                    materialIcon: "search"
                    mainText: Translation.tr("Search settings")
                    onClicked: root.showingSearch = !root.showingSearch
                }
                ScrollView {
                    id: navigationScroll
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    contentWidth: availableWidth
                    ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
                    ColumnLayout {
                        id: navigationColumn
                        width: navigationScroll.availableWidth
                        spacing: 3
                        StyledText {
                            Layout.fillWidth: true
                            text: Translation.tr("Sections")
                            font.pixelSize: Appearance.font.pixelSize.small
                            Layout.leftMargin: 10
                            Layout.topMargin: 6
                            Layout.bottomMargin: 4
                            wrapMode: Text.WordWrap
                            color: Appearance.colors.colSubtext
                        }
                        Repeater {
                            model: registry.pages.filter(page => page.id !== "about")
                            delegate: SettingsNavigationButton {
                                required property var modelData
                                objectName: "settings-nav-" + modelData.id
                                text: modelData.name
                                iconName: modelData.icon
                                selected: root.route === modelData.id && !root.showingSearch
                                onClicked: root.navigate(modelData.id)
                            }
                        }
                        SettingsNavigationButton {
                            text: registry.pageFor("about").name
                            iconName: "info"
                            selected: root.route === "about" && !root.showingSearch
                            onClicked: root.navigate("about")
                        }
                    }
                }
            }
        }
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            ColumnLayout {
                anchors.fill: parent
                visible: !root.showingSearch
                spacing: 8
                StyledText {
                    Layout.fillWidth: true
                    text: root.selectedPage.name
                    Layout.topMargin: 12
                    Layout.leftMargin: 12
                    Layout.rightMargin: 12
                    Layout.bottomMargin: 2
                    font.weight: Font.Medium
                    font.pixelSize: Appearance.font.pixelSize.larger
                    wrapMode: Text.WordWrap
                }
                StyledText {
                    Layout.fillWidth: true
                    visible: root.navigationNotice !== ""
                    text: root.navigationNotice
                    wrapMode: Text.WordWrap
                }
                ContentPage {
                    id: routedPage
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    forceWidth: true
                    // Source views are loaded once, on demand, and retained so
                    // routing never discards a Lua/JSON editor's draft.
                    Repeater {
                        id: sourceRepeater
                        model: registry.sources
                        delegate: Loader {
                            id: sourceLoader
                            objectName: "settings-source-" + modelData
                            required property string modelData
                            readonly property bool contributes: registry.contributes(modelData, root.route)
                            property bool requested: false
                            Layout.fillWidth: true
                            Layout.preferredHeight: visible && item ? item.contentHeight : 0
                            visible: contributes && status === Loader.Ready
                            active: Config.ready && requested
                            asynchronous: true
                            function requestIfNeeded() {
                                if (!contributes || requested || !Config.ready) return
                                requested = true
                                setSource(Qt.resolvedUrl("pages/" + modelData + ".qml"), {
                                    embedded: true,
                                    settingsRoute: Qt.binding(() => root.route),
                                    settingsRouteAliases: Qt.binding(() => registry.aliasesFor(root.route)),
                                    bottomContentPadding: 0,
                                    sidePadding: 0,
                                })
                            }
                            onContributesChanged: requestIfNeeded()
                            Component.onCompleted: requestIfNeeded()
                            Connections {
                                target: Config
                                function onReadyChanged() { sourceLoader.requestIfNeeded() }
                            }
                            onLoaded: Qt.callLater(() => Qt.callLater(root.revealTarget))
                        }
                    }
                    RippleButtonWithIcon {
                        Layout.fillWidth: true
                        visible: root.route === "personal"
                        materialIcon: "code"
                        mainText: Translation.tr("Open shell configuration file")
                        onClicked: Qt.openUrlExternally(Directories.config + "/horizons/config.json")
                    }
                    RippleButtonWithIcon {
                        Layout.fillWidth: true
                        visible: root.route === "session"
                        materialIcon: "widgets"
                        mainText: Translation.tr("Choose lock screen widgets")
                        onClicked: root.navigate("widgets")
                    }
                }
            }
            Loader {
                anchors.fill: parent
                active: root.showingSearch
                visible: active
                source: Qt.resolvedUrl("pages/SettingsSearch.qml")
                onLoaded: { item.settingsContent = root; item.forceFocus() }
            }
        }
    }
    Rectangle {
        id: focusOutline
        property Item targetItem: null
        parent: routedPage.contentItem
        visible: targetItem !== null && highlightTimer.running
        x: targetItem ? targetItem.mapToItem(parent, 0, 0).x - 3 : 0
        y: targetItem ? targetItem.mapToItem(parent, 0, 0).y - 3 : 0
        width: targetItem ? targetItem.width + 6 : 0
        height: targetItem ? targetItem.height + 6 : 0
        color: "transparent"
        border.color: Appearance.colors.colPrimary
        border.width: 2
        radius: Appearance.rounding.small
        z: 100
    }
    Timer { id: highlightTimer; interval: 2200; onTriggered: focusOutline.targetItem = null }
}
