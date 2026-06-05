import os
import django
from django.utils import timezone
from datetime import timedelta

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'medVoice.settings')
django.setup()

from complaints.models import Complaint
from accounts.models import User

# Ensure a user exists
user = User.objects.filter(role='patient').first()
if not user:
    user = User.objects.first()
if not user:
    print("No user found, cannot create test complaints.")
    exit()

# Create stale complaint
# We need to manually set created_at, but auto_now_add makes it immutable on creation usually.
# However, we can update it after creation.
stale_complaint = Complaint.objects.create(
    user=user,
    title="Verification Stale Complaint",
    description="This should be escalated",
    category="service",
    severity="low",
    status="new"
)
# Hack to force old date
stale_complaint.created_at = timezone.now() - timedelta(days=8)
stale_complaint.save()

# Create fresh complaint
fresh_complaint = Complaint.objects.create(
    user=user,
    title="Verification Fresh Complaint",
    description="This should NOT be escalated",
    category="service",
    severity="low",
    status="new"
)

print(f"Created Stale Complaint ID: {stale_complaint.id} (Status: {stale_complaint.status})")
print(f"Created Fresh Complaint ID: {fresh_complaint.id} (Status: {fresh_complaint.status})")

from django.core.management import call_command
print("\n--- Running escalate_complaints command ---")
call_command('escalate_complaints')
print("--- Command finished ---\n")

stale_complaint.refresh_from_db()
fresh_complaint.refresh_from_db()

print(f"Stale Complaint ID: {stale_complaint.id} -> Status: {stale_complaint.status}")
print(f"Fresh Complaint ID: {fresh_complaint.id} -> Status: {fresh_complaint.status}")

if stale_complaint.status == 'escalated' and fresh_complaint.status == 'new':
    print("\n✅ VERIFICATION SUCCESSFUL")
else:
    print("\n❌ VERIFICATION FAILED")

# Cleanup
stale_complaint.delete()
fresh_complaint.delete()
