import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../providers/auth_provider.dart';

/// Giriş ekranı — Email/Password ile giriş
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _animController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    await ref.read(authProvider.notifier).signInWithEmail(
      _emailController.text.trim(),
      _passwordController.text,
    );

    if (mounted) {
      setState(() => _isLoading = false);
      final authState = ref.read(authProvider);
      if (authState.status == AuthStatus.error) {
        _showError(authState.errorMessage ?? 'Giriş başarısız');
      } else if (authState.status == AuthStatus.authenticated) {
        context.go('/home');
      }
    }
  }

  Future<void> _forgotPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      _showError('Lütfen e-posta adresinizi girin');
      return;
    }
    final success = await ref.read(authProvider.notifier).sendPasswordReset(email);
    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Şifre sıfırlama bağlantısı e-postanıza gönderildi'),
            backgroundColor: AppColors.safe,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      } else {
        _showError(ref.read(authProvider).errorMessage ?? 'Bir hata oluştu');
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.danger,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Listen to auth state for auto-navigation
    ref.listen<AuthState>(authProvider, (previous, next) {
      if (next.status == AuthStatus.authenticated) {
        context.go('/home');
      }
    });

    return Scaffold(
      backgroundColor: AppColors.backgroundDeep,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 40),
                    // Logo
                    _buildLogo(),
                    const SizedBox(height: 48),
                    // Email
                    _buildEmailField(),
                    const SizedBox(height: 16),
                    // Password
                    _buildPasswordField(),
                    const SizedBox(height: 8),
                    // Şifremi unuttum
                    _buildForgotPassword(),
                    const SizedBox(height: 24),
                    // Giriş butonu
                    _buildLoginButton(),
                    const SizedBox(height: 32),
                    // Kayıt ol linki
                    _buildRegisterLink(),
                    const SizedBox(height: 24),
                    // Yasal metinler
                    _buildLegalText(),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryBlue.withValues(alpha: 0.35),
                blurRadius: 25,
                spreadRadius: 3,
              ),
            ],
          ),
          child: const Icon(Icons.shield_rounded, color: Colors.white, size: 42),
        ),
        const SizedBox(height: 16),
        const Text(
          'AuraNet',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Ev ağınızı güvende tutun',
          style: TextStyle(
            fontSize: 13,
            color: AppColors.textPrimary.withValues(alpha: 0.5),
          ),
        ),
      ],
    );
  }

  Widget _buildEmailField() {
    return TextFormField(
      controller: _emailController,
      keyboardType: TextInputType.emailAddress,
      style: const TextStyle(color: AppColors.textPrimary, fontSize: 15),
      decoration: _inputDecoration(
        label: 'E-posta',
        hint: 'ornek@mail.com',
        icon: Icons.email_outlined,
      ),
      validator: (v) {
        if (v == null || v.trim().isEmpty) return 'E-posta adresi gerekli';
        if (!v.contains('@') || !v.contains('.')) return 'Geçerli bir e-posta girin';
        return null;
      },
    );
  }

  Widget _buildPasswordField() {
    return TextFormField(
      controller: _passwordController,
      obscureText: _obscurePassword,
      style: const TextStyle(color: AppColors.textPrimary, fontSize: 15),
      decoration: _inputDecoration(
        label: 'Şifre',
        hint: '••••••••',
        icon: Icons.lock_outline,
        suffixIcon: IconButton(
          icon: Icon(
            _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
            color: AppColors.textHint,
            size: 20,
          ),
          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
        ),
      ),
      validator: (v) {
        if (v == null || v.isEmpty) return 'Şifre gerekli';
        if (v.length < 6) return 'Şifre en az 6 karakter olmalı';
        return null;
      },
    );
  }

  Widget _buildForgotPassword() {
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton(
        onPressed: _forgotPassword,
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        ),
        child: const Text(
          'Şifremi unuttum',
          style: TextStyle(
            color: AppColors.primaryBlue,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildLoginButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _login,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryBlueDark,
          foregroundColor: AppColors.primaryBlueLight,
          disabledBackgroundColor: AppColors.primaryBlueDark.withValues(alpha: 0.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 0,
        ),
        child: _isLoading
            ? const SizedBox(
                width: 22, height: 22,
                child: CircularProgressIndicator(
                  color: AppColors.primaryBlueLight,
                  strokeWidth: 2.5,
                ),
              )
            : const Text(
                'Giriş Yap',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
      ),
    );
  }

  Widget _buildRegisterLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Hesabınız yok mu? ',
          style: TextStyle(
            color: AppColors.textPrimary.withValues(alpha: 0.6),
            fontSize: 14,
          ),
        ),
        GestureDetector(
          onTap: () => context.push('/register'),
          child: const Text(
            'Hesap oluştur',
            style: TextStyle(
              color: AppColors.primaryBlue,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLegalText() {
    return Text(
      'Devam ederek Kullanım Koşullarını ve\nGizlilik Politikasını kabul edersiniz.',
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 11,
        color: AppColors.textPrimary.withValues(alpha: 0.35),
        height: 1.5,
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    required String hint,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon, color: AppColors.textHint, size: 20),
      suffixIcon: suffixIcon,
      labelStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
      hintStyle: TextStyle(color: AppColors.textHint.withValues(alpha: 0.5), fontSize: 14),
      filled: true,
      fillColor: AppColors.backgroundCard,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: AppColors.backgroundBorder.withValues(alpha: 0.5), width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.primaryBlue, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.danger, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.danger, width: 1.5),
      ),
      errorStyle: const TextStyle(color: AppColors.danger, fontSize: 11),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }
}
