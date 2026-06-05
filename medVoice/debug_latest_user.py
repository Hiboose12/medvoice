import os
import django
import sys

# Setup Django environment
sys.path.append(os.getcwd())
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'medVoice.settings')
django.setup()

from django.contrib.auth import get_user_model

User = get_user_model()

try:
    latest_user = User.objects.latest('date_joined')
    print(f"Latest User: {latest_user.username} (Role: {latest_user.role})")
    print(f"  is_active: {latest_user.is_active}")
    print(f"  is_approved: {latest_user.is_approved}")
    print(f"  email: {latest_user.email}")
except Exception as e:
    print(f"Error: {e}")
