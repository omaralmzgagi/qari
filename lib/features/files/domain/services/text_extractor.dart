import 'dart:typed_data';

import '../entities/extraction_result.dart';

/// Turns raw document bytes into text.
///
/// The contract is asynchronous and free of Flutter/Android types: heavy
/// parsing runs on a background isolate while the caller stays responsive.
abstract interface class TextExtractor {
  /// Returns the extracted text plus, when the format knows about them, the
  /// page/chapter count.
  ///
  /// Throws [FileImportException] with
  /// [FileImportErrorKind.extractionFailed] (or
  /// [FileImportErrorKind.legacyFormatUnsupported]) on failure.
  Future<ExtractionResult> extract({
    required String extension,
    required Uint8List bytes,
  });
}
