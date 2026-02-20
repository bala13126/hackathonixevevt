from django.core.mail import send_mail
from django.conf import settings


def notify_case_owner(report):
    """
    Send notification to case owner and admin when new report is submitted.
    """
    try:
        case = report.missing_case
        subject = f'New Sighting Report for {case.name}'
        message = f"""
A new sighting report has been submitted for the missing person case:

Person: {case.name}
Location: {report.latitude}, {report.longitude}
Description: {report.description}
Reporter: {report.reporter_name or 'Anonymous'}
Submitted: {report.created_at}

Report ID: {report.pk}
Status: {report.status}

Please review this report in the admin dashboard.
        """
        
        admin_emails = [
            admin[1]
            for admin in settings.ADMINS
            if admin[1]
        ]
        
        if admin_emails:
            send_mail(
                subject,
                message,
                settings.DEFAULT_FROM_EMAIL,
                admin_emails,
                fail_silently=True,
            )
    except Exception as e:
        print(f'Error sending notification: {e}')


def get_report_location_display(report):
    """
    Return human-readable location string.
    """
    return f'{report.latitude}, {report.longitude}'
