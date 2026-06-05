import os
import django
import sys
from django.test import Client

sys.path.append(os.getcwd())
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'medVoice.settings')
django.setup()

from django.contrib.auth import get_user_model
from django.urls import reverse

from django.conf import settings
settings.ALLOWED_HOSTS += ['testserver']

User = get_user_model()

def test_view():
    print("Testing Admin Document View...")
    
    # 1. Get Superadmin
    admin = User.objects.filter(role='superadmin').first()
    if not admin:
        print("No superadmin found. Creating one...")
        admin = User.objects.create_superuser('admin_tester', 'admin@test.com', 'password123', role='superadmin')
    else:
        print(f"Using superadmin: {admin.username}")

    # 2. Get Hospital User
    hospital = User.objects.filter(role='hospital').last()
    if not hospital:
        print("No hospital user found.")
        return
    print(f"Target Hospital: {hospital.username} (ID: {hospital.id})")

    # 3. Client
    c = Client()
    c.force_login(admin)
    
    # 4. URL
    # path("dashboard/documents/<int:user_id>/<str:doc_key>/", views.admin_document_view, name="admin_document_view"),
    url = reverse('admin_document_view', args=[hospital.id, 'hospital_license_document'])
    print(f"URL: {url}")
    
    # 5. Get
    response = c.get(url)
    print(f"Status Code: {response.status_code}")
    print(f"Content-Type: {response.headers.get('Content-Type')}")
    print(f"Content-Disposition: {response.headers.get('Content-Disposition')}")
    print(f"Content Length: {len(response.content) if hasattr(response, 'content') else 'Streaming'}")

if __name__ == "__main__":
    test_view()
