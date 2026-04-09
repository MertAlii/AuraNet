import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/wifi_analyzer_service.dart';
import '../models/wifi_network_model.dart';

final wifiAnalyzerProvider = StateNotifierProvider<WiFiAnalyzerNotifier, WiFiAnalyzerState>((ref) {
  return WiFiAnalyzerNotifier(WiFiAnalyzerService());
});

class WiFiAnalyzerState {
  final List<WiFiNetworkModel> networks;
  final bool isScanning;
  final String? error;

  WiFiAnalyzerState({
    this.networks = const [],
    this.isScanning = false,
    this.error,
  });

  WiFiAnalyzerState copyWith({
    List<WiFiNetworkModel>? networks,
    bool? isScanning,
    String? error,
  }) {
    return WiFiAnalyzerState(
      networks: networks ?? this.networks,
      isScanning: isScanning ?? this.isScanning,
      error: error,
    );
  }
}

class WiFiAnalyzerNotifier extends StateNotifier<WiFiAnalyzerState> {
  final WiFiAnalyzerService _service;
  Timer? _timer;

  WiFiAnalyzerNotifier(this._service) : super(WiFiAnalyzerState());

  Future<void> startContinuousScan() async {
    state = state.copyWith(isScanning: true);
    // İlk taramayı yap
    await _performScan();
    
    // Periyodik tarama (Her 5 saniyede bir)
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) => _performScan());
  }

  void stopScan() {
    _timer?.cancel();
    state = state.copyWith(isScanning: false);
  }

  Future<void> _performScan() async {
    try {
      final results = await _service.scanNearbyNetworks();
      state = state.copyWith(networks: results);
    } catch (e) {
      state = state.copyWith(error: 'Tarama başarısız: $e');
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
