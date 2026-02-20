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

    # Handle file upload by passing both data and FILES
    serializer = CaseSerializer(data=request.data, files=request.FILES)
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


def _get_openai_key():
    return os.getenv('OPENAI_API_KEY', '')


def _ensure_openai_key():
    if not _get_openai_key():
        raise RuntimeError('OpenAI API key not configured')


def _get_openai_model():
    return os.getenv('OPENAI_MODEL', 'gpt-4o-mini')


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


def _openai_chat(messages, temperature=0.2, response_format=None):
    """Mock implementation of OpenAI chat for testing (no API costs)."""
    
    # Extract system prompt and user message
    system_prompt = ''
    user_message = ''
    for msg in messages:
        if msg.get('role') == 'system':
            system_prompt = msg.get('content', '').lower()
        elif msg.get('role') == 'user':
            user_message = msg.get('content', '')
    
    # Determine if this is a parse request (expects JSON) or chat request
    is_parse_request = response_format and response_format.get('type') == 'json_object'
    
    if is_parse_request:
        # Use actual parsing logic from _simple_parse_voice() for realistic data extraction
        parsed = _simple_parse_voice(user_message)
        return json.dumps(parsed)
    else:
        # Enhanced chatbot with comprehensive Q&A
        user_lower = user_message.lower()
        
        # Comprehensive Q&A knowledge base for chatbot
        qa_kb = {
            # Reporting questions
            'how to report': 'To report a missing person: 1) Click "Report Missing" 2) Fill in their name, age, and description 3) Add location and time last seen 4) Upload a photo if available 5) Provide your contact info 6) Click Submit. The case will be tracked immediately.',
            'how do i report': 'To report a missing person: 1) Click "Report Missing" 2) Fill in their name, age, and description 3) Add location and time last seen 4) Upload a photo if available 5) Provide your contact info 6) Click Submit. The case will be tracked immediately.',
            'what information': 'You\'ll need: Name, Age, Gender, Height, Hair color, Eye color, Clothing description, Last seen location, Last seen time, Physical description, Your name, Your phone number, and a recent photo if possible.',
            'what do i need': 'You\'ll need: Name, Age, Gender, Height, Hair color, Eye color, Clothing description, Last seen location, Last seen time, Physical description, Your name, Your phone number, and a recent photo if possible.',
            'where do i report': 'Use the "Report Missing" section in the app. Fill out the form with details about the missing person, upload a photo, and submit. We\'ll immediately coordinate with authorities and help spread the word.',
            
            # Safety questions
            'is it safe': 'Your safety comes first. When searching, always go in groups, stay in contact, and inform authorities of your location. Never search alone in dangerous areas.',
            'what if danger': 'If you suspect immediate danger: 1) Call emergency services (911 or local equivalent) 2) Share all details with authorities 3) Post on community platforms 4) Coordinate with local police 5) Do NOT approach if dangerous.',
            'how to search safely': 'Search safety tips: 1) Always search in groups 2) Inform authorities of your plan 3) Carry communication devices 4) Share your location 5) Check hospitals and shelters 6) Post on social media responsibly',
            
            # Photo questions
            'what photo': 'Provide a recent photo (last few weeks if possible) that: Shows the person\'s face clearly, Is well-lit, Shows their typical appearance and style, Includes full body if possible, Is in natural setting without heavy filters.',
            'photo requirements': 'Best photos are: Recent (last few weeks), Clear facial features, Well-lit and in focus, Shows natural appearance, Multiple angles if available, Full body preferred.',
            'can i upload multiple': 'Currently you can upload one primary photo. For additional photos, contact authorities directly with the case number.',
            
            # Age/description questions
            'age range': 'Provide the exact age if known. If unknown, give a range (e.g., "looks like early 20s" or "teenager").',
            'how describe appearance': 'Describe: Height (exact or range), Build (thin/average/heavy), Hair (color, length, style), Eyes (color), Skin tone, Distinctive marks (scars, tattoos, birthmarks), Medical devices (glasses, crutches), Usual style.',
            
            # Location questions
            'what location': 'Provide the last confirmed location where they were seen. Include: street address if known, nearby landmarks, district/area, usual places they frequent.',
            'where last seen': 'Last location should include: Exact address if known, Nearest landmark, Area/district name, Whether it was work/home/public place, What they might have been doing.',
            
            # Time questions
            'what time': 'Provide the exact time or approximate time they were last seen. Include: Date and time, Who saw them last, Circumstances when they left, Whether behavior was unusual.',
            'when last seen': 'Include the exact date and time, or best estimate. Also mention: Who confirmed this sighting, What they were doing, Whether they mentioned where they were going.',
            
            # Urgency questions
            'why urgent': 'Missing person cases need immediate action because: Time is critical in first 24-48 hours, Details fade with time, Early reports help prevent harm, Community spread helps locate quickly.',
            'is this urgent': 'Yes, missing person cases are always urgent. Report immediately to: Local police, ResQLink app, Social media and community groups. Every hour counts.',
            
            # Contact/follow-up questions
            'how get update': 'You\'ll receive updates via: SMS alerts if provided, App notifications, Email updates, Direct contact from authorities.',
            'can i track case': 'Yes! You can track your case status in the app under "My Reports". You\'ll see: Current status, Tips received, Authority notes, Contact updates.',
            'how contact authority': 'After submitting a report, authorities will contact you using the phone number you provided. Keep your phone available.',
            
            # Medical/special needs
            'what if medical': 'Include medical information: Medications they need, Medical conditions, Allergies, Mental health concerns, Mobility limitations.',
            'what if special needs': 'For people with special needs: Mention autism, dementia, intellectual disability, mobility issues, Communication difficulties, Behavioral patterns.',
            
            # Preventive questions
            'how prevent missing': 'Prevention tips: Keep updated contact info, Know their routine, Encourage communication, Mark safe places, Have recent photos ready, Share location apps with trusted people.',
            'what to do now': 'To be prepared: 1) Have recent photos saved 2) Know their friends and hangouts 3) Share important details with family 4) Set up communication check-ins 5) Keep contact info updated.',
            
            # General help
            'help': 'I\'m ResQLink AI Assistant. I can help with: Reporting missing persons, Reporting tips, Safety guidance, Photo requirements, Location/time information, Tracking cases, Prevention tips. What do you need?',
            'what can you do': 'I can assist with: How to report missing persons, What information to provide, Photo requirements, Safety during search, Case tracking, Tips gathering, Community coordination.',
            'options': 'You can: Report a missing person, Submit tips about cases, View active cases, Track your reports, Get safety guidance, Translate content, Chat with me. What interests you?',
        }
        
        # Check for exact or partial keyword matches
        for key, answer in qa_kb.items():
            if key in user_lower:
                return answer
        
        # Fallback to category-based responses for general keywords
        responses = {
            'report': 'To report a missing person:\n1. Provide name, age, and physical description\n2. Share last known location and time\n3. Describe clothing\n4. Provide contact information\n5. Submit with photos\n\nEvery detail helps locate the person quickly.',
            'tips': 'Reporting tips:\n- Be as detailed as possible\n- Include recent photos\n- Note any medical conditions or medications\n- Mention if they have money or transportation\n- Report to local police immediately',
            'safety': 'Safety guidelines:\n- Always inform authorities of dangerous individuals\n- Search in groups, never alone\n- Carry communication devices\n- Share your location with others\n- Report any sightings immediately',
            'photo': 'Photos should be:\n- Recent and clear\n- Show the person\'s face clearly\n- Well-lit\n- In normal clothing they typically wear\n- Include full body if possible',
            'description': 'A good description includes:\n- Height and build\n- Hair color and style\n- Eye color\n- Distinctive marks (scars, tattoos)\n- Usual clothing preferences\n- Any medical conditions',
            'location': 'When sharing location information:\n- Be specific (address, landmarks, districts)\n- Include all places they frequent\n- Note their usual patterns\n- Mention places they like visiting\n- Share any planned destinations',
            'contact': 'Contact information is crucial. Please provide:\n- Your name\n- Phone number\n- Email if available\n- Relationship to missing person',
            'timeline': 'Timeline is important. Include:\n- When last seen (exact time if known)\n- Last known location\n- Who saw them last\n- Any activities before disappearance\n- Any changes in behavior',
        }
        
        # Find best matching category
        for keyword, response in responses.items():
            if keyword in user_lower:
                return response
        
        # Check for question patterns
        if any(word in user_lower for word in ['what', 'how', 'why', 'when', 'where', 'who']):
            if 'include' in user_lower or 'need' in user_lower or 'require' in user_lower:
                return 'For a complete missing person report, include: name, age, physical description, last known location/time, clothing, distinctive features, contact information, and a recent photo.'
            elif 'do' in user_lower or 'steps' in user_lower or 'process' in user_lower:
                return 'Steps to report:\n1. Go to the report section\n2. Fill in personal details\n3. Add physical description\n4. Share location information\n5. Provide contact details\n6. Upload photos if available\n7. Submit and track progress'
        
        # Default helpful response
        return 'I\'m ResQLink AI Assistant. Ask me about reporting missing persons, tips, safety, photo requirements, or how to track cases. What would you like to know?'


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

    system_prompt = (
        'Extract structured fields for a missing person report. '
        'Input may be in any language; understand it and map values correctly. '
        'Return ONLY valid JSON with these exact keys: '
        'name, age, gender, height, hairColor, eyeColor, clothing, '
        'lastSeenLocation, lastSeenTime, description, contactName, contactPhone. '
        'Use empty string for unknown fields.'
    )

    try:
        _ensure_openai_key()
        ai_text = _openai_chat(
            [
                {'role': 'system', 'content': system_prompt},
                {'role': 'user', 'content': text},
            ],
            temperature=0,
            response_format={'type': 'json_object'},
        )
        payload = _extract_json(ai_text)
    except RuntimeError:
        payload = _simple_parse_voice(text)
    except Exception:
        payload = _simple_parse_voice(text)

    if not payload.get('description'):
        payload['description'] = text
    return Response(payload, status=status.HTTP_200_OK)


@api_view(['POST'])
def ai_chat(request):
    text = (request.data.get('text') or '').strip()
    if not text:
        return Response({'detail': 'Text is required'}, status=status.HTTP_400_BAD_REQUEST)

    system_prompt = (
        'You are ResQLink AI Assistant. Provide helpful, concise guidance for '
        'missing person reporting, tips, and safety. Offer clear next steps and '
        'ask for any missing details. '
        'Always reply in the same language as the user message unless they request a different language. '
        'If asked to translate, provide a direct translation first and then short helpful guidance.'
    )

    try:
        _ensure_openai_key()
        reply = _openai_chat(
            [
                {'role': 'system', 'content': system_prompt},
                {'role': 'user', 'content': text},
            ],
            temperature=0.4,
        )
    except RuntimeError:
        reply = _simple_chat_reply(text)
    except Exception:
        reply = _simple_chat_reply(text)

    return Response({'reply': reply}, status=status.HTTP_200_OK)


@api_view(['POST'])
def text_to_speech(request):
    """Convert text to speech (voice output for accessibility)."""
    text = (request.data.get('text') or '').strip()
    if not text:
        return Response({'detail': 'Text is required'}, status=status.HTTP_400_BAD_REQUEST)
    
    # Limit text to 500 characters for performance
    if len(text) > 500:
        text = text[:500]
    
    try:
        import pyttsx3
        import base64
        import io
        
        # Initialize text-to-speech engine
        engine = pyttsx3.init()
        engine.setProperty('rate', 150)  # Speed of speech
        engine.setProperty('volume', 0.9)  # Volume level
        
        # Save audio to file
        audio_file = '/tmp/resqlink_audio.mp3'
        engine.save_to_file(text, audio_file)
        engine.runAndWait()
        
        # Read and encode audio
        if os.path.exists(audio_file):
            with open(audio_file, 'rb') as f:
                audio_bytes = f.read()
                audio_b64 = base64.b64encode(audio_bytes).decode('utf-8')
            
            os.remove(audio_file)
            return Response({
                'audio': f'data:audio/mpeg;base64,{audio_b64}',
                'text': text,
                'status': 'success'
            }, status=status.HTTP_200_OK)
    except Exception as e:
        pass  # Fall through to text-based response
    
    # Fallback: Return text as-is if TTS fails
    return Response({
        'text': text,
        'audio': None,
        'status': 'text_only',
        'message': 'Audio generation not available, returning text'
    }, status=status.HTTP_200_OK)


@api_view(['POST'])
def speech_recognition(request):
    """Transcribe audio to text (voice input for accessibility)."""
    if 'audio' not in request.FILES:
        return Response({'detail': 'Audio file is required'}, status=status.HTTP_400_BAD_REQUEST)
    
    audio_file = request.FILES['audio']
    
    try:
        import speech_recognition as sr
        
        # Save uploaded audio
        temp_path = f'/tmp/{audio_file.name}'
        with open(temp_path, 'wb') as f:
            f.write(audio_file.read())
        
        # Initialize recognizer
        recognizer = sr.Recognizer()
        
        # Load audio from file
        with sr.AudioFile(temp_path) as source:
            audio = recognizer.record(source)
        
        # Recognize speech
        text = recognizer.recognize_google(audio)
        
        os.remove(temp_path)
        
        return Response({
            'text': text,
            'status': 'success'
        }, status=status.HTTP_200_OK)
    except Exception:
        # Fallback response
        return Response({
            'text': '',
            'status': 'error',
            'message': 'Voice recognition not available'
        }, status=status.HTTP_200_OK)

