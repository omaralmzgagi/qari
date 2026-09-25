import '../../../localization/generated/app_localizations.dart';
import '../domain/entities/file_import_error.dart';
import '../domain/entities/processing_status.dart';

/// Translates a [FileImportErrorKind] into a user-facing, translated
/// sentence. Technical details (`FileImportException.detail`) never reach
/// this layer.
String fileImportErrorMessage(
  AppLocalizations l10n,
  FileImportErrorKind kind,
) {
  switch (kind) {
    case FileImportErrorKind.unsupportedFile:
      return l10n.fileErrorUnsupportedFile;
    case FileImportErrorKind.invalidFile:
      return l10n.fileErrorInvalidFile;
    case FileImportErrorKind.fileTooLarge:
      return l10n.fileErrorFileTooLarge;
    case FileImportErrorKind.fileReadError:
      return l10n.fileErrorFileReadError;
    case FileImportErrorKind.extractionFailed:
      return l10n.fileErrorExtractionFailed;
    case FileImportErrorKind.ocrFailed:
      return l10n.fileErrorOcrFailed;
    case FileImportErrorKind.emptyContent:
      return l10n.fileErrorEmptyContent;
    case FileImportErrorKind.languageDetectionFailed:
      return l10n.fileErrorLanguageDetectionFailed;
    case FileImportErrorKind.legacyFormatUnsupported:
      return l10n.fileErrorLegacyFormat;
    case FileImportErrorKind.cancelled:
      return l10n.importCancelled;
  }
}

/// Translates a pipeline status into its progress caption.
String fileImportStatusMessage(
  AppLocalizations l10n,
  ProcessingStatus status,
) {
  switch (status) {
    case ProcessingStatus.idle:
      return l10n.importIdleTitle;
    case ProcessingStatus.selecting:
      return l10n.importStatusSelecting;
    case ProcessingStatus.validating:
      return l10n.importStatusValidating;
    case ProcessingStatus.processing:
      return l10n.importStatusProcessing;
    case ProcessingStatus.extracting:
      return l10n.importStatusExtracting;
    case ProcessingStatus.ocr:
      return l10n.importStatusOcr;
    case ProcessingStatus.completed:
      return l10n.importStatusCompleted;
    case ProcessingStatus.failed:
      return l10n.importStatusFailed;
  }
}

/// Human-readable label for a detected language code.
String detectedLanguageLabel(AppLocalizations l10n, String code) {
  switch (code) {
    case 'ar':
      return l10n.languageAr;
    case 'en':
      return l10n.languageEn;
    case 'fr':
      return l10n.languageFr;
    case 'es':
      return l10n.languageEs;
    case 'de':
      return l10n.languageDe;
    case 'tr':
      return l10n.languageTr;
    case 'it':
      return l10n.languageIt;
    case 'pt':
      return l10n.languagePt;
    case 'zh':
      return l10n.languageZh;
    case 'hi':
      return l10n.languageHi;
    default:
      return l10n.importLanguageUnknown;
  }
}

/// Formats a byte count with binary units (`B`, `KB`, `MB`, `GB`).
String formatByteSize(int bytes) {
  if (bytes <= 0) return '0 B';
  const units = ['B', 'KB', 'MB', 'GB'];
  var value = bytes.toDouble();
  var unit = 0;
  while (value >= 1024 && unit < units.length - 1) {
    value /= 1024;
    unit++;
  }
  final rounded = value >= 10 || unit == 0 ? value.round() : value;
  return '$rounded ${units[unit]}';
}
