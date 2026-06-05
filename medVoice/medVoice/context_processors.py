from social.models import Message
from accounts.models import Notification
from complaints.models import Complaint
from django.db.models import Q

def unread_counts(request):
    """
    Context processor to return unread message, notification, and complaint counts.
    Using request.user.
    """
    counts = {
        'unread_messages_count': 0,
        'unread_notifications_count': 0,
        'new_complaints_count': 0,
        'active_escalations_count': 0,
    }

    if request.user.is_authenticated:
        # 📩 Unread Messages
        counts['unread_messages_count'] = Message.objects.filter(
            receiver=request.user,
            is_read=False
        ).count()

        # 🔔 Unread Notifications
        counts['unread_notifications_count'] = Notification.objects.filter(
            recipient=request.user,
            is_read=False
        ).count()

        # 🏥 Hospital: New Complaints (not viewed)
        if request.user.role == 'hospital':
            counts['new_complaints_count'] = Complaint.objects.filter(
                hospital=request.user,
                viewed_by_hospital=False
            ).count()

        # 🏛️ Authority: Active Escalations & Notifications
        elif request.user.role == 'authority':
            from authorities.models import AuthorityNotification
            
            # notifications
            counts['unread_notifications_count'] = AuthorityNotification.objects.filter(
                recipient=request.user,
                is_read=False
            ).count()

            try:
                if hasattr(request.user, 'authority_profile'):
                    counts['active_escalations_count'] = Complaint.objects.filter(
                        hospital__hospital_profile__authority=request.user.authority_profile,
                        escalated_to_authority=True,
                        status='escalated',
                        viewed_by_authority=False
                    ).count()
            except Exception:
                pass

    return counts
