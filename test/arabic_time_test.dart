import 'package:flutter_test/flutter_test.dart';
import 'package:dfish_live/utils/arabic_time.dart';

void main() {
  test('converts API ISO time to Arabic 12-hour clock', () {
    expect(formatArabicTime('2026-11-24T21:00:00+03:00'), '9:00 م');
    expect(formatArabicTime('2026-11-24T09:30:00+03:00'), '9:30 ص');
  });

  test('handles midnight and noon', () {
    expect(formatArabicTime('00:15'), '12:15 ص');
    expect(formatArabicTime('12:00'), '12:00 م');
  });
}
