import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../core/constants/app_constants.dart';

enum AuthState { unknown, authenticated, unauthenticated }

class AuthProvider extends ChangeNotifier {
  final _authService = AuthService();
  final _api = ApiService();

  AuthState _state = AuthState.unknown;
  UserModel? _user;
  bool _loading = false;
  String? _error;
  bool _isNewGoogleUser = false;

  AuthState get state => _state;
  UserModel? get user => _user;
  bool get loading => _loading;
  String? get error => _error;
  bool get isLoggedIn => _state == AuthState.authenticated;
  bool get isAdmin => _user?.isAdmin ?? false;
  bool get isStaff => _user?.isStaff ?? false;
  bool get darkMode => _user?.darkMode ?? false;
  /// True after a Google sign-in that created a NEW user — prompt profile completion
  bool get isNewGoogleUser => _isNewGoogleUser;

  AuthProvider() {
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    _state = AuthState.unknown;
    notifyListeners();
    final isLoggedIn = await _authService.isLoggedIn();
    if (isLoggedIn) {
      _user = await _authService.getSavedUser();
      // Refresh profile from server
      try {
        final fresh = await _authService.refreshProfile();
        if (fresh != null) _user = fresh;
      } catch (_) {}
      _state = AuthState.authenticated;
    } else {
      _state = AuthState.unauthenticated;
    }
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    _setLoading(true);
    _error = null;
    final result = await _authService.login(email, password);
    _setLoading(false);
    if (result.success) {
      _user = result.user;
      _state = AuthState.authenticated;
      notifyListeners();
      return true;
    }
    _error = result.error;
    notifyListeners();
    return false;
  }

  Future<bool> register({
    required String email,
    required String fullName,
    required String phone,
    required String password,
    required String confirmPassword,
    String preferredLanguage = 'en',
  }) async {
    _setLoading(true);
    _error = null;
    final result = await _authService.register(
      email: email, fullName: fullName, phone: phone,
      password: password, confirmPassword: confirmPassword,
      preferredLanguage: preferredLanguage,
    );
    _setLoading(false);
    if (result.success) {
      _user = result.user;
      _state = AuthState.authenticated;
      notifyListeners();
      return true;
    }
    _error = result.error;
    notifyListeners();
    return false;
  }

  Future<bool> googleSignIn() async {
    _setLoading(true);
    _error = null;
    _isNewGoogleUser = false;
    final result = await _authService.googleSignIn();
    _setLoading(false);
    if (result.success) {
      _user = result.user;
      _isNewGoogleUser = result.isNewUser;
      _state = AuthState.authenticated;
      notifyListeners();
      return true;
    }
    _error = result.error;
    notifyListeners();
    return false;
  }

  Future<void> logout() async {
    await _authService.logout();
    _user = null;
    _state = AuthState.unauthenticated;
    notifyListeners();
  }

  Future<bool> updateProfile({
    String? fullName, String? phone, String? locationText,
    String? preferredLanguage, bool? receiveNotifications, bool? darkMode,
    File? profileImage,
  }) async {
    _setLoading(true);
    try {
      final data = <String, dynamic>{};
      if (fullName != null) data['full_name'] = fullName;
      if (phone != null) data['phone'] = phone;
      if (locationText != null) data['location_text'] = locationText;
      if (preferredLanguage != null) data['preferred_language'] = preferredLanguage;
      if (receiveNotifications != null) data['receive_notifications'] = receiveNotifications;
      if (darkMode != null) data['dark_mode'] = darkMode;

      final updated = await _api.updateProfile(data, image: profileImage);
      _user = UserModel.fromJson(updated);
      await _authService.saveUser(_user!);
      _setLoading(false);
      return true;
    } catch (e) {
      _setLoading(false);
      return false;
    }
  }

  void _setLoading(bool value) {
    _loading = value;
    notifyListeners();
  }
}
