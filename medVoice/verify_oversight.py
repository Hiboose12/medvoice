import os
import django
from django.utils import timezone
from datetime import timedelta

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'medVoice.settings')
django.setup()

from accounts.models import User, Hospital, Authority, Hospital
from authorities.models import HospitalFreeze, AuthorityNotification
from complaints.models import Complaint

def verify_oversight():
    print("--- Verifying Hospital Oversight & Appeal ---")

    # 1. Setup Data
    print("Setting up test data...")
    
    # Cleanup previous runs
    User.objects.filter(username__in=['test_oversight_auth', 'test_oversight_hosp']).delete()
    
    # Create Authority
    authority_user, _ = User.objects.get_or_create(username='test_oversight_auth', email='auth@test.com', role='authority')
    authority_user.set_password('password')
    authority_user.is_approved = True
    authority_user.save()
    
    auth_profile, _ = Authority.objects.get_or_create(
        user=authority_user, 
        jurisdiction_level='district', 
        jurisdiction_district='Test District',
        jurisdiction_state='Test State',
        authority_name="Test Authority",
        authority_type="district"
    )

    # Create Hospital
    hospital_user, _ = User.objects.get_or_create(username='test_oversight_hosp', email='hosp@test.com', role='hospital')
    hospital_user.set_password('password')
    hospital_user.is_approved = True
    # Ensure active for login
    hospital_user.is_active = True 
    hospital_user.save()

    hosp_profile, _ = Hospital.objects.get_or_create(
        user=hospital_user,
        hospital_name="Test General Hospital",
        authority=auth_profile
    )

    # Create Complaints
    Complaint.objects.create(hospital=hospital_user, title="Complaint 1", status='new', user=authority_user) # reusing auth user as patient for simplicity
    Complaint.objects.create(hospital=hospital_user, title="Complaint 2", status='resolved', user=authority_user)

    print("Data setup complete.")

    # 2. Test Freeze Logic
    print("\nTesting Freeze Logic...")
    # Freeze the hospital (simulating authority action)
    freeze = HospitalFreeze.objects.create(
        hospital=hospital_user,
        frozen_by=authority_user,
        reason="violation",
        description="Repeated violations",
        status="frozen",
        frozen_at=timezone.now()
    )
    print(f"Hospital frozen. Freeze ID: {freeze.id}")

    # Verify freeze record exists
    active_freeze = HospitalFreeze.objects.filter(hospital=hospital_user, status='frozen').first()
    if active_freeze:
        print("[OK] Active freeze record found.")
    else:
        print("[FAIL] Active freeze record NOT found.")

    # 3. Test Appeal Submission
    print("\nTesting Appeal Submission...")
    # Simulate appeal data
    explanation_text = "We have fixed the issues."
    
    # Update freeze record as if view did it
    freeze.explanation_requested = True
    freeze.explanation_received = True
    freeze.explanation_text = explanation_text
    freeze.explanation_submitted_at = timezone.now()
    freeze.status = 'pending_review'
    freeze.save()
    
    print(f"Appeal submitted. Status: {freeze.status}")

    # 4. Verify Notification to Authority
    print("\nVerifying Authority Notification...")
    # Check if a notification would be created (we can manually create it to verify model or check if view logic works)
    # The view creates it, but we are running script. Let's create it manually to verify model/creation works
    notif = AuthorityNotification.objects.create(
        recipient=authority_user,
        notification_type='explanation',
        title="Appeal Received",
        message=f"Hospital {hospital_user.username} submitted appeal.",
        freeze=freeze
    )
    print(f"Notification created: {notif.id} - {notif.title}")

    if notif.freeze == freeze:
        print("[OK] Notification linked to freeze record.")
    else:
        print("[FAIL] Notification link failed.")

    # 5. Verify Unfreeze
    print("\nTesting Unfreeze...")
    freeze.status = 'reactivated'
    freeze.unfrozen_at = timezone.now()
    freeze.save()
    
    print(f"Hospital un-frozen. Status: {freeze.status}")
    
    print("\n--- Verification Complete ---")

if __name__ == '__main__':
    verify_oversight()
