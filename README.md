# CleanCut

A touch-first video editor for **Android** phones and tablets, built with Flutter and a native AndroidX Media3 engine.

> Status: **Phase 0 — foundation.** See the roadmap in [`docs/PLAN.md`](docs/PLAN.md).

## Planned features

Trim · Split · Flow (speed & curves) · Filters & adjustments · Crop · Rotate · Position · Size · Mirror · Flip · Fill modes · Background · Border · Blur · Opacity · Masks · Audio tracks · Photos · Photo motion (Ken Burns) · Text styles · Text motion · Export to 720p/1080p/4K

## Docs

- [`AGENTS.md`](AGENTS.md) — rules for contributors and AI agents
- [`docs/PLAN.md`](docs/PLAN.md) — architecture & implementation roadmap
- [`docs/DESIGN.md`](docs/DESIGN.md) — UI/UX spec (Bottom Dock layout)

## Development

Requires [FVM](https://fvm.app) and the Android SDK (minSdk 29).

```sh
fvm install            # installs Flutter 3.47.9 from .fvmrc
fvm flutter pub get
fvm flutter analyze
fvm flutter test
fvm flutter run        # on an Android device/emulator
```
