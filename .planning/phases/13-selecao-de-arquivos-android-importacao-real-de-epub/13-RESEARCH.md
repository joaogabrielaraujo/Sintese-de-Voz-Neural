# Phase 13: Seleção de Arquivos Android & Importação Real de EPUB — Research

## User Constraints

- A Fase 13 redefine o trabalho anteriormente reservado para telemetria: seu foco será permitir seleção de arquivos no Android e importação real de EPUB.
- A plataforma prioritária é Android, usando o seletor nativo de arquivos do sistema.
- O único formato aceito nesta fase é `.epub`; PDF e TXT ficam para uma fase posterior.
- O usuário deve conseguir selecionar um EPUB armazenado em qualquer pasta acessível pelo seletor do Android.
- A implementação deve reutilizar o parser EPUB, a pipeline de leitura e os modelos de documento já existentes, substituindo o EPUB simulado atual.
- A aplicação não deve solicitar permissão ampla de armazenamento quando o seletor nativo puder conceder acesso ao arquivo escolhido.

## Research Summary

The implementation should use Android's Storage Access Framework through Flutter's native file-picker integration. The selected document should be read as bytes and passed to a ZIP/EPUB boundary, while the existing `EpubParser` remains the source of chapter and metadata behavior. The phase should stop at selecting, validating, parsing, displaying, and sending a real EPUB chapter into the existing pipeline.

## Standard Stack

- `file_picker` for the Flutter-facing native file picker, filtered to `epub` and configured to expose the selected file data when the parser needs bytes. `[CITED: https://pub.dev/packages/file_picker]`
- `archive` for decoding the EPUB ZIP container from bytes using `ZipDecoder.decodeBytes`. `[CITED: https://pub.dev/documentation/archive/latest/archive/ZipDecoder-class.html]`
- Android Storage Access Framework semantics as the platform contract: `ACTION_OPEN_DOCUMENT` lets the user select a document and grants access to the selected URI without broad storage permissions. `[CITED: https://developer.android.com/training/data-storage/shared/documents-files]`
- Existing project modules: `lib/core/document/epub_model.dart`, `lib/core/document/epub_parser.dart`, `lib/core/document/html_sanitizer.dart`, `lib/core/pipeline/pipeline_orchestrator.dart`, and the import flow in `lib/main.dart`. `[VERIFIED: codebase files read this session]`

## Architecture Patterns

### 1. File selection boundary

Introduce a small document-selection abstraction between the UI and package API. It should return either a selected document value (name, extension, bytes, optional path/URI metadata) or a cancellation result. This keeps `FilePicker` out of the page state and makes cancellation, invalid extension, and test doubles deterministic.

### 2. Bytes-to-archive boundary

Add a real-file adapter that converts selected EPUB bytes into the map expected by `EpubParser.parseArchive`. Normalize archive entry paths before passing them to the parser, preserve UTF-8 XHTML/XML content, and reject malformed ZIPs with a user-facing domain error.

### 3. UI state transition

The page should expose an explicit import action and model the states `idle`, `picking`, `parsing`, `ready`, and `error`. Successful import replaces the sample book; cancellation returns to the previous state without showing an error. Chapter selection continues to use the existing `EpubBook`/`EpubChapter` values and existing pipeline action.

### 4. Tracer-first integration

The first production slice should prove: tap import → Android picker opens → select EPUB → parse real bytes → show metadata/chapter → select chapter → invoke current pipeline. Unit tests can cover the byte/parser boundary; a manual Android smoke test must cover the actual picker.

## Don't Hand-Roll

- Do not request `MANAGE_EXTERNAL_STORAGE` or broad read-storage access for this import flow. Android's official document picker is designed for user-selected documents and avoids that permission class. `[CITED: https://developer.android.com/training/data-storage/shared/documents-files]`
- Do not implement a custom Android directory browser.
- Do not implement ZIP decompression manually; use `archive`'s ZIP decoder. `[CITED: https://pub.dev/packages/archive]`
- Do not duplicate EPUB OPF/spine parsing in the UI or importer. Reuse `EpubParser` and add only the adapter needed to supply real archive entries.
- Do not add PDF/TXT dispatch, persistent library storage, or phonetic processing in this phase.

## Common Pitfalls

- Android providers may return a content URI rather than a normal filesystem path; code must work from selected bytes or an input stream and must not assume `PlatformFile.path` is always available. `[CITED: https://developer.android.com/training/data-storage/shared/documents-files]`
- Filtering by extension is a UX aid, not file integrity validation. The importer must also validate that the content is a readable ZIP and contains the required EPUB structure.
- EPUB archive paths may use nested directories and URL-escaped hrefs; path resolution must remain compatible with the existing OPF/spine logic.
- Large books should not be synthesized while the picker callback is still updating the widget. Parse off the UI event path and show progress/error state.
- A canceled picker result is normal control flow, not an exception.
- Existing tests use in-memory archive maps; retain those tests and add a real ZIP-bytes fixture so the new adapter is tested without requiring a device.
- The project currently embeds a simulated EPUB in `lib/main.dart`; leaving that as the default can hide regressions. The plan must make real import the primary path while retaining a deterministic fallback only for tests/demo environments.

## Verification Strategy

1. Unit-test extension filtering, cancellation, malformed bytes, missing `META-INF/container.xml`, and successful ZIP-to-archive conversion.
2. Preserve and extend existing EPUB parser tests for metadata, spine ordering, HTML sanitization, and UTF-8 accented text.
3. Widget-test import states with a fake selector and verify the loaded book replaces the sample book.
4. Run `flutter analyze` and `flutter test`.
5. On an Android device/emulator, manually select an EPUB from a non-app folder, confirm metadata and chapters, select a chapter, and start the existing audio pipeline.

## Sources

- Android Developers — Access documents and other files from shared storage: https://developer.android.com/training/data-storage/shared/documents-files
- `file_picker` package documentation: https://pub.dev/packages/file_picker
- `archive` package documentation: https://pub.dev/packages/archive
- `ZipDecoder` API reference: https://pub.dev/documentation/archive/latest/archive/ZipDecoder-class.html

## Confidence

- Android Storage Access Framework behavior: HIGH — official Android documentation.
- ZIP decoding API: HIGH — official package API documentation.
- Exact dependency versions and final Flutter API shape: MEDIUM — must be resolved against the project's current Flutter/Dart SDK during implementation.
- Mapping the existing parser to real archive bytes: HIGH — based on the source files read in this repository, but implementation details remain for the planner.
