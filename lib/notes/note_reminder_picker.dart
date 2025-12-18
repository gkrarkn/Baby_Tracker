import 'package:flutter/material.dart';

Future<DateTime?> showReminderPicker(
  BuildContext context,
  DateTime? initial,
) async {
  final now = DateTime.now();

  final date = await showDatePicker(
    context: context,
    initialDate: initial ?? now,
    firstDate: now,
    lastDate: DateTime(now.year + 2),
  );
  if (date == null) return null;

  final time = await showTimePicker(
    context: context,
    initialTime: TimeOfDay.fromDateTime(initial ?? now),
  );
  if (time == null) return null;

  return DateTime(date.year, date.month, date.day, time.hour, time.minute);
}
