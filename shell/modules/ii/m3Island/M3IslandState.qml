import Quickshell
pragma Singleton

// Small shared bridge between M3Island.qml's IpcHandler (which lives at the
// Scope level, outside any per-screen PanelWindow) and each screen's
// M3IslandContent instance (which owns the actual expand/collapse and
// notification state). The IpcHandler emits requests here; every
// M3IslandContent listens and acts on its own local state via the same
// setExpanded()/dismissCurrentNotification() helpers used by click/scroll/
// the right-click menu, so all entry points agree on the bookkeeping.
Singleton {
    id: root

    signal requestExpand()
    signal requestCollapse()
    signal requestToggleExpand()
    signal requestDismissNotification()

    // Live geometry of the island pill, in screen coordinates, keyed by screen
    // name. Published by each M3IslandContent as it moves and morphs so panels
    // that want to attach themselves to the island (the wallpaper selector
    // docks under it) can line up with the real pill instead of guessing at a
    // bar height that the island doesn't have.
    //
    // Each entry is { x, width, top, bottom, height }. Written as a whole new
    // object so the property's change signal fires and bindings re-evaluate.
    property var geometry: ({})

    function setGeometry(screenName, geo) {
        if (!screenName) return;
        const next = Object.assign({}, root.geometry);
        next[screenName] = geo;
        root.geometry = next;
    }

    function clearGeometry(screenName) {
        if (!screenName || root.geometry[screenName] === undefined) return;
        const next = Object.assign({}, root.geometry);
        delete next[screenName];
        root.geometry = next;
    }

    function geometryFor(screenName) {
        return root.geometry[screenName] ?? null;
    }
}
