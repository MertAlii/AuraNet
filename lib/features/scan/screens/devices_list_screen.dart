import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/report_service.dart';
import '../../home/providers/home_provider.dart';
import '../providers/scan_provider.dart';
import '../models/device_model.dart';
import 'device_detail_screen.dart';

class DevicesListScreen extends ConsumerStatefulWidget {
  final String? initialFilter; // 'all', 'open_ports', 'suspicious'

  const DevicesListScreen({super.key, this.initialFilter});

  @override
  ConsumerState<DevicesListScreen> createState() => _DevicesListScreenState();
}

class _DevicesListScreenState extends ConsumerState<DevicesListScreen> {
  String _searchQuery = '';
  late String _activeFilter;

  @override
  void initState() {
    super.initState();
    _activeFilter = widget.initialFilter ?? 'all';
  }

  @override
  Widget build(BuildContext context) {
    final scanState = ref.watch(scanProvider);
    
    // Cihazları filtrele
    List<DeviceModel> filteredDevices = scanState.devices.where((device) {
      // Arama filtresi
      final matchesSearch = device.deviceName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                            device.ipAddress.contains(_searchQuery);
      
      if (!matchesSearch) return false;

      // Kategori filtresi
      if (_activeFilter == 'open_ports') return device.openPorts.isNotEmpty;
      if (_activeFilter == 'suspicious') return device.openPorts.length > 2; // Basit şüpheli mantığı
      if (_activeFilter == 'favorites') return device.isFavorite;
      
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.backgroundDeep,
      appBar: AppBar(
        title: const Text('Cihaz Listesi'),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_rounded, color: AppColors.primaryBlueLight),
            onPressed: () async {
              final homeState = ref.read(homeProvider);
              final file = await ReportService.generateScanReport(
                scanState.devices, 
                homeState.networkName ?? 'Bilinmeyen Ağ', 
                homeState.securityScore
              );
              await Share.shareXFiles([XFile(file.path)], text: 'AuraNet Ağ Analiz Raporu');
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.read(scanProvider.notifier).startScan(scanState.currentMode),
          ),
        ],
      ),
      body: Column(
        children: [
          // Arama Çubuğu
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              onChanged: (val) => setState(() => _searchQuery = val),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Cihaz adı veya IP ara...',
                hintStyle: const TextStyle(color: AppColors.textHint),
                prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textSecondary),
                filled: true,
                fillColor: AppColors.backgroundCard,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          
          // Filtre Chip'leri
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _buildFilterChip('Hepsi', 'all'),
                const SizedBox(width: 8),
                _buildFilterChip('Açık Portlar', 'open_ports'),
                const SizedBox(width: 8),
                _buildFilterChip('Şüpheliler', 'suspicious'),
                const SizedBox(width: 8),
                _buildFilterChip('Favoriler', 'favorites'),
              ],
            ),
          ),
          
          const SizedBox(height: 16),

          // Liste
          Expanded(
            child: filteredDevices.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filteredDevices.length,
                    itemBuilder: (context, index) {
                      final device = filteredDevices[index];
                      return _buildDeviceCard(device);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _activeFilter == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) setState(() => _activeFilter = value);
      },
      backgroundColor: AppColors.backgroundCard,
      selectedColor: AppColors.primaryBlue.withOpacity(0.2),
      labelStyle: TextStyle(
        color: isSelected ? AppColors.primaryBlueLight : AppColors.textSecondary,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected ? AppColors.primaryBlue : Colors.transparent,
        ),
      ),
    );
  }

  Widget _buildDeviceCard(DeviceModel device) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.backgroundBorder.withOpacity(0.3)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.primaryBlue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              device.customEmoji ?? (device.isHost ? '🏠' : '📱'),
              style: const TextStyle(fontSize: 24),
            ),
          ),
        ),
        title: Row(
          children: [
            Text(
              device.deviceName,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
            ),
            if (device.isHost)
              Container(
                margin: const EdgeInsets.only(left: 8),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'Siz',
                  style: TextStyle(color: AppColors.primaryBlueLight, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
          ],
        ),
        subtitle: Text(
          '${device.ipAddress} • ${device.vendorName}',
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
        trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textHint),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DeviceDetailScreen(device: device),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.devices_other_rounded, size: 64, color: AppColors.textHint.withOpacity(0.3)),
          const SizedBox(height: 16),
          Text(
            'Cihaz bulunamadı',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
          ),
        ],
      ),
    );
  }
}
