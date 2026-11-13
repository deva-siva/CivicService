import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../core/constants/app_constants.dart';
import '../models/user_model.dart';
import 'api_service.dart';
import 'dart:io';
import 'package:dio/dio.dart';
import 'notification_service.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final _storage = const FlutterSecureStorage();
  final _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
    serverClientId: '783085905102-vnjg8kr0494f0daso3fsoo5aeomeu20r.apps.googleusercontent.com',
  );
  FirebaseAuth? get _firebaseAuth {
    try {
      return FirebaseAuth.instance;
    } catch (_) {
      return null;
    }
  }
  final _api = ApiService();

  // ─── TOKEN MANAGEMENT ─────────────────────────────────────

  Future<void> saveTokens(String access, String refresh) async {
    await _storage.write(key: AppConstants.tokenKey, value: access);
    await _storage.write(key: AppConstants.refreshTokenKey, value: refresh);
  }

  Future<void> saveUser(UserModel user) async {
    await _storage.write(key: AppConstants.userKey, value: jsonEncode(user.toJson()));
  }

  Future<UserModel?> getSavedUser() async {
    final data = await _storage.read(key: AppConstants.userKey);
    if (data == null) return null;
    return UserModel.fromJson(jsonDecode(data));
  }

  Future<bool> isLoggedIn() async {
    final token = await _storage.read(key: AppConstants.tokenKey);
    return token != null;
  }

  Future<void> clearTokens() async {
    await _storage.deleteAll();
  }

  // ─── REGISTER ────────────────────────────────────────────

  Future<AuthResult> register({
    required String email,
    required String fullName,
    required String phone,
    required String password,
    required String confirmPassword,
    String preferredLanguage = 'en',
  }) async {
    try {
      final data = await _api.register({
        'email': email,
        'username': email.split('@').first,
        'full_name': fullName,
        'phone': phone,
        'password': password,
        'confirm_password': confirmPassword,
        'preferred_language': preferredLanguage,
      });
      final tokens = data['tokens'];
      await saveTokens(tokens['access'], tokens['refresh']);
      final user = UserModel.fromJson(data['user']);
      await saveUser(user);
      // Update FCM token
      final fcmToken = await NotificationService.getToken();
      if (fcmToken != null) {
        await _api.updateFirebaseToken(fcmToken);
      }
      return AuthResult(success: true, user: user);
    } catch (e) {
      return AuthResult(success: false, error: _parseError(e));
    }
  }

  // ─── LOGIN ───────────────────────────────────────────────

  Future<AuthResult> login(String email, String password) async {
    try {
      final fcmToken = await NotificationService.getToken();
      final data = await _api.login(email, password, firebaseToken: fcmToken);
      final tokens = data['tokens'];
      await saveTokens(tokens['access'], tokens['refresh']);
      final user = UserModel.fromJson(data['user']);
      await saveUser(user);
      return AuthResult(success: true, user: user);
    } catch (e) {
      return AuthResult(success: false, error: _parseError(e));
    }
  }

  // ─── GOOGLE LOGIN ────────────────────────────────────────

  Future<AuthResult> googleSignIn() async {
    try {
      await _googleSignIn.signOut();
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        return AuthResult(success: false, error: 'Google sign-in cancelled');
      }

      final googleAuth = await googleUser.authentication;
      if (googleAuth.idToken == null) {
        return AuthResult(success: false, error: 'Google sign-in failed: could not retrieve ID token. Check serverClientId configuration.');
      }
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _firebaseAuth?.signInWithCredential(credential);
      final idToken = await userCredential?.user?.getIdToken();

      if (idToken == null) {
        return AuthResult(success: false, error: 'Failed to get Firebase ID token');
      }

      final fcmToken = await NotificationService.getToken();
      final data = await _api.googleLogin(idToken, firebaseToken: fcmToken);
      final tokens = data['tokens'];
      await saveTokens(tokens['access'], tokens['refresh']);
      final user = UserModel.fromJson(data['user']);
      await saveUser(user);
      return AuthResult(success: true, user: user, isNewUser: data['is_new_user'] == true);
    } catch (e) {
      return AuthResult(success: false, error: _parseError(e));
    }
  }

  // ─── LOGOUT ──────────────────────────────────────────────

  Future<void> logout() async {
    try {
      final refresh = await _storage.read(key: AppConstants.refreshTokenKey);
      if (refresh != null) {
        await _api.logout(refresh);
      }
      await _googleSignIn.signOut();
      await _firebaseAuth?.signOut();
    } catch (_) {}
    await clearTokens();
  }

  // ─── PROFILE ─────────────────────────────────────────────

  Future<UserModel?> refreshProfile() async {
    try {
      final data = await _api.getProfile();
      final user = UserModel.fromJson(data);
      await saveUser(user);
      return user;
    } catch (_) {
      return null;
    }
  }

  String _parseError(dynamic e) {
    if (e is DioException) {
      final resData = e.response?.data;
      if (resData is Map && resData['error'] != null) {
        return resData['error'].toString();
      }
      if (e.type == DioExceptionType.connectionTimeout || e.type == DioExceptionType.receiveTimeout) {
        return 'Connection timeout. Please check your internet.';
      }
      if (e.error is SocketException) {
        return 'No internet connection.';
      }
      return 'Server error (${e.response?.statusCode ?? 'no response'}). Please try again.';
    }
    if (e is FirebaseAuthException) {
      switch (e.code) {
        case 'account-exists-with-different-credential':
          return 'An account already exists with a different sign-in method.';
        case 'invalid-credential':
          return 'Google credential is invalid or expired. Please try again.';
        case 'user-disabled':
          return 'This account has been disabled.';
        case 'network-request-failed':
          return 'Network error. Please check your internet connection.';
        default:
          return 'Firebase error: ${e.message ?? e.code}';
      }
    }
    if (e is PlatformException) {
      // Google Sign-In PlatformException codes
      switch (e.code) {
        case 'sign_in_canceled':
          return 'Google sign-in was cancelled.';
        case 'sign_in_failed':
          final details = e.message ?? '';
          if (details.contains('ApiException: 10')) {
            return 'Google sign-in configuration error (code 10). Check SHA-1 fingerprint in Firebase console.';
          }
          if (details.contains('ApiException: 12500')) {
            return 'Google sign-in failed. Ensure OAuth client is configured in Firebase.';
          }
          if (details.contains('ApiException: 7')) {
            return 'Network error. Please check your internet connection.';
          }
          return 'Google sign-in failed: ${e.message}';
        case 'network_error':
          return 'Network error. Please check your internet connection.';
        default:
          return 'Google sign-in error (${e.code}): ${e.message}';
      }
    }
    if (e is Exception) {
      final msg = e.toString();
      if (msg.contains('No account found')) return 'No account found with that email, phone, or username.';
      if (msg.contains('Incorrect password')) return 'Incorrect password. Please try again.';
      if (msg.contains('Invalid email or password')) return 'Invalid credentials. Please try again.';
      if (msg.contains('Email already registered')) return 'Email already registered.';
      if (msg.contains('Passwords do not match')) return 'Passwords do not match.';
      if (msg.contains('Account has been disabled')) return 'This account has been disabled.';
      return 'Error: $msg';
    }
    return 'An unexpected error occurred: $e';
  }
}

class AuthResult {
  final bool success;
  final UserModel? user;
  final String? error;
  final bool isNewUser;

  AuthResult({required this.success, this.user, this.error, this.isNewUser = false});
}
