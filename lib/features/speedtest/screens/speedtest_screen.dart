import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/hive_service.dart';
import '../providers/speedtest_provider.dart';

class SpeedtestScreen extends ConsumerStatefulWidget {
  const SpeedtestScreen({super.key});

  @override
  ConsumerState<SpeedtestScreen> createState() => _SpeedtestScreenState();
}

class _SpeedtestScreenState extends ConsumerState<SpeedtestScreen> with TickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(CurvedAnimation(parent: _animController, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final speedState = ref.watch(speedtestProvider);
    final isTesting = speedState.isTesting;

    return Scaffold(
      appBar: AppBar(title: const Text('Hız Testi')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 20),
            // Gauge Animation Area
            Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 250,
                    height: 250,
                    child: CircularProgressIndicator(
                      value: isTesting ? (speedState.currentValue / 150).clamp(0.0, 1.0) : 0,
                      strokeWidth: 15,
                      backgroundColor: AppColors.backgroundBorder.withValues(alpha: 0.3),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        speedState.phase.contains('Yükleme') ? AppColors.warning : AppColors.primaryBlueLight
                      ),
                    ),
                  ),
                  if (isTesting)
                    ScaleTransition(
                      scale: _pulseAnimation,
                      child: Container(
                        width: 150,
                        height: 150,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primaryBlue.withValues(alpha: 0.1),
                        ),
                      ),
                    ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        isTesting ? speedState.currentValue.toStringAsFixed(1) : (speedState.phase == 'Tamamlandı' ? speedState.download.toStringAsFixed(1) : 'GO'),
                        style: TextStyle(
                          fontSize: isTesting ? 48 : 56,
                          fontWeight: FontWeight.bold,
                          color: isTesting ? AppColors.textPrimary : AppColors.primaryBlueLight,
                        ),
                      ),
                      if (isTesting || speedState.phase == 'Tamamlandı')
                        const Text(
                          'Mbps',
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
                        ),
                    ],
                  )
                ],
              ),
            ),
            const SizedBox(height: 48),

            // Status Text
            Text(
              speedState.phase,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 24),

            // Result Cards
            Row(
              children: [
                Expanded(child: _buildResultCard('Ping', '${speedState.ping.toStringAsFixed(0)} ms', Icons.compare_arrows_rounded, AppColors.safe)),
                const SizedBox(width: 16),
                Expanded(child: _buildResultCard('Download', speedState.download.toStringAsFixed(1), Icons.download_rounded, AppColors.primaryBlueLight)),
                const SizedBox(width: 16),
                Expanded(child: _buildResultCard('Upload', speedState.upload.toStringAsFixed(1), Icons.upload_rounded, AppColors.warning)),
              ],
            ),
            const SizedBox(height: 48),

            // Start Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: isTesting ? null : () => ref.read(speedtestProvider.notifier).startTest(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlueDark,
                  foregroundColor: AppColors.primaryBlueLight,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: Text(
                  speedState.phase == 'Tamamlandı' ? 'Yeniden Test Et' : 'Testi Başlat',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            // Son Testler başlığı
            const SizedBox(height: 48),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Son Testler',
                style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 16),
            _buildHistoryList(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryList() {
    final history = HiveService.getSpeedtestHistory();
    if (history.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.backgroundCard,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: Text('Henüz test geçmişi yok', style: TextStyle(color: AppColors.textHint)),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: history.length,
      itemBuilder: (context, index) {
        final item = history[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.backgroundCard,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Text(
                    item['createdAt'].toString().substring(0, 10), 
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  const Text('Wi-Fi Ağı', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w500)),
                ],
              ),
              Row(
                children: [
                   _buildMiniStat(item['download'].toStringAsFixed(1), 'DL', AppColors.primaryBlueLight),
                   const SizedBox(width: 12),
                   _buildMiniStat(item['upload'].toStringAsFixed(1), 'UL', AppColors.warning),
                ],
              )
            ],
          ),
        );
      },
    );
  }

  Widget _buildMiniStat(String value, String label, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 15)),
        Text(label, style: const TextStyle(color: AppColors.textHint, fontSize: 10)),
      ],
    );
  }

  Widget _buildResultCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.backgroundBorder.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 12),
          Text(title, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
