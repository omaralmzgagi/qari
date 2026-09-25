/// Central configuration for the File Engine.
///
/// Every limit, supported format and behavioural switch of the import
/// pipeline lives in this single file so that no magic number is ever
/// hard-coded inside a service, a parser or a widget.
class FileEngineConfig {
  const FileEngineConfig({
    this.maxFileSizeBytes = 64 * 1024 * 1024,
    this.maxImageSizeBytes = 24 * 1024 * 1024,
    this.maxExtractedTextLength = 1000000,
    this.isolateThresholdBytes = 128 * 1024,
    this.minLanguageConfidence = 0.22,
    this.minLanguageSampleLength = 16,
    this.ocrScriptFallback = true,
    this.copyIntoAppStorage = true,
  });

  /// Production defaults. Tests may build a smaller instance instead of
  /// changing code.
  static const FileEngineConfig defaults = FileEngineConfig();

  /// Hard ceiling for any imported document (bytes).
  final int maxFileSizeBytes;

  /// Hard ceiling for raster images that go through OCR (bytes).
  final int maxImageSizeBytes;

  /// Extracted text is truncated above this many characters so a single huge
  /// document can never exhaust memory downstream.
  final int maxExtractedTextLength;

  /// Files larger than this are parsed in a background isolate instead of on
  /// the UI thread.
  final int isolateThresholdBytes;

  /// Lowest stop-word ratio considered a confident language match.
  final double minLanguageConfidence;

  /// Shortest sample that is considered worth analysing for a language.
  final int minLanguageSampleLength;

  /// Whether OCR retries with the remaining ML Kit scripts when the first
  /// attempt returns no text.
  final bool ocrScriptFallback;

  /// Whether imported files are copied into the app-owned directory
  /// (`AppPaths.filesDirectory()`) so the picker cache can be purged.
  final bool copyIntoAppStorage;

  // ---------------------------------------------------------------------
  // Format groups
  // ---------------------------------------------------------------------

  /// UTF-8 / plain byte text files.
  static const Set<String> plainTextExtensions = {'txt', 'csv', 'log', 'md'};

  /// Markup based documents (HTML, RTF).
  static const Set<String> markupExtensions = {'html', 'htm', 'rtf'};

  /// OOXML / ZIP based containers: DOCX, XLSX, PPTX and EPUB.
  static const Set<String> ooxmlExtensions = {'docx', 'xlsx', 'pptx', 'epub'};

  /// Portable Document Format.
  static const Set<String> pdfExtensions = {'pdf'};

  /// Legacy binary Office formats. They are recognised and validated, but the
  /// extraction layer cannot read them yet — it raises
  /// `FileImportErrorKind.legacyFormatUnsupported` with a translated message
  /// instead of pretending the format works.
  static const Set<String> legacyOfficeExtensions = {'doc', 'ppt', 'xls'};

  /// Raster images handled by the OCR pipeline.
  static const Set<String> imageExtensions = {'jpg', 'jpeg', 'png', 'webp'};

  /// Every extension the picker accepts and the validator allows.
  static const Set<String> supportedExtensions = {
    ...plainTextExtensions,
    ...markupExtensions,
    ...ooxmlExtensions,
    ...pdfExtensions,
    ...legacyOfficeExtensions,
    ...imageExtensions,
  };

  /// Extensions whose bytes can actually be turned into text (images are
  /// excluded: they go through OCR, and legacy Office through the explicit
  /// "not supported yet" branch).
  static const Set<String> directlyExtractableExtensions = {
    ...plainTextExtensions,
    ...markupExtensions,
    ...ooxmlExtensions,
    ...pdfExtensions,
  };

  /// Extensions handed to the platform picker.
  static List<String> get pickerExtensions =>
      supportedExtensions.toList(growable: false)..sort();

  // ---------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------

  /// Lower-cases an extension and strips a leading dot. Returns `''` when the
  /// name carries no extension.
  static String normalizeExtension(String raw) {
    final value = raw.trim().toLowerCase();
    if (value.isEmpty) return '';
    final withoutDot = value.startsWith('.') ? value.substring(1) : value;
    return withoutDot.contains(RegExp(r'[^a-z0-9]')) ? '' : withoutDot;
  }

  /// Picks the extension of [fileName] (never returns `null`).
  static String extensionOf(String fileName) {
    final name = fileName.trim();
    final dot = name.lastIndexOf('.');
    if (dot < 0 || dot == name.length - 1) return '';
    return normalizeExtension(name.substring(dot + 1));
  }

  bool supports(String extension) =>
      supportedExtensions.contains(normalizeExtension(extension));

  bool isImage(String extension) =>
      imageExtensions.contains(normalizeExtension(extension));

  bool isLegacyOffice(String extension) =>
      legacyOfficeExtensions.contains(normalizeExtension(extension));

  bool isDirectlyExtractable(String extension) =>
      directlyExtractableExtensions.contains(normalizeExtension(extension));

  /// Returns the maximum size allowed for the given extension.
  int maxBytesFor(String extension) =>
      isImage(extension) ? maxImageSizeBytes : maxFileSizeBytes;

  /// Best-effort MIME type used for reporting only.
  static const Map<String, String> mimeTypes = {
    'pdf': 'application/pdf',
    'doc': 'application/msword',
    'docx':
        'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    'xls': 'application/vnd.ms-excel',
    'xlsx': 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    'ppt': 'application/vnd.ms-powerpoint',
    'pptx':
        'application/vnd.openxmlformats-officedocument.presentationml.presentation',
    'epub': 'application/epub+zip',
    'txt': 'text/plain',
    'csv': 'text/csv',
    'md': 'text/markdown',
    'log': 'text/plain',
    'html': 'text/html',
    'htm': 'text/html',
    'rtf': 'application/rtf',
    'jpg': 'image/jpeg',
    'jpeg': 'image/jpeg',
    'png': 'image/png',
    'webp': 'image/webp',
  };

  static String mimeTypeFor(String extension) =>
      mimeTypes[normalizeExtension(extension)] ?? 'application/octet-stream';
}
