import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/api_config.dart';
import '../config/league_catalog.dart';

const String footballTimezone = 'Asia/Aden';

DateTime _nowInAden() => DateTime.now().toUtc().add(const Duration(hours: 3));

/// API-Football client with memory + persistent JSON cache, stale fallback,
/// per-URL request de-duplication and daily quota back-off.
class FootballApi {
  FootballApi._();
  static final FootballApi instance = FootballApi._();

  static const String baseUrl = ApiConfig.footballBaseUrl;
  static const String _cachePrefix = 'dfish_api_cache_v2_';
  static const String _cacheIndexKey = 'dfish_api_cache_index_v2';
  static const String _quotaUntilKey = 'dfish_api_quota_until_ms_v1';
  static const int _maxPersistentEntries = 70;
  static const int _maxCacheJsonCharacters = 700000;

  final http.Client _client = http.Client();
  final Map<String, _CachedResponse> _cache = {};
  final Map<String, Future<Map<String, dynamic>>> _inFlight = {};
  final SharedPreferencesAsync _prefs = SharedPreferencesAsync();
  Future<void> _writeQueue = Future<void>.value();
  bool _lastRequestUsedCache = false;
  bool _lastResponseWasStale = false;

  bool get isConfigured => ApiConfig.isFootballConfigured;

  /// True when the latest get() returned locally cached data instead of a new API response.
  bool get lastRequestUsedCache => _lastRequestUsedCache;

  /// True only when the app had to show expired-but-still-useful saved data.
  bool get lastResponseWasStale => _lastResponseWasStale;

  Future<Map<String, dynamic>> get(
    String endpoint, [
    Map<String, String>? params,
  ]) async {
    final sortedParams = <String, String>{};
    if (params != null) {
      final entries = params.entries.toList()
        ..sort((a, b) => a.key.compareTo(b.key));
      for (final entry in entries) {
        sortedParams[entry.key] = entry.value;
      }
    }
    final uri = Uri.parse('$baseUrl/$endpoint').replace(
      queryParameters: sortedParams.isEmpty ? null : sortedParams,
    );
    final cacheKey = uri.toString();

    // Several screens may ask for the same endpoint simultaneously.
    // Share one future instead of spending multiple API requests.
    final running = _inFlight[cacheKey];
    if (running != null) return running;

    final pending = _getWithCache(uri, endpoint, sortedParams, cacheKey);
    _inFlight[cacheKey] = pending;
    try {
      return await pending;
    } finally {
      if (identical(_inFlight[cacheKey], pending)) {
        _inFlight.remove(cacheKey);
      }
    }
  }

  Future<Map<String, dynamic>> _getWithCache(
    Uri uri,
    String endpoint,
    Map<String, String> params,
    String cacheKey,
  ) async {
    _lastRequestUsedCache = false;
    _lastResponseWasStale = false;
    final cached = _cache[cacheKey] ?? await _readPersistentCache(cacheKey);
    if (cached != null) _cache[cacheKey] = cached;

    final now = DateTime.now();
    if (cached != null && cached.expiresAt.isAfter(now)) {
      _lastRequestUsedCache = true;
      _lastResponseWasStale = false;
      return cached.value;
    }

    final quotaUntil = await _readQuotaBlock();
    if (quotaUntil != null && quotaUntil.isAfter(now)) {
      if (_canUseStaleCache(cached, endpoint, now)) {
        _lastRequestUsedCache = true;
        _lastResponseWasStale = true;
        return cached!.value;
      }
      throw const ApiException(
        'تم استهلاك حصة API-Football اليومية. ستُستخدم البيانات المحفوظة حتى تجدد الحصة.',
      );
    }

    try {
      if (!isConfigured) {
        throw const ApiException(
          'مفتاح API-Football غير موجود. أضف GitHub Secret باسم API_FOOTBALL_KEY ثم أعد البناء.',
        );
      }

      final response = await _client.get(
        uri,
        headers: {'x-apisports-key': ApiConfig.footballApiKey.trim()},
      ).timeout(const Duration(seconds: 25));

      if (response.statusCode == 204) {
        final empty = <String, dynamic>{
          'response': <dynamic>[],
          'errors': <String, dynamic>{},
          'results': 0,
        };
        await _storeResponse(cacheKey, empty, _cacheDuration(endpoint, params));
        _lastRequestUsedCache = false;
        return empty;
      }

      dynamic decoded;
      try {
        decoded = jsonDecode(utf8.decode(response.bodyBytes));
      } catch (_) {
        if (response.statusCode == 429) {
          throw const ApiException('تم استهلاك حد طلبات API-Football.');
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

      final errorMessage = _extractErrorMessage(decoded['errors']);
      if (errorMessage.isNotEmpty) {
        throw ApiException(_translateApiError(errorMessage));
      }
      if (response.statusCode == 429) {
        throw const ApiException('تم استهلاك حد طلبات API-Football.');
      }
      if (response.statusCode == 401 || response.statusCode == 403) {
        throw const ApiException('رفض مزوّد البيانات الطلب. تحقق من المفتاح والخطة وصلاحية الموسم.');
      }
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw ApiException('تعذر جلب البيانات (HTTP ${response.statusCode}).');
      }

      await _storeResponse(cacheKey, decoded, _cacheDuration(endpoint, params));
      _lastRequestUsedCache = false;
      _lastResponseWasStale = false;
      return decoded;
    } on TimeoutException {
      return _fallbackOrThrow(
        cached,
        endpoint,
        const ApiException('انتهت مهلة الاتصال. يتم عرض آخر بيانات محفوظة عند توافرها.'),
      );
    } catch (error) {
      final message = error is ApiException ? error.message : error.toString();
      if (_isQuotaError(message)) await _saveQuotaBlock(message);
      return _fallbackOrThrow(
        cached,
        endpoint,
        error is ApiException
            ? error
            : const ApiException('تعذر الاتصال بخدمة المباريات. تحقق من الإنترنت وحاول لاحقاً.'),
      );
    }
  }

  Map<String, dynamic> _extractErrorMessage(dynamic errors) {
    if (errors is Map && errors.isNotEmpty) {
      return {'message': errors.values.map((value) => value.toString()).join('، ')};
    }
    if (errors is List && errors.isNotEmpty) {
      return {'message': errors.map((value) => value.toString()).join('، ')};
    }
    return const <String, dynamic>{};
  }

  String _translateApiError(Map<String, dynamic> errors) {
    final message = errors['message']?.toString() ?? '';
    final lower = message.toLowerCase();
    if (lower.contains('page') && lower.contains('do not exist')) {
      return 'خطأ في معامل ترقيم النتائج من إصدار قديم. حدّث التطبيق ثم أعد المحاولة.';
    }
    if (_isQuotaError(message)) {
      return 'تم استهلاك حصة طلبات API-Football اليومية. ستظهر آخر بيانات محفوظة حتى تجدد الحصة.';
    }
    if (lower.contains('free plans do not have access') ||
        lower.contains('not available on the free plan')) {
      return 'الخطة الحالية لا تتيح هذا الموسم. راجع مواسم التغطية في لوحة API-Football.';
    }
    if (lower.contains('no data') || lower.contains('no results')) {
      return 'لا توجد بيانات متاحة لهذه البطولة والموسم.';
    }
    return message;
  }

  bool _isQuotaError(String message) {
    final lower = message.toLowerCase();
    return lower.contains('limit for the day') ||
        lower.contains('daily request limit') ||
        (lower.contains('request') && lower.contains('limit')) ||
        (lower.contains('حصة') && (lower.contains('اليومية') || lower.contains('طلبات'))) ||
        lower.contains('حد طلبات') || lower.contains('http 429');
  }

  Future<DateTime?> _readQuotaBlock() async {
    try {
      final millis = await _prefs.getInt(_quotaUntilKey);
      if (millis == null) return null;
      final until = DateTime.fromMillisecondsSinceEpoch(millis);
      if (!until.isAfter(DateTime.now())) {
        await _prefs.remove(_quotaUntilKey);
        return null;
      }
      return until;
    } catch (_) {
      return null;
    }
  }

  Future<void> _saveQuotaBlock(String message) async {
    try {
      final nowUtc = DateTime.now().toUtc();
      final lower = message.toLowerCase();
      final isDaily = lower.contains('for the day') ||
          lower.contains('daily') || lower.contains('حصة') || lower.contains('اليومية');
      final until = isDaily
          ? DateTime.utc(nowUtc.year, nowUtc.month, nowUtc.day + 1)
          : DateTime.now().add(const Duration(minutes: 1));
      await _prefs.setInt(_quotaUntilKey, until.millisecondsSinceEpoch);
    } catch (_) {
      // Cache fallback must remain available even if preferences cannot be written.
    }
  }

  bool _canUseStaleCache(_CachedResponse? cached, String endpoint, DateTime now) {
    if (cached == null) return false;
    final maxAge = _maxStaleAge(endpoint);
    return cached.savedAt.isAfter(now.subtract(maxAge));
  }

  Duration _maxStaleAge(String endpoint) {
    switch (endpoint) {
      case 'fixtures':
        return const Duration(days: 3);
      case 'leagues':
        return const Duration(days: 45);
      case 'standings':
      case 'players/topscorers':
      case 'players/topassists':
        return const Duration(days: 14);
      default:
        return const Duration(days: 7);
    }
  }

  Duration _cacheDuration(String endpoint, Map<String, String> params) {
    switch (endpoint) {
      case 'fixtures':
        if (params.containsKey('live')) return const Duration(minutes: 4, seconds: 30);
        final requestedDate = params['date'];
        final today = DateFormat('yyyy-MM-dd').format(_nowInAden());
        if (requestedDate == today) return const Duration(minutes: 4, seconds: 30);
        if (requestedDate != null && requestedDate.compareTo(today) < 0) {
          return const Duration(days: 1);
        }
        return const Duration(hours: 3);
      case 'leagues':
      case 'leagues/seasons':
        return const Duration(hours: 24);
      case 'fixtures/events':
      case 'fixtures/statistics':
      case 'fixtures/players':
        return const Duration(minutes: 2);
      case 'fixtures/lineups':
        return const Duration(minutes: 10);
      case 'fixtures/headtohead':
        return const Duration(days: 7);
      case 'standings':
        return const Duration(hours: 2);
      case 'players/topscorers':
      case 'players/topassists':
        return const Duration(hours: 2);
      case 'teams':
        return const Duration(days: 7);
      case 'players':
      case 'transfers':
        return const Duration(hours: 12);
      case 'status':
        return const Duration(minutes: 10);
      default:
        return const Duration(minutes: 30);
    }
  }

  String _persistentKey(String cacheKey) =>
      '$_cachePrefix${base64Url.encode(utf8.encode(cacheKey))}';

  Future<_CachedResponse?> _readPersistentCache(String cacheKey) async {
    try {
      final raw = await _prefs.getString(_persistentKey(cacheKey));
      if (raw == null || raw.isEmpty) return null;
      final decoded = jsonDecode(raw);
      if (decoded is! Map || decoded['value'] is! Map) return null;
      final savedAtMs = (decoded['savedAt'] as num?)?.toInt();
      final expiresAtMs = (decoded['expiresAt'] as num?)?.toInt();
      if (savedAtMs == null || expiresAtMs == null) return null;
      return _CachedResponse(
        value: Map<String, dynamic>.from(decoded['value'] as Map),
        savedAt: DateTime.fromMillisecondsSinceEpoch(savedAtMs),
        expiresAt: DateTime.fromMillisecondsSinceEpoch(expiresAtMs),
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> _storeResponse(
    String cacheKey,
    Map<String, dynamic> value,
    Duration ttl,
  ) async {
    if (ttl <= Duration.zero) return;
    final now = DateTime.now();
    final entry = _CachedResponse(
      value: value,
      savedAt: now,
      expiresAt: now.add(ttl),
    );
    _cache[cacheKey] = entry;

    try {
      final payload = jsonEncode({
        'savedAt': entry.savedAt.millisecondsSinceEpoch,
        'expiresAt': entry.expiresAt.millisecondsSinceEpoch,
        'value': value,
      });
      // Avoid a single oversized preference value on very large player responses.
      if (payload.length > _maxCacheJsonCharacters) return;
      final storageKey = _persistentKey(cacheKey);
      final write = _writeQueue.then((_) async {
        await _prefs.setString(storageKey, payload);
        final keys = await _prefs.getStringList(_cacheIndexKey) ?? <String>[];
        keys.remove(storageKey);
        keys.add(storageKey);
        while (keys.length > _maxPersistentEntries) {
          final oldest = keys.removeAt(0);
          await _prefs.remove(oldest);
        }
        await _prefs.setStringList(_cacheIndexKey, keys);
      });
      _writeQueue = write.catchError((Object _) {});
      await write;
    } catch (_) {
      // Keep the in-memory copy; persistence is best-effort.
    }
  }


  Future<Map<String, dynamic>> _fallbackOrThrow(
    _CachedResponse? cached,
    String endpoint,
    ApiException error,
  ) async {
    if (_canUseStaleCache(cached, endpoint, DateTime.now())) {
      _lastRequestUsedCache = true;
      _lastResponseWasStale = true;
      return cached!.value;
    }
    _lastRequestUsedCache = false;
    _lastResponseWasStale = false;
    throw error;
  }

  Future<List<dynamic>> fixtures({DateTime? date, bool live = false}) async {
    final requestedDate = date ?? _nowInAden();
    final params = <String, String>{'timezone': footballTimezone};
    if (live) {
      params['live'] = 'all';
    } else {
      params['date'] = DateFormat('yyyy-MM-dd').format(requestedDate);
    }
    // API-Football's fixtures endpoint returns this day's list in one response;
    // do not send an unsupported page parameter.
    final data = await get('fixtures', params);
    final rows = (data['response'] as List?) ?? const [];
    final filtered = rows
        .whereType<Map>()
        .map((row) => Map<String, dynamic>.from(row))
        .where(LeagueCatalog.isAllowedFixture)
        .toList();
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

  /// جميع سنوات المواسم التي يعرضها مزوّد API-Football على مستوى الخدمة.
  /// هذه القائمة لا تعني أن كل موسم متاح لكل بطولة أو لكل خطة اشتراك.
  Future<List<int>> availableSeasons() async {
    final data = await get('leagues/seasons');
    final rows = (data['response'] as List?) ?? const [];
    final years = <int>{};
    for (final row in rows) {
      final year = row is num ? row.toInt() : int.tryParse(row.toString());
      if (year != null && year >= 1900 && year <= ApiConfig.currentSeason + 2) {
        years.add(year);
      }
    }
    final result = years.toList()..sort((a, b) => b.compareTo(a));
    return result;
  }

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

  Future<void> clearCache() async {
    _cache.clear();
    try {
      await _writeQueue;
      final keys = await _prefs.getStringList(_cacheIndexKey) ?? <String>[];
      for (final key in keys) {
        await _prefs.remove(key);
      }
      await _prefs.remove(_cacheIndexKey);
      await _prefs.remove(_quotaUntilKey);
    } catch (_) {
      // Clearing local data is best-effort.
    }
  }
}

class _CachedResponse {
  const _CachedResponse({
    required this.value,
    required this.savedAt,
    required this.expiresAt,
  });
  final Map<String, dynamic> value;
  final DateTime savedAt;
  final DateTime expiresAt;
}

class ApiException implements Exception {
  final String message;
  const ApiException(this.message);
  @override
  String toString() => message;
}
