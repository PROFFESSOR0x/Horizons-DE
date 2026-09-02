pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Io
import QtQuick
import qs.services

/**
 * Manual screen-orientation toggle for the focused monitor, via
 * `hyprctl keyword monitor`. Hyprland-only: Hyprland transform values are
 * 0=normal, 1=90, 2=180, 3=270 (4-7 add a mirror flip; those are treated as
 * their un-flipped base so cycling always lands on 0-3).
 */
Singleton {
    id: root

    property bool hyprctlAvailable: false
    readonly property bool available: root.hyprctlAvailable && WM.compositor === "hyprland"
    readonly property string unavailableReason: WM.compositor !== "hyprland"
        ? "Only supported on Hyprland"
        : "hyprctl not found"

    // Current transform (0-3) of the focused monitor, kept in sync by polling.
    property int transform: 0

    function refresh() {
        if (!root.available) return;
        queryProc.running = false;
        queryProc.running = true;
    }

    function toggle() {
        if (!root.available) return;
        queryBeforeToggle.running = false;
        queryBeforeToggle.running = true;
    }

    function _findFocused(monitors) {
        return monitors.find(m => m.focused) ?? monitors[0] ?? null;
    }

    Process {
        id: checkHyprctl
        running: true
        command: ["sh", "-c", "command -v hyprctl"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.hyprctlAvailable = text.trim().length > 0;
                if (root.available) root.refresh();
            }
        }
    }

    Process {
        id: queryProc
        command: ["hyprctl", "monitors", "-j"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const focused = root._findFocused(JSON.parse(text));
                    if (focused) root.transform = focused.transform % 4;
                } catch (e) {
                    // hyprctl not reachable / malformed output - leave transform as-is
                }
            }
        }
    }

    Process {
        id: queryBeforeToggle
        command: ["hyprctl", "monitors", "-j"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const focused = root._findFocused(JSON.parse(text));
                    if (!focused) return;
                    const next = (focused.transform % 4 + 1) % 4;
                    const resolution = `${focused.width}x${focused.height}@${focused.refreshRate}`;
                    const position = `${focused.x}x${focused.y}`;
                    applyProc.command = ["hyprctl", "keyword", "monitor",
                        `${focused.name},${resolution},${position},${focused.scale},transform,${next}`];
                    applyProc.running = true;
                    root.transform = next;
                } catch (e) {
                    // ignore malformed hyprctl output
                }
            }
        }
    }

    Process {
        id: applyProc
    }

    Timer {
        interval: 4000
        running: root.available
        repeat: true
        onTriggered: root.refresh()
    }
}
