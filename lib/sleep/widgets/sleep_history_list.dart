import 'package:flutter/material.dart';

import '../sleep_entry.dart';
import 'sleep_history_tile.dart';

class SleepHistoryList extends StatelessWidget {
  final List<SleepEntry> entries; // newest first
  final ValueChanged<SleepEntry> onDelete;

  const SleepHistoryList({
    super.key,
    required this.entries,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      final cs = Theme.of(context).colorScheme;
      return Text(
        'Henüz kayıt yok.',
        style: TextStyle(fontFamily: 'Nunito', color: cs.onSurfaceVariant),
      );
    }

    return Column(
      children: [
        for (final e in entries)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: SleepHistoryTile(entry: e, onDelete: () => onDelete(e)),
          ),
      ],
    );
  }
}
