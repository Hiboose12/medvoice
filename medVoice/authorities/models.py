from django.db import models
from django.conf import settings
from django.utils import timezone


class AuthoritySettings(models.Model):
    """Settings specific to each authority for escalation thresholds and notifications."""
    authority = models.OneToOneField(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='authority_settings'
    )
    
    # Escalation thresholds (in hours)
    response_time_threshold = models.PositiveIntegerField(
        default=48,
        help_text="Hours before a complaint is escalated if hospital hasn't responded"
    )
    view_time_threshold = models.PositiveIntegerField(
        default=24,
        help_text="Hours before a complaint is escalated if hospital hasn't viewed it"
    )
    
    # Warning system
    warning_threshold = models.PositiveIntegerField(
        default=3,
        help_text="Number of warnings before automatic freeze"
    )
    
    # Notification preferences
    email_notifications = models.BooleanField(default=True)
    escalation_alerts = models.BooleanField(default=True)
    warning_alerts = models.BooleanField(default=True)
    freeze_alerts = models.BooleanField(default=True)
    
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    def __str__(self):
        return f"Settings for {self.authority.username}"


class HospitalWarning(models.Model):
    """Warnings issued by authorities to hospitals."""
    WARNING_TYPES = (
        ('critical', 'Critical'),
        ('serious', 'Serious'),
        ('minor', 'Minor'),
    )
    
    issued_by = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='issued_warnings'
    )
    hospital = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='received_warnings'
    )
    
    warning_type = models.CharField(
        max_length=20,
        choices=WARNING_TYPES,
        default='serious'
    )
    reason = models.TextField()
    complaint = models.ForeignKey(
        'complaints.Complaint',
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='related_warnings'
    )
    
    is_active = models.BooleanField(default=True)
    expires_at = models.DateTimeField(null=True, blank=True)
    
    created_at = models.DateTimeField(auto_now_add=True)
    
    def __str__(self):
        return f"Warning for {self.hospital.username} - {self.warning_type}"


class HospitalFreeze(models.Model):
    """Freeze/Block records for hospitals."""
    REASON_CHOICES = (
        ('warning_limit', 'Exceeded warning limit'),
        ('critical_complaint', 'Critical complaint'),
        ('non_compliance', 'Non-compliance'),
        ('investigation', 'Under investigation'),
        ('other', 'Other'),
    )
    
    STATUS_CHOICES = (
        ('frozen', 'Frozen'),
        ('pending_review', 'Pending Review'),
        ('reactivated', 'Reactivated'),
        ('permanently_blocked', 'Permanently Blocked'),
    )
    
    hospital = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='freeze_records'
    )
    frozen_by = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        related_name='freeze_actions'
    )
    
    reason = models.CharField(max_length=50, choices=REASON_CHOICES)
    description = models.TextField()
    
    status = models.CharField(
        max_length=20,
        choices=STATUS_CHOICES,
        default='frozen'
    )
    
    # For reactivation flow
    explanation_requested = models.BooleanField(default=False)
    explanation_received = models.BooleanField(default=False)
    explanation_text = models.TextField(blank=True, null=True)
    explanation_evidence = models.FileField(upload_to='freeze_appeals/', null=True, blank=True)
    explanation_submitted_at = models.DateTimeField(blank=True, null=True)
    
    # Timestamps
    frozen_at = models.DateTimeField(auto_now_add=True)
    reactivated_at = models.DateTimeField(blank=True, null=True)
    permanently_blocked_at = models.DateTimeField(blank=True, null=True)
    
    def __str__(self):
        return f"Freeze record for {self.hospital.username} - {self.status}"
    
    @property
    def is_frozen(self):
        return self.status == 'frozen'
    
    @property
    def can_be_reactivated(self):
        return self.status in ['frozen', 'pending_review']


class ComplaintActivityLog(models.Model):
    """Tracks all activities related to a complaint for authority monitoring."""
    ACTIVITY_TYPES = (
        ('viewed', 'Viewed by Hospital'),
        ('responded', 'Responded'),
        ('resolved', 'Marked Resolved'),
        ('escalated', 'Escalated to Authority'),
        ('authority_viewed', 'Viewed by Authority'),
        ('warning_issued', 'Warning Issued'),
        ('frozen', 'Hospital Frozen'),
        ('unfrozen', 'Hospital Reactivated'),
    )
    
    complaint = models.ForeignKey(
        'complaints.Complaint',
        on_delete=models.CASCADE,
        related_name='activity_logs'
    )
    activity_type = models.CharField(max_length=30, choices=ACTIVITY_TYPES)
    performed_by = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        related_name='performed_activities'
    )
    description = models.TextField()
    
    created_at = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        ordering = ['-created_at']
    
    def __str__(self):
        return f"{self.activity_type} on complaint #{self.complaint_id}"


class AuthorityNotification(models.Model):
    """Notifications specific to authorities."""
    NOTIFICATION_TYPES = (
        ('escalation', 'Complaint Escalated'),
        ('new_complaint', 'New Complaint Filed'),
        ('warning', 'Warning Issued'),
        ('freeze', 'Hospital Frozen'),
        ('unfreeze', 'Hospital Reactivated'),
        ('explanation', 'Explanation Received'),
        ('system', 'System Alert'),
    )
    
    recipient = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='authority_notifications'
    )
    
    notification_type = models.CharField(
        max_length=30,
        choices=NOTIFICATION_TYPES
    )
    title = models.CharField(max_length=255)
    message = models.TextField()
    
    # Related objects
    complaint = models.ForeignKey(
        'complaints.Complaint',
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='authority_notifications'
    )
    hospital = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='authority_notifications_received'
    )
    warning = models.ForeignKey(
        HospitalWarning,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='authority_notifications'
    )
    freeze = models.ForeignKey(
        HospitalFreeze,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='authority_notifications'
    )
    
    link = models.CharField(max_length=255, blank=True, null=True)
    is_read = models.BooleanField(default=False)
    read_at = models.DateTimeField(blank=True, null=True)
    
    created_at = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        ordering = ['-created_at']
    
    def __str__(self):
        return f"Notification for {self.recipient.username}: {self.title}"


class AuthorityConversation(models.Model):
    """Conversations between authority and patients/hospitals."""
    PARTICIPANT_TYPES = (
        ('patient', 'Patient'),
        ('hospital', 'Hospital'),
    )
    
    authority = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='authority_conversations_as_authority'
    )
    participant = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='authority_conversations_as_participant'
    )
    participant_type = models.CharField(
        max_length=20,
        choices=PARTICIPANT_TYPES
    )
    
    complaint = models.ForeignKey(
        'complaints.Complaint',
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='authority_conversations'
    )
    
    subject = models.CharField(max_length=255)
    is_active = models.BooleanField(default=True)
    
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        ordering = ['-updated_at']
    
    def __str__(self):
        return f"Conversation: {self.authority.username} - {self.participant.username}"


class AuthorityMessage(models.Model):
    """Messages within authority conversations."""
    conversation = models.ForeignKey(
        AuthorityConversation,
        on_delete=models.CASCADE,
        related_name='messages'
    )
    sender = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='authority_messages_sent'
    )
    message = models.TextField()
    is_read = models.BooleanField(default=False)
    read_at = models.DateTimeField(blank=True, null=True)
    
    created_at = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        ordering = ['created_at']
    
    def __str__(self):
        return f"Message from {self.sender.username}"
