import 'package:flutter_test/flutter_test.dart';
import 'package:dfish_live/config/league_catalog.dart';

Map<String, dynamic> row({
  required String country,
  required String name,
  String type = 'League',
}) => {
  'country': {'name': country},
  'league': {'name': name, 'type': type, 'id': 1},
  'seasons': [
    {
      'year': 2024,
      'coverage': {
        'standings': true,
        'top_scorers': true,
        'top_assists': true,
      },
    }
  ],
};

void main() {
  group('LeagueCatalog', () {
    test('keeps Gulf, Yemen and European top divisions', () {
      expect(LeagueCatalog.isAllowed(row(country: 'Yemen', name: 'Yemeni League')), isTrue);
      expect(LeagueCatalog.isAllowedFixture({'league': {'country': 'Yemen', 'name': 'Yemeni League'}}), isTrue);
      expect(LeagueCatalog.isAllowed(row(country: 'Saudi Arabia', name: 'Pro League')), isTrue);
      expect(LeagueCatalog.isAllowed(row(country: 'Saudi-Arabia', name: 'Pro League')), isTrue);
      expect(LeagueCatalog.isAllowed(row(country: 'United-Arab-Emirates', name: 'Pro League')), isTrue);
      expect(LeagueCatalog.isAllowedFixture({'league': {'country': 'Saudi-Arabia', 'name': 'Pro League'}}), isTrue);
      expect(LeagueCatalog.isAllowed(row(country: 'Spain', name: 'La Liga')), isTrue);
      expect(LeagueCatalog.isAllowed(row(country: 'England', name: 'Premier League')), isTrue);
      expect(LeagueCatalog.isAllowed(row(country: 'Japan', name: 'J1 League')), isTrue);
      expect(LeagueCatalog.isAllowed(row(country: 'South-Korea', name: 'K League 1')), isTrue);
      expect(LeagueCatalog.isAllowed(row(country: 'China', name: 'Super League')), isTrue);
      expect(LeagueCatalog.isAllowed(row(country: 'Brazil', name: 'Serie A')), isTrue);
      expect(LeagueCatalog.isAllowed(row(country: 'Argentina', name: 'Liga Profesional Argentina')), isTrue);
      expect(LeagueCatalog.isAllowed(row(country: 'Mexico', name: 'Liga MX')), isTrue);
      expect(LeagueCatalog.isAllowed(row(country: 'Egypt', name: 'Premier League')), isTrue);
    });

    test('includes only the requested continental cups', () {
      expect(LeagueCatalog.isAllowed(row(country: 'World', name: 'UEFA Champions League', type: 'Cup')), isTrue);
      expect(LeagueCatalog.isAllowed(row(country: 'World', name: 'AFC Champions League Elite', type: 'Cup')), isTrue);
      expect(LeagueCatalog.isAllowed(row(country: 'World', name: 'AFC Champions League Two', type: 'Cup')), isTrue);
      expect(LeagueCatalog.isAllowed(row(country: 'World', name: 'UEFA Europa League', type: 'Cup')), isTrue);
      expect(LeagueCatalog.isAllowedFixture({'league': {'country': 'World', 'name': 'UEFA Champions League'}}), isTrue);
      expect(LeagueCatalog.isAllowed(row(country: 'World', name: 'FIFA World Cup', type: 'Cup')), isTrue);
      expect(LeagueCatalog.isAllowed(row(country: 'World', name: 'Copa Libertadores', type: 'Cup')), isTrue);
    });

    test('excludes other cups, lower divisions and unrelated countries', () {
      expect(LeagueCatalog.isAllowed(row(country: 'Spain', name: 'Copa del Rey', type: 'Cup')), isFalse);
      expect(LeagueCatalog.isAllowed(row(country: 'Spain', name: 'Primera División RFEF - Group 3')), isFalse);
      expect(LeagueCatalog.isAllowed(row(country: 'Brazil', name: 'Serie B')), isFalse);
    });

    test('translates league and country names into Arabic', () {
      final spain = row(country: 'Spain', name: 'La Liga');
      expect(LeagueCatalog.displayName(spain), 'الدوري الإسباني');
      expect(LeagueCatalog.displayCountry(spain), 'إسبانيا');
      expect(LeagueCatalog.displayCountry(row(country: 'Saudi-Arabia', name: 'Pro League')), 'السعودية');
      expect(LeagueCatalog.displayNameFor('Saudi-Arabia', 'Pro League'), 'دوري روشن السعودي');
    });

    test('prioritizes live games and major competitions', () {
      final liveJapanese = {
        'fixture': {'status': {'short': '2H'}},
        'league': {'country': 'Japan', 'name': 'J1 League'},
      };
      final upcomingChampionsLeague = {
        'fixture': {'status': {'short': 'NS'}},
        'league': {'country': 'World', 'name': 'UEFA Champions League'},
      };
      final upcomingPremierLeague = {
        'fixture': {'status': {'short': 'NS'}},
        'league': {'country': 'England', 'name': 'Premier League'},
      };
      expect(LeagueCatalog.fixtureStatusPriority(liveJapanese), 0);
      expect(LeagueCatalog.fixtureStatusPriority(upcomingPremierLeague), 1);
      expect(LeagueCatalog.fixturePriority(upcomingChampionsLeague),
          lessThan(LeagueCatalog.fixturePriority(upcomingPremierLeague)));
      expect(LeagueCatalog.fixturePriority(upcomingPremierLeague),
          lessThan(LeagueCatalog.fixturePriority(liveJapanese)));
      expect(LeagueCatalog.compareFixtures(
          upcomingChampionsLeague, upcomingPremierLeague), lessThan(0));
      expect(LeagueCatalog.compareFixtures(
          upcomingPremierLeague, liveJapanese), lessThan(0));
    });

    test('labels continental competition regions correctly', () {
      expect(LeagueCatalog.displayCompetitionCountry('World', 'UEFA Champions League'), 'أوروبا');
      expect(LeagueCatalog.displayCompetitionCountry('World', 'AFC Champions League Elite'), 'آسيا');
      expect(LeagueCatalog.displayCompetitionCountry('World', 'CAF Champions League'), 'أفريقيا');
      expect(LeagueCatalog.displayCompetitionCountry('World', 'Copa Libertadores'), 'أمريكا الجنوبية');
      expect(LeagueCatalog.displayCompetitionCountry('World', 'FIFA World Cup'), 'دولي');
    });

    test('checks separate data coverage flags', () {
      final Map<String, dynamic> unsupported = {
        'country': {'name': 'Spain'},
        'league': {'name': 'La Liga', 'type': 'League'},
        'seasons': [
          {'year': 2024, 'coverage': {'standings': true, 'top_scorers': true, 'top_assists': false}}
        ],
      };
      expect(LeagueCatalog.supports(unsupported, 2024, 'standings'), isTrue);
      expect(LeagueCatalog.supports(unsupported, 2024, 'top_assists'), isFalse);
    });
  });
}
