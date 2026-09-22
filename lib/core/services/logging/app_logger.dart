/// Minimal logging utility with configurable levels.
///
/// Kept dependency-free on purpose. `verbose` is disabled by default; enable
/// per-environment via [AppLogger.verboseEnabled].
abstract final class AppLogger {
  static bool verboseEnabled = false;

  static void debug(String message) {
    if (verboseEnabled) {
      // ignore: avoid_print
      print('[QARI][DEBUG] $message');
    }
  }

  static void info(String message) {
    debug(message);
  }

  static void warn(String message) {
    // ignore: avoid_print
    print('[QARI][WARN] $message');
  }

  static void error(String message, [Object? error]) {
    final err = error == null ? '' : ' > $error';
    // ignore: avoid_print
    print('[QARI][ERROR] $message$err');
  }
}