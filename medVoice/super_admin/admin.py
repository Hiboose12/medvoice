from django.contrib import admin
from django.utils import timezone
from .models import AuditLogEntry, SecurityAlert


@admin.register(AuditLogEntry)
class AuditLogEntryAdmin(admin.ModelAdmin):
    list_display = ['timestamp', 'admin', 'action_type', 'target_user', 'ip_address']
    list_filter = ['action_type', 'timestamp']
    search_fields = ['admin__username', 'target_user__username', 'description']
    date_hierarchy = 'timestamp'
    readonly_fields = ['timestamp']
    raw_id_fields = ['admin', 'target_user']


@admin.register(SecurityAlert)
class SecurityAlertAdmin(admin.ModelAdmin):
    list_display = ['timestamp', 'alert_type', 'severity', 'user', 'is_resolved', 'resolved_at']
    list_filter = ['alert_type', 'severity', 'is_resolved', 'timestamp']
    search_fields = ['user__username', 'title', 'description', 'ip_address']
    date_hierarchy = 'timestamp'
    readonly_fields = ['timestamp', 'resolved_at']
    raw_id_fields = ['user', 'resolved_by']
    actions = ['mark_resolved']

    def mark_resolved(self, request, queryset):
        queryset.update(is_resolved=True, resolved_at=timezone.now(), resolved_by=request.user)
    mark_resolved.short_description = "Mark selected alerts as resolved"
