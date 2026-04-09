import 'dart:async';
import 'dart:io';
import '../../features/scan/models/device_model.dart';
import '../constants/port_risk_database.dart';
import 'mac_vendor_service.dart';

enum ScanMode { fast, deep, wifi }

class NetworkScannerService {
  final MacVendorService _macService;

  NetworkScannerService(this._macService);

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

  /// Alt ağı tarayarak cihazları Stream olarak fırlatır
  Stream<DeviceModel> scanNetworkStream(String subnet, ScanMode mode, {bool isPremium = false}) async* {
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

    await for (final ip in aliveHostsController.stream) {
      // 1. Hostname sorgula (Reverse DNS) - Cihaz adını çekebilme özelliği
      String? hostname;
      try {
        final lookup = await InternetAddress.lookup(ip).timeout(const Duration(milliseconds: 300));
        if (lookup.isNotEmpty && lookup.first.host != ip) {
          hostname = lookup.first.host;
        }
      } catch (_) {}

      // 2. MAC Vendor sorgula (Not: Android 11+ kısıtlamaları nedeniyle 00:00:00... dönebilir)
      final mac = '00:00:00:00:00:00'; 
      final vendorName = await _macService.getVendor(mac);

      // Ana modeli oluştur
      var device = DeviceModel(
        ipAddress: ip,
        macAddress: mac,
        vendorName: vendorName,
        deviceName: hostname ?? ip, // Hostname yoksa IP'yi isim olarak göster (Daha modern)
        isHost: false, // getLocalIp() ile aynıysa true yapacağız UI tarafında
        isScanningPorts: true, // Port taraması birazdan başlayacak
      );
      
      // Önce cihazı UI'da göstersin diye fırlat
      yield device;

      // Ardından portlarını tara ve güncellenmiş cihazı fırlat (Eğer wifi modu değilse)
      if (mode != ScanMode.wifi) {
        List<int> portsToScan = [];
        if (mode == ScanMode.fast) {
          portsToScan = PortRiskDatabase.ports.keys.toList(); // Sadece veritabanındaki kritik portlar (20 port)
        } else {
          // Deep scan - mobil.md gereği: Free ise 1-1024, Premium ise 1-65535
          final maxPort = isPremium ? 65535 : 1024;
          portsToScan = List.generate(maxPort, (index) => index + 1);
        }

        final openPorts = <int>[];
        
        // Kendi socket metodumuzla port taraması (Platform bağımsız ve güvenilir stream alternatifi)
        for (final port in portsToScan) {
          try {
            final socket = await Socket.connect(ip, port, timeout: const Duration(milliseconds: 300));
            openPorts.add(port);
            socket.destroy();
          } catch (_) {
            // Port kapalı veya timeout
          }
        }

        // Port taraması bitti, son haliyle cihazı fırlat
        yield device.copyWith(
          openPorts: openPorts.toSet().toList(), // duplicate'leri engelle
          isScanningPorts: false,
        );
      } else {
        // Eğer sadece wifi taramasıysa port döngüsüne girmeden direkt kapat
        yield device.copyWith(isScanningPorts: false);
      }
    }
  }

  /// Tüm ağdaki cihazların tam taranması (Future bazlı toplu sonuç)
  Future<List<DeviceModel>> scanNetworkComplete(String subnet, ScanMode mode, {bool isPremium = false}) async {
    final devices = <DeviceModel>[];
    final stream = scanNetworkStream(subnet, mode, isPremium: isPremium);
    
    await for (final d in stream) {
      // Eğer cihaz listemizde varsa güncelle, yoksa ekle
      final i = devices.indexWhere((element) => element.ipAddress == d.ipAddress);
      if (i >= 0) {
        devices[i] = d;
      } else {
        devices.add(d);
      }
    }
    return devices;
  }
}
