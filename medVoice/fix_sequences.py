import os
import django
from django.core.management import call_command
from django.db import connection
from io import StringIO

# Setup Django environment
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'medVoice.settings')
django.setup()

def fix_sequences():
    apps_to_fix = ['accounts', 'complaints', 'hospitals', 'authorities', 'social']
    print("Fixing sequences for apps:", apps_to_fix)
    
    output = StringIO()
    try:
        # Generate the SQL to reset sequences
        call_command('sqlsequencereset', *apps_to_fix, stdout=output)
        sql = output.getvalue()
        
        if sql:
            print("Executing SQL...")
            print(sql)
            with connection.cursor() as cursor:
                cursor.execute(sql)
            print("Successfully reset sequences.")
        else:
            print("No sequences needed resetting.")
            
    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    fix_sequences()
