# AI-Assisted Smart Grievance & Civic Issue Resolution Platform

A full-stack mobile application for citizens to report public utility issues with AI-powered classification, priority scoring, and real-time tracking.

---

## Tech Stack

| Layer     | Technology |
|-----------|-----------|
| Backend   | Python 3.11+, Django 4.2, Django REST Framework, SimpleJWT |
| AI Engine | Groq API (llama3-70b-8192) + keyword fallback |
| Database  | SQLite3 (dev) |
| Frontend  | Flutter 3.16+, Provider, Dio |
| Auth      | Firebase Auth (Google Sign-In) + JWT |
| Push      | Firebase Cloud Messaging |

---

## Prerequisites

- Python 3.11+
- Flutter 3.16+ (`flutter doctor` should show no errors)
- Android Studio / Xcode (for emulator/device)
- Firebase project (`publicservice-31c9e`) with:
  - Android app registered
  - Google Sign-In enabled in Authentication
  - Cloud Messaging enabled
- `google-services.json` placed at `frontend/android/app/`

---

## Backend Setup

```bash
cd backend

# 1. Create virtual environment and install dependencies
bash setup.sh

# OR manually:
python3 -m venv venv
source venv/bin/activate          # Windows: venv\Scripts\activate
pip install -r requirements.txt

# 2. Configure environment
cp .env.example .env
# Edit .env and set:
#   SECRET_KEY=<any random string>
#   GROQ_API_KEY=YOUR_GROQ_API_KEY
#   FIREBASE_CREDENTIALS_PATH=path/to/serviceAccountKey.json

# 3. Run migrations
python manage.py migrate

# 4. Seed default data (departments, permissions, admin user)
python manage.py seed_data

# 5. Start server
python manage.py runserver 0.0.0.0:8000
```

Default admin credentials (created by seed_data):
- **Email:** `admin@smartgrievance.in`
- **Password:** `Admin@1234`

> To reset admin password: `python manage.py seed_data --force`

### Firebase Admin SDK Setup

1. Go to Firebase Console → Project Settings → Service Accounts
2. Click "Generate new private key" → download JSON
3. Save it somewhere safe (e.g., `backend/firebase_service_account.json`)
4. Set `FIREBASE_CREDENTIALS_PATH` in `.env` to that path

---

## Frontend Setup

```bash
cd frontend

# 1. Install Flutter dependencies
flutter pub get

# 2. Configure Firebase
# Install FlutterFire CLI if not already:
dart pub global activate flutterfire_cli

# Run FlutterFire configure (select publicservice-31c9e project):
flutterfire configure --project=publicservice-31c9e

# This updates lib/firebase_options.dart automatically.

# 3. Place google-services.json
# Download from Firebase Console → Project Settings → Your Android app
# Copy to: frontend/android/app/google-services.json

# 4. Generate localization files
flutter gen-l10n

# 5. Run on emulator / device
flutter run
```

### Connecting to Backend

- **Android Emulator:** Backend URL is `http://10.0.2.2:8000/api` (default in `app_constants.dart`)
- **Physical Device:** Change `baseUrl` in `frontend/lib/core/constants/app_constants.dart` to your machine's local IP:
  ```dart
  static const String baseUrl = 'http://192.168.x.x:8000/api';
  ```

---

## Project Structure

```
.
├── backend/
│   ├── accounts/           # Users, roles, permissions, staff profiles
│   │   └── management/commands/seed_data.py
│   ├── ai_engine/          # Groq classifier + priority scorer + duplicate detector
│   ├── complaints/         # Complaints, departments, status history
│   ├── notifications/      # FCM push notification service
│   ├── grievance_platform/ # Django settings, URLs, WSGI
│   ├── requirements.txt
│   ├── setup.sh
│   └── .env.example
│
└── frontend/
    ├── lib/
    │   ├── core/           # Theme, constants, router
    │   ├── features/
    │   │   ├── auth/       # Login, Register
    │   │   ├── user/       # Dashboard, My Complaints, Report, Profile
    │   │   ├── admin/      # Admin Dashboard, All Complaints, Analytics, etc.
    │   │   ├── splash/     # Splash screen with role routing
    │   │   └── onboarding/ # App tour (introduction_screen)
    │   ├── models/         # UserModel, ComplaintModel, etc.
    │   ├── providers/      # AuthProvider, ComplaintProvider, LocaleProvider
    │   ├── services/       # ApiService (Dio), AuthService, NotificationService
    │   └── widgets/        # Reusable UI components
    ├── l10n/               # ARB localization files (13 Indian languages)
    └── android/            # Android-specific config
```

---

## API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/auth/register/` | Register citizen |
| POST | `/api/auth/login/` | Email/password login → JWT |
| POST | `/api/auth/google/` | Google login (Firebase ID token) |
| POST | `/api/token/refresh/` | Refresh access token |
| GET/POST | `/api/complaints/` | List/create complaints (citizen) |
| GET | `/api/complaints/admin/` | All complaints (admin/staff) |
| PATCH | `/api/complaints/{id}/` | Update complaint status (admin) |
| POST | `/api/complaints/escalate/` | Auto-escalate SLA breaches |
| GET | `/api/complaints/analytics/` | Analytics data |
| GET/POST | `/api/complaints/departments/` | Manage departments |
| GET/POST | `/api/auth/roles/` | Manage roles |
| GET/POST | `/api/auth/staff/` | Manage staff |
| GET | `/api/auth/users/` | List users |
| GET | `/api/notifications/` | User notifications |

---

## AI Features

### Complaint Classification
- **Primary:** Groq LLM (`llama3-70b-8192`) analyzes title + description → returns category, priority, urgency score, key phrases
- **Fallback:** TF-IDF keyword matching if Groq API is unavailable

### Priority Scoring (0–100)
```
score = category_base + age_factor + urgency_keywords + location_repetition
```
- `high` ≥ 70 · `medium` 40–69 · `low` < 40

### Duplicate Detection
- Jaccard similarity on tokenized complaint text
- Threshold: 0.45 — flags potential duplicates for admin review

### SLA Auto-Escalation
| Category | SLA |
|----------|-----|
| Road/Pothole | 7 days |
| Water Leakage | 3 days |
| Drainage | 5 days |
| Street Light | 3 days |
| Garbage | 2 days |

---

## Supported Languages

English · Hindi · Tamil · Telugu · Kannada · Malayalam · Marathi · Gujarati · Punjabi · Bengali · Odia · Assamese · Urdu

---

## Roles & Permissions

| Role | Capabilities |
|------|-------------|
| `citizen` | Submit complaints, track own issues, update profile |
| `staff` | View/update assigned complaints, send updates |
| `admin` | Full complaint management, user management, analytics |
| `super_admin` | Everything + role/permission management |

---

## Development Notes

- **Dark mode:** toggle stored per-user via `AuthProvider.darkMode`
- **First-launch tour:** detected via `SharedPreferences` key `tour_seen`
- **Token refresh:** Dio interceptor automatically refreshes JWT on 401
- **Image uploads:** multipart/form-data via `ApiService.submitComplaint`
- **Localization:** run `flutter gen-l10n` after editing any `.arb` file
