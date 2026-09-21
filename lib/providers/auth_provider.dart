import 'package:flutter/foundation.dart';
import '../services/api_service.dart';
import '../services/push_service.dart';

class AuthProvider extends ChangeNotifier {
  String? _accessToken;
  Map<String, dynamic>? _user;
  bool _isLoading = false;
  String? _errorMessage;

  String? get accessToken => _accessToken;
  Map<String, dynamic>? get user => _user;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isLoggedIn => _accessToken != null;

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
  }
}
