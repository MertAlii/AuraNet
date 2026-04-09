import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../auth/providers/auth_provider.dart';

class PremiumScreen extends ConsumerWidget {
  const PremiumScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundDeep,
      appBar: AppBar(title: const Text('Premium')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Icon(Icons.stars_rounded, size: 80, color: AppColors.warning),
            const SizedBox(height: 16),
            const Text(
              'AuraNet Premium',
              style: TextStyle(color: AppColors.textPrimary, fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Ağınızı tam koruma altına alın',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
            ),
            const SizedBox(height: 32),
            _buildFeatureRow(Icons.wifi_find_rounded, 'Detaylı Wi-Fi Analizörü'),
            _buildFeatureRow(Icons.security_rounded, 'ARP Spoofing & DNS Sızıntı Testi'),
            _buildFeatureRow(Icons.search_rounded, 'Tam Port Taraması (1-65535)'),
            _buildFeatureRow(Icons.picture_as_pdf_rounded, 'PDF Tarama Raporu'),
            _buildFeatureRow(Icons.notifications_active_rounded, 'Yeni Cihaz Bildirimleri'),
            const SizedBox(height: 48),
            
            if (authState.isPremium)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: AppColors.safe.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16)),
                child: const Row(
                  children: [
                    Icon(Icons.check_circle_rounded, color: AppColors.safe),
                    SizedBox(width: 12),
                    Text('Premium Üyeliğiniz Aktif!', style: TextStyle(color: AppColors.safe, fontWeight: FontWeight.bold)),
                  ],
                ),
              )
            else
              Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () {
                        _showSimulatedPurchase(context, ref);
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryBlue),
                      child: const Text('Hemen Başla (₺79/Ay)', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Daha Sonra', style: TextStyle(color: AppColors.textSecondary)),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primaryBlueLight, size: 24),
          const SizedBox(width: 16),
          Text(text, style: const TextStyle(color: AppColors.textPrimary, fontSize: 15)),
        ],
      ),
    );
  }

  void _showSimulatedPurchase(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.backgroundCard,
        title: const Text('Satın Alımı Onayla', style: TextStyle(color: AppColors.textPrimary)),
        content: const Text('AuraNet Premium üyeliğini simüle edilecek şekilde satın almak istiyor musunuz?', style: TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('İPTAL', style: TextStyle(color: AppColors.danger))),
          ElevatedButton(
            onPressed: () {
              // Simüle edilen satın alma
              ref.read(authProvider.notifier).setPremium(true);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tebrikler! Artık Premium üyesiniz.')));
            },
            child: const Text('SATIN AL'),
          ),
        ],
      ),
    );
  }
}
