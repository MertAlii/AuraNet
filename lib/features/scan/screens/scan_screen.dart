import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:network_info_plus/network_info_plus.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/network_scanner_service.dart';
import '../providers/scan_provider.dart';

class ScanScreen extends ConsumerStatefulWidget {
  final ScanMode initialMode;
  const ScanScreen({super.key, required this.initialMode});

  @override
  ConsumerState<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends ConsumerState<ScanScreen> {
  String _wifiName = 'Ağ Araştırılıyor...';
  String _wifiBSSID = '...';

  @override
  void initState() {
    super.initState();
    _fetchWifiInfo();
    // Sayfa açılır açılmaz taramayı başlat
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(scanProvider.notifier).startScan(widget.initialMode);
    });
  }

  Future<void> _fetchWifiInfo() async {
    try {
      final info = NetworkInfo();
      String? name = await info.getWifiName();
      String? bssid = await info.getWifiBSSID();
      if (mounted) {
        setState(() {
          _wifiName = name?.replaceAll('"', '') ?? 'Bilinmeyen Ağ';
          _wifiBSSID = bssid ?? 'BSSID Bulunamadı';
        });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final scanState = ref.watch(scanProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundDeep,
      appBar: AppBar(
        title: const Text('Ağ Taraması'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () {
            // Çıkarken durdurabiliriz veya arkada devam eder (isteğe bağlı)
            // ref.read(scanProvider.notifier).cancelScan();
            context.pop();
          },
        ),
        actions: [
          if (scanState.isScanning)
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Center(
                child: Text('%${(scanState.progress * 100).toInt()}', style: const TextStyle(color: AppColors.primaryBlueLight, fontWeight: FontWeight.bold)),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          if (scanState.isScanning)
           Column(
             children: [
               LinearProgressIndicator(
                 value: scanState.progress > 0 ? scanState.progress : null, 
                 color: AppColors.primaryBlue, 
                 backgroundColor: AppColors.primaryBlue.withOpacity(0.1)
               ),
               if (scanState.activeScanningIp.isNotEmpty)
                 Container(
                   width: double.infinity,
                   padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
                   color: AppColors.primaryBlue.withOpacity(0.1),
                   child: Text(
                     'Taranıyor: ${scanState.activeScanningIp} ${scanState.activeScanningPort.isNotEmpty ? ':: Port ${scanState.activeScanningPort}' : ''}',
                     style: const TextStyle(color: AppColors.primaryBlueLight, fontSize: 12, fontFamily: 'JetBrains Mono'),
                     textAlign: TextAlign.center,
                   ),
                 ),
             ],
           ),
          // Üst bilgi kartı
          _buildInfoCard(scanState),

          // Hata mesajı
          if (scanState.error != null)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                scanState.error!,
                style: const TextStyle(color: AppColors.danger),
              ),
            ),

          // Cihaz Listesi
          Expanded(
            child: scanState.devices.isEmpty && scanState.isScanning
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: AppColors.primaryBlue),
                        SizedBox(height: 16),
                        Text('Ağdaki cihazlar aranıyor...', style: TextStyle(color: AppColors.textSecondary)),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: scanState.devices.length,
                    itemBuilder: (context, index) {
                      final device = scanState.devices[index];
                      return _buildDeviceCard(context, device);
                    },
                  ),
          ),
          
          // Durdur Butonu
          if (scanState.isScanning)
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: () {
                    ref.read(scanProvider.notifier).cancelScan();
                  },
                  icon: const Icon(Icons.stop_rounded),
                  label: const Text('Taramayı Durdur', style: TextStyle(fontSize: 16)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.danger.withValues(alpha: 0.15),
                    foregroundColor: AppColors.danger,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(ScanState scanState) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.backgroundBorder.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.wifi_rounded, color: AppColors.primaryBlueLight, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_wifiName, style: const TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    Text('BSSID: $_wifiBSSID', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, fontFamily: 'JetBrains Mono')),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.safe.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Text(
                      '${scanState.devices.length}',
                      style: const TextStyle(color: AppColors.safe, fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const Text('Cihaz', style: TextStyle(color: AppColors.safe, fontSize: 11)),
                  ],
                ),
              )
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(color: AppColors.backgroundDeep, thickness: 2),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildWifiDetailItem('Şifreleme', 'WPA2/3', Icons.security_rounded),
              _buildWifiDetailItem('Kanal', 'Oto', Icons.router_rounded),
              _buildWifiDetailItem('Ağ Tipi', scanState.subnet.isNotEmpty ? '${scanState.subnet}.x' : 'Bekleniyor', Icons.hub_rounded),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildWifiDetailItem(String title, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: AppColors.textSecondary, size: 20),
        const SizedBox(height: 6),
        Text(title, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildDeviceCard(BuildContext context, device) {
    bool hasSuspiciousPorts = device.openPorts.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasSuspiciousPorts ? AppColors.danger.withValues(alpha: 0.5) : AppColors.backgroundBorder.withValues(alpha: 0.3),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          width: 48, height: 48,
          decoration: BoxDecoration(
            color: hasSuspiciousPorts ? AppColors.danger.withValues(alpha: 0.1) : AppColors.primaryBlue.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            device.isHost ? Icons.phone_android_rounded : Icons.devices_other_rounded, 
            color: hasSuspiciousPorts ? AppColors.danger : AppColors.primaryBlue,
          ),
        ),
        title: Text(device.deviceName, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(device.ipAddress, style: const TextStyle(color: AppColors.textSecondary, fontFamily: 'JetBrains Mono', fontSize: 13)),
            const SizedBox(height: 2),
            Text(device.vendorName, style: TextStyle(color: AppColors.textPrimary.withValues(alpha: 0.5), fontSize: 12)),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (device.isScanningPorts)
              const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
            else if (device.openPorts.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.danger.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('${device.openPorts.length} Açık Port', style: const TextStyle(color: AppColors.danger, fontSize: 11, fontWeight: FontWeight.bold)),
              )
            else
               const Icon(Icons.check_circle_outline_rounded, color: AppColors.safe, size: 20),
          ],
        ),
        onTap: () {
          // TODO: Cihaz detayları ekranına git
          context.push('/deviceDetail', extra: device);
        },
      ),
    );
  }
}
