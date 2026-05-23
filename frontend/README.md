# SafePath Frontend

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3.11+-blue?logo=flutter" alt="Flutter" />
  <img src="https://img.shields.io/badge/Dart-3.0+-teal?logo=dart" alt="Dart" />
  <img src="https://img.shields.io/badge/Riverpod-State%20Management-purple" alt="Riverpod" />
  <img src="https://img.shields.io/badge/Supabase-Auth%20%26%20DB-orange?logo=supabase" alt="Supabase" />
  <img src="https://img.shields.io/badge/Google%20Maps-Location-green?logo=googlemaps" alt="Google Maps" />
</p>

Flutter-based frontend for the SafePath personal safety application. Features a modern, responsive UI with real-time location tracking, emergency alerts, and comprehensive safety features.

## 📱 Screens Overview (25+ Screens)

### 🔐 Authentication Flow
| Screen | Description |
|--------|-------------|
| `splash_screen.dart` | App splash with logo animation |
| `welcome_screen.dart` | Onboarding with feature highlights |
| `login_screen.dart` | Google OAuth + Phone OTP login |
| `signup_screen.dart` | User registration with profile setup |
| `verification_screen.dart` | Phone number verification |

### 🏠 Main Application
| Screen | Description |
|--------|-------------|
| `home_dashboard.dart` | Main dashboard with quick actions |
| `main_layout.dart` | Bottom navigation scaffold |
| `active_journey_screen.dart` | Real-time journey with safety checks |
| `timer_setup_screen.dart` | Configure safety check intervals |

### 👥 Guardian Management
| Screen | Description |
|--------|-------------|
| `manage_guardians_screen.dart` | Add/edit trusted contacts |
| `safe_circle_chat_screen.dart` | In-app guardian communication |
| `lifeline_screen.dart` | Emergency contact configuration |

### 📊 History & Analytics
| Screen | Description |
|--------|-------------|
| `history_screen.dart` | Activity logs with filtering (NEW) |
| - Filter by: All, Secure, Alerts |
| - Real-time sync every 5 seconds |
| - Timeline visualization |
| - Search functionality |

### 🔒 Security Features
| Screen | Description |
|--------|-------------|
| `aegis_guard_screen.dart` | VirusTotal URL/File scanner |
| - Radar scanner animation |
| - Threat detection results |
| `safety_check_screen.dart` | OTP verification during journeys |
| `physical_safety.dart` | Safety tips and guidelines |

### ⚙️ Settings & Customization
| Screen | Description |
|--------|-------------|
| `settings_screen.dart` | Main settings menu |
| `appearance_screen.dart` | Theme customization with hex picker |
| `edit_profile_screen.dart` | Profile management |
| `privacy_screen.dart` | Privacy controls |
| `manage_location_sharing_screen.dart` | Location sharing settings |

### 🗺️ Location Services
| Screen | Description |
|--------|-------------|
| `location_picker_screen.dart` | Select origin/destination |
| `location_permissions_screen.dart` | Permission handling |
| `contacts_access_screen.dart` | Contact import for guardians |
| `microphone_access_screen.dart` | Audio permission setup |

## 🏗️ Project Structure

```
lib/
├── main.dart                    # App entry point
├── screens/                     # 25+ UI screens
│   ├── active_journey_screen.dart
│   ├── aegis_guard_screen.dart
│   ├── appearance_screen.dart
│   ├── history_screen.dart      # NEW: Activity Logs UI
│   ├── home_dashboard.dart
│   ├── manage_guardians_screen.dart
│   └── ... (21 more screens)
│
├── models/                      # Data models
│   ├── journey.dart             # Journey with alert tracking
│   ├── guardian.dart
│   ├── profile.dart
│   └── chat_message.dart
│
├── providers/                   # Riverpod state management
│   ├── journey_provider.dart    # Journey state + filters
│   ├── auth_provider.dart
│   ├── theme_provider.dart
│   └── repository_providers.dart
│
├── repositories/                # Data layer
│   ├── journey_repository.dart
│   ├── chat_repository.dart
│   └── ...
│
├── services/                    # Business logic
│   ├── api_service.dart         # Backend API client
│   └── location_service.dart
│
├── theme/
│   └── app_theme.dart           # Color schemes & themes
│
├── core/config/
│   └── env_config.dart          # Environment variables
│
└── widgets/                     # Reusable components
    └── (shared widgets)
```

## 🚀 Getting Started

### Prerequisites
- Flutter SDK: ^3.11.1
- Dart SDK: ^3.0.0
- Android Studio / VS Code
- Supabase account
- Google Cloud Console (for Maps API)

### Installation

1. **Clone and Navigate**
   ```bash
   cd frontend
   ```

2. **Install Dependencies**
   ```bash
   flutter pub get
   ```

3. **Environment Setup**
   Create `.env` file in `frontend/` directory:
   ```env
   SUPABASE_URL=https://your-project.supabase.co
   SUPABASE_ANON_KEY=your-anon-key-here
   VIRUSTOTAL_API_KEY=your-api-key-here
   ```

4. **Configure Platforms**

   **Android** (`android/app/src/main/AndroidManifest.xml`):
   ```xml
   <meta-data android:name="com.google.android.geo.API_KEY"
              android:value="YOUR_GOOGLE_MAPS_API_KEY"/>
   ```

   **iOS** (`ios/Runner/AppDelegate.swift`):
   ```swift
   GMSServices.provideAPIKey("YOUR_GOOGLE_MAPS_API_KEY")
   ```

5. **Run the App**
   ```bash
   # Development
   flutter run

   # Production build
   flutter build apk --release
   flutter build ios --release
   ```

## 📦 Dependencies

### Core Dependencies
```yaml
dependencies:
  flutter:
    sdk: flutter

  # UI & Theming
  google_fonts: ^8.0.2
  cupertino_icons: ^1.0.8

  # State Management
  flutter_riverpod: ^3.3.1

  # Navigation
  go_router: ^17.1.0

  # Backend & Auth
  supabase_flutter: ^2.12.2
  dio: ^5.7.0
  http: ^1.6.0

  # Location & Maps
  google_maps_flutter: ^2.10.0
  geolocator: ^13.0.2
  flutter_polyline_points: ^2.1.0

  # Utilities
  intl: ^0.20.2
  flutter_dotenv: ^5.1.0
  permission_handler: ^11.3.1
  image_picker: ^1.1.2
  file_picker: ^8.1.4
  intl_phone_field: ^3.2.0
```

## 🎯 Key Features Implemented

### 1. Real-Time Journey History (Recently Added)

The new **Activity Logs** screen features:
- **Auto-refresh**: Updates every 5 seconds via `StreamProvider`
- **Smart Filtering**: All / Secure / Alert journey tabs
- **Timeline UI**: Visual journey cards with connector lines
- **Search**: Filter by origin/destination
- **Statistics**: Arrival rate, total journeys, alerts count

```dart
// Stream-based auto-refresh
final historyProvider = StreamProvider<List<Journey>>((ref) async* {
  yield await repo.fetchJourneys();
  await for (final _ in Stream.periodic(Duration(seconds: 5))) {
    yield await repo.fetchJourneys();
  }
});
```

### 2. Journey Safety System

- **Timer-based checks**: Configurable intervals (5-60 mins)
- **OTP verification**: 6-digit safety codes
- **Auto-SOS**: Triggers if user doesn't respond
- **Journey persistence**: Saved to Supabase on completion

### 3. Guardian Management

- **Add guardians**: Name, phone, relation
- **Quick alerts**: SMS/Voice from chat screen
- **Safe Circle**: In-app messaging system
- **Contact sync**: Import from phone contacts

### 4. Digital Security (SafePath Guard)

- **URL Scanner**: VirusTotal integration
- **File Scanner**: Upload and scan files
- **Radar Animation**: Custom painter scanner UI
- **Threat Results**: Malicious/suspicious detection counts

### 5. Theme Customization

- **Custom colors**: Hex spectrum picker
- **Dark/Light modes**: Adaptive themes
- **Preset accents**: Quick color selection
- **Live preview**: Real-time theme changes

## 📡 API Integration

The app connects to the Python backend via `ApiService`:

```dart
class ApiService {
  static const String baseUrl = "http://localhost:8000/api/v1";
  
  // SOS & Journey
  static Future<void> triggerSOS(String userId, LatLng location) async {...}
  
  // Profile
  static Future<Map<String, dynamic>?> getProfile(String userId) async {...}
  static Future<void> updateProfile(String userId, Map updates) async {...}
  
  // Guardians
  static Future<List<dynamic>> getGuardians(String userId) async {...}
  static Future<void> addGuardian(String userId, Map data) async {...}
  static Future<void> deleteGuardian(String guardianId) async {...}
}
```

### Supabase Integration

```dart
// Auth
final authResponse = await Supabase.instance.client.auth.signInWithPassword(
  email: email,
  password: password,
);

// Real-time subscriptions
Supabase.instance.client
  .from('messages')
  .stream(primaryKey: ['id'])
  .listen((data) => handleNewMessages(data));
```

## 🎨 Design System

### Color Palette
```dart
class AppColors {
  static const Color primary = Color(0xFF4A90E2);
  static const Color secondary = Color(0xFFF25C05);
  static const Color darkBackground = Color(0xFF0A1220);
  static const Color cardDark = Color(0xFF1E2633);
}
```

### Typography
```dart
// Using Google Fonts
title: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 24);
body: GoogleFonts.inter(fontSize: 14);
accent: GoogleFonts.manrope(fontWeight: FontWeight.w600);
```

### Screen Architecture
Each screen follows this pattern:
```dart
class ExampleScreen extends ConsumerStatefulWidget {
  const ExampleScreen({super.key});
  @override
  ConsumerState<ExampleScreen> createState() => _ExampleScreenState();
}

class _ExampleScreenState extends ConsumerState<ExampleScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = ref.watch(exampleProvider);
    // UI implementation
  }
}
```

## 🧪 Testing

```bash
# Run unit tests
flutter test

# Run with coverage
flutter test --coverage

# Integration tests
flutter test integration_test/
```

## 📱 Platform-Specific Notes

### Android
- Minimum SDK: 21
- Target SDK: 34
- Location permissions in `AndroidManifest.xml`
- Background location for journey tracking

### iOS
- Minimum iOS: 12.0
- Location permissions in `Info.plist`
- Camera and photo library permissions
- Microphone permissions for voice features

### Web
- Limited location support
- File picker uses browser APIs
- Maps supported with JavaScript renderer

## 🐛 Common Issues

### Build Issues
```bash
# Clean build
flutter clean && flutter pub get

# Update dependencies
flutter pub upgrade
```

### Location Issues
- Ensure location permissions are granted
- Check `AndroidManifest.xml` / `Info.plist`
- Test on physical device (emulator may have GPS issues)

### Supabase Connection
- Verify `.env` file exists and is correct
- Check `pubspec.yaml` includes `.env` in assets
- Ensure Supabase URL and anon key are valid

## 📝 Environment Configuration

### Required Variables (.env)
```env
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIs...
VIRUSTOTAL_API_KEY=your-virustotal-api-key
```

### pubspec.yaml Assets
```yaml
flutter:
  assets:
    - .env
```

## 🤝 Contributing

1. Fork the repository
2. Create feature branch (`git checkout -b feature/amazing-feature`)
3. Commit changes (`git commit -m 'Add amazing feature'`)
4. Push to branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

MIT License - See main project LICENSE file

## 🙏 Credits

- **Flutter Team** - UI framework
- **Supabase** - Backend as a service
- **Google Maps** - Location services
- **VirusTotal** - Security scanning
- **Twilio** - SMS/Voice (via backend)

## � Contributors

| Name | Role | GitHub |
|------|------|--------|
| **Payal Nayak** | Frontend Design, Backend VirusTotal & Twilio Integration | [@Dynamicpayal](https://github.com/Dynamicpayal/) |
| **Harekrushna Behera** | Frontend UI, Supabase Configuration | [@krush-codem](https://github.com/krush-codem/) |
| **Smruti Rekha Sahoo** | Documentation | [@smruti-18](https://github.com/smruti-18) |
| **Suraj Kumar Sahoo** | Testing | [@Dynamicsuraj](https://github.com/Dynamicsuraj/) |
| **Deepika Gouda** | Documentation | [@deepikagouda966-tech](https://github.com/deepikagouda966-tech) |

## �📞 Support

For issues and feature requests, please use the GitHub issue tracker.

---

<p align="center">Built with ❤️ for personal safety</p>
