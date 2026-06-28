import os
import django
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'medVoice.settings')
django.setup()

from django.contrib.auth import get_user_model
User = get_user_model()

hospital = User.objects.filter(role='hospital').first()
if hospital:
    hospital.account_status = 'frozen'
    hospital.is_active = False
    hospital.save()
    print(f'Successfully frozen hospital: {hospital.username}')
else:
    print('No hospital found')
