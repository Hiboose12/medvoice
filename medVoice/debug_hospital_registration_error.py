import os
import django
import sys
from django.core.files.uploadedfile import SimpleUploadedFile

sys.path.append(os.getcwd())
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'medVoice.settings')
django.setup()

from accounts.forms import HospitalRegistrationForm
from django.contrib.auth import get_user_model
from accounts.models import Hospital

User = get_user_model()

def test_hospital_reg():
    print("Testing Hospital Registration (looking for Exceptions)...")
    username = "test_hosp_debug_tx"
    
    # Cleanup
    User.objects.filter(username=username).delete()
    
    data = {
        'role': 'hospital',
        'first_name': 'Test',
        'last_name': 'Hosp',
        'email': 'hosp_debug_tx@ex.com',
        'username': username,
        'password': 'password123',
        'confirm_password': 'password123',
        'phone_number': '3333333333',
        'address_line_1': 'Addr',
        'city': 'City',
        'state': 'Maharashtra', # Use a valid state to trigger signals?
        'pincode': '123456',
        
        # Hospital Fields
        'hospital_name': 'Debug Hospital',
        'hospital_type': 'private',
        'registration_number': 'REG123',
        'license_number': 'LIC123',
        'hospital_address': 'Addr',
        'hospital_district': 'Pune', # Use a valid district
        'hospital_state': 'Maharashtra',
        'hospital_pincode': '411001',
        'hospital_contact': '9999999999',
        'hospital_email': 'hosp@debug.com'
    }
    
    files = {
        'license_document': SimpleUploadedFile("lic.txt", b"content")
    }
    
    # Create a user to conflict with
    User.objects.create_user(username='conflict_user', email='hosp_debug_tx@ex.com', password='password123')
    
    # Use valid data for form to pass validation
    data['username'] = 'unique_hosp_user_123' 
    data['email'] = 'unique_hosp@ex.com'

    form = HospitalRegistrationForm(data=data, files=files)
    if form.is_valid():
        from django.db import transaction
        # Simulate View Decorator
        try:
            with transaction.atomic():
                try:
                    # View Logic
                    print("Form Valid. Saving...")
                    
                    user = form.save(commit=False)
                    user.set_password(form.cleaned_data.get("password"))
                    user.role = 'hospital'
                    
                    # FORCE CONFLICT HERE
                    user.email = 'hosp_debug_tx@ex.com' # This exists!
                    user.username = 'conflict_user'     # This exists!
                    
                    print("Attempting to save user with duplicate data...")
                    user.save() # Should raise IntegrityError
                    
                    print(f"User saved: {user.id}")

                except Exception as e:
                    print("CAUGHT EXCEPTION inside atomic block:")
                    # In the view, we do: messages.error(...) and return render(...)
                    # We are still inside the atomic block, and it is broken.
                    
                    # See if we can access DB here.
                    print("Attempting DB access in broken transaction...")
                    print("Count users:", User.objects.count())
        except Exception as outer_e:
            print(f"Outer Exception: {outer_e}")
            import traceback
            traceback.print_exc()
    else:
        print("Form Errors:", form.errors)

if __name__ == "__main__":
    test_hospital_reg()
