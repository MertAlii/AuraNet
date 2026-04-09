import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../profile/screens/terms_screen.dart';
import '../providers/auth_provider.dart';

/// Kayıt ekranı — Ad Soyad, Email, Şifre, Şifre güç göstergesi
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;
  double _passwordStrength = 0;
  String _passwordStrengthText = '';
  Color _passwordStrengthColor = AppColors.danger;
  bool _acceptedTerms = false;

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

    _passwordController.addListener(_checkPasswordStrength);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _animController.dispose();
    super.dispose();
  }

  void _checkPasswordStrength() {
    final password = _passwordController.text;
    double strength = 0;

    if (password.length >= 6) strength += 0.2;
    if (password.length >= 8) strength += 0.15;
    if (password.length >= 12) strength += 0.15;
    if (password.contains(RegExp(r'[A-Z]'))) strength += 0.15;
    if (password.contains(RegExp(r'[a-z]'))) strength += 0.1;
    if (password.contains(RegExp(r'[0-9]'))) strength += 0.15;
    if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) strength += 0.1;

    setState(() {
      _passwordStrength = strength.clamp(0, 1);
      if (_passwordStrength < 0.3) {
        _passwordStrengthText = 'Zayıf';
        _passwordStrengthColor = AppColors.danger;
      } else if (_passwordStrength < 0.7) {
        _passwordStrengthText = 'Orta';
        _passwordStrengthColor = AppColors.warning;
      } else {
        _passwordStrengthText = 'Güçlü';
        _passwordStrengthColor = AppColors.safe;
      }
    });
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_acceptedTerms) {
      _showError('Kayıt olmak için Kullanım Koşulları ve Gizlilik Politikasını kabul etmelisiniz.');
      return;
    }
    setState(() => _isLoading = true);

    await ref.read(authProvider.notifier).registerWithEmail(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      displayName: _nameController.text.trim(),
    );

    if (mounted) {
      setState(() => _isLoading = false);
      final authState = ref.read(authProvider);
      if (authState.status == AuthStatus.error) {
        _showError(authState.errorMessage ?? 'Kayıt başarısız');
      } else if (authState.status == AuthStatus.authenticated) {
        context.go('/home');
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
                    const SizedBox(height: 30),
                    // Başlık
                    _buildHeader(),
                    const SizedBox(height: 36),
                    // Ad Soyad
                    _buildNameField(),
                    const SizedBox(height: 16),
                    // Email
                    _buildEmailField(),
                    const SizedBox(height: 16),
                    // Şifre
                    _buildPasswordField(),
                    const SizedBox(height: 8),
                    // Şifre güç göstergesi
                    if (_passwordController.text.isNotEmpty) _buildPasswordStrength(),
                    const SizedBox(height: 16),
                    // Şifre tekrar
                    _buildConfirmPasswordField(),
                    const SizedBox(height: 20),
                    // Hizmet sözleşmesi checkbox
                    _buildTermsCheckbox(),
                    const SizedBox(height: 24),
                    // Kayıt butonu
                    _buildRegisterButton(),
                    const SizedBox(height: 24),
                    // Giriş linki
                    _buildLoginLink(),
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

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryBlue.withValues(alpha: 0.3),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: const Icon(Icons.person_add_rounded, color: Colors.white, size: 32),
        ),
        const SizedBox(height: 16),
        const Text(
          'Hesap Oluştur',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'AuraNet ile ağınızı koruyun',
          style: TextStyle(
            fontSize: 13,
            color: AppColors.textPrimary.withValues(alpha: 0.5),
          ),
        ),
      ],
    );
  }

  Widget _buildNameField() {
    return TextFormField(
      controller: _nameController,
      textCapitalization: TextCapitalization.words,
      style: const TextStyle(color: AppColors.textPrimary, fontSize: 15),
      decoration: _inputDecoration(
        label: 'Ad Soyad',
        hint: 'Adınız Soyadınız',
        icon: Icons.person_outline,
      ),
      validator: (v) {
        if (v == null || v.trim().isEmpty) return 'Ad soyad gerekli';
        if (v.trim().length < 2) return 'Geçerli bir isim girin';
        return null;
      },
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
            color: AppColors.textHint, size: 20,
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

  Widget _buildPasswordStrength() {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: _passwordStrength,
              backgroundColor: AppColors.backgroundBorder,
              valueColor: AlwaysStoppedAnimation<Color>(_passwordStrengthColor),
              minHeight: 4,
            ),
          ),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              _passwordStrengthText,
              style: TextStyle(
                fontSize: 11,
                color: _passwordStrengthColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmPasswordField() {
    return TextFormField(
      controller: _confirmPasswordController,
      obscureText: _obscureConfirm,
      style: const TextStyle(color: AppColors.textPrimary, fontSize: 15),
      decoration: _inputDecoration(
        label: 'Şifre Tekrar',
        hint: '••••••••',
        icon: Icons.lock_outline,
        suffixIcon: IconButton(
          icon: Icon(
            _obscureConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined,
            color: AppColors.textHint, size: 20,
          ),
          onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
        ),
      ),
      validator: (v) {
        if (v == null || v.isEmpty) return 'Şifre tekrarı gerekli';
        if (v != _passwordController.text) return 'Şifreler eşleşmiyor';
        return null;
      },
    );
  }

  Widget _buildTermsCheckbox() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 24,
          height: 24,
          child: Checkbox(
            value: _acceptedTerms,
            activeColor: AppColors.primaryBlue,
            side: const BorderSide(color: AppColors.textHint),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            onChanged: (val) {
              setState(() => _acceptedTerms = val ?? false);
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              GestureDetector(
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (context) => const FractionallySizedBox(
                      heightFactor: 0.9,
                      child: ClipRRect(
                        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                        child: TermsScreen(),
                      ),
                    ),
                  );
                },
                child: Text(
                  'Kullanım Koşulları ve Gizlilik Politikasını',
                  style: TextStyle(
                    color: AppColors.primaryBlue,
                    fontSize: 12,
                    decoration: TextDecoration.underline,
                    decorationColor: AppColors.primaryBlue.withValues(alpha: 0.5),
                  ),
                ),
              ),
              const Text(
                ' okudum ve kabul ediyorum.',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRegisterButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _register,
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
                'Kayıt Ol',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
      ),
    );
  }

  Widget _buildLoginLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Zaten hesabınız var mı? ',
          style: TextStyle(
            color: AppColors.textPrimary.withValues(alpha: 0.6),
            fontSize: 14,
          ),
        ),
        GestureDetector(
          onTap: () => context.pop(),
          child: const Text(
            'Giriş Yap',
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
