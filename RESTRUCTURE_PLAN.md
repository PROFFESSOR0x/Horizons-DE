# End4-PXpC Monorepo Restructuring Plan

Status: draft, awaiting go-ahead per phase.
Scope: merge `dots-hyprland/`, `end4-pC/`, `hyprglass/` into one coherent, closely-linked
monorepo; fix the installer; resolve placeholders; expand Hyprland animations; deepen the
hyprglass↔shell integration.

## Current state (from exploration)

- `G:\End4-PXpC` is already one git repo. `dots-hyprland/` and `end4-pC/` were already
  flattened into it (no nested `.git`). `hyprglass/` is still a separate repo with real
  upstream history (tags, hyprpm commit pins to `hyprnux/hyprglass`).
- `dots-hyprland/dots/.config/quickshell/ii/` is a **stale duplicate** of `end4-pC/` —
  same shell, older snapshot, missing the hyprglass integration. This is the single
  biggest source of confusion and must be resolved first.
- Two load-bearing identity strings coexist: `illogical-impulse` (dots-hyprland's config
  dir, keyring app name, legacy scripts) and `end4-pC` (Quickshell config dir, `qsConfig`
  value). Both are read by live code — can't just rename one.
- `end4-pC/installer.sh` calls `dots-hyprland/install.sh` or `setup.sh`, neither of which
  exist — the real entrypoint is `dots-hyprland/setup install`. This call is broken today.
- `hyprglass/services/Hyprglass.qml`-side integration (in end4-pC) drives the plugin
  purely by rewriting `shellOverrides/*.lua` and calling `hyprctl reload` /
  `hyprctl plugin load` — there is no IPC/socket in the plugin itself, so "closer
  integration" has to mean a richer config-authoring surface in the shell, not a new
  wire protocol (unless we add one to the plugin — see Phase 6).
- `hyprglass.so` (14MB) and `src/*.o` are committed build artifacts.
- Distro detection is duplicated (and slightly divergent) between
  `dots-hyprland/sdata/lib/dist-determine.sh` and `end4-pC/installer.sh:detect_distro()`.

## Phase 0 — Hygiene (low risk, do first)
1. Reconcile dirty working trees in `dots-hyprland/dots/.config/hypr/...` before touching
   structure (diff against `origin/main`, decide keep/discard).
2. `.gitignore` + `git rm --cached` the hyprglass build artifacts (`hyprglass.so`, `src/*.o`).
3. Drop or properly resolve the dead `dots/.config/quickshell/ii/modules/.../shapes`
   submodule reference in `dots-hyprland/.gitmodules`.
4. Decide hyprglass history strategy: `git subtree add` (recommended — keeps upstream
   history pullable, no submodule footgun for contributors) vs submodule vs flatten.
   Recommendation: **subtree**, remap into `shell/plugins/hyprglass/`.

## Phase 1 — Canonical directory layout
Target layout (single source of truth per concern):
```
End4-PXpC/
  installer.sh              # one entrypoint, replaces both installer.sh + setup
  dotfiles/                 # was dots-hyprland/dots — hypr, kitty, fish, etc.
  shell/                    # was end4-pC/ (Quickshell, QML)
    plugins/hyprglass/      # subtree of hyprglass
  install/                  # was dots-hyprland/sdata + end4-pC installer logic, unified
  docs/
```
- Delete `dots-hyprland/dots/.config/quickshell/ii/` entirely once `shell/` is confirmed
  as canonical (it's strictly behind end4-pC and has no unique content per the diff).
- Keep `illogical-impulse` as the on-disk config-dir name where legacy scripts expect it
  (documented, not renamed) — OR do a coordinated rename to `end4-pC` everywhere
  (`Directories.qml:shellConfig`, keyring app name, `~/.config/illogical-impulse` →
  `~/.config/end4-pC`) with a migration shim for existing installs. **This needs a
  decision — see question below.**

## Phase 2 — Installer consolidation
1. Single `install/` tree: merge `dist-determine.sh` + `installer.sh:detect_distro()`
   into one shared `install/lib/distro.sh`.
2. Fix the broken dots-install call: point at `dotfiles`'s real entrypoint
   (`install/setup install`, post-move) instead of the nonexistent `install.sh`/`setup.sh`.
3. Fold `dots-hyprland/setup`'s subcommands (`install-deps`, `install-files`, etc.) and
   `end4-pC/installer.sh`'s steps (`install_qs`, `configure_hyprland`, `configure_keybind`,
   `restart_qs`) into one ordered pipeline with one flag set (`--skip-*`, `--uninstall`,
   `-f/-q`).
4. Add a step that builds `shell/plugins/hyprglass` (`make`, or `hyprpm`) instead of
   relying on a prebuilt `.so`, and update the hardcoded fallback path in
   `services/Hyprglass.qml` to match the new layout.
5. Treat the experimental YAML installer (`3.files-exp.sh`) as out of scope — legacy path
   is what's real; either finish it or delete it, don't carry dead code forward silently.

## Phase 3 — Placeholder / TODO burn-down
Concrete list found (all in `end4-pC/`, now `shell/`):
- `modules/common/models/gCloud/GCloudVisionResult.qml:8` — tune confidence threshold.
- `modules/ii/background/widgets/AbstractBackgroundWidget.qml:77` — arbitrary constants.
- `modules/ii/lock/PasswordChars.qml:55` — proper model for char insertion.
- `modules/ii/regionSelector/RegionSelection.qml:30` — sidebar AI action.
- `modules/ii/screenTranslator/ScreenTextOverlay.qml:24` — missing docs page.
- `services/Network.qml:93` — enterprise wifi (username) support.
- `services/Wallpapers.qml:25` — video wallpaper support.
Each gets its own scoped implementation pass (small, independent, low risk to do in
parallel with the structural work).

## Phase 4 — Hyprland animation pass
- Audit current curves/presets in `shellOverrides/animations.lua` (5 beziers, 1 spring,
  ~9 named animation leaves).
- Build a fuller preset library (snappy / smooth / expressive / reduced-motion) with
  matched bezier+spring pairs per leaf (windows in/out, fade, border, workspaces, layers).
- Extend the shell's animation editor (already exists, generates this file) to expose the
  new presets + a live-preview using `hyprctl reload` diffing, so users A/B without
  restarting.

## Phase 5 — Hyprglass ↔ shell integration
Given the plugin has no IPC beyond Hyprland's own config/dispatch system, "closer
integration" means:
1. Make `HyprglassConfig.qml` settings page cover the full option set from the README
   (it's close already — verify `adaptive_dim`, `adaptive_boost`, `lens_distortion`,
   `vibrancy_darkness` are all exposed).
2. Wire per-window tag controls (`hyprglass_disabled`, `hyprglass_theme_*`,
   `hyprglass_preset_*`) into the shell's window-rule UI instead of requiring manual
   `hyprctl dispatch tagwindow`.
3. Auto dark/light theme sync: shell already tracks system theme — push
   `plugin:hyprglass:default_theme` on theme change instead of requiring manual toggle.
4. Stretch goal (bigger, separate effort): add a minimal IPC/socket to the plugin itself
   (e.g. a unix socket emitting current per-window glass state) so the shell can show
   live glass status instead of only writing config one-way.

## Open questions before implementation starts
1. Identity rename: keep `illogical-impulse` as the legacy config-dir name, or do a
   coordinated rename to `end4-pC` with a migration shim for existing users?
2. hyprglass history: subtree (recommended) vs submodule vs flatten — confirm subtree.
3. Should Phase 3 (TODO burn-down) happen interleaved with the structural moves, or after
   the directory layout is stable (recommended — avoids merge conflicts mid-move)?

## Suggested execution order
Phase 0 → Phase 1 → Phase 2 → Phase 4 → Phase 5 → Phase 3 (can run anytime after Phase 1).
Each phase should land as its own commit (or small set of commits) so it stays reviewable
and revertible.
