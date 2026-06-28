from django.urls import path
from . import api_views
from . import auth_views
from . import authority_api_views
from . import admin_api_views
from . import chat_api_views

urlpatterns = [
    # Auth
    path('v1/auth/patient/register/', auth_views.register_patient, name='api-register-patient'),
    path('v1/auth/hospital/register/', auth_views.register_hospital, name='api-register-hospital'),
    path('v1/auth/authority/register/', auth_views.register_authority, name='api-register-authority'),
    path('v1/categories/', api_views.public_categories_api, name='api-public-categories'),
    path('v1/auth/login/', auth_views.login_view, name='api-login'),
    path('v1/auth/appeal/', auth_views.submit_appeal, name='api-submit-appeal'),
    path('v1/auth/me/', auth_views.current_user, name='api-current-user'),

    # Patient Dashboard
    path('v1/patient/dashboard/', api_views.patient_dashboard, name='api-patient-dashboard'),
    path('v1/patient/settings/', api_views.api_patient_settings, name='api-patient-settings'),
    
    # Profile
    path('v1/users/me/', api_views.user_profile, name='api-user-profile'),
    
    # Complaints
    path('v1/complaints/options/', api_views.complaint_options_api, name='api-complaint-options'),
    path('v1/complaints/', api_views.complaint_list, name='api-complaint-list'),
    path('v1/complaints/<int:pk>/', api_views.complaint_detail, name='api-complaint-detail'),
    path('v1/complaints/<int:pk>/resolve/', api_views.patient_complaint_resolve_api, name='api-patient-complaint-resolve'),
    path('v1/complaints/<int:pk>/comments/', api_views.complaint_comments, name='api-complaint-comments'),
    path('v1/complaints/<int:pk>/like/', api_views.toggle_complaint_like, name='api-complaint-like'),

    
    # Community Feed
    path('v1/feed/', api_views.community_feed, name='api-community-feed'),

    # Hospital APIs
    path('v1/hospital/dashboard/', api_views.hospital_dashboard, name='api-hospital-dashboard'),
    path('v1/hospital/complaints/', api_views.hospital_complaint_list, name='api-hospital-complaint-list'),
    path('v1/hospital/complaints/<int:pk>/', api_views.hospital_complaint_detail, name='api-hospital-complaint-detail'),
    path('v1/hospital/complaints/<int:pk>/respond/', api_views.hospital_complaint_respond, name='api-hospital-complaint-respond'),
    path('v1/hospital/complaints/<int:pk>/resolve/', api_views.hospital_complaint_resolve, name='api-hospital-complaint-resolve'),
    path('v1/hospital/profile/', api_views.hospital_profile, name='api-hospital-profile'),

    # Support APIs
    path('v1/support/tickets/', api_views.api_support_tickets, name='api-support-tickets'),
    path('v1/support/tickets/<int:pk>/', api_views.api_support_ticket_detail, name='api-support-ticket-detail'),

    # Notifications (for all roles: hospital, patient, authority)
    path('v1/notifications/', api_views.api_notifications_list, name='api-notifications-list'),
    path('v1/notifications/<int:pk>/read/', api_views.api_notification_mark_read, name='api-notification-mark-read'),
    path('v1/notifications/<int:pk>/reply/', api_views.api_notification_reply, name='api-notification-reply'),

    # Conversations (chat list for all roles)
    path('v1/conversations/', api_views.api_conversations_list, name='api-conversations-list'),
    path('v1/chat/messages/<int:conversation_id>/', chat_api_views.api_get_messages, name='api-chat-messages'),
    path('v1/chat/send/<int:conversation_id>/', chat_api_views.api_send_message, name='api-chat-send'),
    path('v1/chat/start/<int:user_id>/', chat_api_views.api_start_chat, name='api-chat-start'),
    path('v1/chat/start-complaint/<int:complaint_id>/', chat_api_views.api_start_complaint_chat, name='api-chat-start-complaint'),

    # Authority APIs
    path('v1/authority/dashboard/', api_views.authority_dashboard_api, name='api-authority-dashboard'),
    path('v1/authority/escalations/', api_views.authority_escalations_api, name='api-authority-escalations'),
    path('v1/authority/escalations/<int:pk>/', api_views.authority_escalation_detail_api, name='api-authority-escalation-detail'),
    path('v1/authority/hospitals/<int:pk>/freeze/', api_views.authority_freeze_hospital_api, name='api-authority-freeze'),
    path('v1/authority/hospitals/<int:pk>/unfreeze/', api_views.authority_unfreeze_hospital_api, name='api-authority-unfreeze'),
    path('v1/authority/hospitals/<int:pk>/warning/', api_views.authority_issue_warning_api, name='api-authority-warning'),
    path('v1/authority/complaints/', authority_api_views.authority_complaints_api, name='api-authority-complaints'),
    path('v1/authority/complaints/<int:pk>/', authority_api_views.authority_complaint_detail_api, name='api-authority-complaint-detail'),
    path('v1/authority/hospitals/', authority_api_views.authority_hospitals_api, name='api-authority-hospitals'),
    path('v1/authority/hospitals/<int:pk>/', authority_api_views.authority_hospital_detail_api, name='api-authority-hospital-detail'),
    path('v1/authority/warnings/', authority_api_views.authority_warnings_api, name='api-authority-warnings'),
    path('v1/authority/profile/', authority_api_views.authority_profile_api, name='api-authority-profile'),
    path('v1/authority/settings/', authority_api_views.authority_settings_api, name='api-authority-settings'),
    path('v1/authority/feed/', api_views.community_feed, name='api-authority-feed'),
    
    # Admin APIs
    path('v1/admin/dashboard/', admin_api_views.admin_dashboard_api, name='api-admin-dashboard'),
    path('v1/admin/users/', admin_api_views.admin_users_api, name='api-admin-users'),
    path('v1/admin/user/<int:pk>/', admin_api_views.admin_user_detail_api, name='api-admin-user-detail'),
    path('v1/admin/user/<int:pk>/status/', admin_api_views.admin_modify_user_status_api, name='api-admin-modify-user-status'),
    path('v1/superadmin/verification/', admin_api_views.superadmin_verification_list_api, name='api-superadmin-verification-list'),
    path('v1/superadmin/verification/<str:entity_type>/<int:entity_id>/', admin_api_views.superadmin_verification_detail_api, name='api-superadmin-verification-detail'),
    path('v1/superadmin/verification/<str:entity_type>/<int:entity_id>/approve/', admin_api_views.superadmin_verification_approve_api, name='api-superadmin-verification-approve'),
    path('v1/superadmin/verification/<str:entity_type>/<int:entity_id>/reject/', admin_api_views.superadmin_verification_reject_api, name='api-superadmin-verification-reject'),
    path('v1/superadmin/audit-logs/', admin_api_views.superadmin_audit_logs_api, name='api-superadmin-audit-logs'),
    path('v1/superadmin/users/<int:user_id>/activity/', admin_api_views.superadmin_user_activity_api, name='api-superadmin-user-activity'),
    path('v1/superadmin/users/<int:user_id>/freeze/', admin_api_views.superadmin_user_freeze_api, name='api-superadmin-user-freeze'),
    path('v1/superadmin/users/<int:user_id>/unfreeze/', admin_api_views.superadmin_user_unfreeze_api, name='api-superadmin-user-unfreeze'),
    path('v1/superadmin/users/<int:user_id>/block/', admin_api_views.superadmin_user_block_api, name='api-superadmin-user-block'),
    path('v1/superadmin/users/<int:user_id>/unblock/', admin_api_views.superadmin_user_unblock_api, name='api-superadmin-user-unblock'),
    path('v1/superadmin/users/<int:user_id>/warn/', admin_api_views.superadmin_user_warn_api, name='api-superadmin-user-warn'),
    path('v1/superadmin/users/<int:user_id>/reactivate/', admin_api_views.superadmin_user_reactivate_api, name='api-superadmin-user-reactivate'),
    path('v1/superadmin/hospital-freeze/<int:freeze_id>/approve/', admin_api_views.superadmin_approve_hospital_appeal_api, name='api-superadmin-approve-hospital-appeal'),
    path('v1/superadmin/hospital-freeze/<int:freeze_id>/reject/', admin_api_views.superadmin_reject_hospital_appeal_api, name='api-superadmin-reject-hospital-appeal'),
    path('v1/admin/security/monitoring/', admin_api_views.admin_security_monitoring_api, name='api-admin-security-monitoring'),
    path('v1/admin/security/alert/<int:pk>/resolve/', admin_api_views.admin_resolve_security_alert_api, name='api-admin-resolve-alert'),
    path('v1/admin/security/scan/trigger/', admin_api_views.admin_trigger_security_scan_api, name='api-admin-trigger-scan'),
    path('v1/admin/security/settings/', admin_api_views.admin_security_settings_api, name='api-admin-security-settings'),
    
    # Super Admin Category Management APIs
    path('v1/admin/categories/', admin_api_views.admin_categories_api, name='api-admin-categories'),
    path('v1/admin/categories/<int:pk>/', admin_api_views.admin_category_detail_api, name='api-admin-category-detail'),
    
    # Super Admin Support Tickets APIs
    path('v1/admin/support/tickets/', admin_api_views.admin_support_tickets_api, name='api-admin-support-tickets'),
    path('v1/admin/support/tickets/<int:pk>/reply/', admin_api_views.admin_support_ticket_reply_api, name='api-admin-support-ticket-reply'),
    
    # Super Admin Profile API
    path('v1/admin/profile/', admin_api_views.admin_profile_api, name='api-admin-profile'),
]
