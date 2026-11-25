import 'package:flutter_test/flutter_test.dart';
import 'package:dfish_live/services/highlightly_api.dart';
import 'package:dfish_live/utils/arabic_football.dart';

void main() {
  group('Arabic football labels', () {
    test('translates league, team, event, statistic and position labels', () {
      expect(ArabicFootball.league('Premier League', 'England'), 'الدوري الإنجليزي الممتاز');
      expect(ArabicFootball.team('Manchester City'), 'مانشستر سيتي');
      expect(ArabicFootball.text('Yellow Card'), 'بطاقة صفراء');
      expect(ArabicFootball.text('Shots On Target'), 'تسديدات على المرمى');
      expect(ArabicFootball.text('Goalkeeper'), 'حارس مرمى');
    });

    test('keeps unknown proper names rather than inventing translations', () {
      expect(ArabicFootball.team('Unknown FC'), 'Unknown FC');
    });
  });

  group('Highlightly response normalization', () {
    test('reads paginated data arrays', () {
      final rows = HighlightlyApi.asList({
        'data': [{'id': 1, 'name': 'Premier League'}],
        'pagination': {'totalCount': 1},
      });
      expect(rows, hasLength(1));
      expect(rows.first['id'], 1);
    });

    test('reads direct lists and direct objects', () {
      expect(HighlightlyApi.asList([{'id': 7}]).first['id'], 7);
      expect(HighlightlyApi.asObject({'homeTeam': {}, 'awayTeam': {}}), isNotNull);
      expect(HighlightlyApi.asObject([{'id': 9}])?['id'], 9);
    });

    test('normalizes accents and club suffixes for safe fixture matching', () {
      expect(HighlightlyApi.normalizeTeamName('Atlético Madrid FC'), 'atletico madrid');
    });
  });
}
