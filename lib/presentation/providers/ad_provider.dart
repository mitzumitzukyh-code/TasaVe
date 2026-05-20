import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../../core/constants.dart';
import 'accessibility_provider.dart';

final adInitProvider = FutureProvider<bool>((ref) async {
  if (kIsWeb) return false;
  await MobileAds.instance.initialize();
  return true;
});

final bannerAdProvider = Provider<BannerAd?>((ref) {
  final userPlan = ref.watch(userPlanProvider);
  if (userPlan == 'premium' || kIsWeb) return null;

  final ad = BannerAd(
    adUnitId: AdConfig.BANNER_HOME,
    size: AdSize.banner,
    request: const AdRequest(),
    listener: BannerAdListener(
      onAdFailedToLoad: (ad, error) {
        ad.dispose();
      },
    ),
  );
  ad.load();
  return ad;
});

class InterstitialAdService {
  InterstitialAd? _interstitialAd;
  bool _isLoaded = false;

  void loadAd() {
    InterstitialAd.load(
      adUnitId: AdConfig.INTERSTITIAL,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isLoaded = true;
        },
        onAdFailedToLoad: (error) {
          _isLoaded = false;
        },
      ),
    );
  }

  void showAd() {
    if (_isLoaded && _interstitialAd != null) {
      _interstitialAd!.show();
      _interstitialAd = null;
      _isLoaded = false;
      loadAd();
    }
  }

  void dispose() {
    _interstitialAd?.dispose();
  }
}

final interstitialAdProvider = Provider<InterstitialAdService>((ref) {
  final service = InterstitialAdService();
  final userPlan = ref.watch(userPlanProvider);
  if (userPlan != 'premium' && !kIsWeb) {
    service.loadAd();
  }
  return service;
});
