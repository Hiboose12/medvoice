from django.core.management.base import BaseCommand
from django.db import transaction

from accounts.models import Authority, Hospital, PatientSettings, Profile, User


class Command(BaseCommand):
    help = "Seed or repair the demo accounts used by the Flutter app."

    password = "demo123"

    demo_users = [
        {
            "username": "johndoe",
            "email": "patient@demo.com",
            "first_name": "John",
            "last_name": "Doe",
            "role": "patient",
        },
        {
            "username": "cityhospital",
            "email": "hospital@demo.com",
            "first_name": "City",
            "last_name": "Hospital",
            "role": "hospital",
        },
        {
            "username": "healthauth",
            "email": "authority@demo.com",
            "first_name": "District",
            "last_name": "Authority",
            "role": "authority",
        },
        {
            "username": "superadmin",
            "email": "admin@demo.com",
            "first_name": "Admin",
            "last_name": "User",
            "role": "superadmin",
        },
        {
            "username": "hiboose",
            "email": "hiboosehiba53@gmail.com",
            "first_name": "Hiboose",
            "last_name": "Hiba",
            "role": "patient",
        },
        {
            "username": "AH",
            "email": "nihal@gmail.com",
            "first_name": "AH",
            "last_name": "Hospital",
            "role": "hospital",
        },
        {
            "username": "krishna",
            "email": "krishna@gmail.com",
            "first_name": "Krishna",
            "last_name": "Nambiyath",
            "role": "authority",
        },
        {
            "username": "medvoice",
            "email": "medVoice80@gmail.com",
            "first_name": "medVoice",
            "last_name": "Superadmin",
            "role": "superadmin",
        },
    ]

    def handle(self, *args, **options):
        created_count = 0
        repaired_count = 0

        with transaction.atomic():
            for data in self.demo_users:
                user, created = User.objects.get_or_create(
                    username=data["username"],
                    defaults={
                        "email": data["email"],
                        "first_name": data["first_name"],
                        "last_name": data["last_name"],
                    },
                )

                user.email = data["email"]
                user.first_name = data["first_name"]
                user.last_name = data["last_name"]
                user.role = data["role"]
                user.is_active = True
                user.is_approved = True
                user.account_status = "active"
                user.is_staff = data["role"] == "superadmin"
                user.is_superuser = data["role"] == "superadmin"
                user.set_password(self.password)
                user.save()

                Profile.objects.get_or_create(user=user)
                if user.role == "patient":
                    PatientSettings.objects.get_or_create(user=user)
                elif user.role == "hospital":
                    Hospital.objects.update_or_create(
                        user=user,
                        defaults={
                            "hospital_name": "City Hospital",
                            "hospital_type": "private",
                            "registration_number": "DEMO-HOSP-001",
                            "license_number": "DEMO-LIC-001",
                            "license_document": "verification/hospital/demo_license.txt",
                            "address": "Demo Medical Campus",
                            "district": "Demo District",
                            "state": "Demo State",
                            "pincode": "000000",
                            "contact_number": "9999999999",
                            "email": data["email"],
                            "status": "verified",
                        },
                    )
                elif user.role == "authority":
                    Authority.objects.update_or_create(
                        user=user,
                        defaults={
                            "authority_name": "District Health Authority",
                            "authority_type": "district",
                            "department_name": "Public Health",
                            "jurisdiction_level": "Demo District",
                            "jurisdiction_state": "Demo State",
                            "jurisdiction_district": "Demo District",
                            "office_address": "Demo Authority Office",
                            "official_email": data["email"],
                            "official_phone": "9999999998",
                            "appointment_letter": "verification/authority/demo_appointment.txt",
                            "authority_id_document": "verification/authority/demo_id.txt",
                        },
                    )

                if created:
                    created_count += 1
                else:
                    repaired_count += 1

        self.stdout.write(
            self.style.SUCCESS(
                "Demo accounts ready "
                f"({created_count} created, {repaired_count} repaired). "
                f"Password: {self.password}"
            )
        )
