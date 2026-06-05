import os
import django
import sys

# Setup Django environment
sys.path.append(os.getcwd())
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'medVoice.settings')
django.setup()

from django.test import Client
from django.contrib.auth import get_user_model

User = get_user_model()

def test_registration_view():
    client = Client()
    
    # Cleanup
    User.objects.filter(username='test_view_pat').delete()
    
    print("Sending POST request to /register/ ...")
    response = client.post('/register/', {
        'role': 'patient',
        'first_name': 'Test',
        'last_name': 'ViewPat',
        'email': 'testviewpat@example.com',
        'username': 'test_view_pat',
        'password': 'password123',
        'confirm_password': 'password123',
        'phone_number': '1231231234',
        'address_line_1': '123 St',
        'city': 'City',
        'state': 'State',
        'pincode': '123456',
        'govt_id_type': 'aadhaar',
        'govt_id_number': '123412341234',
    }, HTTP_HOST='127.0.0.1')
    
    # Check if form error regarding file
    # If invalid, it returns 200 with errors. If valid, 302 redirect.
    if response.status_code == 200:
        print("Response 200 (Form Error likely)")
        # We need a file.
        from django.core.files.uploadedfile import SimpleUploadedFile
        govt_id = SimpleUploadedFile("id.txt", b"content", content_type="text/plain")
        
        response = client.post('/register/', {
            'role': 'patient',
            'first_name': 'Test',
            'last_name': 'ViewPat',
            'email': 'testviewpat@example.com',
            'username': 'test_view_pat',
            'password': 'password123',
            'confirm_password': 'password123',
            'phone_number': '1231231234',
            'address_line_1': '123 St',
            'city': 'City',
            'state': 'State',
            'pincode': '123456',
            'govt_id_type': 'aadhaar',
            'govt_id_number': '123412341234',
            'govt_id_document': govt_id
        }, HTTP_HOST='127.0.0.1')
        
    print(f"Response Status Code: {response.status_code}")
    if response.status_code == 302:
        print(f"Redirect URL: {response.url}")
    
    # Check User
    try:
        user = User.objects.get(username='test_view_pat')
        print(f"User Created: {user.username}")
        print(f"  is_active: {user.is_active}")
        print(f"  is_approved: {user.is_approved}")
        
        if user.is_active:
            print("SUCCESS: User is active.")
        else:
            print("FAILURE: User is NOT active.")
            
    except User.DoesNotExist:
        print("User was NOT created.")

if __name__ == "__main__":
    test_registration_view()
