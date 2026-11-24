import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;

/// Firebase Android application configuration.
/// Copy these non-secret app identifiers from Firebase Console > Project settings.
/// Do NOT put a Firebase service-account private key in this file.
class DefaultFirebaseOptions {
  DefaultFirebaseOptions._();

  static const String apiKey = 'AIzaSyAauHgIyX6VWm70GZHZhbooqW_khEH_q1Y';
  static const String appId = '1:886205661677:android:d2037192c5cfcd7e9ae7e4';
  static const String messagingSenderId = '886205661677';
  static const String projectId = 'dfish-live';
  static const String storageBucket = 'dfish-live.firebasestorage.app';

  static bool get isConfigured =>
      !apiKey.startsWith('YOUR_') &&
      !appId.startsWith('YOUR_') &&
      !messagingSenderId.startsWith('YOUR_') &&
      !projectId.startsWith('YOUR_') &&
      apiKey.trim().isNotEmpty &&
      appId.trim().isNotEmpty &&
      messagingSenderId.trim().isNotEmpty &&
      projectId.trim().isNotEmpty;

  static FirebaseOptions get android => FirebaseOptions(
        apiKey: apiKey,
        appId: appId,
        messagingSenderId: messagingSenderId,
        projectId: projectId,
        storageBucket: storageBucket.trim().isEmpty ? null : storageBucket,
      );
}
