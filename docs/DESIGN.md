# CleanCut — Design Spec

Chosen layout: **Bottom Dock**. Compact, touch-first, one-handed on phones; a three-pane workspace on tablets.

**Visual source of truth: the VCLIP Figma kit** (Figma file `hR2oviwmkmDaGGHdFApOI7`, page "Mobile Screens"). The owner decided the app follows it completely, in every phase. Before building a screen, open its VCLIP frame (Timeline, Filters, Alignment, Music, Media, Crop, Speed, Adjust, Animation, Transition, Text templates, Fonts, Text color, Overlay, Stickers, Effects, Ratio, Full screen…) and match it. Not used from the kit: its sample photos, the "VCLIP" name and logo, and screens for features outside `PLAN.md` (sign-in, Go Pro, stock media, AI images, templates). Where the kit and this file disagree, the kit wins; update this file to match.

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
│ ⌂                        [⇪] │  top bar: home (left), export (right) — VCLIP
│┌────────────────────────────┐│
││                            ││
││          PREVIEW           ││  ~40–45% height, letterboxed to canvas aspect
││                            ││  gizmos drawn on top when a layer is selected
│└────────────────────────────┘│
│ ▶      ↶ 00:06 / 00:12 ↷   ⛶ │  transport row: play left, undo/timecode/redo centred, full screen right
│ ─────────────┃────────────── │  ruler (playhead fixed at center)
│ ▓▓▓▓▓▓▓▓▓▓▓▓▓┃▓▓▓▓▓▓▓ [+]    │  main video track (thumbnails)
│     ░░T░░░   ┃               │  text / overlay lanes (collapsed pills)
│ ≈≈≈≈≈≈≈≈≈≈≈≈≈┃≈≈≈≈            │  audio lane (waveform)
├──────────────────────────────┤
│ ⊕  ♪Music 🎙Voice T Text ✦…  │  tool dock: white ⊕ add, then icon+label tools (64dp)
└──────────────────────────────┘
```

When a tool opens, a **tool panel** (max 40% height) slides up over the dock and pushes the timeline up (VCLIP "Filters"/"Alignment"). Panel: `surfaceContainer` at 85% opacity with a 20px backdrop blur, top radius 20. Header: **bold 14 title** at left, `Reset` (12, muted) and `✕` at right. Below: a row of text category tabs (14; selected = bold with the accent gradient, others muted), then the controls (preset tiles, sliders).

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

## 5. Visual language (VCLIP tokens)

Colors live only in `AppTheme` (`lib/app/theme/app_theme.dart`); shapes and fonts in `AppTokens` (`lib/core/theme/app_tokens.dart`).

| Token | Value | ColorScheme role |
|---|---|---|
| Background | `#030303` | `surface` |
| Tool panel / sheet / dialog | `#1F1F1F` (85% + blur on panels) | `surfaceContainer` |
| Card | `#212121` | `surfaceContainerHigh` |
| Round icon chip (`+`, `•••`) | `#3A3A3A` | `surfaceContainerHighest` |
| Hairline border | `#2D2D2D` | `outlineVariant` |
| Muted text / inactive tab / tile border | `#606060` | `outline` |
| Secondary text (dates) | `#9E9E9E` | `onSurfaceVariant` |
| Primary text / icons | `#FFFFFF` | `onSurface` |
| Accent gradient | `#FFB951 → #CE50E0` (135°) | `secondary` → `primary` |

- **Accent:** the orange→pink gradient marks the selected tab, the selected tile border and premium highlights; solid `primary` (#CE50E0) where a gradient can't be used (radios, focus).
- **Timeline lanes (Phase 3, VCLIP "Timeline"):** colored pills 30dp tall with icon + label — effect = grey, text = indigo, overlay = magenta, audio = orange with a white waveform; video = thumbnail strip 60dp tall. Exact values to be read from the frame when Phase 3 starts and added as a `ThemeExtension`.
- **Type:** Plus Jakarta Sans (400/500/600/700, bundled, OFL) for everything; Bebas Neue for the wordmark only. Timecodes use tabular figures.
- **Shapes:** cards, tiles and preset thumbnails radius 10; sheets and panels top radius 20; round chips 32dp; page gutter 18dp.
- **Icons:** thin line icons, white on black; Material outlined/rounded icons where the kit's icon isn't available.
- Touch targets stay ≥ 48dp: small visual elements (32dp chips) get invisible padding.
- Dark is the default; the light theme reuses the same accents on white surfaces.
- Motion: 200ms emphasized easing for panel open/close; no animation on scrub.

## 6. Key components (build as reusable widgets)

- `EditorScaffold` (responsive switch between compact and expanded)
- `ToolDock`, `ToolRail`, `ToolPanel`, `PropertiesPanel`
- `PropertySlider` (label, value, typed input, reset, keyframe toggle, haptic snap)
- `OptionChips`, `PresetGrid` (filters, motions, text styles with live thumbnails)
- `TimelineView` (ruler, lanes, clips, playhead, snapping)
- `PreviewSurface` (Texture + gizmo overlay layer)
- `TransformGizmo`, `CropOverlay`, `MaskOverlay`

## 7. Home screen (projects) — VCLIP "Projects"

```
┌──────────────────────────────┐
│ CLEANCUT                  ⚙  │  wordmark (Bebas Neue), settings (tune icon)
│ ┌──────────────────────────┐ │
│ │           (+)            │ │  "New project" tile: outlined (outline), radius 10,
│ │       New project        │ │  114dp tall, grey round + chip
│ └──────────────────────────┘ │
│ My projects                  │  18 medium
│ ┌──────────────────────────┐ │
│ │ ▯▯  Flow lifestyle  (•••)│ │  card #212121, radius 10, 114dp: 72×88 thumbnail,
│ │ ▯▯  26, Nov, 2026        │ │  name 18, date 14 (secondary), duration 10,
│ │ ▯▯  1:06                 │ │  round ••• chip top-right opens the menu
│ └──────────────────────────┘ │
└──────────────────────────────┘
```

- One column on phones; on tablets the cards flow into a grid (max 560dp per card).
- **New project:** system Photo Picker (videos + photos, multi-select) → "Canvas size" panel (tool-panel style: title + ✕, a scrolling row of 70dp outlined preset tiles: Original, 9:16, 16:9, 1:1, 4:5, 3:4, 4:3) → project is created and opened. Cancelling either step creates nothing.
- **Card menu:** Rename (dialog), Duplicate ("<name> copy"), Delete. Delete happens immediately and shows a snackbar with **Undo** — no confirmation dialog.
- Empty state: the New project tile, then icon, "No projects yet" and a hint.
- Thumbnails replace the canvas-shape placeholder once Phase 2 adds frame extraction.
- Not adopted from the kit: Camera / Stock videos / AI images shortcuts and "GO PRO" (not in `PLAN.md`).
