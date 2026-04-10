import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:network_info_plus/network_info_plus.dart';

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
  }) {
    state = state.copyWith(
      securityScore: score,
      deviceCount: devices,
      openPortCount: openPorts,
      suspiciousCount: suspicious,
      networkName: network,
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
    
    try {
      ssid = await info.getWifiName();
    } catch (_) {}
    
    try {
      for (var iface in await NetworkInterface.list()) {
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
    
    state = state.copyWith(
      networkName: ssid ?? (ip != null ? 'Bilinmeyen Ağ ($ip)' : 'Ağ Bağlantısı Yok'),
      routerBrand: ip != null ? 'Bağlı' : 'Bağlı Değil',
    );
  }
}

final homeProvider = StateNotifierProvider<HomeNotifier, HomeState>((ref) {
  final notifier = HomeNotifier();
  
  // İlk açılışta asenkron olarak bilgileri çek
  Future.microtask(() => notifier.initialize());
  
  return notifier;
});
