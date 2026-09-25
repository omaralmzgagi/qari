import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import '../../domain/entities/file_import_error.dart';
import '../../domain/services/ocr_engine.dart';

/// Real OCR backed by Google ML Kit's on-device text recognition.
///
/// Everything runs locally: the model ships inside the APK and no image or
/// recognised text ever leaves the device.
///
/// Script selection
/// ----------------
/// ML Kit ships four recognisers in this Flutter package: `latin`,
/// `chinese`, `devanagiri` and `japanese`/`korean` (the latter two are not
/// part of QARI's language set). The engine maps the detected language onto
/// the matching script and, when `scriptFallback` is enabled, retries with
/// the remaining scripts if the first one returns nothing — which is what
/// makes a scanned page work regardless of which script it actually uses.
class MlKitOcrEngine implements OcrEngine {
  const MlKitOcrEngine({this.scriptFallback = true});

  /// Whether an empty first pass should be retried with the other scripts.
  final bool scriptFallback;

  /// Scripts this engine can run on device, in preferred order for
  /// [languageCode].
  ///
  /// The list only contains scripts whose model artifact is actually bundled
  /// with the app (`latin` ships with the core dependency; `chinese` and
  /// `devanagiri` come from the two extra Android artifacts). Japanese and
  /// Korean models are intentionally **not** shipped, so they are never
  /// requested.
  static List<TextRecognitionScript> scriptsFor(
    String languageCode, {
    required bool fallback,
  }) {
    final hint = scriptForLanguage(languageCode);
    if (!fallback) return [hint];
    const available = [
      TextRecognitionScript.latin,
      TextRecognitionScript.chinese,
      TextRecognitionScript.devanagiri,
    ];
    return [hint, ...available.where((script) => script != hint)];
  }

  /// Maps a QARI language code to the ML Kit script used first.
  ///
  /// `ar` has **no** ML Kit script — the model set of this package covers
  /// Latin, Chinese, Devanagari, Japanese and Korean only — so Arabic images
  /// start with Latin and, when no text is recognised, the pipeline reports
  /// `emptyContent` honestly instead of pretending Arabic OCR worked.
  static TextRecognitionScript scriptForLanguage(String languageCode) {
    switch (languageCode) {
      case 'hi':
        return TextRecognitionScript.devanagiri;
      case 'zh':
        return TextRecognitionScript.chinese;
      default:
        return TextRecognitionScript.latin;
    }
  }

  /// `true` when [languageCode] has a dedicated ML Kit model in this build.
  static bool hasDedicatedModel(String languageCode) =>
      languageCode == 'hi' ||
      languageCode == 'zh' ||
      _latinLanguages.contains(languageCode);

  static const Set<String> _latinLanguages = {
    'en',
    'fr',
    'es',
    'de',
    'tr',
    'it',
    'pt',
  };

  @override
  Future<OcrResult> recognize({
    required String filePath,
    required String languageCode,
  }) async {
    final chain = scriptsFor(languageCode, fallback: scriptFallback);
    OcrResult? emptyResult;
    Object? lastError;

    for (final script in chain) {
      try {
        final text = await _recognize(filePath, script);
        final result = OcrResult(text: text, scriptName: script.name);
        if (!result.isEmpty) return result;
        emptyResult ??= result;
      } catch (error) {
        lastError = error;
      }
    }

    if (emptyResult != null) return emptyResult;

    throw FileImportException(
      FileImportErrorKind.ocrFailed,
      'ML Kit could not process the image: $lastError',
    );
  }

  Future<String> _recognize(
    String filePath,
    TextRecognitionScript script,
  ) async {
    final recognizer = TextRecognizer(script: script);
    try {
      final input = InputImage.fromFilePath(filePath);
      final recognized = await recognizer.processImage(input);
      return recognized.text;
    } finally {
      await recognizer.close();
    }
  }
}
