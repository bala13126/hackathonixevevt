from django.urls import path, include
from . import views

urlpatterns = [
    path('health', views.health, name='health'),
    path('cases', views.list_cases, name='cases-list'),
    path('cases/<int:case_id>/status', views.update_case_status, name='case-status-update'),
    path('tips', views.tips_collection, name='tips-collection'),
    path('tips/<int:tip_id>/verify', views.verify_tip, name='tip-verify'),
    path('users', views.list_users, name='users-list'),
    path('auth/login', views.login, name='login'),
    path('auth/register', views.register, name='register'),
    path('ai/chat', views.ai_chat, name='ai-chat'),
    path('voice/parse', views.parse_voice_report, name='voice-parse'),
    path('voice/text-to-speech', views.text_to_speech, name='text-to-speech'),
    path('voice/speech-recognition', views.speech_recognition, name='speech-recognition'),
    path('', include('public_reports.urls')),
]
