from rest_framework import serializers
from accounts.models import User, Hospital, Authority, Notification
from complaints.models import Complaint, HospitalResponse, Comment, Like
from authorities.models import HospitalWarning, HospitalFreeze, ComplaintActivityLog, AuthoritySettings

class UserSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = ['id', 'username', 'first_name', 'last_name', 'email', 'role', 'is_approved', 'account_status', 'last_login']
        read_only_fields = ['id', 'username', 'role']

    def to_representation(self, instance):
        ret = super().to_representation(instance)
        request = self.context.get('request')
        
        # Mask user profile fields if patient has anonymous posting enabled
        if instance.role == 'patient' and instance.is_anonymous_public:
            # Mask unless the viewer is a superadmin or the user themselves
            if not request or not request.user or (request.user.role != 'superadmin' and request.user.id != instance.id):
                ret['username'] = 'anonymous'
                ret['first_name'] = 'Anonymous'
                ret['last_name'] = 'User'
                ret['email'] = ''
        return ret

class PatientRegistrationSerializer(serializers.ModelSerializer):
    password = serializers.CharField(write_only=True, required=True, style={'input_type': 'password'})
    
    class Meta:
        model = User
        fields = ['email', 'password', 'first_name', 'last_name']
        
    def create(self, validated_data):
        # Username is required in Django AbstractUser, so we use email prefix or email itself
        username = validated_data.get('email').split('@')[0]
        # Ensure uniqueness if needed, but for now just use email
        user = User.objects.create_user(
            username=validated_data.get('email'),
            email=validated_data.get('email'),
            password=validated_data.get('password'),
            first_name=validated_data.get('first_name', ''),
            last_name=validated_data.get('last_name', ''),
            role='patient'
        )
        return user

class HospitalRegistrationSerializer(serializers.ModelSerializer):
    password = serializers.CharField(write_only=True, required=True, style={'input_type': 'password'})
    hospital_name = serializers.CharField(required=True, write_only=True)
    hospital_type = serializers.CharField(required=True, write_only=True)
    registration_number = serializers.CharField(required=True, write_only=True)
    license_number = serializers.CharField(required=True, write_only=True)
    hospital_address = serializers.CharField(required=True, write_only=True)
    hospital_district = serializers.CharField(required=True, write_only=True)
    hospital_state = serializers.CharField(required=True, write_only=True)
    hospital_pincode = serializers.CharField(required=True, write_only=True)
    hospital_contact = serializers.CharField(required=True, write_only=True)
    
    class Meta:
        model = User
        fields = [
            'email', 'password', 'first_name', 'last_name',
            'hospital_name', 'hospital_type', 'registration_number',
            'license_number', 'hospital_address', 'hospital_district',
            'hospital_state', 'hospital_pincode', 'hospital_contact'
        ]
        
    def create(self, validated_data):
        email = validated_data.get('email')
        user = User.objects.create_user(
            username=email,
            email=email,
            password=validated_data.get('password'),
            first_name=validated_data.get('first_name', ''),
            last_name=validated_data.get('last_name', ''),
            role='hospital',
            account_status='pending_verification'
        )
        Hospital.objects.create(
            user=user,
            hospital_name=validated_data.get('hospital_name'),
            hospital_type=validated_data.get('hospital_type'),
            registration_number=validated_data.get('registration_number'),
            license_number=validated_data.get('license_number'),
            address=validated_data.get('hospital_address'),
            district=validated_data.get('hospital_district'),
            state=validated_data.get('hospital_state'),
            pincode=validated_data.get('hospital_pincode'),
            contact_number=validated_data.get('hospital_contact'),
            email=email,
            status='pending'
        )
        return user

class AuthorityRegistrationSerializer(serializers.ModelSerializer):
    password = serializers.CharField(write_only=True, required=True, style={'input_type': 'password'})
    authority_name = serializers.CharField(required=True, write_only=True)
    authority_type = serializers.CharField(required=True, write_only=True)
    authentication_key = serializers.CharField(required=True, write_only=True)
    
    class Meta:
        model = User
        fields = [
            'email', 'password', 'first_name', 'last_name',
            'authority_name', 'authority_type', 'authentication_key'
        ]
        
    def create(self, validated_data):
        email = validated_data.get('email')
        user = User.objects.create_user(
            username=email,
            email=email,
            password=validated_data.get('password'),
            first_name=validated_data.get('first_name', ''),
            last_name=validated_data.get('last_name', ''),
            role='authority',
            account_status='pending_verification'
        )
        Authority.objects.create(
            user=user,
            authority_name=validated_data.get('authority_name'),
            authority_type=validated_data.get('authority_type'),
            designation='Authority Admin',
            contact_number='',
            authentication_key=validated_data.get('authentication_key')
        )
        return user


class HospitalSerializer(serializers.ModelSerializer):
    class Meta:
        model = Hospital
        fields = [
            'id', 'hospital_name', 'hospital_type', 'registration_number', 
            'license_number', 'address', 'district', 'state', 'pincode', 
            'contact_number', 'email', 'status'
        ]
        read_only_fields = ['id', 'status', 'registration_number', 'license_number']

class HospitalResponseSerializer(serializers.ModelSerializer):
    hospital_name = serializers.SerializerMethodField()
    
    class Meta:
        model = HospitalResponse
        fields = ['id', 'hospital_name', 'message', 'created_at', 'is_private']
        read_only_fields = ['id', 'hospital_name', 'created_at']

    def get_hospital_name(self, obj):
        if hasattr(obj.hospital, 'hospital_profile'):
            return obj.hospital.hospital_profile.hospital_name
        return obj.hospital.get_full_name() or obj.hospital.username

class CommentSerializer(serializers.ModelSerializer):
    user_name = serializers.SerializerMethodField()

    class Meta:
        model = Comment
        fields = ['id', 'user_name', 'content', 'created_at']
        read_only_fields = ['id', 'user_name', 'created_at']

    def get_user_name(self, obj):
        request = self.context.get('request')
        if obj.user.role == 'patient' and obj.user.is_anonymous_public:
            if not request or not request.user or request.user.role != 'superadmin':
                return "Anonymous User"
        return obj.user.first_name or obj.user.username

class ComplaintSerializer(serializers.ModelSerializer):
    user = UserSerializer(read_only=True)
    hospital_responses = serializers.SerializerMethodField()
    comments = CommentSerializer(many=True, read_only=True)
    is_liked = serializers.SerializerMethodField()
    likes_count = serializers.IntegerField(source='likes', read_only=True)
    is_owner = serializers.SerializerMethodField()
    
    class Meta:
        model = Complaint
        fields = [
            'id', 'user', 'title', 'description', 'hospital', 
            'hospital_name', 'unregistered_hospital_name', 
            'category', 'severity', 'status', 'evidence', 
            'created_at', 'patient_resolution_status', 'hospital_responses',
            'comments', 'likes_count', 'is_liked', 'is_owner'
        ]
        read_only_fields = ['id', 'user', 'status', 'created_at', 'patient_resolution_status', 'comments', 'likes_count']

    def validate(self, attrs):
        hospital = attrs.get('hospital', getattr(self.instance, 'hospital', None))
        unregistered_hospital_name = attrs.get('unregistered_hospital_name', getattr(self.instance, 'unregistered_hospital_name', None))
        if not hospital and not unregistered_hospital_name:
            raise serializers.ValidationError("Either a registered hospital or an unregistered hospital name must be provided.")
        return attrs

    def get_is_owner(self, obj):
        request = self.context.get('request')
        if request and request.user.is_authenticated:
            return obj.user == request.user
        return False

    def get_hospital_responses(self, obj):
        request = self.context.get('request')
        qs = obj.hospital_responses.all().order_by('created_at')
        if not request or not request.user or request.user.role != 'superadmin':
            user = request.user if request and request.user.is_authenticated else None
            if not user or (obj.user != user and obj.hospital != user):
                qs = qs.filter(is_private=False)
        return HospitalResponseSerializer(qs, many=True, context=self.context).data

    def get_is_liked(self, obj):
        request = self.context.get('request')
        if request and request.user.is_authenticated:
            # Using prefetch_related is recommended but simple exists query works
            return Like.objects.filter(user=request.user, complaint=obj).exists()
        return False

class NotificationSerializer(serializers.ModelSerializer):
    class Meta:
        model = Notification
        fields = '__all__'

class AuthoritySerializer(serializers.ModelSerializer):
    username = serializers.CharField(source='user.username', read_only=True)
    email = serializers.CharField(source='user.email', read_only=True)
    is_approved = serializers.BooleanField(source='user.is_approved', read_only=True)

    class Meta:
        model = Authority
        fields = ['id', 'user', 'username', 'email', 'authority_name', 'authority_type', 'department_name',
                  'jurisdiction_level', 'jurisdiction_state', 'jurisdiction_district', 'office_address',
                  'official_email', 'official_phone', 'is_approved']
        read_only_fields = ['user', 'is_approved']

class AuthoritySettingsSerializer(serializers.ModelSerializer):
    class Meta:
        model = AuthoritySettings
        fields = ['id', 'authority', 'response_time_threshold', 'view_time_threshold', 'warning_threshold',
                  'email_notifications', 'escalation_alerts', 'warning_alerts', 'freeze_alerts']
        read_only_fields = ['authority']

class HospitalWarningSerializer(serializers.ModelSerializer):
    class Meta:
        model = HospitalWarning
        fields = '__all__'

class HospitalFreezeSerializer(serializers.ModelSerializer):
    class Meta:
        model = HospitalFreeze
        fields = '__all__'

class ComplaintActivityLogSerializer(serializers.ModelSerializer):
    performed_by_name = serializers.SerializerMethodField()

    class Meta:
        model = ComplaintActivityLog
        fields = ['id', 'activity_type', 'performed_by', 'performed_by_name', 'description', 'created_at']

    def get_performed_by_name(self, obj):
        if obj.performed_by:
            return obj.performed_by.username
        return 'System'
