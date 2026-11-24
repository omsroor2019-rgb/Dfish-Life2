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
      expect(LeagueCatalog.isAllowed(row(country: 'Saudi Arabia', name: 'Pro League')), isTrue);
      expect(LeagueCatalog.isAllowed(row(country: 'Spain', name: 'La Liga')), isTrue);
      expect(LeagueCatalog.isAllowed(row(country: 'England', name: 'Premier League')), isTrue);
    });

    test('excludes cups, lower divisions and unrelated countries', () {
      expect(LeagueCatalog.isAllowed(row(country: 'Spain', name: 'Copa del Rey', type: 'Cup')), isFalse);
      expect(LeagueCatalog.isAllowed(row(country: 'Spain', name: 'Primera División RFEF - Group 3')), isFalse);
      expect(LeagueCatalog.isAllowed(row(country: 'Brazil', name: 'Serie A')), isFalse);
    });

    test('translates league and country names into Arabic', () {
      final spain = row(country: 'Spain', name: 'La Liga');
      expect(LeagueCatalog.displayName(spain), 'الدوري الإسباني');
      expect(LeagueCatalog.displayCountry(spain), 'إسبانيا');
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
