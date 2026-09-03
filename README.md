# 💠 آفاق | Horizons

A personal fork of [illogical-impulse](https://github.com/end-4/dots-hyprland) by
[@end-4](https://github.com/end-4), customized and maintained by **pctrade**.

This monorepo combines the three pieces that make up Horizons:

- **`dotfiles/`** — the base Hyprland/kitty/fish/etc. dotfiles (originally `dots-hyprland`).
- **`shell/`** — the Quickshell desktop shell (originally `end4-pC`), including its
  README(s) in [`shell/README.md`](shell/README.md).
- **`shell/plugins/hyprglass/`** — the glass/blur Hyprland plugin (originally the
  standalone `hyprglass` repo by [@hyprnux](https://github.com/hyprnux/hyprglass)).

## Install — Horizons Installer v2.0

```bash
git clone https://github.com/PROFFESSOR0x/end4-pC.git End4-PXpC
cd End4-PXpC
./installer.sh                          # interactive (profile: core)
./installer.sh --profile full --force   # full non-interactive
./installer.sh --dry-run --profile ultra # preview what would be done
```

The unified installer (`installer.sh` + `install/lib/*`) does in order: pre-flight
checks, legacy migration (`illogical-impulse`/`end4-pC` → `horizons`), optional backup,
optional full system upgrade, the `dotfiles/setup install` base, optional quickshell
build from source, `hyprglass` plugin build (`make`), optional bundled extras
(Rubik/Gabarito/Bibata/GoogleSans), the `shell/` Quickshell config into
`~/.config/quickshell/horizons`, Hyprland `qsConfig` set to `horizons`, settings keybind,
Quickshell restart, and finally writes the identity marker.

### Identity marker & update protocol

After a successful install a marker is written (requested feature):

- `~/.config/horizons/.horizons-meta.json` — machine-readable (installer version, dates, git commit, profile, components)
- `~/.config/horizons/.horizons-info`     — simple `key=value` human-readable
- `~/.config/horizons/.horizons-version`  — one-liner `horizons <commit> <date> profile=<p>`

The update protocol reads this marker:

```bash
./installer.sh status          # show identity + repo status
./installer.sh check           # check for updates (git fetch + compare)
./installer.sh update          # pull (stash+rebase) + smart re-apply
./install/horizons-update check
./install/horizons-update full --rebase --smart
./install/horizons-update rollback
./install/horizons-update timer install  # daily systemd timer
# Installed helper after first run:
horizons status
horizons update
```

### Profiles & granular control

| Profile | Dots | Shell | hyprglass | Bundled | Build | SysUpgrade |
|---------|------|-------|-----------|---------|-------|------------|
| `minimal` | ✗ | ✔ | ✗ | ✗ | ✗ | ✗ |
| `core` *(default)* | ✔ | ✔ | ✔ | ✗ | ✗ | ✗ |
| `full` | ✔ | ✔ | ✔ | ✔ | ✗ | ✗ |
| `ultra` | ✔ | ✔ | ✔ | ✔ | ✔ | ✔ |

Granular overrides: `--components <csv>` with `^`/`-`/`no-` negation.

```bash
./installer.sh --profile minimal --force            # shell only
./installer.sh --profile full --with-sysupdate -y   # full + system upgrade
./installer.sh --components dots,shell --force      # only dots + shell
./installer.sh --components no-dots,^bundled -y     # everything except dots/bundled
./installer.sh build --build-force                  # only rebuild plugins/shell
```

### Full flags

Run `./installer.sh --help` for the complete list. Highlights:

- `-f/--force`, `-y/--yes`, `-q/--quiet`, `-v/--verbose`, `--dry-run`
- `--profile minimal|core|full|ultra`, `--components <csv>`, `--show-profiles`
- `--with-deps` / `--skip-deps`, `--with-sysupdate` / `--skip-sysupdate`, `--with-build` / `--skip-build`, `--with-bundled` / `--skip-bundled`, `--with-backup` / `--skip-backup`
- `--via-nix`, `--with-fontset <set>`, `--build-force`, `--log-file <path>`
- Legacy compat: `--skip-dots`, `--skip-qs` still work
- Commands: `install` (default), `update`, `check`, `status`, `build`, `uninstall`

## Credits

- **[@end-4](https://github.com/end-4)** — original [dots-hyprland](https://github.com/end-4/dots-hyprland) / illogical-impulse.
- **[@hyprnux](https://github.com/hyprnux)** — original [hyprglass](https://github.com/hyprnux/hyprglass) plugin.
- **pctrade** — end4-pC fork, now rebranded as آفاق | Horizons.

See [`shell/README.md`](shell/README.md) for shell-specific docs (also available in
[日本語](shell/README.ja.md) and [简体中文](shell/README.zh-CN.md)), and
[`RESTRUCTURE_PLAN.md`](RESTRUCTURE_PLAN.md) for the monorepo restructuring history.
