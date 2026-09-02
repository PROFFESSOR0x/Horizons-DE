#!/usr/bin/env bash
# install/lib/distro.sh — shared distro detection.
#
# Meant to be sourced (not executed). Merges the two previously-divergent
# implementations that used to live in:
#   - dotfiles/sdata/lib/dist-determine.sh (dots-hyprland's OS_GROUP_ID logic)
#   - shell/installer.sh:detect_distro()   (end4-pC's PKG_GROUP logic)
#
# Exposes, after calling detect_distro():
#   DISTRO_ID     - lowercase ID from /etc/os-release (e.g. "arch", "fedora")
#   DISTRO_LIKE   - lowercase ID_LIKE from /etc/os-release
#   DISTRO_NAME   - PRETTY_NAME from /etc/os-release, human readable
#   PKG_GROUP     - one of: arch, fedora, gentoo, suse, debian, unknown
#   NEEDS_NIX     - "true" for groups without a native dependency path
#                   (suse, debian, unknown) — mirrors dots-hyprland's
#                   INSTALL_VIA_NIX fallback.

detect_distro() {
    local os_release_file="/etc/os-release"
    # Allow an override file for testing, same convention dots-hyprland used.
    if [[ -n "${REPO_ROOT:-}" && -f "${REPO_ROOT}/os-release" ]]; then
        os_release_file="${REPO_ROOT}/os-release"
    fi

    if [[ -f "$os_release_file" ]]; then
        # shellcheck source=/dev/null
        source "$os_release_file"
        DISTRO_ID="$(printf '%s' "${ID:-unknown}" | tr '[:upper:]' '[:lower:]')"
        DISTRO_LIKE="$(printf '%s' "${ID_LIKE:-}" | tr '[:upper:]' '[:lower:]')"
        DISTRO_NAME="${PRETTY_NAME:-$DISTRO_ID}"
    else
        DISTRO_ID="unknown"
        DISTRO_LIKE=""
        DISTRO_NAME="Unknown"
    fi

    NEEDS_NIX=false

    case "$DISTRO_ID" in
        arch|cachyos|endeavouros|manjaro|garuda)
            PKG_GROUP="arch" ;;
        fedora|nobara)
            PKG_GROUP="fedora" ;;
        gentoo)
            PKG_GROUP="gentoo" ;;
        opensuse-leap|opensuse-tumbleweed)
            PKG_GROUP="suse"; NEEDS_NIX=true ;;
        debian)
            PKG_GROUP="debian"; NEEDS_NIX=true ;;
        *)
            if [[ "$DISTRO_LIKE" == *arch* ]]; then
                PKG_GROUP="arch"
            elif [[ "$DISTRO_LIKE" == *fedora* ]]; then
                PKG_GROUP="fedora"
            elif [[ "$DISTRO_LIKE" == *gentoo* ]]; then
                PKG_GROUP="gentoo"
            elif [[ "$DISTRO_LIKE" == *suse* || "$DISTRO_LIKE" == *opensuse* ]]; then
                PKG_GROUP="suse"; NEEDS_NIX=true
            elif [[ "$DISTRO_LIKE" == *debian* ]]; then
                PKG_GROUP="debian"; NEEDS_NIX=true
            else
                PKG_GROUP="unknown"; NEEDS_NIX=true
            fi
            ;;
    esac

    MACHINE_ARCH="$(uname -m)"

    export DISTRO_ID DISTRO_LIKE DISTRO_NAME PKG_GROUP NEEDS_NIX MACHINE_ARCH
}
