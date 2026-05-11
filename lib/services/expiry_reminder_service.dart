import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../models/product.dart';
import 'reminder_preferences.dart';

/// Notifications locales le jour de la péremption, à l’heure choisie dans les paramètres.
class ExpiryReminderService {
  ExpiryReminderService._();
  static final ExpiryReminderService instance = ExpiryReminderService._();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  static int notificationIdForProduct(String productId) =>
      productId.hashCode & 0x7fffffff;

  Future<void> init() async {
    if (kIsWeb || _initialized) return;

    tzdata.initializeTimeZones();
    try {
      final info = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(info.identifier));
    } on Object {
      tz.setLocalLocation(tz.UTC);
    }

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinInit = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    await _plugin.initialize(
      settings: const InitializationSettings(
        android: androidInit,
        iOS: darwinInit,
        macOS: darwinInit,
      ),
    );

    const channel = AndroidNotificationChannel(
      'perimax_expiry',
      'Dates de péremption',
      description: 'Rappel le jour où un produit atteint sa date de péremption',
      importance: Importance.high,
    );
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    _initialized = true;
  }

  Future<bool> requestNotificationPermission() async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      final granted = await android?.requestNotificationsPermission();
      return granted ?? false;
    }
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      final ios = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      final ok = await ios?.requestPermissions(alert: true, badge: true, sound: true);
      return ok ?? false;
    }
    return true;
  }

  Future<void> scheduleProductIfEnabled({
    required String productId,
    required String productName,
    required DateTime expirationDate,
  }) async {
    if (kIsWeb || !_initialized) return;
    final prefs = await ReminderPreferences.load();
    if (!prefs.enabled) return;
    await _scheduleOne(
      productId: productId,
      productName: productName,
      expirationDate: expirationDate,
      hour: prefs.hour,
      minute: prefs.minute,
    );
  }

  Future<void> rescheduleAllProducts(List<Product> products) async {
    if (kIsWeb || !_initialized) return;
    final prefs = await ReminderPreferences.load();
    await _plugin.cancelAll();
    if (!prefs.enabled) return;
    for (final p in products) {
      await _scheduleOne(
        productId: p.id,
        productName: p.name,
        expirationDate: p.expirationDate,
        hour: prefs.hour,
        minute: prefs.minute,
      );
    }
  }

  Future<void> cancelAll() async {
    if (kIsWeb || !_initialized) return;
    await _plugin.cancelAll();
  }

  Future<void> _scheduleOne({
    required String productId,
    required String productName,
    required DateTime expirationDate,
    required int hour,
    required int minute,
  }) async {
    final when = tz.TZDateTime(
      tz.local,
      expirationDate.year,
      expirationDate.month,
      expirationDate.day,
      hour,
      minute,
    );
    if (!when.isAfter(tz.TZDateTime.now(tz.local))) {
      return;
    }

    const androidDetails = AndroidNotificationDetails(
      'perimax_expiry',
      'Dates de péremption',
      channelDescription: 'Rappel le jour de la péremption',
      importance: Importance.high,
      priority: Priority.high,
    );
    const darwinDetails = DarwinNotificationDetails();
    const details = NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
      macOS: darwinDetails,
    );

    final id = notificationIdForProduct(productId);

    await _plugin.zonedSchedule(
      id: id,
      title: 'Péremption : $productName',
      body: '« $productName » est à consommer aujourd’hui.',
      scheduledDate: when,
      notificationDetails: details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: productId,
    );
  }
}
