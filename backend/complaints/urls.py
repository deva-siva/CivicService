from django.urls import path
from . import views

urlpatterns = [
    # Departments
    path('departments/', views.DepartmentListCreateView.as_view(), name='departments'),
    path('departments/<int:pk>/', views.DepartmentDetailView.as_view(), name='department_detail'),
    # Citizen complaints
    path('', views.ComplaintListCreateView.as_view(), name='complaint_list_create'),
    path('<int:pk>/', views.ComplaintDetailView.as_view(), name='complaint_detail'),
    # Admin complaints
    path('admin/all/', views.AdminComplaintListView.as_view(), name='admin_complaint_list'),
    path('admin/<int:pk>/', views.AdminComplaintDetailView.as_view(), name='admin_complaint_detail'),
    path('admin/<int:pk>/escalate/', views.EscalateComplaintView.as_view(), name='escalate_complaint'),
    path('admin/auto-escalate/', views.AutoEscalateView.as_view(), name='auto_escalate'),
    # Analytics
    path('analytics/', views.AnalyticsView.as_view(), name='analytics'),
    path('dashboard/', views.UserDashboardView.as_view(), name='user_dashboard'),
]
