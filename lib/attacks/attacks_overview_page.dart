// lib/attacks/attacks_overview_page.dart
import 'package:flutter/material.dart';

import '../core/app_globals.dart'; // babyBirthDate, babyDueDate, appThemeColor
import 'attack_calculator.dart';
import 'attack_data.dart';

class AttacksOverviewPage extends StatelessWidget {
  const AttacksOverviewPage({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return ValueListenableBuilder<Color>(
      valueListenable: appThemeColor,
      builder: (_, mainColor, __) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Atak Takvimi'),
            backgroundColor: mainColor,
            foregroundColor: Colors.white,
          ),
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [mainColor.withValues(alpha: 0.10), cs.surface],
              ),
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                child: ValueListenableBuilder<DateTime?>(
                  valueListenable: babyBirthDate,
                  builder: (_, birth, __) {
                    return ValueListenableBuilder<DateTime?>(
                      valueListenable: babyDueDate,
                      builder: (_, due, ___) {
                        if (birth == null) {
                          return _emptyState(context);
                        }

                        final note = AttackCalculator.calcNote(
                          birthDate: birth,
                          dueDate: due,
                        );

                        final current = AttackCalculator.currentAttack(
                          birthDate: birth,
                          dueDate: due,
                        );

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _infoBanner(context, note),
                            const SizedBox(height: 12),
                            if (current != null) ...[
                              _currentBanner(context, mainColor, current.title),
                              const SizedBox(height: 10),
                            ],
                            Expanded(
                              child: ListView.builder(
                                itemCount: AttackData.items.length,
                                itemBuilder: (context, i) {
                                  final a = AttackData.items[i];
                                  final isCurrent = (current?.month == a.month);

                                  return _attackCard(
                                    context,
                                    mainColor: mainColor,
                                    title: a.title,
                                    monthLabel: '${a.month}. ay',
                                    description: a.description,
                                    symptoms: a.symptoms,
                                    tips: a.tips,
                                    highlight: isCurrent,
                                  );
                                },
                              ),
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _emptyState(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: cs.onSurfaceVariant),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Atak takvimi için Ayarlar’dan doğum tarihini (prematüre ise beklenen doğum tarihini) ekleyin.',
              style: TextStyle(color: cs.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoBanner(BuildContext context, String note) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surface.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.35)),
      ),
      child: Text(
        note,
        style: TextStyle(
          fontWeight: FontWeight.w700,
          color: cs.onSurfaceVariant,
          height: 1.2,
        ),
      ),
    );
  }

  Widget _currentBanner(BuildContext context, Color mainColor, String text) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: mainColor.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: mainColor.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Icon(Icons.bolt_rounded, color: mainColor),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '⚡ Atak haftası olabilir • $text',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                color: cs.onSurface,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _attackCard(
    BuildContext context, {
    required Color mainColor,
    required String title,
    required String monthLabel,
    required String description,
    required List<String> symptoms,
    required List<String> tips,
    required bool highlight,
  }) {
    final cs = Theme.of(context).colorScheme;

    final bg = highlight
        ? Color.alphaBlend(mainColor.withValues(alpha: 0.08), cs.surface)
        : cs.surface.withValues(alpha: 0.96);

    final border = highlight
        ? mainColor.withValues(alpha: 0.28)
        : cs.outlineVariant.withValues(alpha: 0.35);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          title: Text(
            title,
            style: TextStyle(fontWeight: FontWeight.w900, color: cs.onSurface),
          ),
          subtitle: Text(
            monthLabel,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: cs.onSurfaceVariant,
            ),
          ),
          children: [
            Text(
              description,
              style: TextStyle(color: cs.onSurfaceVariant, height: 1.25),
            ),
            const SizedBox(height: 10),
            _bullets(context, 'Belirtiler', symptoms),
            const SizedBox(height: 8),
            _bullets(context, 'Öneriler', tips),
            const SizedBox(height: 10),
            Text(
              'Not: Bu içerik bilgilendirme amaçlıdır; tıbbi tavsiye değildir.',
              style: TextStyle(
                fontSize: 12,
                color: cs.onSurfaceVariant.withValues(alpha: 0.90),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bullets(BuildContext context, String title, List<String> items) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(fontWeight: FontWeight.w900, color: cs.onSurface),
        ),
        const SizedBox(height: 6),
        ...items.map(
          (t) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('• ', style: TextStyle(color: cs.onSurfaceVariant)),
                Expanded(
                  child: Text(
                    t,
                    style: TextStyle(color: cs.onSurfaceVariant, height: 1.2),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
