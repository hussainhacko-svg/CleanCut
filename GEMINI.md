@AGENTS.md

# Handoff note for Gemini

This repo is worked on by two AI agents (Claude Code and Gemini) for the
owner. `AGENTS.md` (imported above) holds the rules; this section says where
things stand so you don't redo or undo work. Keep it current: update it when
you finish a chunk of work, and leave the next agent the same courtesy.

## Status (2026-11-26)

- **Phases 0–3 done.** `main` has Phases 0–2 + the VCLIP restyle (PRs #1–#4).
  Branch `feat/phase-3` has Phase 3 (timeline, contextual dock, tablet
  layout) and two audit-fix commits:
  - `955f9b8` post-Phase-2 audit fixes
  - `61ee62d` your post-Phase-3 audit fixes, reviewed and committed by
    Claude. One change on top of yours: `ClipThumbnails.ensure` now catches
    engine errors and caches the frames as missing (callers don't await it,
    so a rethrow was an unhandled error, and failed frames were re-requested
    on every scroll). Regression test in `audit_playback_test.dart`.
- **Known leftovers (not fixed, low priority):**
  - A save queued *after* a project delete can still recreate its folder
    (`AtomicFile._write` creates the parent dir).
  - Scrolling the lanes vertically moves the ruler but not the playhead line.
  - Phase 2 low-end physical-device spike test is still unchecked.
- **Phase 4 (basic editing): mostly done** on branch `feat/phase-4`
  (branched from `feat/phase-3`; not pushed, no PR yet), by Claude:
  - `bd220a9` domain: `TrimClipCommand`, `SplitClipCommand`,
    `DeleteClipCommand`, `DuplicateClipCommand`, `MoveClipCommand`,
    `SetClipSpeedCommand` (`domain/commands/clip_commands.dart`) +
    keyframe re-timing (`domain/model/retiming.dart`). Min clip 0.1 s.
  - `84f8123` engine: `ClipSpec.speed` / `keepPitch` → Media3
    `EditedMediaItem.setSpeed(SpeedParameters(...))` (constant speed).
  - `4ee9558` editor: Split / Duplicate / Delete in the dock; Speed panel
    (`presentation/editor/panels/`), open state in `OpenToolPanel`.
  - `8ec7ffe` timeline: trim handles (applied on release) and long-press
    reorder.
  - **Emulator-tested 2026-11-26** (`Medium_Phone_API_37.0`): split,
    duplicate, delete, undo/redo, speed panel (tap, type, reset, keep
    pitch, back), speed 0.1x/2x/10x playback (2x verified frame-accurate
    against 1x), trim start/end/minimum, reorder, autosave. Two bugs found
    and fixed: `a528808` (lifted clip lost its gesture: main clips are now
    keyed by id) and `b101acc` (speed bubble too wide).
  - **Still open:** speed curves (follow-up); split/delete/etc. for overlay
    and audio clips (Phases 7/9); audible keep-pitch check (emulator has
    no audio output in testing).
  - **Thumbnails fixed (Phase 2 bug):** tiles used the nearest keyframe
    only, so sparse-keyframe videos (screen recordings) repeated frame 0.
    `ThumbnailTiming` now decodes the exact frame when the closest
    keyframe is > 0.5 s away (looked up via `MediaExtractor` with
    `SEEK_TO_CLOSEST_SYNC`, no decoding); the video thumbnail cache key is
    versioned (`thumb|v2|`) so stale frames aren't reused. Emulator: ~40
    exact tiles in 4-8 s worst case.
  - **Post-Phase-4 audit fixes (by Gemini; reviewed and committed by Claude):**
    fixed short/fast clip trim crash (`clip_commands.dart`), post-trim seek
    ordering & stale-duration clamp (`playback_controller.dart`), mid-trim
    clip removal + wasted `onLongPressCancel` rebuilds (`timeline_view.dart`),
    tablet `SpeedPanel` label overlap + tappable labels (`speed_panel.dart`),
    and `SEEK_TO_CLOSEST_SYNC` fast-path for 1 s GOPs in `ThumbnailExtractor`
    (the `KeyframeIndex.open` move is harmless but wasn't a real leak: `open`
    catches its own errors).

- **Speed curves (Phase 4 Flow) done** on `feat/phase-4` by Claude:
  - Model `SpeedCurve` (`domain/model/speed_curve.dart`): points over the
    clip's source progress, monotone cubic in log-speed, 64 constant-speed
    steps shared by model length and engine playback. Presets per owner.
    Curve stretches on trim, divides on split (halves resampled, <1% length
    drift). Schema v2 (`speedCurve`, no-op migration from v1).
  - Commands: `SetClipSpeedCurveCommand`, `SetClipKeepPitchCommand`; a
    Normal speed (`SetClipSpeedCommand`) replaces a curve. Use
    `Clip.timelineLengthOf / sourceOffsetAt / timelineOffsetOf /
    averageSpeed` instead of `clip.speed` maths anywhere time is mapped.
  - Engine: `ClipSpec.speedSteps` → `ItemSpeedProvider` (Media3).
  - UI: Speed panel "Normal | Curve" tabs, preset tiles, `CurveEditor`
    (`presentation/editor/panels/curve_widgets.dart`).

## Design source

The Figma MCP hit its plan limit. The owner exported the VCLIP kit frames to
`VCLIP-video editor (Community)/` (git-ignored, local only): one `.jpg` per
frame (`Speed.jpg`, `Video.jpg`, `Timeline.jpg`, `Edit.jpg`, `Icons.jpg`, …).
**Stick to these screens** for every UI change; `docs/DESIGN.md` records how
each was adapted.

## Owner decisions for Phase 4 (2026-11-26)

- **Speed panel:** the kit's Speed frame (title, Reset, ✕, value bubble over a
  tick ruler, labels underneath) but covering PLAN's **0.1×–10×** on a log
  scale with labels 0.1× · 0.25× · 0.5× · 1× · 2× · 5× · 10×.
- **Speed curves** (montage/hero/bullet/flash ramps + custom editor) come in a
  **separate follow-up** within Phase 4, as a "Normal | Curve" tab row in the
  same panel. First ship constant speed + a keep-pitch switch.
- **Duplicate** is a clip-dock item **right after Split**, with an icon drawn
  in the kit's line style (marked as redrawn inside the SVG).
- Trim = drag the white handles on the selected clip's edges; reorder =
  long-press + drag; delete/split/duplicate are undoable commands (no
  confirmation dialogs).

## Toolchain reminders

- Always `fvm flutter …` / `fvm dart …`.
- Gradle needs `JAVA_HOME="C:/Program Files/Android/Android Studio/jbr"`.
- Before committing: `fvm dart run build_runner build -d`,
  `fvm dart format .`, `fvm flutter analyze` (0 issues),
  `fvm flutter test`, and `.\gradlew.bat :app:testDebugUnitTest` when Kotlin
  changed.
- Bug fixes start with a failing test; `domain/` changes ship with unit tests.
