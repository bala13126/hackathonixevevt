from django.contrib.auth.models import User
from rest_framework import serializers
from .models import Case, Tip, HonourProfile


class CaseSerializer(serializers.ModelSerializer):
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
            'created_at',
            'updated_at',
        ]


class TipSerializer(serializers.ModelSerializer):
    caseId = serializers.IntegerField(source='case_id', read_only=True)

    class Meta:
        model = Tip
        fields = [
            'id',
            'caseId',
            'reporter',
            'content',
            'is_anonymous',
            'share_location',
            'verified',
            'attachment',
            'created_at',
        ]


class TipCreateSerializer(serializers.Serializer):
    caseId = serializers.IntegerField()
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
