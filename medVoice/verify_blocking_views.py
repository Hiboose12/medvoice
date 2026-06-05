import os
import django
import json

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'medVoice.settings')
django.setup()

from django.conf import settings

# Override ALLOWED_HOSTS for test client
settings.ALLOWED_HOSTS = list(settings.ALLOWED_HOSTS) + ['testserver']

from django.test import Client
from accounts.models import User
from django.urls import reverse

def run_tests():
    client = Client()
    
    # 1. Setup Blocked User
    email = "test_blocked@example.com"
    phone = "1112223333"
    govt_id = "BLOCK123"
    
    User.objects.filter(email=email).delete()
    user = User.objects.create_user(username="test_blocked", email=email, password="password")
    user.phone_number = phone
    user.govt_id_number = govt_id
    user.account_status = 'blocked'
    user.is_active = False
    user.save()
    
    print(f"Created blocked user: {email} / {phone}")

    # 2. Verify validate_email
    print("\n--- Testing validate_email ---")
    try:
        url = reverse('validate_email')
        response = client.post(url, {'email': email})
        print(f"Status Code: {response.status_code}")
        if response.headers.get('Content-Type') == 'application/json':
            data = response.json()
            print(f"Response: {data}")
            if data.get('status') == 'error' and 'blocked' in data.get('message', '').lower():
                print("[PASS] validate_email correctly blocked the email.")
            else:
                print(f"[FAIL] validate_email DID NOT block the email as expected. Msg: {data.get('message')}")
        else:
             print(f"[FAIL] validate_email returned non-JSON. Content: {response.content[:200]}")
    except Exception as e:
        print(f"[ERROR] testing validate_email: {e}")

    # 3. Verify request_otp
    print("\n--- Testing request_otp ---")
    try:
        url = reverse('request_otp')
        response = client.post(url, {'phone_number': phone})
        print(f"Status Code: {response.status_code}")
        if response.headers.get('Content-Type') == 'application/json':
            data = response.json()
            print(f"Response: {data}")
            if data.get('status') == 'error' and 'blocked' in data.get('message', '').lower():
                 print("[PASS] request_otp correctly blocked the phone number.")
            else:
                 print(f"[FAIL] request_otp DID NOT block the phone number as expected. Msg: {data.get('message')}")
        else:
            print(f"[FAIL] request_otp returned non-JSON. Content: {response.content[:200]}")
    except Exception as e:
        print(f"[ERROR] testing request_otp: {e}")

    # 4. Verify Content Access (Complaint Detail)
    # Need to create a complaint for the blocked user
    try:
        from complaints.models import Complaint
        complaint = Complaint.objects.create(
            user=user, 
            title="Blocked Complaint", 
            description="Hidden content",
            category="General" 
        )
    except Exception as e:
        print(f"[ERROR] Creating complaint: {e}")
        return

    print(f"\n--- Testing complaint_detail access ---")
    try:
        # Create a generic active user to try to view it
        viewer_email = "viewer_test@example.com"
        User.objects.filter(email=viewer_email).delete()
        viewer = User.objects.create_user(username="viewer_test", email=viewer_email, password="password")
        client.force_login(viewer)
        
        try:
            url = reverse('complaint_detail', args=[complaint.id])
            response = client.get(url)
            print(f"Response code: {response.status_code}")
            
            if response.status_code == 404:
                print("[PASS] complaint_detail correctly returned 404 for blocked user content.")
            else:
                print(f"[FAIL] complaint_detail returned {response.status_code} instead of 404.")
        except Exception as e:
             # Reverse might fail if url not found
             print(f"[ERROR] accessing complaint detail logic: {e}")
            
        # Cleanup viewer
        viewer.delete()
    except Exception as e:
        print(f"[ERROR] testing complaint_detail: {e}")
        
    # Cleanup
    user.delete()
    complaint.delete()

if __name__ == "__main__":
    run_tests()
