from django.contrib import admin
from .models import Case, Tip, HonourProfile


@admin.register(Case)
class CaseAdmin(admin.ModelAdmin):
    list_display = ('id', 'name', 'location', 'urgency', 'status', 'reliability', 'created_at')
    list_filter = ('urgency', 'status')
    search_fields = ('name', 'location', 'description')


@admin.register(Tip)
class TipAdmin(admin.ModelAdmin):
    list_display = ('id', 'case', 'reporter', 'verified', 'created_at')
    list_filter = ('verified', 'is_anonymous', 'share_location')
    search_fields = ('reporter', 'content')


@admin.register(HonourProfile)
class HonourProfileAdmin(admin.ModelAdmin):
    list_display = ('id', 'user', 'score')
    search_fields = ('user__username', 'user__email')
