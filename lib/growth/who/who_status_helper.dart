// lib/growth/who/who_status_helper.dart

import 'who_models.dart';

enum WhoStatus { low, normal, high }

WhoStatus resolveWhoStatus({required double value, required WhoPoint ref}) {
  if (value < ref.p3) return WhoStatus.low;
  if (value > ref.p97) return WhoStatus.high;
  return WhoStatus.normal;
}

String whoStatusLabel(WhoStatus s) {
  switch (s) {
    case WhoStatus.low:
      return 'Alt sınırda';
    case WhoStatus.high:
      return 'Üst sınırda';
    case WhoStatus.normal:
      return 'Normal aralıkta';
  }
}
