# CleanCut — Implementation Plan

Touch-first video editor for Android phones and tablets, built with Flutter (UI) and a native Kotlin engine on AndroidX Media3 (preview + export).

**Key decisions**

| Area | Decision |
|---|---|
| Platform | Android only, minSdk 29 (Android 10) |
| UI | Flutter 3.47.9 (FVM), Material 3, dark only (owner decision) |
| Layout | Bottom Dock (phone) / Tool rail + Properties panel (tablet) — see `DESIGN.md` |
| Engine | Kotlin, AndroidX Media3 `CompositionPlayer` (preview) + `Transformer` (export), OpenGL ES effects |
| Bridge | Pigeon (typed), preview rendered into a Flutter `Texture` via `SurfaceProducer` |
| State | Riverpod 3 + code generation |
| Architecture | Feature-first layers (`domain` / `data` / `presentation`) |
| i18n | English only, ARB-based (ready for more locales) |
| Quality | very_good_analysis, strict tests, GitHub Actions CI |

---

## 1. Feature → implementation map

| Feature | Model (Dart `domain`) | Engine (Kotlin / Media3) |
|---|---|---|
| **Trimming** | `Clip.sourceIn/sourceOut` (µs) | `MediaItem.ClippingConfiguration` |
| **Split** | `SplitClipCommand` → two clips sharing source, adjusted in/out; keyframes partitioned | — (model only) |
| **Flow** (speed) | `Clip.speed` (0.1×–10×) + optional `SpeedCurve` (keyframed ramp presets: montage, hero, bullet, flash in/out) + `keepPitch` | `SpeedChangeEffect` / custom `SpeedProvider`; audio `SonicAudioProcessor` |
| **Filters** | `FilterRef(id, intensity)` + `Adjustments` (brightness, contrast, saturation, exposure, warmth, tint, highlights, shadows, vignette, sharpen) | `SingleColorLut` from bundled `.cube` LUTs, `RgbMatrix`/`Contrast`/`HslAdjustment`, custom `GlShaderProgram` for the rest |
| **Crop** | `CropRect` (normalized 0–1) + aspect presets (free, 1:1, 4:5, 9:16, 16:9, 3:4…) | `Crop` effect |
| **Rotate** | `Transform.rotation` (deg, keyframable) + 90° quick-rotate | `ScaleAndRotateTransformation` / `MatrixTransformation` |
| **Position** | `Transform.offset` (canvas-normalized, keyframable) | `MatrixTransformation` / `OverlaySettings` per layer |
| **Size** | `Transform.scale` (keyframable) | same |
| **Mirror / Flip** | `Transform.flipX / flipY` | scale −1 on X / Y |
| **Fill** | `FitMode` = fit / fill / stretch / custom | `Presentation` + matrix |
| **Background (bg)** | `Canvas.background` = color / gradient / blurred-source / image | Bottom layer in compositor; blur via `GaussianBlur` on a duplicated source |
| **Border** | `Border(width, color, radius)` | Custom GL shader (rounded-rect SDF stroke) |
| **Blur** | `Blur(sigma)` (whole clip) + blur inside masks | `GaussianBlur` / custom separable shader |
| **Opacity** | `Transform.opacity` (keyframable) | `AlphaScale` / `OverlaySettings.alphaScale` |
| **Mask** | `Mask(shape: linear/mirror/circle/rect/heart/star, center, size, rotation, feather, invert)` | Custom GL shader (SDF masks with feather) |
| **Adding audio** | `AudioTrack` → `AudioClip(volume, fadeIn, fadeOut, speed)`; extract audio from video; per-clip mute | Extra `EditedMediaItemSequence` (audio only), `VolumeAudioProcessor`/custom gain envelope |
| **Adding photo** | `ImageClip(duration)` on main or overlay track | `MediaItem` image + `setImageDurationMs` / frame rate |
| **Photo motion** | `MotionPreset` (Ken Burns zoom in/out, pan L/R/U/D, rotate drift) → generates `Transform` keyframes | Time-varying `MatrixTransformation` |
| **Text motion** | `TextAnimation(in, out, loop)` presets: fade, typewriter, slide, pop, bounce, wave, blur-in; duration per phase | `OverlayEffect` with a time-varying `TextureOverlay`; text rasterized via `Canvas`/`StaticLayout` per frame, cached |
| **Text styles** | `TextStyleSpec(font, size, color, gradient, stroke, shadow, background box + radius, letter/line spacing, alignment, bold/italic/underline)` + saved style presets | Android `StaticLayout` + `Paint` rendering to bitmap |

> **"Flow"** = playback speed + speed ramps (confirmed by owner).

Cross-cutting: **keyframes** — every animatable property (`position`, `scale`, `rotation`, `opacity`, `blur`, mask params) is `Animatable<T>` = constant or `List<Keyframe<T>>` with easing (linear, ease-in/out, cubic-bezier).

---

## 2. Architecture

```
┌──────────────────────── Flutter (Dart) ────────────────────────┐
│ presentation: Editor screen, Timeline, Tool panels, Gizmos     │
│        │ Riverpod (ProjectNotifier, PlaybackNotifier, ...)     │
│ domain: Project ─ Tracks ─ Clips ─ Effects ─ Keyframes         │
│         EditCommand + History (undo/redo)                      │
│ data:   ProjectRepository (JSON + schemaVersion), MediaLibrary │
│ engine: EngineApi (Pigeon) ── project → CompositionSpec DTO    │
└───────────────────────────────┬────────────────────────────────┘
                     Pigeon      │   Texture id / events
┌────────────────────── Kotlin (Android) ────────────────────────┐
│ EngineHostApi: load(spec), play/pause/seek, updateSpec(diff),  │
│                thumbnails(uri, times), waveform(uri), export() │
│ CompositionBuilder: spec → Media3 Composition (sequences,      │
│                     EditedMediaItems, effects, overlays)       │
│ Effects: LUT, Adjust, Border, Mask, Blur, Text/Bitmap overlays │
│ CompositionPlayer → SurfaceProducer → Flutter Texture          │
│ ExportService (foreground) → Transformer → MediaStore          │
└────────────────────────────────────────────────────────────────┘
```

**Domain model (sketch)**

```dart
Project { id, name, schemaVersion, canvas: Canvas(aspect, resolution, fps, background),
          mainTrack: VideoTrack, overlayTracks: [OverlayTrack], textTracks: [TextTrack],
          audioTracks: [AudioTrack], createdAt, updatedAt }
Clip    { id, source: MediaRef(uri, kind, durationUs, size, rotation),
          timelineStartUs, sourceInUs, sourceOutUs, speed, speedCurve?,
          transform: Transform, crop, fitMode, filter, adjustments, blur, border,
          mask?, volume, muted, motionPreset? }
TextClip{ id, text, style: TextStyleSpec, animation: TextAnimation, transform, startUs, durationUs }
```

**Edit flow:** gesture → `EditCommand` → `History.apply` → new immutable `Project` → diff → `engine.updateSpec` (debounced ~16ms while dragging; full reload only when track structure changes).

**Preview vs. interaction:** transform gizmos (handles, snapping guides) are drawn in Flutter over the texture; the pixels underneath come from the native engine, so what you see is what you export.

---

## 3. Project structure

```
lib/
  main.dart
  app/            app.dart, router.dart, theme/, l10n/
  core/           widgets/, utils/, errors/
  engine/         engine_api.dart (generated), engine_client.dart, spec_mapper.dart
  features/
    projects/     home screen, project list, create/duplicate/delete,
                  and (owner decision) the editor: presentation/editor/, playback/
    media_import/ photo picker, media metadata
    editor/       editor shell, bottom dock, responsive scaffold
    timeline/     tracks, clips, ruler, playhead, zoom, thumbnails, waveforms
    playback/     preview texture, transport controls
    edit/         trim, split, speed, delete, duplicate, reorder
    transform/    crop, rotate, position, size, mirror, flip, fill
    style/        background, border, opacity, blur, mask
    filters/      filter presets, adjustments
    text/         text clips, styles, motion
    audio/        audio tracks, volume, fades, extract
    export/       export settings, progress, share
    settings/     about / licenses (later: defaults)
pigeons/engine.dart
android/app/src/main/kotlin/com/hussainhacko/cleancut/engine/...
test/             mirrors lib/
```

---

## 4. Dependencies (pre-approved when their phase starts)

| Package | Purpose | Phase |
|---|---|---|
| `flutter_riverpod`, `riverpod_annotation`, `riverpod_generator`, `build_runner` | State | 1 |
| `freezed`, `freezed_annotation`, `json_serializable`, `json_annotation` | Immutable model + JSON | 1 |
| `go_router` | Navigation | 1 |
| `flutter_localizations` (SDK), `intl` | i18n | 1 |
| `path_provider`, `uuid` | Storage, ids | 1 |
| `very_good_analysis` | Lints | 0 |
| `pigeon` (dev) | Bridge codegen (used from Phase 1 for the media picker, owner-approved) | 1 |
| `mocktail` (dev) | Tests | 1 |
| Gradle: `androidx.media3:media3-transformer`, `-effect`, `-common`, `-exoplayer` (+ `CompositionPlayer`) | Engine | 2 |
| Gradle: `kotlinx-coroutines-android` | Engine | 2 |
| `flutter_svg` | VCLIP kit icons (owner-approved) | 2 |
| Gradle (test): `junit:junit` | Engine JVM unit tests (owner-approved) | 2 |

Anything not listed requires owner approval (see AGENTS.md §2).

---

## 5. Roadmap

Each phase ends with a working, tested build and a tag `v0.<phase>.0`.

### Phase 0 — Foundation ✅
- [x] Flutter project (Android only), FVM pin, minSdk 29, package `com.hussainhacko.cleancut`
- [x] AGENTS.md, PLAN.md, DESIGN.md
- [x] very_good_analysis, CI (analyze + test)
- [x] GitHub repository

### Phase 1 — App shell & project model ✅
- [x] Add Phase-1 deps; theme (dark/light M3), l10n wiring, go_router
- [x] Domain: `Project`, tracks, clips, `Animatable`, `Keyframe`, time utils (µs)
- [x] `EditCommand` + `History` (undo/redo, coalescing for drags)
- [x] `ProjectRepository` (JSON files in app docs dir, schemaVersion, autosave)
- [x] Home screen: project grid, new project (pick media via Photo Picker, choose aspect), rename/duplicate/delete
- [x] Tests: model invariants, commands, serialization round-trip
- [x] Restyle to the VCLIP Figma kit (theme tokens, Plus Jakarta Sans / Bebas Neue, home list + New project tile, panel-style canvas picker)

### Phase 2 — Native engine spike (highest risk — do early)
- [x] Pigeon `EngineHostApi` / `EngineFlutterApi` (events: position, state, errors)
- [x] `CompositionPlayer` rendering to `SurfaceProducer` → Flutter `Texture`
- [x] Load a 1-clip spec; play/pause/seek; frame-accurate scrubbing (main track with videos + stills; VCLIP editor top + full-screen scrubber)
- [x] Thumbnail extraction (`MediaMetadataRetriever` / frame extractor) + disk cache
- [x] Waveform extraction (decode → peaks) + cache
- [ ] Spike test on a low-end device (target: 1080p preview ≥ 30fps, seek < 150ms) — verified on the emulator only; needs a real low-end phone

### Phase 3 — Editor shell & timeline
- [x] Responsive editor scaffold (Bottom Dock / Rail + Panel) — see DESIGN.md
- [x] Timeline: ruler, playhead fixed center, horizontal scroll = scrub, pinch zoom
- [x] Clip thumbnails strip, overlay/text/audio lanes, selection, magnetic snapping + haptics (the text lane renders once Phase 8 adds text clips to the model)
- [x] Transport bar, full-screen preview, undo/redo buttons
- [x] Contextual dock: no selection → add tools; selection → clip tools (⊕ appends media; tools of later phases say "coming in a later update")

### Phase 4 — Basic editing
- [x] Trim (drag handles on clip edges; the length updates live, the preview shows the trimmed edge's frame on release)
- [x] Split at playhead, delete, duplicate, reorder (long-press drag)
- [x] Flow: speed panel (0.1×–10×, kit "Speed" frame) + keep pitch — constant speed via Media3 `SpeedParameters`
- [x] Flow: curve presets (montage, hero, bullet, flash in/out) + custom curve editor ("Normal | Curve" tabs in the Speed panel); engine plays curves as 64 constant-speed steps
- [ ] Freeze frame, reverse (stretch goal)

### Phase 5 — Transform & style
- [x] Canvas aspect ratio (resolution moves to the Phase 10 export sheet)
- [x] Crop with aspect presets and on-preview handles
- [x] Rotate (gizmo + 90° quick buttons), position, size (two-finger on preview), mirror, flip
- [x] Fill modes (fit / fill / stretch)
- [x] Background: color, gradient, blurred source, image
- [x] Border (width, color, corner radius), opacity
- [x] Keyframe button on each animatable property + keyframe markers on clip

### Phase 6 — Filters & effects
- [ ] Filter presets from bundled LUTs with intensity + preview thumbnails
- [ ] Adjustments panel
- [ ] Blur (whole clip)
- [ ] Mask: linear, mirror, circle, rect, heart, star — on-preview handles, feather, invert
- [ ] Transitions between main-track clips (VCLIP ⧓ marker on each boundary; owner-added). Give the marker a real tap target without stealing taps from short clips

### Phase 7 — Photos & layers
- [ ] Image clips on main track (default 3s) and overlay tracks (PiP)
- [ ] Overlay video layers with blend opacity
- [ ] Photo motion presets (Ken Burns) generating editable keyframes

### Phase 8 — Text
- [ ] Text clips on text lane; on-preview editing, drag/scale/rotate
- [ ] Styles: bundled fonts (OFL), color/gradient, stroke, shadow, background box, spacing, alignment; save presets
- [ ] Text motion: in / out / loop animation presets with durations

### Phase 9 — Audio
- [ ] Add audio from device (Photo Picker audio / SAF), extract audio from video
- [ ] Audio lanes with waveforms, trim/split/move
- [ ] Volume (clip + keyframes), fade in/out, mute original video audio
- [ ] Voiceover recording from the dock's "Voice" tool (`RECORD_AUDIO` runtime permission; owner-added)

### Phase 10 — Export
- [ ] Export sheet: resolution (720p/1080p/4K if supported), fps (24/30/60), quality/bitrate, estimated size
- [ ] Foreground service, progress notification, cancel
- [ ] Save to MediaStore `Movies/CleanCut`, share sheet
- [ ] Hardware capability checks (`MediaCodecList`), fallback encoder settings

### Phase 11 — Polish & release
- [ ] Performance pass (proxy media for 4K sources, memory budgets)
- [ ] Accessibility (TalkBack labels, contrast, large text in panels)
- [ ] Onboarding tips, empty states, error reporting
- [ ] Release signing, R8, Play Store listing assets, privacy policy

---

## 6. Testing strategy

| Layer | Tool | Scope |
|---|---|---|
| Domain | `flutter test` unit | 100% of commands, timing math, keyframe interpolation, migrations |
| Presentation | widget tests + golden tests for panels | Tool panels, dock states, timeline gestures |
| Engine (Kotlin) | JUnit | Spec → Composition mapping, effect parameter mapping |
| Integration | `integration_test` on device | Import → edit → export smoke test |

## 7. Risks & mitigations

| Risk | Mitigation |
|---|---|
| `CompositionPlayer` limits (multi-sequence, seeking speed) | Phase 2 spike first; fallback: ExoPlayer + `setVideoEffects` for preview of single sequence |
| Device codec fragmentation | Query `MediaCodecList`; proxies for high-res sources; conservative export defaults |
| Text rendering per frame is costly | Rasterize once per style/animation state, cache bitmaps, animate via matrix/alpha |
| Large projects slow down UI | Immutable model with structural sharing, `select` providers, virtualized timeline |
| Preview/export mismatch | Single engine for both (rule in AGENTS.md) |
