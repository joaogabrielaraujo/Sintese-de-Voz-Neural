---
phase: 14-ui-redesign
verified: 2026-08-01T20:01:54Z
status: gaps_found
score: 2/7 must-haves verified
behavior_unverified: 1
overrides_applied: 0
gaps:
  - truth: "The offline library preserves distinct EPUBs, exposes consistent search/import state, and durably restores accurate reading progress."
    status: failed
    reason: "Different EPUB bytes can collide under the 32-bit FNV identity; metadata is overwritten in place; close/lifecycle flushes are unawaited; progress counts the current sentence complete before playback completes; search and import state can become inconsistent."
    artifacts:
      - path: "lib/core/document/saved_book_repository.dart"
        issue: "Uses an eight-hex-digit FNV-1a fingerprint as deduplication proof and writes canonical JSON directly without transactional replacement or recovery."
      - path: "lib/main.dart"
        issue: "Progress flushes are launched without awaiting completion, progress advances before audio completion, and import/search operations lack coherent single-flight/visible state."
      - path: "lib/ui/widgets/library_view.dart"
        issue: "The search field does not reflect the retained searchQuery and the import card is disabled by synthesis state rather than a dedicated import state."
    missing:
      - "Use a collision-resistant content digest and verify payload identity before deduplication."
      - "Write metadata transactionally with recovery/cleanup and await durable progress checkpoints on user-driven close paths."
      - "Track completed playback separately from the current resume sentence."
      - "Synchronize the visible search field with searchQuery and guard EPUB import as a single-flight operation."
  - truth: "The reader remains synchronized with the selected chapter and active audio across cancellation, chapter changes, and replacement streams."
    status: failed
    reason: "An in-flight iterator advance can resume after cancellation and load/play stale audio because no generation or iterator-identity guard is checked after awaits."
    artifacts:
      - path: "lib/main.dart"
        issue: "_advanceStreamingSentence mutates shared reader/audio state after moveNext and loadAudioBuffer without validating that its stream is still current; chapter changes launch cancellation without awaiting it."
    missing:
      - "Add a monotonically increasing stream generation/cancellation token and validate it after every await before state or audio mutation."
      - "Serialize chapter changes and replacement starts behind completed stream cancellation."
      - "Add a behavioral test that cancels an in-flight stream and proves stale audio cannot become active."
  - truth: "RTF, MOS, queue, and memory metrics remain reachable and functional in the redesigned production flow."
    status: failed
    reason: "The streaming path emits per-sentence metrics but never constructs or assigns a PipelineResult; _lastResult is only assigned null, so RTF/report UI never appears and the enabled MOS action is a no-op. Queue and memory metrics are not rendered."
    artifacts:
      - path: "lib/main.dart"
        issue: "No non-null assignment to _lastResult exists, while _showMOSDialog and the academic report both return when it is null."
      - path: "lib/ui/widgets/audio_player_control_bar.dart"
        issue: "Always renders an enabled MOS button even when production cannot provide a result."
      - path: "lib/ui/widgets/reader_page.dart"
        issue: "RTF is conditional on a value that production never supplies; no queue or memory surface exists."
    missing:
      - "Accumulate streamed SentenceAudioItem metrics into a current/final PipelineResult or an equivalent live metrics model."
      - "Wire RTF, MOS, report, queue, and memory states to real production data and disable controls with an explanation until data exists."
      - "Add an app-level test proving synthesis makes MOS and RTF/report actions reachable."
  - truth: "Automated coverage exercises the required library, reader, import-state, responsive-player, persistence, and synchronization behaviors."
    status: partial
    reason: "The 14 focused tests pass, but they verify isolated layouts/callbacks and same-byte repository deduplication; they do not exercise compact reader/player behavior, import processing/error state, restart durability, collision handling, app-level MOS wiring, or stream cancellation ordering."
    artifacts:
      - path: "test/ui/redesign_widgets_test.dart"
        issue: "Covers compact/wide navigation and wide reader structure, but not compact reader/player or intermediate-width behavior and not app integration."
      - path: "test/ui/audio_player_widget_test.dart"
        issue: "Proves a supplied MOS callback fires and the dialog works in isolation, not that production can open it."
      - path: "test/core/document/saved_book_test.dart"
        issue: "Covers identical-byte deduplication and basic update/delete, not colliding distinct bytes, interrupted writes, or restart flush semantics."
    missing:
      - "Focused regression tests for stream cancellation/replacement, distinct-payload collision resistance, completion-based progress, and production metrics reachability."
      - "Widget coverage for compact reader/player plus import processing/error/cancellation states."
behavior_unverified_items:
  - truth: "Native EPUB picking, offline TTS synthesis, and real audio playback remain operational end-to-end on Android and Windows."
    test: "On Android and Windows, select a real EPUB with the native picker, open a chapter, start synthesis, pause/resume/seek/stop, change chapter, and observe synchronized highlighting."
    expected: "The picker returns the selected file, synthesis stays offline, audio controls affect real playback, and no stale sentence plays after stop or chapter replacement."
    why_human: "The focused tests use isolated widgets and mocks; they do not invoke platform file picking, native TTS engines, or the real audio backend."
---

# Phase 14: UI Redesign Verification Report

**Phase Goal:** Apply the visual language of `design_mockup.html` to the Flutter app with a clean library, synchronized reader, responsive player, compact Android layout, wide Windows layout, and preservation of the offline EPUB/TTS/audio/MOS/metrics flows.
**Verified:** 2026-08-01T20:01:54Z
**Status:** gaps_found
**Re-verification:** No — initial verification

## Goal Achievement

The visual system and responsive widget decomposition are real and wired, but the phase goal is not achieved. The production controller has observable correctness gaps in saved-book identity/progress, stream cancellation ordering, and metrics/MOS reachability. Passing focused tests do not exercise those paths.

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | The mockup's visual tokens and editorial library/reader/player structure are implemented without runtime network font loading. | ✓ VERIFIED | `app_theme.dart:4-132` matches the mockup palette and typography roles; `main.dart:37-42` applies the theme; the library, continuous reader, selection confirmation, and player use these tokens. No network/font-loader use was found in `lib/` or `pubspec.yaml`. |
| 2 | Width-driven compact and wide layouts, comfortable reader width, touch targets, and keyboard navigation are implemented. | ✓ VERIFIED | `responsive_navigation_shell.dart:39-80` switches at 900 px; `reader_page.dart:116-167` provides wide/compact reader layouts and `:72-85` keyboard bindings; `app_theme.dart:121-123` sets 44 px icon targets. Focused widget tests pass for compact/wide navigation, wide reader, and arrow-key selection. |
| 3 | The offline library preserves distinct EPUBs, exposes consistent search/import state, and durably restores accurate reading progress. | ✗ FAILED | The repository aliases colliding distinct payloads (`saved_book_repository.dart:75-81,137-143`), writes JSON in place (`:98-105,119-128`), and the controller launches final flushes unawaited (`main.dart:181-202,333-341`). Progress counts the active sentence complete before playback completion (`:219-230,416-430`). Search/import state defects are visible at `library_view.dart:38-68,158-175` and `main.dart:462-518,669-692`. |
| 4 | The reader remains synchronized with the selected chapter and active audio across cancellation and replacement streams. | ✗ FAILED | `main.dart:387-430` resumes after awaited iterator/audio operations without a generation check, while `:446-459` clears/cancels shared stream fields and `:624-633` changes chapters without awaiting cancellation. An old stream can overwrite the new chapter's active index and play stale audio. |
| 5 | Native EPUB picking, offline TTS synthesis, and real audio playback remain operational end-to-end on Android and Windows. | ⚠️ PRESENT_BEHAVIOR_UNVERIFIED | Production calls are wired (`main.dart:462-483,356-430,599-647`), but no test invokes the native picker, real engine, or real player. Device-level behavior remains unproven. |
| 6 | RTF, MOS, queue, and memory metrics remain reachable and functional in the redesigned production flow. | ✗ FAILED | `_lastResult` has no non-null assignment anywhere in `lib/main.dart`; it is reset at `:296,376,516,551`. Consequently RTF at `:617`, MOS at `:571-592`, and report at `:733-746` are unreachable. The player still enables MOS at `audio_player_control_bar.dart:129-144`; no queue or memory metric surface was found. |
| 7 | Automated coverage exercises the required library, reader, import-state, responsive-player, persistence, and synchronization behavior. | ✗ FAILED | All 14 focused tests pass, but coverage is isolated and incomplete: no compact reader/player assertion, no import processing/error/re-entry test, no stream cancellation test, no restart/durability test, no hash-collision test, and no production MOS/RTF path test. |

**Score:** 2/7 truths verified (1 present and wired, behavior-unverified)

### Scope and Deferred Work

EPUB pagination is explicitly outside Phase 14 and is not treated as a gap. No identified blocker is deferred by a later roadmap phase: Phase 15 covers load/telemetry evaluation and Phase 16 documentation, neither explicitly closes Phase 14's persistence, synchronization, or production metrics wiring defects.

### Required Artifacts

The plan frontmatter declares no `must_haves.artifacts`; these artifacts were derived from the phase goal and UI specification.

| Artifact | Expected | Status | Details |
| --- | --- | --- | --- |
| `lib/ui/app_theme.dart` | Mockup-derived colors, type, spacing, breakpoints, touch targets | ✓ VERIFIED | Exists, substantive, imported by `main.dart` and all redesigned widgets; token values match `design_mockup.html`. |
| `lib/ui/widgets/responsive_navigation_shell.dart` | Compact bottom navigation and wide rail | ✓ VERIFIED | Exists, substantive, wired from `main.dart:724-730`, and both breakpoint branches are tested. |
| `lib/ui/widgets/library_view.dart` | Clean library, search, import/empty/error states, saved-book actions | ⚠️ PARTIAL | Exists, substantive, and receives real repository data, but visible search/import state can diverge from controller state. |
| `lib/ui/widgets/reader_page.dart` | Responsive reader composition, chapter selection, keyboard, player | ✓ VERIFIED | Exists, substantive, wired from `main.dart:609-649`; dynamic book/sentence/player data flows into it. Controller ordering defects prevent the overall synchronization truth from passing. |
| `lib/ui/widgets/reader_document_view.dart` | Continuous text with active/pending treatment | ✓ VERIFIED | Exists, substantive, wired through `ReaderPage`; renders segmented EPUB sentences and active/pending indices. Gesture semantics/lifecycle remain warning-level UAT concerns. |
| `lib/ui/widgets/audio_player_control_bar.dart` | Responsive real-player controls and MOS action | ⚠️ HOLLOW | Playback callbacks are wired, but the MOS control is enabled while its production callback can only return early. |
| `lib/core/document/saved_book_repository.dart` | Offline EPUB storage, deduplication, update/load/delete | ✗ DEFECTIVE | Exists, substantive, and wired, but distinct files can alias and metadata/progress durability is not safely preserved. |
| `lib/main.dart` | Service/state controller preserving EPUB, TTS, audio, metrics, and UI links | ✗ DEFECTIVE | UI/service links exist; stale-stream ordering and disconnected metrics break must-have truths. |
| `test/ui/redesign_widgets_test.dart` and focused phase tests | Behavioral coverage for the phase acceptance contract | ⚠️ PARTIAL | Four files contain 14 passing tests, but critical state transitions and production wiring are untested. |

### Key Link Verification

The plan frontmatter declares no `must_haves.key_links`; links below were derived goal-backward.

| From | To | Via | Status | Details |
| --- | --- | --- | --- | --- |
| `design_mockup.html` | `lib/ui/app_theme.dart` and redesigned widgets | Exact palette/type/layout translation | ✓ WIRED | Colors `#12151C`, `#1B1F29`, `#242938`, `#EDE7D6`, `#E3A452`, `#4FA9A6`, `#E2694F`, and `#2B303F` match. |
| `lib/main.dart` | navigation/library/settings/reader widgets | Widget construction and callbacks | ✓ WIRED | All extracted widgets are instantiated and supplied live state/callbacks. |
| Native picker/importer | saved repository and reader | `_importEpub` | ⚠️ PARTIAL | Real selected bytes flow to importer/repository/reader, but import is re-entrant and persistence failure is silently degraded to session-only reading. |
| Pipeline orchestrator | audio player and active reader sentence | streaming iterator, `loadAudioBuffer`, `play` | ✗ NOT RELIABLY WIRED | Nominal flow exists, but cancellation/replacement ordering can reactivate stale stream data. |
| Streamed sentence metrics | `PipelineResult` → RTF/MOS/report UI | `_lastResult` | ✗ NOT WIRED | Stream items contain metrics, but no aggregation or non-null `_lastResult` assignment exists. |
| Saved repository | library tiles and resume position | list/save/load/update/delete | ⚠️ PARTIAL | Real files and records flow, but identity, atomicity, completion semantics, and final flush durability are incorrect. |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
| --- | --- | --- | --- | --- |
| `LibraryView` | `books`, `searchQuery`, import/error/status | `SavedBookRepository.list/saveNew`, controller state | Yes, with integrity/state defects | ⚠️ PARTIAL |
| `ReaderPage` / `ReaderDocumentView` | book, chapter, sentences, active/pending index | Native EPUB bytes → importer → sentence segmenter → stream item | Yes | ⚠️ FLOWING WITH ORDERING RISK |
| `AudioPlayerControlBar` | audio state, position, duration, speed | `AudioPlayerService` streams and callbacks | Yes for nominal playback controls | ✓ FLOWING |
| RTF/MOS/report surfaces | `_lastResult` | Expected stream-metric aggregation | No; null-only | ✗ DISCONNECTED |
| Saved progress tiles/resume | `SavedBookRecord` | controller progress calculation → repository JSON | Yes, but premature and not durably committed | ✗ INCORRECT FLOW |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| Phase-focused tests | Direct Flutter tool invocation for the four Phase 14 test files | `+14: All tests passed!` in 12.9 s | ✓ PASS |
| Changed-file static analysis | Direct Dart analyzer over 14 changed Dart source/test files | `No issues found!` in 3.5 s | ✓ PASS |
| Distinct EPUB identity | Node reproduction of the repository's FNV-1a algorithm for `B906FB55A0217D2B` and `DC3A4CA786B73DE7` | Both produce `257996d5` | ✗ FAIL |
| Native picker/TTS/audio | Requires Android/Windows platform services and stateful playback | Not runnable under non-mutating verifier constraints | ? HUMAN |

### Probe Execution

No probe path or PASS-marker probe is declared by the Phase 14 plan or summary. Step 7c is not applicable.

### Requirements Coverage

Phase 14's plan frontmatter declares **no requirement IDs**. `REQUIREMENTS.md` also contains no requirement mapped to Phase 14, so there are no plan-declared IDs to cross-reference and no Phase 14 orphaned requirement mapping. Existing RF/RNF entries were not silently inferred as Phase 14 declarations.

| Requirement | Source Plan | Description | Status | Evidence |
| --- | --- | --- | --- | --- |
| None declared | `14-PLAN.md` | No `requirements:` frontmatter field | N/A | Explicit frontmatter and `REQUIREMENTS.md` scan found no Phase 14 IDs/mapping. |

### Anti-Patterns and Adversarial Findings

| File | Line | Pattern | Severity | Impact |
| --- | --- | --- | --- | --- |
| `lib/core/document/saved_book_repository.dart` | 75-81, 137-143 | Short non-cryptographic hash used as identity and deduplication proof | 🛑 BLOCKER | Different EPUBs can silently resolve to the same saved book. |
| `lib/core/document/saved_book_repository.dart` | 98-105, 119-128 | Direct canonical metadata overwrite | 🛑 BLOCKER | Interrupted writes can hide a saved book and orphan its EPUB payload. |
| `lib/main.dart` | 181-202, 333-341 | Unawaited final persistence/cancellation | 🛑 BLOCKER | Latest reading state is not guaranteed durable before close/suspend/dispose. |
| `lib/main.dart` | 387-459, 624-633 | Async shared-state mutation without generation guard | 🛑 BLOCKER | Cancelled old streams can load/play stale audio in a new chapter. |
| `lib/main.dart` | 76, 296, 376, 516, 551, 571-617 | Null-only metrics state behind enabled controls | 🛑 BLOCKER | RTF, MOS, and academic report are unreachable. |
| `lib/ui/widgets/library_view.dart` | 38-68 | Filter state not represented in the search field | ⚠️ WARNING | A blank visible field can conceal an active filter after navigation. |
| `lib/ui/widgets/reader_document_view.dart` | 38-80 | Gesture recognizers disposed/recreated during build | ⚠️ WARNING | Playback-driven rebuilds can interrupt taps; active/pending state is visual-only for assistive technology. |

No unreferenced `TBD`, `FIXME`, or `XXX` debt markers were found in Phase 14 changed files. Guard returns and empty initial collections were inspected and are not stubs.

#### Disconfirmation Pass

- **Partial requirement:** Responsive tests prove compact/wide navigation and a wide reader, but not the compact reader/player or the 700-900 px intermediate range.
- **Misleading passing test:** `audio_player_widget_test.dart` proves an injected MOS callback fires; production's injected callback returns immediately because `_lastResult` is always null.
- **Uncovered error path:** No test exercises cancellation during `moveNext`/audio load, interrupted metadata writes, storage failures, or lifecycle termination with a pending progress write.

### Human Verification Required

These checks remain necessary after blocker fixes; they do not downgrade observable code failures to uncertainty.

#### 1. Visual fidelity on Android and Windows

**Test:** Compare the running library, reader, selection confirmation, and player against `design_mockup.html` at phone, intermediate, and wide desktop sizes.
**Expected:** Editorial hierarchy, spacing, contrast, continuous text, player anchoring, and no overflows match the design language.
**Why human:** Source tokens and widget structure cannot establish final rendered fidelity or platform font fallback quality.

#### 2. Native file-picking and import states

**Test:** On Android and Windows, import a valid EPUB, cancel selection, choose an invalid/unsupported file, and rapidly attempt a second import.
**Expected:** Native picking works, every state is understandable, and only one import can control the resulting reader/library state.
**Why human:** Platform picker behavior is not exercised by focused tests.

#### 3. Real TTS and audio synchronization

**Test:** Synthesize and play a real chapter, pause/resume/seek/stop, select a sentence, change chapters during synthesis/playback, and use keyboard/touch/mouse controls.
**Expected:** Audio and active highlighting remain synchronized; cancelled/replaced streams never resume; controls remain responsive.
**Why human:** Native engine/audio integration and perceptual synchronization require device execution.

#### 4. Restart persistence and MOS/metrics

**Test:** After fixes, close/suspend/restart during reading and after playback, then open the book and submit MOS while inspecting RTF, queue, and memory metrics.
**Expected:** The exact intended resume position is restored durably; metrics are real and reachable; MOS saves and remains visible.
**Why human:** Process termination, native storage timing, perceptual MOS, and device metrics cannot be proven by widget presence.

### Gaps Summary

Four root concerns block the phase goal:

1. Saved-library identity and progress are not reliable: distinct EPUBs can alias, metadata writes are not transactional, close/lifecycle flushes are not awaited, and progress advances before playback completion.
2. Stream cancellation is not ordered safely, allowing stale chapter audio/state to resume after replacement.
3. The redesigned production flow disconnects streamed metrics from `PipelineResult`, making RTF, MOS, reports, queue, and memory metrics unavailable or inert.
4. The green 14-test suite does not cover the behavior-dependent paths above or the complete responsive/import acceptance surface.

`14-REVIEW.md` was treated as advisory. Its relevant claims were independently reproduced through source tracing, a deterministic collision check, focused tests, and direct changed-file analysis. Pagination was excluded from the gap set exactly as instructed.

---

_Verified: 2026-08-01T20:01:54Z_
_Verifier: the agent (gsd-verifier)_
