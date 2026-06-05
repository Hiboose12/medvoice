def account_disabled(request):
    # Check if we have a user ID in session from a failed login attempt
    user_id = request.session.get('disabled_user_id')
    if not user_id:
        return redirect('login')
    
    try:
        user = User.objects.get(id=user_id)
    except User.DoesNotExist:
        return redirect('login')

    if request.method == "POST":
        user.reactivation_requested = True
        user.save()
        messages.success(request, "Reactivation request sent to admin.")
        # Clear session potentially? No, keep it so they can see "Request Sent" status if valid.
        
    return render(request, "accounts/account_disabled.html", {"disabled_user": user})
