import 'package:dio/dio.dart';

class PlaceRepository {
  final String _apiKey;
  final Dio _dio = Dio();

  PlaceRepository(this._apiKey);

  Future<List<Map<String, dynamic>>> getAutocomplete(String input) async {
    if (input.isEmpty) return [];

    // For better experience on Chrome/Web where CORS blocks results, 
    // we use mock results directly if we're not using a real/valid key.
    if (_apiKey.isEmpty || _apiKey == "YOUR_GOOGLE_MAPS_API_KEY") {
      return _getMockResults(input);
    }

    try {
      final response = await _dio.get(
        'https://maps.googleapis.com/maps/api/place/autocomplete/json',
        queryParameters: {
          'input': input,
          'key': _apiKey,
          'types': 'geocode',
        },
      );

      if (response.statusCode == 200) {
        final predictions = response.data['predictions'] as List;
        return predictions.map((p) => {
          'title': p['structured_formatting']['main_text'],
          'subtitle': p['structured_formatting']['secondary_text'] ?? '',
          'distance': '${(input.length * 0.5).toStringAsFixed(1)} mi',
        }).toList();
      }
    } catch (e) {
      final mock = _getMockResults(input);
      print("Autocomplete fallback to mock [${mock.length} results] for: $input");
      return mock;
    }
    return [];
  }

  List<Map<String, dynamic>> _getMockResults(String input) {
    if (input.isEmpty) return [];
    
    // We add more mock locations to make it feel better in Dev/Web mode 
    // where CORS blocks real API calls.
    final mockLocations = [
      {'title': 'Central Park', 'subtitle': 'New York, NY', 'distance': '0.5 mi'},
      {'title': 'Central Station', 'subtitle': 'New York, NY', 'distance': '1.2 mi'},
      {'title': 'Central Mall', 'subtitle': 'Jersey City, NJ', 'distance': '3.5 mi'},
      {'title': 'SUM Hospital', 'subtitle': 'K8 Kalinga Nagar, Bhubaneswar', 'distance': '5.7 mi'},
      {'title': 'AIIMS Bhubaneswar', 'subtitle': 'Sijua, Patrapada', 'distance': '8.2 mi'},
      {'title': 'Station Square', 'subtitle': 'Master Canteen Area', 'distance': '2.8 mi'},
      {'title': 'Utkal University', 'subtitle': 'Vani Vihar, Bhubaneswar', 'distance': '4.1 mi'},
      {'title': 'Biju Patnaik Airport', 'subtitle': 'Bhubaneswar, Odisha', 'distance': '6.4 mi'},
      {'title': 'Kalinga Stadium', 'subtitle': 'Nayapalli, Bhubaneswar', 'distance': '3.9 mi'},
      {'title': 'Forum Mart', 'subtitle': 'Kharabela Nagar, Bhubaneswar', 'distance': '2.4 mi'},
      {'title': 'Esplanade One', 'subtitle': 'Rasulgarh, Bhubaneswar', 'distance': '5.0 mi'},
      {'title': 'Kiit University', 'subtitle': 'Patia, Bhubaneswar', 'distance': '7.2 mi'},
    ];
    
    final query = input.toLowerCase();
    return mockLocations.where((e) {
      final title = (e['title'] ?? '').toLowerCase();
      final subtitle = (e['subtitle'] ?? '').toLowerCase();
      return title.contains(query) || subtitle.contains(query);
    }).toList();
  }
}
