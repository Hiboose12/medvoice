from django.urls import path
from django.contrib.auth.views import LogoutView
from django.contrib.auth import views as auth_views
from . import views

urlpatterns = [
    path("", views.home, name="home"),
    path("profile/", views.profile_redirect, name="profile"),
    path("profile/patients", views.patient_profile, name="patient_profile"),
    path("login/", views.login_view, name="login"),
    path("account-disabled/", views.account_disabled, name="account_disabled"),
    path("account-frozen/", views.account_frozen, name="account_frozen"),
    path("register/", views.register_view, name="register"),
    path('activate/<uidb64>/<token>/', views.activate, name='activate'),
    
    # AJAX for Verification
    path('ajax/request-otp/', views.request_otp, name='request_otp'),
    path('ajax/verify-otp/', views.verify_otp, name='verify_otp'),
    path('ajax/validate-email/', views.validate_email, name='validate_email'),
    path("dashboard/approve-users/", views.approve_users, name="approve_users"),
    path("dashboard/approve-users/<int:user_id>/", views.admin_review_detail, name="admin_review_detail"),
    path("dashboard/approve-user/<int:user_id>/", views.approve_user, name="approve_user"),
    path("dashboard/reject-user/<int:user_id>/", views.reject_user, name="reject_user"),
    path("dashboard/documents/<int:user_id>/<str:doc_key>/", views.admin_document_view, name="admin_document_view"),
    path('dashboard/toggle_user_status/<int:user_id>/', views.toggle_user_status, name='toggle_user_status'),
    path('dashboard/admin_warn_user/<int:user_id>/', views.admin_warn_user, name='admin_warn_user'),
    path('dashboard/admin_freeze_user/<int:user_id>/', views.admin_freeze_user, name='admin_freeze_user'),
    path('dashboard/admin_block_user/<int:user_id>/', views.admin_block_user, name='admin_block_user'),
    path('dashboard/admin_reactivate_user/<int:user_id>/', views.admin_reactivate_user, name='admin_reactivate_user'),
    path("pending-approval/", views.pending_approval, name="pending_approval"),
    path("dashboard/", views.admin_dashboard, name="admin_dashboard"),
    path("dashboard/admin_users/", views.admin_users, name="admin_users"),
    path("dashboard/users/<int:user_id>/activity/", views.admin_user_activity, name="admin_user_activity"),
    
    # Hospital Freeze Appeal Management (for Admin)
    path("dashboard/hospital-freeze/<int:freeze_id>/approve/", views.admin_approve_hospital_appeal, name="admin_approve_hospital_appeal"),
    path("dashboard/hospital-freeze/<int:freeze_id>/reject/", views.admin_reject_hospital_appeal, name="admin_reject_hospital_appeal"),
    path("dashboard/hospital-freeze/<int:freeze_id>/", views.admin_hospital_freeze_detail, name="admin_hospital_freeze_detail"),
    path("dashboard/admin_categories/", views.admin_categories, name="admin_categories"),
    path("dashboard/admin_performance/", views.admin_performance, name="admin_performance"),
    path("superadmin/settings/", views.admin_settings, name="admin_settings"),
    path("superadmin/profile/", views.admin_profile, name="admin_profile"),
    path("dashboard/support/", views.admin_support, name="admin_support"),
    path("dashboard/support/<int:ticket_id>/", views.admin_support_detail, name="admin_support_detail"),
    path("dashboard/support/reply/<int:ticket_id>/", views.reply_support_ticket, name="reply_support_ticket"),
    path("dashboard/notifications/", views.admin_notifications, name="admin_notifications"),
    path("patient/dashboard/", views.patient_dashboard, name="patient_dashboard"),
    path("logout/", views.custom_logout, name="logout"),
    path("logout-all/", views.logout_all_devices, name="logout_all_devices"),
    path("settings/", views.patient_settings, name="settings"),
    path("notifications/", views.patient_notifications, name="patient_notifications"),
    path("notifications/reply/<int:notification_id>/", views.reply_to_notification, name="reply_to_notification"),

    # Password Reset
    path("password_reset/", auth_views.PasswordResetView.as_view(template_name="accounts/password_reset_form.html"), name="password_reset"),
    path("password_reset/done/", auth_views.PasswordResetDoneView.as_view(template_name="accounts/password_reset_done.html"), name="password_reset_done"),
    path("reset/<uidb64>/<token>/", auth_views.PasswordResetConfirmView.as_view(template_name="accounts/password_reset_confirm.html"), name="password_reset_confirm"),
    path("reset/done/", auth_views.PasswordResetCompleteView.as_view(template_name="accounts/password_reset_complete.html"), name="password_reset_complete"),
    
    # Notifications
    path("api/notifications/", views.get_notifications, name="get_notifications"),
    path("api/notifications/read/<int:notification_id>/", views.mark_notification_read, name="mark_notification_read"),
]
