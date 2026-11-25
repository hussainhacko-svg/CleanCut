# AGENTS.md — Rules for AI agents and contributors

CleanCut is a touch-first video editor built with Flutter, **Android only**.
Read `docs/PLAN.md` (roadmap & architecture) and `docs/DESIGN.md` (UI spec) before making non-trivial changes.

These rules were chosen by the project owner. Follow them strictly; if a rule blocks you, stop and ask instead of working around it.

---

## 1. Toolchain

- Flutter is pinned with **FVM** (`.fvmrc` → 3.47.9). Always run `fvm flutter ...` / `fvm dart ...`, never a global `flutter`.
- Target platform: **Android only**. Do not add iOS, web, or desktop folders or platform checks for them.
- `minSdk = 29` (Android 10). Do not lower it. Assume scoped storage only — no `READ/WRITE_EXTERNAL_STORAGE`; use the Photo Picker / `READ_MEDIA_*` and MediaStore.
- Kotlin + Gradle Kotlin DSL (`*.gradle.kts`) only. JVM target 17.

## 2. Dependencies — ask first

- **Never add, remove, or upgrade a pub package or Gradle dependency without explicit approval from the owner.** Propose it with: name, version, why, and alternatives considered.
- Pre-approved (listed in `docs/PLAN.md` §4) may be added when their phase starts, but still mention them in the PR/commit body.

## 3. Architecture — feature-first layers

```
lib/
  app/                    # MaterialApp, router, theme, l10n wiring
  core/                   # shared utils, widgets, errors, extensions (no feature logic)
  engine/                 # Dart side of the native engine bridge (Pigeon API wrappers)
  features/<feature>/
    domain/               # PURE DART: entities, value objects, commands, rules
    data/                 # repositories, serialization, platform/IO adapters
    presentation/         # widgets, screens, Riverpod providers/notifiers
android/app/src/main/kotlin/com/hussainhacko/cleancut/
  engine/                 # Media3 composition builder, effects, export service
pigeons/                  # Pigeon interface definitions (source of truth for the bridge)
```

- `domain/` must not import `package:flutter`, Riverpod, or any IO. It must be unit-testable with `dart test` semantics.
- Features may depend on `core/` and `engine/`, and on another feature's `domain/` only. Never import another feature's `presentation/` or `data/`.
- The **timeline/project model is immutable**. All edits go through `EditCommand`s so undo/redo always works. No widget mutates the model directly.
- Times are stored as integer **microseconds** (`int`), never `double` seconds or `Duration` inside the model.
- The native engine is the **single source of truth for pixels**: preview and export use the same Media3 composition. Never re-implement an effect in Dart for preview only.
- The Flutter ↔ Kotlin bridge uses **Pigeon** only. No hand-written `MethodChannel` string APIs. Regenerate with `fvm dart run pigeon --input pigeons/<file>.dart` and commit generated files.

## 4. State management — Riverpod 3

- Use Riverpod 3 with code generation (`@riverpod` / `riverpod_generator`). No `setState` beyond purely local, ephemeral widget state (e.g., an animation controller).
- One `Notifier`/`AsyncNotifier` per concern; keep providers in the feature's `presentation/` folder.
- Do not use `ref.read` inside `build` to watch values; use `ref.watch`. Use `select` for high-frequency state (playhead position) to avoid timeline rebuilds.
- Playback position updates (≥30 Hz) must not rebuild the whole editor — isolate them in small widgets.

## 5. Code style & quality gates (strict)

- Lints: `very_good_analysis`. `fvm flutter analyze` must report **zero** issues. Do not add `// ignore:` without a comment explaining why.
- Format with `fvm dart format .` before committing.
- Run code generation with `fvm dart run build_runner build -d` and commit generated `*.g.dart` / `*.freezed.dart`.
- Kotlin: follow Android Kotlin style; no `!!` without a comment; use coroutines, not raw threads.

## 6. Testing (strict)

- **Every change to `domain/` ships with unit tests** (new behavior and edge cases: zero-length clips, splits at boundaries, speed ≠ 1, overlapping layers).
- Every tool panel / reusable widget gets a **widget test**.
- Serialization changes require a round-trip test and, if the schema changes, a migration + migration test (`schemaVersion` bump).
- Bug fixes start with a failing test that reproduces the bug.
- `fvm flutter test` must pass locally. CI (`.github/workflows/ci.yml`) runs analyze + test and must be green.
- Native engine code: JVM unit tests for pure logic (composition building, mapping); instrumented tests are optional but encouraged for effects.

## 7. Git — Conventional Commits

- Commit messages follow [Conventional Commits](https://www.conventionalcommits.org/): `feat:`, `fix:`, `refactor:`, `perf:`, `test:`, `docs:`, `build:`, `ci:`, `chore:`. Optional scope: `feat(timeline): pinch to zoom`.
- Subject ≤ 72 chars, imperative mood, no trailing period. Body explains *why* when not obvious.
- Breaking project-file schema changes use `!` (`feat(model)!: ...`) and describe the migration.
- Never commit secrets, keystores, `key.properties`, or `local.properties`.

## 8. UI rules (see `docs/DESIGN.md`)

- Layout: **Bottom Dock** pattern. Breakpoints by window width: compact `< 600dp` (phone), medium `600–839dp`, expanded `≥ 840dp` (tablet: left tool rail + right properties panel).
- Touch targets **≥ 48×48dp**. Primary actions within the bottom thumb zone on phones.
- Material 3, **dark theme by default**, light theme available in settings. Colors only from `ColorScheme` / theme extensions — no hard-coded `Color(0x...)` in widgets.
- Every slider-based property: drag + tap-to-type exact value + reset-to-default + haptic tick at default/snap points.
- Every destructive or multi-step edit is undoable; no "Are you sure?" dialogs for undoable actions.
- The timeline is always **left-to-right** regardless of locale (wrap in `Directionality(textDirection: TextDirection.ltr)`).

## 9. Internationalization (English only, i18n-ready)

- **No user-facing string literals in widgets.** All strings go in `lib/app/l10n/app_en.arb` and are accessed via `AppLocalizations`.
- Use ICU plurals/placeholders instead of string concatenation.
- Use `EdgeInsetsDirectional` / `AlignmentDirectional` so RTL can be added later.

## 10. Performance & media

- Never decode video frames or generate thumbnails/waveforms on the UI isolate — do it natively or in a background isolate, and cache to disk.
- Dispose every controller, stream subscription, and native handle. Native resources (players, textures) are released when the editor closes.
- Export runs in an Android **foreground service** with a progress notification and survives the app being backgrounded.
- Media is referenced by content URI + persisted permission, never copied unless the user asks (proxies/caches go in app cache dir).

## 11. Documentation

- Update `docs/PLAN.md` checkboxes when you complete a plan item.
- Update `docs/DESIGN.md` when you change a UI pattern.
- Public Dart APIs in `domain/` and `engine/` need doc comments.

## 12. Agent behavior

- Prefer small, focused changes that keep the app building and tests green at every commit.
- Don't refactor unrelated code in the same change.
- If a requirement is ambiguous (e.g., an effect's exact behavior), ask the owner rather than guessing.
