from django.contrib.auth.models import User
from rest_framework import status, viewsets
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated, AllowAny
from django.shortcuts import get_object_or_404
from django.db import transaction
from api.models import Case, HonourProfile
from .models import PublicReport
from .serializers import PublicReportSerializer, PublicReportReviewSerializer
from .services import notify_case_owner


class PublicReportViewSet(viewsets.ModelViewSet):
    queryset = PublicReport.objects.all()
    serializer_class = PublicReportSerializer
    permission_classes = [AllowAny]

    def get_case(self):
        case_id = self.kwargs.get('case_id')
        return get_object_or_404(Case, id=case_id)

    def get_queryset(self):
        case_id = self.kwargs.get('case_id')
        if case_id:
            return PublicReport.objects.filter(missing_case_id=case_id)
        return PublicReport.objects.all()

    def create(self, request, *args, **kwargs):
        case = self.get_case()
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        reporter_user_id = serializer.validated_data.get('reporter_user_id')
        reporter_user = None
        if reporter_user_id:
            reporter_user = User.objects.filter(id=reporter_user_id).first()
        
        report = PublicReport.objects.create(
            missing_case=case,
            reporter_name=serializer.validated_data.get('reporter_name'),
            reporter_contact=serializer.validated_data.get('reporter_contact'),
            reporter_user=reporter_user,
            description=serializer.validated_data.get('description'),
            image=serializer.validated_data.get('image'),
            latitude=serializer.validated_data.get('latitude'),
            longitude=serializer.validated_data.get('longitude'),
        )
        
        notify_case_owner(report)
        
        return Response(
            PublicReportSerializer(report).data,
            status=status.HTTP_201_CREATED
        )

    def list(self, request, *args, **kwargs):
        queryset = self.get_queryset()
        serializer = self.get_serializer(queryset, many=True)
        return Response(serializer.data)

    @action(
        detail=True,
        methods=['patch'],
        permission_classes=[AllowAny],
        url_path='review'
    )
    def review_report(self, request, *args, **kwargs):
        report = self.get_object()
        serializer = PublicReportReviewSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        new_status = serializer.validated_data.get('status')

        with transaction.atomic():
            report.status = new_status
            report.review_notes = serializer.validated_data.get('review_notes')
            report.reviewed_by_admin = request.user if request.user.is_authenticated else None
            if new_status == PublicReport.STATUS_ACCEPTED and report.reporter_user:
                if report.points_awarded == 0:
                    profile, _ = HonourProfile.objects.get_or_create(user=report.reporter_user)
                    profile.score = profile.score + 15
                    profile.save(update_fields=['score'])
                    report.points_awarded = 15
            report.save()

        return Response(
            PublicReportSerializer(report).data,
            status=status.HTTP_200_OK
        )
