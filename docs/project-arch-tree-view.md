# Project Architecture — Tree View (Production)

```
purenote/
│
├── android/
│   ├── app/
│   │   ├── build.gradle.kts           # compileSdk 35, targetSdk 35, minSdk 24
│   │   ├── proguard-rules.pro         # Obfuscation keep rules
│   │   └── src/main/
│   │       ├── AndroidManifest.xml     # Permissions (BIOMETRIC, RECORD_AUDIO, POST_NOTIFICATIONS, BOOT_COMPLETED, SCHEDULE_EXACT_ALARM, FOREGROUND_SERVICE)
│   │       ├── kotlin/com/purenote/app/
│   │       │   ├── MainActivity.kt
│   │       │   └── BackgroundWorker.kt  # workmanager Dart callback handler
│   │       └── res/
│   │           ├── drawable/           # Adaptive icon foreground
│   │           ├── mipmap-*/           # Launcher icons
│   │           └── xml/
│   │               └── widget_info.xml # Android home screen widget definition
│   ├── gradle.properties
│   └── keystore/                      # NOT COMMITTED — CI injects via env
│       └── .gitkeep
│
├── ios/                               # Flutter iOS shell (stretch goal)
│
├── assets/
│   ├── icons/
│   │   ├── app_icon_foreground.png    # Adaptive icon foreground
│   │   └── app_icon_background.png    # Adaptive icon background
│   ├── templates/                     # Page templates (v2+)
│   │   └── .gitkeep
│   └── fonts/                         # If custom fonts needed
│       └── .gitkeep
│
├── lib/
│   ├── main.dart                      # Entry: ProviderScope → SentryFlutter.init → runApp
│   │
│   ├── core/
│   │   ├── database/
│   │   │   ├── database.dart          # @DriftDatabase: notes, labels, note_labels, attachments, task_items, settings, backup_log
│   │   │   ├── database.g.dart        # Generated (ignored)
│   │   │   ├── connection.dart        # NativeDatabase.createInBackground with WAL + foreign_keys
│   │   │   └── daos/
│   │   │       ├── note_dao.dart      # CRUD + watchAll + search + watchByLabel + watchPinned
│   │   │       ├── label_dao.dart     # CRUD + watchAll
│   │   │       ├── task_dao.dart      # CRUD + watchByNoteId
│   │   │       ├── attachment_dao.dart # CRUD by noteId
│   │   │       └── settings_dao.dart  # get/set key-value pairs
│   │   │
│   │   ├── theme/
│   │   │   ├── app_theme.dart         # Material 3 light/dark seed from settings or dynamic color
│   │   │   ├── app_colors.dart        # Palette constants + color mapping for note colors
│   │   │   └── app_typography.dart    # Text styles with text scale factor support
│   │   │
│   │   ├── routing/
│   │   │   └── app_router.dart        # go_router with ShellRoute for bottom nav, deep links
│   │   │
│   │   ├── services/
│   │   │   ├── encryption_service.dart    # AES-256-CBC + PBKDF2 key derivation + flutter_secure_storage
│   │   │   ├── backup_service.dart        # Create/restore backup ZIPs, password protection, schedule via workmanager
│   │   │   ├── notification_service.dart  # flutter_local_notifications init, schedule, cancel, tap handler
│   │   │   ├── audio_service.dart         # Record audio (record package), playback control
│   │   │   ├── import_service.dart        # Orchestrate Keep/ENEX/Quillpad imports with progress stream
│   │   │   └── widget_service.dart        # HomeWidget data sync + update broadcast
│   │   │
│   │   ├── providers/
│   │   │   ├── database_provider.dart     # Singleton AppDatabase
│   │   │   ├── settings_provider.dart     # @riverpod Notifier for AppSettings (persisted)
│   │   │   ├── lock_provider.dart         # @riverpod Notifier: app lock state (locked/unlocked)
│   │   │   └── theme_provider.dart        # @riverpod: current ThemeData derived from settings
│   │   │
│   │   ├── error/
│   │   │   ├── result.dart               # Result<T> sealed class (Ok / Err)
│   │   │   ├── app_error.dart            # Sealed AppError types with userMessage
│   │   │   ├── error_logger.dart         # Structured logging: debug/file + Sentry
│   │   │   ├── error_boundary.dart       # Widget-level error boundary (catches build exceptions)
│   │   │   └── global_error_handler.dart  # FlutterError.onError + PlatformDispatcher.onError → Sentry
│   │   │
│   │   └── utils/
│   │       ├── date_formatter.dart       # Relative dates: Today, Yesterday, May 28, etc.
│   │       ├── color_utils.dart          # ARGB int ↔ Color, brightness, mapping utilities
│   │       ├── link_detector.dart        # URL/phone/email regex detection + clickable text span builder
│   │       ├── file_utils.dart           # File size formatting, MIME type detection, thumbnail generation
│   │       ├── debounce.dart             # Debounce utility for auto-save
│   │       └── platform_utils.dart       # Platform checks, Android version detection
│   │
│   ├── features/
│   │   ├── notes/
│   │   │   ├── providers/
│   │   │   │   ├── notes_provider.dart        # @riverpod: Stream<List<Note>> with sort/filter applied
│   │   │   │   ├── note_provider.dart         # @riverpod.family: single Note by ID
│   │   │   │   ├── note_list_notifier.dart    # @riverpod: sort order, view mode, active label filter
│   │   │   │   └── recent_notes_provider.dart # @riverpod: last 5 modified notes for widget
│   │   │   ├── screens/
│   │   │   │   ├── notes_list_screen.dart     # Main screen: app bar + label chips + sliver grid/list
│   │   │   │   └── note_viewer_screen.dart    # Read-only Quill view + attachment list + actions
│   │   │   └── widgets/
│   │   │       ├── note_card.dart             # Grid card: color bg, title, preview, date, indicators
│   │   │       ├── note_tile.dart             # List tile: same info, horizontal layout
│   │   │       ├── note_color_picker.dart     # Horizontal scrollable color circles
│   │   │       ├── pinned_section.dart        # "Pinned" section header + animated list
│   │   │       └── empty_notes_placeholder.dart # Illustration + message + CTA
│   │   │
│   │   ├── editor/
│   │   │   ├── providers/
│   │   │   │   ├── editor_provider.dart       # @riverpod: edit state (isDirty, isNew, original content hash)
│   │   │   │   └── quill_controller_provider.dart # @riverpod.family: per-note QuillController
│   │   │   ├── screens/
│   │   │   │   └── note_editor_screen.dart    # Title field + QuillEditor + QuillToolbar + metadata footer
│   │   │   └── widgets/
│   │   │       ├── rich_text_toolbar.dart      # B/I/M/S toolbar + heading/quote/code/indent
│   │   │       ├── attach_file_button.dart     # File picker bottom sheet (gallery/camera/file/audio)
│   │   │       ├── reminder_picker.dart        # Date + time picker bottom sheet
│   │   │       ├── link_insert_dialog.dart     # URL text field with auto-detect (phone/email)
│   │   │       ├── auto_save_indicator.dart    # "Saving..." / "Saved" / "Unsaved changes" indicator
│   │   │       └── attachment_list.dart        # Inline attachment chips with remove button
│   │   │
│   │   ├── tasks/
│   │   │   ├── providers/
│   │   │   │   ├── task_lists_provider.dart    # @riverpod: Stream<List<Note>> filtered by type=taskList
│   │   │   │   ├── task_list_provider.dart     # @riverpod.family: single task list + task items
│   │   │   │   └── task_sort_notifier.dart     # @riverpod: auto-sort checked to bottom toggle
│   │   │   ├── screens/
│   │   │   │   ├── task_lists_screen.dart      # Grid of task list cards (title + progress bar)
│   │   │   │   └── task_list_editor_screen.dart # Title + reorderable task items + subtasks
│   │   │   └── widgets/
│   │   │       ├── task_item_tile.dart         # Checkbox + rich text content + drag handle
│   │   │       ├── subtask_list.dart           # Indented nested task items
│   │   │       ├── task_checkbox.dart          # Animated checkbox with dim effect on check
│   │   │       ├── auto_sort_banner.dart       # "3 checked items — Remove all" banner
│   │   │       └── task_progress_bar.dart      # Visual progress indicator (checked/total)
│   │   │
│   │   ├── audio/
│   │   │   ├── providers/
│   │   │   │   └── audio_recorder_provider.dart # @riverpod: recording state, duration, file path
│   │   │   ├── screens/
│   │   │   │   └── audio_recorder_screen.dart   # Record/stop/playback/discard/save
│   │   │   └── widgets/
│   │   │       ├── recording_waveform.dart     # Real-time waveform visualization
│   │   │       ├── playback_controls.dart      # Play/pause + seek bar + duration
│   │   │       └── audio_note_list_tile.dart   # Audio note card (waveform thumbnail + duration)
│   │   │
│   │   ├── labels/
│   │   │   ├── providers/
│   │   │   │   ├── labels_provider.dart        # @riverpod: Stream<List<Label>>
│   │   │   │   └── label_filter_provider.dart  # @riverpod: active label filter
│   │   │   ├── screens/
│   │   │   │   └── labels_management_screen.dart # List of labels with edit/delete/reorder
│   │   │   └── widgets/
│   │   │       ├── label_chip.dart             # Colored chip (tappable, removable)
│   │   │       ├── label_picker_dialog.dart    # Bottom sheet with checkboxes + create new
│   │   │       └── label_edit_tile.dart        # List tile with color picker + rename
│   │   │
│   │   ├── search/
│   │   │   ├── providers/
│   │   │   │   ├── search_provider.dart        # @riverpod: search query + debounced results
│   │   │   │   └── recent_searches_provider.dart # @riverpod: last 10 searches persisted
│   │   │   ├── screens/
│   │   │   │   └── search_screen.dart          # Search bar + recent searches + results list
│   │   │   └── widgets/
│   │   │       ├── search_result_tile.dart     # Note card with highlighted match
│   │   │       └── search_highlight.dart       # RichText with highlighted span
│   │   │
│   │   ├── settings/
│   │   │   ├── providers/
│   │   │   │   └── settings_provider.dart      # @riverpod Notifier: read/write settings DB
│   │   │   ├── screens/
│   │   │   │   └── settings_screen.dart        # Grouped sections: View, Privacy, Backup, Import, About
│   │   │   └── widgets/
│   │   │       ├── view_mode_toggle.dart       # List/Grid radio
│   │   │       ├── sort_selector.dart          # Dropdown: title/created/modified + asc/desc
│   │   │       ├── lock_settings.dart          # Biometric/PIN setup/change/disable
│   │   │       ├── text_size_slider.dart       # Slider with preview text
│   │   │       ├── theme_selector.dart         # Light/Dark/System radio
│   │   │       ├── backup_settings_section.dart # Auto-backup toggle + interval + last backup
│   │   │       └── import_section.dart         # Source list: Keep/Evernote/Quillpad
│   │   │
│   │   ├── backup/
│   │   │   ├── providers/
│   │   │   │   └── backup_provider.dart        # @riverpod: backup config, status, trigger backup
│   │   │   ├── screens/
│   │   │   │   └── backup_screen.dart          # Backup/restore UI (or embedded in settings)
│   │   │   └── widgets/
│   │   │       ├── backup_status_card.dart     # Last backup time + file size + status icon
│   │   │       └── backup_schedule_picker.dart  # Daily/weekly/monthly radio
│   │   │
│   │   └── import/
│   │       ├── providers/
│   │       │   └── import_provider.dart        # @riverpod: import state (idle/processing/done/error)
│   │       ├── screens/
│   │       │   └── import_screen.dart          # Source selection → file picker → progress → mapping
│   │       ├── services/
│   │       │   ├── keep_parser.dart            # Google Keep HTML parser
│   │       │   ├── evernote_parser.dart        # ENEX XML streaming parser
│   │       │   ├── quillpad_parser.dart        # Quillpad JSON parser
│   │       │   └── html_to_delta_converter.dart # Shared HTML→Quill Delta conversion
│   │       └── widgets/
│   │           ├── import_source_card.dart     # Source type card with icon + description
│   │           ├── import_progress_bar.dart     # Per-note progress + overall count
│   │           └── import_mapping_dialog.dart   # Label mapping UI
│   │
│   └── widgets/                                # Shared app-wide widgets
│       ├── app_scaffold.dart                   # BottomNavigationBar + IndexedStack per tab
│       ├── confirm_dialog.dart                 # Generic confirmation dialog
│       ├── loading_overlay.dart                # Full-screen loading with message
│       ├── error_banner.dart                   # Inline error with retry button
│       ├── empty_state.dart                    # Generic empty state (icon + message + action)
│       └── snackbar_utils.dart                  # Success/error snackbar helpers
│
├── test/
│   ├── core/
│   │   ├── database/
│   │   │   ├── note_dao_test.dart              # CRUD + search + watch + label filter
│   │   │   ├── label_dao_test.dart             # CRUD + cascade delete behavior
│   │   │   ├── task_dao_test.dart              # CRUD + subtask ordering
│   │   │   ├── migrations_test.dart             # Schema v1→v2 data preservation
│   │   │   └── database_integrity_test.dart    # WAL, foreign_keys, FTS5 setup
│   │   ├── services/
│   │   │   ├── encryption_service_test.dart    # Encrypt→decrypt roundtrip, key derivation
│   │   │   ├── backup_service_test.dart        # Create ZIP, restore, password protection
│   │   │   ├── notification_service_test.dart  # Schedule/cancel/getPending
│   │   │   └── audio_service_test.dart         # Record→file exists, playback controls
│   │   ├── providers/
│   │   │   ├── settings_provider_test.dart     # Read/write/update
│   │   │   └── lock_provider_test.dart         # Lock/unlock state transitions
│   │   └── error/
│   │       └── result_test.dart               # Ok/Err pattern matching
│   │
│   ├── features/
│   │   ├── editor/
│   │   │   ├── editor_provider_test.dart       # Dirty state, save trigger
│   │   │   └── note_editor_screen_test.dart    # Widget: create, edit, save, undo/redo
│   │   ├── notes/
│   │   │   ├── notes_provider_test.dart        # Stream emits on insert/update/delete
│   │   │   ├── note_list_notifier_test.dart    # Sort order, filter toggles
│   │   │   ├── note_card_test.dart             # Golden test for card variants
│   │   │   └── notes_list_screen_test.dart     # Widget: empty, populated, filtered states
│   │   ├── tasks/
│   │   │   ├── task_sort_notifier_test.dart    # Auto-sort logic
│   │   │   ├── task_item_tile_test.dart        # Checkbox toggle, subtask display
│   │   │   └── task_list_editor_screen_test.dart # Add, check, reorder, delete
│   │   ├── search/
│   │   │   ├── search_provider_test.dart       # Debounced query, results
│   │   │   └── search_screen_test.dart         # Widget: recent, results, empty
│   │   └── import/
│   │       ├── keep_parser_test.dart           # Sample Keep HTML → expected Note
│   │       ├── evernote_parser_test.dart       # Sample ENEX XML → expected Note
│   │       ├── quillpad_parser_test.dart       # Sample JSON → expected Note
│   │       └── html_to_delta_converter_test.dart # HTML → Quill Delta roundtrip
│   │
│   ├── widgets/
│   │   ├── app_scaffold_test.dart              # Bottom nav tab switches
│   │   ├── error_banner_test.dart             # Render + retry callback
│   │   └── empty_state_test.dart               # Render with custom message
│   │
│   └── integration/
│       ├── note_lifecycle_test.dart            # Create → edit → delete → verify gone
│       ├── task_list_flow_test.dart            # Create → add items → check → auto-sort
│       ├── lock_flow_test.dart                 # Set PIN → lock → background → resume → unlock
│       ├── backup_restore_test.dart            # Backup → delete data → restore → verify
│       ├── import_keep_test.dart               # Import sample Keep export → verify notes in DB
│       └── search_flow_test.dart               # Create notes → search → tap result
│
├── docs/                                       # Planning documents
│   ├── research.md
│   ├── planning.md
│   ├── project-arch-tree-view.md
│   ├── ui-ux.md
│   └── todo.md
│
├── .github/
│   └── workflows/
│       ├── flutter-debug-build.yml             # Current: build debug APK
│       └── flutter-release.yml                 # New: analyze → test → build AAB → deploy to Play Console
│
├── pubspec.yaml                                # Dependencies (pinned)
├── analysis_options.yaml                       # flutter_lints (defaults, no custom rules)
├── build.yaml                                  # build_runner config for drift + riverpod codegen
├── AGENTS.md                                   # Agent instruction file
├── GEMINI.md                                   # Gemini CLI context
└── README.md                                   # Project README
```
