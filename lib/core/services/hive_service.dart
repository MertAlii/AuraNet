import 'package:hive_flutter/hive_flutter.dart';

/// Hive yerel depolama servisi
class HiveService {
  static const String _deviceLabelsBox = 'device_labels';
  static const String _networkProfilesBox = 'network_profiles';
  static const String _achievementsBox = 'achievements';
  static const String _settingsBox = 'settings';
  static const String _macCacheBox = 'mac_cache';

  /// Hive'ı başlat ve box'ları aç
  static Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox(_deviceLabelsBox);
    await Hive.openBox(_networkProfilesBox);
    await Hive.openBox(_achievementsBox);
    await Hive.openBox(_settingsBox);
    await Hive.openBox(_macCacheBox);
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
}
