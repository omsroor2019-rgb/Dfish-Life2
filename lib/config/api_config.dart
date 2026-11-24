/// إعدادات API-Football لتطبيق DFISH LIVE.
/// مرّر المفتاح عند البناء باستخدام --dart-define=API_FOOTBALL_KEY=...
/// تنبيه: المفتاح المضمن في APK يمكن استخراجه من التطبيق.
class ApiConfig {
  ApiConfig._();

  static const String footballBaseUrl = 'https://v3.football.api-sports.io';
  static const String footballApiKey = String.fromEnvironment('5df46e7eca263cc5f30a9395853fdbcc');

  /// الخطة المجانية في 2026 تتيح المواسم من السنة الحالية - 4 إلى - 2.
  /// مثال 2026: 2022، 2023، 2024.
  static List<int> get freePlanSeasons {
    final year = DateTime.now().toUtc().year;
    return List<int>.generate(3, (index) => year - 4 + index);
  }

  static bool get isFootballConfigured =>
      footballApiKey.trim().isNotEmpty &&
      !footballApiKey.contains('YOUR_') &&
      !footballApiKey.contains('PASTE_');
}
