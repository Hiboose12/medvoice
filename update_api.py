import sys

with open(r'c:\Users\VICTUS\OneDrive\Desktop\medvoice\MedVoice\medVoice\api\admin_api_views.py', 'r', encoding='utf-8') as f:
    lines = f.readlines()

start_idx = -1
end_idx = -1
for i, l in enumerate(lines):
    if l.startswith('def superadmin_user_activity_api'):
        start_idx = i
    if l.startswith('def _superadmin_perform_action'):
        end_idx = i
        break

if start_idx != -1 and end_idx != -1:
    before = lines[:start_idx]
    after = lines[end_idx:]
    
    new_func = """def superadmin_user_activity_api(request, user_id):
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
                'timestamp': r.created_at.isoformat() if hasattr(r, 'created_at') and r.created_at else None
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
                'timestamp': l.created_at.isoformat() if hasattr(l, 'created_at') and l.created_at else None
            })

    # General (Patient/Common)
    from complaints.models import Complaint, Comment, Like
    for c in Complaint.objects.filter(user=user):
        activities.append({
            'type': 'Complaint', 'icon': 'edit_note',
            'description': f"Posted complaint: {c.title}",
            'timestamp': c.created_at.isoformat() if hasattr(c, 'created_at') and c.created_at else None
        })
    for c in Comment.objects.filter(user=user):
        activities.append({
            'type': 'Comment', 'icon': 'chat',
            'description': f"Commented on {c.complaint.title if hasattr(c, 'complaint') and c.complaint else 'Unknown'}",
            'timestamp': c.created_at.isoformat() if hasattr(c, 'created_at') and c.created_at else None
        })
    for l in Like.objects.filter(user=user):
        activities.append({
            'type': 'Like', 'icon': 'thumb_up',
            'description': f"Liked complaint: {l.complaint.title if hasattr(l, 'complaint') and l.complaint else 'Unknown'}",
            'timestamp': l.created_at.isoformat() if hasattr(l, 'created_at') and l.created_at else None
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
                'reason': f.reason,
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
            'first_name': getattr(user, 'first_name', ''),
        },
        'activities': activities[:100], # Cap at 100
        'active_alerts': alert_data,
        'past_actions': pa_data,
        'freeze_records': freeze_records_data
    })

"""
    
    with open(r'c:\Users\VICTUS\OneDrive\Desktop\medvoice\MedVoice\medVoice\api\admin_api_views.py', 'w', encoding='utf-8') as f:
        f.writelines(before)
        f.write(new_func)
        f.writelines(after)
    print("Replaced superadmin_user_activity_api.")
else:
    print("Could not find function boundaries.")
