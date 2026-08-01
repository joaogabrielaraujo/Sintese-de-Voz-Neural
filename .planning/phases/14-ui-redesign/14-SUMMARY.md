---
phase: 14-ui-redesign
plan: 01
subsystem: ui
tags: [flutter, responsive-ui, epub, offline-persistence, android, windows]
requires:
  - phase: 13-epub-import
    provides: EPUB byte import, chapter model, synthesis pipeline, and synchronized audio callbacks
provides:
  - Editorial dark theme and reusable UI tokens based on design_mockup.html
  - Compact Android navigation and wide Windows navigation/reader layouts
  - Testable library, reader, settings, navigation, and player widgets
  - Offline EPUB library with deduplication and resumable reading progress
affects: [15-telemetria-tcc, android-release, windows-desktop, uat]
actuals:
  tokens: 32143
  tasks: 7
  commits: 4
tech-stack:
  added: []
  patterns: [LayoutBuilder breakpoints, callback-driven view widgets, debounced serialized persistence]
key-files:
  created:
    - lib/ui/app_theme.dart
    - lib/ui/widgets/library_view.dart
    - lib/ui/widgets/reader_page.dart
    - lib/ui/widgets/responsive_navigation_shell.dart
    - lib/ui/widgets/settings_view.dart
    - lib/core/document/saved_book.dart
    - lib/core/document/saved_book_repository.dart
    - test/ui/redesign_widgets_test.dart
  modified:
    - lib/main.dart
    - lib/ui/widgets/audio_player_control_bar.dart
    - lib/ui/widgets/reader_document_view.dart
    - test/widget_test.dart
key-decisions:
  - "Use bottom navigation below 900 px and a NavigationRail at 900 px or wider, while keeping the compact threshold at 700 px for reader/control adaptation."
  - "Keep EPUBs in the platform application-support directory and identify duplicate payloads with a deterministic content fingerprint."
  - "Keep EPUB pagination deferred; Phase 14 retains continuous chapter reading as explicitly requested."
patterns-established:
  - "Controller/view split: main.dart coordinates services and state while public widgets receive data and callbacks."
  - "Responsive shell: the same destinations and callbacks drive touch, mouse, and keyboard layouts."
requirements-completed: []
coverage:
  - id: D1
    description: "Editorial redesign with compact Android and wide Windows behavior"
    verification:
      - kind: automated_ui
        ref: "test/ui/redesign_widgets_test.dart#ResponsiveNavigationShell and ReaderPage"
        status: pass
    human_judgment: true
    rationale: "Automated tests prove breakpoints and structure, but final visual fidelity to the mockup requires human judgment."
  - id: D2
    description: "Offline saved EPUB library with deduplication, deletion, and progress restoration"
    verification:
      - kind: integration
        ref: "test/core/document/saved_book_test.dart#SavedBookRepository"
        status: pass
    human_judgment: false
  - id: D3
    description: "Reader selection, keyboard navigation, responsive player, and callback preservation"
    verification:
      - kind: automated_ui
        ref: "test/ui/redesign_widgets_test.dart#ReaderPage"
        status: pass
      - kind: automated_ui
        ref: "test/ui/audio_player_widget_test.dart#AudioPlayerControlBar"
        status: pass
    human_judgment: true
    rationale: "Native audio synthesis and playback still require device-level UAT even though widget callbacks pass."
  - id: D4
    description: "Empty, import, error, processing, engine, and search states remain accessible"
    verification:
      - kind: automated_ui
        ref: "test/ui/redesign_widgets_test.dart#LibraryView"
        status: pass
    human_judgment: false
duration: 31min
completed: 2026-08-01
status: complete
---

# Phase 14: UI Redesign Summary

**Responsive Flutter EPUB reader with an editorial offline library, continuous synchronized reading, adaptive Android/Windows navigation, and resumable local progress**

## Performance

- **Duration:** 31 min
- **Started:** 2026-08-01T18:53:51Z
- **Completed:** 2026-08-01T19:24:36Z
- **Tasks:** 7
- **Files modified:** 15 production/test/design files

## Accomplishments

- Replaced the monolithic home/reader rendering with callback-driven `LibraryView`, `ReaderPage`, `SettingsView`, and `ResponsiveNavigationShell` widgets.
- Added compact bottom navigation for Android-sized windows, a wide `NavigationRail` and side-anchored player for Windows, comfortable reader width, and keyboard shortcuts for play/pause, cancel/back, and sentence navigation.
- Applied mockup colors, typography fallbacks, spacing, radii, touch targets, continuous text highlighting, pending-selection confirmation, player metrics, and mandatory empty/error/processing states.
- Preserved engine, synthesis pipeline, audio, RTF, MOS, chapter selection, sentence synchronization, import, and deletion callbacks in the existing state controller.
- Added an offline saved-book repository with payload deduplication, safe identifiers, debounced/serialized progress writes, lifecycle flushes, and resume on open or duplicate re-import.
- Kept EPUB pagination intentionally deferred; the shipped reader remains a continuous chapter view.

## Task Commits

The seven legacy numbered tasks were already interwoven in the dirty Phase 14 implementation, so they were committed by safe outcome boundary rather than staging fragile partial hunks:

1. **Tasks 1-6: Theme, modular widgets, responsive layouts, reader states, callbacks, accessibility, and persistence** — `5f74cc8` (feat)
2. **Task 7: Widget, smoke, and saved-library verification** — `45e5066` (test)

## Files Created/Modified

- `lib/ui/app_theme.dart` — Shared color, spacing, radius, breakpoint, typography, navigation, and touch-target tokens.
- `lib/ui/widgets/library_view.dart` — Scrollable library, import/search/error/empty states, engine badges, and saved-book callbacks.
- `lib/ui/widgets/reader_page.dart` — Compact/wide reader composition, keyboard shortcuts, confirmation surface, status/RTF, and anchored player.
- `lib/ui/widgets/responsive_navigation_shell.dart` — Bottom navigation below 900 px and `NavigationRail` at 900 px or wider.
- `lib/ui/widgets/settings_view.dart` — Testable offline engine selection and initialization state.
- `lib/ui/widgets/audio_player_control_bar.dart` — Responsive controls with compact wrapping and 44 px targets.
- `lib/ui/widgets/reader_document_view.dart` — Continuous reading text with active amber and pending dashed-teal treatment.
- `lib/core/document/saved_book.dart` — Persisted library/progress model.
- `lib/core/document/saved_book_repository.dart` — Private app-support storage, deduplication, load/update/delete, and path-safe IDs.
- `lib/main.dart` — Service/state orchestration and preserved production callbacks, with legacy rendering removed.
- `test/ui/redesign_widgets_test.dart` — Android/Windows, library, reader, keyboard, and player-layout coverage.
- `test/core/document/saved_book_test.dart` — Serialization and repository lifecycle coverage.
- `test/ui/audio_player_widget_test.dart`, `test/widget_test.dart` — Updated player and app smoke assertions.
- `design_mockup.html` — Versioned visual reference used by the Flutter implementation.

## Decisions Made

- Used local font fallbacks instead of runtime network font loading, preserving offline operation.
- Kept one service/state controller while extracting rendering into public widgets; this reduces rebuild and test scope without changing synthesis architecture.
- Used the platform-private application-support directory and validated repository IDs before constructing paths.
- Restored saved chapter/sentence position when a duplicate EPUB is imported rather than resetting prior progress.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Corrected saved-progress completion and duplicate re-import behavior**
- **Found during:** Tasks 4-5
- **Issue:** The active sentence was counted from zero for progress, and re-importing a deduplicated EPUB could reset the visible chapter while retaining stale sentence state.
- **Fix:** Count the current sentence as completed and restore the persisted chapter/sentence when the same payload is imported again.
- **Files modified:** `lib/main.dart`
- **Verification:** Changed-source analysis passed; saved repository and app smoke tests passed.
- **Committed in:** `5f74cc8`

**2. [Rule 2 - Missing Critical] Guarded persisted IDs before filesystem path construction**
- **Found during:** Task 5
- **Issue:** Corrupted local metadata could contain an unsafe ID even though generated IDs were safe.
- **Fix:** Accept only deterministic `book-xxxxxxxx` identifiers for list/load/update/delete operations.
- **Files modified:** `lib/core/document/saved_book_repository.dart`
- **Verification:** Repository test rejects `../outside` and confirms normal delete/load behavior.
- **Committed in:** `5f74cc8`, covered by `45e5066`

**3. [Rule 1 - Bug] Prevented compact player and library overflow**
- **Found during:** Tasks 2-3
- **Issue:** The previous fixed player row and non-scrollable library column could overflow on Android-sized windows or larger saved libraries.
- **Fix:** Use responsive wrapped controls and a constrained, scrollable library view.
- **Files modified:** `lib/ui/widgets/audio_player_control_bar.dart`, `lib/ui/widgets/library_view.dart`
- **Verification:** Compact widget tests and 390 px layout test passed.
- **Committed in:** `5f74cc8`, covered by `45e5066`

---

**Total deviations:** 3 auto-fixed (2 Rule 1 bugs, 1 Rule 2 critical filesystem guard)
**Impact on plan:** All fixes were required for correct responsive behavior and safe persistence; no EPUB pagination or unrelated release configuration was added.

## Verification

- **PASS:** Direct Dart format check over 14 changed source/test files — 0 changed in 0.08 s.
- **PASS:** Direct Dart analysis over all 14 changed source/test files — no issues found.
- **PASS:** Targeted Flutter suite (`saved_book_test`, `redesign_widgets_test`, `audio_player_widget_test`, `widget_test`) — 14/14 tests passed in 10.7 s on the final run.
- **INCONCLUSIVE:** Standard `dart format` wrapper produced no output and timed out after 60.4 s; the SDK executable completed the same format check successfully.
- **INCONCLUSIVE:** Full Flutter `analyze` produced no output for more than two minutes and was terminated. Changed-file direct analysis passed.
- **INCONCLUSIVE:** Full `flutter test --no-pub` produced no output for more than 93 s and was terminated. The Phase 14 targeted suite passed.

## Issues Encountered

- The Flutter/Dart batch wrappers are unreliable in this Windows workspace. Inspection showed only normal VS Code language-server/tooling processes, not orphaned test jobs. Calling `C:\Users\55759\flutter\bin\cache\dart-sdk\bin\dart.exe` directly made formatting, changed-file analysis, and targeted Flutter tests reliable.
- The first targeted run exposed one stale smoke-test expectation from the old product header. It was updated to assert `VozLume`, `OFFLINE`, and `Importar EPUB`; all subsequent targeted runs passed.

## Known Stubs

None. Empty collections and nullable fields in the controller represent real initial/runtime states and are wired to library, reader, metrics, and persistence data sources.

## Threat Flags

| Flag | File | Description |
|---|---|---|
| threat_flag: local-file-persistence | `lib/core/document/saved_book_repository.dart` | New private application-support EPUB storage boundary; generated and loaded IDs are constrained before path construction. |

## User Setup Required

None — no network service, secret, or external runtime configuration was added.

## Next Phase Readiness

- Phase 15 telemetry can use the redesigned reader and existing RTF/MOS surfaces without changing the UI shell.
- Device-level Android/Windows UAT remains appropriate for visual fidelity, native file picking, synthesis, and audio playback.
- Flutter wrapper/full-suite hangs remain an environment/tooling concern; targeted verification is green, but the full commands should be retried after repairing the SDK launcher/lock behavior.

## Self-Check: PASSED

- All ten key created artifacts and `14-SUMMARY.md` exist on disk.
- Implementation commit `5f74cc8` and test commit `45e5066` exist in Git history.

---
*Phase: 14-ui-redesign*
*Completed: 2026-08-01*
