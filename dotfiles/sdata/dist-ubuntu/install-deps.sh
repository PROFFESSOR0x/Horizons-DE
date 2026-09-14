# This script is meant to be sourced.
# It's not for directly running.

if ! command -v apt-get >/dev/null 2>&1; then
  printf "${STY_RED}[$0]: apt-get not found, it seems that the system is not Ubuntu. Aborting...${STY_RST}\n"
  exit 1
fi

apt_update_done=false

apt_update_once() {
  if [[ "$apt_update_done" != true ]]; then
    v sudo apt-get update
    apt_update_done=true
  fi
}

apt_has_package() {
  apt-cache show "$1" >/dev/null 2>&1
}

apt_install_available() {
  local label="$1"; shift
  local pkgs=()
  local pkg
  for pkg in "$@"; do
    if apt_has_package "$pkg"; then
      pkgs+=("$pkg")
    else
      printf "${STY_YELLOW}[$0]: Ubuntu package unavailable, skipping: %s${STY_RST}\n" "$pkg"
    fi
  done
  if (( ${#pkgs[@]} == 0 )); then
    printf "${STY_YELLOW}[$0]: No installable Ubuntu packages found for %s.${STY_RST}\n" "$label"
    return 0
  fi
  apt_update_once
  v sudo apt-get install -y "${pkgs[@]}"
}

enable_universe() {
  apt_install_available "software-properties-common" software-properties-common
  if command -v add-apt-repository >/dev/null 2>&1; then
    v sudo add-apt-repository -y universe
    apt_update_done=false
  else
    printf "${STY_YELLOW}[$0]: add-apt-repository is unavailable; continuing with current apt sources.${STY_RST}\n"
  fi
}

enable_quickshell_ppa() {
  command -v quickshell >/dev/null 2>&1 && return 0
  command -v qs >/dev/null 2>&1 && return 0
  apt_has_package quickshell && return 0
  apt_has_package quickshell-git && return 0

  apt_install_available "Quickshell PPA prerequisites" software-properties-common ca-certificates
  if command -v add-apt-repository >/dev/null 2>&1; then
    printf "${STY_CYAN}[$0]: Enabling Quickshell PPA ppa:avengemedia/danklinux.${STY_RST}\n"
    v sudo add-apt-repository -y ppa:avengemedia/danklinux
    apt_update_done=false
  else
    printf "${STY_YELLOW}[$0]: add-apt-repository is unavailable; Quickshell may need a source build later.${STY_RST}\n"
  fi
}

ubuntu_codename() {
  if [[ -n "${VERSION_CODENAME:-}" ]]; then
    printf '%s' "$VERSION_CODENAME"
    return 0
  fi
  if [[ -r /etc/os-release ]]; then
    # shellcheck source=/dev/null
    source /etc/os-release
    printf '%s' "${VERSION_CODENAME:-}"
  fi
}

enable_hyprland_ppa() {
  local package missing=false
  for package in hyprland hypridle hyprlock hyprpicker xdg-desktop-portal-hyprland; do
    apt_has_package "$package" || missing=true
  done
  [[ "$missing" == true ]] || return 0

  apt_install_available "Hyprland PPA prerequisites" software-properties-common ca-certificates
  local codename
  codename="$(ubuntu_codename)"
  case "$codename" in
    noble|plucky|questing|oracular|jammy)
      if command -v add-apt-repository >/dev/null 2>&1; then
        printf "${STY_CYAN}[$0]: Enabling Hyprland PPA ppa:cppiber/hyprland for missing Hyprland packages.${STY_RST}\n"
        v sudo add-apt-repository -y ppa:cppiber/hyprland
        apt_update_done=false
      else
        printf "${STY_YELLOW}[$0]: add-apt-repository is unavailable; Hyprland packages may need a manual install.${STY_RST}\n"
      fi
      ;;
    *)
      printf "${STY_YELLOW}[$0]: ppa:cppiber/hyprland does not advertise support for Ubuntu codename '${codename:-unknown}'.${STY_RST}\n"
      printf "${STY_YELLOW}[$0]: Continuing with packages available from enabled apt sources.${STY_RST}\n"
      ;;
  esac
}

install_swappy_source_fallback() {
  if command -v swappy >/dev/null 2>&1 || apt_has_package swappy; then
    return 0
  fi

  printf "${STY_YELLOW}[$0]: swappy is unavailable from enabled apt sources; building it from source.${STY_RST}\n"
  apt_install_available "swappy build dependencies" \
    git build-essential meson ninja-build pkg-config scdoc \
    libgtk-3-dev libcairo2-dev libpango1.0-dev libglib2.0-dev

  local src_dir="${REPO_ROOT}/cache/swappy-src"
  if [[ ! -d "$src_dir/.git" ]]; then
    x mkdir -p "$(dirname "$src_dir")"
    x git clone --depth 1 https://github.com/jtheoof/swappy.git "$src_dir"
  else
    x git -C "$src_dir" pull --ff-only
  fi

  if [[ -d "$src_dir/build" ]]; then
    x meson setup --reconfigure "$src_dir/build" --prefix=/usr --buildtype=release
  else
    x meson setup "$src_dir/build" "$src_dir" --prefix=/usr --buildtype=release
  fi
  x ninja -C "$src_dir/build"
  x sudo ninja -C "$src_dir/build" install
}

install_quickshell_package() {
  if command -v quickshell >/dev/null 2>&1 || command -v qs >/dev/null 2>&1; then
    printf "${STY_BLUE}[$0]: Quickshell is already installed.${STY_RST}\n"
    return 0
  fi
  if apt_has_package quickshell; then
    apt_install_available "Quickshell" quickshell
  elif apt_has_package quickshell-git; then
    apt_install_available "Quickshell" quickshell-git
  else
    printf "${STY_YELLOW}[$0]: No Quickshell apt package found; the top-level installer can build it from source.${STY_RST}\n"
  fi
}

case $SKIP_SYSUPDATE in
  true) true ;;
  *) v sudo apt-get update; apt_update_done=true; v sudo apt-get upgrade -y ;;
esac

showfun enable_universe
v enable_universe

showfun enable_quickshell_ppa
v enable_quickshell_ppa

showfun enable_hyprland_ppa
v enable_hyprland_ppa

apt_install_available "base tools" \
  git curl wget rsync jq yq unzip tar xz-utils ca-certificates gnupg lsb-release \
  fd-find ripgrep socat bc gawk coreutils findutils procps psmisc lsof util-linux

apt_install_available "Hyprland session" \
  hyprland hypridle hyprlock hyprpaper hyprpicker xdg-desktop-portal-hyprland \
  xdg-desktop-portal-gtk xwayland wayland-protocols

apt_install_available "desktop services" \
  pipewire wireplumber pipewire-pulse pipewire-alsa pipewire-jack \
  bluez blueman network-manager brightnessctl power-profiles-daemon upower \
  playerctl pavucontrol libnotify-bin dunst gnome-keyring polkit-kde-agent-1 \
  kde-cli-tools geoclue-2.0 ydotool wl-clipboard cliphist ddcutil \
  libsecret-tools adwaita-icon-theme hicolor-icon-theme breeze-icon-theme \
  papirus-icon-theme

apt_install_available "shell applications" \
  kitty foot fish fuzzel cava grim slurp swappy wf-recorder imagemagick \
  python3 python3-venv python3-pip python3-dev python3-pil python3-gi \
  python3-dbus python3-cairo libdbus-1-dev libgirepository1.0-dev \
  gobject-introspection gir1.2-gtk-3.0 libcairo2-dev \
  qt6-wayland qt6-image-formats-plugins qml6-module-qtqml \
  qml6-module-qtquick qml6-module-qt-labs-folderlistmodel \
  qml6-module-qtquick-controls qml6-module-qtquick-layouts \
  qml6-module-qtquick-window qml6-module-qtquick-dialogs \
  qml6-module-qtquick-shapes qml6-module-qtquick-effects \
  qml6-module-qt5compat-graphicaleffects qml6-module-qtmultimedia \
  qml6-module-qtwebsockets qml6-module-qt-labs-synchronizer

apt_install_available "shell prompt tools" \
  starship eza

showfun install_swappy_source_fallback
v install_swappy_source_fallback

apt_install_available "Quickshell build fallback" \
  build-essential cmake ninja-build pkg-config qt6-base-dev qt6-declarative-dev \
  qt6-wayland-dev qt6-svg-dev qt6-5compat-dev qt6-multimedia-dev \
  libwayland-dev libpipewire-0.3-dev libjemalloc-dev libcli11-dev

showfun install_quickshell_package
v install_quickshell_package

printf "\n${STY_GREEN}[$0]: Ubuntu dependency installation completed.${STY_RST}\n"
