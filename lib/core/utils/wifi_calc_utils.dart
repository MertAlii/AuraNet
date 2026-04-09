import 'dart:math';

class WiFiCalcUtils {
  static const double distanceMhzM = 27.55;
  static const int minRssi = -100;
  static const int maxRssi = -55;

  /// RSSI ve Frekans (MHz) kullanarak tahmini mesafe hesaplar.
  /// Formül: 10^((27.55 - 20 * log10(freq) + |RSSI|) / 20)
  static double calculateDistance(int frequency, int level) {
    // log10(x) = log(x) / ln10
    double log10Freq = log(frequency) / ln10;
    return pow(10, (distanceMhzM - (20 * log10Freq) + level.abs()) / 20.0).toDouble();
  }

  /// RSSI değerini 0-100 arası bir seviyeye dönüştürür.
  static int calculateSignalLevel(int rssi) {
    if (rssi <= minRssi) return 0;
    if (rssi >= maxRssi) return 100;
    return ((rssi - minRssi) * 100 ~/ (maxRssi - minRssi));
  }

  /// Frekansa göre Wi-Fi Bandını belirler.
  static String getWiFiBand(int frequency) {
    if (frequency >= 2400 && frequency <= 2500) {
      return "2.4 GHz";
    } else if (frequency >= 4900 && frequency <= 5900) {
      return "5 GHz";
    } else if (frequency >= 5925 && frequency <= 7125) {
      return "6 GHz";
    }
    return "Bilinmiyor";
  }

  /// Kanal numarasını frekanstan hesaplar (Basit eşleştirme).
  static int getChannelFromFrequency(int frequency) {
    if (frequency >= 2412 && frequency <= 2484) {
      return (frequency - 2412) ~/ 5 + 1;
    } else if (frequency >= 5170 && frequency <= 5825) {
      return (frequency - 5170) ~/ 5 + 34;
    } else if (frequency >= 5945 && frequency <= 7105) {
      return (frequency - 5945) ~/ 5 + 1;
    }
    return 0;
  }
}
