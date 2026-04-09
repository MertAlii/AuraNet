import 'dart:async';
import 'package:wifi_scan/wifi_scan.dart';
import '../utils/wifi_calc_utils.dart';
import '../../features/analyzer/models/wifi_network_model.dart';

class WiFiAnalyzerService {
  
  /// Çevredeki Wi-Fi ağlarını tarar ve sonuçları model listesi olarak döner.
  Future<List<WiFiNetworkModel>> scanNearbyNetworks() async {
    // 1. Tarama başlatılabiliyor mu kontrol et
    final canStartScan = await WiFiScan.instance.canStartScan();
    if (canStartScan != CanStartScan.yes) {
      // Hata durumunda boş liste (Veya hata fırlatılabilir)
      return [];
    }

    // 2. Taramayı başlat
    await WiFiScan.instance.startScan();

    // 3. Sonuçları al (Genelde tarama bittikten sonra alınır ancak 
    // wifi_scan doğrudan son önbelleğe alınmış sonuçları da döndürebilir)
    final canGetResults = await WiFiScan.instance.canGetScannedResults();
    if (canGetResults != CanGetScannedResults.yes) {
      return [];
    }

    final results = await WiFiScan.instance.getScannedResults();
    
    // 4. Sonuçları modele dönüştür
    return results.map((network) {
      return WiFiNetworkModel(
        ssid: network.ssid,
        bssid: network.bssid,
        level: network.level,
        frequency: network.frequency,
        capabilities: network.capabilities,
        timestamp: DateTime.now(),
        distance: WiFiCalcUtils.calculateDistance(network.frequency, network.level),
        signalLevel: WiFiCalcUtils.calculateSignalLevel(network.level),
        band: WiFiCalcUtils.getWiFiBand(network.frequency),
        channel: WiFiCalcUtils.getChannelFromFrequency(network.frequency),
      );
    }).toList();
  }

  /// Tarama sonuçlarını bir stream olarak takip etmek için (Opsiyonel)
  Stream<List<WiFiNetworkModel>> get onScannedResults => 
    WiFiScan.instance.onScannedResultsAvailable.asyncMap((_) => scanNearbyNetworks());
}
