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
    user = User.objects.get(username='alan')
    if not user.is_active:
        user.is_active = True
        user.is_approved = True
        user.save()
        print(f"User {user.username} activated.")
    else:
        print(f"User {user.username} is already active.")
except User.DoesNotExist:
    print("User alan not found.")
except Exception as e:
    print(f"Error: {e}")
