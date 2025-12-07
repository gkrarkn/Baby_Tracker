// lib/core/notification_service.dart
import 'package:flutter/material.dart'; // TimeOfDay için GEREKLİ
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  NotificationService._internal();
  static final NotificationService instance = NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

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

    // İzinler
    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();

    await _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  }

  /// Her gün aynı saatte “uyku kaydı” hatırlatması
  Future<void> scheduleDailySleepReminder(TimeOfDay time) async {
    final tz.TZDateTime scheduledDate = _nextInstanceOfTime(time);

    const androidDetails = AndroidNotificationDetails(
      'sleep_channel',
      'Uyku Hatırlatmaları',
      channelDescription: 'Bebek uykusu için günlük hatırlatmalar',
      importance: Importance.max,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails();

    await _plugin.zonedSchedule(
      0, // id
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
    await _plugin.cancel(0);
  }

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
