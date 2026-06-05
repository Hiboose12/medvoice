from django.contrib import admin
from .models import (
    AuthoritySettings, HospitalWarning, HospitalFreeze,
    ComplaintActivityLog, AuthorityNotification,
    AuthorityConversation, AuthorityMessage
)

# Register your models here.
@admin.register(AuthoritySettings)
class AuthoritySettingsAdmin(admin.ModelAdmin):
    list_display = ('authority', 'response_time_threshold', 'view_time_threshold', 'warning_threshold', 'email_notifications', 'created_at')
    list_filter = ('email_notifications', 'escalation_alerts', 'warning_alerts', 'freeze_alerts')
    search_fields = ('authority__username', 'authority__email')

@admin.register(HospitalWarning)
class HospitalWarningAdmin(admin.ModelAdmin):
    list_display = ('issued_by', 'hospital', 'warning_type', 'is_active', 'created_at')
    list_filter = ('warning_type', 'is_active')
    search_fields = ('hospital__username', 'issued_by__username', 'reason')

@admin.register(HospitalFreeze)
class HospitalFreezeAdmin(admin.ModelAdmin):
    list_display = ('hospital', 'frozen_by', 'reason', 'status', 'frozen_at', 'reactivated_at')
    list_filter = ('reason', 'status')
    search_fields = ('hospital__username', 'description')

@admin.register(ComplaintActivityLog)
class ComplaintActivityLogAdmin(admin.ModelAdmin):
    list_display = ('complaint', 'activity_type', 'performed_by', 'created_at')
    list_filter = ('activity_type',)
    search_fields = ('complaint__title', 'description')

@admin.register(AuthorityNotification)
class AuthorityNotificationAdmin(admin.ModelAdmin):
    list_display = ('recipient', 'notification_type', 'title', 'is_read', 'created_at')
    list_filter = ('notification_type', 'is_read')
    search_fields = ('title', 'message')

@admin.register(AuthorityConversation)
class AuthorityConversationAdmin(admin.ModelAdmin):
    list_display = ('authority', 'participant', 'participant_type', 'subject', 'is_active', 'created_at')
    list_filter = ('participant_type', 'is_active')
    search_fields = ('subject',)

@admin.register(AuthorityMessage)
class AuthorityMessageAdmin(admin.ModelAdmin):
    list_display = ('conversation', 'sender', 'message', 'is_read', 'created_at')
    list_filter = ('is_read',)
