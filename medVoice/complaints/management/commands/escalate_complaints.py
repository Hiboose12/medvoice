from django.core.management.base import BaseCommand
from django.utils import timezone
from datetime import timedelta
from complaints.models import Complaint

class Command(BaseCommand):
    help = 'Escalates complaints that have been in "new" status for more than 7 days.'

    def handle(self, *args, **kwargs):
        from accounts.models import User
        from authorities.models import AuthoritySettings, AuthorityNotification
        
        # 1. Get all authorities with settings
        authority_settings = AuthoritySettings.objects.all()
        processed_complaint_ids = set()
        total_escalated = 0
        
        for settings in authority_settings:
            # Calculate threshold date based on authority's preference (hours)
            # Default is 48 hours if not set (though model has default)
            threshold_hours = settings.response_time_threshold
            threshold_date = timezone.now() - timedelta(hours=threshold_hours)
            
            # Find hospitals under this authority
            # Hospital profile -> authority -> user
            # We need hospitals whose profile.authority.user == settings.authority
            
            # Efficiently:
            # hospitals = User.objects.filter(hospital_profile__authority__user=settings.authority)
            # But let's use the Complaint's hospital directly to avoid complex joins if possible
            # Actually filtering complaints is better:
            
            complaints_to_escalate = Complaint.objects.filter(
                status='new',
                created_at__lte=threshold_date,
                hospital__hospital_profile__authority__user=settings.authority
            ).exclude(id__in=processed_complaint_ids)
            
            count = complaints_to_escalate.count()
            if count > 0:
                self.stdout.write(f"Escalating {count} complaints for authority {settings.authority.username} (Threshold: {threshold_hours}h)")
                
                for complaint in complaints_to_escalate:
                    try:
                        self.escalate_complaint(complaint, settings)
                        processed_complaint_ids.add(complaint.id)
                        total_escalated += 1
                    except Exception as e:
                         self.stdout.write(self.style.ERROR(f"Error escalating {complaint.id}: {e}"))

        # 2. Fallback for complaints not under any authority (or authority has no settings)
        # Use default 7 days (168 hours)
        default_threshold_date = timezone.now() - timedelta(days=7)
        orphan_complaints = Complaint.objects.filter(
            status='new',
            created_at__lte=default_threshold_date
        ).exclude(id__in=processed_complaint_ids)
        
        orphan_count = orphan_complaints.count()
        if orphan_count > 0:
             self.stdout.write(f"Escalating {orphan_count} orphan/default complaints (Threshold: 7 days)")
             for complaint in orphan_complaints:
                try:
                    # No specific authority settings, pass None
                    self.escalate_complaint(complaint, None)
                    total_escalated += 1
                except Exception as e:
                    self.stdout.write(self.style.ERROR(f"Error escalating {complaint.id}: {e}"))

        if total_escalated > 0:
            self.stdout.write(self.style.SUCCESS(f'Successfully escalated {total_escalated} complaints.'))
        else:
            self.stdout.write(self.style.SUCCESS('No stale complaints found to escalate.'))

    def escalate_complaint(self, complaint, settings):
        from django.utils import timezone
        from authorities.models import AuthorityNotification
        
        complaint.status = 'escalated'
        complaint.escalated_to_authority = True
        complaint.escalated_at = timezone.now()
        complaint.save()

        # Notify Authority
        if complaint.hospital and hasattr(complaint.hospital, 'hospital_profile') and complaint.hospital.hospital_profile.authority:
            authority_user = complaint.hospital.hospital_profile.authority.user
            
            # If settings were passed, use them. If not (orphan case but somehow has authority now?), fetch them.
            if not settings:
                from authorities.models import AuthoritySettings
                settings, _ = AuthoritySettings.objects.get_or_create(authority=authority_user)
            
            if settings and settings.escalation_alerts:
                AuthorityNotification.objects.create(
                    recipient=authority_user,
                    notification_type='escalation',
                    title="Complaint Escalated",
                    message=f"Complaint #{complaint.id} against {complaint.hospital.hospital_profile.hospital_name} has been automatically escalated due to inaction.",
                    complaint=complaint,
                    hospital=complaint.hospital,
                    link=f"/authority/complaints/{complaint.id}/"
                )
