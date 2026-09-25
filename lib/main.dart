import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/settings_provider.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/splash_screen.dart';
import 'theme/app_theme.dart';
import 'services/push_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Пока не добавлен android/app/google-services.json — tryInitialize()
  // просто тихо ничего не делает, весь остальной запуск это не затрагивает.
  await PushService.instance.tryInitialize();

  // Создаём AuthProvider здесь и сразу запускаем восстановление сессии по
  // сохранённому токену ("запомнить меня") — SplashGate ниже дождётся
  // этого будущего, прежде чем показать экран входа или домашний экран,
  // чтобы не мелькал логин перед автовходом.
  final authProvider = AuthProvider();
  final autoLoginFuture = authProvider.tryAutoLogin();

  runApp(CarSpotApp(authProvider: authProvider, autoLoginFuture: autoLoginFuture));
}

class CarSpotApp extends StatelessWidget {
  final AuthProvider authProvider;
  final Future<void> autoLoginFuture;

  const CarSpotApp({Key? key, required this.authProvider, required this.autoLoginFuture}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            navigatorKey: rootNavigatorKey,
            scaffoldMessengerKey: rootScaffoldMessengerKey,
            title: 'CarSpot',
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: themeProvider.themeMode,
            home: SplashGate(
              waitFor: autoLoginFuture,
              child: Consumer<AuthProvider>(
                builder: (context, authProvider, _) {
                  return authProvider.isLoggedIn
                    ? const HomeScreen()
                    : const LoginScreen();
                },
              ),
            ),
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}
