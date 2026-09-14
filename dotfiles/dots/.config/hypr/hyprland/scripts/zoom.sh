#!/usr/bin/env bash
# Zoom in/out helper for the legacy hyprlang config (hyprland/keybinds.conf).
# Mirrors the zoomfunction() in hyprland/keybinds.lua: step ±0.3, clamped to [1.0, 3.0].
# A script (instead of an inline bind command) is used because hyprlang would
# expand bare $vars inside `exec` commands at parse time.
# Usage: zoom.sh in|out
set -euo pipefail
step="-0.3"
[[ "${1:-in}" == "in" ]] && step="0.3"
cur="$(hyprctl -j getoption cursor:zoom_factor 2>/dev/null | jq -r '.float // 1')"
new="$(awk -v z="$cur" -v s="$step" 'BEGIN { v = z + s; if (v < 1) v = 1; if (v > 3) v = 3; print v }')"
hyprctl keyword cursor:zoom_factor "$new" >/dev/null
