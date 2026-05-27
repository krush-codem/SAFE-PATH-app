# SafePath - Innovative Safety Application

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3.11+-blue?logo=flutter" alt="Flutter" />
  <img src="https://img.shields.io/badge/FastAPI-Python-green?logo=fastapi" alt="FastAPI" />
  <img src="https://img.shields.io/badge/Supabase-Database-orange?logo=supabase" alt="Supabase" />
  <img src="https://img.shields.io/badge/Twilio-SMS/Voice-red?logo=twilio" alt="Twilio" />
  <img src="https://img.shields.io/badge/WebSockets-Realtime-purple?logo=socket.io" alt="WebSockets" />
</p>

**SafePath** is a comprehensive, high-security personal safety application designed to provide real-time protection and emergency response features. Built with a modern **"Deep Obsidian"** aesthetic, it combines robust mobile technology with scalable cloud services to ensure users feel safe and connected to their trusted guardians at all times.

## 🌟 Key Features

### 🚨 Emergency Response System
- **SOS Trigger**: One-tap emergency alert that broadcasts your location to all guardians.
- **Periodic Safety Check**: Automated OTP-based safety verification during active journeys.
- **Auto-SOS**: Automatic emergency trigger if a safety check is missed or fails.
- **Bulk Alerts**: Send emergency alerts to all guardians simultaneously via SMS and automated Voice calls (Twilio integration).

### 💬 Real-Time Safe Chat (Custom WebSockets)
- **Instant Messaging**: Real-time communication with your trust circle powered by a custom FastAPI WebSocket server.
- **System Alerts**: Dedicated read-only channel for official OTPs and security updates.
- **Offline Sync**: Differential message fetching ensures you never miss a message if you lose connection.
- **Optimistic UI**: Instant message rendering on the frontend before database confirmation for a lightning-fast feel.

### 🛡️ Guardian Management
- **Trusted Contacts**: Add multiple guardians with relation tags (Family, Friend, etc.).
- **Live Permission Toggles**: Instantly grant or revoke real-time location tracking access per guardian.
- **SMS & Voice Alerts**: Configure specific guardians to receive priority alerts.

### 🗺️ Journey Tracking & Planning
- **Active Journey Mode**: Real-time location tracking with dynamic timer-based safety checks.
- **Trip Planner**: Built-in location picker utilizing Google Places API for precise routing.
- **Journey History**: Complete activity logs with filtering (Secure / Alert / All).

### 🔒 Security & Aesthetics
- **Digital Sentinel (Aegis Guard)**: Cybersecurity protection with a radar scanner UI and VirusTotal integration for phishing/malware detection.
- **Deep Obsidian Theme**: A cohesive, high-contrast UI utilizing OKLCH tinted neutrals, "Electric Blue" primary actions, and "Urgent Crimson" alerts.
- **Secure Authentication**: Google OAuth and Supabase Auth with strict backend JWT verification.

---

## 📁 Project Architecture

The project is split into a robust Python backend and a cross-platform Flutter frontend.

```text
safepath_innovative_safety_app/
├── backend/                 # FastAPI Backend (Python)
│   ├── app/
│   │   ├── routers/         # API endpoints (chat, sos, journey, alerts)
│   │   ├── services/        # Twilio, VirusTotal logic
│   │   ├── models/          # Pydantic schemas
│   │   └── config.py        # Environment & Supabase initialization
│   ├── requirements.txt
│   └── main.py             # FastAPI entry point
│
└── frontend/               # Flutter Frontend (Dart)
    ├── lib/
    │   ├── screens/        # UI screens (Home, Chat, Settings, etc.)
    │   ├── widgets/        # Reusable UI components
    │   ├── providers/      # Riverpod state management & WebSocket streams
    │   ├── services/       # Custom WebSocketService & API clients
    │   ├── theme/          # Centralized AppTheme (Deep Obsidian)
    │   └── routing/        # GoRouter configuration
    └── pubspec.yaml
```

---

## 🚀 Getting Started

### Prerequisites
- **Flutter SDK**: `^3.11.1`
- **Python**: `3.8+`
- **Supabase Project**: For PostgreSQL database and authentication.
- **Twilio Account**: For SMS and Voice alerts (optional but recommended).
- **Google Maps API Key**: For the location picker and mapping features.

### 1. Backend Setup

```bash
cd backend
python -m venv venv
source venv/bin/activate  # Windows: venv\Scripts\activate
pip install -r requirements.txt
```

Create a `.env` file in the `backend/` directory:
```env
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_KEY=your-service-role-key
TWILIO_ACCOUNT_SID=ACxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
TWILIO_AUTH_TOKEN=your-auth-token
TWILIO_PHONE_NUMBER=+1234567890
VIRUSTOTAL_API_KEY=your-vt-api-key
```

Run the server:
```bash
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

### 2. Frontend Setup

```bash
cd frontend
flutter pub get
```

Create a `.env` file in the `frontend/` directory:
```env
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key
GOOGLE_MAPS_API_KEY=your-gmaps-api-key
BACKEND_BASE_URL=http://localhost:8000/api/v1  # Update for production
```

Run the app:
```bash
flutter run
```

---

## 🔌 WebSocket Chat Implementation Details

SafePath features a highly optimized chat system built from scratch to replace default BaaS solutions:
1.  **FastAPI ConnectionManager**: Tracks active user sockets in memory (designed to scale with Redis Pub/Sub in the future).
2.  **Handshake Authentication**: The connection initializes unauthenticated; the client must immediately send a `{ "type": "auth", "token": "JWT" }` payload. The connection is dropped if verification fails.
3.  **Asynchronous Writes**: Messages are broadcasted instantly to the recipient's socket while the database `insert` happens concurrently via `asyncio.create_task()`, preventing DB latency from slowing down the chat.
4.  **Riverpod Stream Merging**: The Flutter frontend combines initial REST history loads with the live WebSocket stream into a single, deduplicated `AsyncValue` provider.

---

## 👥 Contributors

The SafePath project was built collaboratively by an amazing team of out collaborators.

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.
