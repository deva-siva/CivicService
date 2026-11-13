import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../core/constants/app_constants.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal() { init(); }

  /// Set this from main.dart so the service can navigate to login on session expiry.
  static GlobalKey<NavigatorState>? navigatorKey;

  final _storage = const FlutterSecureStorage();
  late final Dio _dio;
  bool _initialized = false;

  void init() {
    if (_initialized) return;
    _initialized = true;
    _dio = Dio(BaseOptions(
      baseUrl: AppConstants.baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {'Content-Type': 'application/json'},
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _storage.read(key: AppConstants.tokenKey);
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode == 401) {
          // Try refresh token
          final refreshed = await _refreshToken();
          if (refreshed) {
            final token = await _storage.read(key: AppConstants.tokenKey);
            error.requestOptions.headers['Authorization'] = 'Bearer $token';
            final response = await _dio.fetch(error.requestOptions);
            return handler.resolve(response);
          }
          // Refresh also failed → session expired, force logout
          await _storage.deleteAll();
          navigatorKey?.currentState
              ?.pushNamedAndRemoveUntil('/login', (_) => false);
        }
        handler.next(error);
      },
    ));
  }

  Future<bool> _refreshToken() async {
    try {
      final refresh = await _storage.read(key: AppConstants.refreshTokenKey);
      if (refresh == null) return false;
      final response = await Dio().post(
        '${AppConstants.baseUrl}/token/refresh/',
        data: {'refresh': refresh},
      );
      final access = response.data['access'];
      await _storage.write(key: AppConstants.tokenKey, value: access);
      return true;
    } catch (_) {
      return false;
    }
  }

  // ─── AUTH ───────────────────────────────────────────────

  Future<Map<String, dynamic>> register(Map<String, dynamic> data) async {
    final response = await _dio.post('/auth/register/', data: data);
    return response.data;
  }

  Future<Map<String, dynamic>> login(String identifier, String password, {String? firebaseToken}) async {
    final response = await _dio.post('/auth/login/', data: {
      'identifier': identifier,
      'password': password,
      if (firebaseToken != null) 'firebase_token': firebaseToken,
    });
    return response.data;
  }

  Future<Map<String, dynamic>> googleLogin(String idToken, {String? firebaseToken}) async {
    final response = await _dio.post('/auth/google-login/', data: {
      'id_token': idToken,
      if (firebaseToken != null) 'firebase_token': firebaseToken,
    });
    return response.data;
  }

  Future<void> logout(String refreshToken) async {
    await _dio.post('/auth/logout/', data: {'refresh': refreshToken});
  }

  Future<Map<String, dynamic>> getProfile() async {
    final response = await _dio.get('/auth/profile/');
    return response.data;
  }

  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> data, {File? image}) async {
    FormData formData = FormData.fromMap({
      ...data,
      if (image != null)
        'profile_pic': await MultipartFile.fromFile(image.path),
    });
    final response = await _dio.patch('/auth/profile/', data: formData);
    return response.data;
  }

  Future<void> changePassword(String oldPassword, String newPassword) async {
    await _dio.post('/auth/change-password/', data: {
      'old_password': oldPassword,
      'new_password': newPassword,
    });
  }

  Future<void> deleteAccount() async {
    await _dio.delete('/auth/profile/');
  }

  Future<void> requestPasswordReset(String email) async {
    await _dio.post('/auth/password-reset/', data: {'email': email});
  }

  Future<void> updateFirebaseToken(String token) async {
    await _dio.post('/auth/update-firebase-token/', data: {'firebase_token': token});
  }

  // ─── COMPLAINTS ─────────────────────────────────────────

  Future<List<dynamic>> getMyComplaints({String? status, String? category}) async {
    final response = await _dio.get('/complaints/', queryParameters: {
      if (status != null) 'status': status,
      if (category != null) 'category': category,
    });
    return response.data is List ? response.data : (response.data['results'] ?? []);
  }

  Future<Map<String, dynamic>> submitComplaint({
    required String title,
    required String description,
    required String category,
    required String locationText,
    double? latitude,
    double? longitude,
    int? assignedDepartment,
    String? otherDepartment,
    File? image,
  }) async {
    FormData formData = FormData.fromMap({
      'title': title,
      'description': description,
      'category': category,
      'location_text': locationText,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (assignedDepartment != null) 'assigned_department': assignedDepartment,
      if (otherDepartment != null) 'other_department': otherDepartment,
      if (image != null) 'image': await MultipartFile.fromFile(image.path),
    });
    final response = await _dio.post('/complaints/', data: formData);
    return response.data;
  }

  Future<Map<String, dynamic>> getComplaintDetail(int id) async {
    final response = await _dio.get('/complaints/$id/');
    return response.data;
  }

  Future<Map<String, dynamic>> getUserDashboard() async {
    final response = await _dio.get('/complaints/dashboard/');
    return response.data;
  }

  // ─── ADMIN COMPLAINTS ───────────────────────────────────

  Future<Map<String, dynamic>> getAdminComplaints({
    String? status, String? category, String? priority,
    int? departmentId, String? search, String? ordering,
    int page = 1,
  }) async {
    final response = await _dio.get('/complaints/admin/all/', queryParameters: {
      if (status != null) 'status': status,
      if (category != null) 'category': category,
      if (priority != null) 'priority': priority,
      if (departmentId != null) 'assigned_department': departmentId,
      if (search != null) 'search': search,
      if (ordering != null) 'ordering': ordering,
      'page': page,
    });
    return response.data is Map ? response.data : {'results': response.data, 'count': 0};
  }

  Future<Map<String, dynamic>> updateComplaint(int id, Map<String, dynamic> data) async {
    final response = await _dio.patch('/complaints/admin/$id/', data: data);
    return response.data;
  }

  Future<void> escalateComplaint(int id, String reason) async {
    await _dio.post('/complaints/admin/$id/escalate/', data: {'reason': reason});
  }

  Future<Map<String, dynamic>> getAnalytics({int days = 30, int? departmentId}) async {
    final response = await _dio.get('/complaints/analytics/', queryParameters: {
      'days': days,
      if (departmentId != null) 'department': departmentId,
    });
    return response.data;
  }

  // ─── DEPARTMENTS ─────────────────────────────────────────

  Future<List<dynamic>> getDepartments() async {
    final response = await _dio.get('/complaints/departments/');
    return response.data is List ? response.data : (response.data['results'] ?? []);
  }

  Future<Map<String, dynamic>> createDepartment(Map<String, dynamic> data) async {
    final response = await _dio.post('/complaints/departments/', data: data);
    return response.data;
  }

  Future<Map<String, dynamic>> updateDepartment(int id, Map<String, dynamic> data) async {
    final response = await _dio.patch('/complaints/departments/$id/', data: data);
    return response.data;
  }

  Future<void> deleteDepartment(int id) async {
    await _dio.delete('/complaints/departments/$id/');
  }

  // ─── STAFF & ROLES ───────────────────────────────────────

  Future<List<dynamic>> getStaff({int? departmentId}) async {
    final response = await _dio.get('/auth/staff/', queryParameters: {
      if (departmentId != null) 'department': departmentId,
    });
    return response.data is List ? response.data : (response.data['results'] ?? []);
  }

  Future<Map<String, dynamic>> createStaff(Map<String, dynamic> data) async {
    final response = await _dio.post('/auth/staff/create/', data: data);
    return response.data;
  }

  Future<Map<String, dynamic>> updateStaff(int id, Map<String, dynamic> data) async {
    final response = await _dio.patch('/auth/staff/$id/', data: data);
    return response.data;
  }

  Future<List<dynamic>> getRoles() async {
    final response = await _dio.get('/auth/roles/');
    return response.data is List ? response.data : (response.data['results'] ?? []);
  }

  Future<Map<String, dynamic>> createRole(Map<String, dynamic> data) async {
    final response = await _dio.post('/auth/roles/', data: data);
    return response.data;
  }

  Future<Map<String, dynamic>> updateRole(int id, Map<String, dynamic> data) async {
    final response = await _dio.patch('/auth/roles/$id/', data: data);
    return response.data;
  }

  Future<void> deleteRole(int id) async {
    await _dio.delete('/auth/roles/$id/');
  }

  Future<List<dynamic>> getPermissions() async {
    final response = await _dio.get('/auth/permissions/');
    return response.data is List
        ? response.data
        : (response.data['results'] ?? []);
  }

  // ─── USER MANAGEMENT ────────────────────────────────────

  Future<Map<String, dynamic>> getUsers({String? role, bool? isActive, String? search}) async {
    final response = await _dio.get('/auth/users/', queryParameters: {
      if (role != null) 'role': role,
      if (isActive != null) 'is_active': isActive,
      if (search != null) 'search': search,
    });
    return response.data is Map ? response.data : {'results': response.data};
  }

  Future<Map<String, dynamic>> updateUser(int id, Map<String, dynamic> data) async {
    final response = await _dio.patch('/auth/users/$id/', data: data);
    return response.data;
  }

  // ─── NOTIFICATIONS ──────────────────────────────────────

  Future<List<dynamic>> getNotifications() async {
    final response = await _dio.get('/notifications/');
    return response.data is List ? response.data : (response.data['results'] ?? []);
  }

  Future<int> getUnreadCount() async {
    final response = await _dio.get('/notifications/unread-count/');
    return response.data['unread_count'] ?? 0;
  }

  Future<void> markNotificationRead(int? id) async {
    if (id != null) {
      await _dio.post('/notifications/mark-read/$id/');
    } else {
      await _dio.post('/notifications/mark-read/');
    }
  }

  // ─── ADMIN STATS ─────────────────────────────────────────

  Future<Map<String, dynamic>> getAdminStats() async {
    final response = await _dio.get('/auth/admin-stats/');
    return response.data;
  }

  Future<void> autoEscalate() async {
    await _dio.post('/complaints/admin/auto-escalate/');
  }
}
