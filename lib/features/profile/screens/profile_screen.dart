import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/profile_provider.dart';

/// Profil ekranı
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);
    final authState = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundDeep,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              const SizedBox(height: 20),
              // Başlık
              const Row(
                children: [
                  Text(
                    'Profil',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Avatar & İsim
              _buildProfileCard(profile),
              const SizedBox(height: 16),
              // Abonelik durumu
              _buildSubscriptionCard(profile),
              const SizedBox(height: 16),
              // İstatistikler
              _buildStatsCard(profile),
              const SizedBox(height: 16),
              // Rozetler
              _buildBadgesCard(profile),
              const SizedBox(height: 16),
              // Ayarlar menüsü
              _buildSettingsMenu(context, ref),
              const SizedBox(height: 16),
              // Tehlikeli işlemler
              _buildDangerZone(context, ref, authState),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileCard(ProfileState profile) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.backgroundBorder.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
                profile.displayName.isNotEmpty
                    ? profile.displayName[0].toUpperCase()
                    : '?',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile.displayName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  profile.email,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubscriptionCard(ProfileState profile) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: profile.isPremium
            ? const LinearGradient(
                colors: [Color(0xFF2A1F00), Color(0xFF1E1E35)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: profile.isPremium ? null : AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: profile.isPremium
              ? AppColors.premium.withValues(alpha: 0.3)
              : AppColors.backgroundBorder.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: (profile.isPremium ? AppColors.premium : AppColors.primaryBlue)
                  .withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              profile.isPremium ? Icons.workspace_premium_rounded : Icons.star_outline_rounded,
              color: profile.isPremium ? AppColors.premium : AppColors.primaryBlue,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile.isPremium ? 'Premium Üye' : 'Ücretsiz Plan',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: profile.isPremium ? AppColors.premium : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  profile.isPremium
                      ? 'Tüm özellikler aktif'
                      : 'Premium\'a geçerek tüm özellikleri açın',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (!profile.isPremium)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                gradient: AppColors.premiumGradient,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'Yükselt',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatsCard(ProfileState profile) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.backgroundBorder.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'İstatistikler',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 14),
          _statRow(Icons.radar_rounded, 'Toplam Tarama', '${profile.totalScans}'),
          const SizedBox(height: 10),
          _statRow(Icons.emoji_events_rounded, 'Kazanılan Rozet', '${profile.badges.length}'),
        ],
      ),
    );
  }

  Widget _statRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primaryBlue, size: 20),
        const SizedBox(width: 10),
        Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildBadgesCard(ProfileState profile) {
    final allBadges = [
      {'id': 'first_scan', 'name': 'İlk Tarama', 'emoji': '🔍'},
      {'id': 'detective', 'name': 'Dedektif', 'emoji': '🕵️'},
      {'id': 'regular', 'name': 'Düzenli Kullanıcı', 'emoji': '📅'},
      {'id': 'high_score', 'name': '90+ Puan', 'emoji': '🏆'},
      {'id': 'namer', 'name': 'İsimlendirici', 'emoji': '📝'},
      {'id': 'speed_fan', 'name': 'Hız Tutkunu', 'emoji': '⚡'},
    ];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.backgroundBorder.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Başarımlar',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: allBadges.map((b) {
              final earned = profile.badges.contains(b['id']);
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: earned
                      ? AppColors.primaryBlue.withValues(alpha: 0.12)
                      : AppColors.backgroundSurface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: earned
                        ? AppColors.primaryBlue.withValues(alpha: 0.3)
                        : AppColors.backgroundBorder.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      b['emoji']!,
                      style: TextStyle(
                        fontSize: 16,
                        color: earned ? null : AppColors.textHint,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      b['name']!,
                      style: TextStyle(
                        fontSize: 12,
                        color: earned ? AppColors.textPrimary : AppColors.textHint,
                        fontWeight: earned ? FontWeight.w500 : FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsMenu(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.backgroundBorder.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          _menuItem(
            icon: Icons.language_rounded,
            title: 'Dil',
            subtitle: 'Türkçe',
            onTap: () {},
          ),
          _divider(),
          _menuItem(
            icon: Icons.dark_mode_rounded,
            title: 'Tema',
            subtitle: 'Koyu',
            onTap: () {},
          ),
          _divider(),
          _menuItem(
            icon: Icons.privacy_tip_outlined,
            title: 'Gizlilik Politikası',
            onTap: () {},
          ),
          _divider(),
          _menuItem(
            icon: Icons.description_outlined,
            title: 'Kullanım Koşulları',
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _menuItem({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: AppColors.textSecondary, size: 22),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            if (subtitle != null)
              Text(
                subtitle,
                style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right_rounded, color: AppColors.textHint, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _divider() {
    return Divider(
      height: 1,
      indent: 54,
      color: AppColors.backgroundBorder.withValues(alpha: 0.3),
    );
  }

  Widget _buildDangerZone(BuildContext context, WidgetRef ref, AuthState authState) {
    return Column(
      children: [
        // Çıkış Yap
        SizedBox(
          width: double.infinity,
          height: 50,
          child: OutlinedButton.icon(
            onPressed: () async {
              final confirm = await _showConfirmDialog(
                context,
                'Çıkış Yap',
                'Hesabınızdan çıkış yapmak istediğinize emin misiniz?',
              );
              if (confirm == true) {
                await ref.read(authProvider.notifier).signOut();
                if (context.mounted) context.go('/login');
              }
            },
            icon: const Icon(Icons.logout_rounded, size: 20),
            label: const Text('Çıkış Yap'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.textSecondary,
              side: BorderSide(color: AppColors.backgroundBorder.withValues(alpha: 0.5)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ),
        const SizedBox(height: 10),
        // Hesabı Sil
        SizedBox(
          width: double.infinity,
          height: 50,
          child: OutlinedButton.icon(
            onPressed: () async {
              final confirm = await _showConfirmDialog(
                context,
                'Hesabı Sil',
                'Hesabınız ve tüm verileriniz kalıcı olarak silinecektir. Bu işlem geri alınamaz!',
                isDanger: true,
              );
              if (confirm == true) {
                await ref.read(authProvider.notifier).deleteAccount();
                if (context.mounted) context.go('/login');
              }
            },
            icon: const Icon(Icons.delete_forever_rounded, size: 20),
            label: const Text('Hesabı Sil'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.danger,
              side: BorderSide(color: AppColors.danger.withValues(alpha: 0.4)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ),
      ],
    );
  }

  Future<bool?> _showConfirmDialog(
    BuildContext context,
    String title,
    String message, {
    bool isDanger = false,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.backgroundCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(
          title,
          style: TextStyle(
            color: isDanger ? AppColors.danger : AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          message,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('İptal', style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              'Evet',
              style: TextStyle(
                color: isDanger ? AppColors.danger : AppColors.primaryBlue,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
