from django.contrib.auth.models import User
from rest_framework import serializers
from .models import Case, Tip, HonourProfile, Reward, RewardRedemption, UserCoupon


class CaseSerializer(serializers.ModelSerializer):
    userId = serializers.IntegerField(source='user_id', read_only=True)
    userName = serializers.SerializerMethodField()

    class Meta:
        model = Case
        fields = [
            'id',
            'name',
            'age',
            'location',
            'description',
            'reliability',
            'urgency',
            'status',
            'photo',
            'userId',
            'userName',
            'created_at',
            'updated_at',
        ]

    def get_userName(self, obj):
        if not obj.user:
            return ''
        return obj.user.get_full_name() or obj.user.username


class TipSerializer(serializers.ModelSerializer):
    caseId = serializers.IntegerField(source='case_id', read_only=True)
    userId = serializers.IntegerField(source='user_id', read_only=True)
    userName = serializers.SerializerMethodField()

    class Meta:
        model = Tip
        fields = [
            'id',
            'caseId',
            'userId',
            'userName',
            'reporter',
            'content',
            'is_anonymous',
            'share_location',
            'verified',
            'attachment',
            'created_at',
        ]

    def get_userName(self, obj):
        if not obj.user:
            return ''
        return obj.user.get_full_name() or obj.user.username


class TipCreateSerializer(serializers.Serializer):
    caseId = serializers.IntegerField()
    userId = serializers.IntegerField(required=False)
    reporter = serializers.CharField(max_length=120, required=False, allow_blank=True)
    content = serializers.CharField()
    isAnonymous = serializers.BooleanField(required=False, default=False)
    shareLocation = serializers.BooleanField(required=False, default=False)
    attachment = serializers.ImageField(required=False, allow_null=True)

    def validate_caseId(self, value):
        if not Case.objects.filter(id=value).exists():
            raise serializers.ValidationError('Case does not exist.')
        return value


class UserHonourSerializer(serializers.Serializer):
    id = serializers.IntegerField()
    name = serializers.CharField()
    score = serializers.IntegerField()
    medals = serializers.ListField(child=serializers.CharField())


class CaseStatusUpdateSerializer(serializers.Serializer):
    status = serializers.ChoiceField(choices=[choice[0] for choice in Case.STATUS_CHOICES])


class RewardSerializer(serializers.ModelSerializer):
    class Meta:
        model = Reward
        fields = [
            'id',
            'name',
            'description',
            'points_required',
            'image',
            'is_active',
            'created_at',
        ]


class RewardRedemptionSerializer(serializers.ModelSerializer):
    rewardName = serializers.CharField(source='reward.name', read_only=True)
    userName = serializers.SerializerMethodField()
    userId = serializers.IntegerField(source='user_id', read_only=True)

    class Meta:
        model = RewardRedemption
        fields = [
            'id',
            'reward',
            'rewardName',
            'userId',
            'userName',
            'status',
            'requested_at',
            'reviewed_at',
            'reviewed_by',
            'review_notes',
        ]

    def get_userName(self, obj):
        if not obj.user:
            return ''
        return obj.user.get_full_name() or obj.user.username


class UserCouponSerializer(serializers.ModelSerializer):
    rewardName = serializers.CharField(source='reward.name', read_only=True)
    rewardDescription = serializers.CharField(source='reward.description', read_only=True)
    userId = serializers.IntegerField(source='user_id', read_only=True)

    class Meta:
        model = UserCoupon
        fields = [
            'id',
            'reward',
            'rewardName',
            'rewardDescription',
            'userId',
            'status',
            'issued_at',
            'used_at',
            'expiry_date',
        ]
