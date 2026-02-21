from django.contrib import admin
from .models import Case, Tip, HonourProfile, Reward, RewardRedemption, UserCoupon


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


@admin.register(Reward)
class RewardAdmin(admin.ModelAdmin):
    list_display = ('id', 'name', 'points_required', 'is_active', 'created_at')
    list_filter = ('is_active',)
    search_fields = ('name', 'description')


@admin.register(RewardRedemption)
class RewardRedemptionAdmin(admin.ModelAdmin):
    list_display = ('id', 'reward', 'user', 'status', 'requested_at', 'reviewed_at')
    list_filter = ('status',)
    search_fields = ('reward__name', 'user__username', 'user__email')


@admin.register(UserCoupon)
class UserCouponAdmin(admin.ModelAdmin):
    list_display = ('id', 'reward', 'user', 'status', 'issued_at', 'used_at')
    list_filter = ('status',)
    search_fields = ('reward__name', 'user__username', 'user__email')
