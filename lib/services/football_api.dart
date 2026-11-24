import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import '../config/api_config.dart';
import '../config/league_catalog.dart';

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
        'مفتاح API-Football غير موجود. أضف GitHub Secret باسم API_FOOTBALL_KEY ثم أعد البناء.',
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

    dynamic decoded;
    try {
      decoded = jsonDecode(utf8.decode(response.bodyBytes));
    } catch (_) {
      if (response.statusCode == 429) {
        throw const ApiException('تم استهلاك حد الطلبات. انتظر تجدد الحصة اليومية.');
      }
      if (response.statusCode == 401 || response.statusCode == 403) {
        throw const ApiException('رفض مزوّد البيانات الطلب. تحقق من المفتاح والخطة وصلاحية الموسم.');
      }
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw ApiException('تعذر جلب البيانات (HTTP ${response.statusCode}).');
      }
      throw const ApiException('استجابة غير مفهومة من API-Football.');
    }
    if (decoded is! Map<String, dynamic>) {
      throw const ApiException('تنسيق استجابة غير صالح من API-Football.');
    }

    final errors = decoded['errors'];
    if (errors is Map && errors.isNotEmpty) {
      throw ApiException(_translateApiError(errors.values.map((v) => v.toString()).join('، ')));
    }
    if (errors is List && errors.isNotEmpty) {
      throw ApiException(_translateApiError(errors.map((v) => v.toString()).join('، ')));
    }
    if (response.statusCode == 429) {
      throw const ApiException('تم استهلاك حد الطلبات. انتظر تجدد الحصة اليومية.');
    }
    if (response.statusCode == 401 || response.statusCode == 403) {
      throw const ApiException('رفض مزوّد البيانات الطلب. تحقق من المفتاح والخطة وصلاحية الموسم.');
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException('تعذر جلب البيانات (HTTP ${response.statusCode}).');
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

  String _translateApiError(String message) {
    final lower = message.toLowerCase();
    if (lower.contains('free plans do not have access') ||
        lower.contains('not available on the free plan')) {
      return 'الخطة المجانية لا تتيح هذا الموسم. في 2026 جرّب المواسم ${ApiConfig.freePlanSeasons.first} إلى ${ApiConfig.freePlanSeasons.last}، أو استخدم خطة تدعم الموسم الحالي.';
    }
    if (lower.contains('requests') && lower.contains('limit')) {
      return 'تم استهلاك حصة طلبات API-Football. حاول بعد تجدد الحصة اليومية.';
    }
    if (lower.contains('no data') || lower.contains('no results')) {
      return 'لا توجد بيانات متاحة لهذه البطولة والموسم.';
    }
    return message;
  }

  Duration _cacheDuration(String endpoint) {
    switch (endpoint) {
      case 'fixtures':
        return const Duration(minutes: 2);
      case 'fixtures/events':
      case 'fixtures/lineups':
      case 'fixtures/statistics':
      case 'fixtures/players':
      case 'fixtures/headtohead':
        return const Duration(minutes: 1);
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
    final requestedDate = date ?? _nowInAden();
    final params = <String, String>{'timezone': footballTimezone};
    if (live) {
      params['live'] = 'all';
    } else {
      params['date'] = DateFormat('yyyy-MM-dd').format(requestedDate);
    }
    // اجمع صفحات اليوم أولاً ثم صفِّ المسابقات حتى لا تختفي مباريات
    // البطولات القارية التي تقع في الصفحات التالية من استجابة المزود.
    final rows = <Map<String, dynamic>>[];
    var page = 1;
    var totalPages = 1;
    do {
      final pageParams = <String, String>{...params, 'page': '$page'};
      final data = await get('fixtures', pageParams);
      final responseRows = (data['response'] as List?) ?? const [];
      rows.addAll(responseRows.whereType<Map>().map((row) => Map<String, dynamic>.from(row)));
      final paging = data['paging'];
      if (paging is Map) totalPages = (paging['total'] as num?)?.toInt() ?? 1;
      page++;
    } while (page <= totalPages && page <= 30);

    final filtered = rows.where(LeagueCatalog.isAllowedFixture).toList();
    filtered.sort((a, b) {
      final aDate = a['fixture']?['date']?.toString() ?? '';
      final bDate = b['fixture']?['date']?.toString() ?? '';
      return aDate.compareTo(bDate);
    });
    return filtered;
  }

  Future<List<dynamic>> fixtureData(String endpoint, int fixtureId) async {
    final data = await get(endpoint, {'fixture': '$fixtureId'});
    return (data['response'] as List?) ?? const [];
  }

  Future<List<dynamic>> headToHead(int homeTeamId, int awayTeamId) async {
    if (homeTeamId <= 0 || awayTeamId <= 0) return const [];
    final data = await get('fixtures/headtohead', {
      'h2h': '$homeTeamId-$awayTeamId',
      'last': '8',
      'timezone': footballTimezone,
    });
    return (data['response'] as List?) ?? const [];
  }

  /// يعيد الدرجة الأولى في الخليج واليمن وأبرز دوريات أوروبا،
  /// مع دوري أبطال أوروبا وبطولات أبطال آسيا المحددة فقط.
  Future<List<dynamic>> leagues({required int season}) async {
    final data = await get('leagues', {'season': '$season'});
    final rows = (data['response'] as List?) ?? const [];
    final filtered = rows
        .whereType<Map>()
        .map((row) => Map<String, dynamic>.from(row))
        .where(LeagueCatalog.isAllowed)
        .toList();
    filtered.sort((a, b) {
      final byCountry = LeagueCatalog.priority(a).compareTo(LeagueCatalog.priority(b));
      if (byCountry != 0) return byCountry;
      return LeagueCatalog.displayName(a).compareTo(LeagueCatalog.displayName(b));
    });
    return filtered;
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
