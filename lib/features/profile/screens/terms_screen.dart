import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import '../../../core/constants/app_colors.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDeep,
      appBar: AppBar(
        title: const Text('Kullanım Koşulları ve Gizlilik'),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: FutureBuilder<String>(
        future: rootBundle.loadString('assets/docs/terms.md'),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Hata: Belge yüklenemedi. (${snapshot.error})'));
          }

          return Markdown(
            data: snapshot.data ?? '',
            styleSheet: MarkdownStyleSheet(
              p: const TextStyle(color: AppColors.textPrimary, fontSize: 14, height: 1.5),
              h1: const TextStyle(color: AppColors.primaryBlue, fontSize: 24, fontWeight: FontWeight.bold),
              h2: const TextStyle(color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.bold),
              h3: const TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
              listBullet: const TextStyle(color: AppColors.primaryBlue),
              strong: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
            ),
          );
        },
      ),
    );
  }
}
