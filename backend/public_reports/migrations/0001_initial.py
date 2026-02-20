from django.db import migrations, models
import django.db.models.deletion


class Migration(migrations.Migration):

    initial = True

    dependencies = [
        ('api', '0002_case_photo_tip_attachment'),
        ('auth', '0012_alter_user_first_name_max_length'),
    ]

    operations = [
        migrations.CreateModel(
            name='PublicReport',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('reporter_name', models.CharField(blank=True, max_length=255, null=True)),
                ('reporter_contact', models.CharField(blank=True, max_length=255, null=True)),
                ('description', models.TextField()),
                ('image', models.ImageField(upload_to='public_reports/')),
                ('latitude', models.FloatField()),
                ('longitude', models.FloatField()),
                ('created_at', models.DateTimeField(auto_now_add=True)),
                ('status', models.CharField(choices=[('Pending', 'Pending'), ('Reviewed', 'Reviewed'), ('Accepted', 'Accepted'), ('Rejected', 'Rejected')], default='Pending', max_length=16)),
                ('review_notes', models.TextField(blank=True, null=True)),
                ('reviewed_at', models.DateTimeField(blank=True, null=True)),
                ('missing_case', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='public_reports', to='api.case')),
                ('reviewed_by_admin', models.ForeignKey(blank=True, null=True, on_delete=django.db.models.deletion.SET_NULL, related_name='reviewed_reports', to='auth.user')),
            ],
            options={
                'ordering': ['-created_at'],
            },
        ),
    ]
