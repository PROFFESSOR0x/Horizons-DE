#!/usr/bin/env bash
# install/lib/requirements.sh — target-aware runtime bootstrap.
#
# This intentionally installs only the capabilities needed to start Horizons.
# The larger dots-hyprland dependency sets remain optional and are handled by
# their own installer later in the pipeline.

hz_requirements_command_for_target() {
    case "${HORIZONS_WINDOW_MANAGER:-}" in
        hyprland) printf '%s' hyprctl ;;
        i3)       printf '%s' i3-msg ;;
        *)        return 1 ;;
    esac
}

horizons_target_requirements_installed() {
    command -v git >/dev/null 2>&1 || return 1
    command -v rsync >/dev/null 2>&1 || return 1
    command -v curl >/dev/null 2>&1 || return 1
    command -v quickshell >/dev/null 2>&1 || command -v qs >/dev/null 2>&1 || return 1
    local target_command
    target_command="$(hz_requirements_command_for_target)" || return 1
    command -v "$target_command" >/dev/null 2>&1
}

hz_package_available() {
    local package="$1"
    case "${PKG_GROUP:-unknown}" in
        arch)   pacman -Si "$package" >/dev/null 2>&1 ;;
        fedora) dnf -q list --available "$package" >/dev/null 2>&1 || dnf -q list --installed "$package" >/dev/null 2>&1 ;;
        debian) apt-cache show "$package" >/dev/null 2>&1 ;;
        suse)   zypper --non-interactive se --match-exact "$package" 2>/dev/null | grep -qE '^[[:space:]]*[i |]+' ;;
        gentoo) emerge -p "$package" >/dev/null 2>&1 ;;
        *) return 1 ;;
    esac
}

hz_install_native_package() {
    local package="$1"
    case "${PKG_GROUP:-unknown}" in
        arch)   run sudo pacman -S --needed --noconfirm "$package" ;;
        fedora) run sudo dnf install -y "$package" ;;
        debian) run sudo apt-get install -y "$package" ;;
        suse)   run sudo zypper --non-interactive install --no-recommends "$package" ;;
        gentoo) run sudo emerge --ask=n "$package" ;;
        *) return 1 ;;
    esac
}

hz_install_aur_package() {
    local label="$1" package="$2" helper=""
    [[ "${PKG_GROUP:-unknown}" == arch ]] || return 1
    command -v yay >/dev/null 2>&1 && helper=yay
    command -v paru >/dev/null 2>&1 && helper=paru
    [[ -n "$helper" ]] || return 1
    info "Native package unavailable; trying AUR fallback for $label ('$package')…"
    [[ "${DRY_RUN:-false}" == true ]] && { run true; return 0; }
    run "$helper" -S --needed --noconfirm "$package"
}

# Installs the first repository package that exists on this distribution.  A
# failed name never aborts the installation: the next fallback is tried.
hz_install_first_available() {
    local label="$1"; shift
    local package
    for package in "$@"; do
        [[ -n "$package" ]] || continue
        if hz_package_available "$package"; then
            info "Installing $label via package '$package'…"
            if [[ "${DRY_RUN:-false}" == true ]]; then
                run true
                return 0
            fi
            hz_install_native_package "$package"
            is_pkg_installed "$package" && return 0
            warn "Package '$package' could not be installed; trying the next fallback."
        else
            verbose_log "Package fallback unavailable: $package"
        fi
    done
    return 1
}

hz_packages_for() {
    local capability="$1"
    case "${PKG_GROUP:-unknown}:$capability" in
        arch:git)         printf '%s\n' git ;;
        arch:rsync)       printf '%s\n' rsync ;;
        arch:curl)        printf '%s\n' curl ;;
        arch:jq)          printf '%s\n' jq ;;
        arch:quickshell)  printf '%s\n' quickshell ;;
        arch:hyprland)    printf '%s\n' hyprland hyprland-git ;;
        arch:i3)          printf '%s\n' i3-wm i3 ;;
        arch:xserver)     printf '%s\n' xorg-server ;;
        arch:clipboard-w) printf '%s\n' wl-clipboard ;;
        arch:clipboard-x) printf '%s\n' xclip xsel ;;
        arch:portal)      printf '%s\n' xdg-desktop-portal-hyprland ;;

        fedora:git)         printf '%s\n' git ;;
        fedora:rsync)       printf '%s\n' rsync ;;
        fedora:curl)        printf '%s\n' curl ;;
        fedora:jq)          printf '%s\n' jq ;;
        fedora:quickshell)  printf '%s\n' quickshell ;;
        fedora:hyprland)    printf '%s\n' hyprland ;;
        fedora:i3)          printf '%s\n' i3 ;;
        fedora:xserver)     printf '%s\n' xorg-x11-server-Xorg ;;
        fedora:clipboard-w) printf '%s\n' wl-clipboard ;;
        fedora:clipboard-x) printf '%s\n' xclip xsel ;;
        fedora:portal)      printf '%s\n' xdg-desktop-portal-hyprland ;;

        debian:git)         printf '%s\n' git ;;
        debian:rsync)       printf '%s\n' rsync ;;
        debian:curl)        printf '%s\n' curl ;;
        debian:jq)          printf '%s\n' jq ;;
        debian:quickshell)  printf '%s\n' quickshell ;;
        debian:hyprland)    printf '%s\n' hyprland ;;
        debian:i3)          printf '%s\n' i3-wm i3 ;;
        debian:xserver)     printf '%s\n' xserver-xorg ;;
        debian:clipboard-w) printf '%s\n' wl-clipboard ;;
        debian:clipboard-x) printf '%s\n' xclip xsel ;;
        debian:portal)      printf '%s\n' xdg-desktop-portal-hyprland ;;

        suse:git)         printf '%s\n' git ;;
        suse:rsync)       printf '%s\n' rsync ;;
        suse:curl)        printf '%s\n' curl ;;
        suse:jq)          printf '%s\n' jq ;;
        suse:quickshell)  printf '%s\n' quickshell ;;
        suse:hyprland)    printf '%s\n' hyprland ;;
        suse:i3)          printf '%s\n' i3 ;;
        suse:xserver)     printf '%s\n' xorg-x11-server ;;
        suse:clipboard-w) printf '%s\n' wl-clipboard ;;
        suse:clipboard-x) printf '%s\n' xclip xsel ;;
        suse:portal)      printf '%s\n' xdg-desktop-portal-hyprland ;;

        gentoo:git)         printf '%s\n' dev-vcs/git ;;
        gentoo:rsync)       printf '%s\n' net-misc/rsync ;;
        gentoo:curl)        printf '%s\n' net-misc/curl ;;
        gentoo:jq)          printf '%s\n' app-misc/jq ;;
        gentoo:quickshell)  printf '%s\n' gui-apps/quickshell ;;
        gentoo:hyprland)    printf '%s\n' gui-wm/hyprland ;;
        gentoo:i3)          printf '%s\n' x11-wm/i3 ;;
        gentoo:xserver)     printf '%s\n' x11-base/xorg-server ;;
        gentoo:clipboard-w) printf '%s\n' gui-apps/wl-clipboard ;;
        gentoo:clipboard-x) printf '%s\n' x11-misc/xclip ;;
        gentoo:portal)      printf '%s\n' gui-libs/xdg-desktop-portal-hyprland ;;
    esac
}

hz_install_capability() {
    local capability="$1" label="$2"
    local packages=()
    mapfile -t packages < <(hz_packages_for "$capability")
    (( ${#packages[@]} > 0 )) || return 1
    hz_install_first_available "$label" "${packages[@]}"
}

hz_install_quickshell_fallback() {
    command -v quickshell >/dev/null 2>&1 || command -v qs >/dev/null 2>&1 || true
    if command -v quickshell >/dev/null 2>&1 || command -v qs >/dev/null 2>&1; then return 0; fi

    # Arch's official repository is tried first above. AUR is deliberately a
    if [[ "${PKG_GROUP:-unknown}" == arch ]]; then
        hz_install_aur_package QuickShell quickshell-git || true
    fi

    if ! command -v quickshell >/dev/null 2>&1 && ! command -v qs >/dev/null 2>&1; then
        warn "No packaged QuickShell was available. Source-build fallback is available."
        if confirm "Build QuickShell from source now?" "y"; then
            [[ "${DRY_RUN:-false}" == true ]] && return 0
            hz_install_quickshell_build_tools || warn "Some QuickShell build dependencies could not be installed."
            if ! declare -f hz_build_quickshell >/dev/null 2>&1; then
                warn "QuickShell build helper is unavailable in this checkout."
            elif ! hz_build_quickshell false; then
                warn "QuickShell source fallback failed; no executable was installed."
            fi
        fi
    fi
    command -v quickshell >/dev/null 2>&1 || command -v qs >/dev/null 2>&1
}

hz_install_quickshell_build_tools() {
    local packages=()
    case "${PKG_GROUP:-unknown}" in
        arch)   packages=(base-devel cmake ninja qt6-base qt6-declarative) ;;
        fedora) packages=(gcc-c++ cmake ninja-build qt6-qtbase-devel qt6-qtdeclarative-devel qt6-qtwayland wayland-devel pipewire-devel) ;;
        debian) packages=(build-essential cmake ninja-build qt6-base-dev qt6-declarative-dev qt6-wayland-dev libwayland-dev libpipewire-0.3-dev) ;;
        suse)   packages=(gcc-c++ cmake ninja qt6-base-devel qt6-declarative-devel qt6-wayland-devel wayland-devel) ;;
        gentoo) packages=(dev-build/cmake dev-build/ninja dev-qt/qtbase dev-qt/qtdeclarative gui-libs/qtwayland) ;;
        *) return 1 ;;
    esac
    local package
    for package in "${packages[@]}"; do
        if ! is_pkg_installed "$package"; then
            hz_install_native_package "$package"
            is_pkg_installed "$package" || return 1
        fi
    done
}

install_target_requirements() {
    step "Install target runtime requirements"
    if [[ "${DO_DEPS:-true}" != true || "${SKIP_DEPS:-false}" == true ]]; then
        warn "Dependency bootstrap was explicitly skipped; only auditing the selected target."
        horizons_target_requirements_installed || warn "The target still has missing runtime requirements. Re-run without --skip-deps to install them."
        return 0
    fi

    local command capability
    for capability in git rsync curl jq; do
        command="$capability"
        command -v "$command" >/dev/null 2>&1 || hz_install_capability "$capability" "$capability" || warn "Could not resolve required package: $capability"
    done

    if ! command -v quickshell >/dev/null 2>&1 && ! command -v qs >/dev/null 2>&1; then
        hz_install_capability quickshell QuickShell || true
        hz_install_quickshell_fallback || warn "QuickShell is still missing after all package fallbacks."
    fi

    case "${HORIZONS_WINDOW_MANAGER:-}" in
        hyprland)
            command -v hyprctl >/dev/null 2>&1 || hz_install_capability hyprland Hyprland || hz_install_aur_package Hyprland hyprland-git || warn "Hyprland could not be installed from configured repositories."
            command -v wl-copy >/dev/null 2>&1 || hz_install_capability clipboard-w wl-clipboard || warn "wl-clipboard is optional but recommended."
            command -v xdg-desktop-portal-hyprland >/dev/null 2>&1 || hz_install_capability portal xdg-desktop-portal-hyprland || warn "Hyprland portal is optional but recommended."
            ;;
        i3)
            command -v i3-msg >/dev/null 2>&1 || hz_install_capability i3 i3 || warn "i3 could not be installed from configured repositories."
            command -v Xorg >/dev/null 2>&1 || hz_install_capability xserver "X.Org server" || warn "X.Org server is required to start an i3/X11 session."
            command -v xclip >/dev/null 2>&1 || command -v xsel >/dev/null 2>&1 || hz_install_capability clipboard-x "X11 clipboard helper" || warn "An X11 clipboard helper is optional but recommended."
            ;;
    esac

    if [[ "${DRY_RUN:-false}" == true ]] || horizons_target_requirements_installed; then
        ok "Selected target runtime requirements are ready."
    else
        warn "Some runtime requirements remain unavailable. The final pre-flight report lists them explicitly."
    fi
}
