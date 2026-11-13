from rest_framework import serializers
from .models import Complaint, Department, ComplaintStatusHistory
from accounts.serializers import UserSerializer


class DepartmentSerializer(serializers.ModelSerializer):
    active_complaints_count = serializers.ReadOnlyField()

    class Meta:
        model = Department
        fields = ['id', 'name', 'description', 'responsibilities', 'icon',
                  'color', 'is_active', 'active_complaints_count', 'created_at']


class StatusHistorySerializer(serializers.ModelSerializer):
    updated_by_name = serializers.CharField(source='updated_by.display_name', read_only=True)

    class Meta:
        model = ComplaintStatusHistory
        fields = ['id', 'old_status', 'new_status', 'notes', 'updated_by_name', 'timestamp']


class ComplaintSerializer(serializers.ModelSerializer):
    submitted_by_name = serializers.CharField(source='submitted_by.display_name', read_only=True)
    submitted_by_phone = serializers.CharField(source='submitted_by.phone', read_only=True)
    department_name = serializers.CharField(source='assigned_department.name', read_only=True)
    assigned_staff_name = serializers.CharField(source='assigned_staff.display_name', read_only=True)
    status_history = StatusHistorySerializer(many=True, read_only=True)
    is_sla_breached = serializers.ReadOnlyField()
    days_open = serializers.ReadOnlyField()
    image_url = serializers.SerializerMethodField()

    class Meta:
        model = Complaint
        fields = [
            'id', 'title', 'description', 'category', 'status', 'priority', 'priority_score',
            'location_text', 'latitude', 'longitude',
            'submitted_by', 'submitted_by_name', 'submitted_by_phone',
            'assigned_department', 'department_name', 'other_department',
            'assigned_staff', 'assigned_staff_name',
            'image', 'image_url',
            'ai_predicted_category', 'ai_predicted_department', 'ai_confidence',
            'admin_override', 'is_duplicate', 'duplicate_of',
            'sla_deadline', 'is_escalated', 'escalated_at', 'escalation_reason',
            'admin_notes', 'resolution_notes',
            'created_at', 'updated_at', 'resolved_at',
            'is_sla_breached', 'days_open',
            'status_history',
        ]
        read_only_fields = ['id', 'submitted_by', 'created_at', 'updated_at', 'sla_deadline',
                            'ai_predicted_category', 'ai_predicted_department', 'ai_confidence']

    def get_image_url(self, obj):
        # image field now holds a Cloudinary URL directly
        return obj.image or None


class ComplaintCreateSerializer(serializers.ModelSerializer):
    # 'image' is handled separately in the view (uploaded to Cloudinary)
    class Meta:
        model = Complaint
        fields = ['title', 'description', 'category', 'location_text',
                  'latitude', 'longitude', 'assigned_department', 'other_department']

    def validate_description(self, value):
        if len(value.strip()) < 10:
            raise serializers.ValidationError('Description must be at least 10 characters.')
        return value


class ComplaintUpdateAdminSerializer(serializers.ModelSerializer):
    class Meta:
        model = Complaint
        fields = ['status', 'priority', 'assigned_department', 'assigned_staff',
                  'category', 'admin_notes', 'resolution_notes', 'admin_override']


class AnalyticsSerializer(serializers.Serializer):
    total = serializers.IntegerField()
    submitted = serializers.IntegerField()
    assigned = serializers.IntegerField()
    in_progress = serializers.IntegerField()
    resolved = serializers.IntegerField()
    closed = serializers.IntegerField()
    escalated = serializers.IntegerField()
    high_priority = serializers.IntegerField()
    by_category = serializers.DictField()
    by_department = serializers.ListField()
    avg_resolution_days = serializers.FloatField()
