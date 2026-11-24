import 'dart:io';

void main() {
  final api = File('lib/config/api_config.dart').readAsStringSync();
  final firebase = File('lib/firebase_options.dart').readAsStringSync();
  final problems = <String>[];

  if (api.contains('PASTE_NEW_API_FOOTBALL_KEY_HERE') ||
      api.contains('YOUR_API_KEY')) {
    problems.add('أضف مفتاح API-Football الجديد في lib/config/api_config.dart');
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

  stdout.writeln('تم العثور على إعداد API-Football وFirebase.');
}
