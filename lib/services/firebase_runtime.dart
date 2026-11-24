import 'package:firebase_core/firebase_core.dart';

import '../firebase_options.dart';

class FirebaseRuntime {
  FirebaseRuntime._();

  static bool isReady = false;
  static String? initializationError;

  static Future<void> initialize() async {
    if (!DefaultFirebaseOptions.isConfigured) return;
    try {
      await Firebase.initializeApp(options: DefaultFirebaseOptions.android);
      isReady = true;
      initializationError = null;
    } catch (error) {
      isReady = false;
      initializationError = error.toString();
    }
  }
}
