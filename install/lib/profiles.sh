#!/usr/bin/env bash
# install/lib/profiles.sh — Horizons install profiles
# Maps user-friendly profile names to component selections.

# Profiles:
#   minimal  → shell only (no dots, no hyprglass build, no extras)
#   core     → dots + shell + hyprglass (default, recommended)
#   full     → core + bundled fonts/bibata
#   ultra    → full + sysupdate + build-from-source for everything + microtex

# Components (canonical):
#   dots, shell, hyprglass, hyprland, fish, fontconfig, miscconf, bundled, deps, sysupdate, build, backup

declare -A PROFILE_DESC=(
    [minimal]="Shell only — minimal Quickshell config, no base dotfiles"
    [core]="Core — dots + shell + hyprglass (default)"
    [full]="Full — core + bundled fonts & bibata cursor"
    [ultra]="Ultra — full + system upgrade + build all from source + MicroTeX"
)

# Resolve a profile name into flag assignments.
# Sets globals: DO_DOTS, DO_SHELL, DO_HYPRGLASS, DO_BUNDLED, DO_BUILD, DO_SYSUPDATE, DO_DEPS, DO_BACKUP
# Usage: horizons_profile_resolve <profile_name>
horizons_profile_resolve() {
    local profile="${1:-core}"
    profile=$(printf '%s' "$profile" | tr '[:upper:]' '[:lower:]')

    # Defaults (core)
    DO_DOTS=true
    DO_SHELL=true
    DO_HYPRGLASS=true
    DO_BUNDLED=false
    DO_BUILD=false
    DO_SYSUPDATE=false
    DO_DEPS=true
    DO_BACKUP=true

    case "$profile" in
        minimal)
            DO_DOTS=false
            DO_HYPRGLASS=false
            DO_BUNDLED=false
            DO_SYSUPDATE=false
            DO_BUILD=false
            ;;
        core)
            # keep defaults
            ;;
        full)
            DO_BUNDLED=true
            ;;
        ultra)
            DO_BUNDLED=true
            DO_BUILD=true
            DO_SYSUPDATE=true
            ;;
        *)
            # Unknown → treat as core but warn
            if declare -f warn &>/dev/null; then warn "Unknown profile '$profile' — falling back to 'core'."; else echo "[WARN] Unknown profile '$profile' — falling back to 'core'."; fi
            profile="core"
            ;;
    esac

    export HORIZONS_PROFILE="$profile"
    export DO_DOTS DO_SHELL DO_HYPRGLASS DO_BUNDLED DO_BUILD DO_SYSUPDATE DO_DEPS DO_BACKUP
}

horizons_profile_list() {
    echo "Available profiles:"
    for p in minimal core full ultra; do
        local cur=""
        [[ "$p" == "${HORIZONS_PROFILE:-core}" ]] && cur=" ← current"
        printf "  %-10s : %s%s\n" "$p" "${PROFILE_DESC[$p]}" "$cur"
    done
}

# Granular components override: apply --components csv on top of profile
# Usage: horizons_components_apply "dots,shell,hyprglass"
# Supports negation with prefix ^ or - or no- : e.g. "no-dots" or "-bundled"
horizons_components_apply() {
    local csv="$1"
    [[ -z "$csv" ]] && return 0
    IFS=',' read -ra parts <<< "$csv"
    for tok in "${parts[@]}"; do
        tok=$(echo "$tok" | xargs | tr '[:upper:]' '[:lower:]')
        local neg=false
        if [[ "$tok" == ^* || "$tok" == -* || "$tok" == no-* ]]; then
            neg=true
            tok=${tok#^}; tok=${tok#-}; tok=${tok#no-}
        fi
        case "$tok" in
            dots|dotfiles)        [[ "$neg" == true ]] && DO_DOTS=false || DO_DOTS=true ;;
            shell|qs|quickshell)  [[ "$neg" == true ]] && DO_SHELL=false || DO_SHELL=true ;;
            hyprglass|glass|plugin) [[ "$neg" == true ]] && DO_HYPRGLASS=false || DO_HYPRGLASS=true ;;
            bundled|fonts|extras) [[ "$neg" == true ]] && DO_BUNDLED=false || DO_BUNDLED=true ;;
            build|compile)        [[ "$neg" == true ]] && DO_BUILD=false || DO_BUILD=true ;;
            deps|dependencies)    [[ "$neg" == true ]] && DO_DEPS=false || DO_DEPS=true ;;
            sysupdate|sys-upgrade|upgrade) [[ "$neg" == true ]] && DO_SYSUPDATE=false || DO_SYSUPDATE=true ;;
            backup)               [[ "$neg" == true ]] && DO_BACKUP=false || DO_BACKUP=true ;;
            all)  DO_DOTS=true; DO_SHELL=true; DO_HYPRGLASS=true; DO_BUNDLED=true; DO_BUILD=true; DO_DEPS=true ;;
            none) DO_DOTS=false; DO_SHELL=false; DO_HYPRGLASS=false; DO_BUNDLED=false; DO_BUILD=false; DO_DEPS=false ;;
            *) if declare -f warn &>/dev/null; then warn "Unknown component '$tok' — ignored."; else echo "[WARN] Unknown component '$tok'"; fi ;;
        esac
    done
}
