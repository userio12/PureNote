# UI/UX Design — purenote (Production Grade)

## Design Principles

1. **Minimal & Fast** — No splash screens, no onboarding, no fluff. Open → see notes.
2. **Content is king** — Cards show actual note content, not just titles or metadata.
3. **Offline-first by default** — Every pixel renders without network. Never show a loading spinner for data.
4. **Zero distraction** — No ads, no upsells, no analytics prompts, no "rate our app".
5. **Forgiving** — Every destructive action has undo. Every error shows a path forward.
6. **Accessible** — WCAG AA contrast, system font scaling, TalkBack labels on every tappable element.

## Theme

- **Material Design 3** with dynamic color support (Monet on Android 12+)
- Default seed color: Deep Purple (fallback when dynamic color unavailable)
- Three modes: Light, Dark, System
- Text size: Configurable slider (small → large) + respects system font scale
- Note colors: 12 predefined colors (saturated, accessible) + "no color" (uses theme surface)

## Navigation Architecture

```
                    ┌─────────────────────────┐
                    │       App Shell          │
                    │  BottomNavigationBar      │
                    │  [Notes][Tasks][Settings] │
                    └────────┬────────────────┘
                             │
              ┌──────────────┼──────────────┐
              ▼              ▼              ▼
     ┌────────────┐  ┌────────────┐  ┌────────────┐
     │  Notes     │  │  Tasks     │  │ Settings   │
     │  List      │  │  List      │  │ Screen     │
     └─────┬──────┘  └─────┬──────┘  └────────────┘
           │               │
           ▼               ▼
     ┌────────────┐  ┌────────────┐
     │  Note      │  │  Task List │
     │  Editor    │  │  Editor    │
     └────────────┘  └────────────┘

     Full-screen pushes (no nested stacks):
     • Note Editor → Note Viewer
     • Search Screen (from any tab)
     • Audio Recorder (from editor)
     • Labels Management (from settings or editor)
     • Backup Screen (from settings)
     • Import Screen (from settings)
```

## Screen Specifications

### 1. Notes List (Home Tab)

```
┌──────────────────────────────────────┐
│ Status Bar                           │
├──────────────────────────────────────┤
│ 🔍 Search notes...             ⋮ ⚙   │
│ Sort: Latest ▼         [list/grid] │
├──────────────────────────────────────┤
│                                      │
│ [Personal] [Work] [Ideas] [+ Edit]  │
│                                      │
│ ┌─ PINNED ──────────────────────────┐│
│ │ 📌 Note title                    ││
│ │   Preview line of content here... ││
│ │   Yesterday · Label              ││
│ │                                  ││
│ │ 📌 Another pinned note           ││
│ │   Another preview...             ││
│ │   May 28 · Label · 📎 2          ││
│ └──────────────────────────────────┘│
│                                      │
│ ┌─ ALL NOTES ───────────────────────┐│
│ │ Note title (no color = theme)    ││
│ │   Content preview here...        ││
│ │   May 27 · 🔒 Label              ││
│ │                                  ││
│ │ ┌────────────────────┐ ┌────────┐││
│ │ │ Short note         │ │ Note   │││
│ │ │ Quick preview      │ │ prev...│││
│ │ │ May 26             │ │ May 25 │││
│ │ └────────────────────┘ └────────┘││
│ └──────────────────────────────────┘│
│                                      │
│                              [+ FAB] │
└──────────────────────────────────────┘
```

**Interactions:**
- **FAB (+):** Creates new rich text note, pushes editor
- **Long-press card:** Enters multi-select mode (selection checkboxes appear, app bar shows bulk actions)
- **Swipe left:** Delete with "Undo" snackbar (5s timeout)
- **Swipe right:** Pin/unpin (haptic feedback)
- **Tap note:** Push to editor (or viewer if locked)
- **Tap label chip:** Filter by that label (chip becomes active/highlighted)
- **Tap pin icon (on card):** Toggle pin
- **View toggle (app bar):** Animate between List ↔ Staggered Grid
- **Sort dropdown:** Title A-Z, Title Z-A, Newest first, Oldest first, Last edited

**States:**
| State | UI |
|---|---|
| Loading | Skeleton shimmer (3-4 card outlines pulsing) |
| Empty (no notes) | Illustration + "No notes yet" + "Tap + to create your first note" |
| Empty (filtered) | "No notes match this filter" + "Clear filter" button |
| Error | Inline banner: "Could not load notes" + Retry button |
| Multi-select | App bar shows: [Cancel] N selected [Pin] [Label] [Delete] |

### 2. Note Editor

```
┌──────────────────────────────────────┐
│ ← Back         [🔒] [📤] [⋮ Save] │
├──────────────────────────────────────┤
│                                      │
│ Title (first line bold, placeholder) │
│                                      │
│ ┌─ Toolbar (scrollable) ───────────┐ │
│ │ B I M S H1 H2 H3 "  • 1. ` [ ] │ │
│ │ 🔗 📷 🎤 📎 🎨 🏷 ⏰ ↩ ↪      │ │
│ └──────────────────────────────────┘ │
│                                      │
│ ┌─ Content Area (QuillEditor) ─────┐ │
│ │                                   │ │
│ │ Rich text with formatting...      │ │
│ │                                   │ │
│ │ ——— Attachments ———               │ │
│ │ 📄 report.pdf              [×]   │ │
│ │ 🖼 screenshot.png          [×]   │ │
│ │ ———————————————                  │ │
│ │                                   │ │
│ └──────────────────────────────────┘ │
│                                      │
│ ┌─ Metadata Footer ─────────────────┐│
│ │ Color: ● ● ● ● ● ○ ○ ○ ○         ││
│ │ Labels: [Personal ✕] [+ add]     ││
│ │ Reminder: May 30, 9:00 AM  [✕]   ││
│ │ Locked: [OFF]                     ││
│ │ Auto-saved 2s ago                 ││
│ └──────────────────────────────────┘│
└──────────────────────────────────────┘
```

**Toolbar legend:**
| Button | Action | Notes |
|---|---|---|
| **B** | Bold | Toggle |
| *I* | Italic | Toggle |
| `M` | Monospace | Toggle |
| ~~S~~ | Strikethrough | Toggle |
| H1/H2/H3 | Heading levels | Toggle |
| " | Block quote | Toggle |
| • | Bullet list | Toggle |
| 1. | Numbered list | Toggle |
| ` ` | Code block | Toggle |
| [ ] | Checklist | Toggle task mode |
| 🔗 | Insert link | Dialog: URL/phone/email |
| 📷 | Add image | Bottom sheet: Gallery/Camera |
| 🎤 | Record audio | Pushes audio recorder screen |
| 📎 | Attach file | File picker |
| 🎨 | Color | Bottom sheet with color circles |
| 🏷 | Labels | Bottom sheet with label checkboxes |
| ⏰ | Reminder | Date + time picker |
| ↩ | Undo | |
| ↪ | Redo | |

**Auto-save behavior:**
- Triggers: on content change + 800ms debounce, on app lifecycle (pause/detach), on back navigation
- Indicator: subtle "Saved" text in footer (green) / "Saving..." (amber) / "Unsaved changes" (red)
- On back with unsaved changes: confirmation dialog "Discard changes?" with "Save & exit" / "Discard" / "Cancel"
- On crash during save: content recovered from auto-save draft in temp file (checked on next editor open)

**Attachment handling:**
- Files copied to app-private directory on attach (not moved — mobile users may pick from SD card then remove card)
- Attachment list shows: icon by MIME type, filename, file size
- Tap attachment: preview if image, open externally for other types
- Swipe attachment left: remove (file deleted from app dir)
- Large file warning (>50MB): confirm dialog before attaching

**States:**
| State | UI |
|---|---|
| Creating new | Empty title "Untitled", empty content, auto-save starts after first keystroke |
| Editing existing | Pre-filled, auto-save loads last draft or DB content (draft wins if newer) |
| Loading | Skeleton title + toolbar + editor area |
| Saving | "Saving..." in footer |
| Saved | "Saved" in footer (green checkmark) |
| Error saving | "Save failed — retry" banner (critical: data loss risk) |
| Locked | Lock icon in app bar, biometric/PIN prompt before opening |

### 3. Task Lists (Tasks Tab)

```
┌──────────────────────────────────────┐
│ 🔍 Search tasks...                   │
│ Sort: Latest ▼         [list/grid]   │
├──────────────────────────────────────┤
│                                      │
│ ┌────────────────────────────────────┐│
│ │ 📋 Grocery Shopping        3/8    ││
│ │ ○ Milk                            ││
│ │ ○ Eggs                            ││
│ │ ● Bread (dimmed)                  ││
│ │ ○ Butter                          ││
│ │ Yesterday · Label                 ││
│ └────────────────────────────────────┘│
│ ┌────────────────────────────────────┐│
│ │ 📋 Project Tasks           2/5    ││
│ │ ○ Write spec                      ││
│ │ ● Design review (dimmed)          ││
│ │ ○ Implement                       ││
│ │ May 26                            ││
│ └────────────────────────────────────┘│
│                                      │
│                              [+ FAB] │
└──────────────────────────────────────┘
```

**Auto-sort behavior:** When item checked, it animates (positional slide) to bottom of its list within the card. Checked items dim to 50% opacity. Banner at card bottom: "3 checked — Remove all".

**States:**
| State | UI |
|---|---|
| Empty (no task lists) | "No task lists yet" + "Create your first task list" |
| Empty (filtered) | "No task lists match this filter" |
| All tasks completed | Green "All done!" badge on card |

### 4. Task List Editor

```
┌──────────────────────────────────────┐
│ ← Back         Task List     [⋮]    │
├──────────────────────────────────────┤
│                                      │
│ Title: [Grocery Shopping]            │
│                                      │
│ ┌──────────────────────────────────┐│
│ │ ☰ ○ Buy milk               ✕   ││
│ │   ┌────────────────────────┐    ││
│ │   │ ☰ ○ Almond milk   ✕   │    ││
│ │   │ ☰ ● Oat milk      ✕   │    ││
│ │   │                  [+sub]│    ││
│ │   └────────────────────────┘    ││
│ │ ☰ ● Buy bread (dimmed)    ✕   ││
│ │ ☰ ○ Add item...                ││
│ └──────────────────────────────────┘│
│                                      │
│ Auto-sort checked to bottom: [ON]    │
│ [Remove all checked (3)]             │
│                                      │
│ 🎨 Color  📎 Files  ↩ Undo  ↪ Redo    │
└──────────────────────────────────────┘
```

### 5. Search Screen

```
┌──────────────────────────────────────┐
│ ← Back    🔍 [search query...]   [×] │
├──────────────────────────────────────┤
│                                      │
│ RECENT SEARCHES                      │
│ recipes                         [×]  │
│ project notes                   [×]  │
│                                      │
│ ── RESULTS (12) ──                   │
│                                      │
│ ┌────────────────────────────────────┐│
│ │ 📝 My Recipe Note                  ││
│ │ ...ingredients for ...**pasta**... ││
│ │ Yesterday                          ││
│ └────────────────────────────────────┘│
│ ┌────────────────────────────────────┐│
│ │ 📋 Shopping List                   ││
│ │ ○ Buy ...**pasta**...              ││
│ │ May 26                             ││
│ └────────────────────────────────────┘│
└──────────────────────────────────────┘
```

**States:**
| State | UI |
|---|---|
| Empty query | Show recent searches |
| Typing | Debounce 300ms, results appear |
| No results | "No notes match 'query'" |
| Error | "Search failed" + retry |

### 6. Settings Screen

```
┌──────────────────────────────────────┐
│ Settings                              │
├──────────────────────────────────────┤
│                                      │
│ VIEW                                  │
│ ○ View mode          ● List ○ Grid  │
│ ○ Sort by        [Last edited  ▼]   │
│ ○ Text size          [====●======]  │
│ ○ Theme           [System  ▼]       │
│                                      │
│ PRIVACY                              │
│ ○ App lock        [Biometric  ▼]    │
│   → Requires biometric hardware      │
│   → Fallback: 6-digit PIN            │
│ ○ Auto-lock       [After 1 min ▼]   │
│ ○ Lock new notes by default [OFF]    │
│ ○ Change PIN/Password                │
│                                      │
│ BACKUP                               │
│ ○ Auto backup                [ON]   │
│ ○ Interval          [Daily  ▼]      │
│ ○ Include files              [OFF]   │
│ ○ Password protect          [OFF]   │
│ ┌────────────────────────────────────┐│
│ │ Last backup: May 28, 2026 3:00 AM ││
│ │ Size: 2.4 MB                      ││
│ │ [Back up now]  [Restore...]       ││
│ └────────────────────────────────────┘│
│                                      │
│ IMPORT                                │
│ ┌────────────────────────────────────┐│
│ │ 📥 Google Keep                     ││
│ │ 📥 Evernote                        ││
│ │ 📥 Quillpad                        ││
│ └────────────────────────────────────┘│
│                                      │
│ DATA                                  │
│ ○ [Repair database]                  │
│   (checks integrity, fixes corruption)│
│ ○ [Clear all data]                   │
│   (with double confirmation)         │
│                                      │
│ ABOUT                                │
│ Version 1.0.0 (build 1)             │
│ ○ [Open source licenses]            │
│ ○ [Privacy policy]                  │
│ ○ [Send feedback]                   │
│                                      │
└──────────────────────────────────────┘
```

### 7. Import Screen

```
┌──────────────────────────────────────┐
│ ← Back         Import Notes          │
├──────────────────────────────────────┤
│                                      │
│ SELECT SOURCE                        │
│                                      │
│ ┌────────────────────────────────────┐│
│ │ 📥 Google Keep                     ││
│ │ Import notes from Google Takeout   ││
│ └────────────────────────────────────┘│
│ ┌────────────────────────────────────┐│
│ │ 📥 Evernote                        ││
│ │ Import notes from .enex file       ││
│ └────────────────────────────────────┘│
│ ┌────────────────────────────────────┐│
│ │ 📥 Quillpad                        ││
│ │ Import notes from JSON export      ││
│ └────────────────────────────────────┘│
│                                      │
│ ── (After source selected) ──         │
│                                      │
│ 🔍 [Select folder / Select file]     │
│                                      │
│ ┌────────────────────────────────────┐│
│ │ Importing...                       ││
│ │ ██████████░░░░ 38/53 notes        ││
│ │ ✓ 38 imported                     ││
│ │ ⚠ 2 skipped (duplicates)          ││
│ │ ✕ 0 failed                        ││
│ │ [Cancel]                           ││
│ └────────────────────────────────────┘│
│                                      │
│ Label mapping:                       │
│ "personal" → [Personal ▼] ✓ mapped  │
│ "work" → [Work ▼] ✓ mapped          │
│ "ideas" → [Ideas ▼] ✓ mapped        │
│ (auto-mapped 5 labels)              │
│                                      │
│ [Done]                                │
└──────────────────────────────────────┘
```

### 8. Home Screen Widget

```
 ┌─────────────────────────┐
 │ purenote                │
 │ ─────────────────────── │
 │                         │
 │ 📌 My Important Note    │
 │   Preview text shows    │
 │   here for quick ref... │
 │                         │
 │ 📌 Second Note          │
 │   Another preview       │
 │                         │
 │ [See all 5 notes]       │
 └─────────────────────────┘
```

**Widget sizes:** 2×2 (small, 1 note), 4×2 (medium, 3 notes), 4×4 (large, 5+ notes).

**Configuration:** User picks source (pinned notes / specific label) and max count. Widget updates on note change + periodically (30 min Android minimum).

**Post-reboot behavior:** Widget checks SharedPreferences for data. If empty (app data wiped), shows "Open purenote to configure" instead of stale data.

## Dialog & Modal Specifications

| Component | Type | Content |
|---|---|---|
| Label picker | Bottom sheet | Scrollable label list with checkboxes + "Create new label" at bottom + Done button |
| Color picker | Bottom sheet | 12 color circles (scrollable horizontal) + "No color" option + active indicator (checkmark) |
| Reminder picker | Bottom sheet | Date picker → time picker + "Remove reminder" link + "Done" |
| Link insert | Dialog | URL text field + auto-detect icon (🔗/📞/✉) + Insert/Cancel |
| Confirm delete | Dialog | "Delete note?" + "This can be undone." (for trash) OR "This cannot be undone." (for permanent) + Cancel/Delete |
| Lock setup | Full screen (first time) | "Choose your lock method" — Biometric or PIN (with fallback) |
| Lock entry | Full screen | PIN pad or biometric prompt |
| Import label mapping | Dialog | Source label → app label dropdown + auto-mapped indicator |

## Empty States (Every Screen)

| Screen | Illustration | Message | Action |
|---|---|---|---|
| Notes list | Empty notebook | "No notes yet" | "Tap + to create your first note" |
| Notes list (filtered) | Search with no results | "No notes match this filter" | "Clear filter" |
| Tasks | Empty checklist | "No task lists yet" | "Create your first task list" |
| Search (no query) | (recent searches list) | — | — |
| Search (no results) | Search with no results | "No notes match your query" | "Try different keywords" |
| Audio tab | No microphone | "No audio notes" | "Record your first audio note" |
| Trash (future) | Empty trash can | "Trash is empty" | — |
| Labels management | Empty tag | "No labels yet" | "Create your first label" |
| Backup | Empty folder | "No backups yet" | "Back up now" |
| Import | Empty box | "No imports yet" | "Select a source above" |

## Loading States

| Screen | Loading Treatment |
|---|---|
| Notes list | Skeleton cards (3-4 gray rectangles pulsing at 1.5s interval) |
| Note editor | Skeleton: title line + toolbar placeholder + content area |
| Search results | Inline shimmer under search bar |
| Import | Progress bar with per-note counts (determinate) |
| Backup | Progress spinner + "Creating backup..." text (indeterminate for ZIP) |
| Large file import | Isolate-based processing with periodic progress updates |

## Error States

| Error | UI Treatment | Recovery |
|---|---|---|
| Database corruption | Full-screen error: "Database error" + message + [Repair] + [Contact support] | Repair = integrity check + salvage to new DB |
| File I/O failure | Inline banner: "Could not save attachment" | Retry + suggest different file |
| Encryption failure | Dialog: "Could not lock note" + error | Retry + reset encryption key option |
| Import parse error | Per-file error in import progress: ⚠ "Skipped: invalid file" | Continue with remaining files |
| Notification tap after note deleted | Snackbar: "This note was deleted" | — |
| Widget with no data | Widget shows "Open app to configure" | Tap opens app home |
| Biometric unavailable | Fallback to PIN entry | Show PIN pad immediately |
| PIN wrong (3 attempts) | "Too many attempts. Try again in 30s" | Countdown timer, disable input |
| Backup failed | Notification: "Backup failed: reason" + tap to retry | Opens backup settings |
| Audio recording interrupted | Snackbar: "Recording interrupted. Tap to review." | Opens audio recorder with partial file |

## Accessibility

| Requirement | Implementation |
|---|---|
| Touch targets | All interactive widgets min 48x48dp. Toolbar buttons 48x48dp. |
| Color contrast | WCAG AA: 4.5:1 for text, 3:1 for large text + UI components. Note colors checked against both light/dark surfaces. |
| Text scaling | Full respect for `MediaQuery.textScaleFactor`. Test at 150% and 200%. |
| TalkBack | Semantics labels on: FAB, toolbar buttons, note cards, label chips, sort dropdown, view toggle. |
| Semantic groups | Note card = single semantic node with label = "Note: {title}, {preview}, {date}". |
| Focus order | Editor: title → toolbar → content area → footer. Toolbar items: left to right, top to bottom. |
| Reduced motion | `MediaQuery.prefersReducedMotion` respected — skip animations, use instant transitions. |
| Landmark navigation | Headers and sections marked with Semantics headerLevel. |

## Theming Details

| Token | Light | Dark |
|---|---|---|
| Surface | `surface` | `surface` |
| Background | `surfaceContainerLow` | `surfaceContainerLow` |
| Note card default | `surfaceContainerHigh` | `surfaceContainerHigh` |
| Primary | `primary` | `primary` |
| On primary | `onPrimary` | `onPrimary` |
| Error | `error` | `error` |
| Text primary | `onSurface` (87% opacity) | `onSurface` (87% opacity) |
| Text secondary | `onSurfaceVariant` | `onSurfaceVariant` |
| Divider | `outlineVariant` | `outlineVariant` |

**12 note colors** (verified against both light/dark backgrounds for WCAG AA text contrast):
#EF5350, #AB47BC, #5C6BC0, #42A5F5, #26C6DA, #66BB6A, #9CCC65, #FFEE58, #FFA726, #8D6E63, #78909C, #EC407A

## Animations

| Transition | Type | Duration | Curve |
|---|---|---|---|
| Page push | Slide from right | 300ms | standard |
| Page pop | Slide to right | 300ms | standard |
| Note card appear | Fade in + slide up 8dp | 200ms | easeOut |
| Pin toggle | Scale bounce (1.0→1.2→1.0) | 200ms | spring |
| Check task | Slide down to bottom | 300ms | standard |
| Delete swipe | Shrink + fade out | 200ms | easeIn |
| Undo snackbar | Slide up from bottom | 300ms + 5s display | standard |
| View toggle | Cross-fade between list/grid | 200ms | easeInOut |
| Bottom nav tab | Cross-fade content | 200ms | easeInOut |
| Error banner | Slide down from top | 250ms | standard |
| Lock screen | Blur + fade in overlay | 300ms | easeIn |
| Widget update | Native (no Flutter animation) | — | — |
