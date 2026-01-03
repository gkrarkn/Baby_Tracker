import 'package:flutter/material.dart';

class SleepRecommendedWindow extends StatelessWidget {
  final String rangeText; // Örn: "19:10 – 19:40"
  final Color accent;

  /// Opsiyonel: alt açıklamayı kapat/aç
  final bool showHint;

  const SleepRecommendedWindow({
    super.key,
    required this.rangeText,
    required this.accent,
    this.showHint = true,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accent.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _icon(),
          const SizedBox(width: 10),
          Expanded(child: _content(cs)),
        ],
      ),
    );
  }

  Widget _icon() {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(Icons.schedule_rounded, size: 18, color: accent),
    );
  }

  Widget _content(ColorScheme cs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Önerilen uyku aralığı',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontFamily: 'Nunito',
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: cs.onSurface,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          rangeText,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontFamily: 'Nunito',
            fontSize: 18,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.3,
            color: accent,
          ),
        ),
        if (showHint) ...[
          const SizedBox(height: 4),
          Text(
            'Son uyanmaya göre hesaplandı',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: cs.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}
