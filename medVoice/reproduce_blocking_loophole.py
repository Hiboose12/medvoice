import os
import django

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'medVoice.settings')
django.setup()

from accounts.models import User, Profile

def run():
    # 1. Create a user to be blocked
    email = "blocked_user@example.com"
    phone = "9998887776"
    govt_id = "ABC12345"
    
    # Clean up previous runs
    User.objects.filter(email=email).delete()
    User.objects.filter(email="new_attempt@example.com").delete()
    
    print(f"Creating user {email} with phone {phone}...")
    user = User.objects.create_user(username="blocked_user", email=email, password="password123")
    user.phone_number = phone
    user.govt_id_number = govt_id
    user.account_status = 'blocked'
    user.is_active = False
    user.save()
    print(f"User {user.username} created and BLOCKED.")
    
    # 2. Try to "register" a new user with SAME phone/govt_id but DIFFERENT email
    # Simulating what register_view does (checking manual constraints)
    
    print("\n--- Attempting re-registration with same details ---")
    
    new_email = "new_attempt@example.com"
    
    # Check Phone
    phone_exists_blocked = User.objects.filter(phone_number=phone, account_status='blocked').exists()
    if phone_exists_blocked:
        print(f"[FAIL] System DETECTED blocked phone {phone}. (This is what we WANT)")
    else:
        print(f"[SUCCESS Loophole] System did NOT detect blocked phone {phone}. User could register.")
        
    # Check Govt ID
    id_exists_blocked = User.objects.filter(govt_id_number=govt_id, account_status='blocked').exists()
    if id_exists_blocked:
         print(f"[FAIL] System DETECTED blocked Govt ID {govt_id}. (This is what we WANT)")
    else:
         print(f"[SUCCESS Loophole] System did NOT detect blocked Govt ID {govt_id}. User could register.")

if __name__ == '__main__':
    run()
