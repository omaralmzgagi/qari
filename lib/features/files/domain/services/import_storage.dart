import 'dart:typed_data';

/// Copies imported files into app-owned storage so they survive the picker
/// cache and can be re-read later (OCR, Reader, re-import).
///
/// The contract returns the path the pipeline should treat as canonical.
abstract interface class ImportStorage {
  Future<String> store({
    required String id,
    required String fileName,
    required String sourcePath,
    required Uint8List bytes,
  });
}
