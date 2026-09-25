/// Every state the file import pipeline can be in.
///
/// The order mirrors the real pipeline so `ProcessingStatus.isBusy` and
/// progress hints stay meaningful without extra bookkeeping.
enum ProcessingStatus {
  /// Nothing selected yet.
  idle,

  /// The platform picker is open.
  selecting,

  /// The file is being validated (size, extension, readability).
  validating,

  /// Bytes are being read / copied into app storage.
  processing,

  /// Text is being extracted (plain text, OOXML, PDF, markup).
  extracting,

  /// OCR is running on a raster image.
  ocr,

  /// The document is ready for the Reader.
  completed,

  /// Import failed; `FileImportErrorKind` explains why.
  failed;

  /// `true` while the pipeline owns the UI (from picking to OCR).
  bool get isBusy =>
      this == selecting ||
      this == validating ||
      this == processing ||
      this == extracting ||
      this == ocr;

  /// `true` once the file is usable, either successfully or terminally.
  bool get isTerminal => this == completed || this == failed;

  /// Stable storage name (used by `ImportedFile.toJson`).
  String get storageName => name;

  /// Restores a status from [storageName]; falls back to [ProcessingStatus.idle].
  static ProcessingStatus fromStorageName(String? value) {
    for (final status in ProcessingStatus.values) {
      if (status.name == value) return status;
    }
    return ProcessingStatus.idle;
  }
}
