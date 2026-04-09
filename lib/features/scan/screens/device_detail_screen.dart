import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/port_risk_database.dart';
import '../../scan/models/device_model.dart';
import 'package:go_router/go_router.dart';

class DeviceDetailScreen extends StatelessWidget {
  final DeviceModel device;
  const DeviceDetailScreen({super.key, required this.device});

  @override
  Widget build(BuildContext context) {
    bool isRisky = device.openPorts.isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.backgroundDeep,
      appBar: AppBar(
        title: const Text('Cihaz Detayları'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cihaz üst kartı
            Center(
              child: Column(
                children: [
                  Container(
                    width: 80, height: 80,
                    decoration: BoxDecoration(
                      color: isRisky ? AppColors.danger.withValues(alpha: 0.1) : AppColors.primaryBlue.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      device.isHost ? Icons.phone_android_rounded : Icons.desktop_windows_rounded, 
                      size: 40,
                      color: isRisky ? AppColors.danger : AppColors.primaryBlue,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(device.deviceName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                  const SizedBox(height: 8),
                  Text(device.vendorName, style: const TextStyle(fontSize: 14, color: AppColors.textSecondary)),
                ],
              ),
            ),
            const SizedBox(height: 32),
            
            // Bilgiler
            const Text('Ağ Bilgileri', style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _buildInfoRow('IP Adresi', device.ipAddress),
            _buildInfoRow('MAC Adresi', device.macAddress),
            
            const SizedBox(height: 32),
            
            // Açık Portlar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Açık Portlar', style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
                Text('${device.openPorts.length}', style: TextStyle(color: isRisky ? AppColors.danger : AppColors.textSecondary, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 12),
            if (device.openPorts.isEmpty)
               Container(
                 padding: const EdgeInsets.all(16),
                 decoration: BoxDecoration(
                   color: AppColors.safe.withValues(alpha: 0.1),
                   borderRadius: BorderRadius.circular(12),
                   border: Border.all(color: AppColors.safe.withValues(alpha: 0.3)),
                 ),
                 child: const Row(
                   children: [
                     Icon(Icons.check_circle_rounded, color: AppColors.safe, size: 24),
                     SizedBox(width: 12),
                     Text('Bilinen bir açık port tespit edilmedi.', style: TextStyle(color: AppColors.safe)),
                   ],
                 ),
               )
            else
               ...device.openPorts.map((port) => _buildPortTile(context, port)),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.backgroundCard,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: const TextStyle(color: AppColors.textSecondary)),
            Text(value, style: const TextStyle(color: AppColors.textPrimary, fontFamily: 'JetBrains Mono', fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _buildPortTile(BuildContext context, int port) {
    final info = PortRiskDatabase.getPortInfo(port);
    final riskLevel = info.riskLevel;
    final description = info.description;
    
    Color riskColor;
    switch (riskLevel) {
      case 'high':
        riskColor = AppColors.danger;
        break;
      case 'medium':
        riskColor = AppColors.warning;
        break;
      case 'low':
      default:
        riskColor = AppColors.safe;
        break;
    }

    return InkWell(
      onTap: () {
        context.push('/portDictionary', extra: port);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.backgroundCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: riskColor.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: riskColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
              child: Text(port.toString(), style: TextStyle(color: riskColor, fontWeight: FontWeight.bold, fontFamily: 'JetBrains Mono')),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                description,
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Icon(Icons.info_outline_rounded, color: AppColors.textHint, size: 20),
          ],
        ),
      ),
    );
  }
}
