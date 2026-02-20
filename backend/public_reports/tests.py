from django.test import TestCase
from api.models import Case
from .models import PublicReport


class PublicReportModelTest(TestCase):
    def setUp(self):
        self.case = Case.objects.create(
            name='Test Case',
            age=25,
            location='Test Location',
            description='Test Description',
        )

    def test_create_public_report(self):
        report = PublicReport.objects.create(
            missing_case=self.case,
            reporter_name='Test Reporter',
            description='Test Sighting',
            latitude=40.7128,
            longitude=-74.0060,
        )
        self.assertEqual(report.status, PublicReport.STATUS_PENDING)
        self.assertEqual(report.missing_case, self.case)
