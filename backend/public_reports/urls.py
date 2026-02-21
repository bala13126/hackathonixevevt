from django.urls import path
from .views import PublicReportViewSet

urlpatterns = [
    path(
        'cases/<int:case_id>/report-sighting/',
        PublicReportViewSet.as_view({'post': 'create'}),
        name='create-sighting'
    ),
    path(
        'cases/<int:case_id>/reports/',
        PublicReportViewSet.as_view({'get': 'list'}),
        name='list-reports'
    ),
    path(
        'reports/<int:pk>/review/',
        PublicReportViewSet.as_view({'patch': 'review_report'}),
        name='review-report'
    ),
]
