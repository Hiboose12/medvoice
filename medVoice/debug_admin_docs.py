import os
import django
import sys

sys.path.append(os.getcwd())
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'medVoice.settings')
django.setup()

from django.contrib.auth import get_user_model
from accounts.models import Hospital

User = get_user_model()

def check_docs():
    print("Checking Hospital Documents...")
    # Find a hospital user. 'medcity_hospital' was used in previous sessions
    hospital_user = User.objects.filter(role='hospital').last()
    
    if not hospital_user:
        print("No hospital user found.")
        return

    print(f"Checking user: {hospital_user.username} (ID: {hospital_user.id})")
    
    try:
        profile = hospital_user.hospital_profile
        print(f"Hospital Profile found: {profile.hospital_name}")
        
        doc = profile.license_document
        print(f"License Document Field: {doc}")
        
        if doc:
            print(f"  Name: {doc.name}")
            print(f"  Path: {doc.path}")
            print(f"  URL: {doc.url}")
            
            if os.path.exists(doc.path):
                print("  [SUCCESS] File exists on disk.")
                print(f"  Size: {os.path.getsize(doc.path)} bytes")
            else:
                print("  [FAILURE] File DOES NOT exist on disk.")
                
            # Simulate open
            try:
                f = doc.open('rb')
                print("  [SUCCESS] File opened successfully.")
                f.close()
            except Exception as e:
                print(f"  [FAILURE] Could not open file: {e}")
        else:
            print("  [WARNING] No license document associated.")
            
    except Exception as e:
        print(f"Error accessing profile: {e}")

if __name__ == "__main__":
    check_docs()
