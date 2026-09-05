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

# ── X11/i3 recording: wf-recorder is Wayland-only (wlr-screencopy), so the
# i3/X11 target needs a completely different capture path. This mirrors the
# Wayland flow above feature-for-feature (fullscreen vs region, the same
# audio-source detection/AUDIO_MODE handling, the same "both mode falls back
# to just the output source" simplification wf-recorder's own comment already
# documents) rather than introducing new capabilities the Wayland path
# doesn't have.
is_wayland() { [[ -n "${WAYLAND_DISPLAY:-}" ]]; }

# ffmpeg's own -crf flag, not wf-recorder's "-p crf=N" extra-parameter syntax.
FFMPEG_CRF="${CODEC_PARAM#crf=}"

x11_video_codec_args() {
    local args=(-c:v "$CODEC" -pix_fmt yuv420p -crf "$FFMPEG_CRF")
    # VP9 constant-quality mode requires an explicit zero bitrate or ffmpeg
    # falls back to a default bitrate target and ignores -crf.
    [[ "$CODEC" == "libvpx-vp9" ]] && args+=(-b:v 0)
    printf '%s\n' "${args[@]}"
}

x11_audio_input_args() {
    [[ $SOUND_FLAG -eq 1 && "$AUDIO_MODE" != "none" ]] || return 0
    local out_src mic_src
    out_src="${OUTPUT_SOURCE_OVERRIDE:-$(getaudiooutput | head -n 1)}"
    mic_src="${MIC_SOURCE_OVERRIDE:-$(getmicrophone)}"
    case "$AUDIO_MODE" in
        output|both) [[ -n "$out_src" ]] && printf '%s\n' -f pulse -i "$out_src" -c:a aac -b:a 192k ;;
        microphone)  [[ -n "$mic_src" ]] && printf '%s\n' -f pulse -i "$mic_src" -c:a aac -b:a 192k ;;
    esac
}

# X11 has one shared root window across every monitor (no per-output capture
# surface like Wayland's wlr-screencopy) — "fullscreen" here means the whole
# X display, not one specific monitor, same simplification already used for
# the screenshot path (see TempScreenshotProcess.qml).
x11_start_fullscreen() {
    local target="$1"
    mapfile -t vcodec < <(x11_video_codec_args)
    mapfile -t audio < <(x11_audio_input_args)
    # Deliberately foreground (no trailing &), matching wf-recorder's own
    # invocation below: this call blocks until ffmpeg exits, and the *next*
    # keypress's script invocation is what stops it (x11_stop's SIGINT via
    # pkill -f), exactly mirroring the wf-recorder toggle-by-rerunning idiom.
    ffmpeg -y -f x11grab -framerate "$FRAME_RATE" -i "$DISPLAY" \
        "${audio[@]}" "${vcodec[@]}" "$target"
}

# `region` is "X,Y WxH" — the same format slurp already produces and
# wf-recorder's --geometry already expects, kept as the one shared format
# both backends deal in (slop's -f lets it emit the identical layout) so the
# --region/manual-region/cancellation handling above stays backend-agnostic.
x11_start_region() {
    local target="$1" region="$2"
    if [[ ! "$region" =~ ^([0-9]+),([0-9]+)\ ([0-9]+)x([0-9]+)$ ]]; then
        notify-send "Recording cancelled" "Could not parse selected region" -a 'Recorder' & disown
        return 1
    fi
    local rx="${BASH_REMATCH[1]}" ry="${BASH_REMATCH[2]}" rw="${BASH_REMATCH[3]}" rh="${BASH_REMATCH[4]}"
    mapfile -t vcodec < <(x11_video_codec_args)
    mapfile -t audio < <(x11_audio_input_args)
    # Foreground, same reasoning as x11_start_fullscreen above.
    ffmpeg -y -f x11grab -framerate "$FRAME_RATE" -video_size "${rw}x${rh}" -i "${DISPLAY}+${rx},${ry}" \
        "${audio[@]}" "${vcodec[@]}" "$target"
}

# SIGINT (not the default SIGTERM from a plain `pkill`) is required for
# ffmpeg to write its trailer and produce a valid, playable file instead of a
# truncated/corrupt one — this is the one detail that's easy to get subtly
# wrong when scripting ffmpeg as a toggleable background recorder.
x11_stop() { pkill -INT -f 'ffmpeg .*-f x11grab'; }
x11_is_recording() { pgrep -f 'ffmpeg .*-f x11grab' >/dev/null; }

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

if { is_wayland && pgrep wf-recorder > /dev/null; } || { ! is_wayland && x11_is_recording; }; then
    if is_wayland; then pkill wf-recorder & else x11_stop & fi
    set_recording_state false
    LAST_REC=""
    if [[ -f "$REC_TRACK_FILE" ]]; then
        LAST_REC=$(cat "$REC_TRACK_FILE" 2>/dev/null)
        rm -f "$REC_TRACK_FILE"
    fi
    if [[ -n "$LAST_REC" && -f "$LAST_REC" ]]; then
        # ── Screen Canvas: what to do once the recording is done ──────
        # imageResultMode's video counterpart - editor/notification/silent,
        # not a plain "auto-open or not" boolean (see Config.qml's
        # migrateLegacyConfig() for the one-time autoOpenVideo migration).
        VIDEO_RESULT_MODE=$(jq -r '.screenCanvas.videoResultMode // "editor"' "$CONFIG_FILE" 2>/dev/null)
        case "$VIDEO_RESULT_MODE" in
            editor)
                qs -c horizons ipc call captureEditor openVideo "$LAST_REC" 2>/dev/null || \
                qs -p "$HOME/.config/quickshell/horizons" ipc call captureEditor openVideo "$LAST_REC" 2>/dev/null || \
                qs ipc call captureEditor openVideo "$LAST_REC" 2>/dev/null || \
                notify-send "Recording Saved" "$(basename "$LAST_REC") — opened in editor" -a 'Recorder' -i "video-x-generic" &
                ;;
            silent)
                notify-send "Recording Saved" "$(basename "$LAST_REC")" -a 'Recorder' -i "video-x-generic" &
                ;;
            *) # notification (also the fallback for any unrecognized value)
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
                ;;
        esac
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
        if is_wayland; then
            wf-recorder "${RECORDER_ARGS[@]}" -o "$(getactivemonitor)" -f "$TARGET_PATH" -t "${AUDIO_ARGS[@]}"
        else
            x11_start_fullscreen "$TARGET_PATH"
        fi
    else
        if [[ -n "$MANUAL_REGION" ]]; then
            region="$MANUAL_REGION"
        else
            # slop is slurp's X11 equivalent; -f made to emit the identical
            # "X,Y WxH" layout slurp already produces so region/MANUAL_REGION
            # handling above needs no per-backend branching at all. Neither
            # tool sets a non-zero exit code on cancel (slop reports it via
            # a %c format token instead) — checking for empty output, not
            # just a failing exit code, is what actually catches a cancel.
            if is_wayland; then
                region="$(slurp 2>&1)"; select_rc=$?
            else
                region="$(slop -f '%x,%y %wx%h' 2>&1)"; select_rc=$?
            fi
            if (( select_rc != 0 )) || [[ -z "$region" ]]; then
                notify-send "Recording cancelled" "Selection was cancelled" -a 'Recorder' & disown
                rm -f "$REC_TRACK_FILE"
                exit 1
            fi
        fi
        notify-send "Starting recording" "$REC_FILENAME" -a 'Recorder' & disown
        set_recording_state true
        if is_wayland; then
            wf-recorder "${RECORDER_ARGS[@]}" -f "$TARGET_PATH" -t --geometry "$region" "${AUDIO_ARGS[@]}"
        else
            x11_start_region "$TARGET_PATH" "$region"
        fi
    fi
    set_recording_state false

    if [[ -f "$TARGET_PATH" ]]; then
        # Legacy explicit --edit flag always opens
        if [[ $AUTO_EDIT_FLAG -eq 1 ]]; then
            qs -p '' ipc call captureEditor openVideo "$TARGET_PATH" 2>/dev/null || \
            qs -c horizons ipc call captureEditor openVideo "$TARGET_PATH" 2>/dev/null || true
        else
            VIDEO_RESULT_MODE=$(jq -r '.screenCanvas.videoResultMode // "editor"' "$CONFIG_FILE" 2>/dev/null)
            case "$VIDEO_RESULT_MODE" in
                editor)
                    qs -c horizons ipc call captureEditor openVideo "$TARGET_PATH" 2>/dev/null || \
                    qs -p "$HOME/.config/quickshell/horizons" ipc call captureEditor openVideo "$TARGET_PATH" 2>/dev/null || \
                    qs ipc call captureEditor openVideo "$TARGET_PATH" 2>/dev/null || true
                    ;;
                silent)
                    notify-send "Recording Saved" "$(basename "$TARGET_PATH")" -a 'Recorder' -i "video-x-generic" &
                    ;;
                *) # notification (also the fallback for any unrecognized value)
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
                    ;;
            esac
        fi
    fi
fi
