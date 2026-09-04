pragma Singleton

import qs.services
import qs.modules.common
import qs.modules.common.models
import qs.modules.common.functions
import QtQuick
import Qt.labs.folderlistmodel
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import ".."

Singleton {
    id: root

    property string query: ""

    function ensurePrefix(prefix) {
        if ([Config.options.search.prefix.action, Config.options.search.prefix.app, Config.options.search.prefix.clipboard, Config.options.search.prefix.emojis, Config.options.search.prefix.symbols, Config.options.search.prefix.math, Config.options.search.prefix.shellCommand, Config.options.search.prefix.webSearch,].some(i => root.query.startsWith(i))) {
            root.query = prefix + root.query.slice(1);
        } else {
            root.query = prefix + root.query;
        }
    }
    
    Process {
        id: keywordHarvester
        property var pendingPages: []
        property string currentPageName: ""
        
        function startHarvesting() {
            root.settingsKeywordsCache = {}; 
            pendingPages = root.settingsIndex.slice();
            next();
        }

        function next() {
            if (pendingPages.length === 0) {
                return;
            }
            
            let currentPage = pendingPages.shift();
            let fullPath = FileUtils.trimFileProtocol(
                Quickshell.shellPath("modules/ii/settings/pages/" + currentPage.path)
            )

            let rawCommand = "grep -oP \"title:\\s*Translation.tr\\(['\\\"].*?['\\\"]\\)\" " + fullPath + " | sed -E \"s/title:\\s*Translation.tr\\(['\\\"](.*)['\\\"]\\)/\\1/g\" | tr '\\n' ' '";
            
            command = ["bash", "-c", rawCommand];
            
            keywordHarvester.currentPageName = currentPage.page;
            running = true;
        }

        onExited: (exitCode, exitStatus) => {
            keywordHarvester.next();
        }

        stdout: SplitParser {
            onRead: data => {
                let cache = root.settingsKeywordsCache;
                cache[keywordHarvester.currentPageName] = (cache[keywordHarvester.currentPageName] || "") + " " + data;
                root.settingsKeywordsCache = cache;
            }
        }
    }

    Component.onCompleted: {
        keywordHarvester.startHarvesting();
        root._refreshSystemServiceUnits();
    }


    // https://specifications.freedesktop.org/menu/latest/category-registry.html
    property list<string> mainRegisteredCategories: ["AudioVideo", "Development", "Education", "Game", "Graphics", "Network", "Office", "Science", "Settings", "System", "Utility"]
    property list<string> appCategories: DesktopEntries.applications.values.reduce((acc, entry) => {
        for (const category of entry.categories) {
            if (!acc.includes(category) && mainRegisteredCategories.includes(category)) {
                acc.push(category);
            }
        }
        return acc;
    }, []).sort()

    property var settingsKeywordsCache: ({})

    property var settingsIndex: [
        { page: "General",   path: "GeneralConfig.qml" },
        { page: "Bar",       path: "BarConfig.qml" },
        { page: "Desktop",   path: "BackgroundConfig.qml" },
        { page: "Interface", path: "InterfaceConfig.qml" },
        { page: "Services",  path: "ServicesConfig.qml" },
        { page: "Hyprland",  path: "HyprlandConfig.qml" },
        { page: "About",     path: "About.qml" },
        { page: "Quick",     path: "QuickConfig.qml" },
    ]

    // Load user action scripts from ~/.config/horizons/actions/
    // Uses FolderListModel to auto-reload when scripts are added/removed
    property var userActionScripts: {
        const actions = [];
        for (let i = 0; i < userActionsFolder.count; i++) {
            const fileName = userActionsFolder.get(i, "fileName");
            const filePath = userActionsFolder.get(i, "filePath");
            if (fileName && filePath) {
                const actionName = fileName.replace(/\.[^/.]+$/, ""); // strip extension
                actions.push({
                    action: actionName,
                    execute: ((path) => (args) => {
                        Quickshell.execDetached([path, ...(args ? args.split(" ") : [])]);
                    })(FileUtils.trimFileProtocol(filePath.toString()))
                });
            }
        }
        return actions;
    }

    FolderListModel {
        id: userActionsFolder
        folder: Qt.resolvedUrl(Directories.userActions)
        showDirs: false
        showHidden: false
        sortField: FolderListModel.Name
    }

    property var searchActions: [
        {
            action: "accentcolor",
            execute: args => {
                Quickshell.execDetached([Directories.wallpaperSwitchScriptPath, "--noswitch", "--color", ...(args != '' ? [`${args}`] : [])]);
            }
        },
        {
            action: "dark",
            execute: () => {
                Quickshell.execDetached([Directories.wallpaperSwitchScriptPath, "--mode", "dark", "--noswitch"]);
            }
        },
        {
            action: "konachanwallpaper",
            execute: () => {
                Quickshell.execDetached([Quickshell.shellPath("scripts/colors/random/random_konachan_wall.sh")]);
            }
        },
        {
            action: "light",
            execute: () => {
                Quickshell.execDetached([Directories.wallpaperSwitchScriptPath, "--mode", "light", "--noswitch"]);
            }
        },
        {
            action: "superpaste",
            execute: args => {
                if (!/^(\d+)/.test(args.trim())) {
                    // Invalid if doesn't start with numbers
                    Quickshell.execDetached(["notify-send", Translation.tr("Superpaste"), Translation.tr("Usage: <tt>%1superpaste NUM_OF_ENTRIES[i]</tt>\nSupply <tt>i</tt> when you want images\nExamples:\n<tt>%1superpaste 4i</tt> for the last 4 images\n<tt>%1superpaste 7</tt> for the last 7 entries").arg(Config.options.search.prefix.action), "-a", "Shell"]);
                    return;
                }
                const syntaxMatch = /^(?:(\d+)(i)?)/.exec(args.trim());
                const count = syntaxMatch[1] ? parseInt(syntaxMatch[1]) : 1;
                const isImage = !!syntaxMatch[2];
                Cliphist.superpaste(count, isImage);
            }
        },
        {
            action: "todo",
            execute: args => {
                Todo.addTask(args);
            }
        },
        {
            action: "wallpaper",
            execute: () => {
                Hyprland.dispatch("global quickshell:wallpaperSelectorToggle")
            }
        },
        {
            action: "wipeclipboard",
            execute: () => {
                Quickshell.execDetached(["bash", "-c", "rm -f ~/.cache/cliphist/db"]);
            }
        },
        {
            action: "unsplash",
            execute: args => {
                if (!args || args.trim().length === 0) {
                    Quickshell.execDetached(["notify-send", "Unsplash", Translation.tr("Usage: /unsplash YOUR_API_KEY"), "-a", "Shell"]);
                    return;
                }
                KeyringStorage.setNestedField(["apiKeys", "unsplash"], args.trim());
                Quickshell.execDetached(["notify-send", "Unsplash", Translation.tr("API key saved!"), "-a", "Shell"]);
            }
        },
        {
            action: "wallhaven",
            execute: args => {
                if (!args || args.trim().length === 0) {
                    Quickshell.execDetached(["notify-send", "Wallhaven", Translation.tr("Usage: /wallhaven YOUR_API_KEY"), "-a", "Shell"]);
                    return;
                }
                KeyringStorage.setNestedField(["apiKeys", "wallhaven"], args.trim());
                Quickshell.execDetached(["notify-send", "Wallhaven", Translation.tr("API key saved!"), "-a", "Shell"]);
            }
        },
        {
            action: "pexels",
            execute: args => {
                if (!args || args.trim().length === 0) {
                    Quickshell.execDetached(["notify-send", "Pexels", Translation.tr("Usage: /pexels YOUR_API_KEY"), "-a", "Shell"]);
                    return;
                }
                KeyringStorage.setNestedField(["apiKeys", "pexels"], args.trim());
                Quickshell.execDetached(["notify-send", "Pexels", Translation.tr("API key saved!"), "-a", "Shell"]);
            }
        },
    ]

    // Combined built-in and user actions
    property var allActions: searchActions.concat(userActionScripts)

    property string mathResult: ""
    property bool clipboardWorkSafetyActive: {
        const enabled = Config.options.workSafety.enable.clipboard;
        const sensitiveNetwork = (StringUtils.stringListContainsSubstring(Network.networkName.toLowerCase(), Config.options.workSafety.triggerCondition.networkNameKeywords));
        return enabled && sensitiveNetwork;
    }

    function containsUnsafeLink(entry) {
        if (entry == undefined)
            return false;
        const unsafeKeywords = Config.options.workSafety.triggerCondition.linkKeywords;
        return StringUtils.stringListContainsSubstring(entry.toLowerCase(), unsafeKeywords);
    }

    Timer {
        id: nonAppResultsTimer
        interval: Config.options.search.nonAppResultDelay
        onTriggered: {
            let expr = root.query;
            if (expr.startsWith(Config.options.search.prefix.math)) {
                expr = expr.slice(Config.options.search.prefix.math.length);
            }
            mathProc.calculateExpression(expr);
        }
    }

    Process {
        id: mathProc
        property list<string> baseCommand: ["qalc", "-t"]
        function calculateExpression(expression) {
            mathProc.running = false;
            mathProc.command = baseCommand.concat(expression);
            mathProc.running = true;
        }
        stdout: SplitParser {
            onRead: data => {
                root.mathResult = data;
            }
        }
    }

    // ── Local file search (~ prefix) ─────────────────────────────────────
    // Uses plocate's system-wide index (falls back to mlocate/locate's
    // `locate`, then to a live `find` under $HOME if neither index exists
    // yet — e.g. right after install, before the first updatedb run) rather
    // than a home-only live filesystem walk, per the chosen search scope.
    // Debounced the same way the calculator is (nonAppResultsTimer above):
    // async Process -> property -> the `results` computed property below
    // re-reads it reactively, so a filesystem query never blocks the UI
    // thread the way a synchronous call would.
    property list<string> fileResults: []
    property bool fileSearchRunning: false
    Timer {
        id: fileResultsTimer
        interval: Config.options.search.nonAppResultDelay
        onTriggered: {
            const term = StringUtils.cleanPrefix(root.query, Config.options.search.prefix.files).trim();
            filesProc.search(term);
        }
    }
    Process {
        id: filesProc
        function search(term) {
            filesProc.running = false;
            if (!term) {
                root.fileResults = [];
                root.fileSearchRunning = false;
                return;
            }
            root.fileSearchRunning = true;
            // $0 is an unused label, $1 is the actual (unescaped, safe from
            // shell injection since it's a positional param, not interpolated
            // into the script text) search term.
            filesProc.command = ["bash", "-c",
                'plocate -i -l 40 -- "$1" 2>/dev/null' +
                ' || locate -i -l 40 -- "$1" 2>/dev/null' +
                ' || find "$HOME" -iname "*$1*" 2>/dev/null | head -n 40',
                "file-search", term];
            filesProc.running = true;
        }
        stdout: StdioCollector {
            onStreamFinished: {
                root.fileResults = text.split("\n").map(l => l.trim()).filter(l => l.length > 0);
                root.fileSearchRunning = false;
            }
        }
    }

    // ── SSH quick-connect (@ prefix) ──────────────────────────────────────
    // ~/.ssh/config rarely changes, so this is loaded once (and on change)
    // rather than re-parsed per keystroke — filtered synchronously against
    // the already-parsed list below, same as the emoji/symbol lookups.
    property list<string> sshHostNames: []
    FileView {
        id: sshConfigFile
        path: `${Directories.home}/.ssh/config`
        watchChanges: true
        onFileChanged: reload()
        onLoaded: root._parseSshConfig()
        onLoadFailed: root.sshHostNames = []
    }
    function _parseSshConfig() {
        const text = sshConfigFile.text();
        const hosts = [];
        for (const line of text.split("\n")) {
            const m = /^\s*Host\s+(.+)$/i.exec(line);
            if (!m) continue;
            for (const token of m[1].trim().split(/\s+/)) {
                // Skip wildcard/pattern entries (Host *, Host 10.0.*, etc.) —
                // nothing sensible to "connect to" for those.
                if (token && !token.includes("*") && !token.includes("?") && !hosts.includes(token)) {
                    hosts.push(token);
                }
            }
        }
        root.sshHostNames = hosts;
    }

    // ── System services (! prefix) ────────────────────────────────────────
    // The unit *list* (name + enabled/disabled) is fetched once at startup
    // and filtered synchronously per keystroke, same reasoning as the SSH
    // host list above — it almost never changes at runtime. Live
    // active/inactive status and the actual start/stop/restart actions are
    // real systemctl calls made only when a result is actually selected, not
    // on every keystroke. System-wide (non --user) units go through pkexec,
    // which shows a normal polkit authentication prompt — never silently
    // elevated.
    property var systemServiceUnits: [] // [{name, scope: "user"|"system", enabled}]
    function _refreshSystemServiceUnits() {
        systemServiceUnitsProc.running = false;
        systemServiceUnitsProc.running = true;
    }
    Process {
        id: systemServiceUnitsProc
        command: ["bash", "-c",
            'systemctl --user list-unit-files --type=service --no-legend --no-pager 2>/dev/null | awk \'{print "user\\t"$1"\\t"$2}\';' +
            'systemctl list-unit-files --type=service --no-legend --no-pager 2>/dev/null | awk \'{print "system\\t"$1"\\t"$2}\'']
        stdout: StdioCollector {
            onStreamFinished: {
                const units = [];
                for (const line of text.split("\n")) {
                    const parts = line.split("\t");
                    if (parts.length < 3) continue;
                    units.push({ scope: parts[0], name: parts[1], enabled: parts[2].trim() });
                }
                root.systemServiceUnits = units;
            }
        }
    }
    Process { id: systemServiceActionProc }
    function runSystemServiceAction(unit, action) {
        const systemctlCmd = unit.scope === "user"
            ? ["systemctl", "--user", action, unit.name]
            : ["pkexec", "systemctl", action, unit.name];
        systemServiceActionProc.command = systemctlCmd;
        systemServiceActionProc.running = false;
        systemServiceActionProc.running = true;
        Quickshell.execDetached(["notify-send", Translation.tr("Service"),
            Translation.tr("%1 %2 (%3)").arg(action).arg(unit.name).arg(unit.scope), "-a", "Shell"]);
    }

    property list<var> results: {
        // Search results are handled here
        ////////////////// Skip? //////////////////
        if (root.query == "")
            return [];

        ///////////// Special cases ///////////////
        if (root.query.startsWith(Config.options.search.prefix.clipboard)) {
            // Clipboard
            const searchString = StringUtils.cleanPrefix(root.query, Config.options.search.prefix.clipboard);
            return Cliphist.fuzzyQuery(searchString).map((entry, index, array) => {
                const mightBlurImage = Cliphist.entryIsImage(entry) && root.clipboardWorkSafetyActive;
                let shouldBlurImage = mightBlurImage;
                if (mightBlurImage) {
                    shouldBlurImage = shouldBlurImage && (root.containsUnsafeLink(array[index - 1]) || root.containsUnsafeLink(array[index + 1]));
                }
                const type = `#${entry.match(/^\s*(\S+)/)?.[1] || ""}`;
                return resultComp.createObject(null, {
                    rawValue: entry,
                    name: StringUtils.cleanCliphistEntry(entry),
                    verb: "",
                    type: type,
                    execute: () => {
                        Cliphist.copy(entry);
                    },
                    actions: [resultComp.createObject(null, {
                            name: Translation.tr("Copy"),
                            iconName: "content_copy",
                            iconType: LauncherSearchResult.IconType.Material,
                            execute: () => {
                                Cliphist.copy(entry);
                            }
                        }), resultComp.createObject(null, {
                            name: Translation.tr("Delete"),
                            iconName: "delete",
                            iconType: LauncherSearchResult.IconType.Material,
                            execute: () => {
                                Cliphist.deleteEntry(entry);
                            }
                        })],
                    blurImage: shouldBlurImage
                });
            }).filter(Boolean);
        } else if (root.query.startsWith(Config.options.search.prefix.emojis)) {
            // Emojis
            const searchString = StringUtils.cleanPrefix(root.query, Config.options.search.prefix.emojis);
            return Emojis.fuzzyQuery(searchString).map(entry => {
                const emoji = entry.match(/^\s*(\S+)/)?.[1] || "";
                return resultComp.createObject(null, {
                    rawValue: entry,
                    name: entry.replace(/^\s*\S+\s+/, ""),
                    iconName: emoji,
                    iconType: LauncherSearchResult.IconType.Text,
                    verb: Translation.tr("Copy"),
                    type: Translation.tr("Emoji"),
                    execute: () => {
                        Quickshell.clipboardText = entry.match(/^\s*(\S+)/)?.[1];
                    }
                });
            }).filter(Boolean);
        } else if (root.query.startsWith(Config.options.search.prefix.keybinds ?? "<")) {
            // Keybinds
            const searchString = StringUtils.cleanPrefix(root.query, Config.options.search.prefix.keybinds ?? "<");
            const flatBinds = (function flatten(node) {
                let result = [...(node.keybinds ?? [])];
                for (const child of (node.children ?? [])) {
                    result = result.concat(flatten(child));
                }
                return result;
            })(HyprlandKeybinds.keybinds);

            return flatBinds.filter(bind => {
                if (!bind.comment) return false;
                if (searchString.length === 0) return true;
                return bind.comment.toLowerCase().includes(searchString.toLowerCase())
                    || bind.key.toLowerCase().includes(searchString.toLowerCase());
            }).map(bind => {
                const modsStr = bind.mods.join(" + ");
                const keyStr  = modsStr.length > 0 ? `${modsStr} + ${bind.key}` : bind.key;
                return resultComp.createObject(null, {
                    name: bind.comment,
                    iconName: "keyboard",
                    iconType: LauncherSearchResult.IconType.Material,
                    verb: keyStr,
                    type: Translation.tr("Keybind"),
                    comment: keyStr,
                    execute: () => {
                        Quickshell.clipboardText = keyStr;
                    }
                });
            }).filter(Boolean);
        } else if (root.query.startsWith(Config.options.search.prefix.symbols)) {
            // Material Symbols
            const searchString = StringUtils.cleanPrefix(root.query, Config.options.search.prefix.symbols);
            return MaterialSymbolsSearch.fuzzyQuery(searchString).map(entry => {
                const tabIdx = entry.indexOf("\t");
                const symName = tabIdx >= 0 ? entry.slice(0, tabIdx) : entry;
                const symTags = tabIdx >= 0 ? entry.slice(tabIdx + 1) : "";
                return resultComp.createObject(null, {
                    rawValue: entry,
                    name: symName,
                    iconName: symName,
                    iconType: LauncherSearchResult.IconType.Material,
                    verb: Translation.tr("Copy"),
                    type: Translation.tr("Symbol"),
                    comment: symTags,
                    execute: () => {
                        Quickshell.clipboardText = symName;
                    }
                });
            }).filter(Boolean);
        } else if (root.query.startsWith(Config.options.search.prefix.files)) {
            // Local files (plocate/locate/find - see filesProc above)
            fileResultsTimer.restart();
            const searchString = StringUtils.cleanPrefix(root.query, Config.options.search.prefix.files).trim();
            if (searchString.length === 0) return [];
            return root.fileResults.map(path => {
                const fileName = path.split("/").pop();
                const dirPath = path.slice(0, path.length - fileName.length - 1) || "/";
                return resultComp.createObject(null, {
                    rawValue: path,
                    name: fileName,
                    comment: dirPath,
                    iconName: "description",
                    iconType: LauncherSearchResult.IconType.Material,
                    verb: Translation.tr("Open"),
                    type: Translation.tr("File"),
                    execute: () => {
                        Quickshell.execDetached(["xdg-open", path]);
                    },
                    actions: [resultComp.createObject(null, {
                            name: Translation.tr("Open containing folder"),
                            iconName: "folder_open",
                            iconType: LauncherSearchResult.IconType.Material,
                            execute: () => {
                                Quickshell.execDetached(["xdg-open", dirPath]);
                            }
                        }), resultComp.createObject(null, {
                            name: Translation.tr("Copy path"),
                            iconName: "content_copy",
                            iconType: LauncherSearchResult.IconType.Material,
                            execute: () => {
                                Quickshell.clipboardText = path;
                            }
                        })]
                });
            });
        } else if (root.query.startsWith(Config.options.search.prefix.sshHosts)) {
            // SSH quick-connect (~/.ssh/config Host entries - see sshConfigFile above)
            const searchString = StringUtils.cleanPrefix(root.query, Config.options.search.prefix.sshHosts).toLowerCase().trim();
            return root.sshHostNames.filter(host => searchString.length === 0 || host.toLowerCase().includes(searchString)).map(host => {
                return resultComp.createObject(null, {
                    rawValue: host,
                    name: host,
                    iconName: "dns",
                    iconType: LauncherSearchResult.IconType.Material,
                    verb: Translation.tr("Connect"),
                    type: Translation.tr("SSH host"),
                    execute: () => {
                        Quickshell.execDetached(["bash", "-c", `${Config.options.apps.terminal} -e ssh '${StringUtils.shellSingleQuoteEscape(host)}'`]);
                    }
                });
            });
        } else if (root.query.startsWith(Config.options.search.prefix.systemServices)) {
            // systemd services (list cached once - see systemServiceUnits above;
            // start/stop/restart run the real systemctl call on selection only)
            const searchString = StringUtils.cleanPrefix(root.query, Config.options.search.prefix.systemServices).toLowerCase().trim();
            return root.systemServiceUnits.filter(unit => searchString.length === 0 || unit.name.toLowerCase().includes(searchString)).slice(0, 40).map(unit => {
                return resultComp.createObject(null, {
                    rawValue: unit.name,
                    name: unit.name,
                    comment: (unit.scope === "system" ? Translation.tr("System - pkexec required") : Translation.tr("User")) + " · " + unit.enabled,
                    iconName: "settings_applications",
                    iconType: LauncherSearchResult.IconType.Material,
                    verb: Translation.tr("Restart"),
                    type: Translation.tr("Service"),
                    execute: () => {
                        root.runSystemServiceAction(unit, "restart");
                    },
                    actions: [resultComp.createObject(null, {
                            name: Translation.tr("Start"),
                            iconName: "play_arrow",
                            iconType: LauncherSearchResult.IconType.Material,
                            execute: () => root.runSystemServiceAction(unit, "start")
                        }), resultComp.createObject(null, {
                            name: Translation.tr("Stop"),
                            iconName: "stop",
                            iconType: LauncherSearchResult.IconType.Material,
                            execute: () => root.runSystemServiceAction(unit, "stop")
                        }), resultComp.createObject(null, {
                            name: Translation.tr("Status"),
                            iconName: "info",
                            iconType: LauncherSearchResult.IconType.Material,
                            execute: () => {
                                // unit.name came straight from `systemctl list-unit-files`,
                                // whose first column is always a valid systemd unit name -
                                // systemd's own naming rules disallow quotes/spaces/`;`, so
                                // no additional shell-escaping is needed here.
                                Quickshell.execDetached(["bash", "-c",
                                    `${Config.options.apps.terminal} -e bash -c '${unit.scope === "user" ? "systemctl --user" : "systemctl"} status ${unit.name}; read -n1'`]);
                            }
                        })]
                });
            });
        }

        ////////////////// Init ///////////////////
        nonAppResultsTimer.restart();
        const mathResultObject = resultComp.createObject(null, {
            name: root.mathResult,
            verb: Translation.tr("Copy"),
            type: Translation.tr("Math result"),
            fontType: LauncherSearchResult.FontType.Monospace,
            iconName: 'calculate',
            iconType: LauncherSearchResult.IconType.Material,
            execute: () => {
                Quickshell.clipboardText = root.mathResult;
            }
        });
        const appResultObjects = AppSearch.fuzzyQuery(StringUtils.cleanPrefix(root.query, Config.options.search.prefix.app)).map(entry => {
            return resultComp.createObject(null, {
                type: Translation.tr("App"),
                id: entry.id,
                name: entry.name,
                iconName: entry.icon,
                iconType: LauncherSearchResult.IconType.System,
                verb: Translation.tr("Open"),
                execute: () => {
                    if (!entry.runInTerminal)
                        entry.execute();
                    else {
                        // Probably needs more proper escaping, but this will do for now
                        Quickshell.execDetached(["bash", '-c', `${Config.options.apps.terminal} -e '${StringUtils.shellSingleQuoteEscape(entry.command.join(' '))}'`]);
                    }
                },
                comment: entry.comment,
                runInTerminal: entry.runInTerminal,
                genericName: entry.genericName,
                keywords: entry.keywords,
                actions: entry.actions.map(action => {
                    return resultComp.createObject(null, {
                        name: action.name,
                        iconName: action.icon,
                        iconType: LauncherSearchResult.IconType.System,
                        execute: () => {
                            if (!action.runInTerminal)
                                action.execute();
                            else {
                                Quickshell.execDetached(["bash", '-c', `${Config.options.apps.terminal} -e '${StringUtils.shellSingleQuoteEscape(action.command.join(' '))}'`]);
                            }
                        }
                    });
                })
            });
        });
        ////////////////// Settings search //////////////////
        const settingsQuery = root.query.toLowerCase().trim();

        const settingsResults = root.settingsIndex.reduce((acc, page) => {
            const dynamicKeywords = (root.settingsKeywordsCache[page.page] || "").toLowerCase();
            const query = root.query.toLowerCase().trim();
            if (query === "") return acc;

            if (page.page.toLowerCase().includes(query) || dynamicKeywords.includes(query)) {
                acc.push(resultComp.createObject(null, {
                    name: page.page,
                    comment: dynamicKeywords.includes(query) ? "Section: " + query : "Settings for " + page.page,
                    verb: Translation.tr("Go"),
                    type: Translation.tr("Settings"),
                    iconName: "settings",
                    iconType: LauncherSearchResult.IconType.Material,
                    execute: () => {
                        GlobalStates.settingsOpen = true;
                        Qt.callLater(() => {
                            GlobalStates.settingsPage = page.page + ":" + query;
                        });
                        root.query = "";
                    }
                }));
            }
            return acc;
        }, []);
        const commandResultObject = resultComp.createObject(null, {
            name: StringUtils.cleanPrefix(root.query, Config.options.search.prefix.shellCommand).replace("file://", ""),
            verb: Translation.tr("Run"),
            type: Translation.tr("Command"),
            fontType: LauncherSearchResult.FontType.Monospace,
            iconName: 'terminal',
            iconType: LauncherSearchResult.IconType.Material,
            execute: () => {
                let cleanedCommand = root.query.replace("file://", "");
                cleanedCommand = StringUtils.cleanPrefix(cleanedCommand, Config.options.search.prefix.shellCommand);
                if (cleanedCommand.startsWith(Config.options.search.prefix.shellCommand)) {
                    cleanedCommand = cleanedCommand.slice(Config.options.search.prefix.shellCommand.length);
                }
                Quickshell.execDetached(["bash", "-c", root.query.startsWith('sudo') ? `${Config.options.apps.terminal} fish -C '${cleanedCommand}'` : cleanedCommand]);
            }
        });
        const webSearchResultObject = resultComp.createObject(null, {
            name: StringUtils.cleanPrefix(root.query, Config.options.search.prefix.webSearch),
            verb: Translation.tr("Search"),
            type: Translation.tr("Web search"),
            iconName: 'travel_explore',
            iconType: LauncherSearchResult.IconType.Material,
            execute: () => {
                let query = StringUtils.cleanPrefix(root.query, Config.options.search.prefix.webSearch);
                let url = Config.options.search.engineBaseUrl + query;
                for (let site of Config.options.search.excludedSites) {
                    url += ` -site:${site}`;
                }
                Qt.openUrlExternally(url);
            }
        });
        const launcherActionObjects = root.allActions.map(action => {
            const actionString = `${Config.options.search.prefix.action}${action.action}`;
            if (actionString.startsWith(root.query) || root.query.startsWith(actionString)) {
                return resultComp.createObject(null, {
                    name: root.query.startsWith(actionString) ? root.query : actionString,
                    verb: Translation.tr("Run"),
                    type: Translation.tr("Action"),
                    iconName: 'settings_suggest',
                    iconType: LauncherSearchResult.IconType.Material,
                    execute: () => {
                        action.execute(root.query.split(" ").slice(1).join(" "));
                    }
                });
            }
            return null;
        }).filter(Boolean);

        //////// Prioritized by prefix /////////
        let result = [];
        const startsWithNumber = /^\d/.test(root.query);
        const startsWithMathPrefix = root.query.startsWith(Config.options.search.prefix.math);
        const startsWithShellCommandPrefix = root.query.startsWith(Config.options.search.prefix.shellCommand);
        const startsWithWebSearchPrefix = root.query.startsWith(Config.options.search.prefix.webSearch);
        if (startsWithNumber || startsWithMathPrefix) {
            result.push(mathResultObject);
        } else if (startsWithShellCommandPrefix) {
            result.push(commandResultObject);
        } else if (startsWithWebSearchPrefix) {
            result.push(webSearchResultObject);
        }

        //////////////// Apps //////////////////
        result = result.concat(appResultObjects);
        ////////////// Settings ////////////////
        result = result.concat(settingsResults);
        ////////// Launcher actions ////////////
        result = result.concat(launcherActionObjects);

        /// Math result, command, web search ///
        if (Config.options.search.prefix.showDefaultActionsWithoutPrefix) {
            if (!startsWithShellCommandPrefix)
                result.push(commandResultObject);
            if (!startsWithNumber && !startsWithMathPrefix)
                result.push(mathResultObject);
            if (!startsWithWebSearchPrefix)
                result.push(webSearchResultObject);
        }
        
        return result;
    }

    Component {
        id: resultComp
        LauncherSearchResult {}
    }
}
