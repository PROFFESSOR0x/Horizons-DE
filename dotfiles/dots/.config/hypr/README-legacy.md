# Hyprland config: Lua + legacy `.conf` side by side

> ملاحظة سريعة بالعربية: مجلد `hypr` فيه نسختين من نفس الإعدادات. Hyprland
> الجديد (0.55+) بيحمّل ملفات `.lua`، والقديم (زي نسخ Ubuntu اللي لسه
> موصلهاش التحديث) بيحمّل ملفات `.conf`. ثبّت الاتنين وخلي Hyprland يختار
> المناسب له — مش محتاج تعمل حاجة يدوياً.

## How it works

Hyprland ≥ 0.55 loads `hyprland.lua` **instead of** `hyprland.conf`
([upstream announcement](https://hypr.land/news/26_lua)). Older builds
(e.g. Ubuntu archive / PPA builds before the Lua update) ignore every
`.lua` file and load `hyprland.conf`. Both entry points ship in this repo,
so each machine automatically picks the syntax its Hyprland understands.

## Mirror table (keep each pair in sync when editing!)

| Lua (Hyprland ≥ 0.55) | Legacy `.conf` (Hyprland < 0.55) |
|---|---|
| `hyprland.lua` | `hyprland.conf` |
| `hyprland/env.lua` | `hyprland/env.conf` |
| `hyprland/variables.lua` | `hyprland/variables.conf` |
| `hyprland/execs.lua` | `hyprland/execs.conf` |
| `hyprland/general.lua` | `hyprland/general.conf` |
| `hyprland/rules.lua` | `hyprland/rules.conf` |
| `hyprland/colors.lua` | `hyprland/colors.conf` |
| `hyprland/keybinds.lua` | `hyprland/keybinds.conf` |
| `hyprland/shellOverrides/main.lua` | `hyprland/shellOverrides/main.conf` |
| `hyprland/shellOverrides/animations.lua` | `hyprland/shellOverrides/animations.conf` |
| `monitors.lua` | `monitors.conf` |
| `custom/*.lua` | `custom/*.conf` |

## Installer support (auto-detect, Ubuntu included)

The dots installer knows about both variants (`sdata/lib/hypr-variant.sh`):

- It probes the **installed** Hyprland (`hyprland --version`, `hyprctl
  version`, dpkg/pacman/rpm) — ≥ 0.55 means the `.lua` entry will be active,
  older means `hyprland.conf` will be active.
- If Hyprland isn't installed yet (fresh install), it falls back to a distro
  heuristic: **Ubuntu/Debian** families assume legacy, rolling distros assume
  Lua. (On Ubuntu the deps step may then pull a newer Hyprland from
  `ppa:cppiber/hyprland` — in that case the `.lua` entry simply takes over,
  no reinstall needed since both are always on disk.)
- During `setup install`, it prints which entry is ACTIVE on your machine,
  and on the legacy path it **verifies every legacy file landed** in
  `~/.config/hypr` (missing files are reported instead of failing silently).

Manual override:

```bash
./setup install --hypr-variant auto    # default: detect (above)
./setup install --hypr-variant legacy  # force-report/verify the .conf entry (Ubuntu, old Hyprland)
./setup install --hypr-variant lua     # force the Lua entry
```

Helpers used only by the legacy binds (the Lua file keeps inline
equivalents, because hyprlang would expand bare shell `$vars` at parse time):

- `hyprland/scripts/zoom.sh` — screen zoom ±0.3, clamped to 1.0–3.0
- `hyprland/scripts/test-notify.sh` — SUPER+ALT+F11/F12 test notifications

`hyprland.conf.old` is an obsolete artifact from the upstream Lua migration
and is intentionally left untouched.

## Known legacy limits

Static hyprlang cannot do what the Lua config does at runtime:

- **Workspace groups** (`workspace_in_group`, group size 10) → plain
  `workspace 1..10` / `movetoworkspace 1..10`.
- **Unified multi-monitor workspaces** (`unifiedMultiMonitor` in
  `~/.config/horizons/config.json`) → plain relative workspaces.
- **OCR bind** drops `$SLURP_ARGS` (plain `slurp`).
- The shell's keybind-cheatsheet overlay parses `keybinds.lua`; on legacy
  builds the `# ...` trailing comments in `keybinds.conf` are descriptive only.

If your distro finally ships Hyprland ≥ 0.55, you get the full feature set
with zero changes — the `.lua` files take over automatically.
