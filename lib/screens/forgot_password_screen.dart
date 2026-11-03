import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../l10n/app_localizations.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/language_toggle_button.dart';

class ForgotPasswordScreen extends StatefulWidget {
  final AuthService authService;

  const ForgotPasswordScreen({super.key, required this.authService});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  bool _isLoading = false;
  bool _emailSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleResetPassword() async {
    final l10n = context.l10n;
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.info_outline, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.isArabic
                      ? 'يرجى إدخال عنوان بريدك الإلكتروني.'
                      : 'Please enter your email address.',
                ),
              ),
            ],
          ),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await widget.authService.resetPassword(email);
      if (mounted) {
        setState(() {
          _isLoading = false;
          _emailSent = true;
        });
      }
    } on SocketException catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.error,
            content: Row(
              children: [
                const Icon(Icons.wifi_off_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.isArabic
                        ? 'خطأ في الاتصال: تعذر الاتصال بالخادم. يرجى التحقق من اتصالك بالإنترنت والمحاولة مجدداً.'
                        : 'Network error: Unable to connect. Please check your internet connection and try again.',
                  ),
                ),
              ],
            ),
          ),
        );
      }
    } on TimeoutException catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.error,
            content: Row(
              children: [
                const Icon(Icons.timer_off_outlined, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.isArabic
                        ? 'انتهت مهلة الاتصال. يرجى المحاولة مرة أخرى.'
                        : 'Connection timed out. Please try again.',
                  ),
                ),
              ],
            ),
          ),
        );
      }
    } on AuthException catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        if (e.statusCode == '429' ||
            e.message.toLowerCase().contains('rate limit')) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: AppColors.warning,
              content: Row(
                children: [
                  const Icon(Icons.hourglass_top_rounded, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.isArabic
                          ? 'طلبات كثيرة جداً. يرجى الانتظار قليلاً قبل المحاولة مجدداً.'
                          : 'Too many requests. Please wait a moment before trying again.',
                    ),
                  ),
                ],
              ),
            ),
          );
        } else if (e.statusCode == '500' ||
            e.statusCode == '502' ||
            e.statusCode == '503') {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: AppColors.error,
              content: Row(
                children: [
                  const Icon(Icons.dns_outlined, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.isArabic
                          ? 'خطأ في الخادم. يرجى المحاولة لاحقاً.'
                          : 'Server error. Please try again later.',
                    ),
                  ),
                ],
              ),
            ),
          );
        } else {
          // Generic non-enumerating confirmation per FR-AUTH-03
          setState(() => _emailSent = true);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        final errStr = e.toString().toLowerCase();
        if (errStr.contains('socket') ||
            errStr.contains('network') ||
            errStr.contains('connection') ||
            errStr.contains('clientexception')) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: AppColors.error,
              content: Row(
                children: [
                  const Icon(Icons.wifi_off_rounded, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.isArabic
                          ? 'خطأ في الاتصال. يرجى التحقق من الشبكة والمحاولة مجدداً.'
                          : 'Connection error. Please check your network and try again.',
                    ),
                  ),
                ],
              ),
            ),
          );
        } else {
          // Default non-enumerating confirmation per FR-AUTH-03
          setState(() => _emailSent = true);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      appBar: AppBar(
        title: Text(l10n.forgotPassword),
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
              child: _emailSent ? _buildSuccessView() : _buildFormView(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFormView() {
    final l10n = context.l10n;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Center(
          child: CircleAvatar(
            radius: 36,
            backgroundColor: AppColors.lightGreen,
            child: Icon(Icons.lock_reset_rounded, size: 40, color: AppColors.primary),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          l10n.isArabic ? 'استعادة كلمة المرور' : 'Reset Your Password',
          style: const TextStyle(
            fontFamily: AppTheme.fontFamily,
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AppColors.dark,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          l10n.isArabic
              ? 'أدخل البريد الإلكتروني المرتبط بحسابك، وسنرسل لك رابطاً لإعادة تعيين كلمة المرور.'
              : 'Enter the email associated with your account, and we will send you a password reset link.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: AppTheme.fontFamily,
            fontSize: 14,
            color: AppColors.dark.withOpacity(0.65),
          ),
        ),
        const SizedBox(height: 24),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: l10n.isArabic ? 'البريد الإلكتروني' : 'Email Address',
                    hintText: 'name@example.com',
                    prefixIcon: const Icon(Icons.alternate_email_rounded, size: 20),
                  ),
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _handleResetPassword(),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _isLoading ? null : _handleResetPassword,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            color: Colors.white,
                          ),
                        )
                      : Text(l10n.isArabic ? 'إرسال رابط الاستعادة' : 'Send Reset Link'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: TextButton(
            onPressed: () => context.pop(),
            child: Text(l10n.isArabic ? 'العودة لتسجيل الدخول' : 'Back to Login'),
          ),
        ),
      ],
    );
  }

  Widget _buildSuccessView() {
    final l10n = context.l10n;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Center(
              child: CircleAvatar(
                radius: 36,
                backgroundColor: AppColors.lightGreen,
                child: Icon(Icons.mark_email_read_outlined, size: 40, color: AppColors.primary),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.isArabic ? 'تفقد بريدك الإلكتروني' : 'Check Your Email',
              style: const TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.dark,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              l10n.isArabic
                  ? 'إذا كان هذا الحساب مسجلاً لدينا، فقد تم إرسال رابط إعادة تعيين كلمة المرور إلى بريدك.'
                  : 'If an account exists with that email address, a password reset link has been sent.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontSize: 15,
                color: AppColors.dark.withOpacity(0.75),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go('/login'),
              child: Text(l10n.isArabic ? 'العودة لتسجيل الدخول' : 'Return to Login'),
            ),
          ],
        ),
      ),
    );
  }
}
