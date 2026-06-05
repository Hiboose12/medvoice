from django.db import models

# Create your models here.
class Complaint(models.Model):
    STATUS_CHOICES = [
        ("new", "New"),
        ("investigating", "Investigating"),
        ("resolved", "Resolved"),
    ]

    title = models.CharField(max_length=255)
    description = models.TextField()
    hospital = models.ForeignKey("accounts.User", on_delete=models.CASCADE)
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default="new")
    created_at = models.DateTimeField(auto_now_add=True)

