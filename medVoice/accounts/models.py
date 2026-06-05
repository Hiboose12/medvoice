from django.db import models
from django.contrib.auth.models import AbstractUser
from django.conf import settings

# Create your models here.

class User(AbstractUser):

    ROLE_CHOICES = (
        ("patient", "Patient"),
        ("hospital", "Hospital Admin"),
        ("authority", "Health Authority"),
        ("superadmin", "Super Admin"),
    )

    role = models.CharField(
        max_length=20,
        choices=ROLE_CHOICES,
        default="patient"
    )
    
    is_approved = models.BooleanField(default=False)
    
    # Track if a disabled user has requested to be enabled again
    reactivation_requested = models.BooleanField(default=False)
    reactivation_reason = models.TextField(blank=True, null=True)
    reactivation_evidence = models.FileField(upload_to='reactivation_appeals/', null=True, blank=True)

    STATUS_CHOICES = (
        ("active", "Active"),
        ("frozen", "Frozen"),
        ("blocked", "Blocked"),
    )
    account_status = models.CharField(
        max_length=20,
        choices=STATUS_CHOICES,
        default="active"
    )
    
    # Personal Info
    phone_number = models.CharField(max_length=15, blank=True, null=True)
    is_verified = models.BooleanField(default=False)

    # Address
    address_line_1 = models.CharField(max_length=255, blank=True, null=True)
    address_line_2 = models.CharField(max_length=255, blank=True, null=True)
    city = models.CharField(max_length=100, blank=True, null=True)
    district = models.CharField(max_length=100, blank=True, null=True)
    state = models.CharField(max_length=100, blank=True, null=True)
    pincode = models.CharField(max_length=10, blank=True, null=True)
    country = models.CharField(max_length=100, default="India")

    # Government ID (Encrypted/Protected logic to be handled in views/forms, stored here)
    GOVT_ID_CHOICES = (
        ('aadhaar', 'Aadhaar'),
        ('voter_id', 'Voter ID'),
        ('pan', 'PAN'),
    )
    govt_id_type = models.CharField(max_length=50, choices=GOVT_ID_CHOICES, blank=True, null=True)
    govt_id_number = models.CharField(max_length=100, blank=True, null=True)

    # Chat Status
    last_seen = models.DateTimeField(null=True, blank=True)

    def __str__(self):
        return f"{self.username} ({self.role})"

    @property
    def is_anonymous_public(self):
        """Check if user wants to be anonymous."""
        # Only patients can be anonymous
        if self.role != 'patient':
            return False
        
        if hasattr(self, 'settings'):
            return self.settings.anonymous_posting
            
        # Default to True (safe privacy) if settings missing
        return True

    @property
    def profile_picture_url(self):
        """Safely get profile picture URL."""
        if hasattr(self, 'profile') and self.profile.photo:
            return self.profile.photo.url
        return None

class UserActivity(models.Model):
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='activities')
    action_type = models.CharField(max_length=50)  # e.g., "Login", "Logout", "Update Profile"
    description = models.TextField()
    ip_address = models.GenericIPAddressField(null=True, blank=True)
    timestamp = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-timestamp']
        verbose_name_plural = "User Activities"

    def __str__(self):
        return f"{self.user.username} - {self.action_type} - {self.timestamp}"

        if hasattr(self, 'profile') and self.profile.photo:
            return self.profile.photo.url
        return None

class Hospital(models.Model):
    TYPE_CHOICES = (
        ('govt', 'Government'),
        ('private', 'Private'),
    )
    STATUS_CHOICES = (
        ('pending', 'Pending'),
        ('verified', 'Verified'),
        ('suspended', 'Suspended'),
    )

    user = models.OneToOneField(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="hospital_profile"
    )
    hospital_name = models.CharField(max_length=255)
    hospital_type = models.CharField(max_length=50, choices=TYPE_CHOICES)
    registration_number = models.CharField(max_length=100)
    license_number = models.CharField(max_length=100)
    license_document = models.FileField(upload_to="verification/hospital/")
    
    # Hospital Address (Can differ from Admin's generic user address)
    address = models.TextField()
    district = models.CharField(max_length=100)
    state = models.CharField(max_length=100)
    pincode = models.CharField(max_length=10)
    
    contact_number = models.CharField(max_length=15)
    email = models.EmailField()
    
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='pending')

    authority = models.ForeignKey(
        'Authority', 
        on_delete=models.SET_NULL, 
        null=True, 
        blank=True, 
        related_name='hospitals'
    )

    def __str__(self):
        return f"{self.hospital_name} ({self.status})"


class Authority(models.Model):
    TYPE_CHOICES = (
        ('district', 'District'),
        ('state', 'State'),
        ('central', 'Central'),
    )

    user = models.OneToOneField(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="authority_profile"
    )
    authority_name = models.CharField(max_length=255) # e.g. "District Health Officer, Pune"
    authority_type = models.CharField(max_length=50, choices=TYPE_CHOICES)
    department_name = models.CharField(max_length=255, blank=True)
    
    jurisdiction_level = models.CharField(max_length=50) # e.g. "Pune District"
    jurisdiction_state = models.CharField(max_length=100)
    jurisdiction_district = models.CharField(max_length=100, blank=True, null=True)
    
    office_address = models.TextField(blank=True)
    official_email = models.EmailField(blank=True)
    official_phone = models.CharField(max_length=15, blank=True)
    
    appointment_letter = models.FileField(upload_to="verification/authority/")
    authority_id_document = models.FileField(upload_to="verification/authority/")

    def __str__(self):
        return f"{self.authority_name} ({self.authority_type})"
    
class VerificationProfile(models.Model):

    user = models.OneToOneField(
        User,
        on_delete=models.CASCADE,
        related_name="verification"
    )

    # Common
    created_at = models.DateTimeField(auto_now_add=True)

    # Patient
    govt_id = models.FileField(
        upload_to="verification/patient/",
        blank=True,
        null=True
    )

    # Hospital Admin (Deprecated - use Hospital model)
    hospital_license = models.FileField(
        upload_to="verification/hospital/",
        blank=True,
        null=True
    )
    admin_id_proof = models.FileField(
        upload_to="verification/hospital/",
        blank=True,
        null=True
    )

    # Health Authority (Deprecated - use Authority model)
    appointment_letter = models.FileField(
        upload_to="verification/authority/",
        blank=True,
        null=True
    )
    authority_id = models.FileField(
        upload_to="verification/authority/",
        blank=True,
        null=True
    )

    def __str__(self):
        return f"Verification for {self.user.username}"


class PatientSettings(models.Model):
    user = models.OneToOneField(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="settings"
    )

    # Notifications
    email_notifications = models.BooleanField(default=True)
    complaint_status_updates = models.BooleanField(default=True)
    new_messages = models.BooleanField(default=True)
    authority_responses = models.BooleanField(default=False)

    # Feed
    show_in_feed = models.BooleanField(default=True)
    anonymous_posting = models.BooleanField(default=True)
    show_resolved_publicly = models.BooleanField(default=False)

    # Privacy
    hide_profile = models.BooleanField(default=False)
    allow_hospital_contact = models.BooleanField(default=True)
    allow_escalation = models.BooleanField(default=True)

    # Appearance
    theme = models.CharField(
        max_length=10,
        choices=[("light", "Light"), ("dark", "Dark"), ("system", "System")],
        default="light"
    )

    def __str__(self):
        return f"Settings for {self.user.username}"


class Profile(models.Model):
    user = models.OneToOneField(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="profile"
    )
    photo = models.ImageField(
        upload_to="profile/",
        blank=True,
        null=True
    )
    phone_number = models.CharField(max_length=15, blank=True, null=True)

    def __str__(self):
        return f"Profile of {self.user.username}"


class Notification(models.Model):
    recipient = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='notifications'
    )
    support_ticket = models.ForeignKey(
        "social.SupportTicket",
        on_delete=models.SET_NULL,
        related_name="notifications",
        blank=True,
        null=True
    )
    title = models.CharField(max_length=255)
    message = models.TextField()
    link = models.CharField(max_length=255, blank=True, null=True)
    is_read = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"Notification for {self.recipient.username}: {self.title}"


class PatientNotificationReply(models.Model):
    notification = models.ForeignKey(
        Notification,
        on_delete=models.CASCADE,
        related_name="patient_replies"
    )
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="notification_replies"
    )
    support_ticket = models.ForeignKey(
        "social.SupportTicket",
        on_delete=models.SET_NULL,
        related_name="patient_replies",
        blank=True,
        null=True
    )
    message = models.TextField()
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"Reply by {self.user.username} on notification {self.notification_id}"

class PhoneVerification(models.Model):
    phone_number = models.CharField(max_length=15)
    otp = models.CharField(max_length=6)
    is_verified = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        return f"{self.phone_number} - {self.otp}"

# Verified correct

