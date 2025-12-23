// lib/ads/anchored_adaptive_banner.dart
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'admob_ids.dart';

class AnchoredAdaptiveBanner extends StatefulWidget {
  const AnchoredAdaptiveBanner({super.key});

  @override
  State<AnchoredAdaptiveBanner> createState() => _AnchoredAdaptiveBannerState();
}

class _AnchoredAdaptiveBannerState extends State<AnchoredAdaptiveBanner> {
  BannerAd? _ad;
  AdSize? _size;
  bool _isLoaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _load(); // MediaQuery width burada hazır
  }

  Future<void> _load() async {
    // Zaten hazırsa tekrar yükleme
    if (_ad != null || _isLoaded) return;

    final width = MediaQuery.of(context).size.width.truncate();
    final size = await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(
      width,
    );
    if (!mounted || size == null) return;

    final ad = BannerAd(
      adUnitId: AdMobIds.bannerUnitId,
      size: size,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (!mounted) return;
          setState(() {
            _ad = ad as BannerAd;
            _size = size;
            _isLoaded = true;
          });
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          // Fail olursa sayfayı bozma: hiç gösterme.
          debugPrint('Anchored banner failed: $error');
        },
      ),
    );

    ad.load();
  }

  @override
  void dispose() {
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ad = _ad;
    final size = _size;

    if (!_isLoaded || ad == null || size == null) {
      return const SizedBox.shrink();
    }

    return SafeArea(
      top: false,
      child: SizedBox(
        width: double.infinity,
        height: size.height.toDouble(),
        child: AdWidget(ad: ad),
      ),
    );
  }
}
