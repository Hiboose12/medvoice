from django.shortcuts import redirect
from django.contrib import messages
from authorities.models import HospitalFreeze

def check_hospital_freeze(view_func):
    def _wrapped_view(request, *args, **kwargs):
        if request.user.is_authenticated and request.user.role == 'hospital':
            # Check for any active freeze/block - Get the LATEST record
            freeze_record = HospitalFreeze.objects.filter(
                hospital=request.user
            ).order_by('-frozen_at').first()
            
            # Only block if the LATEST record is in a frozen state
            if freeze_record and freeze_record.status in ['frozen', 'pending_review', 'permanently_blocked']:
                # Allow access only to 'submit_appeal' and 'hospital_logout'
                # But since this decorator is applied to views, and submit_appeal won't have it,
                # we just redirect if the user is trying to access a decorated view.
                
                # Double check to prevent redirect loops if applied incorrectly
                if request.resolver_match.url_name == 'submit_appeal':
                    return view_func(request, *args, **kwargs)
                
                messages.error(request, f"Your account is currently {freeze_record.get_status_display()}. access restricted.")
                return redirect('submit_appeal')
                
        return view_func(request, *args, **kwargs)
    return _wrapped_view
