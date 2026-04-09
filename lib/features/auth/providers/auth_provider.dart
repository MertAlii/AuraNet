import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/firestore_service.dart';

/// Auth durumu
enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

/// Auth state sınıfı
class AuthState {
  final AuthStatus status;
  final User? user;
  final bool isPremium;
  final String? errorMessage;

  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.isPremium = false,
    this.errorMessage,
  });

  AuthState copyWith({
    AuthStatus? status,
    User? user,
    bool? isPremium,
    String? errorMessage,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      isPremium: isPremium ?? this.isPremium,
      errorMessage: errorMessage,
    );
  }
}

/// Auth Notifier
class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _authService;
  final FirestoreService _firestoreService;

  AuthNotifier(this._authService, this._firestoreService)
      : super(const AuthState()) {
    _init();
  }

  void _init() {
    _authService.authStateChanges.listen((user) async {
      if (user != null) {
        try {
          // Firestore'dan premium durumunu çek (Maks 5 sn bekle, yoksa devam et)
          final profile = await _firestoreService.getUserProfile(user.uid).timeout(
            const Duration(seconds: 5),
            onTimeout: () => null,
          );
          final isPremium = profile?['isPremium'] ?? false;
          
          state = AuthState(
            status: AuthStatus.authenticated, 
            user: user,
            isPremium: isPremium,
          );
        } catch (_) {
          // Profil çekilemese de kullanıcı giriş yapmış sayılır
          state = AuthState(
            status: AuthStatus.authenticated, 
            user: user,
            isPremium: false,
          );
        }
      } else {
        state = const AuthState(status: AuthStatus.unauthenticated);
      }
    });
  }

  /// Email ile giriş
  Future<void> signInWithEmail(String email, String password) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      await _authService.signInWithEmail(email, password);
      // Not: Durum güncellemesi _init içindeki listener tarafından yapılacak
    } catch (e) {
      state = AuthState(
        status: AuthStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  /// Email ile kayıt
  Future<void> registerWithEmail({
    required String email,
    required String password,
    required String displayName,
  }) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      final credential = await _authService.registerWithEmail(
        email: email,
        password: password,
        displayName: displayName,
      );

      // Firestore'da kullanıcı profili oluştur (Opsiyonel: Hata uygulama akışını bozmamalı)
      if (credential.user != null) {
        try {
          await _firestoreService.createUserProfile(
            uid: credential.user!.uid,
            email: email,
            displayName: displayName,
          ).timeout(const Duration(seconds: 10));
        } catch (e) {
          print("Profil oluşturma hatası: $e");
          // Profil oluşmasa da kullanıcı kayıt oldu, devam edebilir
        }
      }
    } catch (e) {
      state = AuthState(
        status: AuthStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  /// Şifre sıfırlama
  Future<bool> sendPasswordReset(String email) async {
    try {
      await _authService.sendPasswordReset(email);
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      return false;
    }
  }

  /// Çıkış yap
  Future<void> signOut() async {
    await _authService.signOut();
  }

  /// Hesabı sil
  Future<void> deleteAccount() async {
    try {
      final uid = _authService.currentUser?.uid;
      if (uid != null) {
        await _firestoreService.deleteUserData(uid);
      }
      await _authService.deleteAccount();
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    }
  }

  /// Hata mesajını temizle
  void clearError() {
    state = state.copyWith(errorMessage: null);
  }

  /// Premium durumunu simüle et
  void setPremium(bool value) {
    state = state.copyWith(isPremium: value);
  }
}

/// Providers
final authServiceProvider = Provider<AuthService>((ref) => AuthService());
final firestoreServiceProvider = Provider<FirestoreService>((ref) => FirestoreService());

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(
    ref.read(authServiceProvider),
    ref.read(firestoreServiceProvider),
  );
});

/// Auth durumu stream provider
final authStateProvider = StreamProvider<User?>((ref) {
  return ref.read(authServiceProvider).authStateChanges;
});
