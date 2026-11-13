"""Firebase Cloud Messaging service for push notifications"""
import os
import json
import logging
from django.conf import settings

logger = logging.getLogger(__name__)

_firebase_initialized = False


def init_firebase():
    global _firebase_initialized
    if _firebase_initialized:
        return True
    try:
        import firebase_admin
        from firebase_admin import credentials

        cred_path = getattr(settings, 'FIREBASE_CREDENTIALS_PATH', '')
        if not cred_path:
            logger.error("Firebase init failed: FIREBASE_CREDENTIALS_PATH is not set in settings.")
            return False
        if not os.path.exists(cred_path):
            logger.error(f"Firebase init failed: credentials file not found at '{cred_path}'")
            return False
        cred = credentials.Certificate(cred_path)
        if not firebase_admin._apps:
            firebase_admin.initialize_app(cred)
        _firebase_initialized = True
        return True
    except Exception as e:
        logger.error(f"Firebase init failed: {e}")
    return False


class FirebaseService:

    @staticmethod
    def send_notification(token: str, title: str, body: str, data: dict = None):
        """Send a push notification to a specific device token"""
        if not token:
            return False
        if not init_firebase():
            logger.info(f"[FCM Skipped - no creds] {title}: {body}")
            return False
        try:
            from firebase_admin import messaging
            message = messaging.Message(
                notification=messaging.Notification(title=title, body=body),
                data={str(k): str(v) for k, v in (data or {}).items()},
                token=token,
                android=messaging.AndroidConfig(priority='high'),
            )
            response = messaging.send(message)
            logger.info(f"FCM sent: {response}")
            return True
        except Exception as e:
            logger.error(f"FCM send error: {e}")
            return False

    @staticmethod
    def notify_new_complaint(complaint):
        """Notify admins about a new complaint"""
        from accounts.models import CustomUser
        from notifications.models import Notification

        title = "New Complaint Submitted"
        body = f"#{complaint.id}: {complaint.title[:50]}"

        # Save notification for all admins
        admins = CustomUser.objects.filter(
            role__in=['admin', 'super_admin'], is_active=True
        )
        for admin in admins:
            notif = Notification.objects.create(
                user=admin,
                title=title,
                body=body,
                type='new_complaint',
                related_complaint=complaint,
            )
            if admin.firebase_token and admin.receive_notifications:
                FirebaseService.send_notification(
                    admin.firebase_token, title, body,
                    {'complaint_id': str(complaint.id), 'type': 'new_complaint'}
                )

    @staticmethod
    def notify_status_change(complaint, old_status: str, new_status: str):
        """Notify the citizen when their complaint status changes"""
        from notifications.models import Notification

        status_messages = {
            'assigned': 'Your complaint has been assigned to a department.',
            'in_progress': 'Work on your complaint has started.',
            'resolved': 'Your complaint has been resolved! Please confirm.',
            'closed': 'Your complaint has been closed.',
            'escalated': 'Your complaint has been escalated for priority resolution.',
        }

        title = f"Complaint #{complaint.id} Status Updated"
        body = status_messages.get(new_status, f"Status changed to: {new_status.replace('_', ' ').title()}")

        user = complaint.submitted_by
        Notification.objects.create(
            user=user,
            title=title,
            body=body,
            type='status_update',
            related_complaint=complaint,
        )
        if user.firebase_token and user.receive_notifications:
            FirebaseService.send_notification(
                user.firebase_token, title, body,
                {'complaint_id': str(complaint.id), 'new_status': new_status, 'type': 'status_update'}
            )

    @staticmethod
    def notify_escalation(complaint):
        """Notify admins and citizen about escalation"""
        from accounts.models import CustomUser
        from notifications.models import Notification

        title = f"Complaint #{complaint.id} Escalated"
        body = "This complaint has been escalated due to delay or severity."

        # Notify admins
        admins = CustomUser.objects.filter(role__in=['admin', 'super_admin'], is_active=True)
        for admin in admins:
            Notification.objects.create(
                user=admin, title=title, body=body, type='escalation', related_complaint=complaint
            )
            if admin.firebase_token:
                FirebaseService.send_notification(admin.firebase_token, title, body,
                    {'complaint_id': str(complaint.id), 'type': 'escalation'})

        # Notify citizen
        FirebaseService.notify_status_change(complaint, complaint.status, 'escalated')

    @staticmethod
    def send_bulk_notification(tokens: list, title: str, body: str, data: dict = None):
        """Send to multiple tokens"""
        success = 0
        for token in tokens:
            if FirebaseService.send_notification(token, title, body, data):
                success += 1
        return success
