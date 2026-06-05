from django import forms
from accounts.models import Hospital


class HospitalDocumentForm(forms.ModelForm):
    class Meta:
        model = Hospital
        fields = ["license_document"]
        widgets = {
            "license_document": forms.FileInput(attrs={"class": "form-input"}),
        }

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self.fields["license_document"].required = False
