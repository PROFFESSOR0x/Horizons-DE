#!/usr/bin/env bash
# shell/scripts/horizons/check_update.sh — print how many commits the local
# Horizons-DE clone is behind its origin remote. Used by services/Updates.qml
# to fold a repo update into the bar's update badge.
#
# Always prints a single integer and exits 0, even when the repo can't be
# found or the fetch fails (offline, no remote, etc.) — an unknown state
# should never look like "N updates available" and stick a badge on
# indefinitely; it should just report 0 (nothing to show) instead.
set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./repo_root.sh
source "$SCRIPT_DIR/repo_root.sh"

repo=$(find_horizons_repo_root) || { echo 0; exit 0; }

branch=$(git -C "$repo" rev-parse --abbrev-ref HEAD 2>/dev/null) || { echo 0; exit 0; }
git -C "$repo" fetch origin "$branch" --quiet 2>/dev/null || { echo 0; exit 0; }
git -C "$repo" rev-list --count "HEAD..origin/$branch" 2>/dev/null || echo 0
