from django.contrib import admin
from django.contrib.auth.admin import UserAdmin
from .models import CustomUser, Role, Permission, StaffProfile


@admin.register(CustomUser)
class CustomUserAdmin(UserAdmin):
    list_display = ['email', 'full_name', 'role', 'phone', 'is_active', 'created_at']
    list_filter = ['role', 'is_active', 'preferred_language']
    search_fields = ['email', 'full_name', 'phone']
    ordering = ['-created_at']
    fieldsets = UserAdmin.fieldsets + (
        ('Extra Info', {'fields': ('full_name', 'phone', 'role', 'preferred_language',
                                   'location_text', 'firebase_token', 'profile_pic',
                                   'is_google_user', 'receive_notifications', 'dark_mode')}),
    )


@admin.register(Role)
class RoleAdmin(admin.ModelAdmin):
    list_display = ['name', 'description', 'created_at']
    filter_horizontal = ['permissions']


@admin.register(Permission)
class PermissionAdmin(admin.ModelAdmin):
    list_display = ['codename', 'name', 'description']
    search_fields = ['codename', 'name']


@admin.register(StaffProfile)
class StaffProfileAdmin(admin.ModelAdmin):
    list_display = ['user', 'department', 'role', 'designation', 'is_active']
    list_filter = ['department', 'role', 'is_active']
    search_fields = ['user__email', 'user__full_name', 'designation']
