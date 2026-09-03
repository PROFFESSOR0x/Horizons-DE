import QtQuick
import Quickshell

import qs.modules.common
import qs.modules.ii.background
import qs.modules.ii.bar
import qs.modules.ii.dock
import qs.modules.ii.lock
import qs.modules.ii.mediaControls
import qs.modules.ii.notificationPopup
import qs.modules.ii.onScreenDisplay
import qs.modules.ii.onScreenKeyboard
import qs.modules.ii.overview
import qs.modules.ii.polkit
import qs.modules.ii.settings
import qs.modules.ii.keybindsOverlay
import qs.modules.ii.regionSelector
import qs.modules.ii.capture
import qs.modules.ii.screenCorners
import qs.modules.ii.screenTranslator
import qs.modules.ii.sessionScreen
import qs.modules.ii.sidebarLeft
import qs.modules.ii.sidebarRight
import qs.modules.ii.overlay
import qs.modules.ii.verticalBar
import qs.modules.ii.mesoBar
import qs.modules.ii.tasklistBar
import qs.modules.ii.sysmonitorBar
import qs.modules.ii.quickActionsBar
import qs.modules.ii.infoStrip
import qs.modules.ii.m3Island
import qs.modules.ii.wallpaperSelector
import qs.modules.ii.desktopMenu
import qs.modules.ii.dropover
import qs.modules.ii.frame

Scope {
    // ── Active bar — only one is loaded based on barMode ─────────────────────
    // "classic"        → standard Bar (horizontal or vertical)
    // "mesoBar"        → floating, medium-width bar (formerly "topIsland")
    // "m3Island"       → M3 minimal island (clock center + hover/expand/launcher morph)
    // "tasklistBar"    → taskbar with pinned/open apps
    // "sysmonitorBar"  → system-monitor bar
    // "quickActionsBar"→ quick-actions / toggles bar
    // "infoStrip"      → slim info strip
    PanelLoader { extraCondition: Config.options.bar.barMode === "classic" && !Config.options.bar.vertical; component: Bar {} }
    PanelLoader { extraCondition: Config.options.bar.barMode === "classic" &&  Config.options.bar.vertical; component: VerticalBar {} }
    PanelLoader { extraCondition: Config.options.bar.barMode === "mesoBar";         component: MesoBar {} }
    PanelLoader { extraCondition: Config.options.bar.barMode === "m3Island";        component: M3Island {} }
    PanelLoader { extraCondition: Config.options.bar.barMode === "tasklistBar";     component: TasklistBar {} }
    PanelLoader { extraCondition: Config.options.bar.barMode === "sysmonitorBar";   component: SysmonitorBar {} }
    PanelLoader { extraCondition: Config.options.bar.barMode === "quickActionsBar"; component: QuickActionsBar {} }
    PanelLoader { extraCondition: Config.options.bar.barMode === "infoStrip";       component: InfoStrip {} }

    PanelLoader { component: Background {} }
    PanelLoader { extraCondition: Config.options.dock.enable; component: Dock {} }
    PanelLoader { component: Lock {} }
    PanelLoader { component: MediaControls {} }
    PanelLoader { extraCondition: Config.options.bar.barMode !== "m3Island"; component: NotificationPopup {} }
    PanelLoader { component: OnScreenDisplay {} }
    PanelLoader { component: OnScreenKeyboard {} }
    PanelLoader { component: Overlay {} }
    PanelLoader { component: Overview {} }
    PanelLoader { component: Polkit {} }
    PanelLoader { component: RegionSelector {} }
    PanelLoader { component: CaptureEditor {} }
    PanelLoader { component: ScreenCorners {} }
    PanelLoader { component: ScreenTranslator {} }
    PanelLoader { component: SessionScreen {} }
    PanelLoader { component: SidebarLeft {} }
    PanelLoader { component: SidebarRight {} }
    PanelLoader { component: WallpaperSelector {} }
    PanelLoader { component: Settings {} }
    PanelLoader { component: KeybindsOverlay {} }
    PanelLoader { component: DesktopMenu {} }
    PanelLoader { component: DropShelfPanel {} }
    PanelLoader { component: NiriBackdrop {} }
    PanelLoader { component: ScreenFrame {} }
    PanelLoader { component: WorkspacesHoverPreview {} }
}
