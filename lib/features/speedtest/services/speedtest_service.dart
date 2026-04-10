import 'dart:async';
import 'package:dio/dio.dart';

class SpeedtestResult {
  final double downloadMbps;
  final double uploadMbps;
  final int pingMs;

  SpeedtestResult({required this.downloadMbps, required this.uploadMbps, required this.pingMs});
}

class SpeedtestService {
  final Dio _dio = Dio();
  
  // Test dosyaları (Örnek CDN linkleri)
  static const String _downloadUrl = 'https://speed.cloudflare.com/__down?bytes=10000000'; // 10MB
  static const String _uploadUrl = 'https://httpbin.org/post';

  /// Ping testi yapar
  Future<int> measurePing() async {
    final stopwatch = Stopwatch()..start();
    try {
      await _dio.get('https://www.google.com', options: Options(receiveTimeout: const Duration(seconds: 3)));
      return stopwatch.elapsedMilliseconds;
    } catch (_) {
      return 999;
    }
  }

  /// İndirme hızını ölçer
  Stream<double> measureDownload() async* {
    final stopwatch = Stopwatch()..start();
    int receivedBytes = 0;

    try {
      final response = await _dio.get(
        _downloadUrl,
        onReceiveProgress: (count, total) {
          receivedBytes = count;
        },
        options: Options(responseType: ResponseType.bytes),
      );
      
      stopwatch.stop();
      final seconds = stopwatch.elapsedMilliseconds / 1000;
      final mbps = (receivedBytes * 8) / (seconds * 1000000);
      yield mbps;
    } catch (e) {
      yield 0.0;
    }
  }

  /// Yükleme hızını ölçer
  Stream<double> measureUpload() async* {
    final stopwatch = Stopwatch()..start();
    final data = List.generate(2000000, (index) => 0); // ~2MB dummy data

    try {
      await _dio.post(
        _uploadUrl,
        data: Stream.fromIterable([data]),
        onSendProgress: (count, total) {
          // Progress takibi yapılabilir
        },
      );
      
      stopwatch.stop();
      final seconds = stopwatch.elapsedMilliseconds / 1000;
      final mbps = (data.length * 8) / (seconds * 1000000);
      yield mbps;
    } catch (e) {
      yield 0.0;
    }
  }
}
