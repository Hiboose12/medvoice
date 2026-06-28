from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework import status
from django.utils import timezone
from django.shortcuts import get_object_or_404
from django.urls import reverse

from social.models import Conversation, Message
from accounts.models import Notification

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def api_get_messages(request, conversation_id):
    conversation = get_object_or_404(Conversation, id=conversation_id)
    if request.user not in conversation.participants.all():
        return Response({'error': 'Unauthorized'}, status=status.HTTP_403_FORBIDDEN)
        
    request.user.last_seen = timezone.now()
    request.user.save(update_fields=['last_seen'])
    
    last_id = request.GET.get('last_id')
    messages = conversation.messages.all().order_by('created_at')
    if last_id:
        messages = messages.filter(id__gt=last_id)
        
    unread_messages = messages.exclude(sender=request.user).filter(is_read=False)
    if unread_messages.exists():
        unread_messages.update(is_read=True)
        Notification.objects.filter(recipient=request.user, is_read=False, link__icontains=f'chat/{conversation.id}').update(is_read=True)
        
    other_user = conversation.participants.exclude(id=request.user.id).first()
    is_online = False
    if other_user and other_user.last_seen:
        is_online = (timezone.now() - other_user.last_seen).total_seconds() < 60
        
    read_message_ids = list(conversation.messages.filter(sender=request.user, is_read=True).values_list('id', flat=True))
    
    results = []
    for msg in messages:
        sender_name = msg.sender.username
        if msg.sender.role == 'patient' and msg.sender.is_anonymous_public and (request.user.role != 'superadmin'):
            sender_name = 'Anonymous User'
        elif msg.sender.role == 'hospital' and hasattr(msg.sender, 'hospital_profile'):
            sender_name = msg.sender.hospital_profile.hospital_name
        elif hasattr(msg.sender, 'get_full_name'):
            sender_name = msg.sender.get_full_name() or msg.sender.username
            
        results.append({
            'id': msg.id, 
            'sender': sender_name, 
            'sender_role': msg.sender_role, 
            'content': msg.content, 
            'attachment_url': msg.attachment.url if msg.attachment else None, 
            'created_at': msg.created_at.strftime('%I:%M %p'), 
            'is_me': msg.sender == request.user, 
            'is_read': msg.is_read
        })
        
    return Response({'messages': results, 'is_online': is_online, 'read_message_ids': read_message_ids})

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def api_send_message(request, conversation_id):
    conversation = get_object_or_404(Conversation, id=conversation_id)
    if request.user not in conversation.participants.all():
        return Response({'error': 'Unauthorized'}, status=status.HTTP_403_FORBIDDEN)
        
    content = request.data.get('content', '').strip()
    attachment = request.FILES.get('attachment')
    recipient = conversation.participants.exclude(id=request.user.id).first()
    
    if content or attachment:
        message = Message.objects.create(
            conversation=conversation, 
            sender=request.user, 
            content=content, 
            attachment=attachment, 
            sender_role=request.user.role, 
            receiver=recipient, 
            related_complaint=conversation.complaint
        )
        conversation.updated_at = timezone.now()
        conversation.save(update_fields=['updated_at'])
        
        if recipient:
            if conversation.complaint:
                sender_name = request.user.get_full_name() or request.user.username
                if request.user.role == 'patient' and request.user.is_anonymous_public and recipient.role != 'superadmin':
                    sender_name = 'Anonymous User'
                elif request.user.role == 'hospital' and hasattr(request.user, 'hospital_profile'):
                    sender_name = request.user.hospital_profile.hospital_name
                elif request.user.role == 'authority' and hasattr(request.user, 'authority_profile'):
                    sender_name = request.user.authority_profile.authority_name
                
                Notification.objects.create(
                    recipient=recipient, 
                    title=f'New message from {sender_name}', 
                    message=f'You have a new message regarding complaint: {conversation.complaint.title}', 
                    link=f'/patient/chat/{conversation.id}/' if recipient.role == 'patient' else f'/chat/{conversation.id}/'
                )
            else:
                sender_name = request.user.get_full_name() or request.user.username
                if request.user.role == 'patient' and request.user.is_anonymous_public and recipient.role != 'superadmin':
                    sender_name = 'Anonymous User'
                Notification.objects.create(
                    recipient=recipient, 
                    title='New message', 
                    message=f'You have a new message from {sender_name}.', 
                    link=f'/patient/chat/{conversation.id}/' if recipient.role == 'patient' else f'/chat/{conversation.id}/'
                )
        return Response({
            'status': 'ok', 
            'message_id': message.id, 
            'attachment_url': message.attachment.url if message.attachment else None, 
            'timestamp': message.created_at.strftime('%I:%M %p')
        })
    return Response({'error': 'Empty message'}, status=status.HTTP_400_BAD_REQUEST)

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def api_start_chat(request, user_id):
    from accounts.models import User
    other_user = get_object_or_404(User, id=user_id)
    conversation = Conversation.objects.filter(participants=request.user).filter(participants=other_user).first()
    if not conversation:
        conversation = Conversation.objects.create(complaint=None)
        conversation.participants.add(request.user, other_user)
    return Response({'success': True, 'conversation_id': conversation.id})

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def api_start_complaint_chat(request, complaint_id):
    from complaints.models import Complaint
    complaint = get_object_or_404(Complaint, id=complaint_id)
    if request.user.role != 'authority' and request.user not in [complaint.user, complaint.hospital]:
        return Response({'error': 'Unauthorized'}, status=status.HTTP_403_FORBIDDEN)
    
    if not complaint.hospital and request.user.role != 'authority':
        return Response({'error': 'No hospital assigned'}, status=status.HTTP_400_BAD_REQUEST)
        
    conversation = Conversation.objects.filter(participants=complaint.user).filter(participants=complaint.hospital).first()
    if not conversation:
        conversation = Conversation.objects.create(complaint=complaint)
        conversation.participants.add(complaint.user, complaint.hospital)
    elif not conversation.complaint:
        conversation.complaint = complaint
        conversation.save(update_fields=['complaint'])
        
    return Response({'success': True, 'conversation_id': conversation.id})
