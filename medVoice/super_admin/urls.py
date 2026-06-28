from django.urls import path
from . import views

urlpatterns = [
    path('superadmin/users/', views.sa_user_management, name='sa_user_management'),
    path('superadmin/users/<int:user_id>/', views.sa_user_detail, name='sa_user_detail'),
    path('superadmin/users/<int:user_id>/modify/', views.sa_modify_user_status, name='sa_modify_user_status'),

    path('superadmin/verification/', views.sa_entity_verification, name='sa_entity_verification'),
    path('superadmin/verification/<str:entity_type>/<int:entity_id>/', views.sa_verify_entity, name='sa_verify_entity'),

    path('superadmin/audit-logs/', views.sa_audit_logs, name='sa_audit_logs'),
    path('superadmin/audit-logs/export/', views.sa_export_audit_logs, name='sa_export_audit_logs'),

    path('superadmin/security/', views.sa_security_monitoring, name='sa_security_monitoring'),
    path('superadmin/security/alerts/<int:alert_id>/resolve/', views.sa_resolve_security_alert, name='sa_resolve_security_alert'),
    path('superadmin/security/scan/', views.sa_trigger_security_scan, name='sa_trigger_security_scan'),
    path('superadmin/security/settings/', views.sa_security_settings, name='sa_security_settings'),
]
