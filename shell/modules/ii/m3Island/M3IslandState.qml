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
    signal requestExpand()
    signal requestCollapse()
    signal requestToggleExpand()
    signal requestDismissNotification()
}
