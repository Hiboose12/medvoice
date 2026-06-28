from django import forms
from django.contrib.auth import get_user_model
from django.core.exceptions import ValidationError
from .models import Hospital, Authority, Profile, VerificationProfile

User = get_user_model()


class BaseRegistrationForm(forms.ModelForm):
    password = forms.CharField(
        widget=forms.PasswordInput(attrs={
            'class': 'form-input w-full rounded-lg border-gray-300 focus:border-blue-600 focus:ring-blue-600',
            'placeholder': '••••••••'
        })
    )
    confirm_password = forms.CharField(
        widget=forms.PasswordInput(attrs={
            'class': 'form-input w-full rounded-lg border-gray-300 focus:border-blue-600 focus:ring-blue-600',
            'placeholder': '••••••••'
        })
    )

    class Meta:
        model = User
        fields = ['first_name', 'last_name', 'email', 'username', 'phone_number',
                  'address_line_1', 'address_line_2', 'city', 'state', 'pincode']
        widgets = {
            'first_name': forms.TextInput(attrs={'class': 'form-input', 'placeholder': 'John'}),
            'last_name': forms.TextInput(attrs={'class': 'form-input', 'placeholder': 'Doe'}),
            'email': forms.EmailInput(attrs={'class': 'form-input', 'placeholder': 'john@example.com'}),
            'username': forms.TextInput(attrs={'class': 'form-input', 'placeholder': 'johndoe123'}),
            'phone_number': forms.TextInput(attrs={'class': 'form-input', 'placeholder': '+91-9999999999'}),
            'address_line_1': forms.TextInput(attrs={'class': 'form-input', 'placeholder': 'Street Address'}),
            'address_line_2': forms.TextInput(attrs={'class': 'form-input', 'placeholder': 'Apartment, Suite (Optional)'}),
            'city': forms.TextInput(attrs={'class': 'form-input'}),
            'state': forms.TextInput(attrs={'class': 'form-input'}),
            'pincode': forms.TextInput(attrs={'class': 'form-input'}),
        }

    def clean_username(self):
        username = self.cleaned_data.get('username')
        if User.objects.filter(username__iexact=username).exists():
            raise ValidationError("This username is already taken.")
        return username

    def clean_email(self):
        email = self.cleaned_data.get('email')
        if User.objects.filter(email__iexact=email).exists():
            raise ValidationError("This email is already registered.")
        return email

    def clean(self):
        cleaned_data = super().clean()
        password = cleaned_data.get("password")
        confirm_password = cleaned_data.get("confirm_password")

        if password and confirm_password and password != confirm_password:
            self.add_error('confirm_password', "Passwords do not match.")

        return cleaned_data


class PatientRegistrationForm(BaseRegistrationForm):
    govt_id_type = forms.ChoiceField(
        choices=User.GOVT_ID_CHOICES,
        widget=forms.Select(attrs={'class': 'form-select w-full rounded-lg border-gray-300'})
    )
    govt_id_number = forms.CharField(
        widget=forms.TextInput(attrs={'class': 'form-input'})
    )
    govt_id_document = forms.FileField(
        required=False,
        widget=forms.FileInput(attrs={'class': 'form-input file:mr-4 file:py-2 file:px-4 file:rounded-full file:border-0 file:text-sm file:font-semibold file:bg-blue-50 file:text-blue-700 hover:file:bg-blue-100'})
    )

    class Meta(BaseRegistrationForm.Meta):
        fields = BaseRegistrationForm.Meta.fields + ['govt_id_type', 'govt_id_number']


class HospitalRegistrationForm(BaseRegistrationForm):
    # Hospital Fields
    hospital_name = forms.CharField(widget=forms.TextInput(attrs={'class': 'form-input'}))
    hospital_type = forms.ChoiceField(choices=Hospital.TYPE_CHOICES, widget=forms.Select(attrs={'class': 'form-select'}))
    registration_number = forms.CharField(widget=forms.TextInput(attrs={'class': 'form-input'}))
    license_number = forms.CharField(widget=forms.TextInput(attrs={'class': 'form-input'}))
    license_document = forms.FileField(required=False, widget=forms.FileInput(attrs={'class': 'form-input'}))

    # Hospital Contact
    hospital_address = forms.CharField(widget=forms.Textarea(attrs={'class': 'form-input', 'rows': 3}))
    hospital_district = forms.CharField(widget=forms.TextInput(attrs={'class': 'form-input'}))
    hospital_state = forms.CharField(widget=forms.TextInput(attrs={'class': 'form-input'}))
    hospital_pincode = forms.CharField(widget=forms.TextInput(attrs={'class': 'form-input'}))
    hospital_contact = forms.CharField(widget=forms.TextInput(attrs={'class': 'form-input'}))
    hospital_email = forms.EmailField(widget=forms.EmailInput(attrs={'class': 'form-input'}))


class AuthorityRegistrationForm(BaseRegistrationForm):
    authentication_key = forms.CharField(
        widget=forms.PasswordInput(attrs={'class': 'form-input', 'placeholder': 'Secret Key provided by SuperAdmin'}),
        help_text="Required for Authority Registration"
    )

    def clean_authentication_key(self):
        key = self.cleaned_data.get('authentication_key')
        from django.conf import settings
        if key != getattr(settings, 'AUTHORITY_REGISTRATION_SECRET', ''):
            raise ValidationError("Invalid Authentication Key.")
        return key

    authority_name = forms.CharField(widget=forms.TextInput(attrs={'class': 'form-input'}))
    authority_type = forms.ChoiceField(choices=Authority.TYPE_CHOICES, widget=forms.Select(attrs={'class': 'form-select'}))
    department_name = forms.CharField(widget=forms.TextInput(attrs={'class': 'form-input'}))

    LEVEL_CHOICES = [
        ('national', 'National Level'),
        ('state', 'State Level'),
        ('district', 'District Level'),
    ]
    jurisdiction_level = forms.ChoiceField(choices=LEVEL_CHOICES, widget=forms.Select(attrs={'class': 'form-select', 'id': 'id_jurisdiction_level'}))
    jurisdiction_state = forms.CharField(required=False, widget=forms.TextInput(attrs={'class': 'form-input', 'id': 'id_jurisdiction_state', 'placeholder': 'State Name'}))
    jurisdiction_district = forms.CharField(required=False, widget=forms.TextInput(attrs={'class': 'form-input', 'id': 'id_jurisdiction_district', 'placeholder': 'District Name'}))

    office_address = forms.CharField(widget=forms.Textarea(attrs={'class': 'form-input', 'rows': 3}))
    official_email = forms.EmailField(widget=forms.EmailInput(attrs={'class': 'form-input'}))
    official_phone = forms.CharField(widget=forms.TextInput(attrs={'class': 'form-input'}))

    appointment_letter = forms.FileField(required=False, widget=forms.FileInput(attrs={'class': 'form-input'}))
    authority_id_document = forms.FileField(required=False, widget=forms.FileInput(attrs={'class': 'form-input'}))


# --- Update Forms ---

class UserUpdateForm(forms.ModelForm):
    class Meta:
        model = User
        fields = ['first_name', 'last_name', 'email', 'phone_number', 'address_line_1', 'city', 'state']
        widgets = {
            'first_name': forms.TextInput(attrs={'class': 'form-input'}),
            'last_name': forms.TextInput(attrs={'class': 'form-input'}),
            'email': forms.EmailInput(attrs={'class': 'form-input'}),
            'phone_number': forms.TextInput(attrs={'class': 'form-input'}),
            'address_line_1': forms.TextInput(attrs={'class': 'form-input'}),
            'city': forms.TextInput(attrs={'class': 'form-input'}),
            'state': forms.TextInput(attrs={'class': 'form-input'}),
        }


class ProfileUpdateForm(forms.ModelForm):
    class Meta:
        model = Profile
        fields = ['photo', 'phone_number']
        widgets = {
            'photo': forms.FileInput(attrs={'class': 'form-input'}),
            'phone_number': forms.TextInput(attrs={'class': 'form-input'}),
        }


class VerificationProfileForm(forms.ModelForm):
    class Meta:
        model = VerificationProfile
        fields = ['govt_id', 'hospital_license', 'admin_id_proof', 'appointment_letter', 'authority_id']


class HospitalProfileForm(forms.ModelForm):
    class Meta:
        model = Hospital
        fields = ['hospital_name', 'hospital_type', 'registration_number', 'license_number', 'address', 'district', 'state', 'pincode', 'contact_number', 'email']
        widgets = {
            'hospital_name': forms.TextInput(attrs={'class': 'form-input'}),
            'hospital_type': forms.Select(attrs={'class': 'form-select'}),
            'registration_number': forms.TextInput(attrs={'class': 'form-input'}),
            'license_number': forms.TextInput(attrs={'class': 'form-input'}),
            'address': forms.Textarea(attrs={'class': 'form-input', 'rows': 3}),
            'district': forms.TextInput(attrs={'class': 'form-input'}),
            'state': forms.TextInput(attrs={'class': 'form-input'}),
            'pincode': forms.TextInput(attrs={'class': 'form-input'}),
            'contact_number': forms.TextInput(attrs={'class': 'form-input'}),
            'email': forms.EmailInput(attrs={'class': 'form-input'}),
        }


class AuthorityProfileForm(forms.ModelForm):
    class Meta:
        model = Authority
        fields = ['authority_name', 'authority_type', 'department_name', 'jurisdiction_level', 'jurisdiction_state', 'office_address', 'official_email', 'official_phone']
        widgets = {
             'authority_name': forms.TextInput(attrs={'class': 'form-input'}),
             'department_name': forms.TextInput(attrs={'class': 'form-input'}),
             'office_address': forms.Textarea(attrs={'class': 'form-input', 'rows': 3}),
             'official_email': forms.EmailInput(attrs={'class': 'form-input'}),
        }


class PatientSettingsForm(forms.ModelForm):
    class Meta:
        from .models import PatientSettings
        model = PatientSettings
        exclude = ['user']
        widgets = {
            'email_notifications': forms.CheckboxInput(attrs={'class': 'form-checkbox'}),
            'complaint_status_updates': forms.CheckboxInput(attrs={'class': 'form-checkbox'}),
        }
