import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../firebase_options.dart';
import '../screens/notifications_screen.dart';
import 'api_service.dart';

/// Глобальные ключи для показа снэкбара и навигации из push, когда нет
/// под рукой BuildContext (push приходит асинхронно, не из виджета).
final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<ScaffoldMessengerState> rootScaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

/// Push-уведомления через Firebase Cloud Messaging.
///
/// Работает "из коробки" только после того, как в проект добавлен
/// android/app/google-services.json и включён Gradle-плагин
/// com.google.gms.google-services (см. инструкцию к этому файлу).
/// До тех пор Firebase.initializeApp() просто не срабатывает — весь сервис
/// тихо остаётся неактивным и не мешает работе остального приложения.
class PushService {
  PushService._();
  static final PushService instance = PushService._();

  // Ключ Web Push сертификата (VAPID) из Firebase Console → Project settings →
  // Cloud Messaging → Web configuration. Нужен только для веб-версии — на
  // Android/iOS getToken() работает и без него.
  static const String _webVapidKey =
      'BASI5HlXWR4TZOM9BR9oU9SfKzV_pVre7xnM8Ajv2ubXwSlvVdriUciOPT6GpSZqSDo8nql8Ec58LbJBnoqjt_E';

  bool _available = false;
  String? _lastToken;

  bool get isAvailable => _available;

  /// Вызывается один раз при старте приложения, до runApp().
  Future<void> tryInitialize() async {
    try {
      await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
      _available = true;

      FirebaseMessaging.onBackgroundMessage(firebaseBackgroundHandler);

      // Приложение открыто (foreground) — системный трей сам ничего не
      // покажет для data+notification сообщений, поэтому показываем снэкбар.
      FirebaseMessaging.onMessage.listen((message) {
        final n = message.notification;
        if (n == null) return;
        rootScaffoldMessengerKey.currentState?.showSnackBar(
          SnackBar(
            content: Text('${n.title ?? 'CarSpot'}: ${n.body ?? ''}'),
            action: SnackBarAction(label: 'Открыть', onPressed: _openNotifications),
          ),
        );
      });

      // Тап по системному уведомлению, когда приложение было свёрнуто.
      FirebaseMessaging.onMessageOpenedApp.listen((_) => _openNotifications());

      // Приложение было полностью закрыто и открылось именно по тапу на push.
      final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
      if (initialMessage != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _openNotifications());
      }
    } catch (e) {
      _available = false;
      debugPrint('[Push] Firebase не настроен, push отключены: $e');
    }
  }

  void _openNotifications() {
    final navigator = rootNavigatorKey.currentState;
    if (navigator == null) return;
    navigator.push(MaterialPageRoute(builder: (_) => const NotificationsScreen()));
  }

  /// Запрашивает разрешение (важно на iOS и Android 13+) и регистрирует
  /// токен устройства на бэкенде. Вызывается после успешного логина/входа.
  Future<void> registerWithBackend(String accessToken) async {
    if (!_available) return;
    try {
      final permission = await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      if (permission.authorizationStatus == AuthorizationStatus.denied) {
        debugPrint('[Push] Пользователь запретил уведомления');
        return;
      }

      final token = kIsWeb
          ? await FirebaseMessaging.instance.getToken(vapidKey: _webVapidKey.isEmpty ? null : _webVapidKey)
          : await FirebaseMessaging.instance.getToken();
      if (token == null) return;
      _lastToken = token;
      await _sendTokenToBackend(token, accessToken);

      // Firebase иногда выдаёт новый токен (переустановка, смена устройства) —
      // подхватываем и перерегистрируем в фоне.
      FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
        _lastToken = newToken;
        _sendTokenToBackend(newToken, accessToken);
      });
    } catch (e) {
      debugPrint('[Push] Ошибка регистрации токена: $e');
    }
  }

  Future<void> _sendTokenToBackend(String token, String accessToken) async {
    try {
      await ApiService.post(
        '/api/notifications/device-token',
        {
          'token': token,
          'platform': kIsWeb ? 'web' : (defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android'),
        },
        token: accessToken,
      );
    } catch (e) {
      debugPrint('[Push] Ошибка отправки токена на сервер: $e');
    }
  }

  /// Вызывается при выходе из аккаунта — отвязываем токен на бэкенде, чтобы
  /// уведомления не продолжали приходить после логаута с этого устройства.
  Future<void> unregister(String accessToken) async {
    if (!_available || _lastToken == null) return;
    final token = _lastToken;
    _lastToken = null;
    try {
      await ApiService.delete(
        '/api/notifications/device-token?token=$token',
        token: accessToken,
      );
    } catch (e) {
      debugPrint('[Push] Ошибка отвязки токена: $e');
    }
  }
}

/// Обработчик фоновых push (приложение свёрнуто/закрыто). Должен быть
/// top-level функцией (не методом класса) — таково требование Firebase,
/// он выполняется в отдельном изоляте.
@pragma('vm:entry-point')
Future<void> firebaseBackgroundHandler(RemoteMessage message) async {
  // Системное уведомление показывает сама ОС по полю "notification" —
  // здесь дополнительно ничего делать не нужно.
}
