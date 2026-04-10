import 'dart:async';
import 'dart:io';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:network_tools/network_tools.dart';
import 'package:dio/dio.dart';
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

  /// Cihaz ismini çözümle - çoklu kaynak (İyileştirilmiş)
  Future<String?> _resolveHostname(String ip, dynamic host) async {
    // 1. mDNS bilgisi (En güvenilir rootsuz isim kaynağı)
    try {
      final mdns = await host.mdnsInfo;
      if (mdns != null && mdns.mdnsName != null) {
        return mdns.getOnlyTheStartOfMdnsName();
      }
    } catch (_) {}

    // 2. SSDP / UPnP Tespiti (TV, Yazıcı vb. için)
    final upnpName = await _resolveUPnP(ip);
    if (upnpName != null) return upnpName;

    // 3. network_tools deviceName
    try {
      final name = await host.deviceName;
      if (name != null && name != 'Generic Device' && name != ip) {
        return name;
      }
    } catch (_) {}

    // 4. Reverse DNS Lookup
    try {
      final lookup = await InternetAddress(ip).reverse().timeout(const Duration(milliseconds: 500));
      if (lookup.host != ip) return lookup.host;
    } catch (_) {}

    // 5. Ortak Port Servis Tespiti
    final serviceName = await _resolveServiceIdentity(ip);
    if (serviceName != null) return serviceName;

    return null;
  }

  /// UPnP üzerinden cihaz modeli çözümleme
  Future<String?> _resolveUPnP(String ip) async {
    try {
      // Yaygın UPnP/SSDP lokasyonları
      final locations = [':80/description.xml', ':8080/description.xml', ':49152/description.xml'];
      final dio = Dio(BaseOptions(connectTimeout: const Duration(milliseconds: 300)));
      
      for (var loc in locations) {
        try {
          final res = await dio.get('http://$ip$loc');
          if (res.statusCode == 200) {
            final body = res.data.toString();
            if (body.contains('<friendlyName>')) {
              return body.split('<friendlyName>')[1].split('</friendlyName>')[0];
            }
            if (body.contains('<modelName>')) {
              return body.split('<modelName>')[1].split('</modelName>')[0];
            }
          }
        } catch (_) {}
      }
    } catch (_) {}
    return null;
  }

  /// Servis bazlı kimlik tespiti (HTTP Server Headers vb.)
  Future<String?> _resolveServiceIdentity(String ip) async {
    try {
      final dio = Dio(BaseOptions(connectTimeout: const Duration(milliseconds: 200)));
      final res = await dio.get('http://$ip');
      final server = res.headers.value('server');
      if (server != null) {
        if (server.contains('MikroTik')) return 'MikroTik Router';
        if (server.contains('QNAP')) return 'QNAP NAS';
        if (server.contains('Synology')) return 'Synology NAS';
        return server.split(' ')[0];
      }
    } catch (_) {}
    return null;
  }
  /// Alt ağı tarayarak cihazları ve ilerlemeyi Stream olarak fırlatır
  Stream<ScanProgress> scanNetworkStream(String subnet, ScanMode mode, {bool isPremium = false}) async* {
    if (subnet.isEmpty) {
      yield ScanProgress(progress: 1.0, isDone: true);
      return;
    }

    int foundCount = 0;
    try {
      await for (final host in HostScannerService.instance.getAllPingableDevices(
        subnet,
        progressCallback: (double p) {},
      )) {
        foundCount++;
        final ip = host.address;
        // İlerlemeyi daha gerçekçi bir oranda tut (Cihaz keşfi %50, Port taraması %50 yer tutsun)
        final progressBase = (foundCount / 254) * 0.5;

        // 1. MAC Adresi Tespiti
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

        // 3. Hostname Tespiti
        final hostname = await _resolveHostname(ip, host);

        var device = DeviceModel(
          ipAddress: ip,
          macAddress: mac,
          vendorName: vendorName,
          deviceName: hostname ?? ip,
          isHost: false,
          isScanningPorts: mode != ScanMode.wifi,
        );
        
        yield ScanProgress(progress: progressBase, device: device, activeIp: ip);

        // 4. Port Taraması
        if (mode != ScanMode.wifi) {
          List<int> portsToScan = [];
          if (mode == ScanMode.fast) {
            portsToScan = PortRiskDatabase.ports.keys.toList();
          } else {
            // Kullanıcı talebi: 1024'ten yukarı çıkarıldı. 
            // Derin tarama varsayılan 2048, Premium ise tam kapsam (65k)
            final maxPort = isPremium ? 65535 : 2048;
            portsToScan = List.generate(maxPort, (index) => index + 1);
          }

          final openPorts = <int>[];
          int scannedPorts = 0;
          
          for (final port in portsToScan) {
            scannedPorts++;
            // UI kasmaması için her 10 portta bir update gönder
            if (scannedPorts % 10 == 0) {
              yield ScanProgress(
                progress: progressBase + (scannedPorts / portsToScan.length) * 0.4, // %40 port tarama ağırlığı
                activeIp: ip,
                activePort: port.toString(),
              );
            }

            try {
              final socket = await Socket.connect(ip, port, timeout: const Duration(milliseconds: 150));
              openPorts.add(port);
              socket.destroy();
            } catch (_) {}
          }

          yield ScanProgress(
            progress: progressBase + 0.45,
            device: device.copyWith(
              openPorts: openPorts.toSet().toList(),
              isScanningPorts: false,
            ),
          );
        } else {
          yield ScanProgress(
            progress: progressBase + 0.45,
            device: device.copyWith(isScanningPorts: false),
          );
        }
      }
    } catch (e) {
      // Hata durumunda da akışı bitir
    } finally {
      yield ScanProgress(progress: 1.0, isDone: true);
    }
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
