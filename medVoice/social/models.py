from django.db import models
from django.conf import settings
from complaints.models import Complaint
from accounts.models import User


class Conversation(models.Model):
    complaint = models.ForeignKey(
        Complaint,
        on_delete=models.CASCADE,
        related_name="conversations",
        null=True,
        blank=True
    )
    participants = models.ManyToManyField(
        settings.AUTH_USER_MODEL,
        related_name="conversations"
    )
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        title = self.complaint.title if self.complaint else "General Chat"
        return f"Conversation: {title}"


class Message(models.Model):
    conversation = models.ForeignKey(
        Conversation,
        on_delete=models.CASCADE,
        related_name="messages"
    )
    sender = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE)
    content = models.TextField(blank=True, null=True)
    attachment = models.FileField(upload_to='chat_attachments/', blank=True, null=True)
    is_read = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)

    # Role-based messaging fields
    sender_role = models.CharField(max_length=20, choices=User.ROLE_CHOICES, blank=True, null=True)
    receiver = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="received_messages", blank=True, null=True)
    related_complaint = models.ForeignKey(Complaint, on_delete=models.SET_NULL, related_name="chat_messages", blank=True, null=True)

    def __str__(self):
        if self.content:
            return f"{self.sender}: {self.content[:30]}"
        return f"Message from {self.sender.username} (Attachment)"


class SupportTicket(models.Model):
    STATUS_CHOICES = (
        ('open', 'Open'),
        ('resolved', 'Resolved'),
        ('closed', 'Closed'),
    )

    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="support_tickets")
    subject = models.CharField(max_length=255)
    message = models.TextField()
    admin_reply = models.TextField(blank=True, null=True)
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='open')
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        return f"Ticket #{self.id}: {self.subject} ({self.user.username})"
