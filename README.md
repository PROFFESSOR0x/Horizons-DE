# 💠 آفاق | Horizons

A personal fork of [illogical-impulse](https://github.com/end-4/dots-hyprland) by
[@end-4](https://github.com/end-4), customized and maintained by **pctrade**.

This monorepo combines the three pieces that make up Horizons:

- **`dotfiles/`** — the base Hyprland/kitty/fish/etc. dotfiles (originally `dots-hyprland`).
- **`shell/`** — the Quickshell desktop shell (originally `end4-pC`), including its
  README(s) in [`shell/README.md`](shell/README.md).
- **`shell/plugins/hyprglass/`** — the glass/blur Hyprland plugin (originally the
  standalone `hyprglass` repo by [@hyprnux](https://github.com/hyprnux/hyprglass)).

## Install

```bash
git clone https://github.com/PROFFESSOR0x/end4-pC.git End4-PXpC
cd End4-PXpC
./installer.sh
```

This single script (see [`installer.sh`](installer.sh)) runs, in order: pre-flight
checks, a migration shim for existing `illogical-impulse` / `end4-pC` installs, an
optional backup, the `dotfiles/setup install` base installer, a `hyprglass` plugin
build, the `shell/` Quickshell config install into `~/.config/quickshell/horizons`,
Hyprland `qsConfig` configuration, the settings keybind, and a Quickshell restart.

Flags: `-f/--force`, `-q/--quiet`, `--skip-deps`, `--skip-dots`, `--skip-qs`,
`--skip-backup`, `--uninstall`. Run `./installer.sh --help` for details.

## Credits

- **[@end-4](https://github.com/end-4)** — original [dots-hyprland](https://github.com/end-4/dots-hyprland) / illogical-impulse.
- **[@hyprnux](https://github.com/hyprnux)** — original [hyprglass](https://github.com/hyprnux/hyprglass) plugin.
- **pctrade** — end4-pC fork, now rebranded as آفاق | Horizons.

See [`shell/README.md`](shell/README.md) for shell-specific docs (also available in
[日本語](shell/README.ja.md) and [简体中文](shell/README.zh-CN.md)), and
[`RESTRUCTURE_PLAN.md`](RESTRUCTURE_PLAN.md) for the monorepo restructuring history.
