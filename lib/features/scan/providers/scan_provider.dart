import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/device_model.dart';
import '../../../core/services/mac_vendor_service.dart';
import '../../../core/services/network_scanner_service.dart';
import '../../../core/utils/score_calculator.dart';
import '../../home/providers/home_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../core/services/hive_service.dart';
import '../../../core/services/firestore_service.dart';
import '../../../core/services/notification_service.dart';

// Servis provider'ları
final macVendorServiceProvider = Provider((ref) => MacVendorService());
final networkScannerServiceProvider = Provider((ref) => NetworkScannerService(ref.read(macVendorServiceProvider)));

/// Scan durumu state'i
class ScanState {
  final List<DeviceModel> devices;
  final bool isScanning;
  final String subnet;
  final ScanMode currentMode;
  final double progress;
  final String? error;

  const ScanState({
    this.devices = const [],
    this.isScanning = false,
    this.subnet = '',
    this.currentMode = ScanMode.fast,
    this.progress = 0.0,
    this.error,
  });

  ScanState copyWith({
    List<DeviceModel>? devices,
    bool? isScanning,
    String? subnet,
    ScanMode? currentMode,
    double? progress,
    String? error,
  }) {
    return ScanState(
      devices: devices ?? this.devices,
      isScanning: isScanning ?? this.isScanning,
      subnet: subnet ?? this.subnet,
      currentMode: currentMode ?? this.currentMode,
      progress: progress ?? this.progress,
      error: error,
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

  /// Taramayı başlat
  Future<void> startScan(ScanMode mode) async {
    // Önceki tarama varsa iptal et
    await cancelScan();

    final localIp = await _scannerService.getLocalIpAddress();
    if (localIp == null) {
      state = state.copyWith(error: 'Ağ bağlantısı bulunamadı (Yerel IP alınamadı).', isScanning: false);
      return;
    }

    final subnet = _scannerService.getSubnet(localIp) ?? '';
    state = ScanState(isScanning: true, subnet: subnet, currentMode: mode, devices: [], error: null, progress: 0.1);

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

          // 3. Hive'dan yerel etiketleri (İsim, Emoji, Favori) yükle
          final label = HiveService.getDeviceLabel(processedDevice.macAddress);
          DeviceModel finalDevice = processedDevice;
          if (label != null) {
            finalDevice = processedDevice.copyWith(
              deviceName: label['customName'] ?? processedDevice.deviceName,
              customEmoji: label['customEmoji'],
              isFavorite: label['isFavorite'] ?? false,
            );
          } else if (processedDevice.deviceName == 'Bilinmeyen Cihaz' || processedDevice.deviceName == processedDevice.ipAddress) {
             // Eğer hostname bulunamadıysa ama Hive'da etiket yoksa IP'yi isim olarak gösterelim (Daha modern)
             finalDevice = processedDevice.copyWith(deviceName: processedDevice.ipAddress);
          }

          // Cihaz listedeyse güncelle, yoksa ekle
          final currentList = List<DeviceModel>.from(state.devices);
          final index = currentList.indexWhere((d) => d.ipAddress == finalDevice.ipAddress);
          
          if (index >= 0) {
            currentList[index] = finalDevice;
          } else {
            currentList.add(finalDevice);
          }

          // Progress hesapla (Basit simülasyon)
          double newProgress = state.progress + 0.01;
          if (newProgress > 0.95) newProgress = 0.95;

          state = state.copyWith(devices: currentList, progress: newProgress);

          // Yeni cihaz kontrolü (Eğer tarama bitmediyse ve yeni cihaz eklendiyse)
          if (index < 0 && !finalDevice.isHost) {
            _checkAndNotifyNewDevice(finalDevice);
          }
        },
        onDone: () => _finishScan(),
        onError: (e) {
          state = state.copyWith(isScanning: false, error: 'Tarama hatası: $e', progress: 0.0);
          _ref.read(homeProvider.notifier).setScanningState(false);
        },
      );
    } catch (e) {
      state = state.copyWith(isScanning: false, error: 'Tarama başlatılamadı: $e', progress: 0.0);
      _ref.read(homeProvider.notifier).setScanningState(false);
    }
  }

  /// Taramayı manuel olarak iptal et
  Future<void> cancelScan() async {
    if (_scanSubscription != null) {
      await _scanSubscription!.cancel();
      _scanSubscription = null;
    }
    state = state.copyWith(isScanning: false, progress: 0.0);
    _ref.read(homeProvider.notifier).setScanningState(false);
  }

  /// Tarama bittiğinde istatistikleri ve geçmişi kaydet
  Future<void> _finishScan() async {
    state = state.copyWith(isScanning: false, progress: 1.0);

    // Analiz için ScoreCalculator'ı kullan
    final openPortsCount = state.devices.fold<int>(0, (sum, dev) => sum + dev.openPorts.length);
    final suspiciousCount = state.devices.where((d) => d.openPorts.isNotEmpty).length;

    List<int> allPorts = [];
    for(var d in state.devices) { allPorts.addAll(d.openPorts); }
    
    // Gerçek skor hesabı
    int customScore = ScoreCalculator.calculate(
      vendors: state.devices.map((d) => d.vendorName).toList(),
      highRiskPorts: allPorts,
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

    // Yerel geçmişe kaydet
    final auth = _ref.read(authProvider);
    if (auth.user != null) {
      await HiveService.saveScanResult({
        'networkName': state.subnet.isNotEmpty ? '${state.subnet}.X' : 'Bilinmeyen Ağ',
        'securityScore': customScore,
        'deviceCount': state.devices.length,
        'suspiciousCount': suspiciousCount,
        'openPortCount': openPortsCount,
        'devices': state.devices.map((d) => {
          'ip': d.ipAddress,
          'name': d.deviceName,
          'vendor': d.vendorName,
          'ports': d.openPorts,
        }).toList(),
      });
    }
  }

  /// Yeni cihaz tespiti ve bildirimi
  void _checkAndNotifyNewDevice(DeviceModel device) {
    final isPremium = _ref.read(authProvider).isPremium;
    if (!isPremium) return; 

    NotificationService.showNotification(
      id: device.ipAddress.hashCode,
      title: 'Yeni Cihaz Bağlandı!',
      body: '${device.deviceName} (${device.ipAddress}) ağınıza az önce katıldı.',
    );
  }
}

final scanProvider = StateNotifierProvider<ScanNotifier, ScanState>((ref) {
  return ScanNotifier(
    ref,
    ref.read(networkScannerServiceProvider),
  );
});
