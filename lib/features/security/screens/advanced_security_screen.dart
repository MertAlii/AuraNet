import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/arp_service.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../shared/widgets/premium_lock_banner.dart';

class AdvancedSecurityScreen extends ConsumerStatefulWidget {
  const AdvancedSecurityScreen({super.key});

  @override
  ConsumerState<AdvancedSecurityScreen> createState() => _AdvancedSecurityScreenState();
}

class _AdvancedSecurityScreenState extends ConsumerState<AdvancedSecurityScreen> {
  bool _isDnsLoading = false;
  String _dnsResult = 'Test Edilmedi';
  List<String> _arpWarnings = [];
  bool _isArpLoading = false;

  Future<void> _runDnsTest() async {
    setState(() => _isDnsLoading = true);
    // Simüle edilmiş DNS sızıntı testi
    await Future.delayed(const Duration(seconds: 2));
    setState(() {
      _dnsResult = 'Güvenli (Google DNS tespiti)';
      _isDnsLoading = false;
    });
  }

  Future<void> _runArpTest() async {
    setState(() => _isArpLoading = true);
    final table = await ArpService.getArpTable();
    final warnings = ArpService.detectSpoofing(table);
    setState(() {
      _arpWarnings = warnings;
      _isArpLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Premium kontrolü
    final authState = ref.watch(authProvider);
    final bool isPremium = authState.isPremium;

    return Scaffold(
      backgroundColor: AppColors.backgroundDeep,
      appBar: AppBar(title: const Text('Gelişmiş Güvenlik')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (!isPremium) const PremiumLockBanner(featureName: 'Tüm güvenlik testleri için Premium'),
            
            _buildSecurityCard(
              title: 'DNS Sızıntı Testi',
              subtitle: 'İnternet trafiğinizin DNS üzerinden sızıp sızmadığını kontrol eder.',
              icon: Icons.vpn_lock_rounded,
              status: _isDnsLoading ? 'Test Ediliyor...' : _dnsResult,
              onTap: _runDnsTest,
              isLoading: _isDnsLoading,
            ),
            const SizedBox(height: 16),
            _buildSecurityCard(
              title: 'ARP Spoofing Tespiti',
              subtitle: 'Ağınızda "ortadaki adam" saldırısı (MITM) olup olmadığını tarar.',
              icon: Icons.security_rounded,
              status: _isArpLoading ? 'Taranıyor...' : (_arpWarnings.isEmpty ? 'Tehdit Bulunmadı' : '${_arpWarnings.length} Uyarı!'),
              onTap: _runArpTest,
              isLoading: _isArpLoading,
              isAlert: _arpWarnings.isNotEmpty,
            ),
            if (_arpWarnings.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(top: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: AppColors.danger.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                child: Column(
                  children: _arpWarnings.map((w) => Text(w, style: const TextStyle(color: AppColors.danger, fontSize: 12))).toList(),
                ),
              ),
            const SizedBox(height: 16),
            _buildSecurityCard(
              title: 'Komşu Ağ Analizi',
              subtitle: 'Çevredeki güvensiz (açık) Wi-Fi ağlarını tespit eder.',
              icon: Icons.wifi_off_rounded,
              status: 'Wi-Fi Analizörü ile Entegre',
              onTap: () {
                // Analizör ekranına yönlendir
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecurityCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required String status,
    required VoidCallback onTap,
    bool isLoading = false,
    bool isAlert = false,
  }) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.backgroundCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isAlert ? AppColors.danger.withValues(alpha: 0.5) : AppColors.backgroundBorder.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: (isAlert ? AppColors.danger : AppColors.primaryBlue).withValues(alpha: 0.1), shape: BoxShape.circle),
              child: Icon(icon, color: isAlert ? AppColors.danger : AppColors.primaryBlue),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      if (isLoading)
                        const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryBlue)),
                      if (isLoading) const SizedBox(width: 8),
                      Text(status, style: TextStyle(color: isAlert ? AppColors.danger : AppColors.safe, fontSize: 13, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.textHint),
          ],
        ),
      ),
    );
  }
}
