import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/port_risk_database.dart';

class PortDictionaryScreen extends StatelessWidget {
  final int initialPort;

  const PortDictionaryScreen({super.key, this.initialPort = 0});

  @override
  Widget build(BuildContext context) {
    // Sadece PortRiskDatabase içindeki tanımlı portları veya tek bir portu listele
    final ports = initialPort > 0 
        ? [PortRiskDatabase.getPortInfo(initialPort)] 
        : PortRiskDatabase.ports.values.toList()..sort((a, b) => a.port.compareTo(b.port));

    return Scaffold(
      backgroundColor: AppColors.backgroundDeep,
      appBar: AppBar(
        title: Text(initialPort > 0 ? 'Port $initialPort Detayı' : 'Port Sözlüğü'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: ports.length,
        itemBuilder: (context, index) {
          final portInfo = ports[index];
          return _buildPortExplanationCard(portInfo);
        },
      ),
    );
  }

  Widget _buildPortExplanationCard(PortRiskInfo info) {
    Color riskColor;
    IconData riskIcon;
    String riskLabel;

    switch (info.riskLevel) {
      case 'high':
        riskColor = AppColors.danger;
        riskIcon = Icons.warning_rounded;
        riskLabel = 'Yüksek Risk / Kritik';
        break;
      case 'medium':
        riskColor = AppColors.warning;
        riskIcon = Icons.shield_outlined;
        riskLabel = 'Orta Risk / Şüpheli';
        break;
      default:
        riskColor = AppColors.safe;
        riskIcon = Icons.verified_user_rounded;
        riskLabel = 'Düşük Risk / Güvenli';
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: riskColor.withValues(alpha: 0.4), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: riskColor.withValues(alpha: 0.05),
            blurRadius: 10,
            spreadRadius: 2,
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Başlık
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: riskColor.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Icon(riskIcon, color: riskColor, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Port ${info.port} - ${info.protocol}',
                        style: TextStyle(
                          color: riskColor,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'JetBrains Mono'
                        ),
                      ),
                      Text(riskLabel, style: TextStyle(color: riskColor.withValues(alpha: 0.8), fontSize: 13)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // İçerik
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Ne İşe Yarar?', style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(info.description, style: const TextStyle(color: AppColors.textSecondary, fontSize: 14, height: 1.5)),
                
                const SizedBox(height: 20),
                const Divider(color: AppColors.backgroundBorder),
                const SizedBox(height: 20),

                const Text('Güvenlik Analizi & Öneri', style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(info.recommendation, style: const TextStyle(color: AppColors.textSecondary, fontSize: 14, height: 1.5)),
                
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.backgroundBorder.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.lightbulb_outline_rounded, color: AppColors.primaryBlueLight, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _getDetailedBlogText(info.port, info.protocol),
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Blog Tarzı ekstra uzun açıklamalar
  String _getDetailedBlogText(int port, String protocol) {
    if (port == 21 || port == 23) {
      return 'Bu port üzerinden geçen şifreler "plain-text" (düz metin) olarak iletildiğinden aynı ağdaki herhangi bir kişi (ARP Spoofing aracı kullananlar) şifrelerinizi görebilir.';
    } else if (port == 22) {
      return 'SSH güvenlidir ancak varsayılan ("admin/admin") gibi bir şifre kullanıyorsanız otomatik botlar internet üzerinden cihazınıza sızabilir.';
    } else if (port == 443) {
      return 'HTTPS standardıdır. Tüm trafiğiniz şifrelenir. Güvenle kullanabilirsiniz.';
    } else if (port == 3389 || port == 5900) {
      return 'Uzak masaüstü bağlantıları ev kullanıcıları için büyük tehlikedir. Bilgisayarınıza doğrudan erişim sağlar.';
    } else if (port == 3306 || port == 1433 || port == 5432 || port == 27017 || port == 6379) {
      return 'Veritabanlarının internete açık olması genel olarak zafiyet yaratır. Sadece Localhost (127.0.0.1) üzerinden erişilmesine izin verin.';
    }
    
    return 'Eğer bu portu/servisi aktif olarak kullanmıyorsanız modem arayüzünüzden (NAT/Port Forwarding) dış ağa kapatmanız tavsiye edilir.';
  }
}
