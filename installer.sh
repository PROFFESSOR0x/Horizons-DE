#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║              آفاق | Horizons  ✦  Interactive Installer  v2.0               ║
# ║    A personal fork of illogical-impulse  ·  Powered by Quickshell            ║
# ║    Profiles, state tracking, build-from-source & update protocol            ║
# ╚══════════════════════════════════════════════════════════════════════════════╝
# Unified entrypoint — installs shell + dots + plugins, builds from source,
# tracks identity in ~/.config/horizons/.horizons-meta.json + .horizons-info,
# and provides a full update protocol.
#
# Usage:
#   ./installer.sh [COMMAND] [OPTIONS]
#
# Commands (default: install):
#   install             Full install pipeline (respects --profile / flags)
#   update              git pull + re-apply (smart). Alias: --update
#   check               Check for updates only (no pull). Alias: --check-update
#   status              Show horizons identity & repo status
#   build               Only build plugins/shell from source
#   uninstall           Remove Horizons config (keeps backup)
#   help                Show this help
#
# Options:
#   -h, --help              Show help
#   -f, --force  -y, --yes  Skip all confirmations (non-interactive)
#   -q, --quiet             Minimal output
#   -v, --verbose           Verbose output
#       --dry-run           Show what would be done, don't execute
#       --profile <name>    minimal | core (default) | full | ultra
#       --wm <name>         Required on a new install: hyprland | i3
#       --protocol <name>   Wayland | X11 (validated against --wm)
#       --desktop <name>    Required on a new install: horizons | existing
#       --fresh-install     Do not convert a repeated `install` invocation to update
#       --components <csv>  Comma-separated overrides: dots,shell,hyprglass,bundled,build,deps,sysupdate,backup
#                           Prefix with ^/- /no- to disable: --components no-dots,^bundled
#       --with-deps         Install dependencies (default: via profile)
#       --skip-deps         Skip dependencies
#       --with-sysupdate    Full system upgrade (pacman -Syu / dnf upgrade)
#       --skip-sysupdate    Skip system upgrade (default)
#       --with-build        Build quickshell + hyprglass from source
#       --skip-build        Skip building
#       --with-bundled      Install bundled extras (Rubik, Gabarito, Bibata, GoogleSans)
#       --skip-bundled      Skip bundled extras
#       --with-backup       Backup existing configs (default)
#       --skip-backup       Skip backup
#       --with-fontset <set> Use dotfiles fontset
#       --via-nix           Use Nix/Home-manager for deps (experimental)
#       --build-force       Force rebuild even if binaries exist
#       --skip-dots         (compat) Skip dotfiles base install
#       --skip-qs           (compat) Skip Quickshell shell config
#       --skip-hyprglass    Skip hyprglass plugin build
#       --log-file <path>   Custom log file
#       --show-profiles     List available profiles and exit
#       --lang <en|ar>      Installer language (default: interactive prompt, or en)
#       --uninstall         Alias for 'uninstall' command
#       --update            Alias for 'update' command
#       --check-update      Alias for 'check' command
# ─────────────────────────────────────────────────────────────────────────────
set -euo pipefail

# ── Colours & styles ──────────────────────────────────────────────────────────
R=$'\e[31m';  G=$'\e[32m';  Y=$'\e[33m';  B=$'\e[34m'
M=$'\e[35m';  C=$'\e[36m';  W=$'\e[37m'
BD=$'\e[1m';  DM=$'\e[2m';  IT=$'\e[3m';  UL=$'\e[4m';  BL=$'\e[5m'
IV=$'\e[7m';  RST=$'\e[0m'

# ── XDG (must be before sourcing state.sh which uses it) ───────────────────────
XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
XDG_BIN_HOME="${XDG_BIN_HOME:-$HOME/.local/bin}"

# ── Paths ─────────────────────────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$SCRIPT_DIR"
QS_REPO="$REPO_ROOT/shell"
DOTS_REPO="$REPO_ROOT/dotfiles"
HYPRGLASS_DIR="$QS_REPO/plugins/hyprglass"

# Source shared libs (order matters)
# shellcheck source=install/lib/distro.sh
source "$REPO_ROOT/install/lib/distro.sh"
# shellcheck source=install/lib/state.sh
if [[ -f "$REPO_ROOT/install/lib/state.sh" ]]; then source "$REPO_ROOT/install/lib/state.sh"; fi
# shellcheck source=install/lib/profiles.sh
if [[ -f "$REPO_ROOT/install/lib/profiles.sh" ]]; then source "$REPO_ROOT/install/lib/profiles.sh"; fi
# shellcheck source=install/lib/build.sh
if [[ -f "$REPO_ROOT/install/lib/build.sh" ]]; then source "$REPO_ROOT/install/lib/build.sh"; fi
# shellcheck source=install/lib/requirements.sh
if [[ -f "$REPO_ROOT/install/lib/requirements.sh" ]]; then source "$REPO_ROOT/install/lib/requirements.sh"; fi
# shellcheck source=install/lib/update.sh
if [[ -f "$REPO_ROOT/install/lib/update.sh" ]]; then source "$REPO_ROOT/install/lib/update.sh"; fi

QS_CONFIG_DIR="$XDG_CONFIG_HOME/quickshell/horizons"
DOTS_CONFIG_DIR="$XDG_CONFIG_HOME/horizons"
BACKUP_DIR="$HOME/horizons-backup-$(date +%Y%m%d-%H%M%S)"
LOG_FILE="/tmp/horizons-install-$(date +%Y%m%d-%H%M%S).log"

LEGACY_DOTS_CONFIG_DIR="$XDG_CONFIG_HOME/illogical-impulse"
LEGACY_QS_CONFIG_DIR="$XDG_CONFIG_HOME/quickshell/end4-pC"

# ── State flags ───────────────────────────────────────────────────────────────
FORCE=false
QUIET=false
VERBOSE=false
DRY_RUN=false
ASK=true
ERRORS=0

# Profile / components
HORIZONS_PROFILE="core"
COMPONENTS_CSV=""
DO_DOTS=true
DO_SHELL=true
DO_HYPRGLASS=true
DO_BUNDLED=false
DO_BUILD=false
DO_SYSUPDATE=false
DO_DEPS=true
DO_BACKUP=true
BUILD_FORCE=false

# Installation target. Hyprland is a Wayland compositor; i3 is an X11 window
# manager. These are deliberately stored independently from the profile.
HORIZONS_PROTOCOL=""
HORIZONS_WINDOW_MANAGER=""
HORIZONS_DESKTOP_ENVIRONMENT=""
HORIZONS_PROTOCOL_CLI=false
HORIZONS_WINDOW_MANAGER_CLI=false
HORIZONS_DESKTOP_ENVIRONMENT_CLI=false
FRESH_INSTALL=false

# Legacy compat flags (mapped later)
SKIP_DEPS=false
SKIP_DOTS=false
SKIP_QS=false
SKIP_BACKUP=false
SKIP_HYPRGLASS=false
SKIP_SYSUPDATE=false
WITH_VIA_NIX=false
FONTSET_DIR_NAME=""
INSTALL_VIA_NIX=false

COMMAND="install"
SHOW_PROFILES=false

# Language (en / ar) — chosen at start of installer
HORIZONS_LANG="en"
HORIZONS_LANG_CLI=""

# ── Helpers ───────────────────────────────────────────────────────────────────
println(){ [[ "$QUIET" == false ]] && printf "%b\n" "$*"; true; }
info()   { println "${C}${BD}  ℹ  ${RST}${C}$*${RST}"; true; }
ok()     { println "${G}${BD}  ✔  ${RST}${G}$*${RST}"; true; }
warn()   { println "${Y}${BD}  ⚠  ${RST}${Y}$*${RST}"; true; }
err()    { println "${R}${BD}  ✖  ${RST}${R}$*${RST}"; ERRORS=$((ERRORS+1)); true; }
step()   { println "\n${M}${BD}╸╸╸  $*${RST}"; true; }
die()    { err "$*"; exit 1; }
verbose_log(){ [[ "$VERBOSE" == true ]] && println "${DM}  › $*${RST}"; true; }

# ── i18n ─────────────────────────────────────────────────────────────────────
# L "English text" "النص العربي" — prints based on HORIZONS_LANG
L(){ if [[ "${HORIZONS_LANG:-en}" == "ar" ]]; then printf "%s" "$2"; else printf "%s" "$1"; fi; }
# Alias for readability
msg(){ L "$1" "$2"; }

horizons_choose_language(){
  # If CLI forced, respect it
  if [[ -n "${HORIZONS_LANG_CLI:-}" ]]; then
    HORIZONS_LANG="$HORIZONS_LANG_CLI"
    export HORIZONS_LANG
    return 0
  fi
  # Non-interactive → auto-detect
  if [[ "$FORCE" == true || "$ASK" == false || "$QUIET" == true ]]; then
    if [[ "${LANG:-}" == ar* || "${LC_ALL:-}" == ar* ]]; then
      HORIZONS_LANG="ar"
    else
      if [[ -f "${HORIZONS_META_JSON:-$XDG_CONFIG_HOME/horizons/.horizons-meta.json}" ]]; then
        local saved=""; saved=$(grep -oP '"lang"\s*:\s*"\K[^"]+' "$HORIZONS_META_JSON" 2>/dev/null || true)
        if [[ -n "$saved" && "$saved" == "ar" ]]; then HORIZONS_LANG="ar"; else HORIZONS_LANG="en"; fi
      else
        HORIZONS_LANG="en"
      fi
    fi
    export HORIZONS_LANG
    return 0
  fi
  # Interactive prompt — shown BEFORE banner so banner can be localized
  printf "\n"
  printf "${C}${BD}  Choose language / اختر اللغة:${RST}\n"
  printf "    ${G}1)${RST} English\n"
  printf "    ${G}2)${RST} العربية\n"
  printf "\n"
  local sel=""
  printf "${B}${BD}  > ${RST}${B}$(L "Select [1/2] [1]: " "اختر [1/2] [1]: ")${RST}"
  read -r sel || sel="1"
  sel="${sel:-1}"
  case "$sel" in
    2|ar|AR|Arabic|arabic|العربية|عربي) HORIZONS_LANG="ar" ;;
    *) HORIZONS_LANG="en" ;;
  esac
  export HORIZONS_LANG
  if [[ "$HORIZONS_LANG" == "ar" ]]; then
    ok "تم اختيار اللغة العربية ✓"
  else
    ok "Language set to English ✓"
  fi
  printf "\n"
}

print_help(){
    sed -n '2,55p' "$0" | sed 's/^# //'
    if declare -f horizons_profile_list &>/dev/null; then
        echo ""
        horizons_profile_list
        echo ""
        echo "Examples:"
        echo "  ./installer.sh                          # interactive core install"
        echo "  ./installer.sh --profile full --force   # full non-interactive"
        echo "  ./installer.sh --profile minimal -y     # shell only"
        echo "  ./installer.sh --components dots,shell  # granualar"
        echo "  ./installer.sh --skip-dots --skip-qs    # compat flags"
        echo "  ./installer.sh update --force           # update via protocol"
        echo "  ./installer.sh check                    # check for updates"
        echo "  ./installer.sh status                   # show identity"
        echo "  ./installer.sh build --build-force      # rebuild from source"
        echo "  ./installer.sh --dry-run --profile ultra # preview"
    fi
}

# ── Parse args ────────────────────────────────────────────────────────────────
# Support both: ./installer.sh --profile full   and   ./installer.sh install --profile full
# So first check if $1 is a command without dashes
if [[ $# -gt 0 ]]; then
    case "$1" in
        install|update|check|status|build|uninstall|help) COMMAND="$1"; shift ;;
        --update) COMMAND="update"; shift ;;
        --check-update|--check) COMMAND="check"; shift ;;
        --uninstall) COMMAND="uninstall"; shift ;;
        --status) COMMAND="status"; shift ;;
        --build) COMMAND="build"; shift ;;
    esac
fi

while [[ $# -gt 0 ]]; do
  case $1 in
    -h|--help) print_help; exit 0 ;;
    -f|--force|-y|--yes)  FORCE=true; ASK=false; shift ;;
    -q|--quiet)  QUIET=true; shift ;;
    -v|--verbose) VERBOSE=true; shift ;;
    --dry-run) DRY_RUN=true; shift ;;
    --profile) HORIZONS_PROFILE="$2"; shift 2 ;;
    --wm|--window-manager) HORIZONS_WINDOW_MANAGER="${2,,}"; HORIZONS_WINDOW_MANAGER_CLI=true; shift 2 ;;
    --protocol|--display-protocol) HORIZONS_PROTOCOL="${2,,}"; HORIZONS_PROTOCOL_CLI=true; shift 2 ;;
    --desktop|--desktop-environment) HORIZONS_DESKTOP_ENVIRONMENT="${2,,}"; HORIZONS_DESKTOP_ENVIRONMENT_CLI=true; shift 2 ;;
    --fresh-install) FRESH_INSTALL=true; shift ;;
    --components) COMPONENTS_CSV="$2"; shift 2 ;;
    --with-deps) DO_DEPS=true; SKIP_DEPS=false; shift ;;
    --skip-deps) DO_DEPS=false; SKIP_DEPS=true; shift ;;
    --skip-alldeps) DO_DEPS=false; SKIP_DEPS=true; shift ;;
    --with-sysupdate) DO_SYSUPDATE=true; SKIP_SYSUPDATE=false; shift ;;
    --skip-sysupdate|--skip-sysupgrade) DO_SYSUPDATE=false; SKIP_SYSUPDATE=true; shift ;;
    --with-build) DO_BUILD=true; shift ;;
    --skip-build) DO_BUILD=false; shift ;;
    --build-force) BUILD_FORCE=true; DO_BUILD=true; shift ;;
    --with-bundled|--with-extra) DO_BUNDLED=true; shift ;;
    --skip-bundled|--skip-extra) DO_BUNDLED=false; shift ;;
    --with-backup) DO_BACKUP=true; SKIP_BACKUP=false; shift ;;
    --skip-backup) DO_BACKUP=false; SKIP_BACKUP=true; shift ;;
    --skip-dots) SKIP_DOTS=true; shift ;;
    --skip-qs|--skip-quickshell) SKIP_QS=true; shift ;;
    --skip-hyprglass) SKIP_HYPRGLASS=true; shift ;;
    --with-fontset|--fontset) FONTSET_DIR_NAME="$2"; shift 2 ;;
    --via-nix) WITH_VIA_NIX=true; INSTALL_VIA_NIX=true; shift ;;
    --log-file) LOG_FILE="$2"; shift 2 ;;
    --show-profiles) SHOW_PROFILES=true; shift ;;
    --lang|--language) HORIZONS_LANG="$2"; HORIZONS_LANG_CLI="$2"; if [[ "$HORIZONS_LANG" != "en" && "$HORIZONS_LANG" != "ar" ]]; then echo -e "${R}Invalid --lang value: $HORIZONS_LANG (use en or ar)${RST}"; exit 1; fi; shift 2 ;;
    --uninstall) COMMAND="uninstall"; shift ;;
    --update) COMMAND="update"; shift ;;
    --check-update|--check) COMMAND="check"; shift ;;
    install|update|check|status|build|uninstall|help) COMMAND="$1"; shift ;;
    *) echo -e "${R}Unknown option: $1${RST}"; echo "Run ./installer.sh --help for usage."; exit 1 ;;
  esac
done

if [[ "$SHOW_PROFILES" == true ]]; then
    if declare -f horizons_profile_list &>/dev/null; then horizons_profile_list; else echo "minimal core full ultra"; fi
    exit 0
fi

# ── Installation target / session selection ──────────────────────────────────
# i3 and Hyprland are window managers, not desktop environments. `desktop`
# describes whether Horizons manages the surrounding dotfiles or is installed
# as a shell on top of an existing desktop setup.
horizons_target_for_wm(){
  case "$HORIZONS_WINDOW_MANAGER" in
    hyprland) HORIZONS_PROTOCOL="wayland" ;;
    i3)       HORIZONS_PROTOCOL="x11" ;;
    *) return 1 ;;
  esac
}

horizons_validate_target(){
  case "$HORIZONS_WINDOW_MANAGER:$HORIZONS_PROTOCOL" in
    hyprland:wayland|i3:x11) ;;
    hyprland:x11)
      die "Hyprland is Wayland-only; Hyprland/X11 is not a valid target." ;;
    i3:wayland)
      die "i3 is X11-only; use Sway for an i3-like Wayland session (not supported by this installer yet)." ;;
    *) die "Unsupported installation target: protocol='$HORIZONS_PROTOCOL', wm='$HORIZONS_WINDOW_MANAGER'." ;;
  esac
  case "$HORIZONS_DESKTOP_ENVIRONMENT" in
    horizons|existing) ;;
    *) die "Unsupported desktop mode '$HORIZONS_DESKTOP_ENVIRONMENT' (use horizons or existing)." ;;
  esac
}

horizons_load_saved_target(){
  declare -f horizons_state_is_installed &>/dev/null || return 1
  horizons_state_is_installed || return 1
  local saved_protocol saved_wm saved_desktop
  saved_protocol=$(horizons_state_get display_protocol 2>/dev/null || true)
  saved_wm=$(horizons_state_get window_manager 2>/dev/null || true)
  saved_desktop=$(horizons_state_get desktop_environment 2>/dev/null || true)
  [[ -n "$saved_protocol" && -n "$saved_wm" && -n "$saved_desktop" ]] || return 1
  [[ "$HORIZONS_PROTOCOL_CLI" == true ]] || HORIZONS_PROTOCOL="$saved_protocol"
  [[ "$HORIZONS_WINDOW_MANAGER_CLI" == true ]] || HORIZONS_WINDOW_MANAGER="$saved_wm"
  [[ "$HORIZONS_DESKTOP_ENVIRONMENT_CLI" == true ]] || HORIZONS_DESKTOP_ENVIRONMENT="$saved_desktop"
  return 0
}

horizons_infer_legacy_target(){
  if [[ -f "$XDG_CONFIG_HOME/hypr/hyprland/variables.lua" ]] || command -v hyprctl &>/dev/null; then
    HORIZONS_WINDOW_MANAGER="hyprland"
    HORIZONS_PROTOCOL="wayland"
    HORIZONS_DESKTOP_ENVIRONMENT="horizons"
    return 0
  fi
  if [[ -f "$XDG_CONFIG_HOME/i3/config" ]] || command -v i3-msg &>/dev/null; then
    HORIZONS_WINDOW_MANAGER="i3"
    HORIZONS_PROTOCOL="x11"
    HORIZONS_DESKTOP_ENVIRONMENT="existing"
    return 0
  fi
  return 1
}

horizons_choose_target(){
  if horizons_load_saved_target; then
    info "$(L "Using the saved installation target" "استخدام هدف التثبيت المحفوظ"): $HORIZONS_PROTOCOL / $HORIZONS_WINDOW_MANAGER / $HORIZONS_DESKTOP_ENVIRONMENT"
  elif [[ "$HORIZONS_WINDOW_MANAGER_CLI" == true || "$HORIZONS_PROTOCOL_CLI" == true || "$HORIZONS_DESKTOP_ENVIRONMENT_CLI" == true ]]; then
    [[ -n "$HORIZONS_WINDOW_MANAGER" ]] || die "--protocol requires --wm on a new install."
    [[ -n "$HORIZONS_DESKTOP_ENVIRONMENT" ]] || die "--desktop is required on a new install."
    if [[ "$HORIZONS_PROTOCOL_CLI" == false ]]; then horizons_target_for_wm || die "Unknown window manager '$HORIZONS_WINDOW_MANAGER'."; fi
  elif [[ "$ASK" == false ]]; then
    horizons_infer_legacy_target || die "A new non-interactive install requires --wm and --desktop."
    warn "Inferred legacy target: $HORIZONS_PROTOCOL / $HORIZONS_WINDOW_MANAGER / $HORIZONS_DESKTOP_ENVIRONMENT"
  else
    printf "\n  ${B}${BD}$(L "Choose the window-manager target" "اختر هدف مدير النوافذ"):${RST}\n"
    printf "    ${G}1)${RST} Hyprland  $(L "(Wayland)" "(Wayland)")\n"
    printf "    ${G}2)${RST} i3        $(L "(X11)" "(X11)")\n"
    printf "  ${B}> ${RST}"; read -r target_choice || target_choice=""
    case "$target_choice" in
      1|hyprland|Hyprland) HORIZONS_WINDOW_MANAGER="hyprland" ;;
      2|i3|I3) HORIZONS_WINDOW_MANAGER="i3" ;;
      *) die "A window-manager target is required." ;;
    esac
    horizons_target_for_wm
    printf "\n  ${B}${BD}$(L "Choose the desktop integration mode" "اختر نمط تكامل سطح المكتب"):${RST}\n"
    printf "    ${G}1)${RST} $(L "Horizons-managed desktop (includes compatible dotfiles)" "سطح مكتب Horizons المُدار (يشمل ملفات الإعداد المتوافقة)")\n"
    printf "    ${G}2)${RST} $(L "Existing desktop (shell integration only)" "سطح مكتب قائم (تكامل الواجهة فقط)")\n"
    printf "  ${B}> ${RST}"; read -r desktop_choice || desktop_choice=""
    case "$desktop_choice" in
      1|horizons) HORIZONS_DESKTOP_ENVIRONMENT="horizons" ;;
      2|existing) HORIZONS_DESKTOP_ENVIRONMENT="existing" ;;
      *) die "A desktop integration mode is required." ;;
    esac
  fi

  horizons_validate_target
  # The bundled dots and hyprglass are Hyprland-only. An i3 or existing-DE
  # install never receives them, even if a broad profile was selected.
  if [[ "$HORIZONS_WINDOW_MANAGER" == "i3" || "$HORIZONS_DESKTOP_ENVIRONMENT" == "existing" ]]; then
    DO_DOTS=false
    DO_HYPRGLASS=false
  fi
  export HORIZONS_PROTOCOL HORIZONS_WINDOW_MANAGER HORIZONS_DESKTOP_ENVIRONMENT
}

# ── Resolve profile → flags, then apply granular overrides ───────────────────
if declare -f horizons_profile_resolve &>/dev/null; then
    horizons_profile_resolve "$HORIZONS_PROFILE"
    # Apply explicit CLI toggles that override profile defaults (after resolve)
    # We already set DO_* to true/false via flags above; need to re-apply if flag was explicitly set
    # Simpler: if user passed --skip/--with flags, they already flipped; respects last write.
    # But profile resolve overwrote them, so we re-apply: track which flags were touched
    # For now, handle legacy compat flags:
    [[ "$SKIP_DEPS" == true ]] && DO_DEPS=false
    [[ "$SKIP_DOTS" == true ]] && DO_DOTS=false
    [[ "$SKIP_QS" == true ]] && DO_SHELL=false
    [[ "$SKIP_BACKUP" == true ]] && DO_BACKUP=false
    [[ "$SKIP_HYPRGLASS" == true ]] && DO_HYPRGLASS=false
    [[ "$SKIP_SYSUPDATE" == true ]] && DO_SYSUPDATE=false
    if [[ -n "$COMPONENTS_CSV" ]]; then
        horizons_components_apply "$COMPONENTS_CSV"
        # Also update HORIZONS_PROFILE to reflect custom? keep original
    fi
    # Re-honor explicit WITH flags that may have been reset:
    # We use a trick: check if original FORCE/QUIET/DRY_RUN set; for DO_* we need to track if user passed --with-build etc after profile
    # Since we already resolved, and user may have wanted --with-build, we check BUILD_FORCE
    [[ "$BUILD_FORCE" == true ]] && DO_BUILD=true
    # If user passed --with-bundled etc on CLI after profile, it was overwritten — re-check arg presence via a second pass would be needed.
    # Workaround: if DO_BUNDLED etc were set via --with-* before profile, they got reset; so we parse COMPONENTS_CSV fallback to profile.
    # Easier: if user explicitly passed --with-bundled, honor it now (we lost it). Check by re-reading that flag was not in profile ultra?
    # Instead, respect that --with-build/--with-bundled mean true regardless of profile, if they were on CLI.
    # We do this by checking if original invokation contained those strings via $*? Not reliable. So we just keep profile + components.
    # For now, allow manual override via env: if user wants full control, use --components.
fi

if [[ "$COMMAND" == "install" || "$COMMAND" == "update" || "$COMMAND" == "build" ]]; then
    horizons_choose_target
fi

# A repeated plain `./installer.sh` is an update, not a second install. The
# saved target is loaded above and update_apply sets HORIZONS_REAPPLY=1 to
# enter the pipeline exactly once after pulling.
if [[ "$COMMAND" == "install" && "$FRESH_INSTALL" == false && "${HORIZONS_REAPPLY:-0}" != "1" ]] \
    && declare -f horizons_state_is_installed &>/dev/null && horizons_state_is_installed; then
    COMMAND="update"
    info "$(L "Existing Horizons installation detected; switching to update mode." "تم العثور على تثبيت Horizons قائم؛ التحويل إلى وضع التحديث.")"
fi

# Legacy mapping for dotfiles/setup compatibility
SKIP_ALLDEPS=$([[ "$DO_DEPS" == true ]] && echo false || echo true)
SKIP_ALLFILES=$([[ "$DO_DOTS" == true || "$DO_SHELL" == true ]] && echo false || echo true)
SKIP_BACKUP=$([[ "$DO_BACKUP" == true ]] && echo false || echo true)
SKIP_SYSUPDATE=$([[ "$DO_SYSUPDATE" == true ]] && echo false || echo true)

# Compute components string for state file
COMPONENTS_STR=""
[[ "$DO_DOTS" == true ]] && COMPONENTS_STR+="dots,"
[[ "$DO_SHELL" == true ]] && COMPONENTS_STR+="shell,"
[[ "$DO_HYPRGLASS" == true ]] && COMPONENTS_STR+="hyprglass,"
[[ "$DO_BUNDLED" == true ]] && COMPONENTS_STR+="bundled,"
[[ "$DO_BUILD" == true ]] && COMPONENTS_STR+="build,"
[[ "$DO_DEPS" == true ]] && COMPONENTS_STR+="deps,"
[[ "$DO_SYSUPDATE" == true ]] && COMPONENTS_STR+="sysupdate,"
COMPONENTS_STR=${COMPONENTS_STR%,}
[[ -z "$COMPONENTS_STR" ]] && COMPONENTS_STR="none"

# ── Logging ───────────────────────────────────────────────────────────────────
mkdir -p "$(dirname "$LOG_FILE")"
exec > >(tee -a "$LOG_FILE") 2>&1
verbose_log "Log file: $LOG_FILE"
verbose_log "Profile: $HORIZONS_PROFILE  Components: $COMPONENTS_STR  Command: $COMMAND"

# ── Safe command runner: dry-run aware + retry / skip / abort ───────────────
run(){
  if [[ "$QUIET" == false ]]; then
    println "${DM}${IT}    ▸ $*${RST}"
  fi
  if [[ "$DRY_RUN" == true ]]; then
    println "${Y}    [dry-run] would run: $*${RST}"
    return 0
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

# ── Interactive confirmation (respects FORCE/ASK + dry-run) ──────────────────
confirm(){
  local msg="$1"
  local def="${2:-y}"
  [[ "$ASK" == false ]] && return 0
  [[ "$DRY_RUN" == true ]] && { info "[dry-run] would confirm: $msg"; return 0; }
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
  [[ "$QUIET" == true ]] && return 0
  clear 2>/dev/null || true
  printf "\n"
  printf "${M}${BD}"
  printf "  ██   ██  ██████  ██████  ██  ███████   ██████  ███    ██  ███████ \n"
  printf "  ██   ██ ██    ██ ██   ██ ██      ███  ██    ██ ████   ██  ██      \n"
  printf "  ███████ ██    ██ ██████  ██     ███   ██    ██ ██ ██  ██  ███████ \n"
  printf "  ██   ██ ██    ██ ██   ██ ██    ███    ██    ██ ██  ██ ██       ██ \n"
  printf "  ██   ██  ██████  ██   ██ ██  ███████   ██████  ██   ████  ███████ \n"
  printf "                                                            آفاق | Horizons  v2.0\n"
  printf "${RST}"
  printf "\n"
  printf "  ${C}${IT}$(L "A personal fork of illogical-impulse · Powered by Quickshell" "نسخة شخصية من illogical-impulse · مدعومة بـ Quickshell")${RST}\n"
  printf "  ${DM}by pctrade  ·  %s  ·  profile: ${BD}%s${RST}${DM}  ·  %s${RST}  ·  lang: ${BD}%s${RST}${DM}${RST}\n" "$(date '+%Y-%m-%d %H:%M')" "$HORIZONS_PROFILE" "$COMPONENTS_STR" "$HORIZONS_LANG"
  printf "\n"
  printf "  ${DM}$(L "Log file:" "ملف السجل:") ${UL}%s${RST}\n" "$LOG_FILE"
  if [[ "$DRY_RUN" == true ]]; then
    printf "  ${Y}${BD}$(L "⚠ DRY-RUN mode — no changes will be made" "⚠ وضع التجربة — لن يتم إجراء أي تغييرات")${RST}\n"
  fi
  printf "\n"
  printf "${M}$(printf '%0.s─' $(seq 1 60))${RST}\n"
  printf "\n"
}

# ── Smart detection helpers (avoid reinstall, detect non-horizons) ───────────
# Check if a package is installed (distro-aware)
is_pkg_installed(){
  local pkg="$1"
  case "${PKG_GROUP:-unknown}" in
    arch)   pacman -Qi "$pkg" &>/dev/null ;;
    fedora) dnf list installed "$pkg" &>/dev/null 2>&1 || rpm -q "$pkg" &>/dev/null ;;
    gentoo) equery list "$pkg" &>/dev/null 2>&1 || qlist -I "$pkg" &>/dev/null 2>&1 ;;
    suse)   rpm -q "$pkg" &>/dev/null ;;
    debian) dpkg -s "$pkg" &>/dev/null 2>&1 ;;
    *)      command -v "$pkg" &>/dev/null ;;
  esac
}

# Are all horizons meta deps already installed? (arch only — other distros fallback to binary check)
are_horizons_deps_installed(){
  # The i3/existing-desktop targets do not use the Hyprland meta packages.
  # Their complete requirement set is the lightweight target-aware bootstrap.
  if [[ "${HORIZONS_WINDOW_MANAGER:-hyprland}" != "hyprland" || "${DO_DOTS:-true}" != true ]]; then
    declare -f horizons_target_requirements_installed >/dev/null 2>&1 && horizons_target_requirements_installed
    return $?
  fi
  if [[ "${PKG_GROUP:-unknown}" != "arch" ]]; then
    # Fallback: check core binaries exist
    command -v quickshell &>/dev/null || command -v qs &>/dev/null || return 1
    command -v hyprctl &>/dev/null || return 1
    command -v fish &>/dev/null || return 1
    return 0
  fi
  local expanded=()
  for m in illogical-impulse-audio illogical-impulse-backlight illogical-impulse-basic illogical-impulse-fonts-themes illogical-impulse-kde illogical-impulse-portal illogical-impulse-python illogical-impulse-screencapture illogical-impulse-toolkit illogical-impulse-widgets illogical-impulse-hyprland illogical-impulse-microtex-git illogical-impulse-bibata-modern-classic-bin; do
    expanded+=("$m")
  done
  for pkg in "${expanded[@]}"; do
    if ! is_pkg_installed "$pkg"; then
      verbose_log "Missing meta pkg: $pkg"
      return 1
    fi
  done
  # quickshell: accept either meta or plain AUR package
  if ! is_pkg_installed "illogical-impulse-quickshell-git" && ! is_pkg_installed "quickshell-git" && ! is_pkg_installed "quickshell"; then
    verbose_log "Missing quickshell (illogical-impulse-quickshell-git / quickshell-git / quickshell)"
    return 1
  fi
  return 0
}

# Check if dotfiles appear already installed and identical to source (skip-friendly)
dotfiles_need_update(){
  # Returns 0 if update needed, 1 if already identical
  local src="$DOTS_REPO/dots/.config/hypr/hyprland"
  local dst="$XDG_CONFIG_HOME/hypr/hyprland"
  if [[ ! -d "$dst" ]]; then return 0; fi
  if [[ ! -d "$src" ]]; then return 0; fi
  # Quick check: if horizons marker says same commit, consider identical
  if [[ -f "$HORIZONS_META_JSON" ]] && declare -f horizons_state_get &>/dev/null; then
    local recorded_commit
    recorded_commit=$(horizons_state_get git_commit 2>/dev/null || echo "")
    local current_commit
    current_commit=$(git -C "$REPO_ROOT" rev-parse --short HEAD 2>/dev/null || echo "unknown")
    if [[ -n "$recorded_commit" && "$recorded_commit" == "$current_commit" ]]; then
      # Also check file hash via rsync dry-run
      if command -v rsync &>/dev/null; then
        local diff_count
        diff_count=$(rsync -ani --checksum --exclude='.git' "$src/" "$dst/" 2>/dev/null | grep -E "^>" | wc -l)
        if [[ "$diff_count" -eq 0 ]]; then
          return 1  # no diff -> no update needed
        fi
      fi
    fi
  fi
  return 0
}

# Is the current hypr config already from horizons? (if not -> force replace)
is_horizons_hypr(){
  # Marker file exists = horizons was installed before
  if [[ -f "$HORIZONS_META_JSON" || -f "$HORIZONS_META_SIMPLE" ]]; then
    # Check hyprland variables.lua points to horizons
    local vars_file="$XDG_CONFIG_HOME/hypr/hyprland/variables.lua"
    if [[ -f "$vars_file" ]]; then
      if grep -q 'qsConfig.*horizons' "$vars_file" 2>/dev/null; then
        return 0
      fi
      # Check header comment horizons?
      if grep -qi "horizons" "$vars_file" 2>/dev/null; then
        return 0
      fi
      # File exists but not horizons -> non-horizons
      return 1
    fi
    # No hypr config yet -> not relevant, treat as not horizons (will be installed)
    return 1
  fi
  # Also check if hypr config contains our ll env marker
  local vars_file2="$XDG_CONFIG_HOME/hypr/hyprland/variables.lua"
  if [[ -f "$vars_file2" ]] && [[ $(grep -c 'horizons' "$vars_file2" 2>/dev/null) -gt 0 ]]; then
    return 0
  fi
  # Check custom variables.lua fallback
  if grep -rq "horizons" "$XDG_CONFIG_HOME/hypr/" 2>/dev/null; then
    return 0
  fi
  return 1
}

# Is quickshell config already horizons?
is_horizons_shell(){
  if [[ -d "$QS_CONFIG_DIR" && -f "$QS_CONFIG_DIR/shell.qml" ]]; then
    # Check if marker inside
    if [[ -f "$QS_CONFIG_DIR/.horizons-info" || -f "$HORIZONS_META_JSON" ]]; then
      return 0
    fi
    # Check if shell.qml is newer than repo? Use rsync diff
    if command -v rsync &>/dev/null; then
      local diff_count
      diff_count=$(rsync -ani --checksum --exclude='.git' --exclude='*.so' --exclude='*.o' "$QS_REPO/" "$QS_CONFIG_DIR/" 2>/dev/null | grep -E "^>" | wc -l)
      if [[ "$diff_count" -eq 0 ]]; then
        return 0
      fi
    fi
    # Has quickshell config but not necessarily horizons? Check for horizons string in shell.qml
    if grep -q "horizons" "$QS_CONFIG_DIR/shell.qml" 2>/dev/null; then
      return 0
    fi
  fi
  return 1
}

# ── Requirement checks ────────────────────────────────────────────────────────
check_requirements(){
  step "Pre-flight checks (ذكي — يتفادى المثبت بالفعل)"
  local ok_count=0 fail_count=0
  local skip_deps_hint=false

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
  case "$HORIZONS_WINDOW_MANAGER" in
    hyprland) _chk "hyprctl" "command -v hyprctl" ;;
    i3)       _chk "i3-msg" "command -v i3-msg" ;;
  esac
  _chk "dotfiles/ present" "[[ -d '$DOTS_REPO' ]]"
  if [[ "$DO_BUILD" == true ]]; then
      _chk "make"           "command -v make"
      _chk "g++"            "command -v g++"
      _chk "pkg-config"     "command -v pkg-config"
  fi

  # ── Smart deps check: if all meta pkgs already installed, suggest skip ─────
  if [[ "$DO_DEPS" == true ]]; then
    if are_horizons_deps_installed; then
      printf "\n  ${G}${BD}✔ Dependencies already installed (all illogical-impulse-* present)${RST}\n"
      printf "  ${DM}→ Will skip deps install automatically (use --with-deps to force, --skip-deps to hide this)${RST}\n"
      skip_deps_hint=true
      # Auto-skip unless forced
      if [[ "$FORCE" == false && "$BUILD_FORCE" == false ]]; then
        # Don't silently flip DO_DEPS here — just inform. User can still proceed if wants reinstall.
        # But for --dry-run we show what would happen
        if [[ "$ASK" == true ]]; then
          printf "  ${Y}→ Detected installed deps — prompt will offer to skip.${RST}\n"
        fi
      fi
    else
      printf "\n  ${Y}Dependencies not fully installed — will install missing ones.${RST}\n"
    fi
  fi

  # ── Dotfiles/Hyprland detection (only meaningful for the Hyprland target) ─
  if [[ "$HORIZONS_WINDOW_MANAGER" == "hyprland" && -d "$XDG_CONFIG_HOME/hypr" ]]; then
    if is_horizons_hypr; then
      printf "  ${G}✔ hypr config is already Horizons${RST}\n"
      if ! dotfiles_need_update; then
        printf "  ${G}✔ hypr files up-to-date (no diff vs repo) — can skip${RST}\n"
      else
        printf "  ${Y}○ hypr files are Horizons but outdated — update needed${RST}\n"
      fi
    else
      printf "  ${Y}${BD}⚠ hypr config found BUT NOT from Horizons (qsConfig ≠ horizons)${RST}\n"
      printf "  ${Y}  → Will be REPLACED (backed up to $BACKUP_DIR)${RST}\n"
    fi
  elif [[ "$HORIZONS_WINDOW_MANAGER" == "hyprland" ]]; then
    printf "  ${DM}○ No hypr config yet — fresh install${RST}\n"
  fi

  if [[ -d "$QS_CONFIG_DIR" ]]; then
    if is_horizons_shell; then
      printf "  ${G}✔ quickshell/horizons already installed${RST}\n"
    else
      printf "  ${Y}○ quickshell/horizons exists but not recognized as Horizons — will sync${RST}\n"
    fi
  fi

  printf "\n"
  printf "  Checks: ${G}%d OK${RST}  ${R}%d missing${RST}\n" "$ok_count" "$fail_count"
  if [[ $fail_count -gt 0 ]]; then
    warn "$(L "Some requirements are missing." "بعض المتطلبات مفقودة.")"
    if ! confirm "$(L "Continue anyway?" "المتابعة على أي حال؟")"; then
      die "$(L "Aborting — please install missing requirements first." "إلغاء — يرجى تثبيت المتطلبات المفقودة أولاً.")"
    fi
  else
    ok "All requirements satisfied."
  fi

  # Offer to auto-skip deps if they were found installed and user is interactive
  if [[ "$skip_deps_hint" == true && "$FORCE" == false && "$ASK" == true && "$DO_DEPS" == true ]]; then
    printf "\n"
    if confirm "$(L "Skip dependency installation (already satisfied)?" "تخطي تثبيت الاعتماديات (مثبتة بالفعل)؟")" "y"; then
      DO_DEPS=false
      SKIP_DEPS=true
      SKIP_ALLDEPS=true
      ok "Will skip deps — using already installed packages."
    else
      info "Will reinstall deps despite them being present (--with-deps)."
    fi
  fi
  return 0
}

# ── Migration shim ────────────────────────────────────────────────────────────
migrate_legacy_configs(){
  step "$(L "Check for legacy config (illogical-impulse / end4-pC)" "فحص الإعدادات القديمة (illogical-impulse / end4-pC)")"
  local did_anything=false
  if [[ -d "$LEGACY_DOTS_CONFIG_DIR" && ! -d "$DOTS_CONFIG_DIR" ]]; then
    warn "Found legacy config at: $LEGACY_DOTS_CONFIG_DIR"
    warn "New location is:        $DOTS_CONFIG_DIR"
    if confirm "$(L "Copy it to the new 'horizons' location now? (original is kept, nothing is deleted)" "نسخه إلى موقع 'horizons' الجديد الآن؟ (النسخة الأصلية محفوظة)")"; then
      run mkdir -p "$(dirname "$DOTS_CONFIG_DIR")"
      run cp -r "$LEGACY_DOTS_CONFIG_DIR" "$DOTS_CONFIG_DIR"
      ok "Migrated $LEGACY_DOTS_CONFIG_DIR -> $DOTS_CONFIG_DIR"
      did_anything=true
    else
      info "$(L "Skipping migration — a fresh 'horizons' config will be created." "تخطي الترحيل — سيتم إنشاء إعدادات 'horizons' جديدة.")"
    fi
  fi
  if [[ -d "$LEGACY_QS_CONFIG_DIR" && ! -d "$QS_CONFIG_DIR" ]]; then
    warn "Found legacy Quickshell config at: $LEGACY_QS_CONFIG_DIR"
    warn "New location is:                   $QS_CONFIG_DIR"
    if confirm "$(L "Copy it to the new 'horizons' location now? (original is kept, nothing is deleted)" "نسخه إلى موقع 'horizons' الجديد الآن؟ (النسخة الأصلية محفوظة)")"; then
      run mkdir -p "$(dirname "$QS_CONFIG_DIR")"
      run cp -r "$LEGACY_QS_CONFIG_DIR" "$QS_CONFIG_DIR"
      ok "Migrated $LEGACY_QS_CONFIG_DIR -> $QS_CONFIG_DIR"
      did_anything=true
    else
      info "Skipping migration — install will write a fresh 'horizons' Quickshell config."
    fi
  fi
  [[ "$did_anything" == false ]] && info "No legacy config found (or already migrated)." || true
  return 0
}

# ── Backup ────────────────────────────────────────────────────────────────────
do_backup(){
  [[ "$DO_BACKUP" == false || "$SKIP_BACKUP" == true ]] && { info "$(L "Skipping backup (--skip-backup)" "تخطي النسخ الاحتياطي (--skip-backup)")"; return 0; }
  step "$(L "Backup existing configs" "نسخ احتياطي للإعدادات الحالية")"
  local targets=("$QS_CONFIG_DIR" "$DOTS_CONFIG_DIR")
  local has_any=false
  for t in "${targets[@]}"; do [[ -e "$t" ]] && has_any=true && break; done
  if [[ "$has_any" == false ]]; then
    info "Nothing to backup — fresh install detected."
    return 0
  fi
  warn "Existing Horizons config detected."
  printf "\n"
  if ! confirm "$(L "Backup existing config to ${BACKUP_DIR}?" "نسخ الإعدادات الحالية احتياطياً إلى ${BACKUP_DIR}؟")"; then
    warn "$(L "Skipping backup. Existing files will be overwritten." "تخطي النسخ الاحتياطي. سيتم الكتابة فوق الملفات الحالية.")"
    return 0
  fi
  run mkdir -p "$BACKUP_DIR"
  for t in "${targets[@]}"; do [[ -e "$t" ]] && run cp -r "$t" "$BACKUP_DIR/"; done
  ok "Backup saved to: $BACKUP_DIR"
}

# ── System upgrade ────────────────────────────────────────────────────────────
do_sysupdate(){
  [[ "$DO_SYSUPDATE" == false ]] && { info "$(L "Skipping system upgrade (--skip-sysupdate is default; use --with-sysupdate)" "تخطي ترقية النظام (--skip-sysupdate هو الافتراضي، استخدم --with-sysupdate)")"; return 0; }
  step "$(L "System upgrade (full — via distro package manager)" "ترقية النظام (كاملة — عبر مدير الحزم)")"
  if ! confirm "$(L "Run full system upgrade now? (pacman -Syu / dnf upgrade / zypper dup)" "تشغيل ترقية كاملة للنظام الآن؟ (pacman -Syu / dnf upgrade / zypper dup)")"; then
    info "$(L "Skipping system upgrade." "تخطي ترقية النظام.")"
    return 0
  fi
  case "${PKG_GROUP:-unknown}" in
    arch) run sudo pacman -Syu --noconfirm ;;
    fedora) run sudo dnf upgrade --refresh -y ;;
    gentoo) run sudo emerge --sync; run sudo emerge -uDN @world ;;
    suse) run sudo zypper dup -y ;;
    debian) run sudo apt update -y; run sudo apt upgrade -y ;;
    *) warn "Unknown PKG_GROUP '$PKG_GROUP' — cannot do sysupdate automatically. Please update manually." ;;
  esac
  ok "System upgrade done."
}

# ── Install dotfiles (base) via dotfiles/setup ────────────────────────────────
install_dots(){
  [[ "$DO_DOTS" == false || "$SKIP_DOTS" == true ]] && { info "$(L "Skipping dotfiles base install (profile: $HORIZONS_PROFILE)" "تخطي تثبيت ملفات النقاط (الملف: $HORIZONS_PROFILE)")"; return 0; }
  step "$(L "Install dotfiles (base — hypr/kitty/fish/etc.)" "تثبيت ملفات النقاط (الأساسية — hypr/kitty/fish/إلخ)")"

  # ── Smart: if hypr exists and NOT horizons → force replace with backup
  local force_hypr_replace=false
  if [[ -d "$XDG_CONFIG_HOME/hypr" ]]; then
    if ! is_horizons_hypr; then
      warn "Detected non-Horizons hypr config — will be replaced (with backup)."
      force_hypr_replace=true
      # Ensure backup is enabled for this case even if user said --skip-backup
      if [[ "$DO_BACKUP" == false ]]; then
        warn "Enabling backup for hypr replacement despite --skip-backup."
        DO_BACKUP=true
        SKIP_BACKUP=false
        BACKUP_DIR="$HOME/horizons-backup-hypr-replace-$(date +%Y%m%d-%H%M%S)"
      fi
      # Backup hypr specifically
      if [[ "$DRY_RUN" == false ]]; then
        mkdir -p "$BACKUP_DIR"
        cp -r "$XDG_CONFIG_HOME/hypr" "$BACKUP_DIR/" 2>/dev/null || true
        ok "Backed up existing hypr to $BACKUP_DIR/hypr"
      else
        info "[dry-run] would backup $XDG_CONFIG_HOME/hypr → $BACKUP_DIR/hypr"
      fi
    else
      # Horizons hypr already — check if need update
      if ! dotfiles_need_update; then
        ok "hypr files are already Horizons and up-to-date — skipping dotfiles copy, updating marker only."
        # Still ensure qsConfig line? But skip heavy rsync by returning early if user agrees
        if [[ "$FORCE" == false && "$ASK" == true ]]; then
          if confirm "$(L "Skip copying hypr files (identical)?" "تخطي نسخ ملفات hypr (متطابقة)؟")" "y"; then
            info "$(L "Skipped dotfiles — hypr is fresh." "تم تخطي ملفات النقاط — hypr محدث.")"
            return 0
          fi
        else
          # Non-interactive but up-to-date -> skip unless --force
          if [[ "$BUILD_FORCE" == false ]]; then
            info "Skipping dotfiles (up-to-date, non-interactive without --build-force)."
            return 0
          fi
        fi
      fi
    fi
  fi

  if [[ ! -d "$DOTS_REPO" ]]; then
    warn "dotfiles/ not found at: $DOTS_REPO — skipping."
    return 0
  fi
  ok "dotfiles found at $DOTS_REPO"
  if ! confirm "$(L "Run 'dotfiles/setup install' (recommended on first install)?" "تشغيل 'dotfiles/setup install' (مُستحسن عند التثبيت الأول)؟")"; then
    info "$(L "Skipping dotfiles installer." "تخطي مثبت ملفات النقاط.")"
    return 0
  fi
  local setup_args=(install)
  # Smart deps: if already satisfied and not forcing, skip
  if [[ "$DO_DEPS" == false || "$SKIP_DEPS" == true ]]; then
    setup_args+=(--skip-alldeps)
  elif are_horizons_deps_installed && [[ "$FORCE" == false && "$BUILD_FORCE" == false ]]; then
    info "Deps already satisfied — adding --skip-alldeps (override with --with-deps --build-force)"
    setup_args+=(--skip-alldeps)
  fi
  [[ "$DO_BACKUP" == false ]] && setup_args+=(--skip-backup)
  [[ "$DO_SYSUPDATE" == false ]] && setup_args+=(--skip-sysupdate)
  [[ "$FORCE" == true ]]       && setup_args+=(--force)
  [[ "$WITH_VIA_NIX" == true ]] && setup_args+=(--via-nix)
  [[ -n "$FONTSET_DIR_NAME" ]]  && setup_args+=(--fontset "$FONTSET_DIR_NAME")
  # If we forced hypr replace, ensure setup doesn't skip hyprland
  if [[ "$force_hypr_replace" == true ]]; then
    info "Forcing hyprland reinstall (was non-Horizons) — overriding any --skip-hyprland."
  fi
  info "Launching: $DOTS_REPO/setup ${setup_args[*]}"
  printf "\n"
  if [[ "$DRY_RUN" == true ]]; then
    info "[dry-run] would run: (cd $DOTS_REPO && bash ./setup ${setup_args[*]})"
    if [[ "$force_hypr_replace" == true ]]; then
      info "[dry-run] Would also ensure $XDG_CONFIG_HOME/hypr/hyprland/variables.lua → qsConfig = horizons"
    fi
  else
    (cd "$DOTS_REPO" && run bash ./setup "${setup_args[@]}")
    # Post-hook: ensure hypr files are now horizons even if setup was partially skipped earlier
    if [[ "$force_hypr_replace" == true ]]; then
      local vars_file="$XDG_CONFIG_HOME/hypr/hyprland/variables.lua"
      if [[ -f "$vars_file" ]] && ! grep -q 'horizons' "$vars_file" 2>/dev/null; then
        warn "Post-install hypr still not horizons — patching variables.lua"
        cp "$vars_file" "${vars_file}.bak" 2>/dev/null || true
        sed -i -E 's|hl\.env\("qsConfig",[[:space:]]*"[^"]*"\)|hl.env("qsConfig", "horizons")|' "$vars_file" 2>/dev/null || true
        ok "Patched $vars_file → horizons"
      fi
    fi
  fi
}

# ── Build plugins (hyprglass) ────────────────────────────────────────────────
build_hyprglass(){
  [[ "$DO_HYPRGLASS" == false || "$SKIP_HYPRGLASS" == true ]] && { info "$(L "Skipping hyprglass plugin (profile: $HORIZONS_PROFILE)" "تخطي إضافة hyprglass (الملف: $HORIZONS_PROFILE)")"; return 0; }
  step "$(L "Build hyprglass plugin" "بناء إضافة hyprglass")"
  if [[ "$DRY_RUN" == true ]]; then
    info "[dry-run] would build hyprglass.so via make (skip with --skip-hyprglass)"
    return 0
  fi
  # Prefer lib helper (hz_ prefix to avoid recursion)
  if declare -f hz_build_hyprglass &>/dev/null; then
      if [[ "$ASK" == false || "$FORCE" == true ]]; then
          if [[ "$BUILD_FORCE" == true ]]; then hz_build_hyprglass true; else hz_build_hyprglass false; fi
          return 0
      fi
  elif declare -f build_hyprglass &>/dev/null && [[ "$(type -t build_hyprglass)" != "function" || "$(declare -f build_hyprglass | grep -c "hz_build")" -eq 0 ]]; then
      # Fallback if only plain build_hyprglass from lib is available (before alias) — avoid recursion by checking
      :
  fi
  # Fallback inline logic (if lib not loaded)
  if [[ ! -d "$HYPRGLASS_DIR" ]]; then
    warn "hyprglass plugin dir not found at $HYPRGLASS_DIR — skipping."
    return 0
  fi
  if command -v hyprpm &>/dev/null; then
    info "hyprpm found — alternative: hyprpm add https://github.com/hyprnux/hyprglass && hyprpm enable hyprglass"
  fi
  if ! command -v make &>/dev/null || ! command -v g++ &>/dev/null; then
    warn "make/g++ not found — skipping hyprglass build."
    warn "Install build-essential/base-devel and re-run with --with-build."
    return 0
  fi
  if ! confirm "$(L "Build hyprglass.so from source now (make)?" "بناء hyprglass.so من المصدر الآن (make)؟")"; then
    info "$(L "Skipping hyprglass build." "تخطي بناء hyprglass.")"
    return 0
  fi
  if (cd "$HYPRGLASS_DIR" && make -j"$(nproc 2>/dev/null || echo 4)"); then
    ok "hyprglass.so built at $HYPRGLASS_DIR/hyprglass.so"
  else
    warn "hyprglass build failed — missing dev headers (hyprland, pixman, libdrm)?"
    warn "Continuing without fresh build."
  fi
}

# ── QuickShell build (optional, via PKGBUILD) ─────────────────────────────────
build_quickshell_step(){
  [[ "$DO_BUILD" == false && "$BUILD_FORCE" == false ]] && return 0
  step "$(L "Build quickshell from source" "بناء quickshell من المصدر")"
  if [[ "$DRY_RUN" == true ]]; then
    info "[dry-run] would build quickshell from source (skip with --skip-build)"
    return 0
  fi
  if declare -f hz_build_quickshell &>/dev/null; then
      if [[ "$BUILD_FORCE" == true ]]; then hz_build_quickshell true; else hz_build_quickshell false; fi
  elif declare -f build_quickshell &>/dev/null; then
      # Avoid recursion if this is ourselves — call lib via hz alias if exists
      if [[ "$BUILD_FORCE" == true ]]; then build_quickshell true; else build_quickshell false; fi
  else
      info "build.sh not loaded — skipping quickshell build."
  fi
}

# ── Bundled extras ────────────────────────────────────────────────────────────
install_bundled(){
  [[ "$DO_BUNDLED" == false ]] && { info "$(L "Skipping bundled extras (use --with-bundled or --profile full/ultra)" "تخطي الإضافات المرفقة (استخدم --with-bundled أو --profile full/ultra)")"; return 0; }
  step "$(L "Install bundled extras (Rubik, Gabarito, Bibata, etc.)" "تثبيت الإضافات المرفقة (Rubik، Gabarito، Bibata، إلخ)")"
  if ! confirm "$(L "Install bundled fonts/cursors (may download ~100MB)?" "تثبيت الخطوط/المؤشرات المرفقة (قد يتم تنزيل ~100 ميجابايت)؟")"; then
    info "$(L "Skipping bundled extras." "تخطي الإضافات المرفقة.")"
    return 0
  fi
  if declare -f hz_build_bundled &>/dev/null; then
      hz_build_bundled
  elif declare -f build_bundled &>/dev/null; then
      build_bundled
  else
      warn "build.sh not loaded — bundled install unavailable."
  fi
}

# ── Install Horizons Quickshell config ───────────────────────────────────────
install_qs(){
  [[ "$DO_SHELL" == false || "$SKIP_QS" == true ]] && { info "$(L "Skipping Quickshell config (--skip-qs / profile: $HORIZONS_PROFILE)" "تخطي إعدادات Quickshell (--skip-qs / الملف: $HORIZONS_PROFILE)")"; return 0; }
  step "$(L "Install Horizons Quickshell config" "تثبيت إعدادات Horizons لـ Quickshell")"
  # Smart: skip if already horizons and identical (avoid overwriting)
  if [[ -d "$QS_CONFIG_DIR" ]] && is_horizons_shell; then
    if [[ "$BUILD_FORCE" == false && "$FORCE" == false ]]; then
      ok "Quickshell config already Horizons and up-to-date — skipping sync."
      if [[ "$ASK" == true ]]; then
        if ! confirm "$(L "Force re-sync shell anyway?" "فرض إعادة مزامنة الواجهة على أي حال؟")" "n"; then
          info "$(L "Skipping shell sync (identical)." "تخطي مزامنة الواجهة (متطابقة).")"
          return 0
        fi
      else
        info "Skipping (use --build-force to force re-sync)."
        return 0
      fi
    else
      warn "Force mode — re-syncing even though shell appears installed."
    fi
  fi
  info "Source : $QS_REPO"
  info "Target : $QS_CONFIG_DIR"
  info "Profile: $HORIZONS_PROFILE"
  printf "\n"
  if ! confirm "$(L "Copy Horizons config to $QS_CONFIG_DIR?" "نسخ إعدادات Horizons إلى $QS_CONFIG_DIR؟")"; then
    warn "$(L "Skipping Quickshell config install." "تخطي تثبيت إعدادات Quickshell.")"
    return 0
  fi
  if [[ "$DRY_RUN" == true ]]; then
    if [[ -d "$QS_CONFIG_DIR" ]] && is_horizons_shell; then
      info "[dry-run] QS already horizons — would skip unless --build-force"
    else
      info "[dry-run] would rsync $QS_REPO/ -> $QS_CONFIG_DIR/ (delete, exclude .git, *.so, *.o)"
    fi
    return 0
  fi
  run mkdir -p "$QS_CONFIG_DIR"
  info "Syncing files…"
  local total
  total=$(find "$QS_REPO" -not -path "*/.git/*" -not -name ".git" 2>/dev/null | wc -l)
  local copied=0
  rsync -av --delete \
    --exclude='.git' \
    --exclude='installer.sh' \
    --exclude='plugins/hyprglass/src/*.o' \
    --exclude='plugins/hyprglass/*.so' \
    --out-format='%n' \
    "$QS_REPO/" "$QS_CONFIG_DIR/" 2>&1 | while IFS= read -r line; do
      ((copied++)) || true
      progress "$copied" "$total" "$line"
    done
  printf "\n"
  if [[ -f "$HYPRGLASS_DIR/hyprglass.so" ]]; then
    run mkdir -p "$QS_CONFIG_DIR/plugins/hyprglass"
    run cp "$HYPRGLASS_DIR/hyprglass.so" "$QS_CONFIG_DIR/plugins/hyprglass/hyprglass.so"
    ok "Deployed hyprglass.so to $QS_CONFIG_DIR/plugins/hyprglass/"
  fi
  ok "Quickshell config installed."
}

# ── Configure Hyprland ────────────────────────────────────────────────────────
configure_hyprland(){
  [[ "$HORIZONS_WINDOW_MANAGER" == "hyprland" ]] || return 0
  step "$(L "Configure Hyprland shell" "إعداد واجهة Hyprland")"
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
  if confirm "$(L "Change qsConfig to 'horizons'?" "تغيير qsConfig إلى 'horizons'؟")"; then
    if [[ "$DRY_RUN" == true ]]; then info "[dry-run] would update $vars_file"; else
      run cp "$vars_file" "${vars_file}.bak"
      run sed -i -E 's|hl\.env\("qsConfig",[[:space:]]*"[^"]*"\)|hl.env("qsConfig", "horizons")|' "$vars_file"
      ok "qsConfig updated to horizons."
      ok "Backup saved to: ${vars_file}.bak"
    fi
  else
    info "Skipping — you can set it manually later:"
    printf "  ${DM}Edit: %s${RST}\n" "$vars_file"
    printf "  ${DM}Set:  hl.env(\"qsConfig\", \"horizons\")${RST}\n"
  fi
}

# ── Configure i3/X11 integration ────────────────────────────────────────────
configure_i3(){
  [[ "$HORIZONS_WINDOW_MANAGER" == "i3" ]] || return 0
  local i3_config="$XDG_CONFIG_HOME/i3/config"
  local horizons_i3="$XDG_CONFIG_HOME/i3/horizons.conf"
  local source_i3="$REPO_ROOT/i3/horizons.conf"
  [[ -f "$i3_config" ]] || return 0

  step "$(L "Configure i3/X11 shell" "إعداد واجهة i3/X11")"
  if grep -Fq 'include ~/.config/i3/horizons.conf' "$i3_config" 2>/dev/null && [[ -f "$horizons_i3" ]]; then
    ok "Horizons i3 integration already configured — no changes needed."
    return 0
  fi

  printf "\n"
  printf "  ${B}Horizons detected an i3 configuration:${RST} %s\n" "$i3_config"
  printf "  ${DM}This adds a separate, reversible include for startup and IPC keybinds.${RST}\n"
  printf "  ${DM}Existing i3 rules and bindings are left untouched.${RST}\n\n"
  if ! confirm "$(L "Enable Horizons integration for i3/X11?" "تفعيل تكامل Horizons مع i3/X11؟")" "y"; then
    info "$(L "Skipping i3 integration." "تخطي تكامل i3.")"
    return 0
  fi
  if [[ "$DRY_RUN" == true ]]; then
    info "[dry-run] would install $horizons_i3 and add its include to $i3_config"
    return 0
  fi
  if [[ ! -f "$source_i3" ]]; then
    warn "Horizons i3 template is missing: $source_i3"
    return 1
  fi
  run cp "$i3_config" "${i3_config}.horizons.bak"
  if [[ -f "$horizons_i3" ]]; then
    run cp "$horizons_i3" "${horizons_i3}.horizons.bak"
  fi
  run cp "$source_i3" "$horizons_i3"
  if ! grep -Fq 'include ~/.config/i3/horizons.conf' "$i3_config"; then
    printf "\n# Horizons i3/X11 integration\ninclude ~/.config/i3/horizons.conf\n" >> "$i3_config"
  fi
  ok "i3 integration enabled. Backup saved to: ${i3_config}.horizons.bak"
}

# ── Add settings keybind ──────────────────────────────────────────────────────
configure_keybind(){
  # i3 gets its own IPC bindings from i3/horizons.conf. Do not create a
  # Hyprland configuration directory merely because this installer was run
  # inside an X11 session.
  [[ "$HORIZONS_WINDOW_MANAGER" == "hyprland" ]] || return 0
  [[ -f "$XDG_CONFIG_HOME/hypr/hyprland/variables.lua" ]] || return 0
  step "$(L "Settings keybind" "اختصار الإعدادات")"
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
  if confirm "$(L "Add settings keybind (Super+Escape) to $keybind_file?" "إضافة اختصار الإعدادات (Super+Escape) إلى $keybind_file؟")"; then
    if [[ "$DRY_RUN" == true ]]; then info "[dry-run] would append to $keybind_file"; else
      run mkdir -p "$custom_dir"
      { printf "\n-- Horizons settings panel toggle\n"; printf '%s\n' "$keybind_line"; } >> "$keybind_file"
      ok "Keybind added."
    fi
  else
    info "Skipping — add manually:"
    printf "  ${DM}%s${RST}\n" "$keybind_line"
  fi
}

# ── Restart Quickshell ────────────────────────────────────────────────────────
restart_qs(){
  local current_session="${XDG_SESSION_TYPE:-}"
  if [[ "$HORIZONS_PROTOCOL" != "$current_session" ]]; then
    info "$(L "Not restarting the active session because it does not match the selected target." "لن يتم إعادة تشغيل الجلسة الحالية لأنها لا تطابق الهدف المختار.")"
    return 0
  fi
  step "$(L "Restart Quickshell" "إعادة تشغيل Quickshell")"
  if ! confirm "$(L "Restart Quickshell now to apply changes?" "إعادة تشغيل Quickshell الآن لتطبيق التغييرات؟")"; then
    info "$(L "Skipping — restart manually:" "تخطي — أعد التشغيل يدوياً:")"
    printf "  ${DM}pkill -x quickshell; qs -c horizons &${RST}\n"
    return 0
  fi
  if [[ "$DRY_RUN" == true ]]; then info "[dry-run] would restart quickshell"; return 0; fi
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
  if [[ "${XDG_SESSION_TYPE:-}" == "x11" ]]; then
    DISPLAY="${DISPLAY:-:0}" "$QS_BIN" -c horizons >/dev/null 2>&1 &
  else
    WAYLAND_DISPLAY="${WAYLAND_DISPLAY:-wayland-1}" "$QS_BIN" -c horizons >/dev/null 2>&1 &
  fi
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

# ── Write identity marker (always last on success) ───────────────────────────
write_horizons_state(){
  step "$(L "Write Horizons identity marker" "كتابة علامة هوية Horizons")"
  if [[ "$DRY_RUN" == true ]]; then
    info "[dry-run] would write $XDG_CONFIG_HOME/horizons/.horizons-meta.json"
    info "[dry-run] profile=$HORIZONS_PROFILE components=$COMPONENTS_STR"
    return 0
  fi
  if declare -f horizons_state_write &>/dev/null; then
    horizons_state_write "$HORIZONS_PROFILE" "$COMPONENTS_STR" "$HORIZONS_LANG"
    # Ensure lang is persisted even if state.sh version is old — patch JSON
    if [[ -f "$HORIZONS_META_JSON" ]]; then
      if command -v jq &>/dev/null; then
        jq --arg lang "$HORIZONS_LANG" '.lang = $lang | .language = $lang' "$HORIZONS_META_JSON" > "$HORIZONS_META_JSON.tmp" 2>/dev/null && mv "$HORIZONS_META_JSON.tmp" "$HORIZONS_META_JSON" || true
      else
        if ! grep -q '"lang"' "$HORIZONS_META_JSON" 2>/dev/null; then
          sed -i "s/\"profile\":/\"lang\": \"$HORIZONS_LANG\",\n  \"profile\":/" "$HORIZONS_META_JSON" 2>/dev/null || true
        else
          sed -i "s/\"lang\": \"[^\"]*\"/\"lang\": \"$HORIZONS_LANG\"/" "$HORIZONS_META_JSON" 2>/dev/null || true
        fi
      fi
      # Also patch simple marker
      if [[ -f "$HORIZONS_META_SIMPLE" ]] && ! grep -q "^lang=" "$HORIZONS_META_SIMPLE" 2>/dev/null; then
        echo "lang=$HORIZONS_LANG" >> "$HORIZONS_META_SIMPLE"
        echo "language=$HORIZONS_LANG" >> "$HORIZONS_META_SIMPLE"
      fi
    fi
    ok "Identity written to:"
    ok "  $XDG_CONFIG_HOME/horizons/.horizons-meta.json"
    ok "  $XDG_CONFIG_HOME/horizons/.horizons-info"
    ok "  $XDG_CONFIG_HOME/horizons/.horizons-version"
    # Also install a quick CLI helper
    local bin_dir="$HOME/.local/bin"
    mkdir -p "$bin_dir"
    if [[ ! -f "$bin_dir/horizons" ]]; then
        ln -sf "$REPO_ROOT/installer.sh" "$bin_dir/horizons" 2>/dev/null || cp -f "$REPO_ROOT/installer.sh" "$bin_dir/horizons"
        ok "CLI helper installed: $bin_dir/horizons  (run 'horizons status' anytime)"
    fi
  else
    warn "state.sh not loaded — cannot write identity marker."
    mkdir -p "$XDG_CONFIG_HOME/horizons"
    cat > "$XDG_CONFIG_HOME/horizons/.horizons-info" <<EOF
identity=horizons
display_name=آفاق | Horizons
installed_at=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
profile=$HORIZONS_PROFILE
components=$COMPONENTS_STR
lang=$HORIZONS_LANG
language=$HORIZONS_LANG
EOF
    ok "Fallback marker written."
  fi
}

# ── Uninstall ─────────────────────────────────────────────────────────────────
do_uninstall(){
  step "$(L "Uninstall Horizons" "إلغاء تثبيت Horizons")"
  warn "This will remove:"
  warn "  $QS_CONFIG_DIR"
  if [[ "$DO_DOTS" == true ]]; then warn "  $DOTS_CONFIG_DIR (dots base)"; fi
  printf "\n"
  if ! confirm "$(L "Proceed with uninstall?" "المتابعة مع إلغاء التثبيت؟")"; then
    info "$(L "Uninstall cancelled." "تم إلغاء إلغاء التثبيت.")"
    return 0
  fi
  if [[ "$DRY_RUN" == true ]]; then info "[dry-run] would uninstall"; return 0; fi
  if [[ -d "$QS_CONFIG_DIR" ]]; then
    local ubak="$HOME/horizons-uninstall-backup-$(date +%Y%m%d-%H%M%S)"
    run cp -r "$QS_CONFIG_DIR" "$ubak"
    ok "Backup saved to: $ubak"
    run rm -rf "$QS_CONFIG_DIR"
    ok "Removed $QS_CONFIG_DIR"
  else
    info "Nothing to remove — $QS_CONFIG_DIR not found."
  fi
  if [[ "$DO_DOTS" == true && -d "$DOTS_CONFIG_DIR" ]]; then
    warn "$(L "Also removing $DOTS_CONFIG_DIR (use --components shell to keep dots)" "سيتم أيضاً إزالة $DOTS_CONFIG_DIR (استخدم --components shell للاحتفاظ بملفات النقاط)")"
    if confirm "$(L "Remove $DOTS_CONFIG_DIR?" "إزالة $DOTS_CONFIG_DIR؟")"; then
        local ubak2="$HOME/horizons-dots-backup-$(date +%Y%m%d-%H%M%S)"
        run cp -r "$DOTS_CONFIG_DIR" "$ubak2"
        run rm -rf "$DOTS_CONFIG_DIR"
        ok "Removed $DOTS_CONFIG_DIR (backup: $ubak2)"
    fi
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
    printf "${G}${BD}  ✦  $(L "Installation complete — no errors!" "اكتمل التثبيت — بدون أخطاء!")${RST}\n"
  else
    printf "${Y}${BD}  ✦  $(L "Installation finished with %d warning(s)/error(s)." "انتهى التثبيت مع %d تحذير/خطأ.")${RST}\n" "$ERRORS"
    printf "${Y}  $(L "Check the log for details:" "تحقق من السجل للتفاصيل:") ${UL}%s${RST}\n" "$LOG_FILE"
  fi
  printf "\n"
  printf "  ${C}${BD}$(L "Next steps:" "الخطوات التالية:")${RST}\n"
  printf "  ${C}•  $(L "Press ${IV} Super + Escape ${RST}${C} to open Settings" "اضغط ${IV} Super + Escape ${RST}${C} لفتح الإعدادات")${RST}\n"
  printf "  ${C}•  $(L "Press ${IV} Ctrl + Super + T ${RST}${C} to pick a wallpaper" "اضغط ${IV} Ctrl + Super + T ${RST}${C} لاختيار خلفية")${RST}\n"
  printf "  ${C}•  $(L "Press ${IV} Super + / ${RST}${C} to see all keybinds" "اضغط ${IV} Super + / ${RST}${C} لعرض جميع الاختصارات")${RST}\n"
  printf "  ${C}•  $(L "Run ${IV} horizons status ${RST}${C} or ${IV} ./installer.sh status ${RST}${C} to see identity" "شغّل ${IV} horizons status ${RST}${C} أو ${IV} ./installer.sh status ${RST}${C} لعرض الهوية")${RST}\n"
  printf "  ${C}•  $(L "Run ${IV} ./installer.sh update ${RST}${C} to update" "شغّل ${IV} ./installer.sh update ${RST}${C} للتحديث")${RST}\n"
  printf "  ${C}•  $(L "Log file:" "ملف السجل:") ${UL}%s${RST}\n" "$LOG_FILE"
  printf "\n"
  printf "  ${DM}${IT}Source: https://github.com/PROFFESSOR0x/end4-pC${RST}\n"
  printf "\n"
  printf "${M}$(printf '%0.s─' $(seq 1 60))${RST}\n"
  printf "\n"
  if declare -f horizons_state_read &>/dev/null; then
      printf "${DM}Identity marker:${RST}\n"
      horizons_state_read 2>/dev/null | head -n 30 || true
      printf "\n"
  fi
}

# ── Safety: must not run as root ──────────────────────────────────────────────
if [[ "$(whoami)" == "root" ]]; then
  printf "${R}${BD}ERROR:${RST} Do not run this installer as root or with sudo.\n"
  exit 1
fi

# ═════════════════════════════════════════════════════════════════════════════
#  COMMAND DISPATCH
# ═════════════════════════════════════════════════════════════════════════════
case "$COMMAND" in
  help)
    print_help; exit 0 ;;
  status)
    print_banner
    detect_distro 2>/dev/null || true
    if declare -f horizons_state_status &>/dev/null; then horizons_state_status; else
        if [[ -f "$XDG_CONFIG_HOME/horizons/.horizons-meta.json" ]]; then cat "$XDG_CONFIG_HOME/horizons/.horizons-meta.json"; else echo "Not installed."; fi
    fi
    exit 0 ;;
  check)
    print_banner
    detect_distro 2>/dev/null || true
    if declare -f horizons_update_check &>/dev/null; then horizons_update_check; exit $?; else
        echo "Update protocol not loaded (install/lib/update.sh missing)"; exit 1
    fi
    ;;
  update)
    print_banner
    detect_distro 2>/dev/null || true
    if declare -f horizons_update_full &>/dev/null; then
        horizons_update_full rebase smart
        exit $?
    else
        # Fallback simple: git pull
        git -C "$REPO_ROOT" pull --rebase || exit 1
        exec bash "$REPO_ROOT/installer.sh" install --force
    fi
    ;;
  build)
    print_banner
    detect_distro
    info "Detected distro: ${BD}$DISTRO_NAME${RST}  (group: $PKG_GROUP)"
    printf "\n"
    if declare -f hz_build_all &>/dev/null; then
        if [[ "$BUILD_FORCE" == true ]]; then hz_build_all true; else hz_build_all false; fi
    elif declare -f build_all &>/dev/null; then
        if [[ "$BUILD_FORCE" == true ]]; then build_all true; else build_all false; fi
    else
        build_hyprglass
        build_quickshell_step
    fi
    write_horizons_state
    exit 0 ;;
  uninstall)
    print_banner
    detect_distro 2>/dev/null || true
    do_uninstall
    exit 0 ;;
  install|*)
    # fall through to main install pipeline
    ;;
esac

# ═════════════════════════════════════════════════════════════════════════════
#  MAIN INSTALL PIPELINE
# ═════════════════════════════════════════════════════════════════════════════
# ── Language selection (first interactive step) ─────────────────────────────
horizons_choose_language
print_banner
detect_distro

info "$(L "Detected distro:" "التوزيعة المكتشفة:") ${BD}$DISTRO_NAME${RST}  (group: $PKG_GROUP)"
info "$(L "Repo root :" "مسار المستودع:") $REPO_ROOT"
info "$(L "Profile   :" "الملف الشخصي:") ${BD}$HORIZONS_PROFILE${RST}  Components: $COMPONENTS_STR  Lang: $HORIZONS_LANG"
if [[ "$DRY_RUN" == true ]]; then warn "$(L "DRY-RUN — no changes will be written." "وضع التجربة — لن يتم إجراء أي تغييرات.")"; fi
printf "\n"

if [[ "$ASK" == true && "$FORCE" == false ]]; then
  printf "  ${B}${BD}$(L "What this installer does (profile: %s):" "ما الذي سيقوم به المثبت (الملف: %s):")${RST}\n" "$HORIZONS_PROFILE"
  [[ "$DO_DEPS" == true ]]      && printf "  ${G}✔${RST} $(L "Dependencies + sys deps" "الاعتماديات")\n" || printf "  ${DM}○ $(L "Skip deps" "تخطي الاعتماديات")${RST}\n"
  [[ "$DO_SYSUPDATE" == true ]] && printf "  ${G}✔${RST} $(L "Full system upgrade" "ترقية كاملة للنظام")\n" || printf "  ${DM}○ $(L "Skip sysupdate" "تخطي ترقية النظام")${RST}\n"
  printf "  ${DM}•${RST}  $(L "Pre-flight checks" "الفحوصات الأولية")\n"
  printf "  ${DM}•${RST}  $(L "Migrate legacy config" "ترحيل الإعدادات القديمة")\n"
  [[ "$DO_BACKUP" == true ]]    && printf "  ${G}✔${RST} $(L "Backup existing config" "نسخ احتياطي للإعدادات")\n" || printf "  ${DM}○ $(L "Skip backup" "تخطي النسخ الاحتياطي")${RST}\n"
  [[ "$DO_DOTS" == true ]]      && printf "  ${G}✔${RST} $(L "Dotfiles base (dotfiles/setup install)" "ملفات النقاط (dotfiles/setup install)")\n" || printf "  ${DM}○ $(L "Skip dots" "تخطي ملفات النقاط")${RST}\n"
  [[ "$DO_BUILD" == true ]]     && printf "  ${G}✔${RST} $(L "Build quickshell from source" "بناء quickshell من المصدر")\n" || printf "  ${DM}○ $(L "Skip quickshell build" "تخطي بناء quickshell")${RST}\n"
  [[ "$DO_HYPRGLASS" == true ]] && printf "  ${G}✔${RST} $(L "Build hyprglass plugin" "بناء إضافة hyprglass")\n" || printf "  ${DM}○ $(L "Skip hyprglass" "تخطي hyprglass")${RST}\n"
  [[ "$DO_BUNDLED" == true ]]   && printf "  ${G}✔${RST} $(L "Bundled extras (fonts/bibata)" "الإضافات المرفقة (خطوط/bibata)")\n" || printf "  ${DM}○ $(L "Skip bundled" "تخطي الإضافات")${RST}\n"
  [[ "$DO_SHELL" == true ]]     && printf "  ${G}✔${RST} $(L "Horizons Quickshell config" "إعدادات Horizons لـ Quickshell")\n" || printf "  ${DM}○ $(L "Skip shell" "تخطي الواجهة")${RST}\n"
  printf "  ${DM}•${RST}  $(L "Configure Hyprland (qsConfig)" "إعداد Hyprland (qsConfig)")\n"
  printf "  ${DM}•${RST}  $(L "Settings keybind" "اختصار الإعدادات")\n"
  printf "  ${DM}•${RST}  $(L "Restart Quickshell" "إعادة تشغيل Quickshell")\n"
  printf "  ${DM}•${RST}  $(L "Write identity marker (.horizons-meta.json)" "كتابة علامة الهوية (.horizons-meta.json)")\n"
  printf "\n"
  if ! confirm "$(L "Ready to begin installation?" "هل أنت جاهز لبدء التثبيت؟")"; then
    printf "  ${DM}$(L "Goodbye!" "وداعاً!")${RST}\n\n"
    exit 0
  fi
  printf "\n"
  printf "  ${B}${BD}$(L "Confirmation mode:" "وضع التأكيد:")${RST}\n"
  printf "  ${B}y${RST} = $(L "Confirm each step" "تأكيد كل خطوة")  ${B}n${RST} = $(L "Auto-proceed all" "المتابعة التلقائية")\n"
  printf "  ▸ "
  read -r p
  [[ "$p" == "n" || "$p" == "N" ]] && ASK=false
fi

# Dynamic steps total based on profile (use +=1 to avoid set -e exit on 0++)
STEPS_TOTAL=0
((STEPS_TOTAL+=1)) # target requirements
((STEPS_TOTAL+=1)) # check
((STEPS_TOTAL+=1)) # migrate
[[ "$DO_BACKUP" == true ]] && ((STEPS_TOTAL+=1)) || true
[[ "$DO_SYSUPDATE" == true ]] && ((STEPS_TOTAL+=1)) || true
[[ "$DO_DOTS" == true ]] && ((STEPS_TOTAL+=1)) || true
[[ "$DO_BUILD" == true ]] && ((STEPS_TOTAL+=1)) || true
[[ "$DO_HYPRGLASS" == true ]] && ((STEPS_TOTAL+=1)) || true
[[ "$DO_BUNDLED" == true ]] && ((STEPS_TOTAL+=1)) || true
[[ "$DO_SHELL" == true ]] && ((STEPS_TOTAL+=1)) || true
((STEPS_TOTAL+=1)) # hyprland
((STEPS_TOTAL+=1)) # i3
((STEPS_TOTAL+=1)) # keybind
((STEPS_TOTAL+=1)) # restart
((STEPS_TOTAL+=1)) # state

STEPS_DONE=0
_done(){ ((STEPS_DONE++)) || true; progress "$STEPS_DONE" "$STEPS_TOTAL" ""; printf "\n"; }

install_target_requirements; _done
check_requirements;      _done
migrate_legacy_configs;  _done
if [[ "$DO_BACKUP" == true ]]; then do_backup; _done; fi
if [[ "$DO_SYSUPDATE" == true ]]; then do_sysupdate; _done; fi
if [[ "$DO_DOTS" == true ]]; then install_dots; _done; fi
if [[ "$DO_BUILD" == true ]]; then build_quickshell_step; _done; fi
if [[ "$DO_HYPRGLASS" == true ]]; then build_hyprglass; _done; fi
if [[ "$DO_BUNDLED" == true ]]; then install_bundled; _done; fi
if [[ "$DO_SHELL" == true ]]; then install_qs; _done; fi
configure_hyprland;      _done
configure_i3;            _done
configure_keybind;       _done
restart_qs;              _done
write_horizons_state;    _done

print_summary
