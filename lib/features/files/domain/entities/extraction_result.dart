/// Text produced by the extraction layer, before language detection.
class ExtractionResult {
  const ExtractionResult({
    required this.text,
    this.pageCount,
  });

  /// The extracted (or OCR'd) text. May be empty — the pipeline decides
  /// whether that is an `emptyContent` failure.
  final String text;

  /// Logical page/chapter count when the format knows about pages
  /// (PDF, EPUB, XLSX sheets, PPTX slides); `null` otherwise.
  final int? pageCount;

  bool get isEmpty => text.trim().isEmpty;

  int get characterCount => text.length;

  @override
  String toString() =>
      'ExtractionResult(chars: $characterCount, pages: $pageCount)';
}
