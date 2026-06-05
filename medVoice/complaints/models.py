from django.db import models
from django.conf import settings



class Category(models.Model):
    name = models.CharField(max_length=100, unique=True)
    description = models.TextField(blank=True, null=True)
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return self.name

class Complaint(models.Model):

    # NOTE: These choices support both new format (full names from Category model) 
    # and legacy format (lowercase values from original CATEGORY_CHOICES)
    CATEGORY_CHOICES = [
        # Legacy values (for backward compatibility with existing data)
        ('service', 'Service Quality'),
        ('billing', 'Billing'),
        ('infrastructure', 'Infrastructure'),
        # New values (matching Category model names)
        ('Service Quality', 'Service Quality'),
        ('Clinical Quality', 'Clinical Quality'),
        ('Staff Conduct', 'Staff Conduct'),
        ('Access & Billing', 'Access & Billing'),
        ('Facility & Safety', 'Facility & Safety'),
        ('Patient Rights', 'Patient Rights'),
        ('General', 'General'),
    ]

    SEVERITY_CHOICES = [
        ('low', 'Low'),
        ('medium', 'Medium'),
        ('high', 'High'),
    ]

    STATUS_CHOICES = [
        ('new', 'New'),
        ('review', 'In Review'),
        ('responded', 'Responded'),
        ('resolved', 'Resolved'),
        ('escalated', 'Escalated'),
    ]

    # Patient who created the complaint
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='patient_complaints'
    )

    # ✅ LINK TO HOSPITAL USER (IMPORTANT)
    hospital = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='hospital_complaints'
    )

    # 🏥 For hospitals NOT in the system
    unregistered_hospital_name = models.CharField(max_length=255, blank=True, null=True)

    title = models.CharField(max_length=255)
    description = models.TextField()

    category = models.CharField(max_length=50, choices=CATEGORY_CHOICES)
    severity = models.CharField(max_length=20, choices=SEVERITY_CHOICES)

    evidence = models.FileField(upload_to='complaints/', null=True, blank=True)

    status = models.CharField(
        max_length=20,
        choices=STATUS_CHOICES,
        default='new'
    )
    hospital_responded_at = models.DateTimeField(blank=True, null=True)
    patient_resolution_status = models.CharField(
        max_length=20,
        choices=[('satisfied', 'Satisfied'), ('resolved', 'Resolved')],
        blank=True,
        null=True
    )
    patient_resolution_at = models.DateTimeField(blank=True, null=True)
    escalated_to_authority = models.BooleanField(default=False)
    escalated_at = models.DateTimeField(blank=True, null=True)

    viewed_by_hospital = models.BooleanField(default=False)
    viewed_by_authority = models.BooleanField(default=False)


    viewed_by_hospital = models.BooleanField(default=False)
    viewed_by_authority = models.BooleanField(default=False)

    likes = models.PositiveIntegerField(default=0)
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return self.title

    @property
    def hospital_name(self):
        if self.hospital:
            if hasattr(self.hospital, 'hospital_profile'):
                return self.hospital.hospital_profile.hospital_name
            return self.hospital.get_full_name() or self.hospital.username
        return self.unregistered_hospital_name or "Unknown Facility"


class HospitalResponse(models.Model):
    complaint = models.ForeignKey(
        Complaint,
        on_delete=models.CASCADE,
        related_name="hospital_responses"
    )
    hospital = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="public_responses"
    )
    message = models.TextField()
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"Response by {self.hospital.username} on complaint #{self.complaint_id}"


class Comment(models.Model):
    complaint = models.ForeignKey(
        Complaint,
        on_delete=models.CASCADE,
        related_name='comments'
    )
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='comments_made'
    )
    content = models.TextField()
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"Comment by {self.user.username} on {self.complaint.title[:50]}..."


class Like(models.Model):
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='likes_given'
    )
    complaint = models.ForeignKey(
        Complaint,
        on_delete=models.CASCADE,
        related_name='likes_received'
    )

    class Meta:
        unique_together = ('user', 'complaint')
    
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"{self.user.username} likes {self.complaint.title}"
