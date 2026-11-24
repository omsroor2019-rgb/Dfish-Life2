/// API-Football configuration.
/// Replace the placeholder with a NEW key from your API-Football dashboard.
/// NOTE: A key embedded in an Android APK can be extracted by its users.
class ApiConfig {
  ApiConfig._();

  static const String footballBaseUrl = 'https://v3.football.api-sports.io';
  static const String footballApiKey = '5df46e7eca263cc5f30a9395853fdbcc';

  static bool get isFootballConfigured =>
      footballApiKey.trim().isNotEmpty &&
      !footballApiKey.contains('PASTE_NEW_') &&
      !footballApiKey.contains('YOUR_');
}
