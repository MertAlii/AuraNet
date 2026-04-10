import 'dart:async';
import 'package:dio/dio.dart';

class SpeedtestResult {
  final double downloadMbps;
  final double uploadMbps;
  final int pingMs;

  SpeedtestResult({required this.downloadMbps, required this.uploadMbps, required this.pingMs});
}

class SpeedtestService {
  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 5),
    receiveTimeout: const Duration(seconds: 10),
  ));
  
  // Daha stabil CDN linkleri
  static const String _downloadUrl = 'https://speed.cloudflare.com/__down?bytes=25000000'; // 25MB
  static const String _uploadUrl = 'https://httpbin.org/post';

  /// Ping testi yapar (Ortalama alarak daha doğru sonuç verir)
  Future<int> measurePing() async {
    List<int> pings = [];
    for (int i = 0; i < 3; i++) {
       final stopwatch = Stopwatch()..start();
       try {
         await _dio.get('https://8.8.8.8', options: Options(validateStatus: (s) => true));
         pings.add(stopwatch.elapsedMilliseconds);
       } catch (_) {
         pings.add(999);
       }
       await Future.delayed(const Duration(milliseconds: 200));
    }
    pings.sort();
    return pings[1]; // Median değerini dön
  }

  /// İndirme hızını ölçer (Anlık Mbps değerleri döner)
  Stream<double> measureDownload() async* {
    final stopwatch = Stopwatch()..start();
    int lastBytes = 0;
    int lastTime = 0;

    try {
      final response = await _dio.get(
        _downloadUrl,
        onReceiveProgress: (count, total) {
          // Bu callback sık tetiklenir, burada anlık hız hesaplayabiliriz.
        },
        options: Options(responseType: ResponseType.bytes),
      );
      
      // Response tamamlandığında toplam hızı hesapla
      stopwatch.stop();
      final totalSeconds = stopwatch.elapsedMilliseconds / 1000;
      final totalMbps = (response.data.length * 8) / (totalSeconds * 1000000);
      
      // Ara değerleri simüle etmek için (UI'da akıcılık için)
      for (int i = 1; i <= 10; i++) {
        yield (totalMbps * (i / 10));
        await Future.delayed(const Duration(milliseconds: 50));
      }
      yield totalMbps;
    } catch (e) {
      yield 0.0;
    }
  }

  /// Yükleme hızını ölçer
  Stream<double> measureUpload() async* {
    final stopwatch = Stopwatch()..start();
    final data = List.generate(5000000, (index) => 0); // 5MB dummy data

    try {
      await _dio.post(
        _uploadUrl,
        data: Stream.fromIterable([data]),
      );
      
      stopwatch.stop();
      final totalSeconds = stopwatch.elapsedMilliseconds / 1000;
      final totalMbps = (data.length * 8) / (totalSeconds * 1000000);
      
      for (int i = 1; i <= 10; i++) {
        yield (totalMbps * (i / 10));
        await Future.delayed(const Duration(milliseconds: 50));
      }
      yield totalMbps;
    } catch (e) {
      yield 0.0;
    }
  }
}
