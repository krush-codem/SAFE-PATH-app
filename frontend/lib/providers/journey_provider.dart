import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../providers/repository_providers.dart';
import '../providers/auth_provider.dart';
import '../models/journey.dart' show Journey, JourneyType;
import '../services/api_service.dart';

enum JourneyStatus { inactive, active, pinging, sosTriggered, completed }

class JourneyState {
  final String? origin;
  final String? destination;
  final int timerIntervalMinutes;
  final int? timeRemainingSeconds; // Countdown for Safety Check
  final int? nextCheckCountdownSeconds; // Countdown to NEXT check
  final String currentTime;
  final JourneyStatus status;

  final double? currentLat;
  final double? currentLng;
  final DateTime? journeyStartTime;
  final int sosBroadcastRemaining;
  final List<Map<String, dynamic>> guardianLocations; // [{id, lat, lng, name}]
  final List<LatLng>? sosRoutePoints; // Points for the polyline
  final DateTime? lastOtpVerificationTime;
  final List<String> locationPermissionIds;
  final String? generatedOtp;
  final int otpTriesLeft;
  final bool isArrivalOtp;
  final bool hasSentPreOtp;

  const JourneyState({
    this.origin,
    this.destination,
    this.timerIntervalMinutes = 30,
    this.timeRemainingSeconds,
    this.nextCheckCountdownSeconds,
    this.currentTime = '',
    this.status = JourneyStatus.inactive,
    this.currentLat,
    this.currentLng,
    this.journeyStartTime,
    this.sosBroadcastRemaining = 0,
    this.guardianLocations = const [],
    this.sosRoutePoints,
    this.lastOtpVerificationTime,
    this.locationPermissionIds = const [],
    this.generatedOtp,
    this.otpTriesLeft = 3,
    this.isArrivalOtp = false,
    this.hasSentPreOtp = false,
  });

  JourneyState copyWith({
    String? origin,
    String? destination,
    int? timerIntervalMinutes,
    int? timeRemainingSeconds,
    int? nextCheckCountdownSeconds,
    String? currentTime,
    JourneyStatus? status,
    double? currentLat,
    double? currentLng,
    DateTime? journeyStartTime,
    int? sosBroadcastRemaining,
    List<Map<String, dynamic>>? guardianLocations,
    List<LatLng>? sosRoutePoints,
    DateTime? lastOtpVerificationTime,
    List<String>? locationPermissionIds,
    String? generatedOtp,
    int? otpTriesLeft,
    bool? isArrivalOtp,
    bool? hasSentPreOtp,
  }) {
    return JourneyState(
      origin: origin ?? this.origin,
      destination: destination ?? this.destination,
      timerIntervalMinutes: timerIntervalMinutes ?? this.timerIntervalMinutes,
      timeRemainingSeconds: timeRemainingSeconds ?? this.timeRemainingSeconds,
      nextCheckCountdownSeconds: nextCheckCountdownSeconds ?? this.nextCheckCountdownSeconds,
      currentTime: currentTime ?? this.currentTime,
      status: status ?? this.status,
      currentLat: currentLat ?? this.currentLat,
      currentLng: currentLng ?? this.currentLng,
      journeyStartTime: journeyStartTime ?? this.journeyStartTime,
      sosBroadcastRemaining: sosBroadcastRemaining ?? this.sosBroadcastRemaining,
      guardianLocations: guardianLocations ?? this.guardianLocations,
      sosRoutePoints: sosRoutePoints ?? this.sosRoutePoints,
      lastOtpVerificationTime: lastOtpVerificationTime ?? this.lastOtpVerificationTime,
      locationPermissionIds: locationPermissionIds ?? this.locationPermissionIds,
      generatedOtp: generatedOtp ?? this.generatedOtp,
      otpTriesLeft: otpTriesLeft ?? this.otpTriesLeft,
      isArrivalOtp: isArrivalOtp ?? this.isArrivalOtp,
      hasSentPreOtp: hasSentPreOtp ?? this.hasSentPreOtp,
    );
  }
}

class JourneyNotifier extends Notifier<JourneyState> {
  Timer? _ticker;
  Timer? _locationSyncTimer;

  @override
  JourneyState build() {
    Future.microtask(() {
      _startClockTicker();
      fetchCurrentLocation();
    });
    return JourneyState(currentTime: _formatNow());
  }

  Future<void> fetchCurrentLocation() async {
    try {
      bool serviceEnabled;
      LocationPermission permission;

      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return Future.error('Location services are disabled.');
      }

      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw 'Location permissions are denied';
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        throw 'Location permissions are permanently denied, we cannot request permissions.';
      }

      final position = await Geolocator.getCurrentPosition();
      state = state.copyWith(
        currentLat: position.latitude,
        currentLng: position.longitude,
        origin: state.origin ?? "Current Location",
      );
    } catch (e) {
      print("Error fetching location: $e");
    }
  }

  String _formatNow() => DateFormat('hh:mm a').format(DateTime.now());

  void _startClockTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (timer) {
      state = state.copyWith(currentTime: _formatNow());
      
      if (state.status == JourneyStatus.active && state.nextCheckCountdownSeconds != null) {
        if (state.nextCheckCountdownSeconds! > 0) {
           state = state.copyWith(nextCheckCountdownSeconds: state.nextCheckCountdownSeconds! - 1);
        } else {
           // Interval ended -> Trigger Safety Check
           state = state.copyWith(
             status: JourneyStatus.pinging,
             timeRemainingSeconds: 300, // 5 minutes to verify
             otpTriesLeft: 3,
           );
        }
      } else if (state.status == JourneyStatus.pinging && state.timeRemainingSeconds != null) {
        if (state.timeRemainingSeconds! > 0) {
           state = state.copyWith(timeRemainingSeconds: state.timeRemainingSeconds! - 1);
        } else {
           // 5 minutes expired -> Trigger SOS
           triggerSOS();
        }
      }
    });
  }

  void setRouting(String origin, String destination) {
    state = state.copyWith(origin: origin, destination: destination);
  }

  void setTimerInterval(int minutes) {
    state = state.copyWith(timerIntervalMinutes: minutes);
  }

  void toggleLocationPermission(String userId) {
    final current = List<String>.from(state.locationPermissionIds);
    if (current.contains(userId)) {
      current.remove(userId);
    } else {
      current.add(userId);
    }
    state = state.copyWith(locationPermissionIds: current);
  }

  Future<void> startJourney() async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    try {
      final repo = ref.read(journeyRepositoryProvider);
      
      // Start the backend safety loop
      await repo.startSafetyJourney(user.id, state.timerIntervalMinutes);

      state = state.copyWith(
        status: JourneyStatus.active, // Start in active state, countdown begins
        nextCheckCountdownSeconds: state.timerIntervalMinutes * 60,
        journeyStartTime: DateTime.now(),
        otpTriesLeft: 3,
        lastOtpVerificationTime: null,
        timeRemainingSeconds: null,
      );
      
      _startLocationSync();
    } catch (e) {
      print("Error starting journey: $e");
    }
  }

  Future<void> stopJourney({bool isCompleted = false}) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    final origin = state.origin;
    final dest = state.destination;

    try {
      final repo = ref.read(journeyRepositoryProvider);
      
      // Tell backend to stop
      await repo.stopSafetyJourney(user.id);
      
      if (state.status == JourneyStatus.sosTriggered) {
         await ApiService.post('/sos/stop', {'user_id': user.id});
      }

      if (isCompleted && origin != null && dest != null) {
        final journey = Journey(
          id: '',
          userId: user.id,
          origin: origin,
          destination: dest,
          status: 'completed',
          duration: '${DateTime.now().difference(state.journeyStartTime ?? DateTime.now()).inMinutes} mins',
          createdAt: DateTime.now(),
          hadAlert: state.status == JourneyStatus.sosTriggered,
        );
        await repo.saveJourney(journey);
        ref.invalidate(historyProvider); // Immediate refresh
      }

      _locationSyncTimer?.cancel();
      
      state = JourneyState(
        currentTime: _formatNow(),
        status: JourneyStatus.inactive,
      );
    } catch (e) {
      print("Error stopping journey: $e");
    }
  }

  void cancelJourney() {
    stopJourney(isCompleted: false);
  }

  Future<bool> verifySafetyOtp(String otp) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return false;

    try {
      final repo = ref.read(journeyRepositoryProvider);
      final result = await repo.verifySafetyOtp(user.id, otp);

      if (result['success'] == true) {
        state = state.copyWith(
          status: JourneyStatus.active, // Back to active tracking
          lastOtpVerificationTime: DateTime.now(),
          nextCheckCountdownSeconds: state.timerIntervalMinutes * 60,
          timeRemainingSeconds: null, // Clear safety check countdown
          otpTriesLeft: 3,
        );
        return true;
      } else {
        final remaining = state.otpTriesLeft - 1;
        state = state.copyWith(otpTriesLeft: remaining);
        
        if (remaining <= 0 || result['message'].contains('SOS Triggering')) {
          triggerSOS();
        }
        return false;
      }
    } catch (e) {
      print("Error verifying OTP: $e");
      return false;
    }
  }

  void triggerSOS() async {
    if (state.status == JourneyStatus.sosTriggered) return;
    
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) return;

    state = state.copyWith(status: JourneyStatus.sosTriggered);

    try {
      await ApiService.post('/sos/trigger', {
        'user_id': currentUser.id,
        'latitude': state.currentLat ?? 0.0,
        'longitude': state.currentLng ?? 0.0,
      });
      print("SOS Triggered via Backend successfully.");
    } catch (e) {
      print("SOS Trigger Error: $e");
    }
  }

  void _startLocationSync() {
    _locationSyncTimer?.cancel();
    _locationSyncTimer = Timer.periodic(const Duration(seconds: 10), (timer) async {
       if (state.status == JourneyStatus.inactive) {
         timer.cancel();
         return;
       }
       await _syncLocation();
    });
  }

  Future<void> _syncLocation() async {
     try {
       final authRepo = ref.read(authRepositoryProvider);
       
       // Fetch real position
       final position = await Geolocator.getCurrentPosition(
         locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
       );
       
       final double lat = position.latitude;
       final double lng = position.longitude;
       
       await authRepo.updateUserLocation(lat, lng);
       
       final response = await ref.read(supabaseClientProvider)
          .from('profiles')
          .select('id, full_name, last_lat, last_lng, avatar_url')
          .neq('id', ref.read(currentUserProvider)?.id ?? '')
          .not('last_lat', 'is', null);
       
       final List<Map<String, dynamic>> locs = (response as List).map((row) => {
         'id': row['id'],
         'name': row['full_name'],
         'lat': row['last_lat'],
         'lng': row['last_lng'],
         'avatar_url': row['avatar_url'],
       }).toList();
       
       state = state.copyWith(
         currentLat: lat, 
         currentLng: lng,
         guardianLocations: locs,
       );

       if (state.status == JourneyStatus.sosTriggered && locs.isNotEmpty) {
          _calculateSOSRoute(LatLng(lat, lng), locs);
       }
     } catch (e) {
       print("Sync error: $e");
     }
  }

  Future<void> _calculateSOSRoute(LatLng userLoc, List<Map<String, dynamic>> guardians) async {
    try {
      Map<String, dynamic>? nearest;
      double minDist = double.infinity;
      
      for (var g in guardians) {
        final double d = (g['lat'] - userLoc.latitude).abs() + (g['lng'] - userLoc.longitude).abs();
        if (d < minDist) {
          minDist = d;
          nearest = g;
        }
      }

      if (nearest != null) {
        final directionsRepo = ref.read(directionsRepositoryProvider);
        final result = await directionsRepo.getDirections(
          origin: userLoc, 
          destination: LatLng(nearest['lat'], nearest['lng'])
        );
        
        if (result != null) {
          state = state.copyWith(sosRoutePoints: result['polyline_points']);
        }
      }
    } catch (e) {
       print("Routing error: $e");
    }
  }

  Future<void> clearHistory() async {
     await ref.read(journeyRepositoryProvider).clearHistory();
     ref.invalidate(historyProvider);
  }
  
  /// Call this to refresh history immediately (e.g., after completing a journey)
  void refreshHistory() {
    ref.invalidate(historyProvider);
  }
}

final journeyProvider = NotifierProvider<JourneyNotifier, JourneyState>(() {
  return JourneyNotifier();
});

final journeyFilterProvider = Provider<ValueNotifier<JourneyType>>((ref) {
  return ValueNotifier<JourneyType>(JourneyType.all);
});

final historyProvider = StreamProvider<List<Journey>>((ref) async* {
  final repo = ref.watch(journeyRepositoryProvider);
  
  // Initial fetch
  yield await repo.fetchJourneys();
  
  // Auto-refresh every 5 seconds while screen is active
  await for (final _ in Stream.periodic(const Duration(seconds: 5))) {
    yield await repo.fetchJourneys();
  }
});

final filteredHistoryProvider = Provider<AsyncValue<List<Journey>>>((ref) {
  final filterNotifier = ref.watch(journeyFilterProvider);
  final filter = filterNotifier.value;
  final historyAsync = ref.watch(historyProvider);
  
  return historyAsync.when(
    data: (journeys) {
      List<Journey> filtered;
      switch (filter) {
        case JourneyType.secure:
          filtered = journeys.where((j) => j.isSecure).toList();
          break;
        case JourneyType.alert:
          filtered = journeys.where((j) => j.hasAlert).toList();
          break;
        case JourneyType.all:
        default:
          filtered = journeys;
          break;
      }
      return AsyncValue.data(filtered);
    },
    loading: () => const AsyncValue.loading(),
    error: (err, stack) => AsyncValue.error(err, stack),
  );
});

final journeyStatsProvider = Provider<Map<String, dynamic>>((ref) {
  final historyAsync = ref.watch(historyProvider);
  
  return historyAsync.when(
    data: (journeys) {
      final total = journeys.length;
      final secure = journeys.where((j) => j.isSecure).length;
      final alerts = journeys.where((j) => j.hasAlert).length;
      final completed = journeys.where((j) => j.isSuccessful).length;
      final arrivalRate = total > 0 ? (completed / total * 100).round() : 0;
      
      return {
        'total': total,
        'secure': secure,
        'alerts': alerts,
        'completed': completed,
        'arrivalRate': arrivalRate,
      };
    },
    loading: () => {'total': 0, 'secure': 0, 'alerts': 0, 'completed': 0, 'arrivalRate': 0},
    error: (_, __) => {'total': 0, 'secure': 0, 'alerts': 0, 'completed': 0, 'arrivalRate': 0},
  );
});
