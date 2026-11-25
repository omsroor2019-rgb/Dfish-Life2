/// إعدادات API-Football لتطبيق DFISH LIVE.
/// مرّر المفتاح عند البناء باستخدام --dart-define=API_FOOTBALL_KEY=...
/// تنبيه: المفتاح المضمّن في APK يمكن استخراجه من التطبيق؛ استخدم مفتاحاً
/// مخصصاً للتطبيق وقيّد استخدامه من لوحة مزوّد الخدمة قدر الإمكان.
class ApiConfig {
  ApiConfig._();

  static const String footballBaseUrl =
      'https://v3.football.api-sports.io';

  static const String footballApiKey =
      String.fromEnvironment('API_FOOTBALL_KEY');

  /// سنة بدء الموسم الجاري (مثلاً 2026 لموسم 2026/2027).
  static int get currentSeason => DateTime.now().year;

  /// نطاق السنوات التي نجربها من الأحدث إلى الأقدم.
  /// القائمة لا تعني أن حساب API يملك صلاحية الوصول إلى كل سنة.
  static List<int> get requestedSeasons => <int>[
        currentSeason + 1,
        currentSeason,
        currentSeason - 1,
        currentSeason - 2,
        currentSeason - 3,
        currentSeason - 4,
      ];

  /// المواسم التاريخية التي تتيحها الخطة المجانية وفق توثيق المزود لعام 2026.
  /// تستخدم كمرجع احتياطي فقط؛ التحقق النهائي يتم بطلب API الفعلي.
  static List<int> get freePlanSeasons => <int>[
        currentSeason - 2,
        currentSeason - 3,
        currentSeason - 4,
      ];

  static bool get isFootballConfigured =>
      footballApiKey.trim().isNotEmpty &&
      !footballApiKey.contains('YOUR_') &&
      !footballApiKey.contains('PASTE_');
}
