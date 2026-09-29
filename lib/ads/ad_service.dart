import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Build-time ads switch: `--dart-define=ADS_MODE=test`. Default disabled.
enum AdsMode { disabled, test, production }

AdsMode adsModeFromEnvironment() =>
    switch (const String.fromEnvironment('ADS_MODE')) {
      'test' => AdsMode.test,
      'production' => AdsMode.production,
      _ => AdsMode.disabled,
    };

/// Placement rules from docs/TECHNICAL_ARCHITECTURE.md: only after a fully
/// completed level, at most once every [winsBetweenAds] wins, never during
/// play, pause, hints, tutorials or retries. No rewarded unlocks exist.
class AdPolicy {
  final int winsBetweenAds;
  const AdPolicy({this.winsBetweenAds = 3});
  bool shouldShowAfterWin(int winsSinceAd, {required bool tutorialLevel}) =>
      !tutorialLevel && winsSinceAd >= winsBetweenAds;
}

abstract class AdService {
  AdsMode get mode;
  Future<void> init();

  /// Shows an interstitial if one is ready. Returns whether one was shown.
  /// Must never throw: gameplay and progress are independent of ads.
  Future<bool> showBetweenLevels();
}

class DisabledAdService implements AdService {
  @override
  AdsMode get mode => AdsMode.disabled;
  @override
  Future<void> init() async {}
  @override
  Future<bool> showBetweenLevels() async => false;
}

/// Google sample ad units only. Child-directed, G-rated, non-personalized.
class TestAdService implements AdService {
  static String get interstitialUnit => Platform.isAndroid
      ? 'ca-app-pub-3940256099942544/1033173712'
      : 'ca-app-pub-3940256099942544/4411468910';

  InterstitialAd? _ad;
  bool _ready = false;

  @override
  AdsMode get mode => AdsMode.test;

  @override
  Future<void> init() async {
    try {
      await MobileAds.instance.updateRequestConfiguration(
        RequestConfiguration(
          ageRestrictedTreatment: AgeRestrictedTreatment.child,
          maxAdContentRating: MaxAdContentRating.g,
        ),
      );
      await MobileAds.instance.initialize().timeout(
        const Duration(seconds: 10),
      );
      _ready = true;
      _load();
    } catch (e) {
      debugPrint('ads init failed (ignored): $e');
    }
  }

  void _load() {
    if (!_ready) return;
    InterstitialAd.load(
      adUnitId: interstitialUnit,
      request: const AdRequest(nonPersonalizedAds: true),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) => _ad = ad,
        onAdFailedToLoad: (err) {
          debugPrint('ad load failed (ignored): $err');
          _ad = null;
        },
      ),
    );
  }

  @override
  Future<bool> showBetweenLevels() async {
    final ad = _ad;
    if (ad == null) {
      _load();
      return false;
    }
    _ad = null;
    final done = Completer<bool>();
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (a) {
        a.dispose();
        _load();
        if (!done.isCompleted) done.complete(true);
      },
      onAdFailedToShowFullScreenContent: (a, err) {
        a.dispose();
        _load();
        if (!done.isCompleted) done.complete(false);
      },
    );
    try {
      await ad.show();
    } catch (_) {
      return false;
    }
    return done.future.timeout(
      const Duration(minutes: 2),
      onTimeout: () => false,
    );
  }
}

/// Production ads are blocked until the audience, Families/Kids policy and
/// privacy reviews in docs/ADS_PRIVACY_ASO.md are signed off.
AdService createAdService(AdsMode mode) {
  switch (mode) {
    case AdsMode.disabled:
      return DisabledAdService();
    case AdsMode.test:
      return TestAdService();
    case AdsMode.production:
      debugPrint(
        'ADS_MODE=production refused: release gate not passed. Ads disabled.',
      );
      return DisabledAdService();
  }
}
