import 'package:home_widget/home_widget.dart';

class WidgetService {
  static const String _appGroupId = 'group.auranet.widget';
  static const String _androidWidgetName = 'WifiWidgetProvider';

  /// Widget verilerini güncelle (SSID, Sinyal, IP vb.)
  static Future<void> updateWidgetData({
    required String ssid,
    required String ip,
    required int signal,
    required int securityScore,
  }) async {
    try {
      await HomeWidget.saveWidgetData<String>('wifi_ssid', ssid);
      await HomeWidget.saveWidgetData<String>('wifi_ip', ip);
      await HomeWidget.saveWidgetData<int>('wifi_signal', signal);
      await HomeWidget.saveWidgetData<int>('security_score', securityScore);
      
      await HomeWidget.updateWidget(
        androidName: _androidWidgetName,
      );
    } catch (e) {
      // Widget güncelleme hatası
    }
  }

  /// Widget'tan uygulamayı başlatma ayarları (Opsiyonel)
  static Future<void> init() async {
    await HomeWidget.setAppGroupId(_appGroupId);
  }
}
