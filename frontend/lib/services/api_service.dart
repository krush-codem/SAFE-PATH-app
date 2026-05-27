import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/config/env_config.dart';

class ApiService {
  static String get baseUrl => EnvConfig.backendBaseUrl;

  static Map<String, String> _getHeaders() {
    final headers = {"Content-Type": "application/json"};
    final session = Supabase.instance.client.auth.currentSession;
    if (session != null) {
      headers["Authorization"] = "Bearer ${session.accessToken}";
    }
    return headers;
  }

  static Future<Map<String, dynamic>> post(String endpoint, Map<String, dynamic> body) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl$endpoint"),
        headers: _getHeaders(),
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return jsonDecode(response.body);
      } else {
        throw Exception("Server Error: ${response.statusCode} - ${response.body}");
      }
    } catch (e) {
      debugPrint("API Error: $e");
      rethrow;
    }
  }

  /// Calls the backend to permanently delete the user from auth and database.
  static Future<void> deleteUserAccount(String userId) async {
    await post("/user/delete", {"user_id": userId});
  }

  static Future<void> sendHeartbeat() async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/user/heartbeat"),
        headers: _getHeaders(),
      ).timeout(const Duration(seconds: 5));
      if (response.statusCode >= 300) debugPrint("Heartbeat failed: ${response.statusCode}");
    } catch (e) {
      debugPrint("Heartbeat error: $e");
    }
  }

  // --- Profile methods ---
  static Future<Map<String, dynamic>?> getProfile(String userId) async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/user/profile/$userId"),
        headers: _getHeaders(),
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200 && response.body.isNotEmpty && response.body != 'null') {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      debugPrint("API Error getProfile: $e");
      return null;
    }
  }

  static Future<void> updateProfile(String userId, Map<String, dynamic> updates) async {
    try {
      final response = await http.put(
        Uri.parse("$baseUrl/user/profile/$userId"),
        headers: _getHeaders(),
        body: jsonEncode(updates),
      ).timeout(const Duration(seconds: 10));
      if (response.statusCode >= 300) throw Exception("Failed to update profile via API");
    } catch (e) {
      debugPrint("API Error updateProfile: $e");
      rethrow;
    }
  }

  // --- Guardian methods ---
  static Future<List<dynamic>> getGuardians(String userId) async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/user/guardians/$userId"),
        headers: _getHeaders(),
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as List<dynamic>;
      }
      return [];
    } catch (e) {
      debugPrint("API Error getGuardians: $e");
      return [];
    }
  }

  static Future<void> addGuardian(String userId, Map<String, dynamic> guardianData) async {
    await post("/user/guardians/$userId", guardianData);
  }
static Future<void> deleteGuardian(String guardianId) async {
  try {
    final response = await http.delete(
      Uri.parse("$baseUrl/user/guardians/$guardianId"),
      headers: _getHeaders(),
    ).timeout(const Duration(seconds: 10));
    if (response.statusCode >= 300) throw Exception("Failed to delete guardian via API");
  } catch (e) {
    debugPrint("API Error deleteGuardian: $e");
    rethrow;
  }
}

static Future<void> updateGuardian(String guardianId, Map<String, dynamic> guardianData) async {
  try {
    final response = await http.put(
      Uri.parse("$baseUrl/user/guardians/$guardianId"),
      headers: _getHeaders(),
      body: jsonEncode(guardianData),
    ).timeout(const Duration(seconds: 10));
    if (response.statusCode >= 300) throw Exception("Failed to update guardian via API");
  } catch (e) {
    debugPrint("API Error updateGuardian: $e");
    rethrow;
  }
}

// --- Journey methods ---
  static void showServerDownPopup(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1F2B),
        title: const Row(
          children: [
            Icon(Icons.wifi_off_rounded, color: Colors.orangeAccent),
            SizedBox(width: 10),
            Text("Connection Lag", style: TextStyle(color: Colors.white)),
          ],
        ),
        content: const Text(
          "The security server is responding slowly. Emergency features may experience a slight delay. Please stay alert.",
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Understand", style: TextStyle(color: Colors.blueAccent)),
          ),
        ],
      ),
    );
  }
}
