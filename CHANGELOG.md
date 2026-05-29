# Changelog

## [1.0.0] - 2026-05-29

### Added
- Rich text notes with bold, italic, headers, lists, inline code (Quill Delta)
- Task lists with checkable items
- Label management with color-coded labels
- Full-text search with keyword highlighting and recent searches
- Biometric and PIN app lock with auto-lock timer
- Per-note AES-256-CBC encryption (independent from app lock)
- Reminder notifications per note
- Image, audio, and file attachments (up to 50 MB)
- Home screen widget showing latest note
- Backup and restore with optional AES-256 password and auto-backup scheduler
- Import from Google Keep (HTML), Evernote (ENEX), and Quillpad (JSON)
- Light, dark, and system-follow themes
- List and grid view modes with sort by title, created, or modified date
- Adjustable text size (70%–150%)
- About screen with version info and OSS licenses

### Changed
- Production hardening: DB indexes for query performance, orphan cleanup on start

### Fixed
- N/A (initial release)

### Security
- PIN stored as PBKDF2 hash via flutter_secure_storage
- Note content encrypted with AES-256-CBC and random IV
- No internet permission, no cloud, no tracking
