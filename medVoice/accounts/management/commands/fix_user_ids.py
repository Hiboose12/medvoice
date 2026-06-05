from django.core.management.base import BaseCommand
from django.db import connection

class Command(BaseCommand):
    help = 'Fixes the PostgreSQL sequence for the User ID field to prevent unique constraint errors.'

    def handle(self, *args, **options):
        self.stdout.write("Fixing User ID sequence...")

        # SQL to reset the sequence to the maximum existing ID
        # reliable for PostgreSQL
        sql = """
        SELECT setval(pg_get_serial_sequence('"accounts_user"','id'), coalesce(max("id"), 1), max("id") IS NOT null) FROM "accounts_user";
        SELECT setval(pg_get_serial_sequence('"accounts_user_user_permissions"','id'), coalesce(max("id"), 1), max("id") IS NOT null) FROM "accounts_user_user_permissions";
        SELECT setval(pg_get_serial_sequence('"accounts_verificationprofile"','id'), coalesce(max("id"), 1), max("id") IS NOT null) FROM "accounts_verificationprofile";
        SELECT setval(pg_get_serial_sequence('"accounts_patientsettings"','id'), coalesce(max("id"), 1), max("id") IS NOT null) FROM "accounts_patientsettings";
        SELECT setval(pg_get_serial_sequence('"accounts_profile"','id'), coalesce(max("id"), 1), max("id") IS NOT null) FROM "accounts_profile";
        SELECT setval(pg_get_serial_sequence('"accounts_notification"','id'), coalesce(max("id"), 1), max("id") IS NOT null) FROM "accounts_notification";
        """

        try:
            with connection.cursor() as cursor:
                cursor.execute(sql)
            self.stdout.write(self.style.SUCCESS("Successfully reset all ID sequences for 'accounts' app."))
        except Exception as e:
            self.stdout.write(self.style.ERROR(f"Error resetting sequences: {e}"))
