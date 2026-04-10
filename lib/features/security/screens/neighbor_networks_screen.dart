import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wifi_scan/wifi_scan.dart';
import '../../../core/constants/app_colors.dart';

class NeighborNetworksScreen extends ConsumerStatefulWidget {
  const NeighborNetworksScreen({super.key});

  @override
  ConsumerState<NeighborNetworksScreen> createState() => _NeighborNetworksScreenState();
}

class _NeighborNetworksScreenState extends ConsumerState<NeighborNetworksScreen> {
  bool _isScanning = false;
  List<WiFiAccessPoint> _accessPoints = [];
  String _error = '';

  @override
  void initState() {
    super.initState();
    _startScan();
  }

  Future<void> _startScan() async {
    setState(() {
      _isScanning = true;
      _error = '';
    });

    try {
      final canScan = await WiFiScan.instance.canStartScan();
      if (canScan != CanStartScan.yes) {
        throw Exception('Wi-Fi tarama izni yok veya desteklenmiyor (Durum: $canScan). Lütfen konum izinlerini kontrol edin.');
      }

      await WiFiScan.instance.startScan();
      
      // Taramaya biraz süre tanı (Android bazen sonuçları gecikmeli döndürür)
      await Future.delayed(const Duration(seconds: 2));

      final results = await WiFiScan.instance.getScannedResults();
      if (mounted) {
        setState(() {
          _accessPoints = results..sort((a, b) => b.level.compareTo(a.level));
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isScanning = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDeep,
      appBar: AppBar(
        title: const Text('Komşu Ağ Analizi'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _isScanning ? null : _startScan,
          )
        ],
      ),
      body: _isScanning && _accessPoints.isEmpty
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: AppColors.primaryBlue),
                  SizedBox(height: 16),
                  Text('Çevredeki ağlar aranıyor...', style: TextStyle(color: AppColors.textSecondary)),
                ],
              ),
            )
          : _accessPoints.isEmpty && !_isScanning
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Text(
                      _error.isNotEmpty ? _error : 'Çevrede ağ bulunamadı.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.danger),
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _accessPoints.length,
                  itemBuilder: (context, index) {
                    final ap = _accessPoints[index];
                    final isSecure = ap.capabilities.contains('WPA') || ap.capabilities.contains('WEP');
                    final is5Ghz = ap.frequency > 5000;
                    
                    int channel = 0;
                    if (ap.frequency >= 2412 && ap.frequency <= 2484) {
                      channel = ap.frequency == 2484 ? 14 : ((ap.frequency - 2407) / 5).round();
                    } else if (ap.frequency >= 5170 && ap.frequency <= 5825) {
                      channel = ((ap.frequency - 5170) / 5).round() + 34;
                    } else if (ap.frequency >= 5955) {
                      channel = ((ap.frequency - 5950) / 5).round(); // 6GHz approximate
                    }
                    
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.backgroundCard,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.backgroundBorder.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isSecure ? Icons.lock_rounded : Icons.lock_open_rounded,
                            color: isSecure ? AppColors.primaryBlue : AppColors.danger,
                            size: 28,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  ap.ssid.isEmpty ? 'Gizli Ağ' : ap.ssid,
                                  style: TextStyle(
                                    color: ap.ssid.isEmpty ? AppColors.textHint : AppColors.textPrimary,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${ap.bssid} • Kanal $channel',
                                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, fontFamily: 'JetBrains Mono'),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: is5Ghz ? Colors.purple.withOpacity(0.2) : Colors.orange.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        is5Ghz ? '5GHz / 6GHz' : '2.4GHz',
                                        style: TextStyle(
                                          color: is5Ghz ? Colors.purple[200] : Colors.orange[200],
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        ap.capabilities,
                                        style: const TextStyle(color: AppColors.textHint, fontSize: 11),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    )
                                  ],
                                )
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '${ap.level} dBm',
                                style: TextStyle(
                                  color: ap.level >= -60 ? AppColors.safe : AppColors.warning,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Icon(Icons.wifi_rounded, color: ap.level >= -60 ? AppColors.safe : AppColors.warning, size: 20),
                            ],
                          )
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}
