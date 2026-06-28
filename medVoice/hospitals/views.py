from django.shortcuts import render, redirect, get_object_or_404
from django.db.models import Q
from django.contrib.auth.decorators import login_required
from django.contrib import messages
from django.contrib.auth.forms import PasswordChangeForm
from django.contrib.auth import update_session_auth_hash
from django.utils import timezone
from django.conf import settings
from django.urls import reverse
from django.http import HttpResponse, JsonResponse
import csv
import re
from accounts.models import Notification, User
from accounts.forms import HospitalProfileForm, ProfileUpdateForm, UserUpdateForm
from complaints.models import Complaint
from .decorators import check_hospital_freeze

def _escalate_overdue_complaints(hospital):
    hours = getattr(settings, "HOSPITAL_RESPONSE_ESCALATION_HOURS", 48)
    cutoff = timezone.now() - timezone.timedelta(hours=hours)

    overdue = Complaint.objects.filter(
        hospital=hospital,
        status__in=["new", "review"],
        hospital_responded_at__isnull=True,
        created_at__lte=cutoff,
        escalated_to_authority=False,
    )

    if not overdue.exists():
        return 0

    authority_users = User.objects.filter(role="authority", is_approved=True)
    now = timezone.now()
    for complaint in overdue:
        complaint.escalated_to_authority = True
        complaint.escalated_at = now
        complaint.save(update_fields=["escalated_to_authority", "escalated_at"])

        for authority in authority_users:
            Notification.objects.create(
                recipient=authority,
                title="Complaint escalated for review",
                message=f"Complaint #{complaint.id} has not been addressed within {hours} hours.",
                link=reverse("complaint_detail", args=[complaint.id]),
            )

    return overdue.count()


@login_required
@check_hospital_freeze
def hospital_dashboard(request):
    if request.user.role.lower() != "hospital":
        return redirect("login")

    if not request.user.is_approved:
        return redirect("pending_approval")
    
    complaints = Complaint.objects.filter(hospital=request.user)
    _escalate_overdue_complaints(request.user)

    hospital_profile = getattr(request.user, "hospital_profile", None)
    display_name = None
    display_email = None
    if hospital_profile:
        display_name = hospital_profile.hospital_name or None
        display_email = hospital_profile.email or None
    display_name = display_name or request.user.get_full_name() or request.user.username
    display_name = display_name or request.user.get_full_name() or request.user.username
    display_email = display_email or request.user.email
    
    # Check for freeze status
    from authorities.models import HospitalFreeze
    current_freeze = HospitalFreeze.objects.filter(
        hospital=request.user, 
        status='frozen'
    ).first()
    
    context = {
        "hospital_profile": hospital_profile,
        "display_name": display_name,
        "display_email": display_email,
        "total_complaints": complaints.count(),
        "open_complaints": complaints.filter(status="new").count(),
        "active_complaints": complaints.filter(status="review").count(),
        "responded_complaints": complaints.filter(status="responded").count(),
        "resolved_complaints": complaints.filter(status="resolved").count(),
        "recent_complaints": complaints.order_by("-created_at")[:5],
        "notifications": Notification.objects.filter(recipient=request.user).order_by("-created_at")[:5],
        "unread_notifications": Notification.objects.filter(recipient=request.user, is_read=False).count(),
        "current_freeze": current_freeze,
    }

    if request.headers.get('Accept') == 'application/json' or request.GET.get('format') == 'json':
        recent_list = []
        for c in context["recent_complaints"]:
            recent_list.append({
                'id': c.id,
                'title': c.title,
                'description': c.description,
                'status': c.status,
                'created_at': c.created_at.isoformat(),
                'category': c.category,
                'severity': c.severity,
                'escalated': c.escalated_to_authority,
            })
        return JsonResponse({
            "display_name": display_name,
            "display_email": display_email,
            "total_complaints": context["total_complaints"],
            "open_complaints": context["open_complaints"],
            "active_complaints": context["active_complaints"],
            "responded_complaints": context["responded_complaints"],
            "resolved_complaints": context["resolved_complaints"],
            "recent_complaints": recent_list,
            "unread_notifications": context["unread_notifications"],
            "is_frozen": current_freeze is not None,
        })

    return render(request, "hospitals/dashboard.html", context)


@login_required
@check_hospital_freeze
def hospital_profile(request):
    if request.user.role.lower() != "hospital":
        return redirect("login")

    if not request.user.is_approved:
        return redirect("pending_approval")

    hospital_profile = getattr(request.user, "hospital_profile", None)
    return render(
        request,
        "hospitals/profile.html",
        {
            "hospital_profile": hospital_profile,
            "profile": getattr(request.user, "profile", None),
        }
    )

@login_required
@check_hospital_freeze
def hospital_complaints(request):
    if request.user.role.lower() != "hospital":
        return redirect("login")

    if not request.user.is_approved:
        return redirect("pending_approval")

    status_filter = request.GET.get('status', 'all')
    complaints = Complaint.objects.filter(hospital=request.user)
    _escalate_overdue_complaints(request.user)
    
    if status_filter != 'all':
        if status_filter == 'investigating':
            complaints = complaints.filter(status='review')
        else:
            complaints = complaints.filter(status=status_filter)

    complaints = complaints.order_by("-created_at")

    context = {
        "complaints": complaints,
        "current_status": status_filter,
        "new_count": Complaint.objects.filter(hospital=request.user, status='new').count(),
        "review_count": Complaint.objects.filter(hospital=request.user, status='review').count(),
        "responded_count": Complaint.objects.filter(hospital=request.user, status='responded').count(),
        "resolved_count": Complaint.objects.filter(hospital=request.user, status='resolved').count(),
        "total_count": Complaint.objects.filter(hospital=request.user).count(),
    }

    if request.headers.get('Accept') == 'application/json' or request.GET.get('format') == 'json':
        complaints_list = []
        for c in complaints:
            complaints_list.append({
                'id': c.id,
                'title': c.title,
                'description': c.description,
                'status': c.status,
                'created_at': c.created_at.isoformat(),
                'category': c.category,
                'severity': c.severity,
                'escalated': c.escalated_to_authority,
            })
        return JsonResponse({
            "complaints": complaints_list,
            "new_count": context["new_count"],
            "review_count": context["review_count"],
            "responded_count": context["responded_count"],
            "resolved_count": context["resolved_count"],
            "total_count": context["total_count"],
        })

    return render(
        request,
        "hospitals/complaints.html",
        context
    )
@login_required
@check_hospital_freeze
def hospital_reports(request):
    if request.user.role.lower() != "hospital":
        return redirect("login")
    return render(request, "hospitals/reports.html")


@login_required
@check_hospital_freeze
def hospital_reports_export(request):
    if request.user.role.lower() != "hospital":
        return redirect("login")
    if not request.user.is_approved:
        return redirect("pending_approval")

    complaints = Complaint.objects.filter(hospital=request.user).order_by("-created_at")

    response = HttpResponse(content_type="text/csv")
    response["Content-Disposition"] = "attachment; filename=complaints_report.csv"
    writer = csv.writer(response)
    writer.writerow(["ID", "Title", "Status", "Created At", "Patient", "Severity"])
    for complaint in complaints:
        writer.writerow([
            complaint.id,
            complaint.title,
            complaint.get_status_display(),
            complaint.created_at.strftime("%Y-%m-%d %H:%M"),
            complaint.user.username,
            complaint.severity,
        ])

    return response

@login_required
@check_hospital_freeze
def hospital_settings(request):
    if request.user.role.lower() != "hospital":
        return redirect("login")
    if not request.user.is_approved:
        return redirect("pending_approval")

    hospital_profile = getattr(request.user, "hospital_profile", None)
    profile = getattr(request.user, "profile", None)

    hospital_form = HospitalProfileForm(request.POST or None, instance=hospital_profile)
    user_form = UserUpdateForm(request.POST or None, instance=request.user)
    profile_form = ProfileUpdateForm(request.POST or None, request.FILES or None, instance=profile)
    password_form = PasswordChangeForm(request.user, request.POST or None)

    if request.method == "POST":
        action = request.POST.get("action")

        if action == "profile":
            if hospital_form.is_valid() and user_form.is_valid() and profile_form.is_valid():
                hospital_instance = hospital_form.save(commit=False)
                if not hospital_instance.user_id:
                    hospital_instance.user = request.user
                hospital_instance.save()
                user_form.save()
                profile_form.save()
                messages.success(request, "Profile updated successfully.")
                return redirect("hospital_settings")
            messages.error(request, "Please correct the profile errors below.")

        elif action == "password":
            if password_form.is_valid():
                user = password_form.save()
                update_session_auth_hash(request, user)
                messages.success(request, "Password updated successfully.")
                return redirect("hospital_settings")
            messages.error(request, "Please correct the password errors below.")

    return render(
        request,
        "hospitals/settings.html",
        {
            "hospital_profile": hospital_profile,
            "profile": profile,
            "hospital_form": hospital_form,
            "user_form": user_form,
            "profile_form": profile_form,
            "password_form": password_form,
        }
    )

@login_required
@check_hospital_freeze
def hospital_feed(request):
    if request.user.role.lower() != "hospital":
        return redirect("login")
    
    if not request.user.is_approved:
        return redirect("pending_approval")

    query = request.GET.get('q')

    # Fetch all complaints 
    # Logic similar to patient feed but for hospitals
    # Hospitals can see all complaints except those that might be strictly private (if any logic exists, but requirement says "View ALL public complaints")
    
    # 🔒 Privacy Filter? 
    # Requirement: "View ALL public complaints"
    # Existing patient feed uses: privacy_filter = Q(user__settings__show_in_feed=True) | Q(user__settings__isnull=True) ...
    # We should probably respect the patient's privacy setting 'show_in_feed' unless it's THEIR complaint against THIS hospital?
    # Requirement says "View ALL public complaints". 'Public' implies 'show_in_feed=True'.
    # ALSO "Clearly highlight complaints raised against THEIR hospital" -> This implies they should see them even if not public? 
    # Usually, if a patient complains against a hospital, the hospital SHOULD see it.
    # Let's stick to "Public" complaints for general feed, AND complaints against THIS hospital (even if private/not in feed? usually those are in 'Dashboard').
    # For a 'Feed', let's show Public complaints + Any complaint against THIS hospital.
    
    privacy_filter = Q(user__settings__show_in_feed=True) | Q(user__settings__isnull=True) | Q(hospital=request.user)
    
    complaints = Complaint.objects.filter(privacy_filter).prefetch_related(
        'hospital_responses', 'hospital_responses__hospital'
    ).order_by('-created_at')

    if query:
        # 🔍 Search Users
        users = User.objects.filter(
            Q(username__icontains=query) |
            Q(first_name__icontains=query) |
            Q(last_name__icontains=query)
        )[:5]

        # 🔍 Construct Query
        complaint_filter = Q(title__icontains=query) | \
                           Q(description__icontains=query) | \
                           Q(hospital__username__icontains=query) | \
                           Q(category__icontains=query)
        
        complaints = complaints.filter(complaint_filter)

    else:
        users = User.objects.none()

    return render(request, 'hospitals/feed.html', {
        'complaints': complaints,
        'users': users,
        'query': query
    })

@login_required
@check_hospital_freeze
def hospital_notifications(request):
    if request.user.role.lower() != "hospital":
        return redirect("login")
    if not request.user.is_approved:
        return redirect("pending_approval")
        
    notifications = Notification.objects.filter(recipient=request.user).order_by("-created_at")
    
    # Auto-read logic on page view? 
    # The requirement says "Automatically mark as read when opened". 
    # Usually this means when the specific notification is clicked/opened.
    # However, simply visiting the "All Notifications" page often marks them as read in many systems?
    # No, usually you want to keep them unread until clicked.
    # BUT, to keep it simple and because "opened" can mean "opened the list", 
    # let's stick to the "click" behavior.
    # We will implement a small JS or link that hits a "mark read" endpoint, OR just let the destination page handle it.
    # The requirement Part 2 says "Auto Mark-as-Read (VERY IMPORTANT) ... When the receiver Opens the chat conversation". 
    # Part 4 says "Each notification must ... Automatically mark as read when opened". 
    # This implies clicking the notification.
    # We can handle this by making the link go to a proxy view that marks read then redirects.
    # OR we can just rely on the destination page (like Chat) to mark it read.
    # But for "New complaint" notifications, the complaint detail page might not have auto-read logic yet.
    # Let's add a robust `notification/read/<id>/` view to handle "mark read and redirect".

    return render(request, "hospitals/notifications.html", {"notifications": notifications})


@login_required
def submit_appeal(request):
    """View for frozen hospitals to submit an appeal/explanation."""
    if request.user.role.lower() != "hospital":
        return redirect("login")
    
    # Check if hospital is actually frozen
    # Check if hospital is actually frozen
    from authorities.models import HospitalFreeze
    freeze_record = HospitalFreeze.objects.filter(
        hospital=request.user
    ).order_by('-frozen_at').first()
    
    if not freeze_record or freeze_record.status not in ['frozen', 'pending_review', 'permanently_blocked']:
        messages.info(request, "Your account is not currently frozen.")
        return redirect("hospital_dashboard")
        
    if request.method == 'POST':
        if freeze_record.status == 'frozen':
            explanation = request.POST.get('explanation', '').strip()
            evidence = request.FILES.get('evidence')
            
            if not explanation:
                messages.error(request, "Please provide an explanation.")
                return redirect('submit_appeal')
                
            # Update freeze record
            freeze_record.explanation_requested = True
            freeze_record.explanation_received = True
            freeze_record.explanation_text = explanation
            if evidence:
                freeze_record.explanation_evidence = evidence
            freeze_record.explanation_submitted_at = timezone.now()
            freeze_record.status = 'pending_review'
            freeze_record.save()
            
            # Notify based on who froze the hospital
            frozen_by_user = freeze_record.frozen_by
            
            if frozen_by_user:
                if frozen_by_user.role == 'superadmin':
                    # Notify admin
                    from accounts.models import Notification
                    Notification.objects.create(
                        recipient=frozen_by_user,
                        title="Hospital Appeal Received",
                        message=f"Hospital {request.user.username} has submitted an appeal for their frozen account.",
                        link=reverse("admin_user_activity", args=[request.user.id])
                    )
                elif frozen_by_user.role == 'authority':
                    # Notify authority
                    from authorities.models import AuthorityNotification
                    AuthorityNotification.objects.create(
                        recipient=frozen_by_user,
                        notification_type='explanation',
                        title="Appeal Received",
                        message=f"Hospital {request.user.username} has submitted an appeal for their frozen account.",
                        freeze=freeze_record,
                        link=reverse("authority_review_explanation", args=[freeze_record.id])
                    )
            else:
                # Fallback: notify the assigned authority if any
                if hasattr(request.user, 'hospital_profile') and request.user.hospital_profile.authority:
                    authority_user = request.user.hospital_profile.authority.user
                    from authorities.models import AuthorityNotification
                    AuthorityNotification.objects.create(
                        recipient=authority_user,
                        notification_type='explanation',
                        title="Appeal Received",
                        message=f"Hospital {request.user.username} has submitted an appeal for their frozen account.",
                        freeze=freeze_record,
                        link=reverse("authority_review_explanation", args=[freeze_record.id])
                    )
            
            messages.success(request, "Your appeal has been submitted for review.")
            # Stay on the same page, do not redirect to blocked dashboard
            return redirect("submit_appeal")
            
    return render(request, "hospitals/submit_appeal.html", {'freeze_record': freeze_record})
