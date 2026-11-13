from rest_framework import serializers
from .models import Notification


class NotificationSerializer(serializers.ModelSerializer):
    complaint_id = serializers.IntegerField(source='related_complaint.id', read_only=True)

    class Meta:
        model = Notification
        fields = ['id', 'title', 'body', 'type', 'is_read',
                  'complaint_id', 'created_at']
        read_only_fields = ['id', 'created_at']
