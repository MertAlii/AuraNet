import 'package:dio/dio.dart';

/// Mac Vendor API'sini kullanarak MAC adresinden cihaz üreticisini bulur.
class MacVendorService {
  final Dio _dio;

  // En ünlü vendorların OUI (İlk 3 byte) MAC adresleri - API çökerse yerel kontrol
  static const Map<String, String> _localMacVendors = {
    // --- Akıllı Telefonlar ve Bilgisayarlar ---
    // Apple
    'F8:8A:5E': 'Apple', '00:25:00': 'Apple', 'CC:20:E8': 'Apple', 
    '40:B0:FA': 'Apple', '00:1E:52': 'Apple', '04:0C:CE': 'Apple', 
    '10:93:E9': 'Apple', '14:20:5E': 'Apple', '00:1F:5B': 'Apple',
    '34:C4:66': 'Apple', '60:FB:42': 'Apple', 'AC:87:A3': 'Apple',
    // Samsung
    '1C:36:BB': 'Samsung', '00:07:AB': 'Samsung', '88:32:9B': 'Samsung',
    '00:15:99': 'Samsung', '04:FE:31': 'Samsung', '10:1D:C0': 'Samsung',
    '14:89:FD': 'Samsung', '18:22:7E': 'Samsung', '2C:44:01': 'Samsung',
    // Google
    '00:1A:11': 'Google', '3C:5A:B4': 'Google', 'F8:8F:CA': 'Google', 
    '1A:11:00': 'Google', 'F0:03:8C': 'Google', '70:EF:00': 'Google',
    // Xiaomi
    '2C:D0:5A': 'Xiaomi', '38:A4:ED': 'Xiaomi', '50:8A:06': 'Xiaomi',
    '00:9E:C8': 'Xiaomi', '14:F6:5A': 'Xiaomi', '64:09:80': 'Xiaomi',
    // Huawei
    '20:F4:1B': 'Huawei', 'E8:CD:2D': 'Huawei', '00:1E:10': 'Huawei',
    '00:46:4B': 'Huawei', '0C:96:E6': 'Huawei', '10:47:80': 'Huawei',
    // Diğer Markalar
    '00:1C:62': 'LG', '00:1E:B2': 'LG',
    '00:23:76': 'HTC', '00:0B:0D': 'HTC',
    '00:01:A0': 'OnePlus', 'C0:EE:FB': 'OnePlus',
    '00:1E:73': 'ZTE', '00:15:EB': 'ZTE',
    // --- Ağ Kartları ve Bilgisayar Donanımları ---
    // Intel (Çoğu PC Wi-Fi Kartı)
    '00:02:B3': 'Intel', '00:11:11': 'Intel', '00:13:E8': 'Intel',
    '00:15:00': 'Intel', '00:1C:C0': 'Intel', '08:11:96': 'Intel',
    // Realtek & Broadcom (Çoğu Ethernet/Wi-Fi Çipi)
    '00:E0:4C': 'Realtek', '00:14:D1': 'Realtek', '52:54:00': 'Realtek',
    '00:10:18': 'Broadcom', '00:11:22': 'Broadcom',
    // Dell, Lenovo, HP
    '00:14:22': 'Dell', '00:11:43': 'Dell', '00:21:70': 'Dell',
    '00:12:FE': 'Lenovo', '00:50:8D': 'Lenovo', '50:3E:AA': 'Lenovo',
    '00:0E:7F': 'HP', '00:11:0A': 'HP', '00:15:60': 'HP',
    // --- Ağ Cihazları (Router, Switch, Access Point) ---
    // TP-Link
    '50:C7:BF': 'TP-Link', 'C0:25:E9': 'TP-Link', '00:0A:EB': 'TP-Link',
    '14:CC:20': 'TP-Link', 'A0:F3:C1': 'TP-Link', 'F4:F2:6D': 'TP-Link',
    // Asus
    '1C:3B:F3': 'Asus', '50:46:5D': 'Asus', '04:D4:C4': 'Asus', 
    '08:60:6E': 'Asus', '10:7B:44': 'Asus', '14:DD:A9': 'Asus',
    // Ubiquiti (Unifi)
    '00:15:6D': 'Ubiquiti', '04:18:D6': 'Ubiquiti', '24:A4:3C': 'Ubiquiti',
    '44:D9:E7': 'Ubiquiti', '68:72:51': 'Ubiquiti', '80:2A:A8': 'Ubiquiti',
    'B4:FB:E4': 'Ubiquiti', 'F0:9F:C2': 'Ubiquiti',
    // Cisco
    '00:25:9C': 'Cisco', '00:00:0C': 'Cisco', '00:01:42': 'Cisco',
    '00:01:43': 'Cisco', '00:01:63': 'Cisco', '00:01:64': 'Cisco',
    // Netgear & MikroTik & Diğerleri
    'C4:04:15': 'Netgear', '00:09:5B': 'Netgear', '00:14:6C': 'Netgear',
    'E4:8D:8C': 'MikroTik', '00:0C:42': 'MikroTik', 'CC:2D:E0': 'MikroTik',
    'C8:3A:35': 'Tenda', '04:95:E6': 'Tenda',
    '00:A0:C5': 'Zyxel', '4C:9E:FF': 'Zyxel',
    // --- Oyun Konsolları ve Medya Cihazları ---
    // Sony (PlayStation vb.)
    '00:01:4A': 'Sony', '00:0A:16': 'Sony', '00:13:A9': 'Sony',
    '00:1D:BA': 'Sony', '00:24:8E': 'Sony', 'F8:D0:AC': 'Sony',
    // Microsoft (Xbox vb.)
    '00:03:FF': 'Microsoft', '00:0D:3A': 'Microsoft', '00:12:5A': 'Microsoft',
    '00:15:5D': 'Microsoft', '00:1D:D8': 'Microsoft', '00:22:48': 'Microsoft',
    '00:50:F2': 'Microsoft', '28:18:78': 'Microsoft',
    // Nintendo
    '00:09:BF': 'Nintendo', '00:16:56': 'Nintendo', '00:17:AB': 'Nintendo',
    '00:19:F3': 'Nintendo', '00:1A:E9': 'Nintendo', '00:1B:7A': 'Nintendo',
    '00:1C:BE': 'Nintendo', '00:1E:35': 'Nintendo', '00:1F:32': 'Nintendo',
    '00:21:47': 'Nintendo', '00:22:4C': 'Nintendo', '00:22:AA': 'Nintendo',
    '00:23:CC': 'Nintendo', '00:24:1E': 'Nintendo', '00:24:44': 'Nintendo',
    // Amazon (Echo, Kindle, Fire)
    '04:A2:22': 'Amazon', '44:65:0D': 'Amazon', '00:FC:8B': 'Amazon',
    '0C:47:C9': 'Amazon', '18:74:2E': 'Amazon', '34:D2:70': 'Amazon',
    // --- IoT (Nesnelerin İnterneti) ve Geliştirme Kartları ---
    // Espressif (ESP8266 / ESP32 - Akıllı priz, ampul, vb. çok yaygındır)
    '18:FE:34': 'Espressif (IoT)', '24:0A:C4': 'Espressif (IoT)', 
    '24:62:AB': 'Espressif (IoT)', '30:AE:A4': 'Espressif (IoT)',
    '3C:71:BF': 'Espressif (IoT)', '4C:11:AE': 'Espressif (IoT)',
    '5C:CF:7F': 'Espressif (IoT)', '80:7D:3A': 'Espressif (IoT)',
    '84:0D:8E': 'Espressif (IoT)', 'A0:20:A6': 'Espressif (IoT)',
    'BC:DD:C2': 'Espressif (IoT)', 'C8:2B:96': 'Espressif (IoT)',
    // Raspberry Pi
    'DC:A6:32': 'Raspberry Pi', 'B8:27:EB': 'Raspberry Pi', '28:CD:C1': 'Raspberry Pi',
    'D8:3A:DD': 'Raspberry Pi', 'E4:5F:01': 'Raspberry Pi',
    // --- Sanallaştırma (Sanal Makineler) ---
    // VMware
    '00:50:56': 'VMware', '00:0C:29': 'VMware', '00:05:69': 'VMware', '00:1C:14': 'VMware',
    // Oracle VirtualBox
    '08:00:27': 'Oracle VirtualBox',
  };

  MacVendorService() : _dio = Dio() {
    _dio.options.receiveTimeout = const Duration(seconds: 3);
    _dio.options.connectTimeout = const Duration(seconds: 3);
  }

  /// MAC Adresini API'ye sorarak Vendor adını döndürür
  /// Eğer API cevap vermezse yerel küçük listeden offline check yapar.
  Future<String> getVendor(String macAddress) async {
    if (macAddress.isEmpty || macAddress == '00:00:00:00:00:00') {
      return 'Bilinmiyor';
    }

    // 1. Önce Offline Listemizi kontrol et (OUI ilk 3 byte)
    // Örn MAC: 00:1A:11:xx:xx:xx -> 00:1A:11
    if (macAddress.length >= 8) {
      final prefix = macAddress.substring(0, 8).toUpperCase();
      if (_localMacVendors.containsKey(prefix)) {
        return _localMacVendors[prefix]!;
      }
    }

    // 2. Doğrudan api.macvendors.com'a sor
    try {
      final response = await _dio.get('https://api.macvendors.com/$macAddress');
      if (response.statusCode == 200 && response.data != null) {
        return response.data.toString();
      }
    } catch (e) {
      // API Rate limit'e takıldıysa veya internet yoksa sessizce geç
      return 'Bilinmiyor';
    }
    
    return 'Bilinmiyor';
  }
}
