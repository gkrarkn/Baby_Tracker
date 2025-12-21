import 'package:flutter/material.dart';

import '../sleep_entry.dart';
import '../sleep_formatters.dart';

class SleepHistoryTile extends StatelessWidget {
  final SleepEntry entry;
  final VoidCallback onDelete;

  const SleepHistoryTile({
    super.key,
    required this.entry,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: _surfaceCard(
        context,
        ListTile(
          leading: CircleAvatar(
            backgroundColor: cs.primary.withValues(alpha: 0.12),
            child: Icon(Icons.bedtime_rounded, color: cs.primary),
          ),
          title: Text(
            'Uyku: ${SleepFormatters.durationHM(entry.duration)}',
            style: const TextStyle(
              fontFamily: 'Nunito',
              fontWeight: FontWeight.w900,
            ),
          ),
          subtitle: Text(
            '${SleepFormatters.dateTime(entry.start)} → ${SleepFormatters.time(entry.end)}',
            style: TextStyle(fontFamily: 'Nunito', color: cs.onSurfaceVariant),
          ),
          trailing: IconButton(
            tooltip: 'Sil',
            icon: const Icon(Icons.delete_outline),
            onPressed: onDelete,
          ),
        ),
      ),
    );
  }

  static Widget _surfaceCard(BuildContext context, Widget child) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.surface.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.35)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}
