import 'dart:io';

import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';

import '../services/logging/app_logger.dart';

/// Box names used across the app.
abstract final class HiveBoxes {
  static const String appSettings = 'app_settings';
  static const String session = 'session';
  static const String library = 'library';
  static const String readingProgress = 'reading_progress';
  static const String bookmarks = 'bookmarks';
  static const String suggestions = 'suggestions';
  static const String cache = 'cache';

  static List<String> get values => [
        appSettings,
        session,
        library,
        readingProgress,
        bookmarks,
        suggestions,
        cache,
      ];
}

/// Local (offline-first) database wrapper around Hive.
///
/// Hive was chosen as the primary local DB for its speed, small footprint and
/// first-class Flutter support. The database is reached only through this
/// class so the underlying engine can be swapped (Isar / SQLite) later
/// without touching feature code.
class AppDatabase {
  AppDatabase._();

  static bool _initialized = false;

  static bool get isInitialized => _initialized;

  /// Initializes Hive with Flutter adapters on the device.
  ///
  /// Safe to call more than once. Returns false when already initialized.
  static Future<bool> initialize() async {
    if (_initialized) return true;
    try {
      final dir = await getApplicationSupportDirectory();
      Hive.init(dir.path);
      await Future.wait([
        Hive.openBox<Map<dynamic, dynamic>>(HiveBoxes.appSettings),
        Hive.openBox<Map<dynamic, dynamic>>(HiveBoxes.session),
        Hive.openBox<Map<dynamic, dynamic>>(HiveBoxes.library),
        Hive.openBox<Map<dynamic, dynamic>>(HiveBoxes.readingProgress),
        Hive.openBox<Map<dynamic, dynamic>>(HiveBoxes.bookmarks),
        Hive.openBox<Map<dynamic, dynamic>>(HiveBoxes.suggestions),
        Hive.openBox<Map<dynamic, dynamic>>(HiveBoxes.cache),
      ]);
      _initialized = true;
      AppLogger.debug('AppDatabase initialized');
      return true;
    } catch (e) {
      AppLogger.error('AppDatabase initialize failed', e);
      return false;
    }
  }

  static Box<Map<dynamic, dynamic>> box(String name) =>
      Hive.box<Map<dynamic, dynamic>>(name);

  static Future<List<File>> diskFiles() async {
    final support = await getApplicationSupportDirectory();
    final dir = Directory('${support.path}${Platform.pathSeparator}files');
    if (!dir.existsSync()) return const [];
    return dir.listSync().whereType<File>().toList();
  }

  /// Closes every open box (used by tests and to wipe data).
  static Future<void> close() async {
    try {
      for (final name in HiveBoxes.values) {
        if (Hive.isBoxOpen(name)) {
          await Hive.box<Map<dynamic, dynamic>>(name).close();
        }
      }
      _initialized = false;
    } catch (e) {
      AppLogger.error('AppDatabase close failed', e);
    }
  }

  /// Deletes all local boxes (used by "clear local data").
  static Future<void> clearAll() async {
    var deleted = false;
    try {
      for (final name in HiveBoxes.values) {
        if (Hive.isBoxOpen(name)) {
          await Hive.deleteBoxFromDisk(name);
        }
      }
      deleted = true;
    } catch (e) {
      AppLogger.error('AppDatabase clear failed', e);
    }
    if (!deleted) return;
    _initialized = false;
    await initialize();
  }
}

extension HiveBoxValues on Box<Map<dynamic, dynamic>> {
  dynamic getValue(String key) => containsKey(key) ? get(key) : null;

  Future<void> setValue(String key, dynamic value) => put(key, value);

  T? getOrNull<T>(dynamic key) {
    final value = get(key);
    return value == null ? null : value as T;
  }
}