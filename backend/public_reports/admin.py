from django.contrib import admin
from django.utils.html import format_html
from .models import PublicReport


class PublicReportAdmin(admin.ModelAdmin):
    list_display = [
        'id',
        'missing_case',
        'reporter_name',
        'status_badge',
        'created_at',
        'reviewed_by_admin',
    ]
    list_filter = ['status', 'created_at', 'missing_case']
    search_fields = ['reporter_name', 'description', 'missing_case__name']
    readonly_fields = [
        'id',
        'created_at',
        'reviewed_at',
        'image_preview',
        'location_display',
    ]
    fieldsets = (
        ('Case Information', {
            'fields': ('missing_case',)
        }),
        ('Report Details', {
            'fields': (
                'reporter_name',
                'reporter_contact',
                'description',
                'image',
                'image_preview',
                'latitude',
                'longitude',
                'location_display',
            )
        }),
        ('Timestamps', {
            'fields': ('created_at', 'reviewed_at'),
            'classes': ('collapse',)
        }),
        ('Review Status', {
            'fields': (
                'status',
                'reviewed_by_admin',
                'review_notes',
            )
        }),
    )

    def status_badge(self, obj):
        colors = {
            'Pending': '#FFA500',
            'Reviewed': '#87CEEB',
            'Accepted': '#90EE90',
            'Rejected': '#FF6B6B',
        }
        color = colors.get(obj.status, '#808080')
        return format_html(
            '<span style="background-color: {}; color: white; padding: 3px 8px; border-radius: 3px;">{}</span>',
            color,
            obj.status
        )
    status_badge.short_description = 'Status'

    def image_preview(self, obj):
        if obj.image:
            return format_html(
                '<img src="{}" width="200" height="auto" />',
                obj.image.url
            )
        return 'No image'
    image_preview.short_description = 'Image Preview'

    def location_display(self, obj):
        return format_html(
            '{}, {} <br/><a href="https://maps.google.com/?q={},{}" target="_blank">View on Map</a>',
            obj.latitude,
            obj.longitude,
            obj.latitude,
            obj.longitude,
        )
    location_display.short_description = 'Location'


admin.site.register(PublicReport, PublicReportAdmin)
