import 'dart:io';
import 'dart:typed_data';

import '../../../../core/services/logging/app_logger.dart';
import '../../../../core/services/storage/app_paths.dart';
import '../../domain/services/import_storage.dart';

/// Writes imported files under `AppPaths.filesDirectory()` as
/// `<id>__<original name>` and returns that path.
///
/// Storage failures never abort an import: the source path stays usable and a
/// warning (file name + reason only, never content) is logged.
class LocalImportStorage implements ImportStorage {
  const LocalImportStorage();

  @override
  Future<String> store({
    required String id,
    required String fileName,
    required String sourcePath,
    required Uint8List bytes,
  }) async {
    try {
      final directory = await AppPaths.filesDirectory();
      if (!directory.existsSync()) {
        await directory.create(recursive: true);
      }
      final safeName = fileName.replaceAll(RegExp(r'[^\p{L}\p{N}._-]+'), '_');
      final target = File(
        '${directory.path}${Platform.pathSeparator}${id}__$safeName',
      );
      await target.writeAsBytes(bytes, flush: true);
      return target.path;
    } catch (error) {
      AppLogger.warn('could not copy imported file "$fileName": $error');
      return sourcePath;
    }
  }
}

/// Keeps the picked path as-is — used by unit tests and as a safety net when
/// app storage is unavailable.
class PassthroughImportStorage implements ImportStorage {
  const PassthroughImportStorage();

  @override
  Future<String> store({
    required String id,
    required String fileName,
    required String sourcePath,
    required Uint8List bytes,
  }) async {
    return sourcePath;
  }
}
