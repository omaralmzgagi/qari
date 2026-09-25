import 'processing_status.dart';

/// A file that passed the File Engine and is ready for the Reader.
///
/// The model is deliberately database-ready: [toJson]/[fromJson] round-trip
/// every field so a future Library persistence layer can store it in Hive
/// without changing the shape of this class.
class ImportedFile {
  const ImportedFile({
    required this.id,
    required this.fileName,
    required this.extension,
    required this.mimeType,
    required this.fileSizeBytes,
    required this.importedAt,
    required this.localPath,
    required this.extractedText,
    required this.characterCount,
    required this.detectedLanguage,
    required this.languageConfidence,
    required this.status,
    this.pageCount,
    this.usedOcr = false,
    this.ocrScript,
    this.processingError,
  });

  /// Stable unique id (also used for the on-disk copy name).
  final String id;

  /// Original file name, extension included.
  final String fileName;

  /// Lower-cased extension without the dot.
  final String extension;

  /// Best-effort MIME type for the extension.
  final String mimeType;

  final int fileSizeBytes;
  final DateTime importedAt;

  /// Path of the copy owned by the app (or the original path when the copy
  /// step was disabled).
  final String localPath;

  /// Full extracted text.
  final String extractedText;

  /// Length of [extractedText] in characters.
  final int characterCount;

  /// BCP-47-ish language code (`ar`, `en`, …) or `unknown`.
  final String detectedLanguage;

  /// `0.0`–`1.0` confidence of [detectedLanguage].
  final double languageConfidence;

  final ProcessingStatus status;

  final int? pageCount;

  /// `true` when the text came from OCR instead of a text stream.
  final bool usedOcr;

  /// Name of the OCR script that produced text (e.g. `latin`), `null` for
  /// non-image documents.
  final String? ocrScript;

  /// Error code of [FileImportErrorKind.name] when [status] is failed.
  final String? processingError;

  ImportedFile copyWith({
    String? id,
    String? fileName,
    String? extension,
    String? mimeType,
    int? fileSizeBytes,
    DateTime? importedAt,
    String? localPath,
    String? extractedText,
    int? characterCount,
    String? detectedLanguage,
    double? languageConfidence,
    ProcessingStatus? status,
    int? pageCount,
    bool? usedOcr,
    String? ocrScript,
    String? processingError,
  }) {
    return ImportedFile(
      id: id ?? this.id,
      fileName: fileName ?? this.fileName,
      extension: extension ?? this.extension,
      mimeType: mimeType ?? this.mimeType,
      fileSizeBytes: fileSizeBytes ?? this.fileSizeBytes,
      importedAt: importedAt ?? this.importedAt,
      localPath: localPath ?? this.localPath,
      extractedText: extractedText ?? this.extractedText,
      characterCount: characterCount ?? this.characterCount,
      detectedLanguage: detectedLanguage ?? this.detectedLanguage,
      languageConfidence: languageConfidence ?? this.languageConfidence,
      status: status ?? this.status,
      pageCount: pageCount ?? this.pageCount,
      usedOcr: usedOcr ?? this.usedOcr,
      ocrScript: ocrScript ?? this.ocrScript,
      processingError: processingError ?? this.processingError,
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'id': id,
      'fileName': fileName,
      'extension': extension,
      'mimeType': mimeType,
      'fileSizeBytes': fileSizeBytes,
      'importedAt': importedAt.toIso8601String(),
      'localPath': localPath,
      'extractedText': extractedText,
      'characterCount': characterCount,
      'detectedLanguage': detectedLanguage,
      'languageConfidence': languageConfidence,
      'status': status.storageName,
      'pageCount': pageCount,
      'usedOcr': usedOcr,
      'ocrScript': ocrScript,
      'processingError': processingError,
    };
  }

  factory ImportedFile.fromJson(Map<String, Object?> json) {
    final rawExtension =
        (json['extension'] as String?)?.toLowerCase().trim() ?? '';
    final rawId = json['id'] as String?;
    final rawName = json['fileName'] as String?;
    if (rawId == null || rawName == null) {
      throw const FormatException('ImportedFile requires id and fileName');
    }
    return ImportedFile(
      id: rawId,
      fileName: rawName,
      extension: rawExtension.startsWith('.')
          ? rawExtension.substring(1)
          : rawExtension,
      mimeType: json['mimeType'] as String? ?? 'application/octet-stream',
      fileSizeBytes: (json['fileSizeBytes'] as num?)?.toInt() ?? 0,
      importedAt: DateTime.tryParse(json['importedAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      localPath: json['localPath'] as String? ?? '',
      extractedText: json['extractedText'] as String? ?? '',
      characterCount: (json['characterCount'] as num?)?.toInt() ?? 0,
      detectedLanguage: json['detectedLanguage'] as String? ?? 'unknown',
      languageConfidence: (json['languageConfidence'] as num?)?.toDouble() ?? 0,
      status: ProcessingStatus.fromStorageName(json['status'] as String?),
      pageCount: (json['pageCount'] as num?)?.toInt(),
      usedOcr: json['usedOcr'] as bool? ?? false,
      ocrScript: json['ocrScript'] as String?,
      processingError: json['processingError'] as String?,
    );
  }

  @override
  String toString() =>
      'ImportedFile($fileName, $detectedLanguage, $characterCount chars)';
}
