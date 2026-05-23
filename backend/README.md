# SafePath Backend

<p align="center">
  <img src="https://img.shields.io/badge/FastAPI-0.115+-green?logo=fastapi" alt="FastAPI" />
  <img src="https://img.shields.io/badge/Python-3.8+-blue?logo=python" alt="Python" />
  <img src="https://img.shields.io/badge/Supabase-Database-orange?logo=supabase" alt="Supabase" />
  <img src="https://img.shields.io/badge/Twilio-SMS/Voice-red?logo=twilio" alt="Twilio" />
</p>

FastAPI-based backend for the SafePath personal safety application. Provides RESTful APIs for user management, emergency alerts, journey tracking, and security scanning.

## 🏗️ Architecture (Updated)

The backend has been modularized for better security and maintainability:

```
backend/
├── app/
│   ├── main.py              # Application entry point
│   ├── routers/             # Domain-specific API endpoints
│   ├── services/            # Business logic (SOS, Twilio, VT)
│   ├── models/              # Pydantic schemas
│   ├── internal/            # Shared state and constants
│   └── dependencies.py      # JWT Auth & Security logic
├── requirements.txt         # Python dependencies
├── .env                     # Environment variables
└── venv/                    # Virtual environment
```

## 🔒 Security Updates

1. **JWT Authentication**: All endpoints are now secured. The backend verifies the Supabase JWT provided in the `Authorization` header.
2. **Identity Protection**: Users can only perform actions (SOS, Delete, Profile Update) on their own `user_id`.
3. **Refined SOS Escalation**: Safety checks now include a grace period and multiple notifications before alerting guardians to prevent false alarms.

## 🚀 Quick Start

### 1. Environment Setup

```bash
# Create virtual environment
python -m venv venv

# Activate virtual environment
# Windows:
venv\Scripts\activate
# macOS/Linux:
source venv/bin/activate

# Install dependencies
pip install -r requirements.txt
```

### 2. Configuration

Copy `.env.example` to `.env` and configure:

```env
# Supabase Configuration
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_KEY=your-service-role-key-here

# Twilio Configuration (for SMS and Voice alerts)
TWILIO_ACCOUNT_SID=ACxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
TWILIO_AUTH_TOKEN=your-auth-token-here
TWILIO_PHONE_NUMBER=+1234567890

# VirusTotal API Key (for security scanning)
VIRUSTOTAL_API_KEY=your-api-key-here
```

### 3. Run Server

```bash
# Development mode with auto-reload
uvicorn main:app --reload --host 0.0.0.0 --port 8000

# Production mode
uvicorn main:app --host 0.0.0.0 --port 8000
```

### 4. Access API Documentation

- **Swagger UI**: http://localhost:8000/docs
- **ReDoc**: http://localhost:8000/redoc
- **Health Check**: http://localhost:8000/

## 📡 API Endpoints

### 🚨 SOS & Emergency

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/api/v1/sos/trigger` | POST | Trigger emergency SOS with location broadcast |
| `/api/v1/sos/stop` | POST | Stop active SOS alerts |

**SOS Trigger Request:**
```json
{
  "user_id": "uuid-string",
  "latitude": 12.9716,
  "longitude": 77.5946
}
```

### 🛡️ Journey Management

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/api/v1/journey/start` | POST | Start safety journey with periodic checks |
| `/api/v1/journey/verify-otp` | POST | Verify safety check OTP |
| `/api/v1/journey/stop` | POST | Stop journey and save to history |

**Journey Start Request:**
```json
{
  "user_id": "uuid-string",
  "interval_mins": 30
}
```

**OTP Verify Request:**
```json
{
  "user_id": "uuid-string",
  "journey_id": "optional-uuid",
  "otp": "123456"
}
```

### 👤 User Management

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/api/v1/user/delete` | POST | Delete user account completely |
| `/api/v1/user/profile/{user_id}` | GET | Get user profile |
| `/api/v1/user/profile/{user_id}` | PUT | Update user profile |

**Profile Update Request:**
```json
{
  "user_id": "uuid-string",
  "full_name": "John Doe",
  "email": "john@example.com",
  "phone": "+1234567890"
}
```

### 👥 Guardian Management

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/api/v1/user/guardians/{user_id}` | GET | Get all guardians for user |
| `/api/v1/user/guardians/{user_id}` | POST | Add new guardian |
| `/api/v1/user/guardians/{guardian_id}` | DELETE | Delete guardian |

**Add Guardian Request:**
```json
{
  "full_name": "Jane Doe",
  "phone": "+1987654321",
  "relation": "Family"
}
```

### 📱 Alert System (Twilio Integration)

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/api/v1/alerts/send-sms` | POST | Send SMS alert to specific guardian |
| `/api/v1/alerts/send-voice` | POST | Send voice call alert |
| `/api/v1/alerts/send-bulk` | POST | Send alerts to all guardians |
| `/api/v1/twilio/status` | GET | Check Twilio configuration status |

**SMS Alert Request:**
```json
{
  "user_id": "uuid-string",
  "guardian_id": "guardian-uuid",
  "message": "Emergency! Need help at this location",
  "latitude": 12.9716,
  "longitude": 77.5946
}
```

**Bulk Alert Request:**
```json
{
  "user_id": "uuid-string",
  "message": "Emergency alert!",
  "latitude": 12.9716,
  "longitude": 77.5946,
  "alert_type": "both"  // "sms", "voice", or "both"
}
```

### 🔒 Security Scanning (VirusTotal)

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/api/v1/security/scan-url` | POST | Scan URL for phishing/malware |
| `/api/v1/security/scan-file` | POST | Scan uploaded file for threats |

**URL Scan Request:**
```json
{
  "url": "https://example.com/suspicious-link"
}
```

**Scan Response:**
```json
{
  "id": "scan-id",
  "status": "completed",
  "malicious": 2,
  "suspicious": 1,
  "undetected": 70,
  "harmless": 5,
  "total_engines": 78,
  "link": "https://www.virustotal.com/gui/url/..."
}
```

## 📊 Database Schema

### Supabase Tables

#### profiles
```sql
- id: uuid (primary key)
- full_name: text
- email: text
- avatar_url: text
- phone_number: text
- sos_phone: text
- lifeline_setup_complete: boolean
- last_lat: float
- last_lng: float
- last_active: timestamp
- created_at: timestamp
```

#### guardians
```sql
- id: uuid (primary key)
- user_id: uuid (foreign key -> profiles.id)
- full_name: text
- phone: text
- relation: text
- is_active: boolean
- is_app_user: boolean
- profile_id: uuid
- created_at: timestamp
```

#### journeys
```sql
- id: uuid (primary key)
- user_id: uuid (foreign key -> profiles.id)
- origin: text
- destination: text
- status: text ('completed', 'active', 'sosTriggered')
- duration: text
- had_alert: boolean
- sos_count: int
- created_at: timestamp
```

#### messages
```sql
- id: uuid (primary key)
- sender_id: text ('system' or user_id)
- receiver_id: uuid (foreign key -> profiles.id)
- content: text
- is_read: boolean
- read_at: timestamp
- created_at: timestamp
```

## 🔧 Key Features Implementation

### 1. Periodic Safety Check System

The backend implements an async safety loop that:
- Generates 6-digit OTP at configurable intervals (default 30 mins)
- Sends OTP via in-app message
- Waits 5 minutes for verification
- Auto-triggers SOS if verification fails

```python
async def otp_safety_loop(user_id: str, interval_mins: int):
    # Generates OTP and waits for verification
    # Triggers SOS if user fails to respond
```

### 2. Twilio Emergency Alerts

Dual-channel emergency communication:
- **SMS**: Location link with Google Maps URL
- **Voice**: Automated call with spoken coordinates
- **Bulk Send**: Alert all guardians simultaneously

### 3. VirusTotal Security Scanning

Proxy for URL and file scanning:
- Submits scan requests to VirusTotal API
- Polls for results with timeout handling
- Returns aggregated threat statistics

## 🛡️ Security Considerations

1. **CORS**: Configured for development (`allow_origins=["*"]`). Restrict in production.
2. **Authentication**: Relies on Supabase Auth (JWT tokens)
3. **RLS Bypass**: Uses service_role key for admin operations
4. **Phone Formatting**: Ensures E.164 format (+ prefix)
5. **Rate Limiting**: Built-in delays between Twilio calls

## 🐛 Debug Scripts

The `backend/` directory includes utility scripts:

| Script | Purpose |
|--------|---------|
| `check_auth.py` | Verify Supabase authentication |
| `check_db.py` | Test database connectivity |
| `debug_guardians.py` | Debug guardian records |
| `debug_profiles.py` | Inspect user profiles |
| `test_finalize.py` | Test registration finalization |

## 📝 Environment Variables Reference

| Variable | Required | Description |
|----------|----------|-------------|
| `SUPABASE_URL` | Yes | Supabase project URL |
| `SUPABASE_KEY` | Yes | Service role key (bypasses RLS) |
| `TWILIO_ACCOUNT_SID` | No | Twilio account identifier |
| `TWILIO_AUTH_TOKEN` | No | Twilio authentication token |
| `TWILIO_PHONE_NUMBER` | No | Twilio sender phone number |
| `VIRUSTOTAL_API_KEY` | No | VirusTotal API access key |

## 🚦 Status Codes

- `200` - Success
- `400` - Bad Request (invalid payload)
- `408` - Request Timeout (scan timeout)
- `500` - Internal Server Error

## 🤝 Integration with Frontend

The frontend connects to this backend via `ApiService` class:
- Base URL: `http://localhost:8000/api/v1`
- Timeout: 10 seconds per request
- JSON payloads for all requests

## � Dependencies

```
fastapi>=0.115.0      # Web framework
uvicorn>=0.30.0       # ASGI server
supabase>=2.12.0     # Database client
twilio>=8.12.0       # SMS/Voice API
python-dotenv>=1.0.0 # Environment variables
pydantic>=2.10.0     # Data validation
httpx>=0.27.0        # HTTP client
```

## 🐛 Troubleshooting

### Twilio Issues
- Verify phone numbers are in E.164 format (+1234567890)
- For trial accounts, verify recipient numbers at Twilio Console
- Check `TWILIO_PHONE_NUMBER` is set correctly

### Supabase Connection
- Ensure service_role key is used (not anon key)
- Verify RLS policies are configured correctly
- Check database tables exist with correct schema

### CORS Errors
- Backend allows all origins in development
- For production, specify exact frontend URL

## 👥 Contributors

| Name | Role | GitHub |
|------|------|--------|
| **Payal Nayak** | Backend VirusTotal & Twilio Integration, Frontend Design | [@Dynamicpayal](https://github.com/Dynamicpayal/) |
| **Harekrushna Behera** | Frontend UI, Supabase Configuration | [@krush-codem](https://github.com/krush-codem/) |
| **Smruti Rekha Sahoo** | Documentation | [@smruti-18](https://github.com/smruti-18) |
| **Suraj Kumar Sahoo** | Testing | [@Dynamicsuraj](https://github.com/Dynamicsuraj/) |
| **Deepika Gouda** | Documentation | [@deepikagouda966-tech](https://github.com/deepikagouda966-tech) |

## 📄 License

MIT License - See main project LICENSE file

## 🙏 Credits

- FastAPI - High-performance web framework
- Twilio - Communication platform
- Supabase - Open-source Firebase alternative
- VirusTotal - Security intelligence platform
