import 'dart:math' as math;
import 'package:flutter/material.dart';

class SleepSparkline extends StatelessWidget {
  final List<int> minutes; // 7 point
  const SleepSparkline({super.key, required this.minutes});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return CustomPaint(
      painter: _SparklinePainter(
        values: minutes,
        lineColor: cs.primary,
        fillColor: cs.primary.withValues(alpha: 0.12),
        gridColor: cs.outlineVariant.withValues(alpha: 0.35),
        labelColor: cs.onSurfaceVariant,
      ),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  final List<int> values;

  final Color lineColor;
  final Color fillColor;
  final Color gridColor;
  final Color labelColor;

  _SparklinePainter({
    required this.values,
    required this.lineColor,
    required this.fillColor,
    required this.gridColor,
    required this.labelColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;

    final vMin = values.reduce(math.min);
    final vMax = values.reduce(math.max);

    final topPad = 8.0;
    final bottomPad = 10.0;

    final w = size.width;
    final h = size.height - topPad - bottomPad;

    double norm(int v) {
      if (vMax == vMin) return 0.5;
      return (v - vMin) / (vMax - vMin);
    }

    Offset pointAt(int idx) {
      final x = (values.length == 1) ? w / 2 : (w * idx / (values.length - 1));
      final y = topPad + (h * (1 - norm(values[idx])));
      return Offset(x, y);
    }

    // grid midline
    final gridPaint = Paint()
      ..color = gridColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    canvas.drawLine(
      Offset(0, topPad + h / 2),
      Offset(w, topPad + h / 2),
      gridPaint,
    );

    final path = Path();
    final fillPath = Path();

    final p0 = pointAt(0);
    path.moveTo(p0.dx, p0.dy);

    for (int i = 1; i < values.length; i++) {
      final p = pointAt(i);
      final prev = pointAt(i - 1);
      final mid = Offset((prev.dx + p.dx) / 2, (prev.dy + p.dy) / 2);

      path.quadraticBezierTo(prev.dx, prev.dy, mid.dx, mid.dy);

      if (i == values.length - 1) {
        path.quadraticBezierTo(mid.dx, mid.dy, p.dx, p.dy);
      }
    }

    fillPath.addPath(path, Offset.zero);
    fillPath.lineTo(w, topPad + h);
    fillPath.lineTo(0, topPad + h);
    fillPath.close();

    final fillPaint = Paint()
      ..color = fillColor
      ..style = PaintingStyle.fill;

    canvas.drawPath(fillPath, fillPaint);

    final linePaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(path, linePaint);

    final dotPaint = Paint()..color = lineColor;
    for (int i = 0; i < values.length; i++) {
      canvas.drawCircle(pointAt(i), 3.2, dotPaint);
    }

    final textStyle = TextStyle(
      fontFamily: 'Nunito',
      fontSize: 11,
      fontWeight: FontWeight.w800,
      color: labelColor,
    );

    final maxText = '${vMax} dk';
    final minText = '${vMin} dk';

    final tpMax = TextPainter(
      text: TextSpan(text: maxText, style: textStyle),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: size.width);

    final tpMin = TextPainter(
      text: TextSpan(text: minText, style: textStyle),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: size.width);

    tpMax.paint(canvas, const Offset(0, 0));
    tpMin.paint(canvas, Offset(0, size.height - tpMin.height));
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter oldDelegate) {
    if (oldDelegate.values.length != values.length) return true;
    for (int i = 0; i < values.length; i++) {
      if (oldDelegate.values[i] != values[i]) return true;
    }
    return false;
  }
}
