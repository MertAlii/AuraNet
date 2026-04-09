/// Bilinen kamera üreticileri ve şüpheli MAC vendor listesi
class CameraMacVendors {
  CameraMacVendors._();

  /// Kamera / gözetleme cihazı üreticileri — şüpheli olarak işaretlenir
  static const List<String> suspiciousVendors = [
    'hikvision',
    'dahua',
    'axis',
    'reolink',
    'amcrest',
    'vivotek',
    'hanwha',
    'uniview',
    'tiandy',
    'cp plus',
    'zkteco',
    'foscam',
    'wansview',
    'wyze',
    'annke',
    'swann',
    'lorex',
  ];

  /// Telefon / tablet üreticileri
  static const List<String> phoneVendors = [
    'apple',
    'samsung',
    'xiaomi',
    'huawei',
    'oppo',
    'vivo',
    'realme',
    'oneplus',
    'google',
    'motorola',
    'nokia',
    'sony',
    'lg',
    'honor',
    'poco',
    'nothing',
    'tecno',
  ];

  /// Router üreticileri
  static const List<String> routerVendors = [
    'tp-link',
    'asus',
    'netgear',
    'tenda',
    'd-link',
    'zyxel',
    'mikrotik',
    'linksys',
    'huawei',
    'ubiquiti',
    'arris',
    'cisco',
    'tplink',
  ];

  /// TV üreticileri
  static const List<String> tvVendors = [
    'lg',
    'samsung',
    'sony',
    'philips',
    'vestel',
    'hisense',
    'tcl',
    'panasonic',
    'toshiba',
    'sharp',
    'roku',
    'amazon',
    'fire tv',
  ];

  /// IoT cihaz üreticileri
  static const List<String> iotVendors = [
    'philips hue',
    'xiaomi',
    'tuya',
    'sonoff',
    'shelly',
    'esp',
    'espressif',
    'broadlink',
    'ring',
    'nest',
    'ecobee',
    'wemo',
    'meross',
  ];

  /// Vendor adından cihaz tipini belirle
  static String getDeviceType(String vendor) {
    final v = vendor.toLowerCase();
    if (suspiciousVendors.any((s) => v.contains(s))) return 'camera';
    if (routerVendors.any((s) => v.contains(s))) return 'router';
    if (tvVendors.any((s) => v.contains(s))) return 'tv';
    if (phoneVendors.any((s) => v.contains(s))) return 'phone';
    if (iotVendors.any((s) => v.contains(s))) return 'iot';
    return 'unknown';
  }

  /// Cihaz tipine göre emoji
  static String getDeviceEmoji(String deviceType) {
    switch (deviceType) {
      case 'phone':
        return '📱';
      case 'tv':
        return '📺';
      case 'router':
        return '🌐';
      case 'camera':
        return '📷';
      case 'iot':
        return '🏠';
      case 'computer':
        return '💻';
      default:
        return '❓';
    }
  }

  /// Vendor şüpheli mi?
  static bool isSuspicious(String vendor) {
    final v = vendor.toLowerCase();
    return suspiciousVendors.any((s) => v.contains(s));
  }
}
