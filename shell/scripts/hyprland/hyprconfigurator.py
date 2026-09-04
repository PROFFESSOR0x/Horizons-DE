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


# Each preset below is a self-consistent, complete set of curves + speeds for
# every animation leaf Hyprland exposes (see the `order` list further down for
# the authoritative leaf list, cross-checked against Hyprland's own
# example/hyprland.lua and wiki). Bezier control points are taken from real,
# named easing definitions (Material Design 2/3, easings.net) rather than
# invented numbers, so the motion language is recognizable and each preset
# reads as one coherent "feel" rather than a pile of unrelated tweaks.
SNAPPY_PRESET = """\
-- Preset: Snappy - minimal-latency, utilitarian motion. Short durations, no
-- overshoot, no decorative extras (angle animations off). Curves are the
-- textbook easeOutExpo/easeInExpo/easeOutQuart from easings.net.
hl.curve("sn_out",  { type = "bezier", points = { {0.16, 1},   {0.3,  1}    } }) -- easeOutExpo: near-instant settle
hl.curve("sn_in",   { type = "bezier", points = { {0.7,  0},   {0.84, 0}    } }) -- easeInExpo: quick, snappy exit
hl.curve("sn_move", { type = "bezier", points = { {0.25, 1},   {0.5,  1}    } }) -- easeOutQuart: crisp drag/resize follow
hl.animation({ leaf = "global",              enabled = true,  speed = 6,   bezier = "sn_out"                        })
hl.animation({ leaf = "windows",             enabled = true,  speed = 2.2, bezier = "sn_out"                        })
hl.animation({ leaf = "windowsIn",           enabled = true,  speed = 2,   bezier = "sn_out",  style = "popin 90%"  })
hl.animation({ leaf = "windowsOut",          enabled = true,  speed = 1.4, bezier = "sn_in",   style = "popin 90%"  })
hl.animation({ leaf = "windowsMove",         enabled = true,  speed = 2,   bezier = "sn_move"                       })
hl.animation({ leaf = "layers",              enabled = true,  speed = 1.8, bezier = "sn_out"                        })
hl.animation({ leaf = "layersIn",            enabled = true,  speed = 1.8, bezier = "sn_out",  style = "slide"      })
hl.animation({ leaf = "layersOut",           enabled = true,  speed = 1.4, bezier = "sn_in",   style = "slide"      })
hl.animation({ leaf = "fade",                enabled = true,  speed = 1.6, bezier = "sn_out"                        })
hl.animation({ leaf = "fadeIn",              enabled = true,  speed = 1.4, bezier = "sn_out"                        })
hl.animation({ leaf = "fadeOut",             enabled = true,  speed = 1.1, bezier = "sn_in"                         })
hl.animation({ leaf = "fadeSwitch",          enabled = true,  speed = 1,   bezier = "sn_out"                        })
hl.animation({ leaf = "fadeShadow",          enabled = true,  speed = 1.4, bezier = "sn_out"                        })
hl.animation({ leaf = "fadeDim",             enabled = true,  speed = 1.2, bezier = "sn_out"                        })
hl.animation({ leaf = "fadeLayersIn",        enabled = true,  speed = 1.6, bezier = "sn_out"                        })
hl.animation({ leaf = "fadeLayersOut",       enabled = true,  speed = 1.2, bezier = "sn_in"                         })
hl.animation({ leaf = "fadePopups",          enabled = true,  speed = 1.4, bezier = "sn_out"                        })
hl.animation({ leaf = "fadePopupsIn",        enabled = true,  speed = 1.4, bezier = "sn_out"                        })
hl.animation({ leaf = "fadePopupsOut",       enabled = true,  speed = 1.1, bezier = "sn_in"                         })
hl.animation({ leaf = "fadeDpms",            enabled = true,  speed = 3,   bezier = "sn_out"                        })
hl.animation({ leaf = "border",              enabled = true,  speed = 4,   bezier = "sn_out"                        })
hl.animation({ leaf = "borderangle",         enabled = false                                                        })
hl.animation({ leaf = "shadowangle",         enabled = false                                                        })
hl.animation({ leaf = "glowangle",           enabled = false                                                        })
hl.animation({ leaf = "workspaces",          enabled = true,  speed = 2.4, bezier = "sn_move", style = "slide"      })
hl.animation({ leaf = "workspacesIn",        enabled = true,  speed = 2.2, bezier = "sn_out",  style = "slide"      })
hl.animation({ leaf = "workspacesOut",       enabled = true,  speed = 1.6, bezier = "sn_in",   style = "slide"      })
hl.animation({ leaf = "specialWorkspace",    enabled = true,  speed = 2.2, bezier = "sn_out",  style = "slidevert"  })
hl.animation({ leaf = "specialWorkspaceIn",  enabled = true,  speed = 2.2, bezier = "sn_out",  style = "slidevert"  })
hl.animation({ leaf = "specialWorkspaceOut", enabled = true,  speed = 1.6, bezier = "sn_in",   style = "slidevert"  })
hl.animation({ leaf = "zoomFactor",          enabled = true,  speed = 3,   bezier = "sn_out"                        })
"""
SMOOTH_PRESET = """\
-- Preset: Smooth (default) - Material Design "standard" easing family:
-- balanced, everyday motion that neither rushes nor lingers. Good default
-- for daily driving; angle animations (border/shadow/glow gradient spin)
-- stay off since they're a decorative flourish, not part of the base feel.
hl.curve("sm_standard", { type = "bezier", points = { {0.4, 0},   {0.2, 1}   } }) -- Material standard
hl.curve("sm_decel",    { type = "bezier", points = { {0,   0},   {0.2, 1}   } }) -- Material standard decelerate
hl.curve("sm_accel",    { type = "bezier", points = { {0.4, 0},   {1,   1}   } }) -- Material standard accelerate
hl.curve("sm_linear",   { type = "bezier", points = { {0,   0},   {1,   1}   } }) -- for continuous angle loops
hl.animation({ leaf = "global",              enabled = true,  speed = 10,  bezier = "sm_standard"                    })
hl.animation({ leaf = "windows",             enabled = true,  speed = 4.2, bezier = "sm_standard"                    })
hl.animation({ leaf = "windowsIn",           enabled = true,  speed = 3.6, bezier = "sm_decel",  style = "popin 85%" })
hl.animation({ leaf = "windowsOut",          enabled = true,  speed = 2.6, bezier = "sm_accel",  style = "popin 85%" })
hl.animation({ leaf = "windowsMove",         enabled = true,  speed = 4,   bezier = "sm_standard"                    })
hl.animation({ leaf = "layers",              enabled = true,  speed = 3,   bezier = "sm_standard"                    })
hl.animation({ leaf = "layersIn",            enabled = true,  speed = 3,   bezier = "sm_decel",  style = "slide"     })
hl.animation({ leaf = "layersOut",           enabled = true,  speed = 2.4, bezier = "sm_accel",  style = "slide"     })
hl.animation({ leaf = "fade",                enabled = true,  speed = 3,   bezier = "sm_standard"                    })
hl.animation({ leaf = "fadeIn",              enabled = true,  speed = 3,   bezier = "sm_decel"                       })
hl.animation({ leaf = "fadeOut",             enabled = true,  speed = 2.4, bezier = "sm_accel"                       })
hl.animation({ leaf = "fadeSwitch",          enabled = true,  speed = 2,   bezier = "sm_standard"                    })
hl.animation({ leaf = "fadeShadow",          enabled = true,  speed = 3,   bezier = "sm_standard"                    })
hl.animation({ leaf = "fadeDim",             enabled = true,  speed = 3,   bezier = "sm_standard"                    })
hl.animation({ leaf = "fadeLayersIn",        enabled = true,  speed = 2.6, bezier = "sm_decel"                       })
hl.animation({ leaf = "fadeLayersOut",       enabled = true,  speed = 2.2, bezier = "sm_accel"                       })
hl.animation({ leaf = "fadePopups",          enabled = true,  speed = 2.4, bezier = "sm_standard"                    })
hl.animation({ leaf = "fadePopupsIn",        enabled = true,  speed = 2.4, bezier = "sm_decel"                       })
hl.animation({ leaf = "fadePopupsOut",       enabled = true,  speed = 2,   bezier = "sm_accel"                       })
hl.animation({ leaf = "fadeDpms",            enabled = true,  speed = 6,   bezier = "sm_standard"                    })
hl.animation({ leaf = "border",              enabled = true,  speed = 6,   bezier = "sm_standard"                    })
hl.animation({ leaf = "borderangle",         enabled = false, speed = 30,  bezier = "sm_linear", style = "loop"      })
hl.animation({ leaf = "shadowangle",         enabled = false, speed = 30,  bezier = "sm_linear", style = "loop"      })
hl.animation({ leaf = "glowangle",           enabled = false, speed = 30,  bezier = "sm_linear", style = "loop"      })
hl.animation({ leaf = "workspaces",          enabled = true,  speed = 5,   bezier = "sm_standard", style = "slide"   })
hl.animation({ leaf = "workspacesIn",        enabled = true,  speed = 4.5, bezier = "sm_decel",  style = "slide"     })
hl.animation({ leaf = "workspacesOut",       enabled = true,  speed = 3.6, bezier = "sm_accel",  style = "slide"     })
hl.animation({ leaf = "specialWorkspace",    enabled = true,  speed = 4,   bezier = "sm_standard", style = "slidevert" })
hl.animation({ leaf = "specialWorkspaceIn",  enabled = true,  speed = 4,   bezier = "sm_decel",  style = "slidevert" })
hl.animation({ leaf = "specialWorkspaceOut", enabled = true,  speed = 3,   bezier = "sm_accel",  style = "slidevert" })
hl.animation({ leaf = "zoomFactor",          enabled = true,  speed = 6,   bezier = "sm_standard"                    })
"""
EXPRESSIVE_PRESET = """\
-- Preset: Expressive - Material 3 "expressive" motion: pronounced overshoot
-- on window/workspace open, an underdamped spring for a playful bounce.
-- emphasizedDecel/emphasizedAccel are the real published M3 emphasized-easing
-- values; easeOutBack (easings.net) supplies the overshoot on layers/popups;
-- the spring is intentionally underdamped (stiffness >> critical damping) so
-- the bounce is visible rather than just "springy-feeling".
hl.curve("ex_emphDecel",  { type = "bezier", points = { {0.05, 0.7},  {0.1,  1}    } }) -- Material 3 emphasized decelerate
hl.curve("ex_emphAccel",  { type = "bezier", points = { {0.3,  0},    {0.8,  0.15} } }) -- Material 3 emphasized accelerate
hl.curve("ex_overshoot",  { type = "bezier", points = { {0.34, 1.56}, {0.64, 1}    } }) -- easeOutBack: visible overshoot then settle
hl.curve("ex_bounce", { type = "spring", mass = 1, stiffness = 170, dampening = 12 }) -- underdamped spring: pronounced pop-in bounce
hl.animation({ leaf = "global",              enabled = true,  speed = 10,  bezier = "ex_emphDecel"                     })
hl.animation({ leaf = "windows",             enabled = true,  speed = 4.2, bezier = "ex_emphDecel"                     })
hl.animation({ leaf = "windowsIn",           enabled = true,  speed = 4.6, spring = "ex_bounce",  style = "popin 70%"  })
hl.animation({ leaf = "windowsOut",          enabled = true,  speed = 2.2, bezier = "ex_emphAccel", style = "popin 90%" })
hl.animation({ leaf = "windowsMove",         enabled = true,  speed = 4,   bezier = "ex_emphDecel"                     })
hl.animation({ leaf = "layers",              enabled = true,  speed = 3,   bezier = "ex_emphDecel"                     })
hl.animation({ leaf = "layersIn",            enabled = true,  speed = 3.2, bezier = "ex_overshoot", style = "popin 85%" })
hl.animation({ leaf = "layersOut",           enabled = true,  speed = 2.4, bezier = "ex_emphAccel", style = "popin 92%" })
hl.animation({ leaf = "fade",                enabled = true,  speed = 3,   bezier = "ex_emphDecel"                     })
hl.animation({ leaf = "fadeIn",              enabled = true,  speed = 3.4, bezier = "ex_emphDecel"                     })
hl.animation({ leaf = "fadeOut",             enabled = true,  speed = 2.2, bezier = "ex_emphAccel"                     })
hl.animation({ leaf = "fadeSwitch",          enabled = true,  speed = 2.4, bezier = "ex_emphDecel"                     })
hl.animation({ leaf = "fadeShadow",          enabled = true,  speed = 3.4, bezier = "ex_emphDecel"                     })
hl.animation({ leaf = "fadeDim",             enabled = true,  speed = 3,   bezier = "ex_emphDecel"                     })
hl.animation({ leaf = "fadeLayersIn",        enabled = true,  speed = 2.8, bezier = "ex_overshoot"                     })
hl.animation({ leaf = "fadeLayersOut",       enabled = true,  speed = 2.2, bezier = "ex_emphAccel"                     })
hl.animation({ leaf = "fadePopups",          enabled = true,  speed = 2.6, bezier = "ex_emphDecel"                     })
hl.animation({ leaf = "fadePopupsIn",        enabled = true,  speed = 2.6, bezier = "ex_overshoot"                     })
hl.animation({ leaf = "fadePopupsOut",       enabled = true,  speed = 2,   bezier = "ex_emphAccel"                     })
hl.animation({ leaf = "fadeDpms",            enabled = true,  speed = 6,   bezier = "ex_emphDecel"                     })
hl.animation({ leaf = "border",              enabled = true,  speed = 8,   bezier = "ex_emphDecel"                     })
hl.animation({ leaf = "borderangle",         enabled = true,  speed = 20,  bezier = "ex_emphDecel", style = "loop"     })
hl.animation({ leaf = "shadowangle",         enabled = false                                                           })
hl.animation({ leaf = "glowangle",           enabled = false                                                           })
hl.animation({ leaf = "workspaces",          enabled = true,  speed = 9,   bezier = "ex_overshoot", style = "slide"    })
hl.animation({ leaf = "workspacesIn",        enabled = true,  speed = 8,   bezier = "ex_overshoot", style = "slide"    })
hl.animation({ leaf = "workspacesOut",       enabled = true,  speed = 5,   bezier = "ex_emphAccel", style = "slide"    })
hl.animation({ leaf = "specialWorkspace",    enabled = true,  speed = 5,   bezier = "ex_overshoot", style = "slidevert" })
hl.animation({ leaf = "specialWorkspaceIn",  enabled = true,  speed = 5,   bezier = "ex_overshoot", style = "slidevert" })
hl.animation({ leaf = "specialWorkspaceOut", enabled = true,  speed = 3,   bezier = "ex_emphAccel", style = "slidevert" })
hl.animation({ leaf = "zoomFactor",          enabled = true,  speed = 8,   bezier = "ex_emphDecel"                     })
"""
REDUCED_MOTION_PRESET = """\
-- Preset: Reduced Motion (accessibility) - a genuine "prefers-reduced-motion"
-- equivalent, not just a faster preset: parallax/slide/zoom/rotation leaves
-- that can trigger vestibular discomfort are disabled outright (windowsMove,
-- zoomFactor, borderangle/shadowangle/glowangle, fadeSwitch/fadeShadow/
-- fadeDim), workspace/special-workspace transitions are forced to a short
-- plain crossfade instead of sliding, and every remaining leaf uses a linear
-- curve at ~100-200ms so state changes still register without motion cues.
hl.curve("rm_linear", { type = "bezier", points = { {0, 0}, {1, 1} } }) -- plain, uninflected crossfade
hl.animation({ leaf = "global",              enabled = true,  speed = 2, bezier = "rm_linear"                    })
hl.animation({ leaf = "windows",             enabled = true,  speed = 1, bezier = "rm_linear"                    })
hl.animation({ leaf = "windowsIn",           enabled = true,  speed = 1, bezier = "rm_linear", style = ""        })
hl.animation({ leaf = "windowsOut",          enabled = true,  speed = 1, bezier = "rm_linear", style = ""        })
hl.animation({ leaf = "windowsMove",         enabled = false                                                     })
hl.animation({ leaf = "layers",              enabled = true,  speed = 1, bezier = "rm_linear"                    })
hl.animation({ leaf = "layersIn",            enabled = true,  speed = 1, bezier = "rm_linear", style = ""        })
hl.animation({ leaf = "layersOut",           enabled = true,  speed = 1, bezier = "rm_linear", style = ""        })
hl.animation({ leaf = "fade",                enabled = true,  speed = 1, bezier = "rm_linear"                    })
hl.animation({ leaf = "fadeIn",              enabled = true,  speed = 1, bezier = "rm_linear"                    })
hl.animation({ leaf = "fadeOut",             enabled = true,  speed = 1, bezier = "rm_linear"                    })
hl.animation({ leaf = "fadeSwitch",          enabled = false                                                     })
hl.animation({ leaf = "fadeShadow",          enabled = false                                                     })
hl.animation({ leaf = "fadeDim",             enabled = false                                                     })
hl.animation({ leaf = "fadeLayersIn",        enabled = true,  speed = 1, bezier = "rm_linear"                    })
hl.animation({ leaf = "fadeLayersOut",       enabled = true,  speed = 1, bezier = "rm_linear"                    })
hl.animation({ leaf = "fadePopups",          enabled = true,  speed = 1, bezier = "rm_linear"                    })
hl.animation({ leaf = "fadePopupsIn",        enabled = true,  speed = 1, bezier = "rm_linear"                    })
hl.animation({ leaf = "fadePopupsOut",       enabled = true,  speed = 1, bezier = "rm_linear"                    })
hl.animation({ leaf = "fadeDpms",            enabled = true,  speed = 2, bezier = "rm_linear"                    })
hl.animation({ leaf = "border",              enabled = true,  speed = 1, bezier = "rm_linear"                    })
hl.animation({ leaf = "borderangle",         enabled = false                                                     })
hl.animation({ leaf = "shadowangle",         enabled = false                                                     })
hl.animation({ leaf = "glowangle",           enabled = false                                                     })
hl.animation({ leaf = "workspaces",          enabled = true,  speed = 1, bezier = "rm_linear", style = "fade"    })
hl.animation({ leaf = "workspacesIn",        enabled = true,  speed = 1, bezier = "rm_linear", style = "fade"    })
hl.animation({ leaf = "workspacesOut",       enabled = true,  speed = 1, bezier = "rm_linear", style = "fade"    })
hl.animation({ leaf = "specialWorkspace",    enabled = true,  speed = 1, bezier = "rm_linear", style = "fade"    })
hl.animation({ leaf = "specialWorkspaceIn",  enabled = true,  speed = 1, bezier = "rm_linear", style = "fade"    })
hl.animation({ leaf = "specialWorkspaceOut", enabled = true,  speed = 1, bezier = "rm_linear", style = "fade"    })
hl.animation({ leaf = "zoomFactor",          enabled = false                                                     })
"""

ANIM_PRESETS = {
    "snappy": SNAPPY_PRESET,
    "smooth": SMOOTH_PRESET,
    "expressive": EXPRESSIVE_PRESET,
    "reduced_motion": REDUCED_MOTION_PRESET,
    # Back-compat aliases for configs that stored the old preset identifiers.
    "fast": SNAPPY_PRESET,
    "normal": SMOOTH_PRESET,
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
    write_atomic(anim_file, "-- Generated by Horizons custom animations editor\n" + content)
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
    lines.append("-- Generated by Horizons custom animations editor\n")
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
    lines = ["-- Generated by Horizons monitor config editor\n"]
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
