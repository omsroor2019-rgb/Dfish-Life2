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

  /// خيارات الموسم المطلوبة في DFISH LIVE: الموسم الجاري والموسم التالي.
  /// توفر البيانات وإمكانية الوصول إليهما يعتمدان على البطولة والخطة.
  static List<int> get requestedSeasons =>
      <int>[currentSeason + 1, currentSeason];

  /// اسم قديم أبقيناه للتوافق مع أي ملفات أخرى في المشروع.
  /// لا يعني أن هذه السنوات كلها متاحة في الخطة المجانية.
  static List<int> get freePlanSeasons => requestedSeasons;

  static bool get isFootballConfigured =>
      footballApiKey.trim().isNotEmpty &&
      !footballApiKey.contains('YOUR_') &&
      !footballApiKey.contains('PASTE_');
}
