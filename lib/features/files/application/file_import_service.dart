import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import '../../../core/config/file_engine_config.dart';
import '../domain/entities/file_import_error.dart';
import '../domain/entities/imported_file.dart';
import '../domain/entities/processing_status.dart';
import '../domain/language/detected_language.dart';
import '../domain/services/file_validation_service.dart';
import '../domain/services/import_storage.dart';
import '../domain/services/language_detector.dart';
import '../domain/services/ocr_engine.dart';
import '../domain/services/text_extractor.dart';

/// Orchestrates the whole import pipeline:
///
/// `validating → processing → extracting | ocr → language detection → done`
///
/// Every failure surfaces as a typed [FileImportException] carrying a
/// [FileImportErrorKind] that the UI translates; nothing else escapes.
class FileImportService {
  FileImportService({
    required this.validation,
    required this.extractor,
    required this.ocr,
    required this.detector,
    required this.storage,
    this.config = FileEngineConfig.defaults,
  });

  final FileValidationService validation;
  final TextExtractor extractor;
  final OcrEngine ocr;
  final LanguageDetector detector;
  final ImportStorage storage;
  final FileEngineConfig config;

  static final Random _random = Random();

  /// Imports one file and returns the [ImportedFile] ready for the Reader.
  ///
  /// [onStatus] receives each pipeline transition so a controller can mirror
  /// them into UI state.
  Future<ImportedFile> import({
    required String fileName,
    String? sourcePath,
    Uint8List? bytes,
    int? sizeBytes,
    String languageHint = DetectedLanguage.unknownCode,
    void Function(ProcessingStatus status)? onStatus,
  }) async {
    onStatus?.call(ProcessingStatus.validating);

    final content = await _readBytes(
      sourcePath: sourcePath,
      bytes: bytes,
      fileName: fileName,
    );

    final reportedSize =
        sizeBytes != null && sizeBytes > 0 ? sizeBytes : content.length;
    final validated = validation.validate(
      fileName: fileName,
      sizeBytes: reportedSize,
    );

    onStatus?.call(ProcessingStatus.processing);

    final id = _newId();
    var canonicalPath = sourcePath ?? '';
    if (config.copyIntoAppStorage) {
      canonicalPath = await storage.store(
        id: id,
        fileName: validated.name,
        sourcePath: canonicalPath,
        bytes: content,
      );
    }
    if (validated.isImage && canonicalPath.isEmpty) {
      throw const FileImportException(
        FileImportErrorKind.fileReadError,
        'image has no readable path for OCR',
      );
    }

    String text;
    int? pageCount;
    var usedOcr = false;
    String? ocrScript;

    if (validated.isImage) {
      onStatus?.call(ProcessingStatus.ocr);
      final OcrResult result;
      try {
        result = await ocr.recognize(
          filePath: canonicalPath,
          languageCode: languageHint,
        );
      } on FileImportException {
        rethrow;
      } catch (error) {
        throw FileImportException(
          FileImportErrorKind.ocrFailed,
          '$error',
        );
      }
      text = result.text;
      usedOcr = true;
      ocrScript = result.scriptName;
    } else {
      onStatus?.call(ProcessingStatus.extracting);
      try {
        final result = await extractor.extract(
          extension: validated.extension,
          bytes: content,
        );
        text = result.text;
        pageCount = result.pageCount;
      } on FileImportException {
        rethrow;
      } catch (error) {
        throw FileImportException(
          FileImportErrorKind.extractionFailed,
          '$error',
        );
      }
    }

    if (text.trim().isEmpty) {
      throw const FileImportException(FileImportErrorKind.emptyContent);
    }

    onStatus?.call(ProcessingStatus.processing);
    final DetectedLanguage language;
    try {
      language = detector.detect(text);
    } on FileImportException {
      rethrow;
    } catch (error) {
      throw FileImportException(
        FileImportErrorKind.languageDetectionFailed,
        '$error',
      );
    }

    return ImportedFile(
      id: id,
      fileName: validated.name,
      extension: validated.extension,
      mimeType: validated.mimeType,
      fileSizeBytes: content.length,
      importedAt: DateTime.now(),
      localPath: canonicalPath,
      extractedText: text,
      characterCount: text.length,
      detectedLanguage: language.code,
      languageConfidence: language.confidence,
      status: ProcessingStatus.completed,
      pageCount: pageCount,
      usedOcr: usedOcr,
      ocrScript: ocrScript,
    );
  }

  Future<Uint8List> _readBytes({
    required String? sourcePath,
    required Uint8List? bytes,
    required String fileName,
  }) async {
    if (bytes != null) return bytes;
    if (sourcePath == null || sourcePath.isEmpty) {
      throw const FileImportException(
        FileImportErrorKind.fileReadError,
        'no readable location for the selected file',
      );
    }
    try {
      final file = File(sourcePath);
      if (!await file.exists()) {
        throw const FileImportException(
          FileImportErrorKind.fileReadError,
          'file disappeared before it could be read',
        );
      }
      return await file.readAsBytes();
    } on FileImportException {
      rethrow;
    } catch (error) {
      throw FileImportException(
        FileImportErrorKind.fileReadError,
        '$fileName: $error',
      );
    }
  }

  static String _newId() {
    final timestamp = DateTime.now().microsecondsSinceEpoch.toRadixString(36);
    final salt = _random.nextInt(0x7fffffff).toRadixString(36);
    return '$timestamp$salt';
  }
}
