import re

def update_admin_dashboard_api(file_path):
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()

    # The function ends at:
    #         'platform_governance_queue': governance_queue[:10], # Top 10 items
    #     })
    
    start_str = "def admin_dashboard_api(request):"
    start_idx = content.find(start_str)
    if start_idx == -1:
        print("Function not found!")
        return

    end_str = "    })\n"
    end_idx = content.find(end_str, start_idx)
    if end_idx == -1:
        print("End of function not found!")
        return
        
    end_idx += len(end_str)

    new_func = """def admin_dashboard_api(request):
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
"""
    
    new_content = content[:start_idx] + new_func + content[end_idx:]
    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(new_content)
        print("Updated admin_dashboard_api")

update_admin_dashboard_api(r'c:\Users\VICTUS\OneDrive\Desktop\medvoice\MedVoice\medVoice\api\admin_api_views.py')
