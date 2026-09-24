import 'package:firebase_core/firebase_core.dart';

import '../../../firebase_options.dart';
import '../../config/app_config.dart';

/// Firebase credentials for QARI | قارئ.
///
/// Delegates to the FlutterFire-generated [DefaultFirebaseOptions] (project
/// `qari-4e344`). Returns `null` until [AppConfig.firebaseConfigured] is
/// enabled so offline-first builds never touch Firebase.
class AppFirebaseOptions {
  static FirebaseOptions? get current {
    if (!AppConfig.firebaseConfigured) return null;
    return DefaultFirebaseOptions.currentPlatform;
  }
}
