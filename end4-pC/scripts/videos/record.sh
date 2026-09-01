#!/usr/bin/env bash
CONFIG_FILE="$HOME/.config/illogical-impulse/config.json"
JSON_PATH=".screenRecord.savePath"
CUSTOM_PATH=$(jq -r "$JSON_PATH" "$CONFIG_FILE" 2>/dev/null)
RECORDING_DIR=""
if [[ -n "$CUSTOM_PATH" ]]; then
    RECORDING_DIR="$CUSTOM_PATH"
else
    RECORDING_DIR="$HOME/Videos"
fi

set_recording_state() {
    local state=$1
    local STATE_FILE="$HOME/.local/state/quickshell/states.json"
    local tmp=$(mktemp)
    jq ".record.enable = $state" "$STATE_FILE" > "$tmp" && mv "$tmp" "$STATE_FILE"
}

getdate() {
    date '+%Y-%m-%d_%H.%M.%S'
}
getaudiooutput() {
    pactl list sources | grep 'Name' | grep 'monitor' | cut -d ' ' -f2
}

detect_compositor() {
    local combined
    combined="$(echo "${XDG_CURRENT_DESKTOP:-} ${XDG_SESSION_DESKTOP:-}" | tr '[:upper:]' '[:lower:]')"
    if [[ "$combined" == *"niri"* ]]; then
        echo "niri"
    elif [[ "$combined" == *"hyprland"* ]]; then
        echo "hyprland"
    else
        echo "unknown"
    fi
}

getactivemonitor() {
    if [[ "$(detect_compositor)" == "niri" ]]; then
        niri msg -j workspaces | jq -r '.[] | select(.is_focused == true) | .output'
    else
        hyprctl monitors -j | jq -r '.[] | select(.focused == true) | .name'
    fi
}

mkdir -p "$RECORDING_DIR"
cd "$RECORDING_DIR" || exit

ARGS=("$@")
MANUAL_REGION=""
SOUND_FLAG=0
FULLSCREEN_FLAG=0
AUTO_EDIT_FLAG=0

for ((i=0;i<${#ARGS[@]};i++)); do
    if [[ "${ARGS[i]}" == "--region" ]]; then
        if (( i+1 < ${#ARGS[@]} )); then
            MANUAL_REGION="${ARGS[i+1]}"
        else
            notify-send "Recording cancelled" "No region specified for --region" -a 'Recorder' & disown
            exit 1
        fi
    elif [[ "${ARGS[i]}" == "--sound" ]]; then
        SOUND_FLAG=1
    elif [[ "${ARGS[i]}" == "--fullscreen" ]]; then
        FULLSCREEN_FLAG=1
    elif [[ "${ARGS[i]}" == "--edit" ]]; then
        AUTO_EDIT_FLAG=1
    fi
done

REC_TRACK_FILE="/tmp/quickshell/media/active_recording.txt"
mkdir -p "/tmp/quickshell/media"

if pgrep wf-recorder > /dev/null; then
    pkill wf-recorder &
    set_recording_state false
    LAST_REC=""
    if [[ -f "$REC_TRACK_FILE" ]]; then
        LAST_REC=$(cat "$REC_TRACK_FILE" 2>/dev/null)
        rm -f "$REC_TRACK_FILE"
    fi
    if [[ -n "$LAST_REC" && -f "$LAST_REC" ]]; then
        (
            ACTION=$(notify-send -w "Recording Saved" "$(basename "$LAST_REC")" -a 'Recorder' --action="edit=Edit Video" --action="open=Open Folder" -i "video-x-generic" 2>/dev/null)
            if [[ "$ACTION" == "edit" ]]; then
                qs -c end4-pC ipc call captureEditor openVideo "$LAST_REC" 2>/dev/null || \
                qs -p "$HOME/.config/quickshell/end4-pC" ipc call captureEditor openVideo "$LAST_REC" 2>/dev/null || \
                qs ipc call captureEditor openVideo "$LAST_REC" 2>/dev/null
            elif [[ "$ACTION" == "open" ]]; then
                xdg-open "$RECORDING_DIR" &
            fi
        ) & disown
    else
        notify-send "Recording Stopped" "Recording has finished" -a 'Recorder' &
    fi
else
    REC_FILENAME="recording_$(getdate).mp4"
    TARGET_PATH="$RECORDING_DIR/$REC_FILENAME"
    echo "$TARGET_PATH" > "$REC_TRACK_FILE"

    if [[ $FULLSCREEN_FLAG -eq 1 ]]; then
        notify-send "Starting recording" "$REC_FILENAME" -a 'Recorder' & disown
        set_recording_state true
        if [[ $SOUND_FLAG -eq 1 ]]; then
            wf-recorder -o "$(getactivemonitor)" --pixel-format yuv420p -f "$TARGET_PATH" -t --audio="$(getaudiooutput)"
        else
            wf-recorder -o "$(getactivemonitor)" --pixel-format yuv420p -f "$TARGET_PATH" -t
        fi
    else
        if [[ -n "$MANUAL_REGION" ]]; then
            region="$MANUAL_REGION"
        else
            if ! region="$(slurp 2>&1)"; then
                notify-send "Recording cancelled" "Selection was cancelled" -a 'Recorder' & disown
                rm -f "$REC_TRACK_FILE"
                exit 1
            fi
        fi
        notify-send "Starting recording" "$REC_FILENAME" -a 'Recorder' & disown
        set_recording_state true
        if [[ $SOUND_FLAG -eq 1 ]]; then
            wf-recorder --pixel-format yuv420p -f "$TARGET_PATH" -t --geometry "$region" --audio="$(getaudiooutput)"
        else
            wf-recorder --pixel-format yuv420p -f "$TARGET_PATH" -t --geometry "$region"
        fi
    fi
    set_recording_state false

    if [[ $AUTO_EDIT_FLAG -eq 1 && -f "$TARGET_PATH" ]]; then
        qs -p '' ipc call captureEditor openVideo "$TARGET_PATH"
    fi
fi