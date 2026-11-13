class StaffProfile {
  final int id;
  final int? departmentId;
  final String? departmentName;
  final int? roleId;
  final String? roleName;
  final String employeeId;
  final String designation;
  final bool isActive;

  StaffProfile({
    required this.id,
    this.departmentId,
    this.departmentName,
    this.roleId,
    this.roleName,
    this.employeeId = '',
    this.designation = '',
    this.isActive = true,
  });

  factory StaffProfile.fromJson(Map<String, dynamic> json) {
    return StaffProfile(
      id: json['id'] ?? 0,
      departmentId: json['department'],
      departmentName: json['department_name'],
      roleId: json['role'],
      roleName: json['role_name'],
      employeeId: json['employee_id'] ?? '',
      designation: json['designation'] ?? '',
      isActive: json['is_active'] ?? true,
    );
  }
}

class UserModel {
  final int id;
  final String email;
  final String username;
  final String fullName;
  final String phone;
  final String role;
  final String preferredLanguage;
  final String locationText;
  final String? profilePic;
  final bool isGoogleUser;
  final bool receiveNotifications;
  final bool darkMode;
  final bool isActive;
  final StaffProfile? staffProfile;
  final int complaintCount;
  final DateTime? createdAt;

  UserModel({
    required this.id,
    required this.email,
    required this.username,
    this.fullName = '',
    this.phone = '',
    this.role = 'citizen',
    this.preferredLanguage = 'en',
    this.locationText = '',
    this.profilePic,
    this.isGoogleUser = false,
    this.receiveNotifications = true,
    this.darkMode = false,
    this.isActive = true,
    this.staffProfile,
    this.complaintCount = 0,
    this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? 0,
      email: json['email'] ?? '',
      username: json['username'] ?? '',
      fullName: json['full_name'] ?? '',
      phone: json['phone'] ?? '',
      role: json['role'] ?? 'citizen',
      preferredLanguage: json['preferred_language'] ?? 'en',
      locationText: json['location_text'] ?? '',
      profilePic: json['profile_pic'],
      isGoogleUser: json['is_google_user'] ?? false,
      receiveNotifications: json['receive_notifications'] ?? true,
      darkMode: json['dark_mode'] ?? false,
      isActive: json['is_active'] ?? true,
      staffProfile: json['staff_profile'] != null
          ? StaffProfile.fromJson(json['staff_profile'])
          : null,
      complaintCount: json['complaint_count'] ?? 0,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'username': username,
    'full_name': fullName,
    'phone': phone,
    'role': role,
    'preferred_language': preferredLanguage,
    'location_text': locationText,
    'profile_pic': profilePic,
    'is_google_user': isGoogleUser,
    'receive_notifications': receiveNotifications,
    'dark_mode': darkMode,
    'is_active': isActive,
    'complaint_count': complaintCount,
  };

  String get displayName => fullName.isNotEmpty ? fullName : username;

  bool get isAdmin => role == 'admin' || role == 'super_admin';
  bool get isStaff => role == 'staff';
  bool get isCitizen => role == 'citizen';

  UserModel copyWith({
    String? fullName, String? phone, String? preferredLanguage,
    String? locationText, String? profilePic, bool? receiveNotifications, bool? darkMode,
  }) {
    return UserModel(
      id: id, email: email, username: username,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      role: role,
      preferredLanguage: preferredLanguage ?? this.preferredLanguage,
      locationText: locationText ?? this.locationText,
      profilePic: profilePic ?? this.profilePic,
      isGoogleUser: isGoogleUser,
      receiveNotifications: receiveNotifications ?? this.receiveNotifications,
      darkMode: darkMode ?? this.darkMode,
      isActive: isActive,
      staffProfile: staffProfile,
      complaintCount: complaintCount,
    );
  }
}
