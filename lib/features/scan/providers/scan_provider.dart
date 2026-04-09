import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/device_model.dart';
import '../../../core/services/mac_vendor_service.dart';
import '../../../core/services/network_scanner_service.dart';
import '../../../core/utils/score_calculator.dart';
import '../../home/providers/home_provider.dart';
import '../../auth/providers/auth_provider.dart';

// Servis provider'ları
final macVendorServiceProvider = Provider((ref) => MacVendorService());
final networkScannerServiceProvider = Provider((ref) => NetworkScannerService(ref.read(macVendorServiceProvider)));

/// Scan durumu state'i
class ScanState {
  final List<DeviceModel> devices;
  final bool isScanning;
  final String subnet;
  final ScanMode currentMode;
  final String? error;

  const ScanState({
    this.devices = const [],
    this.isScanning = false,
    this.subnet = '',
    this.currentMode = ScanMode.fast,
    this.error,
  });

  ScanState copyWith({
    List<DeviceModel>? devices,
    bool? isScanning,
    String? subnet,
    ScanMode? currentMode,
    String? error,
  }) {
    return ScanState(
      devices: devices ?? this.devices,
      isScanning: isScanning ?? this.isScanning,
      subnet: subnet ?? this.subnet,
      currentMode: currentMode ?? this.currentMode,
      error: error, // Null olabilir, bu yüzden coalesce kullanmıyoruz
    );
  }
}

/// Scan Provider
class ScanNotifier extends StateNotifier<ScanState> {
  final Ref _ref;
  final NetworkScannerService _scannerService;
  StreamSubscription? _scanSubscription;

  ScanNotifier(this._ref, this._scannerService) : super(const ScanState());

  @override
  void dispose() {
    _scanSubscription?.cancel();
    super.dispose();
  }

  /// Yeni bir tarama başlat (Mevcut Stream iptal edilir)
  Future<void> startScan(ScanMode mode) async {
    // Önceki tarama varsa iptal et
    await cancelScan();

    final localIp = await _scannerService.getLocalIpAddress();
    if (localIp == null) {
      state = state.copyWith(error: 'Ağ bağlantısı bulunamadı (Yerel IP alınamadı).', isScanning: false);
      return;
    }

    final subnet = _scannerService.getSubnet(localIp) ?? '';
    state = ScanState(isScanning: true, subnet: subnet, currentMode: mode, devices: [], error: null);

    // Ana ekran homeProvider'ı bilgilendir
    _ref.read(homeProvider.notifier).setScanningState(true);

    // Premium durumunu al
    final isPremium = _ref.read(authProvider).isPremium;

    try {
      final stream = _scannerService.scanNetworkStream(subnet, mode, isPremium: isPremium);
      
      _scanSubscription = stream.listen(
        (device) {
          // Gelen cihazın isHost durumunu ayarla
          final isHost = device.ipAddress == localIp;
          final processedDevice = device.copyWith(isHost: isHost);

          // Cihaz listedeyse güncelle, yoksa ekle
          final currentList = List<DeviceModel>.from(state.devices);
          final index = currentList.indexWhere((d) => d.ipAddress == processedDevice.ipAddress);
          
          if (index >= 0) {
            currentList[index] = processedDevice;
          } else {
            currentList.add(processedDevice);
          }

          state = state.copyWith(devices: currentList);
        },
        onDone: () => _finishScan(),
        onError: (e) {
          state = state.copyWith(isScanning: false, error: 'Tarama hatası: $e');
          _ref.read(homeProvider.notifier).setScanningState(false);
        },
      );
    } catch (e) {
      state = state.copyWith(isScanning: false, error: 'Tarama başlatılamadı: $e');
      _ref.read(homeProvider.notifier).setScanningState(false);
    }
  }

  /// Taramayı manuel olarak iptal et
  Future<void> cancelScan() async {
    if (_scanSubscription != null) {
      await _scanSubscription!.cancel();
      _scanSubscription = null;
    }
    state = state.copyWith(isScanning: false);
    _ref.read(homeProvider.notifier).setScanningState(false);
  }

  /// Tarama bittiğinde HomeState ve ScoreCalculator güncellemelerini yap
  void _finishScan() {
    state = state.copyWith(isScanning: false);

    // Analiz için ScoreCalculator'ı kullan
    final openPortsCount = state.devices.fold<int>(0, (sum, dev) => sum + dev.openPorts.length);
    final suspiciousCount = state.devices.where((d) => d.openPorts.isNotEmpty).length;

    List<int> allPorts = [];
    for(var d in state.devices) { allPorts.addAll(d.openPorts); }
    
    // Gerçek skor hesabı
    int customScore = ScoreCalculator.calculate(
      vendors: state.devices.map((d) => d.vendorName).toList(),
      highRiskPorts: allPorts, // Şimdilik basitleştirilmiş
      mediumRiskPorts: [],
      unknownDeviceCount: suspiciousCount,
      hasTelnet: allPorts.contains(23),
      hasDefaultRouterIp: false,
      isOpenWifi: false,
    ).score;

    // HomeProvider'ı güncelle
    _ref.read(homeProvider.notifier).updateScanResults(
      score: customScore,
      devices: state.devices.length,
      openPorts: openPortsCount,
      suspicious: suspiciousCount,
      network: state.subnet.isNotEmpty ? '${state.subnet}.X' : 'Bilinmeyen Ağ',
    );
  }
}

final scanProvider = StateNotifierProvider<ScanNotifier, ScanState>((ref) {
  return ScanNotifier(
    ref,
    ref.read(networkScannerServiceProvider),
  );
});
