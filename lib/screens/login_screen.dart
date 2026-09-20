import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/app_loader.dart';
import '../utils/sound_player.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  bool _isLogin = true;
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _countryController = TextEditingController();
  final _cityController = TextEditingController();
  final _referralCodeController = TextEditingController();
  late final AnimationController _bgController;

  @override
  void initState() {
    super.initState();
    _bgController = AnimationController(vsync: this, duration: const Duration(seconds: 6))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _bgController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _fullNameController.dispose();
    _countryController.dispose();
    _cityController.dispose();
    _referralCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/backgrounds/login.jpg', fit: BoxFit.cover),
          AnimatedBuilder(
            animation: _bgController,
            builder: (context, child) {
              final t = _bgController.value;
              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment(-1.0 + t * 0.6, -1.0),
                    end: Alignment(1.0, 1.0 - t * 0.6),
                    colors: [
                      AppColors.black.withOpacity(0.75),
                      AppColors.blueDark.withOpacity(0.35),
                      AppColors.black.withOpacity(0.88),
                    ],
                  ),
                ),
              );
            },
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
                  child: const Icon(Icons.directions_car, size: 48, color: Colors.white),
                ),
                const SizedBox(height: 20),
                const Text('CARSPOT',
                  style: TextStyle(
                    fontSize: 42,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 4,
                    color: Colors.white,
                  )),
                const SizedBox(height: 4),
                Container(width: 60, height: 4, color: AppColors.red),
                const SizedBox(height: 14),
                Text(_isLogin ? 'ВХОД' : 'РЕГИСТРАЦИЯ',
                  style: const TextStyle(fontSize: 14, color: Colors.white70, letterSpacing: 2)),
                const SizedBox(height: 40),

                Container(
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.steelLight),
                  ),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      TextField(
                        controller: _usernameController,
                        decoration: InputDecoration(
                          labelText: 'Логин',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                      const SizedBox(height: 15),

                      if (!_isLogin) ...[
                        TextField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            labelText: 'Email',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                        const SizedBox(height: 15),
                        TextField(
                          controller: _fullNameController,
                          decoration: InputDecoration(
                            labelText: 'Полное имя',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                        const SizedBox(height: 15),
                        TextField(
                          controller: _countryController,
                          decoration: InputDecoration(
                            labelText: 'Страна',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                        const SizedBox(height: 15),
                        TextField(
                          controller: _cityController,
                          decoration: InputDecoration(
                            labelText: 'Город',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                        const SizedBox(height: 15),
                        TextField(
                          controller: _referralCodeController,
                          textCapitalization: TextCapitalization.characters,
                          decoration: InputDecoration(
                            labelText: 'Реферальный код (если есть)',
                            prefixIcon: const Icon(Icons.card_giftcard),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                        const SizedBox(height: 15),
                      ],

                      TextField(
                        controller: _passwordController,
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: 'Пароль',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                      const SizedBox(height: 20),

                      Consumer<AuthProvider>(
                        builder: (context, authProvider, _) {
                          return authProvider.errorMessage != null
                            ? Text(authProvider.errorMessage!, style: const TextStyle(color: AppColors.red))
                            : const SizedBox.shrink();
                        },
                      ),

                      const SizedBox(height: 20),

                      Consumer<AuthProvider>(
                        builder: (context, authProvider, _) {
                          return SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: authProvider.isLoading ? null : (_isLogin ? _login : _register),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.blue,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              child: authProvider.isLoading
                                ? AppLoader(size: 22, color: Colors.white)
                                : Text(_isLogin ? 'Войти' : 'Зарегистрироваться',
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 15),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(_isLogin ? 'Нет аккаунта? ' : 'Уже есть аккаунт? ',
                            style: const TextStyle(color: Colors.grey)),
                          GestureDetector(
                            onTap: () => setState(() => _isLogin = !_isLogin),
                            child: Text(_isLogin ? 'Зарегистрируйся' : 'Войди',
                              style: const TextStyle(color: AppColors.blue, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        ],
      ),
    );
  }

  void _login() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.login(
      username: _usernameController.text,
      password: _passwordController.text,
    );
    if (mounted) {
      SoundPlayer.play(context, authProvider.errorMessage == null ? AppSound.success : AppSound.error);
    }
  }

  void _register() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.register(
      username: _usernameController.text,
      email: _emailController.text,
      password: _passwordController.text,
      fullName: _fullNameController.text,
      country: _countryController.text,
      city: _cityController.text,
      referralCode: _referralCodeController.text,
    );
    if (mounted) {
      SoundPlayer.play(context, authProvider.errorMessage == null ? AppSound.success : AppSound.error);
    }
  }
}
