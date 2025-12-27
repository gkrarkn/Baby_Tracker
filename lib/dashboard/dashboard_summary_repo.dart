// lib/dashboard/dashboard_summary_repo.dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Dashboard için okunan ham verilerden üretilen "güvenli" özet modelleri.
/// Bu dosya yalnızca parsing + hesap işini yapar.
/// UI burada yok.

class TodaySummary {
  final Duration sleep; // V9.2: uyku entegre olunca dolacak
  final int milkMl; // toplam süt (ml)
  final int solidCount; // solid entry sayısı

  const TodaySummary({
    required this.sleep,
    required this.milkMl,
    required this.solidCount,
  });

  factory TodaySummary.empty() =>
      const TodaySummary(sleep: Duration.zero, milkMl: 0, solidCount: 0);

  bool get isEmpty => sleep == Duration.zero && milkMl == 0 && solidCount == 0;
}

class WeeklyFeedingSummary {
  /// Son 7 gün (bugün dahil) gün bazlı toplamlar.
  /// Key format: YYYY-MM-DD
  final Map<String, int> milkMlByDay;
  final Map<String, int> solidCountByDay;

  const WeeklyFeedingSummary({
    required this.milkMlByDay,
    required this.solidCountByDay,
  });

  factory WeeklyFeedingSummary.empty() => const WeeklyFeedingSummary(
    milkMlByDay: <String, int>{},
    solidCountByDay: <String, int>{},
  );

  /// Sheet UI'nin beklediği alanlar / getter'lar
  bool get isEmpty => totalMilkMl == 0 && totalSolidCount == 0;

  int get totalMilkMl => milkMlByDay.values.fold<int>(0, (sum, v) => sum + v);

  int get totalSolidCount =>
      solidCountByDay.values.fold<int>(0, (sum, v) => sum + v);

  double get avgMilkPerDay => totalMilkMl / 7.0;

  double get avgSolidPerDay => totalSolidCount / 7.0;

  /// UI tarafında tablo için gün listesi (oldest -> newest) - 7 güne normalize.
  List<String> get milkByDayKeys => _last7DayKeys();

  /// UI sheet "milkByDay" istiyor: 7 eleman (oldest -> newest).
  List<int> get milkByDay {
    final keys = _last7DayKeys();
    return keys.map((k) => milkMlByDay[k] ?? 0).toList();
  }

  /// UI sheet bazen "solidByDay" diye çağırıyor:
  List<int> get solidByDay => solidsByDay;

  /// 7 eleman (oldest -> newest).
  List<int> get solidsByDay {
    final keys = _last7DayKeys();
    return keys.map((k) => solidCountByDay[k] ?? 0).toList();
  }

  /// Basit trend: son 3 gün ort - önceki 3 gün ort (ml).
  /// 7 gün: [0..6] oldest->newest, kıyas: (4-6) vs (1-3)
  int get milkTrendDelta {
    final keys = _last7DayKeys(); // daima 7 eleman
    int sumEarly = 0; // gün 1-3
    int sumLate = 0; // gün 4-6

    for (int i = 1; i <= 3; i++) {
      sumEarly += milkMlByDay[keys[i]] ?? 0;
    }
    for (int i = 4; i <= 6; i++) {
      sumLate += milkMlByDay[keys[i]] ?? 0;
    }

    final earlyAvg = sumEarly / 3.0;
    final lateAvg = sumLate / 3.0;
    return (lateAvg - earlyAvg).round();
  }

  List<String> _last7DayKeys() {
    final now = DateTime.now();
    final keys = <String>[];
    for (int i = 6; i >= 0; i--) {
      final d = DateTime(
        now.year,
        now.month,
        now.day,
      ).subtract(Duration(days: i));
      keys.add(_dateKey(d));
    }
    return keys;
  }
}

class DashboardSummaryRepo {
  static const String feedingKey = 'feeding_entries';
  static const String premiumKey = 'is_premium';

  Future<bool> getPremiumFlag() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(premiumKey) ?? false;
  }

  Future<TodaySummary> getTodaySummary() async {
    final prefs = await SharedPreferences.getInstance();
    final rawList = prefs.getStringList(feedingKey) ?? const <String>[];

    final todayKey = _dateKey(DateTime.now());

    int totalMl = 0;
    int solidCount = 0;

    for (final raw in rawList) {
      try {
        final map = jsonDecode(raw) as Map<String, dynamic>;

        // date: "YYYY-MM-DD"
        if (map['date'] != todayKey) continue;

        final type = map['type'];
        if (type == 'milk') {
          final v = map['amountMl'];
          if (v is int) totalMl += v;
          if (v is double) totalMl += v.round();
          if (v is String) totalMl += int.tryParse(v) ?? 0;
        } else if (type == 'solid') {
          solidCount++;
        }
      } catch (_) {
        // dashboard asla çökmesin
      }
    }

    return TodaySummary(
      sleep: Duration.zero,
      milkMl: totalMl,
      solidCount: solidCount,
    );
  }

  Future<WeeklyFeedingSummary> getWeeklyFeedingSummary() async {
    final prefs = await SharedPreferences.getInstance();
    final rawList = prefs.getStringList(feedingKey) ?? const <String>[];

    final now = DateTime.now();
    final endDay = DateTime(now.year, now.month, now.day);
    final startDay = endDay.subtract(const Duration(days: 6));

    final milkByDay = <String, int>{};
    final solidByDay = <String, int>{};

    // 7 günü default 0 ile başlat (UI stabil)
    for (int i = 0; i < 7; i++) {
      final d = startDay.add(Duration(days: i));
      final k = _dateKey(d);
      milkByDay[k] = 0;
      solidByDay[k] = 0;
    }

    for (final raw in rawList) {
      try {
        final map = jsonDecode(raw) as Map<String, dynamic>;

        final dateStr = map['date'];
        if (dateStr is! String) continue;

        final dt = _parseDateKey(dateStr);
        if (dt == null) continue;

        final day = DateTime(dt.year, dt.month, dt.day);
        if (day.isBefore(startDay) || day.isAfter(endDay)) continue;

        final dayKey = _dateKey(day);

        final type = map['type'];
        if (type == 'milk') {
          final v = map['amountMl'];
          int add = 0;
          if (v is int) add = v;
          if (v is double) add = v.round();
          if (v is String) add = int.tryParse(v) ?? 0;
          milkByDay[dayKey] = (milkByDay[dayKey] ?? 0) + add;
        } else if (type == 'solid') {
          solidByDay[dayKey] = (solidByDay[dayKey] ?? 0) + 1;
        }
      } catch (_) {
        // silent
      }
    }

    return WeeklyFeedingSummary(
      milkMlByDay: milkByDay,
      solidCountByDay: solidByDay,
    );
  }
}

/* -----------------
   Helpers
------------------ */

String _dateKey(DateTime d) {
  final y = d.year.toString().padLeft(4, '0');
  final m = d.month.toString().padLeft(2, '0');
  final day = d.day.toString().padLeft(2, '0');
  return '$y-$m-$day';
}

DateTime? _parseDateKey(String s) {
  // Beklenen format: YYYY-MM-DD
  final parts = s.split('-');
  if (parts.length != 3) return null;
  final y = int.tryParse(parts[0]);
  final m = int.tryParse(parts[1]);
  final d = int.tryParse(parts[2]);
  if (y == null || m == null || d == null) return null;
  return DateTime(y, m, d);
}
