/// Result of a language detection run.
class DetectedLanguage {
  const DetectedLanguage({
    required this.code,
    required this.confidence,
  });

  /// A language code from [supportedCodes] or [unknownCode].
  final String code;

  /// `0.0`–`1.0`. Below the configured threshold the detector returns
  /// [unknownCode] with the confidence it could reach.
  final double confidence;

  /// Languages the Reader is expected to handle in this phase.
  static const List<String> supportedCodes = [
    'ar',
    'en',
    'fr',
    'es',
    'de',
    'tr',
    'it',
    'pt',
    'zh',
    'hi',
  ];

  static const String unknownCode = 'unknown';

  static const DetectedLanguage unknown = DetectedLanguage(
    code: unknownCode,
    confidence: 0,
  );

  bool get isKnown => code != unknownCode;

  @override
  String toString() => 'DetectedLanguage($code, $confidence)';
}
