from django.db import models
from django.contrib.auth.models import User
from api.models import Case


class PublicReport(models.Model):
    STATUS_PENDING = 'Pending'
    STATUS_REVIEWED = 'Reviewed'
    STATUS_ACCEPTED = 'Accepted'
    STATUS_REJECTED = 'Rejected'

    STATUS_CHOICES = [
        (STATUS_PENDING, 'Pending'),
        (STATUS_REVIEWED, 'Reviewed'),
        (STATUS_ACCEPTED, 'Accepted'),
        (STATUS_REJECTED, 'Rejected'),
    ]

    missing_case = models.ForeignKey(
        Case,
        on_delete=models.CASCADE,
        related_name='public_reports'
    )
    reporter_name = models.CharField(max_length=255, blank=True, null=True)
    reporter_contact = models.CharField(max_length=255, blank=True, null=True)
    description = models.TextField()
    image = models.ImageField(upload_to='public_reports/')
    latitude = models.FloatField()
    longitude = models.FloatField()
    created_at = models.DateTimeField(auto_now_add=True)
    status = models.CharField(
        max_length=16,
        choices=STATUS_CHOICES,
        default=STATUS_PENDING
    )
    reviewed_by_admin = models.ForeignKey(
        User,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='reviewed_reports'
    )
    review_notes = models.TextField(blank=True, null=True)
    reviewed_at = models.DateTimeField(null=True, blank=True)

    class Meta:
        ordering = ['-created_at']

    def __str__(self):
        return f'Report #{self.pk} for case #{self.missing_case_id}'
