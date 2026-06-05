from django.shortcuts import render, redirect, get_object_or_404
from django.contrib.auth.decorators import login_required
from django.contrib.auth import update_session_auth_hash
from django.contrib import messages
from django.utils import timezone
from datetime import timedelta
from django.db.models import Q, Count, Avg
from django.http import JsonResponse

from complaints.models import Complaint, HospitalResponse
from .models import (
    AuthoritySettings, HospitalWarning, HospitalFreeze,
    ComplaintActivityLog, AuthorityNotification,
    AuthorityConversation, AuthorityMessage
)
from .forms import AuthorityProfileForm, UserUpdateForm
from django.contrib.auth.forms import PasswordChangeForm

@login_required
def authority_edit_profile(request):
    """Edit authority profile."""
    access_error = check_authority_access(request)
    if access_error:
        return access_error
        
    try:
        authority_profile = request.user.authority_profile
    except:
        messages.error(request, "Authority profile not found")
        return redirect('authority_dashboard')
        
    if request.method == 'POST':
        u_form = UserUpdateForm(request.POST, instance=request.user)
        p_form = AuthorityProfileForm(request.POST, request.FILES, instance=authority_profile)
        
        if u_form.is_valid() and p_form.is_valid():
            u_form.save()
            p_form.save()
            messages.success(request, 'Your profile has been updated!')
            return redirect('authority_profile')
        else:
            print(f"User Form Errors: {u_form.errors}")
            print(f"Authority Form Errors: {p_form.errors}")
            messages.error(request, "Please correct the errors below.")
    else:
        u_form = UserUpdateForm(instance=request.user)
        p_form = AuthorityProfileForm(instance=authority_profile)
        
    context = {
        'u_form': u_form,
        'p_form': p_form
    }
    
    return render(request, 'authorities/edit_profile.html', context)


def check_authority_access(request):
    """Check if user has authority access."""
    if not request.user.is_authenticated:
        return redirect('login')
    if request.user.role.lower() != "authority":
        return redirect('login')
    if not request.user.is_approved:
        return redirect('pending_approval')
    return None


def get_authority_jurisdiction_hospitals(request):
    """Get hospitals that fall under the authority's jurisdiction."""
    try:
        from accounts.models import User
        authority_profile = request.user.authority_profile
        
        # New logic: Use the direct foreign key relationship
        # The Hospital model has an 'authority' FK pointing to Authority model
        # The Authority model is linked to User via OneToOne
        
        hospitals = User.objects.filter(
            role='hospital',
            is_approved=True,
            hospital_profile__authority=authority_profile
        ).distinct()
        
        return hospitals
    except Exception as e:
        print(f"Error getting jurisdiction hospitals: {e}")
        from accounts.models import User
        return User.objects.none()


def get_authority_jurisdiction_filter(request):
    """Get Q object for filtering by authority jurisdiction."""
    # This might need request to know WHICH authority
    try:
        authority_profile = request.user.authority_profile
        return Q(hospital__hospital_profile__authority=authority_profile)
    except:
        return Q(pk__none=True)


@login_required
@login_required
def authority_regulations(request):
    """Regulations page for health authority."""
    access_error = check_authority_access(request)
    if access_error:
        return access_error
    
    return render(request, "authorities/regulations.html")


def authority_dashboard(request):
    """Authority Dashboard with statistics."""
    access_error = check_authority_access(request)
    if access_error:
        return access_error
    
    authority = request.user
    
    # Get hospitals under jurisdiction
    hospitals = get_authority_jurisdiction_hospitals(request)
    hospital_ids = hospitals.values_list('id', flat=True)
    
    # Get complaints for these hospitals
    complaints = Complaint.objects.filter(
        hospital_id__in=hospital_ids
    ).order_by('-created_at')
    
    # Statistics
    total_hospitals = hospitals.count()
    active_complaints = complaints.filter(status__in=['new', 'review', 'responded']).count()
    escalated_complaints = complaints.filter(escalated_to_authority=True).count()
    resolved_complaints = complaints.filter(status='resolved').count()
    
    # Get hospitals with warnings
    hospitals_with_warnings = HospitalWarning.objects.filter(
        hospital_id__in=hospital_ids,
        is_active=True
    ).values_list('hospital_id', flat=True).distinct().count()
    
    # Recently escalated complaints
    recent_escalations = complaints.filter(
        escalated_to_authority=True
    ).order_by('-escalated_at')[:5]
    
    # Get unread notifications
    unread_notifications = AuthorityNotification.objects.filter(
        recipient=authority,
        is_read=False
    ).count()
    
    # Frozen hospitals count
    frozen_hospitals = HospitalFreeze.objects.filter(
        hospital_id__in=hospital_ids,
        status='frozen'
    ).count()
    
    context = {
        'total_hospitals': total_hospitals,
        'active_complaints': active_complaints,
        'escalated_complaints': escalated_complaints,
        'resolved_complaints': resolved_complaints,
        'hospitals_with_warnings': hospitals_with_warnings,
        'recent_escalations': recent_escalations,
        'unread_notifications': unread_notifications,
        'frozen_hospitals': frozen_hospitals,
    }
    
    return render(request, "authorities/dashboard.html", context)


@login_required
def authority_complaints(request):
    """View all complaints under jurisdiction with filtering."""
    access_error = check_authority_access(request)
    if access_error:
        return access_error
    
    hospitals = get_authority_jurisdiction_hospitals(request)
    hospital_ids = hospitals.values_list('id', flat=True)
    
    # Get filter parameters
    status_filter = request.GET.get('status', 'all')
    severity_filter = request.GET.get('severity', 'all')
    search_query = request.GET.get('q', '')
    
    complaints = Complaint.objects.filter(
        hospital_id__in=hospital_ids
    ).order_by('-created_at')
    
    # Apply filters
    if status_filter != 'all':
        complaints = complaints.filter(status=status_filter)
    
    if severity_filter != 'all':
        complaints = complaints.filter(severity=severity_filter)
    
    if search_query:
        complaints = complaints.filter(
            Q(title__icontains=search_query) |
            Q(description__icontains=search_query) |
            Q(hospital__username__icontains=search_query)
        )
    
    # Get escalated complaints count
    escalated_count = complaints.filter(escalated_to_authority=True).count()
    
    context = {
        'complaints': complaints,
        'status_filter': status_filter,
        'severity_filter': severity_filter,
        'search_query': search_query,
        'escalated_count': escalated_count,
    }
    
    return render(request, "authorities/complaints.html", context)


@login_required
def authority_escalations(request):
    """View escalated complaints requiring attention."""
    access_error = check_authority_access(request)
    if access_error:
        return access_error
    
    hospitals = get_authority_jurisdiction_hospitals(request)
    hospital_ids = hospitals.values_list('id', flat=True)
    
    escalated_complaints = Complaint.objects.filter(
        hospital_id__in=hospital_ids,
        escalated_to_authority=True
    ).exclude(status='resolved').order_by('-escalated_at')
    
    # Get activity logs for each complaint
    for complaint in escalated_complaints:
        complaint.activity_logs_data = ComplaintActivityLog.objects.filter(
            complaint=complaint
        ).order_by('-created_at')[:10]
    
    context = {
        'complaints': escalated_complaints,
    }
    
    return render(request, "authorities/escalations.html", context)


@login_required
def authority_complaint_detail(request, complaint_id):
    """View detailed complaint information with activity timeline."""
    access_error = check_authority_access(request)
    if access_error:
        return access_error
    
    hospitals = get_authority_jurisdiction_hospitals(request)
    hospital_ids = hospitals.values_list('id', flat=True)
    
    complaint = get_object_or_404(
        Complaint,
        id=complaint_id,
        hospital_id__in=hospital_ids
    )
    
    # Mark as viewed by authority
    if not complaint.viewed_by_authority:
        complaint.viewed_by_authority = True
        complaint.save()
        
        # Log activity
        ComplaintActivityLog.objects.create(
            complaint=complaint,
            activity_type='authority_viewed',
            performed_by=request.user,
            description=f"Complaint viewed by authority {request.user.username}"
        )
    
    # Get hospital responses
    responses = HospitalResponse.objects.filter(
        complaint=complaint
    ).order_by('created_at')
    
    # Get activity logs
    activity_logs = ComplaintActivityLog.objects.filter(
        complaint=complaint
    ).order_by('-created_at')
    
    # Get hospital profile info
    from accounts.models import Hospital as HospitalModel
    try:
        hospital_profile = HospitalModel.objects.get(user=complaint.hospital)
    except HospitalModel.DoesNotExist:
        hospital_profile = None
    
    context = {
        'complaint': complaint,
        'responses': responses,
        'activity_logs': activity_logs,
        'hospital_profile': hospital_profile,
    }
    
    return render(request, "authorities/complaint_detail.html", context)


@login_required
def authority_hospitals(request):
    """View and manage hospitals under jurisdiction."""
    access_error = check_authority_access(request)
    if access_error:
        return access_error
    
    hospitals = get_authority_jurisdiction_hospitals(request)
    
    # Get filter parameters
    status_filter = request.GET.get('status', 'all')
    search_query = request.GET.get('q', '')
    
    # Get hospital details with counts
    hospital_data = []
    for hospital in hospitals:
        from accounts.models import Hospital as HospitalModel
        try:
            profile = HospitalModel.objects.get(user=hospital)
            complaint_count = Complaint.objects.filter(hospital=hospital).count()
            resolved_count = Complaint.objects.filter(hospital=hospital, status='resolved').count()
            active_warnings = HospitalWarning.objects.filter(
                hospital=hospital,
                is_active=True
            ).count()
            
            # Check freeze status
            freeze_record = HospitalFreeze.objects.filter(
                hospital=hospital
            ).order_by('-frozen_at').first()
            
            hospital_data.append({
                'user': hospital,
                'profile': profile,
                'complaint_count': complaint_count,
                'resolved_count': resolved_count,
                'active_warnings': active_warnings,
                'freeze_record': freeze_record,
            })
        except HospitalModel.DoesNotExist:
            pass
    
    context = {
        'hospitals': hospital_data,
        'status_filter': status_filter,
        'search_query': search_query,
    }
    
    return render(request, "authorities/hospitals.html", context)


@login_required
def authority_hospital_detail(request, hospital_id):
    """View detailed statistics and info for a specific hospital."""
    access_error = check_authority_access(request)
    if access_error:
        return access_error
    
    hospitals = get_authority_jurisdiction_hospitals(request)
    
    # Ensure hospital is in jurisdiction
    hospital = get_object_or_404(
        User := __import__('accounts.models', fromlist=['User']).User,
        id=hospital_id,
        role='hospital'
    )
    
    if hospital.id not in hospitals.values_list('id', flat=True):
        messages.error(request, "Hospital not in your jurisdiction")
        return redirect('authority_hospitals')

    from accounts.models import Hospital as HospitalModel
    try:
        profile = HospitalModel.objects.get(user=hospital)
    except HospitalModel.DoesNotExist:
        profile = None
        
    # Statistics
    complaints = Complaint.objects.filter(hospital=hospital).order_by('-created_at')
    
    stats = {
        'total': complaints.count(),
        'new': complaints.filter(status='new').count(),
        'review': complaints.filter(status='review').count(),
        'responded': complaints.filter(status='responded').count(),
        'resolved': complaints.filter(status='resolved').count(),
        'escalated': complaints.filter(escalated_to_authority=True).count(),
        'avg_rating': 0 # Placeholder for future rating implementation
    }
    
    # Get active warnings
    active_warnings = HospitalWarning.objects.filter(
        hospital=hospital,
        is_active=True
    ).order_by('-created_at')
    
    # Get freeze history
    freeze_history = HospitalFreeze.objects.filter(
        hospital=hospital
    ).order_by('-frozen_at')
    
    current_freeze = freeze_history.filter(status='frozen').first()
    
    context = {
        'hospital': hospital,
        'profile': profile,
        'stats': stats,
        'recent_complaints': complaints[:10],
        'active_warnings': active_warnings,
        'freeze_history': freeze_history,
        'current_freeze': current_freeze,
    }
    
    return render(request, "authorities/hospital_detail.html", context)


@login_required
def authority_warnings(request):
    """View and manage warnings issued to hospitals."""
    access_error = check_authority_access(request)
    if access_error:
        return access_error
    
    hospitals = get_authority_jurisdiction_hospitals(request)
    hospital_ids = hospitals.values_list('id', flat=True)
    
    warnings = HospitalWarning.objects.filter(
        hospital_id__in=hospital_ids
    ).order_by('-created_at')
    
    context = {
        'warnings': warnings,
    }
    
    return render(request, "authorities/warnings.html", context)


@login_required
def issue_warning(request, hospital_id):
    """Issue a warning to a hospital."""
    access_error = check_authority_access(request)
    if access_error:
        return access_error
    
    hospitals = get_authority_jurisdiction_hospitals(request)
    
    hospital = get_object_or_404(
        User := __import__('accounts.models', fromlist=['User']).User,
        id=hospital_id,
        role='hospital'
    )
    
    # Verify hospital is in jurisdiction
    if hospital.id not in hospitals.values_list('id', flat=True):
        messages.error(request, "Hospital not in your jurisdiction")
        return redirect('authority_hospitals')
    
    if request.method == 'POST':
        warning_type = request.POST.get('warning_type', 'serious')
        reason = request.POST.get('reason', '')
        complaint_id = request.POST.get('complaint_id', None)
        
        if not reason:
            messages.error(request, "Warning reason is required")
            return redirect('authority_hospitals')
        
        # Create warning
        warning = HospitalWarning.objects.create(
            issued_by=request.user,
            hospital=hospital,
            warning_type=warning_type,
            reason=reason,
            complaint_id=complaint_id if complaint_id else None
        )
        
        # Create notification for hospital
        from accounts.models import Notification
        Notification.objects.create(
            recipient=hospital,
            title='Warning Issued',
            message=f"You have received a {warning_type} warning from the health authority: {reason}",
            link=f"/hospital/dashboard/" 
        )
        
        # Check settings
        authority_settings, _ = AuthoritySettings.objects.get_or_create(
            authority=request.user
        )
        
        # Create notification for authority if enabled
        if authority_settings.warning_alerts:
            AuthorityNotification.objects.create(
                recipient=request.user,
                notification_type='warning',
                title='Warning Issued',
                message=f"You issued a {warning_type} warning to {hospital.username}",
                warning=warning,
                link=f"/authority/hospitals/{hospital.id}/"
            )
        
        # Check if hospital should be frozen
        authority_settings, _ = AuthoritySettings.objects.get_or_create(
            authority=request.user
        )
        warning_count = HospitalWarning.objects.filter(
            hospital=hospital,
            is_active=True
        ).count()
        
        if warning_count >= authority_settings.warning_threshold:
            # Auto-freeze hospital
            freeze = HospitalFreeze.objects.create(
                hospital=hospital,
                frozen_by=request.user,
                reason='warning_limit',
                description=f"Automatically frozen after receiving {warning_count} active warnings"
            )
            
            # Freeze the hospital user
            hospital.is_active = False
            hospital.save()
            
            messages.warning(
                request,
                f"Hospital has been frozen due to exceeding warning threshold ({warning_count} warnings)"
            )
        else:
            messages.success(request, f"Warning issued to {hospital.username}")
        
        return redirect('authority_hospitals')
    
    context = {
        'hospital': hospital,
    }
    
    return render(request, "authorities/issue_warning.html", context)


@login_required
def authority_freeze_hospital(request, hospital_id):
    """Freeze a hospital account."""
    access_error = check_authority_access(request)
    if access_error:
        return access_error
    
    hospitals = get_authority_jurisdiction_hospitals(request)
    
    hospital = get_object_or_404(
        User := __import__('accounts.models', fromlist=['User']).User,
        id=hospital_id,
        role='hospital'
    )
    
    if request.method == 'POST':
        reason = request.POST.get('reason', '')
        description = request.POST.get('description', '')
        
        if not reason or not description:
            messages.error(request, "Reason and description are required")
            return redirect('authority_hospitals')
        
        # Check if there's already an active freeze or pending review
        existing_freeze = HospitalFreeze.objects.filter(
            hospital=hospital,
            status__in=['frozen', 'pending_review']
        ).first()
        
        if existing_freeze:
            messages.error(request, f"This hospital is already frozen or has a pending appeal.")
            return redirect('authority_hospitals')
        
        # Create freeze record
        freeze = HospitalFreeze.objects.create(
            hospital=hospital,
            frozen_by=request.user,
            reason=reason,
            description=description,
            status='frozen'
        )
        
        # Freeze hospital user
        # We also deactivate the user so they cannot login except to see the disabled page
        hospital.account_status = 'frozen'
        hospital.is_active = False 
        hospital.save()
        
        # Create notification for hospital
        from accounts.models import Notification
        Notification.objects.create(
            recipient=hospital,
            title='Account Frozen',
            message=f"Your hospital account has been frozen. Reason: {description}",
            link="/login/"
        )
        
        # Check settings
        authority_settings, _ = AuthoritySettings.objects.get_or_create(
            authority=request.user
        )
        
        # Create notification for authority if enabled
        if authority_settings.freeze_alerts:
            AuthorityNotification.objects.create(
                recipient=request.user,
                notification_type='freeze',
                title='Account Frozen',
                message=f"You froze the account for {hospital.username}. Reason: {description}",
                freeze=freeze,
                link=f"/authority/hospitals/{hospital.id}/"
            )
        
        messages.success(request, f"Hospital {hospital.username} has been frozen")
        return redirect('authority_hospitals')
    
    context = {
        'hospital': hospital,
    }
    
    return render(request, "authorities/freeze_hospital.html", context)


@login_required
def authority_unfreeze_hospital(request, hospital_id):
    """Unfreeze/reactivate a hospital account."""
    access_error = check_authority_access(request)
    if access_error:
        return access_error
    
    hospitals = get_authority_jurisdiction_hospitals(request)
    
    hospital = get_object_or_404(
        User := __import__('accounts.models', fromlist=['User']).User,
        id=hospital_id,
        role='hospital'
    )
    
    freeze_record = HospitalFreeze.objects.filter(
        hospital=hospital,
        status__in=['frozen', 'pending_review']
    ).order_by('-frozen_at').first()
    
    if not freeze_record:
        messages.error(request, "No active freeze found for this hospital.")
        return redirect('authority_hospitals')
    
    if request.method == 'POST':
        freeze_record.status = 'reactivated'
        freeze_record.reactivated_at = timezone.now()
        freeze_record.save()
        
        # Reactivate hospital user
        hospital.account_status = 'active'
        hospital.is_active = True
        hospital.save()
        
        # Create notification for hospital
        from accounts.models import Notification
        Notification.objects.create(
            recipient=hospital,
            title='Account Reactivated',
            message="Your hospital account has been reactivated after review.",
            link="/hospital/notifications/"
        )
        
        # Check settings
        authority_settings, _ = AuthoritySettings.objects.get_or_create(
            authority=request.user
        )
        
        # Create notification for authority if enabled
        if authority_settings.freeze_alerts:
            AuthorityNotification.objects.create(
                recipient=request.user,
                notification_type='unfreeze',
                title='Account Reactivated',
                message=f"You reactivated the account for {hospital.username}",
                freeze=freeze_record,
                link=f"/authority/hospitals/{hospital.id}/"
            )
        
        messages.success(request, f"Hospital {hospital.username} has been reactivated")
        return redirect('authority_hospitals')
    
    context = {
        'hospital': hospital,
        'freeze_record': freeze_record,
    }
    
    return render(request, "authorities/unfreeze_hospital.html", context)


@login_required
def authority_review_explanation(request, freeze_id):
    """Review explanation request from frozen hospital."""
    access_error = check_authority_access(request)
    if access_error:
        return access_error
    
    freeze_record = get_object_or_404(HospitalFreeze, id=freeze_id)
    
    if not freeze_record.explanation_received:
        messages.error(request, "No explanation received yet")
        return redirect('authority_hospitals')
    
    if request.method == 'POST':
        action = request.POST.get('action', '')
        
        if action == 'reactivate':
            freeze_record.status = 'reactivated'
            freeze_record.reactivated_at = timezone.now()
            freeze_record.save()
            
            hospital = freeze_record.hospital
            hospital.account_status = 'active'
            hospital.is_active = True
            hospital.save()
            
            # Deactivate all warnings
            HospitalWarning.objects.filter(
                hospital=hospital,
                is_active=True
            ).update(is_active=False)
            
            messages.success(request, f"Hospital has been reactivated")
        
        elif action == 'permanently_block':
            freeze_record.status = 'permanently_blocked'
            freeze_record.permanently_blocked_at = timezone.now()
            freeze_record.save()
            
            hospital = freeze_record.hospital
            hospital.account_status = 'blocked'
            hospital.is_active = False
            hospital.save()
            
            messages.error(request, "Hospital has been permanently blocked")
        
        return redirect('authority_hospitals')
    
    context = {
        'freeze_record': freeze_record,
    }
    
    return render(request, "authorities/review_explanation.html", context)


@login_required
def authority_notifications(request):
    """View all notifications."""
    access_error = check_authority_access(request)
    if access_error:
        return access_error
    
    notifications = AuthorityNotification.objects.filter(
        recipient=request.user
    ).order_by('-created_at')
    
    # Mark all as read
    notifications.filter(is_read=False).update(
        is_read=True,
        read_at=timezone.now()
    )
    
    context = {
        'notifications': notifications,
    }
    
    return render(request, "authorities/notifications.html", context)


@login_required
def authority_chat(request):
    """Redirect to the unified social chat."""
    access_error = check_authority_access(request)
    if access_error:
        return access_error
    return redirect('authority_chat_home')


@login_required
def authority_chat_detail(request, conversation_id):
    """Redirect to the unified social chat room."""
    access_error = check_authority_access(request)
    if access_error:
        return access_error
    return redirect('authority_chat_room', conversation_id=conversation_id)


@login_required
def authority_profile(request):
    """Authority profile page."""
    access_error = check_authority_access(request)
    if access_error:
        return access_error
    
    try:
        authority_profile = request.user.authority_profile
    except:
        authority_profile = None
    
    # Get complaint statistics for the jurisdiction
    from complaints.models import Complaint
    
    # Get hospitals under jurisdiction
    hospitals = get_authority_jurisdiction_hospitals(request)
    hospital_ids = hospitals.values_list('id', flat=True)
    
    # Get complaints statistics
    if hospital_ids:
        total_complaints = Complaint.objects.filter(hospital_id__in=hospital_ids).count()
        resolved_complaints = Complaint.objects.filter(hospital_id__in=hospital_ids, status='resolved').count()
        escalated_count = Complaint.objects.filter(hospital_id__in=hospital_ids, escalated_to_authority=True).count()
        pending_complaints = total_complaints - resolved_complaints
    else:
        total_complaints = 0
        resolved_complaints = 0
        escalated_count = 0
        pending_complaints = 0
    
    context = {
        'authority_profile': authority_profile,
        'total_complaints': total_complaints,
        'resolved_complaints': resolved_complaints,
        'pending_complaints': pending_complaints,
        'escalated_count': escalated_count,
    }
    
    return render(request, "authorities/profile.html", context)


@login_required
def authority_settings(request):
    """Authority settings page."""
    access_error = check_authority_access(request)
    if access_error:
        return access_error
    
    settings_obj, created = AuthoritySettings.objects.get_or_create(
        authority=request.user
    )
    
    if request.method == 'POST':
        action = request.POST.get('action', '')
        
        if action == 'update_notifications':
            settings_obj.email_notifications = 'email_notifications' in request.POST
            settings_obj.escalation_alerts = 'escalation_alerts' in request.POST
            settings_obj.warning_alerts = 'warning_alerts' in request.POST
            settings_obj.freeze_alerts = 'freeze_alerts' in request.POST
            settings_obj.save()
            messages.success(request, "Notification settings updated")
        
        elif action == 'update_thresholds':
            settings_obj.response_time_threshold = int(
                request.POST.get('response_time_threshold', 48)
            )
            settings_obj.view_time_threshold = int(
                request.POST.get('view_time_threshold', 24)
            )
            settings_obj.warning_threshold = int(
                request.POST.get('warning_threshold', 3)
            )
            settings_obj.save()
            messages.success(request, "Threshold settings updated")
        
        elif action == 'password':
            from django.contrib.auth.forms import PasswordChangeForm
            from django.contrib.auth import update_session_auth_hash
            password_form = PasswordChangeForm(request.user, request.POST)
            if password_form.is_valid():
                user = password_form.save()
                update_session_auth_hash(request, user)
                messages.success(request, "Password updated successfully.")
                return redirect("authority_settings")
            messages.error(request, "Please correct the password errors below.")
        
        # Only redirect if no password errors, otherwise render with form errors
        if action != 'password' or (action == 'password' and password_form.is_valid()):
            return redirect('authority_settings')
    
    # Initialize forms if not POST or if other action
    from django.contrib.auth.forms import PasswordChangeForm
    if 'password_form' not in locals():
        password_form = PasswordChangeForm(request.user)
        
    context = {
        'settings': settings_obj,
        'password_form': password_form,
    }
    
    return render(request, "authorities/settings.html", context)


@login_required
def authority_feed(request):
    """
    Read-only feed for authorities to view all complaints from patients.
    Authorities can only view complaints - no posting, commenting, or liking.
    """
    access_error = check_authority_access(request)
    if access_error:
        return access_error
    
    query = request.GET.get('q')
    
    # Get all public complaints (show_in_feed=True)
    # This gives authorities a broad view of issues in their society
    privacy_filter = Q(user__settings__show_in_feed=True) | Q(user__settings__isnull=True)
    
    complaints = Complaint.objects.filter(privacy_filter).prefetch_related(
        'hospital_responses', 'hospital_responses__hospital'
    ).order_by('-created_at')
    
    if query:
        # Search complaints
        complaint_filter = Q(title__icontains=query) | \
                           Q(description__icontains=query) | \
                           Q(hospital__username__icontains=query) | \
                           Q(hospital_name__icontains=query) | \
                           Q(category__icontains=query)
        
        complaints = complaints.filter(complaint_filter)
    
    context = {
        'complaints': complaints,
        'query': query,
    }
    
    return render(request, 'authorities/feed.html', context)





@login_required
def mark_notification_read(request, notification_id):
    """Mark a notification as read."""
    access_error = check_authority_access(request)
    if access_error:
        return access_error
    
    notification = get_object_or_404(
        AuthorityNotification,
        id=notification_id,
        recipient=request.user
    )
    
    notification.is_read = True
    notification.read_at = timezone.now()
    notification.save()
    
    # Redirect to link if exists
    if notification.link:
        return redirect(notification.link)
    elif notification.complaint:
        return redirect('authority_complaint_detail', notification.complaint.id)
    
    return redirect('authority_notifications')


def escalate_complaint(complaint_id):
    """
    Automated escalation logic.
    Call this from a management command or Celery task.
    """
    from accounts.models import User
    
    try:
        complaint = Complaint.objects.get(id=complaint_id)
        
        # Check if already escalated
        if complaint.escalated_to_authority:
            return
        
        # Get authority for this hospital's jurisdiction
        try:
            hospital_profile = complaint.hospital.hospital_profile
            authorities = User.objects.filter(
                role='authority',
                authority_profile__jurisdiction_state__iexact=hospital_profile.state
            )
            
            if hospital_profile.district:
                authorities = authorities.filter(
                    Q(authority_profile__jurisdiction_district__iexact=hospital_profile.district) |
                    Q(authority_profile__jurisdiction_district__isnull=True)
                )
        except:
            return
        
        if not authorities.exists():
            return
        
        # Escalate complaint
        complaint.escalated_to_authority = True
        complaint.status = 'escalated'
        complaint.escalated_at = timezone.now()
        complaint.save()
        
        # Create activity log
        ComplaintActivityLog.objects.create(
            complaint=complaint,
            activity_type='escalated',
            description="Complaint automatically escalated due to hospital inaction"
        )
        
        # Notify authorities
        for authority in authorities:
            AuthorityNotification.objects.create(
                recipient=authority,
                notification_type='escalation',
                title='Complaint Escalated',
                message=f"Complaint '{complaint.title}' has been escalated due to hospital inaction.",
                complaint=complaint
            )
        
    except Complaint.DoesNotExist:
        pass


def process_escalations():
    """
    Process all complaints for potential escalation.
    Run this as a scheduled task (Celery/management command).
    """
    from accounts.models import User as UserModel
    
    # Get all approved hospitals
    hospitals = UserModel.objects.filter(
        role='hospital',
        is_approved=True,
        is_active=True
    )
    
    for hospital in hospitals:
        # Get authority settings for this hospital's region
        try:
            hospital_profile = hospital.hospital_profile
            authority_settings_list = AuthoritySettings.objects.filter(
                authority__authority_profile__jurisdiction_state__iexact=hospital_profile.state
            )
            
            if not authority_settings_list.exists():
                continue
            
            # Use first matching authority's settings
            authority_settings = authority_settings_list.first()
        except:
            continue
        
        # Get complaints that need review
        threshold_time = timezone.now() - timedelta(
            hours=authority_settings.response_time_threshold
        )
        
        # Complaints not viewed by hospital
        unviewed = Complaint.objects.filter(
            hospital=hospital,
            escalated_to_authority=False,
            viewed_by_hospital=False,
            created_at__lt=threshold_time
        )
        
        for complaint in unviewed:
            escalate_complaint(complaint.id)
        
        # Complaints viewed but not responded
        view_threshold = timezone.now() - timedelta(
            hours=authority_settings.view_time_threshold
        )
        
        viewed_unresponded = Complaint.objects.filter(
            hospital=hospital,
            escalated_to_authority=False,
            viewed_by_hospital=True,
            hospital_responded_at__isnull=True,
            viewed_by_hospital_at__lt=view_threshold
        )
        
        for complaint in viewed_unresponded:
            escalate_complaint(complaint.id)
