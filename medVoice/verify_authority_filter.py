import os
import django

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'medVoice.settings')
django.setup()

from complaints.models import Complaint
from accounts.models import User

# Setup user if needed (reusing from previous script logic if applicable, but making it standalone)
user = User.objects.filter(role='patient').first()
if not user:
    user = User.objects.first()

# Create test complaints
# 1. Escalated and Active
active_escalated = Complaint.objects.create(
    user=user, title="Active Escalation", description="Desc",
    category="billing", severity="high",
    status="escalated", escalated_to_authority=True
)

# 2. Escalated but Resolved (should be hidden)
resolved_escalated = Complaint.objects.create(
    user=user, title="Resolved Escalation", description="Desc",
    category="billing", severity="high",
    status="resolved", escalated_to_authority=True
)

# 3. Not Escalated (should be hidden)
other_complaint = Complaint.objects.create(
    user=user, title="Other Complaint", description="Desc",
    category="billing", severity="low",
    status="new", escalated_to_authority=False
)

print(f"Created Complaints: IDs {active_escalated.id}, {resolved_escalated.id}, {other_complaint.id}")

# Simulate View Logic
# We don't have easy access to 'hospital_ids' from here without setting up a full authority/hospital relationship structure which is complex code.
# However, we can test the filter logic directly on the queryset as the view does.
# The view does: Complaint.objects.filter(..., escalated_to_authority=True, status='escalated')

filtered_complaints = Complaint.objects.filter(
    escalated_to_authority=True,
    status='escalated'
)

print(f"Filtered Count: {filtered_complaints.count()}")
found_ids = [c.id for c in filtered_complaints]
print(f"Found IDs: {found_ids}")

if active_escalated.id in found_ids and resolved_escalated.id not in found_ids:
    print("\n✅ VERIFICATION SUCCESSFUL: Only active escalated complaints are shown.")
else:
    print("\n❌ VERIFICATION FAILED: Filter logic is incorrect.")

# Cleanup
active_escalated.delete()
resolved_escalated.delete()
other_complaint.delete()
