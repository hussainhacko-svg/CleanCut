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
  - **Pre-existing (Phase 2), not fixed:** timeline thumbnails use
    `OPTION_CLOSEST_SYNC` (`ThumbnailExtractor.kt`), so videos with sparse
    keyframes (e.g. screen recordings) show the same frame in every tile.

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
