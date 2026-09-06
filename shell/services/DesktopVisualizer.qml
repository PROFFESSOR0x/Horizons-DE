pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs.modules.common

/**
 * One place that answers "should the desktop visualizer be drawn (and should
 * cava therefore be running) right now?".
 *
 * The visualizer is the most expensive desktop widget by a wide margin: it is
 * re-laid-out on every frame cava emits, and cava itself is a continuous audio
 * capture + FFT. Neither is worth paying for while nothing can be seen - so
 * when a monitor's active workspace has a non-floating (or fullscreen) window
 * on it, the widget on *that* monitor unloads entirely (FadeLoader.active
 * follows opacity, so this is a real teardown, not just a hidden item), and
 * cava is stopped once no monitor is showing one any more.
 *
 * Floating windows deliberately don't count: the desktop is still visible
 * around them, and someone who floats a window over the visualizer usually
 * wants to keep watching it.
 */
Singleton {
    id: root

    readonly property bool primaryEnabled: Config.options.background.widgets.visualizer.enable
    readonly property bool mirroredEnabled: Config.options.background.widgets.visualizerMirror.enable
    readonly property bool enabled: primaryEnabled || mirroredEnabled
    readonly property var screenList: Config.options.background.screenList ?? []

    // An empty screenList means "every screen", matching Background.qml.
    function allowedOnScreen(screenName) {
        return root.screenList.length === 0 || root.screenList.includes(screenName);
    }

    // Per-screen answer. Bindings that call this re-evaluate correctly because
    // every property it reads (including WM.obscuredMonitors) is a real
    // property read, captured by the binding that calls it.
    function shownOnScreen(screenName, visualizerConfig) {
        if (!visualizerConfig?.enable || !root.allowedOnScreen(screenName)) return false;
        if ((visualizerConfig.hideWhenObscured ?? true) && WM.obscuredMonitors[screenName]) return false;
        return true;
    }

    // Whether any screen at all is currently showing it - what gates cava, so
    // a window covering one monitor never silences the visualizer still
    // visible on another.
    readonly property bool visibleAnywhere: {
        if (!root.enabled) return false;
        const screens = Quickshell.screens;
        for (let i = 0; i < screens.length; i++) {
            const screenName = screens[i].name;
            if (root.shownOnScreen(screenName, Config.options.background.widgets.visualizer)
                || root.shownOnScreen(screenName, Config.options.background.widgets.visualizerMirror)) return true;
        }
        return false;
    }
}
