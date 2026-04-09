/// MAC adresi yardımcı fonksiyonları
class MacUtils {
  MacUtils._();

  /// MAC adresini standart formata çevir (XX:XX:XX:XX:XX:XX)
  static String formatMac(String mac) {
    final clean = mac.replaceAll(RegExp(r'[^a-fA-F0-9]'), '').toUpperCase();
    if (clean.length != 12) return mac.toUpperCase();

    return [
      clean.substring(0, 2),
      clean.substring(2, 4),
      clean.substring(4, 6),
      clean.substring(6, 8),
      clean.substring(8, 10),
      clean.substring(10, 12),
    ].join(':');
  }

  /// MAC adresi geçerli mi?
  static bool isValidMac(String mac) {
    final clean = mac.replaceAll(RegExp(r'[^a-fA-F0-9]'), '');
    return clean.length == 12;
  }

  /// MAC adresinin OUI kısmını al (ilk 3 byte)
  static String getOui(String mac) {
    final formatted = formatMac(mac);
    return formatted.substring(0, 8); // XX:XX:XX
  }

  /// Rastgele / sanal MAC mi? (LAA bit kontrolü)
  static bool isRandomizedMac(String mac) {
    final clean = mac.replaceAll(RegExp(r'[^a-fA-F0-9]'), '').toUpperCase();
    if (clean.length < 2) return false;
    final secondNibble = int.parse(clean[1], radix: 16);
    // LAA bit (bit 1 of first octet) set ise MAC rastgele
    return (secondNibble & 0x2) != 0;
  }

  /// Broadcast MAC mi?
  static bool isBroadcast(String mac) {
    final formatted = formatMac(mac);
    return formatted == 'FF:FF:FF:FF:FF:FF';
  }
}
