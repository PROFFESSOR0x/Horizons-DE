# This script is meant to be sourced.
# It's not for directly running.

# shellcheck shell=bash

#####################################################################################
# MISC (For dots/.config/* but not quickshell, not fish, not Hyprland, not fontconfig)
case "${SKIP_MISCCONF}" in
  true) true;;
  *)
    for i in $(find dots/.config/ -mindepth 1 -maxdepth 1 ! -name 'quickshell' ! -name 'fish' ! -name 'hypr' ! -name 'fontconfig' -exec basename {} \;); do
#      i="dots/.config/$i"
      echo "[$0]: Found target: dots/.config/$i"
      if [ -d "dots/.config/$i" ];then install_dir__sync "dots/.config/$i" "$XDG_CONFIG_HOME/$i"
      elif [ -f "dots/.config/$i" ];then install_file "dots/.config/$i" "$XDG_CONFIG_HOME/$i"
      fi
    done
    install_dir "dots/.local/share/konsole" "${XDG_DATA_HOME}"/konsole
    ;;
esac

case "${SKIP_QUICKSHELL}" in
  true) true;;
  *)
     # Should overwriting the whole directory not only ~/.config/quickshell/ii/ cuz https://github.com/end-4/dots-hyprland/issues/2294#issuecomment-3448671064
    install_dir__sync dots/.config/quickshell "$XDG_CONFIG_HOME"/quickshell
    ;;
esac

case "${SKIP_FISH}" in
  true) true;;
  *)
    install_dir__sync_exclude dots/.config/fish "$XDG_CONFIG_HOME"/fish "conf.d"
    ;;
esac

case "${SKIP_FONTCONFIG}" in
  true) true;;
  *)
    case "$FONTSET_DIR_NAME" in
      "") install_dir__sync dots/.config/fontconfig "$XDG_CONFIG_HOME"/fontconfig ;;
      *) install_dir__sync dots-extra/fontsets/$FONTSET_DIR_NAME "$XDG_CONFIG_HOME"/fontconfig ;;
    esac;;
esac

# For Hyprland
case "${SKIP_HYPRLAND}" in
  true) true;;
  *)
    install_dir__sync dots/.config/hypr/hyprland "$XDG_CONFIG_HOME"/hypr/hyprland
    # Both entry points ship intentionally and coexist:
    #   - Hyprland >= 0.55 loads hyprland.lua and ignores hyprland.conf
    #   - Hyprland < 0.55 (e.g. Ubuntu archive builds) loads hyprland.conf
    #     (+ hyprland/*.conf, monitors.conf) and ignores the *.lua files.
    # Do NOT rename hyprland.conf away — legacy machines need it.
    for i in hyprlock.conf ; do
      install_file__auto_backup "dots/.config/hypr/$i" "${XDG_CONFIG_HOME}/hypr/$i"
    done
    for i in hyprland.lua hyprland.conf monitors.conf workspaces.conf ; do
      case "${SKIP_HYPRLAND_ENTRY}" in
        true) true;;
        *) install_file "dots/.config/hypr/$i" "${XDG_CONFIG_HOME}/hypr/$i" ;;
      esac
    done
    # Lua vs legacy: report which entry this machine will actually load, and
    # on legacy machines (Ubuntu / Hyprland < 0.55) verify the .conf entry
    # is complete. Override with --hypr-variant <auto|lua|legacy>.
    HYPR_ACTIVE_VARIANT="$(hypr_config_variant)"
    v print_hypr_variant
    if [[ "$HYPR_ACTIVE_VARIANT" == "legacy" ]]; then
      echo -e "${STY_YELLOW}[$0]: Legacy Hyprland (< 0.55) path — verifying the .conf entry...${STY_RST}"
      # Hyprland >= 0.53 deprecated `windowrulev2` (every rule logs a Config
      # error) in favor of the unified `windowrule` keyword with the same
      # `match:` syntax. The repo ships `windowrulev2` (understood by the
      # oldest builds, e.g. Ubuntu 24.04 archive) and it is rewritten here
      # in the INSTALLED copies when this machine wants the new keyword.
      HYPR_WINDOWRULE_KW="$(hypr_windowrule_keyword)"
      if [[ "$HYPR_WINDOWRULE_KW" == "windowrule" ]]; then
        echo -e "${STY_YELLOW}[$0]: Hyprland >= 0.53 — using unified 'windowrule' keyword in installed rules...${STY_RST}"
        for HYPR_WR_F in "${XDG_CONFIG_HOME}/hypr/hyprland/rules.conf" "${XDG_CONFIG_HOME}/hypr/hyprland/colors.conf"; do
          if [[ -f "$HYPR_WR_F" ]]; then
            v sed -i 's/^windowrulev2 =/windowrule =/' "$HYPR_WR_F"
          fi
        done
        unset HYPR_WR_F
      fi
      unset HYPR_WINDOWRULE_KW
      HYPR_LEGACY_MISSING=0
      for HYPR_LEGACY_F in hyprland.conf monitors.conf hyprland/env.conf hyprland/variables.conf hyprland/execs.conf hyprland/general.conf hyprland/rules.conf hyprland/colors.conf hyprland/keybinds.conf hyprland/shellOverrides/main.conf hyprland/shellOverrides/animations.conf; do
        if [[ ! -f "${XDG_CONFIG_HOME}/hypr/${HYPR_LEGACY_F}" ]]; then
          echo -e "${STY_RED}[$0]: Missing legacy file: ${XDG_CONFIG_HOME}/hypr/${HYPR_LEGACY_F}${STY_RST}"
          HYPR_LEGACY_MISSING=1
        fi
      done
      if [[ "$HYPR_LEGACY_MISSING" == 0 ]]; then
        echo -e "${STY_GREEN}[$0]: Legacy .conf config complete — this machine will load hyprland.conf.${STY_RST}"
      fi
      unset HYPR_LEGACY_MISSING HYPR_LEGACY_F
    fi
    for i in hypridle.conf ; do
      if [[ "${INSTALL_VIA_NIX}" == true ]]; then
        install_file__auto_backup "dots-extra/via-nix/$i" "${XDG_CONFIG_HOME}/hypr/$i"
      else
        install_file__auto_backup "dots/.config/hypr/$i" "${XDG_CONFIG_HOME}/hypr/$i"
      fi
    done
    if [ "$OS_GROUP_ID" = "fedora" ];then
      v bash -c "printf \"# For fedora to setup polkit\nexec-once = /usr/libexec/kf6/polkit-kde-authentication-agent-1\n\" >> ${XDG_CONFIG_HOME}/hypr/hyprland/execs.conf"
      # Lua entry point equivalent (Hyprland >= 0.55 ignores execs.conf)
      if ! grep -q "polkit-kde-authentication-agent-1" "${XDG_CONFIG_HOME}/hypr/custom/execs.lua" 2>/dev/null; then
        v bash -c "printf '%s\n' 'hl.exec_cmd(\"/usr/libexec/kf6/polkit-kde-authentication-agent-1\") -- For fedora to setup polkit' >> ${XDG_CONFIG_HOME}/hypr/custom/execs.lua"
      fi
    fi

    install_dir__ignore_existing "dots/.config/hypr/custom" "${XDG_CONFIG_HOME}/hypr/custom"
    ;;
esac

install_file "dots/.local/share/icons/illogical-impulse.svg" "${XDG_DATA_HOME}"/icons/illogical-impulse.svg
