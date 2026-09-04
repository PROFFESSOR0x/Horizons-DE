# End4-PXpC Monorepo Restructuring Plan

Status: Phase 0 + Phase 1 (structural move and identity rebrand) and Phase 2
(installer consolidation) are done. Phases 3-6 are still draft/未着手.

## Phase 1 (identity rebrand) + Phase 2 (installer) — done

Decisions that were locked in and applied (superseding the "open question" below):
- Display name everywhere user-facing: **آفاق | Horizons**.
- Technical slug for paths/identifiers: **`horizons`** — replacing both
  `illogical-impulse` and `end4-pC`/`ii`. New canonical paths:
  `~/.config/horizons/` and `~/.config/quickshell/horizons/`; `qsConfig` value
  `"horizons"`.
- A migration shim (copy, not move) from the old paths to the new ones lives in
  the new root `installer.sh` (`migrate_legacy_configs()`), and
  `shell/scripts/keyring/try_lookup.sh` falls back to the old `illogical-impulse`
  secret-service application name so existing stored secrets aren't lost.
- Installer consolidated per Phase 2: `install/lib/distro.sh` (merged distro
  detection) + root `installer.sh` (replaces `shell/installer.sh`), correctly
  calling `dotfiles/setup install` (the old call to nonexistent
  `dots-hyprland/install.sh`/`setup.sh` is fixed), building `shell/plugins/hyprglass`
  from source via `make`, and installing `shell/` into
  `~/.config/quickshell/horizons/`.

Deviations from the plan as originally written:
- The plan's target layout showed `install/` as "was dots-hyprland/sdata +
  end4-pC installer logic, unified" — in practice `dotfiles/sdata` remains where
  it is (it's `dotfiles/setup`'s own implementation detail) and `install/` only
  holds the *shared* piece both installers needed (`install/lib/distro.sh`).
  Duplicating/moving all of `sdata` into `install/` would have meant rewriting
  `dotfiles/setup` itself, which was out of scope for this pass.
- Left un-renamed, deliberately: real upstream AUR/ebuild package names under
  `dotfiles/sdata/dist-arch/` and `dotfiles/sdata/dist-gentoo/`
  (`illogical-impulse-*`) and `dotfiles/sdata/deps-info.md` documenting them —
  these are literal external package identifiers the installer invokes via
  pacman/yay/emerge; renaming them would break dependency installation. Also
  left the installed icon filename and the `illogical-impulse-<font>` fonts
  directory prefix in `dotfiles/sdata/subcmd-install/3.files*.sh` — cosmetic
  local asset naming, tangential to the actual identity strings.
- `dotfiles/sdata/subcmd-install/3.files-exp.sh` (experimental YAML installer)
  was left untouched and is never called by the new root `installer.sh`, per
  the plan.
- The outer repo directory name `End4-PXpC` and the GitHub remote
  (`github.com/PROFFESSOR0x/end4-pC`) were not renamed — out of scope, and the
  self-update flow in `shell/modules/ii/settings/pages/About.qml` was pointed
  at the real remote (it previously pointed at a stale/nonexistent
  `github.com/pctrade/end4-pC`).

---

Status (original): draft, awaiting go-ahead per phase.
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

## Phase 5 — Hyprglass ↔ shell integration — done

Given the plugin has no IPC beyond Hyprland's own config/dispatch system, "closer
integration" meant deepening the config-authoring surface, not a new wire protocol.

**Critical fix found and applied first:** `Hyprglass.qml`, `HyprglassConfig.qml`, and
`Appearance.qml` all read/wrote `Config.options.hyprglass`, but the actual schema in
`Config.qml` nests `hyprglass` inside `appearance`
(`Config.options.appearance.hyprglass`) — the same place `appearance.glass` lives.
This meant `page.h` was always `undefined`, every settings control was disabled,
`Hyprglass.apply()` returned early on every call, and Appearance's
`hyprglassEnabled`/`hyprglassTheme`/`hyprglassPreset`/`hyprglassOpacity` mirrors always
fell back to their hardcoded defaults — i.e. the entire hyprglass↔shell integration was
silently inert before this pass. Fixed by correcting the path in all three files.

1. **Full option-set coverage** — audited `HyprglassConfig.qml` against the README's
   option set; `adaptive_dim`, `adaptive_boost`, `lens_distortion`, `vibrancy_darkness`,
   `blur_iterations`, `edge_thickness`, and the layer-surface whitelist/blacklist/preset/
   per-namespace fields were already present (once the path bug above was fixed, they
   actually work). Added the one real gap: a **Custom Presets** editor (add/remove
   `hg.preset()` entries with name + optional `inherits` from a built-in) plus a
   free-text "Default preset" field so a custom preset name can be set as the global
   default, not just the 4 built-ins the quick-select buttons cover.
2. **Per-window tag controls** — extended the existing "Window Rules (Structured)"
   section in `HyprlandConfig.qml` with a glass-tag picker (disable / force-enable /
   force dark theme / force light theme / custom preset name) that writes the
   `tag = "+hyprglass_..."` clause onto the rule's `hl.window_rule()` line, so
   `hyprctl dispatch tagwindow` no longer needs to be hand-typed.
3. **Auto dark/light theme sync** — new opt-in `appearance.hyprglass.autoThemeSync`
   option (default off). When enabled, `Hyprglass.syncThemeFromSystem()` pushes
   `plugin:hyprglass:default_theme` whenever the shell's own system theme
   (`Appearance.m3colors.darkmode`, set by `MaterialThemeLoader.qml`) flips, and once
   at startup; the manual "Default theme" selector is disabled while auto-sync is on.
   Purely additive — off by default, never overrides a manual choice unless the user
   turns the toggle on.
4. **Stretch goal (plugin IPC for live glass status) — deferred, not attempted.**
   No Linux/Hyprland build environment was available in this pass to compile or test a
   `hyprglass/src/*.cpp` change, and a incorrect `HyprlandAPI::` addition risks
   destabilizing a real compositor plugin. Recommendation for a future pass: a small
   unix socket in `GlassRenderer.cpp`/`main.cpp` that periodically writes current
   per-window glass state (enabled/theme/preset per window address) as newline-delimited
   JSON, polled from `Hyprglass.qml` via a `Socket`/`Process` — additive, and it should
   ship behind its own plugin-config toggle (e.g. `status_socket_enabled`, default off)
   so it can't regress anyone not using it.

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

## Phase 6 — hyprglass removed, replaced with native Hyprland blur variants (2026-09-04)

hyprwm/Hyprland merged native blur variants
([#15661](https://github.com/hyprwm/Hyprland/pull/15661), 2026-08-22):
`decoration:blur:variant` (`kawase|frost|ripple|drops|water|fluid_jar|prism|
heat_shimmer|acrylic|aurora|haze`) plus `decoration:blur:acrylic:*` /
`decoration:blur:glass:*` params — `acrylic` is Hyprland's own Liquid-Glass-style
effect. This made the vendored `shell/plugins/hyprglass` plugin (Phase 5) redundant, so
it was removed entirely: the plugin source, `services/Hyprglass.qml`,
`settings/pages/HyprglassConfig.qml`, `appearance.hyprglass` config schema, the
installer's `hyprglass` component (build step, profile flag, `hyprpm`/manual-load
fallback), and all settings-page wiring (including the per-window "glass tag" picker in
Window Rules, since native blur is a purely compositor-side toggle with no per-window
tag protocol).

"Liquid Glass" is now just `hyprland.decoration.blur.enabled=true` +
`hyprland.decoration.blur.variant="acrylic"` — folded into the existing blur/
transparency exclusivity model (`Config.applyVisualEffectExclusivity()`) instead of
being a separate plugin-backed mode. A new "Blur Style" control (Settings > Hyprland)
exposes all 11 native variants, with acrylic/glass param sliders shown when relevant.

Also fixed: `dotfiles/dots/.config/hypr/hyprland/rules.lua` had a blanket
`hl.window_rule({match={class=".*"}, no_blur=true})` disabling Hyprland's compositor
blur for every regular application window — only shell panels and a few system layer
surfaces had `layer_rule`s opting back in. This is why blur/glass only ever reached the
shell's own panels, independent of the plugin question. Removed, so whichever blur
variant is active applies to any window Hyprland would otherwise blur.
