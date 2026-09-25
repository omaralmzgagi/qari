import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/providers/file_engine_providers.dart';
import '../domain/entities/file_import_error.dart';
import '../domain/entities/imported_file.dart';
import '../domain/entities/processing_status.dart';
import '../domain/language/detected_language.dart';
import '../domain/sources/file_source.dart';

/// Everything the import screen needs to render one import run.
class FileImportState {
  const FileImportState({
    this.status = ProcessingStatus.idle,
    this.fileName,
    this.result,
    this.errorKind,
  });

  final ProcessingStatus status;
  final String? fileName;
  final ImportedFile? result;
  final FileImportErrorKind? errorKind;

  bool get isBusy => status.isBusy;

  bool get hasError => status == ProcessingStatus.failed && errorKind != null;

  bool get wasCancelled => errorKind == FileImportErrorKind.cancelled;

  bool get isCompleted => status == ProcessingStatus.completed;

  FileImportState copyWith({
    ProcessingStatus? status,
    String? fileName,
    ImportedFile? result,
    FileImportErrorKind? errorKind,
    bool clearError = false,
    bool clearResult = false,
  }) {
    return FileImportState(
      status: status ?? this.status,
      fileName: fileName ?? this.fileName,
      result: clearResult ? null : (result ?? this.result),
      errorKind: clearError ? null : (errorKind ?? this.errorKind),
    );
  }

  @override
  String toString() =>
      'FileImportState(${status.name}, file: $fileName, error: ${errorKind?.name})';
}

/// Drives the File Engine: pick → validate → extract/OCR → detect language.
final fileImportControllerProvider =
    NotifierProvider<FileImportController, FileImportState>(
  FileImportController.new,
);

class FileImportController extends Notifier<FileImportState> {
  @override
  FileImportState build() => const FileImportState();

  /// Opens the platform picker and imports whatever the user chose.
  Future<void> pickAndImport() async {
    final source = ref.read(fileSourceProvider);
    final picked = await source.pick();
    if (picked == null) {
      state = FileImportState(
        status: ProcessingStatus.idle,
        errorKind: FileImportErrorKind.cancelled,
      );
      return;
    }
    await importPicked(picked);
  }

  /// Imports an already-picked file (used by tests and by the picker path).
  Future<void> importPicked(PickedFile file) async {
    final service = ref.read(fileImportServiceProvider);
    state = FileImportState(
      status: ProcessingStatus.selecting,
      fileName: file.name,
    );

    try {
      final result = await service.import(
        fileName: file.name,
        sourcePath: file.path,
        bytes: file.bytes == null ? null : Uint8List.fromList(file.bytes!),
        sizeBytes: file.size,
        languageHint: DetectedLanguage.unknownCode,
        onStatus: (status) => state = state.copyWith(status: status),
      );
      state = FileImportState(
        status: ProcessingStatus.completed,
        fileName: file.name,
        result: result,
      );
    } on FileImportException catch (error) {
      state = FileImportState(
        status: ProcessingStatus.failed,
        fileName: file.name,
        errorKind: error.kind,
      );
    } catch (_) {
      state = FileImportState(
        status: ProcessingStatus.failed,
        fileName: file.name,
        errorKind: FileImportErrorKind.extractionFailed,
      );
    }
  }

  /// Returns to the idle screen (after a failure or a completed import).
  void reset() => state = const FileImportState();
}
