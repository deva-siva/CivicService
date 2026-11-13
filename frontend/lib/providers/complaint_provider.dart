import 'dart:io';
import 'package:flutter/material.dart';
import '../models/complaint_model.dart';
import '../services/api_service.dart';

class ComplaintProvider extends ChangeNotifier {
  final _api = ApiService();

  List<ComplaintModel> _myComplaints = [];
  List<ComplaintModel> _adminComplaints = [];
  List<DepartmentModel> _departments = [];
  Map<String, dynamic> _dashboard = {};
  Map<String, dynamic> _analytics = {};
  bool _loading = false;
  bool _submitting = false;
  String? _error;
  int _adminTotal = 0;
  int _notificationCount = 0;

  List<ComplaintModel> get myComplaints => _myComplaints;
  List<ComplaintModel> get adminComplaints => _adminComplaints;
  List<DepartmentModel> get departments => _departments;
  Map<String, dynamic> get dashboard => _dashboard;
  Map<String, dynamic> get analytics => _analytics;
  bool get loading => _loading;
  bool get submitting => _submitting;
  String? get error => _error;
  int get adminTotal => _adminTotal;
  int get notificationCount => _notificationCount;

  Future<void> loadMyComplaints({String? status, String? category}) async {
    _setLoading(true);
    try {
      final data = await _api.getMyComplaints(status: status, category: category);
      _myComplaints = data.map((e) => ComplaintModel.fromJson(e)).toList();
    } catch (e) {
      _error = e.toString();
    }
    _setLoading(false);
  }

  Future<void> loadDashboard() async {
    try {
      _dashboard = await _api.getUserDashboard();
      notifyListeners();
    } catch (_) {}
  }

  Future<void> loadNotificationCount() async {
    try {
      _notificationCount = await _api.getUnreadCount();
      notifyListeners();
    } catch (_) {}
  }

  Future<ComplaintModel?> submitComplaint({
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
    _submitting = true;
    _error = null;
    notifyListeners();
    try {
      final data = await _api.submitComplaint(
        title: title,
        description: description,
        category: category,
        locationText: locationText,
        latitude: latitude,
        longitude: longitude,
        assignedDepartment: assignedDepartment,
        otherDepartment: otherDepartment,
        image: image,
      );
      final complaint = ComplaintModel.fromJson(data);
      _myComplaints.insert(0, complaint);
      _submitting = false;
      notifyListeners();
      return complaint;
    } catch (e) {
      _error = e.toString();
      _submitting = false;
      notifyListeners();
      return null;
    }
  }

  Future<void> loadAdminComplaints({
    String? status, String? category, String? priority,
    int? departmentId, String? search, int page = 1,
  }) async {
    _setLoading(true);
    try {
      final data = await _api.getAdminComplaints(
        status: status, category: category, priority: priority,
        departmentId: departmentId, search: search, page: page,
      );
      final results = data['results'] ?? data;
      _adminTotal = data['count'] ?? (results as List).length;
      _adminComplaints = (results as List).map((e) => ComplaintModel.fromJson(e)).toList();
    } catch (e) {
      _error = e.toString();
    }
    _setLoading(false);
  }

  Future<bool> updateComplaint(int id, Map<String, dynamic> data) async {
    try {
      final updated = await _api.updateComplaint(id, data);
      final idx = _adminComplaints.indexWhere((c) => c.id == id);
      if (idx != -1) {
        _adminComplaints[idx] = ComplaintModel.fromJson(updated);
      }
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> escalateComplaint(int id, String reason) async {
    try {
      await _api.escalateComplaint(id, reason);
      await loadAdminComplaints();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> loadDepartments() async {
    try {
      final data = await _api.getDepartments();
      _departments = data.map((e) => DepartmentModel.fromJson(e)).toList();
      notifyListeners();
    } catch (_) {}
  }

  Future<bool> createDepartment(Map<String, dynamic> data) async {
    try {
      final dept = await _api.createDepartment(data);
      _departments.add(DepartmentModel.fromJson(dept));
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> updateDepartment(int id, Map<String, dynamic> data) async {
    try {
      final dept = await _api.updateDepartment(id, data);
      final idx = _departments.indexWhere((d) => d.id == id);
      if (idx != -1) _departments[idx] = DepartmentModel.fromJson(dept);
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> loadAnalytics({int days = 30, int? departmentId}) async {
    try {
      _analytics = await _api.getAnalytics(days: days, departmentId: departmentId);
      notifyListeners();
    } catch (_) {}
  }

  void _setLoading(bool value) {
    _loading = value;
    notifyListeners();
  }
}
