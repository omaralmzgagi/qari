import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qari/features/files/application/file_import_controller.dart';
import 'package:qari/features/files/data/providers/file_engine_providers.dart';
import 'package:qari/features/files/data/services/local_import_storage.dart';
import 'package:qari/features/files/domain/entities/file_import_error.dart';
import 'package:qari/features/files/domain/entities/imported_file.dart';
import 'package:qari/features/files/domain/entities/processing_status.dart';
import 'package:qari/features/files/domain/services/import_storage.dart';
import 'package:qari/features/files/domain/sources/file_source.dart';

import 'fixtures.dart';

const _arabic = 'الحمد لله رب العالمين الرحمن الرحيم مالك يوم الدين';

class _FakeSource implements FileSource {
  _FakeSource(this.next);

  final PickedFile? Function() next;

  @override
  Future<PickedFile?> pick() async => next();
}

class _ThrowingStorage implements ImportStorage {
  @override
  Future<String> store({
    required String id,
    required String fileName,
    required String sourcePath,
    required Uint8List bytes,
  }) async {
    throw StateError('disk exploded');
  }
}

ProviderContainer _container({
  FileSource? source,
  ImportStorage? storage,
}) {
  final container = ProviderContainer(
    overrides: [
      if (source != null) fileSourceProvider.overrideWithValue(source),
      importStorageProvider.overrideWithValue(
        storage ?? const PassthroughImportStorage(),
      ),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  group('FileImportState', () {
    test('starts idle and is neither busy, failed nor completed', () {
      const state = FileImportState();
      expect(state.status, ProcessingStatus.idle);
      expect(state.isBusy, isFalse);
      expect(state.hasError, isFalse);
      expect(state.wasCancelled, isFalse);
      expect(state.isCompleted, isFalse);
      expect(state.result, isNull);
      expect(state.fileName, isNull);
      expect(state.errorKind, isNull);
    });

    test('a cancelled failure is not reported as a hard error', () {
      const state = FileImportState(
        status: ProcessingStatus.idle,
        errorKind: FileImportErrorKind.cancelled,
      );
      expect(state.wasCancelled, isTrue);
      expect(state.hasError, isFalse);
    });

    test('only a failed status with a kind counts as an error', () {
      const state = FileImportState(
        status: ProcessingStatus.failed,
        errorKind: FileImportErrorKind.unsupportedFile,
      );
      expect(state.hasError, isTrue);
      expect(state.wasCancelled, isFalse);
      expect(state.isBusy, isFalse);
    });

    test('copyWith can clear the error and the result independently', () {
      final state = FileImportState(
        status: ProcessingStatus.completed,
        fileName: 'a.txt',
        errorKind: FileImportErrorKind.emptyContent,
      );

      final clearedError = state.copyWith(clearError: true);
      expect(clearedError.errorKind, isNull);
      expect(clearedError.fileName, 'a.txt');
      expect(clearedError.status, ProcessingStatus.completed);

      final clearedResult = state.copyWith(clearResult: true);
      expect(clearedResult.result, isNull);
      expect(clearedResult.errorKind, FileImportErrorKind.emptyContent);
    });

    test('toString names the status and the error kind', () {
      const state = FileImportState(
        status: ProcessingStatus.failed,
        fileName: 'a.txt',
        errorKind: FileImportErrorKind.fileTooLarge,
      );
      expect(state.toString(), contains('failed'));
      expect(state.toString(), contains('a.txt'));
      expect(state.toString(), contains('fileTooLarge'));
    });
  });

  group('pickAndImport', () {
    test('dismissing the picker lands on idle without crashing', () async {
      final container = _container(source: _FakeSource(() => null));
      final controller = container.read(fileImportControllerProvider.notifier);

      await controller.pickAndImport();

      final state = container.read(fileImportControllerProvider);
      expect(state.status, ProcessingStatus.idle);
      expect(state.wasCancelled, isTrue);
      expect(state.hasError, isFalse);
      expect(state.isBusy, isFalse);
      expect(state.result, isNull);
    });

    test('a real text file reaches the completed state', () async {
      final bytes = utf8Of(_arabic);
      final container = _container(
        source: _FakeSource(
          () => PickedFile(
            name: 'notes.txt',
            size: bytes.length,
            bytes: bytes,
          ),
        ),
      );
      final controller = container.read(fileImportControllerProvider.notifier);

      await controller.pickAndImport();

      final state = container.read(fileImportControllerProvider);
      expect(state.status, ProcessingStatus.completed);
      expect(state.isCompleted, isTrue);
      expect(state.hasError, isFalse);
      expect(state.fileName, 'notes.txt');
      expect(state.result, isNotNull);
      expect(state.result!.extractedText, _arabic);
      expect(state.result!.detectedLanguage, 'ar');
      expect(state.result!.usedOcr, isFalse);
    });

    test('an unsupported file reaches the failed state with its kind',
        () async {
      final container = _container(
        source: _FakeSource(
          () => PickedFile(name: 'holiday.gif', bytes: utf8Of('picture')),
        ),
      );
      final controller = container.read(fileImportControllerProvider.notifier);

      await controller.pickAndImport();

      final state = container.read(fileImportControllerProvider);
      expect(state.status, ProcessingStatus.failed);
      expect(state.hasError, isTrue);
      expect(state.errorKind, FileImportErrorKind.unsupportedFile);
      expect(state.wasCancelled, isFalse);
      expect(state.isBusy, isFalse);
      expect(state.result, isNull);
    });

    test('an unexpected non-typed error degrades to extractionFailed',
        () async {
      final container = _container(
        source: _FakeSource(
          () => PickedFile(name: 'notes.txt', bytes: utf8Of(_arabic)),
        ),
        storage: _ThrowingStorage(),
      );
      final controller = container.read(fileImportControllerProvider.notifier);

      await controller.pickAndImport();

      final state = container.read(fileImportControllerProvider);
      expect(state.status, ProcessingStatus.failed);
      expect(state.errorKind, FileImportErrorKind.extractionFailed);
      expect(state.hasError, isTrue);
    });

    test('reset returns the controller to a clean idle state', () async {
      final container = _container(
        source: _FakeSource(
          () => PickedFile(name: 'holiday.gif', bytes: utf8Of('picture')),
        ),
      );
      final controller = container.read(fileImportControllerProvider.notifier);

      await controller.pickAndImport();
      expect(container.read(fileImportControllerProvider).hasError, isTrue);

      controller.reset();

      final state = container.read(fileImportControllerProvider);
      expect(state.status, ProcessingStatus.idle);
      expect(state.hasError, isFalse);
      expect(state.errorKind, isNull);
      expect(state.result, isNull);
      expect(state.fileName, isNull);
    });
  });

  group('importPicked', () {
    test('a legacy binary file surfaces legacyFormatUnsupported', () async {
      final container = _container(
        storage: const PassthroughImportStorage(),
      );
      final controller = container.read(fileImportControllerProvider.notifier);

      await controller.importPicked(
        PickedFile(name: 'old.doc', bytes: utf8Of('legacy bytes')),
      );

      final state = container.read(fileImportControllerProvider);
      expect(state.status, ProcessingStatus.failed);
      expect(state.errorKind, FileImportErrorKind.legacyFormatUnsupported);
      expect(state.fileName, 'old.doc');
    });

    test('a completed run keeps the file name for the result card', () async {
      final container = _container();
      final controller = container.read(fileImportControllerProvider.notifier);

      await controller.importPicked(
        PickedFile(
          name: 'epub.epub',
          bytes: epubOf(['Chapter one body.']),
        ),
      );

      final state = container.read(fileImportControllerProvider);
      expect(state.status, ProcessingStatus.completed);
      expect(state.result, isA<ImportedFile>());
      expect(state.result!.pageCount, 1);
      expect(state.result!.fileName, 'epub.epub');
    });
  });
}
