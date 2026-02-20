from rest_framework import status, viewsets
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.permissions import AllowAny
from django.shortcuts import get_object_or_404
from django.utils import timezone
from api.models import Case
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
        
        report = PublicReport.objects.create(
            missing_case=case,
            reporter_name=serializer.validated_data.get('reporter_name'),
            reporter_contact=serializer.validated_data.get('reporter_contact'),
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
        case = self.get_case()
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

        report.status = serializer.validated_data.get('status')
        report.review_notes = serializer.validated_data.get('review_notes')
        report.reviewed_by_admin = request.user if request.user.is_authenticated else None
        report.reviewed_at = timezone.now()
        report.save(update_fields=['status', 'review_notes', 'reviewed_by_admin', 'reviewed_at'])

        close_case = serializer.validated_data.get('closeCase', False)
        if report.status == PublicReport.STATUS_ACCEPTED and close_case:
            case = report.missing_case
            case.status = Case.STATUS_SOLVED
            case.save(update_fields=['status', 'updated_at'])

        return Response(
            PublicReportSerializer(report).data,
            status=status.HTTP_200_OK
        )
