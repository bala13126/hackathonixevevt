# ResQLink Backend (Django + PostgreSQL)

## Setup

1. Create and activate Python environment.
2. Install dependencies:
   - `pip install -r requirements.txt`
3. Copy env file:
   - `copy .env.example .env`
4. Ensure PostgreSQL is running and DB exists.
5. Run migrations:
   - `python manage.py migrate`
6. (Optional) create admin user:
   - `python manage.py createsuperuser`
7. Start server:
   - `python manage.py runserver`

## Base URL

- `http://localhost:8000/api`

## API Endpoints

- `GET /api/health`
- `GET /api/cases`
- `PUT /api/cases/{id}/status`
- `GET /api/tips`
- `POST /api/tips`
- `PUT /api/tips/{id}/verify`
- `GET /api/users`

## Expected Frontend Integration

- Admin dashboard fetches from `/api/cases`, `/api/tips`, `/api/users`
- Flutter app fetches cases and posts tips to `/api/tips`
