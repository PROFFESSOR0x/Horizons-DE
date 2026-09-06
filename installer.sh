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
#       --reinstall-dots    Re-apply the base dotfiles (kitty/fish/fuzzel/matugen/...)
#                           as well. They are installed once, on the first install,
#                           and then left alone; only the Hyprland config is
#                           refreshed on later runs. This restores them from the
#                           repo, discarding local edits to those files.
#       --components <csv>  Comma-separated overrides: dots,shell,bundled,build,deps,sysupdate,backup
#                           Prefix with ^/- /no- to disable: --components no-dots,^bundled
#       --with-deps         Install dependencies (default: via profile)
#       --skip-deps         Skip dependencies
#       --with-sysupdate    Full system upgrade (pacman -Syu / dnf upgrade)
#       --skip-sysupdate    Skip system upgrade (default)
#       --with-build        Build quickshell from source
#       --skip-build        Skip building
#       --with-bundled      Install bundled extras (Rubik, Gabarito, Bibata, GoogleSans)
#       --skip-bundled      Skip bundled extras
#       --launchers <csv>   Optional launchers to install: walker,vicinae (or "none").
#                           Omit to be asked interactively; Fuzzel + the built-in
#                           Quickshell launcher need nothing extra either way.
#       --skip-launchers    Don't offer/install optional launchers at all
#       --with-backup       Backup existing configs (default)
#       --skip-backup       Skip backup
#       --existing-config <action>  ask | keep | backup | delete detected non-Horizons configs
#       --with-fontset <set> Use dotfiles fontset
#       --via-nix           Use Nix/Home-manager for deps (experimental)
#       --build-force       Force rebuild even if binaries exist
#       --skip-dots         (compat) Skip dotfiles base install
#       --skip-qs           (compat) Skip Quickshell shell config
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
DO_BUNDLED=false
DO_BUILD=false
DO_SYSUPDATE=false
DO_DEPS=true
DO_BACKUP=true
BUILD_FORCE=false

# Optional launchers (Walker, Vicinae) — see install_launchers() below.
# Fuzzel is already a hard dependency and the built-in Quickshell launcher
# needs no package, so this is only ever about the two external ones.
DO_LAUNCHERS=true
LAUNCHERS_CSV=""

# Installation target. Hyprland is a Wayland compositor; i3 is an X11 window
# manager. These are deliberately stored independently from the profile.
HORIZONS_PROTOCOL=""
HORIZONS_WINDOW_MANAGER=""
HORIZONS_DESKTOP_ENVIRONMENT=""
HORIZONS_PROTOCOL_CLI=false
HORIZONS_WINDOW_MANAGER_CLI=false
HORIZONS_DESKTOP_ENVIRONMENT_CLI=false
FRESH_INSTALL=false
# The base dots are laid down once and then belong to the user; only the
# Hyprland config keeps being refreshed. This forces the base set back to the
# repo's copy. See dots_install_scope in install_dots().
REINSTALL_DOTS=false

# Legacy compat flags (mapped later)
SKIP_DEPS=false
SKIP_DOTS=false
SKIP_QS=false
SKIP_BACKUP=false
SKIP_SYSUPDATE=false
WITH_VIA_NIX=false
FONTSET_DIR_NAME=""
INSTALL_VIA_NIX=false

COMMAND="install"
SHOW_PROFILES=false

# Language (en / ar) — chosen at start of installer
HORIZONS_LANG="en"
HORIZONS_LANG_CLI=""
EXISTING_CONFIG_ACTION="ask" # ask | keep | backup | delete

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
    # Print the whole leading comment block, stopping at the first non-comment
    # line. The old `sed -n '2,55p'` was a hardcoded range that had already
    # drifted - it cut the help off mid-list, hiding --show-profiles, --lang,
    # --uninstall, --update and --check-update - and would drift again on the
    # next header edit. Also strips a bare "#" so blank comment lines render as
    # blank lines instead of a stray hash.
    awk 'NR==1 {next} /^#/ {sub(/^# ?/, ""); print; next} {exit}' "$0"
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
    --reinstall-dots) REINSTALL_DOTS=true; shift ;;
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
    --launchers) LAUNCHERS_CSV="${2,,}"; DO_LAUNCHERS=true; shift 2 ;;
    --skip-launchers) DO_LAUNCHERS=false; shift ;;
    --with-backup) DO_BACKUP=true; SKIP_BACKUP=false; shift ;;
    --skip-backup) DO_BACKUP=false; SKIP_BACKUP=true; shift ;;
    --existing-config) EXISTING_CONFIG_ACTION="${2,,}"; shift 2 ;;
    --skip-dots) SKIP_DOTS=true; shift ;;
    --skip-qs|--skip-quickshell) SKIP_QS=true; shift ;;
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

case "$EXISTING_CONFIG_ACTION" in
  ask|keep|backup|delete) ;;
  *) echo -e "${R}Invalid --existing-config value: $EXISTING_CONFIG_ACTION (use ask, keep, backup, delete)${RST}"; exit 1 ;;
esac

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
  # Only dots/.config/hypr is Hyprland-specific. The rest of the bundled dots
  # - matugen (the wallpaper-theming engine the shell's own
  # appearance.wallpaperTheming drives), fuzzel (which i3/horizons.conf's
  # clipboard and emoji binds fall back to), kitty, foot, fontconfig, fish,
  # mpv, Kvantum, wlogout, xdg-desktop-portal - are all WM-agnostic and are
  # exactly what makes an i3 session look and behave like Horizons rather than
  # like bare i3.
  #
  # This used to disable DO_DOTS wholesale for i3 on the premise that "the
  # bundled dots are Hyprland-only", so an i3 install silently got none of it.
  # install_dots() now passes --skip-hyprland --skip-hyprland-entry for an i3
  # target instead, which drops precisely the Hyprland part and keeps the rest.
  #
  # `existing` (integrating into a running KDE/GNOME session) is a different
  # case and still opts out: those dots include kdeglobals/dolphinrc/Kvantum,
  # which would overwrite the desktop the user asked us to integrate *with*.
  if [[ "$HORIZONS_DESKTOP_ENVIRONMENT" == "existing" ]]; then
    DO_DOTS=false
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
# Compares every directory the dots actually install, not just hypr/hyprland.
#
# This used to look at dots/.config/hypr/hyprland alone, so an update that
# touched kitty, fish, fuzzel, matugen, mpv, foot, Kvantum, wlogout,
# kde-material-you-colors, xdg-desktop-portal or fontconfig - i.e. most of what
# `dotfiles/setup install` copies - reported "already up-to-date" and the whole
# dots step was skipped. Those changes then only ever reached a fresh install,
# never an existing one.
#
# Mirrors the install rules in dotfiles/sdata/subcmd-install/3.files-legacy.sh:
#   - hypr: only hypr/hyprland is --delete-synced there (hypr/custom is
#     install-if-absent and user-owned, so a local edit in it is expected and
#     must not count as drift)
#   - fish: conf.d is excluded from the sync there, so exclude it here too
#   - quickshell: not shipped by this fork at all (Horizons has its own shell/
#     tree) - see the --skip-quickshell note in install_dots
# Scope: "all" (default) walks every installed directory; "hypr" looks only at
# the Hyprland config, which is what a re-apply is allowed to touch once the
# base dots have been laid down (see dots_install_scope in install_dots).
# Returns 0 if an update is needed, 1 if the installed copy already matches.
dotfiles_need_update(){
  local scope="${1:-all}"
  local dots_root="$DOTS_REPO/dots/.config"
  [[ -d "$dots_root" ]] || return 0
  command -v rsync &>/dev/null || return 0   # can't tell -> assume yes

  # Same-commit gate first: a matching recorded commit is a cheap way to skip
  # the checksum walk entirely on a no-op re-run.
  if [[ -f "$HORIZONS_META_JSON" ]] && declare -f horizons_state_get &>/dev/null; then
    local recorded_commit current_commit
    recorded_commit=$(horizons_state_get git_commit 2>/dev/null || echo "")
    current_commit=$(git -C "$REPO_ROOT" rev-parse --short HEAD 2>/dev/null || echo "unknown")
    [[ -n "$recorded_commit" && "$recorded_commit" == "$current_commit" ]] || return 0
  else
    return 0
  fi

  local entry name src dst diff_count
  local -a excludes
  for entry in "$dots_root"/*; do
    [[ -e "$entry" ]] || continue
    name="$(basename "$entry")"
    excludes=(--exclude=.git)
    [[ "$scope" == "hypr" && "$name" != "hypr" ]] && continue
    case "$name" in
      quickshell) continue ;;                     # not shipped by this fork
      hypr)
        # i3 targets never receive the Hyprland config, so its absence is not drift.
        [[ "$HORIZONS_WINDOW_MANAGER" == "i3" ]] && continue
        src="$entry/hyprland"; dst="$XDG_CONFIG_HOME/hypr/hyprland" ;;
      fish)
        src="$entry"; dst="$XDG_CONFIG_HOME/$name"; excludes+=(--exclude=conf.d) ;;
      *)
        src="$entry"; dst="$XDG_CONFIG_HOME/$name" ;;
    esac
    [[ -d "$src" ]] || continue
    [[ -d "$dst" ]] || return 0                   # never installed -> needs update
    diff_count=$(rsync -ani --checksum "${excludes[@]}" "$src/" "$dst/" 2>/dev/null | grep -cE "^>" || true)
    if [[ "${diff_count:-0}" -gt 0 ]]; then
      verbose_log "dots drift in $name ($diff_count file(s))"
      return 0
    fi
  done
  return 1  # everything matches
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

# Does the installed shell actually differ from this repo's shell/ tree?
#
# is_horizons_shell() answers "is what's installed *ours*", and it says yes as
# soon as the identity marker exists - it is not, and cannot be, a freshness
# test. install_qs() used it as one, so on any re-run where the marker was
# present it reported "already Horizons and up-to-date" and skipped the sync,
# defaulting the interactive prompt to "no" - the shell then never picked up
# repo changes unless the user happened to pass --force/--build-force.
# Returns 0 if a sync is needed.
horizons_shell_needs_sync(){
  [[ -d "$QS_CONFIG_DIR" ]] || return 0
  [[ -f "$QS_CONFIG_DIR/shell.qml" ]] || return 0
  command -v rsync &>/dev/null || return 0   # can't tell -> sync
  local diff_count
  local -a _ex=(--exclude=.git --exclude='*.so' --exclude='*.o' --exclude=__pycache__)
  diff_count=$(rsync -ani --checksum --delete "${_ex[@]}" "$QS_REPO/" "$QS_CONFIG_DIR/" 2>/dev/null | grep -cE '^(>|\*deleting)' || true)
  [[ "${diff_count:-1}" -gt 0 ]]
}

# ── Existing desktop configuration inventory ─────────────────────────────────
# Only known, explicit paths are ever offered here. This deliberately does not
# scan arbitrary dotfiles or remove a parent directory such as ~/.config.
detect_existing_desktop_configs(){
  EXISTING_CONFIG_LABELS=()
  EXISTING_CONFIG_PATHS=()
  local label path
  local -a candidates=(
    "Hyprland:$XDG_CONFIG_HOME/hypr"
    "legacy Hyprland:$XDG_CONFIG_HOME/hyprland"
    "i3:$XDG_CONFIG_HOME/i3"
    "i3status:$XDG_CONFIG_HOME/i3status"
    "Quickshell:$XDG_CONFIG_HOME/quickshell"
    "AGS:$XDG_CONFIG_HOME/ags"
    "Waybar:$XDG_CONFIG_HOME/waybar"
    "Polybar:$XDG_CONFIG_HOME/polybar"
    "Eww:$XDG_CONFIG_HOME/eww"
    "Kitty:$XDG_CONFIG_HOME/kitty"
    "Fish:$XDG_CONFIG_HOME/fish"
  )
  for item in "${candidates[@]}"; do
    label="${item%%:*}"; path="${item#*:}"
    [[ -e "$path" ]] || continue
    # Horizons' own separate shell directory is not an external config.
    [[ "$path" == "$QS_CONFIG_DIR" ]] && continue
    # Do not offer the parent QuickShell directory when it contains only the
    # Horizons profile we are installing/updating.
    if [[ "$path" == "$XDG_CONFIG_HOME/quickshell" && -d "$QS_CONFIG_DIR" ]]; then
      local child_count
      child_count=$(find "$path" -mindepth 1 -maxdepth 1 -printf '.' 2>/dev/null | wc -c)
      [[ "$child_count" -le 1 ]] && continue
    fi
    EXISTING_CONFIG_LABELS+=("$label")
    EXISTING_CONFIG_PATHS+=("$path")
  done
}

handle_existing_desktop_configs(){
  detect_existing_desktop_configs
  (( ${#EXISTING_CONFIG_PATHS[@]} > 0 )) || { info "No existing Hyprland/i3 shell or dotfile configs detected."; return 0; }

  step "Detected existing shells and dotfiles"
  local i
  for i in "${!EXISTING_CONFIG_PATHS[@]}"; do
    printf "  ${Y}•${RST} %-18s %s\n" "${EXISTING_CONFIG_LABELS[$i]}" "${EXISTING_CONFIG_PATHS[$i]}"
  done

  local action="$EXISTING_CONFIG_ACTION"
  if [[ "$action" == ask ]]; then
    if [[ "$ASK" == false ]]; then
      action=keep
      info "Non-interactive mode keeps detected configs by default. Use --existing-config backup or delete to choose explicitly."
    else
      printf "\n  ${B}Choose how to handle the detected configurations:${RST}\n"
      printf "    ${G}1)${RST} Keep them unchanged (default)\n"
      printf "    ${G}2)${RST} Create a backup copy\n"
      printf "    ${G}3)${RST} Delete them permanently\n"
      printf "  ${B}> ${RST}"; read -r config_choice || config_choice="1"
      case "$config_choice" in
        2|backup) action=backup ;;
        3|delete) action=delete ;;
        *) action=keep ;;
      esac
    fi
  fi

  case "$action" in
    keep)
      info "Keeping all detected configurations unchanged."
      return 0 ;;
    backup)
      local inventory_backup="$XDG_STATE_HOME/horizons/existing-config-backups/$(date +%Y%m%d-%H%M%S)"
      if [[ "$DRY_RUN" == true ]]; then
        info "[dry-run] would back up detected configs to $inventory_backup"
        return 0
      fi
      run mkdir -p "$inventory_backup"
      for i in "${!EXISTING_CONFIG_PATHS[@]}"; do
        run cp -a "${EXISTING_CONFIG_PATHS[$i]}" "$inventory_backup/${EXISTING_CONFIG_LABELS[$i]// /_}"
      done
      ok "Existing configuration backup saved to: $inventory_backup"
      return 0 ;;
    delete)
      warn "This permanently deletes only the listed configuration paths. It never deletes ~/.config itself."
      if [[ "$ASK" == false ]]; then
        die "Refusing non-interactive deletion. Re-run interactively and confirm the exact deletion."
      fi
      printf "  Type DELETE to remove all %d detected paths: " "${#EXISTING_CONFIG_PATHS[@]}"
      local confirmation=""; read -r confirmation || true
      [[ "$confirmation" == DELETE ]] || { info "Deletion cancelled; all configurations were kept."; return 0; }
      [[ "$DRY_RUN" == true ]] && { info "[dry-run] would delete only the listed paths."; return 0; }
      for i in "${!EXISTING_CONFIG_PATHS[@]}"; do
        run rm -rf -- "${EXISTING_CONFIG_PATHS[$i]}"
      done
      ok "Detected configurations deleted."
      return 0 ;;
  esac
}

# ── Requirement checks ────────────────────────────────────────────────────────
check_requirements(){
  step "$(L "Pre-flight checks (smart — skips what is already installed)" "الفحوصات الأولية (ذكية — تتخطى ما هو مثبت بالفعل)")"
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

# ── Remove a previously-installed hyprglass ──────────────────────────────────
# hyprglass (the vendored shell/plugins/hyprglass Hyprland plugin) was removed
# from this repo in favor of Hyprland's own native decoration:blur:variant.
# A plain re-sync of shell/ (install_qs's rsync --delete) already removes the
# deployed plugin .so from $QS_CONFIG_DIR, but that step can be skipped on an
# "already up to date" update, and several other hyprglass traces live
# outside anything install_qs touches at all: a plugin actually loaded into a
# *running* Hyprland, one added via `hyprpm`, and the generated
# shellOverrides/hyprglass.lua. Runs unconditionally and idempotently (a
# clean install just no-ops silently) so it always fires on install *and*
# update, not just for users who remember to ask for it.
cleanup_hyprglass(){
  step "$(L "Remove any previously-installed hyprglass" "إزالة أي نسخة مثبتة مسبقاً من hyprglass")"
  local found=false

  # Unload from a *running* Hyprland first — files can be deleted safely
  # regardless, but the compositor keeps a crashy plugin mapped into its own
  # process until it's told to unload (or Hyprland itself restarts).
  if command -v hyprctl &>/dev/null && hyprctl -j plugin list &>/dev/null; then
    local loaded_paths
    loaded_paths=$(hyprctl -j plugin list 2>/dev/null | grep -oP '"path"\s*:\s*"\K[^"]*hyprglass[^"]*' || true)
    if [[ -n "$loaded_paths" ]]; then
      while IFS= read -r p; do
        [[ -n "$p" ]] || continue
        warn "Unloading hyprglass from the running Hyprland: $p"
        run hyprctl plugin unload "$p"
        found=true
      done <<< "$loaded_paths"
    fi
  fi

  # hyprpm-managed install (the old README suggested `hyprpm add .../hyprglass`
  # as an alternative to the bundled build — not something install_qs touches).
  if command -v hyprpm &>/dev/null && hyprpm list 2>/dev/null | grep -qi hyprglass; then
    warn "Found hyprglass installed via hyprpm — removing."
    run hyprpm remove hyprglass
    found=true
  fi

  # Deployed files nothing else would clean up on a skipped/partial sync.
  local stale_paths=(
    "$QS_CONFIG_DIR/plugins/hyprglass"
    "$XDG_CONFIG_HOME/hypr/hyprland/shellOverrides/hyprglass.lua"
  )
  local p
  for p in "${stale_paths[@]}"; do
    if [[ -e "$p" ]]; then
      warn "Removing stale hyprglass file: $p"
      run rm -rf "$p"
      found=true
    fi
  done

  # A stray classic-syntax hyprland.conf whose only job was loading the
  # plugin (`plugin = /path/to/hyprglass.so`) — harmless to Hyprland's own
  # config resolution either way, but pure clutter now, and worth clearing
  # out rather than leaving a dead reference to a file we just deleted.
  local legacy_conf="$XDG_CONFIG_HOME/hypr/hyprland.conf"
  if [[ -f "$legacy_conf" ]] && grep -qi hyprglass "$legacy_conf" 2>/dev/null; then
    warn "Found a legacy hyprland.conf referencing hyprglass: $legacy_conf"
    if [[ "$DRY_RUN" == true ]]; then
      info "[dry-run] would strip hyprglass line(s) from $legacy_conf (removing the file entirely if that's all it contained)"
    else
      sed -i '/hyprglass/Id' "$legacy_conf" 2>/dev/null || true
      if [[ ! -s "$legacy_conf" ]]; then
        rm -f "$legacy_conf"
        ok "Removed now-empty legacy $legacy_conf"
      else
        ok "Stripped hyprglass reference(s) from $legacy_conf"
      fi
    fi
    found=true
  fi

  if [[ "$found" == true ]]; then
    if command -v hyprctl &>/dev/null && hyprctl version &>/dev/null 2>&1; then
      run hyprctl reload
    fi
    ok "hyprglass cleaned up."
  else
    info "No installed hyprglass found — nothing to remove."
  fi
  return 0
}

# ── Optional launchers (Walker, Vicinae) ──────────────────────────────────────
# Settings > Services > Search > Launcher (ServicesConfig.qml) lets the user
# pick among the built-in Quickshell launcher, Walker, Vicinae, and Fuzzel —
# but only Fuzzel ships as a hard dependency (illogical-impulse-widgets) and
# the built-in one needs nothing extra. This step installs whichever of the
# two *external* launchers the user actually wants, so picking them in
# Settings isn't a dead end. Never edits config.json itself (a running
# Quickshell owns that file); it just makes the binaries available and tells
# the user to flip the Settings switch afterward.
install_launchers(){
  step "$(L "Optional launchers (Walker / Vicinae)" "أدوات تشغيل اختيارية (Walker / Vicinae)")"
  info "$(L "Fuzzel is already installed as a core dependency, and the built-in Quickshell launcher needs nothing extra — this only installs the two external options." "Fuzzel مثبت مسبقاً كاعتماد أساسي، ومشغّل Quickshell المدمج لا يحتاج شيئاً إضافياً — هذه الخطوة تثبّت فقط الخيارين الخارجيين.")"

  local selection="$LAUNCHERS_CSV"
  if [[ -z "$selection" ]]; then
    if [[ "$ASK" == false ]]; then
      info "$(L "No --launchers selection in non-interactive mode; skipping (use --launchers walker,vicinae or --launchers none)." "لا يوجد اختيار --launchers في الوضع غير التفاعلي؛ سيتم التخطي (استخدم --launchers walker,vicinae أو --launchers none).")"
      return 0
    fi
    local picks=()
    confirm "$(L "Install Walker (+ its Elephant search backend)?" "تثبيت Walker (+ محرك البحث Elephant الخاص به)؟")" "n" && picks+=("walker")
    confirm "$(L "Install Vicinae?" "تثبيت Vicinae؟")" "n" && picks+=("vicinae")
    if [[ ${#picks[@]} -eq 0 ]]; then
      info "$(L "No external launcher selected — keeping the built-in Quickshell launcher / Fuzzel." "لم يتم اختيار أداة تشغيل خارجية — سيتم الإبقاء على مشغّل Quickshell المدمج / Fuzzel.")"
      return 0
    fi
    selection=$(IFS=,; echo "${picks[*]}")
  fi

  if [[ "$selection" == "none" ]]; then
    info "$(L "Skipping external launchers (--launchers none)." "تخطي أدوات التشغيل الخارجية (--launchers none).")"
    return 0
  fi

  local installed_any=false item
  local old_ifs="$IFS"; IFS=','
  for item in $selection; do
    IFS="$old_ifs"
    item="${item//[[:space:]]/}"
    case "$item" in
      walker)  install_launcher_walker  && installed_any=true ;;
      vicinae) install_launcher_vicinae && installed_any=true ;;
      fuzzel|quickshell|"") : ;; # already available, nothing to do
      *) warn "$(L "Unknown launcher '$item' (expected: walker, vicinae, none)" "أداة تشغيل غير معروفة '$item' (المتوقع: walker أو vicinae أو none)")" ;;
    esac
    IFS=','
  done
  IFS="$old_ifs"

  if [[ "$installed_any" == true ]]; then
    ok "$(L "Launcher(s) installed. Pick one in Settings > Services > Search > Launcher to switch to it." "تم التثبيت. اختر أداة التشغيل من الإعدادات > الخدمات > البحث > أداة التشغيل لتفعيلها.")"
  fi
  return 0
}

# Walker (github.com/abenz1267/walker) needs its companion Elephant backend
# daemon (github.com/abenz1267/elephant) running for search results.
install_launcher_walker(){
  step "$(L "Installing Walker" "تثبيت Walker")"
  if [[ "${PKG_GROUP:-unknown}" != arch ]]; then
    warn "$(L "Walker is only packaged for Arch/AUR right now — install it manually: https://github.com/abenz1267/walker" "Walker متوفر حالياً فقط عبر AUR على Arch — ثبّته يدوياً: https://github.com/abenz1267/walker")"
    return 1
  fi
  if ! command -v yay &>/dev/null && ! command -v paru &>/dev/null; then
    warn "$(L "No AUR helper (yay/paru) found — install one, then re-run with --launchers walker." "لم يتم العثور على أداة AUR (yay/paru) — ثبّت واحدة ثم أعد التشغيل مع --launchers walker.")"
    return 1
  fi

  local all_ok=true
  if ! command -v walker &>/dev/null; then
    hz_install_aur_package Walker walker-bin || hz_install_aur_package Walker walker \
      || { warn "$(L "Could not install Walker from the AUR." "تعذر تثبيت Walker من AUR.")"; all_ok=false; }
  else
    info "$(L "Walker is already installed." "Walker مثبت بالفعل.")"
  fi

  if ! command -v elephant &>/dev/null; then
    hz_install_aur_package Elephant elephant-bin || hz_install_aur_package Elephant elephant \
      || { warn "$(L "Could not install Elephant (Walker's search backend) from the AUR." "تعذر تثبيت Elephant (محرك بحث Walker) من AUR.")"; all_ok=false; }
  else
    info "$(L "Elephant is already installed." "Elephant مثبت بالفعل.")"
  fi

  # Elephant's own README explicitly warns against a system-level systemd
  # service (it loses the user's session environment) — its CLI manages the
  # correct user-scope unit (~/.config/systemd/user/elephant.service) for us.
  if command -v elephant &>/dev/null; then
    run elephant service enable
  fi

  [[ "$all_ok" == true ]] && command -v walker &>/dev/null
}

# Vicinae (github.com/vicinaehq/vicinae) ships its own systemd --user unit
# (vicinae.service) inside the package itself — enabling it is all that's
# needed to start vicinae-server in the background.
install_launcher_vicinae(){
  step "$(L "Installing Vicinae" "تثبيت Vicinae")"
  if [[ "${PKG_GROUP:-unknown}" != arch ]]; then
    warn "$(L "Vicinae isn't packaged for this distro yet — install it manually: https://docs.vicinae.com" "Vicinae غير متوفر كحزمة لهذا التوزيع بعد — ثبّته يدوياً: https://docs.vicinae.com")"
    return 1
  fi
  if ! command -v yay &>/dev/null && ! command -v paru &>/dev/null; then
    warn "$(L "No AUR helper (yay/paru) found — install one, then re-run with --launchers vicinae." "لم يتم العثور على أداة AUR (yay/paru) — ثبّت واحدة ثم أعد التشغيل مع --launchers vicinae.")"
    return 1
  fi

  if ! command -v vicinae &>/dev/null; then
    hz_install_aur_package Vicinae vicinae-bin || hz_install_aur_package Vicinae vicinae \
      || { warn "$(L "Could not install Vicinae from the AUR." "تعذر تثبيت Vicinae من AUR.")"; return 1; }
  else
    info "$(L "Vicinae is already installed." "Vicinae مثبت بالفعل.")"
  fi

  if command -v systemctl &>/dev/null; then
    run systemctl --user daemon-reload
    run systemctl --user enable --now vicinae.service
  fi

  command -v vicinae &>/dev/null
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

  # Hyprland config is only Horizons' business when Hyprland is the target.
  # On an i3/X11 install this block used to run anyway and "replace (with
  # backup)" the user's completely unrelated Hyprland config - a WM this
  # install is not even touching.
  local targeting_hyprland=true
  [[ "$HORIZONS_WINDOW_MANAGER" == "i3" ]] && targeting_hyprland=false

  # ── What this run is allowed to write ──────────────────────────────────────
  # The base dots (kitty, fish, fuzzel, matugen, mpv, foot, Kvantum, wlogout,
  # fontconfig, xdg-desktop-portal, ...) are a starting point, not managed
  # state: once they are on disk they belong to the user, and re-running the
  # installer used to --delete-sync straight over local edits to any of them on
  # every single update.
  #
  # The Hyprland config is the opposite - it is the compositor half of this
  # shell, changes in lockstep with it (keybinds.lua drives every
  # quickshell:... global shortcut), and has to keep being refreshed. Anything
  # the user wants to keep there goes in hypr/custom, which the dots install
  # with install_dir__ignore_existing and never overwrite.
  #
  #   full : first install (or --reinstall-dots) - every file step
  #   hypr : later runs - only dots/.config/hypr
  #   none : nothing left for this run to do
  local dots_install_scope="full"
  local dots_first_install=true
  if declare -f horizons_state_is_installed &>/dev/null && horizons_state_is_installed; then
    dots_first_install=false
  fi
  if [[ "$dots_first_install" == false && "$REINSTALL_DOTS" == false ]]; then
    if [[ "$targeting_hyprland" == true ]]; then
      dots_install_scope="hypr"
    else
      dots_install_scope="none"
    fi
  fi

  if [[ "$dots_install_scope" == "none" ]]; then
    info "$(L "Base dotfiles are already installed and are yours to edit — nothing to re-apply on i3 (use --reinstall-dots to restore them)." "ملفات النقاط الأساسية مثبتة بالفعل وهي ملكك للتعديل — لا شيء لإعادة تطبيقه على i3 (استخدم --reinstall-dots لاستعادتها).")"
    return 0
  fi
  if [[ "$dots_install_scope" == "hypr" ]]; then
    info "$(L "Re-applying the Hyprland config only; base dotfiles are left as you have them (--reinstall-dots to restore them)." "إعادة تطبيق إعدادات Hyprland فقط؛ ملفات النقاط الأساسية ستُترك كما هي (--reinstall-dots لاستعادتها).")"
  fi

  # ── Smart: if hypr exists and NOT horizons → force replace with backup
  local force_hypr_replace=false
  if [[ "$targeting_hyprland" == true && -d "$XDG_CONFIG_HOME/hypr" ]]; then
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
      if ! dotfiles_need_update "$dots_install_scope"; then
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
  elif [[ "$targeting_hyprland" == false ]]; then
    # i3 target: there is no hypr config to reason about, but the rest of the
    # dots (kitty/fish/fuzzel/matugen/...) still need the same up-to-date check
    # so a routine update doesn't re-run the whole setup for nothing.
    if ! dotfiles_need_update "$dots_install_scope"; then
      ok "Dotfiles are already up to date — nothing to copy."
      if [[ "$FORCE" == true || "$ASK" == false ]]; then
        [[ "$BUILD_FORCE" == false ]] && { info "Skipping dotfiles (up-to-date)."; return 0; }
      elif confirm "$(L "Skip copying dotfiles (identical)?" "تخطي نسخ ملفات النقاط (متطابقة)؟")" "y"; then
        info "$(L "Skipped dotfiles — already current." "تم تخطي ملفات النقاط — محدثة بالفعل.")"
        return 0
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

  # Always. The dots' own file step does:
  #     install_dir__sync dots/.config/quickshell "$XDG_CONFIG_HOME"/quickshell
  # and install_dir__sync is `rsync -a --delete SRC/ DEST/` over the *whole*
  # ~/.config/quickshell directory (upstream widened it from .../ii on purpose,
  # see end-4/dots-hyprland#2294). Horizons ships its own shell out of this
  # repo's shell/ tree into ~/.config/quickshell/horizons and carries no
  # dots/.config/quickshell at all, so leaving that step enabled means:
  #   - every run errors out on a source directory that does not exist, and
  #   - if dots/.config/quickshell is ever restored from upstream, the --delete
  #     takes ~/.config/quickshell/horizons with it.
  # install_qs() is the only thing that should ever write under
  # ~/.config/quickshell.
  setup_args+=(--skip-quickshell)

  # Hypr-only re-apply: turn off the other three file steps in
  # dotfiles/sdata/subcmd-install/3.files-legacy.sh (MISCCONF / FISH /
  # FONTCONFIG), leaving the HYPRLAND step as the only one that writes.
  if [[ "$dots_install_scope" == "hypr" ]]; then
    setup_args+=(--skip-miscconf --skip-fish --skip-fontconfig)
  fi

  # i3/X11 target: do not install the Hyprland config at all. Nothing in an i3
  # session reads ~/.config/hypr, and writing it would clobber the Hyprland
  # setup of a user who dual-boots between the two.
  if [[ "$targeting_hyprland" == false ]]; then
    info "$(L "i3/X11 target — skipping the Hyprland dotfiles." "الهدف i3/X11 — تخطي ملفات Hyprland.")"
    setup_args+=(--skip-hyprland --skip-hyprland-entry)
  elif [[ "$force_hypr_replace" == true ]]; then
    # Previously this only printed a message and added nothing, so "forcing"
    # was a no-op: a --skip-hyprland arriving from anywhere else still won.
    info "Forcing hyprland reinstall (was non-Horizons)."
    setup_args=("${setup_args[@]/--skip-hyprland}")
    setup_args=("${setup_args[@]/--skip-hyprland-entry}")
  fi
  # Drop any empties the substitutions above may have left behind.
  local _cleaned=(); local _a
  for _a in "${setup_args[@]}"; do [[ -n "$_a" ]] && _cleaned+=("$_a"); done
  setup_args=("${_cleaned[@]}")
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
  # Skip only when the installed copy is ours AND byte-identical to shell/.
  # "Ours" alone is not enough - that is true of every previous version too.
  if [[ -d "$QS_CONFIG_DIR" ]] && is_horizons_shell && ! horizons_shell_needs_sync; then
    if [[ "$BUILD_FORCE" == false && "$FORCE" == false ]]; then
      ok "Quickshell config already Horizons and identical to shell/ — nothing to sync."
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
      warn "Force mode — re-syncing even though shell is already identical."
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
    if [[ -d "$QS_CONFIG_DIR" ]] && is_horizons_shell && ! horizons_shell_needs_sync; then
      info "[dry-run] QS already horizons and identical — would skip unless --build-force"
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
    --out-format='%n' \
    "$QS_REPO/" "$QS_CONFIG_DIR/" 2>&1 | while IFS= read -r line; do
      ((copied++)) || true
      progress "$copied" "$total" "$line"
    done
  printf "\n"
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
  # A brand-new i3 install has no config yet until i3-config-wizard runs (or
  # never gets one at all, e.g. launched non-interactively) - this used to
  # silently skip integration entirely in that case, so Horizons never got
  # wired up on a truly fresh i3/X11 machine. Seed one from i3's own
  # packaged default (same template i3-config-wizard itself offers) instead
  # of leaving it to chance.
  if [[ ! -f "$i3_config" ]]; then
    local i3_default_config=""
    for candidate in /etc/i3/config /usr/share/i3/config /usr/etc/i3/config; do
      [[ -f "$candidate" ]] && { i3_default_config="$candidate"; break; }
    done
    if [[ -z "$i3_default_config" ]]; then
      warn "$(L "No i3 config found and no packaged i3 default template either — skipping i3 integration." "لا يوجد ملف إعداد i3 ولا قالب i3 الافتراضي المرفق — تخطي تكامل i3.")"
      return 0
    fi
    info "$(L "No i3 config yet — seeding one from" "لا يوجد إعداد i3 بعد — سيتم إنشاؤه من"): $i3_default_config"
    if [[ "$DRY_RUN" == true ]]; then
      info "[dry-run] would create $i3_config from $i3_default_config"
    else
      run mkdir -p "$(dirname "$i3_config")"
      run cp "$i3_default_config" "$i3_config"
    fi
  fi

  step "$(L "Configure i3/X11 shell" "إعداد واجهة i3/X11")"
  local already_included=false
  grep -Fq 'include ~/.config/i3/horizons.conf' "$i3_config" 2>/dev/null && already_included=true

  if [[ "$already_included" == true ]]; then
    # horizons.conf itself is Horizons-owned content (like the update
    # protocol re-applies dotfiles) — it must keep being refreshed from the
    # repo on every update, not just written once on first install, or a
    # user who already integrated i3 back when this file only had 2
    # keybinds would never receive any of the newer ones. Only the
    # first-time confirm + `include` line below are one-shot.
    if [[ ! -f "$source_i3" ]]; then
      warn "Horizons i3 template is missing: $source_i3"
      return 1
    fi
    if [[ -f "$horizons_i3" ]] && cmp -s "$source_i3" "$horizons_i3"; then
      ok "Horizons i3 integration already up to date."
      return 0
    fi
    if [[ "$DRY_RUN" == true ]]; then
      info "[dry-run] would refresh $horizons_i3 from $source_i3"
      return 0
    fi
    [[ -f "$horizons_i3" ]] && run cp "$horizons_i3" "${horizons_i3}.horizons.bak"
    run cp "$source_i3" "$horizons_i3"
    ok "Horizons i3 integration refreshed. Previous version backed up to: ${horizons_i3}.horizons.bak"
  else
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
    printf "\n# Horizons i3/X11 integration\ninclude ~/.config/i3/horizons.conf\n" >> "$i3_config"
    ok "i3 integration enabled. Backup saved to: ${i3_config}.horizons.bak"
  fi

  # i3/horizons.conf assumes Quickshell's own bar is the only bar — a
  # leftover `bar { ... }` block from the distro-default template (or a
  # pre-existing custom config) draws i3's native status bar on top of/
  # underneath it. Only Horizons' own include is touched anywhere in this
  # function, so surface this as a warning to act on manually rather than
  # silently editing a block that might carry the user's own customization.
  if [[ "$DRY_RUN" != true ]] && grep -Eq '^[[:space:]]*bar[[:space:]]*\{' "$i3_config" 2>/dev/null; then
    warn "$(L "Your i3 config still has its own 'bar { ... }' block — you'll see i3's native status bar alongside Quickshell's own bar. Comment it out in $i3_config if you don't want both." "لا يزال إعداد i3 يحتوي على كتلة 'bar { ... }' الخاصة به — سترى شريط حالة i3 الأصلي بجانب شريط Quickshell. علّق عليها (اجعلها تعليقاً) في $i3_config إذا كنت لا تريد الاثنين معاً.")"
  fi

  # picom (blur/shadow/rounded corners on regular app windows — i3 itself
  # has no compositor, see i3/picom.conf's own header for why this can't be
  # replicated any other way). i3/horizons.conf's exec_always already
  # no-ops safely when picom isn't installed, so only the config file needs
  # placing; installing the picom package itself is left to the user like
  # every other optional i3 tool this installer doesn't manage dependencies
  # for yet (xclip/ffmpeg/slop — see docs/i3-quickshell-research.md).
  local picom_conf="$XDG_CONFIG_HOME/picom/horizons.conf"
  local source_picom="$REPO_ROOT/i3/picom.conf"
  if [[ -f "$source_picom" && "$DRY_RUN" != true ]]; then
    if [[ ! -f "$picom_conf" ]] || cmp -s "$source_picom" "$picom_conf"; then
      run mkdir -p "$(dirname "$picom_conf")"
      run cp "$source_picom" "$picom_conf"
    else
      info "$(L "Leaving existing $picom_conf untouched (differs from the bundled default)." "الإبقاء على $picom_conf كما هو (يختلف عن الإعداد الافتراضي المرفق).")"
    fi
  fi
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
  printf "  ${DM}${IT}Source: https://github.com/PROFFESSOR0x/Horizons-DE${RST}\n"
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
  [[ "$DO_BUNDLED" == true ]]   && printf "  ${G}✔${RST} $(L "Bundled extras (fonts/bibata)" "الإضافات المرفقة (خطوط/bibata)")\n" || printf "  ${DM}○ $(L "Skip bundled" "تخطي الإضافات")${RST}\n"
  [[ "$DO_SHELL" == true ]]     && printf "  ${G}✔${RST} $(L "Horizons Quickshell config" "إعدادات Horizons لـ Quickshell")\n" || printf "  ${DM}○ $(L "Skip shell" "تخطي الواجهة")${RST}\n"
  if [[ "$DO_LAUNCHERS" == true ]]; then
    if [[ -n "$LAUNCHERS_CSV" ]]; then
      printf "  ${G}✔${RST} $(L "Optional launchers:" "أدوات تشغيل اختيارية:") $LAUNCHERS_CSV\n"
    else
      printf "  ${G}✔${RST} $(L "Optional launchers (Walker/Vicinae — you'll be asked which)" "أدوات تشغيل اختيارية (Walker/Vicinae — سيتم سؤالك عن أيها)")\n"
    fi
  else
    printf "  ${DM}○ $(L "Skip optional launchers" "تخطي أدوات التشغيل الاختيارية")${RST}\n"
  fi
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
((STEPS_TOTAL+=1)) # existing config inventory
((STEPS_TOTAL+=1)) # target requirements
((STEPS_TOTAL+=1)) # check
((STEPS_TOTAL+=1)) # migrate
((STEPS_TOTAL+=1)) # hyprglass cleanup
[[ "$DO_BACKUP" == true ]] && ((STEPS_TOTAL+=1)) || true
[[ "$DO_SYSUPDATE" == true ]] && ((STEPS_TOTAL+=1)) || true
[[ "$DO_DOTS" == true ]] && ((STEPS_TOTAL+=1)) || true
[[ "$DO_BUILD" == true ]] && ((STEPS_TOTAL+=1)) || true
[[ "$DO_BUNDLED" == true ]] && ((STEPS_TOTAL+=1)) || true
[[ "$DO_SHELL" == true ]] && ((STEPS_TOTAL+=1)) || true
[[ "$DO_LAUNCHERS" == true ]] && ((STEPS_TOTAL+=1)) || true
((STEPS_TOTAL+=1)) # hyprland
((STEPS_TOTAL+=1)) # i3
((STEPS_TOTAL+=1)) # keybind
((STEPS_TOTAL+=1)) # restart
((STEPS_TOTAL+=1)) # state

STEPS_DONE=0
_done(){ ((STEPS_DONE++)) || true; progress "$STEPS_DONE" "$STEPS_TOTAL" ""; printf "\n"; }

handle_existing_desktop_configs; _done
install_target_requirements; _done
check_requirements;      _done
migrate_legacy_configs;  _done
cleanup_hyprglass;       _done
if [[ "$DO_BACKUP" == true ]]; then do_backup; _done; fi
if [[ "$DO_SYSUPDATE" == true ]]; then do_sysupdate; _done; fi
if [[ "$DO_DOTS" == true ]]; then install_dots; _done; fi
if [[ "$DO_BUILD" == true ]]; then build_quickshell_step; _done; fi
if [[ "$DO_BUNDLED" == true ]]; then install_bundled; _done; fi
if [[ "$DO_SHELL" == true ]]; then install_qs; _done; fi
if [[ "$DO_LAUNCHERS" == true ]]; then install_launchers; _done; fi
configure_hyprland;      _done
configure_i3;            _done
configure_keybind;       _done
restart_qs;              _done
write_horizons_state;    _done

print_summary
