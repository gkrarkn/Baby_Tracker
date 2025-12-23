// lib/ads/admob_ids.dart
import 'dart:io';

class AdMobIds {
  // Test banner unit id (Google)
  static const String _iosBannerTest = 'ca-app-pub-3940256099942544/2934735716';
  static const String _androidBannerTest =
      'ca-app-pub-3940256099942544/6300978111';

  static String get bannerUnitId =>
      Platform.isIOS ? _iosBannerTest : _androidBannerTest;

  // Prod’a geçince buraya gerçek ID’leri ekleyip bannerUnitId’yi ona bağlarsın.
}
