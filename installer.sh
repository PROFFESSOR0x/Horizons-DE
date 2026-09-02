#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║              آفاق | Horizons  ✦  Interactive Installer                       ║
# ║    A personal fork of illogical-impulse  ·  Powered by Quickshell            ║
# ╚══════════════════════════════════════════════════════════════════════════════╝
# Single entrypoint for the whole monorepo. Replaces the old shell/installer.sh
# (which tried to call a nonexistent dots-hyprland/install.sh) and calls the
# real dotfiles entrypoint (dotfiles/setup install) correctly.
#
# Usage:  bash installer.sh [OPTIONS]
#   -h | --help          Show this help
#   -f | --force         Skip all confirmations (non-interactive)
#   -q | --quiet         Minimal output
#        --skip-deps     Skip dependency installation
#        --skip-dots     Skip dotfiles (base) install
#        --skip-qs       Skip Quickshell shell config install
#        --skip-backup   Skip config backup step
#        --uninstall     Remove the Horizons Quickshell config only
# ─────────────────────────────────────────────────────────────────────────────
set -euo pipefail

# ── Colours & styles ──────────────────────────────────────────────────────────
R=$'\e[31m';  G=$'\e[32m';  Y=$'\e[33m';  B=$'\e[34m'
M=$'\e[35m';  C=$'\e[36m';  W=$'\e[37m'
BD=$'\e[1m';  DM=$'\e[2m';  IT=$'\e[3m';  UL=$'\e[4m';  BL=$'\e[5m'
IV=$'\e[7m';  RST=$'\e[0m'

# ── Paths ─────────────────────────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$SCRIPT_DIR"                          # End4-PXpC/
QS_REPO="$REPO_ROOT/shell"                       # shell/  (Quickshell config)
DOTS_REPO="$REPO_ROOT/dotfiles"                  # dotfiles/ (dots-hyprland base)
HYPRGLASS_DIR="$QS_REPO/plugins/hyprglass"

# shellcheck source=install/lib/distro.sh
source "$REPO_ROOT/install/lib/distro.sh"

XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
XDG_BIN_HOME="${XDG_BIN_HOME:-$HOME/.local/bin}"

# New canonical identity: "horizons" (was "illogical-impulse" / "end4-pC")
QS_CONFIG_DIR="$XDG_CONFIG_HOME/quickshell/horizons"
DOTS_CONFIG_DIR="$XDG_CONFIG_HOME/horizons"
BACKUP_DIR="$HOME/horizons-backup-$(date +%Y%m%d-%H%M%S)"
LOG_FILE="/tmp/horizons-install-$(date +%Y%m%d-%H%M%S).log"

# Legacy locations we migrate from, if present
LEGACY_DOTS_CONFIG_DIR="$XDG_CONFIG_HOME/illogical-impulse"
LEGACY_QS_CONFIG_DIR="$XDG_CONFIG_HOME/quickshell/end4-pC"

# ── State flags ───────────────────────────────────────────────────────────────
FORCE=false
QUIET=false
SKIP_DEPS=false
SKIP_DOTS=false
SKIP_QS=false
SKIP_BACKUP=false
DO_UNINSTALL=false
ASK=true          # prompt before each step
ERRORS=0

# ── Parse args ────────────────────────────────────────────────────────────────
while [[ $# -gt 0 ]]; do
  case $1 in
    -h|--help)
      sed -n '2,17p' "$0" | sed 's/^# //'
      exit 0 ;;
    -f|--force)  FORCE=true; ASK=false; shift ;;
    -q|--quiet)  QUIET=true; shift ;;
    --skip-deps) SKIP_DEPS=true; shift ;;
    --skip-dots) SKIP_DOTS=true; shift ;;
    --skip-qs)   SKIP_QS=true;   shift ;;
    --skip-backup) SKIP_BACKUP=true; shift ;;
    --uninstall) DO_UNINSTALL=true; shift ;;
    *) echo -e "${R}Unknown option: $1${RST}"; exit 1 ;;
  esac
done

# ── Logging ───────────────────────────────────────────────────────────────────
exec > >(tee -a "$LOG_FILE") 2>&1

# ── Helpers ───────────────────────────────────────────────────────────────────
println(){ [[ "$QUIET" == false ]] && printf "%b\n" "$*"; }
info()   { println "${C}${BD}  ℹ  ${RST}${C}$*${RST}"; }
ok()     { println "${G}${BD}  ✔  ${RST}${G}$*${RST}"; }
warn()   { println "${Y}${BD}  ⚠  ${RST}${Y}$*${RST}"; }
err()    { println "${R}${BD}  ✖  ${RST}${R}$*${RST}"; ERRORS=$((ERRORS+1)); }
step()   { println "\n${M}${BD}╸╸╸  $*${RST}"; }
die()    { err "$*"; exit 1; }

# ── Safe command runner: retry / skip / abort on failure ─────────────────────
run(){
  if [[ "$QUIET" == false ]]; then
    println "${DM}${IT}    ▸ $*${RST}"
  fi

  if "$@"; then
    return 0
  fi

  local rc=$?
  err "Command failed (exit $rc): $*"

  if [[ "$FORCE" == true ]]; then
    warn "Force mode — continuing despite error."
    return 0
  fi

  while true; do
    printf "${Y}  [r]etry  [s]kip  [a]bort  ▸ ${RST}"
    read -r p
    case "$p" in
      r|R) "$@" && return 0 || { err "Still failed."; } ;;
      s|S) warn "Skipped."; return 0 ;;
      a|A) die "Aborted by user." ;;
    esac
  done
}

# ── Interactive confirmation ──────────────────────────────────────────────────
confirm(){
  local msg="$1"
  local def="${2:-y}"
  [[ "$ASK" == false ]] && return 0
  local prompt
  [[ "$def" == "y" ]] && prompt="${G}[Y/n]${RST}" || prompt="${R}[y/N]${RST}"
  printf "\n${B}${BD}  ?  ${RST}${B}%s${RST}  %s  " "$msg" "$prompt"
  read -r p
  p="${p:-$def}"
  case "$p" in
    y|Y|yes|YES) return 0 ;;
    *) return 1 ;;
  esac
}

# ── Progress bar ──────────────────────────────────────────────────────────────
progress(){
  local current=$1 total=$2 label="${3:-}"
  local width=40
  local filled=$(( current * width / total ))
  local empty=$(( width - filled ))
  local filled_chars="" empty_chars=""
  (( filled > 0 )) && filled_chars=$(printf '%0.s█' $(seq 1 "$filled"))
  (( empty > 0 )) && empty_chars=$(printf '%0.s░' $(seq 1 "$empty"))
  local bar="${G}${filled_chars}${DM}${empty_chars}${RST}"
  printf "\r  [%b] %3d%% %s" "$bar" "$(( current * 100 / total ))" "$label"
}

# ── Fancy banner ──────────────────────────────────────────────────────────────
print_banner(){
  clear
  printf "\n"
  printf "${M}${BD}"
  printf "   █████╗ ███████╗ █████╗  █████╗ ██╗\n"
  printf "  ██╔══██╗██╔════╝██╔══██╗██╔══██╗██║\n"
  printf "  ███████║█████╗  ███████║███████║██║\n"
  printf "  ██╔══██║██╔══╝  ██╔══██║██╔══██║╚═╝\n"
  printf "  ██║  ██║██║     ██║  ██║██║  ██║██╗\n"
  printf "  ╚═╝  ╚═╝╚═╝     ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  آفاق | Horizons\n"
  printf "${RST}"
  printf "\n"
  printf "  ${C}${IT}A personal fork of illogical-impulse · Powered by Quickshell${RST}\n"
  printf "  ${DM}by pctrade  ·  %s${RST}\n" "$(date '+%Y-%m-%d %H:%M')"
  printf "\n"
  printf "  ${DM}Log file: ${UL}%s${RST}\n" "$LOG_FILE"
  printf "\n"
  printf "${M}$(printf '%0.s─' $(seq 1 60))${RST}\n"
  printf "\n"
}

# ── Requirement checks ────────────────────────────────────────────────────────
check_requirements(){
  step "Pre-flight checks"

  local ok_count=0 fail_count=0

  _chk(){
    local label="$1" cmd="$2"
    printf "  %-30s" "$label"
    if eval "$cmd" &>/dev/null; then
      printf "${G}✔ found${RST}\n"
      ((++ok_count))
    else
      printf "${R}✖ missing${RST}\n"
      ((++fail_count))
    fi
  }

  _chk "bash ≥ 4"         "[[ \${BASH_VERSINFO[0]} -ge 4 ]]"
  _chk "git"               "command -v git"
  _chk "rsync"             "command -v rsync"
  _chk "curl"              "command -v curl"
  _chk "sudo"              "command -v sudo"
  _chk "quickshell (qs)"  "command -v qs || command -v quickshell"
  _chk "hyprctl"          "command -v hyprctl"
  _chk "Hyprland running" "hyprctl version"
  _chk "dotfiles/ present" "[[ -d '$DOTS_REPO' ]]"

  printf "\n"
  printf "  Checks: ${G}%d OK${RST}  ${R}%d missing${RST}\n" "$ok_count" "$fail_count"

  if [[ $fail_count -gt 0 ]]; then
    warn "Some requirements are missing."
    if ! confirm "Continue anyway?"; then
      die "Aborting — please install missing requirements first."
    fi
  else
    ok "All requirements satisfied."
  fi
}

# ── Migration shim: bring old identity's data forward ────────────────────────
migrate_legacy_configs(){
  step "Check for legacy config (illogical-impulse / end4-pC)"

  local did_anything=false

  if [[ -d "$LEGACY_DOTS_CONFIG_DIR" && ! -d "$DOTS_CONFIG_DIR" ]]; then
    warn "Found legacy config at: $LEGACY_DOTS_CONFIG_DIR"
    warn "New location is:        $DOTS_CONFIG_DIR"
    if confirm "Copy it to the new 'horizons' location now? (original is kept, nothing is deleted)"; then
      run mkdir -p "$(dirname "$DOTS_CONFIG_DIR")"
      run cp -r "$LEGACY_DOTS_CONFIG_DIR" "$DOTS_CONFIG_DIR"
      ok "Migrated $LEGACY_DOTS_CONFIG_DIR -> $DOTS_CONFIG_DIR"
      did_anything=true
    else
      info "Skipping migration — a fresh 'horizons' config will be created."
    fi
  fi

  if [[ -d "$LEGACY_QS_CONFIG_DIR" && ! -d "$QS_CONFIG_DIR" ]]; then
    warn "Found legacy Quickshell config at: $LEGACY_QS_CONFIG_DIR"
    warn "New location is:                   $QS_CONFIG_DIR"
    if confirm "Copy it to the new 'horizons' location now? (original is kept, nothing is deleted)"; then
      run mkdir -p "$(dirname "$QS_CONFIG_DIR")"
      run cp -r "$LEGACY_QS_CONFIG_DIR" "$QS_CONFIG_DIR"
      ok "Migrated $LEGACY_QS_CONFIG_DIR -> $QS_CONFIG_DIR"
      did_anything=true
    else
      info "Skipping migration — install will write a fresh 'horizons' Quickshell config."
    fi
  fi

  [[ "$did_anything" == false ]] && info "No legacy config found (or already migrated)."
}

# ── Backup existing configs ────────────────────────────────────────────────────
do_backup(){
  [[ "$SKIP_BACKUP" == true ]] && return 0
  step "Backup existing configs"

  local targets=(
    "$QS_CONFIG_DIR"
    "$DOTS_CONFIG_DIR"
  )
  local has_any=false
  for t in "${targets[@]}"; do
    [[ -e "$t" ]] && has_any=true && break
  done

  if [[ "$has_any" == false ]]; then
    info "Nothing to backup — fresh install detected."
    return 0
  fi

  warn "Existing Horizons config detected."
  printf "\n"

  if ! confirm "Backup existing config to ${BACKUP_DIR}?"; then
    warn "Skipping backup. Existing files will be overwritten."
    return 0
  fi

  run mkdir -p "$BACKUP_DIR"
  for t in "${targets[@]}"; do
    [[ -e "$t" ]] && run cp -r "$t" "$BACKUP_DIR/"
  done
  ok "Backup saved to: $BACKUP_DIR"
}

# ── Install dotfiles (base) via dotfiles/setup ────────────────────────────────
install_dots(){
  [[ "$SKIP_DOTS" == true ]] && { info "Skipping dotfiles base install (--skip-dots)"; return 0; }
  step "Install dotfiles (base — hypr/kitty/fish/etc.)"

  if [[ ! -d "$DOTS_REPO" ]]; then
    warn "dotfiles/ not found at: $DOTS_REPO"
    warn "This repo should ship dotfiles/ already — check your checkout."
    return 0
  fi

  ok "dotfiles found at $DOTS_REPO"
  if ! confirm "Run 'dotfiles/setup install' (recommended on first install)?"; then
    info "Skipping dotfiles installer."
    return 0
  fi

  # The real entrypoint is "./setup install", NOT install.sh / setup.sh
  # (those never existed — this was the broken call in the old installer).
  local setup_args=(install)
  [[ "$SKIP_DEPS" == true ]]   && setup_args+=(--skip-alldeps)
  [[ "$SKIP_BACKUP" == true ]] && setup_args+=(--skip-backup)
  [[ "$FORCE" == true ]]       && setup_args+=(--force)

  info "Launching: $DOTS_REPO/setup ${setup_args[*]}"
  printf "\n"
  (cd "$DOTS_REPO" && run bash ./setup "${setup_args[@]}")
}

# ── Build the hyprglass plugin ────────────────────────────────────────────────
build_hyprglass(){
  step "Build hyprglass plugin"

  if [[ ! -d "$HYPRGLASS_DIR" ]]; then
    warn "hyprglass plugin dir not found at $HYPRGLASS_DIR — skipping."
    return 0
  fi

  if command -v hyprpm &>/dev/null; then
    info "hyprpm found — you can alternatively run:"
    info "  hyprpm add https://github.com/hyprnux/hyprglass && hyprpm enable hyprglass"
  fi

  if ! command -v make &>/dev/null || ! command -v g++ &>/dev/null; then
    warn "make/g++ not found — skipping hyprglass build."
    warn "Install build-essential/base-devel (or use hyprpm) and re-run later."
    return 0
  fi

  if ! confirm "Build hyprglass.so from source now (make)?"; then
    info "Skipping hyprglass build."
    return 0
  fi

  if (cd "$HYPRGLASS_DIR" && make) ; then
    ok "hyprglass.so built at $HYPRGLASS_DIR/hyprglass.so"
  else
    warn "hyprglass build failed — missing dev headers (hyprland, pixman, libdrm)?"
    warn "Continuing install without a fresh plugin build."
  fi
}

# ── Install Horizons Quickshell config ────────────────────────────────────────
install_qs(){
  [[ "$SKIP_QS" == true ]] && { info "Skipping Quickshell config (--skip-qs)"; return 0; }
  step "Install Horizons Quickshell config"

  info "Source : $QS_REPO"
  info "Target : $QS_CONFIG_DIR"
  printf "\n"

  if ! confirm "Copy Horizons config to $QS_CONFIG_DIR?"; then
    warn "Skipping Quickshell config install."
    return 0
  fi

  run mkdir -p "$QS_CONFIG_DIR"

  info "Syncing files…"
  local total
  total=$(find "$QS_REPO" -not -path "*/.git/*" -not -name ".git" | wc -l)
  local copied=0

  rsync -av --delete \
    --exclude='.git' \
    --exclude='installer.sh' \
    --exclude='plugins/hyprglass/src/*.o' \
    --exclude='plugins/hyprglass/*.so' \
    --out-format='%n' \
    "$QS_REPO/" "$QS_CONFIG_DIR/" | while IFS= read -r line; do
      ((copied++)) || true
      progress "$copied" "$total" "$line"
    done
  printf "\n"

  # Copy the freshly-built plugin binary in separately (it's excluded above
  # so a stale one already deployed isn't blown away if the build was skipped).
  if [[ -f "$HYPRGLASS_DIR/hyprglass.so" ]]; then
    run mkdir -p "$QS_CONFIG_DIR/plugins/hyprglass"
    run cp "$HYPRGLASS_DIR/hyprglass.so" "$QS_CONFIG_DIR/plugins/hyprglass/hyprglass.so"
    ok "Deployed hyprglass.so to $QS_CONFIG_DIR/plugins/hyprglass/"
  fi

  ok "Quickshell config installed."
}

# ── Configure Hyprland to use Horizons ────────────────────────────────────────
configure_hyprland(){
  step "Configure Hyprland shell"

  local vars_file="$XDG_CONFIG_HOME/hypr/hyprland/variables.lua"
  local current_qs="(not detected)"

  if [[ -f "$vars_file" ]]; then
    current_qs=$(grep -oP 'hl\.env\("qsConfig",\s*"\K[^"]+' "$vars_file" 2>/dev/null | head -n1 || true)
    current_qs="${current_qs:-not set}"
    info "Current qsConfig: ${BD}$current_qs${RST}"
  else
    warn "Hyprland variables.lua not found at $vars_file"
    warn "You may need to configure Hyprland manually."
    return 0
  fi

  if [[ "$current_qs" == "horizons" ]]; then
    ok "Already set to horizons — no changes needed."
    return 0
  fi

  printf "\n"
  printf "  ${B}Set Hyprland to use Horizons as the shell?${RST}\n"
  printf "  ${DM}(Changes %s)${RST}\n" "$vars_file"
  printf "  ${DM}Current value: ${Y}%s${RST}\n" "$current_qs"
  printf "\n"

  if confirm "Change qsConfig to 'horizons'?"; then
    run cp "$vars_file" "${vars_file}.bak"
    run sed -i -E 's|hl\.env\("qsConfig",[[:space:]]*"[^"]*"\)|hl.env("qsConfig", "horizons")|' "$vars_file"
    ok "qsConfig updated to horizons."
    ok "Backup saved to: ${vars_file}.bak"
  else
    info "Skipping — you can set it manually later:"
    printf "  ${DM}Edit: %s${RST}\n" "$vars_file"
    printf "  ${DM}Set:  hl.env(\"qsConfig\", \"horizons\")${RST}\n"
  fi
}

# ── Add settings keybind ──────────────────────────────────────────────────────
configure_keybind(){
  step "Settings keybind"

  local keybind_line='hl.bind("SUPER + escape", hl.dsp.global("quickshell:settingsToggle"), {description = "Toggle settings"})'
  local custom_dir="$XDG_CONFIG_HOME/hypr/custom"
  local keybind_file="$custom_dir/keybinds.lua"

  if grep -r "settingsToggle" "$XDG_CONFIG_HOME/hypr/" &>/dev/null 2>&1; then
    ok "Settings keybind already configured — skipping."
    return 0
  fi

  printf "\n"
  printf "  ${B}Suggested keybind:${RST}\n"
  printf "  ${DM}Super + Escape${RST}  →  Toggle settings panel\n"
  printf "\n"

  if confirm "Add settings keybind (Super+Escape) to $keybind_file?"; then
    run mkdir -p "$custom_dir"
    {
      printf "\n-- Horizons settings panel toggle\n"
      printf '%s\n' "$keybind_line"
    } >> "$keybind_file"
    ok "Keybind added."
  else
    info "Skipping — add manually to your Hyprland config:"
    printf "  ${DM}%s${RST}\n" "$keybind_line"
  fi
}

# ── Restart Quickshell ────────────────────────────────────────────────────────
restart_qs(){
  step "Restart Quickshell"

  if ! confirm "Restart Quickshell now to apply changes?"; then
    info "Skipping — restart manually:"
    printf "  ${DM}pkill -x quickshell; qs -c horizons &${RST}\n"
    return 0
  fi

  info "Stopping current Quickshell instance…"
  pkill -x quickshell 2>/dev/null || pkill -x qs 2>/dev/null || true
  sleep 1

  info "Starting Horizons…"
  local QS_BIN
  QS_BIN=$(command -v quickshell 2>/dev/null || command -v qs 2>/dev/null || echo "")
  if [[ -z "$QS_BIN" ]]; then
    err "quickshell binary not found. Start manually: qs -c horizons"
    return 1
  fi

  WAYLAND_DISPLAY="${WAYLAND_DISPLAY:-wayland-1}" \
    "$QS_BIN" -c horizons >/dev/null 2>&1 &

  sleep 2
  if pgrep -x quickshell &>/dev/null || pgrep -x qs &>/dev/null; then
    ok "Quickshell started successfully."
  else
    err "Quickshell may have failed to start. Check: $LOG_FILE"
  fi

  if command -v hyprctl &>/dev/null; then
    sleep 1
    hyprctl reload &>/dev/null || true
    ok "hyprctl reload done."
  fi
}

# ── Uninstall Horizons ─────────────────────────────────────────────────────────
do_uninstall(){
  step "Uninstall Horizons"

  warn "This will remove:"
  warn "  $QS_CONFIG_DIR"
  printf "\n"

  if ! confirm "Proceed with uninstall?"; then
    info "Uninstall cancelled."
    return 0
  fi

  if [[ -d "$QS_CONFIG_DIR" ]]; then
    local ubak="$HOME/horizons-uninstall-backup-$(date +%Y%m%d-%H%M%S)"
    run cp -r "$QS_CONFIG_DIR" "$ubak"
    ok "Backup saved to: $ubak"
    run rm -rf "$QS_CONFIG_DIR"
    ok "Removed $QS_CONFIG_DIR"
  else
    info "Nothing to remove — $QS_CONFIG_DIR not found."
  fi

  local vars_file="$XDG_CONFIG_HOME/hypr/hyprland/variables.lua"
  if [[ -f "$vars_file" ]] && grep -q '"horizons"' "$vars_file"; then
    warn "Hyprland still points to horizons."
    warn "Edit $vars_file and change qsConfig back to your preferred shell."
  fi

  ok "Uninstall complete."
}

# ── Summary ───────────────────────────────────────────────────────────────────
print_summary(){
  printf "\n"
  printf "${M}$(printf '%0.s─' $(seq 1 60))${RST}\n"
  printf "\n"
  if [[ $ERRORS -eq 0 ]]; then
    printf "${G}${BD}  ✦  Installation complete — no errors!${RST}\n"
  else
    printf "${Y}${BD}  ✦  Installation finished with %d warning(s)/error(s).${RST}\n" "$ERRORS"
    printf "${Y}  Check the log for details: ${UL}%s${RST}\n" "$LOG_FILE"
  fi
  printf "\n"
  printf "  ${C}${BD}Next steps:${RST}\n"
  printf "  ${C}•  Press ${IV} Super + Escape ${RST}${C} to open Settings${RST}\n"
  printf "  ${C}•  Press ${IV} Ctrl + Super + T ${RST}${C} to pick a wallpaper${RST}\n"
  printf "  ${C}•  Press ${IV} Super + / ${RST}${C} to see all keybinds${RST}\n"
  printf "  ${C}•  Log file: ${UL}%s${RST}\n" "$LOG_FILE"
  printf "\n"
  printf "  ${DM}${IT}Source: https://github.com/PROFFESSOR0x/end4-pC${RST}\n"
  printf "\n"
  printf "${M}$(printf '%0.s─' $(seq 1 60))${RST}\n"
  printf "\n"
}

# ── Safety: must not run as root ──────────────────────────────────────────────
if [[ "$(whoami)" == "root" ]]; then
  printf "${R}${BD}ERROR:${RST} Do not run this installer as root or with sudo.\n"
  exit 1
fi

# ═════════════════════════════════════════════════════════════════════════════
#  MAIN
# ═════════════════════════════════════════════════════════════════════════════
print_banner
detect_distro

info "Detected distro: ${BD}$DISTRO_NAME${RST}  (group: $PKG_GROUP)"
info "Repo root : $REPO_ROOT"
printf "\n"

if [[ "$DO_UNINSTALL" == true ]]; then
  do_uninstall
  exit 0
fi

if [[ "$ASK" == true ]]; then
  printf "  ${B}${BD}What this installer does:${RST}\n"
  printf "  ${DM}1.${RST}  Pre-flight checks (dependencies, Hyprland)\n"
  printf "  ${DM}2.${RST}  Migrate legacy illogical-impulse / end4-pC config, if found\n"
  printf "  ${DM}3.${RST}  Backup existing config (optional)\n"
  printf "  ${DM}4.${RST}  Run dotfiles base installer (dotfiles/setup install)\n"
  printf "  ${DM}5.${RST}  Build the hyprglass plugin\n"
  printf "  ${DM}6.${RST}  Copy the Horizons Quickshell config\n"
  printf "  ${DM}7.${RST}  Configure Hyprland to use Horizons\n"
  printf "  ${DM}8.${RST}  Add settings keybind\n"
  printf "  ${DM}9.${RST}  Restart Quickshell\n"
  printf "\n"

  if ! confirm "Ready to begin installation?"; then
    printf "  ${DM}Goodbye!${RST}\n\n"
    exit 0
  fi

  printf "\n"
  printf "  ${B}${BD}Confirmation mode:${RST}\n"
  printf "  ${B}y${RST} = Confirm each step  ${B}n${RST} = Auto-proceed all\n"
  printf "  ▸ "
  read -r p
  [[ "$p" == "n" || "$p" == "N" ]] && ASK=false
fi

STEPS_TOTAL=9
STEPS_DONE=0

_done(){ ((STEPS_DONE++)) || true; progress "$STEPS_DONE" "$STEPS_TOTAL" ""; printf "\n"; }

check_requirements;      _done
migrate_legacy_configs;  _done
do_backup;               _done
install_dots;            _done
build_hyprglass;         _done
install_qs;              _done
configure_hyprland;      _done
configure_keybind;       _done
restart_qs;              _done

print_summary
