import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service untuk mengelola kuota generate harian dan status premium.
///
/// Logika:
/// - User non-premium: 2x generate per hari (dihitung per tanggal).
/// - User premium: unlimited (return 999).
///
/// Data disimpan di SharedPreferences (offline-first, tanpa server).
class QuotaService {
  static final QuotaService _instance = QuotaService._internal();
  factory QuotaService() => _instance;
  QuotaService._internal();

  static const String _keyLastDate = 'last_date';
  static const String _keyTodayCount = 'today_count';
  static const String _keyIsPremium = 'is_premium';
  static const String _keyPremiumExpiry = 'premium_expiry';

  // Maks generate per hari untuk user non-premium
  static const int _maxDailyQuota = 2;

  /// Mendapatkan sisa kuota generate hari ini.
  /// Return 999 jika premium aktif, atau (2 - todayCount) untuk non-premium.
  Future<int> getRemainingQuota() async {
    final prefs = await SharedPreferences.getInstance();

    // Cek status premium dulu
    final bool isPremium = prefs.getBool(_keyIsPremium) ?? false;
    final int premiumExpiry = prefs.getInt(_keyPremiumExpiry) ?? 0;

    if (isPremium && premiumExpiry > DateTime.now().millisecondsSinceEpoch) {
      return 999; // Unlimited
    }

    // Reset kuota jika hari sudah berganti
    await _resetIfNewDay(prefs);

    final int todayCount = prefs.getInt(_keyTodayCount) ?? 0;
    final int remaining = _maxDailyQuota - todayCount;
    return remaining < 0 ? 0 : remaining;
  }

  /// Menggunakan satu slot kuota generate.
  /// Mengembalikan true jika kuota tersedia dan berhasil dipakai.
  /// Mengembalikan false jika kuota habis.
  Future<bool> useQuota() async {
    final prefs = await SharedPreferences.getInstance();

    // Cek status premium
    final bool isPremium = prefs.getBool(_keyIsPremium) ?? false;
    final int premiumExpiry = prefs.getInt(_keyPremiumExpiry) ?? 0;

    if (isPremium && premiumExpiry > DateTime.now().millisecondsSinceEpoch) {
      // Premium: tidak mengurangi kuota, selalu return true
      return true;
    }

    // Reset jika hari baru
    await _resetIfNewDay(prefs);

    final int todayCount = prefs.getInt(_keyTodayCount) ?? 0;
    if (todayCount >= _maxDailyQuota) {
      return false; // Kuota habis
    }

    // Increment kuota terpakai
    await prefs.setInt(_keyTodayCount, todayCount + 1);
    return true;
  }

  /// Mendapatkan status premium.
  /// Mengembalikan map berisi isPremium, premiumExpiry (timestamp), dan sisa hari.
  Future<Map<String, dynamic>> getPremiumStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final bool isPremium = prefs.getBool(_keyIsPremium) ?? false;
    final int premiumExpiry = prefs.getInt(_keyPremiumExpiry) ?? 0;

    final int remainingDays = isPremium
        ? ((premiumExpiry - DateTime.now().millisecondsSinceEpoch) /
                (1000 * 60 * 60 * 24))
            .ceil()
        : 0;

    return {
      'isPremium': isPremium && premiumExpiry > DateTime.now().millisecondsSinceEpoch,
      'premiumExpiry': premiumExpiry,
      'remainingDays': remainingDays > 0 ? remainingDays : 0,
    };
  }

  /// Mengaktifkan status premium (misalnya setelah pembelian).
  /// [days] adalah lama premium dalam hari.
  Future<void> activatePremium(int days) async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now().millisecondsSinceEpoch;
    final expiry = now + (days * 24 * 60 * 60 * 1000);

    await prefs.setBool(_keyIsPremium, true);
    await prefs.setInt(_keyPremiumExpiry, expiry);
    debugPrint('Premium diaktifkan: $days hari, expired: $expiry');
  }

  /// Mendapatkan jumlah kuota yang sudah dipakai hari ini.
  Future<int> getTodayCount() async {
    final prefs = await SharedPreferences.getInstance();
    await _resetIfNewDay(prefs);
    return prefs.getInt(_keyTodayCount) ?? 0;
  }

  /// Reset todayCount ke 0 jika hari sudah berganti.
  Future<void> _resetIfNewDay(SharedPreferences prefs) async {
    final String today = _getTodayDateString();
    final String? lastDate = prefs.getString(_keyLastDate);

    if (lastDate != today) {
      await prefs.setString(_keyLastDate, today);
      await prefs.setInt(_keyTodayCount, 0);
      debugPrint('Kuota direset untuk hari baru: $today');
    }
  }

  /// Mendapatkan string tanggal hari ini (format: yyyy-MM-dd).
  String _getTodayDateString() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }
}