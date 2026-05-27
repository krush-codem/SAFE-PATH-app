import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../providers/auth_provider.dart';
import '../screens/splash_screen.dart';
import '../screens/welcome_screen.dart';
import '../screens/login_page_screen.dart';
import '../screens/signup_screen.dart';
import '../screens/lifeline_screen.dart';
import '../screens/main_layout.dart';
import '../screens/home_dashboard.dart';
import '../screens/physical_safety.dart';
import '../screens/aegis_guard_screen.dart';
import '../screens/location_picker_screen.dart';
import '../screens/timer_setup_screen.dart';
import '../screens/safety_check_screen.dart';
import '../screens/active_journey_screen.dart';
import '../screens/safe_circle_chat_screen.dart';

import '../screens/settings_screen.dart';
import '../screens/edit_profile_screen.dart';
import '../screens/appearance_screen.dart';
import '../screens/history_screen.dart';
import '../screens/verification_screen.dart';
import '../screens/complete_profile_screen.dart';
import '../screens/manage_guardians_screen.dart';
import '../screens/privacy_screen.dart';
import '../screens/manage_location_sharing_screen.dart';
import '../screens/location_permissions_screen.dart';
import '../screens/microphone_access_screen.dart';
import '../screens/contacts_access_screen.dart';

// ─── Route constants ──────────────────────────────────────────────────────
class AppRoutes {
  static const splash        = '/';
  static const welcome       = '/welcome';
  static const login         = '/login';
  static const signup        = '/signup';
  static const completeProfile = '/complete-profile';
  static const verification  = '/verification';
  static const lifeline      = '/lifeline';
  static const home          = '/home';
  static const physical = '/physical';
  static const cyber    = '/cyber';
  static const settings = '/settings';
  static const editProfile = '/settings/edit_profile';
  static const appearance = '/settings/appearance';
  static const history = '/settings/history';
  static const manageGuardians = '/settings/manage_guardians';
  static const privacy = '/settings/privacy';
  static const manageLocationSharing = '/settings/privacy/manage_location';
  static const locationPermissions = '/settings/privacy/location_permissions';
  static const microphoneAccess = '/settings/privacy/microphone';
  static const contactsAccess = '/settings/privacy/contacts';
  static const locationPicker = '/location_picker';
  static const timerSetup = '/timer_setup';
  static const safetyCheck = '/safety_check';
  static const activeJourney = '/active_journey';
  static const safeCircleChat = '/safe_circle_chat';
}

// ─── Router provider ──────────────────────────────────────────────────────
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: _AuthChangeNotifier(ref),
    redirect: (context, state) {
      final session = Supabase.instance.client.auth.currentSession;
      final isLoggedIn = session != null;
      final path = state.matchedLocation;

      // Always allow splash (it auto-redirects)
      if (path == AppRoutes.splash) return null;

      // Enforce lock if currently undergoing email OTP verification on signup
      final signupPending = ref.read(signupVerificationPendingProvider);
      if (signupPending) {
        if (path != AppRoutes.signup) {
          return AppRoutes.signup;
        }
        return null;
      }

      // Not logged in → only allow auth screens
      final publicRoutes = [
        AppRoutes.welcome,
        AppRoutes.login,
        AppRoutes.signup,
      ];
      if (!isLoggedIn && !publicRoutes.contains(path)) {
        // Special case: Allow verification even if not logged in (some Supabase configs)
        if (path == AppRoutes.verification) return null;
        return AppRoutes.welcome;
      }

      // ── Logged in user logic ──────────────────
      if (isLoggedIn) {
        final user = session.user;
        
        // 1. Ensure at least one primary identity is confirmed
        final isEmailVerified = user.emailConfirmedAt != null;
        final isPhoneVerified = user.phoneConfirmedAt != null;

        if (!isEmailVerified && !isPhoneVerified) {
          if (!publicRoutes.contains(path)) {
            return AppRoutes.login;
          }
          return null;
        }

        // Wait for profile provider to load
        final profileAsync = ref.read(profileProvider);
        if (profileAsync.isLoading) return null;

        final profile = profileAsync.value;
        final hasProfile = profile != null;
        final isProfileComplete = hasProfile && 
                                 profile.fullName.isNotEmpty && 
                                 (profile.phoneNumber?.isNotEmpty ?? false);

        // 2. Force profile completion if missing name or phone number
        if (!isProfileComplete) {
          if (path != AppRoutes.completeProfile) {
            return AppRoutes.completeProfile;
          }
          return null;
        }

        // 3. Force Phone OTP verification if phone is not confirmed in Supabase auth
        if (!isPhoneVerified) {
          if (path != AppRoutes.verification && path != AppRoutes.completeProfile) {
            return AppRoutes.verification;
          }
          return null;
        }

        // 4. Force lifeline setup if guardians/SOS circle is incomplete
        final isLifelineComplete = profile.lifelineSetupComplete;
        if (!isLifelineComplete) {
          if (path != AppRoutes.lifeline) {
            return AppRoutes.lifeline;
          }
          return null;
        }

        // 5. Prevent accessing onboarding/auth pages once fully verified and setup
        final onboardingRoutes = [
          AppRoutes.welcome,
          AppRoutes.login,
          AppRoutes.signup,
          AppRoutes.completeProfile,
          AppRoutes.verification,
          AppRoutes.lifeline,
        ];
        if (onboardingRoutes.contains(path)) {
          return AppRoutes.home;
        }
      }

      return null;
    },
    routes: [
      // ── Splash ────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),

      // ── Welcome ───────────────────────────────────────────
      GoRoute(
        path: AppRoutes.welcome,
        builder: (context, state) => const WelcomeScreen(),
      ),

      // ── Login ─────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginPageScreen(),
      ),

      // ── Sign Up ───────────────────────────────────────────
      GoRoute(
        path: AppRoutes.signup,
        builder: (context, state) {
          final data = state.extra as Map<String, dynamic>?;
          return SignUpScreen(initialData: data);
        },
      ),

      // ── Complete Profile ──────────────────────────────────
      GoRoute(
        path: AppRoutes.completeProfile,
        builder: (context, state) => const CompleteProfileScreen(),
      ),

      // ── Verification ──────────────────────────────────────
       GoRoute(
        path: AppRoutes.verification,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return VerificationScreen(
            name: extra?['name'] as String? ?? '',
            email: extra?['email'] as String? ?? '',
            phone: extra?['phone'] as String? ?? '',
          );
        },
      ),

      // ── Lifeline setup ────────────────────────────────────
      GoRoute(
        path: AppRoutes.lifeline,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return LifelineScreen(
            initialName: extra?['name'] as String?,
            initialPhone: extra?['phone'] as String?,
          );
        },
      ),

      // ── Main app shell ─────────────────────────────────────
      ShellRoute(
        builder: (_, __, child) => MainLayout(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.home,
            builder: (context, state) => const HomeDashboard(),
          ),
          GoRoute(
            path: AppRoutes.locationPicker,
            builder: (context, state) {
              final isOrigin = state.uri.queryParameters['isOrigin'] == 'true';
              return LocationPickerScreen(isOrigin: isOrigin);
            },
          ),
          GoRoute(
            path: AppRoutes.safeCircleChat,
            builder: (context, state) => const SafeCircleChatScreen(),
          ),
          GoRoute(
            path: AppRoutes.physical,
            builder: (context, state) => const PhysicalSafetyScreen(),
          ),
          GoRoute(
            path: AppRoutes.cyber,
            builder: (context, state) => const AegisGuardScreen(),
          ),
          GoRoute(
            path: AppRoutes.settings,
            builder: (context, state) => const SettingsScreen(),
            routes: [
              GoRoute(
                path: 'edit_profile',
                builder: (context, state) => const EditProfileScreen(),
              ),
              GoRoute(
                path: 'appearance',
                builder: (context, state) => const AppearanceScreen(),
              ),
              GoRoute(
                path: 'history',
                builder: (context, state) => const HistoryScreen(),
              ),
              GoRoute(
                path: 'manage_guardians',
                builder: (context, state) => const ManageGuardiansScreen(),
              ),
              GoRoute(
                path: 'privacy',
                builder: (context, state) => const PrivacyScreen(),
              ),
              GoRoute(
                path: 'privacy/manage_location',
                builder: (context, state) => const ManageLocationSharingScreen(),
              ),
              GoRoute(
                path: 'privacy/location_permissions',
                builder: (context, state) => const LocationPermissionsScreen(),
              ),
              GoRoute(
                path: 'privacy/microphone',
                builder: (context, state) => const MicrophoneAccessScreen(),
              ),
              GoRoute(
                path: 'privacy/contacts',
                builder: (context, state) => const ContactsAccessScreen(),
              ),
            ],
          ),
        ],
      ),
      // ── Journey Flow (Post-Setup) ──────────────────────────
      GoRoute(
        path: AppRoutes.timerSetup,
        builder: (context, state) => const TimerSetupScreen(),
      ),
      GoRoute(
        path: AppRoutes.safetyCheck,
        builder: (context, state) => const SafetyCheckScreen(),
      ),
      GoRoute(
        path: AppRoutes.activeJourney,
        builder: (context, state) => const ActiveJourneyScreen(),
      ),
    ],
  );
});

// ─── Listenable wrapper for auth changes ─────────────────────────────────
/// Tells GoRouter to re-evaluate its redirect whenever auth state changes.
class _AuthChangeNotifier extends ChangeNotifier {
  _AuthChangeNotifier(Ref ref) {
    ref.listen(authStateProvider, (_, __) => notifyListeners());
    ref.listen(profileProvider, (_, __) => notifyListeners());
    ref.listen(isRegistrationCompleteProvider, (_, __) => notifyListeners());
    ref.listen(signupVerificationPendingProvider, (_, __) => notifyListeners());
  }
}
