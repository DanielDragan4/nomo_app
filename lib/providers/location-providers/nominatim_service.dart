import 'dart:convert';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class RadarAutocompleteService {
  static const String _baseUrl = 'https://api.radar.io/v1/search/autocomplete';
  static const String _apiKey = 'prj_live_pk_02dfa31c49953a77a6f206cbf917821c48a99c7f';

  Future<List<Map<String, String>>> autocomplete(String query, {String? country}) async {
    try {
      final countryParam = country != null ? '&country=$country' : '';
      final url = Uri.parse('$_baseUrl?query=$query$countryParam&limit=5');
      final response = await http.get(
        url,
        headers: {'Authorization': _apiKey},
      );
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data.containsKey('addresses') && data['addresses'] is List) {
          return (data['addresses'] as List).map((item) => _formatAddress(item)).toList();
        } else {
          print('Unexpected response structure: $data');
          return [];
        }
      } else {
        print('Failed to load autocomplete results. Status code: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Error occurred during API call: $e');
      return [];
    }
  }

  Map<String, String> _formatAddress(Map<String, dynamic> item) {
    return {
      'display_name': item['formattedAddress'] ?? '',
      'lat': item['latitude']?.toString() ?? '',
      'lon': item['longitude']?.toString() ?? '',
    };
  }
}

Future<String?> getSavedCountry() async {
  final savedUserSessionData = await SharedPreferences.getInstance();
  final savedLocation = savedUserSessionData.getStringList("savedLocation");
  if (savedLocation != null && savedLocation.isNotEmpty) {
    final fullAddress = Position.fromMap(json.decode(savedLocation[0])); // Get the first (and only) item in the list
    return await getAddressFromLatLng(fullAddress);
  }
  return null;
}

Future<String> getAddressFromLatLng(Position position) async {
  var country;
  await placemarkFromCoordinates(
          position.latitude, position.longitude)
      .then((List<Placemark> placemarks) {
    Placemark place = placemarks[0];
    country = '${place.isoCountryCode}';
  });
  return country;
}