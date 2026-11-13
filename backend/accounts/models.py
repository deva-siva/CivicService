from django.contrib.auth.models import AbstractUser
from django.db import models
import json


class Permission(models.Model):
    """Granular permission for admin actions"""
    codename = models.CharField(max_length=100, unique=True)
    name = models.CharField(max_length=200)
    description = models.TextField(blank=True)

    def __str__(self):
        return self.name

    class Meta:
        ordering = ['codename']


class Role(models.Model):
    """Staff roles with grouped permissions"""
    name = models.CharField(max_length=100, unique=True)
    description = models.TextField(blank=True)
    permissions = models.ManyToManyField(Permission, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        return self.name

    def get_permission_codenames(self):
        return list(self.permissions.values_list('codename', flat=True))

    class Meta:
        ordering = ['name']


class CustomUser(AbstractUser):
    ROLE_CITIZEN = 'citizen'
    ROLE_STAFF = 'staff'
    ROLE_ADMIN = 'admin'
    ROLE_SUPER_ADMIN = 'super_admin'

    ROLE_CHOICES = [
        (ROLE_CITIZEN, 'Citizen'),
        (ROLE_STAFF, 'Staff'),
        (ROLE_ADMIN, 'Admin'),
        (ROLE_SUPER_ADMIN, 'Super Admin'),
    ]

    LANGUAGE_CHOICES = [
        ('en', 'English'),
        ('hi', 'Hindi'),
        ('ta', 'Tamil'),
        ('te', 'Telugu'),
        ('kn', 'Kannada'),
        ('ml', 'Malayalam'),
        ('mr', 'Marathi'),
        ('gu', 'Gujarati'),
        ('pa', 'Punjabi'),
        ('bn', 'Bengali'),
        ('or', 'Odia'),
        ('as', 'Assamese'),
        ('ur', 'Urdu'),
    ]

    email = models.EmailField(unique=True)
    phone = models.CharField(max_length=15, blank=True)
    full_name = models.CharField(max_length=200, blank=True)
    profile_pic = models.URLField(max_length=600, blank=True, default='')
    role = models.CharField(max_length=20, choices=ROLE_CHOICES, default=ROLE_CITIZEN)
    preferred_language = models.CharField(max_length=5, choices=LANGUAGE_CHOICES, default='en')
    location_text = models.CharField(max_length=300, blank=True)
    firebase_token = models.TextField(blank=True)
    is_google_user = models.BooleanField(default=False)
    google_uid = models.CharField(max_length=200, blank=True)
    receive_notifications = models.BooleanField(default=True)
    dark_mode = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    USERNAME_FIELD = 'email'
    REQUIRED_FIELDS = ['username']

    def __str__(self):
        return f"{self.full_name or self.email} ({self.role})"

    @property
    def display_name(self):
        return self.full_name or self.username or self.email

    def has_permission(self, codename):
        """Check if user (via staff profile role) has a specific permission"""
        if self.role in [self.ROLE_SUPER_ADMIN, self.ROLE_ADMIN]:
            return True
        if hasattr(self, 'staff_profile'):
            return self.staff_profile.role.permissions.filter(codename=codename).exists()
        return False

    class Meta:
        ordering = ['-created_at']


class StaffProfile(models.Model):
    """Extended profile for staff members"""
    user = models.OneToOneField(CustomUser, on_delete=models.CASCADE, related_name='staff_profile')
    department = models.ForeignKey(
        'complaints.Department', on_delete=models.SET_NULL, null=True, blank=True, related_name='staff_members'
    )
    role = models.ForeignKey(Role, on_delete=models.SET_NULL, null=True, blank=True, related_name='staff_members')
    employee_id = models.CharField(max_length=50, blank=True)
    designation = models.CharField(max_length=200, blank=True)
    joined_date = models.DateField(null=True, blank=True)
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"{self.user.display_name} - {self.designation or 'Staff'}"

    class Meta:
        ordering = ['-created_at']
