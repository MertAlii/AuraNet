import 'package:firebase_auth/firebase_auth.dart';

/// Firebase Authentication servisi — Email/Password login, register, password reset
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Mevcut kullanıcı
  User? get currentUser => _auth.currentUser;

  /// Auth durumu stream'i
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Email/Password ile giriş
  Future<UserCredential> signInWithEmail(String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    }
  }

  /// Email/Password ile kayıt
  Future<UserCredential> registerWithEmail({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      // Kullanıcı adını güncelle
      await credential.user?.updateDisplayName(displayName.trim());
      await credential.user?.reload();
      return credential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    }
  }

  /// Şifre sıfırlama e-postası gönder
  Future<void> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    }
  }

  /// Çıkış yap
  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Hesabı sil
  Future<void> deleteAccount() async {
    try {
      await _auth.currentUser?.delete();
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    }
  }

  /// Kullanıcı adını güncelle
  Future<void> updateDisplayName(String name) async {
    await _auth.currentUser?.updateDisplayName(name.trim());
    await _auth.currentUser?.reload();
  }

  /// Firebase Auth hata mesajlarını Türkçe'ye çevir
  String _handleAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'Bu e-posta adresiyle kayıtlı kullanıcı bulunamadı';
      case 'wrong-password':
        return 'Yanlış şifre girdiniz';
      case 'email-already-in-use':
        return 'Bu e-posta adresi zaten kullanılıyor';
      case 'invalid-email':
        return 'Geçersiz e-posta adresi';
      case 'weak-password':
        return 'Şifre çok zayıf, en az 6 karakter olmalı';
      case 'too-many-requests':
        return 'Çok fazla deneme yaptınız, lütfen daha sonra tekrar deneyin';
      case 'user-disabled':
        return 'Bu hesap devre dışı bırakılmış';
      case 'operation-not-allowed':
        return 'Bu işlem şu an kullanılamıyor';
      case 'requires-recent-login':
        return 'Bu işlem için yeniden giriş yapmanız gerekiyor';
      case 'invalid-credential':
        return 'E-posta veya şifre hatalı';
      default:
        return 'Bir hata oluştu: ${e.message}';
    }
  }
}
