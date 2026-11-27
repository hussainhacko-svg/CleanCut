# AGENTS.md — Rules and map for AI agents and contributors

CleanCut is a touch-first video editor built with Flutter, **Android only**.
This file is the single instruction file for every agent (`CLAUDE.md` and
`GEMINI.md` only import it). The owner chose these rules: follow them
strictly, and if one blocks you, stop and ask instead of working around it.

**Read before non-trivial changes:** `docs/PLAN.md` (roadmap, feature map,
approved packages) and `docs/DESIGN.md` (UI spec, how each kit frame was
adapted). §13 below says where work currently stands.

---

## 1. Toolchain

- Flutter is pinned with **FVM** (`.fvmrc` → 3.47.9). Always run
  `fvm flutter …` / `fvm dart …`, never a global `flutter`.
- Target platform: **Android only**. Do not add iOS, web, or desktop folders
  or platform checks for them.
- `minSdk = 29` (Android 10). Do not lower it. Scoped storage only — no
  `READ/WRITE_EXTERNAL_STORAGE`; use the Photo Picker / `READ_MEDIA_*` and
  MediaStore.
- Kotlin + Gradle Kotlin DSL (`*.gradle.kts`) only. JVM target 17.
- Gradle on this machine needs
  `JAVA_HOME="C:/Program Files/Android/Android Studio/jbr"`.

### Commands

| Task | Command |
|---|---|
| Code generation | `fvm dart run build_runner build -d` |
| Pigeon (engine) | `fvm dart run pigeon --input pigeons/engine.dart` |
| Pigeon (picker) | `fvm dart run pigeon --input pigeons/media_picker.dart` |
| Format | `fvm dart format .` |
| Analyze | `fvm flutter analyze` (must be **0** issues) |
| Dart tests | `fvm flutter test` |
| Engine JVM tests | `cd android; .\gradlew.bat :app:testDebugUnitTest` |

## 2. Dependencies — ask first

- **Never add, remove, or upgrade a pub package or Gradle dependency without
  explicit approval from the owner.** Propose it with: name, version, why,
  and alternatives considered.
- Packages pre-approved in `docs/PLAN.md` §4 may be added when their phase
  starts, but still mention them in the commit/PR body.
- Current runtime packages: `flutter_riverpod`, `riverpod_annotation`,
  `freezed_annotation`, `json_annotation`, `go_router`, `flutter_svg`,
  `intl`, `path_provider`, `uuid`.

## 3. Codebase map

```
lib/
  main.dart                     # composition root: overrides cross-feature providers
  app/
    app.dart                    # MaterialApp, theme + l10n wiring
    router.dart                 # go_router routes (AppRoutes)
    licenses.dart               # font licenses registration
    theme/app_theme.dart        # ThemeData built from VCLIP tokens
    l10n/app_en.arb             # ALL user-facing strings (gen/ is generated)
  core/                         # shared, no feature logic
    storage/                    # app_directories, atomic_file
    theme/                      # app_tokens, accent_gradient, timeline_colors
    utils/timecode.dart
    widgets/app_icon.dart       # SVG icon set (assets/icons/*.svg)
  engine/
    media_engine.dart           # Dart wrapper over the native engine
    engine_api.g.dart           # Pigeon output of pigeons/engine.dart
  features/
    media_import/
      domain/media_picker.dart  # MediaPicker interface (pickVisualMedia, pickImage)
      data/platform_media_picker.dart, media_picker_api.g.dart
    projects/
      domain/                   # PURE DART
        model/                  # Project, Clip, tracks, time, canvas, speed_curve,
                                # clip_transform, clip_style, canvas_background,
                                # keyframe, animatable, easing, retiming,
                                # crop_editing, transform_editing
        commands/               # clip_, project_, style_commands (EditCommands)
        history/                # EditCommand + History (undo/redo, coalescing)
        timeline/               # ruler, scale, snapping, reorder, selection
        project_repository.dart # repository interface
      data/
        project_codec.dart      # JSON + schema migrations
        file_project_repository.dart, autosaver.dart
        composition_mapper.dart # Project → engine CompositionSpec
      presentation/
        home_screen.dart, project_card.dart, rename_dialog.dart, aspect_sheet.dart
        project_providers.dart
        project_session.dart    # open project: apply commands, undo/redo, autosave
        project_screen.dart     # editor screen; binds dock tools to panels
        playback/               # playback_controller, preview_widgets
        editor/
          editor_state.dart     # zoom, selection, OpenToolPanel providers
          tool_dock.dart        # DockTool / ToolPanelKind
          timeline/timeline_view.dart
          overlays/             # crop_overlay, transform_gizmo
          panels/               # tool_panel (sheet chrome), panel_widgets (shared
                                # tabs, bubbles, slider rows, swatches, value dialog),
                                # speed_panel, speed_scale, curve_widgets,
                                # crop_panel, transform_panel, ratio_panel
    settings/                   # domain/app_settings, data/file_settings_repository,
                                # presentation/settings_screen + providers
pigeons/                        # bridge definitions (source of truth)
  engine.dart, media_picker.dart
android/app/src/main/kotlin/com/hussainhacko/cleancut/
  MainActivity.kt
  engine/                       # EngineHost, Media3Composer, CompositionPlan,
                                # PreviewPlayer, ClipLook (math), ClipRenderEffect (GL),
                                # Thumbnail*/Waveform*/PeakAccumulator, CacheKeys,
                                # EngineApi.g.kt
  media/                        # MediaPicker.kt, MediaPickerApi.g.kt
android/app/src/test/kotlin/…/engine/   # JVM unit tests
test/                           # mirrors lib/ (core/, features/<f>/{domain,data,presentation})
  helpers/fakes.dart            # fakes (engine, picker, repositories) + TestEnv
assets/icons/                   # kit-style SVGs: dock_*, tool_*, crop_*, lane_*, …
assets/fonts/                   # Plus Jakarta Sans, Bebas Neue (+ OFL licenses)
docs/PLAN.md, docs/DESIGN.md
.github/workflows/ci.yml
```

## 4. Architecture rules

- `domain/` must not import `package:flutter`, Riverpod, or any IO. It must
  be unit-testable with `dart test` semantics.
- Features may depend on `core/` and `engine/`, and on another feature's
  `domain/` only — never another feature's `presentation/` or `data/`. When a
  feature needs another feature's implementation (e.g. the platform media
  picker), it declares a provider typed to that feature's `domain/`
  interface, and `lib/main.dart` overrides it with the implementation.
- The **project model is immutable**. All edits go through `EditCommand`s so
  undo/redo always works. No widget mutates the model directly.
  - One-tap edits (presets, swatches, reset, typed values) pass
    `coalesce: false`; drags coalesce and call `session.seal()` on release.
- Times are integer **microseconds** (`int`) — never `double` seconds or
  `Duration` inside the model.
- The native engine is the **single source of truth for pixels**: preview and
  export use the same Media3 composition. Never re-implement an effect in Dart
  for preview only.
- Flutter ↔ Kotlin uses **Pigeon** only — no hand-written `MethodChannel`
  string APIs. Regenerate (§1) and commit the generated files.

### Domain gotchas

- **Speed:** `Clip.speedCurve` replaces `Clip.speed` while set. Never do
  `clip.speed` arithmetic to map time — use `Clip.timelineLengthOf`,
  `sourceOffsetAt`, `timelineOffsetOf`, `averageSpeed`. Curves are up to 10
  points over source progress (0–1), monotone cubic in log-speed space;
  model and engine both use the same **64 constant-speed steps**. Trim
  stretches a curve; split divides it (each half resampled from the original).
- **Schema:** `Project.currentSchemaVersion` is **3** (v2 speed curves, v3
  crop/border/background/keyframes). Any format change bumps it with a
  migration in `project_codec.dart` and a migration test.
- Minimum clip length is 0.1 s.

## 5. State management — Riverpod 3

- Riverpod 3 with code generation (`@riverpod` / `riverpod_generator`). No
  `setState` beyond purely local, ephemeral widget state.
- One `Notifier`/`AsyncNotifier` per concern, in the feature's
  `presentation/` folder.
- Use `ref.watch` (not `ref.read`) in `build`. Use `select` for
  high-frequency state (playhead position).
- Playback position updates (≥ 30 Hz) must not rebuild the editor — isolate
  them in small widgets.

## 6. Code style

- Lints: `very_good_analysis`; analyze must report **zero** issues. No
  `// ignore:` without a comment explaining why.
- Format before committing; commit generated `*.g.dart` / `*.freezed.dart`.
- Public Dart APIs in `domain/` and `engine/` need doc comments.
- Kotlin: Android Kotlin style; no `!!` without a comment; coroutines, not
  raw threads.

## 7. Testing & CI

- **Every `domain/` change ships with unit tests** (new behavior and edge
  cases: zero-length clips, splits at boundaries, speed ≠ 1, overlapping
  layers).
- Every tool panel / reusable widget gets a **widget test**.
- Serialization changes need a round-trip test; schema changes need a
  migration + migration test.
- Bug fixes start with a failing test that reproduces the bug.
- Native engine: JVM unit tests for pure logic (composition, mapping);
  instrumented tests optional.
- **Before every commit run locally:** build_runner, format, analyze, test,
  and the Gradle JVM tests when Kotlin changed.
- CI (`.github/workflows/ci.yml`) runs **only on version tags (`v*`)** or a
  manual dispatch — it does not check PRs, so the local checks above are the
  gate. A release tag must have a green CI run.

## 8. Git — Conventional Commits

- `feat:`, `fix:`, `refactor:`, `perf:`, `test:`, `docs:`, `build:`, `ci:`,
  `chore:`, optional scope (`feat(timeline): pinch to zoom`).
- Subject ≤ 72 chars, imperative, no trailing period. Body explains *why*.
- Breaking project-file schema changes use `!` (`feat(model)!: …`) and
  describe the migration.
- Never commit secrets, keystores, `key.properties`, or `local.properties`.
- Small, focused commits that keep the build and tests green. Don't refactor
  unrelated code in the same change. The owner decides when to push and
  open PRs.

## 9. UI rules (details in `docs/DESIGN.md`)

- **The VCLIP Figma kit is the visual spec for every screen.** The Figma MCP
  is over its plan limit, so use the exported frames in
  `VCLIP-video editor (Community)/` (git-ignored, local only; one `.jpg` per
  frame: `Speed`, `Crop`, `Ratio`, `Alignment`, `Adjust`, `Icons`, …). Where
  the kit differs from older rules, the kit wins; record each adaptation in
  `docs/DESIGN.md`.
- **Bottom Dock** layout. Breakpoints: compact `< 600dp`, medium
  `600–839dp`, expanded `≥ 840dp` (left tool rail + right properties panel).
- Touch targets **≥ 48×48dp**; primary actions in the bottom thumb zone.
- Material 3 styled with VCLIP tokens, **dark by default**, light in
  settings. Colors only from `ColorScheme` / theme extensions — no
  `Color(0x…)` in widgets.
- Every slider property: drag + tap-to-type + reset-to-default + haptic tick
  at default/snap points. Reuse `panels/panel_widgets.dart`
  (`PanelTabs`, `ValueBubble`, `GradientSliderRow`, `ColorSwatchRow`,
  `showValueDialog`).
- Every destructive or multi-step edit is undoable; no "Are you sure?"
  dialogs for undoable actions.
- The timeline is always **left-to-right**
  (`Directionality(textDirection: TextDirection.ltr)`).

## 10. Internationalization

- No user-facing string literals in widgets: strings go in
  `lib/app/l10n/app_en.arb`, accessed via `AppLocalizations`.
- ICU plurals/placeholders, not concatenation.
- `EdgeInsetsDirectional` / `AlignmentDirectional` so RTL can be added later.

## 11. Performance & media

- Never decode frames or build thumbnails/waveforms on the UI isolate — do it
  natively or in a background isolate, and cache to disk.
- Dispose every controller, subscription, and native handle; release native
  players/textures when the editor closes.
- Export runs in an Android **foreground service** with a progress
  notification.
- Media is referenced by content URI + persisted permission, never copied
  unless the user asks (caches go in the app cache dir).

## 12. Documentation & agent behavior

- Tick `docs/PLAN.md` checkboxes when you finish a plan item; update
  `docs/DESIGN.md` when you change a UI pattern.
- If a requirement is ambiguous (e.g. an effect's exact behavior), ask the
  owner rather than guessing.
- **Multi-agent handoff** (Claude Code and Gemini both work here): leave work
  uncommitted and update §13 with what you did and what's left. The next
  agent reviews it, runs every check, and commits it. Don't redo or undo
  another agent's work without reason; keep §13 short and current.

### Emulator testing (`Medium_Phone_API_37.0`)

- Wake the screen first (`adb shell input keyevent 224`,
  `wm dismiss-keyguard`, `svc power stayon true`) or screenshots are black.
- `uiautomator dump` exposes Flutter semantics labels but fails while video
  plays; delete `/sdcard/ui.xml` first to avoid a stale dump.
- Drive drags/long-presses with `input motionevent DOWN/MOVE/UP` in one
  `adb shell` string, or two-finger gestures with `/system/bin/uinput` JSON
  (virtual multi-touch device, no root required). In Git Bash set
  `MSYS_NO_PATHCONV=1`.
- Test media: `cleancut_test.mp4` (13 s, near-static, sparse keyframes),
  `cleancut_still.png`, and a 2:52 film for visual speed checks.
- The home list is sorted by last edit — re-check which card you open.

---

## 13. Current status (update on every handoff)

| Phase | State | Where |
|---|---|---|
| 0–4 | done | `main` |
| 5 — transform & style | **in review** | `feat/phase-5` (PR open) |

**Phase 5, committed (all on `feat/phase-5`):** schema v3 model (crop,
border, background, keyframes); engine rendering (`ClipLook.kt`,
`ClipRenderEffect.kt`, live look swaps + `experimentalRedrawLastFrame()` in
`PreviewPlayer`); Crop panel + on-preview `CropOverlay`; Transform panel +
`TransformGizmo`; Ratio | Background panel + `MediaPicker.pickImage()`;
keyframe ◇/◆ toggles and timeline diamonds; CI on release tags only.
Emulator-checked by Claude and Gemini (2026-11-27).

**Review fixes (Claude, 2026-11-27, committed; emulator-verified by Gemini, 2026-11-27):** editors read values back
with `ClipTransform.editableAt` (the keyframe within half a frame, the one an
edit updates), so gizmo and ruler drags beside a keyframe no longer cancel
themselves; the gizmo only cancels when a value *it* set changes outside and
otherwise follows the new value (a drag started while playing on an animated
clip keeps going); gizmo and crop handles hide while the playhead is off the
selected clip; a constant rotation is stored within ±180° and a keyframed one
keeps the turn nearest its current value (`wrapDegrees`, `sameAngle`); crop
drags map fingers with the rotation at drag start; the gizmo, crop overlay
and rotation ruler seal their undo step when removed mid-gesture.

**Timeline & kit fixes (Gemini, 2026-11-27; reviewed and committed by Claude):** kept `TimelineView` in the same
widget tree slot across phone panel open/close (`project_screen.dart`) and
synced its initial scroll offset to `playbackPositionProvider` on mount
(`timeline_view.dart`), so opening/closing a tool panel (or switching
phone↔tablet layout) no longer resets the timeline strip to `0s` (covered by
3 widget tests in `editor_test.dart`). Also applied 3 VCLIP Figma parity
tweaks: white left labels on `GradientSliderRow` (`Alignment.jpg`), and bold
white captions on selected Ratio (`Ratio.jpg`) and Crop (`Crop.jpg`) presets.

**Phase 5, remaining:**
1. Physical-device-only check: tactile feel of haptics (emulator has no
   vibration motor).
2. Reset on a keyframed property only resets the playhead's value — owner
   decided to leave it as is.
3. Review and merge the `feat/phase-5` PR.

**Open items:** Phase 2 physical low-end device check (1080p ≥ 30 fps, seek
< 150 ms); audible keep-pitch check; split/delete/speed for overlay and audio
clips come with Phases 7/9; curve editor shrinks the phone timeline to 80 dp;
stills keep an old curve until a Normal speed is set.

### Owner decisions

- **Speed:** kit Speed frame covering 0.1×–10×, labels
  0.1 · 0.25 · 0.5 · 1 · 2 · 5 · 10× evenly spaced. Curve editor is
  CapCut-style (drag points, Add/Delete at playhead). Presets (speed at
  0/25/50/75/100%): Montage 1·2·0.5·2·1, Hero 1·1·0.25·1·1,
  Bullet 2·0.25·0.25·0.25·2, Flash in 5·2·1·1·1, Flash out 1·1·1·2·5,
  Custom flat.
- **Dock:** Duplicate right after Split; Transform right after Crop.
- **Crop:** mirror, flip, rotate live in the Crop panel. Presets: Free, 1:1,
  9:16, 16:9, 3:4, 4:3, 2:1, 4:5.
- **Canvas background** is a tab of the Ratio panel — no new dock item.
- **Resolution** is chosen in the Phase 10 export sheet, not Phase 5.
- Trim = drag the white handles; reorder = long-press + drag.
