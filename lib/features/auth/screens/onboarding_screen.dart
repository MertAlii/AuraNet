import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/hive_service.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int _currentPage = 0;
  bool _isRootGranted = false;
  bool _checkingRoot = false;

  final PageController _pageController = PageController();

  Future<void> _checkRoot() async {
    setState(() => _checkingRoot = true);
    
    try {
      final res = await Process.run('su', ['-c', 'echo "root access granted"']).timeout(const Duration(seconds: 2));
      if (res.exitCode == 0) {
        setState(() => _isRootGranted = true);
        await HiveService.setRootMode(true);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Root yetkisi doğrulandı!', style: TextStyle(color: AppColors.safe))),
          );
        }
      } else {
        throw Exception('Root erişimi reddedildi');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Root izni alınamadı. Cihazınız rootsuz algılanacaktır.', style: TextStyle(color: AppColors.warning))),
        );
      }
    } finally {
      setState(() => _checkingRoot = false);
    }
  }

  void _finishOnboarding() async {
    await HiveService.setSeenOnboarding(true);
    if (mounted) {
      context.go('/home'); // Auth sistemine bağlı olmadığı durumda Home'a geçer, ancak router karar verir
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDeep,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (idx) => setState(() => _currentPage = idx),
                physics: const NeverScrollableScrollPhysics(), // Scroll manuel kontrol edilecek
                children: [
                  _buildWelcomePage(),
                  _buildPermissionsPage(),
                  _buildRootConfigPage(),
                ],
              ),
            ),
            _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: List.generate(
              3,
              (index) => Container(
                margin: const EdgeInsets.only(right: 8),
                width: _currentPage == index ? 24 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _currentPage == index ? AppColors.primaryBlue : AppColors.backgroundSurface,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              if (_currentPage < 2) {
                _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
              } else {
                _finishOnboarding();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlueDark,
              foregroundColor: AppColors.primaryBlueLight,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
            child: Text(_currentPage == 2 ? 'Giriş Yap' : 'İleri'),
          )
        ],
      ),
    );
  }

  Widget _buildWelcomePage() {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: AppColors.primaryBlue.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: const Icon(Icons.radar_rounded, size: 72, color: AppColors.primaryBlue),
          ),
          const SizedBox(height: 48),
          const Text(
            'AuraNet\'e Hoş Geldiniz',
            style: TextStyle(color: AppColors.textPrimary, fontSize: 28, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          const Text(
            'Yeni nesil ağ analizi ve siber güvenlik aracınız. Ağ verilerinizi yerel ağda güvenle inceleyin ve koruyun.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionsPage() {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.security_rounded, size: 64, color: AppColors.warning),
          const SizedBox(height: 32),
          const Text(
            'İzinler Neden Gerekli?',
            style: TextStyle(color: AppColors.textPrimary, fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          _buildPermissionItem(
            Icons.location_on_rounded,
            'Konum İzni',
            'Wi-Fi cihaz taraması yapabilmek ve ağ isminizi (SSID) görebilmek için Android Konum izinlerini zorunlu koşmaktadır.',
          ),
          const SizedBox(height: 20),
          _buildPermissionItem(
            Icons.notifications_active_rounded,
            'Bildirim İzni',
            'Siz arkaplandayken ağınıza sızan/bağlanan cihazları anlık bildirebilmek için kullanılır.',
          ),
          const Spacer(),
          ElevatedButton(
            onPressed: () async {
              await [Permission.location, Permission.notification].request();
              _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
            },
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
              backgroundColor: AppColors.warning.withValues(alpha: 0.2),
              foregroundColor: AppColors.warning,
            ),
            child: const Text('İzinleri Ver'),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionItem(IconData icon, String title, String desc) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: AppColors.backgroundSurface, borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: AppColors.textHint, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(desc, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            ],
          ),
        )
      ],
    );
  }

  Widget _buildRootConfigPage() {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.adb_rounded, size: 64, color: AppColors.safe),
          const SizedBox(height: 32),
          const Text(
            'Cihazınız Rootlu Mu?',
            style: TextStyle(color: AppColors.textPrimary, fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          const Text(
            'Modern Android sistemlerinde (A10+) diğer cihazların MAC adreslerini okumak engellenmiştir. Ağdaki MAC adreslerini kesin olarak görebilmek için cihazın ROOT yetkisine sahip olması gerekir.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          _buildConfigCard(
            title: 'Rootsuz Kullan (Varsayılan)',
            subtitle: 'Basit tarama. MAC adresleri 00:00:00 görünebilir.',
            icon: Icons.shield_outlined,
            isSelected: !_isRootGranted,
            onTap: () {
               HiveService.setRootMode(false);
               setState(() => _isRootGranted = false);
            },
          ),
          const SizedBox(height: 16),
          _buildConfigCard(
            title: 'Rootlu Cihaz',
            subtitle: 'Gelişmiş ağ tarama özelliklerini aktifleştir.',
            icon: Icons.developer_mode_rounded,
            isSelected: _isRootGranted,
            onTap: () => _checkRoot(),
          ),
          if (_checkingRoot) const Padding(
             padding: EdgeInsets.only(top: 24),
             child: CircularProgressIndicator(),
          ),
        ],
      ),
    );
  }

  Widget _buildConfigCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.safe.withValues(alpha: 0.15) : AppColors.backgroundSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSelected ? AppColors.safe : Colors.transparent, width: 2),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? AppColors.safe : AppColors.textHint, size: 32),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                ],
              ),
            ),
            if (isSelected) const Icon(Icons.check_circle_rounded, color: AppColors.safe),
          ],
        ),
      ),
    );
  }
}
