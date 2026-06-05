from django.core.management.base import BaseCommand
from authorities.views import process_escalations


class Command(BaseCommand):
    help = 'Process escalations for complaints that require authority intervention'

    def handle(self, *args, **options):
        self.stdout.write('Processing escalations...')
        process_escalations()
        self.stdout.write(self.style.SUCCESS('Escalation processing complete'))
