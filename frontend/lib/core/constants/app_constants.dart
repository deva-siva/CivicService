class AppConstants {
  // API
  static const String baseUrl = 'https://civicservice.onrender.com/api';

  // Google Maps API key
  static const String googleMapsApiKey = 'AIzaSyC5_umn1UwO4eyITUiltvqjBqS21Cp9MxM';

  // App info
  static const String appName = 'Smart Grievance';
  static const String appFullName = 'AI-Assisted Smart Grievance & Civic Issue Resolution Platform';
  static const String appVersion = '1.0.0';

  // Storage keys
  static const String tokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userKey = 'user_data';
  static const String languageKey = 'app_language';
  static const String darkModeKey = 'dark_mode';
  static const String tourSeenKey = 'tour_seen';

  // Complaint categories
  static const Map<String, String> categoryLabels = {
    'road_pothole': 'Road / Pothole',
    'water_leakage': 'Water Leakage',
    'drainage': 'Drainage',
    'street_light': 'Street Light',
    'garbage_sanitation': 'Garbage / Sanitation',
    'others': 'Others',
  };

  // Complaint status labels
  static const Map<String, String> statusLabels = {
    'submitted': 'Submitted',
    'assigned': 'Assigned',
    'in_progress': 'In Progress',
    'resolved': 'Resolved',
    'closed': 'Closed',
    'escalated': 'Escalated',
  };

  // Priority labels
  static const Map<String, String> priorityLabels = {
    'high': 'High Priority',
    'medium': 'Medium Priority',
    'low': 'Low Priority',
  };

  // Supported Indian languages
  static const Map<String, String> indianLanguages = {
    'en': 'English',
    'hi': 'हिन्दी (Hindi)',
    'ta': 'தமிழ் (Tamil)',
    'te': 'తెలుగు (Telugu)',
    'kn': 'ಕನ್ನಡ (Kannada)',
    'ml': 'മലയാളം (Malayalam)',
    'mr': 'मराठी (Marathi)',
    'gu': 'ગુજરાતી (Gujarati)',
    'pa': 'ਪੰਜਾਬੀ (Punjabi)',
    'bn': 'বাংলা (Bengali)',
    'or': 'ଓଡ଼ିଆ (Odia)',
    'as': 'অসমীয়া (Assamese)',
    'ur': 'اردو (Urdu)',
  };

  // Role definitions
  static const String roleCitizen = 'citizen';
  static const String roleStaff = 'staff';
  static const String roleAdmin = 'admin';
  static const String roleSuperAdmin = 'super_admin';

  // Permissions
  static const List<Map<String, String>> defaultPermissions = [
    {'codename': 'view_complaints', 'name': 'View Complaints'},
    {'codename': 'manage_complaints', 'name': 'Manage Complaints'},
    {'codename': 'assign_complaints', 'name': 'Assign Complaints'},
    {'codename': 'update_status', 'name': 'Update Status'},
    {'codename': 'view_analytics', 'name': 'View Analytics'},
    {'codename': 'manage_departments', 'name': 'Manage Departments'},
    {'codename': 'manage_users', 'name': 'Manage Users'},
    {'codename': 'manage_staff', 'name': 'Manage Staff'},
    {'codename': 'manage_roles', 'name': 'Manage Roles'},
    {'codename': 'send_notifications', 'name': 'Send Notifications'},
  ];
}
