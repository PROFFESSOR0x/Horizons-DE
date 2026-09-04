#!/usr/bin/env bash
# shell/scripts/horizons/repo_root.sh — locate the Horizons-DE git clone on
# this machine. Meant to be `source`d, not run directly.
#
# The running shell (deployed to ~/.config/quickshell/horizons) is a *copy* —
# it has no idea where the actual git clone with installer.sh/install/ lives,
# since that depends entirely on where the user ran `git clone` from. This
# tries, in order:
#   1. $HORIZONS_REPO_ROOT, if the user has set it explicitly.
#   2. The "repo_root" field the installer persists into .horizons-meta.json
#      at install/update time (install/lib/state.sh's horizons_state_write).
#   3. A handful of conventional clone locations, as a last-ditch fallback
#      for a state file predating this field, or a hand-copied config.
#
# Usage: source this file, then call find_horizons_repo_root — it echoes the
# repo path and returns 0, or returns 1 with no output if none of the above
# panned out.
find_horizons_repo_root() {
    if [[ -n "${HORIZONS_REPO_ROOT:-}" && -d "${HORIZONS_REPO_ROOT}/.git" ]]; then
        echo "$HORIZONS_REPO_ROOT"
        return 0
    fi

    local meta="${XDG_CONFIG_HOME:-$HOME/.config}/horizons/.horizons-meta.json"
    if [[ -f "$meta" ]]; then
        local saved
        saved=$(grep -oP '"repo_root"\s*:\s*"\K[^"]+' "$meta" 2>/dev/null | head -n1)
        if [[ -n "$saved" && -d "$saved/.git" ]]; then
            echo "$saved"
            return 0
        fi
    fi

    local candidate
    for candidate in "$HOME/Horizons-DE" "$HOME/horizons-de" "$HOME/End4-PXpC" "$HOME/.local/share/horizons/src"; do
        if [[ -d "$candidate/.git" ]]; then
            echo "$candidate"
            return 0
        fi
    done

    return 1
}
