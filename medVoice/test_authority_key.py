import os
import django
import sys

sys.path.append(os.getcwd())
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'medVoice.settings')
django.setup()

from accounts.forms import AuthorityRegistrationForm
from django.conf import settings
from django.core.files.uploadedfile import SimpleUploadedFile

def test_key_validation():
    print("Testing Authority Key Validation...")
    print(f"Expected Secret: {settings.AUTHORITY_REGISTRATION_SECRET}")
    
    files = {
        'appointment_letter': SimpleUploadedFile("app_letter.pdf", b"content"),
        'authority_id_document': SimpleUploadedFile("auth_id.pdf", b"content")
    }
    
    # Base data (minimal valid data for other fields to isolate key testing)
    base_data = {
        'role': 'authority',
        'first_name': 'Test',
        'last_name': 'Auth',
        'email': 'key_test@ex.com',
        'username': 'key_test_user',
        'password': 'password123',
        'confirm_password': 'password123',
        'phone_number': '1234567890',
        'address_line_1': 'Addr',
        'city': 'City',
        'state': 'State',
        'pincode': '123456',
        'authority_name': 'Auth Name',
        'authority_type': 'state',
        'department_name': 'Dept',
        'jurisdiction_level': 'state',
        'jurisdiction_state': 'State',
        'office_address': 'Addr',
        'official_email': 'off@ex.com',
        'official_phone': '1231231231'
    }

    # Test 1: Invalid Key
    print("\n--- Test 1: Invalid Key ---")
    data_invalid = base_data.copy()
    data_invalid['authentication_key'] = 'wrong_key'
    form = AuthorityRegistrationForm(data=data_invalid, files=files)
    if not form.is_valid():
        if 'authentication_key' in form.errors:
            print(f"[PASS] Invalid key rejected: {form.errors['authentication_key']}")
        else:
             print(f"[FAIL] Key invalid but no specific error? {form.errors}")
    else:
        print("[FAIL] Form valid with wrong key!")

    # Test 2: Correct Key
    print("\n--- Test 2: Correct Key ---")
    data_valid = base_data.copy()
    data_valid['authentication_key'] = settings.AUTHORITY_REGISTRATION_SECRET
    form = AuthorityRegistrationForm(data=data_valid, files=files)
    
    # Note: might fail on other fields (uniqueness), but key should be clean
    form.full_clean()
    if 'authentication_key' not in form.errors:
        print("[PASS] Correct key accepted.")
    else:
        print(f"[FAIL] Correct key rejected: {form.errors['authentication_key']}")

if __name__ == "__main__":
    test_key_validation()
