/// Raster-image OCR is delegated to a replaceable engine so the pipeline can
/// be unit-tested without Google ML Kit and can be swapped later (e.g. for an
/// Arabic-capable engine).
abstract interface class OcrEngine {
  /// Recognises [languageCode] (or a script derived from it) in the image at
  /// [filePath] and returns the recognised text.
  ///
  /// Throws [FileImportException] with [FileImportErrorKind.ocrFailed] when
  /// the engine is unavailable or rejects the image. Returning empty text is
  /// **not** an error — the pipeline turns it into `emptyContent`.
  Future<OcrResult> recognize({
    required String filePath,
    required String languageCode,
  });
}

/// Text recognised on a raster image.
class OcrResult {
  const OcrResult({
    required this.text,
    required this.scriptName,
  });

  final String text;

  /// Name of the script that actually produced the text (`latin`,
  /// `chinese`, `devanagiri`).
  final String scriptName;

  bool get isEmpty => text.trim().isEmpty;
}
