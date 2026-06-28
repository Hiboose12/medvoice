from django.test import TestCase, Client
from django.urls import reverse
from django.contrib.auth import get_user_model
from complaints.models import Complaint, Category
from accounts.models import Hospital

User = get_user_model()

class HospitalFeedTest(TestCase):
    def setUp(self):
        self.client = Client()
        
        # Create Users
        self.hospital_user = User.objects.create_user(username='hospital1', password='password', role='hospital', is_approved=True)
        self.other_hospital = User.objects.create_user(username='hospitalMM', password='password', role='hospital', is_approved=True)
        self.patient = User.objects.create_user(username='patient1', password='password', role='patient')
        
        # Create Profiles
        Hospital.objects.create(user=self.hospital_user, hospital_name="City Hospital", hospital_type="private", status="verified")
        Hospital.objects.create(user=self.other_hospital, hospital_name="Metro Med", hospital_type="private", status="verified")

        # Create Complaints
        self.category = Category.objects.create(name="General")
        
        # 1. Public Complaint
        self.public_complaint = Complaint.objects.create(
            user=self.patient,
            title="Public Complaint",
            description="Everyone should see this",
            category="General",
            severity="low",
            status="new"
        )
        
        # 2. Complaint against THIS hospital
        self.assigned_complaint = Complaint.objects.create(
            user=self.patient,
            hospital=self.hospital_user,
            title="Complaint against City Hospital",
            description="Bad service here",
            category="General",
            severity="high",
            status="new"
        )

        # 3. Complaint against OTHER hospital
        self.other_complaint = Complaint.objects.create(
            user=self.patient,
            hospital=self.other_hospital,
            title="Complaint against Metro Med",
            description="They are okay",
            category="General",
            severity="low",
            status="new"
        )

    def test_hospital_feed_access(self):
        self.client.login(username='hospital1', password='password')
        response = self.client.get(reverse('hospital_feed'))
        self.assertEqual(response.status_code, 200)
        self.assertTemplateUsed(response, 'hospitals/feed.html')

    def test_create_post_absent(self):
        self.client.login(username='hospital1', password='password')
        response = self.client.get(reverse('hospital_feed'))
        self.assertNotContains(response, 'Start a complaint')
        self.assertNotContains(response, 'Create Post')

    def test_complaints_visibility(self):
        self.client.login(username='hospital1', password='password')
        response = self.client.get(reverse('hospital_feed'))
        
        self.assertContains(response, "Public Complaint")
        self.assertContains(response, "Complaint against City Hospital")
        self.assertContains(response, "Complaint against Metro Med")

    def test_highlight_assigned_complaint(self):
        self.client.login(username='hospital1', password='password')
        response = self.client.get(reverse('hospital_feed'))
        
        self.assertContains(response, "Complaint Against Your Hospital")

    def test_complaint_management_links(self):
        self.client.login(username='hospital1', password='password')
        response = self.client.get(reverse('hospital_feed'))
        
        # Should contain "View Details & Manage"
        self.assertContains(response, "View Details & Manage")
        self.assertContains(response, reverse('complaint_detail', args=[self.assigned_complaint.id]))

        # Should NOT contain inline actions
        self.assertNotContains(response, "Respond Publicly")
        self.assertNotContains(response, "Private Resolution Message")
        self.assertNotContains(response, "Mark as Responded")
