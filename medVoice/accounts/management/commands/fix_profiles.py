from django.core.management.base import BaseCommand
from django.contrib.auth import get_user_model
from accounts.models import Profile

User = get_user_model()

class Command(BaseCommand):
    help = 'Fixes missing user profiles'

    def handle(self, *args, **kwargs):
        users = User.objects.all()
        fixed_count = 0
        
        for user in users:
            try:
                if not hasattr(user, 'profile'):
                    Profile.objects.create(user=user)
                    fixed_count += 1
                    self.stdout.write(self.style.SUCCESS(f'Created profile for user: {user.username}'))
            except Exception as e:
                self.stdout.write(self.style.ERROR(f'Error checking user {user.username}: {str(e)}'))

        self.stdout.write(self.style.SUCCESS(f'Successfully checked {users.count()} users. Fixed {fixed_count} missing profiles.'))
