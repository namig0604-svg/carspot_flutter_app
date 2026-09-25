import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../services/push_service.dart';

class AuthProvider extends ChangeNotifier {
  static const String _tokenPrefsKey = 'carspot_access_token';

  String? _accessToken;
  Map<String, dynamic>? _user;
  bool _isLoading = false;
  bool _isInitializing = true;
  String? _errorMessage;

  String? get accessToken => _accessToken;
  Map<String, dynamic>? get user => _user;
  bool get isLoading => _isLoading;
  bool get isInitializing => _isInitializing;
  String? get errorMessage => _errorMessage;
  bool get isLoggedIn => _accessToken != null;

  /// Восстанавливает сессию из сохранённого токена при старте приложения
  /// (важно для веба, где перезагрузка страницы иначе разлогинивала бы
  /// пользователя — токен раньше жил только в памяти).
  Future<void> tryAutoLogin() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedToken = prefs.getString(_tokenPrefsKey);
      if (savedToken != null && savedToken.isNotEmpty) {
        _accessToken = savedToken;
        notifyListeners();
        await getCurrentUser();
      }
    } catch (_) {
      // Сохранённого токена нет либо он недействителен — просто останемся
      // разлогиненными, показав обычный экран входа.
    } finally {
      _isInitializing = false;
      notifyListeners();
    }
  }

  Future<void> _persistToken(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenPrefsKey, token);
    } catch (_) {
      // Не критично: сессия просто не переживёт перезагрузку страницы.
    }
  }

  Future<void> _clearPersistedToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_tokenPrefsKey);
    } catch (_) {}
  }

  Future<void> register({
    required String username,
    required String email,
    required String password,
    required String fullName,
    required String country,
    required String city,
    String? referralCode,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final body = {
        'username': username,
        'email': email,
        'password': password,
        'full_name': fullName,
        'country': country,
        'city': city,
      };
      if (referralCode != null && referralCode.trim().isNotEmpty) {
        body['referral_code'] = referralCode.trim();
      }
      final response = await ApiService.post('/api/auth/register', body);

      _accessToken = response['access_token'];
      _user = response['user'];
      _isLoading = false;
      notifyListeners();
      unawaited(_persistToken(_accessToken!));
      PushService.instance.registerWithBackend(_accessToken!);
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> login({
    required String username,
    required String password,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await ApiService.post('/api/auth/login', {
        'username': username,
        'password': password,
      });

      _accessToken = response['access_token'];
      _user = response['user'];
      _isLoading = false;
      notifyListeners();
      unawaited(_persistToken(_accessToken!));
      PushService.instance.registerWithBackend(_accessToken!);
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> getCurrentUser() async {
    if (_accessToken == null) return;

    try {
      final response = await ApiService.get('/api/auth/me', token: _accessToken);
      _user = response;
      notifyListeners();
      PushService.instance.registerWithBackend(_accessToken!);
    } catch (e) {
      logout();
    }
  }

  void logout() {
    final token = _accessToken;
    if (token != null) PushService.instance.unregister(token);
    _accessToken = null;
    _user = null;
    notifyListeners();
    unawaited(_clearPersistedToken());
  }
}
