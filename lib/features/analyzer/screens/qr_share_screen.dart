import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../core/constants/app_colors.dart';

class QrShareScreen extends StatefulWidget {
  final String ssid;
  const QrShareScreen({super.key, required this.ssid});

  @override
  State<QrShareScreen> createState() => _QrShareScreenState();
}

class _QrShareScreenState extends State<QrShareScreen> {
  final TextEditingController _passwordController = TextEditingController();
  bool _showQr = false;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Wi-Fi QR format: WIFI:T:WPA;S:SSID;P:PASSWORD;;
    final qrData = 'WIFI:T:WPA;S:${widget.ssid};P:${_passwordController.text};;';

    return Scaffold(
      appBar: AppBar(title: const Text('QR ile Ağ Paylaş')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.backgroundCard,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                children: [
                  const Icon(Icons.qr_code_2_rounded, size: 48, color: AppColors.primaryBlue),
                  const SizedBox(height: 16),
                  Text(
                    widget.ssid,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Misafirlerinizin ağa kolayca bağlanması için bir QR kod üretin.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  ),
                  const SizedBox(height: 24),
                  
                  if (!_showQr) ...[
                    TextField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        hintText: 'Ağ Şifresi (Gerekliyse)',
                        prefixIcon: Icon(Icons.lock_rounded),
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () => setState(() => _showQr = true),
                        child: const Text('QR Kod Üret'),
                      ),
                    ),
                  ] else ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: QrImageView(
                        data: qrData,
                        version: QrVersions.auto,
                        size: 200.0,
                        gapless: false,
                        foregroundColor: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 24),
                    TextButton.icon(
                      onPressed: () => setState(() => _showQr = false),
                      icon: const Icon(Icons.edit_rounded),
                      label: const Text('Bilgileri Düzenle'),
                    ),
                  ],
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            const Text(
              'Güvenlik Notu: Şifreniz sadece bu cihazda QR kod üretmek için kullanılır ve hiçbir yere kaydedilmez.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textHint, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
