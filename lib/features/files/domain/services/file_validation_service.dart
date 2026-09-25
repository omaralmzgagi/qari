import '../../../../core/config/file_engine_config.dart';
import '../entities/file_import_error.dart';

/// A file that passed validation.
class ValidatedFile {
  const ValidatedFile({
    required this.name,
    required this.extension,
    required this.sizeBytes,
    required this.mimeType,
    required this.isImage,
    required this.isLegacyOffice,
  });

  final String name;
  final String extension;
  final int sizeBytes;
  final String mimeType;
  final bool isImage;
  final bool isLegacyOffice;
}

/// Pure validation step: name, extension, size and format expectations.
///
/// It performs no I/O, which makes it trivial to unit-test and cheap enough
/// to run before any byte is read from disk.
class FileValidationService {
  const FileValidationService({this.config = FileEngineConfig.defaults});

  final FileEngineConfig config;

  /// Throws [FileImportException] describing the first problem found.
  ValidatedFile validate({
    required String fileName,
    required int sizeBytes,
  }) {
    final name = fileName.trim();
    if (name.isEmpty) {
      throw const FileImportException(FileImportErrorKind.invalidFile);
    }

    final extension = FileEngineConfig.extensionOf(name);
    if (extension.isEmpty) {
      throw const FileImportException(
        FileImportErrorKind.invalidFile,
        'file has no extension',
      );
    }

    if (!config.supports(extension)) {
      throw FileImportException(
        FileImportErrorKind.unsupportedFile,
        'unsupported extension: .$extension',
      );
    }

    if (sizeBytes <= 0) {
      throw const FileImportException(
        FileImportErrorKind.invalidFile,
        'file is empty',
      );
    }

    final limit = config.maxBytesFor(extension);
    if (sizeBytes > limit) {
      throw FileImportException(
        FileImportErrorKind.fileTooLarge,
        '$sizeBytes > $limit',
      );
    }

    return ValidatedFile(
      name: name,
      extension: extension,
      sizeBytes: sizeBytes,
      mimeType: FileEngineConfig.mimeTypeFor(extension),
      isImage: config.isImage(extension),
      isLegacyOffice: config.isLegacyOffice(extension),
    );
  }
}
