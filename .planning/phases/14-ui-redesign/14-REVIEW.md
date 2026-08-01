---
phase: 14-ui-redesign
status: in_progress
depth: deep
files_reviewed: 18
critical: 0
warning: 4
info: 5
total: 9
fixed_warnings: 3
---

# Code Review - Phase 14 UI and project configuration

## Scope

Reviewed the Flutter application, persistence layer, TTS configuration, asset layout, Android/Windows configuration, and the current phase changes. The first remediation pass is recorded below.

## Warnings

### WR-01 - Progress persistence performs disk I/O on every sentence

`_persistReadingProgress()` writes JSON and calls `setState` for every active sentence. On long EPUBs this can create frequent disk writes, UI rebuilds, and overlapping unawaited writes. It also makes progress persistence part of the audio timing path.

Recommendation: debounce writes (for example 1-2 seconds), serialize repository writes, and always flush once on reader close/background.

### WR-02 - Saved books can accumulate duplicate EPUB payloads

Every new import creates a new ID based on the current timestamp. Importing the same EPUB repeatedly stores another full copy of the bytes. There is no delete, replacement, or storage quota policy.

Recommendation: derive a content fingerprint, replace an existing record for the same EPUB, and add delete/clear-library actions with a storage limit.

### WR-03 - Chapter sentence analysis is repeated for the whole book

`_prepareChapterSentences()` segments every chapter whenever the current chapter changes. For large books this is synchronous work on the UI isolate and can cause visible stalls.

Recommendation: cache sentence models/counts per chapter, or compute counts once during import in a background isolate.

### WR-04 - Main screen remains a large stateful controller

`lib/main.dart` still owns library, settings, reader, persistence, engine switching, streaming, audio state, and dialogs. This makes future changes risky and increases rebuild scope.

Recommendation: split into `LibraryPage`, `SettingsPage`, `ReaderPage`, a reading-session controller, and a repository/service boundary.

## Informational findings

### INFO-01 - Duplicate model asset

`models/pt_BR-faber-medium.onnx` and `assets/models/pt_BR-faber-medium.onnx` are identical 63 MB copies. The configured asset path uses `assets/models`; the root `models/` copy appears redundant and increases repository size.

### INFO-02 - Runtime asset footprint is large

The full `espeak-ng-data` tree is bundled and copied to the application directory during engine initialization. This increases package size, first-run time, and local storage usage. Confirm whether all language dictionaries are required for the selected PT-BR voice before reducing the bundle.

### INFO-03 - Configuration is not release-ready

The Android namespace/application ID still uses `com.example.tcc_tts_neural`, and the Android manifest requests `INTERNET` even though the core product goal is offline operation. These may be intentional for development, but should be resolved before release.

### INFO-04 - Build/test verification is currently unreliable in this workspace

`flutter analyze`, targeted tests, and the Windows debug build previously exceeded the configured timeout. This blocks confidence in the current compile/test state and should be resolved before a large refactor.

### INFO-05 - Generated/build artifacts need explicit hygiene

The repository contains both source model directories and generated platform/build trees. Confirm that build outputs remain ignored and that only the intended model asset location is tracked.

## Positive observations

- EPUB persistence is isolated from the parser and uses the platform-private application support directory.
- The file picker path uses selected bytes and does not require broad Android storage permissions.
- Release signing is guarded by environment/property checks instead of embedding credentials.
- The TTS engine validates model files and required `espeak-ng-data` files before initialization.

## Fixes applied

- WR-01: progress updates are debounced, serialized, and flushed when the reader closes or the app changes lifecycle state.
- WR-02: saved EPUBs use a content fingerprint to avoid duplicate payloads and can be removed from the library.
- WR-03: sentence models and per-chapter counts are built once per loaded book and reused when changing chapters.

WR-04 remains as a structural refactor candidate. INFO-01 through INFO-05 remain pending because they require separate asset/configuration decisions or a longer build-validation window.

## Recommended order of work

1. Restore reliable `flutter analyze` and Windows/widget test execution.
2. Debounce and serialize progress persistence.
3. Deduplicate saved EPUBs and add storage management.
4. Cache chapter segmentation.
5. Remove the redundant root model and audit the espeak asset footprint.
6. Split `main.dart` before implementing pagination.
