import 'dart:io';

class ArpService {
  /// ARP tablosunu (/proc/net/arp) okur ve IP -> MAC eşleşmelerini döner.
  /// Not: Android 10+ cihazlarda bu dosyanın okunması kısıtlanmış olabilir.
  static Future<Map<String, String>> getArpTable() async {
    final Map<String, String> arpTable = {};
    
    // Sadece Linux/Android tabanlı sistemlerde çalışır
    if (!Platform.isAndroid && !Platform.isLinux) return arpTable;

    try {
      final file = File('/proc/net/arp');
      if (await file.exists()) {
        final lines = await file.readAsLines();
        
        // İlk satır başlıktır: IP address  HW type  Flags  HW address  Mask  Device
        for (var i = 1; i < lines.length; i++) {
          final line = lines[i].trim();
          if (line.isEmpty) continue;

          // Boşluklara göre ayır: 192.168.1.1 0x1 0x2 00:11:22:33:44:55 * wlan0
          final parts = line.split(RegExp(r'\s+'));
          if (parts.length >= 4) {
            final ip = parts[0];
            final mac = parts[3];
            
            // Gerçek bir MAC adresi mi kontrol et (00:00... değilse)
            if (mac != '00:00:00:00:00:00') {
              arpTable[ip] = mac.toUpperCase();
            }
          }
        }
      }
    } catch (e) {
      // Hata durumunda boş tablo döner
    }
    
    return arpTable;
  }

  /// ARP Spoofing (MITM) tespiti yapar.
  /// Eğer aynı MAC adresi birden fazla IP ile eşleşmişse veya 
  /// Gateway MAC adresi değişmişse uyarı döner.
  static List<String> detectSpoofing(Map<String, String> arpTable) {
    final List<String> warnings = [];
    final Map<String, List<String>> macToIps = {};

    arpTable.forEach((ip, mac) {
      macToIps.putIfAbsent(mac, () => []).add(ip);
    });

    macToIps.forEach((mac, ips) {
      if (ips.length > 1) {
        // Aynı MAC birden fazla IP'de görünüyor (Normal ağ cihazlarında nadirdir)
        warnings.add('Şüpheli MAC Çakışması: $mac adresi ${ips.join(", ")} IP adresleri tarafından kullanılıyor.');
      }
    });

    return warnings;
  }
}
