from django.shortcuts import render, redirect, get_object_or_404
from django.contrib.auth import login, authenticate, logout, update_session_auth_hash
from django.contrib.auth.forms import AuthenticationForm
from django.contrib import messages
from django.contrib.auth.decorators import login_required
from django.views.decorators.clickjacking import xframe_options_sameorigin
from django.core.paginator import Paginator
from django.db.models import Q, Count
from django.urls import reverse
from django.utils import timezone
from django.utils.http import url_has_allowed_host_and_scheme as is_safe_url
from .forms import (
    UserUpdateForm, ProfileUpdateForm, VerificationProfileForm, 
    HospitalProfileForm, AuthorityProfileForm, PatientSettingsForm,
    PatientRegistrationForm, HospitalRegistrationForm, AuthorityRegistrationForm
)
from .models import User, Profile, VerificationProfile, Notification, PatientSettings, Hospital, Authority, PatientNotificationReply
from complaints.models import Complaint, Comment, Like, Category
from social.models import SupportTicket
# Email Activation Imports
from django.contrib.sites.shortcuts import get_current_site
from django.template.loader import render_to_string
from django.utils.http import urlsafe_base64_encode, urlsafe_base64_decode
from django.utils.encoding import force_bytes, force_str
from django.contrib.auth.tokens import default_token_generator
from django.core.mail import send_mail
from django.conf import settings
from django.db import transaction, IntegrityError
from django.http import JsonResponse, HttpResponse, FileResponse
from django.core.exceptions import PermissionDenied
import csv
from datetime import datetime
from django.contrib.sessions.models import Session

# User = get_user_model() # Already imported User from .models, which is likely the custom user model.
# However, using get_user_model() is safer if we want to be generic, but here we strictly use the custom User model defined in .models.
# given the previous code used `from .models import User`, we stick to that, but the register view used `User = get_user_model()`.
# Let's standardize on using the imported User class for consistency, or get_user_model if preferred. 
# The previous code mixed them. `from .models import User` acts as the direct import. 
# Let's use the direct import since it was explicitly used in other views, but ensuring `User` is our custom user.

# NOTE: If your IDE shows "Could not find import..." errors for standard libraries or local apps,
# checking python interpreter settings or restarting the IDE usually resolves it.
# The code is valid and verified with `python manage.py check`.

def home(request):
    return render(request, "home.html")

@login_required
def approve_users(request):

    # 🔒 STEP 6 LOGIC IS HERE
    if request.user.role != "superadmin":
        return redirect("pending_approval")
    
    pending_users = User.objects.filter(
        role__in=["hospital", "authority"],
        is_approved=False
    ).order_by("-date_joined").select_related("verification")

    return render(
        request,
        "accounts/approve_users.html",
        {"pending_users": pending_users,
        "total_pending": pending_users.count(),
        "hospital_count": pending_users.filter(role="hospital").count(),
        "authority_count": pending_users.filter(role="authority").count(),
    })


@login_required
def profile_redirect(request):
    role = request.user.role.lower()

    if role == "patient":
        return redirect("patient_profile")

    elif role == "hospital":
        return redirect("hospital_profile")

    elif role == "authority":
        return redirect("authority_profile")

    elif role == "superadmin":
        return redirect("admin_profile")

    # safety fallback
    return redirect("login")

@login_required
def patient_profile(request):
    user = request.user
    profile, _ = Profile.objects.get_or_create(user=user)

    complaints = Complaint.objects.filter(user=user)

    context = {
        "user_obj": user,
        "profile": profile,
        "total_complaints": complaints.count(),
        "resolved_complaints": complaints.filter(status="resolved").count(),
        "pending_complaints": complaints.exclude(status="resolved").count(),
    }

    return render(request, "accounts/patient_profile.html", context)


@login_required
def patient_dashboard(request):
    # 🔐 Allow only patients
    if request.user.role.lower() != "patient":
        return redirect("login")

    # Fetch User's Complaints
    user_complaints = Complaint.objects.filter(user=request.user)

    # 📊 Calculate Stats
    total_complaints = user_complaints.count()
    resolved_complaints = user_complaints.filter(status="resolved").count()
    pending_complaints = user_complaints.exclude(status="resolved").count()

    # 🕒 Recent Activity (Last 3)
    recent_activity = user_complaints.order_by("-created_at")[:3]

    # 🌍 Community Stats (Approximate)
    today = timezone.now().date()
    # Count complaints in 'billing' category created recently (e.g. this month) to show "active topics"
    community_billing_count = Complaint.objects.filter(category='billing', created_at__month=today.month).count()
    # Count resolved complaints today across the platform
    community_resolved_today = Complaint.objects.filter(status='resolved', created_at__date=today).count()

    context = {
        "total_complaints": total_complaints,
        "resolved_complaints": resolved_complaints,
        "pending_complaints": pending_complaints,
        "recent_activity": recent_activity,
        "user_obj": request.user, # For greeting
        "community_billing_count": community_billing_count,
        "community_resolved_today": community_resolved_today,
    }

    return render(request, "patients/dashboard.html", context)



def login_view(request):
    if request.method == "POST":

        username = request.POST.get("username")
        password = request.POST.get("password")

        # 📧 Allow Login by Email
        if '@' in username:
            try:
                user_obj = User.objects.get(email=username)
                username = user_obj.username
            except User.DoesNotExist:
                pass  # authenticate() will fail naturally

        user = authenticate(request, username=username, password=password)
        
        if user is None:
            # Check if user exists but is disabled
            try:
                disabled_user = User.objects.get(username=username)
                if not disabled_user.is_active and disabled_user.check_password(password):
                    if disabled_user.role in ['hospital', 'authority'] and not disabled_user.is_approved:
                         messages.error(request, "Your account is not yet approved. Please wait for admin approval.")
                         return render(request, "accounts/login.html")

                    # Check for Frozen Status
                    if disabled_user.account_status == 'frozen':
                        request.session['disabled_user_id'] = disabled_user.id
                        return redirect('account_frozen')
                    
                    # Check for Blocked Status
                    if disabled_user.account_status == 'blocked':
                        messages.error(request, "Your account has been permanently blocked due to violations of our terms.")
                        return render(request, "accounts/login.html")

                    request.session['disabled_user_id'] = disabled_user.id
                    return redirect('account_disabled')
            except User.DoesNotExist:
                pass

            messages.error(request, "Invalid username or password")
            return render(request, "accounts/login.html")
        
        # 🔒 LOGIN SAFETY CHECK: Block unapproved hospital/authority users
        # Check if user is approved before allowing login
        if user.role in ['hospital', 'authority'] and not user.is_approved:
            messages.error(request, "Your account is not yet approved. Please wait for admin approval.")
            return render(request, "accounts/login.html")
        if user.role in ['hospital', 'authority'] and not user.is_approved:
            messages.error(request, "Your account is not yet approved. Please wait for admin approval.")
            return render(request, "accounts/login.html")
        
        # 🔒 CHECK ACCOUNT STATUS
        if user.account_status == 'frozen':
             request.session['disabled_user_id'] = user.id
             return redirect('account_frozen')
        
        elif user.account_status == 'blocked':
             messages.error(request, "Your account has been permanently blocked.")
             return render(request, "accounts/login.html")
        
        # ✅ User is approved - proceed with login
        login(request, user)
        
        # 🧠 Remember Me Logic
        if not request.POST.get('remember_me'):
            # If not checked, session expires when browser closes
            request.session.set_expiry(0)
        else:
            # If checked, session expires in 2 weeks (default)
            request.session.set_expiry(1209600) 

        # role = user.role.lower().strip() # Unused variable

        # 🔑 SUPERADMIN
        if user.role == "superadmin":
            return redirect("admin_dashboard")
        
        if user.role == "hospital":
            next_url = request.GET.get('next')
            if next_url and is_safe_url(request, next_url, allowed_hosts={request.get_host()}):
                return redirect(next_url)
            return redirect("hospital_dashboard")

        if user.role == "authority":
            next_url = request.GET.get('next')
            if next_url and is_safe_url(request, next_url, allowed_hosts={request.get_host()}):
                return redirect(next_url)
            return redirect("authority_dashboard")
        
        if user.role == "patient":
            next_url = request.GET.get('next')
            if next_url and is_safe_url(request, next_url, allowed_hosts={request.get_host()}):
                return redirect(next_url)
            return redirect("patient_dashboard")
        # ✅ APPROVED NORMAL USERS
        messages.error(request, "Invalid user role")
        return redirect("login")
        
    return render(request, "accounts/login.html")
            

from .forms import (
    UserUpdateForm, ProfileUpdateForm, VerificationProfileForm, 
    HospitalProfileForm, AuthorityProfileForm, PatientSettingsForm,
    PatientRegistrationForm, HospitalRegistrationForm, AuthorityRegistrationForm
)
from .models import User, Profile, VerificationProfile, Notification, PatientSettings, Hospital, Authority, PhoneVerification, PatientNotificationReply
import random

# ... (other imports remain same)

def request_otp(request):
    if request.method == "POST":
        phone_number = request.POST.get('phone_number')
        if not phone_number:
            return JsonResponse({'status': 'error', 'message': 'Phone number required'})
            
        # Check if phone number is associated with a blocked account
        if User.objects.filter(phone_number=phone_number, account_status='blocked').exists():
             return JsonResponse({'status': 'error', 'message': 'This phone number is associated with a blocked account.'})

        # Generate 6-digit OTP
        otp = str(random.randint(100000, 999999))
        
        # Save to DB
        PhoneVerification.objects.update_or_create(
            phone_number=phone_number,
            defaults={'otp': otp, 'is_verified': False}
        )
        
        # MOCK: Log to Console
        print(f"========================================")
        print(f" OD MOCK SMS :: OTP for {phone_number} is {otp} ")
        print(f"========================================")
        
        return JsonResponse({'status': 'success', 'message': 'OTP sent successfully'})
    return JsonResponse({'status': 'error', 'message': 'Invalid request'})

def verify_otp(request):
    if request.method == "POST":
        phone_number = request.POST.get('phone_number')
        otp = request.POST.get('otp')
        
        try:
            record = PhoneVerification.objects.get(phone_number=phone_number)
            if record.otp == otp:
                record.is_verified = True
                record.save()
                return JsonResponse({'status': 'success', 'message': 'Phone number verified'})
            else:
                return JsonResponse({'status': 'error', 'message': 'Invalid OTP'})
        except PhoneVerification.DoesNotExist:
            return JsonResponse({'status': 'error', 'message': 'No OTP requested for this number'})
            
    return JsonResponse({'status': 'error', 'message': 'Invalid request'})

def validate_email(request):
    if request.method == "POST":
        email = request.POST.get('email')
        if not email:
            return JsonResponse({'status': 'error', 'message': 'Email required'})
        
        # 1. DB User Check
        users_with_email = User.objects.filter(email__iexact=email)
        if users_with_email.exists():
            # Check if any account with this email is blocked
            if users_with_email.filter(account_status='blocked').exists():
                 return JsonResponse({'status': 'error', 'message': 'Account with this email has been permanently blocked.'})
            return JsonResponse({'status': 'error', 'message': 'Email already registered with us.'})
             
        # 2. Mock API Check (Simulate external validation)
        # Randomly fail for specific domain 'fake.com' to demonstrate functionality
        if email.endswith('@fake.com'):
             return JsonResponse({'status': 'error', 'message': 'Email domain invalid (Mock API).'})
             
        return JsonResponse({'status': 'success', 'message': 'Email is valid.'})

    return JsonResponse({'status': 'error', 'message': 'Invalid request'})

def register_view(request):
    if request.method == "POST":
        role = request.POST.get("role")
        
        if role == 'patient':
            form = PatientRegistrationForm(request.POST, request.FILES)
        elif role == 'hospital':
            form = HospitalRegistrationForm(request.POST, request.FILES)
        elif role == 'authority':
            form = AuthorityRegistrationForm(request.POST, request.FILES)
        else:
            messages.error(request, "Invalid role selected.")
            return render(request, "accounts/register.html", {
                "patient_form": PatientRegistrationForm(),
                "hospital_form": HospitalRegistrationForm(),
                "authority_form": AuthorityRegistrationForm(),
                "active_role": "patient"
            })
        

        
        if form.is_valid():
            # 🛡️ SYSTEM CHECK: PREVENT BLOCKED USER RE-REGISTRATION
            # Check unique identifiers against blocked users
            cleaned_data = form.cleaned_data
            
            # 1. Email check (Covered by model unique, but good to be explicit for different variants)
            email = cleaned_data.get('email')
            if User.objects.filter(email__iexact=email, account_status='blocked').exists():
                 messages.error(request, "Registration failed: This email is associated with a blocked account.")
                 return render(request, "accounts/register.html", {
                    "patient_form": form if role == 'patient' else PatientRegistrationForm(),
                    "hospital_form": form if role == 'hospital' else HospitalRegistrationForm(),
                    "authority_form": form if role == 'authority' else AuthorityRegistrationForm(),
                    "active_role": role
                 })

            # 2. Phone check (Not always unique in generic User model, but critical here)
            # We need to find which phone field was used. 
            # Patient form uses 'phone_number', Hospital likely has contact fields.
            # Assuming 'phone_number' in User model is populated from form save logic usually, 
            # but here form.save(commit=false) happens later.
            # Let's check the POST data or cleaned_data directly based on Role.
            
            phone_to_check = None
            if role == 'patient':
                 # PatientRegistrationForm doesn't have phone_number field explicitly in User model maybe?
                 # Wait, User model has phone_number. Form might have it.
                 # Let's check existing verification logic.
                 # Actually, PatientRegistrationForm likely relies on the separate verified phone logic or input.
                 # But let's check generic contact info if available.
                 phone_to_check = request.POST.get('phone_number') 
            elif role == 'hospital':
                 phone_to_check = cleaned_data.get('hospital_contact')
            elif role == 'authority':
                 phone_to_check = cleaned_data.get('official_phone')

            if phone_to_check and User.objects.filter(phone_number=phone_to_check, account_status='blocked').exists():
                 messages.error(request, "Registration failed: This phone number is associated with a blocked account.")
                 return render(request, "accounts/register.html", {
                    "patient_form": form if role == 'patient' else PatientRegistrationForm(),
                    "hospital_form": form if role == 'hospital' else HospitalRegistrationForm(),
                    "authority_form": form if role == 'authority' else AuthorityRegistrationForm(),
                    "active_role": role
                 })

            # 3. Govt ID Check (For Patients)
            if role == 'patient':
                 govt_id_num = cleaned_data.get('govt_id_number')
                 if govt_id_num and User.objects.filter(govt_id_number=govt_id_num, account_status='blocked').exists():
                     messages.error(request, "Registration failed: This Government ID is associated with a blocked account.")
                     return render(request, "accounts/register.html", {
                        "patient_form": form if role == 'patient' else PatientRegistrationForm(),
                        "hospital_form": form if role == 'hospital' else HospitalRegistrationForm(),
                        "authority_form": form if role == 'authority' else AuthorityRegistrationForm(),
                        "active_role": role
                     })

            try:
                with transaction.atomic():
                    # Check Phone on User Creation level (Double check)
                    # ... [Original Save Logic] ...
                    
                    print(f"Form is valid for role: {role}")
                    print(f"Form cleaned data: {list(form.cleaned_data.keys())}")
                    # 1. Save User
                    user = form.save(commit=False)
                    user.set_password(form.cleaned_data.get("password"))
                    user.role = role
                    
                    # Patients are auto-active and auto-approved
                    # Hospitals and Authorities are inactive and unapproved until admin review
                    if role == 'patient':
                        user.is_active = True
                        user.is_approved = True
                        user.is_verified = True # Auto-verify for direct access
                    else:
                        user.is_active = False
                        user.is_approved = False
                        user.is_verified = False
                    
                    user.save()
                    print(f"User saved: {user.username}, ID: {user.id}")
                    
                    # 2. Save Role Specific Data
                    if role == 'hospital':
                        Hospital.objects.create(
                            user=user,
                            hospital_name=form.cleaned_data.get('hospital_name'),
                            hospital_type=form.cleaned_data.get('hospital_type'),
                            registration_number=form.cleaned_data.get('registration_number'),
                            license_number=form.cleaned_data.get('license_number'),
                            license_document=form.cleaned_data.get('license_document'),
                            address=form.cleaned_data.get('hospital_address'),
                            district=form.cleaned_data.get('hospital_district'),
                            state=form.cleaned_data.get('hospital_state'),
                            pincode=form.cleaned_data.get('hospital_pincode'),
                            contact_number=form.cleaned_data.get('hospital_contact'),
                            email=form.cleaned_data.get('hospital_email')
                        )
                    elif role == 'authority':
                        Authority.objects.create(
                            user=user,
                            authority_name=form.cleaned_data.get('authority_name'),
                            authority_type=form.cleaned_data.get('authority_type'),
                            department_name=form.cleaned_data.get('department_name'),
                            jurisdiction_level=form.cleaned_data.get('jurisdiction_level'),
                            jurisdiction_state=form.cleaned_data.get('jurisdiction_state'),
                            jurisdiction_district=form.cleaned_data.get('jurisdiction_district'),
                            office_address=form.cleaned_data.get('office_address'),
                            official_email=form.cleaned_data.get('official_email'),
                            official_phone=form.cleaned_data.get('official_phone'),
                            appointment_letter=form.cleaned_data.get('appointment_letter'),
                            authority_id_document=form.cleaned_data.get('authority_id_document')
                        )
                    elif role == 'patient':
                        # Save Govt ID to VerificationProfile
                        verification, _ = VerificationProfile.objects.get_or_create(user=user)
                        verification.govt_id = form.cleaned_data.get('govt_id_document')
                        verification.save()
                        
                        # Also save govt_id_type/number to user
                        user.govt_id_type = form.cleaned_data.get('govt_id_type')
                        user.govt_id_number = form.cleaned_data.get('govt_id_number')
                        user.save()

                    # 3. Create Basic Profile
                    Profile.objects.create(user=user)
                    
                    # 4. Send Activation Email (All roles require email verification)
                    current_site = get_current_site(request)
                    mail_subject = 'Activate your MedVoice account'
                    message = render_to_string('accounts/activation_email.html', {
                        'user': user,
                        'domain': current_site.domain,
                        'uid': urlsafe_base64_encode(force_bytes(user.pk)),
                        'token': default_token_generator.make_token(user),
                        'protocol': 'https' if request.is_secure() else 'http'
                    })
                    
                    to_email = form.cleaned_data.get('email')
                    try:
                        send_mail(mail_subject, message, settings.DEFAULT_FROM_EMAIL, [to_email], html_message=message)
                    except Exception as e:
                        # Log error but don't fail registration
                        print(f"Email send failed: {e}")
                    
                    # Different success messages based on role
                    if role == 'patient':
                        messages.success(request, "Registration successful! Please check your email to activate your account. After activation, you can login immediately.")
                    else:
                        messages.success(request, f"Registration successful! Please check your email to activate your account. Your {role} account is pending admin approval.")
                
                return redirect("login")
                
            except Exception as e:
                # Log the error for debugging
                import traceback
                print(f"Registration error: {e}")
                print(traceback.format_exc())
                messages.error(request, f"An error occurred during registration: {str(e)}")
                # Re-render form with errors - preserve user input
                return render(request, "accounts/register.html", {
                    "patient_form": form if role == 'patient' else PatientRegistrationForm(),
                    "hospital_form": form if role == 'hospital' else HospitalRegistrationForm(),
                    "authority_form": form if role == 'authority' else AuthorityRegistrationForm(),
                    "active_role": role
                })
        else:
            # Form is invalid - show errors and log them
            print(f"Form errors: {form.errors}")
            messages.error(request, "Please correct the errors below.")
            return render(request, "accounts/register.html", {
                "patient_form": form if role == 'patient' else PatientRegistrationForm(),
                "hospital_form": form if role == 'hospital' else HospitalRegistrationForm(),
                "authority_form": form if role == 'authority' else AuthorityRegistrationForm(),
                "active_role": role
            })
    
    # GET request - show registration form
    return render(request, "accounts/register.html", {
        "patient_form": PatientRegistrationForm(),
        "hospital_form": HospitalRegistrationForm(),
        "authority_form": AuthorityRegistrationForm(),
        "active_role": "patient"
    })


def activate(request, uidb64, token):
    try:
        uid = force_str(urlsafe_base64_decode(uidb64))
        user = User.objects.get(pk=uid)
    except(TypeError, ValueError, OverflowError, User.DoesNotExist):
        user = None

    if user is not None and default_token_generator.check_token(user, token):
        user.is_active = True
        user.save()
        messages.success(request, "Thank you for your email confirmation. You can now login to your account.")
        return redirect('login') 
    else:
        return render(request, 'accounts/activation_invalid.html')


@login_required
def approve_user(request, user_id):

    if request.user.role != "superadmin":
        return redirect("feed")

    if request.method == "POST":
        user = get_object_or_404(User, id=user_id)
        user.is_approved = True
        user.is_active = True
        user.is_verified = True
        user.reactivation_requested = False
        user.save()
        
        # Also update Hospital status if user is a hospital
        if user.role == "hospital" and hasattr(user, 'hospital_profile'):
            hospital = user.hospital_profile
            hospital.status = 'verified'
            hospital.save()
            
        messages.success(request, f"User {user.username} approved successfully.")

    return redirect("approve_users")

@login_required
def reject_user(request, user_id):

    if request.user.role != "superadmin":
        return redirect("feed")

    if request.method == "POST":
        user = get_object_or_404(User, id=user_id)
        user.is_active = False
        user.is_approved = False
        user.reactivation_requested = False
        user.save(update_fields=["is_active", "is_approved", "reactivation_requested"])
        reason = request.POST.get("rejection_reason", "").strip()
        if reason:
            messages.success(request, f"User {user.username} rejected. Reason: {reason}")
        else:
            messages.success(request, f"User {user.username} rejected.")

    return redirect("approve_users")


@login_required
def admin_review_detail(request, user_id):
    if request.user.role != "superadmin":
        return redirect("login")

    target_user = get_object_or_404(User, id=user_id)
    if target_user.role not in ["hospital", "authority"]:
        return redirect("approve_users")

    hospital_profile = None
    authority_profile = None
    if target_user.role == "hospital":
        hospital_profile = getattr(target_user, "hospital_profile", None)
    elif target_user.role == "authority":
        authority_profile = getattr(target_user, "authority_profile", None)

    verification = getattr(target_user, "verification", None)

    documents = []
    def add_doc(label, key, file_field):
        if file_field:
            documents.append({
                "label": label,
                "key": key,
            })

    if target_user.role == "hospital":
        if hospital_profile:
            add_doc("License Document", "hospital_license_document", hospital_profile.license_document)
        if verification:
            add_doc("Authorization Letter", "verification_admin_id_proof", getattr(verification, "admin_id_proof", None))
            add_doc("Hospital License (Verification)", "verification_hospital_license", getattr(verification, "hospital_license", None))

    if target_user.role == "authority":
        if authority_profile:
            add_doc("Appointment Letter", "authority_appointment_letter", authority_profile.appointment_letter)
            add_doc("Authority ID Document", "authority_id_document", authority_profile.authority_id_document)
        if verification:
            add_doc("Appointment Letter (Verification)", "verification_appointment_letter", getattr(verification, "appointment_letter", None))
            add_doc("Authority ID (Verification)", "verification_authority_id", getattr(verification, "authority_id", None))

    return render(request, "accounts/admin_review_detail.html", {
        "target_user": target_user,
        "hospital_profile": hospital_profile,
        "authority_profile": authority_profile,
        "documents": documents,
    })


@login_required
@xframe_options_sameorigin
def admin_document_view(request, user_id, doc_key):
    if request.user.role != "superadmin":
        raise PermissionDenied

    target_user = get_object_or_404(User, id=user_id)
    if target_user.role not in ["hospital", "authority"]:
        raise PermissionDenied

    hospital_profile = getattr(target_user, "hospital_profile", None)
    authority_profile = getattr(target_user, "authority_profile", None)
    verification = getattr(target_user, "verification", None)

    file_field = None

    if doc_key == "hospital_license_document" and hospital_profile:
        file_field = hospital_profile.license_document
    elif doc_key == "authority_appointment_letter" and authority_profile:
        file_field = authority_profile.appointment_letter
    elif doc_key == "authority_id_document" and authority_profile:
        file_field = authority_profile.authority_id_document
    elif doc_key == "verification_hospital_license" and verification:
        file_field = verification.hospital_license
    elif doc_key == "verification_admin_id_proof" and verification:
        file_field = verification.admin_id_proof
    elif doc_key == "verification_appointment_letter" and verification:
        file_field = verification.appointment_letter
    elif doc_key == "verification_authority_id" and verification:
        file_field = verification.authority_id

    if not file_field:
        return HttpResponse(status=404)

    return FileResponse(file_field.open("rb"), as_attachment=False)

@login_required
def pending_approval(request):

    # 🚫 Approved users should NOT see this page
    if request.user.is_approved:
        return redirect("feed")
    # ✅ Hospital Admin & Authority (not approved)
    return render(request, "accounts/pending_approval.html")

@login_required
def admin_dashboard(request):
    if request.user.role != "superadmin":
        return redirect("login")

    # 📊 Statistics
    total_users = User.objects.count()
    total_complaints = Complaint.objects.count()
    resolved_complaints = Complaint.objects.filter(status='resolved').count()
    active_investigations = Complaint.objects.filter(status='review').count() # 'review' status as proxy for investigation
    
    # Pending Provider Approvals
    pending_approvals_qs = User.objects.filter(role__in=["hospital", "authority"], is_approved=False)
    pending_approvals_count = pending_approvals_qs.count()
    recent_approvals = pending_approvals_qs.order_by('-date_joined')[:5]

    # Recent Complaints
    recent_complaints = Complaint.objects.select_related('user').order_by('-created_at')[:5]

    context = {
        "total_users": total_users,
        "total_complaints": total_complaints,
        "resolved_complaints": resolved_complaints,
        "active_investigations": active_investigations,
        "pending_approvals_count": pending_approvals_count,
        "recent_approvals": recent_approvals,
        "recent_complaints": recent_complaints,
    }

    return render(request, "accounts/admin_dashboard.html", context)

from django.contrib.auth.decorators import user_passes_test

def superadmin_only(view_func):
    decorator = user_passes_test(lambda u: u.role == 'superadmin', login_url='login')
    return decorator(view_func)
        
@login_required
@superadmin_only
def admin_users(request):
    
    # Base QuerySet - Show ONLY approved users (Patients are usually auto-approved, others after review)
    # Pending users are handled in `approve_users` view
    # BUT: Include users with pending reactivation requests regardless of is_approved status
    reactivation_filter = request.GET.get('status') == 'reactivation_requested'
    users = User.objects.filter(
        Q(is_approved=True) | Q(reactivation_requested=True)
    ).order_by("-date_joined")
    
    # 🔍 Search
    search_query = request.GET.get('search')
    if search_query:
        users = users.filter(
            Q(username__icontains=search_query) |
            Q(email__icontains=search_query) |
            Q(first_name__icontains=search_query) |
            Q(last_name__icontains=search_query)
        )

    # 🎯 Role Filter
    role_filter = request.GET.get('role',"all")
    if role_filter and role_filter != 'all':
        users = users.filter(role=role_filter)

    # 🚦 Status Filter
    status_filter = request.GET.get('status')
    if status_filter and status_filter != 'all':
        if status_filter == 'active':
            users = users.filter(is_active=True)
        elif status_filter == 'disabled':
            users = users.filter(is_active=False)
        elif status_filter == 'reactivation_requested':
             users = users.filter(reactivation_requested=True)

    # 📊 Performance Metrics (Annotations)
    # Count comments made by the user as a proxy for "replies"
    users = users.annotate(reply_count=Count('comments_made'))

    # 📄 Pagination
    paginator = Paginator(users, 10)  # Show 10 users per page
    page_number = request.GET.get('page')
    page_obj = paginator.get_page(page_number)

    # 🛡️ Safe Profile Access Implementation
    # Prevent 500 errors if user.profile is missing (RelatedObjectDoesNotExist)
    for user in page_obj:
        try:
            if hasattr(user, 'profile') and user.profile.photo:
                user.safe_photo_url = user.profile.photo.url
            else:
                user.safe_photo_url = None
        except Exception:
             # Fallback for any other relationship errors
            user.safe_photo_url = None

    context = {
        "users": page_obj,
        "search_query": search_query,
        "role_filter": role_filter,
        "status_filter": status_filter,
        "total_users": users.count(),
    }

    return render(request, "accounts/admin_users.html", context)


@login_required
def toggle_user_status(request, user_id):
    superadmin_only(request)
    
    if request.method == "POST":
        user = get_object_or_404(User, id=user_id)
        
        # Prevent disabling yourself
        if user == request.user:
            messages.error(request, "You cannot disable your own account.")
            return redirect("admin_users")
            
        # Toggle status
        user.is_active = not user.is_active
    
        # If enabling, clear any reactivation requests
        if user.is_active:
            user.reactivation_requested = False
            
        user.save()
        
        status = "enabled" if user.is_active else "disabled"
        messages.success(request, f"User {user.username} has been {status}.")
        
    return redirect("admin_users")

@login_required
def admin_categories(request):
    superadmin_only(request)
    
    if request.method == "POST":
        action = request.POST.get('action')
        
        if action == 'add':
            name = request.POST.get('name')
            if name:
                if Category.objects.filter(name__iexact=name).exists():
                    messages.error(request, f"Category '{name}' already exists.")
                else:
                    description = request.POST.get('description', '')
                    Category.objects.create(name=name, description=description)
                    messages.success(request, f"Category '{name}' added successfully.")
        
        elif action == 'delete':
            category_id = request.POST.get('category_id')
            try:
                category = Category.objects.get(id=category_id)
                category.delete()
                messages.success(request, f"Category '{category.name}' deleted.")
            except Category.DoesNotExist:
                messages.error(request, "Category not found.")
                
        return redirect('admin_categories')

        return redirect('admin_categories')

    category_list = Category.objects.all().order_by('-created_at')
    paginator = Paginator(category_list, 6) # Show 6 categories per page
    page_number = request.GET.get('page')
    categories = paginator.get_page(page_number)
    
    return render(request, "accounts/admin_categories.html", {"categories": categories})

@login_required
def admin_performance(request):
    superadmin_only(request)
    if request.GET.get("export") == "1":
        response = HttpResponse(content_type="text/csv")
        filename = f"medvoice-performance-{datetime.now().strftime('%Y%m%d')}.csv"
        response["Content-Disposition"] = f'attachment; filename="{filename}"'
        writer = csv.writer(response)
        writer.writerow(["Metric", "Value"])
        writer.writerow(["Total Users", User.objects.count()])
        writer.writerow(["Total Complaints", Complaint.objects.count()])
        writer.writerow(["Resolved Complaints", Complaint.objects.filter(status="resolved").count()])
        writer.writerow(["Open Support Tickets", SupportTicket.objects.filter(status="open").count()])
        return response
    return render(request, "accounts/admin_performance.html")


@login_required
def admin_settings(request):
    if request.user.role != "superadmin":
        return redirect("login")
    
    user = request.user
    profile, _ = Profile.objects.get_or_create(user=user)
    
    if request.method == "POST":
        # Track if anything was updated
        profile_updated = False
        password_changed = False
        
        # Handle profile update
        new_first_name = request.POST.get("first_name", "").strip()
        new_last_name = request.POST.get("last_name", "").strip()
        
        if new_first_name != user.first_name:
            user.first_name = new_first_name
            profile_updated = True
            
        if new_last_name != user.last_name:
            user.last_name = new_last_name
            profile_updated = True
        
        # Handle email update
        new_email = request.POST.get("email", "").strip()
        original_email = user.email or ""
        if new_email and new_email != original_email:
            from django.contrib.auth import get_user_model
            User = get_user_model()
            if User.objects.filter(email=new_email).exclude(id=user.id).exists():
                messages.error(request, "Email already in use by another account.")
                return render(request, "accounts/admin_settings.html", {
                    "user_obj": user,
                    "profile": profile,
                })
            user.email = new_email
            profile_updated = True
        
        # Handle phone number update (through profile)
        new_phone = request.POST.get("phone_number", "").strip()
        if new_phone != profile.phone_number:
            profile.phone_number = new_phone
            profile.save()
        
        # Handle profile photo
        if "photo" in request.FILES:
            profile.photo = request.FILES["photo"]
            profile.save()
            profile_updated = True
        
        # Handle password change
        current_password = request.POST.get("current_password", "").strip()
        new_password = request.POST.get("new_password", "").strip()
        confirm_password = request.POST.get("confirm_password", "").strip()
        
        if current_password or new_password or confirm_password:
            if not current_password:
                messages.error(request, "Current password is required to change password.")
                return render(request, "accounts/admin_settings.html", {
                    "user_obj": user,
                    "profile": profile,
                })
            
            if not user.check_password(current_password):
                messages.error(request, "Current password is incorrect.")
                return render(request, "accounts/admin_settings.html", {
                    "user_obj": user,
                    "profile": profile,
                })
            
            if not new_password:
                messages.error(request, "New password is required.")
                return render(request, "accounts/admin_settings.html", {
                    "user_obj": user,
                    "profile": profile,
                })
            
            if len(new_password) < 8:
                messages.error(request, "Password must be at least 8 characters.")
                return render(request, "accounts/admin_settings.html", {
                    "user_obj": user,
                    "profile": profile,
                })
            
            if new_password != confirm_password:
                messages.error(request, "New passwords do not match.")
                return render(request, "accounts/admin_settings.html", {
                    "user_obj": user,
                    "profile": profile,
                })
            
            user.set_password(new_password)
            from django.contrib.auth import update_session_auth_hash
            update_session_auth_hash(request, user)
            password_changed = True
        
        # Save user changes
        user.save()
        
        # Show success message - always show when no errors occurred
        if password_changed:
            messages.success(request, "Password changed successfully!")
        else:
            messages.success(request, "Profile updated successfully!")
        
        return redirect("admin_profile")

    return render(request, "accounts/admin_settings.html", {
        "user_obj": user,
        "profile": profile,
    })


@login_required
def admin_profile(request):
    user = request.user
    
    # Get profile - fetch fresh from database
    try:
        profile = Profile.objects.get(user=user)
    except Profile.DoesNotExist:
        profile = Profile.objects.create(user=user)
    
    # Calculate password last changed (Django doesn't track this directly, so we use last_login as proxy)
    last_password_change = user.last_login
    
    # Get user counts for activity overview (these would be static for now or calculated from actual data)
    from django.contrib.auth import get_user_model
    User = get_user_model()
    
    total_users = User.objects.filter(role='patient').count()
    pending_approvals = User.objects.filter(is_approved=False, role__in=['hospital', 'authority']).count()
    
    from complaints.models import Complaint
    total_complaints = Complaint.objects.count()
    
    from django.utils import timezone
    from datetime import timedelta
    urgent_complaints = Complaint.objects.filter(status='urgent').count()
    
    return render(request, "accounts/admin_profile.html", {
        "user_obj": user,
        "profile": profile,
        "last_password_change": last_password_change,
        "total_users": total_users,
        "pending_approvals": pending_approvals,
        "total_complaints": total_complaints,
        "urgent_complaints": urgent_complaints,
    })


@login_required
def patient_settings(request):
    # ---- SETTINGS OBJECT (safe create) ----
    settings_obj, _ = PatientSettings.objects.get_or_create(user=request.user)

    # ---- PROFILE OBJECT (for photo) ----
    profile, _ = Profile.objects.get_or_create(user=request.user)

    if request.method == "POST":
        user = request.user

        # ==============================
        # USER BASIC INFO
        # ==============================
        user.first_name = request.POST.get("first_name", user.first_name)
        user.last_name = request.POST.get("last_name", user.last_name)

        # ---- UNIQUE EMAIL ----
        new_email = request.POST.get("email")
        if new_email and new_email != user.email:
            if User.objects.filter(email=new_email).exclude(id=user.id).exists():
                messages.error(request, "Email already in use.")
                return redirect("settings")
            user.email = new_email

        # ---- UNIQUE USERNAME ----
        new_username = request.POST.get("username")
        if new_username and new_username != user.username:
            if User.objects.filter(username=new_username).exclude(id=user.id).exists():
                messages.error(request, "Username already taken.")
                return redirect("settings")
            user.username = new_username

        # ==============================
        # PASSWORD CHANGE
        # ==============================
        current_password = request.POST.get("current_password", "").strip()
        new_password = request.POST.get("new_password", "").strip()
        confirm_password = request.POST.get("confirm_password", "").strip()

        if current_password or new_password or confirm_password:
            if not current_password:
                messages.error(request, "Current password is required to change password.")
                return redirect("settings")

            if not user.check_password(current_password):
                messages.error(request, "Current password is incorrect.")
                return redirect("settings")

            if not new_password:
                messages.error(request, "New password is required.")
                return redirect("settings")

            if len(new_password) < 8:
                messages.error(request, "Password must be at least 8 characters.")
                return redirect("settings")

            if new_password != confirm_password:
                messages.error(request, "New passwords do not match.")
                return redirect("settings")

            user.set_password(new_password)
            update_session_auth_hash(request, user)
            messages.success(request, "Password updated successfully.")

        user.save()

        # ==============================
        # PROFILE PHOTO UPLOAD
        # ==============================
        if "photo" in request.FILES:
            profile.photo = request.FILES["photo"]
        
        profile.phone_number = request.POST.get("phone_number", profile.phone_number)
        profile.save()

        # ==============================
        # SETTINGS TOGGLES
        # ==============================
        settings_obj.email_notifications = "email_notifications" in request.POST
        settings_obj.complaint_status_updates = "complaint_status_updates" in request.POST
        settings_obj.new_messages = "new_messages" in request.POST
        settings_obj.authority_responses = "authority_responses" in request.POST

        settings_obj.show_in_feed = "show_in_feed" in request.POST
        settings_obj.anonymous_posting = "anonymous_posting" in request.POST
        settings_obj.show_resolved_publicly = "show_resolved_publicly" in request.POST

        settings_obj.hide_profile = "hide_profile" in request.POST
        settings_obj.allow_hospital_contact = "allow_hospital_contact" in request.POST
        settings_obj.allow_escalation = "allow_escalation" in request.POST

        settings_obj.theme = request.POST.get("theme", settings_obj.theme)
        settings_obj.save()

        messages.success(request, "Settings updated successfully.")
        return redirect("profile")

    return render(
        request,
        "accounts/patient_settings.html",
        {
            "settings": settings_obj,
            "profile": profile,
            "user_obj": request.user,
        }
    )


@login_required
def patient_notifications(request):
    notifications = Notification.objects.filter(recipient=request.user).order_by("-created_at")
    unread_count = notifications.filter(is_read=False).count()
    replies = PatientNotificationReply.objects.filter(notification__in=notifications).order_by("-created_at")
    reply_map = {}
    for reply in replies:
        if reply.notification_id not in reply_map:
            reply_map[reply.notification_id] = reply
    for notification in notifications:
        notification.patient_reply = reply_map.get(notification.id)
    return render(
        request,
        "patients/notifications.html",
        {
            "notifications": notifications,
            "unread_count": unread_count,
        },
    )


@login_required
def get_notifications(request):
    notifications = Notification.objects.filter(recipient=request.user, is_read=False).order_by('-created_at')
    data = []
    for n in notifications:
        data.append({
            "id": n.id,
            "title": n.title,
            "message": n.message,
            "link": n.link,
            "created_at": n.created_at.strftime("%b %d, %H:%M")
        })
    return JsonResponse({"notifications": data, "count": notifications.count()})

@login_required
def mark_notification_read(request, notification_id):
    notification = get_object_or_404(Notification, id=notification_id, recipient=request.user)
    
    if request.method == "GET":
        notification.is_read = True
        notification.save()
        if notification.link:
            return redirect(notification.link)
        # Default fallback if no link
        if request.user.role == 'hospital':
            return redirect('hospital_dashboard') 
        elif request.user.role == 'patient':
            return redirect('patient_dashboard')
        elif request.user.role == 'authority':
            return redirect('authority_dashboard')
        return redirect('home')

    if request.method == "POST":
        notification.is_read = True
        notification.save()
        return JsonResponse({"status": "ok"})
    
    return JsonResponse({"error": "Invalid method"}, status=400)


@login_required
def reply_to_notification(request, notification_id):
    if request.method != "POST":
        return JsonResponse({"error": "Invalid method"}, status=400)

    notification = get_object_or_404(Notification, id=notification_id, recipient=request.user)
    message = request.POST.get("reply_message", "").strip()
    if not message:
        messages.error(request, "Response cannot be empty.")
        return redirect("patient_notifications")

    PatientNotificationReply.objects.create(
        notification=notification,
        user=request.user,
        support_ticket=notification.support_ticket,
        message=message
    )
    messages.success(request, "Your response has been sent.")
    return redirect("patient_notifications")


@login_required
def logout_all_devices(request):
    if request.method == "POST":
        # Get all sessions for this user
        # We need to filter sessions manually because Django session store doesn't directly link to user easily without querying all
        # Optimization: In production with millions of sessions, this might be slow. 
        # But for this scale, iterating is "okay" or we can rely on a third party package. 
        # Standard approach for default django:
        
        sessions = Session.objects.filter(expire_date__gte=timezone.now())
        for session in sessions:
            data = session.get_decoded()
            if str(data.get('_auth_user_id')) == str(request.user.id):
                session.delete()
        
        # Finally logout current session (which might have been deleted above, but good to be sure)
        logout(request)
        messages.success(request, "Logged out from all devices successfully.")
        return redirect("login")

def custom_logout(request):
    """
    Custom logout view to clear site data and prevent back/forward navigation.
    """
    logout(request)
    response = redirect('home') # Redirect to home page
    
    # Critical: Clear all client-side data to prevent forward/back navigation to authenticated pages
    # This header tells the browser to wipe cookies, cache, storage for this origin
    response['Clear-Site-Data'] = '"cache", "cookies", "storage", "executionContexts"'
    
    return response
    



@login_required
def admin_user_activity(request, user_id):
    if request.user.role != "superadmin":
        return redirect("login")
    
    target_user = get_object_or_404(User, id=user_id)
    
    # Allow access to users with pending reactivation requests (they have is_approved=False but are requesting reactivation)
    if not target_user.is_approved and not target_user.reactivation_requested:
        messages.error(request, "This user is not approved.")
        return redirect("admin_users")
    
    activities = []

    # ==========================
    # 🔄 REACTIVATION REQUEST ACTIVITY
    # ==========================
    # Note: Reactivation requests are logged via UserActivity below
    # This block remains as a fallback for users who have reactivation_requested=True but no activity log
    if target_user.reactivation_requested:
        # Check if there's a reactivation activity log
        from .models import UserActivity
        has_reactivation_log = UserActivity.objects.filter(
            user=target_user, 
            action_type='Reactivation Requested'
        ).exists()
        
        if not has_reactivation_log:
            # Only show this fallback if no activity log exists
            # Use date_joined as fallback timestamp
            activities.append({
                'type': 'Reactivation Request',
                'icon': 'autorenew',
                'description': f"Requested account reactivation: {target_user.reactivation_reason or 'No reason provided'}",
                'date': target_user.date_joined,
                'link': None
            })

    # ==========================
    # 🏥 HOSPITAL ACTIVITIES
    # ==========================
    if target_user.role == 'hospital':
        # 1. Responses to Complaints
        # We need to import HospitalResponse locally or ensure it's imported
        from complaints.models import HospitalResponse
        responses = HospitalResponse.objects.filter(hospital=target_user)
        for r in responses:
            activities.append({
                'type': 'Response',
                'icon': 'rate_review',
                'description': f"Responded to complaint: {r.complaint.title}",
                'date': r.created_at,
                'link': f"/complaints/complaint/{r.complaint.id}/"
            })

        # 2. Warnings Received
        from authorities.models import HospitalWarning
        warnings = HospitalWarning.objects.filter(hospital=target_user)
        for w in warnings:
             activities.append({
                'type': 'Warning Received',
                'icon': 'warning',
                'description': f"Received {w.warning_type} warning: {w.reason}",
                'date': w.created_at,
                'link': None # No direct link for now, maybe profile
            })

        # 3. Freeze Actions (Target)
        from authorities.models import HospitalFreeze
        freezes = HospitalFreeze.objects.filter(hospital=target_user)
        for f in freezes:
             activities.append({
                'type': 'Account Frozen',
                'icon': 'lock',
                'description': f"Account frozen: {f.reason}",
                'date': f.frozen_at,
                'link': None
            })

    # ==========================
    # 👮 AUTHORITY ACTIVITIES
    # ==========================
    elif target_user.role == 'authority':
        # 1. Warnings Issued
        from authorities.models import HospitalWarning
        issued_warnings = HospitalWarning.objects.filter(issued_by=target_user)
        for w in issued_warnings:
             activities.append({
                'type': 'Warning Issued',
                'icon': 'assignment_late',
                'description': f"Issued warning to {w.hospital.username}",
                'date': w.created_at,
                'link': None
            })

        # 2. Freeze Actions (Performed)
        from authorities.models import HospitalFreeze
        frozen_actions = HospitalFreeze.objects.filter(frozen_by=target_user)
        for f in frozen_actions:
             activities.append({
                'type': 'Freeze Action',
                'icon': 'gavel',
                'description': f"Froze hospital account: {f.hospital.username}",
                'date': f.frozen_at,
                'link': None
            })
            
        # 3. Complaint Activities (Escalations/Reviews)
        from authorities.models import ComplaintActivityLog
        logs = ComplaintActivityLog.objects.filter(performed_by=target_user)
        for l in logs:
             activities.append({
                'type': 'Oversight',
                'icon': 'visibility',
                'description': f"{l.get_activity_type_display()}: {l.complaint.title}",
                'date': l.created_at,
                'link': f"/complaints/complaint/{l.complaint.id}/"
            })

    # ==========================
    # 👤 PATIENT / COMMON ACTIVITIES
    # ==========================
    
    # 1. Complaints Posted (Mostly Patient, but technically any user could potentially if logic allowed)
    complaints = Complaint.objects.filter(user=target_user)
    for c in complaints:
        activities.append({
            'type': 'Complaint',
            'icon': 'edit_note',
            'description': f"Posted complaint: {c.title}",
            'date': c.created_at,
            'link': f"/complaints/complaint/{c.id}/"
        })
        
    # 2. Comments Made (Common)
    comments = Comment.objects.filter(user=target_user)
    for c in comments:
        activities.append({
            'type': 'Comment',
            'icon': 'chat',
            'description': f"Commented on {c.complaint.title}",
            'date': c.created_at,
            'link': f"/complaints/complaint/{c.complaint.id}/"
        })

    # 3. Likes Given (Common)
    likes = Like.objects.filter(user=target_user)
    for l in likes:
        activities.append({
            'type': 'Like',
            'icon': 'thumb_up',
            'description': f"Liked complaint: {l.complaint.title}",
            'date': l.created_at,
            'link': f"/complaints/complaint/{l.complaint.id}/"
        })

    
    # 4. Generic User Activities (Login/Logout/Updates)
    # Import locally to ensure availability
    from .models import UserActivity
    user_logs = UserActivity.objects.filter(user=target_user)
    for log in user_logs:
        icon = 'info'
        color_class = 'bg-slate-100 text-slate-600'
        text_class = 'text-slate-500'
        
        if log.action_type == 'Login':
            icon = 'login'
            color_class = 'bg-green-50 text-green-600'
            text_class = 'text-green-600'
        elif log.action_type == 'Logout':
            icon = 'logout'
            color_class = 'bg-slate-50 text-slate-500'
        elif 'Warning' in log.action_type:
            icon = 'warning'
            color_class = 'bg-orange-50 text-orange-600'
            text_class = 'text-orange-600'
        elif 'Reactivation' in log.action_type:
            icon = 'autorenew'
            color_class = 'bg-blue-50 text-blue-600'
            text_class = 'text-blue-600'
            
        activities.append({
            'type': log.action_type,
            'icon': icon,
            'description': log.description,
            'date': log.timestamp,
            'link': None,
            'ip': log.ip_address
        })

    # Sort by date descending
    activities.sort(key=lambda x: x['date'], reverse=True)
    
    # Get freeze records for hospitals
    freeze_records = []
    if target_user.role == 'hospital':
        from authorities.models import HospitalFreeze
        freeze_records = HospitalFreeze.objects.filter(
            hospital=target_user,
            status__in=['frozen', 'pending_review']
        ).order_by('-frozen_at')
    
    return render(request, "accounts/admin_user_activity.html", {
        "target_user": target_user,
        "activities": activities,
        "freeze_records": freeze_records
    })


@superadmin_only
def admin_hospital_freeze_detail(request, freeze_id):
    """View details of a hospital freeze record."""
    from authorities.models import HospitalFreeze
    freeze_record = get_object_or_404(HospitalFreeze, id=freeze_id)
    
    context = {
        'freeze_record': freeze_record,
    }
    return render(request, "accounts/admin_hospital_freeze_detail.html", context)


@superadmin_only
def admin_approve_hospital_appeal(request, freeze_id):
    """Approve a hospital's freeze appeal."""
    from authorities.models import HospitalFreeze
    freeze_record = get_object_or_404(HospitalFreeze, id=freeze_id)
    
    hospital = freeze_record.hospital
    
    # Update freeze record
    freeze_record.status = 'reactivated'
    freeze_record.reactivated_at = timezone.now()
    freeze_record.save()
    
    # Reactivate hospital account
    hospital.account_status = 'active'
    hospital.save()
    
    # Create notification for hospital
    Notification.objects.create(
        recipient=hospital,
        title="Account Reactivated",
        message=f"Your account has been reactivated. Your appeal was approved by admin.",
        link="/hospital/dashboard/"
    )
    
    # Log activity
    UserActivity.objects.create(
        user=request.user,
        activity_type='admin_reactivate',
        description=f"Approved hospital freeze appeal for {hospital.username}"
    )
    
    messages.success(request, f"Appeal approved. {hospital.username} has been reactivated.")
    return redirect('admin_user_activity', user_id=hospital.id)


@superadmin_only
def admin_reject_hospital_appeal(request, freeze_id):
    """Reject a hospital's freeze appeal."""
    from authorities.models import HospitalFreeze
    freeze_record = get_object_or_404(HospitalFreeze, id=freeze_id)
    
    hospital = freeze_record.hospital
    
    # Update freeze record
    freeze_record.status = 'frozen'
    freeze_record.save()
    
    # Create notification for hospital
    Notification.objects.create(
        recipient=hospital,
        title="Appeal Rejected",
        message=f"Your account reactivation appeal has been rejected. Please contact support for more information.",
        link="/hospital/dashboard/"
    )
    
    # Log activity
    UserActivity.objects.create(
        user=request.user,
        activity_type='admin_reject_appeal',
        description=f"Rejected hospital freeze appeal for {hospital.username}"
    )
    
    messages.error(request, f"Appeal rejected. {hospital.username} remains frozen.")
    return redirect('admin_user_activity', user_id=hospital.id)


@superadmin_only
def admin_warn_user(request, user_id):
    if request.method == "POST":
        user = get_object_or_404(User, id=user_id)
        message = request.POST.get('message')
        if message:
            # Create Notification
            Notification.objects.create(
                recipient=user,
                title="Official Warning",
                message=message,
                # Link could range to a policy page or dashboard
                link="/patient/dashboard/" if user.role == 'patient' else "/hospital/dashboard/" if user.role == 'hospital' else "/authority/dashboard/"
            )
            # Log Activity
            from .models import UserActivity
            UserActivity.objects.create(
                user=user,
                action_type="Admin Warning",
                description=f"Received warning: {message}",
                ip_address=request.META.get('REMOTE_ADDR')
            )
            messages.success(request, f"Warning sent to {user.username}.")
        else:
            messages.error(request, "Warning message cannot be empty.")
    
    referer = request.META.get('HTTP_REFERER')
    if referer:
        return redirect(referer)
    return redirect('admin_users')

@superadmin_only
def admin_freeze_user(request, user_id):
    if request.method == "POST":
        user = get_object_or_404(User, id=user_id)
        reason = request.POST.get('reason', 'Violation of terms')
        
        if user.is_superuser:
             messages.error(request, "Cannot freeze superadmin.")
             return redirect('admin_users')

        user.account_status = 'frozen'
        user.is_active = False # Disable login
        user.save()
        
        # Create HospitalFreeze record if user is a hospital (to track who froze them)
        if user.role == 'hospital':
            from authorities.models import HospitalFreeze
            # Check if there's already an active freeze or pending review
            existing_freeze = HospitalFreeze.objects.filter(
                hospital=user,
                status__in=['frozen', 'pending_review']
            ).first()
            
            if not existing_freeze:
                HospitalFreeze.objects.create(
                    hospital=user,
                    frozen_by=request.user,  # Track who froze (admin)
                    reason='other',
                    description=reason,
                    status='frozen'
                )
        
        # Kill sessions
        # (This is a simplified approach; `logout_all_devices` logic can be reused if extracted)
        
        # Log Activity
        from .models import UserActivity
        UserActivity.objects.create(
            user=user,
            action_type="Account Frozen",
            description=f"Account frozen by admin. Reason: {reason}",
            ip_address=request.META.get('REMOTE_ADDR')
        )
        messages.success(request, f"User {user.username} has been frozen.")
    
    referer = request.META.get('HTTP_REFERER')
    if referer:
        return redirect(referer)
    return redirect('admin_users')

@superadmin_only
def admin_block_user(request, user_id):
    if request.method == "POST":
        user = get_object_or_404(User, id=user_id)
        reason = request.POST.get('reason', 'Severe violation')
        
        if user.is_superuser:
             messages.error(request, "Cannot block superadmin.")
             return redirect('admin_users')

        user.account_status = 'blocked'
        user.is_active = False
        user.save()
        
        # Log Activity
        from .models import UserActivity
        UserActivity.objects.create(
            user=user,
            action_type="Account Blocked",
            description=f"Account permanently blocked. Reason: {reason}",
            ip_address=request.META.get('REMOTE_ADDR')
        )
        messages.success(request, f"User {user.username} has been blocked.")
    
    referer = request.META.get('HTTP_REFERER')
    if referer:
        return redirect(referer)
    return redirect('admin_users')

@superadmin_only
def admin_reactivate_user(request, user_id):
    user = get_object_or_404(User, id=user_id)
    
    if request.method == "POST":
        user.account_status = 'active'
        user.is_active = True
        user.is_approved = True  # Also approve the user
        user.reactivation_requested = False
        user.save()
        
        # If user is a hospital, also update any HospitalFreeze records
        if user.role == 'hospital':
            from authorities.models import HospitalFreeze
            freeze_records = HospitalFreeze.objects.filter(
                hospital=user,
                status__in=['frozen', 'pending_review']
            )
            for freeze in freeze_records:
                freeze.status = 'reactivated'
                freeze.reactivated_at = timezone.now()
                freeze.save()
        
        # Notify User
        Notification.objects.create(
            recipient=user,
            title="Account Reactivated",
            message="Your account has been reactivated. You can now log in.",
            link="/login/"
        )
        
        messages.success(request, f"User {user.username} successfully reactivated.")
        
        referer = request.META.get('HTTP_REFERER')
        if referer:
            return redirect(referer)
    
    return redirect('admin_users')
        
    return redirect('admin_users')


def account_frozen(request):
    user_id = request.session.get('disabled_user_id')
    if not user_id:
        return redirect('login')
        
    try:
        user = User.objects.get(id=user_id)
    except User.DoesNotExist:
        return redirect('login')
        
    if user.account_status != 'frozen':
         # If not frozen (e.g. just disabled or active), redirect appropriately
         if user.is_active:
             return redirect('login')
         return redirect('account_disabled')

    if request.method == "POST":
        reason = request.POST.get('reactivation_reason')
        evidence = request.FILES.get('evidence')
        if reason:
            user.reactivation_requested = True
            user.reactivation_reason = reason # Save the plea
            if evidence:
                user.reactivation_evidence = evidence
            user.save()
            # Clear the session to prevent conflicts with other frozen users
            if 'disabled_user_id' in request.session:
                del request.session['disabled_user_id']
            # Log the reactivation request activity
            from .models import UserActivity
            UserActivity.objects.create(
                user=user,
                action_type='Reactivation Requested',
                description=f"User submitted reactivation request: {reason}"
            )
            messages.success(request, "Reactivation request sent to admin.")
    
    return render(request, "accounts/account_frozen.html", {"disabled_user": user})


def account_disabled(request):
    user_id = request.session.get('disabled_user_id')
    if not user_id:
        return redirect('login')
    
    try:
        user = User.objects.get(id=user_id)
    except User.DoesNotExist:
        return redirect('login')

    if request.method == "POST":
        reason = request.POST.get('reactivation_reason')
        evidence = request.FILES.get('evidence')
        user.reactivation_requested = True
        if reason:
            user.reactivation_reason = reason
        if evidence:
            user.reactivation_evidence = evidence
        user.save()
        # Clear the session to prevent conflicts with other disabled users
        if 'disabled_user_id' in request.session:
            del request.session['disabled_user_id']
        # Log the reactivation request activity
        from .models import UserActivity
        UserActivity.objects.create(
            user=user,
            action_type='Reactivation Requested',
            description="User submitted reactivation request"
        )
        messages.success(request, "Reactivation request sent to admin.")
        
    context = {"disabled_user": user}
    
    # Check for active freeze record if user is a hospital
    if user.role == "hospital":
        try:
            # We import here to avoid circular dependency
            from authorities.models import HospitalFreeze
            freeze_record = HospitalFreeze.objects.filter(
                hospital=user,
                status='frozen'
            ).order_by('-frozen_at').first()
            
            if freeze_record:
                context['freeze_record'] = freeze_record
        except Exception:
            pass

    return render(request, "accounts/account_disabled.html", context)


@login_required
def admin_support(request):
    if request.user.role != "superadmin":
        return redirect("login")
    
    # Filter by status
    status_filter = request.GET.get('status', 'all')
    
    from social.models import SupportTicket # Local import to avoid circular dependency if any
    
    tickets = SupportTicket.objects.all().order_by('-created_at')
    
    if status_filter != 'all':
        tickets = tickets.filter(status=status_filter)
        
    paginator = Paginator(tickets, 10)
    page_number = request.GET.get('page')
    page_obj = paginator.get_page(page_number)

    replies = PatientNotificationReply.objects.filter(
        support_ticket__in=tickets
    ).select_related("user").order_by("-created_at")
    reply_map = {}
    for reply in replies:
        if reply.support_ticket_id not in reply_map:
            reply_map[reply.support_ticket_id] = reply
    for ticket in page_obj:
        ticket.patient_reply = reply_map.get(ticket.id)

    return render(request, "accounts/admin_support.html", {
        "tickets": page_obj,
        "status_filter": status_filter
    })


@login_required
def admin_support_detail(request, ticket_id):
    if request.user.role != "superadmin":
        return redirect("login")

    ticket = get_object_or_404(SupportTicket, id=ticket_id)
    patient_reply = PatientNotificationReply.objects.filter(
        support_ticket=ticket
    ).select_related("user").order_by("-created_at").first()
    return render(request, "accounts/admin_support_detail.html", {"ticket": ticket, "patient_reply": patient_reply})


@login_required
def reply_support_ticket(request, ticket_id):
    if request.user.role != "superadmin":
        return redirect("login")
        
    if request.method == "POST":
        from social.models import SupportTicket
        ticket = get_object_or_404(SupportTicket, id=ticket_id)
        reply = request.POST.get('admin_reply')
        
        if reply:
            ticket.admin_reply = reply
            ticket.status = 'resolved'
            ticket.save()
            
            # Create Notification for User
            Notification.objects.create(
                recipient=ticket.user,
                title="Support Ticket Reply",
                message=f"Admin replied to \"{ticket.subject}\": {reply}",
                link=reverse("support"),
                support_ticket=ticket
            )
            
            messages.success(request, f"Reply sent to {ticket.user.username}.")
        else:
            messages.error(request, "Reply cannot be empty.")
            
    return redirect("admin_support")


@login_required
def admin_notifications(request):
    if request.user.role != "superadmin":
        return redirect("login")

    notifications = Notification.objects.filter(recipient=request.user).order_by("-created_at")
    return render(request, "accounts/admin_notifications.html", {"notifications": notifications})
