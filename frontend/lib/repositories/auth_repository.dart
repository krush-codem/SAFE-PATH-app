import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import '../models/profile.dart';
import '../models/guardian.dart';
import '../services/api_service.dart';

/// Single source of truth for all Supabase interactions.
/// Screens and providers call this, never the client directly.
class AuthRepository {
  final SupabaseClient _client;

  AuthRepository(this._client);

  // ─── Auth state ────────────────────────────────────────────
  User? get currentUser => _client.auth.currentUser;
  Session? get currentSession => _client.auth.currentSession;
  bool get isLoggedIn => currentUser != null;

  /// Broadcast stream of auth state changes.
  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  // ─── Sign Up ───────────────────────────────────────────────
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    String fullName = '',
    String? phoneNumber,
  }) async {
    return _client.auth.signUp(
      email: email,
      password: password,
      data: {
        'full_name': fullName,
        'phone_number': phoneNumber,
      },
    );
  }

  // ─── Login ─────────────────────────────────────────────────
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<AuthResponse> signInWithPhone({
    required String phone,
    required String password,
  }) async {
    return _client.auth.signInWithPassword(
      phone: phone,
      password: password,
    );
  }

  // ─── Google OAuth ──────────────────────────────────────────
  Future<bool> signInWithGoogle() async {
    final String redirectTo = kIsWeb 
        ? Uri.base.origin 
        : 'io.supabase.safepathtest://login-callback';

    try {
      return await _client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: redirectTo,
      ).timeout(const Duration(seconds: 5), onTimeout: () {
        // On Web, a timeout often means the redirect is starting but hasn't finished.
        // Returning true here allows the UI to show a "Redirecting..." state.
        if (kIsWeb) return true;
        throw Exception('Sign in timed out. Please try again.');
      });
    } catch (e) {
      debugPrint('OAuth Error: $e');
      return false;
    }
  }

  // ─── Sign Out ──────────────────────────────────────────────
  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  // ─── Password reset ────────────────────────────────────────
  Future<void> sendPasswordResetEmail(String email) async {
    await _client.auth.resetPasswordForEmail(email);
  }

  // ─── OTP Verification ──────────────────────────────────────
  /// Sends a fresh OTP to the identifier (email or phone).
  Future<void> sendOtp({
    required String identifier,
    required bool isEmail,
  }) async {
    if (isEmail) {
      await _client.auth.signInWithOtp(email: identifier);
    } else {
      if (isLoggedIn) {
        // For logged-in users, this triggers the phoneChange OTP (for linking/verification)
        await _client.auth.updateUser(UserAttributes(phone: identifier));
      } else {
        // For logged-out users, this is a standard passwordless login
        await _client.auth.signInWithOtp(phone: identifier);
      }
    }
  }

  /// Resends signup confirmation email OTP.
  Future<void> resendSignupOtp({
    required String email,
  }) async {
    await _client.auth.resend(
      type: OtpType.signup,
      email: email,
    );
  }

  /// Verifies the OTP token against the identifier.
  Future<AuthResponse> verifyOtp({
    required String identifier,
    required String token,
    required bool isEmail,
  }) async {
    if (isEmail) {
      try {
        return await _client.auth.verifyOTP(
          type: OtpType.signup,
          token: token,
          email: identifier,
        );
      } catch (_) {
        return await _client.auth.verifyOTP(
          type: OtpType.email,
          token: token,
          email: identifier,
        );
      }
    } else {
      try {
        // First try phoneChange (for linking phone to existing email account)
        return await _client.auth.verifyOTP(
          type: OtpType.phoneChange,
          token: token,
          phone: identifier,
        );
      } catch (_) {
        // Fallback to standard sms (for signInWithOtp)
        return await _client.auth.verifyOTP(
          type: OtpType.sms,
          token: token,
          phone: identifier,
        );
      }
    }
  }

  Future<void> updateProfileAndAddPhone({
    required String fullName,
    required String phoneNumber,
  }) async {
    final user = currentUser;
    if (user == null) throw Exception('Not authenticated');

    // 1. Update user identity in Supabase Auth
    // Setting 'phone' here triggers a verification OTP to the new number
    await _client.auth.updateUser(
      UserAttributes(
        phone: phoneNumber,
        data: {
          'full_name': fullName,
        },
      ),
    );

    // 2. Update the permanent profiles table (using upsert to ensure it exists)
    await _client.from('profiles').upsert({
      'id': user.id,
      'email': user.email,
      'full_name': fullName,
      'phone_number': phoneNumber,
      'updated_at': DateTime.now().toIso8601String(),
    });

    // Note: No need for manual sendOtp call here as updateUser(phone: ...) 
    // already triggers the OTP from Supabase.
  }

  Future<String> determineInitialRoute() async {
    final user = currentUser;
    if (user == null) return '/login';

    // 1. Check if at least one primary identity is confirmed (Email or Phone)
    final isEmailVerified = user.emailConfirmedAt != null;
    final isPhoneVerified = user.phoneConfirmedAt != null;
    
    if (!isEmailVerified && !isPhoneVerified) return '/login';

    // 2. Fetch profile
    final profile = await fetchProfile();
    final isProfileComplete = profile != null &&
                             profile.fullName.isNotEmpty &&
                             (profile.phoneNumber?.isNotEmpty ?? false);

    if (!isProfileComplete) return '/complete-profile';

    // 3. Ensure Phone is verified (if they signed up with email but phone is new)
    if (!isPhoneVerified) return '/verification';

    // 4. Check lifeline setup
    final isLifelineComplete = profile.lifelineSetupComplete;
    if (!isLifelineComplete) return '/lifeline';

    return '/home';
  }

  // ─── Profile ───────────────────────────────────────────────
  /// Fetch the current user's profile.
  Future<Profile?> fetchProfile() async {
    final uid = currentUser?.id;
    if (uid == null) return null;

    final data = await ApiService.getProfile(uid);
    return data != null ? Profile.fromJson(data) : null;
  }

  /// Update profile fields.
  Future<void> updateProfile(Map<String, dynamic> updates) async {
    final uid = currentUser?.id;
    if (uid == null) throw Exception('Not authenticated');
    await ApiService.updateProfile(uid, updates);
  }

  /// Mark lifeline setup as done.
  Future<void> markLifelineComplete() async {
    await updateProfile({'lifeline_setup_complete': true});
  }

  /// Sends a heartbeat to the backend to show the user is online.
  Future<void> sendHeartbeat() async {
    await ApiService.sendHeartbeat();
  }

  // ─── Guardians / Lifeline ──────────────────────────────────
  /// Fetch all guardians for the current user.
  Future<List<Guardian>> fetchGuardians() async {
    final uid = currentUser?.id;
    if (uid == null) return [];

    try {
      final dataList = await ApiService.getGuardians(uid);
      return dataList.map((d) => Guardian.fromJson(d)).toList();
    } catch (e) {
      debugPrint("Error fetching guardians: $e");
      return [];
    }
  }

  /// Add a new guardian (max 7 enforced).
  Future<Guardian> addGuardian({
    required String fullName,
    required String phone,
    String relation = '',
  }) async {
    final uid = currentUser?.id;
    if (uid == null) throw Exception('Not authenticated');

    // Prevent user from adding themselves
    final profile = await fetchProfile();
    if (profile?.phoneNumber != null && profile!.phoneNumber == phone) {
      throw Exception('SECURITY ALERT: You cannot add your own number to your SOS circle.');
    }

    final existing = await fetchGuardians();
    if (existing.length >= 7) {
      throw Exception('Maximum 7 guardians allowed');
    }

    await ApiService.addGuardian(uid, {
      'guardian_name': fullName,
      'guardian_phone': phone,
      'relation': relation,
      'is_active': true,
    });
    
    return Guardian(
      id: '', // Temporary
      userId: uid,
      fullName: fullName,
      phone: phone,
      relation: relation,
      isActive: true,
      createdAt: DateTime.now(),
    );
  }

  /// Soft-delete a guardian.
  Future<void> removeGuardian(String guardianId) async {
    await ApiService.deleteGuardian(guardianId);
  }

  /// Hard-delete a guardian.
  Future<void> deleteGuardian(String guardianId) async {
    await ApiService.deleteGuardian(guardianId);
  }

  /// Update a guardian's details.
  Future<Guardian> updateGuardian({
    required String guardianId,
    required String fullName,
    required String phone,
    String relation = '',
  }) async {
    await ApiService.updateGuardian(guardianId, {
      'guardian_name': fullName,
      'guardian_phone': phone,
      'relation': relation,
    });
    
    // Return a fresh object
    return Guardian(
      id: guardianId,
      userId: currentUser?.id ?? '',
      fullName: fullName,
      phone: phone,
      relation: relation,
      isActive: true,
      createdAt: DateTime.now(),
    );
  }

  // ─── Account Management ─────────────────────────────────────
  /// Delete the user's data and sign out.
  /// This calls our backend which handles auth.admin deletion.
  Future<void> deleteAccount() async {
    final uid = currentUser?.id;
    if (uid == null) return;

    try {
      // 1. Call administrative backend to wipe auth and primary data
      await ApiService.deleteUserAccount(uid);
    } catch (e) {
      // Fallback: If backend fails, we try to delete what we can locally
      // Delete in order: related records first, then profile
      await _client.from('guardians').delete().eq('user_id', uid);
      await _client.from('journeys').delete().eq('user_id', uid);
      await _client.from('sos_alerts').delete().eq('user_id', uid);
      await _client.from('messages').delete().eq('sender_id', uid);
      await _client.from('messages').delete().eq('receiver_id', uid);
      await _client.from('profiles').delete().eq('id', uid);
      // Note: Auth deletion requires admin privileges, can't do from client
    }
    
    // 2. Sign out locally
    await signOut();
  }

  /// Upload a profile picture to Supabase Storage.
  /// [bytes] should be provided for Web, [filePath] for Native.
  Future<String?> uploadAvatar({String? filePath, Uint8List? bytes}) async {
    final uid = currentUser?.id;
    if (uid == null) return null;

    final String fileExt = filePath?.split('.').last ?? 'jpg';
    final fileName = '$uid/avatar.${DateTime.now().millisecondsSinceEpoch}.$fileExt';

    if (kIsWeb && bytes != null) {
      await _client.storage.from('avatars').uploadBinary(fileName, bytes);
    } else if (filePath != null) {
      // On native, we still need a way to read the file without dart:io if we want pure web compatibility
      // But for now, let's just use the bytes approach as it's most universal for image_picker
      await _client.storage.from('avatars').uploadBinary(fileName, bytes!);
    }
    
    final url = _client.storage.from('avatars').getPublicUrl(fileName);
    await updateProfile({'avatar_url': url});
    
    return url;
  }

  /// Update the user's current GPS location.
  Future<void> updateUserLocation(double lat, double lng) async {
    final uid = currentUser?.id;
    if (uid == null) return;
    await _client.from('profiles').update({
      'last_lat': lat,
      'last_lng': lng,
      'last_active': DateTime.now().toIso8601String(),
    }).eq('id', uid);
  }
}
