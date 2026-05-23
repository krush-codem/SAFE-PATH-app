import 'package:flutter_dotenv/flutter_dotenv.dart';

class EnvConfig {
  static String get supabaseUrl => dotenv.get('SUPABASE_URL', fallback: '');
  static String get supabaseAnonKey => dotenv.get('SUPABASE_ANON_KEY', fallback: '');
  static String get virusTotalApiKey => dotenv.get('VIRUSTOTAL_API_KEY', fallback: '');
  static String get googleMapsApiKey => dotenv.get('GOOGLE_MAPS_API_KEY', fallback: '');
  static String get backendBaseUrl => dotenv.get('BACKEND_BASE_URL', fallback: 'http://localhost:8000/api/v1');
  
  static bool get isLoaded => dotenv.isInitialized;
}
