import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'core/constants/app_colors.dart';
import 'features/auth/screens/splash_screen.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/auth/screens/register_screen.dart';
import 'features/home/screens/home_screen.dart';
import 'features/profile/screens/profile_screen.dart';
import 'features/scan/screens/scan_screen.dart';
import 'features/scan/screens/device_detail_screen.dart';
import 'features/scan/screens/port_dictionary_screen.dart';
import 'features/speedtest/screens/speedtest_screen.dart';
import 'features/analyzer/screens/wifi_analyzer_screen.dart';
import 'features/security/screens/advanced_security_screen.dart';
import 'features/premium/screens/premium_screen.dart';
import 'features/scan/models/device_model.dart';
import 'core/services/network_scanner_service.dart';

/// Go Router konfigürasyonu
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      // Ana sayfa shell — bottom navigation
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: '/home',
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: '/profile',
            builder: (context, state) => const ProfileScreen(),
          ),
          GoRoute(
            path: '/speedtest',
            builder: (context, state) => const SpeedtestScreen(),
          ),
          GoRoute(
            path: '/analyzer',
            builder: (context, state) => const WiFiAnalyzerScreen(),
          ),
          GoRoute(
            path: '/security',
            builder: (context, state) => const AdvancedSecurityScreen(),
          ),
          GoRoute(
            path: '/premium',
            builder: (context, state) => const PremiumScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/scan',
        builder: (context, state) {
          final modeStr = state.extra as String?;
          final mode = modeStr == 'deep' ? ScanMode.deep : ScanMode.fast;
          return ScanScreen(initialMode: mode);
        },
      ),
      GoRoute(
        path: '/deviceDetail',
        builder: (context, state) {
          final device = state.extra as DeviceModel;
          return DeviceDetailScreen(device: device);
        },
      ),
      GoRoute(
        path: '/portDictionary',
        builder: (context, state) {
          final port = state.extra as int?;
          return PortDictionaryScreen(initialPort: port ?? 0);
        },
      ),
    ],
  );
});

/// Ana shell — bottom navigation bar
class MainShell extends StatelessWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    int currentIndex = 0;
    if (location.startsWith('/analyzer')) currentIndex = 1;
    if (location.startsWith('/speedtest')) currentIndex = 2;
    if (location.startsWith('/profile')) currentIndex = 3;

    return Scaffold(
      backgroundColor: AppColors.backgroundDeep,
      body: child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.backgroundSurface,
          border: Border(
            top: BorderSide(
              color: AppColors.backgroundBorder.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _navItem(
                  icon: Icons.home_rounded,
                  label: 'Ana Sayfa',
                  isActive: currentIndex == 0,
                  onTap: () => context.go('/home'),
                ),
                _navItem(
                  icon: Icons.wifi_find_rounded,
                  label: 'Analiz',
                  isActive: currentIndex == 1,
                  onTap: () => context.go('/analyzer'),
                ),
                _navItem(
                  icon: Icons.speed_rounded,
                  label: 'Hız Testi',
                  isActive: currentIndex == 2,
                  onTap: () => context.go('/speedtest'),
                ),
                _navItem(
                  icon: Icons.person_rounded,
                  label: 'Profil',
                  isActive: currentIndex == 3,
                  onTap: () => context.go('/profile'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _navItem({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primaryBlue.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isActive ? AppColors.primaryBlue : AppColors.textHint,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: isActive ? AppColors.primaryBlue : AppColors.textHint,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// AuraNet uygulaması
class AuraNetApp extends ConsumerWidget {
  const AuraNetApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    // Durum çubuğunu şeffaf yap
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: AppColors.backgroundSurface,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );

    return MaterialApp.router(
      title: 'AuraNet',
      debugShowCheckedModeBanner: false,
      routerConfig: router,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.backgroundDeep,
        colorScheme: const ColorScheme.dark(
          primary: AppColors.primaryBlue,
          secondary: AppColors.primaryBlueDark,
          surface: AppColors.backgroundSurface,
          error: AppColors.danger,
        ),
        textTheme: GoogleFonts.interTextTheme(
          ThemeData.dark().textTheme,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.backgroundDeep,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
          iconTheme: IconThemeData(color: AppColors.textPrimary),
        ),
        cardTheme: CardThemeData(
          color: AppColors.backgroundCard,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryBlueDark,
            foregroundColor: AppColors.primaryBlueLight,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.backgroundCard,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        snackBarTheme: SnackBarThemeData(
          backgroundColor: AppColors.backgroundCard,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}
