import 'dart:async';
import 'dart:io';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:network_tools/network_tools.dart';
import '../../features/scan/models/device_model.dart';
import '../constants/port_risk_database.dart';
import 'mac_vendor_service.dart';
import 'hive_service.dart';
// Provider tanımları scan_provider.dart içindedir

enum ScanMode { fast, deep, wifi }

class ScanProgress {
  final double progress;
  final DeviceModel? device;
  final bool isDone;
  final String? activeIp;
  final String? activePort;

  ScanProgress({
    required this.progress, 
    this.device, 
    this.isDone = false,
    this.activeIp,
    this.activePort,
  });
}

class NetworkScannerService {
  final MacVendorService _macService;
  final _info = NetworkInfo();

  NetworkScannerService(this._macService);

  /// Mevcut Wi-Fi SSID'sini döndürür
  Future<String?> getSsid() async {
    try {
      return await _info.getWifiName();
    } catch (_) {
      return null;
    }
  }

  /// Local IP adresini döndürür (192.168.x.y)
  Future<String?> getLocalIpAddress() async {
    try {
      for (var interface in await NetworkInterface.list()) {
        for (var addr in interface.addresses) {
          if (addr.type == InternetAddressType.IPv4 && !addr.isLoopback) {
            if (addr.address.startsWith('192.168.') || addr.address.startsWith('10.') || addr.address.startsWith('172.')) {
              return addr.address;
            }
          }
        }
      }
    } catch (e) {
      return null;
    }
    return null;
  }

  /// Subnet'i hesaplar (örn: 192.168.1)
  String? getSubnet(String ip) {
    if (ip.isEmpty) return null;
    final parts = ip.split('.');
    if (parts.length == 4) {
      return '${parts[0]}.${parts[1]}.${parts[2]}';
    }
    return null;
  }

  /// MAC adresi çekme - çok katmanlı strateji
  Future<String> _resolveMAC(String ip, dynamic host) async {
    String mac = '00:00:00:00:00:00';
    final isRoot = HiveService.isRootMode();

    // Strateji 1: Root modu aktifse - su komutu (en güvenilir)
    if (isRoot && (Platform.isAndroid || Platform.isLinux)) {
      try {
        final res = await Process.run('su', ['-c', 'ip neigh show to $ip']).timeout(const Duration(seconds: 2));
        if (res.exitCode == 0 && res.stdout != null) {
          final out = res.stdout.toString();
          if (out.contains('lladdr')) {
            final split = out.split('lladdr ');
            if (split.length > 1) {
              mac = split[1].split(' ')[0].toUpperCase();
              if (mac != '00:00:00:00:00:00') return mac;
            }
          }
        }
      } catch (_) {}
    }

    // Strateji 2: network_tools ARP veritabanı
    try {
      final macData = await host.arpData;
      if (macData != null && macData.macAddress != null) {
        mac = macData.macAddress!.toUpperCase();
        if (mac != '00:00:00:00:00:00') return mac;
      }
    } catch (_) {}

    // Strateji 3: /proc/net/arp (Android/Linux - çoğu rootsuz cihaz da okuyabilir)
    if (Platform.isAndroid || Platform.isLinux) {
      try {
        final arpRes = await Process.run('cat', ['/proc/net/arp']);
        if (arpRes.stdout != null) {
          final lines = arpRes.stdout.toString().split('\n');
          for (var line in lines) {
            if (line.contains(ip)) {
              final parts = line.split(RegExp(r'\s+'));
              if (parts.length > 3 && parts[3].contains(':') && parts[3] != '00:00:00:00:00:00') {
                return parts[3].toUpperCase();
              }
            }
          }
        }
      } catch (_) {}
    }

    // Strateji 4: ip neigh (rootsuz, izin varsa çalışır)
    if (Platform.isAndroid || Platform.isLinux) {
      try {
        final ipRes = await Process.run('ip', ['neigh', 'show', 'to', ip]);
        if (ipRes.stdout != null) {
          final out = ipRes.stdout.toString();
          if (out.contains('lladdr')) {
            final split = out.split('lladdr ');
            if (split.length > 1) {
              final found = split[1].split(' ')[0].toUpperCase();
              if (found != '00:00:00:00:00:00') return found;
            }
          }
        }
      } catch (_) {}
    }

    return mac;
  }

  /// Cihaz ismini çözümle - çoklu kaynak
  Future<String?> _resolveHostname(String ip, dynamic host) async {
    // 1. network_tools deviceName
    try {
      final name = await host.deviceName;
      if (name != null && name != 'Generic Device' && name != ip) {
        return name;
      }
    } catch (_) {}

    // 2. mDNS bilgisi
    try {
      final mdns = await host.mdnsInfo;
      if (mdns != null) {
        return mdns.getOnlyTheStartOfMdnsName();
      }
    } catch (_) {}

    // 3. Reverse DNS Lookup
    try {
      final lookup = await InternetAddress(ip).reverse().timeout(const Duration(milliseconds: 500));
      if (lookup.host != ip) return lookup.host;
    } catch (_) {}

    // 4. Standart DNS lookup
    try {
      final lookup = await InternetAddress.lookup(ip).timeout(const Duration(milliseconds: 300));
      if (lookup.isNotEmpty && lookup.first.host != ip) {
        return lookup.first.host;
      }
    } catch (_) {}

    // 5. NetBIOS isim sorgusu (Windows cihazları için - port 137)
    try {
      final socket = await Socket.connect(ip, 137, timeout: const Duration(milliseconds: 200));
      socket.destroy();
      // Port 137 açıksa muhtemelen Windows cihazı
      return 'Windows Cihaz';
    } catch (_) {}

    return null;
  }
  /// Alt ağı tarayarak cihazları ve ilerlemeyi Stream olarak fırlatır
  Stream<ScanProgress> scanNetworkStream(String subnet, ScanMode mode, {bool isPremium = false}) async* {
    if (subnet.isEmpty) return;

    int foundCount = 0;
    await for (final host in HostScannerService.instance.getAllPingableDevices(
      subnet,
      progressCallback: (double p) {},
    )) {
      foundCount++;
      final ip = host.address;
      final progressBase = (foundCount / 254) * 0.5;

      // 1. MAC Adresi Tespiti (çok katmanlı strateji)
      final mac = await _resolveMAC(ip, host);

      // 2. Vendor Tespiti
      String vendorName = 'Bilinmeyen Üretici';
      try {
        final vendorData = await host.vendor;
        if (vendorData != null && vendorData.vendorName != null) {
          vendorName = vendorData.vendorName!;
        }
      } catch (_) {}
      if (vendorName == 'Bilinmeyen Üretici' && mac != '00:00:00:00:00:00') {
        vendorName = await _macService.getVendor(mac);
      }

      // 3. Hostname Tespiti (çok katmanlı strateji)
      final hostname = await _resolveHostname(ip, host);

      // Ana modeli oluştur
      var device = DeviceModel(
        ipAddress: ip,
        macAddress: mac,
        vendorName: vendorName,
        deviceName: hostname ?? ip,
        isHost: false,
        isScanningPorts: mode != ScanMode.wifi,
      );
      
      yield ScanProgress(progress: progressBase, device: device, activeIp: ip);

      // 4. Port Taraması (Wifi modu değilse)
      if (mode != ScanMode.wifi) {
        List<int> portsToScan = [];
        if (mode == ScanMode.fast) {
          portsToScan = PortRiskDatabase.ports.keys.toList();
        } else {
          final maxPort = isPremium ? 65535 : 1024;
          portsToScan = List.generate(maxPort, (index) => index + 1);
        }

        final openPorts = <int>[];
        int scannedPorts = 0;
        
        for (final port in portsToScan) {
          scannedPorts++;
          if (scannedPorts % 5 == 0) {
            yield ScanProgress(
              progress: progressBase + (scannedPorts / portsToScan.length) * 0.1,
              activeIp: ip,
              activePort: port.toString(),
            );
          }

          try {
            final socket = await Socket.connect(ip, port, timeout: const Duration(milliseconds: 200));
            openPorts.add(port);
            socket.destroy();
          } catch (_) {}
        }

        yield ScanProgress(
          progress: progressBase + 0.1,
          device: device.copyWith(
            openPorts: openPorts.toSet().toList(),
            isScanningPorts: false,
          ),
        );
      } else {
        yield ScanProgress(
          progress: progressBase + 0.1,
          device: device.copyWith(isScanningPorts: false),
        );
      }
    }
    yield ScanProgress(progress: 1.0, isDone: true);
  }

  /// Tüm ağdaki cihazların tam taranması (Future bazlı toplu sonuç)
  Future<List<DeviceModel>> scanNetworkComplete(String subnet, ScanMode mode, {bool isPremium = false}) async {
    final devices = <DeviceModel>[];
    final stream = scanNetworkStream(subnet, mode, isPremium: isPremium);
    
    await for (final p in stream) {
      if (p.device != null) {
        final d = p.device!;
        // Eğer cihaz listemizde varsa güncelle, yoksa ekle
        final i = devices.indexWhere((element) => element.ipAddress == d.ipAddress);
        if (i >= 0) {
          devices[i] = d;
        } else {
          devices.add(d);
        }
      }
    }
    return devices;
  }
}
