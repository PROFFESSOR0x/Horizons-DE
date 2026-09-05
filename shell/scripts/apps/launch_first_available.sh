#!/usr/bin/env bash
# WM-agnostic copy of dotfiles/dots/.config/hypr/hyprland/scripts/launch_first_available.sh.
# That copy only reaches disk under ~/.config/hypr on a Hyprland install
# (installer.sh's dotfiles-base step is Hyprland-only — see line ~574) so an
# i3/X11-only install, which still gets this "shell" component deployed to
# ~/.config/quickshell/<config>/scripts/, has nothing at that path to call.
# This file has zero Hyprland-specific logic — it's a generic "try these
# commands in order, run the first one whose binary exists" launcher — so it
# is duplicated here instead of moved, to avoid touching the Hyprland-side
# reference in dotfiles/dots/.config/hypr/hyprland/variables.lua.
for cmd in "$@"; do
    [[ -z "$cmd" ]] && continue
    eval "command -v ${cmd%% *}" >/dev/null 2>&1 || continue
    eval "$cmd" &
    exit
done
