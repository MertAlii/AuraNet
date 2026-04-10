import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/score_ring.dart';
import '../../../shared/widgets/stat_card.dart';
import '../providers/home_provider.dart';
import '../../auth/providers/auth_provider.dart';

/// Ana ekran — Dashboard
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  List<String> _missingPermissions = [];

  @override
  void initState() {
    super.initState();
    _checkAndRequestPermissions();
  }

  Future<void> _checkAndRequestPermissions() async {
    final status = await Permission.location.request();
    if (status != PermissionStatus.granted) {
      setState(() {
        _missingPermissions.add('Konum İzni (Ağ taraması ve SSID için gereklidir)');
      });
    }
  }

  Widget _buildPermissionWarning() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.danger.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.danger.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: AppColors.danger),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Eksik İzinler',
                  style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Aşağıdaki izinler verilmemiştir. Uygulama bu yüzden stabil çalışmayabilir:',
            style: TextStyle(color: AppColors.danger, fontSize: 13),
          ),
          const SizedBox(height: 8),
          ..._missingPermissions.map((p) => Text('• $p', style: const TextStyle(color: AppColors.danger, fontSize: 13, fontWeight: FontWeight.w600))),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                openAppSettings();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.danger,
                foregroundColor: Colors.white,
              ),
              child: const Text('Ayarlara Git'),
            ),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final homeState = ref.watch(homeProvider);
    final authState = ref.watch(authProvider);
    final userName = authState.user?.displayName ?? 'Kullanıcı';

    return Scaffold(
      backgroundColor: AppColors.backgroundDeep,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // İzin uyarı bloğu
            if (_missingPermissions.isNotEmpty)
              SliverToBoxAdapter(
                child: _buildPermissionWarning(),
              ),
            // Üst karşılama
            SliverToBoxAdapter(
              child: _buildHeader(context, userName, homeState),
            ),
            // Güvenlik skoru
            SliverToBoxAdapter(
              child: _buildSecurityScore(context, ref, homeState),
            ),
            // Özet kartları
            SliverToBoxAdapter(
              child: _buildSummaryCards(homeState),
            ),
            // Cihazlar ve Güvenlik (Hızlı Erişim)
            SliverToBoxAdapter(
              child: _buildQuickAccess(homeState),
            ),
            // Gelişmiş Araçlar (Sadece Navbar'da olmayanlar)
            SliverToBoxAdapter(
              child: _buildAdvancedTools(homeState),
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
          // Tarama Geçmişi butonu
          IconButton(
            icon: const Icon(Icons.history_rounded, color: AppColors.textSecondary),
            onPressed: () => context.push('/history'),
          ),
          const SizedBox(width: 8),
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

  Widget _buildSecurityScore(BuildContext context, WidgetRef ref, HomeState state) {
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
            const SizedBox(height: 24),
            _buildCentralScanButton(context, ref, state),
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
            child: GestureDetector(
              onTap: () => context.push('/devices?filter=all'),
              child: StatCard(
                icon: Icons.devices_rounded,
                label: 'Cihazlar',
                value: '${state.deviceCount}',
                color: AppColors.primaryBlue,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: GestureDetector(
              onTap: () => context.push('/devices?filter=open_ports'),
              child: StatCard(
                icon: Icons.lan_outlined,
                label: 'Açık Port',
                value: '${state.openPortCount}',
                color: AppColors.warning,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: GestureDetector(
              onTap: () => context.push('/devices?filter=suspicious'),
              child: StatCard(
                icon: Icons.warning_amber_rounded,
                label: 'Şüpheli',
                value: '${state.suspiciousCount}',
                color: AppColors.danger,
              ),
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
              icon: Icons.devices_rounded,
              title: 'Cihazlar',
              subtitle: state.deviceCount > 0
                  ? '${state.deviceCount} cihaz tespit edildi'
                  : 'Ağınızı tarayın',
              color: AppColors.safe,
              onTap: () {
                context.push('/devices?filter=all');
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdvancedTools(HomeState state) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Row(
        children: [
          Expanded(
            child: _quickAccessCard(
              icon: Icons.security_rounded,
              title: 'Gelişmiş Güvenlik',
              subtitle: 'DNS Sızıntı & ARP Koruması',
              color: AppColors.warning,
              onTap: () => context.push('/security'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _quickAccessCard(
              icon: Icons.school_rounded,
              title: 'Akademi (Blog)',
              subtitle: 'Ağ Güvenliğini Öğrenin',
              color: AppColors.primaryBlueLight,
              onTap: () => context.push('/blog'),
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

  Widget _buildCentralScanButton(BuildContext context, WidgetRef ref, HomeState state) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: state.isScanning ? null : () => _showScanOptions(context),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryBlueDark,
          foregroundColor: AppColors.primaryBlueLight,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
        ),
        child: state.isScanning
            ? const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20, height: 20,
                    child: CircularProgressIndicator(color: AppColors.primaryBlueLight, strokeWidth: 2.5),
                  ),
                  SizedBox(width: 12),
                  Text('Taranıyor...', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ],
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.radar_rounded, size: 22),
                  SizedBox(width: 8),
                  Text('Ağınızı Tarayın', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ],
              ),
      ),
    );
  }

  void _showScanOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: AppColors.backgroundCard,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tarama Türü Seçin',
              style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildScanOptionTile(
              context: ctx,
              icon: Icons.wifi_find_rounded,
              title: 'Sadece Wi-Fi Taraması',
              subtitle: 'Ağdaki cihazları port araması yapmadan, anında tespit eder.',
              color: AppColors.primaryBlueLight,
              onTap: () {
                Navigator.pop(ctx);
                ctx.push('/scan', extra: 'wifi');
              },
            ),
            const SizedBox(height: 12),
            _buildScanOptionTile(
              context: ctx,
              icon: Icons.bolt_rounded,
              title: 'Hızlı Port Taraması',
              subtitle: 'Ağdaki cihazları ve yaygın 20 zafiyet portunu tarar.',
              color: AppColors.safe,
              onTap: () {
                Navigator.pop(ctx);
                ctx.push('/scan', extra: 'fast');
              },
            ),
            const SizedBox(height: 12),
            _buildScanOptionTile(
              context: ctx,
              icon: Icons.search_rounded,
              title: 'Derin Tarama (Premium)',
              subtitle: 'Tüm portları (1-65535) ve cihaz açıklarını detaylı tarar.',
              color: AppColors.primaryBlue,
              onTap: () {
                Navigator.pop(ctx);
                ctx.push('/scan', extra: 'deep');
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildScanOptionTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.backgroundBorder.withValues(alpha: 0.5)),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
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
