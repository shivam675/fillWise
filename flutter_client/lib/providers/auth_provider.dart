import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider({required this.apiService});

  final ApiService apiService;
  bool _isAuthenticated = false;
  String? _token;
  Map<String, dynamic>? _user;
  bool _isLoading = false;

  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  String? get token => _token;
  Map<String, dynamic>? get user => _user;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('auth_token');
    if (_token != null) {
      _isAuthenticated = true;
      apiService.setToken(_token!);
      await fetchUser();
    }
    notifyListeners();
  }

  Future<void> fetchUser() async {
    try {
      _user = await apiService.fetchCurrentUser();
      notifyListeners();
    } catch (e) {
      debugPrint('Fetch user error: $e');
      final errorStr = e.toString();
      if (errorStr.contains('401') || errorStr.contains('403')) {
        await logout();
      }
    }
  }

  Future<void> updateUser(Map<String, dynamic> data) async {
    try {
      _user = await apiService.updateUser(data);
      notifyListeners();
    } catch (e) {
      debugPrint('Update user error: $e');
      rethrow;
    }
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final token = await apiService.login(email, password);
      if (token != null) {
        _token = token;
        _isAuthenticated = true;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', token);
        apiService.setToken(token);
        await fetchUser();
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint('Login error: $e');
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<bool> signup(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      await apiService.signup(email, password);
      // Auto login after signup
      return await login(email, password);
    } catch (e) {
      debugPrint('Signup error: $e');
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<void> logout() async {
    _token = null;
    _user = null;
    _isAuthenticated = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    apiService.clearToken();
    notifyListeners();
  }
}
