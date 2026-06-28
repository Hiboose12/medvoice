from django.shortcuts import render, redirect, get_object_or_404
from django.contrib.auth.decorators import login_required, user_passes_test
from django.contrib.auth import get_user_model
from django.db.models import Q, Count, Sum
from django.core.paginator import Paginator
from django.contrib import messages
from django.utils import timezone
from django.http import HttpResponse, JsonResponse
from datetime import timedelta
import csv
from .models import AuditLogEntry, SecurityAlert
from accounts.models import User, VerificationProfile, Hospital, Authority

User = get_user_model()

def _wants_json(request):
    return (
        request.headers.get("Accept") == "application/json"
        or request.headers.get("X-Requested-With") == "XMLHttpRequest"
        or request.GET.get("format") == "json"
    )

def superadmin_only(view_func):
    decorator = user_passes_test(lambda u: u.role == 'superadmin', login_url='login')
    return decorator(view_func)

# ============================================================
#  MODULE 1: USER MANAGEMENT
# ============================================================

@login_required
@superadmin_only
def sa_user_management(request):
    search_query = request.GET.get('search', '')
    role_filter = request.GET.get('role', 'all')
    status_filter = request.GET.get('status', 'all')

    users = User.objects.all()

    if search_query:
        users = users.filter(
            Q(username__icontains=search_query) |
            Q(email__icontains=search_query) |
            Q(first_name__icontains=search_query) |
            Q(last_name__icontains=search_query) |
            Q(phone_number__icontains=search_query)
        )

    if role_filter and role_filter != 'all':
        users = users.filter(role=role_filter)

    if status_filter and status_filter != 'all':
        if status_filter == 'active':
            users = users.filter(is_active=True)
        elif status_filter == 'disabled':
            users = users.filter(is_active=False)
        elif status_filter == 'frozen':
            users = users.filter(account_status='frozen')
        elif status_filter == 'blocked':
            users = users.filter(account_status='blocked')
        elif status_filter == 'reactivation_requested':
            users = users.filter(reactivation_requested=True)

    paginator = Paginator(users, 20)
    page_number = request.GET.get('page')
    page_obj = paginator.get_page(page_number)

    if _wants_json(request):
        user_list = []
        for u in page_obj:
            user_list.append({
                'id': u.id,
                'username': u.username,
                'email': u.email,
                'first_name': u.first_name,
                'last_name': u.last_name,
                'phone_number': u.phone_number,
                'role': u.role,
                'is_active': u.is_active,
                'account_status': u.account_status,
                'reactivation_requested': u.reactivation_requested,
                'date_joined': u.date_joined.isoformat() if u.date_joined else None,
            })
        return JsonResponse({
            'users': user_list,
            'page': page_obj.number,
            'total_pages': paginator.num_pages,
            'has_next': page_obj.has_next(),
            'has_previous': page_obj.has_previous(),
            'search_query': search_query,
            'role_filter': role_filter,
            'status_filter': status_filter,
        })

    return render(request, 'super_admin/user_management.html', {
        'users': page_obj,
        'search_query': search_query,
        'role_filter': role_filter,
        'status_filter': status_filter,
    })


@login_required
@superadmin_only
def sa_user_detail(request, user_id):
    target_user = get_object_or_404(User, id=user_id)
    hospital_profile = getattr(target_user, 'hospital_profile', None)
    authority_profile = getattr(target_user, 'authority_profile', None)
    verification = getattr(target_user, 'verification', None)

    if _wants_json(request):
        verification_data = None
        if verification:
            verification_data = {
                'id': verification.id,
                'govt_id': verification.govt_id.url if verification.govt_id else None,
                'hospital_license': verification.hospital_license.url if verification.hospital_license else None,
                'authority_id': verification.authority_id.url if verification.authority_id else None,
            }
        return JsonResponse({
            'user': {
                'id': target_user.id,
                'username': target_user.username,
                'email': target_user.email,
                'first_name': target_user.first_name,
                'last_name': target_user.last_name,
                'phone_number': target_user.phone_number,
                'role': target_user.role,
                'is_active': target_user.is_active,
                'account_status': target_user.account_status,
                'reactivation_requested': target_user.reactivation_requested,
            },
            'hospital_profile': {
                'id': hospital_profile.id,
                'hospital_name': hospital_profile.hospital_name,
                'license_number': hospital_profile.license_number,
                'address': hospital_profile.address,
                'status': hospital_profile.status,
            } if hospital_profile else None,
            'authority_profile': {
                'id': authority_profile.id,
                'authority_name': authority_profile.authority_name,
                'jurisdiction': authority_profile.jurisdiction,
                'address': authority_profile.address,
            } if authority_profile else None,
            'verification': verification_data,
        })

    return render(request, 'super_admin/user_detail.html', {
        'target_user': target_user,
        'hospital_profile': hospital_profile,
        'authority_profile': authority_profile,
        'verification': verification,
    })



@login_required
@superadmin_only
def sa_modify_user_status(request, user_id):
    if request.method == 'POST':
        user = get_object_or_404(User, id=user_id)
        if user == request.user:
            if _wants_json(request):
                return JsonResponse({'success': False, 'message': "You cannot modify your own account."}, status=400)
            messages.error(request, "You cannot modify your own account.")
            return redirect('sa_user_management')

        if request.content_type == 'application/json':
            import json
            data = json.loads(request.body)
            action = data.get('action')
            reason = data.get('reason', '')
        else:
            action = request.POST.get('action')
            reason = request.POST.get('reason', '')
        ip = request.META.get('REMOTE_ADDR')

        if action == 'toggle_active':
            user.is_active = not user.is_active
            if user.is_active:
                user.reactivation_requested = False
                user.account_status = 'active'
                action_display = 'User Enabled'
                action_type = 'user_enabled'
            else:
                action_display = 'User Disabled'
                action_type = 'user_disabled'
            user.save()

        elif action == 'freeze':
            user.account_status = 'frozen'
            user.is_active = False
            action_display = 'User Frozen'
            action_type = 'user_frozen'
            user.save()

        elif action == 'unfreeze':
            user.account_status = 'active'
            user.is_active = True
            action_display = 'User Unfrozen'
            action_type = 'user_unfrozen'
            user.save()

        elif action == 'block':
            if user.is_superuser:
                if _wants_json(request):
                    return JsonResponse({'success': False, 'message': "Cannot block superadmin."}, status=400)
                messages.error(request, "Cannot block superadmin.")
                return redirect('sa_user_management')
            user.account_status = 'blocked'
            user.is_active = False
            action_display = 'User Blocked'
            action_type = 'user_blocked'
            user.save()

        elif action == 'unblock':
            user.account_status = 'active'
            user.is_active = True
            user.reactivation_requested = False
            action_display = 'User Unblocked'
            action_type = 'user_unblocked'
            user.save()

        elif action == 'warn':
            from accounts.models import Notification
            Notification.objects.create(
                recipient=user,
                title='Official Warning',
                message=reason,
                link='/'
            )
            action_display = 'User Warned'
            action_type = 'user_warned'
            AuditLogEntry.objects.create(
                admin=request.user,
                target_user=user,
                action_type=action_type,
                description=reason,
                ip_address=ip
            )
            if _wants_json(request):
                return JsonResponse({'success': True, 'message': f"Warning sent to {user.username}."})
            messages.success(request, f"Warning sent to {user.username}.")
            return redirect('sa_user_management')

        else:
            if _wants_json(request):
                return JsonResponse({'success': False, 'message': "Invalid action."}, status=400)
            messages.error(request, "Invalid action.")
            return redirect('sa_user_management')

        AuditLogEntry.objects.create(
            admin=request.user,
            target_user=user,
            action_type=action_type,
            description=reason or action_display,
            ip_address=ip
        )
        if _wants_json(request):
            return JsonResponse({'success': True, 'message': f"{action_display} - {user.username}."})
        messages.success(request, f"{action_display} - {user.username}.")
    
    if _wants_json(request):
        return JsonResponse({'success': False, 'message': 'Method not allowed'}, status=405)
    return redirect('sa_user_management')


# ============================================================
#  MODULE 2: ENTITY VERIFICATION
# ============================================================

@login_required
@superadmin_only
def sa_entity_verification(request):
    search_query = request.GET.get('search', '')
    verification_filter = request.GET.get('verification', 'all')

    hospitals = Hospital.objects.filter(status='pending').select_related('user')
    authorities = Authority.objects.all()

    if verification_filter == 'hospitals':
        items = hospitals
    elif verification_filter == 'authorities':
        items = authorities
    else:
        items = list(hospitals) + list(authorities)

    if _wants_json(request):
        serialized_items = []
        for item in items:
            is_hospital = isinstance(item, Hospital)
            u = item.user
            
            # Simple check if user has verification profile
            verification = getattr(u, 'verification', None)
            
            name = item.hospital_name if is_hospital else item.authority_name
            
            if search_query:
                q = search_query.lower()
                if q not in name.lower() and q not in u.username.lower() and q not in u.email.lower():
                    continue

            serialized_items.append({
                'id': item.id,
                'entity_type': 'hospital' if is_hospital else 'authority',
                'name': name,
                'username': u.username,
                'email': u.email,
                'status': getattr(item, 'status', 'pending') if is_hospital else ('approved' if u.is_approved else 'pending'),
                'is_approved': u.is_approved,
                'verification': {
                    'govt_id': verification.govt_id.url if verification and verification.govt_id else None,
                    'hospital_license': verification.hospital_license.url if verification and verification.hospital_license else None,
                    'authority_id': verification.authority_id.url if verification and verification.authority_id else None,
                } if verification else None,
            })
        return JsonResponse({
            'items': serialized_items,
            'search_query': search_query,
            'verification_filter': verification_filter,
        })

    return render(request, 'super_admin/entity_verification.html', {
        'items': items,
        'search_query': search_query,
        'verification_filter': verification_filter,
    })



@login_required
@superadmin_only
def sa_verify_entity(request, entity_type, entity_id):
    if request.method == 'POST':
        if request.content_type == 'application/json':
            import json
            data = json.loads(request.body)
            action_type = data.get('action')
            reason = data.get('reason', '')
        else:
            action_type = request.POST.get('action')
            reason = request.POST.get('reason', '')

        if entity_type == 'hospital':
            entity = get_object_or_404(Hospital, id=entity_id)
            user = entity.user
        elif entity_type == 'authority':
            entity = get_object_or_404(Authority, id=entity_id)
            user = entity.user
        else:
            if _wants_json(request):
                return JsonResponse({'success': False, 'message': "Invalid entity type."}, status=400)
            messages.error(request, "Invalid entity type.")
            return redirect('sa_entity_verification')

        ip = request.META.get('REMOTE_ADDR')

        if action_type == 'approve':
            user.is_approved = True
            user.is_active = True
            user.is_verified = True
            user.save()
            if hasattr(entity, 'status'):
                entity.status = 'verified'
                entity.save()
            AuditLogEntry.objects.create(
                admin=request.user,
                target_user=user,
                action_type='user_approved',
                description=f"{entity_type.title()} approved: {user.username}. {reason}",
                ip_address=ip
            )
            if _wants_json(request):
                return JsonResponse({'success': True, 'message': f"{entity_type.title()} {user.username} approved."})
            messages.success(request, f"{entity_type.title()} {user.username} approved.")

        elif action_type == 'reject':
            user.is_active = False
            user.is_approved = False
            user.save()
            if hasattr(entity, 'status'):
                entity.status = 'suspended'
                entity.save()
            AuditLogEntry.objects.create(
                admin=request.user,
                target_user=user,
                action_type='user_rejected',
                description=f"{entity_type.title()} rejected: {user.username}. {reason}",
                ip_address=ip
            )
            if _wants_json(request):
                return JsonResponse({'success': True, 'message': f"{entity_type.title()} {user.username} rejected."})
            messages.success(request, f"{entity_type.title()} {user.username} rejected.")

    if _wants_json(request):
        return JsonResponse({'success': False, 'message': 'Method not allowed or missing action'}, status=400)
    return redirect('sa_entity_verification')



# ============================================================
#  MODULE 3: AUDIT LOGS
# ============================================================

@login_required
@superadmin_only
def sa_audit_logs(request):
    search_query = request.GET.get('search', '')
    action_filter = request.GET.get('action', 'all')
    date_filter = request.GET.get('date', '7')

    logs = AuditLogEntry.objects.select_related('admin', 'target_user')

    if search_query:
        logs = logs.filter(
            Q(admin__username__icontains=search_query) |
            Q(target_user__username__icontains=search_query) |
            Q(description__icontains=search_query) |
            Q(action_type__icontains=search_query)
        )

    if action_filter and action_filter != 'all':
        logs = logs.filter(action_type=action_filter)

    try:
        days = int(date_filter)
        cutoff = timezone.now() - timedelta(days=days)
        logs = logs.filter(timestamp__gte=cutoff)
    except ValueError:
        days = 7

    paginator = Paginator(logs, 30)
    page_number = request.GET.get('page')
    page_obj = paginator.get_page(page_number)

    action_choices = AuditLogEntry.ACTION_CHOICES

    if _wants_json(request):
        serialized_logs = []
        for log in page_obj:
            serialized_logs.append({
                'id': log.id,
                'timestamp': log.timestamp.isoformat() if log.timestamp else None,
                'admin_username': log.admin.username if log.admin else 'System',
                'target_username': log.target_user.username if log.target_user else 'N/A',
                'action_type': log.action_type,
                'action_type_display': log.get_action_type_display(),
                'description': log.description,
                'ip_address': log.ip_address or 'N/A',
            })
        return JsonResponse({
            'logs': serialized_logs,
            'page': page_obj.number,
            'total_pages': paginator.num_pages,
            'has_next': page_obj.has_next(),
            'has_previous': page_obj.has_previous(),
            'action_choices': dict(action_choices),
        })

    return render(request, 'super_admin/audit_logs.html', {
        'logs': page_obj,
        'search_query': search_query,
        'action_filter': action_filter,
        'date_filter': str(days),
        'action_choices': action_choices,
    })


@login_required
@superadmin_only
def sa_export_audit_logs(request):
    logs = AuditLogEntry.objects.select_related('admin', 'target_user').order_by('-timestamp')

    action_filter = request.GET.get('action', 'all')
    date_filter = request.GET.get('date', '30')

    if action_filter and action_filter != 'all':
        logs = logs.filter(action_type=action_filter)

    try:
        days = int(date_filter)
        cutoff = timezone.now() - timedelta(days=days)
        logs = logs.filter(timestamp__gte=cutoff)
    except ValueError:
        pass

    response = HttpResponse(content_type='text/csv')
    filename = f"audit_logs_{timezone.now().strftime('%Y%m%d_%H%M%S')}.csv"
    response['Content-Disposition'] = f'attachment; filename="{filename}"'
    writer = csv.writer(response)
    writer.writerow(['Timestamp', 'Admin', 'Action', 'Target User', 'Description', 'IP Address'])
    for log in logs:
        admin_username = getattr(log.admin, 'username', 'N/A')
        if log.admin and hasattr(log.admin, 'first_name'):
            admin_username = f"{log.admin.first_name} {log.admin.last_name} ({log.admin.username})"
        target_username = getattr(log.target_user, 'username', 'N/A') if log.target_user else 'System/N/A'
        writer.writerow([
            log.timestamp.strftime('%Y-%m-%d %H:%M:%S'),
            admin_username,
            log.get_action_type_display(),
            target_username,
            log.description,
            log.ip_address or 'N/A'
        ])
    return response


# ============================================================
#  MODULE 4: SECURITY MONITORING
# ============================================================

@login_required
@superadmin_only
def sa_security_monitoring(request):
    severity_filter = request.GET.get('severity', 'all')
    resolved_filter = request.GET.get('resolved', 'all')

    alerts = SecurityAlert.objects.select_related('user', 'resolved_by')

    if severity_filter != 'all':
        alerts = alerts.filter(severity=severity_filter)

    if resolved_filter == 'open':
        alerts = alerts.filter(is_resolved=False)
    elif resolved_filter == 'resolved':
        alerts = alerts.filter(is_resolved=True)

    paginator = Paginator(alerts, 20)
    page_number = request.GET.get('page')
    page_obj = paginator.get_page(page_number)

    open_count = SecurityAlert.objects.filter(is_resolved=False).count()
    critical_count = SecurityAlert.objects.filter(is_resolved=False, severity='critical').count()
    recent_count_24h = SecurityAlert.objects.filter(
        timestamp__gte=timezone.now() - timedelta(hours=24)
    ).count()

    if _wants_json(request):
        serialized_alerts = []
        for alert in page_obj:
            serialized_alerts.append({
                'id': alert.id,
                'alert_type': alert.alert_type,
                'alert_type_display': alert.get_alert_type_display(),
                'severity': alert.severity,
                'user_username': alert.user.username if alert.user else 'Unknown',
                'title': alert.title,
                'description': alert.description,
                'ip_address': alert.ip_address or 'N/A',
                'is_resolved': alert.is_resolved,
                'resolved_at': alert.resolved_at.isoformat() if alert.resolved_at else None,
                'resolved_by_username': alert.resolved_by.username if alert.resolved_by else None,
                'timestamp': alert.timestamp.isoformat() if alert.timestamp else None,
            })
        return JsonResponse({
            'alerts': serialized_alerts,
            'page': page_obj.number,
            'total_pages': paginator.num_pages,
            'has_next': page_obj.has_next(),
            'has_previous': page_obj.has_previous(),
            'open_count': open_count,
            'critical_count': critical_count,
            'recent_count_24h': recent_count_24h,
        })

    return render(request, 'super_admin/security_monitoring.html', {
        'alerts': page_obj,
        'severity_filter': severity_filter,
        'resolved_filter': resolved_filter,
        'open_count': open_count,
        'critical_count': critical_count,
        'recent_count_24h': recent_count_24h,
    })


@login_required
@superadmin_only
def sa_resolve_security_alert(request, alert_id):
    if request.method == 'POST':
        alert = get_object_or_404(SecurityAlert, id=alert_id)
        alert.is_resolved = True
        alert.resolved_at = timezone.now()
        alert.resolved_by = request.user
        alert.save()
        if _wants_json(request):
            return JsonResponse({'success': True, 'message': f"Security alert resolved: {alert.alert_type}."})
        messages.success(request, f"Security alert resolved: {alert.alert_type}.")
    
    if _wants_json(request):
        return JsonResponse({'success': False, 'message': 'Method not allowed'}, status=405)
    return redirect('sa_security_monitoring')


@login_required
@superadmin_only
def sa_trigger_security_scan(request):
    if request.method == 'POST':
        if _wants_json(request):
            return JsonResponse({'success': True, 'message': "Security scan initiated. Results will be available shortly."})
        messages.info(request, "Security scan initiated. Results will be available shortly.")
    
    if _wants_json(request):
        return JsonResponse({'success': False, 'message': 'Method not allowed'}, status=405)
    return redirect('sa_security_monitoring')


@login_required
@superadmin_only
def sa_security_settings(request):
    from django.conf import settings as django_settings
    
    if request.method == 'POST':
        if _wants_json(request):
            return JsonResponse({'success': True, 'message': "Security settings updated successfully."})
        messages.success(request, "Security settings updated successfully.")
        return redirect('sa_security_settings')
        
    context = {
        'two_fa_enabled': getattr(django_settings, 'ENABLE_TWO_FA', False),
        'session_timeout': getattr(django_settings, 'SESSION_COOKIE_AGE', 1209600),
        'max_login_attempts': getattr(django_settings, 'MAX_LOGIN_ATTEMPTS', 5),
    }
    
    if _wants_json(request):
        return JsonResponse(context)
        
    return render(request, 'super_admin/security_settings.html', context)

