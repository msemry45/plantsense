import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../l10n/app_localizations.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/google_logo.dart';
import '../widgets/language_toggle_button.dart';

class RegisterScreen extends StatefulWidget {
  final AuthService authService;

  const RegisterScreen({super.key, required this.authService});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _usernameController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    final l10n = context.l10n;
    final isArabic = l10n.isArabic;
    final name = _nameController.text.trim();
    final username = _usernameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    // 1. Client-side field validations before sending any network request
    if (name.isEmpty) {
      _showWarning(isArabic ? 'يرجى إدخال الاسم الكامل.' : 'Please enter your full name.');
      return;
    }
    if (name.length < 2) {
      _showWarning(isArabic ? 'الاسم الكامل يجب أن يتكون من حرفين على الأقل.' : 'Full name must be at least 2 characters.');
      return;
    }

    if (username.isEmpty) {
      _showWarning(isArabic ? 'يرجى إدخال اسم المستخدم.' : 'Please enter a username.');
      return;
    }
    if (username.length < 3) {
      _showWarning(isArabic ? 'اسم المستخدم يجب أن يتكون من 3 أحرف أو أرقام على الأقل.' : 'Username must be at least 3 characters.');
      return;
    }
    if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(username)) {
      _showWarning(isArabic ? 'اسم المستخدم يمكن أن يحتوي على أحرف وأرقام وشرطة سفلية فقط.' : 'Username can only contain letters, numbers, and underscores.');
      return;
    }

    if (email.isEmpty) {
      _showWarning(isArabic ? 'يرجى إدخال البريد الإلكتروني.' : 'Please enter your email address.');
      return;
    }
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      _showWarning(isArabic ? 'يرجى إدخال بريد إلكتروني صالح (مثال: name@example.com).' : 'Please enter a valid email address.');
      return;
    }

    if (password.isEmpty) {
      _showWarning(isArabic ? 'يرجى إدخال كلمة المرور.' : 'Please enter a password.');
      return;
    }
    if (password.length < 6) {
      _showWarning(isArabic ? 'كلمة المرور يجب ألا تقل عن 6 خانات.' : 'Password must be at least 6 characters.');
      return;
    }

    if (password != confirmPassword) {
      _showWarning(isArabic ? 'كلمتا المرور غير متطابقتين.' : 'Passwords do not match.');
      return;
    }

    setState(() => _isLoading = true);
    try {
      await widget.authService.signUp(
        email: email,
        password: password.trim(),
        username: username,
        fullName: name,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.success,
            content: Row(
              children: [
                const Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isArabic
                        ? 'تم إنشاء الحساب بنجاح!'
                        : 'Registration successful! Check email if required.',
                  ),
                ),
              ],
            ),
          ),
        );
        context.pop();
      }
    } on SocketException catch (_) {
      _showError(isArabic
          ? 'تعذر الاتصال بالخادم. يرجى التحقق من اتصال الإنترنت.'
          : 'Network error. Please check your internet connection.');
    } on TimeoutException catch (_) {
      _showError(isArabic
          ? 'انتهت مهلة الاتصال بالخادم. يرجى المحاولة مرة أخرى.'
          : 'Connection timed out. Please try again.');
    } on AuthException catch (e) {
      final msg = e.message.toLowerCase();
      final code = e.statusCode ?? '';
      if (code == '429' || msg.contains('rate limit') || msg.contains('over_email_send_rate_limit')) {
        _showWarning(isArabic
            ? 'تم تجاوز حد إرسال الرسائل المؤقت. يرجى الانتظار قليلاً ثم المحاولة.'
            : 'Too many requests. Please wait a moment before trying again.');
      } else if (msg.contains('username') || msg.contains('profiles_username_key')) {
        _showError(isArabic
            ? 'اسم المستخدم محجوز بالفعل. يرجى اختيار اسم آخر.'
            : 'Username is already taken. Please choose another.');
      } else if (msg.contains('already registered') || msg.contains('already exists') || msg.contains('duplicate')) {
        _showError(isArabic
            ? 'البريد الإلكتروني مسجل بالفعل. يرجى تسجيل الدخول أو استعادة كلمة المرور.'
            : 'Email is already registered. Please login or reset password.');
      } else if (code == '422' || msg.contains('invalid') || msg.contains('validation')) {
        _showError(isArabic
            ? 'بيانات التسجيل غير صالحة. يرجى مراجعة البريد وكلمة المرور.'
            : 'Invalid registration details. Please verify your email and password.');
      } else {
        _showError(isArabic
            ? 'تعذر إتمام التسجيل: ${e.message}'
            : 'Registration failed: ${e.message}');
      }
    } catch (e) {
      final errStr = e.toString().toLowerCase();
      if (errStr.contains('socket') || errStr.contains('network') || errStr.contains('connection') || errStr.contains('clientexception')) {
        _showError(isArabic
            ? 'تعذر الاتصال بالخادم. يرجى التحقق من اتصال الإنترنت.'
            : 'Network error. Please check your internet connection.');
      } else if (errStr.contains('username') && (errStr.contains('taken') || errStr.contains('unique') || errStr.contains('duplicate'))) {
        _showError(isArabic
            ? 'اسم المستخدم محجوز بالفعل. يرجى اختيار اسم آخر.'
            : 'Username is already taken. Please choose another.');
      } else if (errStr.contains('429') || errStr.contains('rate limit')) {
        _showWarning(isArabic
            ? 'تم تجاوز حد الطلبات المؤقت. يرجى الانتظار قليلاً ثم المحاولة.'
            : 'Too many requests. Please wait a moment before trying again.');
      } else {
        _showError(isArabic
            ? 'حدث خطأ غير متوقع أثناء إنشاء الحساب. يرجى المحاولة لاحقاً.'
            : 'An unexpected error occurred during registration. Please try again later.');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showWarning(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          backgroundColor: AppColors.warning,
          content: Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Expanded(child: Text(message)),
            ],
          ),
        ),
      );
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          backgroundColor: AppColors.error,
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Expanded(child: Text(message)),
            ],
          ),
        ),
      );
  }

  Future<void> _handleGoogleSignIn() async {
    final l10n = context.l10n;
    setState(() => _isLoading = true);
    try {
      await widget.authService.signInWithGoogle();
    } on AuthException catch (e) {
      if (mounted) {
        final isCancel = e.message.toLowerCase().contains('cancel') ||
            e.statusCode == 'canceled';
        _showError(isCancel ? l10n.googleSignInCancelled : '${l10n.error}: ${e.message}');
      }
    } on SocketException {
      if (mounted) {
        _showError(l10n.networkError);
      }
    } catch (e) {
      if (mounted) {
        debugPrint('[GoogleSignUp] Unexpected error: $e');
        final errStr = e.toString().toLowerCase();
        if (errStr.contains('cancel')) {
          _showError(l10n.googleSignInCancelled);
        } else if (errStr.contains('socket') || errStr.contains('network') || errStr.contains('connection')) {
          _showError(l10n.networkError);
        } else {
          _showError(l10n.isArabic
              ? 'تعذر إتمام التسجيل عبر Google. يرجى المحاولة لاحقاً.'
              : 'Google sign-up could not be completed. Please try again later.');
        }
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      appBar: AppBar(
        title: Text(l10n.register),
        actions: const [
          LanguageToggleButton(),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Center(
                    child: SVPGLogo(height: 80),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.createNewAccountHeader,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.dark,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextField(
                            controller: _nameController,
                            decoration: InputDecoration(
                              labelText: l10n.fullName,
                              prefixIcon: const Icon(Icons.person_outline_rounded, size: 20),
                            ),
                            textInputAction: TextInputAction.next,
                          ),
                          const SizedBox(height: 14),
                          TextField(
                            controller: _usernameController,
                            decoration: InputDecoration(
                              labelText: l10n.username,
                              prefixIcon: const Icon(Icons.badge_outlined, size: 20),
                            ),
                            textInputAction: TextInputAction.next,
                          ),
                          const SizedBox(height: 14),
                          TextField(
                            controller: _emailController,
                            decoration: InputDecoration(
                              labelText: l10n.email,
                              hintText: 'name@example.com',
                              prefixIcon: const Icon(Icons.alternate_email_rounded, size: 20),
                            ),
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                          ),
                          const SizedBox(height: 14),
                          TextField(
                            controller: _passwordController,
                            decoration: InputDecoration(
                              labelText: l10n.password,
                              prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  size: 20,
                                ),
                                onPressed: () {
                                  setState(() => _obscurePassword = !_obscurePassword);
                                },
                              ),
                            ),
                            obscureText: _obscurePassword,
                            textInputAction: TextInputAction.next,
                          ),
                          const SizedBox(height: 14),
                          TextField(
                            controller: _confirmPasswordController,
                            decoration: InputDecoration(
                              labelText: l10n.isArabic ? 'تأكيد كلمة المرور' : 'Confirm Password',
                              prefixIcon: const Icon(Icons.lock_reset_rounded, size: 20),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscureConfirmPassword
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  size: 20,
                                ),
                                onPressed: () {
                                  setState(() => _obscureConfirmPassword = !_obscureConfirmPassword);
                                },
                              ),
                            ),
                            obscureText: _obscureConfirmPassword,
                            textInputAction: TextInputAction.done,
                            onSubmitted: (_) => _register(),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: _isLoading ? null : _register,
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(l10n.register),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      const Expanded(child: Divider()),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12.0),
                        child: Text(
                          l10n.isArabic ? 'أو' : 'OR',
                          style: TextStyle(
                            fontFamily: AppTheme.fontFamily,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.dark.withOpacity(0.4),
                          ),
                        ),
                      ),
                      const Expanded(child: Divider()),
                    ],
                  ),
                  const SizedBox(height: 14),
                  OutlinedButton(
                    onPressed: _isLoading ? null : _handleGoogleSignIn,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: BorderSide(color: AppColors.dark.withOpacity(0.2)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const GoogleLogo(size: 20),
                        const SizedBox(width: 12),
                        Text(
                          l10n.signUpWithGoogle,
                          style: const TextStyle(
                            fontFamily: AppTheme.fontFamily,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: AppColors.dark,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: TextButton(
                      onPressed: () => context.pop(),
                      child: Text(
                        l10n.isArabic
                            ? 'لديك حساب بالفعل؟ تسجيل الدخول'
                            : 'Already have an account? Login',
                      ),
                    ),
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
