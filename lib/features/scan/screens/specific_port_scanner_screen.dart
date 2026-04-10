import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/port_risk_database.dart';
import '../providers/scan_provider.dart';

class SpecificPortScannerScreen extends ConsumerStatefulWidget {
  const SpecificPortScannerScreen({super.key});

  @override
  ConsumerState<SpecificPortScannerScreen> createState() => _SpecificPortScannerScreenState();
}

class _SpecificPortScannerScreenState extends ConsumerState<SpecificPortScannerScreen> {
  final _ipController = TextEditingController();
  final _portController = TextEditingController();
  String? _selectedDeviceIp;
  bool _isScanning = false;
  _PortScanResult? _result;

  @override
  void dispose() {
    _ipController.dispose();
    _portController.dispose();
    super.dispose();
  }

  String get _targetIp => _selectedDeviceIp ?? _ipController.text.trim();

  Future<void> _scanPort() async {
    final ip = _targetIp;
    final portStr = _portController.text.trim();

    if (ip.isEmpty || portStr.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen IP adresi ve port numarasını girin.')),
      );
      return;
    }

    final port = int.tryParse(portStr);
    if (port == null || port < 1 || port > 65535) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Geçerli bir port numarası girin (1-65535).')),
      );
      return;
    }

    setState(() {
      _isScanning = true;
      _result = null;
    });

    final result = _PortScanResult(ip: ip, port: port);

    // 1. TCP Bağlantı Testi
    try {
      final socket = await Socket.connect(ip, port, timeout: const Duration(seconds: 3));
      result.isOpen = true;

      // Banner grabbing (servis bilgisi çekme)
      try {
        socket.write('HEAD / HTTP/1.0\r\n\r\n');
        await socket.flush();
        final response = await socket.timeout(const Duration(seconds: 2)).first;
        result.banner = utf8.decode(response, allowMalformed: true).trim();
      } catch (_) {}

      socket.destroy();
    } catch (e) {
      result.isOpen = false;
      result.errorMessage = e.toString();
    }

    // 2. Port Risk Bilgisi
    final portInfo = PortRiskDatabase.ports[port];
    if (portInfo != null) {
      result.serviceName = portInfo.protocol;
      result.riskLevel = portInfo.riskLevel;
      result.description = portInfo.description;
    }

    // 3. Ping Testi
    try {
      if (Platform.isAndroid || Platform.isLinux || Platform.isMacOS) {
        final pingRes = await Process.run('ping', ['-c', '3', '-W', '1', ip]);
        result.pingOutput = pingRes.stdout.toString();
      } else if (Platform.isWindows) {
        final pingRes = await Process.run('ping', ['-n', '3', '-w', '1000', ip]);
        result.pingOutput = pingRes.stdout.toString();
      }
    } catch (_) {}

    setState(() {
      _isScanning = false;
      _result = result;
    });
  }

  Future<void> _tryConnect() async {
    if (_result == null || !_result!.isOpen) return;
    final port = _result!.port;
    final ip = _result!.ip;

    if (port == 80 || port == 443 || port == 8080 || port == 8443) {
      final scheme = (port == 443 || port == 8443) ? 'https' : 'http';
      // URL'yi göster
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.backgroundCard,
          title: const Text('Web Servisi Keşfedildi', style: TextStyle(color: AppColors.textPrimary)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('$scheme://$ip:$port adresinde HTTP servisi algılandı.', style: const TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: 16),
              if (_result!.banner.isNotEmpty) ...[
                const Text('Sunucu Yanıtı:', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: AppColors.backgroundDeep, borderRadius: BorderRadius.circular(8)),
                  child: Text(_result!.banner, style: const TextStyle(color: AppColors.safe, fontSize: 12, fontFamily: 'JetBrains Mono')),
                ),
              ]
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Kapat')),
          ],
        ),
      );
    } else {
      // Telnet-tarzı raw socket deneme
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.backgroundCard,
          title: Text('Port $port - Raw Socket', style: const TextStyle(color: AppColors.textPrimary)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('$ip:$port adresine TCP bağlantısı açıldı.', style: const TextStyle(color: AppColors.textSecondary)),
              if (_result!.banner.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: AppColors.backgroundDeep, borderRadius: BorderRadius.circular(8)),
                  child: Text(_result!.banner, style: const TextStyle(color: AppColors.safe, fontSize: 12, fontFamily: 'JetBrains Mono')),
                ),
              ] else
                const Padding(
                  padding: EdgeInsets.only(top: 12),
                  child: Text('Sunucu banner bilgisi dönmedi.', style: TextStyle(color: AppColors.textHint)),
                ),
            ],
          ),
          actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Kapat'))],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final scanState = ref.watch(scanProvider);
    final knownDevices = scanState.devices;

    return Scaffold(
      backgroundColor: AppColors.backgroundDeep,
      appBar: AppBar(title: const Text('Spesifik Port Analizi')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Bilinen cihaz seçimi
            if (knownDevices.isNotEmpty) ...[
              const Text('Bilinen Cihazlar', style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              SizedBox(
                height: 56,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: knownDevices.length,
                  itemBuilder: (ctx, i) {
                    final d = knownDevices[i];
                    final isSelected = _selectedDeviceIp == d.ipAddress;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text('${d.deviceName}\n${d.ipAddress}', style: TextStyle(color: isSelected ? Colors.white : AppColors.textSecondary, fontSize: 11)),
                        selected: isSelected,
                        selectedColor: AppColors.primaryBlue,
                        backgroundColor: AppColors.backgroundCard,
                        onSelected: (sel) {
                          setState(() {
                            _selectedDeviceIp = sel ? d.ipAddress : null;
                            if (sel) _ipController.text = d.ipAddress;
                          });
                        },
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
            ],

            // IP Girişi
            const Text('Hedef IP Adresi', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            const SizedBox(height: 6),
            TextField(
              controller: _ipController,
              style: const TextStyle(color: AppColors.textPrimary, fontFamily: 'JetBrains Mono'),
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: '192.168.1.1',
                hintStyle: const TextStyle(color: AppColors.textHint),
                prefixIcon: const Icon(Icons.computer_rounded, color: AppColors.textHint),
                filled: true,
                fillColor: AppColors.backgroundCard,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
              ),
              onChanged: (_) => setState(() => _selectedDeviceIp = null),
            ),
            const SizedBox(height: 16),

            // Port Girişi
            const Text('Port Numarası', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            const SizedBox(height: 6),
            TextField(
              controller: _portController,
              style: const TextStyle(color: AppColors.textPrimary, fontFamily: 'JetBrains Mono'),
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: '80, 443, 22...',
                hintStyle: const TextStyle(color: AppColors.textHint),
                prefixIcon: const Icon(Icons.lan_outlined, color: AppColors.textHint),
                filled: true,
                fillColor: AppColors.backgroundCard,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 24),

            // Tara Butonu
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton.icon(
                onPressed: _isScanning ? null : _scanPort,
                icon: _isScanning
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.search_rounded),
                label: Text(_isScanning ? 'Taranıyor...' : 'Portu Tara', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlueDark,
                  foregroundColor: AppColors.primaryBlueLight,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Sonuçlar
            if (_result != null) _buildResultCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildResultCard() {
    final r = _result!;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: r.isOpen ? AppColors.warning.withValues(alpha: 0.5) : AppColors.safe.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Başlık
          Row(
            children: [
              Icon(r.isOpen ? Icons.lock_open_rounded : Icons.lock_rounded, color: r.isOpen ? AppColors.warning : AppColors.safe, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${r.ip}:${r.port}', style: const TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'JetBrains Mono')),
                    Text(r.isOpen ? 'Port AÇIK' : 'Port KAPALI', style: TextStyle(color: r.isOpen ? AppColors.warning : AppColors.safe, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
          const Divider(color: AppColors.backgroundDeep, height: 32),

          // Servis Bilgisi
          _infoRow('Servis', r.serviceName.isNotEmpty ? r.serviceName : 'Bilinmeyen'),
          _infoRow('Risk Seviyesi', r.riskLevel.isNotEmpty ? r.riskLevel : 'Bilinmeyen'),
          if (r.description.isNotEmpty) _infoRow('Açıklama', r.description),
          if (r.banner.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text('Sunucu Yanıtı (Banner):', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            const SizedBox(height: 6),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppColors.backgroundDeep, borderRadius: BorderRadius.circular(10)),
              child: Text(r.banner, style: const TextStyle(color: AppColors.safe, fontSize: 12, fontFamily: 'JetBrains Mono')),
            ),
          ],

          // Bağlan Butonu
          if (r.isOpen) ...[
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _tryConnect,
                icon: const Icon(Icons.link_rounded),
                label: const Text('Bağlantıyı Test Et'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.warning.withValues(alpha: 0.2),
                  foregroundColor: AppColors.warning,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 110, child: Text('$label:', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13))),
          Expanded(child: Text(value, style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }
}

class _PortScanResult {
  final String ip;
  final int port;
  bool isOpen = false;
  String banner = '';
  String serviceName = '';
  String riskLevel = '';
  String description = '';
  String? errorMessage;
  String pingOutput = '';

  _PortScanResult({required this.ip, required this.port});
}
