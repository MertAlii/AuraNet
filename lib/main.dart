import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:network_tools_flutter/network_tools_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'core/services/hive_service.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase başlat
  await Firebase.initializeApp();

  // Hive başlat
  await HiveService.init();

  // Network Tools başlat (Hızlı taramalar için lokal IP/mac veritabanı ayarı)
  final appDocDirectory = await getApplicationDocumentsDirectory();
  await configureNetworkToolsFlutter(appDocDirectory.path);

  runApp(
    const ProviderScope(
      child: AuraNetApp(),
    ),
  );
}
