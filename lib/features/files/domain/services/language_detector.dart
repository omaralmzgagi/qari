import '../entities/file_import_error.dart';
import '../language/detected_language.dart';

/// Detects the language of an already extracted text.
///
/// Implementations are pure Dart so they are unit-testable without plugins.
abstract interface class LanguageDetector {
  /// Never returns `null`; unknown or unreliable input yields
  /// [DetectedLanguage.unknown].
  ///
  /// Throws [FileImportException] with
  /// [FileImportErrorKind.languageDetectionFailed] when the detector itself
  /// fails (empty input is *not* a failure — it is handled earlier by the
  /// `emptyContent` check).
  DetectedLanguage detect(String text);
}
