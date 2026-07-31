import 'dart:typed_data';
import 'dart:io';

import 'package:file_picker/file_picker.dart';

/// Bytes and display metadata returned by the native document picker.
class SelectedDocument {
  final String name;
  final Uint8List bytes;

  const SelectedDocument({required this.name, required this.bytes});

  String get extension {
    final dot = name.lastIndexOf('.');
    return dot < 0 ? '' : name.substring(dot + 1).toLowerCase();
  }
}

class DocumentSelectionException implements Exception {
  final String message;
  const DocumentSelectionException(this.message);

  @override
  String toString() => message;
}

abstract class EpubDocumentPicker {
  Future<SelectedDocument?> pickEpub();
}

/// Android's Storage Access Framework is used by file_picker, so no path or
/// broad storage permission is required.
class NativeEpubDocumentPicker implements EpubDocumentPicker {
  const NativeEpubDocumentPicker();

  @override
  Future<SelectedDocument?> pickEpub() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['epub'],
      withData: true,
      allowMultiple: false,
    );
    final file = result?.files.single;
    if (file == null) return null;
    if (file.bytes != null) {
      return SelectedDocument(name: file.name, bytes: file.bytes!);
    }

    final path = file.path;
    if (path != null && path.isNotEmpty) {
      try {
        return SelectedDocument(
          name: file.name,
          bytes: await File(path).readAsBytes(),
        );
      } on FileSystemException catch (error) {
        throw DocumentSelectionException(
          'Não foi possível ler o arquivo selecionado: ${error.message}',
        );
      }
    }

    throw const DocumentSelectionException(
      'O seletor não forneceu os bytes do EPUB selecionado.',
    );
  }
}
