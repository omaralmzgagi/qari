import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// Resolves well-known application directories.
abstract final class AppPaths {
  static Future<Directory> get documentsDirectory async =>
      await getApplicationDocumentsDirectory();

  static Future<Directory> get supportDirectory async =>
      await getApplicationSupportDirectory();

  /// Directory where imported files are stored locally (offline-first).
  static Future<Directory> filesDirectory() async {
    final support = await getApplicationSupportDirectory();
    return Directory('${support.path}${Platform.pathSeparator}files');
  }
}
