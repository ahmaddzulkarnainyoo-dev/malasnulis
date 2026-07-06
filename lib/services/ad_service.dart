import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Service untuk mengelola iklan Interstitial AdMob.
/// Menggunakan ID test agar aman untuk development.
class AdService {
  static final AdService _instance = AdService._internal();
  factory AdService() => _instance;
  AdService._internal();

  bool _isInitialized = false;

  /// ID unit iklan interstitial test
  /// Sumber: https://developers.google.com/admob/android/test-ads
  static const String _testInterstitialAdUnitId =
      'ca-app-pub-3940256099942544/1033173712';

  /// Inisialisasi AdMob (dipanggil di main.dart)
  Future<void> initialize() async {
    if (!_isInitialized) {
      await MobileAds.instance.initialize();
      _isInitialized = true;
    }
  }

  /// Menampilkan Interstitial Ad.
  /// Menggunakan [Completer] agar fungsi bisa di-await sampai iklan selesai.
  /// Jika gagal load atau timeout, tetap resolve agar flow aplikasi tidak terblokir.
  Future<void> showInterstitialAd() async {
    final completer = Completer<void>();

    try {
      await InterstitialAd.load(
        adUnitId: _testInterstitialAdUnitId,
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          // Iklan berhasil di-load
          onAdLoaded: (InterstitialAd ad) {
            ad.fullScreenContentCallback = FullScreenContentCallback(
              // Iklan selesai ditutup oleh user
              onAdDismissedFullScreenContent: (InterstitialAd ad) {
                ad.dispose();
                if (!completer.isCompleted) completer.complete();
              },
              // Iklan gagal ditampilkan
              onAdFailedToShowFullScreenContent: (InterstitialAd ad, AdError error) {
                debugPrint('Ad failed to show: $error');
                ad.dispose();
                if (!completer.isCompleted) completer.complete();
              },
            );

            // Tampilkan iklan
            ad.show();
          },
          // Iklan gagal di-load
          onAdFailedToLoad: (LoadAdError error) {
            debugPrint('Ad failed to load: $error');
            if (!completer.isCompleted) completer.complete();
          },
        ),
      );
    } catch (e) {
      debugPrint('Ad error: $e');
      if (!completer.isCompleted) completer.complete();
    }

    // Timeout 10 detik agar tidak nge-freeze jika iklan lama
    await completer.future.timeout(
      const Duration(seconds: 10),
      onTimeout: () {
        debugPrint('Ad timeout - melanjutkan proses');
        // Jika timeout, tetap lanjutkan flow
      },
    );
  }
}