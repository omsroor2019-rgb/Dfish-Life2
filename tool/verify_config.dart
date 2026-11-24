import 'dart:io';

void main() {
  final firebase = File('lib/firebase_options.dart').readAsStringSync();
  final problems = <String>[];
  final apiKey = Platform.environment['API_FOOTBALL_KEY'] ?? '';

  if (apiKey.trim().isEmpty) {
    problems.add('أضف API_FOOTBALL_KEY إلى GitHub Secrets.');
  }
  for (final placeholder in [
    'YOUR_FIREBASE_API_KEY',
    'YOUR_FIREBASE_ANDROID_APP_ID',
    'YOUR_FIREBASE_MESSAGING_SENDER_ID',
    'YOUR_FIREBASE_PROJECT_ID',
  ]) {
    if (firebase.contains(placeholder)) {
      problems.add('أكمل إعداد Firebase في lib/firebase_options.dart');
      break;
    }
  }
  if (problems.isNotEmpty) {
    stderr.writeln('لم يبدأ البناء لأن إعدادات المشروع ناقصة:');
    for (final problem in problems.toSet()) {
      stderr.writeln('- $problem');
    }
    exitCode = 1;
    return;
  }
  stdout.writeln('تم التحقق من إعدادات Firebase ووجود مفتاح API-Football.');
}
