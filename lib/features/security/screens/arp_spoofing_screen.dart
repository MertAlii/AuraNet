import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/arp_service.dart';

class ArpSpoofingScreen extends ConsumerStatefulWidget {
  const ArpSpoofingScreen({super.key});

  @override
  ConsumerState<ArpSpoofingScreen> createState() => _ArpSpoofingScreenState();
}

class _ArpSpoofingScreenState extends ConsumerState<ArpSpoofingScreen> {
  bool _isLoading = true;
  Map<String, String> _arpTable = {};
  List<String> _warnings = [];

  @override
  void initState() {
    super.initState();
    _scanArp();
  }

  Future<void> _scanArp() async {
    setState(() => _isLoading = true);
    
    // Simulate slight delay for UX
    await Future.delayed(const Duration(seconds: 1));
    
    final table = await ArpService.getArpTable();
    final warnings = ArpService.detectSpoofing(table);

    if (mounted) {
      setState(() {
        _arpTable = table;
        _warnings = warnings;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDeep,
      appBar: AppBar(
        title: const Text('ARP Spoofing Analizi'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _isLoading ? null : _scanArp,
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryBlue))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildStatusCard(),
                  const SizedBox(height: 24),
                  if (_warnings.isNotEmpty) ...[
                    _buildWarningsCard(),
                    const SizedBox(height: 24),
                  ],
                  _buildArpTableCard(),
                ],
              ),
            ),
    );
  }

  Widget _buildStatusCard() {
    final isSafe = _warnings.isEmpty;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isSafe ? AppColors.safe.withOpacity(0.3) : AppColors.danger.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(
            isSafe ? Icons.gpp_good_rounded : Icons.gpp_bad_rounded,
            color: isSafe ? AppColors.safe : AppColors.danger,
            size: 64,
          ),
          const SizedBox(height: 16),
          Text(
            isSafe ? 'Ağınız Güvende' : 'Tehdit Tespit Edildi!',
            style: TextStyle(
              color: isSafe ? AppColors.safe : AppColors.danger,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isSafe
                ? 'ARP tablonuzda herhangi bir anomali veya Man-in-the-Middle (MITM) saldırısı belirtisi bulunamadı.'
                : 'Ağınızda MAC adresi çakışmaları veya şüpheli yönlendirmeler var. Bu bir siber saldırı belirtisi olabilir.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildWarningsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.danger.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.danger.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: AppColors.danger),
              SizedBox(width: 12),
              Text('Güvenlik Uyarıları', style: TextStyle(color: AppColors.danger, fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),
          ..._warnings.map((w) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• ', style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.bold)),
                    Expanded(child: Text(w, style: const TextStyle(color: AppColors.textPrimary, fontSize: 14))),
                  ],
                ),
              ))
        ],
      ),
    );
  }

  Widget _buildArpTableCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primaryBlue.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.device_hub_rounded, color: AppColors.primaryBlueLight),
              SizedBox(width: 12),
              Text('Yerel ARP Tablosu', style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),
          if (_arpTable.isEmpty)
            const Text('ARP tablosu boş veya sistem tarafından kısıtlanmış.', style: TextStyle(color: AppColors.textHint, fontSize: 13))
          else
            ..._arpTable.entries.map((entry) {
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: AppColors.backgroundDeep, borderRadius: BorderRadius.circular(8)),
                child: Row(
                  children: [
                    const Icon(Icons.computer_rounded, color: AppColors.textSecondary, size: 20),
                    const SizedBox(width: 12),
                    Expanded(child: Text(entry.key, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold))),
                    Text(entry.value, style: const TextStyle(color: AppColors.textHint, fontFamily: 'JetBrains Mono', fontSize: 12)),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}
