import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import '../widgets/app_loader.dart';
import '../l10n/l10n_extensions.dart';

/// Экран восстановления пароля в два шага:
/// 1) ввод email и запрос кода на почту (POST /api/auth/forgot-password);
/// 2) ввод кода + нового пароля (POST /api/auth/reset-password).
///
/// Бэкенд всегда отвечает 200 на первом шаге (не раскрывает, существует ли
/// email), поэтому мы переходим на шаг 2 независимо от результата.
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({Key? key}) : super(key: key);

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  int _step = 1;
  bool _isLoading = false;
  String? _passwordMismatchError;

  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _requestCode({bool isResend = false}) async {
    final email = _emailController.text.trim();
    if (email.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      final response = await ApiService.post('/api/auth/forgot-password', {'email': email});
      final message = (response is Map && response['message'] != null)
          ? response['message'].toString()
          : context.t('forgot_password.generic_sent_message');

      if (!mounted) return;
      setState(() {
        _isLoading = false;
        if (!isResend) _step = 2;
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tArgs('forgot_password.error_message', {'error': '$e'}))),
      );
    }
  }

  Future<void> _resetPassword() async {
    final newPassword = _newPasswordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (newPassword != confirmPassword) {
      setState(() => _passwordMismatchError = context.t('forgot_password.passwords_dont_match'));
      return;
    }

    setState(() {
      _passwordMismatchError = null;
      _isLoading = true;
    });

    try {
      await ApiService.post('/api/auth/reset-password', {
        'email': _emailController.text.trim(),
        'code': _codeController.text.trim(),
        'new_password': newPassword,
      });

      if (!mounted) return;
      // Экран восстановления пароля всегда попадает на стек одним push()
      // прямо с экрана логина, поэтому один pop() возвращает именно туда.
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.t('forgot_password.success_message'))),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tArgs('forgot_password.error_message', {'error': '$e'}))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/backgrounds/login.jpg', fit: BoxFit.cover),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.black.withOpacity(0.75),
                  AppColors.blueDark.withOpacity(0.35),
                  AppColors.black.withOpacity(0.88),
                ],
              ),
            ),
          ),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.red,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(color: AppColors.red.withOpacity(0.5), blurRadius: 24, spreadRadius: 2),
                      ],
                    ),
                    child: const Icon(Icons.lock_reset, size: 48, color: Colors.white),
                  ),
                  const SizedBox(height: 20),
                  Text(context.t('forgot_password.title'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1,
                        color: Colors.white,
                      )),
                  const SizedBox(height: 4),
                  Container(width: 60, height: 4, color: AppColors.red),
                  const SizedBox(height: 30),

                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppColors.steelLight),
                    ),
                    padding: const EdgeInsets.all(20),
                    child: _step == 1 ? _buildStep1() : _buildStep2(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep1() {
    return Column(
      children: [
        Text(
          context.t('forgot_password.subtitle_step1'),
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.black54),
        ),
        const SizedBox(height: 20),
        TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            labelText: context.t('forgot_password.email_label'),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: _isLoading ? null : () => _requestCode(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.blue,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: _isLoading
                ? AppLoader(size: 22, color: Colors.white)
                : Text(context.t('forgot_password.send_code_button'),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
          ),
        ),
      ],
    );
  }

  Widget _buildStep2() {
    return Column(
      children: [
        Text(
          context.tArgs('forgot_password.subtitle_step2', {'email': _emailController.text.trim()}),
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.black54),
        ),
        const SizedBox(height: 20),
        TextField(
          controller: _codeController,
          keyboardType: TextInputType.number,
          maxLength: 6,
          decoration: InputDecoration(
            labelText: context.t('forgot_password.code_label'),
            counterText: '',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
        const SizedBox(height: 15),
        TextField(
          controller: _newPasswordController,
          obscureText: true,
          decoration: InputDecoration(
            labelText: context.t('forgot_password.new_password_label'),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
        const SizedBox(height: 15),
        TextField(
          controller: _confirmPasswordController,
          obscureText: true,
          decoration: InputDecoration(
            labelText: context.t('forgot_password.confirm_password_label'),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
        if (_passwordMismatchError != null) ...[
          const SizedBox(height: 10),
          Text(_passwordMismatchError!, style: const TextStyle(color: AppColors.red)),
        ],
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _resetPassword,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.blue,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: _isLoading
                ? AppLoader(size: 22, color: Colors.white)
                : Text(context.t('forgot_password.reset_button'),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
          ),
        ),
        const SizedBox(height: 15),
        TextButton(
          onPressed: _isLoading ? null : () => _requestCode(isResend: true),
          child: Text(context.t('forgot_password.resend_code'),
              style: const TextStyle(color: AppColors.blue, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
