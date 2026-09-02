#!/usr/bin/env -S /bin/sh -c "source $(eval echo $ILLOGICAL_IMPULSE_VIRTUAL_ENV)/bin/activate&&exec python -E \"$0\" \"$@\""
import argparse
import json
import os
import re
import subprocess
import tempfile

BOOL_KEYS = {
    "decoration:blur:enabled",
    "decoration:blur:xray",
    "decoration:blur:new_optimizations",
    "decoration:blur:special",
    "decoration:blur:popups",
    "decoration:blur:popups_ignorealpha",
    "decoration:shadow:enabled",
    "decoration:shadow:sharp",
    "decoration:dim_inactive",
    "decoration:dim_modal",
    "decoration:dim_around",
    "decoration:border_part_of_window",
    "animations:enabled",
    "general:resize_on_border",
    "general:allow_tearing",
    "general:extend_border_grab_area",
    "general:hover_icon_on_border",
    "general:no_focus_fallback",
    "general:snap:enabled",
    "general:snap:border_overlap",
    "general:snap:respect_gaps",
    "input:numlock_by_default",
    "input:touchpad:natural_scroll",
    "input:touchpad:disable_while_typing",
    "input:touchpad:clickfinger_behavior",
    "input:touchpad:tap_to_click",
    "input:touchpad:tap_and_drag",
    "input:touchpad:drag_lock",
    "input:force_no_accel",
    "input:left_handed",
    "misc:disable_hyprland_logo",
    "misc:disable_splash_rendering",
    "misc:mouse_move_enables_dpms",
    "misc:key_press_enables_dpms",
    "misc:animate_manual_resizes",
    "misc:animate_mouse_windowdragging",
    "misc:allow_session_lock_restore",
    "cursor:zoom_rigid",
    "cursor:hide_on_key_press",
    "cursor:hide_on_touch",
    "cursor:no_warps",
    "cursor:persistent_warps",
    "gestures:workspace_swipe_direction_lock",
    "gestures:workspace_swipe_create_new",
    "dwindle:preserve_split",
    "dwindle:smart_split",
    "dwindle:smart_resizing",
    "group:auto_group",
    "group:drag_into_group",
    "group:merge_groups_on_drag",
    "group:groupbar:enabled",
}

_option_support_cache = {}


def option_is_supported(key):
    """Return whether the running Hyprland accepts *key*.

    A failed lookup is deliberately treated as unknown rather than unsupported:
    this script may be used while Hyprland is not running, and must not erase a
    user's saved override just because it cannot contact the compositor.
    """
    # Hyprglass plugin keys must be written even when the plugin is not yet
    # loaded (e.g. first-time enable). Hyprctl will report them as unsupported
    # until the .so is loaded, but we want them persisted to shellOverrides.
    if key.startswith("plugin:hyprglass:"):
        return True
    if key in _option_support_cache:
        return _option_support_cache[key]

    try:
        result = subprocess.run(
            ["hyprctl", "-j", "getoption", key],
            capture_output=True,
            text=True,
            timeout=2,
            check=False,
        )
    except (OSError, subprocess.TimeoutExpired):
        _option_support_cache[key] = None
        return None

    try:
        response = json.loads(result.stdout)
        supported = isinstance(response, dict) and response.get("option") == key
    except json.JSONDecodeError:
        # "no such option" is sent on stdout by hyprctl. Only mark it absent
        # when the command itself completed, preserving data on transport errors.
        supported = False if result.returncode == 0 else None

    _option_support_cache[key] = supported
    return supported

ANIM_PRESETS = {
    "fast": """\
hl.curve("pc_wobble", { type = "bezier", points = { {0.15, 1.15}, {0.35, 1.0}  } })
hl.curve("pc_decel",  { type = "bezier", points = { {0.05, 0.9},  {0.1,  1.05} } })
hl.curve("pc_accel",  { type = "bezier", points = { {0.3,  0},    {0.8,  0.15} } })
hl.animation({ leaf = "windowsIn",           enabled = true, speed = 5, bezier = "pc_wobble", style = "slide"     })
hl.animation({ leaf = "windowsOut",          enabled = true, speed = 5, bezier = "pc_accel",  style = "slide"     })
hl.animation({ leaf = "windowsMove",         enabled = true, speed = 5, bezier = "pc_decel",  style = "slide"     })
hl.animation({ leaf = "fadeIn",              enabled = true, speed = 4, bezier = "pc_decel"                       })
hl.animation({ leaf = "fadeOut",             enabled = true, speed = 4, bezier = "pc_accel"                       })
hl.animation({ leaf = "layersIn",            enabled = true, speed = 4, bezier = "pc_decel",  style = "slide"     })
hl.animation({ leaf = "layersOut",           enabled = true, speed = 4, bezier = "pc_accel",  style = "slide"     })
hl.animation({ leaf = "workspaces",          enabled = true, speed = 6, bezier = "pc_decel",  style = "slide"     })
hl.animation({ leaf = "specialWorkspaceIn",  enabled = true, speed = 2, bezier = "pc_wobble", style = "slidevert" })
hl.animation({ leaf = "specialWorkspaceOut", enabled = true, speed = 2, bezier = "pc_accel",  style = "slidevert" })
""",
    "normal": """\
hl.curve("emphasizedDecel", { type = "bezier", points = { {0.05, 0.7},  {0.1,  1}    } })
hl.curve("emphasizedAccel", { type = "bezier", points = { {0.3,  0},    {0.8,  0.15} } })
hl.curve("menu_decel",      { type = "bezier", points = { {0.1,  1},    {0,    1}    } })
hl.curve("menu_accel",      { type = "bezier", points = { {0.52, 0.03}, {0.72, 0.08} } })
hl.curve("stall",           { type = "bezier", points = { {1,    -0.1}, {0.7,  0.85} } })
hl.animation({ leaf = "windowsIn",           enabled = true, speed = 3,   bezier = "emphasizedDecel", style = "popin 80%" })
hl.animation({ leaf = "windowsOut",          enabled = true, speed = 2,   bezier = "emphasizedDecel", style = "popin 90%" })
hl.animation({ leaf = "windowsMove",         enabled = true, speed = 3,   bezier = "emphasizedDecel", style = "slide"     })
hl.animation({ leaf = "fadeIn",              enabled = true, speed = 3,   bezier = "emphasizedDecel"  })
hl.animation({ leaf = "fadeOut",             enabled = true, speed = 2,   bezier = "emphasizedDecel"  })
hl.animation({ leaf = "border",              enabled = true, speed = 10,  bezier = "emphasizedDecel"  })
hl.animation({ leaf = "layersIn",            enabled = true, speed = 2.7, bezier = "emphasizedDecel", style = "popin 93%" })
hl.animation({ leaf = "layersOut",           enabled = true, speed = 2.4, bezier = "menu_accel",      style = "popin 94%" })
hl.animation({ leaf = "fadeLayersIn",        enabled = true, speed = 0.5, bezier = "menu_decel"       })
hl.animation({ leaf = "fadeLayersOut",       enabled = true, speed = 2.7, bezier = "stall"            })
hl.animation({ leaf = "workspaces",          enabled = true, speed = 7,   bezier = "menu_decel",      style = "slide"     })
hl.animation({ leaf = "specialWorkspaceIn",  enabled = true, speed = 2.8, bezier = "emphasizedDecel", style = "slidevert" })
hl.animation({ leaf = "specialWorkspaceOut", enabled = true, speed = 1.2, bezier = "emphasizedAccel", style = "slidevert" })
""",
    "niri": """\
hl.curve("niri_wobble", { type = "bezier", points = { {0.15, 1.15}, {0.35, 1.0}  } })
hl.curve("niri_decel",  { type = "bezier", points = { {0.05, 0.9},  {0.1,  1.05} } })
hl.curve("niri_accel",  { type = "bezier", points = { {0.3,  0},    {0.8,  0.15} } })
hl.animation({ leaf = "windowsIn",           enabled = true, speed = 5, bezier = "niri_wobble", style = "slide"     })
hl.animation({ leaf = "windowsOut",          enabled = true, speed = 5, bezier = "niri_accel",  style = "slide"     })
hl.animation({ leaf = "windowsMove",         enabled = true, speed = 5, bezier = "niri_decel",  style = "slide"     })
hl.animation({ leaf = "fadeIn",              enabled = true, speed = 4, bezier = "niri_decel"                       })
hl.animation({ leaf = "fadeOut",             enabled = true, speed = 4, bezier = "niri_accel"                       })
hl.animation({ leaf = "layersIn",            enabled = true, speed = 4, bezier = "niri_decel",  style = "slide"     })
hl.animation({ leaf = "layersOut",           enabled = true, speed = 4, bezier = "niri_accel",  style = "slide"     })
hl.animation({ leaf = "workspaces",          enabled = true, speed = 6, bezier = "niri_decel",  style = "slidevert" })
hl.animation({ leaf = "specialWorkspaceIn",  enabled = true, speed = 4, bezier = "niri_wobble", style = "slidevert" })
hl.animation({ leaf = "specialWorkspaceOut", enabled = true, speed = 4, bezier = "niri_accel",  style = "slidevert" })
""",
}


def to_lua_value(key, value):
    if key in BOOL_KEYS:
        return "false" if value == "0" else "true"
    # Vector like "0, 2" for shadow:offset -> { 0, 2 }
    if isinstance(value, str) and "," in value:
        parts = [p.strip() for p in value.split(",")]
        try:
            nums = [str(float(p)) if "." in p else str(int(p)) for p in parts]
            # keep integer look if possible
            cleaned = []
            for n, p in zip(nums, parts):
                if "." in p:
                    cleaned.append(str(float(p)))
                else:
                    cleaned.append(str(int(p)))
            return "{ " + ", ".join(cleaned) + " }"
        except:
            pass
    try:
        return str(int(value))
    except ValueError:
        pass
    try:
        return str(float(value))
    except ValueError:
        pass
    return f'"{value}"'


def to_lua_line(key, value):
    parts = key.replace(":", ".").split(".")
    val = to_lua_value(key, value)
    inner = f"{{ {parts[-1]} = {val} }}"
    for part in reversed(parts[:-1]):
        inner = f"{{ {part} = {inner} }}"
    return f"hl.config({inner})\n"


def make_marker(key):
    parts = key.replace(":", ".").split(".")

    fragment = " = { ".join(parts[:-1])
    if fragment:
        fragment += " = { " + parts[-1] + " ="
    else:
        fragment = parts[-1] + " ="
    return fragment


def write_atomic(path, content):
    dir_name = os.path.dirname(os.path.abspath(path))
    os.makedirs(dir_name, exist_ok=True)
    tmp_path = None
    try:
        with tempfile.NamedTemporaryFile(mode="w", dir=dir_name, delete=False) as f:
            f.write(content)
            tmp_path = f.name
        if os.path.exists(path):
            os.chmod(tmp_path, os.stat(path).st_mode)
        os.replace(tmp_path, path)
    except Exception as e:
        if tmp_path and os.path.exists(tmp_path):
            os.remove(tmp_path)
        raise e


def edit_lua(file_path, set_pairs, reset_keys):
    unsupported_keys = []
    supported_pairs = []
    for key, value in set_pairs:
        if option_is_supported(key) is False:
            unsupported_keys.append(key)
            print(f"Skipped unsupported Hyprland option: {key}")
        else:
            supported_pairs.append((key, value))

    # Remove stale auto-managed lines when the running compositor explicitly
    # reports that an option no longer exists (e.g. after a Hyprland upgrade).
    set_pairs = supported_pairs
    reset_keys = list(reset_keys) + unsupported_keys

    try:
        with open(file_path) as f:
            lines = f.readlines()
    except FileNotFoundError:
        lines = []

    set_dict   = dict(set_pairs)
    reset_set  = set(reset_keys)
    all_keys   = list(set_dict) + list(reset_set)
    markers    = {k: make_marker(k) for k in all_keys}

    new_lines  = []
    found_keys = set()

    for line in lines:
        matched = None
        for k in all_keys:
            if markers[k] in line:
                matched = k
                break
        if matched is None:
            new_lines.append(line)
        elif matched in reset_set:
            print(f"Removed: {matched}")
        else:
            new_lines.append(to_lua_line(matched, set_dict[matched]))
            found_keys.add(matched)
            print(f"Updated: {to_lua_line(matched, set_dict[matched]).strip()}")

    for k, v in set_dict.items():
        if k not in found_keys:
            new_lines.append(to_lua_line(k, v))
            print(f"Added:   {to_lua_line(k, v).strip()}")

    write_atomic(file_path, "".join(new_lines))


def save_preset(anim_file, preset_name):
    content = ANIM_PRESETS.get(preset_name)
    if not content:
        print(f"Unknown preset '{preset_name}'")
        return
    write_atomic(anim_file, content)
    print(f"Wrote preset '{preset_name}' -> {anim_file}")


def save_custom_animations(anim_file, curves_json, anims_json):
    import json as _json
    try:
        curves = _json.loads(curves_json) if isinstance(curves_json, str) else curves_json
        anims = _json.loads(anims_json) if isinstance(anims_json, str) else anims_json
    except Exception as e:
        print(f"Failed to parse custom JSON: {e}")
        return
    lines = []
    lines.append("-- Generated by end4-pC custom animations editor\n")
    lines.append("-- Curves\n")
    for c in curves:
        name = c.get("name", "")
        if not name:
            continue
        t = c.get("type", "bezier")
        if t == "spring":
            mass = c.get("mass", 1)
            stiff = c.get("stiffness", 100)
            damp = c.get("dampening", c.get("damping", 15))
            lines.append(f'hl.curve("{name}", {{ type = "spring", mass = {mass}, stiffness = {stiff}, dampening = {damp} }})\n')
        else:
            pts = c.get("points", [[0, 0], [1, 1]])
            # normalize to 2 points
            if len(pts) >= 2:
                x0, y0 = pts[0][0], pts[0][1]
                x1, y1 = pts[1][0], pts[1][1]
                lines.append(f'hl.curve("{name}", {{ type = "bezier", points = {{ {{{x0}, {y0}}}, {{{x1}, {y1}}} }} }})\n')
    lines.append("\n-- Animations (tree: inherits parent if unset)\n")
    # official tree order for readability
    order = ["global","windows","windowsIn","windowsOut","windowsMove","layers","layersIn","layersOut","fade","fadeIn","fadeOut","fadeSwitch","fadeShadow","fadeDim","fadeLayers","fadeLayersIn","fadeLayersOut","fadePopups","fadePopupsIn","fadePopupsOut","fadeDpms","border","borderangle","shadowangle","glowangle","workspaces","workspacesIn","workspacesOut","specialWorkspace","specialWorkspaceIn","specialWorkspaceOut","zoomFactor","monitorAdded"]
    # sort anims by order
    def sort_key(a):
        try: return order.index(a.get("leaf",""))
        except: return 999
    anims_sorted = sorted(anims, key=sort_key)
    for a in anims_sorted:
        leaf = a.get("leaf","")
        if not leaf:
            continue
        enabled = a.get("enabled", True)
        if not enabled:
            lines.append(f'hl.animation({{ leaf = "{leaf}", enabled = false }})\n')
            continue
        speed = a.get("speed", 3)
        # Determine bezier vs spring
        bez = a.get("bezier", "")
        spr = a.get("spring", "")
        style = a.get("style", "")
        parts = [f'leaf = "{leaf}"', 'enabled = true', f'speed = {speed}']
        if spr:
            parts.append(f'spring = "{spr}"')
        elif bez:
            parts.append(f'bezier = "{bez}"')
        if style:
            # escape quotes
            style_esc = style.replace('"', '\\"')
            parts.append(f'style = "{style_esc}"')
        lines.append(f'hl.animation({{ {", ".join(parts)} }})\n')
    write_atomic(anim_file, "".join(lines))
    print(f"Wrote custom animations ({len(curves)} curves, {len(anims)} anims) -> {anim_file}")


def save_custom_file(path, content):
    write_atomic(os.path.expanduser(path), content)
    print(f"Wrote custom file -> {path} ({len(content)} chars)")


def save_monitors_json(monitors_json, monitors_file):
    """Generate monitor lua lines from JSON array of monitor configs.
    Each entry: {output, mode, position, scale, transform, mirror, bitdepth, vrr, cm, icc_profile, reserved_area, disabled}
    """
    import json as _json
    try:
        monitors = _json.loads(monitors_json) if isinstance(monitors_json, str) else monitors_json
    except Exception as e:
        print(f"Failed to parse monitors JSON: {e}")
        return
    lines = ["-- Generated by end4-pC monitor config editor\n"]
    for m in monitors:
        output = str(m.get("output", "")).replace("\\", "\\\\").replace('"', '\\"')
        if m.get("disabled"):
            lines.append(f'hl.monitor({{ output = "{output}", mode = "disabled" }})\n')
            continue
        parts = []
        parts.append(f'output = "{output}"')
        parts.append(f'mode = "{m.get("mode", "preferred")}"')
        pos = m.get("position", "auto")
        parts.append(f'position = "{pos}"')
        parts.append(f'scale = {m.get("scale", 1)}')
        transform = m.get("transform", 0)
        if transform:
            parts.append(f'transform = {transform}')
        mirror = m.get("mirror", "")
        if mirror and mirror != "none":
            parts.append(f'mirror = "{mirror}"')
        bitdepth = m.get("bitdepth", 8)
        if bitdepth and bitdepth != 8:
            parts.append(f'bitdepth = {bitdepth}')
        vrr = m.get("vrr", 0)
        if vrr:
            parts.append(f'vrr = {vrr}')
        cm = m.get("cm", "")
        if cm and cm != "auto":
            parts.append(f'cm = "{cm}"')
        icc = m.get("icc_profile", "")
        if icc:
            parts.append(f'icc_profile = "{icc}"')
        reserved = m.get("reserved_area", 0)
        if reserved:
            if isinstance(reserved, dict):
                parts.append(f'reserved_area = {{ top = {reserved.get("top", 0)}, bottom = {reserved.get("bottom", 0)}, left = {reserved.get("left", 0)}, right = {reserved.get("right", 0)} }}')
            else:
                parts.append(f'reserved_area = {reserved}')
        lines.append(f'hl.monitor({{{", ".join(parts)}}})\n')
    write_atomic(os.path.expanduser(monitors_file), "".join(lines))
    print(f"Wrote {len(monitors)} monitor(s) -> {monitors_file}")


if __name__ == "__main__":
    p = argparse.ArgumentParser()
    p.add_argument("--file", default="~/.config/hypr/hyprland/shellOverrides/main.lua")
    p.add_argument("--set", nargs=2, action="append", metavar=("KEY", "VALUE"))
    p.add_argument("--reset", action="append", metavar="KEY")
    p.add_argument("--anim-preset", metavar="PRESET")
    p.add_argument("--anim-file", default="~/.config/hypr/hyprland/shellOverrides/animations.lua")
    p.add_argument("--anim-curves-json", metavar="JSON")
    p.add_argument("--anim-anims-json", metavar="JSON")
    p.add_argument("--custom-binds", metavar="CONTENT")
    p.add_argument("--custom-binds-file", metavar="FILE")
    p.add_argument("--custom-rules", metavar="CONTENT")
    p.add_argument("--custom-rules-file", metavar="FILE")
    p.add_argument("--monitors-json", metavar="JSON")
    p.add_argument("--monitors-file", default="~/.config/hypr/monitors.lua")
    args = p.parse_args()

    if args.custom_binds is not None and args.custom_binds_file:
        save_custom_file(args.custom_binds_file, args.custom_binds)
    if args.custom_rules is not None and args.custom_rules_file:
        save_custom_file(args.custom_rules_file, args.custom_rules)
    if args.monitors_json:
        save_monitors_json(args.monitors_json, args.monitors_file)
    if args.anim_curves_json and args.anim_anims_json:
        save_custom_animations(os.path.expanduser(args.anim_file), args.anim_curves_json, args.anim_anims_json)
    elif args.anim_preset:
        save_preset(os.path.expanduser(args.anim_file), args.anim_preset)

    raw_sets   = args.set or []
    reset_keys = args.reset or []
    set_pairs  = []
    for k, v in raw_sets:
        if v == "[[EMPTY]]":
            reset_keys.append(k)
        else:
            set_pairs.append((k, v))

    if set_pairs or reset_keys:
        edit_lua(os.path.expanduser(args.file), set_pairs, reset_keys)
    elif not args.anim_preset and not (args.anim_curves_json and args.anim_anims_json) and args.custom_binds is None and args.custom_rules is None:
        print("Error: specify --set, --reset, --anim-preset, --anim-curves-json+--anim-anims-json, --custom-binds or --custom-rules")
