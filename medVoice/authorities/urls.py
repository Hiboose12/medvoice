from django.urls import path
from .views import (
    authority_dashboard,
    authority_hospitals,
    authority_hospital_detail,
    authority_regulations,
    authority_settings,
    authority_profile,
    authority_edit_profile,
    authority_complaints,
    authority_escalations,
    authority_complaint_detail,
    authority_warnings,
    issue_warning,
    authority_freeze_hospital,
    authority_unfreeze_hospital,
    authority_review_explanation,
    authority_notifications,
    authority_chat,
    authority_chat_detail,
    mark_notification_read,
    authority_feed,
)


urlpatterns = [
    # Dashboard
    path("authority/dashboard/", authority_dashboard, name="authority_dashboard"),
    
    # Feed (Read-only view for authorities)
    path("authority/feed/", authority_feed, name="authority_feed"),
    
    # Complaints
    path("authority/complaints/", authority_complaints, name="authority_complaints"),
    path("authority/complaints/<int:complaint_id>/", authority_complaint_detail, name="authority_complaint_detail"),
    
    # Escalations
    path("authority/escalations/", authority_escalations, name="authority_escalations"),
    
    # Hospitals
    path("authority/hospitals/", authority_hospitals, name="authority_hospitals"),
    path("authority/hospitals/<int:hospital_id>/", authority_hospital_detail, name="authority_hospital_detail"),
    path("authority/hospitals/<int:hospital_id>/freeze/", authority_freeze_hospital, name="authority_freeze_hospital"),
    path("authority/hospitals/<int:hospital_id>/unfreeze/", authority_unfreeze_hospital, name="authority_unfreeze_hospital"),
    path("authority/hospitals/<int:hospital_id>/warning/", issue_warning, name="authority_issue_warning"),
    
    # Warnings
    path("authority/warnings/", authority_warnings, name="authority_warnings"),
    
    # Freeze Review
    path("authority/freeze/<int:freeze_id>/review/", authority_review_explanation, name="authority_review_explanation"),
    
    # Notifications
    path("authority/notifications/", authority_notifications, name="authority_notifications"),
    path("authority/notifications/<int:notification_id>/read/", mark_notification_read, name="authority_mark_notification_read"),
    
    # Chat
    path("authority/chat/", authority_chat, name="authority_chat"),
    path("authority/chat/<int:conversation_id>/", authority_chat_detail, name="authority_chat_detail"),
    
    # Profile
    path("authority/profile/", authority_profile, name="authority_profile"),
    path("authority/profile/edit/", authority_edit_profile, name="authority_edit_profile"),
    
    # Settings
    path("authority/settings/", authority_settings, name="authority_settings"),
    
    # Regulations (existing placeholder)
    path("authority/regulations/", authority_regulations, name="authority_regulations"),
]
