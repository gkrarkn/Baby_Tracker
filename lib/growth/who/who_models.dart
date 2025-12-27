// lib/growth/who/who_models.dart
class WhoPoint {
  final int ageDays;
  final double p3;
  final double p50;
  final double p97;

  const WhoPoint({
    required this.ageDays,
    required this.p3,
    required this.p50,
    required this.p97,
  });

  factory WhoPoint.fromMap(Map<String, dynamic> m) {
    double _d(dynamic v) => (v as num).toDouble();

    return WhoPoint(
      ageDays: (m['ageDays'] as num).toInt(),
      p3: _d(m['p3']),
      p50: _d(m['p50']),
      p97: _d(m['p97']),
    );
  }
}

class WhoSeries {
  final List<WhoPoint> points;

  const WhoSeries(this.points);

  /// En yakın günü bul (ageDays’e en yakın)
  WhoPoint? nearest(int ageDays) {
    if (points.isEmpty) return null;
    WhoPoint best = points.first;
    int bestDiff = (best.ageDays - ageDays).abs();

    for (final p in points) {
      final diff = (p.ageDays - ageDays).abs();
      if (diff < bestDiff) {
        best = p;
        bestDiff = diff;
      }
    }
    return best;
  }
}

enum WhoGender { boy, girl }

enum WhoMetric { weight, length, head }
