import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/hive_service.dart';
import '../services/speedtest_service.dart';

class SpeedtestState {
  final bool isTesting;
  final String phase;
  final double ping;
  final double download;
  final double upload;
  final double currentValue;

  SpeedtestState({
    this.isTesting = false,
    this.phase = 'Hazır',
    this.ping = 0,
    this.download = 0,
    this.upload = 0,
    this.currentValue = 0,
  });

  SpeedtestState copyWith({
    bool? isTesting,
    String? phase,
    double? ping,
    double? download,
    double? upload,
    double? currentValue,
  }) {
    return SpeedtestState(
      isTesting: isTesting ?? this.isTesting,
      phase: phase ?? this.phase,
      ping: ping ?? this.ping,
      download: download ?? this.download,
      upload: upload ?? this.upload,
      currentValue: currentValue ?? this.currentValue,
    );
  }
}

class SpeedtestNotifier extends StateNotifier<SpeedtestState> {
  final SpeedtestService _service = SpeedtestService();

  SpeedtestNotifier() : super(SpeedtestState());

  Future<void> startTest() async {
    state = SpeedtestState(isTesting: true, phase: 'Ping Ölçülüyor...');
    
    // 1. Ping
    final pingVal = await _service.measurePing();
    state = state.copyWith(ping: pingVal.toDouble(), phase: 'İndirme Testi...');

    // 2. Download
    await for (final mbps in _service.measureDownload()) {
      state = state.copyWith(download: mbps, currentValue: mbps);
    }

    state = state.copyWith(phase: 'Yükleme Testi...', currentValue: 0);

    // 3. Upload
    await for (final mbps in _service.measureUpload()) {
      state = state.copyWith(upload: mbps, currentValue: mbps);
    }

    state = state.copyWith(isTesting: false, phase: 'Tamamlandı', currentValue: 0);

    // Sonuçları Hive'a kaydet
    await HiveService.saveSpeedtestResult({
      'ping': state.ping,
      'download': state.download,
      'upload': state.upload,
      'network': state.phase, // Ağ ismi eklenebilir
    });
  }
}

final speedtestProvider = StateNotifierProvider<SpeedtestNotifier, SpeedtestState>((ref) {
  return SpeedtestNotifier();
});
