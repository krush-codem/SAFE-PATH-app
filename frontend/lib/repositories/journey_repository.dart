import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/journey.dart';
import '../services/api_service.dart';

class JourneyRepository {
  final SupabaseClient _client;

  JourneyRepository(this._client);

  Future<List<Journey>> fetchJourneys() async {
    final user = _client.auth.currentUser;
    if (user == null) return [];

    final response = await _client
        .from('journeys')
        .select()
        .eq('user_id', user.id)
        .order('created_at', ascending: false);

    return (response as List).map((json) => Journey.fromJson(json)).toList();
  }

  Future<void> saveJourney(Journey journey) async {
    await _client.from('journeys').insert(journey.toJson());
  }

  Future<void> clearHistory() async {
    final user = _client.auth.currentUser;
    if (user == null) return;
    await _client.from('journeys').delete().eq('user_id', user.id);
  }

  // --- Backend Safety Features ---
  Future<Map<String, dynamic>> startSafetyJourney(String userId, int interval) async {
    return await ApiService.post('/journey/start', {
      'user_id': userId,
      'interval_mins': interval,
    });
  }

  Future<Map<String, dynamic>> verifySafetyOtp(String userId, String otp) async {
    return await ApiService.post('/journey/verify-otp', {
      'user_id': userId,
      'otp': otp,
    });
  }

  Future<void> stopSafetyJourney(String userId) async {
    await ApiService.post('/journey/stop', {
      'user_id': userId,
    });
  }
}
