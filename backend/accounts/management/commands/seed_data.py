"""
Management command to seed initial data:
  - Default permissions
  - Default departments
  - Default admin/super_admin user
"""
from django.core.management.base import BaseCommand
from django.contrib.auth import get_user_model
from accounts.models import Permission, Role, StaffProfile
from complaints.models import Department

User = get_user_model()

DEFAULT_PERMISSIONS = [
    ('view_complaints',       'View all complaints'),
    ('manage_complaints',     'Assign & update complaint status'),
    ('escalate_complaints',   'Escalate complaints'),
    ('manage_users',          'Create, edit and deactivate users'),
    ('manage_staff',          'Create and manage staff members'),
    ('manage_departments',    'Create and manage departments'),
    ('manage_roles',          'Create and manage roles & permissions'),
    ('view_analytics',        'View analytics and reports'),
    ('send_notifications',    'Send push notifications to users'),
    ('export_reports',        'Export data reports'),
]

DEFAULT_DEPARTMENTS = [
    ('Public Works',    'Roads, bridges, and civil infrastructure'),
    ('Water Supply',    'Water supply and pipeline management'),
    ('Sanitation',      'Garbage collection and drainage management'),
    ('Electrical',      'Street lights and electrical infrastructure'),
    ('Transport',       'Public transport and traffic management'),
]

ADMIN_EMAIL    = 'admin@smartgrievance.in'
ADMIN_PASSWORD = 'Admin@1234'
ADMIN_NAME     = 'System Administrator'

# Simple admin login: username=admin / password=admin123
SIMPLE_ADMIN_USERNAME = 'admin'
SIMPLE_ADMIN_EMAIL    = 'admin@civic.local'
SIMPLE_ADMIN_PASSWORD = 'admin123'
SIMPLE_ADMIN_NAME     = 'Admin'


class Command(BaseCommand):
    help = 'Seed initial platform data (permissions, departments, admin user)'

    def add_arguments(self, parser):
        parser.add_argument('--force', action='store_true',
                            help='Re-seed even if data already exists')

    def handle(self, *args, **options):
        force = options['force']

        self._seed_permissions(force)
        self._seed_departments(force)
        self._seed_admin_role(force)
        self._seed_admin_user(force)
        self._seed_simple_admin(force)

        self.stdout.write(self.style.SUCCESS('✅  Seed completed successfully.'))

    # ── permissions ──────────────────────────────────────────────────────────

    def _seed_permissions(self, force):
        created = 0
        for codename, name in DEFAULT_PERMISSIONS:
            obj, was_created = Permission.objects.get_or_create(
                codename=codename,
                defaults={'name': name},
            )
            if force and not was_created:
                obj.name = name
                obj.save()
            if was_created:
                created += 1
        self.stdout.write(f'  Permissions: {created} created, '
                          f'{len(DEFAULT_PERMISSIONS) - created} already existed.')

    # ── departments ───────────────────────────────────────────────────────────

    def _seed_departments(self, force):
        created = 0
        for name, description in DEFAULT_DEPARTMENTS:
            obj, was_created = Department.objects.get_or_create(
                name=name,
                defaults={'description': description, 'is_active': True},
            )
            if force and not was_created:
                obj.description = description
                obj.save()
            if was_created:
                created += 1
        self.stdout.write(f'  Departments: {created} created, '
                          f'{len(DEFAULT_DEPARTMENTS) - created} already existed.')

    # ── admin role ────────────────────────────────────────────────────────────

    def _seed_admin_role(self, force):
        role, created = Role.objects.get_or_create(
            name='Super Admin',
            defaults={'description': 'Full platform access'},
        )
        all_perms = Permission.objects.all()
        role.permissions.set(all_perms)
        role.save()
        status = 'created' if created else 'updated'
        self.stdout.write(f'  Admin Role: {status} with {all_perms.count()} permissions.')

    # ── admin user ────────────────────────────────────────────────────────────

    def _seed_admin_user(self, force):
        if User.objects.filter(email=ADMIN_EMAIL).exists():
            if not force:
                self.stdout.write(f'  Admin user already exists ({ADMIN_EMAIL}). '
                                  'Use --force to reset password.')
                return
            user = User.objects.get(email=ADMIN_EMAIL)
            user.set_password(ADMIN_PASSWORD)
            user.save()
            self.stdout.write(f'  Admin user password reset: {ADMIN_EMAIL}')
            return

        user = User.objects.create_superuser(
            email=ADMIN_EMAIL,
            username='admin',
            password=ADMIN_PASSWORD,
            full_name=ADMIN_NAME,
            role='super_admin',
        )

        # Attach a StaffProfile so admin shows up correctly in staff lists
        admin_role = Role.objects.filter(name='Super Admin').first()
        dept = Department.objects.first()
        StaffProfile.objects.create(
            user=user,
            department=dept,
            role=admin_role,
            designation='System Administrator',
            employee_id='ADM001',
        )

        self.stdout.write(
            self.style.SUCCESS(
                f'  Admin user created: {ADMIN_EMAIL}  password: {ADMIN_PASSWORD}'
            )
        )

    # ── simple admin (username=admin / password=admin123) ─────────────────────

    def _seed_simple_admin(self, force):
        existing = User.objects.filter(username=SIMPLE_ADMIN_USERNAME).first()
        if existing:
            if force:
                existing.set_password(SIMPLE_ADMIN_PASSWORD)
                existing.save()
                self.stdout.write(f'  Simple admin password reset: username={SIMPLE_ADMIN_USERNAME}')
            else:
                self.stdout.write(
                    f'  Simple admin already exists (username={SIMPLE_ADMIN_USERNAME}). '
                    'Use --force to reset password.')
            return

        user = User.objects.create_superuser(
            email=SIMPLE_ADMIN_EMAIL,
            username=SIMPLE_ADMIN_USERNAME,
            password=SIMPLE_ADMIN_PASSWORD,
            full_name=SIMPLE_ADMIN_NAME,
            role='super_admin',
        )
        admin_role = Role.objects.filter(name='Super Admin').first()
        dept = Department.objects.first()
        StaffProfile.objects.create(
            user=user,
            department=dept,
            role=admin_role,
            designation='Administrator',
            employee_id='ADM002',
        )
        self.stdout.write(
            self.style.SUCCESS(
                f'  Simple admin created: username={SIMPLE_ADMIN_USERNAME}  '
                f'password={SIMPLE_ADMIN_PASSWORD}'
            )
        )
