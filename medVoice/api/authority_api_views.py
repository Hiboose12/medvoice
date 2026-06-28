from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework import status
from django.db.models import Count, Q
from django.utils import timezone
from accounts.models import User
from authorities.models import AuthorityNotification, HospitalWarning, HospitalFreeze, ComplaintActivityLog
from complaints.models import Complaint
from .serializers import ComplaintSerializer
from authorities.views import get_authority_jurisdiction_hospitals

def is_approved_authority(user):
    return user.role == 'authority' and user.is_approved

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def authority_complaints_api(request):
    if not is_approved_authority(request.user):
        return Response({'error': 'Unauthorized'}, status=status.HTTP_403_FORBIDDEN)
        
    hospitals = get_authority_jurisdiction_hospitals(request)
    hospital_ids = hospitals.values_list('id', flat=True)
    
    status_filter = request.GET.get('status', 'all')
    complaints = Complaint.objects.filter(hospital_id__in=hospital_ids)
    
    if status_filter != 'all':
        complaints = complaints.filter(status=status_filter)
        
    complaints = complaints.order_by('-created_at')
    
    serializer = ComplaintSerializer(complaints, many=True, context={'request': request})
    return Response({'complaints': serializer.data})

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def authority_complaint_detail_api(request, pk):
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
        complaint.save(update_fields=['viewed_by_authority'])
        
    serializer = ComplaintSerializer(complaint, context={'request': request})
    return Response(serializer.data)

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def authority_hospitals_api(request):
    if not is_approved_authority(request.user):
        return Response({'error': 'Unauthorized'}, status=status.HTTP_403_FORBIDDEN)
        
    hospitals = get_authority_jurisdiction_hospitals(request).annotate(
        complaint_count=Count('hospital_complaints'),
        resolved_count=Count('hospital_complaints', filter=Q(hospital_complaints__status='resolved')),
        active_warnings=Count('received_warnings', filter=Q(received_warnings__is_active=True))
    )
    
    data = []
    for h in hospitals:
        freeze_record = HospitalFreeze.objects.filter(hospital=h).order_by('-frozen_at').first()
        is_frozen = freeze_record.status == 'frozen' if freeze_record else False
        
        data.append({
            'id': h.id,
            'username': h.username,
            'hospital_name': h.hospital_profile.hospital_name if hasattr(h, 'hospital_profile') else h.username,
            'email': h.email,
            'phone_number': h.profile.phone_number if hasattr(h, 'profile') else '',
            'license_number': h.hospital_profile.license_number if hasattr(h, 'hospital_profile') else '',
            'account_status': h.account_status,
            'complaint_count': h.complaint_count,
            'resolved_count': h.resolved_count,
            'active_warnings': h.active_warnings,
            'is_frozen': is_frozen,
        })
        
    return Response({'hospitals': data})

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def authority_hospital_detail_api(request, pk):
    if not is_approved_authority(request.user):
        return Response({'error': 'Unauthorized'}, status=status.HTTP_403_FORBIDDEN)
        
    hospitals = get_authority_jurisdiction_hospitals(request)
    try:
        hospital = hospitals.get(pk=pk)
    except User.DoesNotExist:
        return Response(status=status.HTTP_404_NOT_FOUND)
        
    complaints = Complaint.objects.filter(hospital=hospital).order_by('-created_at')
    warnings = HospitalWarning.objects.filter(hospital=hospital).order_by('-created_at')
    freezes = HospitalFreeze.objects.filter(hospital=hospital).order_by('-frozen_at')
    
    hospital_data = {
        'id': hospital.id,
        'hospital_name': hospital.hospital_profile.hospital_name if hasattr(hospital, 'hospital_profile') else hospital.username,
        'hospital_type': hospital.hospital_profile.hospital_type if hasattr(hospital, 'hospital_profile') else '',
        'registration_number': hospital.hospital_profile.registration_number if hasattr(hospital, 'hospital_profile') else '',
        'email': hospital.email,
        'phone_number': hospital.hospital_profile.contact_number if hasattr(hospital, 'hospital_profile') else '',
        'account_status': hospital.account_status,
        'license_number': hospital.hospital_profile.license_number if hasattr(hospital, 'hospital_profile') else '',
        'license_document': request.build_absolute_uri(hospital.hospital_profile.license_document.url) if hasattr(hospital, 'hospital_profile') and hospital.hospital_profile.license_document else None,
        'address': hospital.hospital_profile.address if hasattr(hospital, 'hospital_profile') else '',
        'district': hospital.hospital_profile.district if hasattr(hospital, 'hospital_profile') else '',
        'state': hospital.hospital_profile.state if hasattr(hospital, 'hospital_profile') else '',
        'pincode': hospital.hospital_profile.pincode if hasattr(hospital, 'hospital_profile') else '',
        'date_joined': hospital.date_joined.isoformat() if hospital.date_joined else None,
    }
    
    return Response({
        'hospital': hospital_data,
        'complaints': ComplaintSerializer(complaints, many=True, context={'request': request}).data,
        'warnings': [{'id': w.id, 'type': w.warning_type, 'reason': w.reason, 'is_active': w.is_active, 'created_at': w.created_at.isoformat()} for w in warnings],
        'freezes': [{'id': f.id, 'status': f.status, 'reason': f.reason, 'created_at': f.frozen_at.isoformat() if f.frozen_at else None} for f in freezes],
    })

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def authority_warnings_api(request):
    if not is_approved_authority(request.user):
        return Response({'error': 'Unauthorized'}, status=status.HTTP_403_FORBIDDEN)
        
    hospitals = get_authority_jurisdiction_hospitals(request)
    hospital_ids = hospitals.values_list('id', flat=True)
    
    warnings = HospitalWarning.objects.filter(hospital_id__in=hospital_ids).order_by('-created_at')
    
    data = []
    for w in warnings:
        data.append({
            'id': w.id,
            'hospital_name': w.hospital.hospital_profile.hospital_name if hasattr(w.hospital, 'hospital_profile') else w.hospital.username,
            'type': w.warning_type,
            'reason': w.reason,
            'is_active': w.is_active,
            'created_at': w.created_at.isoformat()
        })
        
    return Response({'warnings': data})

@api_view(['GET', 'PUT'])
@permission_classes([IsAuthenticated])
def authority_profile_api(request):
    if request.user.role != 'authority':
        return Response({'error': 'Unauthorized'}, status=status.HTTP_403_FORBIDDEN)
        
    authority = getattr(request.user, 'authority_profile', None)
    if not authority:
        return Response({'error': 'Authority profile not found'}, status=status.HTTP_404_NOT_FOUND)
        
    from .serializers import AuthoritySerializer
    if request.method == 'GET':
        return Response(AuthoritySerializer(authority).data)
    elif request.method == 'PUT':
        serializer = AuthoritySerializer(authority, data=request.data, partial=True)
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

@api_view(['GET', 'PUT'])
@permission_classes([IsAuthenticated])
def authority_settings_api(request):
    if request.user.role != 'authority':
        return Response({'error': 'Unauthorized'}, status=status.HTTP_403_FORBIDDEN)
        
    authority = getattr(request.user, 'authority_profile', None)
    if not authority:
        return Response({'error': 'Authority profile not found'}, status=status.HTTP_404_NOT_FOUND)
        
    from authorities.models import AuthoritySettings
    from .serializers import AuthoritySettingsSerializer
    
    settings, created = AuthoritySettings.objects.get_or_create(authority=request.user)
    
    if request.method == 'GET':
        return Response(AuthoritySettingsSerializer(settings).data)
    elif request.method == 'PUT':
        serializer = AuthoritySettingsSerializer(settings, data=request.data, partial=True)
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
