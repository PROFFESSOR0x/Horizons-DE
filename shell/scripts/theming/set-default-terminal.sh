#!/usr/bin/env bash
# Set the default terminal for the Horizons DE.
# Arguments are passed positionally from QML, never interpolated into a shell
# command. Applies to:
#   1. Hyprland shortcuts (Super+Return, Super+T, Ctrl+Alt+T) via
#      ~/.config/hypr/custom/variables.lua  (Hyprland >= 0.55, lua entry point)
#      and ~/.config/hypr/custom/variables.conf (legacy hyprlang entry point).
#      Both files are user-owned override files: only the terminal line is
#      touched, everything else is preserved. Afterwards `hyprctl reload` is
#      attempted so the new terminal takes effect immediately.
#   2. GNOME consumers (Nautilus "Open in terminal", etc.) via gsettings,
#      best-effort and skipped when the schema is absent.
# The shell's own actions (launcher SSH/service status, ...) read
# Config.options.apps.terminal directly, so they follow without a reload.
set -euo pipefail

cmd="${1:?terminal command is required}"
# Trim surrounding whitespace.
cmd="${cmd#"${cmd%%[![:space:]]*}"}"
cmd="${cmd%"${cmd##*[![:space:]]}"}"
[[ -n "$cmd" ]] || { echo "set-default-terminal: empty command, nothing to do" >&2; exit 0; }

exe="${cmd%% *}"
command -v "$exe" >/dev/null 2>&1 || { echo "set-default-terminal: executable not found: $exe" >&2; exit 0; }

export SET_TERMINAL_CMD="$cmd"
python3 - <<'PYEOF'
import os
from pathlib import Path

cmd = os.environ["SET_TERMINAL_CMD"]
home = Path(os.environ.get("HOME", str(Path.home())))


def upsert_line(path: Path, match_prefixes, new_line: str, header: str) -> None:
    """Replace the first line starting with one of match_prefixes (after
    leading whitespace), or append it. All other lines are preserved byte
    for byte."""
    lines = path.read_text().splitlines() if path.is_file() else []
    out = []
    replaced = False
    for line in lines:
        stripped = line.lstrip()
        if not replaced and any(stripped.startswith(p) for p in match_prefixes):
            out.append(new_line)
            replaced = True
        else:
            out.append(line)
    if not replaced:
        if out and out[-1].strip():
            out.append("")
        if not out:
            out.append(header)
        out.append(new_line)
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text("\n".join(out) + "\n")


lua_escaped = cmd.replace("\\", "\\\\").replace('"', '\\"')
upsert_line(
    home / ".config/hypr/custom/variables.lua",
    ("terminal =", "terminal="),
    f'terminal = "{lua_escaped}"',
    "-- User terminal override (written by Settings > Default terminal)",
)
upsert_line(
    home / ".config/hypr/custom/variables.conf",
    ("$terminal =", "$terminal="),
    f"$terminal = {cmd}",
    "# User terminal override (written by Settings > Default terminal)",
)
print(f"terminal override written: {cmd}")
PYEOF

if command -v hyprctl >/dev/null 2>&1; then
    hyprctl reload >/dev/null 2>&1 || true
fi

if [[ "${SKIP_GSETTINGS:-}" != "1" ]] && gsettings list-schemas 2>/dev/null | grep -qx "org.gnome.desktop.default-applications.terminal"; then
    # Consumers run: exec + exec-arg + command, so only the binary goes to
    # `exec` and any extra flags (e.g. kitty's -1) go to `exec-arg`.
    rest="${cmd#"$exe"}"
    rest="${rest#"${rest%%[![:space:]]*}"}"
    gsettings set org.gnome.desktop.default-applications.terminal exec "$exe" || true
    if [[ -n "$rest" ]]; then
        gsettings set org.gnome.desktop.default-applications.terminal exec-arg "$rest" || true
    fi
fi
