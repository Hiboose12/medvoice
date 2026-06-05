from django.shortcuts import render, redirect, get_object_or_404
from django.http import JsonResponse
from django.contrib.auth.decorators import login_required
from django.views.decorators.csrf import csrf_exempt
from django.views.decorators.http import require_http_methods
from django.db.models import Q
from django.contrib import messages
from django.urls import reverse
from django.utils import timezone
from accounts.models import User, Notification
from .forms import ComplaintForm
from .models import Complaint, Like, Comment, Category, HospitalResponse
from social.models import Conversation


@login_required
def feed(request):
    query = request.GET.get('q')

    # 🔒 Privacy Filter:
    # 1. Show if 'show_in_feed' is True
    # 2. Show if Settings are missing (default to Public)
    # 3. Show if current user is the author
    # 4. Show if current user is Superadmin
    
    privacy_filter = Q(user__settings__show_in_feed=True) | Q(user__settings__isnull=True) | Q(user=request.user)
    
    from django.db.models import Exists, OuterRef

    if request.user.role == "superadmin":
        complaints = Complaint.objects.all().order_by('-created_at')
    else:
        # Exclude blocked users
        complaints = Complaint.objects.filter(privacy_filter).exclude(user__account_status='blocked').order_by('-created_at')

    # Annotate with is_liked
    is_liked_subquery = Like.objects.filter(
        complaint=OuterRef('pk'),
        user=request.user
    )
    
    from django.db.models import Prefetch
    from .models import Comment
    
    # Prefetch comments excluding those from blocked users
    active_comments = Comment.objects.exclude(user__account_status='blocked').select_related('user')
    
    # Prefetch hospital responses excluding those from blocked hospitals
    active_responses = HospitalResponse.objects.exclude(hospital__account_status='blocked').select_related('hospital')

    complaints = complaints.annotate(is_liked=Exists(is_liked_subquery)).prefetch_related(
        Prefetch('hospital_responses', queryset=active_responses), 
        'hospital_responses__hospital',
        Prefetch('comments', queryset=active_comments)
    )

    if query:
        # 🔍 Search Users (Exclude blocked)
        users = User.objects.filter(
            Q(username__icontains=query) |
            Q(first_name__icontains=query) |
            Q(last_name__icontains=query)
        ).exclude(account_status='blocked')[:5] # Limit to 5 users for the feed preview

        # 🔍 Construct Query
        complaint_filter = Q(title__icontains=query) | \
                           Q(description__icontains=query) | \
                           Q(hospital__username__icontains=query) | \
                           Q(category__icontains=query)
        
        complaints = complaints.filter(complaint_filter)

    else:
        users = User.objects.none()
    
    # Get hospitals for edit modal dropdown
    hospitals = User.objects.filter(role='hospital', is_approved=True)
    
    # Get categories for edit modal dropdown
    categories = Category.objects.filter(is_active=True)

    return render(request, 'complaints/feed.html', {
        'complaints': complaints,
        'users': users,
        'query': query,
        'hospitals': hospitals,
        'categories': categories
    })


@login_required
def upload_complaint(request):
    if request.method == 'POST':
        form = ComplaintForm(request.POST, request.FILES)

        if form.is_valid():
            complaint = form.save(commit=False)
            complaint.user = request.user
            # ==========================================
            # 🤖 AI CONTENT VALIDATION START
            # ==========================================
            from ai_verification.services import TextValidationService, ImageValidationService
            from ai_verification.models import TrainingData
            
            # 1. Text Validation
            full_text = f"{complaint.title} {complaint.description}"
            is_text_valid, text_score = TextValidationService.validate(full_text)
            
            # 2. Image Validation
            is_image_valid = False
            image_score = 0.0
            
            # Check if image is uploaded - Use form.cleaned_data or complaint.evidence
            if complaint.evidence:
                try:
                   is_image_valid, image_score = ImageValidationService.validate(complaint.evidence)
                except Exception as e:
                    print(f"Image validation skipped: {e}")
                    pass
            
            # 3. Combined Logic: Text OR Image must be valid
            # Requirement: "IF Text is valid OR Image is valid -> Allow post."
            
            # If no image, then Text MUST be valid.
            if not complaint.evidence:
                is_valid_post = is_text_valid
            else:
                 # If image validation failed (e.g. missing libs returning False), we rely on text.
                 # If image is valid, we allow it regardless of text.
                is_valid_post = is_text_valid or is_image_valid
                
                # Edge case: If text is short/ambiguous (score < 0.7) but image is clearly hospital (score > 0.65), we allow.
                # If text is "pain" (valid keyword) but image is "Maya" (invalid), we allows. 
                # This matches "OR" logic.


            # 4. Save Training Data & Handle Rejection
            if not is_valid_post:
                # Log to DB for future training
                try:
                    TrainingData.objects.create(
                        text_content=full_text,
                        image=complaint.evidence if complaint.evidence else None,
                        is_hospital_related=False,
                        ai_confidence=max(text_score, image_score),
                        reviewed_by=None 
                    )
                except Exception as e:
                    print(f"Error saving training data: {e}")
                
                if request.headers.get('x-requested-with') == 'XMLHttpRequest':
                    return JsonResponse({
                        'success': False,
                        'error': "This platform only accepts hospital-related complaints. Your post does not appear to be related to hospital services."
                    })

                messages.error(request, "This platform only accepts hospital-related complaints. Your post does not appear to be related to hospital services.")
                
                # We need to re-render the form with errors.
                # Since we are returning early, we need to pass context again.
                hospitals = User.objects.filter(role="hospital", is_approved=True)
                categories = Category.objects.filter(is_active=True)
                return render(request, 'complaints/upload.html', {
                    'form': form,
                    'hospitals': hospitals,
                    'categories': categories
                })

            # If Valid, we assume it's relevant.
            try:
                 TrainingData.objects.create(
                    text_content=full_text,
                    image=complaint.evidence if complaint.evidence else None,
                    is_hospital_related=True,
                    ai_confidence=max(text_score, image_score),
                    reviewed_by=None
                )
            except Exception as e:
                print(f"Error saving training data: {e}")

            # ==========================================
            # 🤖 AI CONTENT VALIDATION END
            # ==========================================

            complaint.save()
            if complaint.hospital:
                Notification.objects.create(
                    recipient=complaint.hospital,
                    title="New complaint assigned",
                    message=f"A new complaint has been filed against your hospital: {complaint.title}",
                    link=reverse("complaint_detail", args=[complaint.id]),
                )

                # Notify Authority if hospital is assigned to one
                try:
                    # Check if hospital profile exists and has authority assigned
                    if hasattr(complaint.hospital, 'hospital_profile') and complaint.hospital.hospital_profile.authority:
                        authority_user = complaint.hospital.hospital_profile.authority.user
                        from authorities.models import AuthorityNotification
                        AuthorityNotification.objects.create(
                            recipient=authority_user,
                            notification_type='new_complaint',
                            title="New Complaint in Jurisdiction",
                            message=f"A new complaint has been filed against {complaint.hospital.hospital_profile.hospital_name}: {complaint.title}",
                            complaint=complaint,
                            hospital=complaint.hospital,
                            link=reverse("authority_complaint_detail", args=[complaint.id])
                        )
                except Exception as e:
                    print(f"Error notifying authority: {e}")

            # Create notification for superadmin
            superadmins = User.objects.filter(role='superadmin')
            for admin in superadmins:
                 Notification.objects.create(
                    recipient=admin,
                    title="New Complaint Submitted",
                    message=f"New complaint submitted by @{request.user.username}: {complaint.title[:30]}...",
                    link=f"/complaint/{complaint.id}/"  # Fallback to direct URL if reverse name is uncertain, or use reverse
                )
            
            if request.headers.get('x-requested-with') == 'XMLHttpRequest':
                return JsonResponse({'success': True})

            messages.success(request, "Complaint submitted successfully")
            return redirect('feed')
        else:
            # Form is not valid
            if request.headers.get('x-requested-with') == 'XMLHttpRequest':
                return JsonResponse({
                    'success': False,
                    'errors': form.errors.as_json()
                })
            messages.error(request, "Please correct the errors below")
    
    # Standard GET request or non-AJAX POST with errors
    form = ComplaintForm()
    hospitals = User.objects.filter(role='hospital', is_approved=True)
    categories = Category.objects.filter(is_active=True)
    return render(request, 'complaints/upload.html', {
        'form': form,
        'hospitals': hospitals,
        'categories': categories
    })



@login_required
def like_complaint(request, complaint_id):
    complaint = get_object_or_404(Complaint, id=complaint_id)

    like, created = Like.objects.get_or_create(
        user=request.user,
        complaint=complaint
    )

    if created:
        complaint.likes += 1
    else:
        like.delete()
        complaint.likes = max(complaint.likes - 1, 0)
    complaint.save()

    return redirect('feed')


@login_required
@csrf_exempt
@require_http_methods(["POST"])
def like_complaint_ajax(request, complaint_id):
    """
    AJAX endpoint for liking/unliking a complaint.
    Returns JSON response.
    """
    complaint = get_object_or_404(Complaint, id=complaint_id)

    like, created = Like.objects.get_or_create(
        user=request.user,
        complaint=complaint
    )

    if created:
        complaint.likes += 1
        message = 'Post liked!'
    else:
        like.delete()
        complaint.likes = max(complaint.likes - 1, 0)
        message = 'Post unliked.'
    
    complaint.save()
    
    return JsonResponse({
        'success': True,
        'message': message,
        'likes': complaint.likes,
        'liked': created
    })


@login_required
def my_complaints(request):
    search = request.GET.get("q")
    status = request.GET.get("status")

    complaints = Complaint.objects.filter(
        user=request.user
    ).order_by("-created_at")

    # 🔍 Search
    related_hospitals = None
    if search:
        complaints = complaints.filter(
            Q(title__icontains=search) |
            Q(description__icontains=search) |
            Q(category__icontains=search) |
            Q(hospital__username__icontains=search) |
            Q(hospital__first_name__icontains=search) |
            Q(hospital__last_name__icontains=search) |
            Q(unregistered_hospital_name__icontains=search)
        )
        
        # Get related hospitals from the search results
        # We filter Users who are linked to these complaints as 'hospital'
        related_hospitals = User.objects.filter(
            hospital_complaints__in=complaints
        ).distinct()[:5]  # Limit to 5 for UI

    # 🎯 Status filter
    if status and status != "all":
        complaints = complaints.filter(status=status)

    return render(
        request,
        "complaints/my_complaints.html",
        {
            "complaints": complaints,
            "related_hospitals": related_hospitals
        }
    )


@login_required
def add_comment(request, complaint_id):
    complaint = get_object_or_404(Complaint, id=complaint_id)

    if request.method == "POST":
        content = request.POST.get("content")
        if content:
            Comment.objects.create(
                complaint=complaint,
                user=request.user,
                content=content
            )

    return redirect("feed")
@login_required
def delete_comment(request, comment_id):
    comment = get_object_or_404(Comment, id=comment_id)

    # 🔒 Only the comment owner can delete
    if comment.user != request.user:
        messages.error(request, "You are not allowed to delete this comment.")
        return redirect("feed")

    if request.method == "POST":
        comment.delete()
        messages.success(request, "Comment deleted successfully.")

    return redirect("feed")


@login_required
def complaint_detail(request, complaint_id):
    complaint = get_object_or_404(Complaint, id=complaint_id)
    
    # 🔒 Blocked User Check
    if complaint.user.account_status == 'blocked' and request.user.role != 'superadmin':
        # Treat as 404 to not leak existence, or 403. 404 is safer/cleaner.
        from django.http import Http404
        raise Http404("Complaint not found.")

    # 🔒 Access Control
    is_owner = complaint.user == request.user
    is_assigned_hospital = (request.user.role == "hospital" and complaint.hospital == request.user)
    is_authority = request.user.role == "authority"
    is_admin = request.user.role == "superadmin"

    if not (is_owner or is_assigned_hospital or is_authority or is_admin):
        return render(request, "403.html", status=403)

    # 👁️ Auto-mark as viewed
    if is_assigned_hospital and not complaint.viewed_by_hospital:
        complaint.viewed_by_hospital = True
        complaint.save(update_fields=['viewed_by_hospital'])
    
    if is_authority and not complaint.viewed_by_authority:
        complaint.viewed_by_authority = True
        complaint.save(update_fields=['viewed_by_authority'])

    # Check if user liked the complaint
    complaint.is_liked = complaint.likes_received.filter(user=request.user).exists()

    template_name = "complaints/complaint_detail.html"
    if request.user.role == "patient":
        template_name = "complaints/patient_complaint_detail.html"

    conversation = None
    if complaint.hospital and complaint.user:
        conversation = Conversation.objects.filter(
            complaint=complaint,
            participants=complaint.hospital,
        ).filter(
            participants=complaint.user
        ).first()

    # Get hospitals and categories for edit modal (if owner)
    hospitals = User.objects.filter(role='hospital', is_approved=True)
    categories = Category.objects.filter(is_active=True)
    
    # Check if user is owner (for edit modal)
    is_owner = complaint.user == request.user
    
    # Return JSON for AJAX requests (edit modal)
    if request.headers.get('Accept') == 'application/json' or request.headers.get('X-Requested-With') == 'XMLHttpRequest':
        return JsonResponse({
            'id': complaint.id,
            'title': complaint.title,
            'description': complaint.description,
            'hospital': {
                'id': complaint.hospital.id,
                'name': complaint.hospital.get_full_name() or complaint.hospital.username
            } if complaint.hospital else None,
            'unregistered_hospital_name': complaint.unregistered_hospital_name,
            'category': complaint.category,
            'severity': complaint.severity,
            'evidence_url': complaint.evidence.url if complaint.evidence else None,
            'created_at': complaint.created_at.strftime("%b %d, %Y · %I:%M %p"),
            'is_owner': is_owner
        })

    return render(
        request,
        template_name,
        {
            "complaint": complaint,
            "is_assigned_hospital": is_assigned_hospital,
            "is_authority": is_authority,
            "is_admin": is_admin,
            "hospital_responses": list(complaint.hospital_responses.select_related('hospital').exclude(hospital__account_status='blocked').order_by("-created_at")),
            "conversation": conversation,
            "hospitals": hospitals,
            "categories": categories,
        }
    )

@login_required
def update_complaint_status(request, complaint_id):
    if request.method != "POST":
        return redirect("feed")

    complaint = get_object_or_404(Complaint, id=complaint_id)
    
    # Check if user is the assigned hospital
    if request.user.role == "hospital" and complaint.hospital == request.user:
        new_status = request.POST.get("status")
        if new_status in dict(Complaint.STATUS_CHOICES):
            complaint.status = new_status
            if new_status == "responded" and complaint.hospital_responded_at is None:
                complaint.hospital_responded_at = timezone.now()
            complaint.save()
            messages.success(request, f"Status updated to {complaint.get_status_display()}")
        else:
            messages.error(request, "Invalid status")
    else:
        messages.error(request, "You are not authorized to update this complaint.")
    
    return redirect("complaint_detail", complaint_id=complaint.id)


@login_required
def hospital_public_response(request, complaint_id):
    complaint = get_object_or_404(Complaint, id=complaint_id)

    if request.user.role != "hospital" or complaint.hospital != request.user:
        return render(request, "403.html", status=403)

    if request.method == "POST":
        message = request.POST.get("message", "").strip()
        if not message:
            messages.error(request, "Response message cannot be empty.")
            return redirect("complaint_detail", complaint_id=complaint.id)

        HospitalResponse.objects.create(
            complaint=complaint,
            hospital=request.user,
            message=message
        )

        if complaint.status != "resolved":
            complaint.status = "responded"
        if complaint.hospital_responded_at is None:
            complaint.hospital_responded_at = timezone.now()
        complaint.save(update_fields=["status", "hospital_responded_at"])

        Notification.objects.create(
            recipient=complaint.user,
            title="Hospital replied to your complaint",
            message=f"{request.user.get_full_name() or request.user.username} responded to your complaint: {complaint.title}",
            link=reverse("complaint_detail", args=[complaint.id]),
        )

        messages.success(request, "Public response posted successfully.")

    return redirect("complaint_detail", complaint_id=complaint.id)


@login_required
def patient_mark_resolved(request, complaint_id):
    complaint = get_object_or_404(Complaint, id=complaint_id)

    if complaint.user != request.user:
        return render(request, "403.html", status=403)

    if request.method == "POST":
        resolution = request.POST.get("resolution")
        if resolution not in ["satisfied", "resolved"]:
            messages.error(request, "Invalid resolution choice.")
            return redirect("complaint_detail", complaint_id=complaint.id)

        complaint.status = "resolved"
        complaint.patient_resolution_status = resolution
        complaint.patient_resolution_at = timezone.now()
        complaint.save(update_fields=["status", "patient_resolution_status", "patient_resolution_at"])

        if complaint.hospital:
            Notification.objects.create(
                recipient=complaint.hospital,
                title="Complaint marked as resolved",
                message=f"The patient marked complaint #{complaint.id} as resolved.",
                link=reverse("complaint_detail", args=[complaint.id]),
            )

        messages.success(request, "Complaint marked as resolved.")

    return redirect("complaint_detail", complaint_id=complaint.id)


@login_required
def authority_send_warning(request, complaint_id):
    complaint = get_object_or_404(Complaint, id=complaint_id)

    if request.user.role != "authority":
        return render(request, "403.html", status=403)

    if request.method == "POST":
        warning = request.POST.get("warning", "").strip()
        if not warning:
            messages.error(request, "Warning message cannot be empty.")
            return redirect("complaint_detail", complaint_id=complaint.id)

        if complaint.hospital:
            Notification.objects.create(
                recipient=complaint.hospital,
                title="Authority warning issued",
                message=warning,
                link=reverse("complaint_detail", args=[complaint.id]),
            )
            messages.success(request, "Warning sent to hospital.")
        else:
            messages.error(request, "No hospital is assigned to this complaint.")

    return redirect("complaint_detail", complaint_id=complaint.id)


@login_required
def edit_complaint(request, complaint_id):
    complaint = get_object_or_404(Complaint, id=complaint_id, user=request.user)

    if complaint.status != "resolved" or complaint.patient_resolution_status != "satisfied":
        messages.error(request, "You can only edit a complaint after marking it as satisfied.")
        return redirect("complaint_detail", complaint_id=complaint.id)

    if request.method == "POST":
        form = ComplaintForm(request.POST, request.FILES, instance=complaint)
        if form.is_valid():
            form.save()
            messages.success(request, "Complaint updated successfully.")
            return redirect("complaint_detail", complaint_id=complaint.id)
        messages.error(request, "Please correct the errors below.")
    else:
        form = ComplaintForm(instance=complaint)

    return render(
        request,
        "complaints/edit_complaint.html",
        {
            "form": form,
            "complaint": complaint,
        }
    )


@login_required
@csrf_exempt
@require_http_methods(["POST", "PUT"])
def edit_post_ajax(request, complaint_id):
    """
    AJAX endpoint for editing a post in the community feed.
    Only the post owner can edit their post.
    Returns JSON response for AJAX requests.
    """
    import json
    
    complaint = get_object_or_404(Complaint, id=complaint_id)
    
    # Check ownership
    if complaint.user != request.user:
        return JsonResponse({
            'success': False,
            'error': 'You are not authorized to edit this post.'
        }, status=403)
    
    if request.method in ['POST', 'PUT']:
        try:
            if request.content_type == 'application/json':
                data = json.loads(request.body)
            else:
                data = request.POST
            
            description = data.get('description', '').strip()
            hospital_id = data.get('hospital_id', '')
            unregistered_hospital_name = data.get('unregistered_hospital_name', '').strip()
            category_name = data.get('category', '').strip()
            severity = data.get('severity', '').strip()
            
            # Validation
            errors = {}
            if not description:
                errors['description'] = ['Description cannot be empty.']
            
            # Hospital validation
            hospital = None
            if hospital_id:
                hospital = get_object_or_404(User, id=hospital_id, role='hospital')
            elif not unregistered_hospital_name:
                errors['hospital'] = ['Please select a facility or enter an unregistered facility name.']
            
            # Category validation
            if not category_name:
                errors['category'] = ['Category is required.']
            
            # Severity validation
            valid_severities = [choice[0] for choice in Complaint.SEVERITY_CHOICES]
            if severity not in valid_severities:
                errors['severity'] = ['Invalid severity selected.']
            
            if errors:
                return JsonResponse({
                    'success': False,
                    'errors': errors
                }, status=400)
            
            # Update the complaint
            complaint.description = description
            complaint.hospital = hospital
            complaint.unregistered_hospital_name = unregistered_hospital_name if not hospital else None
            complaint.category = category_name
            complaint.severity = severity
            
            # Handle evidence file if provided
            if 'evidence' in request.FILES:
                complaint.evidence = request.FILES['evidence']
            
            complaint.save()
            
            return JsonResponse({
                'success': True,
                'message': 'Post updated successfully!',
                'post': {
                    'id': complaint.id,
                    'description': complaint.description,
                    'hospital_name': complaint.hospital_name,
                    'evidence_url': complaint.evidence.url if complaint.evidence else None,
                    'updated_at': complaint.created_at.strftime("%b %d, %Y · %I:%M %p"),
                    'category': complaint.category,
                    'category_display': complaint.category, # category is charfield, so display is same
                    'severity': complaint.severity,
                    'severity_display': complaint.get_severity_display()
                }
            })
            
        except json.JSONDecodeError:
            return JsonResponse({
                'success': False,
                'error': 'Invalid JSON data.'
            }, status=400)
        except Exception as e:
            return JsonResponse({
                'success': False,
                'error': str(e)
            }, status=500)
    
    return JsonResponse({
        'success': False,
        'error': 'Method not allowed.'
    }, status=405)


@login_required
@csrf_exempt
@require_http_methods(["POST", "DELETE"])
def delete_post_ajax(request, complaint_id):
    """
    AJAX endpoint for deleting a post in the community feed.
    Only the post owner can delete their post.
    Returns JSON response for AJAX requests.
    """
    complaint = get_object_or_404(Complaint, id=complaint_id)
    
    # Check ownership
    if complaint.user != request.user:
        return JsonResponse({
            'success': False,
            'error': 'You are not authorized to delete this post.'
        }, status=403)
    
    try:
        complaint.delete()
        return JsonResponse({
            'success': True,
            'message': 'Post deleted successfully!',
            'complaint_id': complaint_id
        })
    except Exception as e:
        return JsonResponse({
            'success': False,
            'error': str(e)
        }, status=500)


