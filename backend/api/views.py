import json
import os
import re

import requests
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
    username = request.data.get('username') or request.data.get('email')
    password = request.data.get('password')

    if not username or not password:
        return Response(
            {'detail': 'username/email and password are required'},
            status=status.HTTP_400_BAD_REQUEST,
        )

    user = authenticate(request, username=username, password=password)

    if not user:
        try:
            user_by_email = User.objects.get(email=username)
            user = authenticate(request, username=user_by_email.username, password=password)
        except User.DoesNotExist:
            pass

    if not user and username.isdigit():
        try:
            phone_email = f'{username}@phone.local'
            user_by_phone = User.objects.get(email__iexact=phone_email)
            user = authenticate(request, username=user_by_phone.username, password=password)
        except User.DoesNotExist:
            pass

    if not user:
        return Response({'detail': 'Invalid credentials'}, status=status.HTTP_401_UNAUTHORIZED)

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
    username = (request.data.get('username') or '').strip()
    email = (request.data.get('email') or '').strip().lower()
    password = request.data.get('password')
    first_name = (request.data.get('firstName') or '').strip()
    last_name = (request.data.get('lastName') or '').strip()

    if not username or not email or not password:
        return Response(
            {'detail': 'username, email and password are required'},
            status=status.HTTP_400_BAD_REQUEST,
        )

    if User.objects.filter(username__iexact=username).exists():
        return Response({'detail': 'Username already exists'}, status=status.HTTP_400_BAD_REQUEST)

    if User.objects.filter(email__iexact=email).exists():
        return Response({'detail': 'Email already exists'}, status=status.HTTP_400_BAD_REQUEST)

    try:
        user = User.objects.create_user(
            username=username,
            email=email,
            password=password,
            first_name=first_name,
            last_name=last_name,
        )
        HonourProfile.objects.create(user=user, score=0, medals=[])
    except IntegrityError:
        return Response(
            {'detail': 'Unable to create account with provided details'},
            status=status.HTTP_400_BAD_REQUEST,
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


def _get_gemini_key():
    return os.getenv('GEMINI_API_KEY', '')


def _ensure_gemini_key():
    if not _get_gemini_key():
        raise RuntimeError('Gemini API key not configured')


def _simple_parse_voice(text):
    payload = {
        'name': '',
        'age': '',
        'gender': '',
        'height': '',
        'hairColor': '',
        'eyeColor': '',
        'clothing': '',
        'lastSeenLocation': '',
        'lastSeenTime': '',
        'description': '',
        'contactName': '',
        'contactPhone': '',
    }

    # ===== NAME EXTRACTION =====
    name = _extract_match(r'(?:name is|her name|his name|called|named)\s+([a-zA-Z\s]+?)(?:\s+(?:is|age|and|gender|height|old)|$)', text)
    if not name:
        name = _extract_match(r'\bmy daughter is ([a-zA-Z\s]+)', text)
    if not name:
        name = _extract_match(r'\bmy son is ([a-zA-Z\s]+)', text)
    if not name:
        # Try to find capitalized words as names
        name = _extract_match(r'\b([A-Z][a-z]+)\s+(?:is|was|has)', text)
    payload['name'] = name.strip()

    # ===== AGE EXTRACTION =====
    age = _extract_match(r'(?:age is|aged|she is|he is)\s+(\d{1,3})\s*(?:years?|yrs?)?', text)
    if not age:
        age = _extract_match(r'(\d{1,3})\s*years?\s*(?:old|age)', text)
    if not age:
        # Look for standalone numbers that could be ages
        numbers = re.findall(r'\b(\d{1,3})\b', text)
        if numbers:
            for num in numbers:
                if 5 <= int(num) <= 100:
                    age = num
                    break
    payload['age'] = age.strip()

    # ===== GENDER EXTRACTION =====
    if re.search(r'\b(?:female|girl|woman|she|her)\b', text, re.IGNORECASE):
        payload['gender'] = 'Female'
    elif re.search(r'\b(?:male|boy|man|he|him)\b', text, re.IGNORECASE):
        payload['gender'] = 'Male'

    # ===== HEIGHT EXTRACTION =====
    height = _extract_match(r'(?:height is|tall|height)\s+(\d{2,3})', text)
    if not height:
        height = _extract_match(r'(\d+)\s*(?:cm|centimeters?|feet|ft)', text)
    payload['height'] = height.strip()

    # ===== HAIR COLOR EXTRACTION =====
    hair_colors = ['black', 'brown', 'blonde', 'red', 'white', 'gray', 'grey', 'golden', 'auburn', 'brunette']
    hair = _extract_match(r'(?:hair color|hair colour|hair is)\s+([a-zA-Z]+)', text)
    if not hair:
        for color in hair_colors:
            if re.search(rf'\b{color}\b.*\bhair\b', text, re.IGNORECASE) or \
               re.search(rf'\bhair\b.*\b{color}\b', text, re.IGNORECASE):
                hair = color
                break
    payload['hairColor'] = hair.strip()

    # ===== EYE COLOR EXTRACTION =====
    eye_colors = ['black', 'brown', 'blue', 'green', 'hazel', 'grey', 'gray', 'amber']
    eye = _extract_match(r'(?:eye color|eye colour|eyes are)\s+([a-zA-Z]+)', text)
    if not eye:
        for color in eye_colors:
            if re.search(rf'\b{color}\b.*\beye', text, re.IGNORECASE) or \
               re.search(rf'\beye.*\b{color}\b', text, re.IGNORECASE):
                eye = color
                break
    payload['eyeColor'] = eye.strip()

    # ===== CLOTHING EXTRACTION =====
    clothing = _extract_match(r'(?:wearing|dressed|outfit|clothes|had on|has on)\s+([^\.]+?)(?:\s+(?:when|where|at|near)|$)', text)
    if not clothing:
        clothing = _extract_match(r'(?:shirt|pants|jeans|dress|skirt|jacket|coat|hat|shoes)\s+([a-zA-Z\s]+)', text)
    if not clothing:
        # Extract color-clothing patterns like "black shirt", "blue jeans"
        clothing = _extract_match(r'([a-zA-Z]+\s+(?:shirt|pants|jeans|dress|skirt|jacket|coat|hat|shoes|top|bottom))', text)
    payload['clothing'] = clothing.strip()

    # ===== LOCATION EXTRACTION =====
    location = _extract_match(r'(?:last seen|seen|found|at|near|located at|location is)\s+([^\.]+?)(?:\s+(?:at|on|when|time)|$)', text)
    if not location:
        location = _extract_match(r'(?:place|area|spot|location)\s+([^\.]+)', text)
    payload['lastSeenLocation'] = location.strip()

    # ===== TIME EXTRACTION =====
    time_value = _extract_match(r'(?:at|around|time is|last seen at)\s+(\d{1,2}:\d{2}(?:\s*(?:am|pm))?|\d{1,2}\s*(?:am|pm))', text)
    if not time_value:
        time_value = _extract_match(r'(?:today|yesterday|morning|afternoon|evening|night)\s+at\s+(\d{1,2}:\d{2}|\d{1,2}\s*(?:am|pm))', text)
    payload['lastSeenTime'] = time_value.strip()

    # ===== CONTACT NAME EXTRACTION =====
    contact_name = _extract_match(r'(?:contact name|caller|reporter|my name|this is)\s+(?:is\s+)?([a-zA-Z\s]+?)(?:\s+(?:phone|number|is)|$)', text)
    if not contact_name:
        contact_name = _extract_match(r'(?:you can reach|call|contact)\s+([a-zA-Z\s]+)', text)
    payload['contactName'] = contact_name.strip()

    # ===== CONTACT PHONE EXTRACTION =====
    contact_phone = _extract_match(r'(?:phone|contact|call|number|reach|dial)\s+(?:is|number\s+is)?\s*([\d\-\+\s()]{7,})', text)
    if not contact_phone:
        contact_phone = _extract_match(r'(?:my phone|phone number)\s+(?:is\s+)?([\d\-\+\s()]{7,})', text)
    if not contact_phone:
        # Look for plain number sequences that look like phone numbers
        numbers = re.findall(r'([\d\-\+\s()]{10,})', text)
        if numbers:
            contact_phone = numbers[0]
    payload['contactPhone'] = _normalize_phone(contact_phone)

    return payload


def _simple_chat_reply(text):
    return (
        'I can help with missing person reporting and tips. '
        'If you are reporting a case, please share the name, age, last seen '
        'location/time, clothing, and a contact phone number. '
        'You can also open the report screen and use Auto Fill after sharing details.'
    )


def _gemini_generate(prompt):
    api_key = _get_gemini_key()
    if not api_key:
        raise RuntimeError('Gemini API key not configured')

    endpoint = (
        'https://generativelanguage.googleapis.com/v1beta/models/'
        'gemini-1.5-flash:generateContent'
    )
    payload = {
        'contents': [
            {
                'role': 'user',
                'parts': [{'text': prompt}],
            }
        ]
    }
    response = requests.post(
        f'{endpoint}?key={api_key}',
        json=payload,
        timeout=20,
    )
    response.raise_for_status()
    data = response.json()
    candidates = data.get('candidates') or []
    if not candidates:
        return ''
    content = candidates[0].get('content') or {}
    parts = content.get('parts') or []
    if not parts:
        return ''
    return parts[0].get('text', '')


def _extract_json(text):
    try:
        return json.loads(text)
    except json.JSONDecodeError:
        match = re.search(r'\{.*\}', text, re.DOTALL)
        if not match:
            return {}
        try:
            return json.loads(match.group(0))
        except json.JSONDecodeError:
            return {}


def _extract_match(pattern, text, group=1):
    match = re.search(pattern, text, re.IGNORECASE)
    if not match:
        return ''
    return match.group(group).strip()


def _normalize_phone(value):
    digits = re.sub(r'\D', '', value)
    return digits


@api_view(['POST'])
def parse_voice_report(request):
    text = (request.data.get('text') or '').strip()
    if not text:
        return Response({'detail': 'Text is required'}, status=status.HTTP_400_BAD_REQUEST)

    prompt = (
        'You are extracting structured fields for a missing person report. '
        'Return ONLY a JSON object with these keys: '\
        'name, age, gender, height, hairColor, eyeColor, clothing, '
        'lastSeenLocation, lastSeenTime, description, contactName, contactPhone. '\
        'Use empty string for unknown fields. '\
        f'Text: {text}'
    )

    try:
        _ensure_gemini_key()
        ai_text = _gemini_generate(prompt)
        payload = _extract_json(ai_text)
    except RuntimeError:
        payload = _simple_parse_voice(text)
    except Exception as exc:
        return Response({'detail': str(exc)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

    if not payload.get('description'):
        payload['description'] = text
    return Response(payload, status=status.HTTP_200_OK)


@api_view(['POST'])
def ai_chat(request):
    text = (request.data.get('text') or '').strip()
    if not text:
        return Response({'detail': 'Text is required'}, status=status.HTTP_400_BAD_REQUEST)

    prompt = (
        'You are ResQLink AI Assistant. Provide helpful, concise guidance for '
        'missing person reporting, tips, and safety. Offer clear next steps and '
        'ask for any missing details. User message: '\
        f'{text}'
    )

    try:
        _ensure_gemini_key()
        reply = _gemini_generate(prompt)
    except RuntimeError:
        reply = _simple_chat_reply(text)
    except Exception as exc:
        return Response({'detail': str(exc)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

    return Response({'reply': reply}, status=status.HTTP_200_OK)
