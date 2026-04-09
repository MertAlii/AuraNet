import 'package:equatable/equatable.dart';

class WiFiNetworkModel extends Equatable {
  final String ssid;
  final String bssid;
  final int level; // RSSI
  final int frequency;
  final String capabilities;
  final DateTime timestamp;
  final double distance;
  final int signalLevel; // 0-100
  final String band;
  final int channel;

  const WiFiNetworkModel({
    required this.ssid,
    required this.bssid,
    required this.level,
    required this.frequency,
    required this.capabilities,
    required this.timestamp,
    required this.distance,
    required this.signalLevel,
    required this.band,
    required this.channel,
  });

  @override
  List<Object?> get props => [ssid, bssid, level, frequency];

  String get securityType {
    if (capabilities.contains('WPA3')) return 'WPA3';
    if (capabilities.contains('WPA2')) return 'WPA2';
    if (capabilities.contains('WPA')) return 'WPA';
    if (capabilities.contains('WEP')) return 'WEP';
    return 'Açık';
  }

  bool get isSecure => !capabilities.contains('OPEN') && !capabilities.isEmpty;
}
