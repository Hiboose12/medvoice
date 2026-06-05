from django import forms
from .models import Complaint, Category


class ComplaintForm(forms.ModelForm):

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        # Dynamic categories from DB
        categories = Category.objects.filter(is_active=True).values_list('name', 'name')
        if categories:
            self.fields['category'].widget = forms.Select(choices=categories)
        else:
             # Fallback if no categories exist (though we just added some)
            self.fields['category'].widget = forms.Select(choices=Complaint.CATEGORY_CHOICES)

        # Custom label for hospital field
        self.fields['hospital'].label_from_instance = lambda obj: (
            obj.hospital_profile.hospital_name 
            if hasattr(obj, 'hospital_profile') 
            else (obj.get_full_name() or obj.username)
        )

    class Meta:
        model = Complaint
        fields = [
            'title',
            'hospital',
            'unregistered_hospital_name',
            'category',
            'severity',
            'description',
            'evidence',
        ]

    def clean(self):
        cleaned_data = super().clean()
        hospital = cleaned_data.get('hospital')
        unregistered_hospital_name = cleaned_data.get('unregistered_hospital_name')

        if not hospital and not unregistered_hospital_name:
            raise forms.ValidationError("Please select a registered facility or enter the name of the unlisted one.")
        
        return cleaned_data
    