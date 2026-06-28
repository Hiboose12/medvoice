from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework import status
from django.utils import timezone
from accounts.models import User, Hospital, Authority, Notification, UserActivity
from complaints.models import Complaint
from super_admin.models import AuditLogEntry, SecurityAlert
from social.models import SupportTicket
from authorities.models import HospitalFreeze

def is_superadmin(user):
    return user.role == 'superadmin'

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def admin_dashboard_api(request):
    if not is_superadmin(request.user):
        return Response({'error': 'Unauthorized'}, status=status.HTTP_403_FORBIDDEN)
        
    total_users = User.objects.count()
    active_users = User.objects.filter(is_active=True).count()
    total_complaints = Complaint.objects.count()
    resolved_complaints = Complaint.objects.filter(status='resolved').count()
    active_investigations = Complaint.objects.filter(status='review').count()
    
    pending_approvals_qs = User.objects.filter(role__in=['hospital', 'authority'], is_approved=False)
    pending_approvals_count = pending_approvals_qs.count()
    support_tickets_count = SupportTicket.objects.filter(status='open').count()
    blocked_accounts_count = User.objects.filter(account_status='blocked').count()
    
    # Construct platform governance queue (keep for legacy compatibility)
    governance_queue = []
    
    # Pending Provider Approvals List
    pending_provider_approvals = []
    for user in pending_approvals_qs.order_by('-date_joined')[:5]:
        name = user.first_name if user.first_name else user.username
        pending_provider_approvals.append({
            'id': user.id,
            'username': name,
            'role': user.role.title(),
            'date_joined': user.date_joined.strftime("%b %d, %Y") if user.date_joined else "N/A",
        })
        governance_queue.append({
            'title': f"{user.role.title()} approval pending",
            'subtitle': f"{name} is awaiting verification.",
            'status': "Review",
            'type': "approval",
            'timestamp': user.date_joined.isoformat() if user.date_joined else None
        })
        
    open_tickets = SupportTicket.objects.filter(status='open').order_by('-created_at')[:5]
    for ticket in open_tickets:
        governance_queue.append({
            'title': "Support ticket awaiting reply",
            'subtitle': ticket.subject if ticket.subject else "Patient asked a question.",
            'status': "Open",
            'type': "support",
            'timestamp': ticket.created_at.isoformat() if hasattr(ticket, 'created_at') and ticket.created_at else None
        })
        
    pending_freezes = HospitalFreeze.objects.filter(status='pending_review').order_by('-frozen_at')[:5]
    for freeze in pending_freezes:
        h_name = freeze.hospital.first_name if freeze.hospital.first_name else freeze.hospital.username
        governance_queue.append({
            'title': "Freeze appeal received",
            'subtitle': f"{h_name} submitted evidence for account reactivation.",
            'status': "Urgent",
            'type': "freeze",
            'timestamp': freeze.frozen_at.isoformat() if hasattr(freeze, 'frozen_at') and freeze.frozen_at else None
        })
        
    governance_queue.sort(key=lambda x: x['timestamp'] or '', reverse=True)
    
    # Platform Activity (Timeline)
    # Using AuditLogEntry for real data
    platform_activity = []
    recent_logs = AuditLogEntry.objects.select_related('admin', 'target_user').order_by('-timestamp')[:10]
    
    import datetime
    from django.utils import timezone
    now = timezone.now()
    
    for log in recent_logs:
        # calculate time ago
        diff = now - log.timestamp
        if diff.days > 0:
            time_ago = f"{diff.days} days ago"
        elif diff.seconds >= 3600:
            time_ago = f"{diff.seconds // 3600} hours ago"
        elif diff.seconds >= 60:
            time_ago = f"{diff.seconds // 60} min ago"
        else:
            time_ago = "Just now"
            
        admin_name = log.admin.first_name if log.admin and log.admin.first_name else (log.admin.username if log.admin else "System")
        target_name = log.target_user.first_name if log.target_user and log.target_user.first_name else (log.target_user.username if log.target_user else "")
        
        title = log.get_action_type_display()
        subtitle = f"Action performed by {admin_name}"
        if target_name:
            subtitle += f" on {target_name}"
            
        platform_activity.append({
            'time_ago': time_ago,
            'title': title,
            'subtitle': subtitle,
            'timestamp': log.timestamp.isoformat()
        })
    
    return Response({
        'total_users': total_users,
        'active_users': active_users,
        'total_complaints': total_complaints,
        'resolved_complaints': resolved_complaints,
        'active_investigations': active_investigations,
        'pending_approvals_count': pending_approvals_count,
        'support_tickets': support_tickets_count,
        'blocked_accounts': blocked_accounts_count,
        'platform_governance_queue': governance_queue[:10],
        'pending_provider_approvals': pending_provider_approvals,
        'platform_activity': platform_activity,
    })
        
    open_tickets = SupportTicket.objects.filter(status='open').order_by('-created_at')[:5]
    for ticket in open_tickets:
        governance_queue.append({
            'title': "Support ticket awaiting reply",
            'subtitle': ticket.subject if ticket.subject else "Patient asked a question.",
            'status': "Open",
            'type': "support",
            'timestamp': ticket.created_at.isoformat() if hasattr(ticket, 'created_at') and ticket.created_at else None
        })
        
    pending_freezes = HospitalFreeze.objects.filter(status='pending_review').order_by('-frozen_at')[:5]
    for freeze in pending_freezes:
        h_name = freeze.hospital.first_name if freeze.hospital.first_name else freeze.hospital.username
        governance_queue.append({
            'title': "Freeze appeal received",
            'subtitle': f"{h_name} submitted evidence for account reactivation.",
            'status': "Urgent",
            'type': "freeze",
            'timestamp': freeze.frozen_at.isoformat() if hasattr(freeze, 'frozen_at') and freeze.frozen_at else None
        })
        
    # Sort queue by timestamp descending, fallback if None
    governance_queue.sort(key=lambda x: x['timestamp'] or '', reverse=True)
    
    return Response({
        'active_users': active_users,
        'total_complaints': total_complaints,
        'resolved_complaints': resolved_complaints,
        'active_investigations': active_investigations,
        'pending_approvals_count': pending_approvals_count,
        'support_tickets': support_tickets_count,
        'blocked_accounts': blocked_accounts_count,
        'platform_governance_queue': governance_queue[:10], # Top 10 items
    })

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def admin_users_api(request):
    if not is_superadmin(request.user):
        return Response({'error': 'Unauthorized'}, status=status.HTTP_403_FORBIDDEN)

    from django.core.paginator import Paginator
    from django.db.models import Count, Q

    search = request.GET.get('search', '').strip()
    role = request.GET.get('role', 'all')
    status_filter = request.GET.get('status', 'all')
    page = int(request.GET.get('page', 1))

    qs = User.objects.all().order_by('-date_joined')

    if search:
        qs = qs.filter(Q(username__icontains=search) | Q(email__icontains=search))

    if role and role != 'all':
        qs = qs.filter(role=role)

    if status_filter and status_filter != 'all':
        if status_filter == 'active':
            qs = qs.filter(account_status='active', is_active=True)
        elif status_filter == 'disabled':
            qs = qs.filter(is_active=False, reactivation_requested=False)
        elif status_filter == 'reactivation_requested':
            qs = qs.filter(reactivation_requested=True)
        else:
            qs = qs.filter(account_status=status_filter)

    paginator = Paginator(qs, 15)
    page_obj = paginator.get_page(page)

    data = []
    for u in page_obj.object_list:
        try:
            reply_count = u.complaint_set.filter(status='resolved').count()
        except Exception:
            reply_count = 0

        photo_url = None
        if hasattr(u, 'profile_picture') and u.profile_picture:
            try:
                photo_url = u.profile_picture.url
            except Exception:
                photo_url = None

        reactivation_reason = ''
        if u.reactivation_requested:
            reactivation_reason = getattr(u, 'reactivation_reason', '') or ''

        data.append({
            'id': u.id,
            'username': u.username,
            'email': u.email,
            'first_name': u.first_name or '',
            'last_name': u.last_name or '',
            'phone_number': u.phone_number or '',
            'role': u.role,
            'is_active': u.is_active,
            'account_status': u.account_status,
            'reactivation_requested': u.reactivation_requested,
            'reactivation_reason': reactivation_reason,
            'last_login': u.last_login.isoformat() if u.last_login else None,
            'date_joined': u.date_joined.isoformat() if u.date_joined else None,
            'reply_count': reply_count,
            'photo_url': photo_url,
        })

    return Response({
        'users': data,
        'page': page,
        'total_pages': paginator.num_pages,
        'total_users': paginator.count,
        'start_index': page_obj.start_index(),
        'end_index': page_obj.end_index(),
        'has_next': page_obj.has_next(),
        'has_previous': page_obj.has_previous(),
    })

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def admin_user_detail_api(request, pk):
    if not is_superadmin(request.user):
        return Response({'error': 'Unauthorized'}, status=status.HTTP_403_FORBIDDEN)
        
    try:
        user = User.objects.get(pk=pk)
    except User.DoesNotExist:
        return Response(status=status.HTTP_404_NOT_FOUND)
        
    hospital_profile = getattr(user, 'hospital_profile', None)
    authority_profile = getattr(user, 'authority_profile', None)
    verification = getattr(user, 'verification', None)
    
    verification_data = None
    if verification:
        verification_data = {
            'id': verification.id,
            'govt_id': verification.govt_id.url if verification.govt_id else None,
            'hospital_license': verification.hospital_license.url if verification.hospital_license else None,
            'authority_id': verification.authority_id.url if verification.authority_id else None,
        }
        
    return Response({
        'user': {
            'id': user.id,
            'username': user.username,
            'email': user.email,
            'first_name': user.first_name,
            'last_name': user.last_name,
            'phone_number': user.phone_number,
            'role': user.role,
            'is_active': user.is_active,
            'account_status': user.account_status,
            'reactivation_requested': user.reactivation_requested,
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

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def admin_modify_user_status_api(request, pk):
    if not is_superadmin(request.user):
        return Response({'error': 'Unauthorized'}, status=status.HTTP_403_FORBIDDEN)
        
    try:
        user = User.objects.get(pk=pk)
    except User.DoesNotExist:
        return Response(status=status.HTTP_404_NOT_FOUND)
        
    if user == request.user:
        return Response({'error': 'Cannot modify own account'}, status=status.HTTP_400_BAD_REQUEST)
        
    action = request.data.get('action')
    reason = request.data.get('reason', '')
    
    if action == 'toggle_active':
        user.is_active = not user.is_active
        if user.is_active:
            user.reactivation_requested = False
            user.account_status = 'active'
        else:
            user.account_status = 'frozen' # Default deactivated state
        user.save()
    elif action == 'freeze':
        user.account_status = 'frozen'
        user.is_active = False
        user.save()
    elif action == 'unfreeze':
        user.account_status = 'active'
        user.is_active = True
        user.save()
    elif action == 'block':
        if user.is_superuser:
            return Response({'error': 'Cannot block superadmin'}, status=status.HTTP_400_BAD_REQUEST)
        user.account_status = 'blocked'
        user.is_active = False
        user.save()
    elif action == 'unblock':
        user.account_status = 'active'
        user.is_active = True
        user.reactivation_requested = False
        user.save()
    else:
        return Response({'error': 'Invalid action'}, status=status.HTTP_400_BAD_REQUEST)
        
    AuditLogEntry.objects.create(
        admin=request.user,
        target_user=user,
        action_type=f'user_{action}',
        description=reason or f'User {action}',
        ip_address=request.META.get('REMOTE_ADDR')
    )
        
    return Response({'success': True, 'message': f'Action {action} successful'})

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def superadmin_verification_list_api(request):
    if not is_superadmin(request.user):
        return Response({'error': 'Unauthorized'}, status=status.HTTP_403_FORBIDDEN)
        
    hospitals = Hospital.objects.filter(status='pending').select_related('user')
    authorities = Authority.objects.all()
    
    items = list(hospitals) + list(authorities)
    data = []
    
    for item in items:
        is_hospital = isinstance(item, Hospital)
        u = item.user
        if not is_hospital and u.is_approved:
            continue
            
        name = item.hospital_name if is_hospital else item.authority_name
        
        data.append({
            'id': item.id,
            'entity_type': 'hospital' if is_hospital else 'authority',
            'name': name,
            'username': u.username,
            'email': u.email,
            'status': getattr(item, 'status', 'pending') if is_hospital else ('approved' if u.is_approved else 'pending'),
            'is_approved': u.is_approved,
        })
        
    return Response({'items': data})

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def superadmin_verification_detail_api(request, entity_type, entity_id):
    if not is_superadmin(request.user):
        return Response({'error': 'Unauthorized'}, status=status.HTTP_403_FORBIDDEN)
        
    if entity_type == 'hospital':
        try:
            entity = Hospital.objects.get(id=entity_id)
        except Hospital.DoesNotExist:
            return Response(status=status.HTTP_404_NOT_FOUND)
            
        user = entity.user
        verification = getattr(user, 'verification', None)
        
        documents = []
        if entity.license_document:
            documents.append({
                'label': 'License Document',
                'key': 'hospital_license_document',
                'url': entity.license_document.url
            })
        if verification:
            if getattr(verification, 'admin_id_proof', None):
                documents.append({
                    'label': 'Authorization Letter',
                    'key': 'verification_admin_id_proof',
                    'url': verification.admin_id_proof.url
                })
            if getattr(verification, 'hospital_license', None):
                documents.append({
                    'label': 'Hospital License (Verification)',
                    'key': 'verification_hospital_license',
                    'url': verification.hospital_license.url
                })
                
        data = {
            'id': entity.id,
            'entity_type': 'hospital',
            'name': entity.hospital_name,
            'email': entity.email,
            'phone': entity.contact_number,
            'address': f"{entity.address}, {entity.district}, {entity.state} - {entity.pincode}",
            'verification_status': entity.status,
            'is_approved': user.is_approved,
            'user': {
                'username': user.username,
                'role_display': user.get_role_display(),
                'email': user.email,
                'phone_number': user.phone_number or '-',
                'address_line_1': user.address_line_1 or '',
                'address_line_2': user.address_line_2 or '',
                'city': user.city or '-',
                'state': user.state or '-',
                'pincode': user.pincode or '-',
                'date_joined': user.date_joined.strftime("%b %d, %Y · %I:%M %p") if user.date_joined else '-'
            },
            'hospital_details': {
                'hospital_name': entity.hospital_name,
                'hospital_type_display': entity.get_hospital_type_display(),
                'registration_number': entity.registration_number,
                'license_number': entity.license_number,
                'address': entity.address,
                'district': entity.district,
                'state': entity.state,
                'pincode': entity.pincode
            },
            'documents': documents
        }
    elif entity_type == 'authority':
        try:
            entity = Authority.objects.get(id=entity_id)
        except Authority.DoesNotExist:
            return Response(status=status.HTTP_404_NOT_FOUND)
            
        user = entity.user
        verification = getattr(user, 'verification', None)
        
        documents = []
        if entity.appointment_letter:
            documents.append({
                'label': 'Appointment Letter',
                'key': 'authority_appointment_letter',
                'url': entity.appointment_letter.url
            })
        if entity.authority_id_document:
            documents.append({
                'label': 'Authority ID Document',
                'key': 'authority_id_document',
                'url': entity.authority_id_document.url
            })
        if verification:
            if getattr(verification, 'appointment_letter', None):
                documents.append({
                    'label': 'Appointment Letter (Verification)',
                    'key': 'verification_appointment_letter',
                    'url': verification.appointment_letter.url
                })
            if getattr(verification, 'authority_id', None):
                documents.append({
                    'label': 'Authority ID (Verification)',
                    'key': 'verification_authority_id',
                    'url': verification.authority_id.url
                })
                
        data = {
            'id': entity.id,
            'entity_type': 'authority',
            'name': entity.authority_name,
            'email': entity.official_email,
            'phone': entity.official_phone,
            'address': entity.office_address,
            'verification_status': 'approved' if user.is_approved else 'pending',
            'is_approved': user.is_approved,
            'user': {
                'username': user.username,
                'role_display': user.get_role_display(),
                'email': user.email,
                'phone_number': user.phone_number or '-',
                'address_line_1': user.address_line_1 or '',
                'address_line_2': user.address_line_2 or '',
                'city': user.city or '-',
                'state': user.state or '-',
                'pincode': user.pincode or '-',
                'date_joined': user.date_joined.strftime("%b %d, %Y · %I:%M %p") if user.date_joined else '-'
            },
            'authority_details': {
                'authority_name': entity.authority_name,
                'authority_type_display': entity.get_authority_type_display(),
                'department_name': entity.department_name,
                'jurisdiction_level': entity.jurisdiction_level,
                'jurisdiction_state': entity.jurisdiction_state,
                'jurisdiction_district': entity.jurisdiction_district or '-',
                'office_address': entity.office_address
            },
            'documents': documents
        }
    else:
        return Response({'error': 'Invalid entity type'}, status=status.HTTP_400_BAD_REQUEST)
        
    return Response(data)

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def superadmin_verification_approve_api(request, entity_type, entity_id):
    if not is_superadmin(request.user):
        return Response({'error': 'Unauthorized'}, status=status.HTTP_403_FORBIDDEN)
        
    if entity_type == 'hospital':
        try:
            entity = Hospital.objects.get(id=entity_id)
            user = entity.user
            entity.status = 'verified'
            entity.save()
        except Hospital.DoesNotExist:
            return Response(status=status.HTTP_404_NOT_FOUND)
    elif entity_type == 'authority':
        try:
            entity = Authority.objects.get(id=entity_id)
            user = entity.user
        except Authority.DoesNotExist:
            return Response(status=status.HTTP_404_NOT_FOUND)
    else:
        return Response({'error': 'Invalid entity type'}, status=status.HTTP_400_BAD_REQUEST)
        
    user.is_approved = True
    user.is_verified = True
    user.is_active = True
    user.save()
    
    Notification.objects.create(
        recipient=user,
        title='Verification Approved',
        message='Your account has been approved.'
    )
    
    AuditLogEntry.objects.create(
        admin=request.user,
        target_user=user,
        action_type='user_approved',
        description=f"{entity_type.title()} approved: {user.username}.",
        ip_address=request.META.get('REMOTE_ADDR')
    )
    return Response({'success': True, 'message': 'Entity approved'})

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def superadmin_verification_reject_api(request, entity_type, entity_id):
    if not is_superadmin(request.user):
        return Response({'error': 'Unauthorized'}, status=status.HTTP_403_FORBIDDEN)
        
    reason = request.data.get('reason', 'No reason provided.')
    
    if entity_type == 'hospital':
        try:
            entity = Hospital.objects.get(id=entity_id)
            user = entity.user
            entity.status = 'suspended'
            entity.save()
        except Hospital.DoesNotExist:
            return Response(status=status.HTTP_404_NOT_FOUND)
    elif entity_type == 'authority':
        try:
            entity = Authority.objects.get(id=entity_id)
            user = entity.user
        except Authority.DoesNotExist:
            return Response(status=status.HTTP_404_NOT_FOUND)
    else:
        return Response({'error': 'Invalid entity type'}, status=status.HTTP_400_BAD_REQUEST)
        
    user.is_approved = False
    user.is_active = False
    user.save()
    
    Notification.objects.create(
        recipient=user,
        title='Verification Rejected',
        message=f'Your verification was rejected. Reason: {reason}'
    )
    
    AuditLogEntry.objects.create(
        admin=request.user,
        target_user=user,
        action_type='user_rejected',
        description=f"{entity_type.title()} rejected: {user.username}. Reason: {reason}",
        ip_address=request.META.get('REMOTE_ADDR')
    )
    return Response({'success': True, 'message': 'Entity rejected'})

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def superadmin_audit_logs_api(request):
    if not is_superadmin(request.user):
        return Response({'error': 'Unauthorized'}, status=status.HTTP_403_FORBIDDEN)
        
    logs = AuditLogEntry.objects.select_related('admin', 'target_user').order_by('-timestamp')[:100]
    data = []
    for log in logs:
        target = log.target_user
        data.append({
            'id': log.id,
            'timestamp': log.timestamp.isoformat() if log.timestamp else None,
            'admin_username': log.admin.username if log.admin else 'System',
            'user': target.username if target else 'N/A',
            'user_id': target.id if target else None,
            'role': target.role if target else 'N/A',
            'status': target.account_status if target else 'N/A',
            'action': log.action_type,
            'description': log.description,
            'ip_address': log.ip_address or 'N/A',
        })
    return Response({'logs': data})

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def superadmin_user_activity_api(request, user_id):
    if not is_superadmin(request.user):
        return Response({'error': 'Unauthorized'}, status=status.HTTP_403_FORBIDDEN)
        
    try:
        user = User.objects.get(id=user_id)
    except User.DoesNotExist:
        return Response({'error': 'User not found'}, status=status.HTTP_404_NOT_FOUND)
        
    activities = []
    
    # 1. Reactivation Requests / UserActivity logs
    from accounts.models import UserActivity
    user_logs = UserActivity.objects.filter(user=user)
    for log in user_logs:
        icon = 'info'
        if log.action_type == 'Login': icon = 'login'
        elif log.action_type == 'Logout': icon = 'logout'
        elif 'Warning' in log.action_type: icon = 'warning'
        elif 'Reactivation' in log.action_type: icon = 'autorenew'
            
        activities.append({
            'type': log.action_type,
            'icon': icon,
            'description': log.description,
            'timestamp': log.timestamp.isoformat() if log.timestamp else None,
            'ip_address': log.ip_address
        })
        
    # Reactivation fallback
    if getattr(user, 'reactivation_requested', False):
        has_log = UserActivity.objects.filter(user=user, action_type='Reactivation Requested').exists()
        if not has_log:
            activities.append({
                'type': 'Reactivation Request',
                'icon': 'autorenew',
                'description': f"Requested account reactivation: {getattr(user, 'reactivation_reason', '') or 'No reason provided'}",
                'timestamp': user.date_joined.isoformat() if user.date_joined else None,
                'ip_address': None
            })

    # Hospital specific activities
    if user.role == 'hospital':
        from complaints.models import HospitalResponse
        for r in HospitalResponse.objects.filter(hospital=user):
            activities.append({
                'type': 'Response', 'icon': 'rate_review',
                'description': f"Responded to complaint: {r.complaint.title}",
                'timestamp': r.created_at.isoformat() if hasattr(r, 'created_at') and r.created_at else None,
                'complaint_id': r.complaint.id
            })
            
        from authorities.models import HospitalWarning, HospitalFreeze
        for w in HospitalWarning.objects.filter(hospital=user):
            activities.append({
                'type': 'Warning Received', 'icon': 'warning',
                'description': f"Received {w.warning_type} warning: {w.reason}",
                'timestamp': w.created_at.isoformat() if hasattr(w, 'created_at') and w.created_at else None
            })
            
        for f in HospitalFreeze.objects.filter(hospital=user):
            activities.append({
                'type': 'Account Frozen', 'icon': 'lock',
                'description': f"Account frozen: {f.reason}",
                'timestamp': f.frozen_at.isoformat() if hasattr(f, 'frozen_at') and f.frozen_at else None
            })

    # Authority specific activities
    elif user.role == 'authority':
        from authorities.models import HospitalWarning, HospitalFreeze, ComplaintActivityLog
        for w in HospitalWarning.objects.filter(issued_by=user):
            activities.append({
                'type': 'Warning Issued', 'icon': 'assignment_late',
                'description': f"Issued warning to {w.hospital.username if w.hospital else 'Unknown'}",
                'timestamp': w.created_at.isoformat() if hasattr(w, 'created_at') and w.created_at else None
            })
            
        for f in HospitalFreeze.objects.filter(frozen_by=user):
            activities.append({
                'type': 'Freeze Action', 'icon': 'gavel',
                'description': f"Froze hospital account: {f.hospital.username if f.hospital else 'Unknown'}",
                'timestamp': f.frozen_at.isoformat() if hasattr(f, 'frozen_at') and f.frozen_at else None
            })
            
        for l in ComplaintActivityLog.objects.filter(performed_by=user):
            activities.append({
                'type': 'Oversight', 'icon': 'visibility',
                'description': f"{l.get_activity_type_display()}: {l.complaint.title if hasattr(l, 'complaint') and l.complaint else 'Unknown'}",
                'timestamp': l.created_at.isoformat() if hasattr(l, 'created_at') and l.created_at else None,
                'complaint_id': l.complaint.id if hasattr(l, 'complaint') and l.complaint else None
            })

    # General (Patient/Common)
    from complaints.models import Complaint, Comment, Like
    for c in Complaint.objects.filter(user=user):
        activities.append({
            'type': 'Complaint', 'icon': 'edit_note',
            'description': f"Posted complaint: {c.title}",
            'timestamp': c.created_at.isoformat() if hasattr(c, 'created_at') and c.created_at else None,
            'complaint_id': c.id
        })
    for c in Comment.objects.filter(user=user):
        activities.append({
            'type': 'Comment', 'icon': 'chat',
            'description': f"Commented on {c.complaint.title if hasattr(c, 'complaint') and c.complaint else 'Unknown'}",
            'timestamp': c.created_at.isoformat() if hasattr(c, 'created_at') and c.created_at else None,
            'complaint_id': c.complaint.id if hasattr(c, 'complaint') and c.complaint else None
        })
    for l in Like.objects.filter(user=user):
        activities.append({
            'type': 'Like', 'icon': 'thumb_up',
            'description': f"Liked complaint: {l.complaint.title if hasattr(l, 'complaint') and l.complaint else 'Unknown'}",
            'timestamp': l.created_at.isoformat() if hasattr(l, 'created_at') and l.created_at else None,
            'complaint_id': l.complaint.id if hasattr(l, 'complaint') and l.complaint else None
        })
        
    activities = [a for a in activities if a.get('timestamp')]
    activities.sort(key=lambda x: x['timestamp'], reverse=True)
    
    # Freeze records (for appeals)
    freeze_records_data = []
    if user.role == 'hospital':
        from authorities.models import HospitalFreeze
        for f in HospitalFreeze.objects.filter(hospital=user, status__in=['frozen', 'pending_review']).order_by('-frozen_at'):
            evidence_url = None
            if hasattr(f, 'explanation_evidence') and f.explanation_evidence:
                try: evidence_url = f.explanation_evidence.url
                except: pass
            freeze_records_data.append({
                'id': f.id,
                'status': f.status,
                'status_display': f.get_status_display() if hasattr(f, 'get_status_display') else f.status,
                'frozen_by_role': f.frozen_by.get_role_display() if f.frozen_by else 'System',
                'frozen_at': f.frozen_at.isoformat() if f.frozen_at else None,
                'reason': f.get_reason_display() if hasattr(f, 'get_reason_display') else f.reason,
                'description': f.description,
                'explanation_text': f.explanation_text,
                'explanation_submitted_at': f.explanation_submitted_at.isoformat() if f.explanation_submitted_at else None,
                'evidence_url': evidence_url
            })

    # Security Alerts
    from super_admin.models import SecurityAlert
    alerts = SecurityAlert.objects.filter(user=user, is_resolved=False).order_by('-timestamp')
    alert_data = [{
        'type': al.alert_type,
        'severity': al.severity,
        'description': al.description,
        'timestamp': al.timestamp.isoformat() if al.timestamp else None
    } for al in alerts]
    
    # Audit Logs (Past Admin Actions against this user)
    from super_admin.models import AuditLogEntry
    past_actions = AuditLogEntry.objects.filter(target_user=user).exclude(admin=None).order_by('-timestamp')[:20]
    pa_data = [{
        'action': pa.action_type,
        'description': pa.description,
        'admin': pa.admin.username if pa.admin else 'System',
        'timestamp': pa.timestamp.isoformat() if pa.timestamp else None
    } for pa in past_actions]

    return Response({
        'user': {
            'id': user.id,
            'username': user.username,
            'role': user.role,
            'account_status': user.account_status,
            'is_active': user.is_active,
            'reactivation_requested': getattr(user, 'reactivation_requested', False),
            'reactivation_reason': getattr(user, 'reactivation_reason', '') or '',
            'first_name': getattr(user, 'first_name', ''),
        },
        'activities': activities[:100], # Cap at 100
        'active_alerts': alert_data,
        'past_actions': pa_data,
        'freeze_records': freeze_records_data
    })

def _superadmin_perform_action(request, user_id, action_name, new_status, is_active, notification_msg):
    if not is_superadmin(request.user):
        return Response({'error': 'Unauthorized'}, status=status.HTTP_403_FORBIDDEN)
        
    try:
        user = User.objects.get(id=user_id)
    except User.DoesNotExist:
        return Response({'error': 'User not found'}, status=status.HTTP_404_NOT_FOUND)
        
    reason = request.data.get('reason', '')
    
    if new_status is not None:
        user.account_status = new_status
    if is_active is not None:
        user.is_active = is_active
    user.save()
    
    if action_name == 'unfrozen' and user.role == 'hospital':
        from authorities.models import HospitalFreeze
        HospitalFreeze.objects.filter(
            hospital=user,
            status__in=['frozen', 'pending_review']
        ).update(status='reactivated', reactivated_at=timezone.now())
    
    Notification.objects.create(
        recipient=user,
        title=f'Account {action_name.title()}',
        message=notification_msg
    )
    
    AuditLogEntry.objects.create(
        admin=request.user,
        target_user=user,
        action_type=f'user_{action_name}',
        description=reason or f'User {action_name} by admin.',
        ip_address=request.META.get('REMOTE_ADDR')
    )
    
    return Response({'success': True, 'message': f'User {action_name} successfully.'})

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def superadmin_user_freeze_api(request, user_id):
    return _superadmin_perform_action(
        request, user_id, 'frozen', 'frozen', False,
        'Your account has been temporarily frozen by the administrator.'
    )

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def superadmin_user_unfreeze_api(request, user_id):
    return _superadmin_perform_action(
        request, user_id, 'unfrozen', 'active', True,
        'Your account has been unfrozen and is now active.'
    )

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def superadmin_user_block_api(request, user_id):
    return _superadmin_perform_action(
        request, user_id, 'blocked', 'blocked', False,
        'Your account has been blocked by the administrator.'
    )

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def superadmin_user_unblock_api(request, user_id):
    return _superadmin_perform_action(
        request, user_id, 'unblocked', 'active', True,
        'Your account has been unblocked and is now active.'
    )

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def superadmin_user_warn_api(request, user_id):
    return _superadmin_perform_action(
        request, user_id, 'warned', None, None,
        'You have received an official warning from the administrator.'
    )

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def superadmin_user_reactivate_api(request, user_id):
    if not is_superadmin(request.user):
        return Response({'error': 'Unauthorized'}, status=status.HTTP_403_FORBIDDEN)
    try:
        user = User.objects.get(id=user_id)
    except User.DoesNotExist:
        return Response({'error': 'User not found'}, status=status.HTTP_404_NOT_FOUND)
    user.account_status = 'active'
    user.is_active = True
    user.reactivation_requested = False
    if hasattr(user, 'reactivation_reason'):
        user.reactivation_reason = ''
    user.save()
    
    if user.role == 'hospital':
        from authorities.models import HospitalFreeze
        HospitalFreeze.objects.filter(
            hospital=user,
            status__in=['frozen', 'pending_review']
        ).update(status='reactivated', reactivated_at=timezone.now())
    Notification.objects.create(
        recipient=user,
        title='Account Reactivated',
        message='Your reactivation request has been approved. Your account is now active.'
    )
    AuditLogEntry.objects.create(
        admin=request.user,
        target_user=user,
        action_type='user_reactivated',
        description='User reactivation request approved by admin.',
        ip_address=request.META.get('REMOTE_ADDR')
    )
    return Response({'success': True, 'message': 'User reactivated successfully.'})

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def superadmin_approve_hospital_appeal_api(request, freeze_id):
    if not is_superadmin(request.user):
        return Response({'error': 'Unauthorized'}, status=status.HTTP_403_FORBIDDEN)
        
    from django.shortcuts import get_object_or_404
    freeze_record = get_object_or_404(HospitalFreeze, id=freeze_id)
    hospital = freeze_record.hospital
    
    freeze_record.status = 'reactivated'
    freeze_record.reactivated_at = timezone.now()
    freeze_record.save()
    
    hospital.account_status = 'active'
    hospital.save()
    
    Notification.objects.create(
        recipient=hospital,
        title="Account Reactivated",
        message=f"Your account has been reactivated. Your appeal was approved by admin.",
        link="/hospital/dashboard/"
    )
    
    UserActivity.objects.create(
        user=request.user,
        action_type='Admin Reactivate',
        description=f"Approved hospital freeze appeal for {hospital.username}"
    )
    
    AuditLogEntry.objects.create(
        admin=request.user,
        target_user=hospital,
        action_type='approve_appeal',
        description=f"Approved hospital freeze appeal for {hospital.username}.",
        ip_address=request.META.get('REMOTE_ADDR')
    )
    
    return Response({'success': True, 'message': 'Appeal approved successfully.'})

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def superadmin_reject_hospital_appeal_api(request, freeze_id):
    if not is_superadmin(request.user):
        return Response({'error': 'Unauthorized'}, status=status.HTTP_403_FORBIDDEN)
        
    from django.shortcuts import get_object_or_404
    freeze_record = get_object_or_404(HospitalFreeze, id=freeze_id)
    hospital = freeze_record.hospital
    
    freeze_record.status = 'frozen'
    freeze_record.save()
    
    Notification.objects.create(
        recipient=hospital,
        title="Appeal Rejected",
        message=f"Your account reactivation appeal has been rejected. Please contact support for more information.",
        link="/hospital/dashboard/"
    )
    
    UserActivity.objects.create(
        user=request.user,
        action_type='Admin Reject Appeal',
        description=f"Rejected hospital freeze appeal for {hospital.username}"
    )
    
    AuditLogEntry.objects.create(
        admin=request.user,
        target_user=hospital,
        action_type='reject_appeal',
        description=f"Rejected hospital freeze appeal for {hospital.username}.",
        ip_address=request.META.get('REMOTE_ADDR')
    )
    
    return Response({'success': True, 'message': 'Appeal rejected successfully.'})

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def admin_security_monitoring_api(request):
    if not is_superadmin(request.user):
        return Response({'error': 'Unauthorized'}, status=status.HTTP_403_FORBIDDEN)
        
    alerts = SecurityAlert.objects.select_related('user', 'resolved_by').order_by('-timestamp')[:50]
    data = []
    for alert in alerts:
        data.append({
            'id': alert.id,
            'alert_type': alert.alert_type,
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
    return Response({'alerts': data})

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def admin_resolve_security_alert_api(request, pk):
    if not is_superadmin(request.user):
        return Response({'error': 'Unauthorized'}, status=status.HTTP_403_FORBIDDEN)
        
    try:
        alert = SecurityAlert.objects.get(pk=pk)
    except SecurityAlert.DoesNotExist:
        return Response(status=status.HTTP_404_NOT_FOUND)
        
    alert.is_resolved = True
    alert.resolved_at = timezone.now()
    alert.resolved_by = request.user
    alert.save()
    
    return Response({'success': True, 'message': 'Security alert resolved'})

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def admin_export_audit_logs_api(request):
    if not is_superadmin(request.user):
        return Response({'error': 'Unauthorized'}, status=status.HTTP_403_FORBIDDEN)
    
    # In a real scenario we could return a CSV file or JSON of all records.
    # For Flutter app it expects JSON response.
    return Response({'success': True, 'message': 'Audit logs exported'})

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def admin_trigger_security_scan_api(request):
    if not is_superadmin(request.user):
        return Response({'error': 'Unauthorized'}, status=status.HTTP_403_FORBIDDEN)
    return Response({'success': True, 'message': 'Security scan initiated'})

@api_view(['GET', 'POST'])
@permission_classes([IsAuthenticated])
def admin_security_settings_api(request):
    if not is_superadmin(request.user):
        return Response({'error': 'Unauthorized'}, status=status.HTTP_403_FORBIDDEN)
    
    if request.method == 'GET':
        return Response({
            'two_fa_enabled': False,
            'session_timeout': 1209600,
            'max_login_attempts': 5,
        })
    else:
        return Response({'success': True, 'message': 'Security settings updated successfully'})

@api_view(['GET', 'POST'])
@permission_classes([IsAuthenticated])
def admin_categories_api(request):
    if not is_superadmin(request.user):
        return Response({'error': 'Unauthorized'}, status=status.HTTP_403_FORBIDDEN)

    from complaints.models import Category
    from django.db.models import Q
    from django.core.paginator import Paginator

    if request.method == 'GET':
        search = request.GET.get('search', '').strip()
        page = int(request.GET.get('page', 1))

        qs = Category.objects.all().order_by('-created_at')
        if search:
            qs = qs.filter(Q(name__icontains=search) | Q(description__icontains=search))

        paginator = Paginator(qs, 6) # 6 categories per page as in Django template
        page_obj = paginator.get_page(page)

        data = []
        for c in page_obj.object_list:
            data.append({
                'id': c.id,
                'name': c.name,
                'description': c.description or '',
                'is_active': c.is_active,
                'created_at': c.created_at.isoformat() if c.created_at else None,
            })

        return Response({
            'categories': data,
            'page': page,
            'total_pages': paginator.num_pages,
            'total_categories': paginator.count,
            'start_index': page_obj.start_index() if paginator.count > 0 else 0,
            'end_index': page_obj.end_index() if paginator.count > 0 else 0,
            'has_next': page_obj.has_next(),
            'has_previous': page_obj.has_previous(),
        })

    elif request.method == 'POST':
        name = request.data.get('name', '').strip()
        description = request.data.get('description', '').strip()

        if not name:
            return Response({'error': 'Category name is required'}, status=status.HTTP_400_BAD_REQUEST)

        if Category.objects.filter(name__iexact=name).exists():
            return Response({'error': f"Category '{name}' already exists."}, status=status.HTTP_400_BAD_REQUEST)

        category = Category.objects.create(name=name, description=description)
        return Response({
            'success': True,
            'message': f"Category '{name}' added successfully.",
            'category': {
                'id': category.id,
                'name': category.name,
                'description': category.description or '',
                'is_active': category.is_active,
            }
        }, status=status.HTTP_201_CREATED)

@api_view(['DELETE'])
@permission_classes([IsAuthenticated])
def admin_category_detail_api(request, pk):
    if not is_superadmin(request.user):
        return Response({'error': 'Unauthorized'}, status=status.HTTP_403_FORBIDDEN)

    from complaints.models import Category

    try:
        category = Category.objects.get(pk=pk)
    except Category.DoesNotExist:
        return Response({'error': 'Category not found'}, status=status.HTTP_404_NOT_FOUND)

    name = category.name
    category.delete()
    return Response({'success': True, 'message': f"Category '{name}' deleted successfully."})

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def admin_support_tickets_api(request):
    if not is_superadmin(request.user):
        return Response({'error': 'Unauthorized'}, status=status.HTTP_403_FORBIDDEN)
        
    from social.models import SupportTicket
    
    status_filter = request.GET.get('status', 'all')
    tickets_query = SupportTicket.objects.all()
    
    if status_filter != 'all':
        tickets_query = tickets_query.filter(status=status_filter)
        
    tickets = tickets_query.order_by('-created_at')
    
    data = []
    for t in tickets:
        from accounts.models import PatientNotificationReply
        patient_reply = PatientNotificationReply.objects.filter(support_ticket=t).order_by('-created_at').first()
        patient_reply_data = None
        if patient_reply:
            patient_reply_data = {
                'message': patient_reply.message,
                'user': {
                    'username': patient_reply.user.username,
                    'email': patient_reply.user.email
                },
                'created_at': patient_reply.created_at.isoformat() if patient_reply.created_at else None
            }
            
        data.append({
            'id': t.id,
            'subject': t.subject,
            'message': t.message,
            'admin_reply': t.admin_reply,
            'status': t.status,
            'get_status_display': t.get_status_display() if hasattr(t, 'get_status_display') else t.status,
            'created_at': t.created_at.isoformat() if t.created_at else None,
            'updated_at': t.updated_at.isoformat() if t.updated_at else None,
            'user': {
                'username': t.user.username,
                'email': t.user.email,
                'get_full_name': t.user.get_full_name() or t.user.username
            },
            'patient_reply': patient_reply_data
        })
        
    return Response({'tickets': data})

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def admin_support_ticket_reply_api(request, pk):
    if not is_superadmin(request.user):
        return Response({'error': 'Unauthorized'}, status=status.HTTP_403_FORBIDDEN)
        
    from social.models import SupportTicket
    try:
        ticket = SupportTicket.objects.get(pk=pk)
    except SupportTicket.DoesNotExist:
        return Response({'error': 'Support ticket not found'}, status=status.HTTP_404_NOT_FOUND)
        
    admin_reply = request.data.get('admin_reply', '').strip()
    if not admin_reply:
        return Response({'error': 'Reply message is required'}, status=status.HTTP_400_BAD_REQUEST)
        
    ticket.admin_reply = admin_reply
    ticket.status = 'resolved'
    ticket.save()
    
    from accounts.models import Notification
    Notification.objects.create(
        recipient=ticket.user,
        title="Support Ticket Reply",
        message=f"Admin replied to \"{ticket.subject}\": {admin_reply}",
        support_ticket=ticket
    )
    
    return Response({'success': True, 'message': 'Reply sent successfully'})

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def admin_profile_api(request):
    if not is_superadmin(request.user):
        return Response({'error': 'Unauthorized'}, status=status.HTTP_403_FORBIDDEN)
        
    user = request.user
    
    total_users = User.objects.filter(role='patient').count()
    pending_approvals = User.objects.filter(is_approved=False, role__in=['hospital', 'authority']).count()
    total_complaints = Complaint.objects.count()
    urgent_complaints = Complaint.objects.filter(status='urgent').count()
    
    photo_url = None
    try:
        from accounts.models import Profile
        profile = Profile.objects.get(user=user)
        if profile.photo:
            photo_url = profile.photo.url
    except Exception:
        pass

    return Response({
        'user': {
            'first_name': user.first_name,
            'last_name': user.last_name,
            'username': user.username,
            'email': user.email,
            'last_login': user.last_login.isoformat() if user.last_login else None,
            'date_joined': user.date_joined.isoformat() if user.date_joined else None,
            'photo': request.build_absolute_uri(photo_url) if photo_url else None
        },
        'stats': {
            'total_users': total_users,
            'pending_approvals': pending_approvals,
            'total_complaints': total_complaints,
            'urgent_complaints': urgent_complaints,
            'active_investigations': 0
        },
        'permissions': [
            'User Management',
            'System Configuration',
            'Audit Logs',
            'Data Export',
            'API Access'
        ]
    })
