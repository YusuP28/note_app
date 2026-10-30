# Graph Report - note_app  (2026-10-28)

## Corpus Check
- cluster-only mode — file stats not available

## Summary
- 862 nodes · 1135 edges · 46 communities (45 shown, 1 thin omitted)
- Extraction: 100% EXTRACTED · 0% INFERRED · 0% AMBIGUOUS
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `daccad07`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- edit_screen.dart
- quill_image_service.dart
- note_provider.dart
- neumo.dart
- with
- dependencies
- backup_service.dart
- settings_provider.dart
- web.yml
- lock_service.dart
- google_drive_service.dart
- home_screen.dart
- note.dart
- alarm_page_screen.dart
- main.dart
- lock_guard.dart
- search_screen.dart
- attachment.dart
- NoteProvider
- database_service.dart
- lib.sh
- drive_backup_screen.dart
- SettingsProvider
- theme_provider.dart
- settings_screen.dart
- notebook_provider.dart
- notebook.dart
- tag_provider.dart
- attachment_service.dart
- alarm_service.dart
- note_card.dart
- tags_screen.dart
- note_context_sheet.dart
- tag.dart
- notebooks_screen.dart
- package:flutter/foundation.dart
- ../models/note.dart
- empty_state.dart
- State
- StatelessWidget
- package:flutter/material.dart
- image_thumbnail.dart
- rules
- date_utils.dart
- locale_init.dart
- _EditScreenState

## God Nodes (most connected - your core abstractions)
1. `NoteProvider` - 45 edges
2. `dependencies` - 23 edges
3. `NotebookProvider` - 12 edges
4. `SettingsProvider` - 11 edges
5. `TagProvider` - 11 edges
6. `with` - 9 edges
7. `steps` - 8 edges
8. `_HomeScreenState` - 7 edges
9. `_EditScreenState` - 7 edges
10. `ThemeProvider` - 6 edges

## Surprising Connections (you probably didn't know these)
- `toggleNoteLock` --references--> `NoteProvider`  [EXTRACTED]
  lib/services/lock_guard.dart → lib/providers/note_provider.dart
- `build` --references--> `NoteProvider`  [EXTRACTED]
  lib/screens/archive/archive_screen.dart → lib/providers/note_provider.dart
- `initState` --references--> `NoteProvider`  [EXTRACTED]
  lib/screens/archive/archive_screen.dart → lib/providers/note_provider.dart
- `build` --references--> `NoteProvider`  [EXTRACTED]
  lib/screens/search/search_screen.dart → lib/providers/note_provider.dart
- `_onChange` --references--> `NoteProvider`  [EXTRACTED]
  lib/screens/search/search_screen.dart → lib/providers/note_provider.dart

## Import Cycles
- None detected.

## Communities (46 total, 1 thin omitted)

### Community 0 - "edit_screen.dart"
Cohesion: 0.04
Nodes (42): _bgImagePath, _bgOpacity, _buildQuillController, _clearDraft, _contentCtrl, _contrastText, createState, _deltaJson (+34 more)

### Community 1 - "quill_image_service.dart"
Cohesion: 0.05
Nodes (28): ExportService, _i, _safeFileName, shareAsText, shareAsTxt, writeMarkdown, writeTxt, deleteFile (+20 more)

### Community 2 - "note_provider.dart"
Cohesion: 0.05
Nodes (35): addNote, _alarm, _applyFilter, archive, _buildNotifBody, _cmp, _db, deletePermanently (+27 more)

### Community 3 - "neumo.dart"
Cohesion: 0.05
Nodes (34): accent, bg, build, child, color, darkAccent, darkBg, darkShadowDark (+26 more)

### Community 4 - "with"
Cohesion: 0.05
Nodes (36): permissions, runs-on, steps, default, description, options, required, type (+28 more)

### Community 5 - "dependencies"
Cohesion: 0.05
Nodes (36): dependencies, archive, crypto, file_picker, flutter, flutter_quill, google_sign_in, googleapis (+28 more)

### Community 6 - "backup_service.dart"
Cohesion: 0.06
Nodes (28): _attachmentsFolder, autoBackup, BackupService, _backupVersion, _copyAttachments, _dataFileName, _ensureWritable, exportAll (+20 more)

### Community 7 - "settings_provider.dart"
Cohesion: 0.06
Nodes (29): _autoBackupDays, autoBackupEnabled, dispose, isGrid, _kAutoBackupDays, _kLastAutoBackup, _kSort, _kSound (+21 more)

### Community 8 - "web.yml"
Cohesion: 0.06
Nodes (32): runs-on, steps, concurrency, cancel-in-progress, group, environment, needs, runs-on (+24 more)

### Community 9 - "lock_service.dart"
Cohesion: 0.07
Nodes (23): _auth, authenticateBiometric, canUseBiometric, disable, _generateBackupCode, getBackupCode, getHint, _hash (+15 more)

### Community 10 - "google_drive_service.dart"
Cohesion: 0.07
Nodes (18): _AuthenticatedClient, cleanupOldBackups, _currentUser, deleteBackup, downloadBackup, _getDriveApi, GoogleDriveService, _googleSignIn (+10 more)

### Community 11 - "home_screen.dart"
Cohesion: 0.08
Nodes (14): _buildDrawer, _buildSelectionAppBar, createState, didChangeDependencies, _enterSelectionMode, _exitSelectionMode, _initialized, _lastBackPress (+6 more)

### Community 12 - "note.dart"
Cohesion: 0.09
Nodes (22): attachments, bgImagePath, bgOpacity, color, content, copyWith, createdAt, fromMap (+14 more)

### Community 13 - "alarm_page_screen.dart"
Cohesion: 0.10
Nodes (17): AlarmPageScreen, _AlarmPageScreenState, _body, build, _channel, createState, dispose, initState (+9 more)

### Community 14 - "main.dart"
Cohesion: 0.10
Nodes (13): build, _channel, _check, _checked, createState, didChangeDependencies, initLocale, _isAlarm (+5 more)

### Community 15 - "lock_guard.dart"
Cohesion: 0.10
Nodes (17): assertUnlocked, code, codeCtrl, ctrl, false, fpEnabled, hint, newPin (+9 more)

### Community 16 - "search_screen.dart"
Cohesion: 0.13
Nodes (11): build, createState, initState, build, createState, _ctrl, _debounce, dispose (+3 more)

### Community 17 - "attachment.dart"
Cohesion: 0.11
Nodes (17): Attachment, copyWith, createdAt, durationMs, fromMap, id, mimeType, noteId (+9 more)

### Community 18 - "NoteProvider"
Cohesion: 0.15
Nodes (18): NoteProvider, _archiveSelected, _confirmDelete, _deleteSelected, _openNote, _pinSelected, build, createState (+10 more)

### Community 19 - "database_service.dart"
Cohesion: 0.11
Nodes (14): close, _createAttachmentsSchema, _db, _dbName, deleteAttachment, getAttachmentsForNote, getNoteById, _initDb (+6 more)

### Community 20 - "lib.sh"
Cohesion: 0.11
Nodes (9): C_BLUE, C_BOLD, C_CYAN, C_GREEN, C_MAGENTA, C_RED, C_RESET, C_YELLOW (+1 more)

### Community 21 - "drive_backup_screen.dart"
Cohesion: 0.12
Nodes (14): _backup, build, _busy, createState, _drive, DriveBackupScreen, _DriveBackupScreenState, initState (+6 more)

### Community 22 - "SettingsProvider"
Cohesion: 0.16
Nodes (13): SettingsProvider, ThemeProvider, _openNote, build, _initializeData, _openDrawerItem, _showSortMenu, _openNote (+5 more)

### Community 23 - "theme_provider.dart"
Cohesion: 0.13
Nodes (9): dispose, isDark, _kColor, _kMode, load, _mode, _seed, setMode (+1 more)

### Community 24 - "settings_screen.dart"
Cohesion: 0.13
Nodes (6): _changePin, _disableLock, _openLockSettings, _section, _setupPin, _showBackupCodeDialog

### Community 25 - "notebook_provider.dart"
Cohesion: 0.15
Nodes (11): add, childrenOf, _db, delete, dispose, load, _loading, _notebooks (+3 more)

### Community 26 - "notebook.dart"
Cohesion: 0.15
Nodes (12): color, copyWith, createdAt, fromMap, icon, id, name, Notebook (+4 more)

### Community 27 - "tag_provider.dart"
Cohesion: 0.15
Nodes (10): add, _db, delete, dispose, findByName, load, _tags, update (+2 more)

### Community 28 - "attachment_service.dart"
Cohesion: 0.15
Nodes (8): AttachmentService, _attachmentsFolder, cleanupOrphans, _database, deleteAttachment, _instance, saveAttachment, _uuid

### Community 29 - "alarm_service.dart"
Cohesion: 0.17
Nodes (9): AlarmService, cancel, canScheduleExact, _channel, _i, openChannelSettings, requestExactPermission, schedule (+1 more)

### Community 30 - "note_card.dart"
Cohesion: 0.18
Nodes (8): Note, build, gridMode, note, onLongPress, onTap, selected, selectionMode

### Community 31 - "tags_screen.dart"
Cohesion: 0.22
Nodes (6): TagProvider, build, _addOrEdit, build, _palette, TagsScreen

### Community 32 - "note_context_sheet.dart"
Cohesion: 0.18
Nodes (6): _fmt, _infoRow, provider, showNoteContextSheet, _snack, _tile

### Community 33 - "tag.dart"
Cohesion: 0.20
Nodes (8): color, copyWith, createdAt, fromMap, id, name, Tag, toMap

### Community 34 - "notebooks_screen.dart"
Cohesion: 0.27
Nodes (6): NotebookProvider, _addOrEdit, build, _buildTree, _confirmDelete, NotebooksScreen

### Community 35 - "package:flutter/foundation.dart"
Cohesion: 0.22
Nodes (3): AutoBackupService, checkAndRun, _i

### Community 36 - "../models/note.dart"
Cohesion: 0.22
Nodes (4): _doneFlag, _legacyFile, migrateIfNeeded, MigrationService

### Community 37 - "empty_state.dart"
Cohesion: 0.22
Nodes (5): action, build, icon, subtitle, title

### Community 38 - "State"
Cohesion: 0.32
Nodes (6): _Launcher, _LauncherState, ArchiveScreen, _ArchiveScreenState, HomeScreen, _HomeScreenState

### Community 39 - "StatelessWidget"
Cohesion: 0.25
Nodes (7): NoteApp, NeumoCard, NeumoChip, NeumoFab, NeumoIconButton, EmptyState, NoteCard

### Community 40 - "package:flutter/material.dart"
Cohesion: 0.25
Nodes (4): AppTheme, dark, light, showImageSourceSheet

### Community 41 - "image_thumbnail.dart"
Cohesion: 0.25
Nodes (6): build, ImageThumbnail, onDelete, onTap, path, size

### Community 42 - "rules"
Cohesion: 0.29
Nodes (6): include, linter, rules, avoid_print, prefer_const_constructors, prefer_const_literals_to_create_immutables

### Community 43 - "date_utils.dart"
Cohesion: 0.40
Nodes (3): AppDate, full, short

### Community 44 - "locale_init.dart"
Cohesion: 0.40
Nodes (3): initializeDateFormatting, initLocale, null

## Knowledge Gaps
- **488 isolated node(s):** `_bgImagePath`, `_bgOpacity`, `_buildQuillController`, `_clearDraft`, `_contentCtrl` (+483 more)
  These have ≤1 connection - possible missing edges. (Counts symbols only; 654 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **1 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `NoteProvider` connect `NoteProvider` to `edit_screen.dart`, `note_context_sheet.dart`, `note_provider.dart`, `notebooks_screen.dart`, `State`, `home_screen.dart`, `_EditScreenState`, `lock_guard.dart`, `search_screen.dart`, `drive_backup_screen.dart`, `SettingsProvider`, `settings_screen.dart`, `tags_screen.dart`?**
  _High betweenness centrality (0.069) - this node is a cross-community bridge._
- **What connects `_bgImagePath`, `_bgOpacity`, `_buildQuillController` to the rest of the system?**
  _488 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `edit_screen.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.041666666666666664 - nodes in this community are weakly interconnected._
- **Why does `SettingsProvider` connect `SettingsProvider` to `State`, `settings_provider.dart`, `home_screen.dart`, `main.dart`, `settings_screen.dart`?**
  _High betweenness centrality (0.014) - this node is a cross-community bridge._
- **Should `quill_image_service.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.050505050505050504 - nodes in this community are weakly interconnected._
- **Why does `Note` connect `note_card.dart` to `edit_screen.dart`, `note.dart`, `alarm_page_screen.dart`?**
  _High betweenness centrality (0.013) - this node is a cross-community bridge._
- **Should `note_provider.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.05128205128205128 - nodes in this community are weakly interconnected._