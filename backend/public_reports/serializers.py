from rest_framework import serializers
from .models import PublicReport


class PublicReportSerializer(serializers.ModelSerializer):
    id = serializers.IntegerField(read_only=True)
    missing_case_id = serializers.IntegerField(write_only=True)
    reviewer_name = serializers.CharField(
        source='reviewed_by_admin.username',
        read_only=True
    )

    class Meta:
        model = PublicReport
        fields = [
            'id',
            'missing_case_id',
            'reporter_name',
            'reporter_contact',
            'description',
            'image',
            'latitude',
            'longitude',
            'created_at',
            'status',
            'reviewed_by_admin',
            'reviewer_name',
            'review_notes',
            'reviewed_at',
        ]
        read_only_fields = [
            'id',
            'created_at',
            'reviewed_by_admin',
            'reviewed_at',
            'reviewer_name',
        ]

    def validate(self, data):
        if not data.get('description') or not data['description'].strip():
            raise serializers.ValidationError('Description is required and cannot be empty.')
        if not data.get('image'):
            raise serializers.ValidationError('Image is required.')
        if 'latitude' not in data or 'longitude' not in data:
            raise serializers.ValidationError('Location (latitude and longitude) is required.')
        return data

    def create(self, validated_data):
        case_id = self.context.get('case_id')
        validated_data['missing_case_id'] = case_id
        return super().create(validated_data)


class PublicReportReviewSerializer(serializers.Serializer):
    status = serializers.CharField()
    review_notes = serializers.CharField(required=False, allow_blank=True)
    closeCase = serializers.BooleanField(required=False, default=False)

    def validate_status(self, value):
        valid_statuses = [
            PublicReport.STATUS_PENDING,
            PublicReport.STATUS_REVIEWED,
            PublicReport.STATUS_ACCEPTED,
            PublicReport.STATUS_REJECTED,
        ]
        if value not in valid_statuses:
            raise serializers.ValidationError(f'Invalid status. Must be one of {valid_statuses}.')
        return value
