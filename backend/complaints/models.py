from django.db import models
from django.utils import timezone
from datetime import timedelta
from django.conf import settings


class Department(models.Model):
    name = models.CharField(max_length=200)
    description = models.TextField(blank=True)
    responsibilities = models.TextField(blank=True)
    icon = models.CharField(max_length=50, default='business')
    color = models.CharField(max_length=10, default='#2196F3')
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        return self.name

    @property
    def active_complaints_count(self):
        return self.complaints.exclude(status__in=['resolved', 'closed']).count()

    class Meta:
        ordering = ['name']


class Complaint(models.Model):
    # Category choices
    CAT_ROAD = 'road_pothole'
    CAT_WATER = 'water_leakage'
    CAT_DRAINAGE = 'drainage'
    CAT_LIGHT = 'street_light'
    CAT_GARBAGE = 'garbage_sanitation'
    CAT_OTHERS = 'others'

    CATEGORY_CHOICES = [
        (CAT_ROAD, 'Road / Pothole'),
        (CAT_WATER, 'Water Leakage'),
        (CAT_DRAINAGE, 'Drainage'),
        (CAT_LIGHT, 'Street Light'),
        (CAT_GARBAGE, 'Garbage / Sanitation'),
        (CAT_OTHERS, 'Others'),
    ]

    # Status choices
    STATUS_SUBMITTED = 'submitted'
    STATUS_ASSIGNED = 'assigned'
    STATUS_IN_PROGRESS = 'in_progress'
    STATUS_RESOLVED = 'resolved'
    STATUS_CLOSED = 'closed'
    STATUS_ESCALATED = 'escalated'

    STATUS_CHOICES = [
        (STATUS_SUBMITTED, 'Submitted'),
        (STATUS_ASSIGNED, 'Assigned'),
        (STATUS_IN_PROGRESS, 'In Progress'),
        (STATUS_RESOLVED, 'Resolved'),
        (STATUS_CLOSED, 'Closed'),
        (STATUS_ESCALATED, 'Escalated'),
    ]

    # Priority
    PRIORITY_LOW = 'low'
    PRIORITY_MEDIUM = 'medium'
    PRIORITY_HIGH = 'high'

    PRIORITY_CHOICES = [
        (PRIORITY_LOW, 'Low'),
        (PRIORITY_MEDIUM, 'Medium'),
        (PRIORITY_HIGH, 'High'),
    ]

    # Core fields
    title = models.CharField(max_length=300)
    description = models.TextField()
    category = models.CharField(max_length=30, choices=CATEGORY_CHOICES, default=CAT_OTHERS)
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default=STATUS_SUBMITTED)
    priority = models.CharField(max_length=10, choices=PRIORITY_CHOICES, default=PRIORITY_MEDIUM)
    priority_score = models.IntegerField(default=0)  # 0-100

    # Location
    location_text = models.CharField(max_length=300, blank=True)
    latitude = models.FloatField(null=True, blank=True)
    longitude = models.FloatField(null=True, blank=True)

    # Relations
    submitted_by = models.ForeignKey(
        'accounts.CustomUser', on_delete=models.CASCADE, related_name='complaints'
    )
    assigned_department = models.ForeignKey(
        Department, on_delete=models.SET_NULL, null=True, blank=True, related_name='complaints'
    )
    other_department = models.CharField(max_length=200, blank=True)  # If user chooses 'Other'
    assigned_staff = models.ForeignKey(
        'accounts.CustomUser', on_delete=models.SET_NULL, null=True, blank=True, related_name='assigned_complaints'
    )

    # Media — stored on Cloudinary; field holds the secure HTTPS URL
    image = models.URLField(max_length=600, blank=True, default='')

    # AI fields
    ai_predicted_category = models.CharField(max_length=30, blank=True)
    ai_predicted_department = models.CharField(max_length=200, blank=True)
    ai_confidence = models.FloatField(default=0.0)
    admin_override = models.BooleanField(default=False)

    # Duplicate detection
    is_duplicate = models.BooleanField(default=False)
    duplicate_of = models.ForeignKey('self', on_delete=models.SET_NULL, null=True, blank=True, related_name='duplicates')

    # SLA & escalation
    sla_deadline = models.DateTimeField(null=True, blank=True)
    is_escalated = models.BooleanField(default=False)
    escalated_at = models.DateTimeField(null=True, blank=True)
    escalation_reason = models.TextField(blank=True)

    # Notes
    admin_notes = models.TextField(blank=True)
    resolution_notes = models.TextField(blank=True)

    # Timestamps
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    resolved_at = models.DateTimeField(null=True, blank=True)

    def __str__(self):
        return f"#{self.id} - {self.title} ({self.status})"

    def save(self, *args, **kwargs):
        # Set SLA deadline on first save
        if not self.pk and not self.sla_deadline:
            sla_days = settings.SLA_CONFIG.get(self.category, 7)
            self.sla_deadline = timezone.now() + timedelta(days=sla_days)
        super().save(*args, **kwargs)

    @property
    def is_sla_breached(self):
        if self.sla_deadline and self.status not in ['resolved', 'closed']:
            return timezone.now() > self.sla_deadline
        return False

    @property
    def days_open(self):
        end = self.resolved_at or timezone.now()
        return (end - self.created_at).days

    class Meta:
        ordering = ['-created_at']


class ComplaintStatusHistory(models.Model):
    complaint = models.ForeignKey(Complaint, on_delete=models.CASCADE, related_name='status_history')
    old_status = models.CharField(max_length=20, blank=True)
    new_status = models.CharField(max_length=20)
    notes = models.TextField(blank=True)
    updated_by = models.ForeignKey(
        'accounts.CustomUser', on_delete=models.SET_NULL, null=True, blank=True
    )
    timestamp = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"#{self.complaint.id} {self.old_status} → {self.new_status}"

    class Meta:
        ordering = ['-timestamp']
