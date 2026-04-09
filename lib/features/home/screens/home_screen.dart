import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/score_ring.dart';
import '../../../shared/widgets/stat_card.dart';
import '../providers/home_provider.dart';
import '../../auth/providers/auth_provider.dart';

/// Ana ekran — Dashboard
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final homeState = ref.watch(homeProvider);
    final authState = ref.watch(authProvider);
    final userName = authState.user?.displayName ?? 'Kullanıcı';

    return Scaffold(
      backgroundColor: AppColors.backgroundDeep,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Üst karşılama
            SliverToBoxAdapter(
              child: _buildHeader(context, userName, homeState),
            ),
            // Güvenlik skoru
            SliverToBoxAdapter(
              child: _buildSecurityScore(homeState),
            ),
            // Özet kartları
            SliverToBoxAdapter(
              child: _buildSummaryCards(homeState),
            ),
            // Hızlı erişim
            SliverToBoxAdapter(
              child: _buildQuickAccess(homeState),
            ),
            // Son uyarılar
            SliverToBoxAdapter(
              child: _buildRecentAlerts(homeState),
            ),
            const SliverToBoxAdapter(
              child: SizedBox(height: 80),
            ),
          ],
        ),
      ),
      // Tara FAB
      floatingActionButton: _buildScanFab(ref, homeState),
    );
  }

  Widget _buildHeader(BuildContext context, String userName, HomeState state) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Merhaba, $userName 👋',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: state.networkName != null ? AppColors.safe : AppColors.textHint,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      state.networkName ?? 'Ağ bilgisi yok',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Profil avatarı
          GestureDetector(
            onTap: () {
              // Profile navigation Faz sonrası
            },
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Text(
                  userName.isNotEmpty ? userName[0].toUpperCase() : '?',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityScore(HomeState state) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.backgroundCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.backgroundBorder.withValues(alpha: 0.3)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          children: [
            const Text(
              'Ağ Güvenlik Skoru',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            ScoreRing(
              score: state.securityScore,
              size: 140,
            ),
            const SizedBox(height: 12),
            _buildRiskLabel(state.securityScore),
          ],
        ),
      ),
    );
  }

  Widget _buildRiskLabel(int score) {
    Color color;
    String label;
    IconData icon;

    if (score == 0) {
      color = AppColors.textHint;
      label = 'Tarama yapılmadı';
      icon = Icons.info_outline;
    } else if (score <= 40) {
      color = AppColors.danger;
      label = 'Yüksek Risk';
      icon = Icons.warning_rounded;
    } else if (score <= 70) {
      color = AppColors.warning;
      label = 'Orta Risk';
      icon = Icons.shield_outlined;
    } else {
      color = AppColors.safe;
      label = 'Düşük Risk';
      icon = Icons.verified_user_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards(HomeState state) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: StatCard(
              icon: Icons.devices_rounded,
              label: 'Cihazlar',
              value: '${state.deviceCount}',
              color: AppColors.primaryBlue,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: StatCard(
              icon: Icons.lan_outlined,
              label: 'Açık Port',
              value: '${state.openPortCount}',
              color: AppColors.warning,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: StatCard(
              icon: Icons.warning_amber_rounded,
              label: 'Şüpheli',
              value: '${state.suspiciousCount}',
              color: AppColors.danger,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAccess(HomeState state) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          Expanded(
            child: _quickAccessCard(
              icon: Icons.speed_rounded,
              title: 'Speedtest',
              subtitle: state.lastDownloadSpeed > 0
                  ? '${state.lastDownloadSpeed.toStringAsFixed(1)} Mbps'
                  : 'Test et',
              color: AppColors.primaryBlue,
              onTap: () {},
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _quickAccessCard(
              icon: Icons.devices_rounded,
              title: 'Cihazlar',
              subtitle: state.deviceCount > 0
                  ? '${state.deviceCount} cihaz'
                  : 'Tara',
              color: AppColors.safe,
              onTap: () {},
            ),
          ),
        ],
      ),
    );
  }

  Widget _quickAccessCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.backgroundCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.backgroundBorder.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentAlerts(HomeState state) {
    if (state.securityScore == 0) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.backgroundCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.backgroundBorder.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.radar_rounded, color: AppColors.primaryBlue, size: 24),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Henüz tarama yapılmadı',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Ağınızı taramak için aşağıdaki butona dokunun',
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildScanFab(WidgetRef ref, HomeState state) {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryBlue.withValues(alpha: 0.4),
            blurRadius: 20,
            spreadRadius: 2,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: FloatingActionButton(
        onPressed: state.isScanning ? null : () => ref.read(homeProvider.notifier).startScan(),
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: state.isScanning
            ? const SizedBox(
                width: 26, height: 26,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
              )
            : const Icon(Icons.radar_rounded, color: Colors.white, size: 30),
      ),
    );
  }
}
