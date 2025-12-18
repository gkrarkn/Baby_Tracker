import 'package:intl/intl.dart';

String formatReminderDateTR(DateTime date) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final target = DateTime(date.year, date.month, date.day);

  final diffDays = target.difference(today).inDays;

  final time = DateFormat('HH:mm').format(date);

  if (diffDays == 0) {
    return 'Bugün $time';
  } else if (diffDays == 1) {
    return 'Yarın $time';
  } else if (diffDays == -1) {
    return 'Dün $time';
  } else {
    return DateFormat('d MMM HH:mm', 'tr_TR').format(date);
  }
}
