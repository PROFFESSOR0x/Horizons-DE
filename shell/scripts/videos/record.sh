#!/usr/bin/env bash
CONFIG_FILE="$HOME/.config/horizons/config.json"
JSON_PATH=".screenRecord.savePath"
CUSTOM_PATH=$(jq -r "$JSON_PATH" "$CONFIG_FILE" 2>/dev/null)
RECORDING_DIR=""
if [[ -n "$CUSTOM_PATH" ]]; then
    RECORDING_DIR="$CUSTOM_PATH"
else
    RECORDING_DIR="$HOME/Videos"
fi

# Capture preferences are read once per recording, so changes made in Settings
# apply to the very next capture without restarting Quickshell.
FRAME_RATE=$(jq -r '.screenRecord.frameRate // 60' "$CONFIG_FILE" 2>/dev/null)
CODEC=$(jq -r '.screenRecord.codec // "libx264"' "$CONFIG_FILE" 2>/dev/null)
QUALITY=$(jq -r '.screenRecord.quality // "balanced"' "$CONFIG_FILE" 2>/dev/null)
AUDIO_MODE=$(jq -r '.screenRecord.audioMode // "output"' "$CONFIG_FILE" 2>/dev/null)
OUTPUT_SOURCE_OVERRIDE=$(jq -r '.screenRecord.outputSource // ""' "$CONFIG_FILE" 2>/dev/null)
MIC_SOURCE_OVERRIDE=$(jq -r '.screenRecord.microphoneSource // ""' "$CONFIG_FILE" 2>/dev/null)

[[ "$FRAME_RATE" =~ ^[0-9]+$ ]] || FRAME_RATE=60
(( FRAME_RATE < 1 || FRAME_RATE > 240 )) && FRAME_RATE=60
# Accept the older friendly values as well as the FFmpeg encoder names used by
# the current UI, so existing config files migrate without breaking capture.
case "$CODEC" in
    h264) CODEC=libx264 ;;
    hevc) CODEC=libx265 ;;
    vp9) CODEC=libvpx-vp9 ;;
    libx264|libx265|libvpx-vp9) ;;
    *) CODEC=libx264 ;;
esac
case "$QUALITY" in balanced|high|archive) ;; *) QUALITY=balanced ;; esac
case "$AUDIO_MODE" in none|output|microphone|both) ;; *) AUDIO_MODE=output ;; esac

case "$QUALITY" in
    high)    CODEC_PARAM="crf=18" ;;
    archive) CODEC_PARAM="crf=14" ;;
    *)       CODEC_PARAM="crf=23" ;;
esac

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

getmicrophone() {
    pactl get-default-source 2>/dev/null || pactl list short sources | awk '$2 !~ /\.monitor$/ { print $2; exit }'
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

RECORDER_ARGS=(--pixel-format yuv420p -r "$FRAME_RATE" -c "$CODEC" -p "$CODEC_PARAM")
AUDIO_ARGS=()
if [[ $SOUND_FLAG -eq 1 && "$AUDIO_MODE" != "none" ]]; then
    OUTPUT_SOURCE="${OUTPUT_SOURCE_OVERRIDE:-$(getaudiooutput | head -n 1)}"
    MIC_SOURCE="${MIC_SOURCE_OVERRIDE:-$(getmicrophone)}"
    case "$AUDIO_MODE" in
        output)     [[ -n "$OUTPUT_SOURCE" ]] && AUDIO_ARGS+=("--audio=$OUTPUT_SOURCE") ;;
        microphone) [[ -n "$MIC_SOURCE" ]] && AUDIO_ARGS+=("--audio=$MIC_SOURCE") ;;
        both) # Use a pre-mixed PipeWire source when supplied; wf-recorder has one audio input.
            [[ -n "$OUTPUT_SOURCE" ]] && AUDIO_ARGS+=("--audio=$OUTPUT_SOURCE")
            ;;
    esac
fi

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
        # ── Screen Canvas: auto-open video editor ─────────────────────
        AUTO_OPEN_VIDEO=$(jq -r '.screenCanvas.autoOpenVideo // true' "$CONFIG_FILE" 2>/dev/null)
        if [[ "$AUTO_OPEN_VIDEO" == "true" ]]; then
            qs -c horizons ipc call captureEditor openVideo "$LAST_REC" 2>/dev/null || \
            qs -p "$HOME/.config/quickshell/horizons" ipc call captureEditor openVideo "$LAST_REC" 2>/dev/null || \
            qs ipc call captureEditor openVideo "$LAST_REC" 2>/dev/null || \
            notify-send "Recording Saved" "$(basename "$LAST_REC") — opened in editor" -a 'Recorder' -i "video-x-generic" &
        else
            (
                ACTION=$(notify-send -w "Recording Saved" "$(basename "$LAST_REC")" -a 'Recorder' --action="edit=Edit Video" --action="open=Open Folder" -i "video-x-generic" 2>/dev/null)
                if [[ "$ACTION" == "edit" ]]; then
                    qs -c horizons ipc call captureEditor openVideo "$LAST_REC" 2>/dev/null || \
                    qs -p "$HOME/.config/quickshell/horizons" ipc call captureEditor openVideo "$LAST_REC" 2>/dev/null || \
                    qs ipc call captureEditor openVideo "$LAST_REC" 2>/dev/null
                elif [[ "$ACTION" == "open" ]]; then
                    xdg-open "$RECORDING_DIR" &
                fi
            ) & disown
        fi
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
        wf-recorder "${RECORDER_ARGS[@]}" -o "$(getactivemonitor)" -f "$TARGET_PATH" -t "${AUDIO_ARGS[@]}"
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
        wf-recorder "${RECORDER_ARGS[@]}" -f "$TARGET_PATH" -t --geometry "$region" "${AUDIO_ARGS[@]}"
    fi
    set_recording_state false

    if [[ -f "$TARGET_PATH" ]]; then
        # Legacy explicit --edit flag always opens
        if [[ $AUTO_EDIT_FLAG -eq 1 ]]; then
            qs -p '' ipc call captureEditor openVideo "$TARGET_PATH" 2>/dev/null || \
            qs -c horizons ipc call captureEditor openVideo "$TARGET_PATH" 2>/dev/null || true
        else
            # Auto-open based on Screen Canvas setting
            AUTO_OPEN_VIDEO_END=$(jq -r '.screenCanvas.autoOpenVideo // true' "$CONFIG_FILE" 2>/dev/null)
            if [[ "$AUTO_OPEN_VIDEO_END" == "true" ]]; then
                qs -c horizons ipc call captureEditor openVideo "$TARGET_PATH" 2>/dev/null || \
                qs -p "$HOME/.config/quickshell/horizons" ipc call captureEditor openVideo "$TARGET_PATH" 2>/dev/null || \
                qs ipc call captureEditor openVideo "$TARGET_PATH" 2>/dev/null || true
            else
                # Show notification with edit action when auto-open is disabled
                (
                    ACTION=$(notify-send -w "Recording Saved" "$(basename "$TARGET_PATH")" -a 'Recorder' --action="edit=Edit Video" --action="open=Open Folder" -i "video-x-generic" 2>/dev/null)
                    if [[ "$ACTION" == "edit" ]]; then
                        qs -c horizons ipc call captureEditor openVideo "$TARGET_PATH" 2>/dev/null || \
                        qs -p "$HOME/.config/quickshell/horizons" ipc call captureEditor openVideo "$TARGET_PATH" 2>/dev/null || \
                        qs ipc call captureEditor openVideo "$TARGET_PATH" 2>/dev/null
                    elif [[ "$ACTION" == "open" ]]; then
                        xdg-open "$RECORDING_DIR" &
                    fi
                ) & disown
            fi
        fi
    fi
fi
