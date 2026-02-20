from django.urls import path
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
]
