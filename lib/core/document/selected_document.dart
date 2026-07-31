import 'dart:typed_data';

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
    if (file == null || file.bytes == null) return null;
    return SelectedDocument(name: file.name, bytes: file.bytes!);
  }
}
