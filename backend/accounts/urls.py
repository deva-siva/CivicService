from django.urls import path
from . import views

urlpatterns = [
    # Auth
    path('register/', views.RegisterView.as_view(), name='register'),
    path('login/', views.LoginView.as_view(), name='login'),
    path('google-login/', views.GoogleLoginView.as_view(), name='google_login'),
    path('logout/', views.LogoutView.as_view(), name='logout'),
    # Profile
    path('profile/', views.ProfileView.as_view(), name='profile'),
    path('change-password/', views.ChangePasswordView.as_view(), name='change_password'),
    path('update-firebase-token/', views.UpdateFirebaseTokenView.as_view(), name='update_firebase_token'),
    path('password-reset/', views.PasswordResetRequestView.as_view(), name='password_reset'),
    # Roles (Admin)
    path('permissions/', views.PermissionListView.as_view(), name='permissions'),
    path('roles/', views.RoleListCreateView.as_view(), name='roles'),
    path('roles/<int:pk>/', views.RoleDetailView.as_view(), name='role_detail'),
    # Staff Management (Admin)
    path('staff/', views.StaffListView.as_view(), name='staff_list'),
    path('staff/create/', views.CreateStaffView.as_view(), name='create_staff'),
    path('staff/<int:pk>/', views.StaffDetailView.as_view(), name='staff_detail'),
    # User Management (Admin)
    path('users/', views.UserListView.as_view(), name='user_list'),
    path('users/<int:pk>/', views.UserDetailAdminView.as_view(), name='user_detail_admin'),
    path('admin-stats/', views.AdminStatsView.as_view(), name='admin_stats'),
]
