-- Custom binds (hl.bind)
-- Example: hl.bind("SUPER + T", hl.dsp.exec_cmd("kitty"))
hl.bind("SUPER + escape", hl.dsp.global("quickshell:settingsToggle"), { description = "Toggle settings" })
hl.bind("SUPER + I", hl.dsp.global("quickshell:settingsToggle"), { description = "Toggle settings" })

-- Keybinds cheat sheet overlay (shell/modules/ii/keybindsOverlay/KeybindsOverlay.qml).
-- SUPER + Slash already opens it via the default hyprland/keybinds.lua bind
-- (hl.dsp.global("quickshell:cheatsheetToggle")) — this is a second, alternate
-- trigger that goes through `qs ipc call` directly instead of a compositor
-- global-shortcut dispatch, e.g. for scripting or a different chord.
hl.bind("SUPER + SHIFT + Slash", hl.dsp.exec_cmd("qs -c $qsConfig ipc call keybindsOverlay toggle"), { description = "Shell: Toggle keybinds cheat sheet (ipc)" })
