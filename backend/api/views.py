from django.contrib.auth.models import User
from django.contrib.auth import authenticate
from django.db import IntegrityError
from django.db import transaction
from rest_framework import status
from rest_framework.decorators import api_view
from rest_framework.response import Response
from .models import Case, Tip, HonourProfile
from .serializers import (
	CaseSerializer,
	CaseStatusUpdateSerializer,
	TipCreateSerializer,
	TipSerializer,
)


@api_view(['GET'])
def health(request):
	return Response({'status': 'ok'})


@api_view(['GET', 'POST'])
def list_cases(request):
	if request.method == 'GET':
		queryset = Case.objects.all()
		serializer = CaseSerializer(queryset, many=True)
		return Response(serializer.data)
	
	# POST - Create new case
	serializer = CaseSerializer(data=request.data)
	if serializer.is_valid():
		case = serializer.save()
		return Response(CaseSerializer(case).data, status=status.HTTP_201_CREATED)
	return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


@api_view(['PUT'])
def update_case_status(request, case_id):
	try:
		case = Case.objects.get(id=case_id)
	except Case.DoesNotExist:
		return Response({'detail': 'Case not found.'}, status=status.HTTP_404_NOT_FOUND)

	serializer = CaseStatusUpdateSerializer(data=request.data)
	serializer.is_valid(raise_exception=True)
	case.status = serializer.validated_data['status']
	case.save(update_fields=['status', 'updated_at'])
	return Response(CaseSerializer(case).data)


@api_view(['GET', 'POST'])
def tips_collection(request):
	if request.method == 'GET':
		tips = Tip.objects.select_related('case').all()
		serializer = TipSerializer(tips, many=True)
		return Response(serializer.data)

	serializer = TipCreateSerializer(data=request.data, files=request.FILES)
	serializer.is_valid(raise_exception=True)

	payload = serializer.validated_data
	tip = Tip.objects.create(
		case_id=payload['caseId'],
		reporter=payload.get('reporter') or 'Anonymous',
		content=payload['content'],
		is_anonymous=payload.get('isAnonymous', False),
		share_location=payload.get('shareLocation', False),
		attachment=payload.get('attachment'),
	)
	return Response(TipSerializer(tip).data, status=status.HTTP_201_CREATED)


@api_view(['PUT'])
def verify_tip(request, tip_id):
	try:
		tip = Tip.objects.select_related('case').get(id=tip_id)
	except Tip.DoesNotExist:
		return Response({'detail': 'Tip not found.'}, status=status.HTTP_404_NOT_FOUND)

	if tip.verified:
		return Response(TipSerializer(tip).data)

	with transaction.atomic():
		tip.verified = True
		tip.save(update_fields=['verified'])

		admin_user, _ = User.objects.get_or_create(
			username='community_hero',
			defaults={'email': 'hero@example.com'},
		)
		profile, _ = HonourProfile.objects.get_or_create(user=admin_user)
		profile.score = profile.score + 10
		medals = profile.medals or []
		if profile.score >= 100 and 'Bronze Rescuer' not in medals:
			medals.append('Bronze Rescuer')
		profile.medals = medals
		profile.save(update_fields=['score', 'medals'])

	return Response(TipSerializer(tip).data)


@api_view(['GET'])
def list_users(request):
	users = User.objects.all().select_related('honour_profile')
	response_payload = []

	for user in users:
		profile = getattr(user, 'honour_profile', None)
		response_payload.append(
			{
				'id': user.id,
				'name': user.get_full_name() or user.username,
				'score': profile.score if profile else 0,
				'medals': profile.medals if profile else [],
			}
		)

	return Response(response_payload)


@api_view(['POST'])
def login(request):
	"""
	Login endpoint: expects username/email and password
	Returns: user id, username, email, and auth token
	"""
	username = request.data.get('username') or request.data.get('email')
	password = request.data.get('password')

	if not username or not password:
		return Response(
			{'detail': 'username/email and password are required'},
			status=status.HTTP_400_BAD_REQUEST
		)

	# Try authenticate by username first
	user = authenticate(request, username=username, password=password)
	
	# If not found, try by email
	if not user:
		try:
			user_by_email = User.objects.get(email=username)
			user = authenticate(request, username=user_by_email.username, password=password)
		except User.DoesNotExist:
			pass

	# If still not found, try phone-style login (<phone>@phone.local)
	if not user and username.isdigit():
		try:
			phone_email = f'{username}@phone.local'
			user_by_phone = User.objects.get(email__iexact=phone_email)
			user = authenticate(request, username=user_by_phone.username, password=password)
		except User.DoesNotExist:
			pass

	if not user:
		return Response(
			{'detail': 'Invalid credentials'},
			status=status.HTTP_401_UNAUTHORIZED
		)

	profile = getattr(user, 'honour_profile', None)
	response_data = {
		'id': user.id,
		'username': user.username,
		'email': user.email,
		'firstName': user.first_name,
		'lastName': user.last_name,
		'score': profile.score if profile else 0,
		'medals': profile.medals if profile else [],
	}

	return Response(response_data, status=status.HTTP_200_OK)


@api_view(['POST'])
def register(request):
	"""
	Register endpoint: create new user
	Expects: username, email, password, firstName (optional), lastName (optional)
	"""
	username = (request.data.get('username') or '').strip()
	email = (request.data.get('email') or '').strip().lower()
	password = request.data.get('password')
	first_name = (request.data.get('firstName') or '').strip()
	last_name = (request.data.get('lastName') or '').strip()

	if not username or not email or not password:
		return Response(
			{'detail': 'username, email and password are required'},
			status=status.HTTP_400_BAD_REQUEST
		)

	if User.objects.filter(username__iexact=username).exists():
		return Response(
			{'detail': 'Username already exists'},
			status=status.HTTP_400_BAD_REQUEST
		)

	if User.objects.filter(email__iexact=email).exists():
		return Response(
			{'detail': 'Email already exists'},
			status=status.HTTP_400_BAD_REQUEST
		)

	try:
		user = User.objects.create_user(
			username=username,
			email=email,
			password=password,
			first_name=first_name,
			last_name=last_name,
		)

		# Create honour profile for new user
		HonourProfile.objects.create(user=user, score=0, medals=[])
	except IntegrityError:
		return Response(
			{'detail': 'Unable to create account with provided details'},
			status=status.HTTP_400_BAD_REQUEST
		)

	response_data = {
		'id': user.id,
		'username': user.username,
		'email': user.email,
		'firstName': user.first_name,
		'lastName': user.last_name,
		'score': 0,
		'medals': [],
	}

	return Response(response_data, status=status.HTTP_201_CREATED)
