from django.core.management.base import BaseCommand
from django.contrib.auth.models import User
from api.models import Case, Tip, HonourProfile


class Command(BaseCommand):
    help = 'Seed sample data for development'

    def handle(self, *args, **options):
        cases = [
            {
                'name': 'Sarah Johnson',
                'age': 14,
                'location': 'Central Park, Manhattan',
                'description': 'Last seen wearing blue jeans and white t-shirt',
                'reliability': 72,
                'urgency': Case.URGENCY_HIGH,
                'status': Case.STATUS_PENDING,
            },
            {
                'name': 'Michael Chen',
                'age': 8,
                'location': 'Sunset Mall Food Court',
                'description': 'Wearing red jacket and khaki pants',
                'reliability': 88,
                'urgency': Case.URGENCY_HIGH,
                'status': Case.STATUS_ACTIVE,
            },
            {
                'name': 'Emma Williams',
                'age': 16,
                'location': 'Riverside High School',
                'description': 'School uniform with backpack',
                'reliability': 65,
                'urgency': Case.URGENCY_MEDIUM,
                'status': Case.STATUS_ACTIVE,
            },
        ]

        created_cases = []
        for payload in cases:
            case, _ = Case.objects.get_or_create(
                name=payload['name'],
                defaults=payload,
            )
            created_cases.append(case)

        if created_cases:
            Tip.objects.get_or_create(
                case=created_cases[0],
                content='Seen near the east entrance at around 5 PM.',
                defaults={'reporter': 'Anonymous', 'is_anonymous': True, 'verified': False},
            )

            Tip.objects.get_or_create(
                case=created_cases[1],
                content='May have boarded a bus heading downtown.',
                defaults={'reporter': 'Community Volunteer', 'verified': True},
            )

        users_payload = [
            ('admin_user', 'admin@example.com', 120, ['Bronze Rescuer']),
            ('coordinator', 'coord@example.com', 75, []),
        ]

        for username, email, score, medals in users_payload:
            user, _ = User.objects.get_or_create(username=username, defaults={'email': email})
            profile, _ = HonourProfile.objects.get_or_create(user=user)
            profile.score = score
            profile.medals = medals
            profile.save(update_fields=['score', 'medals'])

        self.stdout.write(self.style.SUCCESS('Seed data created/updated successfully.'))
