import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../components/buttons/app_button.dart';
import '../components/inputs/app_text_field.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.login(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/home');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: AppColors.errorRed,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Industrial / Enterprise Badge Logo
                  Center(
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: AppColors.lightBlueBackground,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: AppColors.steelBlue.withValues(alpha: 0.2), width: 1.5),
                      ),
                      child: const Icon(
                        Icons.domain_rounded,
                        color: AppColors.steelBlue,
                        size: 32,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Header Titles
                  Text(
                    'BSS Attendance',
                    style: AppTextStyles.h1.copyWith(
                      fontSize: 26,
                      color: AppColors.slateNavy,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Sistem Presensi Operasional & Proyek PT BSS',
                    style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 36),

                  // Email Field Component
                  AppTextField(
                    label: 'Email Perusahaan',
                    hint: 'nama@bss.co.id',
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    prefixIcon: Icons.alternate_email_rounded,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Email wajib diisi';
                      }
                      if (!value.contains('@') || !value.contains('.')) {
                        return 'Format email tidak valid';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 18),

                  // Password Field Component
                  AppTextField(
                    label: 'Kata Sandi',
                    hint: 'Minimal 8 karakter',
                    controller: _passwordController,
                    isPassword: true,
                    prefixIcon: Icons.lock_outline_rounded,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Kata sandi wajib diisi';
                      }
                      if (value.length < 8) {
                        return 'Kata sandi minimal 8 karakter';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 28),

                  // Login Button Component
                  AppButton(
                    text: 'Masuk ke Akun',
                    icon: Icons.login_rounded,
                    onPressed: _login,
                    isLoading: _isLoading,
                    height: 50,
                  ),

                  const SizedBox(height: 28),
                  Text(
                    'Mendukung operasi online & offline di lokasi site proyek',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodySmall,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
