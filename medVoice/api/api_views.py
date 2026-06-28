from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework import status
from django.utils import timezone

from accounts.models import User, Notification
from complaints.models import Complaint, HospitalResponse
from authorities.models import (
    AuthoritySettings, HospitalWarning, HospitalFreeze,
    ComplaintActivityLog, AuthorityNotification
)
from authorities.views import get_authority_jurisdiction_hospitals
from .serializers import (
    UserSerializer, ComplaintSerializer, HospitalSerializer,
    HospitalWarningSerializer, HospitalFreezeSerializer, ComplaintActivityLogSerializer
)
from hospitals.views import _escalate_overdue_complaints

def is_approved_authority(user):
    return user.role.lower() == 'authority' and user.is_approved

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def patient_dashboard(request):
    if request.user.role.lower() != 'patient':
        return Response({'error': 'Unauthorized'}, status=status.HTTP_403_FORBIDDEN)
        
    user_complaints = Complaint.objects.filter(user=request.user)
    recent_activity = user_complaints.order_by("-created_at")[:3]
    today = timezone.now().date()
    
    community_billing_count = Complaint.objects.filter(category__iexact='billing', created_at__month=today.month).count()
    community_resolved_today = Complaint.objects.filter(status='resolved', created_at__date=today).count()
    
    recent_list = ComplaintSerializer(recent_activity, many=True, context={'request': request}).data
    
    return Response({
        "total_complaints": user_complaints.count(),
        "resolved_complaints": user_complaints.filter(status="resolved").count(),
        "pending_complaints": user_complaints.exclude(status="resolved").count(),
        "recent_activity": recent_list,
        "community_billing_count": community_billing_count,
        "community_resolved_today": community_resolved_today,
    })

@api_view(['GET', 'PUT'])
@permission_classes([IsAuthenticated])
def user_profile(request):
    if request.method == 'GET':
        serializer = UserSerializer(request.user, context={'request': request})
        return Response(serializer.data)
        
    elif request.method == 'PUT':
        serializer = UserSerializer(request.user, data=request.data, partial=True, context={'request': request})
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

@api_view(['GET', 'POST'])
@permission_classes([IsAuthenticated])
def complaint_list(request):
    """Handles GET /api/v1/complaints/ and POST /api/v1/complaints/"""
    if request.method == 'GET':
        complaints = Complaint.objects.filter(user=request.user).order_by('-created_at')
        serializer = ComplaintSerializer(complaints, many=True, context={'request': request})
        return Response(serializer.data)
        
    elif request.method == 'POST':
        serializer = ComplaintSerializer(data=request.data, context={'request': request})
        if serializer.is_valid():
            serializer.save(user=request.user)
            return Response(serializer.data, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def complaint_options_api(request):
    from accounts.models import User
    hospitals = User.objects.filter(role='hospital', is_active=True, is_approved=True)
    hospital_data = []
    for h in hospitals:
        hospital_name = h.username
        if hasattr(h, 'hospital_profile'):
            hospital_name = h.hospital_profile.hospital_name
        hospital_data.append({'id': h.id, 'name': hospital_name})
    
    from complaints.models import Category
    categories_qs = Category.objects.filter(is_active=True).order_by('name')
    categories = [{"id": cat.id, "name": cat.name} for cat in categories_qs]
    if not categories:
        categories = [
            {"id": 1, "name": "Service Quality"},
            {"id": 2, "name": "Clinical Quality"},
            {"id": 3, "name": "Staff Conduct"},
            {"id": 4, "name": "Access & Billing"},
            {"id": 5, "name": "Facility & Safety"},
            {"id": 6, "name": "Patient Rights"},
            {"id": 7, "name": "General"}
        ]
    return Response({"hospitals": hospital_data, "categories": categories})

@api_view(['GET', 'PUT', 'DELETE'])
@permission_classes([IsAuthenticated])
def complaint_detail(request, pk):
    try:
        complaint = Complaint.objects.get(pk=pk)
    except Complaint.DoesNotExist:
        return Response(status=status.HTTP_404_NOT_FOUND)
        
    # Check permissions
    can_view = False
    if request.user.role == 'superadmin':
        can_view = True
    elif request.user.role == 'authority':
        can_view = (complaint.user.account_status != 'blocked')
    elif request.user.role == 'hospital':
        can_view = (complaint.hospital == request.user) or (complaint.user.account_status != 'blocked')
    else:  # patient
        is_owner = (complaint.user == request.user)
        show_in_feed = True
        try:
            if hasattr(complaint.user, 'settings'):
                show_in_feed = complaint.user.settings.show_in_feed
        except Exception:
            pass
        is_public = show_in_feed and (complaint.user.account_status != 'blocked')
        can_view = is_owner or is_public

    if request.method == 'GET':
        if not can_view:
            return Response({'detail': 'You do not have permission to view this complaint.'}, status=status.HTTP_403_FORBIDDEN)
            
        serializer = ComplaintSerializer(complaint, context={'request': request})
        return Response(serializer.data)

    elif request.method == 'PUT':
        if not is_owner:
            return Response({'error': 'You are not authorized to edit this complaint.'}, status=status.HTTP_403_FORBIDDEN)
            
        serializer = ComplaintSerializer(complaint, data=request.data, partial=True, context={'request': request})
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

    elif request.method == 'DELETE':
        if not is_owner:
            return Response({'error': 'You are not authorized to delete this complaint.'}, status=status.HTTP_403_FORBIDDEN)
            
        complaint.delete()
        return Response({'success': True, 'message': 'Complaint deleted successfully.'}, status=status.HTTP_204_NO_CONTENT)

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def patient_complaint_resolve_api(request, pk):
    try:
        complaint = Complaint.objects.get(pk=pk)
    except Complaint.DoesNotExist:
        return Response(status=status.HTTP_404_NOT_FOUND)
        
    if complaint.user != request.user:
        return Response({'error': 'Unauthorized'}, status=status.HTTP_403_FORBIDDEN)
        
    resolution = request.data.get('resolution')
    if resolution not in ['satisfied', 'resolved']:
        return Response({'error': 'Invalid resolution choice.'}, status=status.HTTP_400_BAD_REQUEST)
        
    complaint.status = 'resolved'
    complaint.patient_resolution_status = resolution
    complaint.patient_resolution_at = timezone.now()
    complaint.save(update_fields=['status', 'patient_resolution_status', 'patient_resolution_at'])
    
    if complaint.hospital:
        Notification.objects.create(
            recipient=complaint.hospital,
            title="Complaint marked as resolved",
            message=f"The patient marked complaint #{complaint.id} as resolved.",
            link=f"/complaint/{complaint.id}/"
        )
        
    return Response({'success': True, 'message': 'Complaint marked as resolved.'})

@api_view(['GET', 'POST'])
@permission_classes([IsAuthenticated])
def community_feed(request):
    """Handles GET /api/v1/feed/ and POST /api/v1/feed/"""
    if request.method == 'GET':
        from django.db.models import Q
        privacy_filter = Q(user__settings__show_in_feed=True) | Q(user__settings__isnull=True) | Q(user=request.user)
        
        if request.user.role == 'superadmin':
            complaints = Complaint.objects.all()
        elif request.user.role in ['hospital', 'authority']:
            complaints = Complaint.objects.exclude(user__account_status='blocked')
        else:
            complaints = Complaint.objects.filter(privacy_filter).exclude(user__account_status='blocked')
            
        q = request.query_params.get('q')
        if q:
            complaint_filter = Q(title__icontains=q) | \
                               Q(description__icontains=q) | \
                               Q(hospital__username__icontains=q) | \
                               Q(category__icontains=q) | \
                               Q(unregistered_hospital_name__icontains=q)
            complaints = complaints.filter(complaint_filter)
            
        complaints = complaints.order_by('-created_at')[:50]
        serializer = ComplaintSerializer(complaints, many=True, context={'request': request})
        return Response(serializer.data)
        
    elif request.method == 'POST':
        serializer = ComplaintSerializer(data=request.data, context={'request': request})
        if serializer.is_valid():
            serializer.save(user=request.user)
            return Response(serializer.data, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

def is_approved_hospital(user):
    return user.role.lower() == 'hospital' and user.is_approved

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def hospital_dashboard(request):
    if not is_approved_hospital(request.user):
        return Response({'error': 'Unauthorized'}, status=status.HTTP_403_FORBIDDEN)

    complaints = Complaint.objects.filter(hospital=request.user)
    _escalate_overdue_complaints(request.user)

    # Check freeze status
    from authorities.models import HospitalFreeze
    is_frozen = HospitalFreeze.objects.filter(hospital=request.user, status='frozen').exists()

    recent_complaints = complaints.order_by("-created_at")[:5]
    recent_list = ComplaintSerializer(recent_complaints, many=True, context={'request': request}).data

    return Response({
        "total_complaints": complaints.count(),
        "open_complaints": complaints.filter(status="new").count(),
        "active_complaints": complaints.filter(status="review").count(),
        "responded_complaints": complaints.filter(status="responded").count(),
        "resolved_complaints": complaints.filter(status="resolved").count(),
        "recent_complaints": recent_list,
        "unread_notifications": Notification.objects.filter(recipient=request.user, is_read=False).count(),
        "is_frozen": is_frozen,
    })

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def hospital_complaint_list(request):
    if not is_approved_hospital(request.user):
        return Response({'error': 'Unauthorized'}, status=status.HTTP_403_FORBIDDEN)

    status_filter = request.GET.get('status', 'all')
    complaints = Complaint.objects.filter(hospital=request.user)
    _escalate_overdue_complaints(request.user)
    
    if status_filter != 'all':
        if status_filter == 'investigating':
            complaints = complaints.filter(status='review')
        else:
            complaints = complaints.filter(status=status_filter)

    complaints = complaints.order_by("-created_at")
    serializer = ComplaintSerializer(complaints, many=True, context={'request': request})
    
    return Response({
        "complaints": serializer.data,
        "new_count": Complaint.objects.filter(hospital=request.user, status='new').count(),
        "review_count": Complaint.objects.filter(hospital=request.user, status='review').count(),
        "responded_count": Complaint.objects.filter(hospital=request.user, status='responded').count(),
        "resolved_count": Complaint.objects.filter(hospital=request.user, status='resolved').count(),
        "total_count": Complaint.objects.filter(hospital=request.user).count(),
    })

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def hospital_complaint_detail(request, pk):
    if not is_approved_hospital(request.user):
        return Response({'error': 'Unauthorized'}, status=status.HTTP_403_FORBIDDEN)

    try:
        complaint = Complaint.objects.get(pk=pk, hospital=request.user)
    except Complaint.DoesNotExist:
        return Response(status=status.HTTP_404_NOT_FOUND)

    # Mark as viewed by hospital
    if not complaint.viewed_by_hospital:
        complaint.viewed_by_hospital = True
        if complaint.status == 'new':
            complaint.status = 'review'
        complaint.save()

    serializer = ComplaintSerializer(complaint, context={'request': request})
    return Response(serializer.data)

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def hospital_complaint_respond(request, pk):
    if not is_approved_hospital(request.user):
        return Response({'error': 'Unauthorized'}, status=status.HTTP_403_FORBIDDEN)

    from authorities.models import HospitalFreeze
    is_frozen = HospitalFreeze.objects.filter(hospital=request.user, status='frozen').exists()
    if is_frozen:
        return Response({'error': 'Account frozen'}, status=status.HTTP_403_FORBIDDEN)

    try:
        complaint = Complaint.objects.get(pk=pk, hospital=request.user)
    except Complaint.DoesNotExist:
        return Response(status=status.HTTP_404_NOT_FOUND)

    message = request.data.get('message')
    if not message:
        return Response({'error': 'Message is required'}, status=status.HTTP_400_BAD_REQUEST)

    is_private = request.data.get('is_private', False)
    if isinstance(is_private, str):
        is_private = is_private.lower() == 'true'

    HospitalResponse.objects.create(
        complaint=complaint,
        hospital=request.user,
        message=message,
        is_private=bool(is_private)
    )

    if complaint.status in ['new', 'review']:
        complaint.status = 'responded'
        complaint.hospital_responded_at = timezone.now()
        complaint.save()
        
    Notification.objects.create(
        recipient=complaint.user,
        title="Hospital Responded",
        message=f"The hospital has responded to your complaint '{complaint.title}'.",
        link=f"/complaint/{complaint.id}/"
    )
    return Response({'status': 'success', 'message': 'Response added'})

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def hospital_complaint_resolve(request, pk):
    if not is_approved_hospital(request.user):
        return Response({'error': 'Unauthorized'}, status=status.HTTP_403_FORBIDDEN)

    from authorities.models import HospitalFreeze
    is_frozen = HospitalFreeze.objects.filter(hospital=request.user, status='frozen').exists()
    if is_frozen:
        return Response({'error': 'Account frozen'}, status=status.HTTP_403_FORBIDDEN)

    try:
        complaint = Complaint.objects.get(pk=pk, hospital=request.user)
    except Complaint.DoesNotExist:
        return Response(status=status.HTTP_404_NOT_FOUND)
        
    new_status = request.data.get('status')
    if new_status in dict(Complaint.STATUS_CHOICES):
        complaint.status = new_status
        if new_status == 'resolved':
            complaint.patient_resolution_status = 'resolved'
            complaint.patient_resolution_at = timezone.now()
        complaint.save()
        
        Notification.objects.create(
            recipient=complaint.user,
            title='Complaint Status Updated',
            message=f"The hospital has marked your complaint '{complaint.title}' as {new_status}.",
            link=f'/complaint/{complaint.id}/'
        )
        return Response({'status': 'success'})
    return Response({'error': 'Invalid status'}, status=status.HTTP_400_BAD_REQUEST)

@api_view(['GET', 'PUT'])
@permission_classes([IsAuthenticated])
def hospital_profile(request):
    if not is_approved_hospital(request.user):
        return Response({'error': 'Unauthorized'}, status=status.HTTP_403_FORBIDDEN)
        
    hospital_profile = getattr(request.user, "hospital_profile", None)
    if not hospital_profile:
        return Response({'error': 'Profile not found'}, status=status.HTTP_404_NOT_FOUND)

    if request.method == 'GET':
        serializer = HospitalSerializer(hospital_profile)
        return Response(serializer.data)
        
    elif request.method == 'PUT':
        serializer = HospitalSerializer(hospital_profile, data=request.data, partial=True)
        if serializer.is_valid():
            serializer.save()
            
            if 'email' in request.data:
                request.user.email = request.data['email']
                request.user.save()
                
            return Response(serializer.data)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

@api_view(['GET', 'POST'])
@permission_classes([IsAuthenticated])
def complaint_comments(request, pk):
    try:
        complaint = Complaint.objects.get(pk=pk)
    except Complaint.DoesNotExist:
        return Response(status=status.HTTP_404_NOT_FOUND)

    if request.method == 'GET':
        comments = complaint.comments.all().order_by('-created_at')
        from .serializers import CommentSerializer
        serializer = CommentSerializer(comments, many=True)
        return Response(serializer.data)
        
    elif request.method == 'POST':
        content = request.data.get('content')
        if not content:
            return Response({'error': 'Content is required'}, status=status.HTTP_400_BAD_REQUEST)
            
        from complaints.models import Comment
        comment = Comment.objects.create(
            complaint=complaint,
            user=request.user,
            content=content
        )
        from .serializers import CommentSerializer
        serializer = CommentSerializer(comment)
        return Response(serializer.data, status=status.HTTP_201_CREATED)

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def toggle_complaint_like(request, pk):
    try:
        complaint = Complaint.objects.get(pk=pk)
    except Complaint.DoesNotExist:
        return Response(status=status.HTTP_404_NOT_FOUND)

    from complaints.models import Like
    like, created = Like.objects.get_or_create(user=request.user, complaint=complaint)
    
    if not created:
        # User already liked it, so unlike it
        like.delete()
        if complaint.likes > 0:
            complaint.likes -= 1
            complaint.save(update_fields=['likes'])
        return Response({'status': 'unliked', 'likes_count': complaint.likes})
    else:
        # Newly liked
        complaint.likes += 1
        complaint.save(update_fields=['likes'])
        return Response({'status': 'liked', 'likes_count': complaint.likes})

# --- Authority APIs ---

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def authority_dashboard_api(request):
    if not is_approved_authority(request.user):
        return Response({'error': 'Unauthorized'}, status=status.HTTP_403_FORBIDDEN)
    
    hospitals = get_authority_jurisdiction_hospitals(request)
    hospital_ids = hospitals.values_list('id', flat=True)
    
    complaints = Complaint.objects.filter(hospital_id__in=hospital_ids).order_by('-created_at')
    
    total_hospitals = hospitals.count()
    active_complaints = complaints.filter(status__in=['new', 'review', 'responded']).count()
    escalated_complaints = complaints.filter(escalated_to_authority=True).count()
    resolved_complaints = complaints.filter(status='resolved').count()
    
    hospitals_with_warnings = HospitalWarning.objects.filter(
        hospital_id__in=hospital_ids,
        is_active=True
    ).values_list('hospital_id', flat=True).distinct().count()
    
    recent_escalations = complaints.filter(escalated_to_authority=True).order_by('-escalated_at')[:5]
    recent_list = ComplaintSerializer(recent_escalations, many=True, context={'request': request}).data
    
    unread_notifications = AuthorityNotification.objects.filter(recipient=request.user, is_read=False).count()
    
    frozen_hospitals = HospitalFreeze.objects.filter(
        hospital_id__in=hospital_ids,
        status='frozen'
    ).count()
    
    return Response({
        'total_hospitals': total_hospitals,
        'active_complaints': active_complaints,
        'escalated_complaints': escalated_complaints,
        'resolved_complaints': resolved_complaints,
        'hospitals_with_warnings': hospitals_with_warnings,
        'recent_escalations': recent_list,
        'unread_notifications': unread_notifications,
        'frozen_hospitals': frozen_hospitals,
    })

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def authority_escalations_api(request):
    if not is_approved_authority(request.user):
        return Response({'error': 'Unauthorized'}, status=status.HTTP_403_FORBIDDEN)
    
    hospitals = get_authority_jurisdiction_hospitals(request)
    hospital_ids = hospitals.values_list('id', flat=True)
    
    escalated_complaints = Complaint.objects.filter(
        hospital_id__in=hospital_ids,
        escalated_to_authority=True
    ).exclude(status='resolved').order_by('-escalated_at')
    
    serializer = ComplaintSerializer(escalated_complaints, many=True, context={'request': request})
    return Response({'complaints': serializer.data})

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def authority_escalation_detail_api(request, pk):
    if not is_approved_authority(request.user):
        return Response({'error': 'Unauthorized'}, status=status.HTTP_403_FORBIDDEN)
    
    hospitals = get_authority_jurisdiction_hospitals(request)
    hospital_ids = hospitals.values_list('id', flat=True)
    
    try:
        complaint = Complaint.objects.get(pk=pk, hospital_id__in=hospital_ids)
    except Complaint.DoesNotExist:
        return Response(status=status.HTTP_404_NOT_FOUND)
        
    if not complaint.viewed_by_authority:
        complaint.viewed_by_authority = True
        complaint.save()
        ComplaintActivityLog.objects.create(
            complaint=complaint,
            activity_type='authority_viewed',
            performed_by=request.user,
            description=f"Complaint viewed by authority {request.user.username}"
        )
        
    activity_logs = ComplaintActivityLog.objects.filter(complaint=complaint).order_by('-created_at')
    
    return Response({
        'complaint': ComplaintSerializer(complaint, context={'request': request}).data,
        'activity_logs': ComplaintActivityLogSerializer(activity_logs, many=True).data
    })

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def authority_freeze_hospital_api(request, pk):
    if not is_approved_authority(request.user):
        return Response({'error': 'Unauthorized'}, status=status.HTTP_403_FORBIDDEN)
        
    hospitals = get_authority_jurisdiction_hospitals(request)
    try:
        hospital = hospitals.get(pk=pk)
    except User.DoesNotExist:
        return Response({'error': 'Hospital not found in your jurisdiction'}, status=status.HTTP_404_NOT_FOUND)
        
    reason = request.data.get('reason', '')
    description = request.data.get('description', '')
    
    if not reason or not description:
        return Response({'error': 'Reason and description are required'}, status=status.HTTP_400_BAD_REQUEST)
        
    existing_freeze = HospitalFreeze.objects.filter(
        hospital=hospital, status__in=['frozen', 'pending_review']
    ).first()
    
    if existing_freeze:
        return Response({'error': 'This hospital is already frozen or has a pending appeal.'}, status=status.HTTP_400_BAD_REQUEST)
        
    freeze = HospitalFreeze.objects.create(
        hospital=hospital,
        frozen_by=request.user,
        reason=reason,
        description=description,
        status='frozen'
    )
    
    hospital.account_status = 'frozen'
    hospital.is_active = False 
    hospital.save()
    
    Notification.objects.create(
        recipient=hospital,
        title='Account Frozen',
        message=f"Your hospital account has been frozen. Reason: {description}",
        link="/login/"
    )
    
    authority_settings, _ = AuthoritySettings.objects.get_or_create(authority=request.user)
    if authority_settings.freeze_alerts:
        AuthorityNotification.objects.create(
            recipient=request.user,
            notification_type='freeze',
            title='Account Frozen',
            message=f"You froze the account for {hospital.username}. Reason: {description}",
            freeze=freeze,
            link=f"/authority/hospitals/{hospital.id}/"
        )
        
    return Response({'status': 'success', 'message': 'Hospital frozen'})

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def authority_unfreeze_hospital_api(request, pk):
    if not is_approved_authority(request.user):
        return Response({'error': 'Unauthorized'}, status=status.HTTP_403_FORBIDDEN)
        
    hospitals = get_authority_jurisdiction_hospitals(request)
    try:
        hospital = hospitals.get(pk=pk)
    except User.DoesNotExist:
        return Response({'error': 'Hospital not found in your jurisdiction'}, status=status.HTTP_404_NOT_FOUND)
        
    freeze_record = HospitalFreeze.objects.filter(
        hospital=hospital, status__in=['frozen', 'pending_review']
    ).first()
    
    if not freeze_record:
        return Response({'error': 'Hospital is not currently frozen'}, status=status.HTTP_400_BAD_REQUEST)
        
    freeze_record.status = 'reactivated'
    freeze_record.reactivated_at = timezone.now()
    freeze_record.save()
    
    hospital.account_status = 'active'
    hospital.is_active = True
    hospital.save()
    
    Notification.objects.create(
        recipient=hospital,
        title='Account Reactivated',
        message="Your hospital account has been reactivated.",
        link="/hospital/dashboard/"
    )
    
    return Response({'status': 'success', 'message': 'Hospital unfrozen'})

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def authority_issue_warning_api(request, pk):
    if not is_approved_authority(request.user):
        return Response({'error': 'Unauthorized'}, status=status.HTTP_403_FORBIDDEN)
        
    hospitals = get_authority_jurisdiction_hospitals(request)
    try:
        hospital = hospitals.get(pk=pk)
    except User.DoesNotExist:
        return Response({'error': 'Hospital not found in your jurisdiction'}, status=status.HTTP_404_NOT_FOUND)
        
    warning_type = request.data.get('warning_type', 'serious')
    reason = request.data.get('reason', '')
    complaint_id = request.data.get('complaint_id', None)
    
    if not reason:
        return Response({'error': 'Warning reason is required'}, status=status.HTTP_400_BAD_REQUEST)
        
    warning = HospitalWarning.objects.create(
        issued_by=request.user,
        hospital=hospital,
        warning_type=warning_type,
        reason=reason,
        complaint_id=complaint_id if complaint_id else None
    )
    
    Notification.objects.create(
        recipient=hospital,
        title='Warning Issued',
        message=f"You have received a {warning_type} warning: {reason}",
        link="/hospital/dashboard/"
    )
    
    authority_settings, _ = AuthoritySettings.objects.get_or_create(authority=request.user)
    if authority_settings.warning_alerts:
        AuthorityNotification.objects.create(
            recipient=request.user,
            notification_type='warning',
            title='Warning Issued',
            message=f"You issued a {warning_type} warning to {hospital.username}",
            warning=warning,
            link=f"/authority/hospitals/{hospital.id}/"
        )
        
    warning_count = HospitalWarning.objects.filter(hospital=hospital, is_active=True).count()
    if warning_count >= authority_settings.warning_threshold:
        freeze = HospitalFreeze.objects.create(
            hospital=hospital,
            frozen_by=request.user,
            reason='warning_limit',
            description=f"Automatically frozen after receiving {warning_count} active warnings",
            status='frozen'
        )
        hospital.account_status = 'frozen'
        hospital.is_active = False
        hospital.save()
        return Response({
            'status': 'success', 
            'message': f"Hospital frozen due to exceeding warning threshold ({warning_count})",
            'is_frozen': True
        })
        
    return Response({'status': 'success', 'message': f"Warning issued to {hospital.username}", 'is_frozen': False})

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def authority_reports_api(request):
    if not is_approved_authority(request.user):
        return Response({'error': 'Unauthorized'}, status=status.HTTP_403_FORBIDDEN)
        
    hospitals = get_authority_jurisdiction_hospitals(request)
    hospital_ids = hospitals.values_list('id', flat=True)
    complaints = Complaint.objects.filter(hospital_id__in=hospital_ids)
    
    # Simple aggregations
    status_counts = {
        'new': complaints.filter(status='new').count(),
        'review': complaints.filter(status='review').count(),
        'responded': complaints.filter(status='responded').count(),
        'resolved': complaints.filter(status='resolved').count(),
    }
    
    severity_counts = {
        'critical': complaints.filter(severity='critical').count(),
        'high': complaints.filter(severity='high').count(),
        'medium': complaints.filter(severity='medium').count(),
        'low': complaints.filter(severity='low').count(),
    }
    
    return Response({
        'status_counts': status_counts,
        'severity_counts': severity_counts,
        'total_complaints': complaints.count()
    })

@api_view(['GET', 'POST'])
@permission_classes([IsAuthenticated])
def api_support_tickets(request):
    if request.user.role != 'patient':
        return Response({'error': 'Unauthorized'}, status=status.HTTP_403_FORBIDDEN)
        
    from social.models import SupportTicket
    if request.method == 'GET':
        tickets = SupportTicket.objects.filter(user=request.user).order_by('-created_at')
        data = [{
            'id': t.id,
            'subject': t.subject,
            'message': t.message,
            'admin_reply': t.admin_reply,
            'status': t.status,
            'created_at': t.created_at.isoformat(),
            'updated_at': t.updated_at.isoformat(),
        } for t in tickets]
        return Response(data)
        
    elif request.method == 'POST':
        subject = request.data.get('subject')
        message = request.data.get('message')
        if not subject or not message:
            return Response({'error': 'Subject and message are required'}, status=status.HTTP_400_BAD_REQUEST)
            
        ticket = SupportTicket.objects.create(
            user=request.user,
            subject=subject,
            message=message
        )
        return Response({
            'id': ticket.id,
            'subject': ticket.subject,
            'message': ticket.message,
            'admin_reply': ticket.admin_reply,
            'status': ticket.status,
            'created_at': ticket.created_at.isoformat(),
        }, status=status.HTTP_201_CREATED)

@api_view(['GET', 'POST'])
@permission_classes([IsAuthenticated])
def api_support_ticket_detail(request, pk):
    from social.models import SupportTicket
    try:
        ticket = SupportTicket.objects.get(pk=pk)
    except SupportTicket.DoesNotExist:
        return Response(status=status.HTTP_404_NOT_FOUND)
        
    if ticket.user != request.user and request.user.role != 'superadmin':
        return Response({'error': 'Unauthorized'}, status=status.HTTP_403_FORBIDDEN)
        
    if request.method == 'GET':
        from accounts.models import PatientNotificationReply, Notification
        patient_replies = PatientNotificationReply.objects.filter(support_ticket=ticket).order_by('created_at')
        
        # Build chronological thread
        messages = [{
            'sender': 'patient',
            'message': ticket.message,
            'created_at': ticket.created_at.isoformat(),
        }]
        
        notifications = Notification.objects.filter(support_ticket=ticket).order_by('created_at')
        for n in notifications:
            msg_content = n.message
            prefix = f"Admin replied to \"{ticket.subject}\": "
            if msg_content.startswith(prefix):
                msg_content = msg_content[len(prefix):]
            elif msg_content.startswith("Admin replied: "):
                msg_content = msg_content[len("Admin replied: "):]
            
            messages.append({
                'sender': 'admin',
                'message': msg_content,
                'created_at': n.created_at.isoformat(),
            })
            
        for r in patient_replies:
            messages.append({
                'sender': 'patient',
                'message': r.message,
                'created_at': r.created_at.isoformat(),
            })
            
        messages.sort(key=lambda m: m['created_at'])
        
        return Response({
            'id': ticket.id,
            'subject': ticket.subject,
            'status': ticket.status,
            'created_at': ticket.created_at.isoformat(),
            'messages': messages
        })
        
    elif request.method == 'POST':
        message_content = request.data.get('message')
        if not message_content:
            return Response({'error': 'Message is required'}, status=status.HTTP_400_BAD_REQUEST)
            
        if request.user.role == 'patient':
            from accounts.models import Notification, PatientNotificationReply
            notification = Notification.objects.filter(recipient=request.user, support_ticket=ticket).order_by('-created_at').first()
            if not notification:
                notification = Notification.objects.create(
                    recipient=request.user,
                    title="Support Ticket Created",
                    message=f"Your ticket '{ticket.subject}' has been submitted.",
                    support_ticket=ticket
                )
                
            PatientNotificationReply.objects.create(
                notification=notification,
                user=request.user,
                support_ticket=ticket,
                message=message_content
            )
            
            ticket.status = 'open'
            ticket.save()
            
            return Response({'status': 'success', 'message': 'Reply sent'})
        else:
            ticket.admin_reply = message_content
            ticket.status = 'resolved'
            ticket.save()
            
            from accounts.models import Notification
            Notification.objects.create(
                recipient=ticket.user,
                title="Support Ticket Reply",
                message=f"Admin replied to \"{ticket.subject}\": {message_content}",
                support_ticket=ticket
            )
            return Response({'status': 'success', 'message': 'Reply sent'})


# ── Notifications API (works for all roles) ──────────────────────────────────

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def api_notifications_list(request):
    """GET /api/v1/notifications/ — returns user notifications newest first."""
    base_qs = Notification.objects.filter(recipient=request.user)
    unread_count = base_qs.filter(is_read=False).count()
    notifications = base_qs.order_by('-created_at')[:50]
    
    data = []
    for n in notifications:
        data.append({
            'id': n.id,
            'title': n.title,
            'message': n.message,
            'is_read': n.is_read,
            'created_at': n.created_at.isoformat(),
            'link': getattr(n, 'link', ''),
        })
    return Response({'notifications': data, 'unread_count': unread_count})


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def api_notification_mark_read(request, pk):
    """POST /api/v1/notifications/<id>/read/ — marks a single notification as read."""
    try:
        notification = Notification.objects.get(pk=pk, recipient=request.user)
    except Notification.DoesNotExist:
        return Response(status=status.HTTP_404_NOT_FOUND)
    notification.is_read = True
    notification.save(update_fields=['is_read'])
    return Response({'status': 'success'})

@api_view(['GET', 'POST'])
@permission_classes([IsAuthenticated])
def api_patient_settings(request):
    if request.user.role.lower() != 'patient':
        return Response({'error': 'Unauthorized'}, status=status.HTTP_403_FORBIDDEN)
        
    from accounts.models import PatientSettings
    settings_obj, _ = PatientSettings.objects.get_or_create(user=request.user)
    
    if request.method == 'GET':
        return Response({
            'settings': {
                'email_notifications': settings_obj.email_notifications,
                'complaint_status_updates': settings_obj.complaint_status_updates,
                'new_messages': settings_obj.new_messages,
                'authority_responses': settings_obj.authority_responses,
                'show_in_feed': settings_obj.show_in_feed,
                'anonymous_posting': settings_obj.anonymous_posting,
                'show_resolved_publicly': settings_obj.show_resolved_publicly,
                'hide_profile': settings_obj.hide_profile,
                'allow_hospital_contact': settings_obj.allow_hospital_contact,
                'allow_escalation': settings_obj.allow_escalation,
                'theme': settings_obj.theme,
                'phone_number': request.user.phone_number,
            }
        })
        
    if request.method == 'POST':
        data = request.data
        if 'email_notifications' in data:
            settings_obj.email_notifications = data['email_notifications']
        if 'complaint_status_updates' in data:
            settings_obj.complaint_status_updates = data['complaint_status_updates']
        if 'new_messages' in data:
            settings_obj.new_messages = data['new_messages']
        if 'authority_responses' in data:
            settings_obj.authority_responses = data['authority_responses']
        if 'show_in_feed' in data:
            settings_obj.show_in_feed = data['show_in_feed']
        if 'anonymous_posting' in data:
            settings_obj.anonymous_posting = data['anonymous_posting']
        if 'show_resolved_publicly' in data:
            settings_obj.show_resolved_publicly = data['show_resolved_publicly']
        if 'hide_profile' in data:
            settings_obj.hide_profile = data['hide_profile']
        if 'allow_hospital_contact' in data:
            settings_obj.allow_hospital_contact = data['allow_hospital_contact']
        if 'allow_escalation' in data:
            settings_obj.allow_escalation = data['allow_escalation']
        if 'theme' in data:
            settings_obj.theme = data['theme']
            
        if 'phone_number' in data:
            request.user.phone_number = data['phone_number']
            request.user.save(update_fields=['phone_number'])
            
        settings_obj.save()
        return Response({'status': 'success'})


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def api_notification_reply(request, pk):
    """POST /api/v1/notifications/<id>/reply/ — reply to a notification (creates a message if linked to chat)."""
    try:
        notification = Notification.objects.get(pk=pk, recipient=request.user)
    except Notification.DoesNotExist:
        return Response(status=status.HTTP_404_NOT_FOUND)
        
    reply_text = request.data.get('reply_text')
    if not reply_text:
        return Response({'error': 'reply_text is required'}, status=status.HTTP_400_BAD_REQUEST)
        
    # In MedVoice, notifications often have links to chats like /chat/123/
    # If the notification is linked to a conversation, we can create a message there.
    # Otherwise, returning success is sufficient for UI purposes.
    if notification.link and '/chat/' in notification.link:
        import re
        match = re.search(r'/chat/(\d+)/', notification.link)
        if match:
            conversation_id = match.group(1)
            from social.models import Conversation, Message
            try:
                convo = Conversation.objects.get(id=conversation_id)
                recipient = convo.participants.exclude(id=request.user.id).first()
                if request.user in convo.participants.all():
                    Message.objects.create(
                        conversation=convo,
                        sender=request.user,
                        content=reply_text,
                        sender_role=request.user.role,
                        receiver=recipient,
                        related_complaint=convo.complaint
                    )
            except Conversation.DoesNotExist:
                pass

    return Response({'success': True, 'message': 'Reply sent successfully'})


# ── Conversations list API ────────────────────────────────────────────────────

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def api_conversations_list(request):
    """GET /api/v1/conversations/ — returns all conversations for current user."""
    from social.models import Conversation
    conversations = Conversation.objects.filter(participants=request.user).order_by('-updated_at')[:50]
    data = []
    for convo in conversations:
        other = convo.participants.exclude(id=request.user.id).first()
        last_msg = convo.messages.order_by('-created_at').first()
        data.append({
            'id': convo.id,
            'other_user': {
                'id': other.id if other else 0,
                'username': other.username if other else 'Unknown',
                'first_name': other.first_name if other else '',
                'role': other.role if other else '',
            },
            'last_message': last_msg.content if last_msg else '',
            'last_message_at': last_msg.created_at.isoformat() if last_msg else convo.updated_at.isoformat(),
            'unread_count': convo.messages.filter(is_read=False).exclude(sender=request.user).count(),
        })
    return Response({'conversations': data})

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def public_categories_api(request):
    from complaints.models import Category
    categories = Category.objects.filter(is_active=True).order_by('name')
    data = []
    for c in categories:
        data.append({
            'id': c.id,
            'name': c.name,
            'description': c.description,
            'is_active': c.is_active
        })
    return Response(data, status=status.HTTP_200_OK)
