import 'package:flutter_riverpod/flutter_riverpod.dart';

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
}

final homeProvider = StateNotifierProvider<HomeNotifier, HomeState>((ref) {
  return HomeNotifier();
});
