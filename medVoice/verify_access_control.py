import os
import django
from django.test import Client
from django.urls import reverse

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'medVoice.settings')
django.setup()

from accounts.models import User, Hospital, Authority
from authorities.models import HospitalFreeze
from django.utils import timezone

def verify_access_control():
    print("--- Verifying Hospital Access Control ---")
    
    # 1. Setup
    client = Client()
    
    # Clean up
    User.objects.filter(username__in=['test_access_hosp', 'test_access_auth']).delete()
    
    # Create Authority
    auth_user = User.objects.create_user(username='test_access_auth', email='auth@test.com', password='password', role='authority', is_approved=True)
    
    # Create Hospital
    hosp_user = User.objects.create_user(username='test_access_hosp', email='hosp@test.com', password='password', role='hospital', is_approved=True)
    Hospital.objects.create(user=hosp_user, hospital_name="Test Access Hospital")
    
    # Login
    client.login(username='test_access_hosp', password='password')
    print("[OK] Logged in as hospital.")
    
    # 2. Test Active Access
    print("\nTesting Active Access...")
    response = client.get(reverse('hospital_dashboard'))
    if response.status_code == 200:
        print("[OK] Accessed dashboard (Active).")
    else:
        print(f"[FAIL] Could not access dashboard. Status: {response.status_code}")
        
    # 3. Freeze Hospital
    print("\nFreezing Hospital...")
    freeze = HospitalFreeze.objects.create(
        hospital=hosp_user,
        frozen_by=auth_user,
        reason="Test Freeze",
        description="Violation",
        status="frozen",
        frozen_at=timezone.now()
    )
    
    # 4. Test Frozen Access
    print("\nTesting Frozen Access...")
    response = client.get(reverse('hospital_dashboard'))
    if response.status_code == 302 and reverse('submit_appeal') in response.url:
        print(f"[OK] Redirected to appeal page. URL: {response.url}")
    else:
        print(f"[FAIL] Did not redirect correctly. Status: {response.status_code}, URL: {getattr(response, 'url', 'N/A')}")
        
    response = client.get(reverse('submit_appeal'))
    if response.status_code == 200:
        print("[OK] Accessed appeal page.")
    else:
        print(f"[FAIL] Could not access appeal page. Status: {response.status_code}")
        
    # 5. Submit Appeal
    print("\nSubmitting Appeal...")
    response = client.post(reverse('submit_appeal'), {'explanation': 'Fixing issues'})
    
    # Should stay on page (redirect to self) or render 200? The view returns redirect("submit_appeal")
    if response.status_code == 302 and 'appeal' in response.url:
         print("[OK] Appeal submitted and redirected to self.")
    else:
         print(f"[FAIL] Appeal submission unexpected response. Status: {response.status_code}")
         
    freeze.refresh_from_db()
    if freeze.status == 'pending_review':
        print("[OK] Freeze status updated to 'pending_review'.")
    else:
        print(f"[FAIL] Freeze status not updated. Status: {freeze.status}")

    # 6. Test Pending Review Access
    print("\nTesting Pending Review Access...")
    response = client.get(reverse('hospital_dashboard'))
    if response.status_code == 302 and reverse('submit_appeal') in response.url:
        print("[OK] Redirected to appeal page (Pending).")
    else:
        print(f"[FAIL] Did not redirect. Status: {response.status_code}")

    # 7. Authority Review & Reactivate
    print("\nAuthority Reviewing Appeal...")
    client.logout()
    client.login(username='test_access_auth', password='password')
    
    # Get freeze record
    freeze.refresh_from_db()
    response = client.get(reverse('authority_review_explanation', args=[freeze.id]))
    if response.status_code == 200:
        print("[OK] Authority accessed review page.")
    else:
        print(f"[FAIL] Authority could not access review page. Status: {response.status_code}")
        
    print("Reactivating via Authority...")
    response = client.post(reverse('authority_review_explanation', args=[freeze.id]), {'action': 'reactivate'})
    
    freeze.refresh_from_db()
    if freeze.status == 'reactivated':
        print("[OK] Authority reactivated hospital.")
    else:
        print(f"[FAIL] Reactivation failed. Status: {freeze.status}")

    # 8. Test Reactivated Access
    print("\nTesting Reactivated Access...")
    client.logout()
    client.login(username='test_access_hosp', password='password')
    
    response = client.get(reverse('hospital_dashboard'))
    if response.status_code == 200:
        print("[OK] Accessed dashboard (Reactivated).")
    else:
        print(f"[FAIL] Could not access dashboard. Status: {response.status_code}")

    # 8. Test Logout
    print("\nTesting Logout...")
    response = client.post(reverse('hospital_logout'))
    if response.status_code == 302 and response.url == reverse('home'):
        print("[OK] Logged out and redirected to home.")
    else:
        print(f"[FAIL] Logout failed or bad redirect. Status: {response.status_code}, URL: {getattr(response, 'url', 'N/A')}")

    print("\n--- Verification Complete ---")

if __name__ == "__main__":
    verify_access_control()
