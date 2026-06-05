from django.conf import settings
from django.db import migrations, models
import django.db.models.deletion


class Migration(migrations.Migration):

    dependencies = [
        ("complaints", "0008_alter_complaint_category"),
    ]

    operations = [
        migrations.AlterField(
            model_name="complaint",
            name="status",
            field=models.CharField(
                choices=[
                    ("new", "New"),
                    ("review", "In Review"),
                    ("responded", "Responded"),
                    ("resolved", "Resolved"),
                ],
                default="new",
                max_length=20,
            ),
        ),
        migrations.AddField(
            model_name="complaint",
            name="hospital_responded_at",
            field=models.DateTimeField(blank=True, null=True),
        ),
        migrations.AddField(
            model_name="complaint",
            name="patient_resolution_status",
            field=models.CharField(
                blank=True,
                choices=[("satisfied", "Satisfied"), ("resolved", "Resolved")],
                max_length=20,
                null=True,
            ),
        ),
        migrations.AddField(
            model_name="complaint",
            name="patient_resolution_at",
            field=models.DateTimeField(blank=True, null=True),
        ),
        migrations.AddField(
            model_name="complaint",
            name="escalated_to_authority",
            field=models.BooleanField(default=False),
        ),
        migrations.AddField(
            model_name="complaint",
            name="escalated_at",
            field=models.DateTimeField(blank=True, null=True),
        ),
        migrations.CreateModel(
            name="HospitalResponse",
            fields=[
                ("id", models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name="ID")),
                ("message", models.TextField()),
                ("created_at", models.DateTimeField(auto_now_add=True)),
                (
                    "complaint",
                    models.ForeignKey(
                        on_delete=django.db.models.deletion.CASCADE,
                        related_name="hospital_responses",
                        to="complaints.complaint",
                    ),
                ),
                (
                    "hospital",
                    models.ForeignKey(
                        on_delete=django.db.models.deletion.CASCADE,
                        related_name="public_responses",
                        to=settings.AUTH_USER_MODEL,
                    ),
                ),
            ],
        ),
    ]
