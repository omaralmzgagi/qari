import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/file_engine_config.dart';
import '../../application/file_import_service.dart';
import '../../domain/services/file_validation_service.dart';
import '../../domain/services/import_storage.dart';
import '../../domain/services/language_detector.dart';
import '../../domain/services/ocr_engine.dart';
import '../../domain/services/text_extractor.dart';
import '../../domain/sources/file_source.dart';
import '../services/local_import_storage.dart';
import '../services/mlkit_ocr_engine.dart';
import '../services/pipeline_text_extractor.dart';
import '../services/script_language_detector.dart';
import '../sources/platform_file_source.dart';

/// File Engine configuration. Override in tests to shrink limits.
final fileEngineConfigProvider = Provider<FileEngineConfig>(
  (ref) => FileEngineConfig.defaults,
);

/// Platform picker (override with a fake in widget tests).
final fileSourceProvider = Provider<FileSource>(
  (ref) => const PlatformFileSource(),
);

final fileValidationServiceProvider = Provider<FileValidationService>(
  (ref) => FileValidationService(config: ref.watch(fileEngineConfigProvider)),
);

final languageDetectorProvider = Provider<LanguageDetector>(
  (ref) => ScriptLanguageDetector(config: ref.watch(fileEngineConfigProvider)),
);

final textExtractorProvider = Provider<TextExtractor>(
  (ref) => PipelineTextExtractor(config: ref.watch(fileEngineConfigProvider)),
);

final ocrEngineProvider = Provider<OcrEngine>(
  (ref) => MlKitOcrEngine(
    scriptFallback: ref.watch(fileEngineConfigProvider).ocrScriptFallback,
  ),
);

final importStorageProvider = Provider<ImportStorage>(
  (ref) => const LocalImportStorage(),
);

final fileImportServiceProvider = Provider<FileImportService>(
  (ref) => FileImportService(
    validation: ref.watch(fileValidationServiceProvider),
    extractor: ref.watch(textExtractorProvider),
    ocr: ref.watch(ocrEngineProvider),
    detector: ref.watch(languageDetectorProvider),
    storage: ref.watch(importStorageProvider),
    config: ref.watch(fileEngineConfigProvider),
  ),
);
