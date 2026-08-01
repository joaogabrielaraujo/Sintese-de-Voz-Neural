---
phase: 14-ui-redesign
reviewed: 2026-08-01T19:50:00Z
depth: standard
files_reviewed: 15
files_reviewed_list:
  - design_mockup.html
  - lib/core/document/saved_book.dart
  - lib/core/document/saved_book_repository.dart
  - lib/main.dart
  - lib/ui/app_theme.dart
  - lib/ui/widgets/audio_player_control_bar.dart
  - lib/ui/widgets/library_view.dart
  - lib/ui/widgets/reader_document_view.dart
  - lib/ui/widgets/reader_page.dart
  - lib/ui/widgets/responsive_navigation_shell.dart
  - lib/ui/widgets/settings_view.dart
  - test/core/document/saved_book_test.dart
  - test/ui/audio_player_widget_test.dart
  - test/ui/redesign_widgets_test.dart
  - test/widget_test.dart
findings:
  critical: 7
  warning: 5
  info: 0
  total: 12
status: issues_found
---

# Phase 14: Code Review Report

**Reviewed:** 2026-08-01T19:50:00Z  
**Depth:** standard  
**Files Reviewed:** 15  
**Status:** issues_found

## Narrative Findings (AI reviewer)

### Summary

The redesign contains shipping blockers in book identity, crash-safe persistence, progress durability, streaming cancellation, progress calculation, search state, and the MOS evaluation flow. The most serious persistence defect is the use of a 32-bit FNV fingerprint as both identity and deduplication proof: two different byte sequences were confirmed to produce the same repository key. The asynchronous reader state also permits an old chapter stream to resume and play after cancellation.

No EPUB pagination finding is raised; pagination remains explicitly deferred as required.

Automated verification was attempted with `flutter analyze --no-pub` and focused `flutter test --no-pub` runs. Both stalled without diagnostics before test execution and were terminated, so they provide no passing evidence. The findings below are based on direct, line-by-line source tracing.

### Critical Issues

#### CR-01: A 32-bit collision silently aliases different EPUB files

**Classification:** BLOCKER  
**File:** `C:/Users/55759/Documents/sintese_de_voz/lib/core/document/saved_book_repository.dart:75-81,137-143`  
**Issue:** `_fingerprint` returns only a 32-bit FNV-1a value, and `saveNew` treats equality of that value as proof that two EPUB payloads are identical. Different files with the same value cause the second import to return the first record without storing the second file. A bounded diagnostic reproduced the collision: `B906FB55A0217D2B` and `DC3A4CA786B73DE7` both hash to `257996d5`. This is deterministic data substitution and can also be triggered by a crafted EPUB.

**Fix:** Use a collision-resistant digest such as the full SHA-256 hex digest for `contentHash` and the file ID. Before deduplicating, verify the existing payload against the full digest (or bytes). Update `_isSafeId` and provide migration for existing eight-character IDs.

#### CR-02: A cancelled chapter stream can still load and play stale audio

**Classification:** BLOCKER  
**File:** `C:/Users/55759/Documents/sintese_de_voz/lib/main.dart:387-430,446-459,624-633`  
**Issue:** `_advanceStreamingSentence` captures the current iterator and queue, then awaits `moveNext()`. `_stopStreamingPipeline` clears shared fields and cancels the iterator, but the already-running advance has no generation check after that await. It can continue through lines 416-430, install an item from the old chapter, overwrite `_activeSentenceIndex`, and play it after the user changed chapters or started another stream. Meanwhile `_isAdvancingStream` can cause the new stream's first advance to return immediately.

**Fix:** Give each stream a monotonically increasing generation/cancellation token. Capture it in `_advanceStreamingSentence` and re-check it, `_isStreaming`, and iterator identity after every await before mutating state or audio. Make chapter changes await stream cancellation before changing chapter state or starting a replacement stream.

#### CR-03: Metadata writes are not crash-safe and can erase a saved book

**Classification:** BLOCKER  
**File:** `C:/Users/55759/Documents/sintese_de_voz/lib/core/document/saved_book_repository.dart:98-105,119-128`  
**Issue:** Both progress updates and initial metadata are written directly to the canonical JSON file. Process termination, Android lifecycle termination, disk-full errors, or an interrupted Windows write can leave truncated JSON. `list()` then silently ignores the record, making a persisted book disappear even when its EPUB payload remains. Initial `_write` can also leave an orphan EPUB when the second write fails.

**Fix:** Write metadata to a sibling temporary file, flush it, validate the serialized content, and atomically replace the canonical file. Use a Windows-safe replace/backup strategy and recover either the last valid canonical or backup file on startup. Clean up an EPUB payload if its initial metadata transaction fails.

#### CR-04: Final reading progress is launched but never guaranteed to finish

**Classification:** BLOCKER  
**File:** `C:/Users/55759/Documents/sintese_de_voz/lib/main.dart:181-202,244-265,333-341`  
**Issue:** `dispose`, lifecycle callbacks, and `_closeReader` call both persistence methods with `unawaited`. The repository update performs asynchronous filesystem I/O, so closing the reader and then terminating/suspending the app can lose the latest position. `dispose` immediately continues to tear down the app and cannot guarantee either future completes. The debounce timer further means the latest update may exist only in memory at termination.

**Fix:** Make user-driven close/navigation paths asynchronous and await a serialized progress flush before completing them. Persist checkpoints during playback rather than relying on `dispose`, and use a lifecycle-aware persistence component whose in-flight write is established before suspension. Keep one write-chain future and drain pending state again after any in-flight write completes.

#### CR-05: Progress reaches the next sentence—and 100%—before playback completes

**Classification:** BLOCKER  
**File:** `C:/Users/55759/Documents/sintese_de_voz/lib/main.dart:211-230,416-430`  
**Issue:** `completedInChapter` is calculated as `_activeSentenceIndex + 1`, but `_persistReadingProgress` is called immediately after a sentence is loaded and before `_audioPlayer.play()` completes it. Opening a book at sentence zero and closing it marks sentence one complete; starting the final sentence reports 100% while it is still unplayed. The stored `sentenceIndex` and percentage therefore describe different completion states.

**Fix:** Track the last completed sentence separately from the current/resume sentence. Increment completed progress only on the matching audio completion event; if partial progress is desired, include the current audio position fraction without ever reporting 100% before final completion.

#### CR-06: The visible MOS action is permanently inert

**Classification:** BLOCKER  
**File:** `C:/Users/55759/Documents/sintese_de_voz/lib/main.dart:356-430,571-592,609-648`  
**File:** `C:/Users/55759/Documents/sintese_de_voz/lib/ui/widgets/audio_player_control_bar.dart:129-144`  
**Issue:** Every pipeline start sets `_lastResult = null`, and no reviewed execution path assigns a non-null `PipelineResult`. The player nevertheless always renders an enabled MOS button. Tapping it calls `_showMOSDialog`, which immediately returns when `_lastResult` is null. RTF and the academic report are unreachable for the same reason.

**Fix:** Accumulate streamed `SentenceAudioItem` metrics and build/update a `PipelineResult`, then enable MOS/report actions only when a valid result exists. Alternatively, remove or disable those controls with an explanatory state until streaming metrics are implemented.

#### CR-07: Search results can remain filtered while the search field is blank

**Classification:** BLOCKER  
**File:** `C:/Users/55759/Documents/sintese_de_voz/lib/main.dart:88-90,680-692,721-730`  
**File:** `C:/Users/55759/Documents/sintese_de_voz/lib/ui/widgets/library_view.dart:38-68`  
**Issue:** `_searchQuery` survives navigation away from Search, but the `TextField` has no controller or initial value. Returning to Search creates a visibly empty field while `visibleBooks` is still filtered by the old query. Users cannot understand or clear the hidden filter without typing a new value.

**Fix:** Own a `TextEditingController` synchronized with `_searchQuery`, or explicitly clear `_searchQuery` when leaving Search. Add a widget test covering Search → Library/Settings → Search.

### Warnings

#### WR-01: Gesture recognizers are disposed during every rebuild

**Classification:** WARNING  
**File:** `C:/Users/55759/Documents/sintese_de_voz/lib/ui/widgets/reader_document_view.dart:27-43,53-80`  
**File:** `C:/Users/55759/Documents/sintese_de_voz/lib/main.dart:149-155`  
**Issue:** `ReaderDocumentView.build` disposes and recreates every `TapGestureRecognizer`. Position-stream updates rebuild the reader repeatedly during playback; if a rebuild occurs between pointer-down and pointer-up, the recognizer handling that gesture is disposed and sentence selection can be dropped.

**Fix:** Keep recognizers stable across ordinary rebuilds, updating them only when the sentence collection changes, or render focusable sentence widgets whose gesture lifecycle Flutter manages.

#### WR-02: Storage failures escape from unawaited open/delete callbacks

**Classification:** WARNING  
**File:** `C:/Users/55759/Documents/sintese_de_voz/lib/main.dart:268-274,652-667,689-692`  
**Issue:** `_openSavedBook` calls repository `load` before entering its `try`, and `_deleteSavedBook` has no error handling. Both are launched with `unawaited`, so path-provider or filesystem failures become unhandled asynchronous errors and leave the UI without actionable feedback.

**Fix:** Wrap the complete operations in `try/catch`, expose a user-facing storage error, and only mutate the in-memory library after the repository operation succeeds.

#### WR-03: EPUB import is re-entrant

**Classification:** WARNING  
**File:** `C:/Users/55759/Documents/sintese_de_voz/lib/main.dart:462-518,680-692`  
**File:** `C:/Users/55759/Documents/sintese_de_voz/lib/ui/widgets/library_view.dart:158-175`  
**Issue:** `_importEpub` changes only `_importStatus`; it never sets a dedicated import-in-progress flag. The import card disables itself only from `isProcessing`, which is used for synthesis/engine work. Repeated taps can launch multiple native pickers or concurrent imports whose completions race to replace the active book and status.

**Fix:** Add a dedicated `_isImporting` guard set before opening the picker and cleared in `finally`; disable the card and expose progress from that flag.

#### WR-04: Active and pending sentence state is visual-only

**Classification:** WARNING  
**File:** `C:/Users/55759/Documents/sintese_de_voz/lib/ui/widgets/reader_document_view.dart:53-87`  
**Issue:** Active and pending sentences differ through color, background, underline, and weight, but those states are not represented as selected/current semantics. TalkBack and other screen readers can read text but cannot determine which sentence is active or awaiting confirmation from the document semantics.

**Fix:** Emit explicit semantics for each actionable sentence (including current/selected state and a tap hint) and announce active-sentence changes through a restrained live region. Preserve keyboard focusability on Windows.

#### WR-05: Book deletion is immediate and irreversible from the overflow menu

**Classification:** WARNING  
**File:** `C:/Users/55759/Documents/sintese_de_voz/lib/ui/widgets/library_view.dart:382-393`  
**File:** `C:/Users/55759/Documents/sintese_de_voz/lib/main.dart:652-667`  
**Issue:** Selecting “Remover da biblioteca” immediately deletes both metadata and the EPUB payload. There is no confirmation, undo, or recovery path, so an accidental Android tap or keyboard selection causes permanent local data loss.

**Fix:** Require a confirmation dialog naming the book, or first move the files to a recoverable trash/undo state and delete permanently only after confirmation or expiry.

---

_Reviewed: 2026-08-01T19:50:00Z_  
_Reviewer: the agent (gsd-code-reviewer)_  
_Depth: standard_
