import 'dart:convert';
import 'package:dio/dio.dart';

class GroqService {
  static const String _apiKey = String.fromEnvironment('GROQ_API_KEY');
  static const String _baseUrl = 'https://api.groq.com/openai/v1/chat/completions';
  static const String _model = 'llama-3.3-70b-versatile';

  static final Dio _dio = Dio(BaseOptions(
    baseUrl: _baseUrl,
    headers: {
      'Authorization': 'Bearer $_apiKey',
      'Content-Type': 'application/json',
    },
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 30),
  ));

  /// Aura AI'a soru sor ve cevap al
  static Future<String> ask({
    required String userMessage,
    required String systemPrompt,
  }) async {
    try {
      final response = await _dio.post(
        '',
        data: jsonEncode({
          'model': _model,
          'messages': [
            {'role': 'system', 'content': systemPrompt},
            {'role': 'user', 'content': userMessage},
          ],
          'temperature': 0.7,
          'max_tokens': 1024,
        }),
      );

      if (response.statusCode == 200) {
        final data = response.data;
        return data['choices'][0]['message']['content'] ?? 'Yanıt alınamadı.';
      } else {
        return 'API Hatası: ${response.statusCode}';
      }
    } on DioException catch (e) {
      if (e.response != null) {
        return 'Groq API Hatası: ${e.response?.statusCode} - ${e.response?.data}';
      }
      return 'Bağlantı hatası: ${e.message}';
    } catch (e) {
      return 'Beklenmeyen hata: $e';
    }
  }

  /// Ağ analiz verileriyle zenginleştirilmiş sistem promptu oluştur
  static String buildSystemPrompt({
    required String userName,
    int? securityScore,
    int? deviceCount,
    int? openPortCount,
    int? suspiciousCount,
    String? networkName,
    List<Map<String, dynamic>>? devices,
  }) {
    final buffer = StringBuffer();
    buffer.writeln('Sen "Aura AI" adlı bir siber güvenlik uzmanısın. AuraNet adlı ağ analiz uygulamasının yapay zeka asistanısın.');
    buffer.writeln('Kullanıcıya Türkçe olarak cevap veriyorsun. Cevapların kısa, öz ve anlaşılır olmalı.');
    buffer.writeln('Ağ güvenliği, port taraması, Wi-Fi güvenliği, DNS, ARP spoofing gibi konularda uzmansın.');
    buffer.writeln('');
    buffer.writeln('## Kullanıcı Bilgileri');
    buffer.writeln('- Kullanıcı Adı: $userName');
    
    if (networkName != null) buffer.writeln('- Bağlı Ağ: $networkName');
    if (securityScore != null) buffer.writeln('- Ağ Güvenlik Skoru: $securityScore/100');
    if (deviceCount != null) buffer.writeln('- Ağdaki Cihaz Sayısı: $deviceCount');
    if (openPortCount != null) buffer.writeln('- Açık Port Sayısı: $openPortCount');
    if (suspiciousCount != null) buffer.writeln('- Şüpheli Cihaz Sayısı: $suspiciousCount');
    
    if (devices != null && devices.isNotEmpty) {
      buffer.writeln('');
      buffer.writeln('## Ağdaki Cihazlar');
      for (final d in devices) {
        buffer.writeln('- IP: ${d['ip']}, İsim: ${d['name']}, Üretici: ${d['vendor']}, Açık Portlar: ${d['ports']}');
      }
    }

    buffer.writeln('');
    buffer.writeln('Bu bilgilere dayanarak kullanıcının sorularını cevapla ve güvenlik tavsiyeleri ver.');
    buffer.writeln('Eğer skor düşükse uyar, yüksekse tebrik et. Her zaman yaratıcı ve eğitici ol.');

    return buffer.toString();
  }
}
