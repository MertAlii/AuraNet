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
  
  /// Verilen ağ listesine göre kanalları puanlar.
  /// Hem 2.4GHz hem de 5GHz (bazı temel kanallar) için değerlendirme yapar.
  static List<ChannelRatingResult> rateChannels(List<WiFiNetworkModel> networks) {
    final List<ChannelRatingResult> ratings = [];

    // 2.4GHz kanalları: 1'den 13'e
    for (int channel = 1; channel <= 13; channel++) {
      final overlapping = networks.where((n) {
        return (n.channel - channel).abs() <= 2 && n.band == "2.4 GHz";
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

    // 5GHz kanalları (Örnek standart kanallar)
    const List<int> channels5GHz = [36, 40, 44, 48, 52, 56, 149, 153, 157, 161, 165];
    for (int channel in channels5GHz) {
      final overlapping = networks.where((n) {
        return n.channel == channel && n.band == "5 GHz"; // 5GHz'de kanallar genelde çakışmaz, aynı kanal üst üste biner.
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
        band: '5 GHz',
      ));
    }

    // Puanı en yüksek olan (en temiz) kanalları en başa al
    ratings.sort((a, b) => b.score.compareTo(a.score));
    
    return ratings;
  }
}
