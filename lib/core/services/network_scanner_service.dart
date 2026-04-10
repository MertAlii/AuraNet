import 'dart:async';
import 'dart:io';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:network_tools/network_tools.dart';
import '../../features/scan/models/device_model.dart';
import '../constants/port_risk_database.dart';
import 'mac_vendor_service.dart';
// Provider tanımları scan_provider.dart içindedir

enum ScanMode { fast, deep, wifi }

/// Tarama ilerleme bilgisini taşıyan model
class ScanProgress {
  final double progress;
  final DeviceModel? device;
  final bool isDone;

  ScanProgress({required this.progress, this.device, this.isDone = false});
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
            // Örn: 192.168.1.15
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

  /// Alt ağı tarayarak cihazları ve ilerlemeyi Stream olarak fırlatır
  Stream<ScanProgress> scanNetworkStream(String subnet, ScanMode mode, {bool isPremium = false}) async* {
    if (subnet.isEmpty) return;

    // Alt ağdaki 254 IP'yi taramak için hedefler
    final hostsToScan = List.generate(254, (index) => '$subnet.${index + 1}');
    
    // Paralel bağlantı ile host taraması (TCP SYN yaklaşımı - cihaz ping'e kapalı olsa da bulur)
    final checkPorts = [80, 53, 443, 22, 139, 445];

    StreamController<String> aliveHostsController = StreamController<String>();

    // Arka planda paralel taramayı başlat
    Future.microtask(() async {
      final futures = hostsToScan.map((ip) async {
        bool isAlive = false;
        
        // 1. Önce ICMP Ping denemesi (Çoğu cihaz yanıt verir)
        try {
          if (Platform.isAndroid || Platform.isIOS || Platform.isLinux || Platform.isMacOS) {
            final res = await Process.run('ping', ['-c', '1', '-W', '1', ip]);
            if (res.exitCode == 0) isAlive = true;
          } else if (Platform.isWindows) {
            final res = await Process.run('ping', ['-n', '1', '-w', '1000', ip]);
            if (res.exitCode == 0) isAlive = true;
          }
        } catch (_) {}

        // 2. Eğer Ping'ten bulunamadıysa popüler portlara hızlı bağlantı at 
        if (!isAlive) {
          for (final port in checkPorts) {
            try {
              final socket = await Socket.connect(ip, port, timeout: const Duration(milliseconds: 150));
              isAlive = true;
              socket.destroy();
              break;
            } catch (_) {}
          }
        }

        if (isAlive && !aliveHostsController.isClosed) {
          aliveHostsController.add(ip);
        }
      });
      
      await Future.wait(futures);
      if (!aliveHostsController.isClosed) {
        aliveHostsController.close();
      }
    });

    int foundCount = 0;
    await for (final host in HostScannerService.instance.getAllPingableDevices(
      subnet,
      progressCallback: (double p) {
        // network_tools kendi progress'ini fırlatır
      },
    )) {
      foundCount++;
      final ip = host.address;
      final progressBase = (foundCount / 254) * 0.5; // host.totalAddress yerine 254 veya benzeri sabit gerekebilir

      // 1. MAC Adresi Tespiti
      String mac = '00:00:00:00:00:00';
      String vendorName = 'Bilinmeyen Üretici';
      
      try {
        // Vendor bilgisini al
        final vendorData = await host.vendor;
        if (vendorData != null && vendorData.vendorName != null) {
           vendorName = vendorData.vendorName!;
        }
        
        // Cihazın MAC adresini almaya çalış
        final macData = await host.arpData;
        if (macData != null && macData.macAddress != null) {
          mac = macData.macAddress!.toUpperCase();
        } else if (Platform.isAndroid || Platform.isLinux) {
          // Android Native Fallback (Root veya kısıtlamasız OS için)
          try {
             final arpRes = await Process.run('cat', ['/proc/net/arp']);
             if (arpRes.stdout != null) {
               final lines = arpRes.stdout.toString().split('\n');
               for (var line in lines) {
                 if (line.contains(ip)) {
                   final parts = line.split(RegExp(r'\s+'));
                   if (parts.length > 3 && parts[3].contains(':')) {
                     mac = parts[3].toUpperCase();
                     break;
                   }
                 }
               }
             }
             if (mac == '00:00:00:00:00:00') {
               final ipRes = await Process.run('ip', ['neigh', 'show', 'to', ip]);
               if (ipRes.stdout != null) {
                 final out = ipRes.stdout.toString();
                 if (out.contains('lladdr')) {
                    final split = out.split('lladdr ');
                    if (split.length > 1) {
                      mac = split[1].split(' ')[0].toUpperCase();
                    }
                 }
               }
             }
          } catch (_) {}
        }
      } catch (_) {}

      // 2. Hostname sorgula
      String? hostname;
      try {
        final lookup = await InternetAddress.lookup(ip).timeout(const Duration(milliseconds: 300));
        if (lookup.isNotEmpty && lookup.first.host != ip) {
          hostname = lookup.first.host;
        }
      } catch (_) {}

      // Vendor ismini API'den de teyit et (Eğer network_tools bulamadıysa)
      if (vendorName == 'Bilinmeyen Üretici' && mac != '00:00:00:00:00:00') {
        vendorName = await _macService.getVendor(mac);
      }

      // Ana modeli oluştur
      var device = DeviceModel(
        ipAddress: ip,
        macAddress: mac,
        vendorName: vendorName,
        deviceName: hostname ?? ip,
        isHost: false,
        isScanningPorts: true,
      );
      
      yield ScanProgress(progress: progressBase, device: device);

      // 3. Port Taraması (Wifi modu değilse)
      if (mode != ScanMode.wifi) {
        List<int> portsToScan = [];
        if (mode == ScanMode.fast) {
          portsToScan = PortRiskDatabase.ports.keys.toList();
        } else {
          // Deep scan logic
          final maxPort = isPremium ? 65535 : 1024;
          portsToScan = List.generate(maxPort, (index) => index + 1);
        }

        final openPorts = <int>[];
        int scannedPorts = 0;
        
        for (final port in portsToScan) {
          scannedPorts++;
          // Port bazlı küçük progress güncellemeleri fırlat (Cihaz başına ayrılan %10'luk dilimde ilerlet)
          if (scannedPorts % 5 == 0) {
            yield ScanProgress(
              progress: progressBase + (scannedPorts / portsToScan.length) * 0.1,
            );
          }

          try {
            final socket = await Socket.connect(ip, port, timeout: const Duration(milliseconds: 200));
            openPorts.add(port);
            socket.destroy();
          } catch (_) {}
        }

        // Port taraması bitti, son haliyle cihazı fırlat
        yield ScanProgress(
          progress: progressBase + 0.1, // Port taraması sonrası küçük artış
          device: device.copyWith(
            openPorts: openPorts.toSet().toList(),
            isScanningPorts: false,
          ),
        );
      } else {
        // Eğer sadece wifi taramasıysa port döngüsüne girmeden direkt kapat
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
