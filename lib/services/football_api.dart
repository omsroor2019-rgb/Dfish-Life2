import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import '../config/api_config.dart';

const String footballTimezone = 'Asia/Aden';

DateTime _nowInAden() => DateTime.now().toUtc().add(const Duration(hours: 3));

class FootballApi {
  FootballApi._();
  static final FootballApi instance = FootballApi._();

  static const String baseUrl = ApiConfig.footballBaseUrl;
  final http.Client _client = http.Client();
  final Map<String, _CachedResponse> _cache = {};

  bool get isConfigured => ApiConfig.isFootballConfigured;

  Future<Map<String, dynamic>> get(
    String endpoint, [
    Map<String, String>? params,
  ]) async {
    if (!isConfigured) {
      throw const ApiException(
        'مفتاح API-Football غير موجود. أضف المفتاح الجديد في lib/config/api_config.dart.',
      );
    }

    final uri = Uri.parse('$baseUrl/$endpoint').replace(
      queryParameters: params == null || params.isEmpty ? null : params,
    );
    final cacheKey = uri.toString();
    final cached = _cache[cacheKey];
    if (cached != null && cached.expiresAt.isAfter(DateTime.now())) {
      return cached.value;
    }

    http.Response response;
    try {
      // API-Football documents x-apisports-key as its API authentication header.
      response = await _client.get(
        uri,
        headers: {'x-apisports-key': ApiConfig.footballApiKey.trim()},
      ).timeout(const Duration(seconds: 25));
    } on TimeoutException {
      throw const ApiException('انتهت مهلة الاتصال بخدمة المباريات. حاول مجدداً.');
    } catch (_) {
      throw const ApiException('تعذر الاتصال بـ API-Football. تحقق من الإنترنت.');
    }

    if (response.statusCode == 204) {
      return <String, dynamic>{'response': <dynamic>[], 'errors': <String, dynamic>{}, 'results': 0};
    }
    if (response.statusCode == 429) {
      throw const ApiException(
        'تم تجاوز حد طلبات API-Football. انتظر حتى تتجدد الحصة أو راجع اشتراكك.',
      );
    }
    if (response.statusCode == 401 || response.statusCode == 403) {
      throw const ApiException(
        'رفض API-Football المفتاح. تحقق من صحته واشتراكك وصلاحيات الخطة.',
      );
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException('تعذر جلب البيانات (HTTP ${response.statusCode}).');
    }

    dynamic decoded;
    try {
      decoded = jsonDecode(utf8.decode(response.bodyBytes));
    } catch (_) {
      throw const ApiException('استجابة غير مفهومة من API-Football.');
    }
    if (decoded is! Map<String, dynamic>) {
      throw const ApiException('تنسيق استجابة غير صالح من API-Football.');
    }

    final errors = decoded['errors'];
    if (errors is Map && errors.isNotEmpty) {
      throw ApiException(errors.values.map((v) => v.toString()).join('، '));
    }
    if (errors is List && errors.isNotEmpty) {
      throw ApiException(errors.map((v) => v.toString()).join('، '));
    }

    final duration = _cacheDuration(endpoint);
    if (duration > Duration.zero) {
      _cache[cacheKey] = _CachedResponse(
        value: decoded,
        expiresAt: DateTime.now().add(duration),
      );
    }
    return decoded;
  }

  Duration _cacheDuration(String endpoint) {
    switch (endpoint) {
      case 'fixtures':
        return const Duration(minutes: 3);
      case 'leagues':
        return const Duration(hours: 6);
      case 'standings':
      case 'players/topscorers':
      case 'players/topassists':
        return const Duration(minutes: 30);
      case 'status':
        return const Duration(minutes: 2);
      default:
        return const Duration(minutes: 3);
    }
  }

  Future<List<dynamic>> fixtures({DateTime? date, bool live = false}) async {
    final params = <String, String>{'timezone': footballTimezone};
    if (live) {
      params['live'] = 'all';
    } else {
      params['date'] = DateFormat('yyyy-MM-dd').format(date ?? _nowInAden());
    }
    final data = await get('fixtures', params);
    return (data['response'] as List?) ?? const [];
  }

  Future<List<dynamic>> fixtureData(String endpoint, int fixtureId) async {
    final data = await get(endpoint, {'fixture': '$fixtureId'});
    return (data['response'] as List?) ?? const [];
  }

  Future<List<dynamic>> leagues() async {
    final data = await get('leagues', {'current': 'true'});
    return (data['response'] as List?) ?? const [];
  }

  Future<List<dynamic>> standings(int leagueId, int season) async {
    final data = await get('standings', {'league': '$leagueId', 'season': '$season'});
    return (data['response'] as List?) ?? const [];
  }

  Future<List<dynamic>> topScorers(int leagueId, int season) async {
    final data = await get('players/topscorers', {'league': '$leagueId', 'season': '$season'});
    return (data['response'] as List?) ?? const [];
  }

  Future<List<dynamic>> topAssists(int leagueId, int season) async {
    final data = await get('players/topassists', {'league': '$leagueId', 'season': '$season'});
    return (data['response'] as List?) ?? const [];
  }

  Future<List<dynamic>> searchPlayers(String query, int season) async {
    final data = await get('players', {'search': query, 'season': '$season'});
    return (data['response'] as List?) ?? const [];
  }

  Future<List<dynamic>> searchTeams(String query) async {
    final data = await get('teams', {'search': query});
    return (data['response'] as List?) ?? const [];
  }

  Future<List<dynamic>> teamPlayers(int teamId, int season) async {
    final data = await get('players', {'team': '$teamId', 'season': '$season'});
    return (data['response'] as List?) ?? const [];
  }

  Future<Map<String, dynamic>> checkStatus() => get('status');

  void clearCache() => _cache.clear();
}

class _CachedResponse {
  const _CachedResponse({required this.value, required this.expiresAt});
  final Map<String, dynamic> value;
  final DateTime expiresAt;
}

class ApiException implements Exception {
  final String message;
  const ApiException(this.message);
  @override
  String toString() => message;
}
