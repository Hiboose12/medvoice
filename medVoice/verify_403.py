import os
import django
from django.template.loader import get_template

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'medVoice.settings')
django.setup()

def verify_403_template():
    print("Verifying 403.html template...")
    try:
        t = get_template('403.html')
        print("✅ SUCCESS: Template 403.html loaded successfully.")
        print(f"Template path: {t.origin.name}")
    except Exception as e:
        print(f"❌ FAILURE: Could not load 403.html. Error: {e}")

if __name__ == "__main__":
    verify_403_template()
