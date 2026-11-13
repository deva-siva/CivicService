from rest_framework import status, generics, permissions
from rest_framework.decorators import api_view, permission_classes
from rest_framework.response import Response
from rest_framework.views import APIView
from rest_framework_simplejwt.tokens import RefreshToken
from django.contrib.auth import update_session_auth_hash
from django.shortcuts import get_object_or_404
import requests as http_requests

from .models import CustomUser, Role, Permission, StaffProfile
from .serializers import (
    RegisterSerializer, LoginSerializer, UserSerializer,
    UpdateProfileSerializer, ChangePasswordSerializer,
    RoleSerializer, PermissionSerializer, CreateStaffSerializer,
    StaffProfileSerializer, GoogleAuthSerializer
)
from notifications.firebase_service import FirebaseService, init_firebase
from utils.cloudinary_utils import upload_image

# ─── Default permissions seeded automatically if DB is empty ─────────────────

DEFAULT_PERMISSIONS = [
    ('view_complaints',     'View all complaints'),
    ('manage_complaints',   'Assign & update complaint status'),
    ('escalate_complaints', 'Escalate complaints'),
    ('manage_users',        'Create, edit and deactivate users'),
    ('manage_staff',        'Create and manage staff members'),
    ('manage_departments',  'Create and manage departments'),
    ('manage_roles',        'Create and manage roles & permissions'),
    ('view_analytics',      'View analytics and reports'),
    ('send_notifications',  'Send push notifications to users'),
    ('export_reports',      'Export data reports'),
]


def _ensure_permissions_seeded():
    """Ensure all default permissions exist (idempotent — safe to call anytime)."""
    for codename, name in DEFAULT_PERMISSIONS:
        Permission.objects.get_or_create(codename=codename, defaults={'name': name})


def get_tokens_for_user(user):
    refresh = RefreshToken.for_user(user)
    return {
        'refresh': str(refresh),
        'access': str(refresh.access_token),
    }


class RegisterView(APIView):
    permission_classes = [permissions.AllowAny]

    def post(self, request):
        serializer = RegisterSerializer(data=request.data)
        if serializer.is_valid():
            user = serializer.save()
            tokens = get_tokens_for_user(user)
            return Response({
                'message': 'Registration successful.',
                'tokens': tokens,
                'user': UserSerializer(user).data,
            }, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


class LoginView(APIView):
    permission_classes = [permissions.AllowAny]

    def post(self, request):
        serializer = LoginSerializer(data=request.data)
        if serializer.is_valid():
            user = serializer.validated_data['user']
            # Update firebase token if provided
            firebase_token = serializer.validated_data.get('firebase_token', '')
            if firebase_token:
                user.firebase_token = firebase_token
                user.save(update_fields=['firebase_token'])
            tokens = get_tokens_for_user(user)
            return Response({
                'message': 'Login successful.',
                'tokens': tokens,
                'user': UserSerializer(user).data,
            })
        return Response(serializer.errors, status=status.HTTP_401_UNAUTHORIZED)


class GoogleLoginView(APIView):
    """Handle Google Sign-In via Firebase ID token"""
    permission_classes = [permissions.AllowAny]

    def post(self, request):
        serializer = GoogleAuthSerializer(data=request.data)
        if not serializer.is_valid():
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

        id_token = serializer.validated_data['id_token']
        firebase_token = serializer.validated_data.get('firebase_token', '')

        # Verify Firebase ID token
        if not init_firebase():
            return Response(
                {'error': 'Firebase is not configured on the server. Set FIREBASE_CREDENTIALS_PATH.'},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )
        try:
            import firebase_admin
            from firebase_admin import auth as firebase_auth
            decoded_token = firebase_auth.verify_id_token(id_token)
            uid = decoded_token['uid']
            email = decoded_token.get('email', '')
            name = decoded_token.get('name', '')
            picture = decoded_token.get('picture', '')
        except Exception as e:
            return Response({'error': f'Invalid token: {str(e)}'}, status=status.HTTP_401_UNAUTHORIZED)

        # Get or create user
        user, created = CustomUser.objects.get_or_create(
            email=email,
            defaults={
                'username': email.split('@')[0],
                'full_name': name,
                'is_google_user': True,
                'google_uid': uid,
                'role': CustomUser.ROLE_CITIZEN,
            }
        )
        if not created:
            user.is_google_user = True
            user.google_uid = uid
            if name and not user.full_name:
                user.full_name = name

        if firebase_token:
            user.firebase_token = firebase_token
        user.save()

        tokens = get_tokens_for_user(user)
        return Response({
            'message': 'Google login successful.',
            'tokens': tokens,
            'user': UserSerializer(user).data,
            'is_new_user': created,
        })


class LogoutView(APIView):
    def post(self, request):
        try:
            refresh_token = request.data['refresh']
            token = RefreshToken(refresh_token)
            token.blacklist()
            # Clear firebase token
            request.user.firebase_token = ''
            request.user.save(update_fields=['firebase_token'])
        except Exception:
            pass
        return Response({'message': 'Logged out successfully.'})


class ProfileView(generics.RetrieveUpdateAPIView):
    serializer_class = UpdateProfileSerializer

    def get_object(self):
        return self.request.user

    def get(self, request, *args, **kwargs):
        return Response(UserSerializer(request.user).data)

    def patch(self, request, *args, **kwargs):
        # Upload profile picture to Cloudinary if provided (compress to ≤ 1 MB)
        if 'profile_pic' in request.FILES:
            url = upload_image(request.FILES['profile_pic'], folder='profiles')
            if url:
                request.user.profile_pic = url
                request.user.save(update_fields=['profile_pic'])

        serializer = UpdateProfileSerializer(request.user, data=request.data, partial=True)
        if serializer.is_valid():
            serializer.save()
            return Response(UserSerializer(request.user).data)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

    def delete(self, request, *args, **kwargs):
        """Soft-delete: deactivate and anonymise the account"""
        user = request.user
        user.is_active = False
        user.full_name = 'Deleted User'
        user.phone = ''
        user.firebase_token = ''
        user.save()
        return Response({'message': 'Account deleted.'}, status=status.HTTP_204_NO_CONTENT)


class ChangePasswordView(APIView):
    def post(self, request):
        serializer = ChangePasswordSerializer(data=request.data, context={'request': request})
        if serializer.is_valid():
            request.user.set_password(serializer.validated_data['new_password'])
            request.user.save()
            return Response({'message': 'Password changed successfully.'})
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


class UpdateFirebaseTokenView(APIView):
    def post(self, request):
        token = request.data.get('firebase_token', '')
        request.user.firebase_token = token
        request.user.save(update_fields=['firebase_token'])
        return Response({'message': 'Token updated.'})


class PasswordResetRequestView(APIView):
    """Send password-reset email (or OTP in future). Currently returns 200 always."""
    permission_classes = [permissions.AllowAny]

    def post(self, request):
        # Always return 200 to prevent email enumeration
        # In production: generate token, send email via django.core.mail
        email = request.data.get('email', '').strip()
        if email:
            user = CustomUser.objects.filter(email=email, is_active=True).first()
            if user:
                # TODO: send actual reset email
                pass
        return Response({'message': 'If the email exists, a reset link has been sent.'})


# ─────────────── ROLE MANAGEMENT (Admin) ───────────────

class IsAdminOrSuperAdmin(permissions.BasePermission):
    def has_permission(self, request, view):
        return request.user.is_authenticated and request.user.role in [
            CustomUser.ROLE_ADMIN, CustomUser.ROLE_SUPER_ADMIN
        ]


class PermissionListView(generics.ListAPIView):
    serializer_class = PermissionSerializer
    permission_classes = [IsAdminOrSuperAdmin]
    pagination_class = None  # always return a plain list

    def get_queryset(self):
        _ensure_permissions_seeded()   # auto-create defaults if DB is empty
        return Permission.objects.all().order_by('codename')


class RoleListCreateView(generics.ListCreateAPIView):
    serializer_class = RoleSerializer
    permission_classes = [IsAdminOrSuperAdmin]
    pagination_class = None

    def get_queryset(self):
        return Role.objects.prefetch_related('permissions').all()


class RoleDetailView(generics.RetrieveUpdateDestroyAPIView):
    queryset = Role.objects.prefetch_related('permissions').all()
    serializer_class = RoleSerializer
    permission_classes = [IsAdminOrSuperAdmin]


# ─────────────── STAFF MANAGEMENT (Admin) ───────────────

class StaffListView(generics.ListAPIView):
    serializer_class = UserSerializer
    permission_classes = [IsAdminOrSuperAdmin]

    def get_queryset(self):
        qs = CustomUser.objects.filter(role__in=[CustomUser.ROLE_STAFF, CustomUser.ROLE_ADMIN])
        department_id = self.request.query_params.get('department')
        if department_id:
            qs = qs.filter(staff_profile__department_id=department_id)
        return qs


class CreateStaffView(APIView):
    permission_classes = [IsAdminOrSuperAdmin]

    def post(self, request):
        serializer = CreateStaffSerializer(data=request.data)
        if serializer.is_valid():
            user = serializer.save()
            return Response({
                'message': 'Staff member created successfully.',
                'user': UserSerializer(user).data,
            }, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


class StaffDetailView(APIView):
    permission_classes = [IsAdminOrSuperAdmin]

    def get(self, request, pk):
        user = get_object_or_404(CustomUser, pk=pk)
        return Response(UserSerializer(user).data)

    def patch(self, request, pk):
        user = get_object_or_404(CustomUser, pk=pk)
        # Update user fields
        for field in ['full_name', 'phone', 'is_active']:
            if field in request.data:
                setattr(user, field, request.data[field])
        user.save()
        # Update staff profile
        if hasattr(user, 'staff_profile'):
            sp_data = {}
            if 'department_id' in request.data:
                sp_data['department_id'] = request.data['department_id']
            if 'role_id' in request.data:
                sp_data['role_id'] = request.data['role_id']
            if 'designation' in request.data:
                sp_data['designation'] = request.data['designation']
            if 'employee_id' in request.data:
                sp_data['employee_id'] = request.data['employee_id']
            StaffProfile.objects.filter(user=user).update(**sp_data)
        return Response(UserSerializer(user).data)

    def delete(self, request, pk):
        user = get_object_or_404(CustomUser, pk=pk)
        user.is_active = False
        user.save()
        return Response({'message': 'Staff deactivated.'}, status=status.HTTP_204_NO_CONTENT)


# ─────────────── USER MANAGEMENT (Admin) ───────────────

class UserListView(generics.ListAPIView):
    serializer_class = UserSerializer
    permission_classes = [IsAdminOrSuperAdmin]
    filterset_fields = ['role', 'is_active']
    search_fields = ['email', 'full_name', 'phone']

    def get_queryset(self):
        return CustomUser.objects.all().order_by('-created_at')


class UserDetailAdminView(APIView):
    permission_classes = [IsAdminOrSuperAdmin]

    def get(self, request, pk):
        user = get_object_or_404(CustomUser, pk=pk)
        return Response(UserSerializer(user).data)

    def patch(self, request, pk):
        user = get_object_or_404(CustomUser, pk=pk)
        for field in ['is_active', 'role', 'full_name', 'phone']:
            if field in request.data:
                setattr(user, field, request.data[field])
        user.save()
        return Response(UserSerializer(user).data)


class AdminStatsView(APIView):
    permission_classes = [IsAdminOrSuperAdmin]

    def get(self, request):
        return Response({
            'total_users': CustomUser.objects.filter(role=CustomUser.ROLE_CITIZEN).count(),
            'total_staff': CustomUser.objects.filter(role=CustomUser.ROLE_STAFF).count(),
            'total_admins': CustomUser.objects.filter(role=CustomUser.ROLE_ADMIN).count(),
            'active_users': CustomUser.objects.filter(is_active=True).count(),
        })
