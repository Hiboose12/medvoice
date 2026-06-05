from django.contrib import admin
from .models import User,VerificationProfile


@admin.register(User)
class UserAdmin(admin.ModelAdmin):
    list_display = ("username", "role", "is_approved")
    list_filter = ("role", "is_approved")
    search_fields = ("username","email")
    list_editable = ("is_approved",) 
    
@admin.register(VerificationProfile)
class VerificationProfileAdmin(admin.ModelAdmin):
    list_display = ("user", "created_at")


