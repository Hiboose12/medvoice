from django.urls import path
from django.contrib.auth import views as auth_views
from accounts import views as accounts_views
from .views import hospital_profile
from .views import hospital_dashboard
from .views import hospital_complaints
from .views import hospital_reports, hospital_reports_export, hospital_feed
from .views import hospital_settings, hospital_notifications, submit_appeal

urlpatterns = [
    path("hospital/profile/", hospital_profile, name="hospital_profile"),
    path("hospital/dashboard/", hospital_dashboard, name="hospital_dashboard"),
    path("hospital/complaints/", hospital_complaints, name="hospital_complaints"),
    path("hospital/feed/", hospital_feed, name="hospital_feed"),
    path("hospital/reports/", hospital_reports, name="hospital_reports"),
    path("hospital/reports/export/", hospital_reports_export, name="hospital_reports_export"),
    path("hospital/settings/", hospital_settings, name="hospital_settings"),
    path("hospital/notifications/", hospital_notifications, name="hospital_notifications"),
    path("hospital/appeal/", submit_appeal, name="submit_appeal"),
    # Legacy path mapping to accounts view (to fix stale links)
    path("hospital/notification/read/<int:notification_id>/", accounts_views.mark_notification_read, name="mark_notification_read_legacy"),
    path("hospital/logout/", accounts_views.custom_logout, name="hospital_logout"),
]
