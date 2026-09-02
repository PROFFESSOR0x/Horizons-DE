#!/usr/bin/env python3
"""
export_video.py — Export a trimmed and/or annotated video via ffmpeg.

Overlay images are produced by EditorCanvas at the NATIVE video resolution
(same width × height as the source video), so no scaling is needed here.
Each overlay is composited with an independent time window using ffmpeg's
overlay filter and an enable expression.
"""

import sys
import os
import json
import argparse
import subprocess


def get_video_size(input_path: str) -> tuple[int, int]:
    """Return (width, height) of the video using ffprobe."""
    try:
        probe = subprocess.run(
            [
                "ffprobe", "-v", "error",
                "-select_streams", "v:0",
                "-show_entries", "stream=width,height",
                "-of", "csv=p=0",
                input_path,
            ],
            capture_output=True, text=True, check=True,
        )
        parts = probe.stdout.strip().split(",")
        return int(parts[0]), int(parts[1])
    except Exception as e:
        print(f"[export_video] ffprobe failed: {e}", file=sys.stderr)
        return 0, 0


def scale_overlay_if_needed(img_path: str, vid_w: int, vid_h: int) -> str:
    """
    If the overlay PNG dimensions don't match the video, resize it in-place
    (overwrite) so that overlay=0:0 places it perfectly.  Returns the path.
    """
    if vid_w <= 0 or vid_h <= 0:
        return img_path
    try:
        identify = subprocess.run(
            ["identify", "-format", "%wx%h", img_path],
            capture_output=True, text=True,
        )
        if identify.returncode != 0:
            return img_path          # ImageMagick not available — skip
        img_w, img_h = map(int, identify.stdout.strip().split("x"))
        if img_w == vid_w and img_h == vid_h:
            return img_path          # already correct size

        print(
            f"[export_video] Rescaling overlay {os.path.basename(img_path)} "
            f"from {img_w}x{img_h} → {vid_w}x{vid_h}"
        )
        scaled = img_path.replace(".png", "_scaled.png")
        subprocess.run(
            ["convert", img_path, "-resize", f"{vid_w}x{vid_h}!", scaled],
            check=True,
        )
        return scaled
    except Exception as e:
        print(f"[export_video] scale_overlay_if_needed failed: {e}", file=sys.stderr)
        return img_path


def main():
    parser = argparse.ArgumentParser(description="Export annotated video with ffmpeg")
    parser.add_argument("--input",    required=True,        help="Input video path")
    parser.add_argument("--output",   required=True,        help="Output video path")
    parser.add_argument("--start",    type=float, default=0.0,  help="Trim start (seconds)")
    parser.add_argument("--end",      type=float, default=-1.0, help="Trim end   (seconds, -1 = full)")
    parser.add_argument("--overlays", default="",
                        help="JSON list of overlays: [{\"image\": path, \"start\": s, \"end\": e}, …]")
    parser.add_argument("--notify",   action="store_true",  help="Send desktop notification on completion")
    args = parser.parse_args()

    input_path  = os.path.abspath(args.input)
    output_path = os.path.abspath(args.output)

    if not os.path.exists(input_path):
        print(f"[export_video] Error: input file not found: {input_path}", file=sys.stderr)
        sys.exit(1)

    # ── Parse overlays ──────────────────────────────────────────────────────
    overlays = []
    if args.overlays:
        try:
            overlays = json.loads(args.overlays) if not os.path.exists(args.overlays) \
                       else json.load(open(args.overlays))
        except Exception as e:
            print(f"[export_video] Error parsing overlays JSON: {e}", file=sys.stderr)

    trim_start = max(0.0, args.start)
    trim_end   = args.end  # -1 means "no end trim"

    # ── Build ffmpeg command ─────────────────────────────────────────────────
    cmd = ["ffmpeg", "-y"]

    # Input seeking (before -i for fast seek)
    if trim_start > 0:
        cmd.extend(["-ss", f"{trim_start:.3f}"])
    if trim_end > 0 and trim_end > trim_start:
        cmd.extend(["-to", f"{trim_end:.3f}"])

    cmd.extend(["-i", input_path])

    # ── No overlays → fast stream copy ──────────────────────────────────────
    if not overlays:
        cmd.extend(["-c", "copy", output_path])
        print("[export_video] Running (trim only):", " ".join(cmd))
        proc = subprocess.run(cmd, capture_output=True, text=True)
        _finish(proc, output_path, args.notify)
        return

    # ── With overlays ────────────────────────────────────────────────────────
    # Get video dimensions so we can sanity-check overlay sizes.
    vid_w, vid_h = get_video_size(input_path)

    valid_overlays = []
    for item in overlays:
        img_path = item.get("image", "")
        if not img_path or not os.path.exists(img_path):
            print(f"[export_video] Overlay image not found, skipping: {img_path}", file=sys.stderr)
            continue
        # Ensure overlay is exactly the video size (safety net — normally it
        # already is because EditorCanvas renders at native resolution).
        img_path = scale_overlay_if_needed(img_path, vid_w, vid_h)
        valid_overlays.append({
            "image": img_path,
            "start": float(item.get("start", 0.0)),
            "end":   float(item.get("end",   999999.0)),
        })
        cmd.extend(["-i", img_path])

    if not valid_overlays:
        # No usable overlays — fall back to stream copy
        cmd_copy = ["ffmpeg", "-y"]
        if trim_start > 0:
            cmd_copy.extend(["-ss", f"{trim_start:.3f}"])
        if trim_end > 0 and trim_end > trim_start:
            cmd_copy.extend(["-to", f"{trim_end:.3f}"])
        cmd_copy.extend(["-i", input_path, "-c", "copy", output_path])
        print("[export_video] No valid overlays, running trim-only:", " ".join(cmd_copy))
        proc = subprocess.run(cmd_copy, capture_output=True, text=True)
        _finish(proc, output_path, args.notify)
        return

    # Build filter_complex: chain overlay filters one by one.
    # Each overlay PNG is the same size as the video frame, so overlay=0:0
    # places it perfectly without any scaling.
    # The enable expression is shifted by trim_start so timestamps are
    # relative to the trimmed output timeline.
    filter_steps = []
    last_v = "0:v"

    for idx, item in enumerate(valid_overlays):
        in_idx  = idx + 1
        # Shift annotation times into the trimmed timeline
        o_start = max(0.0, item["start"] - trim_start)
        o_end   = max(0.0, item["end"]   - trim_start)
        next_v  = f"v_ann_{idx}" if idx < len(valid_overlays) - 1 else "v_out"

        enable_expr = f"between(t,{o_start:.3f},{o_end:.3f})"
        # overlay=0:0 — top-left corner; overlay and video are the same size
        filter_steps.append(
            f"[{last_v}][{in_idx}:v]overlay=0:0:enable='{enable_expr}'[{next_v}]"
        )
        last_v = next_v

    filter_complex = ";".join(filter_steps)
    cmd.extend([
        "-filter_complex", filter_complex,
        "-map", f"[{last_v}]",
        "-map", "0:a?",          # keep audio stream (optional)
        "-c:a", "copy",
        "-c:v", "libx264",
        "-preset", "fast",
        "-crf", "20",
        output_path,
    ])

    print("[export_video] Running:", " ".join(cmd))
    proc = subprocess.run(cmd, capture_output=True, text=True)
    _finish(proc, output_path, args.notify)


def _finish(proc: subprocess.CompletedProcess, output_path: str, notify: bool):
    if proc.returncode == 0:
        print(f"[export_video] Export successful: {output_path}")
        if notify:
            subprocess.run([
                "notify-send", "Video Exported",
                f"Saved to {os.path.basename(output_path)}",
                "-a", "CaptureEditor",
            ])
    else:
        print(f"[export_video] FFmpeg error:\n{proc.stderr}", file=sys.stderr)
        sys.exit(proc.returncode)


if __name__ == "__main__":
    main()
