// lib/pages/settings/notification_settings_section.dart
import 'package:flutter/material.dart';

import '../../core/notification_service.dart';
import 'notification_prefs.dart';

class NotificationSettingsSection extends StatefulWidget {
  const NotificationSettingsSection({super.key});

  @override
  State<NotificationSettingsSection> createState() =>
      _NotificationSettingsSectionState();
}

class _NotificationSettingsSectionState
    extends State<NotificationSettingsSection> {
  late FeedingPrefs feeding;
  late VaccinePrefs vaccine;
  late AttackPrefs attack;

  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    feeding = await NotificationPrefs.loadFeeding();
    vaccine = await NotificationPrefs.loadVaccine();
    attack = await NotificationPrefs.loadAttack();
    setState(() => _loaded = true);
  }

  Future<void> _pickTime(
    TimeOfDay current,
    ValueChanged<TimeOfDay> onPicked,
  ) async {
    final picked = await showTimePicker(context: context, initialTime: current);
    if (picked != null) onPicked(picked);
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: CircularProgressIndicator(),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _section('Bildirimler'),

        _toggleTile(
          title: 'Beslenme hatırlatması',
          value: feeding.enabled,
          time: feeding.time,
          onChanged: (v) async {
            feeding = FeedingPrefs(enabled: v, time: feeding.time);
            await NotificationPrefs.saveFeeding(feeding);
            await NotificationService.instance.scheduleDailyFeedingReminder(
              time: feeding.time,
              enabled: feeding.enabled,
            );
            setState(() {});
          },
          onTimeTap: () => _pickTime(feeding.time, (t) async {
            feeding = FeedingPrefs(enabled: feeding.enabled, time: t);
            await NotificationPrefs.saveFeeding(feeding);
            await NotificationService.instance.scheduleDailyFeedingReminder(
              time: t,
              enabled: feeding.enabled,
            );
            setState(() {});
          }),
        ),

        _toggleTile(
          title: 'Aşı hatırlatmaları',
          value: vaccine.enabled,
          time: vaccine.time,
          onChanged: (v) async {
            vaccine = VaccinePrefs(enabled: v, time: vaccine.time);
            await NotificationPrefs.saveVaccine(vaccine);
            setState(() {});
          },
          onTimeTap: () => _pickTime(vaccine.time, (t) async {
            vaccine = VaccinePrefs(enabled: vaccine.enabled, time: t);
            await NotificationPrefs.saveVaccine(vaccine);
            setState(() {});
          }),
        ),

        _toggleTile(
          title: 'Atak haftası',
          value: attack.enabled,
          time: attack.time,
          subtitle: attack.dailyEnabled ? 'Günlük hatırlatma açık' : null,
          onChanged: (v) async {
            attack = AttackPrefs(
              enabled: v,
              dailyEnabled: attack.dailyEnabled,
              time: attack.time,
            );
            await NotificationPrefs.saveAttack(attack);
            setState(() {});
          },
          onTimeTap: () => _pickTime(attack.time, (t) async {
            attack = AttackPrefs(
              enabled: attack.enabled,
              dailyEnabled: attack.dailyEnabled,
              time: t,
            );
            await NotificationPrefs.saveAttack(attack);
            setState(() {});
          }),
        ),
      ],
    );
  }

  Widget _section(String t) => Padding(
    padding: const EdgeInsets.only(top: 16, bottom: 8),
    child: Text(
      t,
      style: Theme.of(
        context,
      ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
    ),
  );

  Widget _toggleTile({
    required String title,
    required bool value,
    required TimeOfDay time,
    String? subtitle,
    required ValueChanged<bool> onChanged,
    required VoidCallback onTimeTap,
  }) {
    return Card(
      child: Column(
        children: [
          SwitchListTile(
            title: Text(title),
            subtitle: subtitle != null ? Text(subtitle) : null,
            value: value,
            onChanged: onChanged,
          ),
          ListTile(
            title: const Text('Saat'),
            subtitle: Text(time.format(context)),
            trailing: const Icon(Icons.access_time),
            onTap: value ? onTimeTap : null,
          ),
        ],
      ),
    );
  }
}
