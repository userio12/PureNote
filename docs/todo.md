# Todo — purenote Production Implementation Checklist

**Legend:** `[ ]` Not started  `[~]` In progress  `[x]` Complete

---

## Phase 0: Project & Infrastructure Setup

### Project Configuration
- [ ] Update `pubspec.yaml` with production dependency versions
  - [ ] `flutter_quill: ^11.5.1`
  - [ ] `flutter_riverpod: ^2.x`
  - [ ] `riverpod_annotation: ^2.x`
  - [ ] `riverpod_generator: ^2.x`
  - [ ] `drift: ^2.x` + `drift_dev: ^2.x`
  - [ ] `sqlite3_flutter_libs: ^0.x`
  - [ ] `go_router: ^14.x`
  - [ ] `local_auth: ^2.x`
  - [ ] `flutter_secure_storage: ^9.x`
  - [ ] `encrypt: ^5.x`
  - [ ] `flutter_local_notifications: ^18.x`
  - [ ] `file_picker: ^8.x`
  - [ ] `open_filex: ^4.x`
  - [ ] `share_plus: ^10.x`
  - [ ] `record: ^5.x`
  - [ ] `home_widget: ^0.9.x`
  - [ ] `url_launcher: ^6.x`
  - [ ] `path_provider: ^2.x`
  - [ ] `intl: ^0.19.x`
  - [ ] `sentry_flutter: ^9.x`
  - [ ] `workmanager: ^0.x`
  - [ ] `xml: ^6.x` (ENEX import parsing)
  - [ ] `uuid: ^4.x`
- [ ] Dev dependencies:
  - [ ] `flutter_test` (SDK)
  - [ ] `integration_test` (SDK)
  - [ ] `build_runner: ^2.x`
  - [ ] `drift_dev: ^2.x`
  - [ ] `riverpod_generator: ^2.x`
  - [ ] `mocktail: ^1.x`
- [ ] Run `flutter pub get` → verify resolve
- [ ] Create `build.yaml` for `build_runner` (drift + riverpod codegen)
- [ ] Run `dart run build_runner build` → verify zero errors
- [ ] Create `lib/` directory structure (mirror tree view)

### Android Native Configuration
- [ ] Update `android/app/build.gradle.kts`:
  - [ ] `compileSdk = 35`
  - [ ] `targetSdk = 35`
  - [ ] `minSdk = 24`
  - [ ] `ndkVersion = "27.0.12077973"`
  - [ ] `multiDexEnabled = true`
  - [ ] Release config: `minifyEnabled = true`, `proguardFiles`
- [ ] Review `AndroidManifest.xml` permissions:
  - [ ] `USE_BIOMETRIC`
  - [ ] `RECORD_AUDIO`
  - [ ] `POST_NOTIFICATIONS` (Android 13+)
  - [ ] `SCHEDULE_EXACT_ALARM` (reminders)
  - [ ] `RECEIVE_BOOT_COMPLETED` (workmanager)
  - [ ] `FOREGROUND_SERVICE` (backup)
  - [ ] `READ_EXTERNAL_STORAGE` / `READ_MEDIA_IMAGES` (file picker, Android 13+)
- [ ] Create `android/app/proguard-rules.pro`
- [ ] Verify `flutter analyze` passes (zero issues)
- [ ] Verify `flutter test` passes (default test)

### Build Verification
- [ ] `flutter build apk --debug --target-platform android-arm64` → success
- [ ] `flutter analyze` → zero issues
- [ ] App launches on emulator (default counter screen gone)
- [ ] Push initial commit with project skeleton

---

## Phase 1: Core — App Shell + Database

### App Shell
- [ ] `main.dart` — ProviderScope → SentryFlutter.init → runApp
- [ ] `lib/core/theme/app_theme.dart` — Material 3:
  - [ ] Light theme with dynamic color support
  - [ ] Dark theme with dynamic color support
  - [ ] `ThemeMode` provider derived from settings
  - [ ] Note color palette (12 colors) + WCAG AA verification
- [ ] `lib/core/routing/app_router.dart` — go_router:
  - [ ] `ShellRoute` with BottomNavigationBar
  - [ ] `/` → NotesListScreen
  - [ ] `/tasks` → TaskListsScreen
  - [ ] `/settings` → SettingsScreen
  - [ ] `/note/new` → NoteEditorScreen
  - [ ] `/note/:id` → NoteEditorScreen (edit)
  - [ ] `/note/:id/view` → NoteViewerScreen
  - [ ] `/task-list/new` → TaskListEditorScreen
  - [ ] `/task-list/:id` → TaskListEditorScreen
  - [ ] `/search` → SearchScreen
  - [ ] `/audio/record` → AudioRecorderScreen
  - [ ] `/labels` → LabelsManagementScreen
  - [ ] `/backup` → BackupScreen
  - [ ] `/import` → ImportScreen
  - [ ] Deep link handling (widget note tap)
- [ ] `AppScaffold` widget:
  - [ ] BottomNavigationBar (Notes / Tasks / Settings)
  - [ ] IndexedStack per tab (preserves scroll state)
  - [ ] Active tab icon tinted with primary color
  - [ ] Double-tap tab → scroll to top

### Database (drift)
- [ ] `lib/core/database/connection.dart`:
  - [ ] `NativeDatabase.createInBackground` with WAL mode
  - [ ] `PRAGMA foreign_keys=ON` in `beforeOpen`
  - [ ] Debug mode: `PRAGMA foreign_key_check` assertion
- [ ] `lib/core/database/database.dart` — Full schema:
  - [ ] `notes` table (all columns as specified in planning.md)
  - [ ] `labels` table
  - [ ] `note_labels` junction table with composite PK
  - [ ] `attachments` table with FK to notes (ON DELETE CASCADE)
  - [ ] `task_items` table with self-ref FK for subtasks
  - [ ] `settings` table (key-value)
  - [ ] `backup_log` table
- [ ] DAOs:
  - [ ] `NoteDao` — insert, update, delete, watchAll, watchById, watchPinned, watchByLabel, search
  - [ ] `LabelDao` — insert, update, delete, watchAll
  - [ ] `TaskDao` — insert, update, delete, watchByNoteId
  - [ ] `AttachmentDao` — insert, delete, watchByNoteId
  - [ ] `SettingsDao` — get/set string values
- [ ] `build_runner build` → verify generated code
- [ ] **Test:** `note_dao_test.dart` — CRUD + stream emits
- [ ] **Test:** `label_dao_test.dart` — CRUD + cascade
- [ ] **Test:** `task_dao_test.dart` — CRUD + ordering

### Theme & Settings Providers
- [ ] `SettingsDao` backed `@riverpod Notifier` for `AppSettings`
  - [ ] Persisted with migration-safe defaults
  - [ ] Reactive — widgets `.watch()` individual fields via `select()`

### Error Handling Foundation
- [ ] `Result<T>` sealed class (`Ok` / `Err`)
- [ ] `AppError` sealed class with `userMessage`
- [ ] `ErrorLogger` — structured logging to debug console + file in debug mode
- [ ] `GlobalErrorHandler` — `FlutterError.onError` + `PlatformDispatcher.onError` → Sentry capture
- [ ] `ErrorBoundary` widget — catches build exceptions per screen
- [ ] **Test:** `result_test.dart` — pattern matching + fold

---

## Phase 2: Notes MVP (Rich Text CRUD)

### Note List Screen
- [ ] `NotesListScreen` with skeleton shimmer loading
- [ ] `NoteCard` (grid mode) + `NoteTile` (list mode)
  - [ ] Color background from note.color
  - [ ] Title (max 2 lines, bold)
  - [ ] Preview (max 3 lines, strip Quill Delta to plaintext)
  - [ ] Relative date: "Today", "Yesterday", "May 28"
  - [ ] Pin indicator icon
  - [ ] Lock indicator icon
  - [ ] Attachment count icon
  - [ ] Label chips (max 2 visible, overflow "+N")
- [ ] Label filter chip row (horizontal scrollable)
- [ ] View toggle (List ↔ Grid) — animated cross-fade
- [ ] Sort dropdown → `NoteListNotifier` updates
- [ ] Pinned section (visual separator from unpinned)
- [ ] Long-press multi-select mode:
  - [ ] Selection checkboxes on cards
  - [ ] App bar: [Cancel] N selected [Pin] [Label] [Delete]
  - [ ] Bulk pin/unpin
  - [ ] Bulk label assignment
  - [ ] Bulk delete with confirmation
- [ ] Swipe-to-delete with "Undo" snackbar (5s timer)
- [ ] Swipe-to-pin with haptic feedback
- [ ] Empty state (no notes)
- [ ] Empty state (filtered with no match)
- [ ] Error state with retry banner
- [ ] **Test:** `note_card_test.dart` — golden test variants (pinned, locked, with label, etc.)
- [ ] **Test:** `notes_list_screen_test.dart` — empty, populated, filtered
- [ ] **Test:** `notes_provider_test.dart` — stream emits on insert/update/delete

### Note Editor Screen
- [ ] Title field (plain text, auto-focus on new note)
- [ ] `flutter_quill` `QuillEditor` + `QuillController`
- [ ] Toolbar: Bold, Italic, Monospace, Strikethrough, H1/H2/H3, Quote, Code block, Checklist, Bullet list, Numbered list
- [ ] Toolbar: Attach, Image, Audio, Link, Color, Label, Reminder, Undo, Redo
- [ ] Auto-save with 800ms debounce
- [ ] Auto-save on: content change (debounced), app lifecycle, back navigation
- [ ] "Saving..." / "Saved" / "Unsaved changes" footer indicator
- [ ] Back navigation with unsaved changes → confirmation dialog
- [ ] Draft recovery: auto-save content in temp file, check on next editor open
- [ ] Color picker bottom sheet (12 colors)
- [ ] Label picker bottom sheet (checkboxes + create new)
- [ ] Attachment list (inline chips, swipe to remove)
- [ ] Reminder picker bottom sheet (date + time)
- [ ] Link insert dialog (URL/phone/email auto-detect)
- [ ] Lock toggle (prompts for setup on first use)
- [ ] Share button → system share sheet with plain text
- [ ] Locked note: biometric/PIN prompt before opening
- [ ] **Test:** `editor_provider_test.dart` — dirty state, save trigger
- [ ] **Test:** `note_editor_screen_test.dart` — create, edit, save, undo/redo

### Note Viewer Screen
- [ ] Read-only `QuillEditor` display
- [ ] Clickable links (URL, phone, email) via `url_launcher`
- [ ] Attachment list with tap-to-open
- [ ] Color, labels, reminder metadata display
- [ ] Edit button → push editor
- [ ] Share / Delete / Lock actions in app bar

---

## Phase 3: Task Lists

- [ ] `TaskListsScreen` with progress indicator per card
- [ ] `TaskListEditorScreen`:
  - [ ] Title field
  - [ ] ReorderableListView for task items
  - [ ] Each item: checkbox + rich text content (QuillEditor inline) + drag handle + delete
  - [ ] Subtask support: parentId FK, indented display, collapsible
  - [ ] "Add item" at bottom
- [ ] Auto-sort checked items to bottom (animated slide) — ON by default
- [ ] "Remove all checked" button (at card bottom, only visible when checked items exist)
- [ ] Auto-sort toggle in task list footer
- [ ] Color, labels, pin — same architecture as notes
- [ ] **Test:** `task_item_tile_test.dart` — check toggle, subtask indent
- [ ] **Test:** `task_list_editor_screen_test.dart` — add, check, reorder
- [ ] **Test:** `task_sort_notifier_test.dart` — auto-sort logic

---

## Phase 4: Attachments & Audio

### File Attachments
- [ ] `file_picker` integration:
  - [ ] Pick images from gallery
  - [ ] Pick any file from storage
  - [ ] Take photo with camera
- [ ] Copy file to `app_docs/attachments/` (UUID-based filename to avoid collisions)
- [ ] Store metadata in `attachments` table
- [ ] Display as inline chips in editor (icon + filename + size + remove)
- [ ] Tap to open (preview image internally, others via `open_filex`)
- [ ] Swipe to remove (delete file from disk + DB row)
- [ ] Large file warning (>50MB) before attaching
- [ ] Orphan cleanup: on app start, scan for files in table that don't exist on disk

### Audio Notes
- [ ] `record` package integration
- [ ] `AudioRecorderScreen`:
  - [ ] Record (start/stop) with permission request
  - [ ] Real-time waveform visualization (amplitude samples)
  - [ ] Duration counter
  - [ ] Playback preview (play/pause + seek bar)
  - [ ] Save → creates audio attachment on current note
  - [ ] Discard → confirmation dialog
  - [ ] Interruption handling (call received → pause, resume option)
- [ ] Audio playback in note viewer (play/pause + seek + duration)
- [ ] Audio note indicator in note list (🎤 icon + duration badge)

---

## Phase 5: Reminders & Notifications

- [ ] `flutter_local_notifications` initialization:
  - [ ] Android notification channel: "Reminders" (high importance)
  - [ ] Notification tap handler → opens specific note (route `/note/:id/view`)
- [ ] Reminder picker in editor (date + time + "Remove")
- [ ] Schedule notification on note save (if reminder set)
- [ ] Cancel notification when reminder removed or note deleted
- [ ] Boot receiver: reschedule all pending reminders via `workmanager`
- [ ] Handle: notification tap after note deleted → snackbar "This note was deleted"
- [ ] **Test:** notification_service_test.dart — schedule, cancel, getPending

---

## Phase 6: Lock & Security

### App-Level Lock
- [ ] `local_auth` integration (biometric)
- [ ] PIN setup screen (6-digit PIN, confirm)
  - [ ] PIN hashed with PBKDF2 (100K iterations)
  - [ ] Hash stored in `flutter_secure_storage`
- [ ] PIN entry screen (6-digit input, biometric fallback button)
- [ ] App lock flow:
  - [ ] On app resume → check auto-lock timer → show lock screen
  - [ ] Successful unlock → navigate to previous screen
  - [ ] 3 wrong PIN attempts → 30s lockout with countdown timer
- [ ] Auto-lock timer: Immediate / 30s / 1min / 5min / Never
- [ ] Graceful degradation: no biometric hardware → PIN only

### Note-Level Lock
- [x] AES-256-CBC encryption for locked note content
  - [x] Key derived from app PIN via PBKDF2 (separate from auth key)
  - [x] Random IV per note (stored alongside ciphertext)
  - [x] Encrypt Quill Delta JSON before storing in `notes.content`
  - [x] Decrypt on read
- [x] Lock/unlock toggle in editor (locks after save, unlocks on open)
- [x] Lock icon on note card
- [x] Preview hidden for locked notes in list (show "🔒 Locked note" + date only)
- [ ] **Test:** encryption_service_test.dart — encrypt→decrypt roundtrip, wrong key rejection

---

## Phase 7: Search

- [x] Search bar in app bar (home + tasks tabs)
- [x] `SearchScreen`:
  - [x] Debounced search field (300ms)
  - [x] Recent searches list (persisted, max 10)
  - [x] Clear recent search (individual + clear all)
- [x] Search implementation:
  - [x] Phase 7a: `LIKE '%query%'` on title + content (simple, works everywhere)
  - [ ] Phase 7b: FTS5 virtual table for full-text search (advanced, better relevance)
- [x] Search result tiles with highlighted keyword matches
- [x] Tap result → push note viewer
- [ ] **Test:** search_provider_test.dart — debounce, results stream
- [ ] **Test:** search_screen_test.dart — recent, results, empty

---

## Phase 8: Home Screen Widget

- [x] `home_widget` setup for Android:
  - [x] Widget info XML (`android/app/src/main/res/xml/widget_info.xml`)
  - [x] Widget provider class (Kotlin)
  - [x] Widget layout (RemoteViews)
- [x] Configuration (in settings or widget setup):
  - [ ] Source: pinned notes / specific label
  - [ ] Max items: 3/5/10
  - [ ] Theme: match app theme / light always / dark always
- [x] Widget data pipeline:
  - [x] On app start: refresh widget data
  - [x] Call `HomeWidget.updateWidget()` via WidgetService
  - [ ] Auto-refresh on note change (debounced)
- [x] Widget tap → opens app
- [ ] Widget after reboot → background callback refreshes data
- [ ] Widget after app data reset → show "Configure widget"

---

## Phase 9: Labels Management

- [x] `LabelsManagementScreen`:
  - [x] List of labels with color indicator
  - [x] Rename (tap → inline edit)
  - [ ] Reorder (drag handle)
  - [x] Delete (with confirmation: "Delete label? Notes with this label will be unlabeled.")
  - [x] Create new label (dialog: name + color picker)
- [x] Cascade behavior: deleting label removes `note_labels` rows (notes preserved)
- [x] Label picker bottom sheet in note editor
- [x] Label chip display in NoteCard (pass labels as prop)
- [x] `/labels` route + navigation from Settings
- [ ] Label filter chip row in NotesListScreen
- [ ] **Test:** label_dao_test.dart — delete cascade, rename

---

## Phase 10: Backup & Restore

- [x] `backup_service.dart`:
  - [x] Dump drift DB to JSON (all tables)
  - [ ] Copy attachment files to temp
  - [x] Create ZIP archive with manifest
  - [x] Password-protected backup (AES-256 via `encrypt`) — optional
  - [x] Save to app backups directory
  - [x] Auto-prune old backups (keep last 5)
- [x] `Workmanager` integration:
  - [x] Register periodic task (24h)
  - [ ] Constraint: battery not low, storage not low
  - [ ] Skip if app in foreground (file contention)
  - [ ] Notification on failure with retry action
- [x] `BackupScreen` (or embedded in settings):
  - [x] Toggle auto-backup ON/OFF
  - [x] Interval: daily / weekly / monthly
  - [x] Include attachments toggle
  - [ ] Password protection toggle + password setup
  - [x] "Back up now" button
  - [x] "Restore from backup" button → file picker → preview → confirm
  - [x] Last backup info: date, size, status (via BackupLog)
- [x] Restore flow:
  - [x] Pick ZIP file
  - [ ] Validate ZIP integrity (CRC32 of each entry)
  - [x] Password prompt if protected
  - [x] Extract to temp directory
  - [ ] Validate drift DB (schema version check)
  - [ ] Save existing data as "pre-restore backup" (safety net)
  - [x] Swap temp data into app directories
  - [x] Show result: "X notes restored. Y files restored."
- [ ] **Test:** backup_service_test.dart — create ZIP, restore, password protect

---

## Phase 11: Import

### Google Keep
- [x] `KeepParser` service:
  - [x] Parse title, body (HTML), tags, timestamps
  - [ ] Handle: malformed HTML, missing timestamps, filename truncation bug
  - [x] Convert extracted HTML to Quill Delta
  - [ ] SHA-256 dedup against existing notes
- [ ] **Test:** `keep_parser_test.dart` — sample Keep HTML fixtures

### Evernote
- [x] `EvernoteParser` service:
  - [x] Extract title, ENML content, tags, created/updated
  - [ ] Extract `<resource>` base64 → decode → save as attachment
  - [x] Convert ENML (XHTML) to Quill Delta
- [ ] **Test:** `evernote_parser_test.dart` — sample ENEX XML fixtures

### Quillpad
- [x] `QuillpadParser` service:
  - [x] JSON decode
  - [x] Map fields directly to Note model
  - [x] Detect content format (HTML/MD/plain) → convert to Quill Delta
- [ ] **Test:** `quillpad_parser_test.dart` — sample JSON fixtures

### Import UI
- [x] `ImportScreen`:
  - [x] Source selection cards (Keep / Evernote / Quillpad)
  - [x] Per-file error handling (skip invalid files, continue)
  - [x] Progress bar with per-note count
  - [ ] Duplicate handling: skip (default) or import anyway (option)
  - [ ] Label mapping: auto-map by name, manual override per label
  - [x] Result summary: imported, skipped, failed counts
- [ ] **Test:** import_provider_test.dart — import state transitions
- [ ] **Integration test:** `import_keep_test.dart` — full flow

---

## Phase 12: Settings

- [x] View section: List/Grid toggle, Sort selector, Text size slider, Theme selector
- [x] Privacy section: Lock method, Auto-lock timer, Lock new notes default, Change PIN
- [x] Backup section: Auto-backup toggle, Interval, Include files, Password protect, Back up now, Restore
- [x] Import section: Source cards linking to ImportScreen
- [x] Data section: Repair database, Clear all data (double confirmation)
- [x] About section: Version, OSS licenses, Privacy policy link, Send feedback

---
## Phase 13: Production Hardening

### Performance
- [ ] Profile cold start: target < 1.8s p50, < 3.5s p95
- [ ] Profile frame build/raster: target < 16ms p99
- [ ] Profile memory: cold heap < 80MB
- [ ] Scroll performance: 500 notes at 60fps
- [x] Reduce widget rebuilds: `select()` on Riverpod providers
- [ ] Image thumbnails: generate on attachment for list display (not full-res)
- [x] Lazy load: `ListView.builder` everywhere, never `ListView(children: ...)` — confirmed all dynamic lists use builder
- [x] DB query optimization: indexes on `notes.updatedAt`, `notes.isPinned`, `note_labels.noteId`

### Security
- [x] Verify `--obfuscate` + `--split-debug-info` in release build — confirmed `app-release.aab` (49.4MB) builds
- [ ] Verify ProGuard rules don't strip required classes
- [ ] Verify `flutter_secure_storage` uses Keystore (not fallback to SharedPreferences)
- [ ] Verify encryption keys zeroed from memory after use
- [ ] Verify backup ZIP password uses AES-256 (not ZIP 2.0 legacy encryption)
- [x] Verify no secrets in source code (Sentry DSN via `--dart-define`)

### Crash Reporting
- [x] Sentry Flutter init with opt-in (user consent on first launch)
- [ ] Upload debug symbols from CI for symbolicated stack traces
- [ ] Verify breadcrumbs: user actions (create note, delete, lock, etc.)
- [ ] Verify release health: crash-free rate tracking

### CI/CD Pipeline
- [x] `.github/workflows/flutter-release.yml`:
- [x] Trigger: tag push (`v*`)
- [x] `flutter analyze` → fail on issues
- [x] `flutter test` → fail on failures
- [x] `flutter build appbundle --release --obfuscate --split-debug-info=...`
- [x] Upload AAB as artifact
- [x] Upload Debug Symbols as artifact
- [ ] Deploy to Play Console (via `actions/upload-google-play` or manual)

### Play Store Preparation
- [ ] Generate upload keystore (NOT committed)
- [ ] Configure Play App Signing
- [ ] Privacy policy URL (hosted on GitHub Pages)
- [ ] Complete Data Safety section in Play Console
- [ ] Complete Permissions Declaration
- [ ] Add screenshots (phone + tablet)
- [ ] Feature graphic + icon assets
- [ ] Create Internal Testing track

### Database Integrity
- [x] `PRAGMA journal_mode=WAL` (crash recovery)
- [x] `PRAGMA foreign_keys=ON` (referential integrity)
- [x] Debug mode: `PRAGMA foreign_key_check` on open (catch violations early)
- [x] Settings screen: "Repair database" option with `PRAGMA integrity_check`
- [ ] If failed: dump salvageable data, create new DB, re-insert
- [ ] Export old DB as backup before repair attempt

### Edge Case Handling
- [x] Orphan attachment cleanup (app start scan)
- [x] Backup file cleanup (keep last 5)
- [x] Temp directory clear on app start
- [x] Quick successive saves (debounce + cancel pending)
- [ ] Database lock contention during backup (copy DB before zipping)
- [ ] Widget state after data wipe (show "Open app" gracefully)
- [ ] Notification tap after note deleted (snackbar, no crash)
- [ ] Large ENEX import in isolate (don't block UI)
- [ ] Audio interruption (call → pause → resume)

---

## Phase 14: Testing Completion

### Unit Tests
- [x] All DAOs tested with in-memory drift (NoteDao, LabelDao, TaskDao, AttachmentDao)
- [x] Encryption service: encrypt→decrypt roundtrip
- [ ] Backup service: create→restore→verify
- [x] Import parsers: Keep, ENEX, Quillpad fixtures
- [x] HTML→Quill Delta converter
- [x] Settings provider: read/write/update (AppSettings model)
- [x] Lock provider: state transitions (lockStateProvider)
- [x] Delta utils: stripQuillDelta with embeds, attributes, plain text, edge cases
- [x] Empty state widget: title, subtitle, icon, action button

### Widget Tests
- [x] NoteCard — title, preview, locked, pinned, labels, overflow count, untitled, skeleton
- [x] Label chip — name, selected, color, onTap
- [x] Empty state widget — icon, title, subtitle, action

### Final Gate
- [x] `flutter analyze` — zero issues
- [x] `flutter test` — all 79 tests pass
- [ ] Manual smoke test on physical device (Android 14+)
- [ ] Performance profile: cold start < 2s, scrolling 60fps
- [ ] Accessibility scan: TalkBack through all screens

---

## Phase 15: Release (v1.0)

- [ ] Version bump: `pubspec.yaml` → 1.0.0
- [ ] Update `CHANGELOG.md`
- [ ] Update `README.md` with features + screenshots
- [ ] Tag `v1.0.0` in git
- [ ] Build release AAB: `flutter build appbundle --release --obfuscate --split-debug-info=build/app/outputs/symbols`
- [ ] Upload to Play Console Internal Testing
- [ ] Internal testing: 5 testers for 48h

---

## Phase 15: Release (v1.0)

- [ ] Version bump: `pubspec.yaml` → 1.0.0
- [ ] Update `CHANGELOG.md`
- [ ] Update `README.md` with features + screenshots
- [ ] Tag `v1.0.0` in git
- [ ] Build release AAB: `flutter build appbundle --release --obfuscate --split-debug-info=build/app/outputs/symbols`
- [ ] Upload to Play Console Internal Testing
- [ ] Internal testing: 5 testers for 48h
- [ ] Monitor Sentry crash-free rate (target > 99.7%)
- [ ] Promote to Closed Testing (20% staged rollout)
- [ ] Monitor 24h crash-free + ANR rate
- [ ] Promote to Production (1% → 10% → 100% over 48h)
- [ ] Post-release: monitor first week crash-free sessions
