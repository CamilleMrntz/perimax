import 'package:shared_preferences/shared_preferences.dart';

/// Préférences locales : rappel le jour de la péremption à une heure fixe.
class ReminderPreferences {
  ReminderPreferences({
    required this.enabled,
    required this.hour,
    required this.minute,
  });

  final bool enabled;
  final int hour;
  final int minute;

  static const _kEnabled = 'reminder_enabled';
  static const _kHour = 'reminder_hour';
  static const _kMinute = 'reminder_minute';

  static Future<ReminderPreferences> load() async {
    final p = await SharedPreferences.getInstance();
    return ReminderPreferences(
      enabled: p.getBool(_kEnabled) ?? false,
      hour: p.getInt(_kHour) ?? 9,
      minute: p.getInt(_kMinute) ?? 0,
    );
  }

  static Future<void> save({
    required bool enabled,
    required int hour,
    required int minute,
  }) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_kEnabled, enabled);
    await p.setInt(_kHour, hour);
    await p.setInt(_kMinute, minute);
  }
}
