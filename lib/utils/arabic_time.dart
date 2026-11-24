/// Converts API / admin 24-hour clocks into a consistent Arabic 12-hour label.
/// Accepts either an ISO timestamp or HH:mm and preserves the time already
/// converted by the API using timezone=Asia/Aden.
String formatArabicTime(String input) {
  final value = input.trim();
  if (value.isEmpty) return 'قريباً';

  String clock = value;
  if (value.length >= 16 && value[10] == 'T') {
    clock = value.substring(11, 16);
  }
  final match = RegExp(r'^(\d{1,2}):(\d{2})$').firstMatch(clock);
  if (match == null) return value;

  final hour = int.tryParse(match.group(1)!) ?? -1;
  final minute = int.tryParse(match.group(2)!) ?? -1;
  if (hour < 0 || hour > 23 || minute < 0 || minute > 59) return value;

  final hour12 = hour % 12 == 0 ? 12 : hour % 12;
  final suffix = hour < 12 ? 'ص' : 'م';
  return '$hour12:${minute.toString().padLeft(2, '0')} $suffix';
}
