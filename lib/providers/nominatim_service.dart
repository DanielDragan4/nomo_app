import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class NominatimService {
  static const String _baseUrl = 'https://nominatim.openstreetmap.org/search';

  Future<List<Map<String, dynamic>>> search(String query, {String? country}) async {
    final countryParam = country != null ? '&country=$country' : '';
    final url = Uri.parse('$_baseUrl?q=$query$countryParam&format=json');
    final response = await http.get(url);

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
    final fullAddress = savedLocation[0]; // Get the first (and only) item in the list
    return extractCountry(fullAddress);
  }
  return null;
}

String? extractCountry(String fullAddress) {
  // A simple example to extract the country assuming the country is at the end of the address
  // Adjust the logic based on your address format
  final parts = fullAddress.split(',');
  if (parts.isNotEmpty) {
    return parts.last.trim();
  }
  return null;
}
