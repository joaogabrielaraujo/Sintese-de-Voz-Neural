# Phase 14: UI Redesign Gap Closure - Pattern Map

**Mapped:** 2026-08-01
**Files analyzed:** 10 likely new/modified files
**Analogs found:** 10 / 10 at file level; 2 required subpatterns have no exact local implementation
**Scope:** Four verified gap areas only. EPUB pagination remains explicitly deferred; retain the continuous chapter reader.

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `pubspec.yaml` | config | transform | Existing dependency block in `pubspec.yaml:9-18` | exact (same file) |
| `lib/core/document/saved_book_repository.dart` | service | CRUD + file-I/O | Existing `SavedBookRepository` plus the serialized write drain in `lib/main.dart:244-265` | exact role; partial behavior |
| `lib/main.dart` | controller | streaming + event-driven + file-I/O | Existing stream/persistence controller in `lib/main.dart:138-163,205-265,356-459` | exact (same file) |
| `lib/ui/widgets/library_view.dart` | component | event-driven + request-response | Existing callback-driven `LibraryView` in `lib/ui/widgets/library_view.dart:6-109` | exact (same file) |
| `lib/ui/widgets/reader_page.dart` | component | streaming + event-driven | Existing responsive `_PlayerPane` composition in `lib/ui/widgets/reader_page.dart:116-167,291-382` | exact (same file) |
| `lib/ui/widgets/audio_player_control_bar.dart` | component | event-driven | Existing control callbacks in `lib/ui/widgets/audio_player_control_bar.dart:88-160`; disabled-control precedent in `reader_page.dart:250-280` | exact role |
| `test/core/document/saved_book_test.dart` | test | CRUD + file-I/O | Existing real-temp-directory repository tests in `test/core/document/saved_book_test.dart:51-129` | exact |
| `test/ui/redesign_widgets_test.dart` | test | event-driven + responsive | Existing explicit viewport and callback tests in `test/ui/redesign_widgets_test.dart:18-60,142-216` | exact |
| `test/ui/audio_player_widget_test.dart` | test | event-driven | Existing player callback/MOS test in `test/ui/audio_player_widget_test.dart:22-60` | exact |
| `test/ui/app_flow_test.dart` (new) | test | streaming + event-driven + file-I/O | `test/widget_test.dart:4-10`, `test/ui/redesign_widgets_test.dart:142-216`, and controlled async tests in `test/core/memory/circular_audio_buffer_test.dart:135-151` | role-match |

`lib/core/pipeline/pipeline_result.dart`, `lib/core/pipeline/pipeline_orchestrator.dart`, `lib/core/memory/circular_audio_buffer.dart`, and `lib/core/memory/memory_stats.dart` are reference sources first. Modify them only if the planner chooses to extract a reusable live telemetry model instead of keeping aggregation in `main.dart`.

## Pattern Assignments

### `pubspec.yaml` (config, transform)

**Analog:** the existing dependency block in `pubspec.yaml`.

**Dependency placement pattern** (`pubspec.yaml:9-18`):

```yaml
dependencies:
  flutter:
    sdk: flutter
  path: ^1.9.0
  path_provider: ^2.1.2
  audioplayers: ^6.0.0
  flutter_tts: ^4.0.2
  sherpa_onnx: ^1.10.15
  file_picker: ^11.0.2
  archive: ^4.0.9
```

**Assignment:** add the digest library in this block and use a collision-resistant content digest (SHA-256 or stronger) for newly saved EPUBs. There is no digest package or cryptographic hash implementation in the repository today. Do not hand-roll a replacement for the current FNV loop.

**Compatibility constraint:** new IDs may use the full digest, but existing `book-[a-f0-9]{8}` records must remain readable or be migrated transactionally. Do not strand the Phase 14 library when tightening `_isSafeId`.

---

### `lib/core/document/saved_book_repository.dart` (service, CRUD + file-I/O)

**Analogs:** the repository's current dependency injection/path boundary, its tolerant listing behavior, and `main.dart`'s serialized write drain.

**Imports and injectable boundary** (`saved_book_repository.dart:1-20`):

```dart
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'epub_model.dart';
import 'saved_book.dart';

typedef SupportDirectoryProvider = Future<Directory> Function();

class SavedBookRepository {
  final SupportDirectoryProvider _supportDirectoryProvider;

  SavedBookRepository({SupportDirectoryProvider? supportDirectoryProvider})
      : _supportDirectoryProvider =
            supportDirectoryProvider ?? getApplicationSupportDirectory;
```

Copy this provider-injection style for a digest function and, if needed for deterministic failure tests, a narrow file-operation seam. It permits forced hash-collision and interrupted-write tests without platform storage.

**Directory and path construction** (`saved_book_repository.dart:22-27,130-135`):

```dart
Future<Directory> _booksDirectory() async {
  final root = await _supportDirectoryProvider();
  final directory = Directory(p.join(root.path, 'saved_books'));
  await directory.create(recursive: true);
  return directory;
}

String _epubPath(Directory directory, String id) =>
    p.join(directory.path, '$id.epub');
String _jsonPath(Directory directory, String id) =>
    p.join(directory.path, '$id.json');

bool _isSafeId(String id) => RegExp(r'^book-[a-f0-9]{8}$').hasMatch(id);
```

Preserve the single private directory and validate every loaded/caller-supplied ID before constructing paths. Expand the accepted form deliberately for full digests and any deterministic collision suffix; keep legacy IDs readable.

**Corruption isolation pattern** (`saved_book_repository.dart:29-48`):

```dart
Future<List<SavedBookRecord>> list() async {
  final directory = await _booksDirectory();
  final records = <SavedBookRecord>[];
  await for (final entity in directory.list()) {
    if (entity is! File || !entity.path.endsWith('.json')) continue;
    try {
      final json = jsonDecode(await entity.readAsString());
      if (json is Map<String, dynamic>) {
        final record = SavedBookRecord.fromJson(json);
        if (_isSafeId(record.id) &&
            await File(_epubPath(directory, record.id)).exists()) {
          records.add(record);
        }
      }
    } on Object {
      // One corrupt record does not block the whole library.
    }
  }
  records.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  return records;
}
```

Keep per-record isolation, but run transaction recovery/cleanup before scanning canonical JSON files. A malformed canonical file with a valid backup should be recovered, not merely ignored.

**Serialized update pattern to retain** (`main.dart:244-265`):

```dart
Future<void> _flushProgressWrites() async {
  _progressSaveTimer?.cancel();
  _progressSaveTimer = null;
  if (_progressWriteFuture != null) {
    await _progressWriteFuture;
    return;
  }
  final future = _drainProgressWrites();
  _progressWriteFuture = future;
  try {
    await future;
  } finally {
    if (identical(_progressWriteFuture, future)) _progressWriteFuture = null;
  }
}

Future<void> _drainProgressWrites() async {
  while (_pendingProgressRecord != null) {
    final record = _pendingProgressRecord!;
    _pendingProgressRecord = null;
    await _savedBookRepository.update(record);
  }
}
```

Repository updates should still be serialized by the caller. Each individual repository update must also be crash-safe.

**Do not copy** (`saved_book_repository.dart:75-81,98-105,119-143`): the eight-hex FNV identity and direct writes to canonical `.json`/`.epub` files are the verified defects.

**Required new behavior with no exact local analog:**

- Compute a full collision-resistant digest.
- Treat matching digest as a candidate, then compare payload length and bytes before deduplicating.
- If a digest provider returns the same digest for different bytes, preserve both payloads under deterministic safe IDs rather than aliasing them.
- Write same-directory temporary files with `flush: true`, then replace canonical metadata through a recoverable rename/backup protocol. Clean stale temp files and recover valid backups during repository initialization/listing.
- Never publish metadata that points to a missing payload; clean orphaned temporary artifacts after success and after recovery.

---

### `lib/main.dart` (controller, streaming + event-driven + file-I/O)

**Analogs:** the existing injected document boundary, audio-completion listener, serialized progress writer, and stream start/stop lifecycle.

**Constructor injection seam** (`main.dart:46-54`):

```dart
class PoCNeuralHomePage extends StatefulWidget {
  final EpubDocumentPicker picker;
  final EpubBytesImporter importer;

  const PoCNeuralHomePage({
    super.key,
    this.picker = const NativeEpubDocumentPicker(),
    this.importer = const EpubBytesImporter(),
  });
```

Extend this pattern narrowly so app-flow tests can provide a fake player, controlled pipeline/orchestrator, and temp-directory repository. Production defaults must remain unchanged.

#### Durable and completion-based progress

**Completion event is the authoritative boundary** (`main.dart:138-147`):

```dart
_stateSub = _audioPlayer.stateStream.listen((state) {
  if (mounted) setState(() => _audioState = state);
  if (state == TTSAudioState.completed &&
      _isStreaming &&
      !_completionHandledForActiveItem) {
    _completionHandledForActiveItem = true;
    unawaited(_advanceStreamingSentence());
  }
});
```

Use this event to mark the matching active item complete and persist it **before** advancing. Track the resume/current sentence separately from the last completed sentence. Do not calculate completion from `_activeSentenceIndex + 1` when audio is merely loaded.

**Existing coalesced persistence** (`main.dart:223-241`):

```dart
final updated = record.copyWith(
  chapterIndex: chapter.index,
  sentenceIndex: _activeSentenceIndex,
  progress: totalCount == 0
      ? 0
      : (absolute / totalCount).clamp(0.0, 1.0).toDouble(),
  updatedAt: DateTime.now(),
);
_activeSavedBook = updated;
_pendingProgressRecord = updated;
_savedBooks = [
  updated,
  ..._savedBooks.where((item) => item.id != updated.id),
];
_progressSaveTimer?.cancel();
_progressSaveTimer = Timer(const Duration(seconds: 1), () {
  unawaited(_flushProgressWrites());
});
```

Keep coalescing and newest-record-wins ordering. Change the inputs so `sentenceIndex` means resume/current position while `progress` is derived from completed playback only. The last sentence must not produce `1.0` until its completion event.

**User-driven close requirement:** make close/chapter replacement async and await `_persistReadingProgress()` followed by `_flushProgressWrites()` before completing navigation/state replacement. `dispose()` cannot guarantee an awaited flush; durable checkpoints during playback and awaited close paths are the reliable pattern.

#### Stream generation and cancellation safety

**Existing start and ownership fields** (`main.dart:356-384`):

```dart
Future<void> _runMvpPipeline({int startSentenceIndex = 0}) async {
  if (_loadedBook == null || _currentChapter == null) return;

  await _stopStreamingPipeline();
  final queue = CircularAudioBuffer(maxItems: 3);
  final iterator = StreamIterator<SentenceAudioItem>(
    _orchestrator.processChapterStream(
      book: _loadedBook!,
      chapter: _currentChapter!,
      queue: queue,
      startSentenceIndex: startSentenceIndex,
    ),
  );

  setState(() {
    _streamQueue = queue;
    _streamIterator = iterator;
    _activeStreamingItem = null;
    _isStreaming = true;
  });
  await _advanceStreamingSentence();
}
```

**Existing cancellation cleanup** (`main.dart:446-459`):

```dart
Future<void> _stopStreamingPipeline() async {
  _isStreaming = false;
  final active = _activeStreamingItem;
  final iterator = _streamIterator;
  final queue = _streamQueue;
  _streamIterator = null;
  _streamQueue = null;
  _activeStreamingItem = null;
  if (active != null) queue?.release(active);
  queue?.cancel();
  if (iterator != null) await iterator.cancel();
  queue?.dispose();
}
```

Retain local capture and complete cleanup, but add a monotonically increasing generation. There is no exact local analog for the required stale-continuation guard. The planner should use this guard shape after **every** await that precedes state/audio mutation:

```dart
final generation = _streamGeneration;
final iterator = _streamIterator;
final hasNext = await iterator!.moveNext();
if (!mounted ||
    generation != _streamGeneration ||
    !identical(iterator, _streamIterator)) {
  return;
}
```

Repeat the check after `loadAudioBuffer`, `play`, and awaited cancellation boundaries. Increment/invalidate the generation before cancelling. Chapter change, stop, close, engine switch, and replacement start must await cancellation before installing or mutating chapter/audio state. Do not use `_isAdvancingStream` as the ownership token; it is only a re-entry guard.

#### Coherent import and search state

**Current import error mapping to preserve** (`main.dart:519-543`):

```dart
} on EpubImportException catch (error) {
  if (!mounted) return;
  setState(() {
    _errorMessage = error.message;
    _importStatus = 'Falha na importação';
  });
} on DocumentSelectionException catch (error) {
  if (!mounted) return;
  setState(() {
    _errorMessage = error.message;
    _importStatus = 'Falha ao ler o arquivo selecionado';
  });
}
```

Add a dedicated `_isImporting` single-flight guard, set it before `pickEpub()`, and clear it in `finally`. Keep cancellation distinct from error. Pass this state to `LibraryView`; synthesis `_isProcessing` must no longer control the import card.

Keep `_searchQuery` as the source of truth and either own/dispose a synchronized `TextEditingController` in this state object or make `LibraryView` synchronize one in `initState`/`didUpdateWidget`. Returning to Search must render `_searchQuery`, not only filter by it.

#### Live RTF, MOS, report, queue, and memory metrics

**Batch aggregation formula to copy** (`pipeline_orchestrator.dart:37-75`):

```dart
final List<ProcessedSentenceItem> items = [];
double accInferenceMs = 0.0;
double accAudioSec = 0.0;

// For each synthesized item:
accInferenceMs += synthesisResult.metrics.inferenceTimeMs;
accAudioSec += synthesisResult.metrics.audioDurationSeconds;

final double overallRtf = accAudioSec > 0
    ? (accInferenceMs / 1000.0) / accAudioSec
    : 0.0;

return PipelineResult(
  bookTitle: book.title,
  chapterTitle: chapter.title,
  items: items,
  totalInferenceTimeMs: accInferenceMs,
  totalAudioDurationSeconds: accAudioSec,
  overallRtf: overallRtf,
);
```

Apply the same accumulator to each streamed `SentenceAudioItem` (`sentence_audio_item.dart:8-19`). Update a live telemetry snapshot after each accepted-generation item, and retain a final snapshot when the queue is disposed. MOS/report should become enabled after valid data exists.

**Queue/memory sources are already public** (`circular_audio_buffer.dart:28-40`, `memory_manager.dart:12-17`):

```dart
CircularAudioBuffer({this.maxItems = 5});

bool get isFull => _queue.length >= maxItems;
bool get isEmpty => _queue.isEmpty;
int get length => _queue.length;
bool get isCompleted => _isCompleted;

MemoryStats get stats => MemoryStats(
      allocatedBytes: _allocatedBytes,
      purgedItemsCount: _purgedItemsCount,
      freedBytes: _freedBytes,
    );
```

Expose queue depth/capacity and immutable `MemoryStats` through controller state. Snapshot final stats before nulling/disposing the queue.

**Memory constraint:** do not retain every full PCM `AudioBuffer` merely to build telemetry. The batch `PipelineResult` is the formula/report analog, but a streaming implementation should retain scalar metrics and sentence metadata, or introduce a metadata-only/live result representation. Holding all `SentenceAudioItem` buffers would contradict the bounded-memory queue pattern.

---

### `lib/ui/widgets/library_view.dart` (component, event-driven + request-response)

**Analog:** existing data/callback-only `LibraryView`.

**Controlled filter pattern to retain** (`library_view.dart:6-17,36-47`):

```dart
final List<SavedBookRecord> books;
final bool searchMode;
final String searchQuery;
final ValueChanged<String> onSearchChanged;

final normalizedQuery = searchQuery.trim().toLowerCase();
final visibleBooks = normalizedQuery.isEmpty
    ? books
    : books.where(
        (book) =>
            book.title.toLowerCase().contains(normalizedQuery) ||
            book.author.toLowerCase().contains(normalizedQuery),
      ).toList(growable: false);
```

Continue filtering from the parent value. Bind the visible field to that same value via a controller; `onChanged` remains the callback to the controller.

**Import state surface** (`library_view.dart:71-83,158-183`):

```dart
_ImportCard(
  isProcessing: isProcessing,
  onImport: onImport,
),
Semantics(
  liveRegion: true,
  child: Text(importStatus),
)

onTap: isProcessing ? null : onImport,
if (isProcessing)
  const SizedBox.square(
    dimension: 28,
    child: CircularProgressIndicator(strokeWidth: 2),
  )
```

Rename/split this input to dedicated import state (`isImporting`, or a small import-state value). Keep the disabled tap, progress indicator, semantic label, live status, and `_ErrorBanner`; stop coupling these to synthesis processing.

**Validation:** search field text, filtered results, and `searchQuery` must agree after Search → another destination → Search. A cancelled picker returns to idle with a cancellation status; an error displays the banner; a second tap during import does nothing.

---

### `lib/ui/widgets/reader_page.dart` (component, streaming + event-driven)

**Analog:** the current responsive composition and player status row.

**Responsive structure** (`reader_page.dart:116-167`):

```dart
body: LayoutBuilder(
  builder: (context, constraints) {
    final wide = constraints.maxWidth >= AppBreakpoints.wide;
    // Build the same reading and player panes from callback-driven inputs.
    if (wide) {
      return Row(
        key: const Key('wide-reader-layout'),
        children: [
          Expanded(child: reading),
          const VerticalDivider(width: 1),
          SizedBox(width: 370, child: player),
        ],
      );
    }
    return Column(
      key: const Key('compact-reader-layout'),
      children: [Expanded(child: reading), player],
    );
  },
)
```

Do not create a second metrics layout. Add telemetry values to the existing `_PlayerPane` inputs so compact and wide readers render the same live data.

**Existing live status row** (`reader_page.dart:341-378`):

```dart
Row(
  children: [
    Expanded(
      child: Semantics(
        liveRegion: true,
        child: Text(synthesisStatus),
      ),
    ),
    Text('Frase $activeSentence/$sentenceCount'),
    if (rtf != null) ...[
      const SizedBox(width: AppSpacing.sm),
      Text('RTF ${rtf!.toStringAsFixed(3)}'),
    ],
  ],
),
AudioPlayerControlBar(
  // callbacks and current player values
)
```

Extend this surface with queue depth/capacity and allocated/freed memory using `Wrap` or a wrapping metric row, so intermediate and compact widths cannot overflow. Keep RTF conditional on real data; use explicit unavailable text only if needed for explanation.

---

### `lib/ui/widgets/audio_player_control_bar.dart` (component, event-driven)

**Analog:** existing responsive controls and Flutter's nullable `onPressed` disabled state.

**Responsive control pattern** (`audio_player_control_bar.dart:88-160`):

```dart
LayoutBuilder(
  builder: (context, constraints) {
    final compact = constraints.maxWidth < 430;
    // Build shared speed, playback, and MOS controls.
    if (compact) {
      return Wrap(
        key: const Key('compact-player-controls'),
        alignment: WrapAlignment.spaceBetween,
        children: [speedSelector, playbackControls, mosButton],
      );
    }
    return Row(
      key: const Key('wide-player-controls'),
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [speedSelector, playbackControls, mosButton],
    );
  },
)
```

**Disabled-action precedent** (`reader_page.dart:271-280`):

```dart
FilledButton.icon(
  onPressed: isProcessing ? null : onConfirmSelection,
  icon: const Icon(Icons.play_arrow),
  label: const Text('Continuar'),
)
```

Make MOS availability explicit (`VoidCallback? onOpenMOSDialog` or `canOpenMos` plus callback) and set `onPressed: null` until live metrics exist. Supply an explanatory tooltip/semantic label while disabled. Do not leave an enabled callback that returns immediately.

---

### `test/core/document/saved_book_test.dart` (test, CRUD + file-I/O)

**Analog:** existing repository tests against a real temporary directory.

**Isolation and cleanup** (`saved_book_test.dart:51-68`):

```dart
group('SavedBookRepository', () {
  late Directory supportDirectory;
  late SavedBookRepository repository;

  setUp(() async {
    supportDirectory = await Directory.systemTemp.createTemp(
      'vozlume-saved-books-',
    );
    repository = SavedBookRepository(
      supportDirectoryProvider: () async => supportDirectory,
    );
  });

  tearDown(() async {
    if (await supportDirectory.exists()) {
      await supportDirectory.delete(recursive: true);
    }
  });
```

**Round-trip assertion pattern** (`saved_book_test.dart:86-107`):

```dart
final first = await repository.saveNew(
  fileName: 'dom-casmurro.epub',
  bytes: bytes,
  book: book,
);
final duplicate = await repository.saveNew(
  fileName: 'outra-copia.epub',
  bytes: bytes,
  book: book,
);
await repository.update(
  first.copyWith(chapterIndex: 0, sentenceIndex: 2, progress: .75),
);

final records = await repository.list();
final loaded = await repository.load(first.id);
expect(duplicate.id, first.id);
expect(records, hasLength(1));
expect(loaded!.bytes, bytes);
```

Add focused cases for:

- The two distinct legacy-FNV-collision payloads identified by verification (`B906FB55A0217D2B` and `DC3A4CA786B73DE7`) produce distinct saved records.
- An injected digest collision still compares payload bytes and preserves both records.
- Identical bytes still deduplicate.
- Restart durability: update, construct a new repository over the same directory, then load the exact checkpoint.
- Interrupted metadata replacement: stale temp/backup/corrupt-canonical arrangements recover the last valid record and clean transaction artifacts.
- Legacy eight-hex IDs remain readable or migrate without payload loss.

---

### `test/ui/redesign_widgets_test.dart` (test, event-driven + responsive)

**Analog:** explicit viewport control and callback-driven widget factories.

**Viewport pattern** (`redesign_widgets_test.dart:19-46`):

```dart
tester.view.physicalSize = const Size(390, 800);
tester.view.devicePixelRatio = 1;
addTearDown(tester.view.resetPhysicalSize);
addTearDown(tester.view.resetDevicePixelRatio);

await tester.pumpWidget(themed(/* widget */));
```

**Reader fixture pattern** (`redesign_widgets_test.dart:142-188`): build `ReaderPage` with a `MockAudioPlayerService`, fixed chapter/sentences, and no-op callbacks; override only the callback/state under test.

Add:

- A 390 px compact reader assertion for `compact-reader-layout`, `audio-player-control-bar`, and `compact-player-controls` with no overflow exception.
- An intermediate width below 900 px (for example 700-899 px) proving compact reader composition and usable player controls.
- Live RTF/queue/memory labels at compact and wide widths.
- Search field text equal to retained `searchQuery`, plus navigation/rebuild coverage if the controller remains outside this widget test.
- Import idle/processing/cancelled/error surfaces; while importing, tapping the keyed card must not invoke the callback.

Preserve the existing 900 px shell breakpoint and 700/430 px reader/control adaptation. Pagination assertions are out of scope.

---

### `test/ui/audio_player_widget_test.dart` (test, event-driven)

**Analog:** callback observability in the current control test (`audio_player_widget_test.dart:22-60`).

```dart
bool mosDialogCalled = false;

await tester.pumpWidget(
  MaterialApp(
    home: Scaffold(
      body: AudioPlayerControlBar(
        playerService: mockPlayer,
        currentState: TTSAudioState.stopped,
        currentPosition: Duration.zero,
        totalDuration: const Duration(seconds: 30),
        currentSpeed: 1.0,
        onPlayPausePressed: () {},
        onStopPressed: () {},
        onSeekChanged: (_) {},
        onSpeedChanged: (_) {},
        onOpenMOSDialog: () => mosDialogCalled = true,
      ),
    ),
  ),
);

await tester.tap(find.text('Avaliar MOS'));
expect(mosDialogCalled, isTrue);
```

Retain the enabled callback case, then add a disabled/no-metrics case that verifies `onPressed == null` behavior and explanatory semantics/tooltip. Test compact and wide labels without duplicating `ReaderPage` breakpoint coverage.

---

### `test/ui/app_flow_test.dart` (new test, streaming + event-driven + file-I/O)

**Analogs:** `PoCNeuralHomePage` constructor injection (`main.dart:46-54`), `MockAudioPlayerService`'s interface-backed streams (`mock_audio_player_service.dart:8-20,97-123`), app smoke pumping (`test/widget_test.dart:4-10`), and controlled cancellation (`circular_audio_buffer_test.dart:135-151`).

**Controlled async cancellation pattern** (`circular_audio_buffer_test.dart:135-151`):

```dart
final blockedEnqueue = buffer.enqueue(fourth);

buffer.cancel();

await expectLater(blockedEnqueue, throwsStateError);
expect(buffer.isEmpty, isTrue);
expect(buffer.isCompleted, isTrue);
expect(buffer.memoryManager.stats.allocatedBytes, equals(0));
```

Create small test fakes implementing existing interfaces. Use `Completer<void>` gates around iterator emission and `loadAudioBuffer` so ordering is deterministic; do not use arbitrary delays as proof of cancellation safety.

Required behavioral cases:

1. Start stream A, block it after an await, cancel/change chapter/start stream B, release A, and assert only B can load/play audio or change the active sentence/status.
2. Complete one audio item and assert progress advances only on the matching `TTSAudioState.completed`; loading/starting the final sentence alone must not show 100%.
3. Trigger user-driven close and await the UI transition; reopen using a fresh repository/controller and assert the completed checkpoint was durable.
4. Start import, tap import again, and assert the fake picker was called once. Exercise success, cancellation, and error final states.
5. Synthesize one accepted-generation item and assert production UI shows live RTF, queue, and memory data; MOS becomes enabled and opens; the report action becomes reachable after returning to the library.

The existing mock engine/player classes are suitable foundations, but the stale-load test should use a recording/gated player so it can identify which stream's buffer reached `loadAudioBuffer` and `play`.

## Shared Patterns

### Dependency Injection for Deterministic Tests

**Sources:** `main.dart:46-54`, `saved_book_repository.dart:11-20`, `test/core/document/saved_book_test.dart:55-61`.

Apply to repository hashing/storage and app-level pipeline/audio dependencies. Keep defaults in production constructors and inject only interface/provider types in tests.

### Async Ownership and Cleanup

**Sources:** `main.dart:244-265`, `main.dart:446-459`, `circular_audio_buffer.dart:130-153`.

Use local captures, serialized futures, `try/finally`, queue cancellation, and complete disposal. Add generation/identity checks because existing cleanup alone does not prevent an already-awaited continuation from resuming.

### Error and Visible State

**Sources:** `main.dart:519-543`, `library_view.dart:76-88,280-309`.

Map typed import/selection failures to user-facing messages. Keep status in a live region and errors in the keyed banner. Cancellation is a non-error terminal state. A dedicated import state owns card enablement.

### Streaming Metrics

**Sources:** `pipeline_orchestrator.dart:37-75`, `sentence_audio_item.dart:8-19`, `circular_audio_buffer.dart:28-40`, `memory_stats.dart:12-22`.

Use the batch RTF formula with accepted streamed items, and expose queue/memory snapshots already available from the buffer. Keep PCM lifetime bounded by the queue.

### Responsive Tests

**Sources:** `redesign_widgets_test.dart:19-60,190-205`, `audio_player_control_bar.dart:88-160`.

Set physical size and pixel ratio explicitly, register teardown resets, pump the callback-driven public widget, and assert stable keys for compact/wide branches. Add 390 px and intermediate-width reader/player coverage.

### Authentication

Not applicable. This is an offline local Flutter app and no authentication/authorization pattern exists in the scoped code.

## No Exact Local Analog

No target file lacks a role-level analog, but two required behaviors are new to this codebase:

| File | Role | Data Flow | Missing Local Pattern | Planner Direction |
|---|---|---|---|---|
| `lib/core/document/saved_book_repository.dart` | service | file-I/O + CRUD | Recoverable transactional replacement and collision verification | Preserve provider/path/corruption-isolation conventions; implement same-directory temp + backup/rename recovery and byte verification after digest match. |
| `lib/main.dart` | controller | streaming + event-driven | Monotonic generation/iterator-identity guard after awaits | Add a generation token, invalidate before cancellation, and guard every post-await state/audio mutation. |

## Explicit Deferral

EPUB pagination remains outside Phase 14 gap closure. Do not add page models, page navigation, layout pagination, or pagination tests. Continue using `ReaderDocumentView` and the continuous chapter composition already present in `ReaderPage`.

## Metadata

**Analog search scope:** `lib/`, `test/`, `pubspec.yaml`, and Phase 14 context/verification/review/summary artifacts.

**Strong analog groups used:**

1. `lib/core/document/saved_book_repository.dart` + `test/core/document/saved_book_test.dart`
2. `lib/main.dart`
3. `lib/core/pipeline/pipeline_orchestrator.dart` + `lib/core/pipeline/pipeline_result.dart`
4. `lib/core/memory/circular_audio_buffer.dart` + memory models/tests
5. `test/ui/redesign_widgets_test.dart` + `test/ui/audio_player_widget_test.dart`

**Pattern extraction date:** 2026-08-01

