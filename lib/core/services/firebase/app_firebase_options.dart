import 'package:firebase_core/firebase_core.dart';

import '../../config/app_config.dart';

/// Firebase credentials for QARI | قارئ.
///
/// IMPORTANT:
/// - Never commit real credentials. Fill these in locally, or better: keep
///   them out of the repository entirely (e.g. from a secure config source).
/// - Set [AppConfig.firebaseConfigured] to `true` only after the Android
///   `google-services.json` / iOS `GoogleService-Info.plist` are present.
class AppFirebaseOptions {
  static FirebaseOptions? get current {
    if (!AppConfig.firebaseConfigured) return null;

    // TODO(branding config): insert your Firebase web/cloud project values.
    return const FirebaseOptions(
      apiKey: 'YOUR_API_KEY',
      appId: 'YOUR_APP_ID',
      messagingSenderId: 'YOUR_SENDER_ID',
      projectId: 'YOUR_PROJECT_ID',
      storageBucket: 'YOUR_PROJECT_ID.appspot.com',
    );
  }
}