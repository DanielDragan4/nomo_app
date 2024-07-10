import 'dart:convert';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class NominatimService {
  static const String _baseUrl = 'https://nominatim.openstreetmap.org/search';

  Future<List<Map<String, dynamic>>> search(String query, {String? country}) async {
    final countryParam = country != null ? '&countrycodes=$country' : '';
    final url = Uri.parse('$_baseUrl?q=$query$countryParam&limit=5&format=json');
    final response = await http.get(url);
    print(url);
    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      return data.map((item) => item as Map<String, dynamic>).toList();
    } else {
      throw Exception('Failed to load search results');
    }
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
         country =
            '${place.isoCountryCode}';
    });
    return country;
  }
