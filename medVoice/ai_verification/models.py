from django.db import models
from django.conf import settings

# Create your models here.

class TrainingData(models.Model):
    """
    Stores text and images that were reviewed by the AI system.
    Admin can later manually label them as 'relevant' (1) or 'not relevant' (0)
    to retrain the model.
    """
    text_content = models.TextField(blank=True, null=True)
    image = models.ImageField(upload_to='training_data/', blank=True, null=True)
    
    # 0 = Not Relevant, 1 = Relevant
    is_hospital_related = models.BooleanField(default=False)
    
    # AI Prediction Score (Confidence)
    ai_confidence = models.FloatField(default=0.0)
    
    reviewed_by = models.ForeignKey(
        settings.AUTH_USER_MODEL, 
        on_delete=models.SET_NULL, 
        null=True, 
        blank=True
    )
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"Data {self.id} - {'Relevant' if self.is_hospital_related else 'Irrelevant'}"
