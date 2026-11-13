from rest_framework import generics, status, permissions
from rest_framework.views import APIView
from rest_framework.response import Response
from .models import Notification
from .serializers import NotificationSerializer
from .firebase_service import FirebaseService


class NotificationListView(generics.ListAPIView):
    serializer_class = NotificationSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        return Notification.objects.filter(user=self.request.user).order_by('-created_at')


class MarkReadView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request, pk=None):
        if pk:
            Notification.objects.filter(id=pk, user=request.user).update(is_read=True)
        else:
            # Mark all as read
            Notification.objects.filter(user=request.user, is_read=False).update(is_read=True)
        return Response({'message': 'Marked as read.'})


class UnreadCountView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request):
        count = Notification.objects.filter(user=request.user, is_read=False).count()
        return Response({'unread_count': count})


class SendBroadcastView(APIView):
    """Admin: send broadcast notification"""
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request):
        if request.user.role not in ['admin', 'super_admin']:
            return Response({'error': 'Forbidden'}, status=403)

        title = request.data.get('title', '')
        body = request.data.get('body', '')
        target = request.data.get('target', 'all')  # all, citizens, staff

        from accounts.models import CustomUser
        if target == 'citizens':
            users = CustomUser.objects.filter(role='citizen', is_active=True, receive_notifications=True)
        elif target == 'staff':
            users = CustomUser.objects.filter(role__in=['staff', 'admin'], is_active=True)
        else:
            users = CustomUser.objects.filter(is_active=True, receive_notifications=True)

        tokens = [u.firebase_token for u in users if u.firebase_token]

        # Save notification for all targeted users
        notifs = [Notification(user=u, title=title, body=body, type='general') for u in users]
        Notification.objects.bulk_create(notifs)

        sent = FirebaseService.send_bulk_notification(tokens, title, body)
        return Response({'message': f'Broadcast sent to {sent} devices.'})
