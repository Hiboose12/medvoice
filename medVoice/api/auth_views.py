from rest_framework import status
from rest_framework.response import Response
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated, AllowAny
from rest_framework.authtoken.models import Token
from django.contrib.auth import authenticate
from .serializers import UserSerializer, PatientRegistrationSerializer, HospitalRegistrationSerializer, AuthorityRegistrationSerializer

@api_view(['POST'])
@permission_classes([AllowAny])
def register_patient(request):
    serializer = PatientRegistrationSerializer(data=request.data)
    if serializer.is_valid():
        user = serializer.save()
        from django.contrib.auth import login
        login(request, user)
        token, created = Token.objects.get_or_create(user=user)
        return Response({
            'token': token.key,
            'user': UserSerializer(user, context={'request': request}).data
        }, status=status.HTTP_201_CREATED)
    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

@api_view(['POST'])
@permission_classes([AllowAny])
def register_hospital(request):
    serializer = HospitalRegistrationSerializer(data=request.data)
    if serializer.is_valid():
        user = serializer.save()
        from django.contrib.auth import login
        login(request, user)
        token, created = Token.objects.get_or_create(user=user)
        return Response({
            'token': token.key,
            'user': UserSerializer(user, context={'request': request}).data
        }, status=status.HTTP_201_CREATED)
    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

@api_view(['POST'])
@permission_classes([AllowAny])
def register_authority(request):
    serializer = AuthorityRegistrationSerializer(data=request.data)
    if serializer.is_valid():
        user = serializer.save()
        from django.contrib.auth import login
        login(request, user)
        token, created = Token.objects.get_or_create(user=user)
        return Response({
            'token': token.key,
            'user': UserSerializer(user, context={'request': request}).data
        }, status=status.HTTP_201_CREATED)
    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

@api_view(['POST'])
@permission_classes([AllowAny])
def login_view(request):
    username = request.data.get('username') or request.data.get('email')
    password = request.data.get('password')

    if not username or not password:
        return Response({'error': 'Please provide both username/email and password'}, status=status.HTTP_400_BAD_REQUEST)

    user = authenticate(username=username, password=password)

    if not user and '@' in username:
        from django.contrib.auth import get_user_model
        User = get_user_model()
        user_obj = User.objects.filter(email=username).first()
        if user_obj:
            user = authenticate(username=user_obj.username, password=password)

    if not user:
        from django.contrib.auth import get_user_model
        User = get_user_model()
        disabled_user = User.objects.filter(username=username).first()
        if not disabled_user and '@' in username:
            disabled_user = User.objects.filter(email=username).first()
            
        if disabled_user and not disabled_user.is_active and disabled_user.check_password(password):
            if disabled_user.account_status == 'frozen':
                return Response({'error': 'Account frozen', 'is_frozen': True, 'user_id': disabled_user.id}, status=status.HTTP_403_FORBIDDEN)
            if disabled_user.role in ['hospital', 'authority'] and not disabled_user.is_approved:
                return Response({'error': 'Account pending approval'}, status=status.HTTP_403_FORBIDDEN)

        return Response({'error': 'Invalid Credentials'}, status=status.HTTP_401_UNAUTHORIZED)

    from django.contrib.auth import login
    login(request, user)

    token, created = Token.objects.get_or_create(user=user)
    return Response({
        'token': token.key,
        'user': UserSerializer(user, context={'request': request}).data
    }, status=status.HTTP_200_OK)

@api_view(['POST'])
@permission_classes([AllowAny])
def submit_appeal(request):
    from django.contrib.auth import get_user_model
    from django.utils import timezone
    from authorities.models import HospitalFreeze
    from accounts.models import Notification
    from authorities.models import AuthorityNotification
    from django.urls import reverse
    User = get_user_model()
    
    user_id = request.data.get('user_id')
    explanation = request.data.get('reason')
    evidence = request.FILES.get('evidence')
    
    if not user_id or not explanation:
        return Response({'error': 'User ID and reason are required'}, status=status.HTTP_400_BAD_REQUEST)
        
    try:
        user = User.objects.get(id=user_id)
        
        freeze_record = HospitalFreeze.objects.filter(
            hospital=user
        ).order_by('-frozen_at').first()
        
        if not freeze_record or freeze_record.status not in ['frozen', 'pending_review', 'permanently_blocked']:
            if user.account_status != 'frozen':
                return Response({'error': 'Account is not currently frozen'}, status=status.HTTP_400_BAD_REQUEST)
                
            user.reactivation_requested = True
            user.reactivation_reason = explanation
            if evidence:
                user.reactivation_evidence = evidence
            user.save()
            
            from accounts.models import UserActivity
            UserActivity.objects.create(
                user=user,
                action_type='Reactivation Requested',
                description=f"User submitted reactivation request: {explanation}"
            )
            return Response({'status': 'success', 'message': 'Appeal submitted successfully'})
        if freeze_record.status == 'frozen':
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
                    Notification.objects.create(
                        recipient=frozen_by_user,
                        title="Hospital Appeal Received",
                        message=f"Hospital {user.username} has submitted an appeal for their frozen account.",
                        link=f"/admin/users/{user.id}/activity/"
                    )
                elif frozen_by_user.role == 'authority':
                    # Notify authority
                    AuthorityNotification.objects.create(
                        recipient=frozen_by_user,
                        notification_type='explanation',
                        title="Appeal Received",
                        message=f"Hospital {user.username} has submitted an appeal for their frozen account.",
                        freeze=freeze_record,
                        link=f"/authority/hospitals/review/{freeze_record.id}/"
                    )
            else:
                # Fallback: notify the assigned authority if any
                if hasattr(user, 'hospital_profile') and user.hospital_profile.authority:
                    authority_user = user.hospital_profile.authority.user
                    AuthorityNotification.objects.create(
                        recipient=authority_user,
                        notification_type='explanation',
                        title="Appeal Received",
                        message=f"Hospital {user.username} has submitted an appeal for their frozen account.",
                        freeze=freeze_record,
                        link=f"/authority/hospitals/review/{freeze_record.id}/"
                    )
                    
            return Response({'status': 'success', 'message': 'Appeal submitted successfully'})
        else:
             return Response({'error': 'Appeal already submitted or account permanently blocked'}, status=status.HTTP_400_BAD_REQUEST)
             
    except User.DoesNotExist:
        return Response({'error': 'User not found'}, status=status.HTTP_404_NOT_FOUND)

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def current_user(request):
    serializer = UserSerializer(request.user, context={'request': request})
    return Response(serializer.data)
