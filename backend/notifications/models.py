from django.db import models


class Notification(models.Model):
    TYPE_CHOICES = [
        ('new_complaint', 'New Complaint'),
        ('status_update', 'Status Update'),
        ('escalation', 'Escalation'),
        ('general', 'General'),
    ]

    user = models.ForeignKey(
        'accounts.CustomUser', on_delete=models.CASCADE, related_name='notifications'
    )
    title = models.CharField(max_length=200)
    body = models.TextField()
    type = models.CharField(max_length=30, choices=TYPE_CHOICES, default='general')
    is_read = models.BooleanField(default=False)
    related_complaint = models.ForeignKey(
        'complaints.Complaint', on_delete=models.SET_NULL,
        null=True, blank=True, related_name='notifications'
    )
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"{self.user.email} - {self.title}"

    class Meta:
        ordering = ['-created_at']
