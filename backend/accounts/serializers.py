from rest_framework import serializers
from rest_framework_simplejwt.tokens import RefreshToken
from django.contrib.auth import authenticate
from .models import CustomUser, Role, Permission, StaffProfile


class PermissionSerializer(serializers.ModelSerializer):
    class Meta:
        model = Permission
        fields = ['id', 'codename', 'name', 'description']


class RoleSerializer(serializers.ModelSerializer):
    permissions = PermissionSerializer(many=True, read_only=True)
    permission_ids = serializers.PrimaryKeyRelatedField(
        many=True,
        queryset=Permission.objects.all(),
        write_only=True,
        required=False,
    )
    staff_count = serializers.SerializerMethodField()

    class Meta:
        model = Role
        fields = [
            'id', 'name', 'description',
            'permissions', 'permission_ids',
            'staff_count', 'created_at',
        ]

    def get_staff_count(self, obj):
        return obj.staff_members.count()

    def create(self, validated_data):
        perm_objs = validated_data.pop('permission_ids', [])
        role = Role.objects.create(**validated_data)
        role.permissions.set(perm_objs)
        return role

    def update(self, instance, validated_data):
        perm_objs = validated_data.pop('permission_ids', None)
        for attr, value in validated_data.items():
            setattr(instance, attr, value)
        instance.save()
        if perm_objs is not None:
            instance.permissions.set(perm_objs)
        return instance


class StaffProfileSerializer(serializers.ModelSerializer):
    department_name = serializers.CharField(source='department.name', read_only=True)
    role_name = serializers.CharField(source='role.name', read_only=True)

    class Meta:
        model = StaffProfile
        fields = ['id', 'department', 'department_name', 'role', 'role_name',
                  'employee_id', 'designation', 'joined_date', 'is_active']


class UserSerializer(serializers.ModelSerializer):
    staff_profile = StaffProfileSerializer(read_only=True)
    complaint_count = serializers.SerializerMethodField()

    class Meta:
        model = CustomUser
        fields = [
            'id', 'email', 'username', 'full_name', 'phone', 'role',
            'preferred_language', 'location_text', 'profile_pic',
            'is_google_user', 'receive_notifications', 'dark_mode',
            'staff_profile', 'complaint_count', 'is_active', 'created_at'
        ]
        read_only_fields = ['id', 'created_at', 'is_google_user']

    def get_complaint_count(self, obj):
        if hasattr(obj, 'complaints'):
            return obj.complaints.count()
        return 0


class RegisterSerializer(serializers.ModelSerializer):
    password = serializers.CharField(write_only=True, min_length=6)
    confirm_password = serializers.CharField(write_only=True)

    class Meta:
        model = CustomUser
        fields = ['email', 'username', 'full_name', 'phone', 'password', 'confirm_password', 'preferred_language']

    def validate(self, data):
        if data['password'] != data.pop('confirm_password'):
            raise serializers.ValidationError({'confirm_password': 'Passwords do not match.'})
        return data

    def create(self, validated_data):
        user = CustomUser.objects.create_user(
            email=validated_data['email'],
            username=validated_data.get('username', validated_data['email'].split('@')[0]),
            full_name=validated_data.get('full_name', ''),
            phone=validated_data.get('phone', ''),
            preferred_language=validated_data.get('preferred_language', 'en'),
            password=validated_data['password'],
            role=CustomUser.ROLE_CITIZEN,
        )
        return user


class LoginSerializer(serializers.Serializer):
    identifier = serializers.CharField(help_text='Email, mobile number, or username')
    password = serializers.CharField(write_only=True)
    firebase_token = serializers.CharField(required=False, allow_blank=True)

    def _find_user(self, identifier):
        """Return CustomUser matching email, phone, or username — case-insensitive."""
        # Try email
        if '@' in identifier:
            user = CustomUser.objects.filter(email__iexact=identifier).first()
            if user:
                return user
        # Try phone (strip spaces/dashes for comparison)
        cleaned = identifier.replace(' ', '').replace('-', '')
        user = CustomUser.objects.filter(phone=cleaned).first()
        if user:
            return user
        # Try username
        user = CustomUser.objects.filter(username__iexact=identifier).first()
        return user

    def validate(self, data):
        identifier = data['identifier'].strip()
        db_user = self._find_user(identifier)
        if not db_user:
            raise serializers.ValidationError(
                'No account found with that email, phone number, or username.')
        user = authenticate(username=db_user.email, password=data['password'])
        if not user:
            raise serializers.ValidationError('Incorrect password. Please try again.')
        if not user.is_active:
            raise serializers.ValidationError('This account has been disabled.')
        data['user'] = user
        return data


class GoogleAuthSerializer(serializers.Serializer):
    id_token = serializers.CharField()
    firebase_token = serializers.CharField(required=False, allow_blank=True)


class TokenResponseSerializer(serializers.Serializer):
    """Serializer for returning tokens + user info"""
    access = serializers.CharField()
    refresh = serializers.CharField()
    user = UserSerializer()


class UpdateProfileSerializer(serializers.ModelSerializer):
    # profile_pic is handled separately in ProfileView (uploaded to Cloudinary)
    class Meta:
        model = CustomUser
        fields = ['full_name', 'phone', 'location_text', 'preferred_language',
                  'receive_notifications', 'dark_mode']


class ChangePasswordSerializer(serializers.Serializer):
    old_password = serializers.CharField(write_only=True)
    new_password = serializers.CharField(write_only=True, min_length=6)

    def validate_old_password(self, value):
        user = self.context['request'].user
        if not user.check_password(value):
            raise serializers.ValidationError('Old password is incorrect.')
        return value


class CreateStaffSerializer(serializers.Serializer):
    email = serializers.EmailField()
    full_name = serializers.CharField()
    phone = serializers.CharField(required=False, allow_blank=True)
    password = serializers.CharField(min_length=6)
    department_id = serializers.IntegerField(required=False, allow_null=True)
    role_id = serializers.IntegerField(required=False, allow_null=True)
    employee_id = serializers.CharField(required=False, allow_blank=True)
    designation = serializers.CharField(required=False, allow_blank=True)

    def validate_email(self, value):
        if CustomUser.objects.filter(email=value).exists():
            raise serializers.ValidationError('Email already registered.')
        return value

    def create(self, validated_data):
        from complaints.models import Department
        department = None
        role = None
        if validated_data.get('department_id'):
            department = Department.objects.filter(id=validated_data['department_id']).first()
        if validated_data.get('role_id'):
            role = Role.objects.filter(id=validated_data['role_id']).first()

        user = CustomUser.objects.create_user(
            email=validated_data['email'],
            username=validated_data['email'].split('@')[0],
            full_name=validated_data['full_name'],
            phone=validated_data.get('phone', ''),
            password=validated_data['password'],
            role=CustomUser.ROLE_STAFF,
        )
        StaffProfile.objects.create(
            user=user,
            department=department,
            role=role,
            employee_id=validated_data.get('employee_id', ''),
            designation=validated_data.get('designation', ''),
        )
        return user
