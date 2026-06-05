import os
import django
from unittest.mock import MagicMock

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'medVoice.settings')
django.setup()

from complaints.models import Complaint
from accounts.models import User, Authority, AuthorityProfile, Hospital
from medVoice.context_processors import unread_counts

# 1. Setup Test Users
# Ensure we have a patient, a hospital, and an authority
patient = User.objects.filter(role='patient').first()
if not patient:
    patient = User.objects.create(username='test_patient', role='patient')

hospital_user = User.objects.filter(role='hospital').first()
if not hospital_user:
    hospital_user = User.objects.create(username='test_hospital', role='hospital')

authority_user = User.objects.filter(role='authority').first()
if not authority_user:
    authority_user = User.objects.create(username='test_authority', role='authority')
    # Use Authority model for profile as per codebase patterns (User -> AuthorityProfile)
    # Checking models... AuthorityProfile is OneToOne with User
    if not hasattr(authority_user, 'authority_profile'):
        AuthorityProfile.objects.create(user=authority_user)

# Link Hospital to Authority
# Hospital model is OneToOne with User. Hospital has 'authority' field (FK to AuthorityProfile)
if not hasattr(hospital_user, 'hospital_profile'):
    Hospital.objects.create(user=hospital_user, authority=authority_user.authority_profile)
else:
    hospital_user.hospital_profile.authority = authority_user.authority_profile
    hospital_user.hospital_profile.save()

# 2. Create Complaints
# New Complaint for Hospital
new_complaint = Complaint.objects.create(
    user=patient,
    hospital=hospital_user,
    title="Badge Test New",
    status='new',
    viewed_by_hospital=False
)

# Escalated Complaint for Authority
escalated_complaint = Complaint.objects.create(
    user=patient,
    hospital=hospital_user,
    title="Badge Test Escalated",
    status='escalated',
    escalated_to_authority=True,
    viewed_by_authority=False
)

print(f"Created New Complaint ID: {new_complaint.id}")
print(f"Created Escalated Complaint ID: {escalated_complaint.id}")

# 3. Verify Hospital Context
request_hospital = MagicMock()
request_hospital.user = hospital_user
context_hospital = unread_counts(request_hospital)
print(f"Hospital 'new_complaints_count': {context_hospital.get('new_complaints_count')}")

# 4. Verify Authority Context
request_authority = MagicMock()
request_authority.user = authority_user
context_authority = unread_counts(request_authority)
print(f"Authority 'active_escalations_count': {context_authority.get('active_escalations_count')}")

# Check Results
success = True
if context_hospital['new_complaints_count'] < 1:
    print("❌ Hospital badge count failed (expected >= 1)")
    success = False
else:
    print("✅ Hospital badge count correct")

if context_authority['active_escalations_count'] < 1:
    print("❌ Authority badge count failed (expected >= 1)")
    success = False
else:
    print("✅ Authority badge count correct")

# Cleanup
new_complaint.delete()
escalated_complaint.delete()

if success:
    print("\n✅ VERIFICATION SUCCESSFUL")
else:
    print("\n❌ VERIFICATION FAILED")

