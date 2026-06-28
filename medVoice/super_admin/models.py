from django.db import models
from django.conf import settings
from django.contrib.auth import get_user_model

User = get_user_model()

class AuditLogEntry(models.Model):
    ACTION_CHOICES = (
        ('user_approved', 'User Approved'),
        ('user_rejected', 'User Rejected'),
        ('user_disabled', 'User Disabled'),
        ('user_enabled', 'User Enabled'),
        ('user_frozen', 'User Frozen'),
        ('user_unfrozen', 'User Unfrozen'),
        ('user_blocked', 'User Blocked'),
        ('user_unblocked', 'User Unblocked'),
        ('user_reactivated', 'User Reactivated'),
        ('user_warned', 'User Warned'),
        ('freeze_appeal_approved', 'Freeze Appeal Approved'),
        ('freeze_appeal_rejected', 'Freeze Appeal Rejected'),
        ('category_added', 'Category Added'),
        ('category_deleted', 'Category Deleted'),
        ('support_ticket_replied', 'Support Ticket Replied'),
        ('settings_changed', 'Settings Changed'),
        ('password_changed', 'Password Changed'),
        ('account_deactivated', 'Account Deactivated'),
    )

    admin = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='audit_logs'
    )
    target_user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='audit_logs_received'
    )
    action_type = models.CharField(max_length=50, choices=ACTION_CHOICES)
    description = models.TextField(blank=True, help_text="Detailed description of the action taken")
    metadata = models.JSONField(null=True, blank=True, help_text="Additional context data (IP, user agent, etc.)")
    ip_address = models.GenericIPAddressField(null=True, blank=True)
    timestamp = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-timestamp']
        verbose_name_plural = "Audit Log Entries"

    def __str__(self):
        target = getattr(self.target_user, 'username', 'Unknown')
        admin = getattr(self.admin, 'username', 'System')
        return f"{admin} -> {self.action_type} on {target} @ {self.timestamp.strftime('%Y-%m-%d %H:%M')}"


class SecurityAlert(models.Model):
    SEVERITY_CHOICES = (
        ('low', 'Low'),
        ('medium', 'Medium'),
        ('high', 'High'),
        ('critical', 'Critical'),
    )

    ALERT_TYPE_CHOICES = (
        ('failed_login', 'Failed Login Attempt'),
        ('suspicious_ip', 'Suspicious IP Location'),
        ('multiple_sessions', 'Multiple Active Sessions'),
        ('privilege_escalation', 'Privilege Escalation Attempt'),
        ('bulk_data_export', 'Bulk Data Export'),
        ('data_tampering', 'Data Tampering Detected'),
        ('unauthorized_access', 'Unauthorized Access Attempt'),
        ('anomalous_activity', 'Anomalous Activity'),
    )

    alert_type = models.CharField(max_length=50, choices=ALERT_TYPE_CHOICES)
    severity = models.CharField(max_length=20, choices=SEVERITY_CHOICES, default='medium')
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='security_alerts'
    )
    title = models.CharField(max_length=255, blank=True)
    description = models.TextField(blank=True)
    ip_address = models.GenericIPAddressField(null=True, blank=True)
    user_agent = models.TextField(blank=True, help_text="Browser/device info from request")
    metadata = models.JSONField(null=True, blank=True)
    is_resolved = models.BooleanField(default=False)
    resolved_at = models.DateTimeField(null=True, blank=True)
    resolved_by = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='resolved_security_alerts'
    )
    timestamp = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-timestamp']

    def __str__(self):
        user = getattr(self.user, 'username', 'Unknown')
        return f"[{self.severity.upper()}] {self.alert_type} - {user}"
