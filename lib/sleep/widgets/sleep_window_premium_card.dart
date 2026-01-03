// lib/sleep/widgets/sleep_window_premium_card.dart

import 'package:flutter/material.dart';
import 'sleep_recommended_window.dart';

class SleepWindowPremiumCard extends StatelessWidget {
  final bool isPremium;
  final bool enabled;
  final VoidCallback onUpgradeTap;
  final ValueChanged<bool>? onToggle;

  /// Örn: "19:10 – 19:40"
  final String? windowRangeText;

  const SleepWindowPremiumCard({
    super.key,
    required this.isPremium,
    required this.enabled,
    required this.onUpgradeTap,
    this.onToggle,
    this.windowRangeText,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final locked = !isPremium;

    return GestureDetector(
      onTap: locked ? onUpgradeTap : null,
      child: Opacity(
        opacity: locked ? 0.6 : 1,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: cs.outlineVariant.withOpacity(0.4)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // -------------------------------------------------
              // Header row
              // -------------------------------------------------
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: cs.primary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.alarm, size: 20, color: cs.primary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Uyku penceresi hatırlatıcısı',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (locked)
                    const Icon(Icons.lock, size: 18)
                  else
                    Switch(value: enabled, onChanged: onToggle),
                ],
              ),

              // -------------------------------------------------
              // Content
              // -------------------------------------------------
              const SizedBox(height: 12),

              if (locked)
                Text(
                  'Bu özellik Premium ile açılır.',
                  style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                )
              else if (windowRangeText != null)
                SleepRecommendedWindow(
                  rangeText: windowRangeText!,
                  accent: cs.primary,
                )
              else
                Text(
                  'Son uyanmaya göre hesaplanıyor…',
                  style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
