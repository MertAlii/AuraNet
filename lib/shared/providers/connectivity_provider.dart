import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';

/// İnternet bağlantı durumu
enum ConnectivityStatus { connected, disconnected, checking }

class ConnectivityNotifier extends StateNotifier<ConnectivityStatus> {
  Timer? _timer;

  ConnectivityNotifier() : super(ConnectivityStatus.checking) {
    _checkConnectivity();
    // Her 30 saniyede bir kontrol et
    _timer = Timer.periodic(const Duration(seconds: 30), (_) => _checkConnectivity());
  }

  Future<void> _checkConnectivity() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        state = ConnectivityStatus.connected;
      } else {
        state = ConnectivityStatus.disconnected;
      }
    } on SocketException catch (_) {
      state = ConnectivityStatus.disconnected;
    }
  }

  Future<void> refresh() async {
    state = ConnectivityStatus.checking;
    await _checkConnectivity();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

final connectivityProvider =
    StateNotifierProvider<ConnectivityNotifier, ConnectivityStatus>((ref) {
  return ConnectivityNotifier();
});
