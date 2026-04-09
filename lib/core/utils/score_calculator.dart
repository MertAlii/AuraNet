import '../constants/camera_mac_vendors.dart';

/// Güvenlik skoru hesaplama motoru
class ScoreCalculator {
  ScoreCalculator._();

  /// Güvenlik puanını hesapla (0-100)
  ///
  /// Başlangıç: 100 puan
  /// - Şüpheli kamera üreticisi tespit: -20 (maks -20)
  /// - Her yüksek riskli açık port: -10 (maks -30)
  /// - Her orta riskli açık port: -5 (maks -15)
  /// - Bilinmeyen cihaz başına: -3 (maks -15)
  /// - Telnet portu açık: -15 (ayrıca)
  /// - Router default IP: -5
  /// - Açık/güvensiz WiFi: -20
  static ScoreResult calculate({
    required List<String> vendors,
    required List<int> highRiskPorts,
    required List<int> mediumRiskPorts,
    required int unknownDeviceCount,
    required bool hasTelnet,
    required bool hasDefaultRouterIp,
    required bool isOpenWifi,
  }) {
    int score = 100;
    final List<ScoreDeduction> deductions = [];

    // Şüpheli kamera üreticisi
    final hasSuspicious = vendors.any((v) => CameraMacVendors.isSuspicious(v));
    if (hasSuspicious) {
      const penalty = -20;
      score += penalty;
      deductions.add(ScoreDeduction(
        name: 'Şüpheli Kamera Cihazı',
        penalty: penalty,
        recommendation: 'Ağınızda bir kamera cihazı tespit edildi. Tanımıyorsanız ağdan çıkarın.',
      ));
    }

    // Yüksek riskli portlar
    final highRiskPenalty = (highRiskPorts.length * -10).clamp(-30, 0);
    if (highRiskPenalty < 0) {
      score += highRiskPenalty;
      deductions.add(ScoreDeduction(
        name: 'Yüksek Riskli Açık Port (${highRiskPorts.length})',
        penalty: highRiskPenalty,
        recommendation: 'Portları kapatın: ${highRiskPorts.join(", ")}',
      ));
    }

    // Orta riskli portlar
    final mediumRiskPenalty = (mediumRiskPorts.length * -5).clamp(-15, 0);
    if (mediumRiskPenalty < 0) {
      score += mediumRiskPenalty;
      deductions.add(ScoreDeduction(
        name: 'Orta Riskli Açık Port (${mediumRiskPorts.length})',
        penalty: mediumRiskPenalty,
        recommendation: 'Port güvenliğini gözden geçirin: ${mediumRiskPorts.join(", ")}',
      ));
    }

    // Bilinmeyen cihazlar
    final unknownPenalty = (unknownDeviceCount * -3).clamp(-15, 0);
    if (unknownPenalty < 0) {
      score += unknownPenalty;
      deductions.add(ScoreDeduction(
        name: 'Bilinmeyen Cihaz ($unknownDeviceCount)',
        penalty: unknownPenalty,
        recommendation: 'Bilinmeyen cihazları tanımlayın veya ağdan çıkarın.',
      ));
    }

    // Telnet
    if (hasTelnet) {
      const penalty = -15;
      score += penalty;
      deductions.add(ScoreDeduction(
        name: 'Telnet Portu Açık',
        penalty: penalty,
        recommendation: 'Port 23 (Telnet) kapatın, SSH (Port 22) kullanın.',
      ));
    }

    // Default router IP
    if (hasDefaultRouterIp) {
      const penalty = -5;
      score += penalty;
      deductions.add(ScoreDeduction(
        name: 'Varsayılan Router IP',
        penalty: penalty,
        recommendation: 'Router IP adresini değiştirmeyi düşünün.',
      ));
    }

    // Açık WiFi
    if (isOpenWifi) {
      const penalty = -20;
      score += penalty;
      deductions.add(ScoreDeduction(
        name: 'Güvensiz WiFi Ağı',
        penalty: penalty,
        recommendation: 'WiFi şifrenizi WPA2/WPA3 ile koruyun.',
      ));
    }

    return ScoreResult(
      score: score.clamp(0, 100),
      deductions: deductions,
    );
  }

  /// Skora göre risk seviyesi
  static String getRiskLevel(int score) {
    if (score <= 40) return 'Yüksek Risk';
    if (score <= 70) return 'Orta Risk';
    return 'Düşük Risk';
  }

  /// Skora göre risk rengi (hex string olarak)
  static String getRiskColorHex(int score) {
    if (score <= 40) return '#E24B4A';
    if (score <= 70) return '#EF9F27';
    return '#5DCAA5';
  }
}

/// Skor kesinti detayı
class ScoreDeduction {
  final String name;
  final int penalty;
  final String recommendation;

  const ScoreDeduction({
    required this.name,
    required this.penalty,
    required this.recommendation,
  });
}

/// Skor hesaplama sonucu
class ScoreResult {
  final int score;
  final List<ScoreDeduction> deductions;

  const ScoreResult({
    required this.score,
    required this.deductions,
  });
}
