import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Qt5Compat.GraphicalEffects
import qs
import qs.services
import qs.modules.common
import qs.modules.ii.settings.pages
import qs.modules.common.widgets
import qs.modules.common.functions as CF

Item {
    id: root
    property real contentPadding: 8
    property int currentPage: 0
    property bool showingProfile: false
    property bool showingSearch: false
    // Flat {pageName, pageIcon, sectionTitle, settingLabels, haystack} list,
    // one entry per
    // ContentSection/ContentSubsection across every settings page - built
    // once (all pages are already eagerly loaded shortly after Settings
    // opens, see Component.onCompleted below) rather than re-walking every
    // page's whole item tree on each keystroke. SettingsSearch.qml matches
    // against `haystack` (the section's own title plus every descendant
    // ConfigRow/ConfigSwitch/etc. `text` under it) so a hit on any
    // individual setting's label still surfaces its containing section -
    // navigation always lands on a real section title, which is exactly
    // what every page's own goTo(term) already knows how to scroll to.
    property var searchIndex: []

    // Rebuilt (not cached-once) every time search opens rather than gated
    // behind a one-shot "already built" flag: pages load asynchronously
    // (see pageLoader.asynchronous below), so a search opened in the brief
    // window before a heavier page like HyprlandSettings.qml finishes loading
    // would otherwise permanently miss everything in it for the rest of the
    // session. Opening search isn't a hot path, so re-walking on every open
    // (never on keystrokes - SettingsSearch.qml only re-filters the cached
    // list it's handed) is the safe trade to make here.
    function buildSearchIndex() {
        const index = []
        function collectSearchData(sectionItem) {
            let parts = [sectionItem.title ?? ""]
            let settingLabels = []
            function append(value, includeAsSetting) {
                if (typeof value !== "string" || value.length === 0) return
                parts.push(value)
                if (includeAsSetting && !settingLabels.includes(value)) settingLabels.push(value)
            }
            function walk(it) {
                if (!it || !it.children) return
                for (let i = 0; i < it.children.length; i++) {
                    const child = it.children[i]
                    if (child !== sectionItem) {
                        // Config controls expose their user-facing name as
                        // `text`; nested groups use `title`. Retain both so a
                        // result can show the exact matching option below its
                        // parent section.
                        append(child.text, true)
                        append(child.title, true)
                    }
                    walk(child)
                }
            }
            walk(sectionItem)
            return { haystack: parts.join(" • "), settingLabels: settingLabels }
        }
        function walkForSections(item, pageName, pageIcon) {
            if (!item || !item.children) return
            for (let i = 0; i < item.children.length; i++) {
                const child = item.children[i]
                if (typeof child.title === "string" && child.title.length > 0) {
                    const searchData = collectSearchData(child)
                    index.push({
                        pageName: pageName,
                        pageIcon: pageIcon,
                        sectionTitle: child.title,
                        settingLabels: searchData.settingLabels,
                        haystack: searchData.haystack
                    })
                }
                walkForSections(child, pageName, pageIcon)
            }
        }
        for (let i = 0; i < root.pages.length; i++) {
            const loader = pagesRepeater.itemAt(i)
            if (loader && loader.item) walkForSections(loader.item, root.pages[i].name, root.pages[i].icon)
        }
        root.searchIndex = index
    }

    function navigateToSearchResult(entry) {
        root.showingSearch = false
        GlobalStates.settingsPage = entry.pageName + ":" + entry.sectionTitle
    }

    onShowingSearchChanged: {
        if (showingSearch) Qt.callLater(root.buildSearchIndex)
    }
    property bool isMinimal: Config.options.settings.style === "minimal"
    // Remembers the active page by name so that if the pages list itself
    // changes shape while it's open (e.g. a conditionally-shown tab
    // disappearing because its feature just got turned off from within that
    // very page), currentPage can be re-pointed at whatever the same logical page's new
    // index is instead of landing on whichever unrelated page shifted into
    // the old numeric slot.
    property string _currentPageName: ""

    onPagesChanged: {
        if (root._currentPageName === "") return
        const idx = root.pages.findIndex(p => p.name === root._currentPageName)
        if (idx >= 0) {
            root.currentPage = idx
        } else if (root.currentPage >= root.pages.length) {
            // The active page itself vanished (e.g. a conditional tab got hidden
            // while open) — fall back to a page that always exists.
            const fallback = root.pages.findIndex(p => p.name === Translation.tr("Interface"))
            root.currentPage = fallback >= 0 ? fallback : 0
        }
    }

    Connections {
        target: GlobalStates
        function onSettingsPageChanged() {
            if (GlobalStates.settingsPage === "") return
            
            let parts = GlobalStates.settingsPage.split(":");
            let pageName = parts[0];
            let searchTerm = parts.length > 1 ? parts[1] : "";

            const idx = root.pages.findIndex(p => p.name.toLowerCase() === pageName.toLowerCase());
            
            if (idx >= 0) {
                root.currentPage = idx;
                root.showingProfile = false;
                
                if (searchTerm !== "") {
                    let loader = pagesRepeater.itemAt(idx);
                    if (loader && loader.item && typeof loader.item.goTo === "function") {
                        loader.item.goTo(searchTerm);
                    } else if (loader) {
                        loader.onLoaded.connect(function() {
                            if (loader.item && typeof loader.item.goTo === "function") {
                                loader.item.goTo(searchTerm);
                            }
                        });
                    }
                }
            }
            GlobalStates.settingsPage = "";
        }
    }

    onCurrentPageChanged: {
        const pageName = root.pages[currentPage]?.name ?? ""
        root._currentPageName = pageName
        if (pageName === Translation.tr("About")) {
            if (SystemInfo.cpu === "") SystemInfo.refresh()
            Updates.refresh()
        }
    }
    
    property var pages: {
        let list = [
            { name: Translation.tr("Quick"),      icon: "instant_mix",    component: Qt.resolvedUrl("pages/QuickConfig.qml") },
            { name: Translation.tr("General"),    icon: "browse",         component: Qt.resolvedUrl("pages/GeneralConfig.qml") },
            { name: Translation.tr("Bar"),        icon: "toast",          iconRotation: 180, component: Qt.resolvedUrl("pages/BarConfig.qml") },
            { name: Translation.tr("Desktop"),    icon: "texture",        component: Qt.resolvedUrl("pages/BackgroundConfig.qml") },
            { name: Translation.tr("Interface"),  icon: "bottom_app_bar", component: Qt.resolvedUrl("pages/InterfaceConfig.qml") },
            { name: Translation.tr("Experience"), icon: "tune",           component: Qt.resolvedUrl("pages/ExperienceConfig.qml") },
            { name: Translation.tr("Services"),   icon: "settings",       component: Qt.resolvedUrl("pages/ServicesConfig.qml") },
        ]
        if (WM.compositor === "hyprland") {
                    list.push({ name: Translation.tr("Hyprland"), icon: "select_window_2", component: Qt.resolvedUrl("pages/HyprlandSettings.qml") })
                    list.push({ name: Translation.tr("Keybinds"), icon: "keyboard", component: Qt.resolvedUrl("pages/KeybindsConfig.qml") })
                }
        if (WM.compositor === "niri") {
                    list.push({ name: Translation.tr("Niri"), icon: "select_window_2", component: Qt.resolvedUrl("pages/NiriSettings.qml") })
                }
        list.push({ name: Translation.tr("About"), icon: "info", component: Qt.resolvedUrl("pages/About.qml") })
        return list
    }

    Component.onCompleted: {
        Config.readWriteDelay = 0
        Qt.callLater(() => {
            for (let i = 0; i < root.pages.length; i++) {
                let loader = pagesRepeater.itemAt(i)
                if (loader) loader.active = true
            }
            if (profileLoader) profileLoader.active = true
        })
    }

    ColumnLayout {
        anchors {
            fill: parent
            margins: contentPadding
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: contentPadding

            Rectangle {
                id: navRailWrapper
                Layout.fillHeight: true
                Layout.margins: 0
                implicitWidth: navRail.expanded ? 195 : fab.baseSize
                color: isMinimal ? "transparent" : Appearance.m3colors.m3surfaceContainerLow
                radius: Appearance.rounding.normal

                Behavior on implicitWidth {
                    animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                }

                NavigationRail {
                    id: navRail
                    anchors { left: parent.left; top: parent.top; bottom: parent.bottom; leftMargin: 20 }
                    spacing: 10
                    expanded: root.width > 900

                    Item {
                        id: profileHeader
                        Layout.fillWidth: true
                        Layout.margins: isMinimal ? 0 : 5
                        Layout.topMargin: 15
                        Layout.bottomMargin: isMinimal ? -30 : 0
                        implicitHeight: profileRow.implicitHeight

                        RowLayout {
                            id: profileRow
                            anchors.fill: parent
                            visible: true
                            spacing: 10

                        Rectangle {
                            id: avatarRect
                            width: 48
                            height: 48
                            radius: width / 2
                            color: Appearance.colors.colPrimaryContainer

                            Image {
                                id: avatarImage
                                // Decode off the UI thread - a synchronous load of an arbitrarily
                                // large user/theme image stalls the whole shell (one QML thread).
                                asynchronous: true
                                anchors.fill: parent
                                source: Config.options.profile.avatarPath !== "" 
                                    ? "file://" + Config.options.profile.avatarPicture 
                                    : "file:///home/" + (Quickshell.env("USER") ?? "user") + "/.face"
                                sourceSize.width: avatarImage.width * 2
                                sourceSize.height: avatarImage.height * 2
                                fillMode: Image.PreserveAspectCrop
                                layer.enabled: true
                                layer.effect: OpacityMask {
                                    maskSource: Rectangle {
                                        width: avatarRect.width
                                        height: avatarRect.height
                                        radius: avatarRect.radius
                                    }
                                }
                                onStatusChanged: {
                                    if (status === Image.Error)
                                        visible = false
                                }
                            }

                            MaterialSymbol {
                                anchors.centerIn: parent
                                text: "account_circle"
                                iconSize: 32
                                color: Appearance.colors.colOnPrimaryContainer
                                visible: avatarImage.status === Image.Error
                            }
                        }

                        ColumnLayout {
                            spacing: 2
                            Layout.fillWidth: true
                            visible: !isMinimal

                            StyledText {
                                text: Config.options.profile.displayName === "" ? SystemInfo.username : Config.options.profile.displayName
                                font.pixelSize: Appearance.font.pixelSize.normal
                                color: Appearance.colors.colOnLayer1
                                font.weight: Font.Medium
                                elide: Text.ElideRight
                                Layout.maximumWidth: 100
                            }

                            StyledText {
                                id: distroText
                                font.pixelSize: Appearance.font.pixelSize.smaller
                                color: Appearance.colors.colSubtext
                                elide: Text.ElideRight
                                Layout.maximumWidth: 100

                                text: {
                                    const d = Config.options.profile.descriptionText
                                    if (d === "::uptime::") return Translation.tr("Up • %1").arg(DateTime.uptime)
                                    return SystemInfo.distroName
                                }
                            }
                        }

                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.showingProfile = !root.showingProfile
                        }
                    }

                    Rectangle {
                        Layout.preferredWidth: isMinimal ? 50 : 160
                        Layout.topMargin: isMinimal ? 30 : -5
                        Layout.bottomMargin: isMinimal ? -30 : 0
                        height: 2
                        gradient: Gradient {
                            orientation: Gradient.Horizontal
                            GradientStop { position: 0.0; color: "transparent" }
                            GradientStop { position: 0.2; color: Appearance.colors.colOutline }
                            GradientStop { position: 0.8; color: Appearance.colors.colOutline }
                            GradientStop { position: 1.0; color: "transparent" }
                        }
                        opacity: 0.15
                    }

                    // Both FABs sit on one row as plain icon buttons. They
                    // used to be two full-width pills stacked vertically,
                    // which is a lot of rail height for two actions whose
                    // icons (edit / search) already say what they do - the
                    // labels move into the tooltips instead.
                    GridLayout {
                        // Side by side while the rail is expanded; stacked when
                        // it collapses to a single icon column (its width is
                        // one FAB wide - see navRailWrapper.implicitWidth).
                        columns: navRail.expanded ? 2 : 1
                        Layout.alignment: Qt.AlignHCenter
                        Layout.bottomMargin: -25
                        visible: !isMinimal
                        rowSpacing: 8
                        columnSpacing: 8

                        FloatingActionButton {
                            id: fab
                            property bool justCopied: false
                            iconText: justCopied ? "check" : "edit"
                            // Icon-only: `expanded` false keeps the pill at
                            // baseSize instead of growing to fit buttonText.
                            expanded: false
                            downAction: () => {
                                Qt.openUrlExternally(`${Directories.config}/horizons/config.json`);
                            }
                            altAction: () => {
                                Quickshell.clipboardText = CF.FileUtils.trimFileProtocol(`${Directories.config}/horizons/config.json`);
                                fab.justCopied = true;
                                revertTextTimer.restart()
                            }
                            Timer {
                                id: revertTextTimer
                                interval: 1500
                                onTriggered: fab.justCopied = false
                            }
                            StyledToolTip {
                                text: fab.justCopied
                                    ? Translation.tr("Path copied")
                                    : Translation.tr("Config file\nOpen the shell config file\nAlternatively right-click to copy path")
                            }
                        }

                        FloatingActionButton {
                            id: searchFab
                            iconText: "search"
                            expanded: false
                            downAction: () => { root.showingSearch = !root.showingSearch }
                            StyledToolTip {
                                text: Translation.tr("Search settings\nSearch every setting (title, description, regex supported)")
                            }
                        }
                    }

                    NavigationRailTabArray {
                        currentIndex: root.currentPage
                        expanded: navRail.expanded
                        colToggled: root.showingProfile ? "transparent" : Appearance.colors.colSecondaryContainer
                        Repeater {
                            model: root.pages
                            NavigationRailButton {
                                required property var index
                                required property var modelData
                                toggled: root.currentPage === index && !root.showingProfile && !root.showingSearch
                                onPressed: {
                                    root.currentPage = index
                                    root.showingProfile = false
                                    root.showingSearch = false
                                }
                                expanded: navRail.expanded
                                buttonIcon: modelData.icon
                                buttonIconRotation: modelData.iconRotation || 0
                                buttonText: modelData.name
                                showToggledHighlight: false
                            }
                        }
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                color: "transparent"
                radius: Appearance.rounding.screenRounding - Appearance.sizes.hyprlandGapsOut

                Item {
                    anchors.fill: parent

                    Repeater {
                        id: pagesRepeater
                        model: root.pages
                        Loader {
                            id: pageLoader
                            required property var modelData
                            required property var index
                            source: modelData.component
                            // Settings pages can be large (HyprlandSettings.qml
                            // especially) - loading one synchronously on first
                            // visit was a real, if brief, main-thread hitch
                            // every time Settings opened onto a heavy page.
                            // Async moves the parse/compile/instantiate off
                            // the UI thread; the opacity fade already covers
                            // the short gap before `item` exists.
                            asynchronous: true

                            active: Config.ready && (root.currentPage === index || item !== null)

                            anchors.fill: parent

                            property bool isActive: root.currentPage === index && !root.showingProfile && !root.showingSearch
                            opacity: isActive ? 1 : 0
                            enabled: isActive
                            visible: isActive
                            anchors.topMargin: isActive ? 0 : 12

                            onLoaded: {
                                if (root.currentPage === index) {
                                    GlobalStates.currentPageInstance = item;
                                }
                            }

                            onIsActiveChanged: {
                                if (isActive && item) {
                                    GlobalStates.currentPageInstance = item;
                                } else if (!isActive && GlobalStates.currentPageInstance === item) {
                                    GlobalStates.currentPageInstance = null;
                                }
                            }

                            Behavior on opacity {
                                NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
                            }
                            Behavior on anchors.topMargin {
                                NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
                            }
                        }
                    }

                    Loader {
                        id: profileLoader
                        active: false
                        anchors.fill: parent
                        source: Qt.resolvedUrl("pages/Profile.qml")
                        asynchronous: true

                        property bool isActive: root.showingProfile && !root.showingSearch
                        opacity: isActive ? 1 : 0
                        enabled: isActive
                        visible: isActive
                        anchors.topMargin: isActive ? 0 : 12

                        onIsActiveChanged: {
                            if (isActive && item) {
                                GlobalStates.currentPageInstance = item;
                            } else if (!isActive && GlobalStates.currentPageInstance === item) {
                                GlobalStates.currentPageInstance = null;
                            }
                        }

                        Behavior on opacity {
                            NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
                        }
                        Behavior on anchors.topMargin {
                            NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
                        }
                    }

                    Loader {
                        id: searchLoader
                        active: root.showingSearch
                        anchors.fill: parent
                        source: Qt.resolvedUrl("pages/SettingsSearch.qml")
                        asynchronous: true

                        property bool isActive: root.showingSearch
                        opacity: isActive ? 1 : 0
                        enabled: isActive
                        visible: isActive
                        anchors.topMargin: isActive ? 0 : 12

                        onLoaded: {
                            if (item) {
                                item.settingsContent = root
                                if (isActive) item.forceFocus()
                            }
                        }
                        onIsActiveChanged: {
                            if (isActive && item) item.forceFocus()
                        }

                        Behavior on opacity {
                            NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
                        }
                        Behavior on anchors.topMargin {
                            NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
                        }
                    }
                }
            }
        }
    }
}
