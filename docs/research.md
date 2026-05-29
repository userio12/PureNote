# Research — purenote (Production Grade)

## Reference Projects

### NotallyX (Primary Inspiration)

| Attribute | Detail |
|---|---|
| Repo | [Crustack/NotallyX](https://github.com/Crustack/NotallyX) |
| Language | Kotlin (native Android) |
| Stars | ~643 |
| Release count | 39 releases across 3 years |
| License | GPL-3.0 |

**Feature set (all must-haves for purenote):**
- Rich text notes (bold, italic, monospace, strikethrough)
- Task lists with subtasks + auto-sort checked items to bottom
- Reminders with notifications
- File attachments (images, PDFs, any type)
- Sort by title / created date / last modified date
- Color, pin, and label notes
- Clickable links (URLs, phone numbers, emails)
- Undo/Redo
- Home screen widget
- Biometric/PIN lock
- Configurable auto-backups
- Import from Google Keep, Evernote, Quillpad
- Quick audio notes
- List and Grid views
- Quick share as text
- Extensive preferences

**Lessons from NotallyX production operations:**
1. Supports Android Lollipop (API 21) through current. We target API 24+ (drift requirement).
2. Auto-backup uses Android `AlarmManager` + `BootReceiver` — surviving reboot is a production requirement.
3. Widget must survive reboot and theme changes (known issue they fixed in v7.x).
4. 1579 commits over 3 years — this is a mature project with sustained maintenance.
5. Import from 3 competing apps (Keep, Evernote, Quillpad) was a multi-release feature.

---

### Samsung Notes (UX Reference)

| Attribute | Detail |
|---|---|
| Platform | Android (Samsung proprietary, pre-installed on 1B+ devices) |
| Format | `.sdocx` (ZIP of binary `.page` files) — **proprietary, cannot reverse-engineer** |

**Borrowable concepts:**
- Hierarchical folders with color-coded subfolders
- Infinite scroll vs. individual page modes
- Page templates (lined, grid, blank)
- Voice recording embedded in notes
- PDF import + annotation
- Note-level locking
- Multiple export formats (PDF, `.docx`, image)

**Import feasibility:** `.sdocx` is closed binary. No parser exists. Users must export as PDF/Word first (lossy). Samsung Notes **cannot be a direct import source** — document this in the app's import screen so users know.

---

### Flutter Reference Projects

| Project | Stars | Stack | Key Takeaways |
|---|---|---|---|
| [better-keep](https://github.com/foxbiz/better-keep) | ~21 | flutter_quill, sqflite, XOR+SHA256 encryption, PIN, labels, sync | Closest feature match. 12 releases, 4 contributors. Responsive masonry grid. **Flaw:** Uses toy encryption (XOR) instead of AES — we must not repeat this. |
| [miniwiki](https://github.com/wellsa-ai/miniwiki) | ~1 | Riverpod 2.x, drift + SQLCipher, go_router, FTS5, ChaCha20-Poly1305 | Best architecture reference. 54 tests, encrypted DB. Clean feature-first structure. |
| [vaultnbinder](https://github.com/Whyme-Labs/vaultnbinder) | ~1 | Riverpod, drift + SQLCipher, go_router, Argon2id + XChaCha20-Poly1305 | Same stack. Hackathon-quality. Strong encryption choices (Argon2id KDF, XChaCha20-Poly1305 AEAD). |
| [VaultNote](https://github.com/Paresh-Maheshwari/VaultNote) | ~0 | flutter_quill, AES-256-CBC, local_auth, GitHub sync, Provider | Encryption + sync. AGPL-3.0 license. Uses `encrypt` package same as our choice. |
| [Pinpoint](https://github.com/theprantadutta/pinpoint) | ~2 | Riverpod, drift, AES-256, local_auth, audio notes, Freemium model | Multiple note types. Has production architecture with Riverpod + drift. Freemium approach is overkill for us. |
| [flutter_notebook](https://github.com/zjcz/flutter_notebook) | ~1 | Riverpod + drift + freezed, clean arch | Clean arch demo. Tests included. No rich text. |
| [Butterfly](https://github.com/LinwoodDev/Butterfly) | **~1794** | Flutter, custom renderer, drawing, 175 releases, 30 contributors | Largest Flutter notes app. Lessons: needs proper CI/CD (they have 175 releases), cross-platform from day one, open source community management. |

---

## Production Package Evaluations

### Core Stack

| Category | Package | Version | Rationale | Production Concern |
|---|---|---|---|---|
| Rich text | **flutter_quill** | ^11.5.1 | Mature WYSIWYG, Quill Delta standard, 3K+ stars, 232 releases | Large binary contribution (~2MB). Lazy-load embeds. |
| State | **riverpod** + riverpod_generator + riverpod_annotation | ^2.x | Compile-time safe, AsyncNotifier, ProviderContainer for testing. 2026 default. | Codegen is a build step. Hot reload compatible. |
| Database | **drift** + drift_dev + sqlite3_flutter_libs | latest | Type-safe SQL, auto-migrations, Stream-based reactivity, FTS5 | Migration version tracking is manual. Must test migrations in CI. |
| Navigation | **go_router** | latest | Declarative routes, deep links, state-based redirects | ShellRoute for bottom nav (needs care for tab state preservation). |
| Encryption | **encrypt** (AES-256-CBC) + **local_auth** + **flutter_secure_storage** | latest | AES-256 for note content, platform biometric for auth, Keystore/Keychain for keys | Key derivation from PIN must use PBKDF2 (100K iterations min). Don't store keys in SharedPreferences. |

### Crash Reporting & Monitoring (Opt-in, Privacy-First)

| Package | Free Tier | Symbols | Replay | Bundle Size | Decision |
|---|---|---|---|---|---|
| **Sentry** | 5K events/month | ✅ Dart plugin + ProGuard | ✅ Session Replay | ~200KB | **Selected.** Best Flutter support, privacy-compliant, debug symbols via Flutter plugin |
| Firebase Crashlytics | Unlimited | ✅ via Firebase | ❌ | ~2MB (includes Firebase core) | Avoid — too heavy, Google dependency |

**Sentry config for production:**
```dart
await SentryFlutter.init((options) {
  options.dsn = const String.fromEnvironment('SENTRY_DSN');
  options.environment = const String.fromEnvironment('ENV', defaultValue: 'prod');
  options.release = 'purenote@${packageInfo.version}+${packageInfo.buildNumber}';
  options.tracesSampleRate = kReleaseMode ? 0.1 : 1.0;  // 10% in prod, 100% dev
  options.replay.sessionSampleRate = 0.1;                // 10% of sessions
  options.replay.onErrorSampleRate = 1.0;                 // 100% of error sessions
}, appRunner: () => runApp(const ProviderScope(child: PurenoteApp())));
```

**Sentry debug symbols in CI (release builds):**
```bash
flutter build appbundle --release --obfuscate \
  --split-debug-info=build/debug-info
sentry-cli debug-files upload \
  --include-sources \
  --org purenote --project purenote-flutter \
  build/debug-info
```

### Background Work

| Package | Android API | iOS API | RAM/Task | Decision |
|---|---|---|---|---|
| **workmanager** | WorkManager | BGTaskScheduler | ~50-100MB (full Flutter engine) | **Selected** — simpler, well-documented for backup/reminder use cases |
| native_workmanager | WorkManager | BGTaskScheduler | ~2-5MB (native workers) | Rejected — overkill for our task set (no sync, no HTTP, no image processing) |

**Backup scheduling pattern:**
```dart
await Workmanager().registerPeriodicTask(
  'purenote-backup',
  'backupTask',
  frequency: const Duration(hours: 24),
  constraints: Constraints(
    networkType: NetworkType.not_required,  // local backup
    requiresBatteryNotLow: true,
    requiresStorageNotLow: true,
  ),
  existingWorkPolicy: ExistingWorkPolicy.keep,
);
```

### Testing

| Type | Tool | Scope |
|---|---|---|
| Unit | flutter_test | Models, services, DAOs (in-memory drift), parsers |
| Widget | flutter_test | NoteCard, TaskItemTile, every widget |
| Integration | integration_test | Full flows: create→edit→delete, backup→restore, lock→unlock |
| Golden | alchemist / flutter_test | UI snapshot regression for NoteCard variants |
| Fuzz | dart_fuzz | Random input to import parsers (Keep HTML, ENEX XML) |

### Version Pinning Strategy

All direct dependencies pinned to `^X.Y.Z` (compatible version with upper bound). Lockfile (`pubspec.lock`) committed to repo. `dart pub upgrade --major-versions` run explicitly per release cycle, not automatically.

---

## Import Format Analysis

### Google Keep

| Attribute | Detail |
|---|---|
| Export source | Google Takeout |
| Format | HTML files (one per note) + optional companion JSON for metadata |
| Content | Title (from `<meta>` or h1), body (HTML), tags, timestamps, pinned/archived/trashed flags |

**Parser approach (production concerns):**
1. Read all `.html` files from selected directory
2. Parse HTML title from `<title>` or `<h1>` tag
3. Parse body content from `<div>` with specific class or first `<p>` block
4. Look for companion `.json` file with same base name for metadata
5. Handle: files without valid HTML structure, missing timestamps, duplicate filenames
6. Convert extracted HTML body to Quill Delta (use `flutter_quill_delta_from_html` or custom converter)
7. **Malformed input protection:** Catch all parse exceptions per-file, continue processing remaining files
8. **Progress reporting:** Emit per-note progress events for UI
9. **Duplicate detection:** Compare SHA-256 of HTML content against existing notes

**Error scenarios to handle:**
- Directory contains non-Keep HTML files (skip gracefully)
- Filename truncated due to Google Takeout bug ('.' at end of title → no extension)
- Empty directory selected
- Permission denied reading files

### Evernote

| Attribute | Detail |
|---|---|
| Export source | Evernote desktop app |
| Format | ENEX (XML, `.enex` file) |
| Content | Title, content (ENML — XHTML-based), tags, `<resource>` (base64 encoded attachments), created/updated |

**Parser approach:**
1. Parse XML with `xml` package streaming parser (avoid loading entire file for large ENEX)
2. Extract per-note using `//note` XPath
3. Extract ENML from `<content>` CDATA
4. Convert ENML (XHTML) to Quill Delta — map `<en-bold>`, `<en-italic>`, `<en-strikethrough>`, etc.
5. Extract base64 resources, decode to files in app documents directory
6. Map `<tag>` elements to app labels
7. **Large file handling:** ENEX files can contain 100+ notes with attachments. Use streaming XML parse, decode resources on-the-fly, don't hold all in memory.

**Error scenarios:**
- Invalid XML / truncated ENEX file
- Base64 decode failures on corrupt attachments
- Notes without title (use "Imported from Evernote" fallback)

### Quillpad

| Attribute | Detail |
|---|---|
| Export source | Quillpad app |
| Format | JSON |
| Content | Title, content (HTML/Markdown/plain), tags, color, pinned, timestamps |

Simplest import — JSON parse, direct field mapping. Content may be HTML or Markdown. Detect format and convert to Quill Delta.

### Samsung Notes

**No direct import implemented.** `.sdocx` is a closed binary format within a ZIP. No open-source parser exists. The only export paths are:
- PDF (lossy — no metadata, no tags, no folder hierarchy)
- Microsoft Word (`.docx`) — partial fidelity, no tags
- Image (lossy — flat image, no text extraction)

**User-visible note in import screen:** "Samsung Notes is not directly supported. Export your notes as PDF or Word from Samsung Notes first."

---

## Performance Budgets

| Metric | Target | Measurement |
|---|---|---|
| Cold start (p50) | < 1.8s | Sentry TTID / Firebase Performance |
| Cold start (p95) | < 3.5s | Sentry TTID / Firebase Performance |
| Frame build (p99) | < 16ms | DevTools timeline |
| Frame raster (p99) | < 16ms | DevTools timeline |
| Crash-free sessions | > 99.7% | Sentry Release Health |
| ANR rate (Android) | < 0.4% | Play Console Vitals |
| App size (download, arm64) | < 35 MB | `flutter build --analyze-size` |
| Cold heap after first screen | < 80 MB | DevTools memory tab |
| Note list scroll (500+ notes) | 60fps sustained | DevTools performance overlay |
| Widget update latency | < 500ms | Custom trace |

---

## Security Model

| Threat | Mitigation |
|---|---|
| Unauthorized app access | Biometric/PIN lock. PIN hashed with PBKDF2 (100K iterations). Hash stored in `flutter_secure_storage` (Keystore/Keychain). |
| Note content exposure from DB dump | AES-256-CBC encryption of locked note content. Key derived from app PIN via PBKDF2. IV stored alongside ciphertext. |
| Backup file theft | Optional password-protected ZIP. Password hashed for verification, not stored as plaintext. |
| Side-channel via file attachments | Attachment files stored in app-private directory (Android `data/data/`). Not accessible via USB without root. |
| Memory dumps | `--obfuscate` + `--split-debug-info` in release builds. Sensitive data cleared from memory after use (zeroing byte arrays). |
| Clipboard leak | No automatic clipboard paste. User-triggered paste only. |

**Database encryption (future):** Starting with plaintext drift DB for simplicity. Produce a migration path to SQLCipher-encrypted database using drift's `sqlcipher_export()` mechanism:
1. Add `sqlite3_flutter_libs` with `SQLITE3_MCIPHER=true`
2. Open existing plaintext DB and encrypted DB simultaneously
3. Use `SELECT sqlcipher_export('encrypted')` to copy schema + data
4. Apply `user_version` pragma to encrypted DB (drift version tracking)
5. Delete old plaintext DB, rename encrypted DB to original path
6. Set `PRAGMA key = '...'` on all subsequent opens

---

## Build & Release Strategy

| Artifact | Command | Signing | Distribution |
|---|---|---|---|
| Debug APK | `flutter build apk --debug --target-platform android-arm64` | Debug keystore | Local testing, CI artifact |
| Release AAB | `flutter build appbundle --release --obfuscate --split-debug-info=build/app/outputs/symbols` | Upload keystore → Play App Signing | Internal / Closed / Production tracks |
| Release APK | `flutter build apk --release --obfuscate --split-debug-info=build/app/outputs/symbols --target-platform android-arm64` | Upload keystore | Direct download (F-Droid) |

**Play Store deployment checklist:**
- [ ] compileSdk = 35, targetSdk = 35 (mandatory as of Aug 2025)
- [ ] App bundle (AAB) only for Play Store
- [ ] Upload keystore + Play App Signing enabled
- [ ] Hosted privacy policy URL (GitHub Pages / website)
- [ ] Data Safety & Permissions Declaration completed
- [ ] Internal testing track before production
- [ ] Sentry + symbol upload configured in CI

**Release cadence:** Semantic versioning. Minor releases monthly, patches as needed. Beta track for feature validation before staged production rollout.

## App Size Budget

| Component | Budget |
|---|---|
| Flutter engine + framework | ~6 MB |
| flutter_quill | ~2 MB |
| drift + sqlite3 | ~1.5 MB |
| Sentry SDK | ~200 KB |
| Other packages | ~3 MB |
| **Subtotal (code)** | **~13 MB** |
| Assets (icons, templates) | ~2 MB |
| **Total download (arm64)** | **~15 MB target (< 35 MB hard limit)** |

---

## Dependency Constraint Conflicts (Known)

| Conflict | Resolution |
|---|---|
| `flutter_quill` depends on `url_launcher` | Shared dependency, version conflict resolved by dependency resolution |
| `drift` + `sqlite3` versions | Use `sqlite3_flutter_libs` with matching version constraint |
| `local_auth` Android API requirements | minSdk 24 (already our minimum) |
| `flutter_quill` requires Flutter 3.44+ (as of v11.5.1) | Our SDK constraint ^3.11.5 is already sufficient |

---

## Edge Cases from Production Flutter Notes Apps

1. **Database corruption:** drift DB can corrupt on crash during write. Mitigation: `PRAGMA journal_mode=WAL`, periodic integrity check (`PRAGMA integrity_check`), expose "Repair database" in settings.
2. **Large note lists (500+):** Virtual scrolling with `SliverList` / `ListView.builder`. Don't load all widgets at once. drift `.watch()` streams emit deltas efficiently.
3. **Large attachments (100MB+ video):** Don't try to load into memory. Stream file operations. Show thumbnail + file info in card, open externally for viewing.
4. **Quick successive saves:** Debounce auto-save (500ms). Cancel pending save when new one arrives.
5. **Concurrent edits:** Last-write-wins. drift handles this at transaction level. Show "conflict detected" snackbar if user-facing conflict.
6. **Widget state after app data wipe:** Widget should gracefully show "App not found" or "Configure widget" instead of crashing.
7. **Notification tap after note deleted:** Notification should detect missing note and show "This note has been deleted" instead of crashing.
8. **Background backup while app is open:** Skip backup if app is foregrounded (avoid file contention on drift DB). Use copy of DB file.
9. **Phone number links in silent mode:** `tel:` links should gracefully fail (no crash) if device can't make calls.
10. **App lock after reboot without biometric:** On first unlock after reboot, some biometric implementations require PIN fallback. Always provide PIN as fallback.
