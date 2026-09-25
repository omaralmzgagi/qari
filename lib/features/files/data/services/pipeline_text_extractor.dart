import 'package:flutter/foundation.dart';

import '../../../../core/config/file_engine_config.dart';
import '../../domain/entities/extraction_result.dart';
import '../../domain/entities/file_import_error.dart';
import '../../domain/services/text_extractor.dart';
import '../parsers/parser_registry.dart';

/// Payload handed to the background isolate.
class ExtractionJob {
  const ExtractionJob({required this.extension, required this.bytes});

  final String extension;
  final Uint8List bytes;
}

/// Isolate-safe envelope: exceptions do not survive `Isolate.run`, so the
/// error kind travels by name instead of by object.
class ExtractionOutcome {
  const ExtractionOutcome.success({
    required this.text,
    this.pageCount,
  })  : errorCode = null,
        detail = null;

  const ExtractionOutcome.failure({
    required String this.errorCode,
    this.detail,
  })  : text = '',
        pageCount = null;

  final String? errorCode;
  final String? detail;
  final String text;
  final int? pageCount;

  bool get isSuccess => errorCode == null;
}

/// Runs the parser pipeline.
///
/// Small files are parsed inline; anything above
/// `FileEngineConfig.isolateThresholdBytes` is parsed in a background isolate
/// so a large document never skips a frame. Extracted text is truncated at
/// `FileEngineConfig.maxExtractedTextLength`.
class PipelineTextExtractor implements TextExtractor {
  PipelineTextExtractor({ParserRegistry? registry, FileEngineConfig? config})
      : registry = registry ?? ParserRegistry(),
        config = config ?? FileEngineConfig.defaults;

  final ParserRegistry registry;
  final FileEngineConfig config;

  @override
  Future<ExtractionResult> extract({
    required String extension,
    required Uint8List bytes,
  }) async {
    final ExtractionOutcome outcome;
    if (bytes.length <= config.isolateThresholdBytes) {
      outcome = _runInline(extension, bytes);
    } else {
      outcome = await compute(
        _parseInIsolate,
        ExtractionJob(extension: extension, bytes: bytes),
        debugLabel: 'qari.file.extract',
      );
    }

    if (!outcome.isSuccess) {
      throw FileImportException(
        kindOfName(outcome.errorCode),
        outcome.detail,
      );
    }

    var text = outcome.text;
    if (text.length > config.maxExtractedTextLength) {
      text = text.substring(0, config.maxExtractedTextLength);
    }
    return ExtractionResult(text: text, pageCount: outcome.pageCount);
  }

  ExtractionOutcome _runInline(String extension, Uint8List bytes) {
    try {
      final result = registry.parse(extension: extension, bytes: bytes);
      return ExtractionOutcome.success(
        text: result.text,
        pageCount: result.pageCount,
      );
    } on FileImportException catch (error) {
      return ExtractionOutcome.failure(
        errorCode: error.kind.name,
        detail: error.detail,
      );
    } catch (error) {
      return ExtractionOutcome.failure(
        errorCode: FileImportErrorKind.extractionFailed.name,
        detail: '$error',
      );
    }
  }

  /// Maps a transported error name back to its kind.
  static FileImportErrorKind kindOfName(String? name) {
    for (final kind in FileImportErrorKind.values) {
      if (kind.name == name) return kind;
    }
    return FileImportErrorKind.extractionFailed;
  }
}

/// Entry point executed on the background isolate.
@pragma('vm:entry-point')
ExtractionOutcome _parseInIsolate(ExtractionJob job) {
  try {
    final registry = ParserRegistry();
    final result = registry.parse(extension: job.extension, bytes: job.bytes);
    return ExtractionOutcome.success(
      text: result.text,
      pageCount: result.pageCount,
    );
  } on FileImportException catch (error) {
    return ExtractionOutcome.failure(
      errorCode: error.kind.name,
      detail: error.detail,
    );
  } catch (error) {
    return ExtractionOutcome.failure(
      errorCode: FileImportErrorKind.extractionFailed.name,
      detail: '$error',
    );
  }
}
