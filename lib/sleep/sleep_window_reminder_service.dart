import '../core/notification_service.dart';
import 'sleep_window_calculator.dart';

class SleepWindowReminderService {
  /// Uyku penceresi için tek aktif notification mantığı
  static Future<void> schedule({
    required DateTime lastWakeTime,
    required int ageInMonths,
    int notifyBeforeMinutes = 15,
  }) async {
    final targetSleep = SleepWindowCalculator.calculateTargetSleep(
      lastWakeTime: lastWakeTime,
      ageInMonths: ageInMonths,
    );

    final notifyAt = targetSleep.subtract(
      Duration(minutes: notifyBeforeMinutes),
    );

    // Geçmişe schedule etme
    if (!notifyAt.isAfter(DateTime.now())) return;

    // UI + notification body için aynı metni kullanıyoruz
    final start = targetSleep.subtract(const Duration(minutes: 15));
    final end = targetSleep.add(const Duration(minutes: 15));

    String fmt(DateTime d) =>
        '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

    final rangeText = '${fmt(start)}–${fmt(end)}';

    await NotificationService.instance.scheduleSleepWindowReminder(
      when: notifyAt,
      title: 'Uyku penceresi yaklaşıyor',
      body: '$rangeText aralığı yaklaşıyor',
    );
  }

  static Future<void> cancel() async {
    await NotificationService.instance.cancelSleepWindowReminder();
  }
}
