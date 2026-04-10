import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:network_info_plus/network_info_plus.dart';
import '../../../core/services/hive_service.dart';

/// Ana ekran state
class HomeState {
  final int securityScore;
  final int deviceCount;
  final int openPortCount;
  final int suspiciousCount;
  final double lastDownloadSpeed;
  final double lastUploadSpeed;
  final bool isScanning;
  final String? networkName;
  final String? routerBrand;
  final String? aiRecommendation;

  const HomeState({
    this.securityScore = 0,
    this.deviceCount = 0,
    this.openPortCount = 0,
    this.suspiciousCount = 0,
    this.lastDownloadSpeed = 0,
    this.lastUploadSpeed = 0,
    this.isScanning = false,
    this.networkName,
    this.routerBrand,
    this.aiRecommendation,
  });

  HomeState copyWith({
    int? securityScore,
    int? deviceCount,
    int? openPortCount,
    int? suspiciousCount,
    double? lastDownloadSpeed,
    double? lastUploadSpeed,
    bool? isScanning,
    String? networkName,
    String? routerBrand,
    String? aiRecommendation,
  }) {
    return HomeState(
      securityScore: securityScore ?? this.securityScore,
      deviceCount: deviceCount ?? this.deviceCount,
      openPortCount: openPortCount ?? this.openPortCount,
      suspiciousCount: suspiciousCount ?? this.suspiciousCount,
      lastDownloadSpeed: lastDownloadSpeed ?? this.lastDownloadSpeed,
      lastUploadSpeed: lastUploadSpeed ?? this.lastUploadSpeed,
      isScanning: isScanning ?? this.isScanning,
      networkName: networkName ?? this.networkName,
      routerBrand: routerBrand ?? this.routerBrand,
      aiRecommendation: aiRecommendation ?? this.aiRecommendation,
    );
  }
}

/// Ana ekran provider
class HomeNotifier extends StateNotifier<HomeState> {
  HomeNotifier() : super(const HomeState());

  /// Tarama asıl olarak ScanProvider tarafından tetiklenecek, 
  /// HomeScreen'de UI durumu için UI'ın start fonksiyonu değişecek.
  // startScan is now managed by ScanProvider, but we provide methods for it to update HomeState
  
  void setScanningState(bool isScanning) {
    state = state.copyWith(isScanning: isScanning);
  }

  void updateScanResults({
    required int score,
    required int devices,
    required int openPorts,
    required int suspicious,
    String? network,
    String? aiRec,
  }) {
    state = state.copyWith(
      securityScore: score,
      deviceCount: devices,
      openPortCount: openPorts,
      suspiciousCount: suspicious,
      networkName: network,
      aiRecommendation: aiRec,
    );
  }

  /// Ağ bilgilerini güncelle
  void updateNetworkInfo(String? name, String? brand) {
    state = state.copyWith(networkName: name, routerBrand: brand);
  }

  /// Uygulama açılışında verileri temizle/başlat
  Future<void> initialize() async {
    final info = NetworkInfo();
    String? ssid;
    String? ip;
    
    // 1. Ağ bilgilerini al
    try {
      ssid = await info.getWifiName();
    } catch (_) {}
    
    try {
      final interfaces = await NetworkInterface.list();
      for (var iface in interfaces) {
        for (var addr in iface.addresses) {
          if (addr.type == InternetAddressType.IPv4 && !addr.isLoopback) {
            if (addr.address.startsWith('192.168.') || addr.address.startsWith('10.') || addr.address.startsWith('172.')) {
              ip = addr.address;
              break;
            }
          }
        }
        if (ip != null) break;
      }
    } catch (_) {}
    
    // 2. Hive'dan en son başarılı tarama sonucunu yükle
    final history = HiveService.getScanHistory();
    if (history.isNotEmpty) {
      final lastScan = history.first; // En yeni en başta (getScanHistory sıralıyor)
      state = state.copyWith(
        securityScore: lastScan['securityScore'] ?? 0,
        deviceCount: lastScan['deviceCount'] ?? 0,
        openPortCount: lastScan['openPortCount'] ?? 0,
        suspiciousCount: lastScan['suspiciousCount'] ?? 0,
        networkName: ssid ?? lastScan['networkName'],
        routerBrand: 'Bağlı',
      );
    } else {
      state = state.copyWith(
        networkName: ssid ?? (ip != null ? 'Bilinmeyen Ağ ($ip)' : 'Ağ Bağlantısı Yok'),
        routerBrand: ip != null ? 'Bağlı' : 'Bağlı Değil',
      );
    }
  }
}

final homeProvider = StateNotifierProvider<HomeNotifier, HomeState>((ref) {
  final notifier = HomeNotifier();
  
  // İlk açılışta asenkron olarak bilgileri çek
  Future.microtask(() => notifier.initialize());
  
  return notifier;
});
