import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../repositories/auth_repository.dart';
import '../models/profile.dart';
import '../models/guardian.dart';

// ─── Core client provider ──────────────────────────────────────────────────
final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

// ─── Repository provider ───────────────────────────────────────────────────
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.watch(supabaseClientProvider));
});

// ─── Auth state stream ─────────────────────────────────────────────────────
/// Emits every time the auth state changes (sign in, sign out, token refresh).
final authStateProvider = StreamProvider<AuthState>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});

// ─── Current user ──────────────────────────────────────────────────────────
final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(authRepositoryProvider).currentUser;
});

// ─── Is authenticated ──────────────────────────────────────────────────────
final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(currentUserProvider) != null;
});

// ─── Profile provider ──────────────────────────────────────────────────────
/// Fetches and caches the current user's profile from Supabase.
final profileProvider = FutureProvider<Profile?>((ref) async {
  // Re-run whenever auth state changes
  ref.watch(authStateProvider);
  final repo = ref.watch(authRepositoryProvider);
  if (!repo.isLoggedIn) return null;
  return repo.fetchProfile();
});

// ─── Registration completeness check ──────────────────────────────────────
/// Returns true if the user has completed the SOS setup (lifeline).
final isRegistrationCompleteProvider = Provider<bool>((ref) {
  final profileAsync = ref.watch(profileProvider);
  return profileAsync.value?.lifelineSetupComplete ?? false;
});

// ─── Guardians provider ────────────────────────────────────────────────────
/// Fetches and caches the user's guardian (SOS contact) list.
final guardiansProvider = FutureProvider<List<Guardian>>((ref) async {
  ref.watch(authStateProvider);
  final repo = ref.watch(authRepositoryProvider);
  if (!repo.isLoggedIn) return [];
  return repo.fetchGuardians();
});

// ─── Auth notifier ─────────────────────────────────────────────────────────
/// Wraps sign-in / sign-up / sign-out with loading state.
class AuthNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  AuthRepository get _repo => ref.read(authRepositoryProvider);

  Future<void> signUp({
    required String email,
    required String password,
    String fullName = '',
    String? phoneNumber,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _repo
        .signUp(
          email: email,
          password: password,
          fullName: fullName,
          phoneNumber: phoneNumber,
        )
        .then((_) {}));
  }

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
        () => _repo.signIn(email: email, password: password).then((_) {}));
  }

  Future<void> signInWithPhone({
    required String phone,
    required String password,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
        () => _repo.signInWithPhone(phone: phone, password: password).then((_) {}));
  }

  /// Signs in with Google. Returns true if successful.
  Future<bool> signInWithGoogle() async {
    state = const AsyncLoading();
    bool success = false;
    state = await AsyncValue.guard(() async {
      final res = await _repo.signInWithGoogle();
      if (res) success = true;
    });
    return success;
  }

  Future<void> signOut() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_repo.signOut);
  }

  Future<void> deleteAccount() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_repo.deleteAccount);
  }

  Future<void> updateProfile(Map<String, dynamic> updates) async {

    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _repo.updateProfile(updates));
    // Refresh profile provider
    ref.invalidate(profileProvider);
  }

  Future<void> updateProfileAndAddPhone({
    required String fullName,
    required String phoneNumber,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _repo.updateProfileAndAddPhone(
      fullName: fullName,
      phoneNumber: phoneNumber,
    ));
    ref.invalidate(profileProvider);
  }

  Future<String> determineInitialRoute() async {
    state = const AsyncLoading();
    try {
      final route = await _repo.determineInitialRoute();
      state = const AsyncData(null);
      return route;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }

  Future<void> uploadAvatar({String? filePath, Uint8List? bytes}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
        () => _repo.uploadAvatar(filePath: filePath, bytes: bytes));
    ref.invalidate(profileProvider);
  }

  Future<void> sendOtp({
    required String identifier,
    required bool isEmail,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
        () => _repo.sendOtp(identifier: identifier, isEmail: isEmail));
  }

  /// Resends the signup OTP to email.
  Future<void> resendSignupOtp({
    required String email,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
        () => _repo.resendSignupOtp(email: email));
  }

  /// Verifies the OTP [token] against [identifier].
  /// Returns true on success, false on failure (so UI can count attempts).
  Future<bool> verifyOtp({
    required String identifier,
    required String token,
    required bool isEmail,
  }) async {
    state = const AsyncLoading();
    bool success = false;
    state = await AsyncValue.guard(() async {
      await _repo.verifyOtp(
          identifier: identifier, token: token, isEmail: isEmail);
      success = true;
    });
    return success;
  }
}

final authNotifierProvider =
    AsyncNotifierProvider<AuthNotifier, void>(AuthNotifier.new);

/// Tracks if the user is currently undergoing signup email OTP verification.
class SignupVerificationPendingNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void set(bool value) {
    state = value;
  }
}

final signupVerificationPendingProvider =
    NotifierProvider<SignupVerificationPendingNotifier, bool>(
        SignupVerificationPendingNotifier.new);

// ─── Guardian notifier ─────────────────────────────────────────────────────
/// Manages adding / removing guardians and saving the lifeline.
class GuardianNotifier extends AsyncNotifier<List<Guardian>> {
  @override
  Future<List<Guardian>> build() async {
    return ref.watch(authRepositoryProvider).fetchGuardians();
  }

  AuthRepository get _repo => ref.read(authRepositoryProvider);

  Future<void> addGuardian({
    required String fullName,
    required String phone,
    String relation = '',
  }) async {
    final current = state.value ?? [];
    if (current.length >= 7) {
      throw Exception('Maximum 7 guardians allowed');
    }
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await _repo.addGuardian(
          fullName: fullName, phone: phone, relation: relation);
      return _repo.fetchGuardians();
    });
  }

  Future<void> removeGuardian(String guardianId) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await _repo.deleteGuardian(guardianId);
      return _repo.fetchGuardians();
    });
  }

  Future<void> updateGuardian({
    required String guardianId,
    required String fullName,
    required String phone,
    String relation = '',
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await _repo.updateGuardian(
        guardianId: guardianId,
        fullName: fullName,
        phone: phone,
        relation: relation,
      );
      return _repo.fetchGuardians();
    });
  }

  /// Save all pending guardians (local list) and mark lifeline complete.
  Future<void> saveAndComplete(List<Map<String, String>> pendingGuardians) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      for (final g in pendingGuardians) {
        await _repo.addGuardian(
          fullName: g['name'] ?? '',
          phone: g['phone'] ?? '',
          relation: g['relation'] ?? '',
        );
      }
      await _repo.markLifelineComplete();
      return _repo.fetchGuardians();
    });
  }
}

final guardianNotifierProvider =
    AsyncNotifierProvider<GuardianNotifier, List<Guardian>>(
        GuardianNotifier.new);
