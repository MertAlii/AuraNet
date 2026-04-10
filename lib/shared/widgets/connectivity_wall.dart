import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../core/constants/app_colors.dart';

class ConnectivityWall extends StatefulWidget {
  final Widget child;
  const ConnectivityWall({super.key, required this.child});

  @override
  State<ConnectivityWall> createState() => _ConnectivityWallState();
}

class _ConnectivityWallState extends State<ConnectivityWall> {
  List<ConnectivityResult> _connectionStatus = [ConnectivityResult.none];
  bool _bypassed = false;
  late Stream<List<ConnectivityResult>> _connectivityStream;

  @override
  void initState() {
    super.initState();
    _checkInitial();
    _connectivityStream = Connectivity().onConnectivityChanged;
    _connectivityStream.listen((results) {
      if (mounted) {
        setState(() {
          _connectionStatus = results;
          // Eğer bağlantı tamamen geldiyse bypass'ı sıfırla
          if (_hasWifi()) {
            _bypassed = false;
          }
        });
      }
    });
  }

  Future<void> _checkInitial() async {
    final results = await Connectivity().checkConnectivity();
    if (mounted) {
      setState(() {
        _connectionStatus = results;
      });
    }
  }

  bool _hasWifi() => _connectionStatus.contains(ConnectivityResult.wifi);
  bool _hasMobile() => _connectionStatus.contains(ConnectivityResult.mobile);
  bool _isNone() => _connectionStatus.contains(ConnectivityResult.none) || _connectionStatus.isEmpty;

  @override
  Widget build(BuildContext context) {
    if (_hasWifi() || _bypassed) {
      return widget.child;
    }

    if (_hasMobile()) {
      return _buildWallScreen(
        icon: Icons.cell_tower_rounded,
        title: 'Wi-Fi Kapalı',
        message: 'Şu anda sadece Mobil Veri kullanıyorsunuz. Uygulama açılacak ancak yerel ağ taraması (IP Taraması) yapamayacaksınız.',
        allowBypass: true,
      );
    }

    return _buildWallScreen(
      icon: Icons.wifi_off_rounded,
      title: 'İnternet Bağlantısı Yok',
      message: 'Lütfen bir Wi-Fi ağına bağlanın. Bazı özellikler (Komşu Wi-Fi Araştırması) bağlantısız da çalışabilir.',
      allowBypass: true,
    );
  }

  Widget _buildWallScreen({
    required IconData icon,
    required String title,
    required String message,
    required bool allowBypass,
  }) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDeep,
      body: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.danger.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppColors.danger, size: 64),
            ),
            const SizedBox(height: 32),
            Text(
              title,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: const TextStyle(fontSize: 15, color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 48),
            if (allowBypass)
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _bypassed = true;
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue.withValues(alpha: 0.1),
                    foregroundColor: AppColors.primaryBlueLight,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: const Text('Devam Et', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
