class StatusHistory {
  final int id;
  final String oldStatus;
  final String newStatus;
  final String notes;
  final String? updatedByName;
  final DateTime timestamp;

  StatusHistory({
    required this.id,
    required this.oldStatus,
    required this.newStatus,
    required this.notes,
    this.updatedByName,
    required this.timestamp,
  });

  factory StatusHistory.fromJson(Map<String, dynamic> json) => StatusHistory(
    id: json['id'] ?? 0,
    oldStatus: json['old_status'] ?? '',
    newStatus: json['new_status'] ?? '',
    notes: json['notes'] ?? '',
    updatedByName: json['updated_by_name'],
    timestamp: DateTime.parse(json['timestamp']),
  );
}

class ComplaintModel {
  final int id;
  final String title;
  final String description;
  final String category;
  final String status;
  final String priority;
  final int priorityScore;
  final String locationText;
  final double? latitude;
  final double? longitude;
  final int submittedBy;
  final String? submittedByName;
  final String? submittedByPhone;
  final int? assignedDepartment;
  final String? departmentName;
  final String? otherDepartment;
  final String? assignedStaff;
  final String? assignedStaffName;
  final String? imageUrl;
  final String aiPredictedCategory;
  final String aiPredictedDepartment;
  final double aiConfidence;
  final bool adminOverride;
  final bool isDuplicate;
  final bool isEscalated;
  final String escalationReason;
  final String adminNotes;
  final String resolutionNotes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? resolvedAt;
  final DateTime? slaDeadline;
  final bool isSlaBreached;
  final int daysOpen;
  final List<StatusHistory> statusHistory;

  ComplaintModel({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.status,
    required this.priority,
    required this.priorityScore,
    required this.locationText,
    this.latitude,
    this.longitude,
    required this.submittedBy,
    this.submittedByName,
    this.submittedByPhone,
    this.assignedDepartment,
    this.departmentName,
    this.otherDepartment,
    this.assignedStaff,
    this.assignedStaffName,
    this.imageUrl,
    this.aiPredictedCategory = '',
    this.aiPredictedDepartment = '',
    this.aiConfidence = 0,
    this.adminOverride = false,
    this.isDuplicate = false,
    this.isEscalated = false,
    this.escalationReason = '',
    this.adminNotes = '',
    this.resolutionNotes = '',
    required this.createdAt,
    required this.updatedAt,
    this.resolvedAt,
    this.slaDeadline,
    this.isSlaBreached = false,
    this.daysOpen = 0,
    this.statusHistory = const [],
  });

  factory ComplaintModel.fromJson(Map<String, dynamic> json) => ComplaintModel(
    id: json['id'] ?? 0,
    title: json['title'] ?? '',
    description: json['description'] ?? '',
    category: json['category'] ?? 'others',
    status: json['status'] ?? 'submitted',
    priority: json['priority'] ?? 'medium',
    priorityScore: json['priority_score'] ?? 0,
    locationText: json['location_text'] ?? '',
    latitude: json['latitude']?.toDouble(),
    longitude: json['longitude']?.toDouble(),
    submittedBy: json['submitted_by'] ?? 0,
    submittedByName: json['submitted_by_name'],
    submittedByPhone: json['submitted_by_phone'],
    assignedDepartment: json['assigned_department'],
    departmentName: json['department_name'],
    otherDepartment: json['other_department'],
    assignedStaff: json['assigned_staff']?.toString(),
    assignedStaffName: json['assigned_staff_name'],
    imageUrl: json['image_url'],
    aiPredictedCategory: json['ai_predicted_category'] ?? '',
    aiPredictedDepartment: json['ai_predicted_department'] ?? '',
    aiConfidence: (json['ai_confidence'] ?? 0).toDouble(),
    adminOverride: json['admin_override'] ?? false,
    isDuplicate: json['is_duplicate'] ?? false,
    isEscalated: json['is_escalated'] ?? false,
    escalationReason: json['escalation_reason'] ?? '',
    adminNotes: json['admin_notes'] ?? '',
    resolutionNotes: json['resolution_notes'] ?? '',
    createdAt: DateTime.parse(json['created_at']),
    updatedAt: DateTime.parse(json['updated_at']),
    resolvedAt: json['resolved_at'] != null ? DateTime.parse(json['resolved_at']) : null,
    slaDeadline: json['sla_deadline'] != null ? DateTime.parse(json['sla_deadline']) : null,
    isSlaBreached: json['is_sla_breached'] ?? false,
    daysOpen: json['days_open'] ?? 0,
    statusHistory: (json['status_history'] as List<dynamic>? ?? [])
        .map((e) => StatusHistory.fromJson(e))
        .toList(),
  );
}

class DepartmentModel {
  final int id;
  final String name;
  final String description;
  final String responsibilities;
  final String icon;
  final String color;
  final bool isActive;
  final int activeComplaintsCount;

  DepartmentModel({
    required this.id,
    required this.name,
    this.description = '',
    this.responsibilities = '',
    this.icon = 'business',
    this.color = '#2196F3',
    this.isActive = true,
    this.activeComplaintsCount = 0,
  });

  factory DepartmentModel.fromJson(Map<String, dynamic> json) => DepartmentModel(
    id: json['id'] ?? 0,
    name: json['name'] ?? '',
    description: json['description'] ?? '',
    responsibilities: json['responsibilities'] ?? '',
    icon: json['icon'] ?? 'business',
    color: json['color'] ?? '#2196F3',
    isActive: json['is_active'] ?? true,
    activeComplaintsCount: json['active_complaints_count'] ?? 0,
  );

  Map<String, dynamic> toJson() => {
    'name': name,
    'description': description,
    'responsibilities': responsibilities,
    'icon': icon,
    'color': color,
    'is_active': isActive,
  };
}

class NotificationModel {
  final int id;
  final String title;
  final String body;
  final String type;
  final bool isRead;
  final int? complaintId;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.isRead,
    this.complaintId,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) => NotificationModel(
    id: json['id'] ?? 0,
    title: json['title'] ?? '',
    body: json['body'] ?? '',
    type: json['type'] ?? 'general',
    isRead: json['is_read'] ?? false,
    complaintId: json['complaint_id'],
    createdAt: DateTime.parse(json['created_at']),
  );
}
