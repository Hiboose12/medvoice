import os
import django

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'medVoice.settings')
django.setup()

try:
    from social import views
    print("Successfully imported social.views")
    print(f"Has Count? {'Count' in dir(views)}")
except Exception as e:
    print(f"Error importing social.views: {e}")
