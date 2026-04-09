import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/hive_service.dart';
import '../../auth/providers/auth_provider.dart';
import '../../scan/providers/scan_provider.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  List<Map<String, dynamic>> _scans = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final history = HiveService.getScanHistory();
    setState(() {
      _scans = history;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDeep,
      appBar: AppBar(
        title: const Text('Tarama Geçmişi'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep_rounded),
            onPressed: () async {
              await HiveService.clearHistory();
              _loadHistory();
            },
          ),
        ],
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : _scans.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.history_rounded, size: 64, color: AppColors.textHint.withValues(alpha: 0.5)),
                    const SizedBox(height: 16),
                    const Text('Henüz bir tarama geçmişi yok.', style: TextStyle(color: AppColors.textSecondary)),
                  ],
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _scans.length,
                itemBuilder: (context, index) {
                  final scan = _scans[index];
                  final date = DateTime.tryParse(scan['scannedAt'] ?? '') ?? DateTime.now();
                  final score = scan['securityScore'] as int? ?? 0;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: AppColors.backgroundCard,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.backgroundBorder.withValues(alpha: 0.3)),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      leading: CircularProgressIndicator(
                        value: score / 100.0,
                        backgroundColor: AppColors.backgroundDeep,
                        color: score > 70 ? AppColors.safe : (score > 40 ? AppColors.warning : AppColors.danger),
                        strokeWidth: 4,
                      ),
                      title: Text(
                        scan['networkName'] ?? 'Bilinmeyen Ağ',
                        style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        '${DateFormat('dd MMM yyyy, HH:mm').format(date)} · ${scan['deviceCount']} Cihaz',
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                      ),
                      trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textHint),
                      onTap: () => _showScanDetail(context, scan),
                    ),
                  );
                },
              ),
    );
  }

  void _showScanDetail(BuildContext context, Map<String, dynamic> scan) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: const BoxDecoration(
          color: AppColors.backgroundCard,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.textHint, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 24),
            Text(scan['networkName'] ?? 'Ağ Detayları', style: const TextStyle(color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                children: [
                  _summaryRow('Güvenlik Skoru', '${scan['securityScore']}/100'),
                  _summaryRow('Cihaz Sayısı', '${scan['deviceCount']}'),
                  _summaryRow('Şüpheli Cihaz', '${scan['suspiciousCount']}'),
                  _summaryRow('Açık Port', '${scan['openPortCount']}'),
                  const Divider(color: AppColors.backgroundBorder),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text('Tespit Edilen Cihazlar', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
                  ),
                  if (scan['devices'] != null)
                    ...(scan['devices'] as List).map((d) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(d['name'] ?? d['ip'] ?? 'Bilinmeyen Cihaz', style: const TextStyle(color: AppColors.textPrimary, fontSize: 14)),
                      subtitle: Text(d['vendor'] ?? 'Bilinmiyor', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                      trailing: Text('${(d['ports'] as List?)?.length ?? 0} Port', style: const TextStyle(color: AppColors.textHint, fontSize: 12)),
                    )),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textSecondary)),
          Text(value, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
