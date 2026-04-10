import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class BlogArticle {
  final String title;
  final String excerpt;
  final String content;
  final String category;
  final IconData icon;

  BlogArticle({
    required this.title,
    required this.excerpt,
    required this.content,
    required this.category,
    required this.icon,
  });
}

class BlogScreen extends StatelessWidget {
  BlogScreen({super.key});

  final List<BlogArticle> _articles = [
    BlogArticle(
      title: 'Wi-Fi Güvenliği: Temel Adımlar',
      category: 'Güvenlik',
      icon: Icons.wifi_lock_rounded,
      excerpt: 'Ağınızı dış saldırılara karşı nasıl korursunuz? Basit ama etkili yöntemler.',
      content: 'Wi-Fi ağınızın güvenliği, dijital hayatınızın kapısıdır. İlk adım olarak WPA3 şifreleme protokolünü kullanmaya özen gösterin. Ayrıca, modem arayüz şifrenizi varsayılan (admin) bırakmamak, WPS özelliğini kapatmak ve SSID adınızda kişisel bilgi vermemek ağınızı çok daha güvenli hale getirecektir.',
    ),
    BlogArticle(
      title: 'Zayıf Şifrelerin Gizli Tehlikeleri',
      category: 'Analiz',
      icon: Icons.password_rounded,
      excerpt: 'Neden "123456" kullanmamalısınız? Brute-force saldırıları nasıl çalışır?',
      content: 'Brute-force (Kaba kuvvet) saldırıları, saniyede binlerce kombinasyon deneyerek şifrenizi kırmaya çalışır. Karmaşık olmayan şifreler, bu yazılımlar tarafından saniyeler içinde çözülebilir. Şifrenizde en az bir büyük harf, bir rakam ve bir özel karakter bulundurmak, saldırganın işini imkansız hale getirebilir.',
    ),
    BlogArticle(
      title: 'AuraNet ile Tam Koruma',
      category: 'Rehber',
      icon: Icons.info_outline_rounded,
      excerpt: 'Uygulamadaki araçları en verimli nasıl kullanırsınız?',
      content: 'AuraNet sadece bir tarayıcı değildir. Hız testi ile performansınızı ölçerken, DNS sızıntı testi ile gizliliğinizi denetleyebilirsiniz. Port tarama özelliği sayesinde, cihazlarınızın internete açık kapı bırakıp bırakmadığını düzenli olarak kontrol etmenizi öneririz.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Eğitim ve Blog')),
      body: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: _articles.length,
        itemBuilder: (context, index) {
          final article = _articles[index];
          return _buildArticleCard(context, article);
        },
      ),
    );
  }

  Widget _buildArticleCard(BuildContext context, BlogArticle article) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.backgroundBorder.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(article.icon, color: AppColors.primaryBlueLight),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(article.category.toUpperCase(), style: const TextStyle(color: AppColors.primaryBlueLight, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                      Text(article.title, style: const TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              article.excerpt,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.all(20),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => _showArticleDetail(context, article),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.primaryBlue),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Devamını Oku', style: TextStyle(color: AppColors.primaryBlueLight)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showArticleDetail(BuildContext context, BlogArticle article) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.backgroundDeep,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.textHint, borderRadius: BorderRadius.circular(2))),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Icon(article.icon, color: AppColors.primaryBlueLight, size: 32),
                  const SizedBox(width: 16),
                  Text(article.title, style: const TextStyle(color: AppColors.textPrimary, fontSize: 24, fontWeight: FontWeight.bold)),
                ],
              ),
              const Divider(height: 40, color: AppColors.backgroundBorder),
              Text(
                article.content,
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 16, height: 1.6),
              ),
              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }
}
