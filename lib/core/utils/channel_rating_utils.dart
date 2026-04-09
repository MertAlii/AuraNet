import '../../features/analyzer/models/wifi_network_model.dart';

class ChannelRatingResult {
  final int channel;
  final double score; // 0-10
  final int overlappingCount;

  ChannelRatingResult({
    required this.channel,
    required this.score,
    required this.overlappingCount,
  });
}

class ChannelRatingUtils {
  
  /// Verilen ağ listesine göre kanalları puanlar.
  /// Sadece 1-13 arası (2.4GHz) için örnekleme yapılmıştır.
  static List<ChannelRatingResult> rateChannels(List<WiFiNetworkModel> networks) {
    final List<ChannelRatingResult> ratings = [];

    // 2.4GHz kanalları: 1'den 13'e
    for (int channel = 1; channel <= 13; channel++) {
      final overlapping = networks.where((n) {
        // Bir kanal kendisinden +- 2 kanal uzağa kadar etki eder (20MHz genişlikte)
        return (n.channel - channel).abs() <= 2 && n.band == "2.4 GHz";
      }).toList();

      double score = 10.0;
      
      for (var network in overlapping) {
        // Sinyal gücüne göre puan kır
        // -50 ve üstü (çok güçlü): -3 puan
        // -70 ve üstü (orta): -1.5 puan
        // -90 ve üstü (zayıf): -0.5 puan
        if (network.level >= -50) {
          score -= 3.0;
        } else if (network.level >= -70) {
          score -= 1.5;
        } else {
          score -= 0.5;
        }
      }

      ratings.add(ChannelRatingResult(
        channel: channel,
        score: score.clamp(1.0, 10.0), // En düşük 1 puan
        overlappingCount: overlapping.length,
      ));
    }

    // Puanı en yüksek olan (en temiz) kanalları en başa al
    ratings.sort((a, b) => b.score.compareTo(a.score));
    
    return ratings;
  }
}
