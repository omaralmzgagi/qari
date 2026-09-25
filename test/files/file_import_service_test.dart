import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:qari/core/config/file_engine_config.dart';
import 'package:qari/features/files/application/file_import_service.dart';
import 'package:qari/features/files/data/services/pipeline_text_extractor.dart';
import 'package:qari/features/files/domain/entities/extraction_result.dart';
import 'package:qari/features/files/domain/entities/file_import_error.dart';
import 'package:qari/features/files/domain/entities/imported_file.dart';
import 'package:qari/features/files/domain/entities/processing_status.dart';
import 'package:qari/features/files/domain/language/detected_language.dart';
import 'package:qari/features/files/domain/services/file_validation_service.dart';
import 'package:qari/features/files/domain/services/import_storage.dart';
import 'package:qari/features/files/domain/services/language_detector.dart';
import 'package:qari/features/files/domain/services/ocr_engine.dart';
import 'package:qari/features/files/domain/services/text_extractor.dart';

import 'fixtures.dart';

// ---------------------------------------------------------------------------
// Fakes
// ---------------------------------------------------------------------------

class _FakeOcrEngine implements OcrEngine {
  _FakeOcrEngine({this.result, this.error});

  final OcrResult? result;
  final Object? error;

  final List<({String filePath, String languageCode})> calls = [];

  @override
  Future<OcrResult> recognize({
    required String filePath,
    required String languageCode,
  }) async {
    calls.add((filePath: filePath, languageCode: languageCode));
    if (error != null) throw error!;
    return result ?? const OcrResult(text: '', scriptName: 'latin');
  }
}

class _FakeStorage implements ImportStorage {
  _FakeStorage({this.returnedPath = '/app/storage'});

  final String returnedPath;
  final List<({String id, String fileName, int byteLength})> calls = [];

  @override
  Future<String> store({
    required String id,
    required String fileName,
    required String sourcePath,
    required Uint8List bytes,
  }) async {
    calls.add((id: id, fileName: fileName, byteLength: bytes.length));
    return returnedPath;
  }
}

class _FakeDetector implements LanguageDetector {
  _FakeDetector({this.detected, this.error});

  final DetectedLanguage? detected;
  final Object? error;

  var calls = 0;

  @override
  DetectedLanguage detect(String text) {
    calls++;
    if (error != null) throw error!;
    return detected ?? DetectedLanguage.unknown;
  }
}

class _FakeExtractor implements TextExtractor {
  _FakeExtractor({this.result, this.error});

  final ExtractionResult? result;
  final Object? error;

  final List<({String extension, int byteLength})> calls = [];

  @override
  Future<ExtractionResult> extract({
    required String extension,
    required Uint8List bytes,
  }) async {
    calls.add((extension: extension, byteLength: bytes.length));
    if (error != null) throw error!;
    return result ?? const ExtractionResult(text: 'fallback text');
  }
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

_FakeOcrEngine _ocrThatReturns(String text, {String script = 'latin'}) =>
    _FakeOcrEngine(
      result: OcrResult(text: text, scriptName: script),
    );

_FakeOcrEngine _ocrThatThrows() => _FakeOcrEngine(
      error: const FileImportException(FileImportErrorKind.ocrFailed),
    );

/// Runs [run] and returns the [FileImportErrorKind] it threw.
Future<FileImportErrorKind> failureOf(Future<ImportedFile> run) async {
  try {
    await run;
  } on FileImportException catch (error) {
    return error.kind;
  }
  fail('expected a FileImportException');
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  const arabic = 'الحمد لله رب العالمين الرحمن الرحيم مالك يوم الدين';

  FileImportService service({
    OcrEngine? ocr,
    LanguageDetector? detector,
    ImportStorage? storage,
    TextExtractor? extractor,
    FileEngineConfig config = FileEngineConfig.defaults,
  }) {
    return FileImportService(
      validation: const FileValidationService(),
      extractor: extractor ?? PipelineTextExtractor(),
      ocr: ocr ?? _FakeOcrEngine(),
      detector: detector ?? _FakeDetector(),
      storage: storage ?? _FakeStorage(),
      config: config,
    );
  }

  group('successful import', () {
    test('a text file walks the pipeline and reports every status', () async {
      final statuses = <ProcessingStatus>[];
      final storage = _FakeStorage();
      final detector = _FakeDetector(
        detected: const DetectedLanguage(code: 'ar', confidence: 0.9),
      );
      final importer = service(storage: storage, detector: detector);

      final result = await importer.import(
        fileName: 'notes.txt',
        bytes: utf8Of(arabic),
        onStatus: statuses.add,
      );

      expect(
        statuses,
        [
          ProcessingStatus.validating,
          ProcessingStatus.processing,
          ProcessingStatus.extracting,
          ProcessingStatus.processing,
        ],
      );
      expect(result.status, ProcessingStatus.completed);
      expect(result.id, isNotEmpty);
      expect(result.fileName, 'notes.txt');
      expect(result.extension, 'txt');
      expect(result.mimeType, 'text/plain');
      expect(result.extractedText, arabic);
      expect(result.characterCount, arabic.length);
      expect(result.detectedLanguage, 'ar');
      expect(result.languageConfidence, 0.9);
      expect(result.usedOcr, isFalse);
      expect(result.ocrScript, isNull);
      expect(result.pageCount, isNull);
      expect(result.localPath, '/app/storage');
      expect(result.fileSizeBytes, utf8Of(arabic).length);
      expect(result.importedAt, isNotNull);
    });

    test('the file is handed to storage exactly once', () async {
      final storage = _FakeStorage();
      final bytes = utf8Of(arabic);
      await service(storage: storage).import(
        fileName: 'notes.txt',
        bytes: bytes,
      );

      expect(storage.calls, hasLength(1));
      expect(storage.calls.single.fileName, 'notes.txt');
      expect(storage.calls.single.byteLength, bytes.length);
      expect(storage.calls.single.id, isNotEmpty);
    });

    test('an EPUB keeps its chapter count on the result', () async {
      final extractor = _FakeExtractor(
        result: const ExtractionResult(text: 'chapter text', pageCount: 12),
      );
      final result = await service(extractor: extractor).import(
        fileName: 'book.epub',
        bytes: epubOf(['Chapter one.']),
      );
      expect(result.pageCount, 12);
      expect(result.extension, 'epub');
      expect(extractor.calls.single.extension, 'epub');
    });

    test('storage can be switched off without breaking the pipeline', () async {
      final storage = _FakeStorage();
      final result = await service(
        storage: storage,
        config: const FileEngineConfig(copyIntoAppStorage: false),
      ).import(
        fileName: 'notes.txt',
        sourcePath: '/somewhere/notes.txt',
        bytes: utf8Of(arabic),
      );

      expect(storage.calls, isEmpty);
      expect(result.localPath, '/somewhere/notes.txt');
    });
  });

  group('validation failures', () {
    test('an unsupported extension is rejected before any work', () async {
      final extractor = _FakeExtractor();
      expect(
        await failureOf(
          service(extractor: extractor).import(
            fileName: 'holiday.gif',
            bytes: utf8Of('picture'),
          ),
        ),
        FileImportErrorKind.unsupportedFile,
      );
      expect(extractor.calls, isEmpty);
    });

    test('an empty payload is rejected as an invalid file', () async {
      expect(
        await failureOf(
          service().import(fileName: 'notes.txt', bytes: Uint8List(0)),
        ),
        FileImportErrorKind.invalidFile,
      );
    });

    test('a file over the size ceiling is rejected', () async {
      expect(
        await failureOf(
          service().import(
            fileName: 'big.pdf',
            bytes: utf8Of('x'),
            sizeBytes: 65 * 1024 * 1024,
          ),
        ),
        FileImportErrorKind.fileTooLarge,
      );
    });
  });

  group('read failures', () {
    test('a missing source path surfaces fileReadError', () async {
      expect(
        await failureOf(
          service().import(
            fileName: 'notes.txt',
            sourcePath: '/definitely/not/here/notes.txt',
          ),
        ),
        FileImportErrorKind.fileReadError,
      );
    });

    test('no location at all surfaces fileReadError', () async {
      expect(
        await failureOf(service().import(fileName: 'notes.txt')),
        FileImportErrorKind.fileReadError,
      );
    });

    test('an image without a readable path surfaces fileReadError', () async {
      final storage = _FakeStorage(returnedPath: '');
      expect(
        await failureOf(
          service(storage: storage).import(
            fileName: 'scan.png',
            bytes: utf8Of('fake image payload'),
          ),
        ),
        FileImportErrorKind.fileReadError,
      );
      expect(storage.calls, hasLength(1));
    });
  });

  group('extraction failures', () {
    test('legacy binary formats are reported honestly', () async {
      expect(
        await failureOf(
          service().import(fileName: 'old.doc', bytes: utf8Of('binary')),
        ),
        FileImportErrorKind.legacyFormatUnsupported,
      );
    });

    test('an extractor error is forwarded unchanged', () async {
      final extractor = _FakeExtractor(
        error: const FileImportException(
          FileImportErrorKind.extractionFailed,
        ),
      );
      expect(
        await failureOf(
          service(extractor: extractor).import(
            fileName: 'broken.docx',
            bytes: utf8Of('corrupt'),
          ),
        ),
        FileImportErrorKind.extractionFailed,
      );
    });

    test('extraction that yields nothing is emptyContent', () async {
      final extractor = _FakeExtractor(
        result: const ExtractionResult(text: '   \n  '),
      );
      expect(
        await failureOf(
          service(extractor: extractor).import(
            fileName: 'blank.txt',
            bytes: utf8Of('not empty on disk'),
          ),
        ),
        FileImportErrorKind.emptyContent,
      );
    });
  });

  group('OCR path', () {
    test('an image is recognised and marked as OCR', () async {
      final statuses = <ProcessingStatus>[];
      final ocr = _ocrThatReturns('النص المقروء من الصورة', script: 'latin');
      final detector = _FakeDetector(
        detected: const DetectedLanguage(code: 'ar', confidence: 0.8),
      );
      final extractor = _FakeExtractor();

      final result = await service(
        ocr: ocr,
        detector: detector,
        extractor: extractor,
      ).import(
        fileName: 'scan.png',
        bytes: utf8Of('fake png bytes'),
        languageHint: 'ar',
        onStatus: statuses.add,
      );

      expect(
        statuses,
        [
          ProcessingStatus.validating,
          ProcessingStatus.processing,
          ProcessingStatus.ocr,
          ProcessingStatus.processing,
        ],
      );
      expect(result.usedOcr, isTrue);
      expect(result.ocrScript, 'latin');
      expect(result.detectedLanguage, 'ar');
      expect(result.extractedText, 'النص المقروء من الصورة');
      expect(extractor.calls, isEmpty);
      expect(ocr.calls, hasLength(1));
      expect(ocr.calls.single.filePath, '/app/storage');
      expect(ocr.calls.single.languageCode, 'ar');
    });

    test('an image with no recognised text is emptyContent', () async {
      final ocr = _ocrThatReturns('   ');
      expect(
        await failureOf(
          service(ocr: ocr).import(
            fileName: 'blank.jpg',
            bytes: utf8Of('fake jpg bytes'),
          ),
        ),
        FileImportErrorKind.emptyContent,
      );
    });

    test('an engine failure surfaces ocrFailed', () async {
      final ocr = _ocrThatThrows();
      expect(
        await failureOf(
          service(ocr: ocr).import(
            fileName: 'bad.webp',
            bytes: utf8Of('fake webp bytes'),
          ),
        ),
        FileImportErrorKind.ocrFailed,
      );
    });
  });

  group('language detection failures', () {
    test('a detector failure surfaces languageDetectionFailed', () async {
      final detector = _FakeDetector(error: StateError('no detector'));
      expect(
        await failureOf(
          service(detector: detector).import(
            fileName: 'notes.txt',
            bytes: utf8Of(arabic),
          ),
        ),
        FileImportErrorKind.languageDetectionFailed,
      );
    });

    test('detection is skipped entirely when extraction is empty', () async {
      final detector = _FakeDetector();
      await failureOf(
        service(
          detector: detector,
          extractor: _FakeExtractor(result: const ExtractionResult(text: '')),
        ).import(fileName: 'notes.txt', bytes: utf8Of('bytes')),
      );
      expect(detector.calls, 0);
    });
  });

  group('language hint', () {
    test('an unknown hint is the default', () async {
      final ocr = _ocrThatReturns('hello world text');
      await service(ocr: ocr).import(
        fileName: 'scan.jpeg',
        bytes: utf8Of('fake jpeg bytes'),
      );
      expect(ocr.calls.single.languageCode, DetectedLanguage.unknownCode);
    });
  });
}
