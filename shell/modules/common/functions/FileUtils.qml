pragma Singleton
import Quickshell

Singleton {
    id: root

    /**
     * Trims the File protocol off the input string
     * @param {string} str
     * @returns {string}
     */
    function trimFileProtocol(str) {
        let s = str;
        if (typeof s !== "string") s = str.toString(); // Convert to string if it's an url or whatever
        return s.startsWith("file://") ? s.slice(7) : s;
    }

    /**
     * Extracts the file name from a file path
     * @param {string} str
     * @returns {string}
     */
    function fileNameForPath(str) {
        if (typeof str !== "string") return "";
        const trimmed = trimFileProtocol(str);
        return trimmed.split(/[\\/]/).pop();
    }

    /**
     * Extracts the folder name from a directory path
     * @param {string} str
     * @returns {string}
     */
    function folderNameForPath(str) {
        if (typeof str !== "string") return "";
        const trimmed = trimFileProtocol(str);
        // Remove trailing slash if present
        const noTrailing = trimmed.endsWith("/") ? trimmed.slice(0, -1) : trimmed;
        if (!noTrailing) return "";
        return noTrailing.split(/[\\/]/).pop();
    }

    /**
     * Removes the file extension from a file path or name
     * @param {string} str
     * @returns {string}
     */
    function trimFileExt(str) {
        if (typeof str !== "string") return "";
        const trimmed = trimFileProtocol(str);
        const lastDot = trimmed.lastIndexOf(".");
        if (lastDot > -1 && lastDot > trimmed.lastIndexOf("/")) {
            return trimmed.slice(0, lastDot);
        }
        return trimmed;
    }

    // Extension -> Material Symbol name. Deliberately Material Symbols and not
    // themed MIME icons: symbols are single-colour outline glyphs, so they take
    // the shell's own text colour and stay legible in light and dark alike,
    // where a themed icon set drags its own palette into a list that is
    // otherwise monochrome. One entry per *kind* of file, not per extension -
    // the point is to tell a video from an archive at a glance, not to name the
    // codec.
    readonly property var fileTypeIcons: ({
        // Documents & text
        "txt": "description", "md": "article", "rst": "article", "log": "receipt_long",
        "pdf": "picture_as_pdf",
        "doc": "description", "docx": "description", "odt": "description", "rtf": "description",
        "tex": "functions", "epub": "menu_book", "mobi": "menu_book", "djvu": "menu_book",
        // Spreadsheets & presentations
        "csv": "table", "tsv": "table",
        "xls": "table_chart", "xlsx": "table_chart", "ods": "table_chart",
        "ppt": "slideshow", "pptx": "slideshow", "odp": "slideshow",
        // Images
        "png": "image", "jpg": "image", "jpeg": "image", "gif": "gif", "bmp": "image",
        "webp": "image", "tif": "image", "tiff": "image", "avif": "image", "heic": "image",
        "ico": "image", "svg": "shapes", "xcf": "brush", "kra": "brush", "psd": "brush",
        // Video & audio
        "mp4": "movie", "mkv": "movie", "webm": "movie", "avi": "movie", "mov": "movie",
        "m4v": "movie", "mpg": "movie", "mpeg": "movie", "wmv": "movie",
        "srt": "subtitles", "vtt": "subtitles", "ass": "subtitles",
        "mp3": "music_note", "flac": "music_note", "wav": "music_note", "ogg": "music_note",
        "opus": "music_note", "m4a": "music_note", "aac": "music_note", "wma": "music_note",
        "mid": "piano", "midi": "piano",
        // Archives & images of disks
        "zip": "folder_zip", "tar": "folder_zip", "gz": "folder_zip", "xz": "folder_zip",
        "bz2": "folder_zip", "zst": "folder_zip", "7z": "folder_zip", "rar": "folder_zip",
        "iso": "album", "img": "album",
        // Packages
        "deb": "deployed_code", "rpm": "deployed_code", "apk": "deployed_code",
        "appimage": "deployed_code", "flatpakref": "deployed_code", "pkg": "deployed_code",
        // Code
        "c": "code", "h": "code", "cpp": "code", "cc": "code", "hpp": "code", "cs": "code",
        "rs": "code", "go": "code", "java": "code", "kt": "code", "swift": "code",
        "py": "code", "rb": "code", "php": "code", "pl": "code", "lua": "code",
        "js": "code", "mjs": "code", "ts": "code", "jsx": "code", "tsx": "code",
        "qml": "code", "vue": "code", "dart": "code", "scala": "code", "hs": "code",
        "html": "html", "htm": "html", "css": "css", "scss": "css", "sass": "css",
        "sh": "terminal", "bash": "terminal", "zsh": "terminal", "fish": "terminal",
        "ps1": "terminal", "bat": "terminal",
        "sql": "database", "db": "database", "sqlite": "database", "sqlite3": "database",
        "patch": "difference", "diff": "difference",
        // Config & data
        "json": "data_object", "yaml": "data_object", "yml": "data_object",
        "toml": "data_object", "xml": "data_object", "plist": "data_object",
        "ini": "settings", "conf": "settings", "cfg": "settings", "desktop": "launch",
        "service": "settings_applications", "rules": "rule",
        // Fonts
        "ttf": "font_download", "otf": "font_download", "woff": "font_download",
        "woff2": "font_download", "ttc": "font_download",
        // Keys & secrets
        "pem": "key", "key": "key", "crt": "verified_user", "cer": "verified_user",
        "gpg": "lock", "asc": "lock", "kdbx": "lock",
        // Binaries
        "so": "memory", "o": "memory", "a": "memory", "bin": "memory", "exe": "memory"
    })

    /**
     * Picks a monochrome Material Symbol for a path, by extension.
     * Directories (no extension, or a trailing slash) get a folder.
     * @param {string} str  file path
     * @param {bool} isDirectory  optional hint when the caller already knows
     * @returns {string} Material Symbol name
     */
    function iconForPath(str, isDirectory) {
        if (isDirectory === true) return "folder";
        if (typeof str !== "string" || str.length === 0) return "draft";
        const trimmed = trimFileProtocol(str);
        if (trimmed.endsWith("/")) return "folder";
        const name = trimmed.split("/").pop();
        // A dotfile with no further extension ("/.bashrc") is a config file,
        // not an extensionless blob - its name *is* the extension.
        const dotIndex = name.lastIndexOf(".");
        if (dotIndex <= 0) {
            if (name.startsWith(".")) return "settings";
            return "draft";
        }
        const ext = name.slice(dotIndex + 1).toLowerCase();
        // Compound archive extensions (".tar.gz", ".tar.zst", …) - the last
        // component alone already maps to folder_zip, so nothing extra needed.
        return root.fileTypeIcons[ext] ?? "draft";
    }

    /**
     * Returns the parent directory of a given file path
     * @param {string} str
     * @returns {string}
     */
    function parentDirectory(str) {
        if (typeof str !== "string") return "";
        const trimmed = trimFileProtocol(str);
        const parts = trimmed.split(/[\\/]/);
        if (parts.length <= 1) return "";
        parts.pop();
        return parts.join("/");
    }
}
