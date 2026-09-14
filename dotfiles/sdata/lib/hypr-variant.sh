# Hyprland Lua-vs-legacy config variant detection.
# This script is meant to be sourced. It's not for directly running.
#
# Background: Hyprland >= 0.55 loads hyprland.lua INSTEAD of hyprland.conf
# (https://hypr.land/news/26_lua). Older builds — e.g. Ubuntu archive/PPA
# builds that predate the Lua update — ignore every *.lua file and load
# hyprland.conf (+ hyprland/*.conf). This repo ships BOTH side by side, so
# each machine picks the syntax its Hyprland understands; the helpers below
# decide (and report) which entry will actually be ACTIVE.
#
# Override with: ./setup install --hypr-variant <auto|lua|legacy>

HYPR_LUA_MIN_MAJOR=0
HYPR_LUA_MIN_MINOR=55

function hypr_version_string(){
  # Prints e.g. "0.55.0" for the installed Hyprland, or nothing (return 1)
  # when no version is detectable (Hyprland not installed yet).
  local out
  # 1) `hyprland --version` works without a running compositor.
  if command -v hyprland &>/dev/null; then
    out="$(hyprland --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+(\.[0-9]+)?' | head -n 1)"
    if [[ -n "$out" ]]; then printf '%s\n' "$out"; return 0; fi
  fi
  # 2) `hyprctl version` (usually needs a running instance, but try anyway).
  if command -v hyprctl &>/dev/null; then
    out="$(hyprctl version 2>/dev/null | grep -oE 'v?[0-9]+\.[0-9]+(\.[0-9]+)?' | head -n 1)"
    out="${out#v}"
    if [[ -n "$out" ]]; then printf '%s\n' "$out"; return 0; fi
  fi
  # 3) Package managers (no running compositor needed).
  if command -v dpkg-query &>/dev/null; then
    out="$(dpkg-query -W -f='${Version}' hyprland 2>/dev/null | grep -oE '[0-9]+\.[0-9]+(\.[0-9]+)?' | head -n 1)"
    if [[ -n "$out" ]]; then printf '%s\n' "$out"; return 0; fi
  fi
  if command -v pacman &>/dev/null; then
    out="$(pacman -Q hyprland 2>/dev/null | grep -oE '[0-9]+\.[0-9]+(\.[0-9]+)?' | head -n 1)"
    if [[ -n "$out" ]]; then printf '%s\n' "$out"; return 0; fi
  fi
  if command -v rpm &>/dev/null; then
    out="$(rpm -q --qf '%{VERSION}' hyprland 2>/dev/null | grep -oE '[0-9]+\.[0-9]+(\.[0-9]+)?' | head -n 1)"
    if [[ -n "$out" ]]; then printf '%s\n' "$out"; return 0; fi
  fi
  return 1
}

function hypr_version_at_least(){
  # Usage: hypr_version_at_least <maj> <min> — true iff installed Hyprland >= maj.min
  local need_maj="${1:-0}" need_min="${2:-55}" cur maj min
  cur="$(hypr_version_string)" || return 1
  maj="${cur%%.*}"; min="${cur#*.}"; min="${min%%.*}"
  [[ "$maj" =~ ^[0-9]+$ && "$min" =~ ^[0-9]+$ ]] || return 1
  (( maj > need_maj || (maj == need_maj && min >= need_min) ))
}

function hypr_supports_lua(){
  # True iff the installed Hyprland can load the *.lua config (>= 0.55).
  hypr_version_at_least "$HYPR_LUA_MIN_MAJOR" "$HYPR_LUA_MIN_MINOR"
}

function hypr_os_likely_legacy(){
  # True for distros whose archives historically ship Hyprland < 0.55
  # (Ubuntu and Debian families, incl. Mint/Pop!/elementary/Zorin which
  # dist-determine maps to the ubuntu group).
  case "${OS_GROUP_ID:-unknown}" in
    ubuntu|debian) return 0;;
    *) return 1;;
  esac
}

function hypr_config_variant(){
  # Prints the ACTIVE config variant for this machine: "lua" or "legacy".
  # Honors ${HYPR_VARIANT:-auto} (see --hypr-variant in subcmd-install/options.sh).
  local forced="${HYPR_VARIANT:-auto}" ver
  case "$forced" in
    lua) printf 'lua\n'; return 0;;
    legacy) printf 'legacy\n'; return 0;;
  esac
  # auto: trust the installed Hyprland's real capability first ...
  if ver="$(hypr_version_string)"; then
    if hypr_supports_lua; then printf 'lua\n'; else printf 'legacy\n'; fi
    return 0
  fi
  # ... otherwise fall back to the distro heuristic (fresh installs where
  # Hyprland is not on disk yet, e.g. Ubuntu before the deps step).
  if hypr_os_likely_legacy; then printf 'legacy\n'; else printf 'lua\n'; fi
}

function print_hypr_variant(){
  local variant ver
  variant="$(hypr_config_variant)"
  ver="$(hypr_version_string 2>/dev/null || true)"
  printf "${STY_CYAN:-}[$0]: Hyprland config variant: %s${STY_RST:-}\n" "$variant"
  if [[ -n "$ver" ]]; then
    printf "${STY_CYAN:-}[$0]: Detected Hyprland %s (Lua config needs >= 0.55)${STY_RST:-}\n" "$ver"
  else
    printf "${STY_CYAN:-}[$0]: Hyprland version not detectable (not installed yet?) — distro heuristic: OS_GROUP_ID=%s${STY_RST:-}\n" "${OS_GROUP_ID:-unknown}"
  fi
  if [[ "$variant" == "legacy" ]]; then
    printf "${STY_YELLOW:-}[$0]: ACTIVE entry: ~/.config/hypr/hyprland.conf (+ hyprland/*.conf). hyprland.lua ships alongside but is ignored until Hyprland >= 0.55.${STY_RST:-}\n"
  else
    printf "${STY_CYAN:-}[$0]: ACTIVE entry: ~/.config/hypr/hyprland.lua. hyprland.conf (+ hyprland/*.conf) ships alongside as fallback for older builds.${STY_RST:-}\n"
  fi
}
