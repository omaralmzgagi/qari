/// Machine-readable reasons why an import can fail.
///
/// The UI maps each kind to a translated message; [FileImportException.detail]
/// is only ever written to the logger and is never shown to a user.
enum FileImportErrorKind {
  /// The extension is not part of [FileEngineConfig.supportedExtensions].
  unsupportedFile,

  /// The file has no name, no extension, zero bytes or is not a file.
  invalidFile,

  /// The file is larger than the configured ceiling.
  fileTooLarge,

  /// The bytes could not be read from disk (missing, locked, permission).
  fileReadError,

  /// A supported format existed but the parser could not produce text.
  extractionFailed,

  /// The OCR engine returned no text or crashed.
  ocrFailed,

  /// Parsing/OCR finished but produced no usable characters.
  emptyContent,

  /// Language detection threw instead of returning `unknown`.
  languageDetectionFailed,

  /// A legacy binary Office file (DOC/PPT/XLS) reached the extraction layer.
  legacyFormatUnsupported,

  /// The user dismissed the picker.
  cancelled;

  /// Whether the failure was caused by the user rather than the file.
  bool get isUserInterruption => this == cancelled;
}

/// Thrown by validation, extraction and OCR layers; never escapes the
/// import pipeline unhandled.
class FileImportException implements Exception {
  const FileImportException(this.kind, [this.detail]);

  final FileImportErrorKind kind;

  /// Technical note for the logger. Never rendered in the UI.
  final String? detail;

  @override
  String toString() =>
      'FileImportException(${kind.name}${detail == null ? '' : ': $detail'})';
}
