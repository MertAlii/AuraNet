import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// AuraNet tipografi sistemi — Inter + JetBrains Mono
class AppTextStyles {
  AppTextStyles._();

  // Başlıklar
  static TextStyle h1 = GoogleFonts.inter(
    fontSize: 22,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
  );

  static TextStyle h2 = GoogleFonts.inter(
    fontSize: 18,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
  );

  static TextStyle h3 = GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
  );

  // Gövde
  static TextStyle body = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
  );

  static TextStyle bodySecondary = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
  );

  // Küçük
  static TextStyle small = GoogleFonts.inter(
    fontSize: 11,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
  );

  // Mono (MAC/IP adresleri için)
  static TextStyle mono = GoogleFonts.jetBrainsMono(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
  );

  // Buton
  static TextStyle button = GoogleFonts.inter(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: AppColors.primaryBlueLight,
  );

  // Büyük sayı (skor, hız vb.)
  static TextStyle bigNumber = GoogleFonts.inter(
    fontSize: 48,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  // Label
  static TextStyle label = GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
    letterSpacing: 0.5,
  );
}
