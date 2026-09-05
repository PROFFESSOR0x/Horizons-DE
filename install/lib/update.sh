#!/usr/bin/env bash
# install/lib/update.sh — Horizons update protocol
# Provides: check / pull / apply / rollback
# State file: ~/.config/horizons/.horizons-meta.json  (via state.sh)

: "${XDG_CONFIG_HOME:=$HOME/.config}"
: "${XDG_STATE_HOME:=$HOME/.local/state}"

HORIZONS_META_JSON="${HORIZONS_META_JSON:-$XDG_CONFIG_HOME/horizons/.horizons-meta.json}"
HORIZONS_META_SIMPLE="${HORIZONS_META_SIMPLE:-$XDG_CONFIG_HOME/horizons/.horizons-info}"
HORIZONS_STATE_DIR="${HORIZONS_STATE_DIR:-$XDG_STATE_HOME/horizons}"

_hz_upd_info() { if declare -f info &>/dev/null; then info "$*"; else echo "[INFO] $*"; fi; }
_hz_upd_warn() { if declare -f warn &>/dev/null; then warn "$*"; else echo "[WARN] $*"; fi; }
_hz_upd_ok()   { if declare -f ok &>/dev/null; then ok "$*"; else echo "[OK] $*"; fi; }
_hz_upd_err()  { if declare -f err &>/dev/null; then err "$*"; else echo "[ERR] $*" >&2; fi; }

# ── Check ─────────────────────────────────────────────────────────────────────
# Compares local HEAD vs remote HEAD (origin/branch). No network if offline.
horizons_update_check() {
    local repo="${REPO_ROOT:-$(pwd)}"
    if [[ ! -d "$repo/.git" ]]; then
        _hz_upd_warn "Not a git repository: $repo"
        return 2
    fi

    local branch
    branch=$(git -C "$repo" rev-parse --abbrev-ref HEAD 2>/dev/null || echo "main")
    local local_commit remote_commit
    local_commit=$(git -C "$repo" rev-parse HEAD 2>/dev/null || echo "unknown")
    _hz_upd_info "Local  : $branch @ $local_commit"

    # Try to fetch (respect offline)
    if git -C "$repo" remote 2>/dev/null | grep -q origin; then
        _hz_upd_info "Fetching origin/$branch …"
        if git -C "$repo" fetch origin "$branch" --quiet 2>/dev/null; then
            remote_commit=$(git -C "$repo" rev-parse "origin/$branch" 2>/dev/null || echo "unknown")
            _hz_upd_info "Remote : origin/$branch @ $remote_commit"
            if [[ "$local_commit" == "$remote_commit" ]]; then
                _hz_upd_ok "Already up-to-date."
                return 0
            else
                local ahead behind
                ahead=$(git -C "$repo" rev-list --count "origin/$branch..HEAD" 2>/dev/null || echo "?")
                behind=$(git -C "$repo" rev-list --count "HEAD..origin/$branch" 2>/dev/null || echo "?")
                _hz_upd_warn "Update available: $behind commit(s) behind, $ahead ahead."
                echo ""
                git -C "$repo" log --oneline "HEAD..origin/$branch" 2>/dev/null | head -n 20 || true
                echo ""
                return 1
            fi
        else
            _hz_upd_warn "Failed to fetch — offline or no network. Showing local vs last-known remote."
            remote_commit=$(git -C "$repo" rev-parse "origin/$branch" 2>/dev/null || echo "unknown")
            _hz_upd_info "Last-known remote: $remote_commit"
            return 2
        fi
    else
        _hz_upd_warn "No 'origin' remote configured."
        return 2
    fi
}

# ── Pull ──────────────────────────────────────────────────────────────────────
# Stashes local changes, pulls, restores. Uses --rebase by default.
horizons_update_pull() {
    local repo="${REPO_ROOT:-$(pwd)}"
    local strategy="${1:-rebase}"  # rebase | merge | ff-only
    local branch
    branch=$(git -C "$repo" rev-parse --abbrev-ref HEAD 2>/dev/null || echo "main")

    _hz_upd_info "Pulling updates (strategy: $strategy)…"

    # Detect dirty
    local dirty=false
    if ! git -C "$repo" diff --quiet 2>/dev/null || ! git -C "$repo" diff --cached --quiet 2>/dev/null; then
        dirty=true
        _hz_upd_warn "Local changes detected — stashing."
        git -C "$repo" stash push -m "horizons-update-$(date +%Y%m%d-%H%M%S)" --include-untracked || true
    fi

    # Shallow → unshallow
    if [[ -f "$repo/.git/shallow" ]]; then
        _hz_upd_info "Shallow clone detected — fetching full history…"
        git -C "$repo" fetch --unshallow 2>/dev/null || true
    fi

    local pull_ok=false
    case "$strategy" in
        rebase)  git -C "$repo" pull --rebase origin "$branch" && pull_ok=true || pull_ok=false ;;
        merge)   git -C "$repo" pull --no-rebase origin "$branch" && pull_ok=true || pull_ok=false ;;
        ff-only) git -C "$repo" pull --ff-only origin "$branch" && pull_ok=true || pull_ok=false ;;
        *)       git -C "$repo" pull --rebase origin "$branch" && pull_ok=true || pull_ok=false ;;
    esac

    if [[ "$pull_ok" == true ]]; then
        _hz_upd_ok "Pulled latest changes."
        # Update submodules if any
        if git -C "$repo" submodule status --recursive 2>/dev/null | grep -qE '^[+-U]'; then
            _hz_upd_info "Updating submodules…"
            git -C "$repo" submodule update --init --recursive || true
        fi
        # Update state marker immediately
        if declare -f horizons_state_write &>/dev/null; then
            local prof comp saved_lang
            prof=$(horizons_state_get profile 2>/dev/null || echo "full")
            comp=$(horizons_state_get components 2>/dev/null || echo "dots,shell")
            saved_lang=$(horizons_state_get lang 2>/dev/null || true)
            [[ -n "$saved_lang" ]] && HORIZONS_LANG="$saved_lang"
            horizons_state_write "$prof" "$comp"
        fi
        return 0
    else
        _hz_upd_err "git pull failed — possible conflicts. Resolve manually:"
        _hz_upd_err "  cd $repo && git status"
        if [[ "$dirty" == true ]]; then
            _hz_upd_info "Your stashed changes: git stash list"
        fi
        return 1
    fi
}

# ── Apply (re-run installer steps) ───────────────────────────────────────────
# After pull, re-apply file sync + build + hyprland reload without re-doing deps if not needed.
horizons_update_apply() {
    local mode="${1:-smart}" # smart | full | quick
    _hz_upd_info "Applying updates (mode: $mode)…"
    # Delegate to installer.sh via re-exec
    local installer="$REPO_ROOT/installer.sh"
    if [[ ! -f "$installer" ]]; then installer="$REPO_ROOT/install/horizons-installer.sh"; fi
    if [[ ! -f "$installer" ]]; then
        _hz_upd_err "Installer not found at $installer"
        return 1
    fi

    # smart (the Update button's default) used to only skip the system
    # package upgrade - install_target_requirements() still ran unconditionally
    # underneath, re-checking (and, on any false negative, re-installing or
    # even source-building) every base dependency including quickshell itself
    # on every single routine update. --skip-deps stops that: a dependency
    # that was fine at the last real install/full-apply is still fine now,
    # and a genuinely new one only needs a full apply once, not every time.
    # --skip-backup stays off smart's list on purpose (still cheap and worth
    # the safety net); --launchers none skips prompting to install Walker/
    # Vicinae on every routine update.
    case "$mode" in
        quick)  HORIZONS_REAPPLY=1 bash "$installer" --skip-deps --skip-backup --skip-sysupdate --launchers none --force ;;
        smart)  HORIZONS_REAPPLY=1 bash "$installer" --skip-deps --skip-sysupdate --launchers none --force ;;
        full)   HORIZONS_REAPPLY=1 bash "$installer" --force ;;
        *)      HORIZONS_REAPPLY=1 bash "$installer" --force ;;
    esac
}

# ── Rollback ──────────────────────────────────────────────────────────────────
# Restores from backup dir or git reset.
horizons_update_rollback() {
    local repo="${REPO_ROOT:-$(pwd)}"
    _hz_upd_info "Rollback options:"
    echo "  1) git reset --hard HEAD@{1} (undo last pull)"
    echo "  2) git reset --hard HEAD~1  (undo last commit locally)"
    echo "  3) Restore from Horizons backup (~ ~/horizons-backup-*)"

    # Try git reflog
    local prev
    prev=$(git -C "$repo" rev-parse HEAD@{1} 2>/dev/null || echo "")
    if [[ -n "$prev" ]]; then
        _hz_upd_info "Previous HEAD (via reflog): $prev"
        _hz_upd_info "To rollback: git -C \"$repo\" reset --hard HEAD@{1}"
    fi

    # Find latest backup
    local latest_backup
    latest_backup=$(ls -dt ~/horizons-backup-* 2>/dev/null | head -n1 || true)
    if [[ -n "$latest_backup" ]]; then
        _hz_upd_info "Latest backup: $latest_backup"
    fi

    # Non-interactive if --force
    if [[ "${FORCE:-false}" == true ]]; then
        _hz_upd_warn "--force: auto-rolling back via git reset --hard HEAD@{1}"
        git -C "$repo" reset --hard HEAD@{1} || return 1
        horizons_update_apply quick
        return 0
    fi

    printf "\nRollback? [1=git reflog / 2=HEAD~1 / 3=backup / n=cancel]: "
    read -r ans
    case "$ans" in
        1) git -C "$repo" reset --hard HEAD@{1} && horizons_update_apply quick ;;
        2) git -C "$repo" reset --hard HEAD~1 && horizons_update_apply quick ;;
        3) if [[ -n "$latest_backup" ]]; then
               _hz_upd_info "Restoring from $latest_backup … (manual copy needed)"
               echo "  cp -r $latest_backup/* ~/.config/"
           else
               _hz_upd_warn "No backup found."
           fi
           ;;
        *) _hz_upd_info "Rollback cancelled." ;;
    esac
}

# ── Combined: check + pull + apply ───────────────────────────────────────────
horizons_update_full() {
    local strategy="${1:-rebase}"
    local mode="${2:-smart}"
    horizons_update_check
    local rc=$?
    if [[ $rc -eq 0 ]]; then
        _hz_upd_ok "No repository update needed — re-applying the saved installation target."
        horizons_update_apply "$mode"
        return $?
    fi
    # Even if check returned 2 (offline) we still try pull? Let user decide.
    if ! horizons_update_pull "$strategy"; then
        return 1
    fi
    # Re-exec into a fresh `horizons-update apply` process instead of calling
    # horizons_update_apply() directly: this file (and everything it calls
    # into) was sourced from disk *before* the pull above - calling it now
    # would run whatever update logic existed prior to this very update.
    # Re-execing re-reads install/horizons-update (and everything it
    # sources) fresh, so a change to the apply steps themselves takes effect
    # on the same run that pulls it in, not the one after.
    local repo="${REPO_ROOT:-$(pwd)}"
    local apply_flag="--smart"
    case "$mode" in
        quick) apply_flag="--quick" ;;
        full)  apply_flag="--full-apply" ;;
    esac
    exec bash "$repo/install/horizons-update" apply "$apply_flag" --force
}

# ── Auto-update cron / systemd timer helper ──────────────────────────────────
horizons_update_install_timer() {
    local timer_dir="$HOME/.config/systemd/user"
    mkdir -p "$timer_dir"
    local repo
    repo=$(realpath "${REPO_ROOT:-$(pwd)}")
    cat > "$timer_dir/horizons-update.service" <<EOF
[Unit]
Description=Horizons auto-update

[Service]
Type=oneshot
ExecStart=$repo/installer.sh update --force --skip-sysupdate
EOF
    cat > "$timer_dir/horizons-update.timer" <<EOF
[Unit]
Description=Check Horizons updates daily

[Timer]
OnCalendar=daily
Persistent=true

[Install]
WantedBy=timers.target
EOF
    systemctl --user daemon-reload 2>/dev/null || true
    systemctl --user enable --now horizons-update.timer 2>/dev/null || true
    _hz_upd_ok "Installed systemd user timer: horizons-update.timer (daily)"
}

horizons_update_remove_timer() {
    systemctl --user disable --now horizons-update.timer 2>/dev/null || true
    rm -f "$HOME/.config/systemd/user/horizons-update.service" "$HOME/.config/systemd/user/horizons-update.timer"
    systemctl --user daemon-reload 2>/dev/null || true
    _hz_upd_ok "Removed auto-update timer."
}
