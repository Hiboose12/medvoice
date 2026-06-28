import os
import django
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'medVoice.settings')
django.setup()
from django.contrib.auth import get_user_model
User = get_user_model()
for u in User.objects.all():
    print(f'User: {u.username}, Role: {getattr(u, "role", "N/A")}, Active: {u.is_active}, Approved: {getattr(u, "is_approved", "N/A")}')
