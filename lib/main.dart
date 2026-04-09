import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'core/services/hive_service.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase başlat
  await Firebase.initializeApp();

  // Hive başlat
  await HiveService.init();

  runApp(
    const ProviderScope(
      child: AuraNetApp(),
    ),
  );
}
