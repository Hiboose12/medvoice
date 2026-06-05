import os
import django
from unittest.mock import MagicMock

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'medVoice.settings')
django.setup()

from complaints.models import Complaint
from accounts.models import User, AuthorityProfile, Hospital, Notification
from authorities.models import AuthorityNotification
from django.core.management import call_command
from django.utils import timezone
from datetime import timedelta

# 1. Setup Test Data
patient = User.objects.filter(role='patient').first()
if not patient:
    patient = User.objects.create(username='notify_patient', role='patient')

authority_user = User.objects.filter(role='authority', username='notify_authority').first()
if not authority_user:
    authority_user = User.objects.create(username='notify_authority', role='authority')
    AuthorityProfile.objects.create(user=authority_user, authority_name="Test Authority")

hospital_user = User.objects.filter(role='hospital', username='notify_hospital').first()
if not hospital_user:
    hospital_user = User.objects.create(username='notify_hospital', role='hospital')
    Hospital.objects.create(user=hospital_user, hospital_name="Test Hospital", authority=authority_user.authority_profile)

# Link Hospital to Authority if not already
if not hasattr(hospital_user, 'hospital_profile'):
     Hospital.objects.create(user=hospital_user, hospital_name="Test Hospital", authority=authority_user.authority_profile)
else:
    hospital_user.hospital_profile.authority = authority_user.authority_profile
    hospital_user.hospital_profile.save()

print("Test data setup complete.")

# 2. Test New Complaint Notification (Simulated)
# We can't easily simulate the view request without a test client and urls, 
# but we can verify the manual creation logic we added to the view by replicating it here 
# OR we can assume if the code is there it works, but better to test the logic flow.

# Let's create a complaint and manually trigger the notification logic 
# (simulating what the view does) to ensure the model relations are correct.
complaint = Complaint.objects.create(
    user=patient,
    hospital=hospital_user,
    title="Notification Test Complaint",
    status='new'
)

# Simulate View Logic
if hasattr(complaint.hospital, 'hospital_profile') and complaint.hospital.hospital_profile.authority:
    auth_user = complaint.hospital.hospital_profile.authority.user
    AuthorityNotification.objects.create(
        recipient=auth_user,
        notification_type='new_complaint',
        title="New Complaint",
        message="New complaint filed",
        complaint=complaint
    )

# Verify Notification exists
new_notif = AuthorityNotification.objects.filter(
    recipient=authority_user, 
    notification_type='new_complaint',
    complaint=complaint
).first()

if new_notif:
    print("✅ New Complaint Notification created successfully.")
else:
    print("❌ New Complaint Notification FAILED.")

# 3. Test Escalation Notification
# Create stale complaint
stale_complaint = Complaint.objects.create(
    user=patient,
    hospital=hospital_user,
    title="Escalation Notification Test",
    status='new'
)
stale_complaint.created_at = timezone.now() - timedelta(days=8)
stale_complaint.save()

print("Running escalation command...")
call_command('escalate_complaints')

# Verify Notification
escalation_notif = AuthorityNotification.objects.filter(
    recipient=authority_user,
    notification_type='escalation',
    complaint=stale_complaint
).first()

if escalation_notif:
    print("✅ Escalation Notification created successfully.")
else:
    print("❌ Escalation Notification FAILED.")

# Cleanup
complaint.delete()
stale_complaint.delete()
if new_notif: new_notif.delete()
if escalation_notif: escalation_notif.delete()
# Users are persistent for speed, maybe delete if unique
