#!/usr/bin/env bash
# install/lib/state.sh — Horizons identity & state management
# Creates and maintains the Horizons marker file + metadata used by the update protocol.

# Canonical locations (respect XDG)
: "${XDG_CONFIG_HOME:=$HOME/.config}"
: "${XDG_STATE_HOME:=$HOME/.local/state}"
: "${XDG_DATA_HOME:=$HOME/.local/share}"

HORIZONS_CONFIG_DIR="$XDG_CONFIG_HOME/horizons"
HORIZONS_STATE_DIR="$XDG_STATE_HOME/horizons"
HORIZONS_DATA_DIR="$XDG_DATA_HOME/horizons"

# Markers
HORIZONS_META_JSON="$HORIZONS_CONFIG_DIR/.horizons-meta.json"
HORIZONS_META_SIMPLE="$HORIZONS_CONFIG_DIR/.horizons-info"
HORIZONS_VERSION_FILE="$HORIZONS_CONFIG_DIR/.horizons-version"

# Installer version (bump when installer logic changes)
HORIZONS_INSTALLER_VERSION="2.0.0"

# ── helpers ──────────────────────────────────────────────────────────────────
_hz_now_iso() { date -u +"%Y-%m-%dT%H:%M:%SZ"; }
_hz_now_human() { date +"%Y-%m-%d %H:%M:%S %Z"; }

_hz_git_info() {
    local repo="${REPO_ROOT:-$(pwd)}"
    local commit="unknown" branch="unknown" remote="unknown" dirty="false"
    if git -C "$repo" rev-parse --git-dir &>/dev/null; then
        commit=$(git -C "$repo" rev-parse --short HEAD 2>/dev/null || echo "unknown")
        branch=$(git -C "$repo" rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")
        remote=$(git -C "$repo" remote get-url origin 2>/dev/null || echo "unknown")
        if ! git -C "$repo" diff --quiet 2>/dev/null; then dirty="true"; fi
    fi
    printf "%s|%s|%s|%s" "$commit" "$branch" "$remote" "$dirty"
}

_hz_ensure_dirs() {
    mkdir -p "$HORIZONS_CONFIG_DIR" "$HORIZONS_STATE_DIR" "$HORIZONS_DATA_DIR"
}

# ── Write state ───────────────────────────────────────────────────────────────
# Usage: horizons_state_write [profile] [components_csv] [lang]
# Target information is read from the installer globals so every update can
# re-apply the exact first-install choice without prompting again.
# e.g. horizons_state_write "full" "dots,shell" "ar"
horizons_state_write() {
    local profile="${1:-full}"
    local components="${2:-dots,shell}"
    local lang="${3:-${HORIZONS_LANG:-en}}"
    local distro="${PKG_GROUP:-${OS_GROUP_ID:-unknown}}"
    local protocol="${HORIZONS_PROTOCOL:-unknown}"
    local window_manager="${HORIZONS_WINDOW_MANAGER:-unknown}"
    local desktop_environment="${HORIZONS_DESKTOP_ENVIRONMENT:-existing}"
    local gitinfo
    gitinfo=$(_hz_git_info)
    IFS='|' read -r git_commit git_branch git_remote git_dirty <<< "$gitinfo"

    local now_iso now_human epoch
    now_iso=$(_hz_now_iso)
    now_human=$(_hz_now_human)
    epoch=$(date +%s)

    _hz_ensure_dirs

    local prev_installed_at=""
    if [[ -f "$HORIZONS_META_JSON" ]]; then
        prev_installed_at=$(grep -oP '"installed_at"\s*:\s*"\K[^"]+' "$HORIZONS_META_JSON" 2>/dev/null || true)
    fi
    [[ -z "$prev_installed_at" ]] && prev_installed_at="$now_iso"

    # ── JSON (machine readable, update protocol reads this) ─────────────────
    cat > "$HORIZONS_META_JSON" <<EOF
{
  "identity": "horizons",
  "display_name": "آفاق | Horizons",
  "installer_version": "$HORIZONS_INSTALLER_VERSION",
  "version": "1.0",
  "installed_at": "$prev_installed_at",
  "updated_at": "$now_iso",
  "epoch": $epoch,
  "git_commit": "$git_commit",
  "git_branch": "$git_branch",
  "git_remote": "$git_remote",
  "git_dirty": $git_dirty,
  "distro": "$distro",
  "arch": "$(uname -m)",
  "lang": "$lang",
  "language": "$lang",
  "profile": "$profile",
  "components": "$components",
  "display_protocol": "$protocol",
  "window_manager": "$window_manager",
  "desktop_environment": "$desktop_environment",
  "kernel": "$(uname -r)",
  "user": "$(whoami)",
  "hostname": "$(hostname 2>/dev/null || echo unknown)"
}
EOF

    # ── Simple marker (human readable, requested by user) ───────────────────
    cat > "$HORIZONS_META_SIMPLE" <<EOF
# آفاق | Horizons — identity marker
# This file proves this config is managed by Horizons.
# Do not delete — the update protocol uses it.
identity=horizons
display_name=آفاق | Horizons
installer_version=$HORIZONS_INSTALLER_VERSION
installed_at=$prev_installed_at
updated_at=$now_iso
updated_human=$now_human
epoch=$epoch
git_commit=$git_commit
git_branch=$git_branch
git_remote=$git_remote
profile=$profile
components=$components
display_protocol=$protocol
window_manager=$window_manager
desktop_environment=$desktop_environment
lang=$lang
language=$lang
distro=$distro
EOF

    # ── Legacy version file (one-liner for quick checks) ────────────────────
    echo "horizons $git_commit $now_iso profile=$profile" > "$HORIZONS_VERSION_FILE"

    # Also keep a copy in STATE dir for logs / rollback
    cp -f "$HORIZONS_META_JSON" "$HORIZONS_STATE_DIR/meta-$(date +%Y%m%d-%H%M%S).json" 2>/dev/null || true

    # History log
    echo "[$now_iso] $profile [$components] target=$protocol/$window_manager desktop=$desktop_environment commit=$git_commit distro=$distro" >> "$HORIZONS_STATE_DIR/history.log"

    # XDG state install.log symlink
    if [[ -n "${LOG_FILE:-}" && -f "$LOG_FILE" ]]; then
        cp -f "$LOG_FILE" "$HORIZONS_STATE_DIR/last-install.log" 2>/dev/null || true
    fi
}

# ── Read state ───────────────────────────────────────────────────────────────
horizons_state_read() {
    if [[ -f "$HORIZONS_META_JSON" ]]; then
        cat "$HORIZONS_META_JSON"
        return 0
    elif [[ -f "$HORIZONS_META_SIMPLE" ]]; then
        cat "$HORIZONS_META_SIMPLE"
        return 0
    else
        return 1
    fi
}

horizons_state_is_installed() {
    [[ -f "$HORIZONS_META_JSON" || -f "$HORIZONS_META_SIMPLE" ]]
}

horizons_state_get() {
    local key="$1"
    if [[ -f "$HORIZONS_META_JSON" ]] && command -v jq &>/dev/null; then
        jq -r ".\"$key\" // empty" "$HORIZONS_META_JSON" 2>/dev/null
    elif [[ -f "$HORIZONS_META_JSON" ]]; then
        grep -oP "\"$key\"\\s*:\\s*\"\\K[^\"]+" "$HORIZONS_META_JSON" 2>/dev/null | head -n1
    elif [[ -f "$HORIZONS_META_SIMPLE" ]]; then
        grep -oP "^$key=\\K.*" "$HORIZONS_META_SIMPLE" 2>/dev/null | head -n1
    fi
}

horizons_state_status() {
    if ! horizons_state_is_installed; then
        echo "Horizons is not installed (no marker file found)."
        echo "  Expected: $HORIZONS_META_JSON"
        return 1
    fi
    echo "┌─ Horizons Status ─────────────────────────────────"
    echo "│  Config dir : $HORIZONS_CONFIG_DIR"
    echo "│  State dir  : $HORIZONS_STATE_DIR"
    if [[ -f "$HORIZONS_META_JSON" ]]; then
        if command -v jq &>/dev/null; then
            jq . "$HORIZONS_META_JSON"
        else
            cat "$HORIZONS_META_JSON"
        fi
    else
        cat "$HORIZONS_META_SIMPLE"
    fi
    echo "└───────────────────────────────────────────────────"
    # Also show git divergence if inside repo
    if [[ -n "${REPO_ROOT:-}" && -d "$REPO_ROOT/.git" ]]; then
        echo ""
        echo "Repository: $REPO_ROOT"
        git -C "$REPO_ROOT" status --short --branch 2>/dev/null | head -n 20 || true
    fi
}

# ── Migrate legacy horizons state if needed ─────────────────────────────────
horizons_state_maybe_migrate_legacy() {
    local legacy_dirs=("$XDG_CONFIG_HOME/illogical-impulse" "$XDG_CONFIG_HOME/quickshell/end4-pC")
    for d in "${legacy_dirs[@]}"; do
        if [[ -d "$d" && ! -f "$HORIZONS_META_JSON" ]]; then
            # Don't auto-create, just hint
            return 0
        fi
    done
}
