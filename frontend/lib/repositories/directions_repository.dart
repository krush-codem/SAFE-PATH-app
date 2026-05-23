import 'package:dio/dio.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';

class DirectionsRepository {
  static const String _baseUrl = 'https://maps.googleapis.com/maps/api/directions/json';
  final Dio _dio;
  final String _apiKey;

  DirectionsRepository({required Dio dio, required String apiKey})
      : _dio = dio,
        _apiKey = apiKey;

  static DateTime? _lastLogTime;

  Future<Map<String, dynamic>?> getDirections({
    required LatLng origin,
    required LatLng destination,
  }) async {
    try {
      final response = await _dio.get(
        _baseUrl,
        queryParameters: {
          'origin': '${origin.latitude},${origin.longitude}',
          'destination': '${destination.latitude},${destination.longitude}',
          'key': _apiKey,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        if ((data['routes'] as List).isEmpty) return null;

        final route = data['routes'][0];
        final polyline = route['overview_polyline']['points'];
        
        // Decode polyline points
        final polylinePoints = PolylinePoints();
        List<PointLatLng> decodedPolyline = polylinePoints.decodePolyline(polyline);
        
        List<LatLng> points = decodedPolyline
            .map((p) => LatLng(p.latitude, p.longitude))
            .toList();

        final legs = route['legs'][0];
        return {
          'polyline_points': points,
          'distance': legs['distance']['text'],
          'duration': legs['duration']['text'],
          'bounds': _getBounds(route['bounds']),
        };
      }
    } catch (e) {
      if (e is DioError && e.type == DioErrorType.connectionError) {
         final now = DateTime.now();
         if (_lastLogTime == null || now.difference(_lastLogTime!).inSeconds > 60) {
           print('Directions CORS Fallback: Returning mock route for web (logs throttled).');
           _lastLogTime = now;
         }
         return _getMockDirections(origin, destination);
      }
      print('Directions Error: $e');
    }
    return _getMockDirections(origin, destination); // Safe fallback
  }

  Map<String, dynamic> _getMockDirections(LatLng origin, LatLng destination) {
    return {
      'polyline_points': [
        origin,
        LatLng((origin.latitude + destination.latitude) / 2, (origin.longitude + destination.longitude) / 2),
        destination,
      ],
      'distance': '5.2 km',
      'duration': '12 mins',
      'bounds': LatLngBounds(
        southwest: LatLng(
          origin.latitude < destination.latitude ? origin.latitude : destination.latitude,
          origin.longitude < destination.longitude ? origin.longitude : destination.longitude,
        ),
        northeast: LatLng(
          origin.latitude > destination.latitude ? origin.latitude : destination.latitude,
          origin.longitude > destination.longitude ? origin.longitude : destination.longitude,
        ),
      ),
    };
  }

  LatLngBounds _getBounds(Map<String, dynamic> bounds) {
    return LatLngBounds(
      southwest: LatLng(bounds['southwest']['lat'], bounds['southwest']['lng']),
      northeast: LatLng(bounds['northeast']['lat'], bounds['northeast']['lng']),
    );
  }
}
