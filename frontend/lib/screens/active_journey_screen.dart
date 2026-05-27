import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../providers/journey_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/dynamic_ui.dart';
import '../core/utils/map_marker_helper.dart';
import '../theme/app_theme.dart';

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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final journeyState = ref.watch(journeyProvider);
    final isJourneyActive = journeyState.status != JourneyStatus.inactive;
    final isSOSActive = journeyState.status == JourneyStatus.sosTriggered;
    final profileAsync = ref.watch(profileProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: colorScheme.onSurface, size: 20), 
          onPressed: () => context.pop()
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isSOSActive ? 'SOS: EMERGENCY PROTOCOL' : 'Safe Path Active', 
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)
            ),
            if (isSOSActive) 
              Text(
                'CALCULATING SHORTEST ROUTE', 
                style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.error, fontWeight: FontWeight.bold, letterSpacing: 1)
              ),
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
        ? Center(
            child: Text(
              'No Active Journey.\nStart a journey to see mapping and SOS tools.', 
              style: theme.textTheme.bodyMedium, 
              textAlign: TextAlign.center
            )
          )
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
              Center(
                child: Text(
                  'Settings Coming Soon', 
                  style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface.withValues(alpha: 0.2))
                )
              ),
            ],
          ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: colorScheme.surface, 
          border: Border(top: BorderSide(color: theme.dividerColor))
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

class _MapTab extends ConsumerStatefulWidget {
  final JourneyState journeyState;
  final Function(GoogleMapController) onMapCreated;

  const _MapTab({required this.journeyState, required this.onMapCreated});

  @override
  ConsumerState<_MapTab> createState() => _MapTabState();

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

class _MapTabState extends ConsumerState<_MapTab> {
  final Map<String, Marker> _markers = {};
  bool _isLoadingMarkers = false;

  @override
  void initState() {
    super.initState();
    _updateMarkers();
  }

  @override
  void didUpdateWidget(_MapTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.journeyState.guardianLocations != widget.journeyState.guardianLocations ||
        oldWidget.journeyState.currentLat != widget.journeyState.currentLat ||
        oldWidget.journeyState.locationPermissionIds != widget.journeyState.locationPermissionIds) {
      _updateMarkers();
    }
  }

  Future<void> _updateMarkers() async {
    if (_isLoadingMarkers) return;
    _isLoadingMarkers = true;

    final journeyState = widget.journeyState;
    final profile = ref.read(profileProvider).value;
    
    final Map<String, Marker> newMarkers = {};

    // 1. User marker
    final LatLng userPos = LatLng(journeyState.currentLat ?? 0.0, journeyState.currentLng ?? 0.0);
    final userIcon = await MapMarkerHelper.getCustomMarker(
      profile?.avatarUrl, 
      profile?.fullName ?? 'You',
      color: Colors.blueAccent
    );
    
    newMarkers['user'] = Marker(
      markerId: const MarkerId('user'),
      position: userPos,
      infoWindow: const InfoWindow(title: 'You'),
      icon: userIcon,
      zIndex: 10,
    );

    // 2. Guardian markers
    final permittedGuardians = journeyState.guardianLocations
      .where((g) => journeyState.locationPermissionIds.contains(g['id']));

    for (var g in permittedGuardians) {
      final icon = await MapMarkerHelper.getCustomMarker(
        g['avatar_url'], 
        g['name'],
        color: const Color(0xFF5C79FF)
      );
      
      newMarkers[g['id']] = Marker(
        markerId: MarkerId(g['id']),
        position: LatLng(g['lat'], g['lng']),
        infoWindow: InfoWindow(title: g['name']),
        icon: icon,
      );
    }

    if (mounted) {
      setState(() {
        _markers.clear();
        _markers.addAll(newMarkers);
        _isLoadingMarkers = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final journeyState = widget.journeyState;
    final LatLng userPos = LatLng(journeyState.currentLat ?? 0.0, journeyState.currentLng ?? 0.0);
    
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
            controller.setMapStyle(_MapTab._darkMapStyle);
            widget.onMapCreated(controller);
          },
          markers: _markers.values.toSet(),
          polylines: polylines,
          myLocationEnabled: false, // Using custom marker for precision and style
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
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Safe Stories', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          Text('TRANSIENT: DELETES AFTER JOURNEY', style: theme.textTheme.bodySmall?.copyWith(letterSpacing: 1.5)),
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
          Text('Active Threads', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
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
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(12), 
                border: Border.all(color: colorScheme.primary, width: 1.5), 
                image: isAdd ? null : DecorationImage(image: NetworkImage(imageUrl ?? 'https://i.pravatar.cc/150?u=$label'), fit: BoxFit.cover)
              ), 
              child: isAdd ? Icon(Icons.add, color: colorScheme.primary, size: 32) : null
            ),
            const SizedBox(height: 8),
            Text(label, style: theme.textTheme.bodySmall),
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface, 
        borderRadius: BorderRadius.circular(16), 
        border: Border.all(color: theme.dividerColor, width: 1)
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24, 
            backgroundColor: colorScheme.onSurface.withValues(alpha: 0.1),
            backgroundImage: NetworkImage('https://i.pravatar.cc/150?u=$name')
          ),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(name, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
            const SizedBox(height: 4),
            Text(message, style: theme.textTheme.bodyMedium, maxLines: 1),
          ])),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            if (active) Row(children: [
              Text('LIVE', style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w900, letterSpacing: 1)), 
              const SizedBox(width: 4), 
              Switch.adaptive(
                value: hasPermission, 
                onChanged: onToggle, 
                activeTrackColor: colorScheme.primary.withValues(alpha: 0.2),
                activeColor: colorScheme.primary,
              )
            ]),
            Text(time, style: theme.textTheme.bodySmall),
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final color = isActive ? colorScheme.primary : colorScheme.onSurface.withValues(alpha: 0.4);
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min, 
        children: [
          Icon(icon, color: color, size: 24), 
          const SizedBox(height: 6), 
          Text(
            label, 
            style: theme.textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5
            )
          )
        ]
      ),
    );
  }
}

class _SafetyStatusCard extends ConsumerWidget {
  final JourneyState journeyState;
  const _SafetyStatusCard({required this.journeyState});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final seconds = journeyState.nextCheckCountdownSeconds ?? 0;
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    final timeStr = "${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}";
    
    final isVerificationWindow = journeyState.status == JourneyStatus.pinging;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isVerificationWindow ? Colors.orangeAccent : theme.dividerColor,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                isVerificationWindow ? Icons.security_rounded : Icons.timer_outlined, 
                color: isVerificationWindow ? Colors.orangeAccent : colorScheme.onSurface
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isVerificationWindow ? "SAFETY CHECK" : "SECURITY CHECKPOINT",
                      style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w900, letterSpacing: 1),
                    ),
                    Text(
                      isVerificationWindow ? "Confirm your safety now" : "NEXT AUTOMATED PROMPT: $timeStr",
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              if (isVerificationWindow)
                ElevatedButton(
                  onPressed: () => _showOtpDialog(context, ref),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.onSurface,
                    foregroundColor: colorScheme.surface,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                  child: const Text("VERIFY NOW", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11)),
                )
              else 
                Text(timeStr, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
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
                    foregroundColor: colorScheme.onSurface,
                    side: BorderSide(color: colorScheme.onSurface, width: 1.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text("FINISH JOURNEY", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11)),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showOtpDialog(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final TextEditingController otpController = TextEditingController();
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Column(
          children: [
            Icon(Icons.security, color: colorScheme.onSurface, size: 48),
            const SizedBox(height: 16),
            Text("SAFETY CHECK", style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900, letterSpacing: 1)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Please enter your safety code to continue. If not verified, an SOS alert will be sent to your contacts.",
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            TextField(
              controller: otpController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              textAlign: TextAlign.center,
              style: theme.textTheme.displayLarge?.copyWith(fontSize: 32, letterSpacing: 8, fontWeight: FontWeight.w900),
              decoration: InputDecoration(
                counterText: "",
                filled: true,
                fillColor: colorScheme.onSurface.withValues(alpha: 0.05),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              "ATTEMPTS LEFT: ${ref.watch(journeyProvider).otpTriesLeft}",
              style: const TextStyle(color: Colors.orangeAccent, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("CANCEL", style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.5), fontWeight: FontWeight.w900)),
          ),
          ElevatedButton(
            onPressed: () async {
              final ok = await ref.read(journeyProvider.notifier).verifySafetyOtp(otpController.text);
              if (ok) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Safety verified.")),
                );
              } else {
                otpController.clear();
                if (ref.read(journeyProvider).status == JourneyStatus.sosTriggered) {
                   Navigator.pop(context);
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: colorScheme.onSurface, foregroundColor: colorScheme.surface),
            child: const Text("CONFIRM"),
          ),
        ],
      ),
    );
  }
}
