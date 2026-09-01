#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║              end4-pC  ✦  Interactive Installer                              ║
# ║    A personal fork of illogical-impulse  ·  Powered by Quickshell          ║
# ╚══════════════════════════════════════════════════════════════════════════════╝
# Usage:  bash installer.sh [OPTIONS]
#   -h | --help          Show this help
#   -f | --force         Skip all confirmations (non-interactive)
#   -q | --quiet         Minimal output
#        --skip-deps     Skip dependency installation
#        --skip-dots     Skip dots-hyprland (base install)
#        --skip-qs       Skip Quickshell config install
#        --skip-backup   Skip config backup step
#        --uninstall     Remove end4-pC config only
# ─────────────────────────────────────────────────────────────────────────────
set -euo pipefail

# ── Colours & styles ──────────────────────────────────────────────────────────
R=$'\e[31m';  G=$'\e[32m';  Y=$'\e[33m';  B=$'\e[34m'
M=$'\e[35m';  C=$'\e[36m';  W=$'\e[37m'
BD=$'\e[1m';  DM=$'\e[2m';  IT=$'\e[3m';  UL=$'\e[4m';  BL=$'\e[5m'
IV=$'\e[7m';  RST=$'\e[0m'

# ── Paths ─────────────────────────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"       # End4-PXpC/
QS_REPO="$SCRIPT_DIR"                           # end4-pC/
DOTS_REPO="$REPO_ROOT/dots-hyprland"            # dots-hyprland/

XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
XDG_BIN_HOME="${XDG_BIN_HOME:-$HOME/.local/bin}"

QS_CONFIG_DIR="$XDG_CONFIG_HOME/quickshell/end4-pC"
BACKUP_DIR="$HOME/end4-pC-backup-$(date +%Y%m%d-%H%M%S)"
LOG_FILE="/tmp/end4-pC-install-$(date +%Y%m%d-%H%M%S).log"

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
      sed -n '2,9p' "$0" | sed 's/^# //'
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
  if eval "$@"; then
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
      r|R) eval "$@" && return 0 || { err "Still failed."; } ;;
      s|S) warn "Skipped."; return 0 ;;
      a|A) die "Aborted by user." ;;
    esac
  done
}

# ── Interactive confirmation ──────────────────────────────────────────────────
confirm(){
  # confirm "Message" [default=y]
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

# ── Spinner ───────────────────────────────────────────────────────────────────
spin(){
  local pid=$1 msg="$2"
  local frames=('⠋' '⠙' '⠹' '⠸' '⠼' '⠴' '⠦' '⠧' '⠇' '⠏')
  local i=0
  while kill -0 "$pid" 2>/dev/null; do
    printf "\r  ${C}${frames[$((i % ${#frames[@]}))]}${RST}  %s " "$msg"
    sleep 0.1
    ((i++))
  done
  printf "\r  ${G}✔${RST}  %-50s\n" "$msg"
}

# ── Progress bar ──────────────────────────────────────────────────────────────
progress(){
  local current=$1 total=$2 label="${3:-}"
  local width=40
  local filled=$(( current * width / total ))
  local empty=$(( width - filled ))
  local bar="${G}$(printf '%0.s█' $(seq 1 $filled))${DM}$(printf '%0.s░' $(seq 1 $empty))${RST}"
  printf "\r  [%b] %3d%% %s" "$bar" "$(( current * 100 / total ))" "$label"
}

# ── Fancy banner ──────────────────────────────────────────────────────────────
print_banner(){
  clear
  printf "\n"
  printf "${M}${BD}"
  printf "  ███████╗███╗   ██╗██████╗ ██╗  ██╗      ██████╗  ██████╗\n"
  printf "  ██╔════╝████╗  ██║██╔══██╗██║  ██║      ██╔══██╗██╔════╝\n"
  printf "  █████╗  ██╔██╗ ██║██║  ██║███████║█████╗██████╔╝██║     \n"
  printf "  ██╔══╝  ██║╚██╗██║██║  ██║╚════██║╚════╝██╔═══╝ ██║     \n"
  printf "  ███████╗██║ ╚████║██████╔╝     ██║      ██║     ╚██████╗\n"
  printf "  ╚══════╝╚═╝  ╚═══╝╚═════╝      ╚═╝      ╚═╝      ╚═════╝\n"
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

# ── Distro detection ─────────────────────────────────────────────────────────
detect_distro(){
  if [[ -f /etc/os-release ]]; then
    # shellcheck source=/dev/null
    source /etc/os-release
    DISTRO_ID="${ID:-unknown}"
    DISTRO_LIKE="${ID_LIKE:-}"
    DISTRO_NAME="${PRETTY_NAME:-$ID}"
  else
    DISTRO_ID="unknown"
    DISTRO_LIKE=""
    DISTRO_NAME="Unknown"
  fi

  case "$DISTRO_ID" in
    arch|cachyos|endeavouros|manjaro|garuda) PKG_GROUP="arch" ;;
    fedora|nobara)                           PKG_GROUP="fedora" ;;
    *)
      if echo "$DISTRO_LIKE" | grep -qi "arch"; then   PKG_GROUP="arch"
      elif echo "$DISTRO_LIKE" | grep -qi "fedora"; then PKG_GROUP="fedora"
      else PKG_GROUP="unknown"
      fi ;;
  esac
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
      ((ok_count++))
    else
      printf "${R}✖ missing${RST}\n"
      ((fail_count++))
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
  _chk "dots-hyprland"    "[[ -d '$DOTS_REPO' ]]"

  printf "\n"
  printf "  Checks: ${G}%d OK${RST}  ${R}%d missing${RST}\n" "$ok_count" "$fail_count"

  if [[ $fail_count -gt 0 ]]; then
    warn "Some requirements are missing."
    warn "end4-pC requires illogical-impulse (dots-hyprland) to be installed first."
    warn "See: https://github.com/end-4/dots-hyprland"
    if ! confirm "Continue anyway?"; then
      die "Aborting — please install missing requirements first."
    fi
  else
    ok "All requirements satisfied."
  fi
}

# ── Backup existing configs ────────────────────────────────────────────────────
do_backup(){
  [[ "$SKIP_BACKUP" == true ]] && return 0
  step "Backup existing configs"

  local targets=(
    "$QS_CONFIG_DIR"
  )
  local has_any=false
  for t in "${targets[@]}"; do
    [[ -e "$t" ]] && has_any=true && break
  done

  if [[ "$has_any" == false ]]; then
    info "Nothing to backup — fresh install detected."
    return 0
  fi

  warn "Existing end4-pC config detected at:"
  warn "  $QS_CONFIG_DIR"
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

# ── Install dots-hyprland (base) ─────────────────────────────────────────────
install_dots(){
  [[ "$SKIP_DOTS" == true ]] && { info "Skipping dots-hyprland (--skip-dots)"; return 0; }
  step "Install dots-hyprland (base)"

  if [[ ! -d "$DOTS_REPO" ]]; then
    warn "dots-hyprland not found at: $DOTS_REPO"
    if confirm "Clone dots-hyprland now?"; then
      run git clone --depth=1 \
        https://github.com/end-4/dots-hyprland.git \
        "$DOTS_REPO"
    else
      warn "Skipping base install — end4-pC may not work without it."
      return 0
    fi
  else
    ok "dots-hyprland found at $DOTS_REPO"
    if confirm "Run dots-hyprland installer (recommended on first install)?"; then
      local installer="$DOTS_REPO/install.sh"
      [[ -f "$installer" ]] || installer="$DOTS_REPO/setup.sh"
      if [[ -f "$installer" ]]; then
        info "Launching: $installer"
        info "You can pass --force or other flags inside the installer."
        printf "\n"
        # Let the user interact with the upstream installer
        bash "$installer"
      else
        warn "No installer found in dots-hyprland. Skipping."
      fi
    else
      info "Skipping dots-hyprland installer."
    fi
  fi
}

# ── Install end4-pC Quickshell config ─────────────────────────────────────────
install_qs(){
  [[ "$SKIP_QS" == true ]] && { info "Skipping Quickshell config (--skip-qs)"; return 0; }
  step "Install end4-pC Quickshell config"

  info "Source : $QS_REPO"
  info "Target : $QS_CONFIG_DIR"
  printf "\n"

  if ! confirm "Copy end4-pC config to $QS_CONFIG_DIR?"; then
    warn "Skipping Quickshell config install."
    return 0
  fi

  run mkdir -p "$QS_CONFIG_DIR"

  # rsync with progress
  info "Syncing files…"
  local total
  total=$(find "$QS_REPO" -not -path "*/.git/*" -not -name ".git" | wc -l)
  local copied=0

  rsync -av --delete \
    --exclude='.git' \
    --exclude='installer.sh' \
    --out-format='%n' \
    "$QS_REPO/" "$QS_CONFIG_DIR/" | while IFS= read -r line; do
      ((copied++)) || true
      progress "$copied" "$total" "$line"
    done
  printf "\n"

  ok "Quickshell config installed."
}

# ── Configure Hyprland to use end4-pC ─────────────────────────────────────────
configure_hyprland(){
  step "Configure Hyprland shell"

  # Detect current qsConfig value
  local vars_file="$XDG_CONFIG_HOME/hypr/hyprland/variables.lua"
  local current_qs="(not detected)"

  if [[ -f "$vars_file" ]]; then
    current_qs=$(grep -oP 'qsConfig[^"]*"\K[^"]+' "$vars_file" 2>/dev/null || echo "not set")
    info "Current qsConfig: ${BD}$current_qs${RST}"
  else
    warn "Hyprland variables.lua not found at $vars_file"
    warn "You may need to configure Hyprland manually."
    return 0
  fi

  if [[ "$current_qs" == "end4-pC" ]]; then
    ok "Already set to end4-pC — no changes needed."
    return 0
  fi

  printf "\n"
  printf "  ${B}Set Hyprland to use end4-pC as the shell?${RST}\n"
  printf "  ${DM}(Changes %s)${RST}\n" "$vars_file"
  printf "  ${DM}Current value: ${Y}%s${RST}\n" "$current_qs"
  printf "\n"

  if confirm "Change qsConfig to 'end4-pC'?"; then
    # Backup the file first
    run cp "$vars_file" "${vars_file}.bak"
    run sed -i "s|hl.env(\"qsConfig\", \"[^\"]*\")|hl.env(\"qsConfig\", \"end4-pC\")|" "$vars_file"
    ok "qsConfig updated to end4-pC."
    ok "Backup saved to: ${vars_file}.bak"
  else
    info "Skipping — you can set it manually later:"
    printf "  ${DM}Edit: %s${RST}\n" "$vars_file"
    printf "  ${DM}Set:  hl.env(\"qsConfig\", \"end4-pC\")${RST}\n"
  fi
}

# ── Add settings keybind ──────────────────────────────────────────────────────
configure_keybind(){
  step "Settings keybind"

  local keybind_line='hl.bind("SUPER + escape", hl.dsp.global("quickshell:settingsToggle"), {description = "Toggle settings"})'
  local custom_dir="$XDG_CONFIG_HOME/hypr/custom"
  local keybind_file="$custom_dir/keybinds.lua"

  # Check if already configured anywhere in hypr config
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
      printf "\n-- end4-pC settings panel toggle\n"
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
    printf "  ${DM}pkill -x quickshell; qs -c end4-pC &${RST}\n"
    return 0
  fi

  info "Stopping current Quickshell instance…"
  pkill -x quickshell 2>/dev/null || pkill -x qs 2>/dev/null || true
  sleep 1

  info "Starting end4-pC…"
  local QS_BIN
  QS_BIN=$(command -v quickshell 2>/dev/null || command -v qs 2>/dev/null || "")
  if [[ -z "$QS_BIN" ]]; then
    err "quickshell binary not found. Start manually: qs -c end4-pC"
    return 1
  fi

  WAYLAND_DISPLAY="${WAYLAND_DISPLAY:-wayland-1}" \
    "$QS_BIN" -c end4-pC >/dev/null 2>&1 &

  sleep 2
  if pgrep -x quickshell &>/dev/null || pgrep -x qs &>/dev/null; then
    ok "Quickshell started successfully."
  else
    err "Quickshell may have failed to start. Check: $LOG_FILE"
  fi

  # Reload Hyprland
  if command -v hyprctl &>/dev/null; then
    sleep 1
    hyprctl reload &>/dev/null || true
    ok "hyprctl reload done."
  fi
}

# ── Uninstall end4-pC ─────────────────────────────────────────────────────────
do_uninstall(){
  step "Uninstall end4-pC"

  warn "This will remove:"
  warn "  $QS_CONFIG_DIR"
  printf "\n"

  if ! confirm "Proceed with uninstall?"; then
    info "Uninstall cancelled."
    return 0
  fi

  # Backup before removing
  if [[ -d "$QS_CONFIG_DIR" ]]; then
    local ubak="$HOME/end4-pC-uninstall-backup-$(date +%Y%m%d-%H%M%S)"
    run cp -r "$QS_CONFIG_DIR" "$ubak"
    ok "Backup saved to: $ubak"
    run rm -rf "$QS_CONFIG_DIR"
    ok "Removed $QS_CONFIG_DIR"
  else
    info "Nothing to remove — $QS_CONFIG_DIR not found."
  fi

  # Suggest reverting Hyprland config
  local vars_file="$XDG_CONFIG_HOME/hypr/hyprland/variables.lua"
  if [[ -f "$vars_file" ]] && grep -q '"end4-pC"' "$vars_file"; then
    warn "Hyprland still points to end4-pC."
    warn "Edit $vars_file and change qsConfig back to 'ii'."
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
  printf "  ${DM}${IT}Source: https://github.com/pctrade/end4-pC${RST}\n"
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

# Uninstall path
if [[ "$DO_UNINSTALL" == true ]]; then
  do_uninstall
  exit 0
fi

# ── Interactive mode welcome ──────────────────────────────────────────────────
if [[ "$ASK" == true ]]; then
  printf "  ${B}${BD}What this installer does:${RST}\n"
  printf "  ${DM}1.${RST}  Pre-flight checks (dependencies, Hyprland)\n"
  printf "  ${DM}2.${RST}  Backup existing config (optional)\n"
  printf "  ${DM}3.${RST}  Run dots-hyprland base installer (optional)\n"
  printf "  ${DM}4.${RST}  Copy end4-pC Quickshell config\n"
  printf "  ${DM}5.${RST}  Configure Hyprland to use end4-pC\n"
  printf "  ${DM}6.${RST}  Add settings keybind\n"
  printf "  ${DM}7.${RST}  Restart Quickshell\n"
  printf "\n"
  printf "  ${Y}${BD}Note:${RST}${Y} end4-pC requires dots-hyprland to be installed first.${RST}\n"
  printf "  ${Y}It does NOT replace your Hyprland config — it only adds a Quickshell shell.${RST}\n"
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

# ── Run phases ────────────────────────────────────────────────────────────────
STEPS_TOTAL=7
STEPS_DONE=0

_done(){ ((STEPS_DONE++)) || true; progress "$STEPS_DONE" "$STEPS_TOTAL" ""; printf "\n"; }

check_requirements;    _done
do_backup;             _done
install_dots;          _done
install_qs;            _done
configure_hyprland;    _done
configure_keybind;     _done
restart_qs;            _done

print_summary
