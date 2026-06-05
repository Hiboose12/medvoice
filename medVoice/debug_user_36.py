import os
import django
import sys

sys.path.append(os.getcwd())
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'medVoice.settings')
django.setup()

from django.contrib.auth import get_user_model

User = get_user_model()

def check_user_36():
    print("Checking User 36...")
    try:
        user = User.objects.get(id=36)
        print(f"User Found: {user.username} ({user.role})")
        
        if user.role == 'authority':
            profile = getattr(user, 'authority_profile', None)
            if profile:
                print(f"Authority Profile: {profile.authority_name}")
                doc = profile.authority_id_document
                print(f"ID Document Field: {doc}")
                if doc:
                    print(f"  Name: {doc.name}")
                    print(f"  Path: {doc.path}")
                    print(f"  Size: {doc.size} bytes" if os.path.exists(doc.path) else "  File MISSING")
            else:
                print("No Authority Profile found.")
        
        elif user.role == 'hospital':
           # ... check hospital ...
           pass

    except User.DoesNotExist:
        print("User 36 does not exist.")

if __name__ == "__main__":
    check_user_36()
