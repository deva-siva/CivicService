from rest_framework import status, generics, permissions, filters
from rest_framework.decorators import api_view, permission_classes
from rest_framework.response import Response
from rest_framework.views import APIView
from django.db.models import Count, Avg, Q
from django.utils import timezone
from django.shortcuts import get_object_or_404
from django_filters.rest_framework import DjangoFilterBackend

from .models import Complaint, Department, ComplaintStatusHistory
from .serializers import (
    ComplaintSerializer, ComplaintCreateSerializer,
    ComplaintUpdateAdminSerializer, DepartmentSerializer, StatusHistorySerializer
)
from accounts.models import CustomUser
from ai_engine.classifier import classify_complaint, calculate_priority, detect_duplicates
from notifications.firebase_service import FirebaseService
from utils.cloudinary_utils import upload_image


class IsAdminOrSuperAdmin(permissions.BasePermission):
    def has_permission(self, request, view):
        return request.user.is_authenticated and request.user.role in [
            CustomUser.ROLE_ADMIN, CustomUser.ROLE_SUPER_ADMIN
        ]


class IsAdminOrStaff(permissions.BasePermission):
    def has_permission(self, request, view):
        return request.user.is_authenticated and request.user.role in [
            CustomUser.ROLE_ADMIN, CustomUser.ROLE_SUPER_ADMIN, CustomUser.ROLE_STAFF
        ]


# ─────────────── DEPARTMENT VIEWS ───────────────

class DepartmentListCreateView(generics.ListCreateAPIView):
    serializer_class = DepartmentSerializer

    def get_permissions(self):
        if self.request.method == 'GET':
            return [permissions.IsAuthenticated()]
        return [IsAdminOrSuperAdmin()]

    def get_queryset(self):
        qs = Department.objects.all()
        if self.request.query_params.get('active_only'):
            qs = qs.filter(is_active=True)
        return qs


class DepartmentDetailView(generics.RetrieveUpdateDestroyAPIView):
    queryset = Department.objects.all()
    serializer_class = DepartmentSerializer

    def get_permissions(self):
        if self.request.method == 'GET':
            return [permissions.IsAuthenticated()]
        return [IsAdminOrSuperAdmin()]

    def destroy(self, request, *args, **kwargs):
        dept = self.get_object()
        dept.is_active = False
        dept.save()
        return Response({'message': 'Department deactivated.'})


# ─────────────── COMPLAINT VIEWS (Citizen) ───────────────

class ComplaintListCreateView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request):
        """Citizens see only their own complaints"""
        qs = Complaint.objects.filter(submitted_by=request.user)
        # Filters
        status_filter = request.query_params.get('status')
        category_filter = request.query_params.get('category')
        if status_filter:
            qs = qs.filter(status=status_filter)
        if category_filter:
            qs = qs.filter(category=category_filter)
        qs = qs.order_by('-created_at')
        serializer = ComplaintSerializer(qs, many=True, context={'request': request})
        return Response(serializer.data)

    def post(self, request):
        """Submit a new complaint"""
        serializer = ComplaintCreateSerializer(data=request.data)
        if not serializer.is_valid():
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

        complaint = serializer.save(submitted_by=request.user)

        # Upload image to Cloudinary (compress to ≤ 1 MB automatically)
        if 'image' in request.FILES:
            url = upload_image(request.FILES['image'], folder='complaints')
            if url:
                complaint.image = url
                complaint.save(update_fields=['image'])

        # AI Classification
        try:
            ai_result = classify_complaint(complaint.description, complaint.title)
            complaint.ai_predicted_category = ai_result.get('category', complaint.category)
            complaint.ai_predicted_department = ai_result.get('department', '')
            complaint.ai_confidence = ai_result.get('confidence', 0.0)

            # Auto-assign category if not set by user
            if complaint.category == Complaint.CAT_OTHERS and ai_result.get('category'):
                complaint.category = ai_result['category']

            # Auto-assign department
            dept_name = ai_result.get('department', '')
            if dept_name:
                dept = Department.objects.filter(name__icontains=dept_name, is_active=True).first()
                if dept:
                    complaint.assigned_department = dept
                    complaint.status = Complaint.STATUS_ASSIGNED
        except Exception as e:
            pass  # AI failure is non-blocking

        # Priority scoring
        try:
            priority_result = calculate_priority(complaint)
            complaint.priority_score = priority_result['score']
            complaint.priority = priority_result['level']
        except Exception:
            pass

        # Duplicate detection
        try:
            duplicate_id = detect_duplicates(complaint)
            if duplicate_id:
                complaint.is_duplicate = True
                complaint.duplicate_of_id = duplicate_id
        except Exception:
            pass

        complaint.save()

        # Log status
        ComplaintStatusHistory.objects.create(
            complaint=complaint,
            old_status='',
            new_status=complaint.status,
            notes='Complaint submitted',
            updated_by=request.user,
        )

        # Notify admins
        FirebaseService.notify_new_complaint(complaint)

        return Response(
            ComplaintSerializer(complaint, context={'request': request}).data,
            status=status.HTTP_201_CREATED
        )


class ComplaintDetailView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request, pk):
        complaint = get_object_or_404(Complaint, pk=pk)
        # Citizens can only view their own
        if request.user.role == CustomUser.ROLE_CITIZEN and complaint.submitted_by != request.user:
            return Response({'error': 'Not found.'}, status=status.HTTP_404_NOT_FOUND)
        return Response(ComplaintSerializer(complaint, context={'request': request}).data)


# ─────────────── COMPLAINT VIEWS (Admin/Staff) ───────────────

class AdminComplaintListView(generics.ListAPIView):
    serializer_class = ComplaintSerializer
    permission_classes = [IsAdminOrStaff]
    filter_backends = [DjangoFilterBackend, filters.SearchFilter, filters.OrderingFilter]
    filterset_fields = ['status', 'category', 'priority', 'is_escalated', 'assigned_department']
    search_fields = ['title', 'description', 'location_text', 'submitted_by__full_name']
    ordering_fields = ['created_at', 'priority_score', 'status']
    ordering = ['-created_at']

    def get_queryset(self):
        qs = Complaint.objects.select_related(
            'submitted_by', 'assigned_department', 'assigned_staff'
        ).prefetch_related('status_history')

        # Staff can only see their department's complaints
        if self.request.user.role == CustomUser.ROLE_STAFF:
            if hasattr(self.request.user, 'staff_profile') and self.request.user.staff_profile.department:
                qs = qs.filter(assigned_department=self.request.user.staff_profile.department)

        return qs

    def get_serializer_context(self):
        return {'request': self.request}


class AdminComplaintDetailView(APIView):
    permission_classes = [IsAdminOrStaff]

    def get(self, request, pk):
        complaint = get_object_or_404(Complaint, pk=pk)
        return Response(ComplaintSerializer(complaint, context={'request': request}).data)

    def patch(self, request, pk):
        complaint = get_object_or_404(Complaint, pk=pk)
        old_status = complaint.status
        serializer = ComplaintUpdateAdminSerializer(complaint, data=request.data, partial=True)

        if not serializer.is_valid():
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

        complaint = serializer.save()
        new_status = complaint.status

        # Record resolved time
        if new_status == Complaint.STATUS_RESOLVED and not complaint.resolved_at:
            complaint.resolved_at = timezone.now()
            complaint.save(update_fields=['resolved_at'])

        # Log status change
        if old_status != new_status:
            ComplaintStatusHistory.objects.create(
                complaint=complaint,
                old_status=old_status,
                new_status=new_status,
                notes=request.data.get('admin_notes', ''),
                updated_by=request.user,
            )
            # Notify citizen
            FirebaseService.notify_status_change(complaint, old_status, new_status)

        return Response(ComplaintSerializer(complaint, context={'request': request}).data)


class EscalateComplaintView(APIView):
    permission_classes = [IsAdminOrStaff]

    def post(self, request, pk):
        complaint = get_object_or_404(Complaint, pk=pk)
        reason = request.data.get('reason', 'SLA breached')
        old_status = complaint.status

        complaint.is_escalated = True
        complaint.escalated_at = timezone.now()
        complaint.escalation_reason = reason
        complaint.status = Complaint.STATUS_ESCALATED
        complaint.save()

        ComplaintStatusHistory.objects.create(
            complaint=complaint,
            old_status=old_status,
            new_status=Complaint.STATUS_ESCALATED,
            notes=f'Escalated: {reason}',
            updated_by=request.user,
        )
        FirebaseService.notify_escalation(complaint)
        return Response({'message': 'Complaint escalated.'})


class AutoEscalateView(APIView):
    """Background task endpoint to auto-escalate SLA-breached complaints"""
    permission_classes = [IsAdminOrSuperAdmin]

    def post(self, request):
        breached = Complaint.objects.filter(
            sla_deadline__lt=timezone.now(),
            is_escalated=False,
            status__in=[Complaint.STATUS_SUBMITTED, Complaint.STATUS_ASSIGNED, Complaint.STATUS_IN_PROGRESS]
        )
        count = 0
        for complaint in breached:
            complaint.is_escalated = True
            complaint.escalated_at = timezone.now()
            complaint.escalation_reason = 'Auto-escalated: SLA breached'
            complaint.status = Complaint.STATUS_ESCALATED
            complaint.save()
            ComplaintStatusHistory.objects.create(
                complaint=complaint,
                old_status=complaint.status,
                new_status=Complaint.STATUS_ESCALATED,
                notes='Auto-escalated due to SLA breach',
            )
            count += 1
        return Response({'message': f'{count} complaints escalated.'})


# ─────────────── ANALYTICS ───────────────

class AnalyticsView(APIView):
    permission_classes = [IsAdminOrStaff]

    def get(self, request):
        qs = Complaint.objects.all()
        days = int(request.query_params.get('days', 30))
        dept_id = request.query_params.get('department')

        from django.utils import timezone
        from datetime import timedelta
        start_date = timezone.now() - timedelta(days=days)
        qs = qs.filter(created_at__gte=start_date)

        if dept_id:
            qs = qs.filter(assigned_department_id=dept_id)

        # Staff filter by department
        if request.user.role == CustomUser.ROLE_STAFF:
            if hasattr(request.user, 'staff_profile') and request.user.staff_profile.department:
                qs = qs.filter(assigned_department=request.user.staff_profile.department)

        total = qs.count()

        # By status
        status_counts = dict(qs.values_list('status').annotate(count=Count('id')))

        # By category
        by_category = dict(qs.values_list('category').annotate(count=Count('id')))

        # By department
        by_dept = list(
            qs.values('assigned_department__name').annotate(count=Count('id')).order_by('-count')
        )

        # By priority
        by_priority = dict(qs.values_list('priority').annotate(count=Count('id')))

        # Average resolution time
        resolved_qs = qs.filter(resolved_at__isnull=False)
        avg_days = 0
        if resolved_qs.exists():
            for c in resolved_qs:
                avg_days += c.days_open
            avg_days = avg_days / resolved_qs.count()

        return Response({
            'total': total,
            'submitted': status_counts.get('submitted', 0),
            'assigned': status_counts.get('assigned', 0),
            'in_progress': status_counts.get('in_progress', 0),
            'resolved': status_counts.get('resolved', 0),
            'closed': status_counts.get('closed', 0),
            'escalated': status_counts.get('escalated', 0),
            'high_priority': qs.filter(priority='high').count(),
            'by_category': by_category,
            'by_department': by_dept,
            'by_priority': by_priority,
            'avg_resolution_days': round(avg_days, 1),
        })


class UserDashboardView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request):
        qs = Complaint.objects.filter(submitted_by=request.user)
        return Response({
            'total': qs.count(),
            'open': qs.filter(status=Complaint.STATUS_SUBMITTED).count(),
            'in_progress': qs.filter(status=Complaint.STATUS_IN_PROGRESS).count(),
            'resolved': qs.filter(status=Complaint.STATUS_RESOLVED).count(),
            'escalated': qs.filter(is_escalated=True).count(),
            'recent': ComplaintSerializer(
                qs.order_by('-created_at')[:5], many=True, context={'request': request}
            ).data,
        })
