#!/usr/bin/env bash
# install/lib/build.sh — Horizons build-from-source helpers
# Builds quickshell (via PKGBUILD) and hyprglass (via make / hyprpm) from source.

# Expects: REPO_ROOT, QS_REPO, HYPRGLASS_DIR, DISTRO vars, and UI helpers (info, warn, ok, err, run) if available.
# Falls back to plain echo if not.

_build_info() { if declare -f info &>/dev/null; then info "$*"; else echo "[INFO] $*"; fi; }
_build_warn() { if declare -f warn &>/dev/null; then warn "$*"; else echo "[WARN] $*"; fi; }
_build_ok()   { if declare -f ok &>/dev/null; then ok "$*"; else echo "[OK] $*"; fi; }
_build_err()  { if declare -f err &>/dev/null; then err "$*"; else echo "[ERR] $*" >&2; fi; }

# ── hyprglass (primary: hz_) ──────────────────────────────────────────────────
hz_build_hyprglass() {
    local hyprglass_dir="${HYPRGLASS_DIR:-$REPO_ROOT/shell/plugins/hyprglass}"
    local force="${1:-false}"

    if [[ ! -d "$hyprglass_dir" ]]; then
        _build_warn "hyprglass plugin dir not found at $hyprglass_dir — skipping."
        return 0
    fi

    if [[ -f "$hyprglass_dir/hyprglass.so" && "$force" != "true" ]]; then
        _build_info "hyprglass.so already exists — skipping build (use --build-force to rebuild)."
        return 0
    fi

    if command -v hyprpm &>/dev/null; then
        _build_info "hyprpm found — alternative: hyprpm add https://github.com/hyprnux/hyprglass && hyprpm enable hyprglass"
    fi

    local missing=()
    for t in make g++ pkg-config; do command -v "$t" &>/dev/null || missing+=("$t"); done
    if [[ ${#missing[@]} -gt 0 ]]; then
        _build_warn "Missing build tools: ${missing[*]} — skipping hyprglass build."
        _build_warn "Install base-devel (Arch) / build-essential (Debian) and re-run with --with-build."
        return 0
    fi

    _build_info "Building hyprglass.so from source (make)…"
    if (cd "$hyprglass_dir" && make -j"$(nproc 2>/dev/null || echo 4)"); then
        _build_ok "hyprglass.so built at $hyprglass_dir/hyprglass.so"
        local qs_config_dir="${QS_CONFIG_DIR:-$XDG_CONFIG_HOME/quickshell/horizons}"
        if [[ -d "$qs_config_dir" ]]; then
            mkdir -p "$qs_config_dir/plugins/hyprglass"
            cp -f "$hyprglass_dir/hyprglass.so" "$qs_config_dir/plugins/hyprglass/hyprglass.so"
            _build_ok "Deployed hyprglass.so to $qs_config_dir/plugins/hyprglass/"
        fi
        return 0
    else
        _build_warn "hyprglass build failed — missing dev headers (hyprland, pixman, libdrm, wayland)?"
        _build_warn "Try: sudo pacman -S hyprland pixman libdrm wayland wayland-protocols (Arch)"
        _build_warn "Continuing without fresh plugin build."
        return 0
    fi
}
build_hyprglass(){ hz_build_hyprglass "$@"; }

hz_build_hyprglass_clean() {
    local hyprglass_dir="${HYPRGLASS_DIR:-$REPO_ROOT/shell/plugins/hyprglass}"
    if [[ -d "$hyprglass_dir" ]]; then
        (cd "$hyprglass_dir" && make clean 2>/dev/null || rm -f hyprglass.so src/*.o)
        _build_ok "hyprglass cleaned."
    fi
}
build_hyprglass_clean(){ hz_build_hyprglass_clean "$@"; }

# ── quickshell (primary: hz_) ─────────────────────────────────────────────────
hz_build_quickshell() {
    local force="${1:-false}"
    local pkgdir="$REPO_ROOT/dotfiles/sdata/dist-arch/illogical-impulse-quickshell-git"

    if command -v quickshell &>/dev/null || command -v qs &>/dev/null; then
        if [[ "$force" != "true" ]]; then
            _build_info "quickshell already installed — skipping build (use --build-force)."
            quickshell --version 2>/dev/null | head -n1 || true
            return 0
        fi
    fi

    case "${PKG_GROUP:-unknown}" in
        arch)
            if [[ ! -d "$pkgdir" ]]; then
                _build_warn "Quickshell PKGBUILD not found at $pkgdir — skipping."
                return 0
            fi
            _build_info "Building quickshell from PKGBUILD (arch)…"
            if command -v yay &>/dev/null; then
                if (cd "$pkgdir" && makepkg -Afsi --noconfirm); then
                    _build_ok "quickshell built via PKGBUILD + yay."
                    return 0
                fi
            elif command -v paru &>/dev/null; then
                if (cd "$pkgdir" && makepkg -Afsi --noconfirm); then
                    _build_ok "quickshell built via PKGBUILD + paru."
                    return 0
                fi
            else
                _build_warn "yay/paru not found — trying makepkg directly (deps must be installed)."
                if (cd "$pkgdir" && makepkg -Afsi --noconfirm); then
                    _build_ok "quickshell built via makepkg."
                    return 0
                fi
            fi
            _build_warn "Quickshell PKGBUILD build failed. Try installing yay first."
            return 0
            ;;
        *)
            _build_info "Non-Arch distro ($PKG_GROUP) — quickshell build from source via cmake (experimental)…"
            local qs_src="$REPO_ROOT/cache/quickshell-src"
            mkdir -p "$qs_src"
            if [[ ! -d "$qs_src/.git" ]]; then
                git clone https://git.outfoxxed.me/quickshell/quickshell.git "$qs_src" 2>/dev/null || \
                git clone https://github.com/quickshell-mirror/quickshell.git "$qs_src" 2>/dev/null || {
                    _build_warn "Failed to clone quickshell source — skipping."
                    return 0
                }
            fi
            if (cd "$qs_src" && cmake -GNinja -B build -DCMAKE_BUILD_TYPE=RelWithDebInfo -DCMAKE_INSTALL_PREFIX=/usr && cmake --build build && sudo cmake --install build); then
                _build_ok "quickshell built from source (cmake)."
                return 0
            else
                _build_warn "Quickshell cmake build failed — see output above."
                return 0
            fi
            ;;
    esac
}
build_quickshell(){ hz_build_quickshell "$@"; }

# ── all ───────────────────────────────────────────────────────────────────────
hz_build_all() {
    local force="${1:-false}"
    _build_info "Build profile: all (quickshell + hyprglass)"
    hz_build_quickshell "$force"
    hz_build_hyprglass "$force"
}
build_all(){ hz_build_all "$@"; }

# ── bundled extras ────────────────────────────────────────────────────────────
hz_build_bundled() {
    _build_info "Installing bundled extras (fonts, bibata, microtex, google-sans)…"
    if ! declare -f install-Rubik &>/dev/null; then
        if [[ -f "$REPO_ROOT/dotfiles/sdata/lib/package-installers.sh" ]]; then
            # shellcheck source=/dev/null
            source "$REPO_ROOT/dotfiles/sdata/lib/package-installers.sh"
        fi
    fi
    local items=()
    [[ "${WITH_RUBIK:-true}" == "true" ]] && items+=(Rubik)
    [[ "${WITH_GABARITO:-true}" == "true" ]] && items+=(Gabarito)
    [[ "${WITH_BIBATA:-true}" == "true" ]] && items+=(bibata)
    [[ "${WITH_MICROTEX:-false}" == "true" ]] && items+=(MicroTeX)

    for item in "${items[@]}"; do
        _build_info "→ $item"
        case "$item" in
            Rubik)    if declare -f install-Rubik &>/dev/null; then install-Rubik || _build_warn "Rubik failed"; fi ;;
            Gabarito) if declare -f install-Gabarito &>/dev/null; then install-Gabarito || _build_warn "Gabarito failed"; fi ;;
            bibata)   if declare -f install-bibata &>/dev/null; then install-bibata || _build_warn "bibata failed"; fi ;;
            MicroTeX) if declare -f install-MicroTeX &>/dev/null; then install-MicroTeX || _build_warn "MicroTeX failed"; fi ;;
        esac
    done

    if [[ "${OS_GROUP_ID:-}" != "fedora" && "${INSTALL_VIA_NIX:-}" != "true" ]]; then
        if declare -f install_google_sans_flex &>/dev/null; then
            install_google_sans_flex || _build_warn "Google Sans Flex failed"
        fi
    fi
    _build_ok "Bundled extras done."
}
build_bundled(){ hz_build_bundled "$@"; }
