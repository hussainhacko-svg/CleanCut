# CleanCut — Design Spec

Chosen visual system: **Clipcraft** (local reference in `Clipcraft_cleancut/`, git-ignored; Jetpack Compose prototype + 133 category-colored duotone SVG icons + Manrope & JetBrains Mono variable fonts + adaptive launcher icon). Replaces the earlier VCLIP Figma kit across every screen while keeping the **CleanCut** brand name and only the screens in `PLAN.md` (Projects home, Editor, Settings — no Templates/AI/Cloud/Sign-in tabs).

## 1. Principles

1. **Preview first, tools at the thumb.** Full-bleed preview on phones with a rounded bottom timeline/tool sheet; Neon Focus floating inspector on tablets.
2. **Context, not menus.** The tool tray shows only what applies to the current selection.
3. **Direct manipulation.** Drag clips, pinch the timeline, and manipulate layers directly on the preview with one or two fingers.
4. **Everything undoable.** No confirmation dialogs; undo/redo is always visible.
5. **Exact when needed.** Every slider also accepts a typed value and has a reset.

## 2. Layouts

### Phone — compact (< 840dp), Clipcraft **Editor B**

```
┌──────────────────────────────┐
│ (‹)                 [Export] │  floating top bar (56dp)
│                              │
│          PREVIEW             │  fitted between top bar & sheet (never behind them)
│     (gizmos drawn on top)    │
│╭────────────────────────────╮│  rounded bottom sheet (top radius 22, 340dp)
││            ────            ││  40×4 drag handle pill
││ 00:08/00:24  ↶ (▶) ↷    ⛶ ││  PlayRow: monospace timecode, undo·play·redo, fullscreen
││ ─────────────●─────────────││  ruler (JetBrains Mono) + indigo playhead with dot cap
││ ▓▓▓▓▓▓▓▓▓▓▓▓▓┃▓▓▓▓▓▓▓      ││  main video strip (radius 12) + ⧓ transition markers
││     ░░O░░░   ┃             ││  overlay / audio pill lanes (translucent category fill)
││ ⊕  ♪Music 🎙Voice T Text … ││  ToolTray: duotone category icons + 10sp labels
│╰────────────────────────────╯│
└──────────────────────────────┘
```

When a tool opens, a **tool panel** replaces the tool tray inside the bottom sheet (keeping the timeline at least 80dp tall and preserving its scroll offset; the sheet expands up to 430dp / 62% height). The sheet is 340dp (at most 44% of the height) otherwise. **Adaptation:** Clipcraft draws the preview full-bleed behind the sheet, but its preview is a placeholder; with real video that hid the lower part of the frame and the crop/transform handles, so the preview is fitted into the space between the top bar and the sheet. Header: bold 14sp Manrope title at left, muted `Reset` and `✕` at right, hairline `outlineVariant` top divider.

### Tablet — expanded (≥ 840dp), Clipcraft **Neon Focus**

```
┌──────────────────────────────────────────────┐
│ ‹                                   [Export] │  top bar
├──────────────────────────────┬───────────────┤
│                              │  INSPECTOR /  │  floating right card (300dp,
│           PREVIEW            │  TOOL PANEL   │  radius 14, outlineVariant border)
│         (radius 12)          │               │
├──────────────────────────────┴───────────────┤
│ 00:08 / 00:24       ↶  (▶)  ↷             ⛶  │  PlayRow
├──────────────────────────────────────────────┤
│ ▓▓▓▓▓▓▓▓▓▓●▓▓▓▓▓▓▓▓▓▓▓▓      video           │  full-width Timeline T1
│   ░░O░░   ┃                  overlay         │
│ ≈≈≈≈≈≈≈≈≈≈┃≈≈≈≈≈             audio           │
├──────────────────────────────────────────────┤
│ ⊕  ♪Music  🎙Voice  T Text  ✦Effect  …       │  bottom ToolTray
└──────────────────────────────────────────────┘
```

When no tool panel is open, the floating Inspector card shows the selected clip's name and duration (or a prompt when nothing is selected); opening any tool panel renders it inside the floating card.

## 3. Tool tray content

Horizontally scrolling row (`ToolDock`, height 64dp); items ≥ 60dp wide with 22px category-colored duotone `AppIcon` + 10sp `Manrope` label in `onSurfaceVariant`; leading item is a 38dp circle chip (`primary` for ⊕ Add media, `surfaceContainerHigh` for ‹ Back) with tooltip/semantics.

| State | Dock items |
|---|---|
| Nothing selected | ⊕ Add media · Music · Voice · Text · Effect · Overlay · Ratio |
| Video/photo or overlay clip selected | ‹ Back · Split · Duplicate · Filters · Crop · Transform · Adjust · Speed · Animation · Volume · Delete |
| Text selected (Phase 8, kit "Edit") | ‹ Back · Split · Edit · Delete · Color · Font · Align |
| Audio selected | ‹ Back · Split · Volume · Speed · Delete |

Tools whose phase hasn't shipped show "Coming in a later update." All icons come from the Clipcraft icon pack (`assets/icons/`). Category icons keep their built-in duotone color; the pack's uncategorized grey glyphs (chevrons, close, plus, more, settings, info, sun, moon, sliders) take the ambient icon color so they follow the theme and dim when disabled (`AppIcons.neutral`). On filled buttons every icon is tinted `onPrimary`. **Duplicate** sits right after Split (owner decision).

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
- Selection: tap a clip to select, tap it again or empty space (or ‹ Back) to deselect. A selected main clip gets a light video-cyan `#36C5F0` wash (28%, thumbnails stay visible), a 2px video-cyan border and 4×14 trim handles in the same color; the other lanes drop to 60% opacity. Pills have a 30% fill in their lane color (58% when selected), an outline and, when selected, handles in their lane color. Selection is UI state (not undoable) and clears when its clip disappears.
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

## 5. Visual language (Clipcraft tokens)

Colors live only in `AppTheme` (`lib/app/theme/app_theme.dart`); shapes and fonts in `AppTokens` (`lib/core/theme/app_tokens.dart`).

| Token | Value | ColorScheme role |
|---|---|---|
| Background | `#16171B` | `surface` |
| Editor canvas backing | `#0F1014` | `surfaceContainerLowest` |
| Sheet / card / tool panel | `#1D1E24` | `surfaceContainer` |
| Elevated surface / chip | `#262730` | `surfaceContainerHigh` |
| Hairline border / divider | `#2E2F39` | `outlineVariant` |
| Muted / disabled | `#6B6F85` | `outline` |
| Secondary text | `#8B8FA3` | `onSurfaceVariant` |
| Primary text | `#E6E6EA` | `onSurface` |
| Primary / Secondary / Tertiary | `#7C8CFF` / `#A35CFF` / `#FF4FD8` | `primary` / `secondary` / `tertiary` |
| Accent gradient | `#7C8CFF → #A35CFF` (135°) | `AccentGradient` |

- **Category / timeline colors (`TimelineColors`):** video `#36C5F0`, audio `#1DD1A1`, text `#FF9F43`, effect `#A35CFF`, overlay `#FF5D73`, music `#5B8CFF`.
- **Type:** **Manrope** (variable, SIL OFL) for all UI text; **JetBrains Mono** (variable, SIL OFL) for timecodes and ruler labels (tabular fixed-width digits).
- **Shapes:** cards and preview frames radius 12; floating tablet inspector radius 14; bottom sheets and phone timeline sheet top radius 22; page gutter 16dp.
- **Icons:** Clipcraft category-colored duotone SVGs in `assets/icons/`. `AppIcon` keeps category colors by default; the uncategorized grey glyphs (`AppIcons.neutral`) take the ambient icon color; pass `color:` to tint on filled buttons or disabled states.
- Touch targets stay ≥ 48dp. The app is **dark only** (owner decision): no light theme and no theme setting.

## 5a. Editor & Full Screen

- **Phone (`Editor B`):** Full-bleed preview behind the floating top bar (`‹` back in a translucent circle, primary `Export` button on right) and a rounded bottom sheet (top radius 22, 340dp default / up to 430dp with a tool panel open).
- **PlayRow:** Monospace timecode on the left, Undo · primary circular Play/Pause · Redo centered, Full screen on the right.
- **Timeline T1:** Fixed centered playhead in `primary` with a 10dp circular cap; rounded main clips (radius 12) highlighted in cyan `#36C5F0` when selected; full-pill overlay/audio clips in 30% translucent category fill (58% + 2px border when selected).
- **Full screen:** Video edge-to-edge on black, translucent close circle top-right, floating dark bar (`surfaceContainer` 90%, radius 14, `outlineVariant` border) with play/pause, JetBrains Mono times, gradient scrub bar, and exit.

## 6. Key components (build as reusable widgets)

- `ToolDock` (Clipcraft `ToolTray`), `ToolPanel`, `PropertiesPanel` (tablet floating Inspector)
- `GradientSliderRow`, `PanelTabs`, `ValueBubble`, `ColorSwatchRow`, `KeyframeToggleButton`
- `TimelineView` (ruler, lanes, clips, playhead, snapping)
- `PreviewView` (Texture + gizmo overlay layer)
- `TransformGizmo`, `CropOverlay`

## 7. Home screen (projects) — Clipcraft **Home A**

```
┌──────────────────────────────┐
│ 🎞 CleanCut                ⚙ │  TopAppBar: film icon + title (phone), settings
│ ┌──────────┐  ┌──────────┐   │
│ │  16:10 ⋯ │  │  16:10 ⋯ │   │  2-col grid (phone) / adaptive grid (tablet)
│ │    01:05 │  │    00:12 │   │  rounded 12dp thumbnail + duration badge + •••
│ └──────────┘  └──────────┘   │
│ Holiday       Summer trip    │  title (bodyLarge SemiBold)
│ 26, Nov, 2026 25, Nov, 2026  │  date (bodySmall onSurfaceVariant)
│                         [+]  │  FAB (phone) / Extended FAB "New project" (tablet)
└──────────────────────────────┘
```

- **New project:** Tap the FAB (the only New project action; the empty state just says "Tap + …") → system Photo Picker → "Canvas size" bottom sheet (drag handle + title + ratio outlines) → project created and opened.
- **Card menu (`•••`):** Rename, Duplicate, Delete (immediate with Undo snackbar).
- **Settings:** a single About card (Open source licenses) on every width; no theme choice since the app is dark only.
