
@login_required
def admin_user_activity(request, user_id):
    if request.user.role != "superadmin":
        return redirect("login")
    
    target_user = get_object_or_404(User, id=user_id)
    
    # 1. Complaints Posted
    complaints = Complaint.objects.filter(user=target_user)
    
    # 2. Comments Made
    comments = Comment.objects.filter(user=target_user)
    
    # 3. Likes Given
    likes = Like.objects.filter(user=target_user)
    
    # 4. Hospital Specific: Complaints Assigned / Replied
    assigned_complaints = []
    if target_user.role == "hospital":
        assigned_complaints = Complaint.objects.filter(hospital=target_user)

    # Aggregate into a single list
    activities = []
    
    for c in complaints:
        activities.append({
            'type': 'complaint_posted',
            'icon': 'edit_note',
            'description': f"Posted complaint: {c.title}",
            'date': c.created_at,
            'link': f"/complaint/{c.id}/" # Assuming URL pattern
        })
        
    for c in comments:
        activities.append({
            'type': 'comment',
            'icon': 'chat',
            'description': f"Commented on {c.complaint.title}: \"{c.content[:50]}...\"",
            'date': c.created_at,
            'link': f"/complaint/{c.complaint.id}/"
        })

    for l in likes:
        activities.append({
            'type': 'like',
            'icon': 'thumb_up',
            'description': f"Liked complaint: {l.complaint.title}",
            'date': l.created_at,
            'link': f"/complaint/{l.complaint.id}/"
        })

    # Hospital specific actions (e.g. status updates - implicitly tracked by complaint update time if we had history, 
    # but for now we can just show currently assigned complaints as "Working on")
    # A better approach for "actions" would be to track history, but for now let's just show they are assigned.
    # actually, user asked for "if they give reply", which is comments. We have comments above.
    # We can also add "status updated" if we had a log, but we don't. 
    # Let's stick to the requested: posts, comments, likes.
    
    # Sort by date descending
    activities.sort(key=lambda x: x['date'], reverse=True)
    
    return render(request, "accounts/admin_user_activity.html", {
        "target_user": target_user,
        "activities": activities
    })
