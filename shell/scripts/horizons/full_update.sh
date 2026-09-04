#!/usr/bin/env bash
# shell/scripts/horizons/full_update.sh — the bar's Update button, in full:
# system packages (Arch/AUR) *and* the Horizons-DE repo itself (pull +
# re-apply), so "Update" means update everything, not just packages. Meant
# to run inside a held-open terminal (see UpdatesCount.qml) so the user can
# watch both steps and read any errors instead of them flashing by.
set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./repo_root.sh
source "$SCRIPT_DIR/repo_root.sh"

echo "═══ Horizons: Full Update ═══"
echo

echo "── System packages ──"
if command -v yay &>/dev/null; then
    yay -Syu --combinedupgrade=false
elif command -v paru &>/dev/null; then
    paru -Syu
else
    echo "No yay/paru found — skipping system package upgrade."
fi
echo

echo "── Horizons-DE repository ──"
if repo=$(find_horizons_repo_root); then
    echo "Repo: $repo"
    remote=$(git -C "$repo" remote get-url origin 2>/dev/null || echo "")
    case "$remote" in
        *PROFFESSOR0x/Horizons-DE*) ;;
        *) echo "Note: origin ($remote) doesn't look like PROFFESSOR0x/Horizons-DE — continuing anyway." ;;
    esac

    if [[ -x "$repo/install/horizons-update" ]]; then
        "$repo/install/horizons-update" full --rebase --smart --force
    else
        echo "install/horizons-update missing — falling back to a plain pull + re-apply."
        branch=$(git -C "$repo" rev-parse --abbrev-ref HEAD 2>/dev/null || echo "main")
        if git -C "$repo" pull --rebase origin "$branch"; then
            (cd "$repo" && ./installer.sh update --force)
        fi
    fi
else
    echo "Could not locate the Horizons-DE repo on this machine."
    echo "Re-run ./installer.sh once from your clone (it records its path for"
    echo "next time), or export HORIZONS_REPO_ROOT=/path/to/Horizons-DE before"
    echo "launching the shell."
fi

echo
echo "═══ Done ═══"
