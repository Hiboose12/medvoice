from django.contrib.auth.signals import user_logged_in, user_logged_out
from django.dispatch import receiver
from .models import UserActivity

def get_client_ip(request):
    x_forwarded_for = request.META.get('HTTP_X_FORWARDED_FOR')
    if x_forwarded_for:
        ip = x_forwarded_for.split(',')[0]
    else:
        ip = request.META.get('REMOTE_ADDR')
    return ip

@receiver(user_logged_in)
def log_user_login(sender, request, user, **kwargs):
    UserActivity.objects.create(
        user=user,
        action_type="Login",
        description="User logged in",
        ip_address=get_client_ip(request)
    )

@receiver(user_logged_out)
def log_user_logout(sender, request, user, **kwargs):
    if user: # user can be None in some logout cases
        UserActivity.objects.create(
            user=user,
            action_type="Logout",
            description="User logged out",
            ip_address=get_client_ip(request)
        )
