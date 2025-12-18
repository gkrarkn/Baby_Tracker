// lib/core/notification_service.dart
import 'package:flutter/material.dart'; // TimeOfDay
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  NotificationService._internal();
  static final NotificationService instance = NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  // Kanal ID'leri
  static const String _sleepChannelId = 'sleep_channel';
  static const String _notesChannelId = 'notes_channel';

  // Sleep reminder sabit id (tek hatırlatma)
  static const int _sleepNotifId = 0;

  Future<void> init() async {
    // Timezone setup
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Europe/Istanbul'));

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();

    const initSettings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    );

    await _plugin.initialize(initSettings);

    // Android 13+ notification izinleri
    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();

    // iOS izinleri
    await _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  }

  // ---------------------------
  // NOTES: Tek seferlik hatırlatma
  // ---------------------------
  Future<void> scheduleNoteReminder({
    required String noteId,
    required String title,
    required String body,
    required DateTime when,
  }) async {
    final int id = _noteIdToInt(noteId);

    // Geçmişe/çok yakına schedule etme (iOS/Android'de saçma davranabiliyor)
    final now = DateTime.now();
    if (!when.isAfter(now.add(const Duration(seconds: 5)))) {
      await _plugin.cancel(id);
      return;
    }

    const androidDetails = AndroidNotificationDetails(
      _notesChannelId,
      'Not Hatırlatmaları',
      channelDescription: 'Notlar için tek seferlik hatırlatmalar',
      importance: Importance.max,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails();

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(when, tz.local),
      const NotificationDetails(android: androidDetails, iOS: iosDetails),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      // Tek seferlik -> matchDateTimeComponents YOK
    );
  }

  Future<void> cancelNoteReminder(String noteId) async {
    final int id = _noteIdToInt(noteId);
    await _plugin.cancel(id);
  }

  // ---------------------------
  // SLEEP: Günlük hatırlatma
  // ---------------------------
  Future<void> scheduleDailySleepReminder(TimeOfDay time) async {
    final tz.TZDateTime scheduledDate = _nextInstanceOfTime(time);

    const androidDetails = AndroidNotificationDetails(
      _sleepChannelId,
      'Uyku Hatırlatmaları',
      channelDescription: 'Bebek uykusu için günlük hatırlatmalar',
      importance: Importance.max,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails();

    await _plugin.zonedSchedule(
      _sleepNotifId,
      'Uyku zamanı',
      'Bebeğin uyku kaydını eklemeyi unutma 💛',
      scheduledDate,
      const NotificationDetails(android: androidDetails, iOS: iosDetails),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time, // her gün aynı saat
    );
  }

  Future<void> cancelSleepReminder() async {
    await _plugin.cancel(_sleepNotifId);
  }

  // ---------------------------
  // Helpers
  // ---------------------------
  int _noteIdToInt(String noteId) => noteId.hashCode & 0x7fffffff;

  tz.TZDateTime _nextInstanceOfTime(TimeOfDay time) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      now.location,
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );

    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }
}
