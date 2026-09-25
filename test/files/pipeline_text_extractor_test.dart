import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:qari/core/config/file_engine_config.dart';
import 'package:qari/features/files/data/services/pipeline_text_extractor.dart';
import 'package:qari/features/files/domain/entities/file_import_error.dart';

import 'fixtures.dart';

void main() {
  Future<FileImportErrorKind> failureOf(
    PipelineTextExtractor extractor,
    String extension,
    Uint8List bytes,
  ) async {
    try {
      await extractor.extract(extension: extension, bytes: bytes);
    } on FileImportException catch (error) {
      return error.kind;
    }
    fail('expected $extension to be rejected');
  }

  group('inline path (below the isolate threshold)', () {
    final extractor = PipelineTextExtractor();

    test('a small text file is extracted', () async {
      const text = 'نص صغير جدا للاختبار';
      final result = await extractor.extract(
        extension: 'txt',
        bytes: utf8Of(text),
      );
      expect(result.text, text);
    });

    test('HTML keeps its page count semantics by returning no count', () async {
      final result = await extractor.extract(
        extension: 'html',
        bytes: utf8Of('<p>hello</p>'),
      );
      expect(result.pageCount, isNull);
      expect(result.text, contains('hello'));
    });
  });

  group('isolate path (above the isolate threshold)', () {
    final extractor = PipelineTextExtractor();

    test('a large document is parsed without losing text', () async {
      const targetLength = 400000;
      const unit = 'القراءة توسّع المعرفة وتثري الخيال للقارئ المبتدئ. ';
      final buffer = StringBuffer();
      while (buffer.length < targetLength) {
        buffer.write(unit);
      }
      final text = buffer.toString().substring(0, targetLength);
      final bytes = utf8Of(text);
      expect(
        bytes.length,
        greaterThan(FileEngineConfig.defaults.isolateThresholdBytes),
        reason: 'the fixture must exceed the threshold to hit the isolate',
      );

      final result = await extractor.extract(extension: 'txt', bytes: bytes);
      expect(result.text, hasLength(targetLength));
      expect(result.text, startsWith('القراءة'));
    });

    test('an EPUB is parsed on a background isolate and keeps its chapters',
        () async {
      final chapters = List<String>.generate(
        40,
        (index) => 'Chapter ${index + 1} of the file engine test book. '
            'الفصل رقم ${index + 1} في كتاب اختبار محرك الملفات.',
      );
      final bytes = epubOf(chapters);
      final extractor = PipelineTextExtractor(
        config: const FileEngineConfig(isolateThresholdBytes: 1024),
      );
      expect(
        bytes.length,
        greaterThan(1024),
        reason: 'the fixture must exceed the configured threshold',
      );

      final result = await extractor.extract(extension: 'epub', bytes: bytes);
      expect(result.pageCount, 40);
      expect(result.text, contains('الفصل رقم 40'));
    });

    test('an unsupported extension still fails on the isolate path', () async {
      final filler = StringBuffer();
      while (filler.length < 200000) {
        filler.write('padding ');
      }
      final extractor = PipelineTextExtractor(
        config: const FileEngineConfig(isolateThresholdBytes: 64),
      );
      expect(
        await failureOf(
          extractor,
          'gif',
          utf8Of(filler.toString()),
        ),
        FileImportErrorKind.unsupportedFile,
      );
    });
  });

  group('error mapping', () {
    final extractor = PipelineTextExtractor();

    test('legacy binary formats map to legacyFormatUnsupported', () async {
      for (final extension in ['doc', 'ppt', 'xls']) {
        expect(
          await failureOf(extractor, extension, utf8Of('binary payload')),
          FileImportErrorKind.legacyFormatUnsupported,
          reason: '.$extension must be honest about not being readable',
        );
      }
    });

    test('a corrupt container maps to extractionFailed', () async {
      expect(
        await failureOf(extractor, 'docx', utf8Of('not really a zip')),
        FileImportErrorKind.extractionFailed,
      );
    });
  });

  group('truncation', () {
    test('text longer than the configured ceiling is cut', () async {
      const config = FileEngineConfig(maxExtractedTextLength: 40);
      final extractor = PipelineTextExtractor(config: config);
      final buffer = StringBuffer();
      while (buffer.length < 500) {
        buffer.write('النص يتكرر لاختبار حد الطول المسموح في المحرك. ');
      }

      final result = await extractor.extract(
        extension: 'txt',
        bytes: utf8Of(buffer.toString()),
      );
      expect(result.text, hasLength(40));
    });

    test('text under the ceiling is left untouched', () async {
      const config = FileEngineConfig(maxExtractedTextLength: 1000);
      final extractor = PipelineTextExtractor(config: config);
      const text = 'short enough';
      final result = await extractor.extract(
        extension: 'txt',
        bytes: utf8Of(text),
      );
      expect(result.text, text);
    });
  });

  group('outcome envelope', () {
    test('a successful outcome carries no error code', () {
      const outcome = ExtractionOutcome.success(text: 'abc', pageCount: 3);
      expect(outcome.isSuccess, isTrue);
      expect(outcome.errorCode, isNull);
      expect(outcome.text, 'abc');
      expect(outcome.pageCount, 3);
    });

    test('a failure outcome carries no text', () {
      const outcome = ExtractionOutcome.failure(errorCode: 'extractionFailed');
      expect(outcome.isSuccess, isFalse);
      expect(outcome.text, isEmpty);
      expect(outcome.pageCount, isNull);
    });

    test('unknown error names fall back to extractionFailed', () {
      expect(
        PipelineTextExtractor.kindOfName('somethingElse'),
        FileImportErrorKind.extractionFailed,
      );
      expect(
        PipelineTextExtractor.kindOfName('legacyFormatUnsupported'),
        FileImportErrorKind.legacyFormatUnsupported,
      );
      expect(
        PipelineTextExtractor.kindOfName(null),
        FileImportErrorKind.extractionFailed,
      );
    });
  });
}
