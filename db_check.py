import os
import sys

# Add the Django backend path to sys.path
sys.path.insert(0, r"d:\flutter tut\New folder")

# Setup Django environment
os.environ.setdefault("DJANGO_SETTINGS_MODULE", "project.settings")
import django
django.setup()

from django.contrib.auth import get_user_model

User = get_user_model()

print("User Accounts:")
for user in User.objects.all():
    print(f"ID: {user.id}")
    print(f"Email: {user.email}")
    print(f"Is Active: {user.is_active}")
    print(f"Is Staff: {user.is_staff}")
    print(f"Is Superuser: {user.is_superuser}")
    print(f"Is Email Verified: {user.is_email_verified}")
    print("-" * 30)
