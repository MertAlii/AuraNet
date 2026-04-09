import 'package:equatable/equatable.dart';

class DeviceModel extends Equatable {
  final String ipAddress;
  final String macAddress;
  final String deviceName;
  final String vendorName;
  final List<int> openPorts;
  final bool isHost;
  final bool isScanningPorts;
  final bool isFavorite;
  final String? customEmoji;

  const DeviceModel({
    required this.ipAddress,
    required this.macAddress,
    this.deviceName = 'Bilinmeyen Cihaz',
    this.vendorName = 'Bilinmiyor',
    this.openPorts = const [],
    this.isHost = false,
    this.isScanningPorts = false,
    this.isFavorite = false,
    this.customEmoji,
  });

  DeviceModel copyWith({
    String? ipAddress,
    String? macAddress,
    String? deviceName,
    String? vendorName,
    List<int>? openPorts,
    bool? isHost,
    bool? isScanningPorts,
    bool? isFavorite,
    String? customEmoji,
  }) {
    return DeviceModel(
      ipAddress: ipAddress ?? this.ipAddress,
      macAddress: macAddress ?? this.macAddress,
      deviceName: deviceName ?? this.deviceName,
      vendorName: vendorName ?? this.vendorName,
      openPorts: openPorts ?? this.openPorts,
      isHost: isHost ?? this.isHost,
      isScanningPorts: isScanningPorts ?? this.isScanningPorts,
      isFavorite: isFavorite ?? this.isFavorite,
      customEmoji: customEmoji ?? this.customEmoji,
    );
  }

  @override
  List<Object?> get props => [
        ipAddress,
        macAddress,
        deviceName,
        vendorName,
        openPorts,
        isHost,
        isScanningPorts,
        isFavorite,
        customEmoji,
      ];
}
