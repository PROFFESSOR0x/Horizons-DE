#!/usr/bin/env bash
# Test-notification helper for the legacy hyprlang config (hyprland/keybinds.conf).
# Mirrors the SUPER+ALT+F11 / SUPER+ALT+F12 binds in hyprland/keybinds.lua.
# A script (instead of inline bind commands) is used because hyprlang would
# expand bare $vars ($RANDOM_IMAGE, $ACTION, $USER) inside `exec` at parse time.
# Usage: test-notify.sh body-image|simple
set -uo pipefail
mode="${1:-simple}"

if [[ "$mode" == "body-image" ]]; then
    RANDOM_IMAGE=$(find ~/Pictures -type f 2>/dev/null | shuf -n 1)
    ACTION=$(notify-send "Test notification with body image" "This notification should contain your user account <b>image</b> and <a href=\"https://discord.com/app\">Discord</a> <b>icon</b>. Oh and here is a random image in your Pictures folder: <img src=\"$RANDOM_IMAGE\" alt=\"Testing image\"/>" -a "Hyprland" -p -h "string:image-path:/var/lib/AccountsService/icons/$USER" -t 6000 -i "discord" -A "openImage=Profile image" -A "action2=Open the random image" -A "action3=Useless button")
    [[ $ACTION == *openImage ]] && xdg-open "/var/lib/AccountsService/icons/$USER"
    [[ $ACTION == *action2 ]] && xdg-open "$RANDOM_IMAGE"
else
    RANDOM_IMAGE=$(find ~/Pictures -type f 2>/dev/null | shuf -n 1)
    ACTION=$(notify-send "Test notification" "This notification should contain a random image in your <b>Pictures</b> folder and <a href=\"https://discord.com/app\">Discord</a> <b>icon</b>.\n<i>Flick right to dismiss!</i>" -a "Discord (fake)" -p -h "string:image-path:$RANDOM_IMAGE" -t 6000 -i "discord" -A "openImage=Profile image" -A "action2=Useless button")
    [[ $ACTION == *openImage ]] && xdg-open "/var/lib/AccountsService/icons/$USER"
fi
