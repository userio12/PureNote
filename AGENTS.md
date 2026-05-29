# purenote — Agents guide

Single-package Flutter note-taking app inspired by NotallyX. Offline-only, no cloud, no ads.

## Commands

| Action | Command |
|---|---|
| Install deps | `flutter pub get` |
| Run app | `flutter run` |
| Run all tests | `flutter test` |
| Static analysis | `flutter analyze` |
| Code generation | `dart run build_runner build` |
| Debug APK build | `flutter build apk --debug --target-platform android-arm64` |
| Release AAB | `flutter build appbundle --release --obfuscate --split-debug-info=build/app/outputs/symbols` |

Order: `dart run build_runner build` then `flutter analyze` before pushing.

## Structure

- **Entry:** `lib/main.dart` — ProviderScope → SentryFlutter.init → runApp
- **Architecture:** Feature-first with core layer (database, theme, routing, services, error)
- **State:** Riverpod 2.x with codegen (`@riverpod` annotation)
- **Database:** drift (SQLite) with WAL mode, auto-migrations, FTS5 for search
- **Rich text:** flutter_quill (Quill Delta JSON)
- **Navigation:** go_router with ShellRoute for bottom nav
- **Lint:** `analysis_options.yaml` → `package:flutter_lints/flutter.yaml` (defaults)
- **Tests:** `test/` mirrors `lib/` structure. In-memory drift for DAO tests.
- **CI:** `.github/workflows/flutter-debug-build.yml` — push/PR to `main`/`master`

## Key conventions

- `Result<T>` (sealed Ok/Err) for all data layer operations
- All user-facing strings in ARB files (v1: English only, prepared for l10n)
- Every tappable widget needs Semantics label
- `flutter analyze` must pass before push — zero issues policy
- No secrets in code. Sentry DSN via `--dart-define=SENTRY_DSN=...`

## SDK

`pubspec.yaml` environment: `sdk: ^3.11.5`. Pin Flutter to stable channel.

## Reference

- `docs/research.md` — package evaluations, import format analysis
- `docs/planning.md` — architecture, data model, phases, security model
- `docs/todo.md` — 15-phase implementation checklist
- `GEMINI.md` — Gemini CLI context (sibling file)
