from django.contrib import admin
from .models import Complaint, Department, ComplaintStatusHistory


@admin.register(Department)
class DepartmentAdmin(admin.ModelAdmin):
    list_display = ['name', 'is_active', 'active_complaints_count', 'created_at']
    list_filter = ['is_active']
    search_fields = ['name', 'responsibilities']


@admin.register(Complaint)
class ComplaintAdmin(admin.ModelAdmin):
    list_display = ['id', 'title', 'category', 'status', 'priority', 'submitted_by',
                    'assigned_department', 'is_escalated', 'created_at']
    list_filter = ['status', 'category', 'priority', 'is_escalated']
    search_fields = ['title', 'description', 'location_text']
    ordering = ['-created_at']
    readonly_fields = ['ai_predicted_category', 'ai_predicted_department', 'ai_confidence', 'sla_deadline']


@admin.register(ComplaintStatusHistory)
class ComplaintStatusHistoryAdmin(admin.ModelAdmin):
    list_display = ['complaint', 'old_status', 'new_status', 'updated_by', 'timestamp']
    list_filter = ['new_status']
    ordering = ['-timestamp']
