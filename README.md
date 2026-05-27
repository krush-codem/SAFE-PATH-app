# SafePath - Personal Safety Application

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3.11+-blue?logo=flutter" alt="Flutter" />
  <img src="https://img.shields.io/badge/FastAPI-Python-green?logo=fastapi" alt="FastAPI" />
  <img src="https://img.shields.io/badge/Supabase-Database-orange?logo=supabase" alt="Supabase" />
  <img src="https://img.shields.io/badge/Twilio-SMS/Voice-red?logo=twilio" alt="Twilio" />
</p>

**SafePath** is a comprehensive personal safety application designed to provide real-time protection and emergency response features. The app combines modern mobile technology with cloud services to ensure users feel safe and connected to their trusted guardians at all times.

## 🌟 Key Features

### 🚨 Emergency Response System
- **SOS Trigger**: One-tap emergency alert that broadcasts location to all guardians
- **Periodic Safety Check**: Automated OTP-based safety verification during journeys
- **Auto-SOS**: Automatic emergency trigger if safety check fails
- **Bulk Alerts**: Send emergency alerts to all guardians simultaneously via SMS and Voice

### 🛡️ Guardian Management
- **Trusted Contacts**: Add multiple guardians with relation tags (Family, Friend, etc.)
- **SMS Alerts**: Send location-based emergency SMS to specific guardians
- **Voice Calls**: Automated emergency voice calls with location coordinates
- **Safe Circle Chat**: In-app communication with guardians

### 🗺️ Journey Tracking
- **Active Journey Mode**: Real-time location tracking with timer-based safety checks
- **Journey History**: Complete activity logs with filtering (Secure/Alert/All)
- **Real-time Updates**: Auto-refreshing history with every 5-second sync
- **Alert Detection**: Automatic tracking of journeys with SOS triggers

### 🔒 Security Features
- **VirusTotal Integration**: URL and file scanning for phishing/malware detection
- **Digital Sentinel**: Cybersecurity protection with radar scanner UI
- **Google OAuth**: Secure authentication via Google Sign-In
- **Phone OTP**: Twilio-based phone verification

### 🎨 Customization
- **Appearance Settings**: Custom theme colors with hex spectrum selector
- **Dark/Light Mode**: Adaptive UI themes
- **Custom Accents**: Personalized color schemes

### 📱 Additional Features
- **Lifeline Setup**: Emergency contact configuration
- **Location Sharing**: Share real-time location with guardians
- **Profile Management**: User profile with avatar and contact details
- **Physical Safety**: Safety tips and guidelines

## 📁 Project Structure

```
safepath_innovative_safety_app/
├── backend/                 # FastAPI Backend
│   ├── main.py             # Main FastAPI application
│   ├── requirements.txt    # Python dependencies
│   ├── .env.example        # Environment variables template
│   └── venv/               # Python virtual environment
│
└── frontend/               # Flutter Frontend
    ├── lib/
    │   ├── screens/        # UI screens (25+ screens)
    │   ├── models/         # Data models (Journey, Guardian, Profile, ChatMessage)
    │   ├── providers/      # Riverpod state management
    │   ├── services/       # API services
    │   ├── repositories/   # Data repositories
    │   ├── theme/          # App theming
    │   └── core/config/    # Environment configuration
    ├── pubspec.yaml        # Flutter dependencies
    └── .env                # Frontend environment variables
```

## 🚀 Getting Started

### Prerequisites
- **Flutter SDK**: ^3.11.1
- **Python**: 3.8+
- **Supabase Account**: For database and authentication
- **Twilio Account**: For SMS and Voice alerts (optional but recommended)
- **VirusTotal API Key**: For security scanning (optional)

### Installation

1. **Clone the Repository**
   ```bash
   git clone https://github.com/yourusername/safepath.git
   cd safepath_innovative_safety_app
   ```

2. **Backend Setup**
   ```bash
   cd backend
   python -m venv venv
   source venv/bin/activate  # Windows: venv\Scripts\activate
   pip install -r requirements.txt
   cp .env.example .env
   # Edit .env with your credentials
   uvicorn main:app --reload --host 0.0.0.0 --port 8000
   ```

3. **Frontend Setup**
   ```bash
   cd frontend
   flutter pub get
   # Create .env file with Supabase credentials
   flutter run
   ```

## 🔧 Configuration

### Environment Variables

#### Backend (.env)
```env
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_KEY=your-service-role-key
TWILIO_ACCOUNT_SID=ACxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
TWILIO_AUTH_TOKEN=your-auth-token
TWILIO_PHONE_NUMBER=+1234567890
VIRUSTOTAL_API_KEY=your-api-key
```

#### Frontend (.env)
```env
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key
VIRUSTOTAL_API_KEY=your-api-key
```

### Supabase Database Schema

Required tables:
- `profiles` - User profiles
- `guardians` - Trusted contacts
- `journeys` - Journey history
- `messages` - In-app messages and system alerts

## 📚 Documentation

- [Backend README](./backend/README.md) - Detailed backend documentation
- [Frontend README](./frontend/README.md) - Detailed frontend documentation

## 👥 Contributors

The SafePath project was built collaboratively by an amazing team:

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🙏 Acknowledgments

- Flutter Team for the amazing UI framework
- Supabase for the open-source Firebase alternative
- Twilio for communication APIs
- VirusTotal for security scanning services
