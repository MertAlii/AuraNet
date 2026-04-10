import 'package:hive_flutter/hive_flutter.dart';

/// Hive yerel depolama servisi
class HiveService {
  static const String _deviceLabelsBox = 'device_labels';
  static const String _networkProfilesBox = 'network_profiles';
  static const String _achievementsBox = 'achievements';
  static const String _settingsBox = 'settings';
  static const String _macCacheBox = 'mac_cache';
  static const String _scanHistoryBox = 'scan_history';
  static const String _speedtestHistoryBox = 'speedtest_history';

  /// Hive'ı başlat ve box'ları aç
  static Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox(_deviceLabelsBox);
    await Hive.openBox(_networkProfilesBox);
    await Hive.openBox(_achievementsBox);
    await Hive.openBox(_settingsBox);
    await Hive.openBox(_macCacheBox);
    await Hive.openBox(_scanHistoryBox);
    await Hive.openBox(_speedtestHistoryBox);
  }

  // ─── Cihaz Etiketleri ─────────────────────────────────

  /// Cihaz etiketi kaydet (MAC adresine göre)
  static Future<void> saveDeviceLabel(String mac, Map<String, dynamic> label) async {
    final box = Hive.box(_deviceLabelsBox);
    await box.put(mac.toUpperCase(), label);
  }

  /// Cihaz etiketini getir
  static Map<String, dynamic>? getDeviceLabel(String mac) {
    final box = Hive.box(_deviceLabelsBox);
    final data = box.get(mac.toUpperCase());
    return data != null ? Map<String, dynamic>.from(data) : null;
  }

  /// Tüm cihaz etiketlerini getir
  static Map<String, Map<String, dynamic>> getAllDeviceLabels() {
    final box = Hive.box(_deviceLabelsBox);
    final Map<String, Map<String, dynamic>> result = {};
    for (final key in box.keys) {
      result[key as String] = Map<String, dynamic>.from(box.get(key));
    }
    return result;
  }

  // ─── MAC Vendor Cache ─────────────────────────────────

  /// MAC vendor cache'e kaydet
  static Future<void> cacheMacVendor(String mac, String vendor) async {
    final box = Hive.box(_macCacheBox);
    await box.put(mac.toUpperCase().substring(0, 8), vendor);
  }

  /// Cache'ten MAC vendor getir
  static String? getCachedVendor(String mac) {
    final box = Hive.box(_macCacheBox);
    return box.get(mac.toUpperCase().substring(0, 8)) as String?;
  }

  // ─── Başarımlar ─────────────────────────────────

  /// Başarım kazanıldı mı?
  static bool hasAchievement(String achievementId) {
    final box = Hive.box(_achievementsBox);
    return box.containsKey(achievementId);
  }

  /// Başarım kazandır
  static Future<void> earnAchievement(String achievementId) async {
    final box = Hive.box(_achievementsBox);
    if (!box.containsKey(achievementId)) {
      await box.put(achievementId, {
        'earnedAt': DateTime.now().toIso8601String(),
      });
    }
  }

  /// Tüm kazanılan başarımları getir
  static List<String> getEarnedAchievements() {
    final box = Hive.box(_achievementsBox);
    return box.keys.cast<String>().toList();
  }

  // ─── Ayarlar ─────────────────────────────────

  /// Ayar kaydet
  static Future<void> saveSetting(String key, dynamic value) async {
    final box = Hive.box(_settingsBox);
    await box.put(key, value);
  }

  /// Ayar getir
  static T? getSetting<T>(String key, {T? defaultValue}) {
    final box = Hive.box(_settingsBox);
    return box.get(key, defaultValue: defaultValue) as T?;
  }

  /// Gateway MAC adresini getir
  static String? getGatewayMac() {
    return getSetting<String>('gateway_mac');
  }

  /// Gateway MAC adresini kaydet
  static Future<void> saveGatewayMac(String mac) async {
    await saveSetting('gateway_mac', mac);
  }

  // ─── Uygulama Ayarları ─────────────────────────────────
  
  static bool hasSeenOnboarding() {
    return getSetting<bool>('has_seen_onboarding', defaultValue: false) ?? false;
  }

  static Future<void> setSeenOnboarding(bool value) async {
    await saveSetting('has_seen_onboarding', value);
  }

  static bool isRootMode() {
    return getSetting<bool>('is_root_mode', defaultValue: false) ?? false;
  }

  static Future<void> setRootMode(bool value) async {
    await saveSetting('is_root_mode', value);
  }

  static bool isWakelockEnabled() {
    return getSetting<bool>('is_wakelock_enabled', defaultValue: true) ?? true;
  }

  static Future<void> setWakelockEnabled(bool value) async {
    await saveSetting('is_wakelock_enabled', value);
  }

  // ─── Ağ Profilleri ─────────────────────────────────

  /// Ağ profili kaydet
  static Future<void> saveNetworkProfile(String ssid, Map<String, dynamic> profile) async {
    final box = Hive.box(_networkProfilesBox);
    await box.put(ssid, profile);
  }

  /// Ağ profili getir
  static Map<String, dynamic>? getNetworkProfile(String ssid) {
    final box = Hive.box(_networkProfilesBox);
    final data = box.get(ssid);
    return data != null ? Map<String, dynamic>.from(data) : null;
  }

  /// Tüm ağ profillerini getir
  static Map<String, Map<String, dynamic>> getAllNetworkProfiles() {
    final box = Hive.box(_networkProfilesBox);
    final Map<String, Map<String, dynamic>> result = {};
    for (final key in box.keys) {
      result[key as String] = Map<String, dynamic>.from(box.get(key));
    }
    return result;
  }

  // ─── Tarama Geçmişi (Local Only) ──────────────────────

  /// Tarama sonucunu kaydet
  static Future<void> saveScanResult(Map<String, dynamic> scanData) async {
    final box = Hive.box(_scanHistoryBox);
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    await box.put(id, {
      ...scanData,
      'id': id,
      'scannedAt': DateTime.now().toIso8601String(),
    });
  }

  /// Tüm tarama geçmişini getir (Tarihe göre azalan)
  static List<Map<String, dynamic>> getScanHistory() {
    final box = Hive.box(_scanHistoryBox);
    final List<Map<String, dynamic>> history = [];
    for (final key in box.keys) {
      history.add(Map<String, dynamic>.from(box.get(key)));
    }
    // Tarihe göre sırala (Yeni en üstte)
    history.sort((a, b) => b['scannedAt'].compareTo(a['scannedAt']));
    return history;
  }

  /// Tüm geçmişi temizle
  static Future<void> clearHistory() async {
    final box = Hive.box(_scanHistoryBox);
    await box.clear();
  }

  // ─── Hız Testi Geçmişi ────────────────────────────────
  
  /// Hız testi sonucunu kaydet
  static Future<void> saveSpeedtestResult(Map<String, dynamic> result) async {
    final box = Hive.box(_speedtestHistoryBox);
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    await box.put(id, {
      ...result,
      'createdAt': DateTime.now().toIso8601String(),
    });
  }

  /// Hız testi geçmişini getir (Yeni en üstte)
  static List<Map<String, dynamic>> getSpeedtestHistory() {
    final box = Hive.box(_speedtestHistoryBox);
    final List<Map<String, dynamic>> results = [];
    for (final key in box.keys) {
      results.add(Map<String, dynamic>.from(box.get(key)));
    }
    results.sort((a, b) => b['createdAt'].compareTo(a['createdAt']));
    return results.take(10).toList(); // Son 10 test
  }
}
