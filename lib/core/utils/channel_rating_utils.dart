import '../../features/analyzer/models/wifi_network_model.dart';

class ChannelRatingResult {
  final int channel;
  final double score; // 0-10
  final int overlappingCount;
  final List<String> overlappingNetworks;
  final String band;

  ChannelRatingResult({
    required this.channel,
    required this.score,
    required this.overlappingCount,
    required this.overlappingNetworks,
    required this.band,
  });
}

class ChannelRatingUtils {
  
  /// Verilen ağ listesine ve hedef banda göre kanalları puanlar.
  static List<ChannelRatingResult> rateChannels(List<WiFiNetworkModel> networks, String targetBand) {
    final List<ChannelRatingResult> ratings = [];
    final bandNetworks = networks.where((n) => n.band == targetBand).toList();

    if (targetBand == "2.4 GHz") {
      // 2.4GHz kanalları: 1'den 13'e
      for (int channel = 1; channel <= 13; channel++) {
        final overlapping = bandNetworks.where((n) {
          return (n.channel - channel).abs() <= 2;
        }).toList();

        double score = 10.0;
        final List<String> overlappingNames = [];
        
        for (var network in overlapping) {
          overlappingNames.add("${network.ssid.isEmpty ? 'Gizli' : network.ssid} (${network.level}dBm)");
          if (network.level >= -50) score -= 3.0;
          else if (network.level >= -70) score -= 1.5;
          else score -= 0.5;
        }

        ratings.add(ChannelRatingResult(
          channel: channel,
          score: score.clamp(1.0, 10.0),
          overlappingCount: overlapping.length,
          overlappingNetworks: overlappingNames,
          band: '2.4 GHz',
        ));
      }
    } else {
      // 5GHz ve 6GHz kanalları (Daha geniş spektrum)
      // Mevcut ağların olduğu kanalları ve standart boş kanalları belirle
      final List<int> standardChannels = targetBand == "5 GHz" 
          ? [36, 40, 44, 48, 52, 56, 60, 64, 100, 104, 108, 112, 149, 153, 157, 161, 165]
          : [1, 5, 9, 13, 17, 21, 25, 29, 33, 37, 41]; // 6GHz basitleştirilmiş liste

      for (int channel in standardChannels) {
        final overlapping = bandNetworks.where((n) => n.channel == channel).toList();

        double score = 10.0;
        final List<String> overlappingNames = [];
        
        for (var network in overlapping) {
          overlappingNames.add("${network.ssid.isEmpty ? 'Gizli' : network.ssid} (${network.level}dBm)");
          if (network.level >= -50) score -= 3.0;
          else if (network.level >= -70) score -= 1.5;
          else score -= 0.5;
        }

        ratings.add(ChannelRatingResult(
          channel: channel,
          score: score.clamp(1.0, 10.0),
          overlappingCount: overlapping.length,
          overlappingNetworks: overlappingNames,
          band: targetBand,
        ));
      }
    }

    // Puanı en yüksek olan (en temiz) kanalları en başa al
    ratings.sort((a, b) => b.score.compareTo(a.score));
    
    return ratings;
  }
}
