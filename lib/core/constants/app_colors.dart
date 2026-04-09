import 'package:flutter/material.dart';

/// AuraNet renk paleti — Koyu tema
class AppColors {
  AppColors._();

  // Arka plan renkleri
  static const Color backgroundDeep = Color(0xFF0D0D1A);
  static const Color backgroundSurface = Color(0xFF1A1A2E);
  static const Color backgroundCard = Color(0xFF1E1E35);
  static const Color backgroundBorder = Color(0xFF2A2A45);

  // Vurgu renkleri
  static const Color primaryBlue = Color(0xFF378ADD);
  static const Color primaryBlueDark = Color(0xFF185FA5);
  static const Color primaryBlueLight = Color(0xFFE6F1FB);

  // Semantik renkler
  static const Color safe = Color(0xFF5DCAA5);
  static const Color warning = Color(0xFFEF9F27);
  static const Color danger = Color(0xFFE24B4A);
  static const Color premium = Color(0xFFEF9F27);

  // Metin renkleri
  static const Color textPrimary = Color(0xFFE0E0F0);
  static const Color textSecondary = Color(0xFF888888);
  static const Color textHint = Color(0xFF555555);

  // Gradient'ler
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryBlue, primaryBlueDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [backgroundCard, backgroundSurface],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient dangerGradient = LinearGradient(
    colors: [Color(0xFFE24B4A), Color(0xFFB83A39)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient safeGradient = LinearGradient(
    colors: [Color(0xFF5DCAA5), Color(0xFF3DA882)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient premiumGradient = LinearGradient(
    colors: [Color(0xFFEF9F27), Color(0xFFD4880E)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
