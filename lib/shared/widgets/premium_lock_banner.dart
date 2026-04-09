import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

/// Premium özellik kilidi banner'ı
class PremiumLockBanner extends StatelessWidget {
  final String featureName;
  final VoidCallback? onUpgrade;

  const PremiumLockBanner({
    super.key,
    required this.featureName,
    this.onUpgrade,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2A1F00), Color(0xFF1E1E35)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.premium.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.premium.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.lock_rounded,
              color: AppColors.premium,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  featureName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.premium,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Bu özellik Premium üyelere özeldir',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: onUpgrade,
            child: Container(
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
          ),
        ],
      ),
    );
  }
}
