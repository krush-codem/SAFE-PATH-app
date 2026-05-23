import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../providers/journey_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/dynamic_ui.dart';

class ActiveJourneyScreen extends ConsumerStatefulWidget {
  const ActiveJourneyScreen({super.key});

  @override
  ConsumerState<ActiveJourneyScreen> createState() => _ActiveJourneyScreenState();
}

class _ActiveJourneyScreenState extends ConsumerState<ActiveJourneyScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  GoogleMapController? _mapController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this, initialIndex: 1); // Start on LIVE_MAP
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final journeyState = ref.watch(journeyProvider);
    final isJourneyActive = journeyState.status != JourneyStatus.inactive;
    final isSOSActive = journeyState.status == JourneyStatus.sosTriggered;
    final profileAsync = ref.watch(profileProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: isSOSActive ? Colors.red.withValues(alpha: 0.2) : Colors.black,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20), onPressed: () => context.pop()),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isSOSActive ? 'SOS: EMERGENCY PROTOCOL' : 'Safe Path Active', 
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)
            ),
            if (isSOSActive) 
              const Text('CALCULATING SHORTEST ROUTE', style: TextStyle(color: Colors.redAccent, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
          ],
        ),
        actions: [
          profileAsync.when(
            data: (profile) => Padding(
              padding: const EdgeInsets.only(right: 16),
              child: UserAvatar(
                url: profile?.avatarUrl,
                name: profile?.fullName,
                size: 32,
              ),
            ),
            loading: () => const Padding(
              padding: EdgeInsets.only(right: 16),
              child: SkeletonBox(width: 32, height: 32, shape: BoxShape.circle),
            ),
            error: (_, __) => const Padding(
              padding: EdgeInsets.only(right: 16),
              child: UserAvatar(size: 32),
            ),
          ),
        ],
      ),
      body: !isJourneyActive 
        ? const Center(child: Text('No Active Journey.\nStart a journey to see mapping and SOS tools.', style: TextStyle(color: Colors.white38), textAlign: TextAlign.center))
        : TabBarView(
            controller: _tabController,
            physics: const NeverScrollableScrollPhysics(), 
            children: [
              // Tab 0: Chat & Stories
              _ChatTab(journeyState: journeyState),
              
              // Tab 1: Live Map (Primary)
              _MapTab(
                journeyState: journeyState, 
                onMapCreated: (controller) => _mapController = controller
              ),
              
              // Tab 2: Settings (Placeholder)
              const Center(child: Text('Settings Coming Soon', style: TextStyle(color: Colors.white24))),
            ],
          ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: const BoxDecoration(
          color: Colors.black, 
          border: Border(top: BorderSide(color: Colors.white10))
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _NavBarItem(icon: Icons.chat_bubble_outline, label: 'CHAT', isActive: _tabController.index == 0, onTap: () => setState(() => _tabController.index = 0)),
            _NavBarItem(icon: Icons.explore_outlined, label: 'LIVE_MAP', isActive: _tabController.index == 1, onTap: () => setState(() => _tabController.index = 1)),
            _NavBarItem(icon: Icons.settings_outlined, label: 'SETTING', isActive: _tabController.index == 2, onTap: () => setState(() => _tabController.index = 2)),
          ],
        ),
      ),
    );
  }
}

class _MapTab extends ConsumerWidget {
  final JourneyState journeyState;
  final Function(GoogleMapController) onMapCreated;

  const _MapTab({required this.journeyState, required this.onMapCreated});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final LatLng userPos = LatLng(journeyState.currentLat ?? 0.0, journeyState.currentLng ?? 0.0);
    
    // Create markers for guardians with permission
    final Set<Marker> markers = journeyState.guardianLocations
      .where((g) => journeyState.locationPermissionIds.contains(g['id']))
      .map((g) {
        return Marker(
          markerId: MarkerId(g['id']),
          position: LatLng(g['lat'], g['lng']),
          infoWindow: InfoWindow(title: g['name']),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        );
      }).toSet();

    // User marker
    markers.add(Marker(
      markerId: const MarkerId('user'),
      position: userPos,
      infoWindow: const InfoWindow(title: 'You'),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
    ));

    // Polylines for SOS route
    final Set<Polyline> polylines = {};
    if (journeyState.sosRoutePoints != null) {
      polylines.add(Polyline(
        polylineId: const PolylineId('sos_route'),
        points: journeyState.sosRoutePoints!,
        color: Colors.redAccent,
        width: 5,
      ));
    }

    return Stack(
      children: [
        GoogleMap(
          initialCameraPosition: CameraPosition(target: userPos, zoom: 15),
          onMapCreated: (controller) {
            controller.setMapStyle(_darkMapStyle);
            onMapCreated(controller);
          },
          markers: markers,
          polylines: polylines,
          myLocationEnabled: true,
          myLocationButtonEnabled: true,
          zoomControlsEnabled: false,
        ),
        
        // Safety Progress HUD
        if (!kIsWeb || journeyState.status == JourneyStatus.pinging) // Only show most critical overlay on Web
          Positioned(
            bottom: 24,
            left: 16,
            right: 16,
            child: _SafetyStatusCard(journeyState: journeyState),
          ),

        // SOS Overlay if active
        if (journeyState.status == JourneyStatus.sosTriggered)
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: GlassCard(
              opacity: 0.9,
              padding: const EdgeInsets.all(16),
              border: Border.all(color: Colors.redAccent, width: 2),
              child: Row(
                children: [
                  const Icon(Icons.warning_rounded, color: Colors.white, size: 28),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('SHORTEST PATH TO SAFETY', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        Text('Navigating to nearest Safe Point...', style: TextStyle(color: Colors.white70, fontSize: 10)),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () => ref.read(journeyProvider.notifier).stopJourney(),
                    child: const Text('CANCEL SOS', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                  )
                ],
              ),
            ),
          ),
      ],
    );
  }

  static const String _darkMapStyle = '''
[
  {
    "elementType": "geometry",
    "stylers": [{"color": "#000000"}]
  },
  {
    "elementType": "labels.text.fill",
    "stylers": [{"color": "#888888"}]
  },
  {
    "elementType": "labels.text.stroke",
    "stylers": [{"color": "#000000"}]
  },
  {
    "featureType": "administrative.locality",
    "elementType": "labels.text.fill",
    "stylers": [{"color": "#B87333"}]
  },
  {
    "featureType": "poi",
    "elementType": "labels.text.fill",
    "stylers": [{"color": "#B87333"}]
  },
  {
    "featureType": "poi.park",
    "elementType": "geometry",
    "stylers": [{"color": "#111111"}]
  },
  {
    "featureType": "road",
    "elementType": "geometry",
    "stylers": [{"color": "#222222"}]
  },
  {
    "featureType": "road",
    "elementType": "geometry.stroke",
    "stylers": [{"color": "#111111"}]
  },
  {
    "featureType": "water",
    "elementType": "geometry",
    "stylers": [{"color": "#000B1A"}]
  }
]
''';
}

class _ChatTab extends ConsumerWidget {
  final JourneyState journeyState;
  const _ChatTab({required this.journeyState});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Safe Stories', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          const Text('TRANSIENT: DELETES AFTER JOURNEY', style: TextStyle(color: Colors.white38, fontSize: 10, letterSpacing: 1.5)),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _StoryItem(isAdd: true, label: 'Your Story', onTap: () {}),
                ...journeyState.guardianLocations
                  .where((g) => journeyState.locationPermissionIds.contains(g['id']))
                  .map((g) => _StoryItem(label: g['name'])),
              ],
            ),
          ),
          const SizedBox(height: 32),
          const Text('Active Threads', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          ...journeyState.guardianLocations.map((g) {
            final hasPermission = journeyState.locationPermissionIds.contains(g['id']);
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _ThreadItem(
                name: g['name'], 
                message: hasPermission ? 'Live Location Tracking...' : 'Permission Required', 
                time: 'Now', 
                active: true,
                hasPermission: hasPermission,
                onToggle: (val) {
                  ref.read(journeyProvider.notifier).toggleLocationPermission(g['id']);
                },
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _StoryItem extends StatelessWidget {
  final bool isAdd;
  final String? imageUrl;
  final String label;
  final VoidCallback? onTap;
  const _StoryItem({this.isAdd = false, this.imageUrl, required this.label, this.onTap});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          children: [
            Container(
              width: 72, 
              height: 72, 
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12), 
                border: Border.all(color: const Color(0xFF5C79FF), width: 1.5), 
                image: isAdd ? null : DecorationImage(image: NetworkImage(imageUrl ?? 'https://i.pravatar.cc/150?u=$label'), fit: BoxFit.cover)
              ), 
              child: isAdd ? const Icon(Icons.add, color: Color(0xFF5C79FF), size: 32) : null
            ),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

class _ThreadItem extends StatelessWidget {
  final String name;
  final String message;
  final String time;
  final bool active;
  final bool hasPermission;
  final ValueChanged<bool> onToggle;

  const _ThreadItem({
    required this.name, 
    required this.message, 
    required this.time, 
    required this.active,
    required this.hasPermission,
    required this.onToggle,
  });
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFF111111), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white.withValues(alpha: 0.05))),
      child: Row(
        children: [
          CircleAvatar(radius: 24, backgroundImage: NetworkImage('https://i.pravatar.cc/150?u=$name')),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 4),
            Text(message, style: const TextStyle(color: Colors.white38, fontSize: 13), maxLines: 1),
          ])),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            if (active) Row(children: [
              const Text('Live', style: TextStyle(color: Colors.white38, fontSize: 10)), 
              const SizedBox(width: 4), 
              Switch.adaptive(
                value: hasPermission, 
                onChanged: onToggle, 
                activeColor: const Color(0xFF5C79FF)
              )
            ]),
            Text(time, style: const TextStyle(color: Colors.white38, fontSize: 10)),
          ])
        ],
      ),
    );
  }
}

class _NavBarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  const _NavBarItem({required this.icon, required this.label, this.isActive = false, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(icon, color: isActive ? const Color(0xFF5C79FF) : Colors.white38), const SizedBox(height: 4), Text(label, style: TextStyle(color: isActive ? const Color(0xFF5C79FF) : Colors.white38, fontSize: 10, fontWeight: FontWeight.bold))]),
    );
  }
}

class _SafetyStatusCard extends ConsumerWidget {
  final JourneyState journeyState;
  const _SafetyStatusCard({required this.journeyState});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final seconds = journeyState.nextCheckCountdownSeconds ?? 0;
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    final timeStr = "${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}";
    
    final isVerificationWindow = journeyState.status == JourneyStatus.pinging;

    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      opacity: isVerificationWindow ? 0.15 : 0.05,
      border: Border.all(
        color: isVerificationWindow ? Colors.orangeAccent : const Color(0xFF5C79FF).withValues(alpha: 0.3),
        width: 1.5,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                isVerificationWindow ? Icons.security_rounded : Icons.timer_outlined, 
                color: isVerificationWindow ? Colors.orangeAccent : const Color(0xFF5C79FF)
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isVerificationWindow ? "VERIFICATION REQUIRED" : "Safety Checkpoint",
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    Text(
                      isVerificationWindow ? "Confirm your safety now" : "Next automated check in $timeStr",
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 11),
                    ),
                  ],
                ),
              ),
              if (isVerificationWindow)
                ElevatedButton(
                  onPressed: () => _showOtpDialog(context, ref),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orangeAccent,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                  child: const Text("ENTER OTP", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                )
              else 
                Text(timeStr, style: const TextStyle(color: Color(0xFF5C79FF), fontWeight: FontWeight.bold, fontSize: 18)),
            ],
          ),
          if (journeyState.lastOtpVerificationTime != null && 
              DateTime.now().difference(journeyState.lastOtpVerificationTime!).inMinutes < 10)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => ref.read(journeyProvider.notifier).stopJourney(isCompleted: true),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.greenAccent,
                    side: const BorderSide(color: Colors.greenAccent),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text("FINISH JOURNEY", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showOtpDialog(BuildContext context, WidgetRef ref) {
    final TextEditingController otpController = TextEditingController();
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF111111),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Column(
          children: [
            Icon(Icons.shield_moon_rounded, color: Color(0xFF5C79FF), size: 48),
            SizedBox(height: 16),
            Text("Enter Safety OTP", style: TextStyle(color: Colors.white)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Please verify your safety to continue. Failure to do so will trigger an SOS alert.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: otpController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 24, letterSpacing: 8, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                counterText: "",
                filled: true,
                fillColor: Colors.black26,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Tries left: ${ref.watch(journeyProvider).otpTriesLeft}",
              style: const TextStyle(color: Colors.orangeAccent, fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("CANCEL", style: TextStyle(color: Colors.white38)),
          ),
          ElevatedButton(
            onPressed: () async {
              final ok = await ref.read(journeyProvider.notifier).verifySafetyOtp(otpController.text);
              if (ok) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Safety Verified. Secure journey continue.")),
                );
              } else {
                otpController.clear();
                if (ref.read(journeyProvider).status == JourneyStatus.sosTriggered) {
                   Navigator.pop(context);
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF5C79FF)),
            child: const Text("VERIFY"),
          ),
        ],
      ),
    );
  }
}
