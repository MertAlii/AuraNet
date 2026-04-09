/// IP adresi yardımcı fonksiyonları
class IpUtils {
  IpUtils._();

  /// Gateway IP'den taranacak IP aralığını hesapla
  /// Örnek: 192.168.1.1 → [192.168.1.1, 192.168.1.2, ..., 192.168.1.254]
  static List<String> calculateIpRange(String gatewayIp, {String subnetMask = '255.255.255.0'}) {
    final List<String> ips = [];
    final parts = gatewayIp.split('.');
    if (parts.length != 4) return ips;

    final maskParts = subnetMask.split('.');
    if (maskParts.length != 4) return ips;

    // Basit hesaplama: Son oktet değişir (tipik ev ağı /24)
    final prefix = '${parts[0]}.${parts[1]}.${parts[2]}';
    for (int i = 1; i <= 254; i++) {
      ips.add('$prefix.$i');
    }
    return ips;
  }

  /// IP adresi geçerli mi?
  static bool isValidIp(String ip) {
    final parts = ip.split('.');
    if (parts.length != 4) return false;
    for (final part in parts) {
      final n = int.tryParse(part);
      if (n == null || n < 0 || n > 255) return false;
    }
    return true;
  }

  /// Gateway IP mi?
  static bool isGateway(String ip) {
    return ip.endsWith('.1') || ip.endsWith('.254');
  }

  /// Loopback IP mi?
  static bool isLoopback(String ip) {
    return ip.startsWith('127.');
  }

  /// Private IP mi?
  static bool isPrivateIp(String ip) {
    final parts = ip.split('.');
    if (parts.length != 4) return false;
    final first = int.parse(parts[0]);
    final second = int.parse(parts[1]);

    // 10.0.0.0/8
    if (first == 10) return true;
    // 172.16.0.0/12
    if (first == 172 && second >= 16 && second <= 31) return true;
    // 192.168.0.0/16
    if (first == 192 && second == 168) return true;

    return false;
  }
}
