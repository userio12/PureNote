# Planning — purenote (Production Grade)

## Overview

**purenote** is a production Flutter note-taking app inspired by NotallyX. Single-package project. Android-first, iOS stretch. Zero ads, zero tracking, zero cloud dependency. All data stays on device.

## Tech Stack (Final)

| Layer | Technology | Version Constraint | Rationale |
|---|---|---|---|
| Framework | Flutter | stable (SDK ^3.11.5) | Matches pubspec environment |
| Language | Dart | ^3.11.5 | Non-negotiable |
| State | Riverpod + codegen | ^2.x | Compile-time safe, testable, 2026 standard |
| Database | drift + drift_dev | latest | Type-safe SQL, auto-migration, reactive |
| Rich text | flutter_quill | ^11.5.1 | Mature (3K stars, 232 releases), Quill Delta |
| Navigation | go_router | latest | Declarative, deep links, tab state |
| Encryption | encrypt + local_auth + flutter_secure_storage | latest | AES-256 + platform biometric |
| Crash reporting | Sentry (opt-in) | latest | Privacy-first, debug symbols, session replay |
| Background work | workmanager | latest | Backup scheduler, reminder reschedule on boot |
| Widget | home_widget | latest | Android/iOS widget bridge |
| Notifications | flutter_local_notifications | latest | Reminder alarms |
| Audio | record | latest | Audio note capture |
| Testing | flutter_test + integration_test | SDK | No extra test frameworks |
| Codegen | build_runner + riverpod_generator + drift_dev | latest | Required by Riverpod + drift |

## Production Architecture

### Pattern: Feature-First with Core Layer

```
lib/
├── core/               # Shared infrastructure
│   ├── database/       # drift schema + DAOs
│   ├── theme/          # Material 3 theming
│   ├── routing/        # go_router config
│   ├── services/       # encryption, backup, notification, audio, import
│   ├── providers/      # app-level Riverpod providers
│   ├── utils/          # helpers, formatters, link detection
│   └── error/          # error boundaries, logging, crash reporting
├── features/           # One folder per feature
│   ├── notes/
│   ├── editor/
│   ├── tasks/
│   ├── audio/
│   ├── labels/
│   ├── search/
│   ├── settings/
│   ├── backup/
│   └── import/
├── widgets/            # Shared app-wide widgets
└── main.dart
```

### Production Data Model (drift Tables)

```dart
// --- notes ---
// Columns: id (Text PK), type (Int: 0=richText, 1=taskList, 2=audio),
//          title (Text), content (Text — Quill Delta JSON),
//          color (Int — ARGB), isPinned (Bool), isLocked (Bool),
//          isArchived (Bool), reminderAt (Int? — epoch ms),
//          createdAt (Int — epoch ms), updatedAt (Int — epoch ms),
//          orderIndex (Real)

// --- labels ---
// Columns: id (Text PK), name (Text), color (Int — ARGB, nullable)

// --- note_labels (junction) ---
// Columns: noteId (Text FK→notes), labelId (Text FK→labels)
// PK: (noteId, labelId)

// --- attachments ---
// Columns: id (Text PK), noteId (Text FK→notes),
//          filePath (Text — relative to app docs dir),
//          mimeType (Text), fileName (Text), fileSize (Int)

// --- task_items ---
// Columns: id (Text PK), noteId (Text FK→notes),
//          content (Text — Quill Delta JSON),
//          isChecked (Bool), parentId (Text? self-ref FK for subtasks),
//          orderIndex (Real)

// --- settings (single-row key-value) ---
// Columns: key (Text PK), value (Text — JSON-encoded)

// --- backup_log ---
// Columns: id (Int PK auto), timestamp (Int), filePath (Text),
//          fileSize (Int), status (Int: 0=success, 1=failure),
//          errorMessage (Text?)
```

### Error Handling Architecture

**Three-layer error model:**

1. **Data layer errors** — DB corruption, file I/O failures, encryption failures
   - Caught in DAOs and services
   - Wrapped in `Result<T>` type (sealed class: `Ok<T>` / `Err`)
   - Logged via structured logger
   - Propagated up to provider layer

2. **Provider layer errors** — AsyncValue handles loading/error/data states
   - Riverpod `AsyncValue.error` caught by UI
   - Non-critical errors shown as snackbars
   - Critical errors shown as inline banners with retry

3. **UI layer errors** — Uncaught exceptions, widget build failures
   - `FlutterError.onError` → Sentry capture
   - `PlatformDispatcher.instance.onError` → Sentry capture
   - Widget-level error boundaries for complex screens (editor, viewer)
   - Never show raw exception text to user

```dart
// Result type
sealed class Result<T> {
  const Result();
}
class Ok<T> extends Result<T> {
  final T value;
  const Ok(this.value);
}
class Err<T> extends Result<T> {
  final AppError error;
  const Err(this.error);
}

// Structured error types
sealed class AppError {
  String get userMessage;  // User-readable, localized
}
class DatabaseError extends AppError { ... }
class EncryptionError extends AppError { ... }
class FileSystemError extends AppError { ... }
class ImportError extends AppError { ... }
```

### Database Migration Strategy

**All migrations are version-tracked via drift's auto-migration API with explicit tests.**

```dart
@DriftDatabase(tables: [Notes, Labels, NoteLabels, Attachments, TaskItems, Settings, BackupLog])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (m) async {
        await m.createAll();
      },
      onUpgrade: (m, from, to) async {
        // Each version bump gets a test
      },
      beforeOpen: (details) async {
        await customStatement('PRAGMA journal_mode=WAL');
        await customStatement('PRAGMA foreign_keys=ON');

        if (kDebugMode) {
          // Verify schema integrity in debug builds
          final result = await customSelect('PRAGMA foreign_key_check').get();
          assert(result.isEmpty, 'Foreign key violations found: $result');
        }
      },
    );
  }
}
```

**Migration testing pattern:**
```dart
// test/core/database/migrations_test.dart
void main() {
  test('migrate from v1 to v2 preserves all data', () async {
    // 1. Create v1 schema
    // 2. Insert test data
    // 3. Run upgrade to v2
    // 4. Verify all data preserved
    // 5. Verify new schema constraints
  });
}
```

### Background Work Architecture

**workmanager tasks:**

| Task ID | Type | Frequency | Constraints | Action |
|---|---|---|---|---|
| `purenote-backup` | Periodic | 24h | Battery not low, storage not low | Copy drift DB + attachments → ZIP archive |
| `purenote-reminder-reschedule` | One-time (boot) | On boot | None | Reschedule all pending reminder notifications |

**Boot receiver:** Required for reminder notifications to survive device reboot. `workmanager` handles this natively via Android `AlarmManager` persistence.

**Backup strategy:**
- Backup is a ZIP containing: drift DB dump (`.sql` file via `.export()`) + attachment files
- Password-protected ZIP if user opts in (AES-256 via `encrypt` package on the ZIP)
- Manifests: `backup_manifest.json` inside ZIP with file list + dates
- Restore: validate ZIP integrity, prompt password if needed, extract to temp, validate DB, swap with current

### Release Process

```
┌──────────┐    ┌──────────┐    ┌──────────┐    ┌──────────┐
│ Feature  │───>│  Dev     │───>│  Beta    │───>│ Production│
│ Branch   │    │  Merge   │    │  Release │    │  Release  │
└──────────┘    └──────────┘    └──────────┘    └──────────┘
                    │               │               │
                    ▼               ▼               ▼
              flutter analyze   Internal test   Staged rollout
              flutter test      track (20%)      (1% → 10% → 100%)
              Build AAB                           Monitor Sentry
```

1. **Feature branch:** `feature/<name>` → PR to `main`
2. **Dev merge:** Merge to `main` triggers CI: `analyze` → `test` → `build debug APK`
3. **Beta release:** Tag `vX.Y.Z-beta.N` → CI builds AAB, uploads to Play Console Internal Testing track
4. **Production release:** Tag `vX.Y.Z` → CI builds AAB, uploads to Play Console Production track with staged rollout (1% → 10% → 100% over 48h)

**Rollback plan:** If crash-free rate drops below 99.0% or ANR rate exceeds 0.5%, halt rollout and revert to previous version.

### Performance Budgets (Hard Constraints)

| Metric | Target | Breach response |
|---|---|---|
| Cold start p50 | < 1.8s | Investigate on next cycle |
| Cold start p95 | < 3.5s | Block release |
| Frame build p99 | < 16ms | Investigate on next cycle |
| Frame raster p99 | < 16ms | Block release |
| Crash-free sessions | > 99.7% | Auto-halt rollout |
| ANR rate | < 0.4% | Block release |
| App size (download) | < 35 MB | Block release |

### Security Hardening

1. **Release builds** use `--obfuscate --split-debug-info=build/debug-info`. Symbols uploaded to Sentry from CI.
2. **ProGuard rules** (`android/app/proguard-rules.pro`):
   ```
   -keep class com.purenote.** { *; }
   -keep class com.philkes.** { *; }
   -dontwarn com.google.errorprone.**
   ```
3. **Keystore** is NOT in repo. Managed via environment variables in CI (encoded as base64 `KEYSTORE_FILE`, `KEYSTORE_PASSWORD`, `KEY_ALIAS`, `KEY_PASSWORD`).
4. **Sentry DSN** passed via `--dart-define=SENTRY_DSN=...` (not hardcoded).
5. **No secrets in code.** Zero API keys, zero tokens. Only local-auth and encryption keys derived from user PIN at runtime.

### Accessibility Requirements

- All tappable widgets have `Semantics` labels
- Sufficient color contrast (WCAG AA minimum) in both light and dark themes
- Toolbar buttons have tooltips (Accessibility `onLongPress` hint)
- Rich text content readable via TalkBack (flutter_quill has `accessibilityLabel` per embed)
- Text scale factor respects system setting
- Touch targets minimum 48x48dp

### Localization Strategy

- v1: English only
- v2+: `flutter_localizations` with ARB files via `flutter gen-l10n`
- Extract all user-facing strings to ARB from day one (don't hardcode)
- RTL layout support in widget design (avoid hardcoded left/right)

### File & Cache Management

| Directory | Content | Cleanup Strategy |
|---|---|---|
| `app_docs/attachments/` | User-attached files | Never auto-deleted |
| `app_docs/backups/` | Generated backup ZIPs | Keep last 5, auto-prune oldest |
| `app_docs/audio/` | Audio recordings | Deleted when note is deleted |
| `tempDir/` | Import temporary files, thumbnails | Clear on app start |
| `cacheDir/` | Image cache, widget render cache | System manages, or clear on low storage |

**Orphan detection:** On app start, scan attachments table for file references that don't exist on disk → mark as broken in UI. Scan attachment directory for files not referenced in DB → delete (with confirmation).

### Edge Cases (Production)

1. **Device reboot during backup:** Backup is atomic (write to temp, rename). Incomplete backup files are cleaned on next app start.
2. **Database corruption:** Integrity check on open. If failed, offer "Repair database" which exports what it can to a new DB.
3. **Concurrent app + widget data access:** Widget reads from SharedPreferences snapshot. App writes to drift + updates SharedPreferences + calls `HomeWidget.updateWidget()`. Use debounce to avoid rap`id updates.
4. **Large ENEX import (100+ notes with attachments):** Stream XML parse. Show progress per-note. Don't block UI isolate — use isolate for XML parsing and base64 decoding.
5. **Reminder notification when note is deleted:** Notification tap handler checks if note still exists. If not, show snackbar "This note was deleted" and navigate home.
6. **Audio recording interrupted by call:** `record` package handles interruption. On resume, user can continue or discard partial recording.
7. **Quick successive app lock/unlock:** `local_auth` does not allow spamming. Rate-limit lock attempts (3 wrong PIN → 30s lockout).
8. **Widget after app data reset:** Widget shows "Open purenote to set up" instead of data remnants.
