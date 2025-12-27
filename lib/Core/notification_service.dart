// lib/core/notification_service.dart
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// Tek sorumluluk: Local notification init + schedule + cancel.
/// Uygulama genelinde tek instance kullan.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const String _channelId = 'baby_tracker_reminders';
  static const String _channelName = 'Reminders';
  static const String _channelDesc = 'Baby Tracker reminder notifications';

  // --- ID PLANLAMASI ---
  // Note: noteId bazlı
  // Vaccine: vaccineId bazlı + offset
  // Attack: sabit blok + gün index
  // Feeding: tek sabit
  //
  // Çakışmayı engellemek için geniş aralıklar:
  static const int _baseNote = 10_000;
  static const int _baseVaccine = 20_000;
  static const int _baseAttack = 30_000;
  static const int _feedingId = 40_000;

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;

    tz.initializeTimeZones();

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const settings = InitializationSettings(android: android, iOS: ios);

    await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: (resp) {
        // İleride: payload ile ilgili sayfaya yönlendirme yapılabilir.
        // Şimdilik no-op.
      },
    );

    // Android channel
    const channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDesc,
      importance: Importance.high,
    );

    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);

    _initialized = true;
  }

  Future<void> requestPermissionsIfNeeded() async {
    // iOS/macOS
    await _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);

    await _plugin
        .resolvePlatformSpecificImplementation<
          MacOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);

    // Android 13+ runtime permission
    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
  }

  NotificationDetails _details() {
    const android = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDesc,
      importance: Importance.high,
      priority: Priority.high,
    );
    const ios = DarwinNotificationDetails();
    return const NotificationDetails(android: android, iOS: ios);
  }

  tz.TZDateTime _toTz(DateTime dt) => tz.TZDateTime.from(dt, tz.local);

  DateTime _combineDateTime(DateTime date, TimeOfDay time) {
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  /// Geçmişteyse bir sonraki güne atar (daily / future schedule için).
  DateTime _ensureFuture(DateTime dt) {
    final now = DateTime.now();
    if (dt.isAfter(now)) return dt;
    return dt.add(const Duration(days: 1));
  }

  // ---------------------------------------------------------------------------
  // NOTE REMINDER (event-driven)
  // ---------------------------------------------------------------------------

  /// noteId: uygulamadaki notun id’si (int olması ideal).
  Future<void> scheduleNoteReminder({
    required int noteId,
    required String title,
    required String body,
    required DateTime scheduledAt,
  }) async {
    await init();

    // Minimal hardening: geçmişteki not schedule edilmez.
    final now = DateTime.now();
    if (!scheduledAt.isAfter(now)) return;

    final id = _baseNote + noteId;

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      _toTz(scheduledAt),
      _details(),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: null,
      payload: 'note:$noteId',
    );
  }

  Future<void> cancelNoteReminder(int noteId) async {
    await init();
    await _plugin.cancel(_baseNote + noteId);
  }

  // ---------------------------------------------------------------------------
  // VACCINE REMINDERS (schedule-based + kullanıcı ayarı)
  // ---------------------------------------------------------------------------

  /// Varsayılan hatırlatma mantığı:
  /// - dueDate - 7 gün (optional)
  /// - dueDate - 1 gün (optional)
  /// Saat: kullanıcı seçer (TimeOfDay).
  ///
  /// vaccineId benzersiz olmalı.
  Future<void> scheduleVaccineReminders({
    required int vaccineId,
    required String vaccineName,
    required DateTime dueDate,
    required TimeOfDay remindTime,
    bool remind7DaysBefore = true,
    bool remind1DayBefore = true,
  }) async {
    await init();

    // Önce eski aşı bildirimlerini temizle (id aralığı: vaccineId * 10 + x)
    await cancelVaccineReminders(vaccineId);

    final now = DateTime.now();

    if (remind7DaysBefore) {
      final dt = _combineDateTime(
        dueDate.subtract(const Duration(days: 7)),
        remindTime,
      );
      if (dt.isAfter(now)) {
        await _scheduleOneTime(
          id: _vaccineOffsetId(vaccineId, 7),
          title: 'Yaklaşan aşı',
          body: '$vaccineName — 7 gün kaldı',
          when: dt,
          payload: 'vaccine:$vaccineId:7',
        );
      }
    }

    if (remind1DayBefore) {
      final dt = _combineDateTime(
        dueDate.subtract(const Duration(days: 1)),
        remindTime,
      );
      if (dt.isAfter(now)) {
        await _scheduleOneTime(
          id: _vaccineOffsetId(vaccineId, 1),
          title: 'Yaklaşan aşı',
          body: '$vaccineName — yarın',
          when: dt,
          payload: 'vaccine:$vaccineId:1',
        );
      }
    }
  }

  int _vaccineOffsetId(int vaccineId, int offsetDays) {
    // offsetDays: 7 veya 1
    // 20_000 + vaccineId*10 + (7/1)
    return _baseVaccine + (vaccineId * 10) + offsetDays;
  }

  Future<void> cancelVaccineReminders(int vaccineId) async {
    await init();
    await _plugin.cancel(_vaccineOffsetId(vaccineId, 7));
    await _plugin.cancel(_vaccineOffsetId(vaccineId, 1));
  }

  // ---------------------------------------------------------------------------
  // ATTACK WEEK (recurring + kullanıcı ayarı)
  // ---------------------------------------------------------------------------

  /// Haftaya giriş bildirimi + opsiyonel günlük kısa hatırlatma.
  /// nextAttackWeekStart: atak haftasının başladığı gün (00:00 gibi gelebilir)
  /// notifyDaily: true ise start gününden itibaren N gün günlük atar.
  ///
  /// Not: Bu yaklaşım “tek schedule + matchDateTimeComponents” yerine
  /// “tarih aralığına tek tek schedule” (daha kontrollü, release öncesi güvenli).
  Future<void> scheduleAttackWeek({
    required DateTime nextAttackWeekStart,
    required TimeOfDay time,
    bool notifyOnStart = true,
    bool notifyDaily = false,
    int days = 7,
  }) async {
    await init();

    await cancelAttackWeek(); // tek blok yaklaşımı

    final now = DateTime.now();

    if (notifyOnStart) {
      final startDt = _combineDateTime(nextAttackWeekStart, time);
      if (startDt.isAfter(now)) {
        await _scheduleOneTime(
          id: _baseAttack,
          title: 'Atak haftası başladı',
          body: 'Bugün itibarıyla atak haftasına girdiniz.',
          when: startDt,
          payload: 'attack:start',
        );
      }
    }

    if (notifyDaily) {
      for (int i = 0; i < days; i++) {
        final day = nextAttackWeekStart.add(Duration(days: i));
        final dt = _combineDateTime(day, time);
        if (dt.isAfter(now)) {
          await _scheduleOneTime(
            id: _baseAttack + 1 + i, // 30_001..30_007
            title: 'Atak haftası',
            body: 'Kısa hatırlatma: Bugün atak haftası günü (${i + 1}/$days).',
            when: dt,
            payload: 'attack:daily:$i',
          );
        }
      }
    }
  }

  Future<void> cancelAttackWeek() async {
    await init();
    // start + 31 gün güvenli temizle
    await _plugin.cancel(_baseAttack);
    for (int i = 0; i < 31; i++) {
      await _plugin.cancel(_baseAttack + 1 + i);
    }
  }

  // ---------------------------------------------------------------------------
  // FEEDING REMINDER (schedule-based, daily)
  // ---------------------------------------------------------------------------

  /// Günlük tek hatırlatma (kullanıcı saat seçer).
  Future<void> scheduleDailyFeedingReminder({
    required TimeOfDay time,
    required bool enabled,
  }) async {
    await init();
    await cancelFeedingReminder();
    if (!enabled) return;

    final first = _ensureFuture(_combineDateTime(DateTime.now(), time));

    // Günlük tekrar: matchDateTimeComponents.time
    await _plugin.zonedSchedule(
      _feedingId,
      'Beslenme hatırlatması',
      'Beslenme kaydı eklemek ister misiniz?',
      _toTz(first),
      _details(),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: 'feeding:daily',
    );
  }

  Future<void> cancelFeedingReminder() async {
    await init();
    await _plugin.cancel(_feedingId);
  }

  // ---------------------------------------------------------------------------
  // CORE HELPERS
  // ---------------------------------------------------------------------------

  Future<void> _scheduleOneTime({
    required int id,
    required String title,
    required String body,
    required DateTime when,
    String? payload,
  }) async {
    await _plugin.zonedSchedule(
      id,
      title,
      body,
      _toTz(when),
      _details(),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: null,
      payload: payload,
    );
  }

  Future<List<PendingNotificationRequest>> pending() async {
    await init();
    return _plugin.pendingNotificationRequests();
  }

  Future<void> cancelAll() async {
    await init();
    await _plugin.cancelAll();
  }
}
