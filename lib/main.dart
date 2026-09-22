import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/qari_app.dart';
import 'core/database/app_database.dart';
import 'core/services/firebase/firebase_foundation_service.dart';
import 'core/services/logging/app_logger.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Offline-first: local Hive database is always initialized first.
  await AppDatabase.initialize();

  // Firebase comes second and only activates when configured (see AppConfig).
  await FirebaseFoundationService.initialize();

  AppLogger.verboseEnabled = kDebugMode;

  runApp(const ProviderScope(child: QariApp()));
}