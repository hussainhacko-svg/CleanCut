@AGENTS.md

# Handoff note for Gemini

This repo is worked on by two AI agents (Claude Code and Gemini) for the
owner. `AGENTS.md` (imported above) holds the rules; this section says where
things stand so you don't redo or undo work. Keep it current: update it when
you finish a chunk of work, and leave the next agent the same courtesy.

**How we hand off:** leave your work uncommitted with a note in `CLAUDE.md`
(as you did for the post-Phase-3 and post-Phase-4 audits). Claude reviews
it, runs every check, commits it, and trims `CLAUDE.md` back to
`@AGENTS.md`. Claude records its own work here.

## Status (2026-11-26)

| Phase | State | Where |
|---|---|---|
| 0–2 + VCLIP restyle | done | `main` (PRs #1–#4) |
| 3 — editor shell & timeline | done | `feat/phase-3` (pushed, **no PR yet**) |
| 4 — basic editing + speed curves | **done** | `feat/phase-4` (from `feat/phase-3`; **not pushed**) |
| 5 — transform & style | next | — |

Neither branch has a PR yet; the owner decides when to push/open them.

### Phase 3 (`feat/phase-3`)

- Timeline, contextual dock, tablet layout, plus two audit-fix commits:
  `955f9b8` (post-Phase-2) and `61ee62d` (your post-Phase-3 fixes, with one
  addition: `ClipThumbnails.ensure` caches failed frames as missing instead
  of throwing unhandled).

### Phase 4 (`feat/phase-4`), in order

| Commit | What |
|---|---|
| `bd220a9` | Domain: trim, split, delete, duplicate, move, speed commands (`domain/commands/clip_commands.dart`) + keyframe re-timing (`domain/model/retiming.dart`). Min clip 0.1 s. |
| `84f8123` | Engine: constant speed + keep pitch via Media3 `EditedMediaItem.setSpeed(SpeedParameters(...))`. |
| `4ee9558` | Editor: Split / Duplicate / Delete in the dock; Speed panel; open-panel state `OpenToolPanel`. |
| `8ec7ffe` | Timeline: drag handles to trim (applied on release), long-press reorder. |
| `a528808`, `b101acc` | Emulator fixes: lifted clip lost its gesture (main clips keyed by id); speed bubble too wide. |
| `35597b7` | Thumbnails: exact frames when the closest keyframe is > 0.5 s away (`ThumbnailTiming`, `MediaExtractor` index lookup, cache key `thumb\|v2\|`). |
| `7b54097` | Your post-Phase-4 audit fixes (short-clip trim crash, post-trim seek ordering, mid-trim clip removal, tablet label overlap + tappable labels, `SEEK_TO_CLOSEST_SYNC`). Note: the `KeyframeIndex.open` move was harmless, not a real leak — `open` catches its own errors. |
| `22a7450` | **Speed curves model** (schema **v2**, see below). |
| `a42d7fe` | Engine plays curves: `ClipSpec.speedSteps` → `ItemSpeedProvider`. |
| `5f6520d` | UI: "Normal \| Curve" tabs, preset tiles, `CurveEditor`. |
| `3760610` | Emulator fix: curve points drag inside the scrolling panel (eager point recognizer); tapping a point no longer records an empty undo step. |

### Speed curves — how they work (read before touching speed/time code)

- `SpeedCurve` (`domain/model/speed_curve.dart`): up to 10 points of speed
  over the clip's **source progress** (0–1), joined by a monotone cubic in
  log-speed space (smooth, no overshoot). Both the model's length and the
  engine's playback use the same **64 constant-speed steps**, so they agree
  (verified on the emulator: engine duration = model duration).
- `Clip.speedCurve` replaces `Clip.speed` while set. **Never do
  `clip.speed` arithmetic to map time** — use `Clip.timelineLengthOf`,
  `sourceOffsetAt`, `timelineOffsetOf` and `averageSpeed`.
- Commands: `SetClipSpeedCurveCommand` (null removes the curve),
  `SetClipKeepPitchCommand` (keeps the curve), and `SetClipSpeedCommand`
  (a Normal speed replaces a curve).
- Trim stretches the curve; split divides it, each half resampled from the
  original so lengths stay within 1%.
- Project schema is **v2** (`Project.currentSchemaVersion = 2`); the v1→v2
  migration is a no-op (no curve = constant speed). Bump the version with a
  migration + test for any further format change.

### Tested on the emulator (`Medium_Phone_API_37.0`)

Split, duplicate, delete, undo/redo, Speed panel (tap, type, reset, keep
pitch, back), 0.1×/2×/10× playback (2× frame-checked against 1×), trim
start/end/minimum, reorder, autosave across restarts, thumbnails, curve
presets, curve editing and playback, v1→v2 migration of existing projects.

### Open items

- Phase 2 low-end **physical** device check (1080p ≥ 30 fps, seek < 150 ms).
- Audible keep-pitch check (emulator audio not verified).
- Split/delete/speed for overlay and audio clips arrive with Phases 7/9;
  the dock says "coming in a later update" for them.
- Low priority: a save queued *after* a project delete can recreate its
  folder (`AtomicFile._write` creates the parent); vertical lane scroll
  moves the ruler but not the playhead line.
- With the curve editor open, the phone timeline shrinks to its 80 dp
  minimum; owner may want a shorter graph.

## Design source

The Figma MCP hit its plan limit. The owner exported the VCLIP kit frames to
`VCLIP-video editor (Community)/` (git-ignored, local only): one `.jpg` per
frame (`Speed.jpg`, `Video.jpg`, `Timeline.jpg`, `Filters.jpg`, `Crop.jpg`,
`Adjust.jpg`, `Ratio.jpg`, `Icons.jpg`, …). **Stick to these screens** for
every UI change; `docs/DESIGN.md` records how each was adapted. For Phase 5
start from `Crop.jpg`, `Ratio.jpg`, `Alignment.jpg` and `Adjust.jpg`.

## Owner decisions (2026-11-26)

- **Speed panel:** the kit's Speed frame but covering **0.1×–10×**, labels
  0.1× · 0.25× · 0.5× · 1× · 2× · 5× · 10× at even distances.
- **Duplicate** is a clip-dock item right after Split (icon drawn in the
  kit's line style, marked in the SVG).
- **Curve presets** (speed at 0/25/50/75/100%): Montage 1·2·0.5·2·1,
  Hero 1·1·0.25·1·1, Bullet 2·0.25·0.25·0.25·2, Flash in 5·2·1·1·1,
  Flash out 1·1·1·2·5, Custom flat.
- **Curve editor:** CapCut-style — drag points, Add/Delete point at the
  playhead.
- **Curves follow the clip:** trim stretches, split divides.
- Trim = drag the white handles; reorder = long-press + drag; all edits
  undoable, no confirmation dialogs.

## Emulator testing tips

- Wake the screen first (`adb shell input keyevent 224`,
  `wm dismiss-keyguard`, `svc power stayon true`) or screenshots are black.
- `uiautomator dump` exposes Flutter semantics labels (good for finding
  controls) but fails while a video plays; delete `/sdcard/ui.xml` first or
  you'll read a stale dump.
- Drive drags and long-presses with `input motionevent DOWN/MOVE/UP` in one
  `adb shell` string. In Git Bash set `MSYS_NO_PATHCONV=1`.
- Test media on the emulator: `cleancut_test.mp4` (13 s screen recording,
  nearly static, sparse keyframes), `cleancut_still.png`, and a 2:52 film
  (good for visual speed checks).
- The home list is sorted by last edit — re-check which card you open.

## Toolchain reminders

- Always `fvm flutter …` / `fvm dart …`.
- Gradle needs `JAVA_HOME="C:/Program Files/Android/Android Studio/jbr"`.
- Before committing: `fvm dart run build_runner build -d`,
  `fvm dart format .`, `fvm flutter analyze` (0 issues),
  `fvm flutter test`, and `.\gradlew.bat :app:testDebugUnitTest` when Kotlin
  changed. Regenerate Pigeon with `fvm dart run pigeon --input pigeons/engine.dart`.
- Bug fixes start with a failing test; `domain/` changes ship with unit tests.
