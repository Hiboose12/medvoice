from django.shortcuts import render, redirect, get_object_or_404
from django.contrib import messages
from django.contrib.auth.decorators import login_required
from django.http import JsonResponse
from django.utils import timezone
from django.urls import reverse
from accounts.models import Notification
from complaints.models import Complaint
from django.db.models import Q, Count
# Ensure Count is available (Touched for reload)
from accounts.models import User
from .models import Conversation, Message, SupportTicket


# Create your views here.

def _wants_json(request):
    return (
        request.headers.get("Accept") == "application/json"
        or request.headers.get("X-Requested-With") == "XMLHttpRequest"
        or request.GET.get("format") == "json"
    )


def _participant_name(user, viewer):
    if user.role == 'patient' and user.is_anonymous_public and viewer.role != 'superadmin':
        return "Anonymous User"
    if user.role == 'hospital' and hasattr(user, 'hospital_profile'):
        return user.hospital_profile.hospital_name
    if user.role == 'authority' and hasattr(user, 'authority_profile'):
        return user.authority_profile.authority_name
    return user.get_full_name() or user.username


def _conversation_payload(conversation, viewer):
    other_user = conversation.participants.exclude(id=viewer.id).first()
    latest = conversation.messages.order_by("-created_at").first()
    unread_count = conversation.messages.filter(receiver=viewer, is_read=False).count()
    return {
        "id": conversation.id,
        "other_user": {
            "id": other_user.id,
            "name": _participant_name(other_user, viewer),
            "role": other_user.role,
            "is_online": bool(other_user.last_seen and (timezone.now() - other_user.last_seen).total_seconds() < 60),
        } if other_user else None,
        "complaint": {
            "id": conversation.complaint.id,
            "title": conversation.complaint.title,
            "status": conversation.complaint.status,
        } if conversation.complaint else None,
        "last_message": latest.content if latest else "",
        "last_message_at": latest.created_at.isoformat() if latest else conversation.updated_at.isoformat(),
        "unread_count": unread_count,
        "updated_at": conversation.updated_at.isoformat(),
    }

def support(request):
    return render(request, "social/support.html")

@login_required
def contact_support(request):
    if request.method == "POST":
        subject = request.POST.get('subject')
        message = request.POST.get('message')
        
        if subject and message:
            SupportTicket.objects.create(
                user=request.user,
                subject=subject,
                message=message
            )
            messages.success(request, "Your support request has been submitted successfully! We will notify you when we reply.")
            return redirect('support')
        else:
            messages.error(request, "Please fill in all fields.")
            
    return redirect('support')


@login_required
def chat_home(request):
    if request.user.role == "hospital":
        return redirect("hospital_chat_home")
    if request.user.role == "patient":
        return redirect("patient_chat_home")
    if request.user.role == "authority":
        return redirect("authority_chat_home")
    return _render_chat(request, "social/chat.html")


@login_required
def chat_room(request, conversation_id=None):
    if request.user.role == "hospital":
        if conversation_id is None:
            return redirect("hospital_chat_home")
        return redirect("hospital_chat_room", conversation_id=conversation_id)
    if request.user.role == "patient":
        if conversation_id is None:
            return redirect("patient_chat_home")
        return redirect("patient_chat_room", conversation_id=conversation_id)
    if request.user.role == "authority":
        if conversation_id is None:
            return redirect("authority_chat_home")
        return redirect("authority_chat_room", conversation_id=conversation_id)
    return _render_chat(request, "social/chat.html", conversation_id)


def consolidate_user_conversations(user):
    """
    Merges duplicate conversations for the same set of participants.
    1. Group conversations by participant set.
    2. For duplicates, keep the most recently updated one.
    3. Move messages from others to the keeper.
    4. Delete others.
    """
    conversations = user.conversations.all().prefetch_related('participants', 'messages')
    
    # Group by participant set (using frozenset of IDs for hashability)
    grouped = {}
    for convo in conversations:
        # We only care about 1-on-1 chats mostly, but this handles any set
        parts = frozenset(convo.participants.values_list('id', flat=True))
        if parts not in grouped:
            grouped[parts] = []
        grouped[parts].append(convo)
        
    for parts, convos in grouped.items():
        if len(convos) > 1:
            # Sort by updated_at descending (Keep the latest)
            # If updated_at is same, tie-break by ID
            convos.sort(key=lambda c: (c.updated_at, c.id), reverse=True)
            
            master = convos[0]
            duplicates = convos[1:]
            
            for dup in duplicates:
                # Move messages
                dup.messages.update(conversation=master)
                # Delete duplicate
                dup.delete()

def _render_chat(request, template_name, conversation_id=None):
    # Consolidate duplicates before rendering
    consolidate_user_conversations(request.user)

    conversations = request.user.conversations.annotate(
        unread_count=Count('messages', filter=Q(messages__is_read=False) & Q(messages__receiver=request.user))
    ).order_by("-updated_at")
    active_conversation = None
    messages_list = []

    if conversation_id:
        try:
             active_conversation = Conversation.objects.get(id=conversation_id)
        except Conversation.DoesNotExist:
            pass
        
        if active_conversation:
             if request.user not in active_conversation.participants.all():
                 return render(request, "403.html", status=403)

             # 🛑 Auto-Read Logic: Mark unread messages as read
             unread_msgs = active_conversation.messages.filter(receiver=request.user, is_read=False)
             if unread_msgs.exists():
                 unread_msgs.update(is_read=True)
                 
                 # 🔔 Notification Sync: Mark related notifications as read
                 Notification.objects.filter(
                     recipient=request.user,
                     is_read=False,
                     link__icontains=f"chat/{active_conversation.id}"
                 ).update(is_read=True)

             messages_list = active_conversation.messages.order_by("created_at")

    if _wants_json(request):
        return JsonResponse({
            "conversations": [
                _conversation_payload(conversation, request.user)
                for conversation in conversations
            ],
            "active_conversation_id": active_conversation.id if active_conversation else None,
        })

    return render(request, template_name, {
        "conversations": conversations,
        "active_conversation": active_conversation,
        "messages": messages_list,
    })


@login_required
def patient_chat_view(request):
    if request.user.role != "patient":
        return render(request, "403.html", status=403)
    return _render_chat(request, "patients/chat.html")


@login_required
def patient_chat_room(request, conversation_id):
    if request.user.role != "patient":
        return render(request, "403.html", status=403)
    return _render_chat(request, "patients/chat.html", conversation_id)


@login_required
def hospital_chat_view(request):
    if request.user.role != "hospital":
        return render(request, "403.html", status=403)
    return _render_chat(request, "hospitals/chat.html")


@login_required
def hospital_chat_room(request, conversation_id):
    if request.user.role != "hospital":
        return render(request, "403.html", status=403)
    return _render_chat(request, "hospitals/chat.html", conversation_id)


@login_required
def authority_chat_view(request):
    if request.user.role != "authority":
        return render(request, "403.html", status=403)
    if not request.user.is_approved:
        return redirect('pending_approval')
    return _render_chat(request, "authorities/chat.html")


@login_required
def authority_chat_room(request, conversation_id):
    if request.user.role != "authority":
        return render(request, "403.html", status=403)
    if not request.user.is_approved:
        return redirect('pending_approval')
    return _render_chat(request, "authorities/chat.html", conversation_id)


@login_required
def search_users(request):
    query = request.GET.get("q", "").strip()
    
    if query:
        users = User.objects.filter(
            Q(username__icontains=query) |
            Q(first_name__icontains=query) |
            Q(last_name__icontains=query)
        ).exclude(id=request.user.id)
    else:
        users = User.objects.exclude(id=request.user.id)

    # Exclude anonymous patients for non-admins
    if request.user.role != 'superadmin':
        users = users.exclude(role='patient', settings__anonymous_posting=True)

    users = users[:10]

    results = []
    for user in users:
        # Anonymize if needed
        full_name = user.get_full_name() or user.username
        username = user.username
        if user.role == 'patient' and user.is_anonymous_public and request.user.role != 'superadmin':
             full_name = "Anonymous User"
             username = "anonymous"
        elif user.role == 'hospital' and hasattr(user, 'hospital_profile'):
             full_name = user.hospital_profile.hospital_name
             
        results.append({
            "id": user.id,
            "username": username, 
            "full_name": full_name,
            "role": user.role,
        })
    
    return JsonResponse(results, safe=False)


@login_required
def start_chat(request, user_id):
    other_user = get_object_or_404(User, id=user_id)
    
    conversation = Conversation.objects.filter(
        participants=request.user
    ).filter(
        participants=other_user
    ).first()
    
    if not conversation:
        conversation = Conversation.objects.create(complaint=None)
        conversation.participants.add(request.user, other_user)

    if _wants_json(request):
        return JsonResponse({
            "success": True,
            "conversation": _conversation_payload(conversation, request.user),
        })
    
    if request.user.role == "hospital":
        return redirect("hospital_chat_room", conversation_id=conversation.id)
    if request.user.role == "patient":
        return redirect("patient_chat_room", conversation_id=conversation.id)
    if request.user.role == "authority":
        return redirect("authority_chat_room", conversation_id=conversation.id)
    return redirect("chat_room", conversation_id=conversation.id)


@login_required
def patient_start_chat(request, user_id):
    if request.user.role != "patient":
        return render(request, "403.html", status=403)
    return start_chat(request, user_id)


@login_required
def hospital_start_chat(request, user_id):
    if request.user.role != "hospital":
        return render(request, "403.html", status=403)
    return start_chat(request, user_id)


@login_required
def start_complaint_chat(request, complaint_id):
    complaint = get_object_or_404(Complaint, id=complaint_id)

    # Allow authority to join complaint chat?
    # Logic below assumes only user and hospital. 
    # For now, sticking to user/hospital for complaint chats unless authority is explicitly added.
    # But authorities can view complaints. If they start chat, they join.
    
    # Original logic strict on participants
    # if request.user not in [complaint.user, complaint.hospital]:
    #    return render(request, "403.html", status=403)
    
    if request.user.role == 'authority':
        # Authority starting chat about complaint
        # Check jurisdiction? For now simplify -> allowed if not forbidden
        pass
    elif request.user not in [complaint.user, complaint.hospital]:
         return render(request, "403.html", status=403)

    if not complaint.hospital and request.user.role != 'authority':
         messages.error(request, "No hospital is assigned to this complaint yet.")
         return redirect("complaint_detail", complaint_id=complaint.id)

    # 🔍 Deduplication: Reuse existing chat between Patient & Hospital
    # This logic is specific to Patient-Hospital. 
    # If Authority, logic is different (Authority-Patient or Authority-Hospital).
    
    # TODO: Refine for Authority-Complaint chat. 
    # For now, let's keep it simple: If Authority calls this, redirect to standard start_chat with the target?
    # But start_complaint_chat implies the chat IS about the complaint.
    
    # Current implementation supports Patient-Hospital.
    conversation = Conversation.objects.filter(
        participants=complaint.user
    ).filter(
        participants=complaint.hospital
    ).first()

    if not conversation:
        conversation = Conversation.objects.create(complaint=complaint)
        conversation.participants.add(complaint.user, complaint.hospital)
    else:
        if not conversation.complaint:
            conversation.complaint = complaint
            conversation.save(update_fields=['complaint'])

    if _wants_json(request):
        return JsonResponse({
            "success": True,
            "conversation": _conversation_payload(conversation, request.user),
        })

    if request.user.role == "hospital":
        return redirect("hospital_chat_room", conversation_id=conversation.id)
    if request.user.role == "patient":
        return redirect("patient_chat_room", conversation_id=conversation.id)
    if request.user.role == "authority":
        return redirect("authority_chat_room", conversation_id=conversation.id)
    return redirect("chat_room", conversation_id=conversation.id)


@login_required
def get_complaint_chat_info(request, complaint_id):
    """API to get chat info for a complaint, used by Modal"""
    complaint = get_object_or_404(Complaint, id=complaint_id)
    
    # Access checks
    if request.user.role == 'hospital' and complaint.hospital != request.user:
        return JsonResponse({'error': 'Unauthorized'}, status=403)
    if request.user.role == 'patient' and complaint.user != request.user:
        return JsonResponse({'error': 'Unauthorized'}, status=403)
        
    # Ensure conversation exists (Reuse logic)
    conversation = Conversation.objects.filter(
        participants=complaint.user
    ).filter(
        participants=complaint.hospital
    ).first()

    if not conversation:
        conversation = Conversation.objects.create(complaint=complaint)
        conversation.participants.add(complaint.user, complaint.hospital)
    elif not conversation.complaint:
        # Upgrade to complaint chat if generic
        conversation.complaint = complaint
        conversation.save(update_fields=['complaint'])
        
    patient_name = complaint.user.get_full_name() or complaint.user.username
    if complaint.user.role == 'patient' and complaint.user.is_anonymous_public and request.user.role != 'superadmin':
         patient_name = "Anonymous User"

    return JsonResponse({
        "conversation_id": conversation.id,
        "patient_name": patient_name,
        "hospital_name": complaint.hospital.hospital_profile.hospital_name if hasattr(complaint.hospital, 'hospital_profile') else complaint.hospital.username
    })


@login_required
def get_messages(request, conversation_id):
    conversation = get_object_or_404(Conversation, id=conversation_id)
    if request.user not in conversation.participants.all():
        return JsonResponse({"error": "Unauthorized"}, status=403)

    request.user.last_seen = timezone.now()
    request.user.save(update_fields=['last_seen'])

    last_id = request.GET.get("last_id")
    messages = conversation.messages.all().order_by("created_at")
    
    if last_id:
        messages = messages.filter(id__gt=last_id)

    unread_messages = messages.exclude(sender=request.user).filter(is_read=False)
    if unread_messages.exists():
        unread_messages.update(is_read=True)
        
        Notification.objects.filter(
             recipient=request.user,
             is_read=False,
             link__icontains=f"chat/{conversation.id}"
         ).update(is_read=True)

    other_user = conversation.participants.exclude(id=request.user.id).first()
    is_online = False
    if other_user and other_user.last_seen:
        is_online = (timezone.now() - other_user.last_seen).total_seconds() < 60

    read_message_ids = list(conversation.messages.filter(sender=request.user, is_read=True).values_list('id', flat=True))

    results = []
    for msg in messages:
        sender_name = msg.sender.username
        if msg.sender.role == 'patient' and msg.sender.is_anonymous_public and request.user.role != 'superadmin':
             sender_name = "Anonymous User"
        elif msg.sender.role == 'hospital' and hasattr(msg.sender, 'hospital_profile'):
             sender_name = msg.sender.hospital_profile.hospital_name
        elif hasattr(msg.sender, 'get_full_name'):
             sender_name = msg.sender.get_full_name() or msg.sender.username

        results.append({
            "id": msg.id,
            "sender": sender_name,
            "sender_role": msg.sender_role, 
            "content": msg.content,
            "attachment_url": msg.attachment.url if msg.attachment else None,
            "created_at": msg.created_at.strftime("%I:%M %p"),
            "is_me": msg.sender == request.user,
            "is_read": msg.is_read
        })
    
    return JsonResponse({
        "messages": results,
        "is_online": is_online,
        "read_message_ids": read_message_ids
    }, safe=False)


@login_required
def send_message(request, conversation_id):
    if request.method == "POST":
        conversation = get_object_or_404(Conversation, id=conversation_id)
        
        if request.user not in conversation.participants.all():
            return JsonResponse({"error": "Unauthorized"}, status=403)

        content = request.POST.get("content", "").strip()
        attachment = request.FILES.get("attachment")

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
            conversation.save(update_fields=["updated_at"])

            if recipient:
                if conversation.complaint:
                    sender_name = request.user.get_full_name() or request.user.username
                    if request.user.role == 'hospital' and hasattr(request.user, 'hospital_profile'):
                         sender_name = request.user.hospital_profile.hospital_name
                    elif request.user.role == 'authority' and hasattr(request.user, 'authority_profile'):
                        sender_name = request.user.authority_profile.authority_name

                    if recipient.role == 'patient':
                         chat_link = reverse("patient_chat_room", args=[conversation.id])
                    elif recipient.role == 'hospital':
                         chat_link = reverse("hospital_chat_room", args=[conversation.id])
                    elif recipient.role == 'authority':
                         chat_link = reverse("authority_chat_room", args=[conversation.id])
                    else:
                         chat_link = reverse("chat_room", args=[conversation.id])

                    Notification.objects.create(
                        recipient=recipient,
                        title=f"New message from {sender_name}",
                        message=f"You have a new message regarding complaint: {conversation.complaint.title}",
                        link=chat_link, 
                    )
                else:
                    if recipient.role == "hospital":
                        chat_link = reverse("hospital_chat_room", args=[conversation.id])
                    elif recipient.role == "patient":
                        chat_link = reverse("patient_chat_room", args=[conversation.id])
                    elif recipient.role == "authority":
                        chat_link = reverse("authority_chat_room", args=[conversation.id])
                    else:
                        chat_link = reverse("chat_room", args=[conversation.id])
                    
                    Notification.objects.create(
                        recipient=recipient,
                        title="New message",
                        message=f"You have a new message from {request.user.get_full_name() or request.user.username}.",
                        link=chat_link,
                    )
            return JsonResponse({
                "status": "ok",
                "message_id": message.id,
                "attachment_url": message.attachment.url if message.attachment else None,
                "timestamp": message.created_at.strftime("%I:%M %p")
            })

        return JsonResponse({"error": "Empty message"}, status=400)

    return JsonResponse({"error": "Invalid request"}, status=400)


@login_required
def delete_message(request, message_id):
    if request.method == "POST":
        message = get_object_or_404(Message, id=message_id)
        
        if message.sender != request.user:
            return JsonResponse({"error": "Unauthorized"}, status=403)
            
        if message.is_read:
            return JsonResponse({"error": "Cannot delete read messages"}, status=403)
            
        message.delete()
        return JsonResponse({"status": "ok"})
        
    return JsonResponse({"error": "Invalid request method"}, status=405)
