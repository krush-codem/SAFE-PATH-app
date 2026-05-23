import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../providers/journey_provider.dart';

class LiveMapTab extends ConsumerStatefulWidget {
  const LiveMapTab({super.key});

  @override
  ConsumerState<LiveMapTab> createState() => _LiveMapTabState();
}

class _LiveMapTabState extends ConsumerState<LiveMapTab> {
  GoogleMapController? _mapController;

  @override
  void didUpdateWidget(covariant LiveMapTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    _updateCamera();
  }

  void _updateCamera() {
    final journeyState = ref.read(journeyProvider);
    if (_mapController != null && journeyState.currentLat != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLng(
          LatLng(journeyState.currentLat!, journeyState.currentLng!),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final journeyState = ref.watch(journeyProvider);
    
    // If we don't have a location yet, show a loading placeholder
    if (journeyState.currentLat == null) {
      return Container(
        color: const Color(0xFF0F1724),
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: Colors.blueAccent),
              SizedBox(height: 16),
              Text('Acquiring GPS Signal...', style: TextStyle(color: Colors.white70)),
            ],
          ),
        ),
      );
    }

    final userLoc = LatLng(journeyState.currentLat!, journeyState.currentLng!);

    final Set<Marker> markers = {
      // Self Marker
      Marker(
        markerId: const MarkerId('me'),
        position: userLoc,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueCyan),
        infoWindow: const InfoWindow(title: 'You (Current Location)'),
      ),
    };

    // Guardian Markers
    for (var loc in journeyState.guardianLocations) {
      markers.add(
        Marker(
          markerId: MarkerId(loc['id']),
          position: LatLng(loc['lat'], loc['lng']),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
          infoWindow: InfoWindow(
            title: loc['name'] ?? 'Guardian',
            snippet: 'Live Location Access Granted',
          ),
        ),
      );
    }

    return Container(
      color: const Color(0xFF0F1724),
      child: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(target: userLoc, zoom: 15),
            onMapCreated: (c) => _mapController = c,
            markers: markers,
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            zoomControlsEnabled: false,
            mapType: MapType.normal,
            style: _darkMapStyle,
          ),
          
          // Floating Label
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF1E2633).withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white10),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 10),
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.radar_outlined, color: Colors.blueAccent, size: 20),
                  const SizedBox(width: 12),
                  Text(
                    '${journeyState.guardianLocations.length} People Sharing with You',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // A simplified dark style for Google Maps
  static const String _darkMapStyle = '''
[
  {
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#212121"
      }
    ]
  },
  {
    "elementType": "labels.icon",
    "stylers": [
      {
        "visibility": "off"
      }
    ]
  },
  {
    "elementType": "labels.text.fill",
    "stylers": [
      {
        "color": "#757575"
      }
    ]
  },
  {
    "elementType": "labels.text.stroke",
    "stylers": [
      {
        "color": "#212121"
      }
    ]
  },
  {
    "featureType": "administrative",
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#757575"
      }
    ]
  },
  {
    "featureType": "water",
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#000000"
      }
    ]
  }
]
''';
}
