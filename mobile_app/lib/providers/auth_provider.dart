import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

class AuthProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  bool _isAuthenticated = false;
  String? _token;
  String? _username;
  
  bool get isAuthenticated => _isAuthenticated;
  String? get token => _token;
  String? get username => _username;
  
  AuthProvider() {
    _loadToken();
  }
  
  Future<void> _loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('auth_token');
    _username = prefs.getString('username');
    _isAuthenticated = _token != null;
    notifyListeners();
  }
  
  Future<bool> login(String username, String password) async {
    try {
      final response = await _apiService.login(username, password);
      _token = response['access_token'];
      _username = username;
      _isAuthenticated = true;
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', _token!);
      await prefs.setString('username', username);
      
      notifyListeners();
      return true;
    } catch (e) {
      // Log the actual error for debugging
      print('Login error: $e');
      if (e is Exception) {
        print('Exception details: ${e.toString()}');
      }
      return false;
    }
  }
  
  Future<bool> register(Map<String, String> userData) async {
    try {
      await _apiService.register(userData);
      return true;
    } catch (e) {
      return false;
    }
  }
  
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('username');
    
    _token = null;
    _username = null;
    _isAuthenticated = false;
    notifyListeners();
  }
}
