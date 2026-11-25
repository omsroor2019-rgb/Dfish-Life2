import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/api_config.dart';

/// Optional Highlightly client. API-Football remains the primary source unless
/// a Highlightly key is configured and a corresponding match can be resolved.
class HighlightlyApi {
  HighlightlyApi._();
  static final HighlightlyApi instance = HighlightlyApi._();

  static const String baseUrl = 'https://soccer.highlightly.net';
  static const String _cachePrefix = 'dfish_highlightly_cache_v1_';
  static const String _cacheIndexKey = 'dfish_highlightly_cache_index_v1';
  static const int _maxPersistentEntries = 80;
  static const Duration _timeout = Duration(seconds: 18);

  final http.Client _client = http.Client();
  final SharedPreferencesAsync _prefs = SharedPreferencesAsync();
  final Map<String, _HighlightlyCache> _memory = {};
  final Map<String, Future<dynamic>> _inFlight = {};

  bool get isConfigured => ApiConfig.isHighlightlyConfigured;

  Future<dynamic> get(
    String path, [
    Map<String, String>? parameters,
  ]) async {
    if (!isConfigured) {
      throw const HighlightlyException(
        'خدمة Highlightly غير مفعّلة. أضف HIGHLIGHTLY_API_KEY إلى GitHub Secrets ثم أعد بناء التطبيق.',
      );
    }

    final uri = Uri.parse('$baseUrl/$path').replace(
      queryParameters: parameters == null || parameters.isEmpty
          ? null
          : Map<String, String>.fromEntries(
              parameters.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
            ),
    );
    final cacheKey = uri.toString();
    final running = _inFlight[cacheKey];
    if (running != null) return running;

    final pending = _getCached(uri, path, cacheKey);
    _inFlight[cacheKey] = pending;
    try {
      return await pending;
    } finally {
      if (identical(_inFlight[cacheKey], pending)) {
        _inFlight.remove(cacheKey);
      }
    }
  }

  Future<dynamic> _getCached(Uri uri, String path, String key) async {
    final duration = _ttl(path);
    final now = DateTime.now();
    var cached = _memory[key];
    if (cached == null) {
      try {
        final encodedKey = base64Url.encode(utf8.encode(key)).replaceAll('=', '');
        final raw = await _prefs.getString('$_cachePrefix$encodedKey');
        if (raw != null) {
          final decoded = jsonDecode(raw);
          if (decoded is Map && decoded['savedAt'] is int && decoded.containsKey('data')) {
            cached = _HighlightlyCache(
              data: decoded['data'],
              savedAt: DateTime.fromMillisecondsSinceEpoch(decoded['savedAt'] as int),
            );
            _memory[key] = cached;
          }
        }
      } catch (_) {
        cached = null;
      }
    }
    if (cached != null && cached.savedAt.add(duration).isAfter(now)) {
      return cached.data;
    }

    try {
      final response = await _client.get(
        uri,
        headers: {'x-rapidapi-key': ApiConfig.highlightlyApiKey.trim()},
      ).timeout(_timeout);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        final detail = _readError(response.body);
        if (response.statusCode == 401 || response.statusCode == 403) {
          throw const HighlightlyException('رفض Highlightly الطلب. تحقق من المفتاح واشتراك Football API.');
        }
        if (response.statusCode == 429) {
          throw const HighlightlyException('وصلت إلى حد طلبات Highlightly اليومي. ستُستخدم البيانات المحفوظة إن توفرت.');
        }
        throw HighlightlyException(detail.isEmpty
            ? 'تعذر جلب بيانات Highlightly (HTTP ${response.statusCode}).'
            : 'تعذر جلب البيانات: $detail');
      }

      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      final fresh = _HighlightlyCache(data: decoded, savedAt: DateTime.now());
      _memory[key] = fresh;
      try {
        final encodedKey = base64Url.encode(utf8.encode(key)).replaceAll('=', '');
        await _prefs.setString('$_cachePrefix$encodedKey', jsonEncode({
          'savedAt': fresh.savedAt.millisecondsSinceEpoch,
          'data': decoded,
        }));
        final index = await _prefs.getStringList(_cacheIndexKey) ?? <String>[];
        index.remove(encodedKey);
        index.add(encodedKey);
        while (index.length > _maxPersistentEntries) {
          final removed = index.removeAt(0);
          await _prefs.remove('$_cachePrefix$removed');
        }
        await _prefs.setStringList(_cacheIndexKey, index);
      } catch (_) {
        // The in-memory cache still protects the current session.
      }
      return decoded;
    } on TimeoutException {
      if (cached != null && cached.savedAt.isAfter(now.subtract(_staleTtl(path)))) {
        return cached.data;
      }
      throw const HighlightlyException('انتهت مهلة الاتصال بـ Highlightly. حاول مرة أخرى.');
    } on HighlightlyException {
      if (cached != null && cached.savedAt.isAfter(now.subtract(_staleTtl(path)))) {
        return cached.data;
      }
      rethrow;
    } catch (_) {
      if (cached != null && cached.savedAt.isAfter(now.subtract(_staleTtl(path)))) {
        return cached.data;
      }
      throw const HighlightlyException('تعذر الاتصال بخدمة Highlightly. تحقق من الإنترنت ومفتاح الخدمة.');
    }
  }

  String _readError(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map) {
        return (decoded['message'] ?? decoded['error'] ?? decoded['detail'] ?? '').toString();
      }
    } catch (_) {}
    return '';
  }

  Duration _ttl(String path) {
    if (path == 'matches') return const Duration(hours: 12);
    if (path.startsWith('events/')) return const Duration(minutes: 1);
    if (path.startsWith('statistics/') || path.startsWith('box-score/')) return const Duration(minutes: 5);
    if (path.startsWith('lineups/')) return const Duration(minutes: 15);
    if (path == 'standings') return const Duration(minutes: 60);
    if (path.startsWith('players/')) return const Duration(hours: 24);
    if (path == 'leagues' || path.startsWith('leagues/')) return const Duration(hours: 12);
    return const Duration(minutes: 10);
  }

  Duration _staleTtl(String path) {
    if (path.startsWith('events/')) return const Duration(hours: 2);
    if (path.startsWith('statistics/') || path.startsWith('box-score/')) return const Duration(days: 1);
    if (path.startsWith('lineups/')) return const Duration(days: 2);
    if (path == 'standings') return const Duration(days: 7);
    if (path == 'matches') return const Duration(days: 2);
    return const Duration(days: 14);
  }

  static List<Map<String, dynamic>> asList(dynamic value) {
    dynamic source = value;
    if (source is Map && source['data'] is List) source = source['data'];
    if (source is Map && source['response'] is List) source = source['response'];
    if (source is! List) return const [];
    return source.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
  }

  static Map<String, dynamic>? asObject(dynamic value) {
    if (value is Map) {
      if (value['data'] is Map) return Map<String, dynamic>.from(value['data'] as Map);
      if (value['response'] is List && (value['response'] as List).isNotEmpty) {
        final first = (value['response'] as List).first;
        if (first is Map) return Map<String, dynamic>.from(first);
      }
      return Map<String, dynamic>.from(value);
    }
    if (value is List && value.isNotEmpty && value.first is Map) {
      return Map<String, dynamic>.from(value.first as Map);
    }
    return null;
  }

  /// Resolve an API-Football fixture to Highlightly's independent match ID.
  /// IDs from the two providers are never assumed to be interchangeable.
  Future<Map<String, dynamic>?> resolveMatch({
    required String kickoff,
    required String homeTeam,
    required String awayTeam,
  }) async {
    final parsed = DateTime.tryParse(kickoff);
    if (parsed == null || homeTeam.trim().isEmpty || awayTeam.trim().isEmpty) return null;
    final local = parsed.toUtc().add(const Duration(hours: 3));
    final date = DateFormat('yyyy-MM-dd').format(local);
    final raw = await get('matches', {
      'date': date,
      'timezone': 'Asia/Aden',
      'limit': '100',
      'offset': '0',
    });
    final candidates = asList(raw);
    if (candidates.isEmpty) return null;

    final wantedHome = normalizeTeamName(homeTeam);
    final wantedAway = normalizeTeamName(awayTeam);
    Map<String, dynamic>? best;
    var bestScore = -1;
    for (final candidate in candidates) {
      final home = candidate['homeTeam'];
      final away = candidate['awayTeam'];
      if (home is! Map || away is! Map) continue;
      final actualHome = normalizeTeamName(home['name']?.toString() ?? '');
      final actualAway = normalizeTeamName(away['name']?.toString() ?? '');
      final straight = _nameMatches(wantedHome, actualHome) && _nameMatches(wantedAway, actualAway);
      final reversed = _nameMatches(wantedHome, actualAway) && _nameMatches(wantedAway, actualHome);
      if (!straight && !reversed) continue;
      final candidateDate = DateTime.tryParse(candidate['date']?.toString() ?? '');
      final timeDifference = candidateDate == null
          ? 0
          : candidateDate.difference(parsed.toUtc()).inMinutes.abs();
      if (timeDifference > 12 * 60) continue;
      final score = (straight ? 100 : 80) - (timeDifference ~/ 30);
      if (score > bestScore) {
        best = candidate;
        bestScore = score;
      }
    }
    return best;
  }

  static String normalizeTeamName(String value) {
    var result = value.toLowerCase().trim();
    const accents = {
      'á': 'a', 'à': 'a', 'ä': 'a', 'â': 'a', 'ã': 'a', 'å': 'a',
      'é': 'e', 'è': 'e', 'ë': 'e', 'ê': 'e',
      'í': 'i', 'ì': 'i', 'ï': 'i', 'î': 'i',
      'ó': 'o', 'ò': 'o', 'ö': 'o', 'ô': 'o', 'õ': 'o',
      'ú': 'u', 'ù': 'u', 'ü': 'u', 'û': 'u', 'ñ': 'n', 'ç': 'c',
    };
    accents.forEach((from, to) => result = result.replaceAll(from, to));
    result = result.replaceAll(RegExp(r'\b(fc|cf|afc|sc|ac|club|football|team)\b', caseSensitive: false), ' ');
    result = result.replaceAll(RegExp(r'[^a-z0-9]+'), ' ').replaceAll(RegExp(r'\s+'), ' ').trim();
    if (result == 'man city') result = 'manchester city';
    if (result == 'man utd' || result == 'man united' || result == 'manchester utd') result = 'manchester united';
    if (result == 'psg' || result == 'paris sg') result = 'paris saint germain';
    if (result == 'atletico de madrid') result = 'atletico madrid';
    if (result == 'internazionale') result = 'inter milan';
    return result;
  }

  static bool _nameMatches(String a, String b) {
    // Strict matching is intentional: a false match would display another
    // fixture's lineups/events. If provider names differ, retain API-Football.
    return a.isNotEmpty && b.isNotEmpty && a == b;
  }

  Future<dynamic> matchDetails(int matchId) => get('matches/$matchId');
  Future<dynamic> liveEvents(int matchId) => get('events/$matchId');
  Future<dynamic> matchStatistics(int matchId) => get('statistics/$matchId');
  Future<dynamic> lineups(int matchId) => get('lineups/$matchId');
  Future<dynamic> boxScore(int matchId) => get('box-score/$matchId');
  Future<dynamic> playerDetails(int playerId) => get('players/$playerId');
  Future<dynamic> playerStatistics(int playerId) => get('players/$playerId/statistics');

  Future<List<Map<String, dynamic>>> leagues({int limit = 100, int offset = 0}) async {
    final raw = await get('leagues', {'limit': '$limit', 'offset': '$offset'});
    return asList(raw);
  }

  /// Load the league catalog in documented 100-row pages. Results are cached
  /// per page for 12 hours, so the free daily quota is not repeatedly spent.
  Future<List<Map<String, dynamic>>> allLeagues() async {
    const pageSize = 100;
    const maxItems = 1000;
    final result = <Map<String, dynamic>>[];
    var offset = 0;
    var total = maxItems;
    while (offset < total && offset < maxItems) {
      final raw = await get('leagues', {'limit': '$pageSize', 'offset': '$offset'});
      final page = asList(raw);
      if (raw is Map && raw['pagination'] is Map) {
        final count = (raw['pagination']['totalCount'] as num?)?.toInt();
        if (count != null && count >= 0) total = count;
      }
      result.addAll(page);
      if (page.isEmpty) break;
      final pageOffset = raw is Map && raw['pagination'] is Map
          ? ((raw['pagination']['offset'] as num?)?.toInt() ?? offset)
          : offset;
      final actualLimit = raw is Map && raw['pagination'] is Map
          ? ((raw['pagination']['limit'] as num?)?.toInt() ?? pageSize)
          : pageSize;
      offset = pageOffset + actualLimit;
    }
    return result;
  }

  Future<List<Map<String, dynamic>>> standings(int leagueId, int season) async {
    final raw = await get('standings', {'leagueId': '$leagueId', 'season': '$season'});
    final object = asObject(raw);
    final groups = object?['groups'];
    if (groups is! List) return const [];
    return groups.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
  }

  void clearMemoryCache() => _memory.clear();
}

class _HighlightlyCache {
  const _HighlightlyCache({required this.data, required this.savedAt});
  final dynamic data;
  final DateTime savedAt;
}

class HighlightlyException implements Exception {
  const HighlightlyException(this.message);
  final String message;
  @override
  String toString() => message;
}
