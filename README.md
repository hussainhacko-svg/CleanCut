# CleanCut

A touch-first video editor for **Android** phones and tablets, built with Flutter and a native AndroidX Media3 engine. Preview and export share one Media3 composition, so what you see is what you export.

> **Status:** Phases 0–4 done — project management, the native preview engine, the timeline editor and basic editing including speed curves. **Next: Phase 5 — transform & style.** Roadmap: [`docs/PLAN.md`](docs/PLAN.md).

## What works today

**Projects**
- Create a project from videos and photos (system Photo Picker), pick a canvas size, rename, duplicate, delete with undo.
- Autosave to versioned project files (schema v2, with migrations).

**Editor**
- Live preview from the native Media3 engine, play/pause, frame-accurate scrubbing and full-screen playback.
- Timeline with ruler, fixed centre playhead, pinch zoom, magnetic snapping with haptics, thumbnail strips, waveforms and lanes for effects, text, overlays and audio.
- Phone layout with a bottom tool dock, tablet layout (≥ 840dp) with a tool rail and properties panel.
- Undo/redo for every edit.

**Basic editing**
- Trim (drag the clip's edge handles), split at the playhead, duplicate, delete, reorder (long-press and drag).
- **Flow (speed):** constant speed 0.1×–10× with keep pitch, and speed curves — Montage, Hero, Bullet, Flash in, Flash out, or a custom curve with draggable points.

## Coming next

Crop · Rotate · Position · Size · Mirror · Flip · Fill modes · Background · Border · Opacity · Filters & adjustments · Blur · Masks · Transitions · Photo motion (Ken Burns) · Text styles & motion · Audio tracks & voiceover · Export to 720p/1080p/4K

## Architecture in brief

- **Flutter (Dart):** feature-first layers (`domain` / `data` / `presentation`), Riverpod 3 with code generation, an immutable project model where every change is an undoable `EditCommand`. Times are integer microseconds.
- **Native engine (Kotlin):** AndroidX Media3 `CompositionPlayer` renders the preview into a Flutter texture; thumbnails and waveforms are extracted natively and cached on disk.
- **Bridge:** typed [Pigeon](https://pub.dev/packages/pigeon) APIs (`pigeons/`), no hand-written channels.

```
lib/
  app/        app shell, router, theme, l10n
  core/       shared widgets, theme tokens, utilities
  engine/     Dart side of the native engine bridge
  features/   media_import, projects (home + editor), settings
android/app/src/main/kotlin/…/engine/   Media3 composition, preview, thumbnails, waveforms
pigeons/      bridge definitions (source of truth)
docs/         PLAN.md (roadmap & architecture), DESIGN.md (UI spec)
```

## Development

Requires [FVM](https://fvm.app), the Android SDK (minSdk 29) and JDK 17 (Android Studio's bundled JBR works).

```sh
fvm install                              # Flutter 3.47.9 from .fvmrc
fvm flutter pub get
fvm dart run build_runner build -d       # Riverpod / freezed / JSON codegen
fvm flutter run                          # on an Android device or emulator
```

Before committing (CI runs the same checks):

```sh
fvm dart format .
fvm flutter analyze                      # must report 0 issues
fvm flutter test
cd android && ./gradlew :app:testDebugUnitTest   # engine unit tests (when Kotlin changed)
```

After editing a file in `pigeons/`, regenerate the bridge with `fvm dart run pigeon --input pigeons/engine.dart`.

## Docs

- [`AGENTS.md`](AGENTS.md) — rules for contributors and AI agents (toolchain, architecture, testing, commits)
- [`docs/PLAN.md`](docs/PLAN.md) — architecture and phase-by-phase roadmap
- [`docs/DESIGN.md`](docs/DESIGN.md) — UI spec: layouts, panels, timeline, gestures, visual tokens
