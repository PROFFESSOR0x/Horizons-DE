import QtQuick
import Quickshell
import qs.services

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
    // Wayland layer-shell is unavailable on X11/i3 (Xephyr). Those panels
    // would spam `WlrLayershell` / `wl_display` warnings and LazyLoader
    // failures (see screenshot). Keep only X11-safe panels there; full
    // Wayland-only panels stay gated behind WM.capabilities.layerShell.
    readonly property bool wayland: WM.capabilities.layerShell
    readonly property bool useX11Fallback: !wayland

    // ── Active bar — only one is loaded based on barMode ─────────────────────
    // On X11 the Bar's PanelWindow still needs layer-shell, so it is gated too.
    // i3/X11 users get a minimal fallback via i3bar/polybar or FloatingWindow.
    PanelLoader { extraCondition: wayland && Config.options.bar.barMode === "classic" && !Config.options.bar.vertical; component: Bar {} }
    PanelLoader { extraCondition: wayland && Config.options.bar.barMode === "classic" &&  Config.options.bar.vertical; component: VerticalBar {} }
    PanelLoader { extraCondition: wayland && Config.options.bar.barMode === "mesoBar";         component: MesoBar {} }
    PanelLoader { extraCondition: wayland && Config.options.bar.barMode === "m3Island";        component: M3Island {} }
    PanelLoader { extraCondition: wayland && Config.options.bar.barMode === "tasklistBar";     component: TasklistBar {} }
    PanelLoader { extraCondition: wayland && Config.options.bar.barMode === "sysmonitorBar";   component: SysmonitorBar {} }
    PanelLoader { extraCondition: wayland && Config.options.bar.barMode === "quickActionsBar"; component: QuickActionsBar {} }
    PanelLoader { extraCondition: wayland && Config.options.bar.barMode === "infoStrip";       component: InfoStrip {} }

    PanelLoader { extraCondition: wayland; component: Background {} }
    PanelLoader { extraCondition: wayland && Config.options.dock.enable; component: Dock {} }
    PanelLoader { extraCondition: wayland; component: Lock {} }
    PanelLoader { extraCondition: wayland; component: MediaControls {} }
    PanelLoader { extraCondition: wayland && Config.options.bar.barMode !== "m3Island"; component: NotificationPopup {} }
    PanelLoader { extraCondition: wayland; component: OnScreenDisplay {} }
    PanelLoader { extraCondition: wayland; component: OnScreenKeyboard {} }
    PanelLoader { extraCondition: wayland; component: Overlay {} }
    PanelLoader { extraCondition: wayland; component: Overview {} }
    PanelLoader { extraCondition: wayland; component: Polkit {} }
    PanelLoader { extraCondition: wayland; component: RegionSelector {} }
    PanelLoader { extraCondition: wayland; component: CaptureEditor {} }
    PanelLoader { extraCondition: wayland; component: ScreenCorners {} }
    PanelLoader { extraCondition: wayland; component: ScreenTranslator {} }
    PanelLoader { extraCondition: wayland; component: SessionScreen {} }
    PanelLoader { extraCondition: wayland; component: SidebarLeft {} }
    PanelLoader { extraCondition: wayland; component: SidebarRight {} }
    PanelLoader { extraCondition: wayland; component: WallpaperSelector {} }
    PanelLoader { extraCondition: wayland; component: Settings {} }
    PanelLoader { extraCondition: wayland; component: KeybindsOverlay {} }
    PanelLoader { extraCondition: wayland; component: DesktopMenu {} }
    PanelLoader { extraCondition: wayland; component: DropShelfPanel {} }
    PanelLoader { extraCondition: WM.compositor === "niri"; component: NiriBackdrop {} }
    PanelLoader { extraCondition: wayland; component: ScreenFrame {} }
    PanelLoader { extraCondition: wayland; component: WorkspacesHoverPreview {} }

    // ── Minimal X11 fallback: plain FloatingWindows so Xephyr/i3 does not
    // spam WARNs. Extend here with X11-native panels as needed.
    PanelLoader {
        extraCondition: useX11Fallback
        component: Scope {
            // Simple placeholder so the user sees the shell is running on X11.
            // Replace with X11-specific Bar/FloatingWindow when ready.
            Variants {
                model: Quickshell.screens
                LazyLoader {
                    required property ShellScreen modelData
                    active: true
                    component: FloatingWindow {
                        screen: modelData
                        visible: true
                        color: "transparent"
                        // Centered notice – does not use WlrLayershell at all
                        Text {
                            anchors.centerIn: parent
                            text: "Horizons (X11/i3) – Wayland panels disabled"
                            color: "#88ffffff"
                        }
                    }
                }
            }
        }
    }
}
