import 'package:firebase_core/firebase_core.dart';

import '../../config/app_config.dart';
import 'app_firebase_options.dart';
import '../logging/app_logger.dart';

/// Initializes Firebase only when the project has been configured.
///
/// The app is fully offline-first and must run without Firebase. Use
/// [FirebaseFoundationService.initialize] in `main()`; it is a no-op until
/// [AppConfig.firebaseConfigured] is enabled and native config is present.
abstract final class FirebaseFoundationService {
  static Future<bool> initialize() async {
    if (!AppConfig.firebaseConfigured) {
      AppLogger.info('Firebase skipped (not configured)');
      return false;
    }

    final options = AppFirebaseOptions.current;
    if (options == null) {
      AppLogger.warn('Firebase skipped (options missing)');
      return false;
    }

    try {
      await Firebase.initializeApp(options: options);
      AppLogger.info('Firebase initialized');
      return true;
    } catch (e) {
      AppLogger.error('Firebase initialize failed', e);
      return false;
    }
  }
}
