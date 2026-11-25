# CleanCut — Design Spec

Chosen layout: **Bottom Dock**. Compact, touch-first, one-handed on phones; a three-pane workspace on tablets.

## 1. Principles

1. **Preview first, tools at the thumb.** Content stays at the top, controls at the bottom within reach.
2. **Context, not menus.** The dock shows only what applies to the current selection.
3. **Direct manipulation.** Drag clips, pinch the timeline, and manipulate layers directly on the preview with two fingers.
4. **Everything undoable.** No confirmation dialogs; undo/redo is always visible.
5. **Exact when needed.** Every slider also accepts a typed value and has a reset.

## 2. Layouts

### Phone — compact (< 600dp)

```
┌──────────────────────────────┐
│ ✕   Project ▾   1080p ▾  [⇪] │  top bar: close, title, export settings, Export
│┌────────────────────────────┐│
││                            ││
││          PREVIEW           ││  ~40–45% height, letterboxed to canvas aspect
││                            ││  gizmos drawn on top when a layer is selected
│└────────────────────────────┘│
│ 00:12.4 / 00:45   ↶ ↷  ▶  ⛶  │  transport row
│ ─────────────┃────────────── │  ruler (playhead fixed at center)
│ ▓▓▓▓▓▓▓▓▓▓▓▓▓┃▓▓▓▓▓▓▓ [+]    │  main video track (thumbnails)
│     ░░T░░░   ┃               │  text / overlay lanes (collapsed pills)
│ ≈≈≈≈≈≈≈≈≈≈≈≈≈┃≈≈≈≈            │  audio lane (waveform)
├──────────────────────────────┤
│ ✂Edit ◐Filter T Text ♪Audio …│  tool dock (horizontal scroll, 64dp)
└──────────────────────────────┘
```

When a tool opens, a **tool panel** (max 40% height) replaces the dock area and pushes the timeline up. Panel header: `← Tool name ........ ✓`. Sliders and option chips go inside.

### Tablet — expanded (≥ 840dp), landscape

```
┌────┬───────────────────────────────┬──────────────┐
│ ✂  │                               │ PROPERTIES   │
│ ◐  │           PREVIEW             │ Position ─○─ │
│ T  │                               │ Scale    ──○ │
│ ♪  │   00:12.4   ↶ ↷  ▶  ⛶         │ Rotate   ○── │
│ ▣  ├───────────────────────────────┴──────────────┤
│ ⚙  │ ▓▓▓▓▓▓▓▓▓▓┃▓▓▓▓▓▓▓▓▓▓▓▓       video          │
│    │   ░░T░░   ┃                   text           │
│    │ ≈≈≈≈≈≈≈≈≈≈┃≈≈≈≈≈              audio          │
└────┴──────────────────────────────────────────────┘
 rail   preview + transport          properties panel (320dp)
 72dp                                timeline spans the full width
```

**Medium (600–839dp)** uses the phone layout with a wider preview. The tool panel becomes a side sheet in landscape.

## 3. Tool dock content

| State | Dock items |
|---|---|
| Nothing selected | Edit · Audio · Text · Photo/Overlay · Filters · Canvas (ratio, bg) · Effects |
| Video/photo clip selected | Split · Trim · Flow (speed) · Crop · Transform (rotate/position/size/mirror/flip/fill) · Filter · Adjust · Blur · Mask · Border · Opacity · Volume · Motion (photo) · Duplicate · Delete |
| Text selected | Edit text · Style · Motion · Transform · Opacity · Duplicate · Delete |
| Audio selected | Split · Volume · Fade · Speed · Duplicate · Delete |

## 4. Gestures

| Where | Gesture | Action |
|---|---|---|
| Timeline | horizontal drag | scrub (playhead fixed, content moves) |
| Timeline | pinch | zoom time scale |
| Clip | tap | select |
| Clip | long-press + drag | reorder / move to another lane |
| Clip edges | drag handles | trim (shows source frame on preview) |
| Preview | 1-finger drag on layer | move |
| Preview | 2-finger pinch/rotate | scale / rotate the selected layer |
| Preview | double-tap text | edit text inline |
| Anywhere | 2-finger tap / 3-finger tap | undo / redo (optional, settings) |

Snapping: clip edges snap to playhead, clip boundaries, and markers. Transforms snap to center, edges, and 0/90/180/270°. Each snap triggers a light haptic.

## 5. Visual language

- Material 3, **dark default** (`surface` near-black so the video reads true), light theme optional.
- One accent color (seed) for selection, playhead, and primary action. Track colors: video = neutral, overlay = accent-tint, text = tertiary, audio = secondary.
- Typography: Material 3 type scale. Timecodes use tabular figures.
- Sizes: dock item 64dp tall (icon + label), touch targets ≥ 48dp, panel corner radius 16dp, timeline track 56dp (video) / 32dp (text, audio).
- Motion: 200ms emphasized easing for panel open/close; no animation on scrub.

## 6. Key components (build as reusable widgets)

- `EditorScaffold` (responsive switch between compact and expanded)
- `ToolDock`, `ToolRail`, `ToolPanel`, `PropertiesPanel`
- `PropertySlider` (label, value, typed input, reset, keyframe toggle, haptic snap)
- `OptionChips`, `PresetGrid` (filters, motions, text styles with live thumbnails)
- `TimelineView` (ruler, lanes, clips, playhead, snapping)
- `PreviewSurface` (Texture + gizmo overlay layer)
- `TransformGizmo`, `CropOverlay`, `MaskOverlay`

## 7. Home screen (projects)

```
┌──────────────────────────────┐
│ CleanCut                  ⚙  │  app bar: title, Settings
│ ┌──────────┐ ┌──────────┐    │
│ │  ▭  0:42 │ │  ▯  1:05 │    │  grid of project cards (max 240dp wide):
│ │ Trip   ⋮ │ │ Demo   ⋮ │    │  canvas-shaped preview + duration badge,
│ │ Edited … │ │ Edited … │    │  name, edited date, ⋮ menu
│ └──────────┘ └──────────┘    │
│                              │
│        [ + New project ]     │  extended FAB, bottom center (thumb zone)
└──────────────────────────────┘
```

- **New project:** system Photo Picker (videos + photos, multi-select) → bottom sheet "Canvas size" (Original, 9:16, 16:9, 1:1, 4:5, 3:4, 4:3) → project is created and opened. Cancelling either step creates nothing.
- **Card menu:** Rename (dialog), Duplicate ("<name> copy"), Delete. Delete happens immediately and shows a snackbar with **Undo** — no confirmation dialog.
- Empty state: icon, "No projects yet", hint to tap New project.
- Thumbnails replace the canvas-shape placeholder once Phase 2 adds frame extraction.
