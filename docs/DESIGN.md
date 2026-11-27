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

**Tablet (≥ 840dp)** has no VCLIP frame; it keeps this rail + properties panel layout with the kit's tokens (owner decision). In Phase 3 the panel shows the selected clip's name and length; tool controls move into it as their phases land.

## 3. Tool dock content (VCLIP "Timeline" / "Video" / "Edit")

Phone dock: a horizontally scrolling row; items 52dp apart, 24px icon + 8px label at 50% opacity; the first item is a white disc (⊕ add, or ‹ back) without a label. Tablet: the same items in the left rail.

| State | Dock items |
|---|---|
| Nothing selected | ⊕ Add media · Music · Voice · Text · Effect · Overlay · Ratio |
| Video/photo or overlay clip selected | ‹ Back · Split · Duplicate · Filters · Crop · Transform · Adjust · Speed · Animation · Volume · Delete |
| Text selected (Phase 8, kit "Edit") | ‹ Back · Split · Edit · Delete · Color · Font · Align |
| Audio selected | ‹ Back · Split · Volume · Speed · Delete |

Tools whose phase hasn't shipped show "Coming in a later update." Icons that exist as vectors in the kit come from it; the clip tools (split, filters, crop, adjust, speed, animation, volume, delete, mute) were redrawn from the kit's flattened "Icons" sheet and are marked inside their SVGs. **Duplicate** is not in the kit: the owner placed it right after Split, with an icon drawn in the kit's line style (marked in `tool_duplicate.svg`).

- **Split** cuts the selected clip at the playhead; with the playhead outside the clip (or within 0.1 s of an edge) a snackbar says to move it. **Delete** removes the clip at once (undoable, no dialog). Overlay and audio clips get these tools with their phases.

### Speed panel (VCLIP "Speed")

```
┌──────────────────────────────┐
│ Speed               Reset  ✕ │  tool panel header
│              (2×)            │  white value bubble rides over the ruler
│ |'''|'''|'''|'''|'''|'''|    │  tall tick at each label, 3 short between
│ 0.1× 0.25× 0.5× 1× 2× 5× 10× │  labels; the current one bold in the accent gradient
│ Keep pitch              [⏻]  │  video only (not in the kit; owner-approved)
└──────────────────────────────┘
```

- Opens over the dock on phones (the timeline shrinks above it) and in place of the properties panel on tablets; closes with ✕, system back, or when the selection changes.
- Range **0.1×–10×** (owner decision; the kit shows 1/8×–4×). Labels sit at even distances and the speed grows geometrically between them, so 1× is the middle.
- A taller tick under the bubble marks the current value (kit).
- Drag anywhere on the ruler (bubble follows, haptic tick + snap at each label), tap to jump, tap a label (48dp target) to pick that speed, tap the bubble to type an exact value, Reset → 1×. Labels shrink to fit narrow panels (tablet). The speed is applied once, on release, so the preview reloads once; each change is one undo step.
- A **"Normal | Curve"** tab row (kit "Filters" tab style: selected bold in the accent gradient, others muted, 48dp targets) sits under the header. The panel opens on Curve when the clip has a curve. Keep pitch stays below both tabs. On phones the panel leaves the timeline at least 80dp and scrolls inside on short screens.

```
┌──────────────────────────────┐
│ Speed               Reset  ✕ │
│ Normal   Curve               │  tabs
│ [⊘] [~] [∿] [⌄] [⊔] [╲_] [_╱]│  70dp tiles: None, Custom, Montage, Hero,
│ None Custom Montage Hero …   │  Bullet, Flash in, Flash out (shape drawn;
│ Keep pitch              [⏻]  │  selected = white border + bold label + ✎)
└──────────────────────────────┘
```

- **Curve presets** (owner-approved shapes; speed at start/25/50/75/100%): Montage 1·2·0.5·2·1, Hero 1·1·0.25·1·1, Bullet 2·0.25·0.25·0.25·2, Flash in 5·2·1·1·1, Flash out 1·1·1·2·5, Custom flat 1×. Tapping a tile applies it; None returns to the Normal speed. Tapping the selected tile again opens the editor. Reset (Curve tab) restores the preset's shape.
- **Curve editor:** a 150dp graph of speed (10× top, 1× middle, 0.1× bottom, log scale, labelled guides) over the clip, the curve in `primary`, points as white dots (selected: larger, `primary` centre), and a white playhead line. Drag a point up/down (end points) or anywhere between its neighbours (inner points); near 1× it snaps with a haptic tick; the change applies on release (one undo step). Tap a point to select it. The button on the right is **Add point** (adds at the playhead; off when the playhead is outside the clip, on a point, or 10 points exist) or, with an inner point selected, **Delete point**. **‹ Presets** goes back to the tiles.
- The curve follows the clip (owner decision): trimming stretches it, splitting divides it.

### Crop panel (VCLIP "Crop")

```
┌──────────────────────────────┐
│ Crop                Reset  ✕ │
│ [◁▷] [△▽]               [↻] │  mirror, flip (toggles, faint disc when on) · rotate 90°
│              (30°)           │  value bubble over the rotation ruler
│ |''|''|''|''|''|''|''|''|    │  −180° … 0° (middle) … 180°, tall tick every 45°
│ [⌜⌟] [□] [▯] [▭] [▯] [▭] …  │  presets: Free, 1:1, 9:16, 16:9, 3:4, 4:3, 2:1, 4:5
│ Free 1:1 9:16 16:9 3:4 4:3 … │  selected = white glyph + bold white label
└──────────────────────────────┘
```

- **Presets** (owner decision, replacing the kit's "Fit … 5.8:1" list and its Instagram/TikTok logos): Free, 1:1, 9:16, 16:9, 3:4, 4:3, 2:1, 4:5. A ratio crops the largest centered rectangle of that shape from the clip (the lock steers the on-preview handles); Free keeps the rectangle and drops the lock. Free uses the kit's "Fit" corners glyph.
- **Rotation ruler** works like the speed ruler: drag (applied live, one undo step per drag), tap to jump, tap the bubble to type an exact angle (−180 to 180). It snaps with a haptic tick at multiples of 45°. A constant rotation is stored within ±180° (four quarter turns come back to 0°); a keyframed one keeps the turn nearest its current value, so wrapping never spins the clip the long way between keyframes, and is shown wrapped. A keyframed rotation is edited at the playhead.
- Mirror, flip and rotate 90° each are one undo step. **Reset** restores the whole frame, clears mirror and flip and sets the rotation to 0 — one undo step; disabled when nothing changed.
- **On-preview `CropOverlay`:** while Crop is open, the preview shows the selected clip uncropped and fitted (preserving flip and rotation) with a darkened scrim, 3×3 rule-of-thirds grid, and white L-corner brackets. Corners, edges (48dp touch targets) and interior pan update the crop live in one undo step; closing the panel applies the cropped framing to the preview.

### Transform panel, gizmo & keyframes

- **Transform dock tool** sits right after Crop and opens a four-tab panel (`Fill | Position | Opacity | Border`):
  - **Fill:** Fit, Fill, Stretch tiles (single undo step each).
  - **Position:** X (−200%..200%), Y (−200%..200%), Scale (5%..1000%, non-linear with 100% centered), Rotation (−180°..180° with 45° snaps).
  - **Opacity:** 0%..100%.
  - **Border:** Width, Corners, and circular ARGB color swatches.
- Every slider supports drag with snap haptics, tap-to-type exact value, and **tab-scoped Reset** (restores only the open tab in one undo step).
- **Keyframes:** each animatable row (X, Y, Scale, Rotation, Opacity) carries a 48dp ◇/◆ toggle at the right (muted hollow = constant, bright hollow = animated elsewhere, accent-gradient filled = keyframe at playhead). Timeline main clips show accent-gradient diamond markers along the top edge at every distinct keyframe timestamp, keeping them visible when an open panel shrinks the timeline and clear of the centered trim handles and `⧓` markers.
- **On-preview `TransformGizmo`:** active whenever a main clip is selected and the playhead is on it (except while `CropOverlay` is open, which also hides when the playhead leaves the clip). 1-finger drag moves; 2-finger pinch/twist scales and rotates continuously (unwrapped angle deltas). Magnetic snap guides (canvas center X/Y, rotated bounding-box edges, and 0°/90°/180°/270° with an angle pill) draw in the accent gradient with a haptic tick on snap; each gesture coalesces into one undo step.

### Ratio & Background panel (VCLIP "Ratio")

- **Ratio** dock item opens a two-tab panel (`Ratio | Background`) with tab-scoped Reset:
  - **Ratio:** kit rounded aspect outlines (`Original`, 9:16, 16:9, 1:1, 4:5, 3:4, 4:3).
  - **Background:** Color (swatches), Gradient (presets + angle slider), Blur (presets + strength slider), Image (image-only Photo Picker + blur slider). Resolution moves to the Phase 10 export sheet.

### Timeline (VCLIP "Timeline")

- Ruler: labels every major step (5 s at the default zoom of 22.8 px/s) in 12px at 50% white, 4 dots between labels. Steps adapt to zoom so labels stay ≥ 90px apart.
- Playhead: a 2px white line fixed in the middle, spanning the lanes only. Dragging the timeline scrubs; within 8px of a clip edge it snaps there with a haptic tick; playback resumes after the drag if it was playing. Two-finger pinch zooms around the playhead.
- Rows, top to bottom: effect · text · overlay lanes (30px pills, radius 18.5, 10px label with a small glyph), the main video strip (60px thumbnails, radius 10, 4px visual gap between clips, ⧓ transition marker on each boundary), audio lanes (orange pills with a white waveform). The "mute original audio" speaker sits left of 0 s on the first audio row.
- Lane colors (`TimelineColors`): effect `#808080`, text `#43418E`, overlay `#D158D9`, audio `#E86F48`.
- Selection: tap a clip to select, tap it again or empty space (or ‹ Back) to deselect. A selected main clip gets a light cream `#EDDB93` wash (50%, thumbnails stay visible as in the kit's "Video" frame), a 2px white border and 4×14 white trim handles; the other lanes drop to 60% opacity. A selected pill gets a 50% fill, a 2px outline and handles in its lane color. Selection is UI state (not undoable) and clears when its clip disappears.
- The ⧓ marker is decorative until transitions ship: a 48dp target would cover short clips (a 2 s clip is 45px wide at the default zoom).
- **Trim:** the selected clip's white handles have 48dp-wide touch targets centred on its edges. Dragging draws the new length live (trimming the start moves the left edge; the gap closes on release, as the main track is magnetic), snaps to the playhead with a haptic tick, stops at the media's ends and at 0.1 s, and is applied on release as one undo step. The preview then seeks to the trimmed edge to show its frame.
- **Reorder:** long-press a main clip to lift it (raised, shadowed, haptic); drag it sideways; a 2dp white line shows where it will land (a haptic tick when that changes); release to drop. A long press without moving changes nothing.

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

## 5a. Editor (VCLIP "Timeline", "Full screen")

- **Background** `#080808` (`surfaceContainerLowest`).
- **Top:** home icon (top-left) and export icon (top-right) sit beside the preview; no title, no PRO badge.
- **Preview:** the kit's 282×360 box on a 393×852 screen (56dp side insets, ~42% of the height); the canvas is letterboxed inside it. Pixels come from the native engine texture.
- **Transport row:** 40dp dark circle with play/pause at the left, full-screen circle at the right (13dp from the edges, 48dp targets); in the middle small grey undo/redo arrows (white when usable) around a 98dp-wide `00:06 / 00:12` readout (12px, tabular figures).
- **Full screen:** video edge to edge on black, a ✕ at the top right, and a floating rounded bar (`surfaceContainer` 85%) with play/pause, position, a gradient scrub bar (2dp track, 5dp thumb), duration and an exit-full-screen icon. Dragging pauses, seeks frame-accurately and resumes if it was playing.
- **Icons:** the kit's SVGs live in `assets/icons` and are drawn with `AppIcon` (flutter_svg). Glyphs the kit lacks (pause, close, exit full screen) are drawn in the same style and marked in the SVG.

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
│ │ ▯▯  01:06                │ │  round ••• chip top-right opens the menu
│ └──────────────────────────┘ │
└──────────────────────────────┘
```

- One column on phones; on tablets the cards flow into a grid (max 560dp per card).
- **New project:** system Photo Picker (videos + photos, multi-select) → "Canvas size" panel (tool-panel style: title + ✕, then the kit "Ratio" row: bare rounded aspect outlines in `onSurfaceVariant` with captions, 64dp apart — Original first, drawn as the kit's "Fit" corners glyph — then 9:16, 16:9, 1:1, 4:5, 3:4, 4:3; a selected ratio gets an accent-gradient outline and a bold white caption. The kit's Instagram/TikTok logos inside 1:1 and 9:16 are left out: third-party trademarks) → project is created and opened. Cancelling either step creates nothing.
- **Card menu:** Rename (dialog), Duplicate ("<name> copy"), Delete. Delete happens immediately and shows a snackbar with **Undo** — no confirmation dialog.
- Empty state: the New project tile, then icon, "No projects yet" and a hint.
- The card thumbnail is the first frame of the first clip (native extraction, disk-cached); the canvas-shape placeholder shows while it loads or when there is no frame.
- Not adopted from the kit: Camera / Stock videos / AI images shortcuts and "GO PRO" (not in `PLAN.md`).
