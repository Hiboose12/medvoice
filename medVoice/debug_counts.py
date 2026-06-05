import os
import django
from django.db.models import Count, Q

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'medVoice.settings')
django.setup()

from accounts.models import User
from social.models import Message

def debug_unread_counts():
    # Get a patient user
    patient = User.objects.filter(role='patient').first()
    if not patient:
        print("No patient found")
        return

    print(f"Checking counts for user: {patient.username} (ID: {patient.id})")

    conversations = patient.conversations.annotate(
        unread_count=Count('messages', filter=Q(messages__is_read=False) & Q(messages__receiver=patient))
    ).order_by("-updated_at")

    for convo in conversations:
        print(f"Conversation ID: {convo.id}")
        print(f"  - Unread Count: {convo.unread_count} (Type: {type(convo.unread_count)})")
        
        # Verify manually
        actual_count = convo.messages.filter(is_read=False, receiver=patient).count()
        print(f"  - Actual Checks Query: {actual_count}")
        
        if convo.unread_count != actual_count:
            print("  MISMATCH DETECTED!")
        else:
             print("  Count Matches")
    
    # Simulate unread message
    print("\nSimulating unread message...")
    convo = conversations.first()
    if convo:
        # Create a message FROM someone else TO the patient
        # Find another user
        other = convo.participants.exclude(id=patient.id).first()
        if other:
            Message.objects.create(conversation=convo, sender=other, receiver=patient, content="Test unread", is_read=False)
            print("Created unread message from", other.username)
            
            # Re-query
            convo_refresh = patient.conversations.annotate(
                unread_count=Count('messages', filter=Q(messages__is_read=False) & Q(messages__receiver=patient))
            ).get(id=convo.id)
            print(f"New Unread Count: {convo_refresh.unread_count}")

if __name__ == "__main__":
    debug_unread_counts()

