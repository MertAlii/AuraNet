import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class SpeedtestScreen extends StatefulWidget {
  const SpeedtestScreen({super.key});

  @override
  State<SpeedtestScreen> createState() => _SpeedtestScreenState();
}

class _SpeedtestScreenState extends State<SpeedtestScreen> with SingleTickerProviderStateMixin {
  bool _isTesting = false;
  String _testPhase = 'Hazır'; // 'Hazır', 'Ping', 'Download', 'Upload', 'Tamamlandı'
  
  double _ping = 0.0;
  double _download = 0.0;
  double _upload = 0.0;
  double _currentValue = 0.0;

  late AnimationController _animController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(CurvedAnimation(parent: _animController, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _startTest() async {
    setState(() {
      _isTesting = true;
      _testPhase = 'Ping Bağlantısı İzi Sürmesi...';
      _ping = 0;
      _download = 0;
      _upload = 0;
      _currentValue = 0;
    });

    final random = Random();

    // Ping Phase
    for (int i = 0; i <= 20; i++) {
      await Future.delayed(const Duration(milliseconds: 50));
      setState(() {
        _ping = 15.0 + random.nextDouble() * 10; 
      });
    }

    // Download Phase
    setState(() => _testPhase = 'İndirme Testi (Download)...');
    double targetDownload = 80.0 + random.nextDouble() * 50; 
    for (int i = 0; i <= 50; i++) {
      await Future.delayed(const Duration(milliseconds: 100));
      setState(() {
        _currentValue = (targetDownload / 50) * i + (random.nextDouble() * 5);
        _download = _currentValue;
      });
    }

    // Upload Phase
    setState(() {
      _testPhase = 'Yükleme Testi (Upload)...';
      _currentValue = 0;
    });
    double targetUpload = 20.0 + random.nextDouble() * 20;
    for (int i = 0; i <= 50; i++) {
      await Future.delayed(const Duration(milliseconds: 100));
      setState(() {
        _currentValue = (targetUpload / 50) * i + (random.nextDouble() * 2);
        _upload = _currentValue;
      });
    }

    setState(() {
      _testPhase = 'Tamamlandı';
      _isTesting = false;
      _currentValue = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Hız Testi')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 20),
            // Gauge Animation Area
            Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 250,
                    height: 250,
                    child: CircularProgressIndicator(
                      value: _isTesting ? (_currentValue / 150).clamp(0.0, 1.0) : 0,
                      strokeWidth: 15,
                      backgroundColor: AppColors.backgroundBorder.withValues(alpha: 0.3),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _testPhase.contains('Upload') ? AppColors.warning : AppColors.primaryBlueLight
                      ),
                    ),
                  ),
                  if (_isTesting)
                    ScaleTransition(
                      scale: _pulseAnimation,
                      child: Container(
                        width: 150,
                        height: 150,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primaryBlue.withValues(alpha: 0.1),
                        ),
                      ),
                    ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _isTesting ? _currentValue.toStringAsFixed(1) : 'GO',
                        style: TextStyle(
                          fontSize: _isTesting ? 48 : 56,
                          fontWeight: FontWeight.bold,
                          color: _isTesting ? AppColors.textPrimary : AppColors.primaryBlueLight,
                        ),
                      ),
                      if (_isTesting)
                        const Text(
                          'Mbps',
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
                        ),
                    ],
                  )
                ],
              ),
            ),
            const SizedBox(height: 48),

            // Status Text
            Text(
              _testPhase,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 24),

            // Result Cards
            Row(
              children: [
                Expanded(child: _buildResultCard('Ping', '${_ping.toStringAsFixed(0)} ms', Icons.compare_arrows_rounded, AppColors.safe)),
                const SizedBox(width: 16),
                Expanded(child: _buildResultCard('Download', '${_download.toStringAsFixed(1)}', Icons.download_rounded, AppColors.primaryBlueLight)),
                const SizedBox(width: 16),
                Expanded(child: _buildResultCard('Upload', '${_upload.toStringAsFixed(1)}', Icons.upload_rounded, AppColors.warning)),
              ],
            ),
            const SizedBox(height: 48),

            // Start Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isTesting ? null : _startTest,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlueDark,
                  foregroundColor: AppColors.primaryBlueLight,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: Text(
                  _testPhase == 'Tamamlandı' ? 'Yeniden Test Et' : 'Testi Başlat',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.backgroundBorder.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 12),
          Text(title, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
